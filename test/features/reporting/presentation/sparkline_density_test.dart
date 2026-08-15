import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/presentation/sparkline.dart';

void main() {
  test('dense charts average 100 time buckets instead of skipping samples', () {
    final values = List<double?>.generate(200, (index) => index.toDouble());

    final reduced = reduceChartDensity(values);

    expect(reduced, hasLength(100));
    expect(reduced.first, .5);
    expect(reduced.last, 198.5);
  });

  test('charts with enough room retain all samples', () {
    final values = List<double?>.generate(100, (index) => index.toDouble());
    expect(reduceChartDensity(values), values);
  });

  test('invalid maximum sample count is rejected', () {
    expect(
      () => reduceChartDensity(const [1, 2, 3], maximumSamples: 1),
      throwsArgumentError,
    );
  });

  test('bucket averaging preserves a substantial reporting gap', () {
    final values = <double?>[
      for (var index = 0; index < 100; index++) index.toDouble(),
      for (var index = 0; index < 100; index++) null,
    ];

    final reduced = reduceChartDensity(values);

    expect(reduced.take(50), everyElement(isNotNull));
    expect(reduced.skip(50), everyElement(isNull));
  });

  test('log chart scale compresses large gaps and remains reversible', () {
    final linearGap = 10000 - 10;
    final logGap = logChartValue(10000) - logChartValue(10);

    expect(logGap, lessThan(linearGap));
    expect(inverseLogChartValue(logChartValue(10000)), closeTo(10000, 1e-8));
    expect(logChartValue(0), 0);
    expect(logChartValue(-10), closeTo(-math.log(11), 1e-10));
  });
}
