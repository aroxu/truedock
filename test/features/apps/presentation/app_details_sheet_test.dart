import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:true_dock/features/apps/domain/app_stats.dart';
import 'package:true_dock/features/apps/presentation/app_details_sheet.dart';
import 'package:true_dock/features/apps/presentation/app_stats_provider.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('shows live resources and configured workloads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStatsProvider('immich').overrideWith(
            (ref) => Stream.value(
              const AppStats(
                appName: 'immich',
                cpuUsage: 12.5,
                memoryBytes: 1073741824,
                networks: [
                  AppNetworkStats(
                    interfaceName: 'eth0',
                    receivedBytesPerSecond: 1024,
                    sentBytesPerSecond: 2048,
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

    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('1.0 GiB'), findsOneWidget);
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('메모리'), findsOneWidget);
    expect(find.text('RAM'), findsNothing);
    expect(find.text('immich-server · 실행 중'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('/mnt/tank/photos'), findsOneWidget);
    expect(find.text('편집'), findsOneWidget);
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
    containers: [
      AppContainerWorkload(
        id: 'abc',
        serviceName: 'immich-server',
        image: 'ghcr.io/immich-app/immich-server',
        state: 'running',
      ),
    ],
    volumes: [
      AppVolumeMount(
        source: '/mnt/tank/photos',
        destination: '/usr/src/app/upload',
        mode: 'rw',
        type: 'bind',
      ),
    ],
  ),
);
