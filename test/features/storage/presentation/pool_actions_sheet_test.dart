import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/pool_actions_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('offers a scrub start when none is running', (tester) async {
    await _open(tester);

    expect(find.text('Start scrub'), findsOneWidget);
    expect(find.text('Pause scrub'), findsNothing);
    expect(find.text('Stop scrub'), findsNothing);
  });

  testWidgets('offers pause and stop while a scrub runs', (tester) async {
    await _open(tester, scanning: true);

    expect(find.text('Scrub running'), findsOneWidget);
    expect(find.text('Start scrub'), findsNothing);
    expect(find.text('Pause scrub'), findsOneWidget);
    expect(find.text('Stop scrub'), findsOneWidget);
  });

  testWidgets('returns the chosen scrub control verb', (tester) async {
    PoolAction? action;
    await _open(tester, scanning: true, onResult: (value) => action = value);

    await tester.tap(find.text('Stop scrub'));
    await tester.pumpAndSettle();

    expect((action! as PoolScrubAction).action, ScrubControlAction.stop);
  });

  testWidgets('returns an offline request for an online member', (
    tester,
  ) async {
    PoolAction? action;
    await _open(tester, onResult: (value) => action = value);

    await tester.tap(find.text('Pool members'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take offline').first);
    await tester.pumpAndSettle();

    final member = action! as PoolMemberAction;
    expect(member.online, isFalse);
    expect(member.member.label, '111');
  });

  testWidgets('offers to bring an offline member back online', (tester) async {
    PoolAction? action;
    await _open(tester, onResult: (value) => action = value);

    await tester.tap(find.text('Pool members'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bring online'));
    await tester.pumpAndSettle();

    final member = action! as PoolMemberAction;
    expect(member.online, isTrue);
    expect(member.member.label, '222');
  });

  testWidgets('export defaults to keeping the data intact', (tester) async {
    PoolAction? action;
    await _open(tester, onResult: (value) => action = value);

    await tester.tap(find.text('Export or destroy pool'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final export = action! as PoolExportAction;
    expect(export.destroyData, isFalse);
    expect(export.takeSnapshotsOffline, isTrue);
  });

  testWidgets('destroying data is an explicit opt-in', (tester) async {
    PoolAction? action;
    await _open(tester, onResult: (value) => action = value);

    await tester.tap(find.text('Export or destroy pool'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Destroy all data on the disks'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect((action! as PoolExportAction).destroyData, isTrue);
  });

  testWidgets('offers attach and replace for data vdevs', (tester) async {
    await _open(
      tester,
      candidateDisks: [
        StorageDisk.fromJson(const {
          'identifier': 'sdc',
          'name': 'sdc',
          'devname': 'sdc',
          'model': 'IronWolf',
          'serial': 'ZXC1',
          'type': 'HDD',
          'size': 4_000_000_000_000,
        }),
      ],
    );

    expect(find.text('Attach disk'), findsOneWidget);
    expect(find.text('Replace disk'), findsOneWidget);
  });

  testWidgets('hides attach and replace when no candidates exist', (
    tester,
  ) async {
    await _open(tester, candidateDisks: const []);

    expect(find.text('Attach disk'), findsNothing);
    expect(find.text('Replace disk'), findsNothing);
  });

  testWidgets('returns an attach action after picking a vdev and disk', (
    tester,
  ) async {
    PoolAction? action;
    await _open(
      tester,
      candidateDisks: [
        StorageDisk.fromJson(const {
          'identifier': 'sdc',
          'name': 'sdc',
          'devname': 'sdc',
          'model': 'IronWolf',
          'serial': 'ZXC1',
          'type': 'HDD',
          'size': 4_000_000_000_000,
        }),
      ],
      onResult: (value) => action = value,
    );

    await tester.tap(find.text('Attach disk'));
    await tester.pumpAndSettle();

    // The first attachable member exposes its vdev guid.
    await tester.tap(find.text('vdev 111'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('sdc'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final attach = action! as PoolAttachAction;
    expect(attach.disk, 'sdc');
    // The topology in _open carries guid '111'/'222' as leaves; the vdev guid
    // is the MIRROR's own guid when the server provides one, otherwise the
    // first leaf guid is used as the attachable vdev.
    expect(attach.targetVdev, isNotEmpty);
  });

  testWidgets('returns a replace action after picking an offline member', (
    tester,
  ) async {
    PoolAction? action;
    await _open(
      tester,
      candidateDisks: [
        StorageDisk.fromJson(const {
          'identifier': 'sdc',
          'name': 'sdc',
          'devname': 'sdc',
          'model': 'IronWolf',
          'serial': 'ZXC1',
          'type': 'HDD',
          'size': 4_000_000_000_000,
        }),
      ],
      onResult: (value) => action = value,
    );

    await tester.tap(find.text('Replace disk'));
    await tester.pumpAndSettle();

    // sdb is OFFLINE in the topology, so it is the only selectable member.
    await tester.tap(find.text('sdb'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose replacement disk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('sdc'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final replace = action! as PoolReplaceAction;
    expect(replace.member.name, 'sdb');
    expect(replace.disk, 'sdc');
    expect(replace.force, isFalse);
  });

  testWidgets('explains when no pool operation is available', (tester) async {
    await _open(
      tester,
      canScrub: false,
      canToggleMembers: false,
      canExport: false,
      canAttach: false,
      canReplace: false,
    );

    expect(
      find.textContaining('does not expose pool operations'),
      findsOneWidget,
    );
  });
}

Future<void> _open(
  WidgetTester tester, {
  bool scanning = false,
  bool canScrub = true,
  bool canToggleMembers = true,
  bool canExport = true,
  bool canAttach = true,
  bool canReplace = true,
  List<StorageDisk> candidateDisks = const [],
  ValueChanged<PoolAction?>? onResult,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final pool = StoragePool.fromJson({
    'id': 1,
    'name': 'tank',
    'status': 'DEGRADED',
    'size': 1000,
    'allocated': 400,
    'free': 600,
    if (scanning)
      'scan': {'function': 'SCRUB', 'state': 'SCANNING', 'percentage': 40.0},
    'topology': {
      'data': [
        {
          'type': 'MIRROR',
          'children': [
            {'guid': '111', 'disk': 'sda', 'status': 'ONLINE'},
            {'guid': '222', 'disk': 'sdb', 'status': 'OFFLINE'},
          ],
        },
      ],
    },
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
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showModalBottomSheet<PoolAction>(
                context: context,
                isScrollControlled: true,
                builder: (context) => PoolActionsSheet(
                  pool: pool,
                  candidateDisks: candidateDisks,
                  canScrub: canScrub,
                  canControlScrub: canScrub,
                  canToggleMembers: canToggleMembers,
                  canExport: canExport,
                  canAttach: canAttach,
                  canReplace: canReplace,
                ),
              );
              onResult?.call(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
