import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/widgets/active_jobs_fab.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

class _ConnectedController extends ConnectionController {
  _ConnectedController()
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = const NasConnectionState(stage: ConnectionStage.connected);
  }
}

final _running = SystemJob.fromJson(const {
  'id': 42,
  'method': 'pool.scrub.scrub',
  'state': 'RUNNING',
  'progress': {'percent': 37, 'description': 'Scrubbing tank'},
  'time_started': {r'$date': 1760000000000},
});

Widget _host(ResourceSection<SystemJob> jobs) => ProviderScope(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => _ConnectedController()),
    activeJobsProvider.overrideWith((ref) async => jobs),
    jobDetailProvider.overrideWith((ref, id) async {
      for (final job in jobs.items) {
        if (job.id == id) return job;
      }
      return null;
    }),
  ],
  child: const MaterialApp(
    locale: Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ActiveJobsFabHost(
      child: Scaffold(body: Center(child: Text('화면 내용'))),
    ),
  ),
);

final _liveJobsProvider = StateProvider<ResourceSection<SystemJob>>(
  (ref) => const ResourceSection(),
);

ProviderContainer _liveContainer(ResourceSection<SystemJob> jobs) =>
    ProviderContainer(
      overrides: [
        connectionControllerProvider.overrideWith(
          (ref) => _ConnectedController(),
        ),
        _liveJobsProvider.overrideWith((ref) => jobs),
        activeJobsProvider.overrideWith(
          (ref) async => ref.watch(_liveJobsProvider),
        ),
        jobDetailProvider.overrideWith((ref, id) async {
          for (final job in ref.watch(_liveJobsProvider).items) {
            if (job.id == id) return job;
          }
          return null;
        }),
      ],
    );

Widget _liveHost(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(
    locale: Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ActiveJobsFabHost(
      child: Scaffold(body: Center(child: Text('화면 내용'))),
    ),
  ),
);

void main() {
  testWidgets('hides the global job FAB when no job is active', (tester) async {
    await tester.pumpWidget(_host(const ResourceSection()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-jobs-fab')), findsNothing);
    expect(find.text('화면 내용'), findsOneWidget);
  });

  testWidgets('opens active list and then the selected job detail', (
    tester,
  ) async {
    await tester.pumpWidget(_host(ResourceSection(items: [_running])));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-jobs-fab')), findsOneWidget);
    expect(find.byTooltip('실행 중인 작업 1개'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('active-jobs-fab')));
    await tester.pumpAndSettle();
    expect(find.text('실행 중인 작업'), findsOneWidget);
    expect(find.text('풀 스크럽'), findsOneWidget);
    expect(find.text('pool.scrub.scrub'), findsNothing);
    expect(find.text('Scrubbing tank'), findsOneWidget);
    expect(find.text('37%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('active-job-42')));
    await tester.pumpAndSettle();
    expect(find.text('작업 ID'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('API 메서드'), findsOneWidget);
    expect(find.text('pool.scrub.scrub'), findsOneWidget);
    expect(find.text('진행률'), findsOneWidget);
    expect(find.text('37%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('job detail polls live progress, step, and terminal state', (
    tester,
  ) async {
    final container = _liveContainer(ResourceSection(items: [_running]));
    addTearDown(container.dispose);
    await tester.pumpWidget(_liveHost(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('active-jobs-fab')));
    await tester.pumpAndSettle();
    expect(find.text('37%'), findsOneWidget);

    final updated = SystemJob.fromJson(const {
      'id': 42,
      'method': 'pool.scrub.scrub',
      'state': 'RUNNING',
      'progress': {'percent': 68, 'description': 'Scrubbing data vdev'},
      'time_started': {r'$date': 1760000000000},
    });
    container.read(_liveJobsProvider.notifier).state = ResourceSection(
      items: [updated],
    );
    await tester.pumpAndSettle();

    expect(find.text('68%'), findsOneWidget);
    expect(find.text('Scrubbing data vdev'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('active-job-42')));
    await tester.pumpAndSettle();
    expect(find.text('68%'), findsOneWidget);

    final completed = SystemJob.fromJson(const {
      'id': 42,
      'method': 'pool.scrub.scrub',
      'state': 'SUCCESS',
      'progress': {'percent': 100, 'description': 'Finished'},
      'time_started': {r'$date': 1760000000000},
      'time_finished': {r'$date': 1760000100000},
    });
    container.read(_liveJobsProvider.notifier).state = ResourceSection(
      items: [completed],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('성공'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
