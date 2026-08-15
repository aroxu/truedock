import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/reporting/data/reporting_repository.dart';

void main() {
  test('requests the overview graphs over a bounded window', () async {
    final client = _StubClient(response: const []);
    final repository = ReportingRepository(client);

    await repository.loadOverview(
      supportedMethods: const {'reporting.netdata_get_data'},
      window: const Duration(hours: 1),
    );

    expect(client.methods, ['reporting.netdata_get_data']);
    final graphs = (client.paramsLog.last[0]! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(graphs.map((graph) => graph['name']), ['cpu', 'memory', 'load']);

    final window = client.paramsLog.last[1]! as Map<String, Object?>;
    final start = window['start']! as int;
    final end = window['end']! as int;
    expect(end - start, 3600);
  });

  test('requests a seven-day history window', () async {
    final client = _StubClient(response: const []);

    await ReportingRepository(client).loadOverview(
      supportedMethods: const {'reporting.netdata_get_data'},
      window: const Duration(days: 7),
    );

    final window = client.paramsLog.single[1] as Map<String, Object?>;
    expect((window['end'] as int) - (window['start'] as int), 7 * 24 * 3600);
  });

  test('expands every advertised network and disk identifier', () async {
    final client = _StubClient(
      responses: const [
        [
          {
            'name': 'interface',
            'identifiers': ['ens18', 'ens19'],
          },
          {
            'name': 'disk',
            'identifiers': ['sda | Model: QEMU', 'sdb | Model: QEMU'],
          },
        ],
        [
          {
            'name': 'interface',
            'identifier': 'ens18',
            'legend': ['time', 'received', 'sent'],
            'data': [
              [1760000000, 10.0, -5.0],
            ],
          },
          {
            'name': 'disk',
            'identifier': 'sda | Model: QEMU',
            'legend': ['time', 'reads', 'writes'],
            'data': [
              [1760000000, 3.0, -2.0],
            ],
          },
        ],
      ],
    );

    final snapshot = await ReportingRepository(client).loadOverview(
      supportedMethods: const {
        'reporting.netdata_get_data',
        'reporting.netdata_graphs',
      },
    );
    final requests = (client.paramsLog.last[0] as List).cast<Map>();

    bool requested(String name, String identifier) => requests.any(
      (request) =>
          request['name'] == name && request['identifier'] == identifier,
    );

    expect(requested('interface', 'ens18'), isTrue);
    expect(requested('interface', 'ens19'), isTrue);
    expect(requested('disk', 'sda | Model: QEMU'), isTrue);
    expect(snapshot.network.single.identifier, 'ens18');
    expect(snapshot.disks.single.identifier, 'sda | Model: QEMU');
  });

  test('decodes each returned graph by name', () async {
    final client = _StubClient(
      response: const [
        {
          'name': 'cpu',
          'legend': ['time', 'user'],
          'data': [
            [1760000000, 12.0],
          ],
        },
        {
          'name': 'load',
          'legend': ['time', 'load1'],
          'data': [
            [1760000000, 0.5],
          ],
        },
      ],
    );

    final snapshot = await ReportingRepository(client).loadOverview();

    expect(snapshot.hasError, isFalse);
    expect(snapshot.cpu?.latestTotal, 12.0);
    expect(snapshot.load?.valuesFor('load1'), [0.5]);
    expect(snapshot.memory, isNull);
  });

  test('sorts disks by natural device-name order', () async {
    final client = _StubClient(
      response: const [
        {
          'name': 'disk',
          'identifier': 'nvme10p1 | Model: Fast',
          'legend': ['time', 'reads'],
          'data': [
            [1760000000, 1.0],
          ],
        },
        {
          'name': 'disk',
          'identifier': 'sdc | Model: QEMU',
          'legend': ['time', 'reads'],
          'data': [
            [1760000000, 1.0],
          ],
        },
        {
          'name': 'disk',
          'identifier': 'nvme2p1 | Model: Fast',
          'legend': ['time', 'reads'],
          'data': [
            [1760000000, 1.0],
          ],
        },
        {
          'name': 'disk',
          'identifier': 'sda | Model: QEMU',
          'legend': ['time', 'reads'],
          'data': [
            [1760000000, 1.0],
          ],
        },
        {
          'name': 'disk',
          'identifier': 'sdb | Model: QEMU',
          'legend': ['time', 'reads'],
          'data': [
            [1760000000, 1.0],
          ],
        },
      ],
    );

    final snapshot = await ReportingRepository(client).loadOverview();

    expect(snapshot.disks.map((series) => series.identifier), [
      'nvme2p1 | Model: Fast',
      'nvme10p1 | Model: Fast',
      'sda | Model: QEMU',
      'sdb | Model: QEMU',
      'sdc | Model: QEMU',
    ]);
  });

  test('sorts network interfaces by natural device-name order', () async {
    Map<String, Object?> interfaceSeries(String identifier) => {
      'name': 'interface',
      'identifier': identifier,
      'legend': ['time', 'received', 'sent'],
      'data': [
        [1760000000, 1.0, -1.0],
      ],
    };
    final client = _StubClient(
      response: [
        interfaceSeries('enp6s18'),
        interfaceSeries('enp6s20'),
        interfaceSeries('enp6s19'),
      ],
    );

    final snapshot = await ReportingRepository(client).loadOverview();

    expect(snapshot.network.map((series) => series.identifier), [
      'enp6s18',
      'enp6s19',
      'enp6s20',
    ]);
  });

  test('reports unavailable reporting instead of an empty chart', () async {
    final client = _StubClient(response: const []);

    final snapshot = await ReportingRepository(
      client,
    ).loadOverview(supportedMethods: const {'system.info'});

    expect(client.method, isNull);
    expect(snapshot.hasError, isTrue);
    expect(snapshot.errorMessage, contains('not available'));
  });

  test('surfaces a permission error from the server', () async {
    final client = _StubClient(
      error: const TrueNasRpcException(code: -32001, message: 'Not authorized'),
    );

    final snapshot = await ReportingRepository(client).loadOverview();

    expect(snapshot.hasError, isTrue);
    expect(snapshot.errorMessage, contains('Not authorized'));
  });

  test('rejects a non-list reporting response', () async {
    final client = _StubClient(response: const {'unexpected': true});

    final snapshot = await ReportingRepository(client).loadOverview();

    expect(snapshot.hasError, isTrue);
  });
}

class _StubClient extends TrueNasJsonRpcClient {
  _StubClient({this.response, this.responses, this.error});

  final Object? response;
  final List<Object?>? responses;
  final Object? error;
  String? method;
  List<Object?>? params;
  final List<String> methods = [];
  final List<List<Object?>> paramsLog = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    this.method = method;
    this.params = params;
    methods.add(method);
    paramsLog.add(params);
    if (error != null) throw error!;
    if (responses != null) return responses![methods.length - 1];
    return response;
  }
}
