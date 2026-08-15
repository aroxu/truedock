import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';

void main() {
  test('decodes rows into timestamped samples per dimension', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'user', 'system'],
      'start': 1760000000,
      'end': 1760000120,
      'step': 60,
      'data': [
        [1760000000, 10.0, 5.0],
        [1760000060, 20.0, 7.5],
        [1760000120, 30.0, 2.5],
      ],
    });

    expect(series.name, 'cpu');
    // The leading time column is excluded from the legend.
    expect(series.legend, ['user', 'system']);
    expect(series.points, hasLength(3));
    expect(series.valuesFor('user'), [10.0, 20.0, 30.0]);
    expect(series.valuesFor('system'), [5.0, 7.5, 2.5]);
    expect(
      series.points.first.timestamp,
      DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
    );
    expect(series.step, 60);
  });

  test('sums dimensions for stacked charts', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'user', 'system'],
      'data': [
        [1760000000, 10.0, 5.0],
        [1760000060, 20.0, 7.5],
      ],
    });

    expect(series.totals, [15.0, 27.5]);
    expect(series.latestTotal, 27.5);
  });

  test('normalizes per-core CPU usage to a whole-machine percentage', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'cpu0', 'cpu1', 'cpu2', 'cpu3'],
      'data': [
        [1760000000, 100.0, 100.0, 100.0, 100.0],
        [1760000060, 80.0, 60.0, 40.0, 20.0],
        [1760000120, 50.0, null, 100.0, null],
      ],
    });

    expect(series.totals, [400.0, 200.0, 150.0]);
    expect(series.cpuUtilisation, [100.0, 50.0, 75.0]);
  });

  test('CPU utilization stays within the chart percentage range', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'cpu0', 'cpu1'],
      'data': [
        [1760000000, 110.0, 120.0],
        [1760000060, null, null],
      ],
    });

    expect(series.cpuUtilisation, [100.0, null]);
  });

  test('preserves Netdata gaps as null instead of inventing zeros', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'load',
      'legend': ['time', 'load1'],
      'data': [
        [1760000000, 1.5],
        [1760000060, null],
        [1760000120, 2.5],
      ],
    });

    expect(series.valuesFor('load1'), [1.5, null, 2.5]);
    expect(series.totals, [1.5, null, 2.5]);
    expect(series.latestTotal, 2.5);
  });

  test('ignores malformed rows and unknown dimensions', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'memory',
      'legend': ['time', 'used'],
      'data': [
        [1760000000, 512.0],
        'not-a-row',
        <Object?>[],
        ['not-a-timestamp', 1.0],
      ],
    });

    expect(series.points, hasLength(1));
    expect(series.valuesFor('missing'), isEmpty);
  });

  test('reads aggregation summaries when present', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'user'],
      'data': [
        [1760000000, 10.0],
      ],
      'aggregations': {
        'mean': {'user': 12.5},
        'max': {'user': 30.0},
      },
    });

    expect(series.aggregate('mean', 'user'), 12.5);
    expect(series.aggregate('max', 'user'), 30.0);
    expect(series.aggregate('min', 'user'), isNull);
  });

  test('treats a series without samples as empty', () {
    final series = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'user'],
      'data': <Object?>[],
    });

    expect(series.isEmpty, isTrue);
    expect(series.latestTotal, isNull);
  });

  test('a snapshot with no usable series reports empty', () {
    const snapshot = ReportingSnapshot();

    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.hasError, isFalse);
  });

  test('network and disk samples make a snapshot non-empty', () {
    final network = ReportingSeries.fromJson(const {
      'name': 'interface',
      'identifier': 'ens18',
      'legend': ['time', 'received', 'sent'],
      'data': [
        [1760000000, 1.0, -2.0],
      ],
    });

    final snapshot = ReportingSnapshot(network: [network]);

    expect(snapshot.isEmpty, isFalse);
    expect(snapshot.network.single.identifier, 'ens18');
  });

  test('foreground refresh retains temporarily missing device graphs', () {
    final network = ReportingSeries.fromJson(const {
      'name': 'interface',
      'identifier': 'ens18',
      'legend': ['time', 'received', 'sent'],
      'data': [
        [1760000000, 1.0, -2.0],
      ],
    });
    final disk = ReportingSeries.fromJson(const {
      'name': 'disk',
      'identifier': 'sda',
      'legend': ['time', 'reads', 'writes'],
      'data': [
        [1760000000, 3.0, -4.0],
      ],
    });
    final cpu = ReportingSeries.fromJson(const {
      'name': 'cpu',
      'legend': ['time', 'cpu0'],
      'data': [
        [1760000060, 25.0],
      ],
    });
    final previous = ReportingSnapshot(network: [network], disks: [disk]);

    final merged = ReportingSnapshot(
      cpu: cpu,
    ).retainMissingDevicesFrom(previous);

    expect(merged.cpu, same(cpu));
    expect(merged.network, same(previous.network));
    expect(merged.disks, same(previous.disks));
  });

  test('foreground refresh replaces device graphs when new data arrives', () {
    final previousNetwork = ReportingSeries.fromJson(const {
      'name': 'interface',
      'identifier': 'ens18',
      'legend': ['time', 'received'],
      'data': [
        [1760000000, 1.0],
      ],
    });
    final currentNetwork = ReportingSeries.fromJson(const {
      'name': 'interface',
      'identifier': 'ens19',
      'legend': ['time', 'received'],
      'data': [
        [1760000060, 2.0],
      ],
    });

    final merged = ReportingSnapshot(
      network: [currentNetwork],
    ).retainMissingDevicesFrom(ReportingSnapshot(network: [previousNetwork]));

    expect(merged.network.single.identifier, 'ens19');
  });
}
