import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:true_dock/core/widgets/truedock_dropdown.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('opens a 60 percent Material choice sheet and selects a value', (
    tester,
  ) async {
    String? selected = 'one';
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: TrueDockDropdownButtonFormField<String>(
              initialValue: selected,
              decoration: const InputDecoration(labelText: 'Server mode'),
              items: const [
                DropdownMenuItem(value: 'one', child: Text('First option')),
                DropdownMenuItem(value: 'two', child: Text('Second option')),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('First option'));
    await tester.pumpAndSettle();
    final sheet = tester.widget<FractionallySizedBox>(
      find.ancestor(
        of: find.byKey(const ValueKey('truedock-dropdown-list')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(sheet.heightFactor, .60);

    await tester.tap(find.text('Second option'));
    await tester.pumpAndSettle();
    expect(selected, 'two');
    expect(find.text('Second option'), findsOneWidget);
  });

  testWidgets('offers search for long option lists', (tester) async {
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
          body: TrueDockDropdownButtonFormField<int>(
            initialValue: 0,
            decoration: const InputDecoration(labelText: 'Account'),
            items: [
              for (var index = 0; index < 10; index++)
                DropdownMenuItem(value: index, child: Text('Account $index')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Account 0'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('truedock-dropdown-search')),
      'Account 9',
    );
    await tester.pumpAndSettle();

    expect(find.text('Account 9'), findsNWidgets(2));
    expect(find.text('Account 1'), findsNothing);
  });
}
