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

  testWidgets('long app options fit the iPhone installation sheet', (
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
          body: AppInstallationSheet(app: _app, details: _details),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1Password Connect 구성'), findsOneWidget);
    expect(find.text('외부 접속을 위해 호스트에 포트 공개'), findsOneWidget);
    expect(find.text('포트 바인딩 방식'), findsOneWidget);
    final groupToggle = find.byKey(
      const ValueKey('app-section-toggle-1Password Connect Configuration'),
    );
    expect(groupToggle, findsOneWidget);
    await tester.tap(groupToggle);
    await tester.pumpAndSettle();
    expect(find.text('외부 접속을 위해 호스트에 포트 공개'), findsNothing);
    await tester.tap(groupToggle);
    await tester.pumpAndSettle();
    expect(find.text('외부 접속을 위해 호스트에 포트 공개'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('app-option-bind_mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-option-list')), findsOneWidget);
    expect(find.text('옵션 1개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _app = CatalogApp(
  name: 'onepassword-connect',
  title: '1Password Connect',
  train: 'community',
  description: 'Password service',
  healthy: true,
  recommended: false,
  categories: [],
  tags: [],
);

final _details = CatalogAppInstallationDetails.fromJson(
  {
    'name': 'onepassword-connect',
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
              'variable': 'bind_mode',
              'label': 'Port Bind Mode',
              'group': '1Password Connect Configuration',
              'schema': {
                'type': 'string',
                'required': true,
                'enum': [
                  {
                    'value': 'published',
                    'description':
                        'Publish port on the host for external access',
                  },
                ],
                'default': 'published',
              },
            },
          ],
        },
        'values': const {},
      },
    },
  },
  fallbackName: 'onepassword-connect',
  train: 'community',
);
