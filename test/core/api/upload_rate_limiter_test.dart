import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';

void main() {
  test(
    'firmware byte limiter applies backpressure without changing data',
    () async {
      final stopwatch = Stopwatch()..start();
      final chunks = await limitByteRate(
        Stream<List<int>>.fromIterable([
          List<int>.filled(10, 1),
          List<int>.filled(10, 2),
        ]),
        bytesPerSecond: 100,
      ).toList();

      expect(chunks.expand((chunk) => chunk), [
        ...List<int>.filled(10, 1),
        ...List<int>.filled(10, 2),
      ]);
      expect(
        stopwatch.elapsed,
        greaterThanOrEqualTo(const Duration(milliseconds: 180)),
      );
    },
  );

  test('firmware byte limiter rejects a non-positive rate', () async {
    await expectLater(
      limitByteRate(const Stream<List<int>>.empty(), bytesPerSecond: 0),
      emitsError(isA<ArgumentError>()),
    );
  });
}
