import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_edit_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dataset review has no untranslated English prose', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DatasetEditSheet(dataset: _dataset)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '할당량'), '20');
    final review = find.widgetWithText(FilledButton, '검토');
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();

    expect(find.text('데이터셋 변경 검토'), findsOneWidget);
    expect(find.text('데이터셋 할당량을 20 GiB(으)로 설정합니다.'), findsOneWidget);
    expect(find.textContaining('Dataset quota set'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _dataset = Dataset.fromJson(const {
  'id': 'truedock_data/media',
  'name': 'truedock_data/media',
  'type': 'FILESYSTEM',
  'comments': {'value': '', 'source': 'LOCAL'},
  'quota': {'parsed': 0, 'source': 'LOCAL'},
  'refquota': {'parsed': 0, 'source': 'INHERITED'},
  'readonly': {'value': 'OFF', 'source': 'LOCAL'},
  'compression': {'value': 'LZ4', 'source': 'INHERITED'},
  'sync': {'value': 'STANDARD', 'source': 'LOCAL'},
});
