import 'package:flutter/foundation.dart';

/// Stable codes for general-system configuration validation failures, so
/// presentation layers can translate the message instead of parsing the
/// English fallback.
enum SystemGeneralValidationCode { hostnameRequired, timezoneRequired }

/// Syslog level options for `system.advanced.update.sysloglevel`.
enum SystemSyslogLevel {
  defaultLevel('DEFAULT', 'Default (local)'),
  debug('DEBUG', 'Debug'),
  info('INFO', 'Info'),
  notice('NOTICE', 'Notice'),
  warning('WARNING', 'Warning'),
  error('ERROR', 'Error'),
  critical('CRITICAL', 'Critical'),
  alert('ALERT', 'Alert'),
  emergency('EMERGENCY', 'Emergency');

  const SystemSyslogLevel(this.apiName, this.label);

  final String apiName;
  final String label;

  static SystemSyslogLevel fromApi(String? value) {
    for (final l in SystemSyslogLevel.values) {
      if (l.apiName == value) return l;
    }
    return SystemSyslogLevel.defaultLevel;
  }
}

/// Mutable values collected by the general editor. TrueNAS 25.10 owns these
/// fields in different namespaces, so [changedFields] describes UI changes;
/// the repository routes each supported field to its documented method.
@immutable
class SystemGeneralConfiguration {
  const SystemGeneralConfiguration({
    required this.hostname,
    required this.timezone,
    required this.syslogLevel,
  });

  /// Seeds a configuration from a `system.general.config` response.
  factory SystemGeneralConfiguration.fromConfig(Map<String, dynamic> json) =>
      SystemGeneralConfiguration(
        hostname: json['hostname'] is String ? json['hostname'] as String : '',
        timezone: json['timezone'] is String ? json['timezone'] as String : '',
        syslogLevel: SystemSyslogLevel.fromApi(json['sysloglevel'] as String?),
      );

  final String hostname;
  final String timezone;
  final SystemSyslogLevel syslogLevel;

  /// Returns only the fields that differ from [baseline], as the payload for
  /// `system.general.update`.
  Map<String, Object?> changedFields(SystemGeneralConfiguration baseline) {
    final out = <String, Object?>{};
    if (hostname != baseline.hostname) out['hostname'] = hostname;
    if (timezone != baseline.timezone) out['timezone'] = timezone;
    if (syslogLevel != baseline.syslogLevel) {
      out['sysloglevel'] = syslogLevel.apiName;
    }
    return out;
  }

  SystemGeneralConfiguration copyWith({
    String? hostname,
    String? timezone,
    SystemSyslogLevel? syslogLevel,
  }) => SystemGeneralConfiguration(
    hostname: hostname ?? this.hostname,
    timezone: timezone ?? this.timezone,
    syslogLevel: syslogLevel ?? this.syslogLevel,
  );
}

/// Validates a [SystemGeneralConfiguration]. Returns field-keyed errors.
Map<String, SystemGeneralValidationCode> validateSystemGeneralConfiguration(
  SystemGeneralConfiguration config,
) {
  final errors = <String, SystemGeneralValidationCode>{};
  if (config.hostname.trim().isEmpty) {
    errors['hostname'] = SystemGeneralValidationCode.hostnameRequired;
  }
  if (config.timezone.trim().isEmpty) {
    errors['timezone'] = SystemGeneralValidationCode.timezoneRequired;
  }
  return errors;
}
