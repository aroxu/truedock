import 'package:meta/meta.dart';

import '../../data_protection/domain/task_schedule.dart';

/// Stable codes for cron job validation failures.
enum CronJobValidationCode { commandRequired, userRequired }

@immutable
class CronJobValidationIssue {
  const CronJobValidationIssue(this.code);
  final CronJobValidationCode code;
}

/// A scheduled command, for `cronjob.create` / `cronjob.update`.
///
/// The schedule reuses [TaskSchedule] because `cronjob` takes the same
/// `{minute, hour, dom, month, dow}` object the snapshot and replication tasks
/// use; duplicating it would let the two drift.
@immutable
class CronJobConfiguration {
  const CronJobConfiguration({
    required this.command,
    required this.user,
    this.description = '',
    this.enabled = true,
    this.schedule = const TaskSchedule(),
    this.captureStdout = true,
    this.captureStderr = false,
  });

  factory CronJobConfiguration.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'];
    return CronJobConfiguration(
      command: json['command'] is String ? json['command'] as String : '',
      user: json['user'] is String ? json['user'] as String : 'root',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      enabled: json['enabled'] != false,
      schedule: schedule is Map<String, dynamic>
          ? TaskSchedule.fromJson(schedule)
          : const TaskSchedule(),
      // The API names these from the daemon's point of view: `stdout: true`
      // means "hide stdout from the mailed report". TrueDock exposes the
      // inverse, because "capture output" is what a user is deciding.
      captureStdout: json['stdout'] != true,
      captureStderr: json['stderr'] == true,
    );
  }

  final String command;

  /// Account the command runs as. TrueNAS validates that it exists.
  final String user;
  final String description;
  final bool enabled;
  final TaskSchedule schedule;

  /// Whether stdout is kept in the job report rather than discarded.
  final bool captureStdout;
  final bool captureStderr;

  List<CronJobValidationIssue> validate() {
    final issues = <CronJobValidationIssue>[];
    if (command.trim().isEmpty) {
      issues.add(
        const CronJobValidationIssue(CronJobValidationCode.commandRequired),
      );
    }
    if (user.trim().isEmpty) {
      issues.add(
        const CronJobValidationIssue(CronJobValidationCode.userRequired),
      );
    }
    return issues;
  }

  Map<String, Object?> toApiJson() => <String, Object?>{
    'command': command.trim(),
    'user': user.trim(),
    'description': description.trim(),
    'enabled': enabled,
    'schedule': schedule.toApiJson(),
    // Inverted back into the daemon's vocabulary: `stdout: true` suppresses it.
    'stdout': !captureStdout,
    'stderr': captureStderr,
  };

  CronJobConfiguration copyWith({
    String? command,
    String? user,
    String? description,
    bool? enabled,
    TaskSchedule? schedule,
    bool? captureStdout,
    bool? captureStderr,
  }) => CronJobConfiguration(
    command: command ?? this.command,
    user: user ?? this.user,
    description: description ?? this.description,
    enabled: enabled ?? this.enabled,
    schedule: schedule ?? this.schedule,
    captureStdout: captureStdout ?? this.captureStdout,
    captureStderr: captureStderr ?? this.captureStderr,
  );
}

/// A cron job as returned by `cronjob.query`.
@immutable
class CronJob {
  const CronJob({required this.id, required this.configuration});

  factory CronJob.fromJson(Map<String, dynamic> json) => CronJob(
    id: json['id'] is int ? json['id'] as int : -1,
    configuration: CronJobConfiguration.fromJson(json),
  );

  final int id;
  final CronJobConfiguration configuration;

  String get command => configuration.command;
  String get user => configuration.user;
  String get description => configuration.description;
  bool get enabled => configuration.enabled;
  TaskSchedule get schedule => configuration.schedule;
}
