/// A stable code for a recognized cron schedule shape, so presentation layers
/// can describe the schedule in the active language instead of parsing the
/// English sentence [TaskSchedule.summary] returns.
enum TaskScheduleSummaryCode {
  everyHour,
  everySundayMidnight,
  firstOfMonthMidnight,
  everyDayMidnight,
  cron,
}

/// Cron schedule shared by replication and rsync tasks.
///
/// TrueNAS models task schedules as a `{minute, hour, dom, month, dow}` object
/// on `replication.create`/`update` and `rsynctask.create`/`update`. The fields
/// accept standard cron expressions, so validation only rejects characters the
/// middleware cannot parse rather than trying to fully evaluate the expression.
class TaskSchedule {
  const TaskSchedule({
    this.minute = '00',
    this.hour = '*',
    this.dayOfMonth = '*',
    this.month = '*',
    this.dayOfWeek = '*',
  });

  factory TaskSchedule.forPreset(TaskSchedulePreset preset) => switch (preset) {
    TaskSchedulePreset.hourly => const TaskSchedule(),
    TaskSchedulePreset.daily => const TaskSchedule(hour: '00'),
    TaskSchedulePreset.weekly => const TaskSchedule(hour: '00', dayOfWeek: '7'),
    TaskSchedulePreset.monthly => const TaskSchedule(
      hour: '00',
      dayOfMonth: '1',
    ),
    TaskSchedulePreset.custom => const TaskSchedule(),
  };

  /// Seeds a schedule from a `schedule` object returned by a task query.
  factory TaskSchedule.fromJson(Map<String, dynamic> json) => TaskSchedule(
    minute: json['minute'] is String ? json['minute'] as String : '00',
    hour: json['hour'] is String ? json['hour'] as String : '*',
    dayOfMonth: json['dom'] is String ? json['dom'] as String : '*',
    month: json['month'] is String ? json['month'] as String : '*',
    dayOfWeek: json['dow'] is String ? json['dow'] as String : '*',
  );

  final String minute;
  final String hour;
  final String dayOfMonth;
  final String month;
  final String dayOfWeek;

  Map<String, Object?> toApiJson() => {
    'minute': minute,
    'hour': hour,
    'dom': dayOfMonth,
    'month': month,
    'dow': dayOfWeek,
  };

  TaskSchedule copyWith({
    String? minute,
    String? hour,
    String? dayOfMonth,
    String? month,
    String? dayOfWeek,
  }) => TaskSchedule(
    minute: minute ?? this.minute,
    hour: hour ?? this.hour,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    month: month ?? this.month,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
  );

  Map<String, String> validate() {
    final errors = <String, String>{};
    for (final field in invalidCronFields()) {
      errors[field] = cronFieldMessage;
    }
    return errors;
  }

  /// Field names whose cron expression the middleware would reject. The
  /// message is identical for every field, so the caller supplies its own
  /// translated text rather than receiving English here.
  Set<String> invalidCronFields() => {
    if (!_isValidCron(minute)) 'minute',
    if (!_isValidCron(hour)) 'hour',
    if (!_isValidCron(dayOfMonth)) 'dayOfMonth',
    if (!_isValidCron(month)) 'month',
    if (!_isValidCron(dayOfWeek)) 'dayOfWeek',
  };

  /// The recognized shape of this schedule. Anything TrueDock does not
  /// recognize falls back to the raw cron fields, which are locale-independent.
  TaskScheduleSummaryCode get summaryCode {
    if (minute == '00' && hour == '*') return TaskScheduleSummaryCode.everyHour;
    if (minute == '00' && hour == '00' && dayOfWeek == '7') {
      return TaskScheduleSummaryCode.everySundayMidnight;
    }
    if (minute == '00' && hour == '00' && dayOfMonth == '1') {
      return TaskScheduleSummaryCode.firstOfMonthMidnight;
    }
    if (minute == '00' && hour == '00') {
      return TaskScheduleSummaryCode.everyDayMidnight;
    }
    return TaskScheduleSummaryCode.cron;
  }

  /// The cron expression shown when [summaryCode] is
  /// [TaskScheduleSummaryCode.cron].
  String get cronExpression => '$minute $hour $dayOfMonth $month $dayOfWeek';

  String get summary => switch (summaryCode) {
    TaskScheduleSummaryCode.everyHour => 'At the start of every hour',
    TaskScheduleSummaryCode.everySundayMidnight => 'Every Sunday at 00:00',
    TaskScheduleSummaryCode.firstOfMonthMidnight =>
      'On day 1 of every month at 00:00',
    TaskScheduleSummaryCode.everyDayMidnight => 'Every day at 00:00',
    TaskScheduleSummaryCode.cron => 'Cron $cronExpression',
  };
}

enum TaskSchedulePreset { hourly, daily, weekly, monthly, custom }

extension TaskSchedulePresetLabel on TaskSchedulePreset {
  String get label => switch (this) {
    TaskSchedulePreset.hourly => 'Hourly',
    TaskSchedulePreset.daily => 'Daily',
    TaskSchedulePreset.weekly => 'Weekly',
    TaskSchedulePreset.monthly => 'Monthly',
    TaskSchedulePreset.custom => 'Custom',
  };
}

/// English fallback for an invalid cron field. Presentation layers translate
/// the same condition through their own resources.
const cronFieldMessage = 'Use a numeric cron expression such as *, 00, or */2.';

bool _isValidCron(String value) =>
    value.isNotEmpty && RegExp(r'^[0-9*/,-]+$').hasMatch(value);

/// A saved SSH connection from `keychaincredential.query`.
///
/// Replication over `SSH`/`SSH+NETCAT` and rsync in `SSH` mode reference these
/// by integer id. TrueDock only selects existing credentials; creating them
/// involves private-key material and is intentionally left to the web UI.
class SshCredential {
  const SshCredential({required this.id, required this.name});

  factory SshCredential.fromJson(Map<String, dynamic> json) => SshCredential(
    id: json['id'] is num ? (json['id'] as num).toInt() : 0,
    name: json['name'] is String && (json['name'] as String).isNotEmpty
        ? json['name'] as String
        : 'SSH connection',
  );

  final int id;
  final String name;
}
