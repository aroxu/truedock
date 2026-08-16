import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/interface_configuration.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/features/system/presentation/interface_config_sheet.dart';

const _static = InterfaceConfiguration(
  id: 'eno1',
  name: 'eno1',
  description: 'LAN',
  ipv4Dhcp: false,
  aliases: [InterfaceAlias(address: '192.168.1.10', netmask: 24)],
  mtu: 1500,
);

const _dhcp = InterfaceConfiguration(id: 'eno2', name: 'eno2', ipv4Dhcp: true);

Widget _harness({
  InterfaceConfiguration baseline = _static,
  String? dhcpOwnedByOtherInterface,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InterfaceConfigSheet(
        baseline: baseline,
        dhcpOwnedByOtherInterface: dhcpOwnedByOtherInterface,
      ),
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// The default 800x600 test surface squeezes the sheet so tightly that rows
/// collide with the bottom action bar and taps land on the wrong widget. Use a
/// realistic phone surface instead.
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('seeds the existing addressing and always warns about staging', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('Edit eno1'), findsOneWidget);
    expect(find.textContaining('Interface changes are staged'), findsOneWidget);
    await _scrollTo(tester, find.text('192.168.1.10/24'));
    expect(find.text('192.168.1.10/24'), findsOneWidget);
  });

  testWidgets('turning DHCP on hides static IPv4 but keeps IPv6 controls', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Static addresses'));
    expect(find.text('Static addresses'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Add IPv6 address'));
    expect(find.text('Static addresses'), findsOneWidget);
    expect(find.text('192.168.1.10/24'), findsNothing);
    expect(find.text('Add IPv6 address'), findsOneWidget);
  });

  testWidgets('turning automatic IPv6 on hides and disables manual IPv6', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final baseline = _static.copyWith(
      aliases: const [
        InterfaceAlias(address: '192.168.1.10', netmask: 24),
        InterfaceAlias(address: 'fd00::10', netmask: 64, type: 'INET6'),
      ],
    );
    await tester.pumpWidget(_harness(baseline: baseline));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(SwitchListTile).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).at(1));
    await tester.pumpAndSettle();

    expect(find.text('fd00::10/64'), findsNothing);
    await _scrollTo(tester, find.text('Add IPv6 address'));
    final addIpv6 = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Add IPv6 address'),
    );
    expect(addIpv6.onPressed, isNull);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.textContaining(
        'Turning on automatic IPv6 removes the static IPv6 addresses',
      ),
    );
    expect(
      find.textContaining(
        'Turning on automatic IPv6 removes the static IPv6 addresses',
      ),
      findsOneWidget,
    );
  });

  testWidgets('warns when another interface already owns DHCP', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(baseline: _dhcp, dhcpOwnedByOtherInterface: 'eno1'),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('eno1 already uses DHCP'));
    expect(find.textContaining('eno1 already uses DHCP'), findsOneWidget);
  });

  testWidgets('blocks review when static mode has no addresses', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      _harness(baseline: _static.copyWith(aliases: const [])),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.textContaining('Add at least one static address'),
    );
    expect(
      find.textContaining('Add at least one static address'),
      findsOneWidget,
    );
    expect(find.text('Review eno1'), findsNothing);
  });

  testWidgets('blocks review for an out-of-range MTU', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.widgetWithText(TextField, 'MTU (optional)'));
    await tester.enterText(
      find.widgetWithText(TextField, 'MTU (optional)'),
      '10',
    );
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Use an MTU between 68 and 9216.'), findsOneWidget);
  });

  testWidgets('removes a static address', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('192.168.1.10/24'));
    expect(find.text('192.168.1.10/24'), findsOneWidget);
    final removeIcon = find.byIcon(Icons.remove_circle_outline_rounded);
    await tester.ensureVisible(removeIcon);
    await tester.pumpAndSettle();
    await tester.tap(removeIcon);
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.10/24'), findsNothing);
    expect(find.text('No static addresses configured.'), findsOneWidget);
  });

  testWidgets('adds a static address through the alias editor', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Add IPv4 address'));
    await tester.tap(find.text('Add IPv4 address'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Address'),
      '192.168.1.20',
    );
    await tester.pump();
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.20/24'), findsOneWidget);
    expect(find.text('192.168.1.10/24'), findsOneWidget);
  });

  testWidgets('the alias editor rejects a malformed address', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Add IPv4 address'));
    await tester.tap(find.text('Add IPv4 address'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Address'),
      '999.1.1.1',
    );
    await tester.pump();
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid IPv4 address.'), findsOneWidget);
  });

  testWidgets('switching the alias editor to IPv6 defaults the prefix to 64', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Add IPv6 address'));
    await tester.tap(find.text('Add IPv6 address'));
    await tester.pumpAndSettle();
    expect(find.text('64'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Address'),
      'fd00::10',
    );
    await tester.pump();
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(find.text('fd00::10/64'), findsOneWidget);
  });

  testWidgets('review reports when nothing changed', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review eno1'), findsOneWidget);
    expect(find.textContaining('Nothing changed'), findsOneWidget);
  });

  testWidgets('review warns that switching to DHCP drops static addresses', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await _scrollTo(
      tester,
      find.textContaining('Switching to DHCP removes the static addresses'),
    );
    expect(
      find.textContaining('Switching to DHCP removes the static addresses'),
      findsOneWidget,
    );
  });

  testWidgets('returns a configuration whose payload clears aliases for DHCP', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final completer = Completer<InterfaceConfiguration?>();
    late BuildContext capturedContext;
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
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showModalBottomSheet<InterfaceConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const InterfaceConfigSheet(baseline: _static),
    ).then(completer.complete);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stage change'));
    await tester.pumpAndSettle();

    final result = await completer.future;
    expect(result, isNotNull);
    expect(result!.ipv4Dhcp, isTrue);
    final json = result.toApiJson();
    expect(json['ipv4_dhcp'], true);
    expect(json['aliases'], isEmpty);
  });
}
