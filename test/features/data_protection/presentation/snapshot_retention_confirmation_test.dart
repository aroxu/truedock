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
import 'package:true_dock/features/data_protection/presentation/data_protection_screen.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Editing a periodic snapshot task is presented as a schedule change, but the
/// server reports how many *existing* snapshots the new retention would move a
/// deadline onto. Shortening a lifetime makes ZFS prune snapshots that already
/// exist and nothing restores them, so that case has to be confirmed like the
/// destructive action it is - while a schedule-only edit must not be, or the
/// serious prompt becomes noise the user learns to dismiss.
void main() {
  testWidgets(
    'names the server and the pruned snapshots when retention moves',
    (tester) async {
      final client = _RecordingClient(
        impact: const {
          'tank/documents': ['snap-a', 'snap-b', 'snap-c'],
        },
      );
      await _openEditor(tester, client);

      // The shared confirmation surface, not a plain dialog.
      expect(
        find.text('Server'),
        findsOneWidget,
        reason: 'a retention change must say which server it applies to',
      );
      expect(find.text('Lab NAS'), findsOneWidget);
      expect(find.text('What happens'), findsOneWidget);
      expect(
        find.textContaining('cannot be recovered'),
        findsOneWidget,
        reason: 'pruning is irreversible and has to be stated',
      );
      expect(
        find.textContaining('tank/documents: 3'),
        findsOneWidget,
        reason: "the server's own per-dataset count is the whole point",
      );

      // Nothing is applied until the user agrees.
      expect(
        client.calls.map((call) => call.$1),
        isNot(contains('pool.snapshottask.update')),
      );
    },
  );

  testWidgets('a schedule-only edit is not escalated', (tester) async {
    // The server reports no affected snapshots, so this really is just a
    // schedule edit. Escalating it anyway would train the user to dismiss the
    // destructive prompt along with the routine one.
    final client = _RecordingClient(impact: const {});
    await _openEditor(tester, client);

    expect(find.text('Update tank/documents?'), findsOneWidget);
    expect(
      find.textContaining('no existing snapshot retention changes'),
      findsOneWidget,
    );
    expect(
      find.text('Server'),
      findsNothing,
      reason: 'a schedule-only change must not use the destructive surface',
    );
  });
}

/// Drives the screen to the point where the retention decision is shown:
/// open the task's overflow menu, edit it, review, and continue.
Future<void> _openEditor(WidgetTester tester, _RecordingClient client) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trueNasClientProvider.overrideWithValue(client),
        connectionControllerProvider.overrideWith(
          (ref) => _StubConnectionController(),
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
        home: const Scaffold(body: DataProtectionScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip('Snapshot task actions').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit task'));
  await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(FilledButton, 'Review'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

final _resources = ServerResources(
  snapshotTasks: ResourceSection<SnapshotTask>(
    items: [
      SnapshotTask.fromJson(const {
        'id': 9,
        'dataset': 'tank/documents',
        'recursive': false,
        'lifetime_value': 2,
        'lifetime_unit': 'WEEK',
        'enabled': true,
        'naming_schema': 'auto-%Y%m%d',
        'allow_empty': true,
        'schedule': {
          'minute': '00',
          'hour': '*',
          'dom': '*',
          'month': '*',
          'dow': '*',
          'begin': '00:00',
          'end': '23:59',
        },
      }),
    ],
  ),
  datasets: const ResourceSection<Dataset>(
    items: [
      Dataset(id: 'tank/documents', name: 'tank/documents', type: 'FILESYSTEM'),
    ],
  ),
);

class _StubConnectionController extends ConnectionController {
  _StubConnectionController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
      profile: ServerProfile.parse(
        name: 'Lab NAS',
        address: 'https://truenas.local',
      ),
      capabilities: const ServerCapabilities(
        productType: 'COMMUNITY_EDITION',
        version: TrueNasVersion(25, 10, 0),
        methods: {
          'pool.snapshottask.update',
          'pool.snapshottask.update_will_change_retention_for',
          'pool.snapshottask.run',
          'pool.snapshottask.delete',
        },
      ),
    );
  }
}

/// Answers the retention preview with a fixed impact and records everything
/// else, so the test can assert nothing was applied before confirmation.
class _RecordingClient extends TrueNasJsonRpcClient {
  _RecordingClient({required this.impact});

  final Map<String, List<String>> impact;
  final List<(String, List<Object?>)> calls = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls.add((method, params));
    if (method == 'pool.snapshottask.update_will_change_retention_for') {
      return impact;
    }
    return {'id': 1};
  }
}
