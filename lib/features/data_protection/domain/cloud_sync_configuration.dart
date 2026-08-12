import 'task_schedule.dart';

/// Which way data flows for a cloud sync task.
enum CloudSyncDirection { push, pull }

extension CloudSyncDirectionApi on CloudSyncDirection {
  String get apiValue => switch (this) {
    CloudSyncDirection.push => 'PUSH',
    CloudSyncDirection.pull => 'PULL',
  };

  String get label => switch (this) {
    CloudSyncDirection.push => 'Push (this server to cloud)',
    CloudSyncDirection.pull => 'Pull (cloud to this server)',
  };

  String get description => switch (this) {
    CloudSyncDirection.push => 'Sends the local path up to the cloud provider.',
    CloudSyncDirection.pull =>
      'Downloads the remote location into the local path.',
  };

  static CloudSyncDirection fromApi(String? value) =>
      value == 'PULL' ? CloudSyncDirection.pull : CloudSyncDirection.push;
}

/// How the transfer reconciles source and destination.
///
/// Only [copy] is non-destructive: [sync] deletes destination files that no
/// longer exist on the source, and [move] deletes the source files after a
/// successful transfer.
enum CloudSyncTransferMode { sync, copy, move }

extension CloudSyncTransferModeApi on CloudSyncTransferMode {
  String get apiValue => switch (this) {
    CloudSyncTransferMode.sync => 'SYNC',
    CloudSyncTransferMode.copy => 'COPY',
    CloudSyncTransferMode.move => 'MOVE',
  };

  String get label => switch (this) {
    CloudSyncTransferMode.sync => 'Sync',
    CloudSyncTransferMode.copy => 'Copy',
    CloudSyncTransferMode.move => 'Move',
  };

  String get description => switch (this) {
    CloudSyncTransferMode.sync =>
      'Makes the destination match the source. Files missing from the '
          'source are deleted at the destination.',
    CloudSyncTransferMode.copy =>
      'Copies new and changed files. Nothing is ever deleted.',
    CloudSyncTransferMode.move =>
      'Copies files, then deletes them from the source once the transfer '
          'succeeds.',
  };

  /// True when the mode can delete data on either side.
  bool get deletesData => this != CloudSyncTransferMode.copy;

  static CloudSyncTransferMode fromApi(String? value) => switch (value) {
    'COPY' => CloudSyncTransferMode.copy,
    'MOVE' => CloudSyncTransferMode.move,
    _ => CloudSyncTransferMode.sync,
  };
}

/// A saved cloud credential from `cloudsync.credentials.query`.
///
/// Cloud sync tasks reference these by integer id. TrueDock only selects
/// existing credentials; creating them involves provider secrets and OAuth
/// flows, so that stays in the web UI.
class CloudCredential {
  const CloudCredential({
    required this.id,
    required this.name,
    required this.provider,
  });

  factory CloudCredential.fromJson(Map<String, dynamic> json) {
    final rawProvider = json['provider'];
    // 25.10 returns provider as an object; older shapes return a bare string.
    final provider = rawProvider is Map
        ? (rawProvider['type'] is String ? rawProvider['type'] as String : '')
        : (rawProvider is String ? rawProvider : '');
    return CloudCredential(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: json['name'] is String && (json['name'] as String).isNotEmpty
          ? json['name'] as String
          : 'Cloud credential',
      provider: provider,
    );
  }

  final int id;
  final String name;

  /// Provider type such as `S3`, `B2`, `GOOGLE_DRIVE`, or `DROPBOX`.
  final String provider;

  /// Providers that address objects inside a bucket. Bucket-less providers
  /// (personal drive services) use only a folder path.
  static const _bucketProviders = {
    'S3',
    'B2',
    'GOOGLE_CLOUD_STORAGE',
    'AZUREBLOB',
    'OPENSTACK_SWIFT',
    'STORJ_IX',
  };

  /// True when `attributes` should carry a `bucket` alongside `folder`.
  bool get usesBucket => _bucketProviders.contains(provider.toUpperCase());

  /// Storage class only applies to S3-compatible providers.
  bool get supportsStorageClass => provider.toUpperCase() == 'S3';

  String get label => provider.isEmpty ? name : '$name ($provider)';
}

/// Configuration collected by the cloud sync editor and sent to
/// `cloudsync.create` / `cloudsync.update`.
///
/// Field names follow the documented TrueNAS SCALE API: `description`,
/// `direction`, `transfer_mode`, `path`, `credentials`, `attributes`,
/// `schedule`, `transfers`, `encryption`, `filename_encryption`,
/// `encryption_password`, `encryption_salt`, and `enabled`.
///
/// The remote location lives in `attributes`, whose shape depends on the
/// provider: bucket-based providers use `bucket` plus `folder`, while
/// bucket-less providers use `folder` alone.
class CloudSyncConfiguration {
  const CloudSyncConfiguration({
    this.id,
    required this.description,
    required this.direction,
    required this.transferMode,
    required this.path,
    this.credentialId,
    this.bucket = '',
    this.folder = '',
    this.storageClass = '',
    this.transfers,
    this.encryption = false,
    this.filenameEncryption = false,
    this.encryptionPassword = '',
    this.encryptionSalt = '',
    this.enabled = true,
    this.schedule = const TaskSchedule(hour: '00'),
    this.preservedAttributes = const {},
    this.preservedFields = const {},
  });

  final int? id;
  final String description;
  final CloudSyncDirection direction;
  final CloudSyncTransferMode transferMode;

  /// Absolute local path on this server.
  final String path;

  /// Integer id from `cloudsync.credentials.query`.
  final int? credentialId;

  /// Remote bucket, for providers that use buckets.
  final String bucket;

  /// Remote folder path within the bucket or drive.
  final String folder;

  /// S3 storage class, e.g. STANDARD or GLACIER. Empty leaves it unset.
  final String storageClass;

  /// Concurrent transfer count. Null leaves the server default.
  final int? transfers;

  final bool encryption;
  final bool filenameEncryption;

  /// Secrets are write-only: they are sent to the server on save and are
  /// never persisted or logged by TrueDock.
  final String encryptionPassword;
  final String encryptionSalt;

  final bool enabled;
  final TaskSchedule schedule;

  /// Attribute keys the editor does not surface, preserved from the existing
  /// task so an update round-trips provider-specific settings unchanged.
  final Map<String, Object?> preservedAttributes;

  /// Top-level fields the editor does not surface (pre_script, post_script,
  /// bwlimit, chunk_size, exclude, and similar), preserved on update.
  ///
  /// Scripts run arbitrary commands on the server, so the mobile editor does
  /// not expose them; round-tripping them keeps an existing task intact.
  final Map<String, Object?> preservedFields;

  bool get isCreate => id == null;

  /// Whether this configuration addresses a bucket-based provider.
  ///
  /// Determined by the selected credential, which the caller supplies because
  /// the provider type lives on the credential rather than the task.
  bool usesBucketFor(CloudCredential? credential) =>
      credential?.usesBucket ?? bucket.isNotEmpty;

  /// Builds the `attributes` object for the selected provider.
  Map<String, Object?> attributesFor(CloudCredential? credential) {
    final attributes = <String, Object?>{...preservedAttributes};
    if (usesBucketFor(credential)) {
      attributes['bucket'] = bucket;
    } else {
      attributes.remove('bucket');
    }
    attributes['folder'] = folder;
    if (credential?.supportsStorageClass == true && storageClass.isNotEmpty) {
      attributes['storage_class'] = storageClass;
    } else {
      attributes.remove('storage_class');
    }
    return attributes;
  }

  /// Payload for `cloudsync.create` / `cloudsync.update`.
  ///
  /// Encryption secrets are omitted when encryption is off, and an empty
  /// password/salt is omitted on update so an existing secret is not cleared
  /// by an edit that did not touch it.
  Map<String, Object?> toApiJson(CloudCredential? credential) => {
    ...preservedFields,
    'description': description,
    'direction': direction.apiValue,
    'transfer_mode': transferMode.apiValue,
    'path': path,
    if (credentialId != null) 'credentials': credentialId,
    'attributes': attributesFor(credential),
    'schedule': schedule.toApiJson(),
    if (transfers != null) 'transfers': transfers,
    'encryption': encryption,
    if (encryption) ...{
      'filename_encryption': filenameEncryption,
      if (encryptionPassword.isNotEmpty)
        'encryption_password': encryptionPassword,
      if (encryptionSalt.isNotEmpty) 'encryption_salt': encryptionSalt,
    },
    'enabled': enabled,
  };

  CloudSyncConfiguration copyWith({
    int? id,
    String? description,
    CloudSyncDirection? direction,
    CloudSyncTransferMode? transferMode,
    String? path,
    int? credentialId,
    bool clearCredential = false,
    String? bucket,
    String? folder,
    String? storageClass,
    int? transfers,
    bool clearTransfers = false,
    bool? encryption,
    bool? filenameEncryption,
    String? encryptionPassword,
    String? encryptionSalt,
    bool? enabled,
    TaskSchedule? schedule,
    Map<String, Object?>? preservedAttributes,
    Map<String, Object?>? preservedFields,
  }) => CloudSyncConfiguration(
    id: id ?? this.id,
    description: description ?? this.description,
    direction: direction ?? this.direction,
    transferMode: transferMode ?? this.transferMode,
    path: path ?? this.path,
    credentialId: clearCredential ? null : (credentialId ?? this.credentialId),
    bucket: bucket ?? this.bucket,
    folder: folder ?? this.folder,
    storageClass: storageClass ?? this.storageClass,
    transfers: clearTransfers ? null : (transfers ?? this.transfers),
    encryption: encryption ?? this.encryption,
    filenameEncryption: filenameEncryption ?? this.filenameEncryption,
    encryptionPassword: encryptionPassword ?? this.encryptionPassword,
    encryptionSalt: encryptionSalt ?? this.encryptionSalt,
    enabled: enabled ?? this.enabled,
    schedule: schedule ?? this.schedule,
    preservedAttributes: preservedAttributes ?? this.preservedAttributes,
    preservedFields: preservedFields ?? this.preservedFields,
  );

  /// Seeds a configuration from a `cloudsync.query` row.
  static CloudSyncConfiguration fromJson(Map<String, dynamic> json) {
    final rawAttributes = json['attributes'];
    final attributes = rawAttributes is Map
        ? Map<String, Object?>.from(rawAttributes)
        : <String, Object?>{};
    final rawCredentials = json['credentials'];
    int? credentialId;
    if (rawCredentials is num) {
      credentialId = rawCredentials.toInt();
    } else if (rawCredentials is Map && rawCredentials['id'] is num) {
      credentialId = (rawCredentials['id'] as num).toInt();
    }
    final schedule = json['schedule'];
    // Keep provider-specific attribute keys the editor does not surface.
    final preservedAttributes = Map<String, Object?>.from(attributes)
      ..remove('bucket')
      ..remove('folder')
      ..remove('storage_class');
    // Keep top-level fields the editor does not surface, notably the scripts.
    const surfaced = {
      'id',
      'description',
      'direction',
      'transfer_mode',
      'path',
      'credentials',
      'attributes',
      'schedule',
      'transfers',
      'encryption',
      'filename_encryption',
      'encryption_password',
      'encryption_salt',
      'enabled',
      // Runtime-only fields that must never be sent back on update.
      'job',
      'locked',
      'locked_by',
    };
    final preservedFields = <String, Object?>{};
    for (final entry in json.entries) {
      if (!surfaced.contains(entry.key)) {
        preservedFields[entry.key] = entry.value;
      }
    }
    return CloudSyncConfiguration(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      direction: CloudSyncDirectionApi.fromApi(json['direction'] as String?),
      transferMode: CloudSyncTransferModeApi.fromApi(
        json['transfer_mode'] as String?,
      ),
      path: json['path'] is String ? json['path'] as String : '',
      credentialId: credentialId,
      bucket: attributes['bucket'] is String
          ? attributes['bucket']! as String
          : '',
      folder: attributes['folder'] is String
          ? attributes['folder']! as String
          : '',
      storageClass: attributes['storage_class'] is String
          ? attributes['storage_class']! as String
          : '',
      transfers: json['transfers'] is num
          ? (json['transfers'] as num).toInt()
          : null,
      encryption: json['encryption'] == true,
      filenameEncryption: json['filename_encryption'] == true,
      enabled: json['enabled'] != false,
      schedule: schedule is Map<String, dynamic>
          ? TaskSchedule.fromJson(schedule)
          : const TaskSchedule(hour: '00'),
      preservedAttributes: preservedAttributes,
      preservedFields: preservedFields,
    );
  }
}

/// A stable code for a cloud sync validation failure, so presentation layers
/// can translate the message instead of surfacing the English fallback.
enum CloudSyncValidationCode {
  descriptionRequired,
  pathRequired,
  pathNotAbsolute,
  credentialRequired,
  bucketRequired,
  transfersRange,
  encryptionPasswordRequired,
  cronInvalid,
}

extension CloudSyncValidationMessage on CloudSyncValidationCode {
  String get message => switch (this) {
    CloudSyncValidationCode.descriptionRequired => 'Enter a task name.',
    CloudSyncValidationCode.pathRequired => 'Enter a local path.',
    CloudSyncValidationCode.pathNotAbsolute =>
      'Use an absolute path starting with /.',
    CloudSyncValidationCode.credentialRequired =>
      'Choose a saved cloud credential.',
    CloudSyncValidationCode.bucketRequired =>
      'Enter the bucket for this provider.',
    CloudSyncValidationCode.transfersRange =>
      'Use between 1 and 64 concurrent transfers.',
    CloudSyncValidationCode.encryptionPasswordRequired =>
      'Enter an encryption password, or turn encryption off.',
    CloudSyncValidationCode.cronInvalid => cronFieldMessage,
  };
}

/// Validates a [CloudSyncConfiguration]. Returns field-keyed errors.
///
/// [credential] supplies the provider type, which decides whether a bucket is
/// required.
Map<String, String> validateCloudSyncConfiguration(
  CloudSyncConfiguration config, {
  CloudCredential? credential,
}) => {
  for (final entry in cloudSyncConfigurationIssues(
    config,
    credential: credential,
  ).entries)
    entry.key: entry.value.message,
};

/// Typed validation failures keyed by form field.
Map<String, CloudSyncValidationCode> cloudSyncConfigurationIssues(
  CloudSyncConfiguration config, {
  CloudCredential? credential,
}) {
  final issues = <String, CloudSyncValidationCode>{};
  if (config.description.trim().isEmpty) {
    issues['description'] = CloudSyncValidationCode.descriptionRequired;
  }
  final path = config.path.trim();
  if (path.isEmpty) {
    issues['path'] = CloudSyncValidationCode.pathRequired;
  } else if (!path.startsWith('/')) {
    issues['path'] = CloudSyncValidationCode.pathNotAbsolute;
  }
  if (config.credentialId == null) {
    issues['credentials'] = CloudSyncValidationCode.credentialRequired;
  }
  if (config.usesBucketFor(credential) && config.bucket.trim().isEmpty) {
    issues['bucket'] = CloudSyncValidationCode.bucketRequired;
  }
  final transfers = config.transfers;
  if (transfers != null && (transfers < 1 || transfers > 64)) {
    issues['transfers'] = CloudSyncValidationCode.transfersRange;
  }
  if (config.encryption) {
    // A new task must set a password; an edit may leave it blank to keep the
    // existing server-side secret.
    if (config.isCreate && config.encryptionPassword.isEmpty) {
      issues['encryptionPassword'] =
          CloudSyncValidationCode.encryptionPasswordRequired;
    }
  }
  for (final field in config.schedule.invalidCronFields()) {
    issues[field] = CloudSyncValidationCode.cronInvalid;
  }
  return issues;
}
