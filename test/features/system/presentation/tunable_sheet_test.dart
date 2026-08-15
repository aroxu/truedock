import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/tunable_configuration.dart';
import 'package:true_dock/features/system/presentation/tunable_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('blocks an empty create submission', (tester) async {
    await tester.pumpWidget(
      app(
        const TunableSheet(
          baseline: TunableConfiguration(variable: '', value: ''),
        ),
      ),
    );

    await tester.tap(find.text('Review'));
    await tester.pump();

    expect(find.text('Enter a variable name.'), findsOneWidget);
    expect(find.text('Enter a value.'), findsOneWidget);
  });

  testWidgets('locks type and variable while editing', (tester) async {
    await tester.pumpWidget(
      app(
        const TunableSheet(
          editing: true,
          baseline: TunableConfiguration(
            type: TunableType.zfs,
            variable: 'zfs_arc_max',
            value: '1024',
          ),
        ),
      ),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.enabled, isFalse);
    expect(find.text('Update initramfs'), findsOneWidget);
  });

  testWidgets('returns a trimmed reviewed configuration', (tester) async {
    TunableConfiguration? result;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showModalBottomSheet<TunableConfiguration>(
                context: context,
                builder: (_) => const TunableSheet(
                  baseline: TunableConfiguration(variable: '', value: ''),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Variable'),
      ' kernel.watchdog ',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Value'), ' 0 ');
    await tester.ensureVisible(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(result?.variable, ' kernel.watchdog ');
    expect(result?.toCreateApiJson()['var'], 'kernel.watchdog');
    expect(result?.toCreateApiJson()['value'], '0');
  });
}
