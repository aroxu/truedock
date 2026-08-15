// Suspend/resume against a real server over a real socket.
//
// The widget test in `app_shell_connection_banner_test` already proves the
// resume handler probes before refreshing, but it does so against a scripted
// fake socket that answers instantly and never dies. What it cannot show is the
// behaviour that actually matters after iOS suspends an app for minutes: the
// probe runs over a genuine WebSocket that may have been torn down while the
// process was frozen, and the app has to notice rather than presenting hours-old
// values as current.
//
// Usage:
//   flutter test integration_test/live_lifecycle_ui_test.dart \
//     -d <deviceId> \
//     --dart-define=TRUEDOCK_HOST=10.0.0.2 \
//     --dart-define=TRUEDOCK_USER=truenas_admin \
//     --dart-define=TRUEDOCK_PASSWORD=... \
//     --dart-define=TRUEDOCK_LIVE=1
//
// Read-only against the server.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';

const _live = String.fromEnvironment('TRUEDOCK_LIVE');
const _host = String.fromEnvironment('TRUEDOCK_HOST');
const _user = String.fromEnvironment('TRUEDOCK_USER');
const _password = String.fromEnvironment('TRUEDOCK_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'live lifecycle',
    () {
      testWidgets('resuming refreshes stale data over the real socket', (
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

        final before = container
            .read(connectionControllerProvider)
            .systemInfo
            ?.uptimeSeconds;
        expect(before, isNotNull, reason: 'need a baseline to compare against');

        await _suspendAndResume(tester);

        // The resume handler probes `system.info` first. Against a live server
        // the reported uptime must have moved forward, which is what proves the
        // probe really went to the wire rather than replaying cached state.
        final refreshed = await _waitFor(tester, () {
          final after = container
              .read(connectionControllerProvider)
              .systemInfo
              ?.uptimeSeconds;
          return after != null && after > before!;
        }, const Duration(seconds: 60));

        expect(
          refreshed,
          isTrue,
          reason:
              'uptime did not advance after resuming, so the session probe '
              'did not reach the server',
        );
        expect(
          container.read(connectionControllerProvider).isConnected,
          isTrue,
          reason: 'a healthy resume must not drop the session',
        );
      });

      testWidgets('resuming onto a dead session reconnects automatically', (
        tester,
      ) async {
        // The case that matters. iOS can freeze the process long enough for the
        // server to close the socket; on resume the app must say so rather than
        // leaving hours-old numbers on screen looking live.
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
        expect(
          container.read(connectionControllerProvider).isConnected,
          isTrue,
        );

        // Kill the app's session from outside, the way the server would if it
        // restarted or an admin evicted the client. Deliberately not a debug
        // hook on the controller: a test-only backdoor would prove the app
        // handles a state the app itself produced, which is the weaker claim.
        // `auth.terminate_session` is the same call the Sessions screen makes.
        await _terminateAppSession(tester);
        await _suspendAndResume(tester);

        final reconnected = await _waitFor(
          tester,
          () => container.read(connectionControllerProvider).isConnected,
          const Duration(seconds: 60),
        );

        expect(
          reconnected,
          isTrue,
          reason:
              'the dead session was not reauthenticated after resume. '
              'On screen: ${_text(tester)}',
        );
        expect(
          find.textContaining('마지막으로 받은 데이터'),
          findsNothing,
          reason: 'the stale-data banner must clear after recovery',
        );
      });
    },
    skip: _live != '1'
        ? 'set --dart-define=TRUEDOCK_LIVE=1 with host/user/password to run'
        : null,
  );
}

/// Drives the platform lifecycle transitions iOS emits around a suspend.
///
/// The full sequence matters: an app that only handled `resumed` without seeing
/// `paused`/`hidden` first would pass a shortcut and fail in the field.
Future<void> _suspendAndResume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

  // Deliberately not pumping while paused. A paused app produces no frames, so
  // `pump` waits for one that never arrives and the test hangs rather than
  // failing - which is exactly what happened on the first run here. Let real
  // time pass instead, which is also closer to what a suspend is.
  await Future<void>.delayed(const Duration(seconds: 3));

  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _settle(tester, seconds: 3);
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

/// `pumpAndSettle` cannot be used: the app holds a live WebSocket and animates
/// progress while jobs run, so the tree never becomes fully idle.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Ends TrueDock's own session from a second connection.
///
/// Uses the real `auth.sessions` / `auth.terminate_session` pair rather than a
/// test hook, so the app faces a session that died the way sessions actually
/// die. The app's session is the one that is *not* this helper's own.
Future<void> _terminateAppSession(WidgetTester tester) async {
  final rpc = _Rpc(_host);
  await rpc.open();
  try {
    await rpc.login(_user, _password);
    final rows = await rpc.call('auth.sessions') as List;
    final victims = rows
        .whereType<Map<String, dynamic>>()
        // Skip the middleware's own UNIX-socket connections and this helper.
        .where((row) => row['internal'] != true && row['current'] != true)
        .map((row) => row['id'])
        .whereType<String>()
        .toList();
    expect(
      victims,
      isNotEmpty,
      reason: "the app's session was not visible to terminate",
    );
    for (final id in victims) {
      await rpc.call('auth.terminate_session', params: [id]);
    }
  } finally {
    await rpc.close();
  }
  await _settle(tester, seconds: 2);
}

/// Minimal JSON-RPC client, enough to evict a session from outside the app.
class _Rpc {
  _Rpc(this.host);

  final String host;
  final _pending = <int, Completer<Object?>>{};
  WebSocket? _socket;
  var _nextId = 1;

  Future<void> open() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..badCertificateCallback = (cert, h, p) => h == host;
    final socket = await WebSocket.connect(
      'wss://$host/api/current',
      customClient: client,
    );
    _socket = socket;
    socket.listen((message) {
      final decoded = jsonDecode(message.toString());
      if (decoded is! Map || decoded['id'] is! int) return;
      final completer = _pending.remove(decoded['id'] as int);
      if (completer == null || completer.isCompleted) return;
      final error = decoded['error'];
      if (error != null) {
        completer.completeError(StateError('$error'));
      } else {
        completer.complete(decoded['result']);
      }
    });
  }

  Future<void> login(String username, String password) async {
    final result = await call(
      'auth.login_ex',
      params: [
        {
          'mechanism': 'PASSWORD_PLAIN',
          'username': username,
          'password': password,
        },
      ],
    );
    if ((result as Map)['response_type'] != 'SUCCESS') {
      throw StateError('login returned ${result['response_type']}');
    }
  }

  Future<Object?> call(String method, {List<Object?> params = const []}) {
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _socket!.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future.timeout(const Duration(seconds: 30));
  }

  Future<void> close() async {
    try {
      await _socket?.close();
    } catch (_) {}
  }
}
