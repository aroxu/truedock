import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';
import 'package:true_dock/features/apps/presentation/apps_catalog_provider.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/reporting_provider.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/shell/presentation/app_shell.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Google Play requires large-screen support to be genuine: the app must use
/// the extra space instead of stretching a phone layout, and it must survive
/// both orientations on 7" and 10" tablets.
///
/// These sizes are the logical (dp) resolutions of the two emulators used for
/// manual verification:
///   - 7 inch    : 800x1280 @213dpi  -> 600 x 960 dp
///   - 10.95 inch: 2560x1600 @320dpi -> 1280 x 800 dp
const _tablet7Portrait = Size(600, 960);
const _tablet7Landscape = Size(960, 600);
const _tablet10Portrait = Size(800, 1280);
const _tablet10Landscape = Size(1280, 800);

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

Future<ConnectionController> _connect() async {
  final controller = ConnectionController(
    TrueNasJsonRpcClient(connector: (_) async => _ScriptedChannel()),
    _StubSavedServerRepository(),
    automaticReconnectDelays: const [],
  );
  await controller.connect(
    _profile,
    const ApiKeyCredential(username: 'admin', apiKey: 'k'),
  );
  return controller;
}

Widget _shell(ConnectionController controller) => ProviderScope(
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
    overviewReportingProvider.overrideWith(
      (ref) async => const ReportingSnapshot(),
    ),
  ],
  // Overview links to pushed routes, so the shell needs a real router in
  // context even though these tests never navigate away from it.
  child: MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AppShell()),
        GoRoute(
          path: '/servers/new',
          builder: (_, _) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/reporting/:metric',
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
    ),
  ),
);

/// Sizes the test surface in logical pixels, matching how a tablet reports its
/// window to Flutter.
void _useSurface(WidgetTester tester, Size logicalSize) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
}

const _surfaces = <String, Size>{
  '7-inch portrait': _tablet7Portrait,
  '7-inch landscape': _tablet7Landscape,
  '10-inch portrait': _tablet10Portrait,
  '10-inch landscape': _tablet10Landscape,
};

void main() {
  for (final entry in _surfaces.entries) {
    testWidgets('every destination fits on ${entry.key}', (tester) async {
      _useSurface(tester, entry.value);
      final controller = await _connect();
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();

      // Visit each of the six destinations. A RenderFlex overflow throws
      // during layout, so an exception here means that tab does not fit.
      // Unselected destination icons are stable across both the bottom bar
      // and the rail, so tapping them exercises the same six screens without
      // depending on either widget's internal structure.
      const icons = <IconData>[
        Icons.space_dashboard_outlined,
        Icons.storage_outlined,
        Icons.shield_outlined,
        Icons.widgets_outlined,
        Icons.tune_outlined,
        Icons.settings_outlined,
      ];
      for (final icon in icons) {
        final target = find.byIcon(icon);
        if (target.evaluate().isEmpty) continue;
        await tester.tap(target.first);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'a destination overflowed on this surface',
        );
      }
    });
  }

  for (final entry in _surfaces.entries) {
    testWidgets('${entry.key} uses the tablet navigation rail', (tester) async {
      _useSurface(tester, entry.value);
      final controller = await _connect();
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  }

  testWidgets('compact phone keeps the bottom navigation bar', (tester) async {
    _useSurface(tester, const Size(390, 844));
    final controller = await _connect();
    await tester.pumpWidget(_shell(controller));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('wide surfaces keep content within a readable measure', (
    tester,
  ) async {
    _useSurface(tester, _tablet10Landscape);
    final controller = await _connect();
    await tester.pumpWidget(_shell(controller));
    await tester.pumpAndSettle();

    // Overview is the default destination. Its scrolling body must not run
    // the full 1280dp width: long lines of small text across a whole tablet
    // are hard to scan, and Play reviews treat it as a stretched phone UI.
    final body = tester.getSize(find.byType(CustomScrollView).first);
    expect(
      body.width,
      lessThan(1000),
      reason: 'overview content should be constrained on a wide tablet',
    );
  });

  testWidgets(
    'every destination is centred within the readable measure on a wide tablet',
    (tester) async {
      _useSurface(tester, _tablet10Landscape);
      final controller = await _connect();
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();

      const icons = <IconData>[
        Icons.space_dashboard_outlined,
        Icons.storage_outlined,
        Icons.shield_outlined,
        Icons.widgets_outlined,
        Icons.tune_outlined,
        Icons.settings_outlined,
      ];
      for (final icon in icons) {
        final target = find.byIcon(icon);
        if (target.evaluate().isEmpty) continue;
        await tester.tap(target.first);
        await tester.pumpAndSettle();

        // Whatever scrollable the destination uses, it must sit inside the
        // shared cap rather than spanning the full window.
        final scrollables = find.byType(Scrollable);
        expect(scrollables, findsWidgets);
        final width = tester.getSize(scrollables.first).width;
        expect(
          width,
          lessThanOrEqualTo(900),
          reason: 'a destination spanned the full tablet width',
        );
      }
    },
  );
}
