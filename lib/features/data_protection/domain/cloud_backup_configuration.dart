import 'package:meta/meta.dart';

import 'cloud_sync_configuration.dart';
import 'task_schedule.dart';

/// How aggressively the backup transfers data.
enum CloudBackupTransferSetting {
  standard('DEFAULT'),
  performance('PERFORMANCE'),
  fastStorage('FAST_STORAGE');

  const CloudBackupTransferSetting(this.apiValue);

  final String apiValue;

  static CloudBackupTransferSetting fromApi(Object? value) {
    for (final setting in values) {
      if (setting.apiValue == value) return setting;
    }
    return CloudBackupTransferSetting.standard;
  }
}

/// Stable codes for cloud backup validation failures.
enum CloudBackupValidationCode {
  pathRequired,
  pathNotAbsolute,
  credentialRequired,
  passwordRequired,
  bucketRequired,
  keepLastRange,
}

@immutable
class CloudBackupValidationIssue {
  const CloudBackupValidationIssue(this.code, {this.bound});
  final CloudBackupValidationCode code;
  final int? bound;
}

/// A cloud backup task, for `cloud_backup.create` / `update`.
///
/// Distinct from a cloud *sync* task despite the similar shape: this is a
/// restic-style repository with snapshot retention, so it carries a repository
/// password and a `keep_last` count that cloud sync has no equivalent for. The
/// schedule reuses [TaskSchedule] because the payload is the same object.
@immutable
class CloudBackupConfiguration {
  const CloudBackupConfiguration({
    required this.path,
    required this.credentialId,
    required this.keepLast,
    this.description = '',
    this.password = '',
    this.bucket = '',
    this.folder = '',
    this.schedule = const TaskSchedule(),
    this.enabled = true,
    this.snapshot = false,
    this.transferSetting = CloudBackupTransferSetting.standard,
    this.excludePaths = const [],
  });

  factory CloudBackupConfiguration.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    final attributeMap = attributes is Map ? attributes : const {};
    final credentials = json['credentials'];
    final schedule = json['schedule'];
    return CloudBackupConfiguration(
      path: json['path'] is String ? json['path'] as String : '',
      // `credentials` is an id on the way in and an expanded object on the way
      // out, so both shapes have to be accepted.
      credentialId: credentials is int
          ? credentials
          : credentials is Map && credentials['id'] is int
          ? credentials['id'] as int
          : null,
      keepLast: json['keep_last'] is int ? json['keep_last'] as int : 0,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      // The repository password is never modelled from a read: see [password].
      bucket: '${attributeMap['bucket'] ?? ''}',
      folder: '${attributeMap['folder'] ?? ''}',
      schedule: schedule is Map<String, dynamic>
          ? TaskSchedule.fromJson(schedule)
          : const TaskSchedule(),
      enabled: json['enabled'] != false,
      snapshot: json['snapshot'] == true,
      transferSetting: CloudBackupTransferSetting.fromApi(
        json['transfer_setting'],
      ),
      excludePaths: json['exclude'] is List
          ? (json['exclude'] as List).whereType<String>().toList(
              growable: false,
            )
          : const [],
    );
  }

  /// Dataset path being backed up, absolute under `/mnt`.
  final String path;
  final int? credentialId;

  /// Snapshots to retain in the repository. The server requires it on create.
  final int keepLast;
  final String description;

  /// Repository password. Write-only: `cloud_backup.query` returns it, but
  /// TrueDock never seeds an editor from it, so a blank field on an edit means
  /// "unchanged" and the caller substitutes the stored value.
  final String password;
  final String bucket;
  final String folder;
  final TaskSchedule schedule;
  final bool enabled;

  /// Take a ZFS snapshot first, so the backup is consistent rather than a live
  /// read of a changing dataset.
  final bool snapshot;
  final CloudBackupTransferSetting transferSetting;
  final List<String> excludePaths;

  List<CloudBackupValidationIssue> validate({bool requirePassword = true}) {
    final issues = <CloudBackupValidationIssue>[];
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      issues.add(
        const CloudBackupValidationIssue(
          CloudBackupValidationCode.pathRequired,
        ),
      );
    } else if (!trimmed.startsWith('/')) {
      issues.add(
        const CloudBackupValidationIssue(
          CloudBackupValidationCode.pathNotAbsolute,
        ),
      );
    }
    if (credentialId == null) {
      issues.add(
        const CloudBackupValidationIssue(
          CloudBackupValidationCode.credentialRequired,
        ),
      );
    }
    // Only a create needs one: an edit leaves it blank to keep the stored
    // password, which the caller substitutes.
    if (requirePassword && password.isEmpty) {
      issues.add(
        const CloudBackupValidationIssue(
          CloudBackupValidationCode.passwordRequired,
        ),
      );
    }
    if (keepLast < 1) {
      issues.add(
        const CloudBackupValidationIssue(
          CloudBackupValidationCode.keepLastRange,
          bound: 1,
        ),
      );
    }
    return issues;
  }

  /// Whether this provider needs a bucket, so the editor and the payload agree.
  ///
  /// Reuses `CloudCredential.usesBucket` rather than repeating the provider
  /// list: cloud sync and cloud backup share the same credential objects, and a
  /// second copy of that list would eventually disagree with the first.

  /// Payload for `cloud_backup.create` / `update`.
  ///
  /// [storedPassword] stands in when the user left the field blank on an edit;
  /// the server requires `password` and would otherwise reject the call.
  Map<String, Object?> toApiJson({
    CloudCredential? credential,
    String? storedPassword,
  }) {
    final effectivePassword = password.isEmpty
        ? (storedPassword ?? '')
        : password;
    final attributes = <String, Object?>{
      if (folder.trim().isNotEmpty) 'folder': folder.trim(),
      if ((credential?.usesBucket ?? bucket.trim().isNotEmpty) &&
          bucket.trim().isNotEmpty)
        'bucket': bucket.trim(),
    };
    return <String, Object?>{
      'path': path.trim(),
      'credentials': credentialId,
      'attributes': attributes,
      'password': effectivePassword,
      'keep_last': keepLast,
      'description': description.trim(),
      'enabled': enabled,
      'snapshot': snapshot,
      'transfer_setting': transferSetting.apiValue,
      'schedule': schedule.toApiJson(),
      if (excludePaths.isNotEmpty) 'exclude': excludePaths,
    };
  }

  /// True when the payload carries the repository password.
  bool get carriesSecret => true;

  CloudBackupConfiguration copyWith({
    String? path,
    int? credentialId,
    int? keepLast,
    String? description,
    String? password,
    String? bucket,
    String? folder,
    TaskSchedule? schedule,
    bool? enabled,
    bool? snapshot,
    CloudBackupTransferSetting? transferSetting,
    List<String>? excludePaths,
  }) => CloudBackupConfiguration(
    path: path ?? this.path,
    credentialId: credentialId ?? this.credentialId,
    keepLast: keepLast ?? this.keepLast,
    description: description ?? this.description,
    password: password ?? this.password,
    bucket: bucket ?? this.bucket,
    folder: folder ?? this.folder,
    schedule: schedule ?? this.schedule,
    enabled: enabled ?? this.enabled,
    snapshot: snapshot ?? this.snapshot,
    transferSetting: transferSetting ?? this.transferSetting,
    excludePaths: excludePaths ?? this.excludePaths,
  );
}

/// A cloud backup task as returned by `cloud_backup.query`.
@immutable
class CloudBackupTask {
  const CloudBackupTask({
    required this.id,
    required this.configuration,
    this.storedPassword,
    this.credentialName,
    this.lastRunState,
  });

  factory CloudBackupTask.fromJson(Map<String, dynamic> json) {
    final credentials = json['credentials'];
    final job = json['job'];
    return CloudBackupTask(
      id: json['id'] is int ? json['id'] as int : -1,
      configuration: CloudBackupConfiguration.fromJson(json),
      // Held only so an edit that leaves the password blank can resend it: the
      // server requires the field, and a blank would leave the repository
      // unreadable. Deliberately not part of [CloudBackupConfiguration], so it
      // never reaches an editor, a screenshot, or a state dump.
      storedPassword: json['password'] is String
          ? json['password'] as String
          : null,
      credentialName: credentials is Map && credentials['name'] is String
          ? credentials['name'] as String
          : null,
      // The most recent run is embedded rather than fetched separately.
      lastRunState: job is Map && job['state'] is String
          ? job['state'] as String
          : null,
    );
  }

  final int id;
  final CloudBackupConfiguration configuration;

  /// Repository password as the server reports it, used only to resend an
  /// unchanged value on an edit.
  final String? storedPassword;
  final String? credentialName;
  final String? lastRunState;

  String get path => configuration.path;
  String get description => configuration.description;
  bool get enabled => configuration.enabled;
  TaskSchedule get schedule => configuration.schedule;
  int get keepLast => configuration.keepLast;
}

/// One snapshot in a backup repository, from `cloud_backup.list_snapshots`.
@immutable
class CloudBackupSnapshot {
  const CloudBackupSnapshot({
    required this.id,
    required this.time,
    this.paths = const [],
    this.hostname,
  });

  factory CloudBackupSnapshot.fromJson(Map<String, dynamic> json) {
    final time = json['time'];
    return CloudBackupSnapshot(
      id: '${json['id'] ?? json['short_id'] ?? ''}',
      time: time is String ? DateTime.tryParse(time) : null,
      paths: json['paths'] is List
          ? (json['paths'] as List).whereType<String>().toList(growable: false)
          : const [],
      hostname: json['hostname'] is String ? json['hostname'] as String : null,
    );
  }

  final String id;
  final DateTime? time;
  final List<String> paths;
  final String? hostname;
}
