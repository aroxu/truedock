import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/truedock_dropdown.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_configuration.dart';
import 'package:true_dock/features/storage/presentation/iscsi_target_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('creates and returns an unrestricted NONE target group', (
    tester,
  ) async {
    _configurePhoneView(tester);
    await tester.pumpWidget(
      _localizedApp(
        home: const _TargetSheetHost(
          portals: [_portal],
          initiators: [_initiator],
        ),
      ),
    );

    await tester.tap(find.text('Open target sheet'));
    await tester.pumpAndSettle();
    expect(find.text('New iSCSI target'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Target name'),
      'iqn.2026-08.me.aroxu:media',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Authorized networks'),
      '10.20.0.0/24',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add group'));
    await tester.pump();

    expect(find.text('Unauthenticated group 1'), findsOneWidget);
    final unrestrictedNotice = find.textContaining('allows every initiator');
    await tester.scrollUntilVisible(
      unrestrictedNotice,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(unrestrictedNotice, findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI target'), findsOneWidget);
    expect(find.text('iqn.2026-08.me.aroxu:media'), findsOneWidget);
    expect(find.text('10.20.0.0/24'), findsOneWidget);
    expect(find.text('Group 1 · NONE'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Create target'));
    await tester.pumpAndSettle();

    expect(
      find.text('Saved iqn.2026-08.me.aroxu:media · 1 group(s)'),
      findsOneWidget,
    );
  });

  testWidgets('allows zero groups after warning that target is unreachable', (
    tester,
  ) async {
    _configurePhoneView(tester);
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: IscsiTargetSheet(portals: [_portal], initiators: [], auths: []),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Target name'),
      'iqn.2026-08.me.aroxu:offline',
    );
    expect(find.textContaining('will be unreachable'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI target'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(
      find.textContaining('created without a portal group'),
      findsOneWidget,
    );
  });

  testWidgets('preserves authenticated groups as locked when editing', (
    tester,
  ) async {
    _configurePhoneView(tester);
    final target = IscsiTarget.fromJson({
      'id': 7,
      'name': 'iqn.2026-08.me.aroxu:archive',
      'alias': 'Archive',
      'mode': 'ISCSI',
      'groups': [
        {'portal': 4, 'initiator': 9, 'authmethod': 'CHAP', 'auth': 12},
      ],
      'auth_networks': ['192.0.2.0/24'],
      'iscsi_parameters': {'QueuedCommands': 128},
    });
    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: IscsiTargetSheet(
            portals: const [_portal],
            initiators: const [_initiator],
            auths: const [],
            existingTarget: target,
          ),
        ),
      ),
    );

    expect(find.text('Edit iSCSI target'), findsOneWidget);
    expect(find.text('CHAP group'), findsOneWidget);
    expect(find.text('Credential ID: 12'), findsOneWidget);
    expect(find.textContaining('cannot be changed or removed'), findsOneWidget);
    expect(find.byTooltip('Remove group 1'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();
    expect(find.text('Group 1 · CHAP'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save changes'), findsOneWidget);
  });

  testWidgets('shows configuration validation errors before review', (
    tester,
  ) async {
    _configurePhoneView(tester);
    await tester.pumpWidget(
      _localizedApp(
        home: const Scaffold(
          body: IscsiTargetSheet(portals: [], initiators: [], auths: []),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Authorized networks'),
      '10.20.0.0/99',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pump();

    expect(find.text('New iSCSI target'), findsOneWidget);
    expect(
      find.text('Enter a target name between 1 and 120 characters.'),
      findsOneWidget,
    );
    expect(
      find.text('Use unique IPv4 or IPv6 networks in CIDR notation.'),
      findsOneWidget,
    );
  });

  testWidgets('lets a new group pick a CHAP credential', (tester) async {
    _configurePhoneView(tester);
    const auth = IscsiAuth(id: 11, tag: 1, user: 'alice');
    await tester.pumpWidget(
      _localizedApp(
        home: const _TargetSheetHost(
          portals: [_portal],
          initiators: [_initiator],
          auths: [auth],
        ),
      ),
    );

    await tester.tap(find.text('Open target sheet'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Target name'),
      'iqn.2026-08.me.aroxu:secure',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add group'));
    await tester.pump();

    // Choose CHAP (one-way) authentication.
    final authField = find.byWidgetPredicate(
      (widget) =>
          widget is TrueDockDropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Authentication',
    );
    await tester.ensureVisible(authField);
    await tester.pumpAndSettle();
    await tester.tap(authField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHAP (one-way)').last);
    await tester.pumpAndSettle();

    // The credential dropdown should now be visible with alice.
    await tester.scrollUntilVisible(
      find.text('alice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('alice'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review iSCSI target'), findsOneWidget);
    expect(find.text('Group 1 · CHAP'), findsOneWidget);
    expect(find.text('Credential ID 11'), findsOneWidget);
  });

  testWidgets('renders target form and validation feedback in Korean', (
    tester,
  ) async {
    _configurePhoneView(tester);
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('ko'),
        home: const Scaffold(
          body: IscsiTargetSheet(portals: [], initiators: [], auths: []),
        ),
      ),
    );

    expect(find.text('새 iSCSI 타깃'), findsOneWidget);
    expect(find.text('타깃 이름'), findsOneWidget);
    expect(find.textContaining('사용 가능한 iSCSI 포털이 없습니다'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, '허용된 네트워크'),
      '10.20.0.0/99',
    );
    await tester.tap(find.widgetWithText(FilledButton, '검토'));
    await tester.pump();
    expect(find.text('타깃 이름을 1~120자로 입력하세요.'), findsOneWidget);
    expect(find.textContaining('CIDR 표기법'), findsOneWidget);
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

const _portal = IscsiPortal(
  id: 4,
  tag: 2,
  comment: 'Storage fabric',
  listen: [IscsiPortalListen(ip: '10.20.0.10', port: 3260)],
);

const _initiator = IscsiInitiator(
  id: 9,
  initiators: ['iqn.2026-08.me.aroxu:client'],
  comment: 'Media clients',
);

class _TargetSheetHost extends StatefulWidget {
  const _TargetSheetHost({
    required this.portals,
    required this.initiators,
    this.auths = const [],
  });

  final List<IscsiPortal> portals;
  final List<IscsiInitiator> initiators;
  final List<IscsiAuth> auths;

  @override
  State<_TargetSheetHost> createState() => _TargetSheetHostState();
}

class _TargetSheetHostState extends State<_TargetSheetHost> {
  IscsiTargetConfiguration? _configuration;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _configuration == null
          ? FilledButton(
              onPressed: _openSheet,
              child: const Text('Open target sheet'),
            )
          : Text(
              'Saved ${_configuration!.name.trim()} · ${_configuration!.groups.length} group(s)',
            ),
    ),
  );

  Future<void> _openSheet() async {
    final result = await showModalBottomSheet<IscsiTargetConfiguration>(
      context: context,
      isScrollControlled: true,
      builder: (context) => IscsiTargetSheet(
        portals: widget.portals,
        initiators: widget.initiators,
        auths: widget.auths,
      ),
    );
    if (result != null && mounted) setState(() => _configuration = result);
  }
}

void _configurePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
