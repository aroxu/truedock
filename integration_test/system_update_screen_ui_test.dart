import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('update page shows refreshable status and manual firmware', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionControllerProvider.overrideWith(
            (ref) => _ConnectedController(),
          ),
          systemResourcesProvider.overrideWith(
            (ref) async => const SystemResources(
              updateStatus: ResourceValue(
                value: SystemUpdateStatus(
                  code: 'NORMAL',
                  train: 'TrueNAS-SCALE-25.10',
                  profile: 'GENERAL',
                  newVersion: '25.10.7',
                  downloadPercent: 100,
                ),
              ),
            ),
          ),
          systemUpdateStatusProvider.overrideWith(
            (ref) async => const ResourceValue(
              value: SystemUpdateStatus(
                code: 'NORMAL',
                train: 'TrueNAS-SCALE-25.10',
                profile: 'GENERAL',
                newVersion: '25.10.7',
                downloadPercent: 100,
              ),
            ),
          ),
          serverResourcesProvider.overrideWith(
            (ref) async => const ServerResources(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ko'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SystemAdministrationScreen(section: 'updates'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('잠시 후 곧 재시작됩니다.'), findsOneWidget);
    expect(find.text('커스텀 펌웨어'), findsOneWidget);
    expect(find.text('업데이트 파일 선택'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ConnectedController extends ConnectionController {
  _ConnectedController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: ServerProfile.parse(
        name: 'Lab NAS',
        address: 'https://truenas.local',
      ),
      capabilities: const ServerCapabilities(
        productType: 'COMMUNITY_EDITION',
        version: TrueNasVersion(25, 10, 0),
        methods: {'update.run', 'update.file'},
      ),
    );
  }
}
