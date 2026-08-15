import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_client_provider.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/system_administration_screen.dart';
import 'package:true_dock/features/system/presentation/system_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Restart and shut down are the only actions in the app that cannot report
/// their own outcome: the connection drops as they run, so the confirmation is
/// the last accurate thing the user sees. Verifying it on a real server means
/// rebooting one, which is why this pins the behaviour a simulator run cannot -
/// that the impact summary is read from live server state rather than being
/// static text, and that a single tap can never reach system.reboot.
void main() {
  testWidgets('restart counts the workloads it will actually interrupt', (
    tester,
  ) async {
    final client = _RecordingClient();
    await _openPower(tester, client);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Restart server'));
    await tester.pumpAndSettle();

    expect(find.text('Restart server?'), findsOneWidget);
    expect(find.text('Lab NAS'), findsWidgets);

    // The counts have to come from the loaded resources. Static wording would
    // read identically on an idle server and on one mid-replication.
    expect(
      find.textContaining('2 running app(s) and 1 running VM(s)'),
      findsOneWidget,
      reason: 'the summary must reflect what is running right now',
    );
    expect(
      find.textContaining('1 job is still running'),
      findsOneWidget,
      reason: 'an in-flight job is the strongest reason not to restart',
    );
    expect(find.textContaining('loses access immediately'), findsOneWidget);
    expect(
      find.textContaining('cannot confirm the result'),
      findsOneWidget,
      reason: 'the app goes silent mid-action; it must say so beforehand',
    );

    // Nothing has been sent yet.
    expect(client.calls, isEmpty);
  });

  testWidgets('restart needs the server name typed, not one tap', (
    tester,
  ) async {
    final client = _RecordingClient();
    await _openPower(tester, client);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Restart server'));
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(FilledButton, 'Restart now');
    expect(
      tester.widget<FilledButton>(confirm).onPressed,
      isNull,
      reason: 'restart must not be reachable by a single tap',
    );

    // A near miss must not unlock it either.
    final typedConfirmation = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(typedConfirmation, 'Lab');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(client.calls, isEmpty);

    await tester.enterText(typedConfirmation, 'Lab NAS');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(client.calls.single.$1, 'system.reboot');
  });

  testWidgets('cancelling leaves the server untouched', (tester) async {
    final client = _RecordingClient();
    await _openPower(tester, client);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Shut down server'));
    await tester.pumpAndSettle();

    expect(find.text('Shut down server?'), findsOneWidget);
    // Shutdown says the opposite of restart: nothing brings it back remotely.
    expect(find.textContaining('comes back on its own'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(client.calls, isEmpty);
  });

  testWidgets('power controls are hidden without the server methods', (
    tester,
  ) async {
    await _openPower(tester, _RecordingClient(), methods: const {});

    expect(find.widgetWithText(OutlinedButton, 'Restart server'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Shut down server'),
      findsNothing,
    );
    expect(
      find.textContaining('cannot restart or shut down'),
      findsOneWidget,
      reason: 'a permission gap must be explained, not silently blank',
    );
  });

  testWidgets('boot environments live in Advanced, not Updates', (
    tester,
  ) async {
    await _openSection(tester, _RecordingClient(), section: 'advanced');

    expect(
      find.byKey(const ValueKey('advanced-boot-environments-section')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('general-power-section')), findsNothing);

    await _openSection(tester, _RecordingClient(), section: 'updates');

    expect(
      find.byKey(const ValueKey('advanced-boot-environments-section')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('general-power-section')), findsNothing);
  });

  testWidgets('updates refresh their status every second', (tester) async {
    final client = _RecordingClient();
    await _openSection(
      tester,
      client,
      section: 'updates',
      methods: const {'update.run', 'update.file'},
    );

    final before = client.calls
        .where((call) => call.$1 == 'update.status')
        .length;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final afterOneSecond = client.calls
        .where((call) => call.$1 == 'update.status')
        .length;
    expect(afterOneSecond, greaterThan(before));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(
      client.calls.where((call) => call.$1 == 'update.status').length,
      greaterThan(afterOneSecond),
    );
    // Manual firmware upload was intentionally removed; channel selection is
    // the supported update path.
    expect(find.text('Custom firmware'), findsNothing);
    expect(find.text('Choose update file'), findsNothing);
  });
}

Future<void> _openPower(
  WidgetTester tester,
  _RecordingClient client, {
  Set<String> methods = const {'system.reboot', 'system.shutdown'},
}) async {
  await _openSection(tester, client, section: 'general', methods: methods);
  await tester.scrollUntilVisible(
    find.text('Power'),
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openSection(
  WidgetTester tester,
  _RecordingClient client, {
  required String section,
  Set<String> methods = const {'system.reboot', 'system.shutdown'},
}) async {
  tester.view.physicalSize = const Size(430, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trueNasClientProvider.overrideWithValue(client),
        connectionControllerProvider.overrideWith(
          (ref) => _StubConnectionController(methods),
        ),
        systemResourcesProvider.overrideWith(
          (ref) async => const SystemResources(),
        ),
        serverResourcesProvider.overrideWith((ref) async => _resources),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SystemAdministrationScreen(section: section),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Two running apps, one running VM, one active job - so the confirmation has
/// something specific to report and a static string would be visibly wrong.
final _resources = ServerResources(
  apps: ResourceSection<InstalledApp>(
    items: [
      InstalledApp.fromJson(const {
        'id': 'immich',
        'name': 'immich',
        'state': 'RUNNING',
        'version': '1.0',
      }),
      InstalledApp.fromJson(const {
        'id': 'syncthing',
        'name': 'syncthing',
        'state': 'RUNNING',
        'version': '1.0',
      }),
      InstalledApp.fromJson(const {
        'id': 'plex',
        'name': 'plex',
        'state': 'STOPPED',
        'version': '1.0',
      }),
    ],
  ),
  virtualMachines: ResourceSection<VirtualMachine>(
    items: [
      VirtualMachine.fromJson(const {
        'id': 1,
        'name': 'build-vm',
        'status': {'state': 'RUNNING'},
      }),
    ],
  ),
  jobs: ResourceSection<SystemJob>(
    items: [
      SystemJob.fromJson(const {
        'id': 11,
        'method': 'replication.run',
        'state': 'RUNNING',
        'abortable': true,
      }),
      SystemJob.fromJson(const {
        'id': 10,
        'method': 'pool.scrub.scrub',
        'state': 'SUCCESS',
        'abortable': false,
      }),
    ],
  ),
);

class _StubConnectionController extends ConnectionController {
  _StubConnectionController(Set<String> methods)
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: ServerProfile.parse(
        name: 'Lab NAS',
        address: 'https://truenas.local',
      ),
      capabilities: ServerCapabilities(
        productType: 'COMMUNITY_EDITION',
        version: const TrueNasVersion(25, 10, 0),
        methods: methods,
      ),
    );
  }
}

class _RecordingClient extends TrueNasJsonRpcClient {
  final List<(String, List<Object?>)> calls = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (method == 'system.general.config') {
      return {
        'hostname': 'truenas',
        'description': 'Lab NAS',
        'timezone': 'Asia/Seoul',
        'sysloglevel': 'F_INFO',
      };
    }
    if (method == 'system.general.timezone_choices') {
      return [
        {'id': 'Asia/Seoul', 'label': 'Asia/Seoul'},
      ];
    }
    calls.add((method, params));
    return 1;
  }
}
