import 'reporting_series.dart';

/// Converts the Netdata memory graph into used bytes.
///
/// TrueNAS releases have returned this graph in both MiB and bytes. Prefer the
/// advertised unit and use total physical memory as a safe fallback for older
/// payloads that omit it.
List<double?> reportingMemoryUsedBytes(ReportingSnapshot snapshot) {
  final series = snapshot.memory;
  if (series == null || series.isEmpty) return const [];
  final total = snapshot.totalMemoryBytes;
  final available = series.valuesFor('available');
  if (total != null && total > 0 && available.any((value) => value != null)) {
    return [
      for (final value in available)
        value == null
            ? null
            : (total - _memoryValueToBytes(value, series.unit, total))
                  .clamp(0, total)
                  .toDouble(),
    ];
  }

  for (final dimension in const ['used', 'Used', 'apps', 'active']) {
    final values = series.valuesFor(dimension);
    if (values.any((value) => value != null)) {
      return [
        for (final value in values)
          value == null ? null : _memoryValueToBytes(value, series.unit, total),
      ];
    }
  }
  return const [];
}

double _memoryValueToBytes(double value, String? unit, int? totalBytes) {
  final normalized = unit?.trim().toLowerCase() ?? '';
  if (normalized.contains('gib')) return value * 1024 * 1024 * 1024;
  if (normalized.contains('mib')) return value * 1024 * 1024;
  if (normalized.contains('kib')) return value * 1024;
  if (normalized == 'gb') return value * 1000 * 1000 * 1000;
  if (normalized == 'mb') return value * 1000 * 1000;
  if (normalized == 'kb') return value * 1000;
  if (normalized.contains('byte')) return value;

  if (totalBytes != null && totalBytes > 0) {
    // A byte-valued sample is of the same order as total RAM. A MiB sample is
    // at least three orders smaller (for example 28,000 vs 32,000,000,000).
    if (value >= totalBytes / 1024) return value;
  }
  return value * 1024 * 1024;
}
