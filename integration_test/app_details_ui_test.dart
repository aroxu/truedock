import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:true_dock/features/apps/domain/app_stats.dart';
import 'package:true_dock/features/apps/presentation/app_details_sheet.dart';
import 'package:true_dock/features/apps/presentation/app_stats_provider.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app detail presents live usage and edit action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStatsProvider('immich').overrideWith(
            (ref) => Stream.value(
              const AppStats(
                appName: 'immich',
                cpuUsage: 7.4,
                memoryBytes: 768 * 1024 * 1024,
                networks: [
                  AppNetworkStats(
                    interfaceName: 'eth0',
                    receivedBytesPerSecond: 2048,
                    sentBytesPerSecond: 1024,
                  ),
                ],
                blockReadBytes: 4096,
                blockWriteBytes: 8192,
              ),
            ),
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
          home: Scaffold(body: AppDetailsSheet(app: _app, canEdit: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7.4%'), findsOneWidget);
    expect(find.text('768 MiB'), findsOneWidget);
    expect(find.text('편집'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _app = InstalledApp(
  id: 'immich',
  name: 'Immich',
  state: 'RUNNING',
  version: '1.0.0',
  catalogUpgradeAvailable: false,
  imageUpdatesAvailable: false,
  workloads: AppWorkloads(
    containerCount: 1,
    images: ['ghcr.io/immich-app/immich-server'],
    networks: ['ix-immich'],
  ),
);
