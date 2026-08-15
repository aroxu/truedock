import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/domain/app_metadata.dart';
import 'package:true_dock/features/settings/presentation/about_screen.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('About screen renders static metadata', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About TrueDock'), findsOneWidget);
    expect(find.text('Dock your TrueNAS'), findsOneWidget);
    expect(find.text('Made with ❤️ in 🇰🇷'), findsOneWidget);
    expect(find.text('1.0.0 (build 3)'), findsOneWidget);
    expect(find.text('GPL-3.0-or-later'), findsOneWidget);
    expect(find.text('Source code'), findsOneWidget);
    expect(find.text('Open source licenses'), findsOneWidget);
  });

  testWidgets('Open source packages screen lists components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: OpenSourceLicensesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open source licenses'), findsOneWidget);
    for (final component in openSourceComponents) {
      expect(
        find.byKey(ValueKey('about-package-${component.name}')),
        findsOneWidget,
      );
      expect(find.text(component.name), findsOneWidget);
    }
  });
}
