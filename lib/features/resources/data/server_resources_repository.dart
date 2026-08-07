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

  Future<ServerResources> load({Set<String>? supportedMethods}) async {
    final results = await Future.wait<Object>([
      _section(
        'pool.query',
        StoragePool.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'pool.dataset.query',
        Dataset.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'app.query',
        InstalledApp.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'service.query',
        SystemService.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'alert.list',
        SystemAlert.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
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
      _section(
        'replication.query',
        ReplicationTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'pool.snapshottask.query',
        SnapshotTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
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
      _section(
        'sharing.smb.query',
        SmbShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'sharing.nfs.query',
        NfsShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'vm.query',
        VirtualMachine.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
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
      _section(
        'pool.scrub.query',
        ScrubTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'cloudsync.query',
        CloudSyncTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'rsynctask.query',
        RsyncTask.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'container.query',
        ManagedContainer.fromJson,
        supportedMethods: supportedMethods,
      ),
      // 25.10's Instances surface. Separate from container.query, which that
      // release does not advertise at all: virt.* replaced it, so a 25.10
      // server reaches this section and the container one degrades.
      _section(
        'virt.instance.query',
        VirtInstance.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.target.query',
        IscsiTarget.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.extent.query',
        IscsiExtent.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'sharing.webshare.query',
        WebShare.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.portal.query',
        IscsiPortal.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.initiator.query',
        IscsiInitiator.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.targetextent.query',
        IscsiTargetExtent.fromJson,
        supportedMethods: supportedMethods,
      ),
      _section(
        'iscsi.auth.query',
        IscsiAuth.fromJson,
        supportedMethods: supportedMethods,
      ),
    ]);

    // Temperatures are read after the inventory because the call takes the
    // device names to poll, so it cannot join the batch above. A failure here
    // must not degrade the disk list.
    final disks = results[8] as ResourceSection<StorageDisk>;
    final temperatures = await _diskTemperatures(
      disks.items.map((disk) => disk.name).toList(growable: false),
      supportedMethods: supportedMethods,
    );

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
