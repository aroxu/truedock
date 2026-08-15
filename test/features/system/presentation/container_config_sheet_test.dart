import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/container_configuration.dart';
import 'package:true_dock/features/system/presentation/container_config_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

const _container = ManagedContainer(
  id: 7,
  uuid: 'uuid-7',
  name: 'plex',
  state: 'STOPPED',
  dataset: 'tank/apps/plex',
  autostart: true,
  deviceCount: 1,
);

const _baseline = ContainerConfiguration(
  name: 'plex',
  description: 'Media server',
  dataset: 'tank/apps/plex',
  autostart: true,
  vcpus: 2,
  memoryLimitMiB: 2048,
  devices: [
    {'path': '/dev/sda'},
  ],
  volumes: [],
  environment: {},
);

Widget _harness({
  required ContainerConfiguration baseline,
  Map<String, String> deviceChoices = const {},
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
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showModalBottomSheet<ContainerConfiguration>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => ContainerConfigSheet(
                container: _container,
                baseline: baseline,
                deviceChoices: deviceChoices,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(_harness(baseline: _baseline));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _scrollToDevices(WidgetTester tester) async {
  // The Devices section lives below the fold in the form ListView. Scroll
  // until it is built so find.text can see it.
  final listFinder = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    find.text('Devices'),
    200,
    scrollable: listFinder,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists existing devices with derived labels', (tester) async {
    await _open(tester);
    await _scrollToDevices(tester);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('/dev/sda'), findsOneWidget);
    expect(find.text('No devices attached.'), findsNothing);
  });

  testWidgets('removes a device when the remove button is tapped', (
    tester,
  ) async {
    await _open(tester);
    await _scrollToDevices(tester);
    expect(find.text('/dev/sda'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove device'));
    await tester.pumpAndSettle();
    expect(find.text('/dev/sda'), findsNothing);
    expect(find.text('No devices attached.'), findsOneWidget);
  });

  testWidgets('hides the Add device button when choices are empty', (
    tester,
  ) async {
    await _open(tester);
    await _scrollToDevices(tester);
    expect(find.text('Add device'), findsNothing);
  });

  testWidgets('shows Add device when choices are available', (tester) async {
    await tester.pumpWidget(
      _harness(
        baseline: _baseline,
        deviceChoices: {'/dev/sdb': 'Host sdb', '/dev/sdc': 'Host sdc'},
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _scrollToDevices(tester);
    expect(find.text('Add device'), findsOneWidget);
  });

  testWidgets('add device opens the picker and appends the chosen device', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        baseline: _baseline,
        deviceChoices: {'/dev/sdb': 'Host sdb', '/dev/sdc': 'Host sdc'},
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _scrollToDevices(tester);
    await tester.tap(find.text('Add device'));
    await tester.pumpAndSettle();
    // Picker is open.
    expect(find.text('Host sdb'), findsOneWidget);
    expect(find.text('Host sdc'), findsOneWidget);
    await tester.tap(find.text('Host sdb'));
    await tester.pumpAndSettle();
    // The chosen device now appears in the device list.
    expect(find.text('/dev/sdb'), findsOneWidget);
    // The original device is still there.
    expect(find.text('/dev/sda'), findsOneWidget);
  });

  testWidgets('the returned config carries the edited device list', (
    tester,
  ) async {
    final completer = Completer<ContainerConfiguration?>();
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
    final future = showModalBottomSheet<ContainerConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ContainerConfigSheet(
        container: _container,
        baseline: _baseline,
        deviceChoices: {'/dev/sdb': 'Host sdb'},
      ),
    );
    future.then(completer.complete);
    await tester.pumpAndSettle();
    await _scrollToDevices(tester);
    // Add a device.
    await tester.tap(find.text('Add device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host sdb'));
    await tester.pumpAndSettle();
    // Scroll back to the device list after the picker closed.
    await _scrollToDevices(tester);
    // Remove the original device.
    // The first row is the original /dev/sda; the second is the new /dev/sdb.
    await tester.tap(find.byTooltip('Remove device').first);
    await tester.pumpAndSettle();
    // Submit through Review -> Save changes.
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    final result = await completer.future;
    expect(result, isNotNull);
    expect(result!.devices, [
      {'path': '/dev/sdb'},
    ]);
  });
}
