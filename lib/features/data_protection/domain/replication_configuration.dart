import 'task_schedule.dart';

/// Which way data flows for a replication task.
enum ReplicationDirection { push, pull }

extension ReplicationDirectionApi on ReplicationDirection {
  String get apiValue => switch (this) {
    ReplicationDirection.push => 'PUSH',
    ReplicationDirection.pull => 'PULL',
  };

  String get label => switch (this) {
    ReplicationDirection.push => 'Push (this server to target)',
    ReplicationDirection.pull => 'Pull (target to this server)',
  };

  static ReplicationDirection fromApi(String? value) =>
      value == 'PULL' ? ReplicationDirection.pull : ReplicationDirection.push;
}

/// How the replication stream reaches the other system.
enum ReplicationTransport { ssh, sshNetcat, local }

extension ReplicationTransportApi on ReplicationTransport {
  String get apiValue => switch (this) {
    ReplicationTransport.ssh => 'SSH',
    ReplicationTransport.sshNetcat => 'SSH+NETCAT',
    ReplicationTransport.local => 'LOCAL',
  };

  String get label => switch (this) {
    ReplicationTransport.ssh => 'SSH',
    ReplicationTransport.sshNetcat => 'SSH + netcat (faster, less secure)',
    ReplicationTransport.local => 'Local (same system)',
  };

  /// `LOCAL` replicates within this server and needs no SSH connection.
  bool get requiresSshCredentials => this != ReplicationTransport.local;

  static ReplicationTransport fromApi(String? value) => switch (value) {
    'PULL' => ReplicationTransport.ssh,
    'SSH+NETCAT' => ReplicationTransport.sshNetcat,
    'LOCAL' => ReplicationTransport.local,
    _ => ReplicationTransport.ssh,
  };
}

/// How long replicated snapshots are kept on the destination.
enum ReplicationRetentionPolicy { source, custom, none }

extension ReplicationRetentionPolicyApi on ReplicationRetentionPolicy {
  String get apiValue => switch (this) {
    ReplicationRetentionPolicy.source => 'SOURCE',
    ReplicationRetentionPolicy.custom => 'CUSTOM',
    ReplicationRetentionPolicy.none => 'NONE',
  };

  String get label => switch (this) {
    ReplicationRetentionPolicy.source => 'Same as source',
    ReplicationRetentionPolicy.custom => 'Custom retention',
    ReplicationRetentionPolicy.none => 'Keep forever',
  };

  String get description => switch (this) {
    ReplicationRetentionPolicy.source =>
      'Destination snapshots follow the source task retention.',
    ReplicationRetentionPolicy.custom =>
      'Destination snapshots are destroyed after the period you set.',
    ReplicationRetentionPolicy.none =>
      'Destination snapshots are never destroyed automatically.',
  };
}

/// Retention units accepted by `lifetime_unit` when the policy is `CUSTOM`.
enum ReplicationLifetimeUnit { hour, day, week, month, year }

extension ReplicationLifetimeUnitApi on ReplicationLifetimeUnit {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    ReplicationLifetimeUnit.hour => 'Hours',
    ReplicationLifetimeUnit.day => 'Days',
    ReplicationLifetimeUnit.week => 'Weeks',
    ReplicationLifetimeUnit.month => 'Months',
    ReplicationLifetimeUnit.year => 'Years',
  };

  static ReplicationLifetimeUnit fromApi(String? value) {
    for (final unit in ReplicationLifetimeUnit.values) {
      if (unit.apiValue == value) return unit;
    }
    return ReplicationLifetimeUnit.week;
  }
}

/// Configuration collected by the replication editor and sent to
/// `replication.create` / `replication.update`.
///
/// Field names follow the documented TrueNAS SCALE API: `name`, `direction`,
/// `transport`, `ssh_credentials`, `source_datasets`, `target_dataset`,
/// `recursive`, `auto`, `enabled`, `retention_policy`, `schedule`, and
/// `also_include_naming_schema`. `source_datasets` is a list because a task can
/// replicate several datasets into one target; `target_dataset` is a single
/// path and may name a dataset that does not exist yet.
class ReplicationConfiguration {
  const ReplicationConfiguration({
    this.id,
    required this.name,
    required this.direction,
    required this.transport,
    this.sshCredentialId,
    required this.sourceDatasets,
    required this.targetDataset,
    this.recursive = false,
    this.auto = true,
    this.enabled = true,
    this.retentionPolicy = ReplicationRetentionPolicy.source,
    this.lifetimeValue = 2,
    this.lifetimeUnit = ReplicationLifetimeUnit.week,
    this.namingSchema = 'auto-%Y-%m-%d_%H-%M',
    this.schedule = const TaskSchedule(hour: '00'),
  });

  final int? id;
  final String name;
  final ReplicationDirection direction;
  final ReplicationTransport transport;

  /// Integer id from `keychaincredential.query`. Required unless the transport
  /// is `LOCAL`.
  final int? sshCredentialId;

  final List<String> sourceDatasets;
  final String targetDataset;
  final bool recursive;

  /// `auto` enables the schedule. A task with `auto: false` only runs manually.
  final bool auto;
  final bool enabled;
  final ReplicationRetentionPolicy retentionPolicy;
  final int lifetimeValue;
  final ReplicationLifetimeUnit lifetimeUnit;

  /// Snapshot naming pattern the task matches on the source.
  final String namingSchema;
  final TaskSchedule schedule;

  bool get isCreate => id == null;

  /// Payload for `replication.create` / `replication.update`.
  ///
  /// `ssh_credentials` is omitted entirely for `LOCAL` because the middleware
  /// rejects a credential on a local task. Retention fields are only sent for
  /// the `CUSTOM` policy for the same reason.
  Map<String, Object?> toApiJson() => {
    'name': name,
    'direction': direction.apiValue,
    'transport': transport.apiValue,
    if (transport.requiresSshCredentials && sshCredentialId != null)
      'ssh_credentials': sshCredentialId,
    'source_datasets': sourceDatasets,
    'target_dataset': targetDataset,
    'recursive': recursive,
    'auto': auto,
    'enabled': enabled,
    'retention_policy': retentionPolicy.apiValue,
    if (retentionPolicy == ReplicationRetentionPolicy.custom) ...{
      'lifetime_value': lifetimeValue,
      'lifetime_unit': lifetimeUnit.apiValue,
    },
    'also_include_naming_schema': [namingSchema],
    if (auto) 'schedule': schedule.toApiJson(),
  };

  ReplicationConfiguration copyWith({
    int? id,
    String? name,
    ReplicationDirection? direction,
    ReplicationTransport? transport,
    int? sshCredentialId,
    bool clearSshCredential = false,
    List<String>? sourceDatasets,
    String? targetDataset,
    bool? recursive,
    bool? auto,
    bool? enabled,
    ReplicationRetentionPolicy? retentionPolicy,
    int? lifetimeValue,
    ReplicationLifetimeUnit? lifetimeUnit,
    String? namingSchema,
    TaskSchedule? schedule,
  }) => ReplicationConfiguration(
    id: id ?? this.id,
    name: name ?? this.name,
    direction: direction ?? this.direction,
    transport: transport ?? this.transport,
    sshCredentialId: clearSshCredential
        ? null
        : (sshCredentialId ?? this.sshCredentialId),
    sourceDatasets: sourceDatasets ?? this.sourceDatasets,
    targetDataset: targetDataset ?? this.targetDataset,
    recursive: recursive ?? this.recursive,
    auto: auto ?? this.auto,
    enabled: enabled ?? this.enabled,
    retentionPolicy: retentionPolicy ?? this.retentionPolicy,
    lifetimeValue: lifetimeValue ?? this.lifetimeValue,
    lifetimeUnit: lifetimeUnit ?? this.lifetimeUnit,
    namingSchema: namingSchema ?? this.namingSchema,
    schedule: schedule ?? this.schedule,
  );
}

/// A stable code for a replication validation failure, so presentation layers
/// can translate the message instead of surfacing the English fallback.
enum ReplicationValidationCode {
  nameRequired,
  sourceDatasetsRequired,
  targetRequired,
  sshCredentialRequired,
  namingSchemaRequired,
  namingSchemaSlash,
  retentionTooSmall,
  targetSameAsSource,
  cronInvalid,
}

extension ReplicationValidationMessage on ReplicationValidationCode {
  String get message => switch (this) {
    ReplicationValidationCode.nameRequired => 'Enter a task name.',
    ReplicationValidationCode.sourceDatasetsRequired =>
      'Choose at least one source dataset.',
    ReplicationValidationCode.targetRequired => 'Enter a target dataset path.',
    ReplicationValidationCode.sshCredentialRequired =>
      'Choose the saved SSH connection for this transport.',
    ReplicationValidationCode.namingSchemaRequired =>
      'Enter a snapshot naming schema.',
    ReplicationValidationCode.namingSchemaSlash =>
      'Snapshot names cannot contain /.',
    ReplicationValidationCode.retentionTooSmall =>
      'Retention must be at least 1.',
    ReplicationValidationCode.targetSameAsSource =>
      'The target cannot be the same as a source dataset.',
    ReplicationValidationCode.cronInvalid => cronFieldMessage,
  };
}

/// Validates a [ReplicationConfiguration]. Returns field-keyed errors.
Map<String, String> validateReplicationConfiguration(
  ReplicationConfiguration config,
) => {
  for (final entry in replicationConfigurationIssues(config).entries)
    entry.key: entry.value.message,
};

/// Typed validation failures keyed by form field.
Map<String, ReplicationValidationCode> replicationConfigurationIssues(
  ReplicationConfiguration config,
) {
  final issues = <String, ReplicationValidationCode>{};
  if (config.name.trim().isEmpty) {
    issues['name'] = ReplicationValidationCode.nameRequired;
  }
  if (config.sourceDatasets.isEmpty ||
      config.sourceDatasets.every((dataset) => dataset.trim().isEmpty)) {
    issues['sourceDatasets'] = ReplicationValidationCode.sourceDatasetsRequired;
  }
  if (config.targetDataset.trim().isEmpty) {
    issues['targetDataset'] = ReplicationValidationCode.targetRequired;
  }
  if (config.transport.requiresSshCredentials &&
      config.sshCredentialId == null) {
    issues['sshCredentials'] = ReplicationValidationCode.sshCredentialRequired;
  }
  if (config.namingSchema.trim().isEmpty) {
    issues['namingSchema'] = ReplicationValidationCode.namingSchemaRequired;
  } else if (config.namingSchema.contains('/')) {
    issues['namingSchema'] = ReplicationValidationCode.namingSchemaSlash;
  }
  if (config.retentionPolicy == ReplicationRetentionPolicy.custom &&
      config.lifetimeValue < 1) {
    issues['lifetimeValue'] = ReplicationValidationCode.retentionTooSmall;
  }
  // A local task that replicates a dataset onto itself would destroy data.
  if (config.transport == ReplicationTransport.local &&
      config.sourceDatasets.contains(config.targetDataset.trim())) {
    issues['targetDataset'] = ReplicationValidationCode.targetSameAsSource;
  }
  if (config.auto) {
    for (final field in config.schedule.invalidCronFields()) {
      issues[field] = ReplicationValidationCode.cronInvalid;
    }
  }
  return issues;
}
