import '../../../l10n/app_localizations.dart';

class SystemInfo {
  const SystemInfo({
    required this.hostname,
    required this.version,
    required this.uptime,
    required this.uptimeSeconds,
    required this.physicalMemoryBytes,
    required this.cpuModel,
    required this.cores,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      hostname: json['hostname'] as String? ?? 'TrueNAS',
      version: json['version'] as String? ?? 'Unknown version',
      uptime: _withoutFractionalSeconds(json['uptime'] as String? ?? 'Unknown'),
      uptimeSeconds: (json['uptime_seconds'] as num?)?.toDouble() ?? 0,
      physicalMemoryBytes: json['physmem'] as int? ?? 0,
      cpuModel: json['model'] as String? ?? 'Unknown CPU',
      cores: json['cores'] as int? ?? 0,
    );
  }

  final String hostname;
  final String version;
  final String uptime;
  final double uptimeSeconds;
  final int physicalMemoryBytes;
  final String cpuModel;
  final int cores;

  /// Returns a localized, human-readable representation of [uptimeSeconds].
  ///
  /// This replaces the server-provided [uptime] string, which is hardcoded in
  /// English (e.g. `1 day, 08:14:37`), so the representation can adapt to
  /// plural rules and translations across all supported client locales.
  String formattedUptime(AppLocalizations l10n) {
    final total = uptimeSeconds.round();
    if (total <= 0) return uptime;

    final days = total ~/ 86400;
    final remainder = total % 86400;
    final hours = remainder ~/ 3600;
    final minutes = (remainder % 3600) ~/ 60;
    final seconds = remainder % 60;

    final time =
        '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
    return l10n.metricUptimeDuration(days, time);
  }
}

String _withoutFractionalSeconds(String value) => value
    // TrueNAS commonly returns durations such as `08:14:37.123456`.
    .replaceAllMapped(
      RegExp(r'(\d{1,3}:\d{2}:\d{2})\.\d+'),
      (match) => match.group(1)!,
    )
    // Also tolerate prose-form durations such as `12.345 seconds`.
    .replaceAllMapped(
      RegExp(r'(\d+)\.\d+\s+(seconds?)\b', caseSensitive: false),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
