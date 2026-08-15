import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/vm_device.dart';
import 'package:true_dock/features/system/presentation/vm_device_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// A disk carrying attributes the form does not surface. TrueNAS replaces the
/// whole attribute set on update, so these must survive an edit.
const _disk = VmDevice(
  id: 7,
  vmId: 1,
  type: VmDeviceType.disk,
  attributes: {
    'path': '/dev/zvol/tank/vm',
    'size': 10240,
    'type': 'AHCI',
    'logical_sectorsize': 512,
    'boot': true,
  },
);

const _nic = VmDevice(
  id: 8,
  vmId: 1,
  type: VmDeviceType.nic,
  attributes: {'mac': '52:54:00:aa:bb:cc', 'nic_attach': 'br0'},
);

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Opens the editor and returns the future that completes with the sheet's
/// result. The setup is awaited here; the caller must not await the returned
/// future until it has driven the form, or the test would deadlock.
Future<Future<VmDeviceConfiguration?>> _openEditor(
  WidgetTester tester,
  VmDevice device,
) async {
  final completer = Completer<VmDeviceConfiguration?>();
  late BuildContext captured;
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
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  showModalBottomSheet<VmDeviceConfiguration>(
    context: captured,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => VmDeviceAddSheet(existing: device),
  ).then(completer.complete);
  await tester.pumpAndSettle();
  return completer.future;
}

void main() {
  testWidgets('the add form is titled for adding', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VmDeviceAddSheet()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add VM device'), findsOneWidget);
    expect(find.text('Add device'), findsOneWidget);
  });

  testWidgets('the edit form is titled for editing and seeds the fields', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VmDeviceAddSheet(existing: _disk)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit VM device'), findsOneWidget);
    expect(find.text('Save device'), findsOneWidget);
    expect(find.text('/dev/zvol/tank/vm'), findsOneWidget);
    expect(find.text('10240'), findsOneWidget);
  });

  testWidgets('editing preserves attributes the form does not surface', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final result = await _openEditor(tester, _disk);
    await tester.enterText(
      find.widgetWithText(TextField, 'Path'),
      '/dev/zvol/tank/vm2',
    );
    await tester.pump();
    await tester.tap(find.text('Save device'));
    await tester.pumpAndSettle();

    final configuration = await result;
    expect(configuration, isNotNull);
    final json = configuration!.toUpdateApiJson();
    // The edited field changed.
    expect(json['path'], '/dev/zvol/tank/vm2');
    // Everything the form never showed survived, because TrueNAS replaces the
    // attribute set rather than merging it.
    expect(json['type'], 'AHCI');
    expect(json['logical_sectorsize'], 512);
    expect(json['boot'], true);
    expect(json['dtype'], 'DISK');
  });

  testWidgets('clearing the MAC asks the server to regenerate it', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    final result = await _openEditor(tester, _nic);
    expect(find.text('52:54:00:aa:bb:cc'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'MAC address (optional)'),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('Save device'));
    await tester.pumpAndSettle();

    final configuration = await result;
    final json = configuration!.toUpdateApiJson();
    // Sending an empty MAC would be rejected; removing the key restores the
    // server's auto-generation.
    expect(json.containsKey('mac'), isFalse);
    // The unsurfaced bridge attachment is still preserved.
    expect(json['nic_attach'], 'br0');
  });

  testWidgets('a disk edit still requires a path', (tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VmDeviceAddSheet(existing: _disk)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Path'), '');
    await tester.pump();
    await tester.tap(find.text('Save device'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a path for the disk.'), findsOneWidget);
  });

  testWidgets('the device list offers edit only when the server supports it', (
    tester,
  ) async {
    _usePhoneSurface(tester);
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
          body: VmDeviceSheet(
            devices: const [_disk],
            canCreate: true,
            canDelete: true,
            canEdit: false,
            onAddDevice: () async => null,
            onDeleteDevice: (_) async => false,
            onEditDevice: (_) async => false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit device'), findsNothing);
    expect(find.byTooltip('Remove device'), findsOneWidget);
  });

  testWidgets('tapping edit asks the caller to handle it', (tester) async {
    _usePhoneSurface(tester);
    VmDevice? edited;
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
          body: VmDeviceSheet(
            devices: const [_disk],
            canCreate: true,
            canDelete: true,
            canEdit: true,
            onAddDevice: () async => null,
            onDeleteDevice: (_) async => false,
            onEditDevice: (device) async {
              edited = device;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit device'));
    await tester.pumpAndSettle();
    expect(edited?.id, 7);
  });
}
