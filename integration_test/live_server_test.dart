// End-to-end verification of the shipped app against a live TrueNAS server.
//
// Unit and widget tests never open a socket, and the Dart-VM probes in `tool/`
// exercise the wire protocol without the widget tree. This closes the gap
// between them: it launches the real `TrueDockApp` on a simulator or device,
// registers the server through the onboarding form, approves the self-signed
// certificate, and then walks the top-level destinations asserting that each
// one renders live server data rather than an error state.
//
// Credentials are supplied at run time and never committed:
//
//   flutter test integration_test/live_server_test.dart \
//     -d <deviceId> \
//     --dart-define=TRUEDOCK_HOST=10.0.0.2 \
//     --dart-define=TRUEDOCK_USER=truenas_admin \
//     --dart-define=TRUEDOCK_PASSWORD=... \
//     --dart-define=TRUEDOCK_LIVE=1
//
// Without `TRUEDOCK_LIVE=1` the whole group is skipped, so the file is safe to
// leave in place for contributors who have no test server.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/features/system/presentation/system_general_sheet.dart';
import 'package:true_dock/features/storage/presentation/dataset_acl_sheet.dart';
import 'package:true_dock/features/reporting/presentation/reporting_history_screen.dart';

const _live = String.fromEnvironment('TRUEDOCK_LIVE');
const _host = String.fromEnvironment('TRUEDOCK_HOST');
const _user = String.fromEnvironment('TRUEDOCK_USER');
const _password = String.fromEnvironment('TRUEDOCK_PASSWORD');

/// Comma-separated resource names that must be visible somewhere in the app,
/// e.g. a pool and an installed app created before the run.
///
/// Absence of an error card only proves nothing broke. It does not prove the
/// app rendered the server's actual inventory: a screen that quietly returned
/// an empty list would pass the error check while showing the user nothing.
/// Naming known resources is what turns this into a positive assertion.
const _expected = String.fromEnvironment('TRUEDOCK_EXPECT');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'live server',
    () {
      testWidgets('registers a server and renders every destination', (
        tester,
      ) async {
        await tester.pumpWidget(const ProviderScope(child: TrueDockApp()));
        await _settle(tester);

        // A clean simulator opens registration. Keychain metadata survives an
        // app reinstall, so a repeated run correctly opens the server picker;
        // use its explicit registration button to avoid triggering biometric
        // unlock when the prior run saved a protected credential.
        if (find.byType(TextFormField).evaluate().isEmpty) {
          final addServer = find.byKey(
            const ValueKey('register-server-button'),
          );
          expect(
            addServer,
            findsOneWidget,
            reason: 'expected registration or a registered server picker',
          );
          await _tap(tester, addServer, seconds: 3);
        }
        expect(
          find.byType(TextFormField),
          findsAtLeast(3),
          reason: 'expected the server registration form after entry',
        );

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Live');
        await tester.enterText(fields.at(1), _host);
        await tester.enterText(fields.at(2), _user);
        await tester.enterText(fields.at(3), _password);
        await _settle(tester);

        // Ordinary login is the default method, which is what the demo server
        // accepts, so no segment switch is needed here. Asserting it keeps a
        // regression in the default from silently changing what this test
        // exercises.
        expect(
          find.byIcon(Icons.password_rounded),
          findsOneWidget,
          reason: 'the password field should be shown by default',
        );

        // Connecting is not a single tap: submitting the form starts an
        // asynchronous handshake, the connect button becomes a spinner (so its
        // icon disappears), and a self-signed certificate raises a trust sheet
        // that covers the form. Drive it as a state machine rather than a
        // fixed sequence, or the test races the UI it is verifying.
        await _connect(tester);

        // Overview must show live data, and no destination may land on an
        // error state.
        expect(
          find.byType(NavigationBar),
          findsOneWidget,
          reason:
              'connecting should replace registration with the app shell. '
              'On screen: ${_visibleText(tester)}',
        );
        _expectNoErrorState(tester, 'Overview');
        await _pullToRefresh(tester, 'Overview');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('reporting-memory-chart')),
          260,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(const ValueKey('reporting-memory-chart')),
          findsOneWidget,
          reason: 'live RAM usage should be rendered from reporting data',
        );
        expect(
          find.byKey(const ValueKey('reporting-network-carousel')),
          findsOneWidget,
          reason: 'advertised network interfaces should render as a carousel',
        );
        expect(
          find.byKey(const ValueKey('reporting-disk-carousel')),
          findsOneWidget,
          reason: 'advertised disks should render their read/write I/O',
        );
        for (final entry in const [
          (
            ValueKey('reporting-cpu-chart'),
            ReportingHistoryMetric.cpu,
            ValueKey('reporting-history-cpu'),
          ),
          (
            ValueKey('reporting-memory-chart'),
            ReportingHistoryMetric.memory,
            ValueKey('reporting-history-memory'),
          ),
          (
            ValueKey('reporting-network-carousel'),
            ReportingHistoryMetric.network,
            ValueKey('reporting-history-network'),
          ),
          (
            ValueKey('reporting-disk-carousel'),
            ReportingHistoryMetric.disk,
            ValueKey('reporting-history-disk'),
          ),
        ]) {
          await tester.scrollUntilVisible(
            find.byKey(entry.$1),
            220,
            scrollable: find.byType(Scrollable).first,
          );
          await _tap(tester, find.byKey(entry.$1), seconds: 12);
          expect(find.byType(ReportingHistoryScreen), findsOneWidget);
          expect(find.byKey(entry.$3), findsOneWidget);
          expect(
            tester
                .widget<ReportingHistoryScreen>(
                  find.byType(ReportingHistoryScreen),
                )
                .metric,
            entry.$2,
          );
          _expectNoErrorState(tester, '${entry.$2.name} history');
          await _goBack(tester);
        }

        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        final seen = StringBuffer(_visibleText(tester));
        for (var index = 1; index < bar.destinations.length; index++) {
          final destination = bar.destinations[index] as NavigationDestination;
          await _tap(
            tester,
            find.byType(NavigationDestination).at(index),
            seconds: 20,
          );
          _expectNoErrorState(tester, destination.label);
          await _pullToRefresh(tester, destination.label);
          if (index == 1) {
            final datasetMenu = find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'dataset-actions-',
                  ),
            );
            expect(
              datasetMenu,
              findsAtLeast(1),
              reason: 'the live server should expose a dataset action menu',
            );
            await _tap(tester, datasetMenu.first);
            await _tap(
              tester,
              find.byKey(const ValueKey('dataset-manage-acl-action')),
              seconds: 8,
            );
            expect(find.byType(DatasetAclSheet), findsOneWidget);
            expect(find.textContaining('POSIX1E'), findsOneWidget);
            _expectNoErrorState(tester, 'Dataset ACL');
            await tester.tap(
              find.descendant(
                of: find.byType(DatasetAclSheet),
                matching: find.byIcon(Icons.close_rounded),
              ),
            );
            await _settle(tester);
          }
          seen.write(' / ${_visibleText(tester)}');
        }

        // System administration is split by responsibility: General is a
        // full page containing power controls, Advanced owns boot
        // environments, and Updates contains neither. Exercise the actual
        // routes so a future navigation edit cannot quietly mix them again.
        await _tap(
          tester,
          find.byKey(const ValueKey('system-general-tile')),
          seconds: 12,
        );
        expect(
          tester
              .widget<SystemGeneralSheet>(find.byType(SystemGeneralSheet))
              .embedded,
          isTrue,
          reason: 'general settings must render as a page, not a modal sheet',
        );
        expect(
          find.byKey(const ValueKey('general-power-section')),
          findsOneWidget,
        );
        _expectNoErrorState(tester, 'System general');
        await _goBack(tester);

        await _tap(
          tester,
          find.byKey(const ValueKey('system-advanced-tile')),
          seconds: 8,
        );
        expect(
          find.byKey(const ValueKey('advanced-boot-environments-section')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('general-power-section')),
          findsNothing,
        );
        _expectNoErrorState(tester, 'System advanced');
        await _goBack(tester);

        await _tap(
          tester,
          find.byKey(const ValueKey('system-updates-tile')),
          seconds: 8,
        );
        expect(
          find.byKey(const ValueKey('general-power-section')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('advanced-boot-environments-section')),
          findsNothing,
        );
        _expectNoErrorState(tester, 'System updates');
        await _goBack(tester);

        // Positive check: the named resources really reached the screen.
        final expected = _expected
            .split(',')
            .map((name) => name.trim())
            .where((name) => name.isNotEmpty);
        final rendered = seen.toString();
        for (final name in expected) {
          expect(
            rendered.contains(name),
            isTrue,
            reason:
                '"$name" exists on the server but never appeared in the app. '
                'On screen: $rendered',
          );
        }
      });
    },
    skip: _live != '1'
        ? 'set --dart-define=TRUEDOCK_LIVE=1 with host/user/password to run'
        : null,
  );
}

/// Pulls the current top-level screen from its top edge and waits for the
/// resulting provider refresh to finish. This is the only whole-screen refresh
/// affordance, so the live test drives the gesture instead of looking for a
/// toolbar icon.
Future<void> _pullToRefresh(WidgetTester tester, String destination) async {
  final scrollView = find.byType(CustomScrollView);
  expect(
    scrollView,
    findsOneWidget,
    reason: '$destination must expose one pull-to-refresh scroll surface',
  );
  await tester.drag(scrollView, const Offset(0, 360));
  await tester.pump(const Duration(milliseconds: 150));
  expect(
    find.byType(RefreshProgressIndicator),
    findsOneWidget,
    reason: '$destination did not start pull-to-refresh',
  );
  await _settle(tester, seconds: 12);
  _expectNoErrorState(tester, '$destination refresh');
}

/// Submits the registration form and resolves whatever the connection flow
/// raises until the app shell appears or the attempt clearly failed.
///
/// Approving the certificate is part of the behaviour under test: TrueDock must
/// not connect to a self-signed server without an explicit trust decision.
Future<void> _connect(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 2);

  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    if (find.byType(NavigationBar).evaluate().isNotEmpty) {
      // Reaching the shell without a trust prompt is correct when the
      // certificate was already pinned by an earlier run on this simulator.
      // Uninstall the app between runs to exercise the first-use path.
      return;
    }

    final trust = find.byIcon(Icons.shield_outlined);
    if (trust.evaluate().isNotEmpty) {
      await tester.tap(trust, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }

    // Idle: the form is showing and nothing is in flight, so submit it.
    final connect = find.byIcon(Icons.link_rounded);
    if (connect.evaluate().isNotEmpty) {
      await tester.tap(connect, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }

    // A spinner is up; wait for it to resolve.
    await _settle(tester, seconds: 2);
  }
  fail(
    'connection did not complete in 90s. On screen: ${_visibleText(tester)}',
  );
}

/// Every string currently rendered, so a failure reports what the app actually
/// showed instead of only which widget was missing.
String _visibleText(WidgetTester tester) {
  final seen = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final data = (element.widget as Text).data;
    if (data != null && data.trim().isNotEmpty) seen.add(data.trim());
  }
  return seen.join(' / ');
}

/// Dismisses the keyboard, scrolls [finder] into view, and taps it.
///
/// The registration form is taller than the viewport once the software
/// keyboard is up, so a plain `tap` lands on whatever is covering the target.
Future<void> _tap(
  WidgetTester tester,
  FinderBase<Element> finder, {
  int seconds = 4,
}) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 1);
  await tester.ensureVisible(finder);
  await _settle(tester, seconds: 1);
  await tester.tap(finder);
  await _settle(tester, seconds: seconds);
}

/// Sends the platform back gesture through the router.
///
/// `WidgetTester.pageBack` only recognizes Cupertino back buttons, while
/// TrueDock deliberately uses Material 3 app bars on iOS too.
Future<void> _goBack(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  expect(handled, isTrue, reason: 'the administration page should be poppable');
  await _settle(tester);
}

/// Pumps until the widget tree stops changing, bounded by [seconds].
///
/// `pumpAndSettle` cannot be used: the app keeps a live WebSocket and animates
/// progress indicators while jobs run, so the tree never becomes fully idle.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Fails when a destination rendered a failure state instead of server data.
void _expectNoErrorState(WidgetTester tester, String destination) {
  final failures = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final data = (element.widget as Text).data;
    if (data == null) continue;
    final lower = data.toLowerCase();
    // Match the failure vocabulary the repositories and DataMessage codes
    // produce, in both shipped locales.
    if (lower.contains('invalid data') ||
        lower.contains('could not decode') ||
        lower.contains('rpc error') ||
        lower.contains('unexpected error') ||
        // Raised by the server, not by TrueDock, so it does not match any
        // DataMessage code and was previously invisible to this check even
        // though it renders as a plain error card. It means the app put more
        // calls on one connection than the server accepts, which is a defect
        // in how a screen fans out its reads rather than a server problem.
        lower.contains('concurrent calls') ||
        lower.contains('did not answer') ||
        data.contains('유효하지 않은') ||
        data.contains('디코딩할 수 없')) {
      failures.add(data);
    }
  }
  expect(
    failures,
    isEmpty,
    reason: '$destination rendered failure text: ${failures.join(' | ')}',
  );
}
