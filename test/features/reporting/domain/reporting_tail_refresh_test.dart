// Guards the Overview tail refresh.
//
// Overview repaints once a second but displays an hour of history. It used to
// re-request that whole hour on every tick, decoding thousands of samples per
// series per second and discarding all of them - measured at ~39,600 points
// per refresh on a 3-NIC/5-disk host. `appendTo` exists so a tick can ask for
// only the elapsed seconds and stitch them onto the retained history.
//
// Stitching is only safe when the two ranges actually meet, so these tests pin
// the refusal cases as tightly as the success case: a wrong join would draw a
// continuous line across time the server never reported, which is a worse
// outcome than the allocation it saves.

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/domain/data_message.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';

const _epoch = 1760000000;

ReportingSeries _series({
  required String name,
  required int firstSecond,
  required int count,
  String? identifier,
  List<String> dimensions = const ['user'],
  double base = 1.0,
}) => ReportingSeries.fromJson(<String, dynamic>{
  'name': name,
  'identifier': ?identifier,
  'legend': ['time', ...dimensions],
  'data': [
    for (var index = 0; index < count; index++)
      <Object?>[
        _epoch + firstSecond + index,
        for (var dimension = 0; dimension < dimensions.length; dimension++)
          base + index + dimension,
      ],
  ],
});

DateTime _at(int second) =>
    DateTime.fromMillisecondsSinceEpoch((_epoch + second) * 1000, isUtc: true);

void main() {
  test('a tail refresh extends retained history instead of replacing it', () {
    final retained = _series(name: 'cpu', firstSecond: 0, count: 60);
    final tail = _series(name: 'cpu', firstSecond: 60, count: 5, base: 100);

    final merged = tail.appendTo(retained, keep: const Duration(hours: 1));

    expect(merged.points, hasLength(65));
    expect(merged.points.first.timestamp, _at(0));
    expect(merged.points.last.timestamp, _at(64));
    // The newest samples must come from the tail, not the retained copy.
    expect(merged.valuesFor('user').last, 104.0);
  });

  test('overlapping samples are taken from the fresher response', () {
    final retained = _series(name: 'cpu', firstSecond: 0, count: 60);
    // Re-reports the last ten seconds with different values, as a server whose
    // samples were still settling would.
    final tail = _series(name: 'cpu', firstSecond: 50, count: 15, base: 500);

    final merged = tail.appendTo(retained, keep: const Duration(hours: 1));

    expect(merged.points, hasLength(65));
    final values = merged.valuesFor('user');
    // Second 49 is retained; second 50 onwards belongs to the tail.
    expect(values[49], 50.0);
    expect(values[50], 500.0);
  });

  test('history is trimmed to the retention window as it grows', () {
    final retained = _series(name: 'cpu', firstSecond: 0, count: 600);
    final tail = _series(name: 'cpu', firstSecond: 600, count: 5);

    final merged = tail.appendTo(retained, keep: const Duration(minutes: 5));

    expect(merged.points.last.timestamp, _at(604));
    expect(merged.points.first.timestamp, _at(304));
    expect(merged.points, hasLength(301));
  });

  test('a gap in coverage is never bridged', () {
    final retained = _series(name: 'cpu', firstSecond: 0, count: 60);
    // Resuming from a long suspension: minutes of unsampled time in between.
    final tail = _series(name: 'cpu', firstSecond: 900, count: 5);

    final merged = tail.appendTo(retained, keep: const Duration(hours: 1));

    expect(merged.points, hasLength(5));
    expect(merged.points.first.timestamp, _at(900));
  });

  test('a changed dimension layout is never spliced', () {
    final retained = _series(name: 'cpu', firstSecond: 0, count: 60);
    final tail = _series(
      name: 'cpu',
      firstSecond: 60,
      count: 5,
      dimensions: const ['user', 'system'],
    );

    expect(
      tail.appendTo(retained, keep: const Duration(hours: 1)).points,
      hasLength(5),
    );
  });

  test('device series join by identifier, not by graph name', () {
    final snapshot = ReportingSnapshot(
      network: [
        _series(
          name: 'interface',
          firstSecond: 0,
          count: 60,
          identifier: 'enp6s18',
        ),
        _series(
          name: 'interface',
          firstSecond: 0,
          count: 60,
          identifier: 'enp6s19',
          base: 900,
        ),
      ],
    );
    final tail = ReportingSnapshot(
      network: [
        _series(
          name: 'interface',
          firstSecond: 60,
          count: 5,
          identifier: 'enp6s19',
          base: 900,
        ),
        _series(
          name: 'interface',
          firstSecond: 60,
          count: 5,
          identifier: 'enp6s18',
        ),
      ],
    );

    final merged = tail.appendTo(snapshot, keep: const Duration(hours: 1));

    expect(merged.network, hasLength(2));
    for (final series in merged.network) {
      expect(series.points, hasLength(65), reason: series.identifier);
    }
    // enp6s19's high values must not have leaked onto enp6s18.
    final first = merged.network.firstWhere(
      (series) => series.identifier == 'enp6s18',
    );
    expect(first.valuesFor('user').first, 1.0);
  });

  test('a newly attached device keeps only what the server sent', () {
    final snapshot = ReportingSnapshot(
      disks: [
        _series(name: 'disk', firstSecond: 0, count: 60, identifier: 'sda'),
      ],
    );
    final tail = ReportingSnapshot(
      disks: [
        _series(name: 'disk', firstSecond: 60, count: 5, identifier: 'sda'),
        _series(name: 'disk', firstSecond: 60, count: 5, identifier: 'sdb'),
      ],
    );

    final merged = tail.appendTo(snapshot, keep: const Duration(hours: 1));

    expect(
      merged.disks.firstWhere((series) => series.identifier == 'sda').points,
      hasLength(65),
    );
    expect(
      merged.disks.firstWhere((series) => series.identifier == 'sdb').points,
      hasLength(5),
    );
  });

  test('an errored refresh never rewrites the retained snapshot', () {
    final snapshot = ReportingSnapshot(
      cpu: _series(name: 'cpu', firstSecond: 0, count: 60),
    );
    const failed = ReportingSnapshot(error: DataMessage.raw('Not authorized'));

    expect(
      failed.appendTo(snapshot, keep: const Duration(hours: 1)).cpu,
      isNull,
    );
  });

  test('the newest sample time drives how much a refresh must ask for', () {
    final snapshot = ReportingSnapshot(
      cpu: _series(name: 'cpu', firstSecond: 0, count: 60),
      disks: [
        _series(name: 'disk', firstSecond: 0, count: 120, identifier: 'sda'),
      ],
    );

    expect(snapshot.latestSampleTime, _at(119));
    expect(const ReportingSnapshot().latestSampleTime, isNull);
  });
}
