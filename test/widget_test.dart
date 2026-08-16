import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/diagnostics/diagnostics_backend.dart';
import 'package:true_dock/core/diagnostics/diagnostics_controller.dart';
import 'package:true_dock/core/navigation/app_router.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connect_server_screen.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _NoopVault implements CredentialVault {
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

class _MutableConnectionController extends ConnectionController {
  _MutableConnectionController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _NoopVault()));

  void setConnected() {
    state = const NasConnectionState(stage: ConnectionStage.connected);
  }

  void setDisconnected() {
    state = const NasConnectionState(stage: ConnectionStage.disconnected);
  }
}

class _ConfiguredDiagnosticsBackend implements DiagnosticsBackend {
  @override
  bool get isConfigured => true;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens registration instead of an empty shell', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Register TrueNAS server'), findsOneWidget);
    expect(find.text('TrueNAS Server Address'), findsOneWidget);
    expect(find.textContaining('WSS /api/current'), findsNothing);
    expect(find.text('Connect server'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    final methodSelector = tester.widget<SegmentedButton<AuthMethod>>(
      find.byType(SegmentedButton<AuthMethod>),
    );
    expect(methodSelector.segments.map((segment) => segment.value), [
      AuthMethod.password,
      AuthMethod.apiKey,
    ]);
    expect(methodSelector.selected, {AuthMethod.password});

    final usernameField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(2),
    );
    expect(usernameField.controller?.text, isEmpty);
  });

  testWidgets(
    'launch does not show a diagnostics disclosure dialog even when configured',
    (tester) async {
      final container = _testContainer(
        diagnosticsBackend: _ConfiguredDiagnosticsBackend(),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TrueDockApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Diagnostics default to enabled silently; the app only confirms when
      // the user opts out from Settings, never as a launch interruption.
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offers saved sign-ins without showing the empty shell', (
    tester,
  ) async {
    final saved = SavedServer(
      profile: ServerProfile(
        name: 'Home NAS',
        baseUri: Uri.parse('https://nas.local'),
      ),
      username: 'admin',
      authMethod: AuthMethod.apiKey,
      hasSavedCredential: true,
    );

    await tester.pumpWidget(_testApp(savedServers: [saved]));
    await tester.pumpAndSettle();

    expect(find.text('Choose a server'), findsOneWidget);
    expect(find.text('Saved servers'), findsOneWidget);
    expect(find.text('Home NAS'), findsOneWidget);
    expect(find.text('Register another server'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('keeps add-server registration as a separate closeable page', (
    tester,
  ) async {
    await tester.pumpWidget(_registrationPage());
    await tester.pumpAndSettle();

    expect(find.text('Add TrueNAS server'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('registered server asks only for its missing credential', (
    tester,
  ) async {
    final registered = SavedServer(
      profile: ServerProfile(
        name: 'Home NAS',
        baseUri: Uri.parse('https://nas.local'),
      ),
      username: 'alice',
      authMethod: AuthMethod.password,
      hasSavedCredential: false,
    );
    await tester.pumpWidget(_testApp(savedServers: [registered]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign in required'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Home NAS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Username: alice'), findsOneWidget);
    expect(find.text('Sign in to Home NAS'), findsOneWidget);
    expect(find.text('Add TrueNAS server'), findsNothing);
    expect(find.text('Server name'), findsNothing);
    expect(find.text('TrueNAS Server Address'), findsNothing);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('restored authentication route ignores serialized extra data', (
    tester,
  ) async {
    final registered = SavedServer(
      profile: ServerProfile(
        name: 'Home NAS',
        baseUri: Uri.parse('https://nas.local'),
      ),
      username: 'alice',
      authMethod: AuthMethod.password,
      hasSavedCredential: false,
    );
    final container = _testContainer(savedServers: [registered]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueDockApp(),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(appRouterProvider)
        .go(
          '/servers/auth/${registered.profile.id}',
          extra: registered.toJson(),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sign in to Home NAS'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Server name'), findsNothing);
    expect(find.text('TrueNAS Server Address'), findsNothing);
    expect(find.text('Add TrueNAS server'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved login uses login status and links forgotten PIN recovery',
    (tester) async {
      final saved = SavedServer(
        profile: ServerProfile(
          name: 'Home NAS',
          baseUri: Uri.parse('https://nas.local'),
        ),
        username: 'alice',
        authMethod: AuthMethod.password,
        hasSavedCredential: true,
        credentialProtection: CredentialProtection.appPassword,
      );
      await tester.pumpWidget(_testApp(savedServers: [saved]));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Home NAS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Signing in…'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();

      expect(find.text('Erase all TrueDock data'), findsOneWidget);
      expect(find.text('Erase all data from this device?'), findsOneWidget);
      expect(find.text('Server name'), findsNothing);
      expect(find.text('TrueNAS Server Address'), findsNothing);
    },
  );

  testWidgets('disconnected admin deep links return to registration', (
    tester,
  ) async {
    final container = _testContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueDockApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/system/activity');
    await tester.pumpAndSettle();

    expect(find.text('Register TrueNAS server'), findsOneWidget);
    expect(find.byType(SystemAdministrationScreen), findsNothing);
  });

  testWidgets('losing a session evicts an open administration route', (
    tester,
  ) async {
    final controller = _MutableConnectionController()..setConnected();
    final container = _testContainer(controller: controller);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TrueDockApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/system/activity');
    await tester.pumpAndSettle();
    expect(find.byType(SystemAdministrationScreen), findsOneWidget);

    controller.setDisconnected();
    await tester.pumpAndSettle();

    expect(find.byType(SystemAdministrationScreen), findsNothing);
    expect(find.text('Register TrueNAS server'), findsOneWidget);
  });
}

Widget _testApp({List<SavedServer> savedServers = const []}) {
  return ProviderScope(
    overrides: [
      biometricVaultAvailabilityProvider.overrideWith(
        (ref) async =>
            const BiometricVaultAvailability(BiometricVaultStatus.unsupported),
      ),
      savedServersProvider.overrideWith((ref) async => savedServers),
    ],
    child: const TrueDockApp(),
  );
}

Widget _registrationPage() => ProviderScope(
  overrides: [
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async =>
          const BiometricVaultAvailability(BiometricVaultStatus.unsupported),
    ),
    savedServersProvider.overrideWith((ref) async => const []),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ServerRegistrationScreen(),
  ),
);

ProviderContainer _testContainer({
  ConnectionController? controller,
  DiagnosticsBackend? diagnosticsBackend,
  List<SavedServer> savedServers = const [],
}) => ProviderContainer(
  overrides: [
    if (controller != null)
      connectionControllerProvider.overrideWith((ref) => controller),
    if (diagnosticsBackend != null)
      diagnosticsBackendProvider.overrideWithValue(diagnosticsBackend),
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async =>
          const BiometricVaultAvailability(BiometricVaultStatus.unsupported),
    ),
    savedServersProvider.overrideWith((ref) async => savedServers),
  ],
);
