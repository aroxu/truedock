import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/device_data_reset_service.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/settings/presentation/device_data_reset_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _Resetter implements DeviceDataResetter {
  bool didReset = false;

  @override
  Future<void> reset() async => didReset = true;
}

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

class _Controller extends ConnectionController {
  _Controller()
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _Vault()));

  int clears = 0;

  @override
  Future<void> clearSessionForDeviceReset() async {
    clears++;
    state = const NasConnectionState();
  }
}

void main() {
  testWidgets('confirmed reset clears local data and returns to first use', (
    tester,
  ) async {
    final resetter = _Resetter();
    final controller = _Controller();
    final router = GoRouter(
      initialLocation: '/reset',
      routes: [
        GoRoute(
          path: '/reset',
          builder: (_, _) => const DeviceDataResetScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('First use')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceDataResetterProvider.overrideWithValue(resetter),
          connectionControllerProvider.overrideWith((ref) => controller),
          savedServersProvider.overrideWith(
            (ref) async => resetter.didReset
                ? const []
                : [
                    SavedServer(
                      profile: ServerProfile(
                        name: 'NAS',
                        baseUri: Uri.parse('https://nas.local'),
                      ),
                      username: 'admin',
                      authMethod: AuthMethod.password,
                      hasSavedCredential: true,
                    ),
                  ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.widgetWithText(FilledButton, 'Erase all data');
    expect(tester.widget<FilledButton>(action).onPressed, isNull);

    final confirmationField = find.byKey(
      const ValueKey('reset-all-device-data-confirmation'),
    );
    final prompt = tester
        .widget<Text>(find.textContaining('Type the code'))
        .data!;
    final code = RegExp(
      r'[A-Z0-9]{4}-[A-Z0-9]{4}',
    ).firstMatch(prompt)?.group(0);
    expect(code, matches(RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$')));
    expect(find.text('This action cannot be undone.'), findsOneWidget);
    await tester.enterText(
      find.descendant(of: confirmationField, matching: find.byType(TextField)),
      code!,
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(resetter.didReset, isTrue);
    expect(find.text('Reset complete'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Start again'), findsNothing);
    expect(find.text('First use'), findsNothing);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(find.text('Reset complete'), findsOneWidget);
    expect(find.text('First use'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('device-data-reset-complete')));
    await tester.pumpAndSettle();

    expect(controller.clears, 1);
    expect(find.text('First use'), findsOneWidget);
  });
}
