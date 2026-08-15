import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/diagnostics/diagnostics_controller.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/core/security/tls_certificate_service.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/settings/presentation/app_settings_screen.dart';
import 'package:true_dock/features/settings/presentation/device_data_reset_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _Vault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.available);
  @override
  Future<void> delete(ServerProfile profile) async {}
  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}
  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
}

class _SettingsController extends ConnectionController {
  _SettingsController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _Vault()));

  String? configuredPassword;
  (String, bool)? biometricChange;
  (String, String)? passwordChange;

  void showConnectedServer(ServerProfile profile) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: profile,
    );
  }

  @override
  Future<void> configureAppPassword(String password) async {
    configuredPassword = password;
  }

  @override
  Future<void> changeAppPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    passwordChange = (currentPassword, newPassword);
  }

  @override
  Future<void> setBiometricUnlockEnabled({
    required String appPassword,
    required bool enabled,
  }) async {
    biometricChange = (appPassword, enabled);
  }
}

class _CertificateInspector implements TlsCertificateInspector {
  const _CertificateInspector(this.identity);

  final TlsCertificateIdentity identity;

  @override
  Future<TlsCertificateIdentity> inspect(Uri uri) async => identity;
}

Widget _screen(
  _SettingsController controller, {
  required bool passwordConfigured,
  double textScale = 1,
  TlsCertificateInspector? certificateInspector,
}) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => controller),
    savedServersProvider.overrideWith((ref) async => const []),
    appPasswordConfiguredProvider.overrideWith(
      (ref) async => passwordConfigured,
    ),
    biometricVaultAvailabilityProvider.overrideWith(
      (ref) async =>
          const BiometricVaultAvailability(BiometricVaultStatus.available),
    ),
    biometricUnlockEnabledProvider.overrideWith((ref) async => false),
    if (certificateInspector != null)
      tlsCertificateInspectorProvider.overrideWithValue(certificateInspector),
  ],
  child: MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const Scaffold(body: AppSettingsScreen()),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('reduced animations can be changed from app settings', (
    tester,
  ) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: false));
    await tester.pumpAndSettle();

    final setting = find.byKey(const ValueKey('reduce-animations-setting'));
    expect(setting, findsOneWidget);
    expect(tester.widget<SwitchListTile>(setting).value, isFalse);

    await tester.tap(setting);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(setting).value, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'accessibility.reduce_animations',
      ),
      isTrue,
    );
  });

  testWidgets('anonymous diagnostics can be opted out in app settings', (
    tester,
  ) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: false));
    await tester.pumpAndSettle();

    final setting = find.byKey(const ValueKey('anonymous-diagnostics-setting'));
    await tester.scrollUntilVisible(
      setting,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SwitchListTile>(setting).value, isTrue);

    await tester.tap(setting);
    await tester.pumpAndSettle();

    // Turning diagnostics off requires an explicit confirmation dialog.
    expect(find.text('익명 진단 정보 수집을 끄시겠습니까?'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(setting).value, isTrue);

    await tester.tap(find.widgetWithText(FilledButton, '끄기'));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(setting).value, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        DiagnosticsController.preferenceKey,
      ),
      isFalse,
    );
  });

  testWidgets(
    'anonymous diagnostics opt-out can be cancelled from the confirmation',
    (tester) async {
      final controller = _SettingsController();
      await tester.pumpWidget(_screen(controller, passwordConfigured: false));
      await tester.pumpAndSettle();

      final setting = find.byKey(
        const ValueKey('anonymous-diagnostics-setting'),
      );
      await tester.scrollUntilVisible(
        setting,
        160,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(setting);
      await tester.pumpAndSettle();

      expect(find.text('익명 진단 정보 수집을 끄시겠습니까?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(setting).value, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          DiagnosticsController.preferenceKey,
        ),
        isNull,
      );
    },
  );

  testWidgets('app PIN setting creates a PIN from its switch', (tester) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: false));
    await tester.pumpAndSettle();

    final passwordSwitch = find.byKey(const ValueKey('app-password-setting'));
    expect(passwordSwitch, findsOneWidget);
    expect(tester.widget<SwitchListTile>(passwordSwitch).value, isFalse);
    await tester.tap(passwordSwitch);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('settings-app-password')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('settings-app-password-confirm')),
      '123456',
    );
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    expect(controller.configuredPassword, '123456');
  });

  testWidgets('biometric switch verifies the app PIN before enabling', (
    tester,
  ) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: true));
    await tester.pumpAndSettle();

    final biometricSwitch = find.byKey(
      const ValueKey('biometric-unlock-setting'),
    );
    expect(tester.widget<SwitchListTile>(biometricSwitch).onChanged, isNotNull);
    await tester.tap(biometricSwitch);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-app-password')),
      '123456',
    );
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    expect(controller.biometricChange, ('123456', true));
  });

  testWidgets('configured app PIN can be changed', (tester) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('change-app-password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('current-app-password')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-app-password')),
      '654321',
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-app-password-confirm')),
      '654321',
    );
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    expect(controller.passwordChange, ('123456', '654321'));
  });

  testWidgets('device data reset requires typed confirmation', (tester) async {
    final controller = _SettingsController();
    await tester.pumpWidget(_screen(controller, passwordConfigured: false));
    await tester.pumpAndSettle();

    final reset = find.byKey(const ValueKey('reset-all-device-data'));
    await tester.scrollUntilVisible(
      reset,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();

    final action = find.widgetWithText(FilledButton, '모든 데이터 초기화');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    final confirmationField = find.byKey(
      const ValueKey('reset-all-device-data-confirmation'),
    );
    final prompt = tester.widget<Text>(find.textContaining('계속하려면 코드')).data!;
    final code = RegExp(
      r'[A-Z0-9]{4}-[A-Z0-9]{4}',
    ).firstMatch(prompt)?.group(0);
    expect(code, matches(RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$')));
    await tester.enterText(
      find.descendant(of: confirmationField, matching: find.byType(TextField)),
      code!,
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
  });

  testWidgets('device reset page scrolls without overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(750, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final controller = _SettingsController();
    await tester.pumpWidget(
      _screen(controller, passwordConfigured: false, textScale: 1.8),
    );
    await tester.pumpAndSettle();

    final reset = find.byKey(const ValueKey('reset-all-device-data'));
    await tester.scrollUntilVisible(
      reset,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(find.byType(DeviceDataResetScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trusted certificate opens its current certificate details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const fingerprint =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final controller = _SettingsController();
    controller.showConnectedServer(
      ServerProfile(
        name: '테스트 NAS',
        baseUri: Uri.parse('https://nas.example.test'),
        pinnedCertificateSha256: fingerprint,
      ),
    );
    final identity = TlsCertificateIdentity(
      sha256: fingerprint,
      subject: 'CN=nas.example.test',
      issuer: 'CN=Example CA',
      validFrom: DateTime.utc(2026, 1, 1),
      validTo: DateTime.utc(2027, 1, 1),
      isTrustedBySystem: true,
    );

    await tester.pumpWidget(
      _screen(
        controller,
        passwordConfigured: false,
        certificateInspector: _CertificateInspector(identity),
      ),
    );
    await tester.pumpAndSettle();

    final certificateRow = find.byKey(
      const ValueKey('trusted-certificate-details'),
    );
    await tester.scrollUntilVisible(
      certificateRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(certificateRow);
    await tester.pumpAndSettle();

    expect(find.text('TrueDock이 신뢰한 인증서와 일치함'), findsOneWidget);
    expect(find.text('CN=nas.example.test'), findsOneWidget);
    expect(find.text('CN=Example CA'), findsOneWidget);
    expect(find.text('운영 체제에서도 신뢰함'), findsOneWidget);
    expect(find.text(identity.formattedSha256), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trusted certificate reports a changed server certificate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = _SettingsController();
    controller.showConnectedServer(
      ServerProfile(
        name: '테스트 NAS',
        baseUri: Uri.parse('https://nas.example.test'),
        pinnedCertificateSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
    );
    final identity = TlsCertificateIdentity(
      sha256:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      subject: 'CN=changed.example.test',
      issuer: 'CN=Unknown CA',
      validFrom: DateTime.utc(2026, 1, 1),
      validTo: DateTime.utc(2027, 1, 1),
      isTrustedBySystem: false,
    );

    await tester.pumpWidget(
      _screen(
        controller,
        passwordConfigured: false,
        certificateInspector: _CertificateInspector(identity),
      ),
    );
    await tester.pumpAndSettle();
    final certificateRow = find.byKey(
      const ValueKey('trusted-certificate-details'),
    );
    await tester.scrollUntilVisible(
      certificateRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(certificateRow);
    await tester.pumpAndSettle();

    expect(find.text('TrueDock이 신뢰한 인증서와 일치하지 않음'), findsOneWidget);
    expect(find.text('TrueDock이 이 서버에 한해 신뢰함'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
