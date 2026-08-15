import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/app_password_vault.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/core/security/tls_certificate_service.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connect_server_screen.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _NoopBiometricVault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(
        BiometricVaultStatus.unsupported,
        canUseAppPassword: true,
      );

  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}

  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;

  @override
  Future<void> delete(ServerProfile profile) async {}
}

class _NoopAppPasswordVault implements AppPasswordCredentialVault {
  @override
  Future<bool> isConfigured() async => false;

  @override
  Future<void> configurePassword(String password) async {}

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    Map<ServerProfile, AuthCredential> credentials,
  ) async {}

  @override
  Future<void> verifyPassword(String password) async {}

  @override
  Future<void> save(
    ServerProfile profile,
    AuthCredential credential,
    String password,
  ) async {}

  @override
  Future<AuthCredential?> unlock(
    ServerProfile profile,
    String password,
  ) async => null;

  @override
  Future<void> delete(ServerProfile profile) async {}

  @override
  Future<void> clearAll() async {}
}

class _AppPasswordController extends ConnectionController {
  _AppPasswordController({this.configured = false, this.certificate})
    : super(
        TrueNasJsonRpcClient(),
        SavedServerRepository(
          vault: _NoopBiometricVault(),
          appPasswordVault: _NoopAppPasswordVault(),
        ),
      );

  final bool configured;
  final TlsCertificateIdentity? certificate;
  final List<String> verified = [];
  String? acceptedPassword;
  bool acceptedBiometricUnlock = false;
  int clears = 0;

  void showConnecting() {
    state = const NasConnectionState(stage: ConnectionStage.connecting);
  }

  @override
  Future<bool> isAppPasswordConfigured() async => configured;

  @override
  Future<void> verifyAppPassword(String password) async {
    verified.add(password);
    if (password != '123456') {
      throw const AppPasswordVaultException('wrong PIN');
    }
  }

  @override
  Future<void> connect(
    ServerProfile profile,
    AuthCredential credential, {
    bool keepSignedIn = false,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {
    acceptedPassword = appPassword;
    acceptedBiometricUnlock = enableBiometricUnlock;
    if (certificate case final certificate?) {
      state = NasConnectionState(
        stage: ConnectionStage.awaitingCertificateTrust,
        profile: profile,
        certificate: certificate,
      );
    }
  }

  @override
  Future<void> switchToSavedWithAppPassword(
    SavedServer server,
    String appPassword,
  ) async {
    acceptedPassword = appPassword;
  }

  @override
  Future<void> clearAllAppPasswordCredentials() async {
    clears++;
  }
}

final _saved = SavedServer(
  profile: ServerProfile(
    name: 'Home NAS',
    baseUri: Uri.parse('https://nas.local'),
  ),
  username: 'admin',
  authMethod: AuthMethod.password,
  hasSavedCredential: true,
  credentialProtection: CredentialProtection.appPassword,
);

Widget _screen(
  _AppPasswordController controller, {
  List<SavedServer> servers = const [],
  bool? appPasswordConfigured,
  double textScale = 1,
  Locale locale = const Locale('en'),
  BiometricVaultAvailability availability = const BiometricVaultAvailability(
    BiometricVaultStatus.unsupported,
    canUseAppPassword: true,
  ),
}) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => controller),
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async => availability,
    ),
    appPasswordConfiguredProvider.overrideWith(
      (ref) async => appPasswordConfigured ?? controller.configured,
    ),
    savedServersProvider.overrideWith((ref) async => servers),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const ServerRegistrationScreen(canClose: false),
    ),
  ),
);

Widget _savedServerEntry(_AppPasswordController controller) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => controller),
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async => const BiometricVaultAvailability(
        BiometricVaultStatus.unsupported,
        canUseAppPassword: true,
      ),
    ),
    savedServersProvider.overrideWith((ref) async => [_saved]),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ServerRegistrationScreen(initialServer: _saved),
  ),
);

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _fillRegistration(
  WidgetTester tester, {
  bool selectKeepSignedIn = true,
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Home NAS');
  await tester.enterText(fields.at(1), 'https://nas.local');
  await tester.enterText(fields.at(2), 'admin');
  await tester.enterText(fields.at(3), 'server password');
  if (selectKeepSignedIn) {
    final keepSignedIn = find.text('Keep me signed in');
    await tester.ensureVisible(keepSignedIn);
    await tester.tap(keepSignedIn);
    await tester.pump();
  }
  final connect = find.text('Connect server');
  await tester.ensureVisible(connect);
  final button = tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Connect server'),
  );
  button.onPressed!();
  await tester.pumpAndSettle();
}

void main() {
  TlsCertificateIdentity certificate({required bool trusted}) =>
      TlsCertificateIdentity(
        sha256: 'aa' * 32,
        subject: '/CN=nas.local',
        issuer: '/CN=TrueNAS',
        validFrom: DateTime.utc(2026),
        validTo: DateTime.utc(2030),
        isTrustedBySystem: trusted,
      );

  testWidgets('trusted certificate is always shown before connecting', (
    tester,
  ) async {
    final controller = _AppPasswordController(
      certificate: certificate(trusted: true),
    );
    await tester.pumpWidget(_screen(controller));
    await tester.pumpAndSettle();
    await _fillRegistration(tester, selectKeepSignedIn: false);

    expect(find.text('Verify server certificate'), findsOneWidget);
    expect(find.text('Verify and connect'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('untrusted-certificate-acknowledgement')),
      findsNothing,
    );
  });

  testWidgets('untrusted certificate requires explicit acknowledgement', (
    tester,
  ) async {
    final controller = _AppPasswordController(
      certificate: certificate(trusted: false),
    );
    await tester.pumpWidget(_screen(controller));
    await tester.pumpAndSettle();
    await _fillRegistration(tester, selectKeepSignedIn: false);

    final acknowledgement = find.byKey(
      const ValueKey('untrusted-certificate-acknowledgement'),
    );
    expect(acknowledgement, findsOneWidget);
    var continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Trust and connect'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.ensureVisible(acknowledgement);
    await tester.tap(acknowledgement);
    await tester.pump();
    continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Trust and connect'),
    );
    expect(continueButton.onPressed, isNotNull);
  });

  testWidgets('first use creates one global TrueDock PIN twice', (
    tester,
  ) async {
    final controller = _AppPasswordController();
    await tester.pumpWidget(_screen(controller));
    await tester.pumpAndSettle();

    expect(
      find.text('Protect the saved credential with a separate TrueDock PIN.'),
      findsOneWidget,
    );
    await _fillRegistration(tester);

    expect(find.text('Create TrueDock PIN'), findsOneWidget);
    expect(find.text('TrueDock PIN'), findsOneWidget);
    expect(find.text('Confirm TrueDock PIN'), findsOneWidget);
  });

  testWidgets('registration hero uses the TrueDock foreground logo and title', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(_AppPasswordController()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('registration-foreground-logo')),
      findsOneWidget,
    );
    expect(find.text('Dock your TrueNAS'), findsOneWidget);
  });

  testWidgets('all registration inputs are disabled while connecting', (
    tester,
  ) async {
    final controller = _AppPasswordController()..showConnecting();
    await tester.pumpWidget(
      _screen(
        controller,
        availability: const BiometricVaultAvailability(
          BiometricVaultStatus.available,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.enabled, isFalse);
    }
    expect(
      tester
          .widget<SegmentedButton<AuthMethod>>(
            find.byType(SegmentedButton<AuthMethod>),
          )
          .onSelectionChanged,
      isNull,
    );
    for (final toggle in tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    )) {
      expect(toggle.onChanged, isNull);
    }
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.visibility_outlined),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Connecting securely…'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('an existing global PIN is verified before connecting', (
    tester,
  ) async {
    final controller = _AppPasswordController(configured: true);
    await tester.pumpWidget(_screen(controller));
    await tester.pumpAndSettle();
    await _fillRegistration(tester);

    expect(find.text('Enter TrueDock PIN'), findsOneWidget);
    expect(find.text('Confirm TrueDock PIN'), findsNothing);
    await tester.enterText(find.byType(TextFormField).last, '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('The TrueDock PIN is incorrect.'), findsOneWidget);
    expect(controller.acceptedPassword, isNull);

    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(controller.acceptedPassword, '123456');
    expect(controller.verified, ['654321', '123456']);
  });

  testWidgets(
    'server registration reuses the PIN state shown in App Settings',
    (tester) async {
      // Reproduces a provider/controller refresh race: App Settings already
      // reports a configured PIN while the registration controller still has
      // an older false snapshot.
      final controller = _AppPasswordController();
      await tester.pumpWidget(_screen(controller, appPasswordConfigured: true));
      await tester.pumpAndSettle();
      await _fillRegistration(tester);

      expect(find.text('Enter TrueDock PIN'), findsOneWidget);
      expect(find.text('Create TrueDock PIN'), findsNothing);
      expect(find.text('Confirm TrueDock PIN'), findsNothing);

      await tester.enterText(find.byType(TextFormField).last, '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(controller.acceptedPassword, '123456');
    },
  );

  testWidgets('available biometrics are an optional app-password unlock', (
    tester,
  ) async {
    final controller = _AppPasswordController();
    await tester.pumpWidget(
      _screen(
        controller,
        availability: const BiometricVaultAvailability(
          BiometricVaultStatus.available,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biometric Unlock'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    await tester.ensureVisible(find.text('Keep me signed in'));
    await tester.tap(find.text('Keep me signed in'));
    await tester.pump();
    await tester.ensureVisible(find.text('Biometric Unlock'));
    await tester.tap(find.text('Biometric Unlock'));
    await _fillRegistration(tester, selectKeepSignedIn: false);
    await tester.enterText(find.byType(TextFormField).at(4), '123456');
    await tester.enterText(find.byType(TextFormField).at(5), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(controller.acceptedPassword, '123456');
    expect(controller.acceptedBiometricUnlock, isTrue);
  });

  testWidgets('forgotten PIN warns that every protected sign-in clears', (
    tester,
  ) async {
    final controller = _AppPasswordController(configured: true);
    await tester.pumpWidget(_savedServerEntry(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();

    expect(find.text('Clear saved sign-in?'), findsOneWidget);
    expect(
      find.textContaining('Every sign-in protected by the TrueDock PIN'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Clear protected sign-ins'),
    );
    await tester.pumpAndSettle();

    expect(controller.clears, 1);
  });

  testWidgets('creation dialog survives Korean text at 2x scale', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final controller = _AppPasswordController();
    await tester.pumpWidget(
      _screen(controller, textScale: 2, locale: const Locale('ko')),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Home NAS');
    await tester.enterText(fields.at(1), 'https://nas.local');
    await tester.enterText(fields.at(2), 'admin');
    await tester.enterText(fields.at(3), 'server password');
    await tester.ensureVisible(find.text('로그인 유지'));
    await tester.tap(find.text('로그인 유지'));
    await tester.pump();
    await tester.ensureVisible(find.text('서버 연결'));
    await tester.tap(find.text('서버 연결'));
    await tester.pumpAndSettle();

    expect(find.text('TrueDock PIN 생성'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unlock dialog meets touch, label, and contrast guidelines', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final handle = tester.ensureSemantics();
    final controller = _AppPasswordController(configured: true);
    await tester.pumpWidget(_savedServerEntry(controller));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
