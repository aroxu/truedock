import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_edit_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('reviews and returns only the changed properties', (
    tester,
  ) async {
    Map<String, Object?>? result;
    await _pumpSheet(tester, onResult: (value) => result = value);

    // Turning on read-only is the only change.
    await tester.tap(find.text('Block writes to this dataset'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review dataset changes'), findsOneWidget);
    expect(find.text('Dataset becomes read-only.'), findsOneWidget);
    expect(find.textContaining('will start'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply changes'));
    await tester.pumpAndSettle();

    expect(result, {'readonly': 'ON'});
  });

  testWidgets('blocks review when nothing changed', (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has changed for this dataset.'), findsOneWidget);
    expect(find.text('Review dataset changes'), findsNothing);
  });

  testWidgets('switching a property to inherit clears the override', (
    tester,
  ) async {
    Map<String, Object?>? result;
    await _pumpSheet(tester, onResult: (value) => result = value);

    // The quota section is the second "Inherit" segment on the sheet.
    await tester.tap(find.text('Inherit').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(
      find.text('Dataset quota inherits from the parent.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Apply changes'));
    await tester.pumpAndSettle();

    expect(result, {'quota': 'INHERIT'});
  });

  testWidgets('rejects a non-numeric quota', (tester) async {
    await _pumpSheet(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Quota'), 'abc');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter quota sizes as a positive number.'),
      findsOneWidget,
    );
  });

  testWidgets('renders quota review changes in Korean', (tester) async {
    await _pumpSheet(tester, locale: const Locale('ko'));

    await tester.enterText(find.widgetWithText(TextField, '할당량'), '20');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '검토'));
    await tester.pumpAndSettle();

    expect(find.text('데이터셋 변경 검토'), findsOneWidget);
    expect(find.text('데이터셋 할당량을 20 GiB(으)로 설정합니다.'), findsOneWidget);
    expect(find.textContaining('Dataset quota set'), findsNothing);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  ValueChanged<Map<String, Object?>?>? onResult,
  Locale? locale,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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
              final result = await showModalBottomSheet<Map<String, Object?>>(
                context: context,
                isScrollControlled: true,
                builder: (context) => DatasetEditSheet(dataset: _dataset),
              );
              onResult?.call(result);
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

final _dataset = Dataset.fromJson(const {
  'id': 'tank/projects/work',
  'name': 'tank/projects/work',
  'type': 'FILESYSTEM',
  'comments': {'value': 'Project files', 'source': 'LOCAL'},
  'quota': {'parsed': 10737418240, 'source': 'LOCAL'},
  'refquota': {'parsed': 0, 'source': 'INHERITED'},
  'readonly': {'value': 'OFF', 'source': 'LOCAL'},
  'compression': {'value': 'LZ4', 'source': 'INHERITED'},
  'sync': {'value': 'STANDARD', 'source': 'LOCAL'},
});
