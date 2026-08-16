// Drives a real server restart through the shipped UI, and verifies what
// happens to the app while the server is gone.
//
// This is the one flow the app cannot report on itself: the connection drops
// mid-action, so nothing after the tap can be confirmed from inside the request
// that caused it. Everything else about restart is already pinned by widget
// tests and the static confirmation audit; what those cannot show is whether
// the app notices the server disappearing, says so honestly, and recovers.
//
// Usage:
//   flutter test integration_test/live_reboot_ui_test.dart \
//     -d <deviceId> \
//     --dart-define=TRUEDOCK_HOST=10.0.0.2 \
//     --dart-define=TRUEDOCK_USER=truenas_admin \
//     --dart-define=TRUEDOCK_PASSWORD=... \
//     --dart-define=TRUEDOCK_LIVE=1
//
// DISRUPTIVE. It restarts the target server. Only run it against a disposable
// test system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';

import 'adaptive_shell_test_helpers.dart';

const _live = String.fromEnvironment('TRUEDOCK_LIVE');
const _host = String.fromEnvironment('TRUEDOCK_HOST');
const _user = String.fromEnvironment('TRUEDOCK_USER');
const _password = String.fromEnvironment('TRUEDOCK_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'live restart through the UI',
    () {
      testWidgets('restarts the server, reports the loss, and reconnects', (
        tester,
      ) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const TrueDockApp(),
          ),
        );
        await _settle(tester);
        await _register(tester);

        final uptimeBefore = container
            .read(connectionControllerProvider)
            .systemInfo
            ?.uptimeSeconds;
        expect(
          uptimeBefore,
          isNotNull,
          reason:
              'need a pre-restart uptime to prove the box actually rebooted',
        );

        // System is the fifth destination; Updates carries the power controls.
        await _tap(tester, adaptiveDestinationAt(4));
        await _tap(tester, find.text('업데이트'), seconds: 10);

        await tester.scrollUntilVisible(
          find.text('전원'),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await _settle(tester, seconds: 2);

        await _tap(tester, find.widgetWithText(OutlinedButton, '서버 재시작'));

        // The typed confirmation is the last accurate thing the user sees, so
        // check it is really gating rather than assuming the widget tests cover
        // the live path too.
        final confirm = find.widgetWithText(FilledButton, '지금 재시작');
        expect(
          tester.widget<FilledButton>(confirm).onPressed,
          isNull,
          reason: 'restart must not be reachable without typing the name',
        );
        await tester.enterText(find.byType(TextField), 'Live');
        await _settle(tester, seconds: 1);
        await tester.tap(confirm);

        // ---- the server is going away -------------------------------------

        // The app must move itself out of the connected state. A UI that keeps
        // rendering as though the server were reachable is the failure this
        // whole flow exists to rule out.
        final lost = await _waitFor(
          tester,
          () =>
              container.read(connectionControllerProvider).isConnectionLost ||
              find.textContaining('연결 끊김').evaluate().isNotEmpty,
          const Duration(minutes: 3),
        );
        expect(
          lost,
          isTrue,
          reason:
              'the app never noticed the server going away. '
              'On screen: ${_text(tester)}',
        );

        // `_waitFor` returns the moment the controller flips, which is before
        // the tree has rebuilt around it. Pump first, or this asserts against
        // the pre-drop frame and reports a missing banner that is merely late.
        await _settle(tester, seconds: 6);

        expect(
          find.textContaining('마지막으로 받은 데이터'),
          findsWidgets,
          reason:
              'anything on screen predates the drop, so it must be labelled '
              'stale rather than left to read as live. '
              'On screen: ${_text(tester)}',
        );

        // ---- recovery ------------------------------------------------------

        // Reconnect is offered in the banner. It will fail while the server is
        // still booting, which is itself worth exercising: the banner has to
        // survive a failed retry rather than collapsing into a dead end.
        final recovered = await _retryUntilConnected(
          tester,
          container,
          const Duration(minutes: 10),
        );
        expect(
          recovered,
          isTrue,
          reason:
              'the app never reconnected after the restart. '
              'On screen: ${_text(tester)}',
        );

        final uptimeAfter = container
            .read(connectionControllerProvider)
            .systemInfo
            ?.uptimeSeconds;
        expect(uptimeAfter, isNotNull);
        expect(
          uptimeAfter!,
          lessThan(uptimeBefore!),
          reason:
              'uptime did not reset, so the server never actually restarted '
              '(before: $uptimeBefore, after: $uptimeAfter)',
        );

        // Capabilities describe a session that no longer exists, so they must
        // have been rediscovered rather than carried across the drop.
        expect(
          container.read(connectionControllerProvider).capabilities,
          isNotNull,
          reason: 'capabilities were not rediscovered after reconnecting',
        );
      });
    },
    skip: _live != '1'
        ? 'set --dart-define=TRUEDOCK_LIVE=1 with host/user/password to run'
        : null,
  );
}

/// Taps Reconnect until the app is connected again or the deadline passes.
///
/// Retries are expected to fail while the server boots; that path is part of
/// what this verifies.
Future<bool> _retryUntilConnected(
  WidgetTester tester,
  ProviderContainer container,
  Duration limit,
) async {
  final deadline = DateTime.now().add(limit);
  var attempts = 0;
  while (DateTime.now().isBefore(deadline)) {
    if (container.read(connectionControllerProvider).isConnected) {
      debugPrint('reconnected after $attempts retry attempt(s)');
      return true;
    }
    final retry = find.widgetWithText(TextButton, '다시 연결');
    if (retry.evaluate().isNotEmpty) {
      attempts++;
      await tester.tap(retry, warnIfMissed: false);
      await _settle(tester, seconds: 6);
      continue;
    }
    await _settle(tester, seconds: 3);
  }
  return container.read(connectionControllerProvider).isConnected;
}

Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() predicate,
  Duration limit,
) async {
  final deadline = DateTime.now().add(limit);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return true;
    await _settle(tester, seconds: 2);
  }
  return predicate();
}

Future<void> _register(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(
    fields,
    findsAtLeast(4),
    reason: 'expected the registration form. On screen: ${_text(tester)}',
  );
  await tester.enterText(fields.at(0), 'Live');
  await tester.enterText(fields.at(1), _host);
  await tester.enterText(fields.at(2), _user);
  await tester.enterText(fields.at(3), _password);
  await _settle(tester);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 2);

  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    if (adaptiveShellIsVisible()) return;
    final trust = find.byIcon(Icons.shield_outlined);
    if (trust.evaluate().isNotEmpty) {
      await tester.tap(trust, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }
    final connect = find.byIcon(Icons.link_rounded);
    if (connect.evaluate().isNotEmpty) {
      await tester.tap(connect, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }
    await _settle(tester, seconds: 2);
  }
  fail('connection did not complete. On screen: ${_text(tester)}');
}

String _text(WidgetTester tester) {
  final seen = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final data = (element.widget as Text).data;
    if (data != null && data.trim().isNotEmpty) seen.add(data.trim());
  }
  return seen.join(' / ');
}

Future<void> _tap(
  WidgetTester tester,
  FinderBase<Element> finder, {
  int seconds = 6,
}) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 1);
  await tester.ensureVisible(finder);
  await _settle(tester, seconds: 1);
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester, seconds: seconds);
}

/// `pumpAndSettle` cannot be used: the app holds a live WebSocket and animates
/// progress while jobs run, so the tree never becomes fully idle.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
