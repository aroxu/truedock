import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('system update progress disables the iPhone action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverResourcesProvider.overrideWith(
            (ref) async => const ServerResources(
              jobs: ResourceSection(
                items: [
                  SystemJob(
                    id: 91,
                    method: 'update.run',
                    state: 'RUNNING',
                    percent: 37,
                    description: '업데이트 패키지 설치 중',
                  ),
                ],
              ),
            ),
          ),
          systemResourcesProvider.overrideWith(
            (ref) async => const SystemResources(
              updateStatus: ResourceValue(value: _status),
            ),
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
          home: Scaffold(
            body: SafeArea(
              child: SystemUpdateDetails(
                status: _status,
                canUpdate: true,
                onInstall: () async =>
                    const OperationReceipt(method: 'update.run', jobId: 91),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '25.10.2 설치'));
    await tester.pump();
    await tester.pump();

    expect(find.text('업데이트 진행 중'), findsOneWidget);
    expect(find.text('업데이트 패키지 설치 중'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('system-update-progress')),
          )
          .value,
      .37,
    );
    expect(tester.takeException(), isNull);
  });
}

const _status = SystemUpdateStatus(
  code: 'NORMAL',
  train: 'TrueNAS-SCALE-25.10',
  profile: 'GENERAL',
  newVersion: '25.10.2',
);
