import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_client_provider.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/jobs/presentation/job_center.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/core/domain/data_message.dart';

void main() {
  testWidgets('defaults to active jobs and shows progress', (tester) async {
    await _pumpJobCenter(tester, section: _section);

    expect(find.text('Scrub Pool'), findsOneWidget);
    expect(find.text('Scrubbing tank'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Terminal jobs stay hidden behind their own filters.
    expect(find.text('Upgrade App'), findsNothing);
    expect(find.text('Create Dataset'), findsNothing);
  });

  testWidgets('shows failures with their server error', (tester) async {
    await _pumpJobCenter(tester, section: _section);

    await tester.tap(find.textContaining('Failed ('));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade App'), findsOneWidget);
    expect(find.text('Image pull failed.'), findsOneWidget);
  });

  testWidgets('opens job detail with timing and log excerpt', (tester) async {
    await _pumpJobCenter(tester, section: _section);

    await tester.tap(find.text('Scrub Pool'));
    await tester.pumpAndSettle();

    expect(find.text('Job ID'), findsOneWidget);
    expect(find.text('API method'), findsOneWidget);
    expect(find.text('pool.scrub.scrub'), findsOneWidget);
    expect(find.text('Running'), findsWidgets);
    expect(find.text('Log excerpt'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Abort job'), findsOneWidget);
  });

  testWidgets('aborts an abortable job only after confirmation', (
    tester,
  ) async {
    final client = _RecordingClient();
    await _pumpJobCenter(tester, section: _section, client: client);

    await tester.tap(find.byTooltip('Abort job'));
    await tester.pumpAndSettle();

    expect(find.text('Abort this job?'), findsOneWidget);
    expect(client.calls, isEmpty);

    // The job center can be looking at any registered server, so the
    // confirmation has to say which one it is about. A bespoke dialog used to
    // ask the question without naming it.
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('this TrueNAS server'), findsOneWidget);
    expect(
      find.text('Job 11 (Scrub Pool)'),
      findsOneWidget,
      reason: 'the confirmation must identify the job it will abort',
    );
    expect(
      find.textContaining('is not rolled back'),
      findsOneWidget,
      reason: 'aborting does not undo work already done; say so',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Abort job'));
    await tester.pumpAndSettle();

    expect(client.calls.first.$1, 'core.job_abort');
    expect(client.calls.first.$2, [11]);
    expect(find.text('Abort requested for job 11.'), findsOneWidget);
  });

  testWidgets('hides abort when the server lacks core.job_abort', (
    tester,
  ) async {
    await _pumpJobCenter(
      tester,
      section: _section,
      methods: const {'core.get_jobs'},
    );

    expect(find.byTooltip('Abort job'), findsNothing);
  });

  testWidgets('surfaces a permission error instead of an empty list', (
    tester,
  ) async {
    await _pumpJobCenter(
      tester,
      section: const ResourceSection<SystemJob>(
        error: DataMessage(
          DataMessageCode.methodUnavailable,
          method: 'core.get_jobs',
          fallback: 'core.get_jobs is not available on this TrueNAS version.',
        ),
      ),
    );

    expect(
      find.text('core.get_jobs is not available on this TrueNAS version.'),
      findsOneWidget,
    );
  });

  testWidgets('explains an empty active queue', (tester) async {
    await _pumpJobCenter(
      tester,
      section: const ResourceSection<SystemJob>(items: []),
    );

    expect(find.text('No jobs are running.'), findsOneWidget);
  });
}

final _section = ResourceSection<SystemJob>(
  items: [
    SystemJob.fromJson(const {
      'id': 11,
      'method': 'pool.scrub.scrub',
      'state': 'RUNNING',
      'abortable': true,
      'progress': {'percent': 42, 'description': 'Scrubbing tank'},
      'time_started': {r'$date': 1760000000000},
      'logs_excerpt': 'scanning tank...',
    }),
    SystemJob.fromJson(const {
      'id': 10,
      'method': 'app.upgrade',
      'state': 'FAILED',
      'abortable': false,
      'error': 'Image pull failed.',
      'time_started': {r'$date': 1759999000000},
      'time_finished': {r'$date': 1759999060000},
    }),
    SystemJob.fromJson(const {
      'id': 9,
      'method': 'pool.dataset.create',
      'state': 'SUCCESS',
      'abortable': false,
      'time_started': {r'$date': 1759998000000},
      'time_finished': {r'$date': 1759998005000},
    }),
  ],
);

Future<void> _pumpJobCenter(
  WidgetTester tester, {
  required ResourceSection<SystemJob> section,
  TrueNasJsonRpcClient? client,
  Set<String> methods = const {'core.get_jobs', 'core.job_abort'},
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (client != null) trueNasClientProvider.overrideWithValue(client),
        connectionControllerProvider.overrideWith(
          (ref) => _StubConnectionController(methods),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: JobCenter(section: section)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StubConnectionController extends ConnectionController {
  _StubConnectionController(Set<String> methods)
    : super(TrueNasJsonRpcClient(), SavedServerRepository()) {
    state = NasConnectionState(
      stage: ConnectionStage.connected,
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
    calls.add((method, params));
    return true;
  }
}
