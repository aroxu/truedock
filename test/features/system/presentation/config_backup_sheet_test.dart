import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/config_backup.dart';
import 'package:true_dock/features/system/presentation/config_backup_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

Widget _app(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () async {
          final result = await showModalBottomSheet<ConfigBackupReadyAction>(
            context: context,
            builder: (_) => ConfigBackupReadySheet(
              download: const ConfigBackupDownload(
                jobId: 42,
                path: '/_download/42?auth_token=secret',
                filename: 'nas-config.db',
              ),
              url: Uri.parse(
                'https://nas.local/_download/42?auth_token=secret',
              ),
            ),
          );
          if (context.mounted) Navigator.pop(context, result);
        },
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  testWidgets('Korean ready sheet returns browser download action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('ko')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('다운로드'), findsOneWidget);
    expect(find.text('다운로드 링크 복사'), findsOneWidget);
    await tester.tap(find.text('다운로드'));
    await tester.pumpAndSettle();

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)), isNotNull);
  });

  testWidgets('English ready sheet exposes download and copy actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Copy download link'), findsOneWidget);
  });
}
