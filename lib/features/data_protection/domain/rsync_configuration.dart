import 'task_schedule.dart';

/// Which way data flows for an rsync task.
enum RsyncDirection { push, pull }

extension RsyncDirectionApi on RsyncDirection {
  String get apiValue => switch (this) {
    RsyncDirection.push => 'PUSH',
    RsyncDirection.pull => 'PULL',
  };

  String get label => switch (this) {
    RsyncDirection.push => 'Push (this server to remote)',
    RsyncDirection.pull => 'Pull (remote to this server)',
  };

  String get description => switch (this) {
    RsyncDirection.push => 'Sends the local path to the remote host or module.',
    RsyncDirection.pull =>
      'Copies the remote path into the local path on this server.',
  };

  static RsyncDirection fromApi(String? value) =>
      value == 'PULL' ? RsyncDirection.pull : RsyncDirection.push;
}

/// How rsync connects to the remote system.
enum RsyncMode { ssh, module }

extension RsyncModeApi on RsyncMode {
  String get apiValue => switch (this) {
    RsyncMode.ssh => 'SSH',
    RsyncMode.module => 'MODULE',
  };

  String get label => switch (this) {
    RsyncMode.ssh => 'SSH',
    RsyncMode.module => 'rsync module',
  };

  /// SSH mode references a saved connection; module mode uses the rsync
  /// daemon protocol and has no SSH credential.
  bool get usesSshCredentials => this == RsyncMode.ssh;

  /// TrueNAS defaults to port 22 for SSH and 873 for the rsync daemon.
  int get defaultPort => this == RsyncMode.ssh ? 22 : 873;

  static RsyncMode fromApi(String? value) =>
      value == 'SSH' ? RsyncMode.ssh : RsyncMode.module;
}

/// Configuration collected by the rsync editor and sent to
/// `rsynctask.create` / `rsynctask.update`.
///
/// Field names follow the documented TrueNAS SCALE API: `path`, `user`,
/// `direction`, `desc`, `remotehost`, `remoteport`, `mode`, `remotepath`,
/// `remotemodule`, `ssh_credentials`, `enabled`, `validate_rpath`, and
/// `schedule`. `remotepath` applies to SSH mode and `remotemodule` to module
/// mode; sending the wrong one is rejected by the middleware, so the editor
/// emits only the field that matches the selected mode.
class RsyncConfiguration {
  const RsyncConfiguration({
    this.id,
    required this.path,
    required this.user,
    required this.direction,
    required this.mode,
    this.description = '',
    this.remoteHost = '',
    this.remotePort,
    this.remotePath = '',
    this.remoteModule = '',
    this.sshCredentialId,
    this.enabled = true,
    this.validateRemotePath = true,
    this.schedule = const TaskSchedule(hour: '00'),
  });

  final int? id;

  /// Absolute local path on this server.
  final String path;

  /// Local user the task runs as. Must match the SSH connection user.
  final String user;

  final RsyncDirection direction;
  final RsyncMode mode;
  final String description;
  final String remoteHost;

  /// Null falls back to the mode default (22 for SSH, 873 for module).
  final int? remotePort;

  /// Remote filesystem path, used in SSH mode.
  final String remotePath;

  /// Remote rsync module name, used in module mode.
  final String remoteModule;

  /// Integer id from `keychaincredential.query`, used in SSH mode.
  final int? sshCredentialId;

  final bool enabled;

  /// Asks the server to verify the remote path exists before running.
  final bool validateRemotePath;

  final TaskSchedule schedule;

  bool get isCreate => id == null;

  int get effectivePort => remotePort ?? mode.defaultPort;

  /// Payload for `rsynctask.create` / `rsynctask.update`.
  Map<String, Object?> toApiJson() => {
    'path': path,
    'user': user,
    'direction': direction.apiValue,
    'mode': mode.apiValue,
    if (description.isNotEmpty) 'desc': description,
    'remotehost': remoteHost,
    'remoteport': effectivePort,
    if (mode == RsyncMode.ssh) ...{
      'remotepath': remotePath,
      if (sshCredentialId != null) 'ssh_credentials': sshCredentialId,
    } else
      'remotemodule': remoteModule,
    'enabled': enabled,
    'validate_rpath': validateRemotePath,
    'schedule': schedule.toApiJson(),
  };

  RsyncConfiguration copyWith({
    int? id,
    String? path,
    String? user,
    RsyncDirection? direction,
    RsyncMode? mode,
    String? description,
    String? remoteHost,
    int? remotePort,
    bool clearRemotePort = false,
    String? remotePath,
    String? remoteModule,
    int? sshCredentialId,
    bool clearSshCredential = false,
    bool? enabled,
    bool? validateRemotePath,
    TaskSchedule? schedule,
  }) => RsyncConfiguration(
    id: id ?? this.id,
    path: path ?? this.path,
    user: user ?? this.user,
    direction: direction ?? this.direction,
    mode: mode ?? this.mode,
    description: description ?? this.description,
    remoteHost: remoteHost ?? this.remoteHost,
    remotePort: clearRemotePort ? null : (remotePort ?? this.remotePort),
    remotePath: remotePath ?? this.remotePath,
    remoteModule: remoteModule ?? this.remoteModule,
    sshCredentialId: clearSshCredential
        ? null
        : (sshCredentialId ?? this.sshCredentialId),
    enabled: enabled ?? this.enabled,
    validateRemotePath: validateRemotePath ?? this.validateRemotePath,
    schedule: schedule ?? this.schedule,
  );
}

/// A stable code for an rsync validation failure, so presentation layers can
/// translate the message instead of surfacing the English fallback.
enum RsyncValidationCode {
  pathRequired,
  pathNotAbsolute,
  userRequired,
  remoteHostRequired,
  remotePortRange,
  remotePathRequired,
  sshCredentialRequired,
  remoteModuleRequired,
  cronInvalid,
}

extension RsyncValidationMessage on RsyncValidationCode {
  String get message => switch (this) {
    RsyncValidationCode.pathRequired => 'Enter a local path.',
    RsyncValidationCode.pathNotAbsolute =>
      'Use an absolute path starting with /.',
    RsyncValidationCode.userRequired => 'Choose the local user to run as.',
    RsyncValidationCode.remoteHostRequired => 'Enter the remote host.',
    RsyncValidationCode.remotePortRange => 'Use a port between 1 and 65535.',
    RsyncValidationCode.remotePathRequired => 'Enter the remote path.',
    RsyncValidationCode.sshCredentialRequired =>
      'Choose the saved SSH connection.',
    RsyncValidationCode.remoteModuleRequired =>
      'Enter the remote rsync module name.',
    RsyncValidationCode.cronInvalid => cronFieldMessage,
  };
}

/// Validates an [RsyncConfiguration]. Returns field-keyed errors.
Map<String, String> validateRsyncConfiguration(RsyncConfiguration config) => {
  for (final entry in rsyncConfigurationIssues(config).entries)
    entry.key: entry.value.message,
};

/// Typed validation failures keyed by form field.
Map<String, RsyncValidationCode> rsyncConfigurationIssues(
  RsyncConfiguration config,
) {
  final issues = <String, RsyncValidationCode>{};
  final path = config.path.trim();
  if (path.isEmpty) {
    issues['path'] = RsyncValidationCode.pathRequired;
  } else if (!path.startsWith('/')) {
    issues['path'] = RsyncValidationCode.pathNotAbsolute;
  }
  if (config.user.trim().isEmpty) {
    issues['user'] = RsyncValidationCode.userRequired;
  }
  if (config.remoteHost.trim().isEmpty) {
    issues['remoteHost'] = RsyncValidationCode.remoteHostRequired;
  }
  final port = config.remotePort;
  if (port != null && (port < 1 || port > 65535)) {
    issues['remotePort'] = RsyncValidationCode.remotePortRange;
  }
  if (config.mode == RsyncMode.ssh) {
    if (config.remotePath.trim().isEmpty) {
      issues['remotePath'] = RsyncValidationCode.remotePathRequired;
    }
    if (config.sshCredentialId == null) {
      issues['sshCredentials'] = RsyncValidationCode.sshCredentialRequired;
    }
  } else {
    if (config.remoteModule.trim().isEmpty) {
      issues['remoteModule'] = RsyncValidationCode.remoteModuleRequired;
    }
  }
  for (final field in config.schedule.invalidCronFields()) {
    issues[field] = RsyncValidationCode.cronInvalid;
  }
  return issues;
}
