import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/truedock_dropdown.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_extent_configuration.dart';
import 'package:true_dock/features/storage/presentation/iscsi_target_extent_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('creates an association with automatic LUN assignment', (
    tester,
  ) async {
    _configurePhoneView(tester);
    IscsiTargetExtentConfiguration? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SheetLauncher(
          targets: _targets,
          extents: const [_writableExtent],
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('New iSCSI association'), findsOneWidget);
    expect(find.text('Media clients — iqn.media'), findsOneWidget);
    expect(find.text('Media — zvol/tank/media'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI association'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Read and write'), findsOneWidget);
    expect(find.textContaining('read and write access'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create association'));
    await tester.pumpAndSettle();

    expect(result?.targetId, 3);
    expect(result?.extentId, 7);
    expect(result?.lunId, isNull);
  });

  testWidgets('validates an explicit create LUN and returns the selection', (
    tester,
  ) async {
    _configurePhoneView(tester);
    IscsiTargetExtentConfiguration? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SheetLauncher(
          targets: _targets,
          extents: const [_writableExtent, _readOnlyExtent],
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TrueDockDropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup — iqn.backup').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TrueDockDropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive — /mnt/tank/archive.img').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '-1');
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();

    expect(find.text('Use a nonnegative LUN ID.'), findsOneWidget);
    expect(find.text('New iSCSI association'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    expect(find.text('Read-only'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Create association'));
    await tester.pumpAndSettle();

    expect(result?.targetId, 8);
    expect(result?.extentId, 9);
    expect(result?.lunId, 4);
  });

  testWidgets('edits with a concrete LUN and warns for unavailable storage', (
    tester,
  ) async {
    _configurePhoneView(tester);
    IscsiTargetExtentConfiguration? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SheetLauncher(
          targets: _targets,
          extents: const [_unavailableExtent],
          existingAssociation: const IscsiTargetExtent(
            id: 12,
            targetId: 8,
            extentId: 11,
            lunId: 6,
          ),
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Edit iSCSI association'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '6',
    );
    expect(find.textContaining('selected extent is disabled'), findsOneWidget);
    expect(find.textContaining('selected extent is locked'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(result?.targetId, 8);
    expect(result?.extentId, 11);
    expect(result?.lunId, 12);
  });

  testWidgets('requires a concrete LUN when an old association has none', (
    tester,
  ) async {
    _configurePhoneView(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _SheetLauncher(
          targets: _targets,
          extents: const [_writableExtent],
          existingAssociation: const IscsiTargetExtent(
            id: 12,
            targetId: 3,
            extentId: 7,
          ),
          onResult: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();

    expect(find.text('Enter a nonnegative LUN ID.'), findsOneWidget);
    expect(find.text('Edit iSCSI association'), findsOneWidget);
  });
}

class _SheetLauncher extends StatelessWidget {
  const _SheetLauncher({
    required this.targets,
    required this.extents,
    required this.onResult,
    this.existingAssociation,
  });

  final List<IscsiTarget> targets;
  final List<IscsiExtent> extents;
  final IscsiTargetExtent? existingAssociation;
  final ValueChanged<IscsiTargetExtentConfiguration> onResult;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () async {
          final result =
              await showModalBottomSheet<IscsiTargetExtentConfiguration>(
                context: context,
                isScrollControlled: true,
                builder: (_) => IscsiTargetExtentSheet(
                  targets: targets,
                  extents: extents,
                  existingAssociation: existingAssociation,
                ),
              );
          if (result != null) onResult(result);
        },
        child: const Text('Open sheet'),
      ),
    ),
  );
}

const _targets = [
  IscsiTarget(
    id: 3,
    name: 'iqn.media',
    alias: 'Media clients',
    mode: 'ISCSI',
    groups: [],
  ),
  IscsiTarget(
    id: 8,
    name: 'iqn.backup',
    alias: 'Backup',
    mode: 'ISCSI',
    groups: [],
  ),
];

const _writableExtent = IscsiExtent(
  id: 7,
  name: 'Media',
  type: 'DISK',
  backingStore: 'zvol/tank/media',
  enabled: true,
  readOnly: false,
  locked: false,
  blockSize: 4096,
);

const _readOnlyExtent = IscsiExtent(
  id: 9,
  name: 'Archive',
  type: 'FILE',
  backingStore: '/mnt/tank/archive.img',
  enabled: true,
  readOnly: true,
  locked: false,
  blockSize: 512,
);

const _unavailableExtent = IscsiExtent(
  id: 11,
  name: 'Encrypted',
  type: 'DISK',
  backingStore: 'zvol/tank/encrypted',
  enabled: false,
  readOnly: false,
  locked: true,
  blockSize: 4096,
);

void _configurePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
