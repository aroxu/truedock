import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/reporting/domain/reporting_memory.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';

ReportingSeries _memory(double available, {String? unit}) =>
    ReportingSeries.fromJson({
      'name': 'memory',
      'unit': ?unit,
      'legend': ['time', 'available'],
      'data': [
        [1760000000, available],
      ],
    });

void main() {
  const total = 32 * 1024 * 1024 * 1024;

  test('calculates used RAM when available is already bytes', () {
    const available = 20 * 1024 * 1024 * 1024;
    final used = reportingMemoryUsedBytes(
      ReportingSnapshot(
        memory: _memory(available.toDouble(), unit: 'bytes'),
        totalMemoryBytes: total,
      ),
    );

    expect(used.single, 12 * 1024 * 1024 * 1024);
  });

  test('calculates used RAM when available is MiB', () {
    final used = reportingMemoryUsedBytes(
      ReportingSnapshot(
        memory: _memory(20 * 1024, unit: 'MiB'),
        totalMemoryBytes: total,
      ),
    );

    expect(used.single, 12 * 1024 * 1024 * 1024);
  });

  test('infers byte samples when old payload omits the unit', () {
    const available = 20 * 1024 * 1024 * 1024;
    final used = reportingMemoryUsedBytes(
      ReportingSnapshot(
        memory: _memory(available.toDouble()),
        totalMemoryBytes: total,
      ),
    );

    expect(used.single, 12 * 1024 * 1024 * 1024);
  });

  test('infers MiB samples when old payload omits the unit', () {
    final used = reportingMemoryUsedBytes(
      ReportingSnapshot(memory: _memory(20 * 1024), totalMemoryBytes: total),
    );

    expect(used.single, 12 * 1024 * 1024 * 1024);
  });
}
