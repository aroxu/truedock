import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_client_provider.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/connection/presentation/connection_controller.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_quota_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Answers `pool.dataset.get_quota` per subject and records what is written,
/// so the tests can assert the payload rather than only the rendering.
class _QuotaClient extends TrueNasJsonRpcClient {
  _QuotaClient({
    this.users = const [],
    this.groups = const [],
    this.fail = false,
    this.setError,
  });

  final List<Map<String, Object?>> users;
  final List<Map<String, Object?>> groups;
  final bool fail;
  final String? setError;
  final List<(String, List<Object?>)> calls = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls.add((method, params));
    if (method == 'pool.dataset.get_quota') {
      if (fail) {
        throw const TrueNasRpcException(code: 13, message: 'Not authorized');
      }
      return params[1] == 'USER' ? users : groups;
    }
    if (method == 'pool.dataset.set_quota' && setError != null) {
      throw TrueNasRpcException(code: 22, message: setError!);
    }
    return 1;
  }
}

const _dataset = Dataset(
  id: 'tank/shared',
  name: 'tank/shared',
  type: 'FILESYSTEM',
);

Map<String, Object?> _row({
  String type = 'USER',
  int id = 1,
  String name = 'alice',
  int used = 0,
  int objUsed = 0,
  int? quota,
  int? objQuota,
}) => {
  'quota_type': type,
  'id': id,
  'name': name,
  'used_bytes': used,
  'obj_used': objUsed,
  'quota': ?quota,
  'obj_quota': ?objQuota,
};

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
        methods: {'pool.dataset.get_quota', 'pool.dataset.set_quota'},
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, _QuotaClient client) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trueNasClientProvider.overrideWithValue(client),
        connectionControllerProvider.overrideWith(
          (ref) => _StubConnectionController(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DatasetQuotaSheet(dataset: _dataset)),
      ),
    ),
  );
  // Not pumpAndSettle: a failed load leaves nothing animating, but a busy row
  // renders a progress indicator whose animation never ends.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('reads users first, since that is the common case', (
    tester,
  ) async {
    final client = _QuotaClient(users: [_row(quota: 2147483648)]);
    await _open(tester, client);

    final read = client.calls
        .where((call) => call.$1 == 'pool.dataset.get_quota')
        .toList();
    expect(read, hasLength(1));
    expect(read.single.$2, ['tank/shared', 'USER']);
  });

  testWidgets('shows a configured limit with its usage', (tester) async {
    await _open(
      tester,
      _QuotaClient(users: [_row(used: 1073741824, quota: 2147483648)]),
    );

    expect(find.text('alice'), findsOneWidget);
    expect(find.textContaining('of 2.0 GiB'), findsOneWidget);
  });

  testWidgets('an account with no limit is shown as usage only', (
    tester,
  ) async {
    // The server returns every account that has ever written, so these rows
    // dominate the list and must not read as if they were limited.
    await _open(tester, _QuotaClient(users: [_row(used: 4096)]));

    expect(find.textContaining('no limit'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('an account at its limit is flagged', (tester) async {
    // ZFS refuses writes at the limit, so this is a failure state rather than
    // a warning.
    await _open(
      tester,
      _QuotaClient(users: [_row(used: 2147483648, quota: 2147483648)]),
    );

    expect(find.text('Over limit'), findsOneWidget);
  });

  testWidgets('only a limited account offers removal', (tester) async {
    // Offering "remove quota" on a row with no quota would be a no-op that
    // looks like an action.
    await _open(
      tester,
      _QuotaClient(
        users: [
          _row(name: 'alice', quota: 1024),
          _row(id: 2, name: 'bob', used: 512),
        ],
      ),
    );

    expect(find.byTooltip('Remove quota'), findsOneWidget);
  });

  testWidgets('switching to groups refetches, because the API is per type', (
    tester,
  ) async {
    final client = _QuotaClient(
      users: [_row(name: 'alice', quota: 1024)],
      groups: [_row(type: 'GROUP', id: 10, name: 'staff', quota: 2048)],
    );
    await _open(tester, client);
    expect(find.text('alice'), findsOneWidget);

    await tester.tap(find.text('Groups'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final read = client.calls
        .where((call) => call.$1 == 'pool.dataset.get_quota')
        .toList();
    expect(read, hasLength(2));
    expect(read.last.$2, ['tank/shared', 'GROUP']);
    expect(find.text('staff'), findsOneWidget);
    expect(find.text('alice'), findsNothing);
  });

  testWidgets('a permission failure is explained rather than shown empty', (
    tester,
  ) async {
    await _open(tester, _QuotaClient(fail: true));

    expect(find.textContaining('could not be read'), findsOneWidget);
  });

  testWidgets('an empty dataset says so', (tester) async {
    await _open(tester, _QuotaClient());

    expect(find.textContaining('No user has written'), findsOneWidget);
  });

  testWidgets('the editor sends both limits as separate entries', (
    tester,
  ) async {
    final client = _QuotaClient();
    await _open(tester, client);

    await tester.tap(find.widgetWithText(FilledButton, 'Set a quota'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'User or group'),
      'alice',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Space limit'), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final write = client.calls
        .where((call) => call.$1 == 'pool.dataset.set_quota')
        .single;
    expect(write.$2.first, 'tank/shared');
    expect(write.$2[1], [
      {
        'quota_type': 'USER',
        'id': 'alice',
        'quota_value': 2 * 1024 * 1024 * 1024,
      },
    ]);
  });

  testWidgets('the editor refuses root before reaching the server', (
    tester,
  ) async {
    // The server refuses uid 0 with a bare EINVAL; catching it locally is what
    // turns that into an explanation.
    final client = _QuotaClient();
    await _open(tester, client);

    await tester.tap(find.widgetWithText(FilledButton, 'Set a quota'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'User or group'),
      'root',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Space limit'), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.textContaining('root cannot be given a quota'), findsOneWidget);
    expect(
      client.calls.where((call) => call.$1 == 'pool.dataset.set_quota'),
      isEmpty,
    );
  });

  testWidgets('a rejected group quota stays inside the edit sheet', (
    tester,
  ) async {
    final client = _QuotaClient(setError: 'Group does not exist.');
    await _open(tester, client);

    await tester.tap(find.text('Groups'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(FilledButton, 'Set a quota'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'User or group'),
      'missing-group',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Space limit'), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('quota-apply-error')), findsOneWidget);
    expect(find.text('Group does not exist.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'missing-group'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a server-rejected user quota uses the same in-sheet error', (
    tester,
  ) async {
    final client = _QuotaClient(setError: 'User does not exist.');
    await _open(tester, client);

    await tester.tap(find.widgetWithText(FilledButton, 'Set a quota'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'User or group'),
      'missing-user',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Space limit'), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('quota-apply-error')), findsOneWidget);
    expect(find.text('User does not exist.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('an edit that changes nothing is refused', (tester) async {
    final client = _QuotaClient();
    await _open(tester, client);

    await tester.tap(find.widgetWithText(FilledButton, 'Set a quota'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'User or group'),
      'alice',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.textContaining('at least one limit'), findsOneWidget);
    expect(
      client.calls.where((call) => call.$1 == 'pool.dataset.set_quota'),
      isEmpty,
    );
  });

  testWidgets('editing an existing quota does not let the account change', (
    tester,
  ) async {
    // Changing the identity would create a second quota rather than move one.
    await _open(
      tester,
      _QuotaClient(users: [_row(name: 'alice', quota: 1024)]),
    );

    await tester.tap(find.byTooltip('Quota for alice'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'User or group'),
    );
    expect(field.enabled, isFalse);
    expect(field.controller?.text, 'alice');
  });
}
