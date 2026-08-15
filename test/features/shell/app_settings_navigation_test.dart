import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/device_data_reset_service.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/connection/presentation/connect_server_screen.dart';
import 'package:true_dock/features/connection/presentation/server_entry_screen.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/reporting_provider.dart';
import 'package:true_dock/features/settings/presentation/app_settings_screen.dart';
import 'package:true_dock/features/shell/presentation/app_shell.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _Vault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.unsupported);
  @override
  Future<void> delete(ServerProfile profile) async {}
  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}
  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
}

class _ConnectedController extends ConnectionController {
  _ConnectedController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _Vault())) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: ServerProfile(
        name: 'Home NAS',
        baseUri: Uri.parse('https://nas.local'),
      ),
    );
  }
}

class _Resetter implements DeviceDataResetter {
  bool cleared = false;

  @override
  Future<void> reset() async => cleared = true;
}

void main() {
  testWidgets('app and server settings live in their own sixth destination', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith(
            (ref) => _ConnectedController(),
          ),
          biometricVaultAvailabilityProvider.overrideWith(
            (ref) async => const BiometricVaultAvailability(
              BiometricVaultStatus.unsupported,
            ),
          ),
          savedServersProvider.overrideWith((ref) async => const []),
          serverResourcesProvider.overrideWith(
            (ref) async => const ServerResources(),
          ),
          systemResourcesProvider.overrideWith(
            (ref) async => const SystemResources(),
          ),
          overviewReportingProvider.overrideWith(
            (ref) async => const ReportingSnapshot(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          theme: ThemeData(platform: TargetPlatform.android),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationDestination), findsNWidgets(6));
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();
    expect(find.text('TrueDock'), findsNothing);
    expect(find.text('서버'), findsNothing);

    await tester.tap(find.byType(NavigationDestination).at(5));
    await tester.pumpAndSettle();
    expect(find.byType(AppSettingsScreen), findsOneWidget);
    expect(find.text('앱 설정'), findsWidgets);
    expect(find.text('TrueDock'), findsOneWidget);
    expect(find.text('서버'), findsOneWidget);
    expect(find.text('Home NAS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android back returns a top-level tab to Overview then exits the app',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionControllerProvider.overrideWith(
              (ref) => _ConnectedController(),
            ),
            biometricVaultAvailabilityProvider.overrideWith(
              (ref) async => const BiometricVaultAvailability(
                BiometricVaultStatus.unsupported,
              ),
            ),
            savedServersProvider.overrideWith((ref) async => const []),
            serverResourcesProvider.overrideWith(
              (ref) async => const ServerResources(),
            ),
            systemResourcesProvider.overrideWith(
              (ref) async => const SystemResources(),
            ),
            overviewReportingProvider.overrideWith(
              (ref) async => const ReportingSnapshot(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            theme: ThemeData(platform: TargetPlatform.android),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isFalse,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isTrue,
      );
      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        isEmpty,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        platformCalls.where((call) => call.method == 'SystemNavigator.pop'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'device reset immediately replaces server list with registration',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final controller = _ConnectedController();
      final resetter = _Resetter();
      final savedServer = SavedServer(
        profile: controller.state.profile!,
        username: 'admin',
        authMethod: AuthMethod.password,
        hasSavedCredential: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionControllerProvider.overrideWith((ref) => controller),
            deviceDataResetterProvider.overrideWithValue(resetter),
            biometricVaultAvailabilityProvider.overrideWith(
              (ref) async => const BiometricVaultAvailability(
                BiometricVaultStatus.unsupported,
              ),
            ),
            savedServersProvider.overrideWith(
              (ref) async => resetter.cleared ? const [] : [savedServer],
            ),
            serverResourcesProvider.overrideWith(
              (ref) async => const ServerResources(),
            ),
            systemResourcesProvider.overrideWith(
              (ref) async => const SystemResources(),
            ),
            overviewReportingProvider.overrideWith(
              (ref) async => const ReportingSnapshot(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ServerEntryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(5));
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
      final confirmationField = find.byKey(
        const ValueKey('reset-all-device-data-confirmation'),
      );
      final prompt = tester.widget<Text>(find.textContaining('계속하려면 코드')).data!;
      final code = RegExp(
        r'[A-Z0-9]{4}-[A-Z0-9]{4}',
      ).firstMatch(prompt)!.group(0)!;
      await tester.enterText(
        find.descendant(
          of: confirmationField,
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '모든 데이터 초기화'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(resetter.cleared, isTrue);
      expect(find.text('초기화 완료'), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      expect(find.text('초기화 완료'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('device-data-reset-complete')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ServerRegistrationScreen), findsOneWidget);
      expect(find.byType(ServerSelectionScreen), findsNothing);
      expect(find.text('Home NAS'), findsNothing);
    },
  );
}
