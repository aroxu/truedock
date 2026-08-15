import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/presentation/instance_sheets.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/virt_instance_configuration.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  group('CreateInstanceSheet', () {
    testWidgets('rejects an invalid name before returning a payload', (
      tester,
    ) async {
      // Incus derives the guest hostname from the name, so the server rejects a
      // non-DNS-label with an opaque validation dump. Catching it here is the
      // difference between a usable message and a middleware traceback.
      final returned = <VirtInstanceCreateConfiguration>[];
      await _pumpCreate(tester, onSubmit: returned.add);

      await tester.enterText(find.byType(TextField).first, '1-bad_name');
      await tester.tap(find.text('Create instance').last);
      await tester.pumpAndSettle();

      expect(returned, isEmpty);
      expect(
        find.text(
          'Use letters, digits, and hyphens only, starting with a letter.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('builds the create payload from the form', (tester) async {
      final returned = <VirtInstanceCreateConfiguration>[];
      await _pumpCreate(tester, onSubmit: returned.add);

      await tester.enterText(find.byType(TextField).first, 'web');
      await tester.enterText(
        find.widgetWithText(TextField, 'Memory (MiB)'),
        '512',
      );
      await tester.tap(find.text('Create instance').last);
      await tester.pumpAndSettle();

      expect(returned, hasLength(1));
      final payload = returned.single.toApiJson();
      expect(payload['name'], 'web');
      expect(payload['image'], 'alpine/3.22/default');
      expect(payload['instance_type'], 'CONTAINER');
      expect(payload['source_type'], 'IMAGE');
      // Memory is sent in bytes; the field collects MiB.
      expect(payload['memory'], 512 * 1024 * 1024);
      expect(payload['storage_pool'], 'tank');
    });
  });

  group('EditInstanceSheet', () {
    testWidgets('sends nothing when no field changed', (tester) async {
      // virt.instance.update merges a partial object, so resending unchanged
      // values would overwrite fields the sheet does not surface.
      final returned = <VirtInstanceConfiguration>[];
      await _pumpEdit(tester, onSubmit: returned.add);

      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(returned, hasLength(1));
      expect(returned.single.isEmpty, isTrue);
    });

    testWidgets('sends only the field that changed', (tester) async {
      final returned = <VirtInstanceConfiguration>[];
      await _pumpEdit(tester, onSubmit: returned.add);

      await tester.enterText(
        find.widgetWithText(TextField, 'Memory (MiB)'),
        '1024',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(returned.single.toApiJson(), {'memory': 1024 * 1024 * 1024});
    });

    testWidgets('rejects memory a guest cannot boot with', (tester) async {
      final returned = <VirtInstanceConfiguration>[];
      await _pumpEdit(tester, onSubmit: returned.add);

      await tester.enterText(
        find.widgetWithText(TextField, 'Memory (MiB)'),
        '8',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(returned, isEmpty);
      expect(
        find.text('Memory must be at least $virtMinimumMemoryMiB MiB.'),
        findsOneWidget,
      );
    });
  });
}

final _instance = VirtInstance(
  id: 'web',
  name: 'web',
  type: 'CONTAINER',
  status: 'STOPPED',
  autostart: true,
  privileged: false,
  vncEnabled: false,
  cpu: '2',
  memoryBytes: 512 * 1024 * 1024,
  storagePool: 'tank',
);

Future<void> _pumpCreate(
  WidgetTester tester, {
  required ValueChanged<VirtInstanceCreateConfiguration> onSubmit,
}) => _pump(
  tester,
  builder: (context) => FilledButton(
    onPressed: () async {
      final result =
          await showModalBottomSheet<VirtInstanceCreateConfiguration>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CreateInstanceSheet(
              images: [
                VirtImageChoice(
                  id: 'alpine/3.22/default',
                  label: 'Alpine 3.22 (amd64, default)',
                  os: 'Alpine',
                  release: '3.22',
                  variant: 'default',
                  architectures: ['amd64'],
                  instanceTypes: ['CONTAINER'],
                ),
              ],
              storagePool: 'tank',
            ),
          );
      if (result != null) onSubmit(result);
    },
    child: const Text('open'),
  ),
);

Future<void> _pumpEdit(
  WidgetTester tester, {
  required ValueChanged<VirtInstanceConfiguration> onSubmit,
}) => _pump(
  tester,
  builder: (context) => FilledButton(
    onPressed: () async {
      final result = await showModalBottomSheet<VirtInstanceConfiguration>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditInstanceSheet(instance: _instance),
      );
      if (result != null) onSubmit(result);
    },
    child: const Text('open'),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required WidgetBuilder builder,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Builder(builder: builder)),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
