import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/presentation/sparkline.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('does not render minimum and maximum labels below the chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Sparkline(
            values: [20, 40, 60],
            label: 'CPU',
            minimum: 0,
            maximum: 100,
            formatValue: _percent,
          ),
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('100%'), findsNothing);
  });
}

String _percent(double value) => '${value.toStringAsFixed(0)}%';
