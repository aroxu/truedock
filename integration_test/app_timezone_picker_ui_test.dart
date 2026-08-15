import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/apps/domain/app_installation.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';
import 'package:true_dock/features/apps/presentation/app_installation_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('timezone picker shows only IANA identifiers', (tester) async {
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
          body: AppInstallationSheet(app: _app, details: _details),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('app-option-timezone')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('app-option-search')),
      'Asia/Seoul',
    );
    await tester.pump();

    final result = find.descendant(
      of: find.byKey(const ValueKey('app-option-list')),
      matching: find.text('Asia/Seoul'),
    );
    expect(result, findsOneWidget);
    expect(find.text("'Asia/Seoul' timezone"), findsNothing);
    await tester.tap(result);
    await tester.pumpAndSettle();
    expect(find.text('Asia/Seoul'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _app = CatalogApp(
  name: 'timezone-test',
  title: 'Timezone Test',
  train: 'community',
  description: 'Timezone picker',
  healthy: true,
  recommended: false,
  categories: [],
  tags: [],
);

final _details = CatalogAppInstallationDetails.fromJson(
  {
    'name': 'timezone-test',
    'latest_version': '1.0.0',
    'versions': {
      '1.0.0': {
        'version': '1.0.0',
        'human_version': '1.0.0',
        'healthy': true,
        'supported': true,
        'schema': {
          'questions': [
            {
              'variable': 'timezone',
              'label': 'Timezone',
              'schema': {
                'type': 'string',
                'enum': [
                  for (var index = 0; index < 598; index++)
                    {
                      'value': index == 300
                          ? 'Asia/Seoul'
                          : 'Region/Zone$index',
                      'description': index == 300
                          ? "'Asia/Seoul' timezone"
                          : "'Region/Zone$index' timezone",
                    },
                ],
                'default': 'Region/Zone0',
              },
            },
          ],
        },
        'values': const {},
      },
    },
  },
  fallbackName: 'timezone-test',
  train: 'community',
);
