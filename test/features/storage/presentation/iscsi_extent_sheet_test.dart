import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_extent_configuration.dart';
import 'package:true_dock/features/storage/presentation/iscsi_extent_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('reviews and returns a disk extent configuration', (
    tester,
  ) async {
    _configurePhoneView(tester);
    IscsiExtentConfiguration? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ExtentHarness(
          diskChoices: const {
            'zvol/tank/data': 'tank/data (20 GiB)',
            'zvol/tank/archive': 'tank/archive (50 GiB)',
          },
          onResult: (value) => result = value,
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.text('New iSCSI extent'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'data-extent');
    await tester.tap(find.byKey(const Key('extent-disk-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tank/data (20 GiB)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI extent'), findsOneWidget);
    expect(find.text('data-extent'), findsOneWidget);
    expect(find.text('tank/data (20 GiB)'), findsOneWidget);
    expect(find.text('512 bytes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create extent'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create extent'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'data-extent');
    expect(result!.type, IscsiExtentType.disk);
    expect(result!.disk, 'zvol/tank/data');
    expect(result!.path, isNull);
    expect(result!.fileSize, 0);
    expect(result!.blockSize, 512);
    expect(result!.rpm, IscsiExtentRpm.ssd);
    expect(result!.readOnly, isFalse);
    expect(result!.enabled, isTrue);
  });

  testWidgets('preserves every field when editing a file extent', (
    tester,
  ) async {
    _configurePhoneView(tester);
    final extent = IscsiExtent.fromJson({
      'id': 12,
      'name': 'backup-file',
      'type': 'FILE',
      'disk': null,
      'serial': 'FILE0001',
      'path': '/mnt/tank/iscsi/backup.img',
      'filesize': '1073741824',
      'blocksize': 2048,
      'pblocksize': true,
      'avail_threshold': 15,
      'comment': 'Backup target',
      'insecure_tpc': false,
      'xen': true,
      'rpm': '10000',
      'ro': true,
      'enabled': false,
      'product_id': 'Backup Disk',
      'locked': false,
    });
    IscsiExtentConfiguration? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ExtentHarness(
          diskChoices: const {'zvol/tank/data': 'tank/data'},
          existingExtent: extent,
          onResult: (value) => result = value,
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.text('Edit iSCSI extent'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('extent-path-field')))
          .controller
          ?.text,
      '/mnt/tank/iscsi/backup.img',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('extent-file-size-field')))
          .controller
          ?.text,
      '1073741824',
    );
    expect(
      find.textContaining('can allocate the requested space'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI extent'), findsOneWidget);
    expect(find.text('/mnt/tank/iscsi/backup.img'), findsOneWidget);
    expect(find.text('1073741824 bytes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'backup-file');
    expect(result!.type, IscsiExtentType.file);
    expect(result!.disk, isNull);
    expect(result!.serial, 'FILE0001');
    expect(result!.path, '/mnt/tank/iscsi/backup.img');
    expect(result!.fileSize, 1073741824);
    expect(result!.blockSize, 2048);
    expect(result!.physicalBlockSize, isTrue);
    expect(result!.availableThreshold, 15);
    expect(result!.comment, 'Backup target');
    expect(result!.insecureTpc, isFalse);
    expect(result!.xen, isTrue);
    expect(result!.rpm, IscsiExtentRpm.rpm10000);
    expect(result!.readOnly, isTrue);
    expect(result!.enabled, isFalse);
    expect(result!.productId, 'Backup Disk');
  });

  testWidgets('requires a current disk when the previous disk is unavailable', (
    tester,
  ) async {
    _configurePhoneView(tester);
    final extent = IscsiExtent.fromJson({
      'id': 19,
      'name': 'old-zvol',
      'type': 'DISK',
      'disk': 'zvol/tank/removed',
      'filesize': 0,
      'blocksize': 512,
      'enabled': true,
      'ro': false,
      'locked': false,
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _ExtentHarness(
          diskChoices: const {'zvol/tank/current': 'tank/current (10 GiB)'},
          existingExtent: extent,
          onResult: (_) {},
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.textContaining('previous backing store'), findsOneWidget);
    expect(find.textContaining('zvol/tank/removed'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();

    expect(find.text('Edit iSCSI extent'), findsOneWidget);
    expect(find.text('Select a disk or zvol.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('extent-disk-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tank/current (10 GiB)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI extent'), findsOneWidget);
    final disruptionWarning = find.textContaining(
      'Existing target mappings can be disrupted',
    );
    await tester.scrollUntilVisible(
      disruptionWarning,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(disruptionWarning, findsOneWidget);
    expect(find.text('tank/current (10 GiB)'), findsOneWidget);
  });
}

class _ExtentHarness extends StatefulWidget {
  const _ExtentHarness({
    required this.diskChoices,
    required this.onResult,
    this.existingExtent,
  });

  final Map<String, String> diskChoices;
  final IscsiExtent? existingExtent;
  final ValueChanged<IscsiExtentConfiguration?> onResult;

  @override
  State<_ExtentHarness> createState() => _ExtentHarnessState();
}

class _ExtentHarnessState extends State<_ExtentHarness> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () async {
          final result = await showModalBottomSheet<IscsiExtentConfiguration>(
            context: context,
            isScrollControlled: true,
            builder: (context) => IscsiExtentSheet(
              diskChoices: widget.diskChoices,
              existingExtent: widget.existingExtent,
            ),
          );
          widget.onResult(result);
        },
        child: const Text('Open extent'),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open extent'));
  await tester.pumpAndSettle();
}

void _configurePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
