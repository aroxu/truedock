import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/iscsi_configuration_sheets.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('reviews a new portal using available static addresses', (
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
        home: Scaffold(
          body: IscsiPortalSheet(
            availableAddresses: ['10.20.0.10', '192.168.40.5'],
          ),
        ),
      ),
    );

    expect(find.text('New iSCSI portal'), findsOneWidget);
    expect(find.text('10.20.0.10'), findsOneWidget);
    expect(find.text('192.168.40.5'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '10.20.0.10'))
          .selected,
      isTrue,
    );

    await tester.tap(find.widgetWithText(FilterChip, '192.168.40.5'));
    await tester.enterText(find.byType(TextField), 'Storage network');
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI portal'), findsOneWidget);
    expect(find.text('10.20.0.10, 192.168.40.5'), findsOneWidget);
    expect(find.text('3260 (managed by TrueNAS)'), findsOneWidget);
    expect(find.text('Storage network'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create portal'), findsOneWidget);
  });

  testWidgets('restores an existing portal for editing', (tester) async {
    _configurePhoneView(tester);
    const portal = IscsiPortal(
      id: 8,
      tag: 3,
      comment: 'Backup fabric',
      listen: [IscsiPortalListen(ip: '172.16.8.12', port: 3260)],
    );
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
          body: IscsiPortalSheet(
            availableAddresses: ['10.20.0.10', '172.16.8.12'],
            existingPortal: portal,
          ),
        ),
      ),
    );

    expect(find.text('Edit iSCSI portal'), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '172.16.8.12'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '10.20.0.10'))
          .selected,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Backup fabric',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI portal'), findsOneWidget);
    expect(find.text('172.16.8.12'), findsOneWidget);
    expect(find.text('Backup fabric'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
  });

  testWidgets('warns when a new initiator group allows every client', (
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
        home: Scaffold(body: IscsiInitiatorSheet()),
      ),
    );

    expect(find.text('New initiator group'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review initiator group'), findsOneWidget);
    expect(find.text('All initiators'), findsOneWidget);
    expect(find.textContaining('allows every initiator'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create group'), findsOneWidget);
  });

  testWidgets('restores an existing initiator group and offers save', (
    tester,
  ) async {
    _configurePhoneView(tester);
    const initiator = IscsiInitiator(
      id: 11,
      initiators: ['iqn.2026-08.me.aroxu:backup', '10.20.0.44'],
      comment: 'Backup clients',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: IscsiInitiatorSheet(existingInitiator: initiator)),
      ),
    );

    expect(find.text('Edit initiator group'), findsOneWidget);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(
      fields.first.controller?.text,
      'iqn.2026-08.me.aroxu:backup\n10.20.0.44',
    );
    expect(fields.last.controller?.text, 'Backup clients');

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review initiator group'), findsOneWidget);
    expect(
      find.text('iqn.2026-08.me.aroxu:backup, 10.20.0.44'),
      findsOneWidget,
    );
    expect(find.text('Backup clients'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
  });

  testWidgets('blocks review for duplicate initiator entries', (tester) async {
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
        home: Scaffold(body: IscsiInitiatorSheet()),
      ),
    );

    await tester.enterText(
      find.byType(TextField).first,
      'iqn.2026-08.me.aroxu:host\niqn.2026-08.me.aroxu:host',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();

    expect(find.text('New initiator group'), findsOneWidget);
    expect(
      find.text('Use unique IQNs or IP addresses without whitespace.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Review'), findsOneWidget);
  });
}

void _configurePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
