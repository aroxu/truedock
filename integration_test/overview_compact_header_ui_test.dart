import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/connection/domain/system_info.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'overview header omits status labels and trims uptime fractions',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionControllerProvider.overrideWith(
              (ref) => _ConnectedController(),
            ),
            serverResourcesProvider.overrideWith(
              (ref) async => const ServerResources(),
            ),
            overviewReportingProvider.overrideWith(
              (ref) async => const ReportingSnapshot(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: OverviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.toolbarHeight, kToolbarHeight);
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      final safeTop = MediaQuery.paddingOf(
        tester.element(find.byType(OverviewScreen)),
      ).top;
      expect(safeTop, greaterThan(0));
      expect(refresh.edgeOffset, safeTop);
      expect(refresh.displacement, safeTop + 40);
      final metricsGrid = tester.widget<GridView>(find.byType(GridView));
      expect(metricsGrid.padding, EdgeInsets.zero);
      expect(find.text('개요'), findsOneWidget);
      expect(find.text('TrueDock'), findsNothing);
      expect(find.text('안전하게 연결됨'), findsNothing);
      expect(find.text('한눈에 보기'), findsNothing);
      expect(find.text('truenas'), findsNothing);
      expect(find.text('25.10.6'), findsNothing);
      expect(find.text('1 day, 08:14:37'), findsOneWidget);
      expect(find.text('가동 시간'), findsOneWidget);
      final metricLabels = tester
          .widgetList<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  const {'CPU 코어', '메모리', '가동 시간', '상태'}.contains(widget.data),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(metricLabels, ['CPU 코어', '메모리', '가동 시간', '상태']);
      final uptimeIcon = tester.getBottomLeft(
        find.byIcon(Icons.schedule_rounded),
      );
      final uptimeValue = tester.getTopLeft(find.text('1 day, 08:14:37'));
      expect(uptimeValue.dy - uptimeIcon.dy, lessThanOrEqualTo(10));
      expect(find.textContaining('.582319'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ConnectedController extends ConnectionController {
  _ConnectedController()
    : super(
        TrueNasJsonRpcClient(),
        SavedServerRepository(vault: _NoopVault()),
      ) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      systemInfo: SystemInfo.fromJson({
        'hostname': 'truenas',
        'version': '25.10.6',
        'uptime': '1 day, 08:14:37.582319',
        'uptime_seconds': 116077.582319,
        'physmem': 32 * 1024 * 1024 * 1024,
        'model': 'CPU',
        'cores': 4,
      }),
    );
  }
}

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
