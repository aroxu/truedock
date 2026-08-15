import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/features/system/presentation/system_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _appearance() => const ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: AppearanceSheet()),
  ),
);

Widget _system() => const ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SystemScreen()),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('appearance controls use the localized labels', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_appearance());
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.byTooltip('Custom color'), findsOneWidget);
  });

  testWidgets('system administration does not expose tunables', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_system());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('system-tunables-tile')), findsNothing);
    expect(find.text('System tunables'), findsNothing);
    expect(find.byKey(const ValueKey('system-advanced-tile')), findsOneWidget);
  });

  testWidgets('custom color dialog localizes and validates hex input', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_appearance());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Custom color'));
    await tester.pumpAndSettle();
    expect(find.text('Custom source color'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saturation-value-picker')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hue-picker')), findsOneWidget);

    final hexField = find.byKey(const ValueKey('custom-color-hex'));
    await tester.enterText(hexField, '123456');
    expect(tester.widget<TextField>(hexField).controller!.text, '123456');
    expect(tester.widget<TextField>(hexField).maxLength, 6);
    await tester.enterText(hexField, '1234567');
    expect(
      tester.widget<TextField>(hexField).controller!.text.length,
      lessThanOrEqualTo(6),
    );
    await tester.enterText(hexField, '12');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('Enter six hexadecimal digits.'), findsOneWidget);
  });

  testWidgets('color picker and hex field stay synchronized', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_appearance());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Custom color'));
    await tester.pumpAndSettle();
    final hexField = find.byKey(const ValueKey('custom-color-hex'));
    await tester.enterText(hexField, 'FF0000');
    await tester.pump();

    final preview = tester.widget<Container>(
      find.byKey(const ValueKey('custom-color-preview')),
    );
    expect(
      (preview.decoration! as BoxDecoration).color,
      const Color(0xFFFF0000),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('hue-picker'))),
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(hexField).controller!.text,
      isNot('FF0000'),
    );
  });
}
