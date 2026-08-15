// Guards the shared active-job poll.
//
// Every authenticated route is wrapped in an `ActiveJobsFabHost`, and go_router
// keeps pushed routes mounted underneath the visible one. When the one-second
// poll lived in each host's state, navigating three screens deep ran three
// timers that all invalidated the same provider, so the app sent three
// `core.get_jobs` calls a second and decoded three copies of the same answer.
//
// These tests pin the reference-counting contract: one timer while any host is
// mounted, none once the last one goes away.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Counts how many times the job feed was actually re-read.
var _reads = 0;

ProviderContainer _container() => ProviderContainer(
  overrides: [
    connectionControllerProvider.overrideWith((ref) => _ConnectedController()),
    activeJobsProvider.overrideWith((ref) async {
      _reads++;
      return const ResourceSection<SystemJob>();
    }),
  ],
);

Widget _app(ProviderContainer container, {required int depth}) {
  Widget tree = const Scaffold(body: Center(child: Text('화면 내용')));
  // Reproduces a navigation stack: each pushed route adds another host around
  // the ones already mounted.
  for (var level = 0; level < depth; level++) {
    tree = ActiveJobsFabHost(child: tree);
  }
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: tree,
    ),
  );
}

void main() {
  setUp(() => _reads = 0);

  testWidgets('a single host runs exactly one poll timer', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, depth: 1));
    await tester.pumpAndSettle();

    expect(container.read(activeJobsPollerProvider).activeTimers, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(container.read(activeJobsPollerProvider).activeTimers, 0);
  });

  testWidgets('a deep navigation stack still runs only one poll timer', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, depth: 4));
    await tester.pumpAndSettle();

    expect(container.read(activeJobsPollerProvider).activeTimers, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(container.read(activeJobsPollerProvider).activeTimers, 0);
  });

  testWidgets('nested hosts do not multiply the job reads', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, depth: 3));
    await tester.pumpAndSettle();
    final afterMount = _reads;

    // Three ticks. One timer means three reads, not nine.
    for (var tick = 0; tick < 3; tick++) {
      await tester.pump(ActiveJobsPoller.interval);
      await tester.pumpAndSettle();
    }

    expect(_reads - afterMount, 3);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('popping back to one host keeps the poll running', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, depth: 3));
    await tester.pumpAndSettle();
    expect(container.read(activeJobsPollerProvider).activeTimers, 1);

    // Unwinding the stack must not stop the poll while a host remains.
    await tester.pumpWidget(_app(container, depth: 1));
    await tester.pumpAndSettle();
    expect(container.read(activeJobsPollerProvider).activeTimers, 1);

    final before = _reads;
    await tester.pump(ActiveJobsPoller.interval);
    await tester.pumpAndSettle();
    expect(_reads - before, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(container.read(activeJobsPollerProvider).activeTimers, 0);
  });
}
