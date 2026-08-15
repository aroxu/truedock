import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/data_protection/presentation/snapshot_actions_sheet.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('offers clone, rollback, and delete when supported', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Clone to new dataset'), findsOneWidget);
    expect(find.text('Roll back to this snapshot'), findsOneWidget);
    expect(find.text('Delete snapshot'), findsOneWidget);
    expect(find.text('Hold snapshot'), findsOneWidget);
  });

  testWidgets('hides actions the server does not expose', (tester) async {
    await _open(tester, canRollback: false, canDelete: false, canHold: false);

    expect(find.text('Clone to new dataset'), findsOneWidget);
    expect(find.text('Roll back to this snapshot'), findsNothing);
    expect(find.text('Delete snapshot'), findsNothing);
    expect(find.text('Hold snapshot'), findsNothing);
  });

  testWidgets('explains when no snapshot action is available', (tester) async {
    await _open(
      tester,
      canClone: false,
      canRollback: false,
      canDelete: false,
      canHold: false,
    );

    expect(
      find.textContaining('does not expose snapshot actions'),
      findsOneWidget,
    );
  });

  testWidgets('a held snapshot cannot be deleted until it is released', (
    tester,
  ) async {
    SnapshotAction? action;
    await _open(tester, held: true, onResult: (value) => action = value);

    expect(find.text('Release hold'), findsOneWidget);
    expect(
      find.text('Release the hold before deleting this snapshot.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete snapshot'));
    await tester.pumpAndSettle();
    expect(action, isNull);

    await tester.tap(find.text('Release hold'));
    await tester.pumpAndSettle();
    expect((action! as SnapshotHoldAction).held, isFalse);
  });

  testWidgets('requests a hold on an unheld snapshot', (tester) async {
    SnapshotAction? action;
    await _open(tester, onResult: (value) => action = value);

    await tester.tap(find.text('Hold snapshot'));
    await tester.pumpAndSettle();

    expect((action! as SnapshotHoldAction).held, isTrue);
  });

  testWidgets('counts newer snapshots destroyed by a rollback', (tester) async {
    await _open(tester, newerSnapshotCount: 3);

    expect(find.textContaining('3 newer snapshots'), findsOneWidget);

    await tester.tap(find.text('Roll back to this snapshot'));
    await tester.pumpAndSettle();

    // The safest mode is preselected and warns that it will fail outright.
    expect(
      find.textContaining('will fail until you choose to destroy them'),
      findsOneWidget,
    );
  });

  testWidgets('returns the chosen rollback mode and force flag', (
    tester,
  ) async {
    SnapshotAction? action;
    await _open(tester, newerSnapshotCount: 2, onResult: (a) => action = a);

    await tester.tap(find.text('Roll back to this snapshot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Destroy newer snapshots and their clones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Force unmount if busy'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final rollback = action! as SnapshotRollbackAction;
    expect(rollback.mode, SnapshotRollbackMode.newerSnapshotsAndClones);
    expect(rollback.force, isTrue);
  });

  testWidgets('returns a delete request directly', (tester) async {
    SnapshotAction? action;
    await _open(tester, onResult: (a) => action = a);

    await tester.tap(find.text('Delete snapshot'));
    await tester.pumpAndSettle();

    expect(action, isA<SnapshotDeleteAction>());
  });

  testWidgets('validates the clone destination path', (tester) async {
    SnapshotAction? action;
    await _open(tester, onResult: (a) => action = a);

    await tester.tap(find.text('Clone to new dataset'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nopath');
    await tester.tap(find.widgetWithText(FilledButton, 'Create clone'));
    await tester.pumpAndSettle();
    expect(find.textContaining('full dataset path'), findsOneWidget);
    expect(action, isNull);

    await tester.enterText(find.byType(TextField), 'tank/media');
    await tester.tap(find.widgetWithText(FilledButton, 'Create clone'));
    await tester.pumpAndSettle();
    expect(find.textContaining('different from the source'), findsOneWidget);
    expect(action, isNull);

    await tester.enterText(find.byType(TextField), 'tank/restored');
    await tester.tap(find.widgetWithText(FilledButton, 'Create clone'));
    await tester.pumpAndSettle();

    expect((action! as SnapshotCloneAction).destination, 'tank/restored');
  });
}

Future<void> _open(
  WidgetTester tester, {
  int newerSnapshotCount = 0,
  bool canDelete = true,
  bool canRollback = true,
  bool canClone = true,
  bool canHold = true,
  bool held = false,
  ValueChanged<SnapshotAction?>? onResult,
}) async {
  tester.view.physicalSize = const Size(430, 1400);
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
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showModalBottomSheet<SnapshotAction>(
                context: context,
                isScrollControlled: true,
                builder: (context) => SnapshotActionsSheet(
                  snapshot: SnapshotEntry.fromJson({
                    'id': 'tank/media@daily',
                    'dataset': 'tank/media',
                    'snapshot_name': 'daily',
                    'createtxg': '4210',
                    if (held) 'holds': const {'truenas': 1},
                  }),
                  newerSnapshotCount: newerSnapshotCount,
                  canDelete: canDelete,
                  canRollback: canRollback,
                  canClone: canClone,
                  canHold: canHold,
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
