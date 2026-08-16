import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/connection/presentation/connect_server_screen.dart';
import 'package:true_dock/features/connection/presentation/server_entry_screen.dart';
import 'package:true_dock/features/shell/presentation/app_shell.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The gate that decides whether the shell is on screen at all.
///
/// The banner tests in `app_shell_connection_banner_test.dart` mount `AppShell`
/// directly, so they prove the banner renders *given* the shell. They cannot
/// see this: `ServerEntryScreen` used to return the shell only while
/// `isConnected`, so the instant a socket dropped it swapped the whole shell -
/// banner included - for the registration screen. Every banner test still
/// passed while the banner was unreachable in the running app. A real server
/// restart is what surfaced it.
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

class _PasswordSwitchController extends ConnectionController {
  _PasswordSwitchController()
    : super(TrueNasJsonRpcClient(), _StubSavedServerRepository());

  final List<String> passwords = [];
  Completer<void>? switchCompleter;

  @override
  Future<void> verifyAppPassword(String password) async {
    if (password != '123456') {
      throw StateError('wrong PIN');
    }
  }

  @override
  Future<void> switchToSavedWithAppPassword(
    SavedServer server,
    String appPassword,
  ) async {
    passwords.add(appPassword);
    await switchCompleter?.future;
  }
}

class _BiometricSwitchController extends ConnectionController {
  _BiometricSwitchController()
    : super(TrueNasJsonRpcClient(), _StubSavedServerRepository());

  final switchCompleter = Completer<void>();

  @override
  Future<bool> switchToSavedWithBiometrics(
    SavedServer server, {
    void Function()? onCredentialUnlocked,
  }) async {
    onCredentialUnlocked?.call();
    await switchCompleter.future;
    return true;
  }
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

Widget _entry(ConnectionController controller) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => controller),
    // The registration screen watches both of these, and unstubbed they reach
    // platform channels that never answer under `flutter test`, so the pump
    // hangs rather than failing on anything to do with the screen.
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async =>
          const BiometricVaultAvailability(BiometricVaultStatus.unsupported),
    ),
    savedServersProvider.overrideWith((ref) async => const []),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ServerEntryScreen(),
  ),
);

Widget _serverPicker(
  ConnectionController controller,
  SavedServer server, {
  Locale? locale,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => ServerSelectionScreen(servers: [server]),
      ),
      GoRoute(
        path: '/servers/auth/:serverId',
        builder: (_, state) => SavedServerAuthenticationScreen(
          serverId: state.pathParameters['serverId'] ?? '',
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      connectionControllerProvider.overrideWith((ref) => controller),
      savedServersProvider.overrideWith((ref) async => [server]),
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _openSavedServer(WidgetTester tester) async {
  await tester.tap(find.byKey(ValueKey('server-${_profile.id}')));
  // First complete the route transition, then give the authentication page's
  // post-frame callback a frame to open the PIN dialog or start biometrics.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('a live session shows the shell', (tester) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_entry(session.controller));
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('a dropped session keeps the shell so the banner can show', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_entry(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    // The regression: the shell was replaced wholesale the instant the socket
    // died, so a restart read as being signed out.
    //
    // Only the gate is asserted here. The banner itself is mounted app-wide by
    // `ConnectionLostHost` above the router - deliberately not by this harness -
    // so asserting its text from here would be checking a widget this file does
    // not build. `connection_lost_route_test` covers the banner and the app's
    // wiring of it.
    expect(
      find.byType(AppShell),
      findsOneWidget,
      reason: 'a recoverable drop must not tear down the shell',
    );
  });

  testWidgets('navigation survives a dropped session', (tester) async {
    _usePhoneSurface(tester);
    final session = await _connect();

    await tester.pumpWidget(_entry(session.controller));
    await tester.pump();
    await session.channel.drop();
    await tester.pump();

    // Being dropped back to registration also meant losing the whole nav.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('no session at all still shows registration', (tester) async {
    _usePhoneSurface(tester);
    final controller = ConnectionController(
      TrueNasJsonRpcClient(connector: (_) async => _ScriptedChannel()),
      _StubSavedServerRepository(),
    );

    await tester.pumpWidget(_entry(controller));
    // Not pumpAndSettle: the registration screen renders progress indicators
    // whose animation never ends, so settling would time out.
    await tester.pump();

    // Never connected is not the same as dropped: there is nothing to retry
    // and no stale data to label, so the shell must stay away.
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('saved-server password dialog owns its controller until exit', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final controller = _PasswordSwitchController();
    final server = SavedServer(
      profile: _profile,
      username: 'admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
      credentialProtection: CredentialProtection.appPassword,
    );
    await tester.pumpWidget(_serverPicker(controller, server));
    await tester.pumpAndSettle();

    // Exercise both dismissal paths; the old implementation disposed the
    // controller as soon as pop started, while TextField still rebuilt during
    // the route's exit animation.
    await _openSavedServer(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await _openSavedServer(tester);
    await tester.enterText(
      find.byKey(const ValueKey('saved-server-app-password')),
      '123456',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.passwords, ['123456']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incorrect app password is localized inside the dialog', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final controller = _PasswordSwitchController();
    final server = SavedServer(
      profile: _profile,
      username: 'admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
      credentialProtection: CredentialProtection.appPassword,
    );
    await tester.pumpWidget(
      _serverPicker(controller, server, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();

    await _openSavedServer(tester);
    await tester.enterText(
      find.byKey(const ValueKey('saved-server-app-password')),
      '654321',
    );
    await tester.tap(find.text('계속'));
    await tester.pump();

    expect(find.text('TrueDock PIN이 올바르지 않습니다.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows authenticated status while server sign-in is pending', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final controller = _PasswordSwitchController()
      ..switchCompleter = Completer<void>();
    final server = SavedServer(
      profile: _profile,
      username: 'admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
      credentialProtection: CredentialProtection.appPassword,
    );
    await tester.pumpWidget(
      _serverPicker(controller, server, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();

    await _openSavedServer(tester);
    await tester.enterText(
      find.byKey(const ValueKey('saved-server-app-password')),
      '123456',
    );
    await tester.tap(find.text('계속'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('nas에 로그인 중…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('authenticated-signing-in')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows authenticated status after Face ID unlock succeeds', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final controller = _BiometricSwitchController();
    final server = SavedServer(
      profile: _profile,
      username: 'admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
      credentialProtection: CredentialProtection.appPasswordWithBiometric,
    );
    await tester.pumpWidget(
      _serverPicker(controller, server, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();

    await _openSavedServer(tester);

    expect(find.text('nas에 로그인 중…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('authenticated-signing-in')),
      findsOneWidget,
    );
  });

  // Signing out is deliberately not driven through the widget here. A real
  // `disconnect()` awaits an `auth.logout` round trip, which deadlocks against
  // the scripted socket inside `flutter test`. The behaviour is covered where
  // it belongs: `connection_loss_controller_test` proves a deliberate
  // disconnect lands on `disconnected` rather than `connectionLost`, and the
  // "no session at all" case above proves that stage shows registration - so
  // the two together already pin that sign-out leaves the shell.
}
