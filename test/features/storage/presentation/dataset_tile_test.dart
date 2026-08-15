import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_tile.dart';
import 'package:true_dock/l10n/app_localizations.dart';

Dataset _dataset({
  String name = 'tank/media',
  String? origin,
  bool locked = false,
  bool encrypted = false,
}) => Dataset(
  id: name,
  name: name,
  type: 'FILESYSTEM',
  origin: origin,
  locked: locked,
  encrypted: encrypted,
);

Future<List<String>> _pump(
  WidgetTester tester, {
  required Dataset dataset,
  bool canPromote = true,
  bool canEdit = true,
  bool canRename = true,
  bool canDelete = true,
  bool canLock = true,
  bool canManageQuotas = true,
  bool canManageAcl = true,
  bool hasChildren = false,
  bool isExpanded = false,
  VoidCallback? onToggle,
}) async {
  final invoked = <String>[];
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
        body: DatasetTile(
          dataset: dataset,
          onCreateSnapshot: () => invoked.add('snapshot'),
          canEdit: canEdit,
          canRename: canRename,
          onEdit: () => invoked.add('edit'),
          onRename: () => invoked.add('rename'),
          canDelete: canDelete,
          onDelete: () => invoked.add('delete'),
          canLock: canLock,
          onLock: () => invoked.add('lock'),
          onUnlock: () => invoked.add('unlock'),
          canPromote: canPromote,
          onPromote: () => invoked.add('promote'),
          canManageQuotas: canManageQuotas,
          onManageQuotas: () => invoked.add('quotas'),
          canManageAcl: canManageAcl,
          onManageAcl: () => invoked.add('acl'),
          hasChildren: hasChildren,
          isExpanded: isExpanded,
          onToggle: onToggle,
        ),
      ),
    ),
  );
  return invoked;
}

void main() {
  testWidgets('leaf tap does not trigger an action', (tester) async {
    final invoked = await _pump(tester, dataset: _dataset());

    await tester.tap(find.byType(ListTile).first);
    await tester.pump();

    expect(invoked, isEmpty);
  });

  testWidgets('parent tap toggles and expansion icon rotates', (tester) async {
    var toggles = 0;
    await _pump(
      tester,
      dataset: _dataset(name: 'tank'),
      hasChildren: true,
      onToggle: () => toggles++,
    );

    final rotation = find.byKey(const ValueKey('dataset-expansion-tank'));
    expect(rotation, findsOneWidget);
    expect(tester.widget<AnimatedRotation>(rotation).turns, 0);

    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    expect(toggles, 1);

    await _pump(
      tester,
      dataset: _dataset(name: 'tank'),
      hasChildren: true,
      isExpanded: true,
      onToggle: () => toggles++,
    );
    expect(tester.widget<AnimatedRotation>(rotation).turns, 0.25);
  });

  testWidgets('offers promotion for a clone', (tester) async {
    final invoked = await _pump(
      tester,
      dataset: _dataset(name: 'tank/restored', origin: 'tank/media@auto-1'),
    );

    expect(find.textContaining('clone'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Promote clone'), findsOneWidget);

    await tester.tap(find.text('Promote clone'));
    await tester.pumpAndSettle();
    expect(invoked, ['promote']);
  });

  testWidgets('never offers promotion for an ordinary dataset', (tester) async {
    await _pump(tester, dataset: _dataset());

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Promotion is meaningless without an origin snapshot.
    expect(find.text('Promote clone'), findsNothing);
  });

  testWidgets('never offers promotion for an empty origin', (tester) async {
    // ZFS reports an empty string rather than omitting the property.
    await _pump(tester, dataset: _dataset(origin: ''));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Promote clone'), findsNothing);
  });

  testWidgets('hides promotion when the server lacks the method', (
    tester,
  ) async {
    await _pump(
      tester,
      dataset: _dataset(name: 'tank/restored', origin: 'tank/media@auto-1'),
      canPromote: false,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Promote clone'), findsNothing);
    // The clone itself is still labelled, because that is useful information.
    expect(find.textContaining('clone'), findsOneWidget);
  });

  testWidgets('a pool root cannot be renamed or deleted', (tester) async {
    final invoked = await _pump(tester, dataset: _dataset(name: 'tank'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Renaming a pool root is not a dataset operation, and destroying it is a
    // pool operation. Both entries stay visible but inert.
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(invoked, isEmpty);

    await tester.tap(find.text('Delete dataset'));
    await tester.pumpAndSettle();
    expect(invoked, isEmpty);
  });

  testWidgets('a locked dataset cannot take property changes', (tester) async {
    final invoked = await _pump(
      tester,
      dataset: _dataset(locked: true, encrypted: true),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit properties'));
    await tester.pumpAndSettle();
    expect(invoked, isEmpty);

    await tester.tap(find.text('Manage ACL'));
    await tester.pumpAndSettle();
    expect(invoked, isEmpty);
  });

  testWidgets('an unlocked filesystem offers ACL management', (tester) async {
    final invoked = await _pump(tester, dataset: _dataset());

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage ACL'));
    await tester.pumpAndSettle();

    expect(invoked, ['acl']);
  });

  testWidgets('an ordinary unlocked dataset can be edited and renamed', (
    tester,
  ) async {
    final invoked = await _pump(tester, dataset: _dataset(name: 'tank/media'));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit properties'));
    await tester.pumpAndSettle();

    // Proves the two tests above assert a real gate rather than a menu that
    // never fires at all.
    expect(invoked, ['edit']);
  });
}
