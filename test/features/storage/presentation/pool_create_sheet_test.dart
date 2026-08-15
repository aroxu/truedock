import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';
import 'package:true_dock/features/storage/presentation/pool_create_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

StorageDisk _disk(String name, {int size = 1000000000000}) =>
    StorageDisk.fromJson({
      'identifier': name,
      'name': name,
      'devname': name,
      'model': 'IronWolf',
      'serial': 'ZXC$name',
      'type': 'HDD',
      'size': size,
    });

Future<PoolConfiguration?> _pumpAndOpen(
  WidgetTester tester, {
  required List<StorageDisk> candidates,
  Locale locale = const Locale('en'),
}) async {
  PoolConfiguration? result;
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
              result = await showModalBottomSheet<PoolConfiguration>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PoolCreateSheet(candidateDisks: candidates),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('warns when no disks are available and blocks review', (
    tester,
  ) async {
    await _pumpAndOpen(tester, candidates: const []);

    await tester.enterText(
      find.widgetWithText(TextField, 'Pool name').first,
      'tank',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('at least one data vdev'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('at least one data vdev'), findsOneWidget);
  });

  testWidgets('blocks review for a stripe vdev with no disks', (tester) async {
    await _pumpAndOpen(tester, candidates: [_disk('sda'), _disk('sdb')]);

    await tester.enterText(
      find.widgetWithText(TextField, 'Pool name').first,
      'tank',
    );
    await tester.pump();

    // No vdev added yet, so review fails.
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('at least one data vdev'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('at least one data vdev'), findsOneWidget);
  });

  testWidgets('rejects a name starting with a number', (tester) async {
    await _pumpAndOpen(tester, candidates: [_disk('sda'), _disk('sdb')]);

    await tester.enterText(
      find.widgetWithText(TextField, 'Pool name').first,
      '1tank',
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Start with a letter'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Start with a letter'), findsOneWidget);
  });

  testWidgets('shows the stripe redundancy warning', (tester) async {
    await _pumpAndOpen(tester, candidates: [_disk('sda')]);
    expect(find.textContaining('No redundancy'), findsOneWidget);
  });

  testWidgets('renders pool controls, warnings, and validation in Korean', (
    tester,
  ) async {
    await _pumpAndOpen(
      tester,
      candidates: const [],
      locale: const Locale('ko'),
    );

    expect(find.text('풀 생성'), findsOneWidget);
    expect(find.text('풀 이름'), findsOneWidget);
    expect(find.textContaining('중복성이 없습니다'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '풀 이름'), 'tank');
    await tester.tap(find.widgetWithText(FilledButton, '검토'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('데이터 vdev를 하나 이상'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('데이터 vdev를 하나 이상'), findsOneWidget);
  });
}
