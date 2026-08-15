import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/nfs_share_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('reviews a new unrestricted NFS share', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
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
          body: NfsShareSheet(
            datasets: [
              Dataset(
                id: 'tank/projects',
                name: 'tank/projects',
                type: 'FILESYSTEM',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('New NFS share'), findsOneWidget);
    expect(find.text('/mnt/tank/projects'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review NFS share'), findsOneWidget);
    expect(find.text('All networks and hosts'), findsOneWidget);
    expect(
      find.textContaining('writable export allows all networks'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Create share'), findsOneWidget);
  });

  testWidgets('restores an NFS share for editing', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final share = NfsShare.fromJson({
      'id': 7,
      'path': '/mnt/tank/archive',
      'comment': 'Archive',
      'networks': ['10.0.0.0/24'],
      'hosts': ['backup.local'],
      'ro': true,
      'mapall_user': 'backup',
      'mapall_group': 'backup',
      'security': ['KRB5P'],
      'enabled': true,
      'expose_snapshots': true,
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
          body: NfsShareSheet(
            datasets: const [
              Dataset(
                id: 'tank/archive',
                name: 'tank/archive',
                type: 'FILESYSTEM',
              ),
            ],
            existingShare: share,
          ),
        ),
      ),
    );

    expect(find.text('Edit NFS share'), findsOneWidget);
    expect(find.text('10.0.0.0/24'), findsOneWidget);
    expect(find.text('Kerberos + privacy'), findsOneWidget);
    final enterpriseNotice = find.textContaining('Enterprise-only value');
    await tester.scrollUntilVisible(
      enterpriseNotice,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(enterpriseNotice, findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
    expect(find.text('backup : backup'), findsOneWidget);
  });
}
