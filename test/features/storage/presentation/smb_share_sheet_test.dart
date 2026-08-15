import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/smb_share_configuration.dart';
import 'package:true_dock/features/storage/presentation/smb_share_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('reviews a new default SMB share', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: SmbShareSheet(
            datasets: [
              Dataset(
                id: 'tank/projects',
                name: 'tank/projects',
                type: 'FILESYSTEM',
              ),
            ],
            presets: [
              SmbSharePreset(
                purpose: SmbSharePurpose.defaultShare,
                label: 'Default',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('New SMB share'), findsOneWidget);
    expect(find.text('/mnt/tank/projects'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review SMB share'), findsOneWidget);
    expect(find.text('projects'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create share'), findsOneWidget);
  });

  testWidgets('restores a Time Machine share for editing', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final share = SmbShare.fromJson({
      'id': 3,
      'name': 'Backups',
      'path': '/mnt/tank/backups',
      'purpose': 'TIMEMACHINE_SHARE',
      'enabled': true,
      'readonly': false,
      'browsable': true,
      'access_based_share_enumeration': false,
      'locked': false,
      'audit': {'enable': false, 'watch_list': [], 'ignore_list': []},
      'options': {
        'timemachine_quota': 1073741824,
        'auto_snapshot': true,
        'auto_dataset_creation': false,
        'dataset_naming_schema': null,
        'vuid': 'volume-id',
        'hostsallow': [],
        'hostsdeny': [],
      },
    });
    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: SmbShareSheet(
            datasets: const [
              Dataset(
                id: 'tank/backups',
                name: 'tank/backups',
                type: 'FILESYSTEM',
              ),
            ],
            presets: const [
              SmbSharePreset(
                purpose: SmbSharePurpose.timeMachine,
                label: 'Time Machine',
              ),
            ],
            existingShare: share,
          ),
        ),
      ),
    );

    expect(find.text('Edit SMB share'), findsOneWidget);
    expect(find.text('Time Machine'), findsOneWidget);
    expect(find.text('1073741824'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
    expect(find.text('Backups'), findsOneWidget);
  });

  testWidgets('renders SMB form and review in Korean', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('ko'),
        home: const Scaffold(
          body: SmbShareSheet(
            datasets: [
              Dataset(
                id: 'tank/projects',
                name: 'tank/projects',
                type: 'FILESYSTEM',
              ),
            ],
            presets: [
              SmbSharePreset(
                purpose: SmbSharePurpose.defaultShare,
                label: 'Default',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('새 SMB 공유'), findsOneWidget);
    expect(find.text('기본 공유'), findsOneWidget);
    expect(find.text('공유 이름'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '검토'));
    await tester.pumpAndSettle();
    expect(find.text('SMB 공유 검토'), findsOneWidget);
    expect(find.text('읽기 및 쓰기'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '공유 생성'), findsOneWidget);
  });

  testWidgets('shows matching dataset paths while typing', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: SmbShareSheet(
            datasets: [
              Dataset(id: 'tank/media', name: 'tank/media', type: 'FILESYSTEM'),
              Dataset(
                id: 'tank/movies',
                name: 'tank/movies',
                type: 'FILESYSTEM',
              ),
              Dataset(
                id: 'backup/docs',
                name: 'backup/docs',
                type: 'FILESYSTEM',
              ),
            ],
            presets: [
              SmbSharePreset(
                purpose: SmbSharePurpose.defaultShare,
                label: 'Default',
              ),
            ],
          ),
        ),
      ),
    );

    final field = find.byKey(const ValueKey('smb-share-path-field'));
    await tester.tap(field);
    await tester.enterText(field, 'tank/m');
    await tester.pump();

    expect(
      find.byKey(const ValueKey('smb-share-path-suggestions')),
      findsOneWidget,
    );
    expect(find.text('/mnt/tank/media'), findsWidgets);
    expect(find.text('/mnt/tank/movies'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('smb-share-path-suggestions')),
        matching: find.text('/mnt/backup/docs'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('smb-share-path-suggestions')),
        matching: find.text('/mnt/tank/media'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '/mnt/tank/media');
    expect(
      find.byKey(const ValueKey('smb-share-path-suggestions')),
      findsNothing,
    );
  });

  testWidgets('keeps the first floating field label inside the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: SmbShareSheet(
            datasets: [],
            presets: [
              SmbSharePreset(
                purpose: SmbSharePurpose.defaultShare,
                label: 'Default',
              ),
            ],
          ),
        ),
      ),
    );

    final label = find.text('Purpose');
    expect(label, findsOneWidget);
    expect(tester.getTopLeft(label).dy, greaterThan(100));
  });
}

MaterialApp _localizedApp({
  required Widget home,
  Locale locale = const Locale('en'),
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
