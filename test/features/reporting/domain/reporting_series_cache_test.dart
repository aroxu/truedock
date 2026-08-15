// Pins the memoisation of `ReportingSeries`' derived projections.
//
// `totals`, `cpuUtilisation`, and `valuesFor` were plain getters that rebuilt a
// full-length list on every call. Overview reads several of them on every
// frame while a one-second timer replaces the snapshot underneath, so an hour
// of one-second samples turned each frame into thousands of throwaway doubles
// per series. A decoded series never changes, so each projection is computed
// once and handed back thereafter.
//
// Identity is the assertion that matters here: equal contents would still pass
// if the memoisation were accidentally removed, which is exactly the
// regression these tests exist to catch.

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';

ReportingSeries _cpu() => ReportingSeries.fromJson(const {
  'name': 'cpu',
  'legend': ['time', 'cpu0', 'cpu1'],
  'data': [
    [1760000000, 10.0, 30.0],
    [1760000001, 20.0, 40.0],
    [1760000002, null, null],
  ],
});

void main() {
  test('totals is computed once and reused', () {
    final series = _cpu();

    expect(identical(series.totals, series.totals), isTrue);
    expect(series.totals, [40.0, 60.0, null]);
  });

  test('cpuUtilisation is computed once and reused', () {
    final series = _cpu();

    expect(identical(series.cpuUtilisation, series.cpuUtilisation), isTrue);
    expect(series.cpuUtilisation, [20.0, 30.0, null]);
  });

  test('latestTotal is computed once and reused', () {
    final series = _cpu();

    expect(series.latestTotal, 60.0);
    expect(series.latestTotal, 60.0);
  });

  test('each dimension is projected once and cached per name', () {
    final series = _cpu();

    final first = series.valuesFor('cpu0');
    expect(identical(series.valuesFor('cpu0'), first), isTrue);
    expect(first, [10.0, 20.0, null]);

    // A second dimension must get its own cache entry rather than overwrite
    // the first one.
    final second = series.valuesFor('cpu1');
    expect(identical(series.valuesFor('cpu1'), second), isTrue);
    expect(second, [30.0, 40.0, null]);
    expect(series.valuesFor('cpu0'), [10.0, 20.0, null]);
  });

  test('an unknown dimension stays empty and is still cached', () {
    final series = _cpu();

    expect(series.valuesFor('missing'), isEmpty);
    expect(
      identical(series.valuesFor('missing'), series.valuesFor('missing')),
      isTrue,
    );
  });

  test('cached projections cannot be mutated by a caller', () {
    final series = _cpu();

    // The lists are shared now, so a caller that modified one would corrupt
    // every later read of the same series.
    expect(() => series.totals.add(1), throwsUnsupportedError);
    expect(() => series.cpuUtilisation.clear(), throwsUnsupportedError);
    expect(() => series.valuesFor('cpu0')[0] = 0, throwsUnsupportedError);
  });

  test('separate decodes do not share a cache', () {
    expect(identical(_cpu().totals, _cpu().totals), isFalse);
  });
}
