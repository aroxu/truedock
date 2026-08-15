import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connect_server_screen.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/connection/presentation/server_entry_screen.dart';
import 'package:true_dock/features/shell/presentation/app_shell.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved server authenticates without showing registration', (
    tester,
  ) async {
    final server = SavedServer(
      profile: ServerProfile.parse(
        name: 'Live',
        address: 'https://10.24.30.81',
      ),
      username: 'truenas_admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
    );
    final controller = _DelayedSavedConnectionController(server.profile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith((ref) => controller),
          savedServersProvider.overrideWith((ref) async => [server]),
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

    await tester.tap(find.text('Live'));
    await tester.pump();
    expect(find.byType(ServerRegistrationScreen), findsNothing);
    expect(find.text('TrueNAS 서버 추가'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.finish();
    await tester.pumpAndSettle();
    expect(find.byType(ServerRegistrationScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });
}

class _DelayedSavedConnectionController extends ConnectionController {
  _DelayedSavedConnectionController(this.profile)
    : super(TrueNasJsonRpcClient(), SavedServerRepository(vault: _NoopVault()));

  final ServerProfile profile;
  final _gate = Completer<void>();

  @override
  Future<void> switchToSaved(SavedServer server) async {
    state = NasConnectionState(
      stage: ConnectionStage.connecting,
      profile: server.profile,
    );
    await _gate.future;
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: server.profile,
      username: server.username,
    );
  }

  void finish() => _gate.complete();
}

class _NoopVault implements CredentialVault {
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
