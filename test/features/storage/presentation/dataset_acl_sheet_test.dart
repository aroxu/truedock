import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/domain/dataset_acl.dart';
import 'package:true_dock/features/storage/presentation/dataset_acl_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

const _acl = DatasetAcl(
  path: '/mnt/tank/media',
  type: DatasetAclType.posix1e,
  entries: [],
  uid: 0,
  gid: 0,
  user: 'root',
  group: 'wheel',
);

const _users = [
  DatasetAclPrincipal(name: 'root', id: 0, kind: DatasetAclPrincipalKind.user),
  DatasetAclPrincipal(
    name: 'daemon',
    id: 1,
    kind: DatasetAclPrincipalKind.user,
  ),
  DatasetAclPrincipal(
    name: 'alice',
    id: 1000,
    kind: DatasetAclPrincipalKind.user,
  ),
];

const _groups = [
  DatasetAclPrincipal(
    name: 'wheel',
    id: 0,
    kind: DatasetAclPrincipalKind.group,
  ),
  DatasetAclPrincipal(
    name: 'media',
    id: 1000,
    kind: DatasetAclPrincipalKind.group,
  ),
];

void main() {
  testWidgets('principal chooser is a compact searchable bottom sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester);
    await tester.pumpAndSettle();

    final selector = find.byKey(
      const ValueKey('dataset-acl-principal-selector'),
    );
    expect(
      find.descendant(of: selector, matching: find.text('User')),
      findsNothing,
    );
    expect(
      find.descendant(of: selector, matching: find.text('Choose User')),
      findsOneWidget,
    );

    await tester.tap(selector);
    await tester.pumpAndSettle();

    expect(find.text('Choose User'), findsWidgets);
    expect(
      find.byKey(const ValueKey('dataset-acl-principal-search')),
      findsOneWidget,
    );
    final listSize = tester.getSize(
      find.byKey(const ValueKey('dataset-acl-principal-list')),
    );
    expect(listSize.height, lessThan(844 * .5));
  });

  testWidgets('search filters principals and selection closes the picker', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dataset-acl-principal-selector')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('dataset-acl-principal-search')),
      'ali',
    );
    await tester.pump();
    expect(find.text('alice'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dataset-acl-principal-list')),
        matching: find.text('root'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    expect(find.text('alice'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dataset-acl-principal-search')),
      findsNothing,
    );
    expect(find.text('alice'), findsOneWidget);
  });

  testWidgets('POSIX permissions use independent read write execute checks', (
    tester,
  ) async {
    const acl = DatasetAcl(
      path: '/mnt/tank/media',
      type: DatasetAclType.posix1e,
      entries: [
        DatasetAclEntry(
          tag: 'USER_OBJ',
          permissions: {'READ': true, 'WRITE': true, 'EXECUTE': true},
          id: -1,
          isDefault: false,
        ),
      ],
      uid: 0,
      gid: 0,
      user: 'root',
      group: 'wheel',
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DatasetAclSheet(
            datasetName: 'tank/media',
            initialAcl: acl,
            users: _users,
            groups: _groups,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final read = find.byKey(const ValueKey('posix-read-USER_OBJ--1'));
    final write = find.byKey(const ValueKey('posix-write-USER_OBJ--1'));
    final execute = find.byKey(const ValueKey('posix-execute-USER_OBJ--1'));
    expect(read, findsOneWidget);
    expect(write, findsOneWidget);
    expect(execute, findsOneWidget);
    for (final finder in [read, write, execute]) {
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(of: finder, matching: find.byType(Checkbox)),
            )
            .value,
        isTrue,
      );
    }

    await tester.tap(
      find.descendant(of: read, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    await tester.tap(
      find.descendant(of: execute, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: read, matching: find.byType(Checkbox)),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: write, matching: find.byType(Checkbox)),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: execute, matching: find.byType(Checkbox)),
          )
          .value,
      isFalse,
    );
    expect(find.byKey(const ValueKey('truedock-dropdown-list')), findsNothing);
  });

  testWidgets('changes owner and group and returns them in the result', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dataset-acl-owner-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dataset-acl-owner-group-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('media'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final result = _result;
    expect(result, isNotNull);
    expect(result!.acl.uid, 1000);
    expect(result.acl.gid, 1000);
    expect(result.ownerChanged, isTrue);
  });

  testWidgets('converts POSIX rules to TrueNAS ACL rules', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TrueNAS ACL'));
    await tester.pumpAndSettle();
    expect(find.text('Change ACL type?'), findsOneWidget);
    expect(find.textContaining('POSIX to TrueNAS ACL'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirm-dataset-acl-type-change')),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('ACL type: POSIX'), findsOneWidget);
    expect(find.textContaining('rebuilds the rules'), findsOneWidget);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(_result?.acl.type, DatasetAclType.nfs4);
    expect(_result?.typeChanged, isTrue);
  });

  testWidgets('current owner choices stay enabled before account lists load', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DatasetAclSheet(
            datasetName: 'tank/media',
            initialAcl: _acl,
            users: [],
            groups: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final owner = find.byKey(const ValueKey('dataset-acl-owner-selector'));
    final group = find.byKey(
      const ValueKey('dataset-acl-owner-group-selector'),
    );
    expect(find.descendant(of: owner, matching: find.text('root')), findsOne);
    expect(find.descendant(of: group, matching: find.text('wheel')), findsOne);

    await tester.tap(owner);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dataset-acl-principal-list')),
      findsOneWidget,
    );
  });

  testWidgets('cancelling ACL type warning preserves POSIX rules', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TrueNAS ACL'));
    await tester.pumpAndSettle();
    expect(find.text('Change ACL type?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('cancel-dataset-acl-type-change')),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<SegmentedButton<DatasetAclType>>(
      find.byKey(const ValueKey('dataset-acl-type-selector')),
    );
    expect(selector.selected, {DatasetAclType.posix1e});
    expect(find.textContaining('rebuilds the rules'), findsNothing);
  });
}

DatasetAclEditResult? _result;

Future<void> _pump(WidgetTester tester) {
  _result = null;
  return tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _AclHarness(),
    ),
  );
}

class _AclHarness extends StatefulWidget {
  const _AclHarness();

  @override
  State<_AclHarness> createState() => _AclHarnessState();
}

class _AclHarnessState extends State<_AclHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _result = await showModalBottomSheet<DatasetAclEditResult>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const DatasetAclSheet(
          datasetName: 'tank/media',
          initialAcl: _acl,
          users: _users,
          groups: _groups,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
