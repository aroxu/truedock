import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/core/widgets/connection_lost_banner.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The banner has to reach routes pushed *outside* the shell.
///
/// `app_shell_connection_banner_test` mounts the shell, so it can only ever
/// prove the banner works there. The `/system/*` detail screens are separate
/// routes stacked on top, and while the banner lived inside `AppShell` they had
/// no notice and no retry: a real restart left the user on
/// "connect to a server to see this section" with no way back. Found by
/// restarting the demo server for real.
class _ScriptedChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _ScriptedChannel()
    : _inbound = StreamController<Object?>(),
      _sink = _ReplyingSink() {
    _sink.onRequest = (id, method) => _inbound.add(
      jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': _responses[method]}),
    );
  }

  final StreamController<Object?> _inbound;
  final _ReplyingSink _sink;

  Future<void> drop() => _inbound.close();

  @override
  Stream<Object?> get stream => _inbound.stream;
  @override
  WebSocketSink get sink => _sink;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReplyingSink implements WebSocketSink {
  void Function(int id, String method)? onRequest;

  @override
  void add(Object? data) {
    final decoded = jsonDecode(data! as String) as Map<String, dynamic>;
    final id = decoded['id'];
    final method = decoded['method'];
    if (id is int && method is String) {
      scheduleMicrotask(() => onRequest?.call(id, method));
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<Object?> stream) async {}
  @override
  Future<void> get done => Future<void>.value();
}

class _StubVault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.unsupported);
  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}
  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
  @override
  Future<void> delete(ServerProfile profile) async {}
}

class _StubSavedServerRepository extends SavedServerRepository {
  _StubSavedServerRepository() : super(vault: _StubVault());

  @override
  Future<void> register(
    ServerProfile profile,
    AuthCredential credential, {
    required bool saveCredential,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {}
}

const _responses = <String, Object?>{
  'auth.login_ex': {
    'response_type': 'SUCCESS',
    'user_info': {'pw_name': 'admin'},
  },
  'system.info': {
    'hostname': 'nas',
    'version': 'TrueNAS-SCALE-25.10.2',
    'uptime': '1 day',
    'uptime_seconds': 86400,
    'physmem': 8589934592,
    'model': 'CPU',
    'cores': 4,
  },
  'system.product_type': 'COMMUNITY_EDITION',
  'core.get_methods': {
    'auth.login_ex': <String, Object?>{},
    'system.info': <String, Object?>{},
    'pool.query': <String, Object?>{},
  },
};

final _profile = ServerProfile(
  name: 'nas',
  baseUri: Uri.parse('https://nas.local'),
);

Future<({ConnectionController controller, _ScriptedChannel channel})>
_connect() async {
  final channels = <_ScriptedChannel>[];
  final controller = ConnectionController(
    TrueNasJsonRpcClient(
      connector: (_) async {
        final channel = _ScriptedChannel();
        channels.add(channel);
        return channel;
      },
    ),
    _StubSavedServerRepository(),
  );
  await controller.connect(
    _profile,
    const ApiKeyCredential(username: 'admin', apiKey: 'k'),
  );
  return (controller: controller, channel: channels.single);
}

/// Mirrors how the real app mounts the host: from `builder`, wrapping whatever
/// route is on screen rather than a specific one.
Widget _routeUnderHost(ConnectionController controller, Widget route) =>
    ProviderScope(
      overrides: [
        connectionControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            ConnectionLostHost(child: child ?? const SizedBox.shrink()),
        home: route,
      ),
    );

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a system detail route gets the banner when the socket drops', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(
      _routeUnderHost(
        session.controller,
        const SystemAdministrationScreen(section: 'updates'),
      ),
    );
    await tester.pump();
    expect(find.text('Reconnect'), findsNothing);

    await session.channel.drop();
    await tester.pump();

    // The regression: this screen showed only "connect to a server to see this
    // section", with nothing naming the server and no way to retry.
    expect(
      find.text('Lost connection to nas'),
      findsOneWidget,
      reason: 'a route outside the shell must still report the drop',
    );
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.textContaining('last data TrueDock received'), findsOneWidget);
  });

  testWidgets('the banner leaves the underlying route in place', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(
      _routeUnderHost(
        session.controller,
        const SystemAdministrationScreen(section: 'updates'),
      ),
    );
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    // The banner is an addition, not a replacement: the user keeps their place
    // so a restart does not throw away where they were.
    expect(find.byType(SystemAdministrationScreen), findsOneWidget);
  });

  testWidgets('the real app mounts the host, not just the harness', (
    tester,
  ) async {
    // The tests above mount `ConnectionLostHost` themselves, so they prove the
    // widget works - not that the application wires it up. That gap is not
    // hypothetical: removing the host from `TrueDockApp` left them all passing.
    // Assert against the real app so the wiring itself is covered.
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith(
            (ref) => session.controller,
          ),
          biometricVaultAvailabilityProvider.overrideWith(
            (ref) async => const BiometricVaultAvailability(
              BiometricVaultStatus.unsupported,
            ),
          ),
          savedServersProvider.overrideWith((ref) async => const []),
        ],
        child: const TrueDockApp(),
      ),
    );
    await tester.pump();

    expect(
      find.byType(ConnectionLostHost),
      findsOneWidget,
      reason: 'TrueDockApp must mount the host above every route',
    );

    await session.channel.drop();
    await tester.pump();

    expect(find.text('Lost connection to nas'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
  });

  testWidgets('nothing is added while the connection is healthy', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(
      _routeUnderHost(
        session.controller,
        const SystemAdministrationScreen(section: 'updates'),
      ),
    );
    await tester.pump();

    expect(find.byType(ConnectionLostBanner), findsNothing);
  });
}
