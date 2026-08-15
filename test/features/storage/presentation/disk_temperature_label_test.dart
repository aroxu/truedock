import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/disk_temperature_label.dart';
import 'package:true_dock/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, DiskTemperature? temperature) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DiskTemperatureLabel(temperature: temperature)),
    ),
  );
}

Color? _colorOf(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).style?.color;

void main() {
  testWidgets('shows the reading in degrees Celsius', (tester) async {
    await _pump(tester, const DiskTemperature(celsius: 34));

    expect(find.text('34°C'), findsOneWidget);
  });

  testWidgets('renders nothing when the drive could not be read', (
    tester,
  ) async {
    await _pump(tester, const DiskTemperature());

    // A zero here would read as a very cold disk.
    expect(find.byType(Text), findsNothing);
    expect(find.textContaining('0'), findsNothing);
  });

  testWidgets('renders nothing when there is no reading at all', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('a normal reading does not use the error colour', (tester) async {
    await _pump(
      tester,
      const DiskTemperature(celsius: 40, maximum: 55, critical: 60),
    );

    final context = tester.element(find.byType(DiskTemperatureLabel));
    expect(_colorOf(tester), isNot(Theme.of(context).colorScheme.error));
  });

  testWidgets('warns once the drive passes its own rated maximum', (
    tester,
  ) async {
    await _pump(
      tester,
      const DiskTemperature(celsius: 58, maximum: 55, critical: 70),
    );

    final context = tester.element(find.byType(DiskTemperatureLabel));
    expect(_colorOf(tester), Theme.of(context).colorScheme.error);
    // Thresholds are per-drive, so this must not be a fixed number.
    expect(
      tester.widget<Text>(find.byType(Text)).style?.fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('the warning does not depend on colour alone', (tester) async {
    await _pump(
      tester,
      const DiskTemperature(celsius: 62, maximum: 55, critical: 60),
    );

    expect(
      tester.widget<Text>(find.byType(Text)).semanticsLabel,
      '62 degrees Celsius, over the drive limit',
    );
  });

  testWidgets('a reading without thresholds is never alarming', (tester) async {
    await _pump(tester, const DiskTemperature(celsius: 61));

    final context = tester.element(find.byType(DiskTemperatureLabel));
    expect(_colorOf(tester), isNot(Theme.of(context).colorScheme.error));
    expect(
      tester.widget<Text>(find.byType(Text)).semanticsLabel,
      '61 degrees Celsius',
    );
  });
}
