// Drives app start/stop through the shipped UI against a live TrueNAS server.
//
// The dataset test covers a create flow, which is a sheet plus a submit button.
// A lifecycle action is a different shape: it goes through a confirmation
// dialog, it is a long-running server job rather than an immediate write, and
// the tile it lives on re-renders from server state while the job runs. Each of
// those is a place the wiring can be wrong without any unit test noticing.
//
// Usage:
//   flutter test integration_test/live_app_lifecycle_ui_test.dart \
//     -d <deviceId> \
//     --dart-define=TRUEDOCK_HOST=10.0.0.2 \
//     --dart-define=TRUEDOCK_USER=truenas_admin \
//     --dart-define=TRUEDOCK_PASSWORD=... \
//     --dart-define=TRUEDOCK_APP=syncthing \
//     --dart-define=TRUEDOCK_LIVE=1
//
// MUTATING. It stops the named app and starts it again, leaving it running.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';

const _live = String.fromEnvironment('TRUEDOCK_LIVE');
const _host = String.fromEnvironment('TRUEDOCK_HOST');
const _user = String.fromEnvironment('TRUEDOCK_USER');
const _password = String.fromEnvironment('TRUEDOCK_PASSWORD');
const _app = String.fromEnvironment('TRUEDOCK_APP');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'live app lifecycle through the UI',
    () {
      testWidgets('stops and restarts an installed app from the Apps screen', (
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

        // Apps is the fourth destination.
        await _tap(
          tester,
          find.byType(NavigationDestination).at(3),
          seconds: 12,
        );

        expect(
          find.textContaining(_app),
          findsWidgets,
          reason: 'the app is not listed. On screen: ${_text(tester)}',
        );

        // The app has to start from a known state, otherwise "it stopped" could
        // just be reporting where it already was.
        await _expectState(container, 'RUNNING');

        // ---- stop ------------------------------------------------------

        await _tap(tester, _toggleFor(Icons.stop_rounded));

        // Stopping interrupts a workload, so it must be confirmed rather than
        // acting on the first tap. Its absence is a failure, not a shortcut.
        final confirm = find.widgetWithText(FilledButton, '앱 중지');
        expect(
          confirm,
          findsOneWidget,
          reason:
              'stopping an app must ask for confirmation first. '
              'On screen: ${_text(tester)}',
        );
        await _tap(tester, confirm, seconds: 10);

        await _expectState(container, 'STOPPED');

        // ---- start again -----------------------------------------------

        // Starting is not destructive, so it must NOT ask for confirmation;
        // a dialog here would mean the two paths were wired the same way.
        await _tap(tester, _toggleFor(Icons.play_arrow_rounded), seconds: 10);
        expect(
          find.widgetWithText(FilledButton, '앱 중지'),
          findsNothing,
          reason: 'starting an app should not raise the stop confirmation',
        );

        await _expectState(container, 'RUNNING');
      });
    },
    skip: _live != '1' || _app.isEmpty
        ? 'set --dart-define=TRUEDOCK_LIVE=1 and TRUEDOCK_APP to run'
        : null,
  );
}

/// The lifecycle button on the tile for the app under test.
///
/// `find.byIcon(...).first` is wrong twice over. The tile's leading avatar uses
/// the same two icons to display state, so the first match inside a single tile
/// is a decoration rather than a control; and every other installed app has a
/// tile of its own, so the first match on the screen may belong to a different
/// app entirely. That is not hypothetical - an earlier version of this test
/// stopped the wrong app and still reported the failure as "syncthing never
/// reached STOPPED". Scope to the tile carrying the app's name, then take the
/// `IconButton` within it.
Finder _toggleFor(IconData icon) => find.descendant(
  of: find.ancestor(of: find.text(_app), matching: find.byType(ListTile)),
  matching: find.widgetWithIcon(IconButton, icon),
);

/// Polls the app's own resource provider until [state] is reported.
///
/// Reading the server back is the point: a tile that flipped its icon locally
/// without the job succeeding would satisfy any purely on-screen assertion.
Future<void> _expectState(ProviderContainer container, String state) async {
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  String? last;
  while (DateTime.now().isBefore(deadline)) {
    // Await the refresh rather than invalidating and reading whatever is
    // cached. The resources provider fans out a large batch of reads, so a
    // reload takes longer than a short poll interval: invalidating on a timer
    // restarts the load before it can finish, `value` keeps answering
    // with the pre-change snapshot, and the poll never observes the new state
    // no matter how long it runs. That failed here for a full three minutes
    // against a server that had already settled in two seconds.
    final snapshot = await container.refresh(serverResourcesProvider.future);
    for (final installed in snapshot.apps.items) {
      if (installed.id != _app) continue;
      last = installed.state;
      if (installed.state == state) return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  fail('$_app never reached $state (last reported: $last)');
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
    if (find.byType(NavigationBar).evaluate().isNotEmpty) return;
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
