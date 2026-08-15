import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

const _status = SystemUpdateStatus(
  code: 'NORMAL',
  train: 'TrueNAS-SCALE-25.10',
  profile: 'GENERAL',
  newVersion: '25.10.2',
);

void main() {
  testWidgets('disables the install button while request is being accepted', (
    tester,
  ) async {
    final pending = Completer<OperationReceipt?>();
    await _pump(tester, onInstall: () => pending.future);

    await tester.tap(find.widgetWithText(FilledButton, 'Install 25.10.2'));
    await tester.pump();

    expect(find.text('Update in progress'), findsOneWidget);
    expect(find.text('Preparing the system update…'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    pending.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('shows progress from the accepted TrueNAS update job', (
    tester,
  ) async {
    await _pump(
      tester,
      onInstall: () async =>
          const OperationReceipt(method: 'update.run', jobId: 91),
      serverResources: const ServerResources(
        jobs: ResourceSection(
          items: [
            SystemJob(
              id: 91,
              method: 'update.run',
              state: 'RUNNING',
              percent: 37,
              description: 'Installing packages',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Install 25.10.2'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Installing packages'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('system-update-progress')),
    );
    expect(progress.value, .37);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('shows the restart notice above install at full download', (
    tester,
  ) async {
    await _pump(
      tester,
      onInstall: () async => null,
      locale: const Locale('ko'),
      status: const SystemUpdateStatus(
        code: 'NORMAL',
        train: 'TrueNAS-SCALE-25.10',
        profile: 'GENERAL',
        newVersion: '25.10.2',
        downloadPercent: 100,
        downloadDescription: 'Download complete',
      ),
    );

    expect(find.text('업데이트를 설치할 준비가 되었습니다.'), findsOneWidget);
    final notice = tester.getTopLeft(find.text('업데이트를 설치할 준비가 되었습니다.'));
    final button = tester.getTopLeft(
      find.widgetWithText(FilledButton, '25.10.2 설치'),
    );
    expect(notice.dy, lessThan(button.dy));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<OperationReceipt?> Function() onInstall,
  ServerResources serverResources = const ServerResources(),
  SystemUpdateStatus status = _status,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverResourcesProvider.overrideWith((ref) async => serverResources),
        systemResourcesProvider.overrideWith(
          (ref) async =>
              SystemResources(updateStatus: ResourceValue(value: status)),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SystemUpdateDetails(
            status: status,
            canUpdate: true,
            onInstall: onInstall,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
