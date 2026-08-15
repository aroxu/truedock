import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:true_dock/features/apps/presentation/custom_app_editor_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('returns edited custom compose JSON', (tester) async {
    Map<String, Object?>? result;
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<Map<String, Object?>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CustomAppEditorSheet(
                    appName: 'custom',
                    configuration: {
                      'services': {
                        'web': {'image': 'nginx:1'},
                      },
                    },
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
    await tester.enterText(
      find.byKey(const ValueKey('custom-app-compose-editor')),
      '{"services":{"web":{"image":"nginx:2"}}}',
    );
    await tester.tap(find.text('변경 검토'));
    await tester.pumpAndSettle();

    expect(((result?['services'] as Map)['web'] as Map)['image'], 'nginx:2');
  });
}
