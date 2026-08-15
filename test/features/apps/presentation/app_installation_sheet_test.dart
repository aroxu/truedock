import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/app_configuration.dart';
import 'package:true_dock/features/apps/domain/app_installation.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';
import 'package:true_dock/features/apps/presentation/app_installation_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  late CatalogAppInstallationDetails details;
  late CatalogApp catalogApp;

  setUp(() {
    catalogApp = const CatalogApp(
      name: 'immich',
      title: 'Immich',
      train: 'stable',
      description: 'Photos',
      healthy: true,
      recommended: false,
      categories: [],
      tags: [],
    );
    details = CatalogAppInstallationDetails.fromJson(
      {
        'name': 'immich',
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
                  'variable': 'image_repository',
                  'label': 'Image repository',
                  'schema': {'type': 'string', 'required': true},
                  'default': 'immich-app/immich',
                },
                {
                  'variable': 'port',
                  'label': 'Port',
                  'schema': {'type': 'int', 'required': true},
                  'default': 8080,
                },
              ],
            },
            'values': const {},
          },
        },
      },
      fallbackName: 'immich',
      train: 'stable',
    );
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    AppConfiguration? configuration,
  }) async {
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
          body: AppInstallationSheet(
            app: catalogApp,
            details: details,
            configuration: configuration,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('install mode shows the app instance name field', (tester) async {
    await pumpSheet(tester);
    expect(find.text('App instance name'), findsOneWidget);
    expect(find.text('Install Immich'), findsOneWidget);
  });

  testWidgets('configuration categories start open and collapse separately', (
    tester,
  ) async {
    final categorized = CatalogAppInstallationDetails.fromJson(
      {
        'name': 'immich',
        'latest_version': '1.0.0',
        'versions': {
          '1.0.0': {
            'version': '1.0.0',
            'human_version': '1.0.0',
            'healthy': true,
            'supported': true,
            'schema': {
              'groups': [
                {'name': 'Network', 'description': 'Network settings'},
                {'name': 'Storage', 'description': 'Storage settings'},
              ],
              'questions': [
                {
                  'variable': 'host',
                  'label': 'Host name',
                  'group': 'Network',
                  'schema': {'type': 'string', 'default': 'immich.local'},
                },
                {
                  'variable': 'path',
                  'label': 'Data path',
                  'group': 'Storage',
                  'schema': {'type': 'string', 'default': '/mnt/photos'},
                },
                {
                  'variable': 'advanced',
                  'label': 'Advanced options',
                  'group': 'Storage',
                  'schema': {
                    'type': 'dict',
                    'attrs': [
                      {
                        'variable': 'debug',
                        'label': 'Debug logging',
                        'schema': {'type': 'boolean', 'default': true},
                      },
                    ],
                  },
                },
              ],
            },
            'values': const {},
          },
        },
      },
      fallbackName: 'immich',
      train: 'stable',
    );
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
          body: AppInstallationSheet(app: catalogApp, details: categorized),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('호스트 이름'), findsOneWidget);
    expect(find.text('데이터 경로'), findsOneWidget);
    expect(find.text('디버그 로깅'), findsOneWidget);
    expect(find.text('네트워크'), findsOneWidget);
    expect(find.text('스토리지'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-section-toggle-Network')));
    await tester.pumpAndSettle();
    expect(find.text('호스트 이름'), findsNothing);
    expect(find.text('데이터 경로'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('app-section-toggle-Advanced options')),
    );
    await tester.pumpAndSettle();
    expect(find.text('디버그 로깅'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long dropdown choices fit a narrow phone', (tester) async {
    final narrowDetails = CatalogAppInstallationDetails.fromJson(
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
                  'schema': {
                    'type': 'string',
                    'required': true,
                    'enum': [
                      {
                        'value': 'published',
                        'description':
                            'Publish port on the host for external access',
                      },
                      {
                        'value': 'internal',
                        'description': 'Expose only inside the application',
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
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          body: AppInstallationSheet(
            app: const CatalogApp(
              name: 'onepassword-connect',
              title: '1Password Connect',
              train: 'community',
              description: 'Password service',
              healthy: true,
              recommended: false,
              categories: [],
              tags: [],
            ),
            details: narrowDetails,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      errors.where((detail) => detail.exceptionAsString().contains('overflow')),
      isEmpty,
    );

    await tester.tap(find.byKey(const ValueKey('app-option-bind_mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-option-list')), findsOneWidget);
    final sheet = tester.widget<FractionallySizedBox>(
      find.ancestor(
        of: find.byKey(const ValueKey('app-option-list')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(sheet.heightFactor, .60);
    expect(
      find.text('Publish port on the host for external access'),
      findsWidgets,
    );
    expect(
      errors.where((detail) => detail.exceptionAsString().contains('overflow')),
      isEmpty,
    );
  });

  testWidgets('update mode hides the name field and locks the instance', (
    tester,
  ) async {
    final config = AppConfiguration.fromJson({
      'app_id': 'immich',
      'name': 'immich',
      'catalog_app': 'immich',
      'train': 'stable',
      'app_version': '1.0.0',
      'values': {'image_repository': 'immich-app/immich', 'port': 2283},
    });
    await pumpSheet(tester, configuration: config);

    expect(find.text('App instance name'), findsNothing);
    expect(find.text('Reconfigure immich'), findsOneWidget);
    expect(find.text('App instance'), findsOneWidget);
    expect(find.text('immich'), findsWidgets);
  });

  testWidgets('update mode seeds the editor with current values', (
    tester,
  ) async {
    final config = AppConfiguration.fromJson({
      'app_id': 'immich',
      'name': 'immich',
      'catalog_app': 'immich',
      'train': 'stable',
      'app_version': '1.0.0',
      'values': {'image_repository': 'custom/immich', 'port': 2283},
    });
    await pumpSheet(tester, configuration: config);

    // The image repository text field should carry the seeded value.
    final imageField = find.widgetWithText(TextField, 'custom/immich');
    expect(imageField, findsOneWidget);
  });

  testWidgets(
    'update mode returns an AppSheetUpdate with the resolved values',
    (tester) async {
      final config = AppConfiguration.fromJson({
        'app_id': 'immich',
        'name': 'immich',
        'catalog_app': 'immich',
        'train': 'stable',
        'app_version': '1.0.0',
        'values': {'image_repository': 'custom/immich', 'port': 2283},
      });
      AppSheetResult? result;
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
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<AppSheetResult>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    showDragHandle: true,
                    builder: (_) => AppInstallationSheet(
                      app: catalogApp,
                      details: details,
                      configuration: config,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Move to review then submit.
      await tester.tap(find.widgetWithText(FilledButton, 'Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reconfigure app'));
      await tester.pumpAndSettle();

      expect(result, isA<AppSheetUpdate>());
      final update = result as AppSheetUpdate;
      expect(update.request.values['image_repository'], 'custom/immich');
      expect(update.request.values['port'], 2283);
    },
  );
}
