import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/dataset_configuration.dart';
import 'package:true_dock/features/storage/presentation/dataset_rename_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('returns a rename request scoped to the existing parent', (
    tester,
  ) async {
    DatasetRenameRequest? result;
    await _pumpSheet(tester, onResult: (value) => result = value);

    expect(find.textContaining('unmounts the dataset'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'archive');
    await tester.tap(find.text('Rename child datasets'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rename dataset'));
    await tester.pumpAndSettle();

    expect(result?.newName, 'tank/projects/archive');
    expect(result?.recursive, isTrue);
  });

  testWidgets('rejects a name that is unchanged or contains a slash', (
    tester,
  ) async {
    DatasetRenameRequest? result;
    await _pumpSheet(tester, onResult: (value) => result = value);

    await tester.tap(find.widgetWithText(FilledButton, 'Rename dataset'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a name different from the current one.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'nested/name');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename dataset'));
    await tester.pumpAndSettle();
    expect(find.text('A dataset name cannot contain "/".'), findsOneWidget);
    expect(result, isNull);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required ValueChanged<DatasetRenameRequest?> onResult,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showModalBottomSheet<DatasetRenameRequest>(
                context: context,
                isScrollControlled: true,
                builder: (context) => DatasetRenameSheet(
                  dataset: Dataset.fromJson(const {
                    'id': 'tank/projects/work',
                    'name': 'tank/projects/work',
                    'type': 'FILESYSTEM',
                  }),
                ),
              );
              onResult(result);
            },
            child: const Text('Open sheet'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
}
