import 'package:flutter/foundation.dart';

/// A stable code for a snapshot schedule summary, so presentation layers can
/// localize the description without parsing the English sentence.
enum SnapshotScheduleSummaryCode {
  everyHour,
  everySundayMidnight,
  firstOfMonthMidnight,
  everyDayMidnight,
  cron,
}

/// A stable code for a snapshot task validation failure, paired with the form
/// field it belongs to. Presentation layers map the code to a translated
/// message rather than surfacing the domain's English text.
enum SnapshotValidationCode {
  datasetRequired,
  retentionTooSmall,
  namingSchemaRequired,
  namingSchemaSlash,
  excludeNotChild,
  cronInvalid,
  timeInvalid,
}

enum SnapshotLifetimeUnit { hour, day, week, month, year }

extension SnapshotLifetimeUnitApi on SnapshotLifetimeUnit {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    SnapshotLifetimeUnit.hour => 'Hours',
    SnapshotLifetimeUnit.day => 'Days',
    SnapshotLifetimeUnit.week => 'Weeks',
    SnapshotLifetimeUnit.month => 'Months',
    SnapshotLifetimeUnit.year => 'Years',
  };
}

enum SnapshotSchedulePreset { hourly, daily, weekly, monthly, custom }

extension SnapshotSchedulePresetLabel on SnapshotSchedulePreset {
  String get label => switch (this) {
    SnapshotSchedulePreset.hourly => 'Hourly',
    SnapshotSchedulePreset.daily => 'Daily',
    SnapshotSchedulePreset.weekly => 'Weekly',
    SnapshotSchedulePreset.monthly => 'Monthly',
    SnapshotSchedulePreset.custom => 'Custom',
  };
}

class SnapshotTaskSchedule {
  const SnapshotTaskSchedule({
    this.minute = '00',
    this.hour = '*',
    this.dayOfMonth = '*',
    this.month = '*',
    this.dayOfWeek = '*',
    this.begin = '00:00',
    this.end = '23:59',
  });

  factory SnapshotTaskSchedule.forPreset(SnapshotSchedulePreset preset) =>
      switch (preset) {
        SnapshotSchedulePreset.hourly => const SnapshotTaskSchedule(),
        SnapshotSchedulePreset.daily => const SnapshotTaskSchedule(hour: '00'),
        SnapshotSchedulePreset.weekly => const SnapshotTaskSchedule(
          hour: '00',
          dayOfWeek: '7',
        ),
        SnapshotSchedulePreset.monthly => const SnapshotTaskSchedule(
          hour: '00',
          dayOfMonth: '1',
        ),
        SnapshotSchedulePreset.custom => const SnapshotTaskSchedule(),
      };

  final String minute;
  final String hour;
  final String dayOfMonth;
  final String month;
  final String dayOfWeek;
  final String begin;
  final String end;

  Map<String, Object?> toApiJson() => {
    'minute': minute,
    'hour': hour,
    'dom': dayOfMonth,
    'month': month,
    'dow': dayOfWeek,
    'begin': begin,
    'end': end,
  };

  Map<String, String> validate() => {
    for (final entry in issues().entries) entry.key: entry.value.message,
  };

  /// Typed validation failures keyed by form field.
  Map<String, SnapshotValidationIssue> issues() {
    final issues = <String, SnapshotValidationIssue>{};
    _validateCron('minute', minute, issues);
    _validateCron('hour', hour, issues);
    _validateCron('dayOfMonth', dayOfMonth, issues);
    _validateCron('month', month, issues);
    _validateCron('dayOfWeek', dayOfWeek, issues);
    _validateTime('begin', begin, issues);
    _validateTime('end', end, issues);
    return issues;
  }

  /// The recognized shape of this schedule, so the UI can describe it in the
  /// active language. Anything TrueDock does not recognize falls back to the
  /// raw cron fields, which are locale-independent.
  SnapshotScheduleSummaryCode get summaryCode {
    if (minute == '00' && hour == '*') {
      return SnapshotScheduleSummaryCode.everyHour;
    }
    if (minute == '00' && hour == '00' && dayOfWeek == '7') {
      return SnapshotScheduleSummaryCode.everySundayMidnight;
    }
    if (minute == '00' && hour == '00' && dayOfMonth == '1') {
      return SnapshotScheduleSummaryCode.firstOfMonthMidnight;
    }
    if (minute == '00' && hour == '00') {
      return SnapshotScheduleSummaryCode.everyDayMidnight;
    }
    return SnapshotScheduleSummaryCode.cron;
  }

  /// The cron expression shown when [summaryCode] is
  /// [SnapshotScheduleSummaryCode.cron].
  String get cronExpression => '$minute $hour $dayOfMonth $month $dayOfWeek';

  String get summary => switch (summaryCode) {
    SnapshotScheduleSummaryCode.everyHour => 'At the start of every hour',
    SnapshotScheduleSummaryCode.everySundayMidnight => 'Every Sunday at 00:00',
    SnapshotScheduleSummaryCode.firstOfMonthMidnight =>
      'On day 1 of every month at 00:00',
    SnapshotScheduleSummaryCode.everyDayMidnight => 'Every day at 00:00',
    SnapshotScheduleSummaryCode.cron => 'Cron $cronExpression',
  };
}

/// A typed snapshot task validation failure.
@immutable
class SnapshotValidationIssue {
  const SnapshotValidationIssue(this.code);

  final SnapshotValidationCode code;

  String get message => switch (code) {
    SnapshotValidationCode.datasetRequired => 'Choose a dataset.',
    SnapshotValidationCode.retentionTooSmall => 'Retention must be at least 1.',
    SnapshotValidationCode.namingSchemaRequired =>
      'Enter a snapshot naming schema.',
    SnapshotValidationCode.namingSchemaSlash =>
      'Snapshot names cannot contain /.',
    SnapshotValidationCode.excludeNotChild =>
      'Each exclusion must be a child of the selected dataset.',
    SnapshotValidationCode.cronInvalid =>
      'Use a numeric cron expression such as *, 00, or */2.',
    SnapshotValidationCode.timeInvalid => 'Use 24-hour time in HH:mm format.',
  };
}

class CreateSnapshotTaskRequest {
  const CreateSnapshotTaskRequest({
    required this.dataset,
    required this.recursive,
    required this.lifetimeValue,
    required this.lifetimeUnit,
    required this.enabled,
    required this.excludes,
    required this.namingSchema,
    required this.allowEmpty,
    required this.schedule,
  });

  final String dataset;
  final bool recursive;
  final int lifetimeValue;
  final SnapshotLifetimeUnit lifetimeUnit;
  final bool enabled;
  final List<String> excludes;
  final String namingSchema;
  final bool allowEmpty;
  final SnapshotTaskSchedule schedule;

  Map<String, Object?> toApiJson() => {
    'dataset': dataset,
    'recursive': recursive,
    'lifetime_value': lifetimeValue,
    'lifetime_unit': lifetimeUnit.apiValue,
    'enabled': enabled,
    'exclude': recursive ? excludes : <String>[],
    'naming_schema': namingSchema,
    'allow_empty': allowEmpty,
    'schedule': schedule.toApiJson(),
  };

  Map<String, String> validate() => {
    for (final entry in issues().entries) entry.key: entry.value.message,
  };

  /// Typed validation failures keyed by form field, so the editor can render
  /// translated messages instead of the domain's English fallback text.
  Map<String, SnapshotValidationIssue> issues() {
    final issues = schedule.issues();
    if (dataset.trim().isEmpty) {
      issues['dataset'] = const SnapshotValidationIssue(
        SnapshotValidationCode.datasetRequired,
      );
    }
    if (lifetimeValue < 1) {
      issues['lifetimeValue'] = const SnapshotValidationIssue(
        SnapshotValidationCode.retentionTooSmall,
      );
    }
    if (namingSchema.trim().isEmpty) {
      issues['namingSchema'] = const SnapshotValidationIssue(
        SnapshotValidationCode.namingSchemaRequired,
      );
    } else if (namingSchema.contains('/')) {
      issues['namingSchema'] = const SnapshotValidationIssue(
        SnapshotValidationCode.namingSchemaSlash,
      );
    }
    if (recursive) {
      for (final exclude in excludes) {
        if (exclude.isEmpty || !exclude.startsWith('$dataset/')) {
          issues['excludes'] = const SnapshotValidationIssue(
            SnapshotValidationCode.excludeNotChild,
          );
          break;
        }
      }
    }
    return issues;
  }
}

class SnapshotRetentionImpact {
  const SnapshotRetentionImpact({required this.counts});

  factory SnapshotRetentionImpact.fromResult(Object? result) {
    if (result is! Map) {
      throw const FormatException('Invalid snapshot retention impact data.');
    }
    final counts = <String, int>{};
    for (final entry in result.entries) {
      final value = entry.value;
      if (value is List) counts['${entry.key}'] = value.length;
    }
    return SnapshotRetentionImpact(counts: Map.unmodifiable(counts));
  }

  final Map<String, int> counts;

  int get total => counts.values.fold(0, (sum, count) => sum + count);

  bool get hasChanges => total > 0;
}

void _validateCron(
  String field,
  String value,
  Map<String, SnapshotValidationIssue> issues,
) {
  if (value.isEmpty || !RegExp(r'^[0-9*/,-]+$').hasMatch(value)) {
    issues[field] = const SnapshotValidationIssue(
      SnapshotValidationCode.cronInvalid,
    );
  }
}

void _validateTime(
  String field,
  String value,
  Map<String, SnapshotValidationIssue> issues,
) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  final hour = match == null ? null : int.tryParse(match.group(1)!);
  final minute = match == null ? null : int.tryParse(match.group(2)!);
  if (hour == null || minute == null || hour > 23 || minute > 59) {
    issues[field] = const SnapshotValidationIssue(
      SnapshotValidationCode.timeInvalid,
    );
  }
}
