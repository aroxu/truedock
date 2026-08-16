import '../../../core/api/truenas_json_rpc_client.dart';
import '../domain/server_resources.dart';
import '../../../core/domain/data_message.dart';

class ServerResourcesRepository {
  const ServerResourcesRepository(this._client);

  final TrueNasJsonRpcClient _client;

  Future<ResourceSection<SystemJob>> loadActiveJobs({
    Set<String>? supportedMethods,
  }) => _section(
    'core.get_jobs',
    SystemJob.fromJson,
    supportedMethods: supportedMethods,
    params: const [
      [
        [
          'state',
          'in',
          ['WAITING', 'RUNNING'],
        ],
      ],
      {
        'order_by': ['-id'],
        'limit': 100,
      },
    ],
  );

  /// Reads one job without filtering out terminal states so an already-open
  /// detail sheet can transition from running to success/failure in place.
  Future<SystemJob?> loadJob(int id, {Set<String>? supportedMethods}) async {
    final section = await _section(
      'core.get_jobs',
      SystemJob.fromJson,
      supportedMethods: supportedMethods,
      params: [
        [
          ['id', '=', id],
        ],
        const {'limit': 1},
      ],
    );
    return section.items.firstOrNull;
  }

  Future<ServerResources> load({
    Set<String>? supportedMethods,
    ServerResourceScope scope = ServerResourceScope.all,
  }) async {
    final storage =
        scope == ServerResourceScope.all ||
        scope == ServerResourceScope.storage;
    final protection =
        scope == ServerResourceScope.all ||
        scope == ServerResourceScope.protection;
    final apps =
        scope == ServerResourceScope.all || scope == ServerResourceScope.apps;
    final overview =
        scope == ServerResourceScope.all ||
        scope == ServerResourceScope.overview;
    final system =
        scope == ServerResourceScope.all || scope == ServerResourceScope.system;
    final results = await Future.wait<Object>([
      _sectionWhen(
        storage,
        'pool.query',
        StoragePool.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage || protection,
        'pool.dataset.query',
        Dataset.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        apps,
        'app.query',
        InstalledApp.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        apps,
        'service.query',
        SystemService.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        overview || system,
        'alert.list',
        SystemAlert.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        overview || protection || system,
        'core.get_jobs',
        SystemJob.fromJson,
        supportedMethods: supportedMethods,
        params: const [
          [],
          {
            'order_by': ['-id'],
            'limit': 200,
          },
        ],
      ),
      _sectionWhen(
        protection,
        'replication.query',
        ReplicationTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        protection,
        'pool.snapshottask.query',
        SnapshotTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'disk.query',
        StorageDisk.fromJson,
        supportedMethods: supportedMethods,
        params: const [
          [],
          {
            'extra': {'pools': true},
          },
        ],
      ),
      _sectionWhen(
        storage,
        'sharing.smb.query',
        SmbShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'sharing.nfs.query',
        NfsShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        apps,
        'vm.query',
        VirtualMachine.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage || protection,
        'pool.snapshot.query',
        SnapshotEntry.fromJson,
        supportedMethods: supportedMethods,
        params: const [
          [],
          {
            'order_by': ['-createtxg'],
            'limit': 50,
            // Holds are omitted unless requested, and TrueDock needs them to
            // show which snapshots are protected from deletion.
            'extra': {'holds': true},
          },
        ],
      ),
      _sectionWhen(
        protection,
        'pool.scrub.query',
        ScrubTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        protection,
        'cloudsync.query',
        CloudSyncTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        protection,
        'rsynctask.query',
        RsyncTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        apps,
        'container.query',
        ManagedContainer.fromJson,
        supportedMethods: supportedMethods,
      ),
      // 25.10's Instances surface. Separate from container.query, which that
      // release does not advertise at all: virt.* replaced it, so a 25.10
      // server reaches this section and the container one degrades.
      _sectionWhen(
        apps,
        'virt.instance.query',
        VirtInstance.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.target.query',
        IscsiTarget.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.extent.query',
        IscsiExtent.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'sharing.webshare.query',
        WebShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.portal.query',
        IscsiPortal.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.initiator.query',
        IscsiInitiator.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.targetextent.query',
        IscsiTargetExtent.fromJson,
        supportedMethods: supportedMethods,
      ),
      _sectionWhen(
        storage,
        'iscsi.auth.query',
        IscsiAuth.fromJson,
        supportedMethods: supportedMethods,
      ),
    ]);

    // Temperatures are read after the inventory because the call takes the
    // device names to poll, so it cannot join the batch above. A failure here
    // must not degrade the disk list.
    final disks = results[8] as ResourceSection<StorageDisk>;
    final temperatures = storage
        ? await _diskTemperatures(
            disks.items.map((disk) => disk.name).toList(growable: false),
            supportedMethods: supportedMethods,
          )
        : const DiskTemperatureReport();

    return ServerResources(
      pools: results[0] as ResourceSection<StoragePool>,
      datasets: results[1] as ResourceSection<Dataset>,
      apps: results[2] as ResourceSection<InstalledApp>,
      services: results[3] as ResourceSection<SystemService>,
      alerts: results[4] as ResourceSection<SystemAlert>,
      jobs: results[5] as ResourceSection<SystemJob>,
      replications: results[6] as ResourceSection<ReplicationTask>,
      snapshotTasks: results[7] as ResourceSection<SnapshotTask>,
      disks: disks,
      smbShares: results[9] as ResourceSection<SmbShare>,
      nfsShares: results[10] as ResourceSection<NfsShare>,
      virtualMachines: results[11] as ResourceSection<VirtualMachine>,
      snapshots: results[12] as ResourceSection<SnapshotEntry>,
      scrubTasks: results[13] as ResourceSection<ScrubTask>,
      cloudSyncTasks: results[14] as ResourceSection<CloudSyncTask>,
      rsyncTasks: results[15] as ResourceSection<RsyncTask>,
      containers: results[16] as ResourceSection<ManagedContainer>,
      virtInstances: results[17] as ResourceSection<VirtInstance>,
      iscsiTargets: results[18] as ResourceSection<IscsiTarget>,
      iscsiExtents: results[19] as ResourceSection<IscsiExtent>,
      webShares: results[20] as ResourceSection<WebShare>,
      iscsiPortals: results[21] as ResourceSection<IscsiPortal>,
      iscsiInitiators: results[22] as ResourceSection<IscsiInitiator>,
      iscsiTargetExtents: results[23] as ResourceSection<IscsiTargetExtent>,
      iscsiAuths: results[24] as ResourceSection<IscsiAuth>,
      diskTemperatures: temperatures,
    );
  }

  Future<ResourceSection<T>> _sectionWhen<T>(
    bool enabled,
    String method,
    T Function(JsonObject json) decode, {
    List<Object?> params = const [],
    Set<String>? supportedMethods,
  }) {
    if (!enabled) return Future.value(ResourceSection<T>());
    return _section(
      method,
      decode,
      params: params,
      supportedMethods: supportedMethods,
    );
  }

  /// Reads current disk temperatures via `disk.temperatures`.
  ///
  /// 25.10 removed the `smart.*` namespace, so this is the supported way to
  /// surface drive thermals. The response is a mapping keyed by device name
  /// whose value is null for a drive that could not be read.
  Future<DiskTemperatureReport> _diskTemperatures(
    List<String> deviceNames, {
    Set<String>? supportedMethods,
  }) async {
    const method = 'disk.temperatures';
    if (supportedMethods != null && !supportedMethods.contains(method)) {
      return const DiskTemperatureReport(
        error: DataMessage(
          DataMessageCode.methodUnavailable,
          method: 'disk.temperatures',
          fallback:
              'disk.temperatures is not available on this TrueNAS version.',
        ),
      );
    }
    // Asking for an empty list would make the server poll every disk it knows.
    if (deviceNames.isEmpty) return const DiskTemperatureReport();
    try {
      final response = await _client.call(method, params: [deviceNames]);
      if (response is! Map<Object?, Object?>) {
        return const DiskTemperatureReport(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: 'disk.temperatures',
            fallback: 'disk.temperatures returned invalid data.',
          ),
        );
      }
      final readings = <String, DiskTemperature>{};
      for (final entry in response.entries) {
        final name = entry.key;
        if (name is! String) continue;
        readings[name] = DiskTemperature.fromValue(entry.value);
      }
      return DiskTemperatureReport(readings: readings);
    } on TrueNasRpcException catch (error) {
      return DiskTemperatureReport(
        error: DataMessage.raw(error.displayMessage),
      );
    } on Object {
      return const DiskTemperatureReport(
        error: DataMessage(
          DataMessageCode.decodeDiskTemperatures,
          fallback: 'Could not decode disk.temperatures.',
        ),
      );
    }
  }

  Future<ResourceSection<T>> _section<T>(
    String method,
    T Function(JsonObject json) decode, {
    List<Object?> params = const [],
    Set<String>? supportedMethods,
  }) async {
    if (supportedMethods != null && !supportedMethods.contains(method)) {
      return ResourceSection(
        error: DataMessage(
          DataMessageCode.methodUnavailable,
          method: method,
          fallback: '$method is not available on this TrueNAS version.',
        ),
      );
    }
    try {
      final response = await _client.call(method, params: params);
      if (response is! List<Object?>) {
        return ResourceSection(
          error: DataMessage(
            DataMessageCode.invalidData,
            method: method,
            fallback: '$method returned invalid data.',
          ),
        );
      }
      final items = response
          .whereType<JsonObject>()
          .map(decode)
          .toList(growable: false);
      return ResourceSection(items: items);
    } on TrueNasRpcException catch (error) {
      if (_isMissingMethod(error)) {
        return ResourceSection(
          error: DataMessage(
            DataMessageCode.methodUnavailable,
            method: method,
            fallback: '$method is not available on this TrueNAS version.',
          ),
        );
      }
      return ResourceSection(error: DataMessage.raw(error.displayMessage));
    } on Object {
      return ResourceSection(
        error: DataMessage(
          DataMessageCode.decodeFailed,
          method: method,
          fallback: 'Could not decode $method.',
        ),
      );
    }
  }

  static bool _isMissingMethod(TrueNasRpcException error) {
    if (error.code == -32601) return true;
    final detail = error.displayMessage.toLowerCase();
    return detail.contains('method does not exist') ||
        detail.contains('method not found');
  }
}
