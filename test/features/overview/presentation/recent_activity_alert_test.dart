import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/overview/presentation/overview_screen.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/reporting_provider.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
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
    state = const NasConnectionState(stage: ConnectionStage.connected);
  }
}

void main() {
  testWidgets('tapping a recent alert shows its complete formatted content', (
    tester,
  ) async {
    final alert = SystemAlert.fromJson({
      'uuid': 'alert-1',
      'level': 'WARNING',
      'text': 'Short alert summary',
      'formatted': 'First line<br><b>Complete second line</b> &amp; details',
      'last_occurrence': {r'$date': 1760000060000},
      'dismissed': false,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith(
            (ref) => _ConnectedController(),
          ),
          serverResourcesProvider.overrideWith(
            (ref) async =>
                ServerResources(alerts: ResourceSection(items: [alert])),
          ),
          overviewReportingProvider.overrideWith(
            (ref) async => const ReportingSnapshot(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: OverviewScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Short alert summary'));
    await tester.pumpAndSettle();

    expect(find.text('알림 상세 정보'), findsOneWidget);
    expect(find.text('경고'), findsOneWidget);
    expect(
      find.text('First line\nComplete second line & details'),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent app update alert resolves every server placeholder', (
    tester,
  ) async {
    final alert = SystemAlert.fromJson({
      'uuid': 'app-update-alert',
      'level': 'INFO',
      'text':
          'Updates are available for %(count)d application%(plural)s: %(app)s',
      'args': {'count': 2, 'plural': 's', 'app': 'Immich, Syncthing'},
      'dismissed': false,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith(
            (ref) => _ConnectedController(),
          ),
          serverResourcesProvider.overrideWith(
            (ref) async =>
                ServerResources(alerts: ResourceSection(items: [alert])),
          ),
          overviewReportingProvider.overrideWith(
            (ref) async => const ReportingSnapshot(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: OverviewScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const resolved =
        'Updates are available for 2 applications: Immich, Syncthing';
    expect(find.text(resolved), findsOneWidget);

    await tester.tap(find.text(resolved));
    await tester.pumpAndSettle();
    expect(find.text(resolved), findsNWidgets(2));
    expect(find.textContaining('%('), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
