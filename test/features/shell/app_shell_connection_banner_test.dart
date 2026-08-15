import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/core/widgets/connection_lost_banner.dart';
import 'package:true_dock/features/apps/presentation/apps_catalog_provider.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/reporting_provider.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/shell/presentation/app_shell.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Answers JSON-RPC requests from a canned map so a real controller can reach
/// the connected state, then be dropped on demand.
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

  List<String> get sentMethods => _sink.methods;

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
  final List<String> methods = [];

  @override
  void add(Object? data) {
    final decoded = jsonDecode(data! as String) as Map<String, dynamic>;
    final id = decoded['id'];
    final method = decoded['method'];
    if (id is int && method is String) {
      methods.add(method);
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
      const BiometricVaultAvailability(BiometricVaultStatus.available);
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

Future<
  ({
    ConnectionController controller,
    _ScriptedChannel channel,
    List<_ScriptedChannel> channels,
  })
>
_connect({Completer<void>? reconnectGate}) async {
  final channels = <_ScriptedChannel>[];
  final controller = ConnectionController(
    TrueNasJsonRpcClient(
      connector: (_) async {
        if (channels.isNotEmpty && reconnectGate != null) {
          await reconnectGate.future;
        }
        final channel = _ScriptedChannel();
        channels.add(channel);
        return channel;
      },
    ),
    _StubSavedServerRepository(),
    automaticReconnectDelays: const [],
  );
  await controller.connect(
    _profile,
    const ApiKeyCredential(username: 'admin', apiKey: 'k'),
  );
  return (controller: controller, channel: channels.single, channels: channels);
}

Widget _shell(ConnectionController controller) => ProviderScope(
  overrides: [connectionControllerProvider.overrideWith((ref) => controller)],
  // AppShell reads AppLocalizations, so the harness must supply the same
  // delegates the real app wires up.
  //
  // The banner is no longer part of the shell: it is mounted app-wide from
  // `MaterialApp.router`'s builder so it also covers routes pushed on top of
  // the shell. Mirroring that here with `builder` keeps these tests exercising
  // the real arrangement rather than one that no longer exists.
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        ConnectionLostHost(child: child ?? const SizedBox.shrink()),
    home: const AppShell(),
  ),
);

Widget _shellWithReporting(
  ConnectionController controller,
  void Function() onReportingLoad,
) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => controller),
    serverResourcesProvider.overrideWith(
      (ref) async => const ServerResources(),
    ),
    systemResourcesProvider.overrideWith(
      (ref) async => const SystemResources(),
    ),
    appsCatalogProvider.overrideWith(
      (ref) async => const AppsCatalogSnapshot(),
    ),
    overviewReportingProvider.overrideWith((ref) async {
      onReportingLoad();
      return const ReportingSnapshot();
    }),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const AppShell(),
  ),
);

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('overview reporting refreshes every second only on overview', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();
    var loads = 0;

    await tester.pumpWidget(
      _shellWithReporting(session.controller, () => loads++),
    );
    await tester.pump();
    expect(loads, 1);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(loads, 2);

    await tester.tap(find.text('Storage').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(loads, 2);
  });

  testWidgets('no banner while the connection is healthy', (tester) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();

    expect(find.text('Reconnect'), findsNothing);
    expect(find.textContaining('Lost connection'), findsNothing);
  });

  testWidgets('a dropped socket surfaces a banner naming the server', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    expect(find.text('Lost connection to nas'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
  });

  testWidgets('the banner warns that on-screen data is stale', (tester) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    // Anything on screen predates the drop; the UI must not imply it is live.
    expect(find.textContaining('last data TrueDock received'), findsOneWidget);
  });

  testWidgets('the banner does not replace navigation', (tester) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    // The user must still be able to move around while disconnected.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Storage'), findsWidgets);
  });

  testWidgets('the banner clears once the connection is restored', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();
    expect(find.text('Reconnect'), findsOneWidget);

    // The controller keeps the credential, so a retry recovers in place.
    await session.controller.reconnect();
    await tester.pump();

    expect(session.channels, hasLength(2));
    expect(session.controller.state.stage, ConnectionStage.connected);
    expect(find.text('Reconnect'), findsNothing);
  });

  testWidgets('reconnect shows progress and prevents a duplicate retry', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final gate = Completer<void>();
    final session = await _connect(reconnectGate: gate);

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('connection-reconnect-button')));
    await tester.pump();

    expect(session.controller.state.isReconnecting, isTrue);
    expect(
      find.byKey(const ValueKey('connection-reconnecting')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Reconnecting…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('connection-reconnect-button')),
      findsNothing,
      reason: 'a retry already in flight must not be submitted twice',
    );

    gate.complete();
    await tester.pumpAndSettle();

    expect(session.controller.state.isConnected, isTrue);
    expect(find.byKey(const ValueKey('connection-reconnecting')), findsNothing);
  });

  testWidgets('resuming probes the session before refreshing stale data', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();
    expect(
      session.channel.sentMethods.where((method) => method == 'system.info'),
      hasLength(1),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      session.channel.sentMethods.where((method) => method == 'system.info'),
      hasLength(2),
    );
    expect(session.controller.state.stage, ConnectionStage.connected);
  });

  testWidgets('resuming immediately reconnects a socket lost while suspended', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_shell(session.controller));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await session.channel.drop();
    await tester.pump();
    expect(session.controller.state.isConnectionLost, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(session.channels, hasLength(2));
    expect(session.controller.state.stage, ConnectionStage.connected);
  });

  testWidgets(
    'resume keeps stale data quiet for seven seconds before showing the banner',
    (tester) async {
      _usePhoneSurface(tester);
      final reconnectGate = Completer<void>();
      final session = await _connect(reconnectGate: reconnectGate);

      await tester.pumpWidget(_shell(session.controller));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await session.channel.drop();
      await tester.pump();
      expect(session.controller.state.isConnectionLost, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.textContaining('Lost connection'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 6, milliseconds: 999));
      expect(find.textContaining('Lost connection'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Lost connection to nas'), findsOneWidget);
      expect(find.text('Reconnecting…'), findsOneWidget);

      reconnectGate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Lost connection'), findsNothing);
      expect(session.controller.state.isConnected, isTrue);
    },
  );
}
