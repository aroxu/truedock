import '../../../core/domain/data_message.dart';

typedef JsonObject = Map<String, dynamic>;

/// Limits the shared resource snapshot to the destination currently visible.
///
/// The complete snapshot fans out across more than twenty middleware methods.
/// Re-reading all of it every second would waste allocations and API slots for
/// data the user cannot see, so live refreshes select the relevant subset.
enum ServerResourceScope {
  all,
  none,
  overview,
  storage,
  protection,
  apps,
  system,
}

class ResourceSection<T> {
  const ResourceSection({this.items = const [], this.error});

  final List<T> items;

  /// The failure to show, as a code the presentation layer localizes.
  final DataMessage? error;

  /// English text for logs and tests. The UI renders [error] through
  /// `DataMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  bool get hasError => error != null;
}

class ServerResources {
  const ServerResources({
    this.pools = const ResourceSection(),
    this.datasets = const ResourceSection(),
    this.apps = const ResourceSection(),
    this.services = const ResourceSection(),
    this.alerts = const ResourceSection(),
    this.jobs = const ResourceSection(),
    this.replications = const ResourceSection(),
    this.snapshotTasks = const ResourceSection(),
    this.disks = const ResourceSection(),
    this.smbShares = const ResourceSection(),
    this.nfsShares = const ResourceSection(),
    this.virtualMachines = const ResourceSection(),
    this.snapshots = const ResourceSection(),
    this.scrubTasks = const ResourceSection(),
    this.cloudSyncTasks = const ResourceSection(),
    this.rsyncTasks = const ResourceSection(),
    this.containers = const ResourceSection(),
    this.virtInstances = const ResourceSection(),
    this.iscsiTargets = const ResourceSection(),
    this.iscsiExtents = const ResourceSection(),
    this.iscsiPortals = const ResourceSection(),
    this.iscsiInitiators = const ResourceSection(),
    this.iscsiTargetExtents = const ResourceSection(),
    this.webShares = const ResourceSection(),
    this.iscsiAuths = const ResourceSection(),
    this.diskTemperatures = const DiskTemperatureReport(),
  });

  final ResourceSection<StoragePool> pools;
  final ResourceSection<Dataset> datasets;
  final ResourceSection<InstalledApp> apps;
  final ResourceSection<SystemService> services;
  final ResourceSection<SystemAlert> alerts;
  final ResourceSection<SystemJob> jobs;
  final ResourceSection<ReplicationTask> replications;
  final ResourceSection<SnapshotTask> snapshotTasks;
  final ResourceSection<StorageDisk> disks;
  final ResourceSection<SmbShare> smbShares;
  final ResourceSection<NfsShare> nfsShares;
  final ResourceSection<VirtualMachine> virtualMachines;
  final ResourceSection<SnapshotEntry> snapshots;
  final ResourceSection<ScrubTask> scrubTasks;
  final ResourceSection<CloudSyncTask> cloudSyncTasks;
  final ResourceSection<RsyncTask> rsyncTasks;
  final ResourceSection<ManagedContainer> containers;

  /// Containers and VMs from 25.10's `virt.instance.query`. `containers` holds
  /// the older standalone-container surface, which 25.10 does not advertise.
  final ResourceSection<VirtInstance> virtInstances;
  final ResourceSection<IscsiTarget> iscsiTargets;
  final ResourceSection<IscsiExtent> iscsiExtents;
  final ResourceSection<IscsiPortal> iscsiPortals;
  final ResourceSection<IscsiInitiator> iscsiInitiators;
  final ResourceSection<IscsiTargetExtent> iscsiTargetExtents;
  final ResourceSection<WebShare> webShares;
  final ResourceSection<IscsiAuth> iscsiAuths;

  /// Disk temperatures, keyed by device name. Separate from [disks] because
  /// `disk.temperatures` returns a mapping rather than a list and is polled at
  /// most every five minutes by the server.
  final DiskTemperatureReport diskTemperatures;
}

/// The result of a `disk.temperatures` read.
///
/// A failure here must not degrade the disk inventory, so the error is carried
/// alongside the readings instead of failing the whole storage load.
class DiskTemperatureReport {
  const DiskTemperatureReport({this.readings = const {}, this.error});

  final Map<String, DiskTemperature> readings;

  /// The failure to show, as a code the presentation layer localizes.
  final DataMessage? error;

  /// English text for logs and tests. The UI renders [error] through
  /// `DataMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  bool get hasError => error != null;

  DiskTemperature? forDisk(String deviceName) => readings[deviceName];
}

/// One disk's temperature in degrees Celsius, with the drive's own thresholds.
///
/// TrueNAS reports `null` when a drive cannot be read, which is distinct from
/// zero; callers must treat a missing value as unknown rather than cold.
class DiskTemperature {
  const DiskTemperature({this.celsius, this.critical, this.maximum});

  /// Parses one entry of a `disk.temperatures` mapping.
  ///
  /// The value is a bare temperature in the documented shape, but a per-drive
  /// object carrying thresholds appears in some responses. Both are accepted
  /// because guessing one shape would silently drop every reading on the other,
  /// and an unreadable drive legitimately reports null.
  factory DiskTemperature.fromValue(Object? value) {
    if (value is Map<Object?, Object?>) {
      return DiskTemperature(
        celsius: _strictInteger(value['temperature'] ?? value['temp']),
        critical: _strictInteger(value['critical']),
        maximum: _strictInteger(value['maximum'] ?? value['max']),
      );
    }
    return DiskTemperature(celsius: _strictInteger(value));
  }

  final int? celsius;
  final int? critical;
  final int? maximum;

  bool get isKnown => celsius != null;

  /// True once the drive is at or past its own rated maximum. Thresholds are
  /// per-drive, so a fixed number would be wrong for both SSDs and NVMe.
  bool get isOverMaximum =>
      celsius != null && maximum != null && celsius! >= maximum!;

  bool get isCritical =>
      celsius != null && critical != null && celsius! >= critical!;
}

class StoragePool {
  const StoragePool({
    required this.id,
    required this.name,
    required this.status,
    this.sizeBytes,
    this.allocatedBytes,
    this.freeBytes,
    this.fragmentation,
    this.scan,
    this.members = const [],
  });

  factory StoragePool.fromJson(JsonObject json) => StoragePool(
    id: _integer(json['id']),
    name: _string(json['name'], fallback: 'Pool'),
    status: _string(json['status'], fallback: 'UNKNOWN'),
    sizeBytes: _nullableInteger(json['size']),
    allocatedBytes: _nullableInteger(json['allocated']),
    freeBytes: _nullableInteger(json['free']),
    fragmentation: _nullableString(json['fragmentation']),
    scan: json['scan'] is JsonObject
        ? PoolScan.fromJson(json['scan']! as JsonObject)
        : null,
    members: _poolMembers(json['topology']),
  );

  final int id;
  final String name;
  final String status;
  final int? sizeBytes;
  final int? allocatedBytes;
  final int? freeBytes;
  final String? fragmentation;

  /// Current or most recent scrub/resilver, when the server reports one.
  final PoolScan? scan;

  /// Flattened leaf devices across every vdev category.
  final List<PoolMember> members;

  double? get usedFraction {
    final size = sizeBytes;
    final allocated = allocatedBytes;
    if (size == null || allocated == null || size <= 0) return null;
    return (allocated / size).clamp(0, 1);
  }

  bool get isHealthy => status == 'ONLINE';
  bool get isDegraded => status == 'DEGRADED';
}

/// A leaf device inside a pool's topology.
class PoolMember {
  const PoolMember({
    required this.label,
    required this.name,
    required this.status,
    required this.category,
    this.vdevGuid,
  });

  /// The vdev GUID, which is what `pool.offline` and `pool.online` expect.
  final String label;
  final String name;
  final String status;

  /// data, cache, log, spare, dedup, or special.
  final String category;

  /// GUID of the enclosing vdev when the topology exposes one. `pool.attach`
  /// uses this as `target_vdev`; only mirror and stripe vdevs are attachable.
  final String? vdevGuid;

  bool get isOnline => status == 'ONLINE';
  bool get isOffline => status == 'OFFLINE';
}

class PoolScan {
  const PoolScan({
    required this.function,
    required this.state,
    this.percentage,
    this.errors,
  });

  factory PoolScan.fromJson(JsonObject json) => PoolScan(
    function: _string(json['function'], fallback: 'SCRUB'),
    state: _string(json['state'], fallback: 'FINISHED'),
    percentage: (json['percentage'] as num?)?.toDouble(),
    errors: _nullableInteger(json['errors']),
  );

  final String function;
  final String state;
  final double? percentage;
  final int? errors;

  bool get isScrub => function.toUpperCase().contains('SCRUB');
  bool get isRunning => state == 'SCANNING';
  bool get isPaused => state == 'PAUSED';
}

/// Walks the nested `topology` structure and returns every leaf device.
///
/// Mirrors and RAIDZ vdevs nest their disks one level down, so a flat scan of
/// the top level alone would miss the actual members.
List<PoolMember> _poolMembers(Object? topology) {
  if (topology is! JsonObject) return const [];
  final members = <PoolMember>[];

  void visit(Object? node, String category, {String? vdevGuid}) {
    if (node is List<Object?>) {
      for (final child in node) {
        visit(child, category, vdevGuid: vdevGuid);
      }
      return;
    }
    if (node is! JsonObject) return;
    final children = node['children'];
    final hasChildren = children is List<Object?> && children.isNotEmpty;
    final currentVdevGuid = vdevGuid ?? _nullableString(node['guid']);
    if (hasChildren) {
      visit(children, category, vdevGuid: currentVdevGuid);
      return;
    }
    final guid = _nullableString(node['guid']);
    if (guid == null) return;
    members.add(
      PoolMember(
        label: guid,
        vdevGuid: currentVdevGuid,
        name: _string(
          node['disk'] ?? node['device'] ?? node['name'],
          fallback: 'Member',
        ),
        status: _string(node['status'], fallback: 'UNKNOWN'),
        category: category,
      ),
    );
  }

  for (final entry in topology.entries) {
    visit(entry.value, entry.key);
  }
  return List.unmodifiable(members);
}

class Dataset {
  const Dataset({
    required this.id,
    required this.name,
    required this.type,
    this.usedBytes,
    this.availableBytes,
    this.encrypted = false,
    this.locked = false,
    this.comments,
    this.quotaBytes,
    this.refquotaBytes,
    this.readOnly = false,
    this.compression,
    this.sync,
    this.atime,
    this.inheritedProperties = const {},
    this.keyFormat,
    this.encryptionRoot,
    this.keyLoaded = false,
    this.origin,
  });

  factory Dataset.fromJson(JsonObject json) => Dataset(
    id: _string(json['id'] ?? json['name'], fallback: 'dataset'),
    name: _string(json['name'] ?? json['id'], fallback: 'Dataset'),
    type: _string(json['type'], fallback: 'FILESYSTEM'),
    usedBytes: _propertyInteger(json['used']),
    availableBytes: _propertyInteger(json['available']),
    encrypted: json['encrypted'] == true,
    locked: json['locked'] == true,
    comments: _propertyString(json['comments']),
    quotaBytes: _propertyInteger(json['quota']),
    refquotaBytes: _propertyInteger(json['refquota']),
    readOnly: _propertyString(json['readonly'])?.toUpperCase() == 'ON',
    compression: _propertyString(json['compression'])?.toUpperCase(),
    sync: _propertyString(json['sync'])?.toUpperCase(),
    atime: _propertyString(json['atime'])?.toUpperCase(),
    keyFormat: _propertyString(json['key_format'])?.toUpperCase(),
    encryptionRoot: _nullableString(json['encryption_root']),
    keyLoaded: json['key_loaded'] == true,
    origin: _propertyString(json['origin']),
    inheritedProperties: {
      for (final property in const [
        'comments',
        'quota',
        'refquota',
        'readonly',
        'compression',
        'sync',
        'atime',
      ])
        if (_propertySource(json[property]) == 'INHERITED') property,
    },
  );

  final String id;
  final String name;
  final String type;
  final int? usedBytes;
  final int? availableBytes;
  final bool encrypted;
  final bool locked;
  final String? comments;

  /// ZFS reports "no quota" as 0, which TrueDock models as `null`.
  final int? quotaBytes;
  final int? refquotaBytes;
  final bool readOnly;
  final String? compression;
  final String? sync;
  final String? atime;

  /// PASSPHRASE or HEX, when the dataset is encrypted.
  final String? keyFormat;

  /// The dataset that owns the encryption key. A child inherits its parent's
  /// key unless it is its own encryption root.
  final String? encryptionRoot;
  final bool keyLoaded;

  /// The snapshot this dataset was cloned from, when it is a clone.
  ///
  /// ZFS reports an empty string for an ordinary dataset, so only a non-empty
  /// value means "clone".
  final String? origin;

  /// True when this dataset still depends on the snapshot it was cloned from.
  ///
  /// That dependency is what blocks deleting the origin snapshot, and promoting
  /// the clone is what breaks it.
  bool get isClone => origin != null && origin!.isNotEmpty;

  /// Properties the server reports as inherited from the parent dataset.
  final Set<String> inheritedProperties;

  String get leafName => name.split('/').last;
  int get depth => name.split('/').length - 1;

  /// Pool root datasets cannot be renamed or destroyed like child datasets.
  bool get isPoolRoot => depth == 0;

  bool get isVolume => type == 'VOLUME';

  /// Only an encryption root can be locked or unlocked directly.
  bool get isEncryptionRoot => encrypted && encryptionRoot == name;

  bool get usesPassphrase => keyFormat == 'PASSPHRASE';

  bool get canLock => isEncryptionRoot && !locked;

  bool get canUnlock => isEncryptionRoot && locked;

  bool inherits(String property) => inheritedProperties.contains(property);
}

class InstalledApp {
  const InstalledApp({
    required this.id,
    required this.name,
    required this.state,
    required this.version,
    required this.catalogUpgradeAvailable,
    required this.imageUpdatesAvailable,
    this.latestVersion,
    this.technicalVersion,
    this.customApp = false,
    this.catalogApp,
    this.train,
    this.workloads = const AppWorkloads(),
  });

  factory InstalledApp.fromJson(JsonObject json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    return InstalledApp(
      id: _string(json['id'], fallback: 'app'),
      name: _string(json['name'], fallback: 'App'),
      state: _string(json['state'], fallback: 'UNKNOWN'),
      version: _string(
        json['human_version'] ?? json['version'],
        fallback: 'Unknown version',
      ),
      catalogUpgradeAvailable: json['upgrade_available'] == true,
      imageUpdatesAvailable: json['image_updates_available'] == true,
      latestVersion: _nullableString(json['latest_version']),
      technicalVersion: _nullableString(json['version']),
      customApp: json['custom_app'] == true,
      catalogApp: _nullableString(
        metadata['name'] ?? metadata['app_name'] ?? json['catalog_app'],
      ),
      train: _nullableString(metadata['train'] ?? json['train']),
      workloads: AppWorkloads.fromJson(json['active_workloads']),
    );
  }

  final String id;
  final String name;
  final String state;
  final String version;
  final bool catalogUpgradeAvailable;
  final bool imageUpdatesAvailable;
  final String? latestVersion;
  final String? technicalVersion;
  final bool customApp;
  final String? catalogApp;
  final String? train;
  final AppWorkloads workloads;

  bool get upgradeAvailable => catalogUpgradeAvailable || imageUpdatesAvailable;
}

class AppWorkloads {
  const AppWorkloads({
    this.containerCount = 0,
    this.containers = const [],
    this.volumes = const [],
    this.images = const [],
    this.networks = const [],
    this.ports = const [],
  });

  factory AppWorkloads.fromJson(Object? value) {
    if (value is! Map) return const AppWorkloads();
    final json = Map<String, dynamic>.from(value);
    return AppWorkloads(
      containerCount: _integer(json['containers']),
      containers: _objectList(
        json['container_details'],
      ).map(AppContainerWorkload.fromJson).toList(growable: false),
      volumes: _objectList(
        json['volumes'],
      ).map(AppVolumeMount.fromJson).toList(growable: false),
      images: _stringList(json['images']),
      networks: _objectList(json['networks'])
          .map(
            (item) =>
                _string(item['Name'] ?? item['name'], fallback: 'Network'),
          )
          .toList(growable: false),
      ports: _parseAppPorts(json['used_ports']),
    );
  }

  final int containerCount;
  final List<AppContainerWorkload> containers;
  final List<AppVolumeMount> volumes;
  final List<String> images;
  final List<String> networks;
  final List<AppPortMapping> ports;
}

class AppContainerWorkload {
  const AppContainerWorkload({
    required this.id,
    required this.serviceName,
    required this.image,
    required this.state,
  });

  factory AppContainerWorkload.fromJson(JsonObject json) =>
      AppContainerWorkload(
        id: _string(json['id'], fallback: ''),
        serviceName: _string(json['service_name'], fallback: 'Container'),
        image: _string(json['image'], fallback: 'Unknown image'),
        state: _string(json['state'], fallback: 'unknown'),
      );

  final String id;
  final String serviceName;
  final String image;
  final String state;
}

class AppVolumeMount {
  const AppVolumeMount({
    required this.source,
    required this.destination,
    required this.mode,
    required this.type,
  });

  factory AppVolumeMount.fromJson(JsonObject json) => AppVolumeMount(
    source: _string(json['source'], fallback: 'Unknown source'),
    destination: _string(json['destination'], fallback: 'Unknown destination'),
    mode: _string(json['mode'], fallback: ''),
    type: _string(json['type'], fallback: ''),
  );

  final String source;
  final String destination;
  final String mode;
  final String type;
}

class AppPortMapping {
  const AppPortMapping({
    required this.containerPort,
    required this.hostPort,
    required this.hostIp,
    required this.protocol,
  });

  final int containerPort;
  final int hostPort;
  final String hostIp;
  final String protocol;
}

List<AppPortMapping> _parseAppPorts(Object? value) {
  final result = <AppPortMapping>[];
  for (final port in _objectList(value)) {
    for (final host in _objectList(port['host_ports'])) {
      result.add(
        AppPortMapping(
          containerPort: _integer(port['container_port']),
          hostPort: _integer(host['host_port']),
          hostIp: _string(host['host_ip'], fallback: '*'),
          protocol: _string(port['protocol'], fallback: 'tcp'),
        ),
      );
    }
  }
  return result;
}

class SystemService {
  const SystemService({
    required this.id,
    required this.name,
    required this.state,
    required this.enabled,
  });

  factory SystemService.fromJson(JsonObject json) => SystemService(
    id: _integer(json['id']),
    name: _string(json['service'], fallback: 'Service'),
    state: _string(json['state'], fallback: 'UNKNOWN'),
    enabled: json['enable'] == true,
  );

  final int id;
  final String name;
  final String state;
  final bool enabled;
}

class SystemAlert {
  const SystemAlert({
    required this.id,
    required this.uuid,
    required this.level,
    required this.text,
    required this.dismissed,
    this.formattedText,
    this.arguments = const {},
    this.occurredAt,
    this.lastOccurredAt,
  });

  factory SystemAlert.fromJson(JsonObject json) {
    final arguments = _alertArguments(json['args']);
    final text = _string(json['text'], fallback: 'TrueNAS alert');
    final formattedText = _nullableString(json['formatted']);
    return SystemAlert(
      id: _string(json['id'] ?? json['uuid'], fallback: 'alert'),
      uuid: _string(json['uuid'] ?? json['id'], fallback: 'alert'),
      level: _string(json['level'], fallback: 'INFO'),
      text: _formatAlertTemplate(text, arguments),
      dismissed: json['dismissed'] == true,
      formattedText: formattedText == null
          ? null
          : _formatAlertTemplate(formattedText, arguments),
      arguments: arguments,
      occurredAt: _epochTimestamp(json['datetime']),
      lastOccurredAt: _epochTimestamp(json['last_occurrence']),
    );
  }

  final String id;
  final String uuid;
  final String level;
  final String text;
  final bool dismissed;
  final String? formattedText;
  final Map<String, Object?> arguments;
  final DateTime? occurredAt;
  final DateTime? lastOccurredAt;

  bool get isCritical => level == 'CRITICAL' || level == 'ERROR';
  bool get isWarning => level == 'WARNING' || level == 'WARN';
}

class SystemJob {
  const SystemJob({
    required this.id,
    required this.method,
    required this.state,
    this.percent,
    this.description,
    this.error,
    this.abortable = false,
    this.startedAt,
    this.finishedAt,
    this.arguments = const [],
    this.logsExcerpt,
  });

  factory SystemJob.fromJson(JsonObject json) {
    final progress = json['progress'];
    final progressObject = progress is JsonObject ? progress : null;
    return SystemJob(
      id: _integer(json['id']),
      method: _string(json['method'], fallback: 'TrueNAS job'),
      state: _string(json['state'], fallback: 'UNKNOWN'),
      percent: (progressObject?['percent'] as num?)?.toDouble(),
      description: _nullableString(progressObject?['description']),
      error: _nullableString(json['error']),
      abortable: json['abortable'] == true,
      startedAt: _epochTimestamp(json['time_started']),
      finishedAt: _epochTimestamp(json['time_finished']),
      arguments: json['arguments'] is List<Object?>
          ? List<Object?>.unmodifiable(json['arguments'] as List<Object?>)
          : const [],
      logsExcerpt: _nullableString(json['logs_excerpt']),
    );
  }

  final int id;
  final String method;
  final String state;
  final double? percent;
  final String? description;
  final String? error;
  final bool abortable;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<Object?> arguments;
  final String? logsExcerpt;

  bool get isActive => state == 'WAITING' || state == 'RUNNING';

  bool get isRunning => state == 'RUNNING';

  bool get hasFailed => state == 'FAILED' || state == 'ABORTED';

  bool get isSuccessful => state == 'SUCCESS';

  /// A job may only be aborted while the server still reports it as
  /// in-flight and explicitly marks it abortable.
  bool get canAbort => abortable && isActive;

  Duration? get duration {
    final started = startedAt;
    if (started == null) return null;
    return (finishedAt ?? DateTime.now().toUtc()).difference(started);
  }
}

class ReplicationTask {
  const ReplicationTask({
    required this.id,
    required this.name,
    required this.direction,
    required this.enabled,
    this.state,
  });

  factory ReplicationTask.fromJson(JsonObject json) {
    final state = json['state'];
    return ReplicationTask(
      id: _integer(json['id']),
      name: _string(json['name'], fallback: 'Replication'),
      direction: _string(json['direction'], fallback: 'PUSH'),
      enabled: json['enabled'] != false,
      state: state is JsonObject
          ? _nullableString(state['state'])
          : _nullableString(state),
    );
  }

  final int id;
  final String name;
  final String direction;
  final bool enabled;
  final String? state;

  bool get isRunning => state == 'RUNNING' || state == 'WAITING';
}

class SnapshotTask {
  const SnapshotTask({
    required this.id,
    required this.dataset,
    required this.enabled,
    required this.recursive,
    required this.lifetimeValue,
    required this.lifetimeUnit,
    required this.lifetimeLabel,
    required this.minute,
    required this.hour,
    required this.dayOfMonth,
    required this.month,
    required this.dayOfWeek,
    required this.begin,
    required this.end,
    required this.namingSchema,
    required this.allowEmpty,
    required this.excludes,
  });

  factory SnapshotTask.fromJson(JsonObject json) {
    final schedule = json['schedule'];
    final scheduleJson = schedule is JsonObject
        ? schedule
        : <String, dynamic>{};
    return SnapshotTask(
      id: _integer(json['id']),
      dataset: _string(json['dataset'], fallback: 'Dataset'),
      enabled: json['enabled'] != false,
      recursive: json['recursive'] == true,
      lifetimeValue: _integer(json['lifetime_value'], fallback: 2),
      lifetimeUnit: _string(json['lifetime_unit'], fallback: 'WEEK'),
      lifetimeLabel:
          '${_integer(json['lifetime_value'], fallback: 2)} '
          '${_string(json['lifetime_unit'], fallback: 'WEEK').toLowerCase()}',
      minute: _string(scheduleJson['minute'], fallback: '00'),
      hour: _string(scheduleJson['hour'], fallback: '*'),
      dayOfMonth: _string(scheduleJson['dom'], fallback: '*'),
      month: _string(scheduleJson['month'], fallback: '*'),
      dayOfWeek: _string(scheduleJson['dow'], fallback: '*'),
      begin: _string(scheduleJson['begin'], fallback: '00:00'),
      end: _string(scheduleJson['end'], fallback: '23:59'),
      namingSchema: _string(
        json['naming_schema'],
        fallback: 'auto-%Y-%m-%d_%H-%M',
      ),
      allowEmpty: json['allow_empty'] != false,
      excludes: _stringList(json['exclude']),
    );
  }

  final int id;
  final String dataset;
  final bool enabled;
  final bool recursive;
  final int lifetimeValue;
  final String lifetimeUnit;
  final String lifetimeLabel;
  final String minute;
  final String hour;
  final String dayOfMonth;
  final String month;
  final String dayOfWeek;
  final String begin;
  final String end;
  final String namingSchema;
  final bool allowEmpty;
  final List<String> excludes;

  String get schedule => '$minute $hour $dayOfMonth $month $dayOfWeek';
}

class StorageDisk {
  const StorageDisk({
    required this.id,
    required this.name,
    required this.model,
    required this.serial,
    required this.type,
    this.sizeBytes,
    this.pool,
    this.rotationRate,
  });

  factory StorageDisk.fromJson(JsonObject json) => StorageDisk(
    id: _string(
      json['identifier'] ?? json['name'] ?? json['devname'],
      fallback: 'disk',
    ),
    name: _string(json['name'] ?? json['devname'], fallback: 'Disk'),
    model: _string(json['model'], fallback: 'Unknown model'),
    serial: _string(json['serial'], fallback: 'No serial'),
    type: _string(json['type'], fallback: 'HDD'),
    sizeBytes: _nullableInteger(json['size']),
    pool: _nullableString(json['pool']),
    rotationRate: _nullableInteger(json['rotationrate']),
  );

  final String id;
  final String name;
  final String model;
  final String serial;
  final String type;
  final int? sizeBytes;
  final String? pool;
  final int? rotationRate;

  bool get isSolidState =>
      type.toUpperCase().contains('SSD') || rotationRate == 0;
}

/// Returns disks in human device-name order without mutating server state.
/// Numeric components are compared as numbers, so `nvme2` precedes `nvme10`.
List<StorageDisk> sortStorageDisksNaturally(Iterable<StorageDisk> disks) {
  final sorted = disks.toList();
  sorted.sort((left, right) => naturalDeviceNameCompare(left.name, right.name));
  return sorted;
}

int naturalDeviceNameCompare(String left, String right) {
  final leftParts = RegExp(r'\d+|\D+').allMatches(left.toLowerCase()).toList();
  final rightParts = RegExp(
    r'\d+|\D+',
  ).allMatches(right.toLowerCase()).toList();
  final sharedLength = leftParts.length < rightParts.length
      ? leftParts.length
      : rightParts.length;
  for (var index = 0; index < sharedLength; index++) {
    final leftPart = leftParts[index].group(0)!;
    final rightPart = rightParts[index].group(0)!;
    final leftNumber = int.tryParse(leftPart);
    final rightNumber = int.tryParse(rightPart);
    final comparison = leftNumber != null && rightNumber != null
        ? leftNumber.compareTo(rightNumber)
        : leftPart.compareTo(rightPart);
    if (comparison != 0) return comparison;
  }
  return leftParts.length.compareTo(rightParts.length);
}

class SmbShare {
  const SmbShare({
    required this.id,
    required this.name,
    required this.path,
    required this.enabled,
    required this.readOnly,
    required this.purpose,
    required this.locked,
    required this.browsable,
    required this.accessBasedEnumeration,
    required this.auditEnabled,
    required this.auditWatchList,
    required this.auditIgnoreList,
    required this.aaplNameMangling,
    required this.hostsAllow,
    required this.hostsDeny,
    required this.timeMachineQuota,
    required this.autoSnapshot,
    required this.autoDatasetCreation,
    required this.gracePeriod,
    required this.autoQuota,
    required this.remotePaths,
    this.comment,
    this.datasetNamingSchema,
    this.volumeUuid,
  });

  factory SmbShare.fromJson(JsonObject json) {
    final audit = json['audit'] is JsonObject
        ? json['audit'] as JsonObject
        : <String, dynamic>{};
    final options = json['options'] is JsonObject
        ? json['options'] as JsonObject
        : <String, dynamic>{};
    return SmbShare(
      id: _integer(json['id']),
      name: _string(json['name'], fallback: 'SMB share'),
      path: _string(json['path'], fallback: 'Unknown path'),
      enabled: json['enabled'] != false,
      readOnly: json['readonly'] == true,
      purpose: _string(json['purpose'], fallback: 'DEFAULT_SHARE'),
      locked: json['locked'] == true,
      comment: _nullableString(json['comment']),
      browsable: json['browsable'] != false,
      accessBasedEnumeration: json['access_based_share_enumeration'] == true,
      auditEnabled: audit['enable'] == true,
      auditWatchList: _stringList(audit['watch_list']),
      auditIgnoreList: _stringList(audit['ignore_list']),
      aaplNameMangling: options['aapl_name_mangling'] == true,
      hostsAllow: _stringList(options['hostsallow']),
      hostsDeny: _stringList(options['hostsdeny']),
      timeMachineQuota: _integer(options['timemachine_quota']),
      autoSnapshot: options['auto_snapshot'] == true,
      autoDatasetCreation: options['auto_dataset_creation'] == true,
      datasetNamingSchema: _nullableString(options['dataset_naming_schema']),
      volumeUuid: _nullableString(options['vuid']),
      gracePeriod: _integer(options['grace_period'], fallback: 900),
      autoQuota: _integer(options['auto_quota']),
      remotePaths: _stringList(options['remote_path']),
    );
  }

  final int id;
  final String name;
  final String path;
  final bool enabled;
  final bool readOnly;
  final String purpose;
  final bool locked;
  final String? comment;
  final bool browsable;
  final bool accessBasedEnumeration;
  final bool auditEnabled;
  final List<String> auditWatchList;
  final List<String> auditIgnoreList;
  final bool aaplNameMangling;
  final List<String> hostsAllow;
  final List<String> hostsDeny;
  final int timeMachineQuota;
  final bool autoSnapshot;
  final bool autoDatasetCreation;
  final String? datasetNamingSchema;
  final String? volumeUuid;
  final int gracePeriod;
  final int autoQuota;
  final List<String> remotePaths;
}

class NfsShare {
  const NfsShare({
    required this.id,
    required this.path,
    required this.enabled,
    required this.readOnly,
    required this.locked,
    required this.mapRootUser,
    required this.mapRootGroup,
    required this.mapAllUser,
    required this.mapAllGroup,
    required this.security,
    required this.exposeSnapshots,
    this.comment,
    this.networks = const [],
    this.hosts = const [],
  });

  factory NfsShare.fromJson(JsonObject json) => NfsShare(
    id: _integer(json['id']),
    path: _string(json['path'], fallback: 'Unknown path'),
    enabled: json['enabled'] != false,
    readOnly: json['ro'] == true,
    locked: json['locked'] == true,
    mapRootUser: _nullableString(json['maproot_user']),
    mapRootGroup: _nullableString(json['maproot_group']),
    mapAllUser: _nullableString(json['mapall_user']),
    mapAllGroup: _nullableString(json['mapall_group']),
    security: _stringList(json['security']),
    exposeSnapshots: json['expose_snapshots'] == true,
    comment: _nullableString(json['comment']),
    networks: _stringList(json['networks']),
    hosts: _stringList(json['hosts']),
  );

  final int id;
  final String path;
  final bool enabled;
  final bool readOnly;
  final bool locked;
  final String? mapRootUser;
  final String? mapRootGroup;
  final String? mapAllUser;
  final String? mapAllGroup;
  final List<String> security;
  final bool exposeSnapshots;
  final String? comment;
  final List<String> networks;
  final List<String> hosts;

  String get accessSummary {
    final entries = [...networks, ...hosts];
    return entries.isEmpty ? 'All networks' : entries.join(', ');
  }
}

class ManagedContainer {
  const ManagedContainer({
    required this.id,
    required this.uuid,
    required this.name,
    required this.state,
    required this.dataset,
    required this.autostart,
    required this.deviceCount,
    this.description,
    this.defaultNetwork,
  });

  factory ManagedContainer.fromJson(JsonObject json) {
    final status = json['status'];
    final statusObject = status is JsonObject ? status : null;
    final devices = json['devices'];
    return ManagedContainer(
      id: _integer(json['id']),
      uuid: _string(json['uuid'], fallback: 'Unknown UUID'),
      name: _string(json['name'], fallback: 'Container'),
      state: _string(statusObject?['state'], fallback: 'UNKNOWN'),
      dataset: _string(json['dataset'], fallback: 'Unknown dataset'),
      autostart: json['autostart'] == true,
      deviceCount: devices is List<Object?> ? devices.length : 0,
      description: _nullableString(json['description']),
      defaultNetwork: _nullableString(json['default_network']),
    );
  }

  final int id;
  final String uuid;
  final String name;
  final String state;
  final String dataset;
  final bool autostart;
  final int deviceCount;
  final String? description;
  final String? defaultNetwork;

  bool get isRunning => state == 'RUNNING';
}

/// An entry from `virt.instance.query`: TrueNAS 25.10's Instances surface,
/// which supersedes the older standalone-container API.
///
/// Modelled from the live 25.10.5 response rather than the docs, because the
/// shape differs in ways that matter: `status` is a bare string (not the nested
/// object `vm.query` uses), `cpu` is a string because it accepts a core count or
/// a pinned CPU set, `memory` is bytes, and `image` is an object describing the
/// source rather than a name.
class VirtInstance {
  const VirtInstance({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.autostart,
    required this.privileged,
    required this.vncEnabled,
    this.cpu,
    this.memoryBytes,
    this.storagePool,
    this.imageDescription,
    this.imageOs,
    this.imageArchitecture,
    this.rootDiskSizeGiB,
    this.vncPort,
    this.aliases = const [],
    this.environment = const {},
  });

  factory VirtInstance.fromJson(JsonObject json) {
    final image = json['image'];
    final imageObject = image is JsonObject ? image : null;
    final environment = json['environment'];
    return VirtInstance(
      // The id is the instance name, not a number: every virt.instance.* call
      // takes that string.
      id: _string(json['id'] ?? json['name'], fallback: 'instance'),
      name: _string(json['name'], fallback: 'Instance'),
      type: _string(json['type'], fallback: 'CONTAINER'),
      status: _string(json['status'], fallback: 'UNKNOWN'),
      autostart: json['autostart'] == true,
      privileged: json['privileged_mode'] == true,
      vncEnabled: json['vnc_enabled'] == true,
      cpu: _nullableString(json['cpu']),
      memoryBytes: _nullableInteger(json['memory']),
      storagePool: _nullableString(json['storage_pool']),
      imageDescription: _nullableString(imageObject?['description']),
      imageOs: _nullableString(imageObject?['os']),
      imageArchitecture: _nullableString(imageObject?['architecture']),
      rootDiskSizeGiB: _nullableInteger(json['root_disk_size']),
      vncPort: _nullableInteger(json['vnc_port']),
      aliases: _stringList(json['aliases']),
      environment: environment is JsonObject
          ? {
              for (final entry in environment.entries)
                entry.key: '${entry.value}',
            }
          : const {},
    );
  }

  /// Instance name, which is also the identifier every mutation takes.
  final String id;
  final String name;

  /// `CONTAINER` or `VM`. 25.10 exposes both through the same surface.
  final String type;
  final String status;
  final bool autostart;
  final bool privileged;
  final bool vncEnabled;

  /// Core count or a pinned CPU set, as the server reports it.
  final String? cpu;
  final int? memoryBytes;
  final String? storagePool;
  final String? imageDescription;
  final String? imageOs;
  final String? imageArchitecture;
  final int? rootDiskSizeGiB;
  final int? vncPort;
  final List<String> aliases;
  final Map<String, String> environment;

  bool get isRunning => status == 'RUNNING';
  bool get isStopped => status == 'STOPPED';
  bool get isVirtualMachine => type == 'VM';
}

/// A device attached to an instance, from `virt.instance.device_list`.
class VirtInstanceDevice {
  const VirtInstanceDevice({
    required this.name,
    required this.deviceType,
    required this.readOnly,
    this.description,
  });

  factory VirtInstanceDevice.fromJson(JsonObject json) => VirtInstanceDevice(
    name: _string(json['name'], fallback: 'device'),
    deviceType: _string(json['dev_type'], fallback: 'UNKNOWN'),
    readOnly: json['readonly'] == true,
    description: _nullableString(json['description']),
  );

  final String name;
  final String deviceType;

  /// Server-managed devices are reported read-only and cannot be removed.
  final bool readOnly;
  final String? description;
}

/// `virt.global.config`: whether the Instances platform is usable at all.
///
/// State is `NO_POOL` until a storage pool is chosen, and no instance can exist
/// before then, so the UI has to explain that rather than showing an empty list.
class VirtGlobalConfig {
  const VirtGlobalConfig({
    required this.state,
    this.pool,
    this.dataset,
    this.bridge,
    this.v4Network,
    this.v6Network,
    this.storagePools = const [],
  });

  factory VirtGlobalConfig.fromJson(JsonObject json) => VirtGlobalConfig(
    state: _string(json['state'], fallback: 'UNKNOWN'),
    pool: _nullableString(json['pool']),
    dataset: _nullableString(json['dataset']),
    bridge: _nullableString(json['bridge']),
    v4Network: _nullableString(json['v4_network']),
    v6Network: _nullableString(json['v6_network']),
    storagePools: _stringList(json['storage_pools']),
  );

  final String state;
  final String? pool;
  final String? dataset;
  final String? bridge;
  final String? v4Network;
  final String? v6Network;
  final List<String> storagePools;

  bool get isInitialized => state == 'INITIALIZED';
  bool get needsPool => state == 'NO_POOL' || pool == null;
}

class IscsiTarget {
  const IscsiTarget({
    required this.id,
    required this.name,
    required this.mode,
    required this.groups,
    this.alias,
    this.authNetworks = const [],
    this.relativeTargetId,
    this.queuedCommands,
  });

  factory IscsiTarget.fromJson(JsonObject json) {
    final parameters = json['iscsi_parameters'];
    final parameterObject = parameters is JsonObject ? parameters : null;
    return IscsiTarget(
      id: _integer(json['id']),
      name: _string(json['name'], fallback: 'iSCSI target'),
      alias: _nullableString(json['alias']),
      mode: _string(json['mode'], fallback: 'ISCSI'),
      groups: _objectList(
        json['groups'],
      ).map(IscsiTargetGroup.fromJson).toList(growable: false),
      authNetworks: _stringList(json['auth_networks']),
      relativeTargetId: _nullableInteger(json['rel_tgt_id']),
      queuedCommands: _nullableInteger(parameterObject?['QueuedCommands']),
    );
  }

  final int id;
  final String name;
  final String? alias;
  final String mode;
  final List<IscsiTargetGroup> groups;
  final List<String> authNetworks;
  final int? relativeTargetId;
  final int? queuedCommands;

  int get groupCount => groups.length;
}

class IscsiTargetGroup {
  const IscsiTargetGroup({
    required this.portalId,
    required this.authMethod,
    this.initiatorId,
    this.authId,
  });

  factory IscsiTargetGroup.fromJson(JsonObject json) => IscsiTargetGroup(
    portalId: _integer(json['portal']),
    initiatorId: _nullableInteger(json['initiator']),
    authMethod: _string(json['authmethod'], fallback: 'NONE'),
    authId: _nullableInteger(json['auth']),
  );

  final int portalId;
  final int? initiatorId;
  final String authMethod;
  final int? authId;
}

/// A CHAP credential entry referenced by iSCSI target groups.
///
/// TrueNAS stores these in `iscsi.auth` and exposes them by integer `id`. The
/// target group's `auth` field points at one of these entries; `authmethod`
/// decides whether it is used as one-way CHAP or mutual CHAP. Secrets are
/// write-only on the server side: queries return them masked or omitted, so
/// the model never holds the plaintext of an existing entry.
class IscsiAuth {
  const IscsiAuth({
    required this.id,
    required this.tag,
    required this.user,
    this.peerUser,
  });

  factory IscsiAuth.fromJson(JsonObject json) {
    final user = _string(json['user'], fallback: '');
    // Some 25.10 builds return an empty user for the implicit NONE entry;
    // treat an empty user as "no credential" so the picker can skip it.
    return IscsiAuth(
      id: _integer(json['id']),
      tag: _integer(json['tag']),
      user: user,
      peerUser:
          _nullableString(json['peeruser']) ??
          _nullableString(json['peer_user']),
    );
  }

  final int id;

  /// Numeric tag identifying the credential within the target group.
  final int tag;

  /// The CHAP username initiators must present. Empty for the implicit NONE.
  final String user;

  /// The peer username the target must present for mutual CHAP, if set.
  final String? peerUser;

  /// Whether this entry is configured for mutual CHAP (peer user present).
  bool get isMutual => peerUser != null && peerUser!.isNotEmpty;

  /// A short label for pickers, e.g. "user: alice (mutual)".
  String get label => isMutual ? '$user · mutual' : user;
}

class IscsiExtent {
  const IscsiExtent({
    required this.id,
    required this.name,
    required this.type,
    required this.backingStore,
    required this.enabled,
    required this.readOnly,
    required this.locked,
    required this.blockSize,
    this.sizeBytes,
    this.disk,
    this.serial,
    this.path,
    this.physicalBlockSize = false,
    this.availableThreshold,
    this.comment = '',
    this.insecureTpc = true,
    this.xen = false,
    this.rpm = 'SSD',
    this.productId,
  });

  factory IscsiExtent.fromJson(JsonObject json) {
    final type = _string(json['type'], fallback: 'DISK');
    return IscsiExtent(
      id: _integer(json['id']),
      name: _string(json['name'], fallback: 'iSCSI extent'),
      type: type,
      backingStore: _string(
        type == 'FILE' ? json['path'] : json['disk'],
        fallback: 'Unassigned',
      ),
      sizeBytes: _nullableInteger(json['filesize']),
      disk: _nullableString(json['disk']),
      enabled: json['enabled'] != false,
      readOnly: json['ro'] == true,
      locked: json['locked'] == true,
      blockSize: _integer(json['blocksize'], fallback: 512),
      serial: _nullableString(json['serial']),
      path: _nullableString(json['path']),
      physicalBlockSize: json['pblocksize'] == true,
      availableThreshold: _nullableInteger(json['avail_threshold']),
      comment: _string(json['comment'], fallback: ''),
      insecureTpc: json['insecure_tpc'] != false,
      xen: json['xen'] == true,
      rpm: _string(json['rpm'], fallback: 'SSD'),
      productId: _nullableString(json['product_id']),
    );
  }

  final int id;
  final String name;
  final String type;
  final String backingStore;
  final int? sizeBytes;
  final String? disk;
  final bool enabled;
  final bool readOnly;
  final bool locked;
  final int blockSize;
  final String? serial;
  final String? path;
  final bool physicalBlockSize;
  final int? availableThreshold;
  final String comment;
  final bool insecureTpc;
  final bool xen;
  final String rpm;
  final String? productId;
}

class IscsiPortalListen {
  const IscsiPortalListen({required this.ip, required this.port});

  factory IscsiPortalListen.fromJson(JsonObject json) => IscsiPortalListen(
    ip: _string(json['ip'], fallback: 'Unknown address'),
    port: _integer(json['port'], fallback: 3260),
  );

  final String ip;
  final int port;
}

class IscsiPortal {
  const IscsiPortal({
    required this.id,
    required this.tag,
    required this.comment,
    required this.listen,
  });

  factory IscsiPortal.fromJson(JsonObject json) => IscsiPortal(
    id: _integer(json['id']),
    tag: _integer(json['tag']),
    comment: _string(json['comment'], fallback: ''),
    listen: _objectList(
      json['listen'],
    ).map(IscsiPortalListen.fromJson).toList(growable: false),
  );

  final int id;
  final int tag;
  final String comment;
  final List<IscsiPortalListen> listen;

  String get addressSummary =>
      listen.map((entry) => '${entry.ip}:${entry.port}').join(', ');
}

class IscsiInitiator {
  const IscsiInitiator({
    required this.id,
    required this.initiators,
    required this.comment,
  });

  factory IscsiInitiator.fromJson(JsonObject json) => IscsiInitiator(
    id: _integer(json['id']),
    initiators: _stringList(json['initiators']),
    comment: _string(json['comment'], fallback: ''),
  );

  final int id;
  final List<String> initiators;
  final String comment;

  bool get allowsAll => initiators.isEmpty;
}

class IscsiTargetExtent {
  const IscsiTargetExtent({
    required this.id,
    required this.targetId,
    required this.extentId,
    this.lunId,
  });

  factory IscsiTargetExtent.fromJson(JsonObject json) => IscsiTargetExtent(
    id: _integer(json['id']),
    targetId: _integer(json['target']),
    extentId: _integer(json['extent']),
    lunId: _nullableInteger(json['lunid']),
  );

  final int id;
  final int targetId;
  final int extentId;
  final int? lunId;
}

class WebShare {
  const WebShare({
    required this.id,
    required this.name,
    required this.path,
    required this.enabled,
    required this.locked,
  });

  factory WebShare.fromJson(JsonObject json) => WebShare(
    id: _integer(json['id']),
    name: _string(json['name'] ?? json['comment'], fallback: 'WebShare'),
    path: _string(json['path'], fallback: 'Unknown path'),
    enabled: json['enabled'] != false,
    locked: json['locked'] == true,
  );

  final int id;
  final String name;
  final String path;
  final bool enabled;
  final bool locked;
}

class VirtualMachine {
  const VirtualMachine({
    required this.id,
    required this.name,
    required this.state,
    required this.vcpus,
    required this.cores,
    required this.threads,
    required this.memoryMiB,
    required this.autostart,
    required this.displayAvailable,
    this.description,
  });

  factory VirtualMachine.fromJson(JsonObject json) {
    final status = json['status'];
    final statusObject = status is JsonObject ? status : null;
    return VirtualMachine(
      id: _integer(json['id']),
      name: _string(json['name'], fallback: 'Virtual machine'),
      state: _string(statusObject?['state'], fallback: 'UNKNOWN'),
      vcpus: _integer(json['vcpus'], fallback: 1),
      cores: _integer(json['cores'], fallback: 1),
      threads: _integer(json['threads'], fallback: 1),
      memoryMiB: _integer(json['memory']),
      autostart: json['autostart'] == true,
      displayAvailable: json['display_available'] == true,
      description: _nullableString(json['description']),
    );
  }

  final int id;
  final String name;
  final String state;
  final int vcpus;
  final int cores;
  final int threads;
  final int memoryMiB;
  final bool autostart;
  final bool displayAvailable;
  final String? description;

  bool get isRunning => state == 'RUNNING';
}

class SnapshotEntry {
  const SnapshotEntry({
    required this.id,
    required this.dataset,
    required this.name,
    required this.transactionGroup,
    this.held = false,
  });

  factory SnapshotEntry.fromJson(JsonObject json) => SnapshotEntry(
    id: _string(json['id'] ?? json['name'], fallback: 'snapshot'),
    dataset: _string(json['dataset'], fallback: 'Dataset'),
    name: _string(
      json['snapshot_name'] ?? _snapshotLeaf(json['name']),
      fallback: 'Snapshot',
    ),
    transactionGroup: _string(json['createtxg'], fallback: 'Unknown'),
    held: _hasHold(json['holds']),
  );

  final String id;
  final String dataset;
  final String name;
  final String transactionGroup;

  /// A held snapshot cannot be destroyed until every hold is released.
  final bool held;
}

/// `pool.snapshot.query` returns holds as a tag/value map, so any entry means
/// the snapshot is protected from deletion.
bool _hasHold(Object? value) {
  if (value is JsonObject) return value.isNotEmpty;
  if (value is List<Object?>) return value.isNotEmpty;
  return false;
}

class ScrubTask {
  const ScrubTask({
    required this.id,
    required this.poolName,
    required this.enabled,
    required this.thresholdDays,
    required this.schedule,
    required this.scheduleHour,
    required this.scheduleMinute,
    required this.scheduleDayOfWeek,
    required this.scheduleAvailable,
    this.description,
  });

  factory ScrubTask.fromJson(JsonObject json) {
    final schedule = json['schedule'];
    final scheduleJson = schedule is JsonObject ? schedule : null;
    final minute = '${scheduleJson?['minute'] ?? '00'}';
    final hour = '${scheduleJson?['hour'] ?? '00'}';
    final dayOfWeek = '${scheduleJson?['dow'] ?? '*'}';
    return ScrubTask(
      id: _integer(json['id']),
      poolName: _string(json['pool_name'], fallback: 'Pool'),
      enabled: json['enabled'] != false,
      thresholdDays: _integer(json['threshold'], fallback: 35),
      schedule: '$minute $hour * * $dayOfWeek',
      scheduleHour: hour,
      scheduleMinute: minute,
      scheduleDayOfWeek: dayOfWeek,
      scheduleAvailable: scheduleJson != null,
      description: _nullableString(json['description']),
    );
  }

  final int id;
  final String poolName;
  final bool enabled;
  final int thresholdDays;
  final String schedule;
  final String scheduleHour;
  final String scheduleMinute;
  final String scheduleDayOfWeek;
  final bool scheduleAvailable;
  final String? description;
}

class CloudSyncTask {
  const CloudSyncTask({
    required this.id,
    required this.name,
    required this.path,
    required this.direction,
    required this.transferMode,
    required this.enabled,
    required this.provider,
    this.state,
  });

  factory CloudSyncTask.fromJson(JsonObject json) {
    final credentials = json['credentials'];
    final credentialObject = credentials is JsonObject ? credentials : null;
    final provider = credentialObject?['provider'];
    final providerObject = provider is JsonObject ? provider : null;
    final job = json['job'];
    final jobObject = job is JsonObject ? job : null;
    return CloudSyncTask(
      id: _integer(json['id']),
      name: _string(json['description'], fallback: 'Cloud sync'),
      path: _string(json['path'], fallback: 'Unknown path'),
      direction: _string(json['direction'], fallback: 'PUSH'),
      transferMode: _string(json['transfer_mode'], fallback: 'SYNC'),
      enabled: json['enabled'] != false,
      provider: _string(
        providerObject?['type'] ?? credentialObject?['name'],
        fallback: 'Cloud',
      ),
      state: _nullableString(jobObject?['state']),
    );
  }

  final int id;
  final String name;
  final String path;
  final String direction;
  final String transferMode;
  final bool enabled;
  final String provider;
  final String? state;

  bool get isRunning => state == 'RUNNING' || state == 'WAITING';
}

class RsyncTask {
  const RsyncTask({
    required this.id,
    required this.path,
    required this.direction,
    required this.mode,
    required this.enabled,
    required this.remote,
    this.description,
    this.state,
  });

  factory RsyncTask.fromJson(JsonObject json) {
    final job = json['job'];
    final jobObject = job is JsonObject ? job : null;
    return RsyncTask(
      id: _integer(json['id']),
      path: _string(json['path'], fallback: 'Unknown path'),
      direction: _string(json['direction'], fallback: 'PUSH'),
      mode: _string(json['mode'], fallback: 'MODULE'),
      enabled: json['enabled'] != false,
      remote: _string(
        json['remotehost'] ?? json['remotemodule'],
        fallback: 'Remote system',
      ),
      description: _nullableString(json['desc']),
      state: _nullableString(jobObject?['state']),
    );
  }

  final int id;
  final String path;
  final String direction;
  final String mode;
  final bool enabled;
  final String remote;
  final String? description;
  final String? state;

  bool get isRunning => state == 'RUNNING' || state == 'WAITING';
}

String formatBytes(int? bytes) {
  if (bytes == null) return '—';
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final decimals = value >= 10 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

int? _nullableInteger(Object? value) => value == null ? null : _integer(value);

/// Parses a numeric value without inventing a fallback.
///
/// Distinct from [_nullableInteger]: an unparseable temperature must stay
/// unknown rather than becoming zero, which would read as a very cold drive.
int? _strictInteger(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// TrueNAS serializes job timestamps as `{"$date": <milliseconds>}`, but some
/// releases return a bare epoch value instead.
DateTime? _epochTimestamp(Object? value) {
  Object? raw = value;
  if (raw is JsonObject) {
    raw = raw[r'$date'] ?? raw['date'];
  }
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc();
    raw = num.tryParse(raw);
  }
  if (raw is! num) return null;
  final milliseconds = raw.abs() > 100000000000
      ? raw.toInt()
      : raw.toInt() * 1000;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

int? _propertyInteger(Object? value) {
  if (value is JsonObject) {
    return _nullableInteger(
      value['parsed'] ?? value['rawvalue'] ?? value['value'],
    );
  }
  return _nullableInteger(value);
}

/// Reads the string form of a ZFS property, which 25.10 returns as
/// `{"value": ..., "rawvalue": ..., "parsed": ..., "source": ...}`.
String? _propertyString(Object? value) {
  if (value is JsonObject) {
    final parsed = value['parsed'] ?? value['value'] ?? value['rawvalue'];
    if (parsed is bool) return parsed ? 'ON' : 'OFF';
    return _nullableString(parsed is String ? parsed : '$parsed');
  }
  if (value is bool) return value ? 'ON' : 'OFF';
  return _nullableString(value);
}

String? _propertySource(Object? value) {
  if (value is! JsonObject) return null;
  final source = value['source'];
  return source is String ? source.toUpperCase() : null;
}

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

Map<String, Object?> _alertArguments(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  });
}

/// Resolves the named Python printf placeholders used by TrueNAS alerts.
///
/// Middleware sends alert templates and their `args` separately. Unknown or
/// missing arguments stay visible instead of being silently erased, which
/// keeps malformed server messages diagnosable.
String _formatAlertTemplate(String template, Map<String, Object?> arguments) {
  if (arguments.isEmpty || !template.contains('%(')) return template;
  final placeholder = RegExp(
    r'%\(([^)]+)\)[#0\- +]*\d*(?:\.(\d+))?([diouxXeEfFgGcrs])',
  );
  return template.replaceAllMapped(placeholder, (match) {
    final name = match.group(1)!;
    if (!arguments.containsKey(name)) return match.group(0)!;
    return _formatAlertArgument(
      arguments[name],
      match.group(3)!,
      int.tryParse(match.group(2) ?? ''),
    );
  });
}

String _formatAlertArgument(Object? value, String type, int? precision) {
  final number = value is num ? value : num.tryParse('$value');
  switch (type) {
    case 'd':
    case 'i':
    case 'u':
      return number?.toInt().toString() ?? '$value';
    case 'o':
      return number?.toInt().toRadixString(8) ?? '$value';
    case 'x':
    case 'X':
      final formatted = number?.toInt().toRadixString(16) ?? '$value';
      return type == 'X' ? formatted.toUpperCase() : formatted;
    case 'e':
    case 'E':
      final formatted = number?.toDouble().toStringAsExponential(
        precision ?? 6,
      );
      return type == 'E'
          ? formatted?.toUpperCase() ?? '$value'
          : formatted ?? '$value';
    case 'f':
    case 'F':
      return number?.toDouble().toStringAsFixed(precision ?? 6) ?? '$value';
    case 'g':
    case 'G':
      final formatted = number?.toDouble().toStringAsPrecision(precision ?? 6);
      return type == 'G'
          ? formatted?.toUpperCase() ?? '$value'
          : formatted ?? '$value';
    case 'c':
      if (value is int) return String.fromCharCode(value);
      final string = '$value';
      return string.isEmpty ? string : string[0];
    case 'r':
    case 's':
      if (value is Iterable) return value.join(', ');
      return value?.toString() ?? '';
  }
  return '$value';
}

List<String> _stringList(Object? value) => value is List<Object?>
    ? value.whereType<String>().toList(growable: false)
    : const [];

List<JsonObject> _objectList(Object? value) => value is List<Object?>
    ? value.whereType<JsonObject>().toList(growable: false)
    : const [];

String? _snapshotLeaf(Object? value) {
  if (value is! String || !value.contains('@')) return null;
  return value.split('@').last;
}
