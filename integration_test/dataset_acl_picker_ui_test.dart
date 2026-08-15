import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/storage/domain/dataset_acl.dart';
import 'package:true_dock/features/storage/presentation/dataset_acl_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ACL principal picker stays compact and searchable', (
    tester,
  ) async {
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
            initialAcl: DatasetAcl(
              path: '/mnt/tank/media',
              type: DatasetAclType.posix1e,
              entries: [],
              uid: 0,
              gid: 0,
            ),
            users: [
              DatasetAclPrincipal(
                name: 'root',
                id: 0,
                kind: DatasetAclPrincipalKind.user,
              ),
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
            ],
            groups: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dataset-acl-principal-selector')),
    );
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('dataset-acl-principal-list'));
    expect(list, findsOneWidget);
    expect(
      tester.getSize(list).height,
      lessThan(
        tester.view.physicalSize.height / tester.view.devicePixelRatio * .5,
      ),
    );
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
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TrueNAS ACL'));
    await tester.pumpAndSettle();
    expect(find.text('ACL 유형을 변경할까요?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('confirm-dataset-acl-type-change')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('대응 항목이 없는'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('ACL 유형: POSIX'), findsOneWidget);
  });

  testWidgets('current ownership stays selectable without account inventory', (
    tester,
  ) async {
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
            initialAcl: DatasetAcl(
              path: '/mnt/tank/media',
              type: DatasetAclType.posix1e,
              entries: [],
              uid: 0,
              gid: 0,
              user: 'root',
              group: 'wheel',
            ),
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
    expect(tester.takeException(), isNull);
  });

  testWidgets('POSIX ACL exposes independent permission checkboxes', (
    tester,
  ) async {
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
            initialAcl: DatasetAcl(
              path: '/mnt/tank/media',
              type: DatasetAclType.posix1e,
              entries: [
                DatasetAclEntry(
                  tag: 'USER_OBJ',
                  permissions: {'READ': true, 'WRITE': false, 'EXECUTE': true},
                  id: -1,
                  isDefault: false,
                ),
              ],
              uid: 0,
              gid: 0,
              user: 'root',
              group: 'wheel',
            ),
            users: [],
            groups: [],
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
    await tester.tap(
      find.descendant(of: write, matching: find.byType(Checkbox)),
    );
    await tester.pump();
    expect(
      tester
          .widget<Checkbox>(
            find.descendant(of: write, matching: find.byType(Checkbox)),
          )
          .value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
