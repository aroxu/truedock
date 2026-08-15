import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:true_dock/core/widgets/truedock_dropdown.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('global dropdown uses the 60 percent searchable choice sheet', (
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
        home: Scaffold(
          body: TrueDockDropdownButtonFormField<int>(
            initialValue: 0,
            decoration: const InputDecoration(
              labelText: '시간대',
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
            items: [
              for (var index = 0; index < 12; index++)
                DropdownMenuItem(
                  value: index,
                  child: Text('Asia/Seoul option $index'),
                ),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Asia/Seoul option 0'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('truedock-dropdown-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('truedock-dropdown-search')),
      findsOneWidget,
    );
    final sheet = tester.widget<FractionallySizedBox>(
      find.ancestor(
        of: find.byKey(const ValueKey('truedock-dropdown-list')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(sheet.heightFactor, .60);
    expect(tester.takeException(), isNull);
  });
}
