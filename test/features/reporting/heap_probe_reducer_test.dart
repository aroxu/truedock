// Pins `tool/live_heap_probe.dart`'s copied reducer to the shipped one.
//
// The probe cannot import `sparkline.dart`, because that library pulls in
// Flutter and the probe has to compile for the plain Dart VM. A copy is
// therefore unavoidable, but a copy that drifts would silently invalidate the
// measurement it exists to produce: the probe would be reporting the cost of
// arithmetic the app no longer performs.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/presentation/sparkline.dart'
    as shipped;

import '../../../tool/live_heap_probe.dart' as probe;

void main() {
  test('the probe reduces density identically to the shipped chart', () {
    // A fixed seed keeps a failure reproducible; the shapes below cover the
    // cases the reducer distinguishes: dense input, sparse input, all-null
    // buckets, and lengths that do not divide evenly into 100 buckets.
    final random = math.Random(20260815);
    for (final length in const [0, 1, 99, 100, 101, 360, 3600, 5001]) {
      final values = <double?>[
        for (var index = 0; index < length; index++)
          random.nextInt(11) == 0 ? null : random.nextDouble() * 1000,
      ];

      expect(
        probe.reduceChartDensity(values),
        shipped.reduceChartDensity(values),
        reason: 'probe and shipped reducers diverged at length $length',
      );
    }
  });

  test('the probe preserves reporting gaps like the shipped chart', () {
    final values = <double?>[
      for (var index = 0; index < 1800; index++) index.toDouble(),
      for (var index = 0; index < 1800; index++) null,
    ];

    expect(
      probe.reduceChartDensity(values),
      shipped.reduceChartDensity(values),
    );
  });
}
