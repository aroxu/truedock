import '../../../core/api/truenas_json_rpc_client.dart';
import '../../connection/domain/server_profile.dart';
import '../../apps/domain/app_configuration.dart';
import '../../apps/domain/app_installation.dart';
import '../../apps/domain/app_upgrade.dart';
import '../../data_protection/domain/snapshot_task_configuration.dart';
import '../../system/domain/vm_configuration.dart';
import '../../system/domain/vm_device.dart';
import '../../system/domain/container_configuration.dart';
import '../../system/domain/system_general_configuration.dart';
import '../../storage/domain/pool_configuration.dart';
import '../../storage/domain/dataset_quota.dart';
import '../../system/domain/static_route_configuration.dart';
import '../../system/domain/interface_configuration.dart';
import '../../system/domain/pending_network_changes.dart';
import '../../system/domain/network_configuration.dart';
import '../../system/domain/cron_job_configuration.dart';
import '../../system/domain/tunable_configuration.dart';
import '../../system/domain/mail_configuration.dart';
import '../../system/domain/service_configuration.dart';
import '../../system/domain/alert_service_configuration.dart';
import '../../system/domain/alert_class_configuration.dart';
import '../../system/domain/privilege_configuration.dart';
import '../../system/domain/config_backup.dart';
import '../../system/domain/audit_entry.dart';
import '../../system/domain/virt_instance_configuration.dart';
import '../../resources/domain/server_resources.dart';
import '../../data_protection/domain/replication_configuration.dart';
import '../../data_protection/domain/cloud_sync_configuration.dart';
import '../../data_protection/domain/cloud_backup_configuration.dart';
import '../../data_protection/domain/rsync_configuration.dart';
import '../../data_protection/domain/task_schedule.dart';
import '../../storage/domain/dataset_configuration.dart';
import '../../storage/domain/iscsi_configuration.dart';
import '../../storage/domain/iscsi_extent_configuration.dart';
import '../../storage/domain/nfs_share_configuration.dart';
import '../../storage/domain/smb_acl_configuration.dart';
import '../../storage/domain/dataset_acl.dart';
import '../../storage/domain/smb_share_configuration.dart';
import '../../storage/domain/iscsi_target_configuration.dart';
import '../../storage/domain/iscsi_target_extent_configuration.dart';

enum DatasetShareType { generic, smb, nfs, multiprotocol, apps }

extension DatasetShareTypeApi on DatasetShareType {
  String get apiValue => switch (this) {
    DatasetShareType.generic => 'GENERIC',
    DatasetShareType.smb => 'SMB',
    DatasetShareType.nfs => 'NFS',
    DatasetShareType.multiprotocol => 'MULTIPROTOCOL',
    DatasetShareType.apps => 'APPS',
  };
}

enum ServiceVerb { start, stop, restart, reload }

extension ServiceVerbApi on ServiceVerb {
  String get apiValue => name.toUpperCase();
}

/// Lifecycle verbs shared by virtual machines and standalone containers.
enum InstanceVerb { start, stop, restart, powerOff }

/// How far a snapshot rollback is allowed to reach.
enum ScrubControlAction { pause, resume, stop }

extension ScrubControlActionApi on ScrubControlAction {
  String get apiValue => switch (this) {
    ScrubControlAction.pause => 'PAUSE',
    ScrubControlAction.resume => 'RESUME',
    ScrubControlAction.stop => 'STOP',
  };

  String get label => switch (this) {
    ScrubControlAction.pause => 'Pause scrub',
    ScrubControlAction.resume => 'Resume scrub',
    ScrubControlAction.stop => 'Stop scrub',
  };
}

///
/// TrueNAS refuses a rollback when newer snapshots exist unless it is told
/// which ones it may destroy, so TrueDock makes that choice explicit rather
/// than silently sending the widest option.
enum SnapshotRollbackMode {
  newestOnly,
  newerSnapshots,
  newerSnapshotsAndClones,
}

extension SnapshotRollbackModeApi on SnapshotRollbackMode {
  bool get recursive => this != SnapshotRollbackMode.newestOnly;

  bool get recursiveClones =>
      this == SnapshotRollbackMode.newerSnapshotsAndClones;

  String get label => switch (this) {
    SnapshotRollbackMode.newestOnly => 'Only if this is the newest snapshot',
    SnapshotRollbackMode.newerSnapshots => 'Destroy newer snapshots',
    SnapshotRollbackMode.newerSnapshotsAndClones =>
      'Destroy newer snapshots and their clones',
  };

  String get description => switch (this) {
    SnapshotRollbackMode.newestOnly =>
      'The rollback fails if any newer snapshot exists. Safest option.',
    SnapshotRollbackMode.newerSnapshots =>
      'Every snapshot taken after this one is permanently destroyed.',
    SnapshotRollbackMode.newerSnapshotsAndClones =>
      'Newer snapshots and any datasets cloned from them are destroyed.',
  };
}

extension InstanceVerbLabel on InstanceVerb {
  String get label => switch (this) {
    InstanceVerb.start => 'Start',
    InstanceVerb.stop => 'Stop',
    InstanceVerb.restart => 'Restart',
    InstanceVerb.powerOff => 'Force power off',
  };

  /// Stopping or restarting interrupts a running workload, so those verbs
  /// require confirmation before TrueDock calls the server.
  bool get isDisruptive => this != InstanceVerb.start;
}

class OperationReceipt {
  const OperationReceipt({required this.method, this.jobId, this.result});

  factory OperationReceipt.fromResult(String method, Object? result) {
    return OperationReceipt(
      method: method,
      jobId: result is int ? result : null,
      result: result,
    );
  }

  final String method;
  final int? jobId;
  final Object? result;
}

class ServerActionsRepository {
  const ServerActionsRepository(this._client);

  final TrueNasJsonRpcClient _client;

  Future<OperationReceipt> createDataset({
    required String fullName,
    required DatasetShareType shareType,
  }) async {
    const method = 'pool.dataset.create';
    final result = await _client.call(
      method,
      params: [
        {
          'name': fullName,
          'type': 'FILESYSTEM',
          'share_type': shareType.apiValue,
          'inherit_encryption': true,
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Creates a zvol (a block-device dataset) via `pool.dataset.create`.
  ///
  /// This is a separate call rather than a flag on [createDataset] because the
  /// payloads barely overlap: a volume takes `volsize` and `sparse` and must not
  /// carry `share_type`, which applies only to a filesystem. iSCSI disk extents
  /// need a zvol, so without this the extent editor could only ever reuse
  /// volumes created in the web UI.
  Future<OperationReceipt> createVolume({
    required String fullName,
    required int sizeBytes,
    bool sparse = false,
    int? blockSizeBytes,
  }) async {
    const method = 'pool.dataset.create';
    final result = await _client.call(
      method,
      params: [
        {
          'name': fullName,
          'type': 'VOLUME',
          'volsize': sizeBytes,
          'sparse': sparse,
          // Omitted unless chosen so the server keeps its own default, which
          // varies by pool geometry.
          if (blockSizeBytes != null)
            'volblocksize': '${blockSizeBytes ~/ 1024}K',
          'inherit_encryption': true,
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Reads per-account quotas and usage for a dataset.
  ///
  /// `get_quota` only accepts `USER`, `GROUP`, `DATASET` and `PROJECT` - it
  /// rejects the `USEROBJ`/`GROUPOBJ` values that `set_quota` requires. Object
  /// limits come back as an `obj_quota` field on the plain USER/GROUP row
  /// instead, so one read per subject covers both limits.
  ///
  /// Every account that has ever written to the dataset appears here, whether
  /// or not it has a limit, so the caller decides what is worth showing.
  Future<List<DatasetQuota>> getDatasetQuotas(
    String datasetId,
    QuotaSubject subject,
  ) async {
    const method = 'pool.dataset.get_quota';
    final result = await _client.call(
      method,
      params: [datasetId, subject.spaceType],
    );
    if (result is! List) {
      throw TrueNasRpcException(
        code: -1,
        message: '$method returned unexpected data.',
      );
    }
    return [
      for (final row in result)
        if (row is Map<String, dynamic>) DatasetQuota.fromJson(row),
    ];
  }

  /// Applies quota changes to a dataset.
  ///
  /// Takes the whole batch because the API does: one call carries entries of
  /// mixed types, and a single edit already expands into separate space and
  /// object entries. Sending them together also means a rejected entry - an
  /// unknown account, or uid 0, both of which the server refuses - fails the
  /// batch rather than leaving half of it applied.
  Future<OperationReceipt> setDatasetQuotas(
    String datasetId,
    List<DatasetQuotaEdit> edits,
  ) => _mutate('pool.dataset.set_quota', [
    datasetId,
    [for (final edit in edits) ...edit.toApiJson()],
  ]);

  Future<OperationReceipt> updateDataset(
    String datasetId,
    Map<String, Object?> payload,
  ) => _mutate('pool.dataset.update', [datasetId, payload]);

  /// Renames a dataset. TrueNAS runs this as a job because the operation
  /// unmounts and remounts the dataset and any children.
  Future<OperationReceipt> renameDataset(
    String datasetId,
    DatasetRenameRequest request,
  ) => _mutate('pool.dataset.rename', [datasetId, request.toApiJson()]);

  /// Destroys a dataset and, when [recursive] is set, everything beneath it.
  ///
  /// [force] additionally unmounts the dataset if it is busy. Both flags are
  /// surfaced explicitly in the UI because they widen the blast radius.
  Future<OperationReceipt> deleteDataset(
    String datasetId, {
    required bool recursive,
    required bool force,
  }) => _mutate('pool.dataset.delete', [
    datasetId,
    {'recursive': recursive, 'force': force},
  ]);

  /// Locks an encrypted dataset, evicting its key from memory.
  ///
  /// Only an encryption root can be locked. [forceUmount] additionally
  /// unmounts the dataset when applications still hold it open.
  Future<OperationReceipt> lockDataset(
    String datasetId, {
    required bool forceUmount,
  }) => _mutate('pool.dataset.lock', [
    datasetId,
    {'force_umount': forceUmount},
  ]);

  /// Unlocks an encrypted dataset using a passphrase or hex key.
  ///
  /// The secret is passed straight through to the server and is never stored
  /// or logged by TrueDock.
  Future<OperationReceipt> unlockDataset(
    String datasetId, {
    required String secret,
    required bool usePassphrase,
    required bool unlockChildren,
  }) => _mutate('pool.dataset.unlock', [
    datasetId,
    {
      'recursive': unlockChildren,
      'datasets': [
        {
          'name': datasetId,
          if (usePassphrase) 'passphrase': secret else 'key': secret,
        },
      ],
    },
  ]);

  /// Deletes a single snapshot. `defer` lets ZFS release it once existing
  /// holds are gone instead of failing outright.
  Future<OperationReceipt> deleteSnapshot(
    String snapshotId, {
    bool defer = false,
  }) => _mutate('pool.snapshot.delete', [
    snapshotId,
    {'defer': defer},
  ]);

  /// Rolls a dataset back to [snapshotId].
  ///
  /// TrueNAS requires a recursion mode describing which newer snapshots may be
  /// destroyed to make the rollback possible.
  Future<OperationReceipt> rollbackSnapshot(
    String snapshotId, {
    required SnapshotRollbackMode mode,
    required bool force,
  }) => _mutate('pool.snapshot.rollback', [
    snapshotId,
    {
      'recursive': mode.recursive,
      'recursive_clones': mode.recursiveClones,
      'force': force,
    },
  ]);

  /// Clones a snapshot into a new dataset. This is non-destructive.
  Future<OperationReceipt> cloneSnapshot(
    String snapshotId, {
    required String datasetDestination,
  }) => _mutate('pool.snapshot.clone', [
    {'snapshot': snapshotId, 'dataset_dst': datasetDestination},
  ]);

  /// Promotes a cloned dataset via `pool.dataset.promote`.
  ///
  /// A clone depends on the snapshot it came from, which blocks deleting that
  /// snapshot or its dataset. Promoting reverses the relationship so the clone
  /// owns the data and the original becomes the dependent one.
  Future<OperationReceipt> promoteDataset(String datasetId) =>
      _mutate('pool.dataset.promote', [datasetId]);

  /// Revokes an API key via `api_key.delete`.
  ///
  /// TrueDock recommends API-key authentication because a key can be withdrawn
  /// independently of the account password; this is what makes that true from
  /// inside the app. Any client still using the key stops working immediately.
  Future<OperationReceipt> deleteApiKey(int keyId) =>
      _mutate('api_key.delete', [keyId]);

  /// Ends one authenticated session via `auth.terminate_session`.
  ///
  /// The id is the session's own uuid, not an account id: terminating signs out
  /// a single connection rather than the user everywhere, which is what makes
  /// this usable for evicting one suspicious client.
  Future<OperationReceipt> terminateSession(String sessionId) =>
      _mutate('auth.terminate_session', [sessionId]);

  /// Ends every session except the caller's own, via
  /// `auth.terminate_other_sessions`.
  ///
  /// Deliberately a separate method rather than a loop over
  /// [terminateSession]: the server excludes the current session itself, so a
  /// client-side loop would race its own connection and could sign TrueDock out
  /// halfway through.
  Future<OperationReceipt> terminateOtherSessions() =>
      _mutate('auth.terminate_other_sessions', []);

  Future<OperationReceipt> deleteSmbShare(int shareId) =>
      _mutate('sharing.smb.delete', [shareId]);

  Future<OperationReceipt> deleteNfsShare(int shareId) =>
      _mutate('sharing.nfs.delete', [shareId]);

  /// Deletes an iSCSI portal. TrueNAS refuses when a target still uses it.
  Future<OperationReceipt> deleteIscsiPortal(int portalId) =>
      _mutate('iscsi.portal.delete', [portalId]);

  Future<OperationReceipt> deleteIscsiInitiator(int initiatorId) =>
      _mutate('iscsi.initiator.delete', [initiatorId]);

  /// Deletes an iSCSI target. [force] removes it even while initiators are
  /// connected, which interrupts their I/O immediately.
  Future<OperationReceipt> deleteIscsiTarget(
    int targetId, {
    required bool force,
  }) => _mutate('iscsi.target.delete', [targetId, force]);

  /// Deletes an iSCSI extent. [removeBackingFile] also destroys the backing
  /// file or zvol, which is unrecoverable.
  Future<OperationReceipt> deleteIscsiExtent(
    int extentId, {
    required bool removeBackingFile,
    required bool force,
  }) => _mutate('iscsi.extent.delete', [extentId, removeBackingFile, force]);

  Future<OperationReceipt> deleteIscsiTargetExtent(
    int associationId, {
    required bool force,
  }) => _mutate('iscsi.targetextent.delete', [associationId, force]);

  /// Places a hold on a snapshot so it cannot be deleted accidentally.
  Future<OperationReceipt> holdSnapshot(String snapshotId) =>
      _mutate('pool.snapshot.hold', [snapshotId]);

  /// Releases a previously placed hold.
  Future<OperationReceipt> releaseSnapshot(String snapshotId) =>
      _mutate('pool.snapshot.release', [snapshotId]);

  /// Restarts the server. TrueNAS runs this as a job and the connection drops
  /// as soon as it is accepted.
  ///
  /// `reason` is a required *positional* string, not a field of an options
  /// object; the second argument is the options object and carries only
  /// `delay`. Sending `{'reason': ...}` as the first argument is rejected.
  Future<OperationReceipt> rebootServer({required String reason}) =>
      _mutate('system.reboot', [reason]);

  /// Powers the server off. Recovery requires physical or out-of-band access.
  ///
  /// Takes the same positional `reason` argument as [rebootServer].
  Future<OperationReceipt> shutdownServer({required String reason}) =>
      _mutate('system.shutdown', [reason]);

  /// Downloads and applies an available update.
  ///
  /// [rebootAfter] lets the server restart itself once staging finishes;
  /// otherwise the update applies on the next manual restart.
  Future<OperationReceipt> runSystemUpdate({required bool rebootAfter}) =>
      _mutate('update.run', [
        {'reboot': rebootAfter},
      ]);

  Future<OperationReceipt> changeSystemUpdateProfile(String profileId) =>
      _mutate('update.update', [
        {'profile': profileId},
      ]);

  Future<OperationReceipt> uploadSystemUpdate({
    required ServerProfile profile,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    final jobId = await _client.uploadSystemUpdate(
      profile: profile,
      filePath: filePath,
      fileName: fileName,
      onProgress: onProgress,
    );
    return OperationReceipt(method: 'update.file', jobId: jobId);
  }

  Future<OperationReceipt> createSnapshot({
    required String dataset,
    required String name,
    required bool recursive,
  }) async {
    const method = 'pool.snapshot.create';
    final result = await _client.call(
      method,
      params: [
        {'dataset': dataset, 'name': name, 'recursive': recursive},
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> createSnapshotTask(
    CreateSnapshotTaskRequest request,
  ) async {
    const method = 'pool.snapshottask.create';
    final result = await _client.call(method, params: [request.toApiJson()]);
    return OperationReceipt.fromResult(method, result);
  }

  Future<SnapshotRetentionImpact> inspectSnapshotTaskUpdate(
    int taskId,
    CreateSnapshotTaskRequest request,
  ) async {
    const method = 'pool.snapshottask.update_will_change_retention_for';
    final result = await _client.call(
      method,
      params: [taskId, request.toApiJson()],
    );
    return SnapshotRetentionImpact.fromResult(result);
  }

  Future<OperationReceipt> updateSnapshotTask(
    int taskId,
    CreateSnapshotTaskRequest request,
  ) async {
    const method = 'pool.snapshottask.update';
    final result = await _client.call(
      method,
      params: [taskId, request.toApiJson()],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> runSnapshotTask(int taskId) =>
      _runTask('pool.snapshottask.run', [taskId]);

  /// Deletes a periodic snapshot task. Snapshots already taken by the task
  /// are kept; only the schedule is removed.
  Future<OperationReceipt> deleteSnapshotTask(int taskId) =>
      _mutate('pool.snapshottask.delete', [taskId]);

  /// Deletes a replication task definition. In-flight replications are not
  /// cancelled by this call; abort the underlying job first if needed.
  Future<OperationReceipt> deleteReplicationTask(int taskId) =>
      _mutate('replication.delete', [taskId]);

  /// Deletes a Cloud Sync task definition. Stored credentials referenced by
  /// the task are kept.
  Future<OperationReceipt> deleteCloudSyncTask(int taskId) =>
      _mutate('cloudsync.delete', [taskId]);

  /// Deletes an Rsync task definition.
  Future<OperationReceipt> deleteRsyncTask(int taskId) =>
      _mutate('rsynctask.delete', [taskId]);

  Future<List<SmbSharePreset>> getSmbSharePresets() async {
    const method = 'sharing.smb.presets';
    final result = await _client.call(method);
    return SmbSharePreset.fromResult(result);
  }

  Future<void> precheckSmbShareName(String name) async {
    const method = 'sharing.smb.share_precheck';
    await _client.call(
      method,
      params: [
        {'name': name},
      ],
    );
  }

  Future<OperationReceipt> createSmbShare(
    SmbShareConfiguration configuration,
  ) async {
    const method = 'sharing.smb.create';
    final result = await _client.call(
      method,
      params: [configuration.toApiJson()],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> updateSmbShare(
    int shareId,
    SmbShareConfiguration configuration,
  ) async {
    const method = 'sharing.smb.update';
    final result = await _client.call(
      method,
      params: [shareId, configuration.toApiJson()],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Reads the SMB share ACL via `sharing.smb.getacl`.
  ///
  /// The method takes the share *name*, not its id, and answers an object
  /// carrying `share_acl` rather than a bare list. Both were verified against
  /// a live 25.10 server; the underscored `sharing.smb.get_acl` spelling does
  /// not exist on the middleware.
  Future<List<SmbAclEntry>> getSmbShareAcl(String shareName) async {
    const method = 'sharing.smb.getacl';
    final result = await _client.call(
      method,
      params: [
        {'share_name': shareName},
      ],
    );
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'sharing.smb.getacl returned invalid data.',
      );
    }
    final entries = result['share_acl'];
    if (entries is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'sharing.smb.getacl returned no share_acl list.',
      );
    }
    return entries
        .whereType<Map<String, dynamic>>()
        .map(SmbAclEntry.fromJson)
        .toList(growable: false);
  }

  /// Replaces the SMB share ACL with [acl] via `sharing.smb.setacl`.
  ///
  /// Like the getter, this is keyed by share name and takes a single object
  /// with `share_name` and `share_acl`. The full list must be sent.
  Future<OperationReceipt> setSmbShareAcl(
    String shareName,
    List<SmbAclEntry> acl,
  ) async {
    const method = 'sharing.smb.setacl';
    final result = await _client.call(
      method,
      params: [
        {
          'share_name': shareName,
          'share_acl': acl.map((e) => e.toApiJson()).toList(),
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<DatasetAcl> getDatasetAcl(String datasetName) async {
    const method = 'filesystem.getacl';
    final result = await _client.call(
      method,
      params: ['/mnt/$datasetName', true, true],
    );
    if (result is! Map) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'filesystem.getacl returned invalid data.',
      );
    }
    return DatasetAcl.fromJson(Map<String, dynamic>.from(result));
  }

  Future<OperationReceipt> setDatasetAcl(
    DatasetAcl acl, {
    required bool recursive,
  }) async {
    const method = 'filesystem.setacl';
    final result = await _client.call(
      method,
      params: [acl.toSetApiJson(recursive: recursive)],
    );
    final receipt = OperationReceipt.fromResult(method, result);
    final jobId = receipt.jobId;
    if (jobId == null) return receipt;

    // `filesystem.setacl` is a job method. Its first response only confirms
    // that TrueNAS accepted the job; validation errors such as attempting to
    // change a ZFS pool mountpoint are reported later by `core.get_jobs`.
    // Treating the job id as success hides precisely the useful server error.
    await _waitForJob(jobId, operationName: 'setacl');
    return receipt;
  }

  Future<void> _waitForJob(
    int jobId, {
    required String operationName,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final result = await _client.call(
        'core.get_jobs',
        params: [
          [
            ['id', '=', jobId],
          ],
          {'limit': 1},
        ],
      );
      final jobs = result is List ? result : const <Object?>[];
      final rawJob = jobs.isEmpty ? null : jobs.first;
      if (rawJob is Map) {
        final job = Map<String, dynamic>.from(rawJob);
        final state = job['state']?.toString().toUpperCase();
        if (state == 'SUCCESS') return;
        if (state == 'FAILED' || state == 'ABORTED') {
          final error = job['error']?.toString().trim();
          final logs = job['logs_excerpt']?.toString().trim();
          final detail = error?.isNotEmpty == true
              ? error!
              : logs?.isNotEmpty == true
              ? logs!
              : 'TrueNAS job $jobId ended with state $state.';
          throw TrueNasRpcException(
            code: -1,
            message: '$operationName failed.',
            reason: detail,
          );
        }
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TrueNasRpcException(
          code: -1,
          message: '$operationName timed out while waiting for job $jobId.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<OperationReceipt> setDatasetAclType(
    String datasetId,
    DatasetAclType type,
  ) => _mutate('pool.dataset.update', [
    datasetId,
    {
      'acltype': type == DatasetAclType.nfs4 ? 'NFSV4' : 'POSIX',
      'aclmode': type == DatasetAclType.nfs4 ? 'PASSTHROUGH' : 'DISCARD',
    },
  ]);

  Future<OperationReceipt> createNfsShare(
    NfsShareConfiguration configuration,
  ) async {
    const method = 'sharing.nfs.create';
    final result = await _client.call(
      method,
      params: [configuration.toApiJson()],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> updateNfsShare(
    int shareId,
    NfsShareConfiguration configuration,
  ) async {
    const method = 'sharing.nfs.update';
    final result = await _client.call(
      method,
      params: [shareId, configuration.toApiJson()],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<List<String>> getIscsiPortalListenIpChoices() async {
    const method = 'iscsi.portal.listen_ip_choices';
    final result = await _client.call(method);
    if (result is! Map<Object?, Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'iscsi.portal.listen_ip_choices returned invalid data.',
      );
    }
    final addresses = result.keys.whereType<String>().toList(growable: false)
      ..sort();
    return addresses;
  }

  Future<OperationReceipt> createIscsiPortal(
    IscsiPortalConfiguration configuration,
  ) => _mutate('iscsi.portal.create', [configuration.toApiJson()]);

  Future<OperationReceipt> updateIscsiPortal(
    int portalId,
    IscsiPortalConfiguration configuration,
  ) => _mutate('iscsi.portal.update', [portalId, configuration.toApiJson()]);

  Future<OperationReceipt> createIscsiInitiator(
    IscsiInitiatorConfiguration configuration,
  ) => _mutate('iscsi.initiator.create', [configuration.toApiJson()]);

  Future<OperationReceipt> updateIscsiInitiator(
    int initiatorId,
    IscsiInitiatorConfiguration configuration,
  ) => _mutate('iscsi.initiator.update', [
    initiatorId,
    configuration.toApiJson(),
  ]);

  Future<void> validateIscsiTargetName(String name, {int? existingId}) async {
    const method = 'iscsi.target.validate_name';
    final result = await _client.call(method, params: [name, existingId]);
    if (result is String && result.isNotEmpty) {
      throw TrueNasRpcException(code: -1, message: result);
    }
    if (result != null) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'iscsi.target.validate_name returned invalid data.',
      );
    }
  }

  Future<OperationReceipt> createIscsiTarget(
    IscsiTargetConfiguration configuration,
  ) => _mutate('iscsi.target.create', [configuration.toApiJson()]);

  Future<OperationReceipt> updateIscsiTarget(
    int targetId,
    IscsiTargetConfiguration configuration,
  ) => _mutate('iscsi.target.update', [targetId, configuration.toApiJson()]);

  Future<Map<String, String>> getIscsiExtentDiskChoices() async {
    const method = 'iscsi.extent.disk_choices';
    final result = await _client.call(method);
    if (result is! Map<Object?, Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'iscsi.extent.disk_choices returned invalid data.',
      );
    }
    final choices = <String, String>{};
    for (final entry in result.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const TrueNasRpcException(
          code: -1,
          message: 'iscsi.extent.disk_choices returned invalid data.',
        );
      }
      choices[entry.key! as String] = entry.value! as String;
    }
    return Map.unmodifiable(choices);
  }

  Future<OperationReceipt> createIscsiExtent(
    IscsiExtentConfiguration configuration,
  ) => _mutate('iscsi.extent.create', [configuration.toApiJson()]);

  Future<OperationReceipt> updateIscsiExtent(
    int extentId,
    IscsiExtentConfiguration configuration,
  ) => _mutate('iscsi.extent.update', [extentId, configuration.toApiJson()]);

  Future<OperationReceipt> createIscsiTargetExtent(
    IscsiTargetExtentConfiguration configuration,
  ) => _mutate('iscsi.targetextent.create', [configuration.toCreateApiJson()]);

  Future<OperationReceipt> updateIscsiTargetExtent(
    int associationId,
    IscsiTargetExtentConfiguration configuration,
  ) => _mutate('iscsi.targetextent.update', [
    associationId,
    configuration.toUpdateApiJson(),
  ]);

  /// Creates a CHAP credential entry. [secret] and [peerSecret] (when mutual)
  /// are sent only in this call over the authenticated session and are never
  /// persisted by TrueDock. The repository does not log the payload; the
  /// shared redacted logger scrubs `secret`/`peersecret` shapes regardless.
  Future<OperationReceipt> createIscsiAuth({
    required int tag,
    required String user,
    required String secret,
    String? peerUser,
    String? peerSecret,
  }) => _mutate('iscsi.auth.create', [
    {
      'tag': tag,
      'user': user,
      'secret': secret,
      if (peerUser != null && peerUser.isNotEmpty) 'peeruser': peerUser,
      if (peerSecret != null && peerSecret.isNotEmpty) 'peersecret': peerSecret,
    },
  ]);

  /// Updates an existing CHAP credential entry. Secrets are write-only: pass a
  /// non-empty [secret] only when rotating it; pass null to leave the existing
  /// server-side secret unchanged. The same applies to [peerSecret].
  Future<OperationReceipt> updateIscsiAuth(
    int authId, {
    required int tag,
    required String user,
    String? secret,
    String? peerUser,
    String? peerSecret,
  }) => _mutate('iscsi.auth.update', [
    authId,
    {
      'tag': tag,
      'user': user,
      if (secret != null && secret.isNotEmpty) 'secret': secret,
      if (peerUser != null && peerUser.isNotEmpty) 'peeruser': peerUser,
      if (peerSecret != null && peerSecret.isNotEmpty) 'peersecret': peerSecret,
    },
  ]);

  /// Deletes a CHAP credential entry. Targets and initiator groups that still
  /// reference it must be updated first; the caller confirms the consequence.
  Future<OperationReceipt> deleteIscsiAuth(int authId) =>
      _mutate('iscsi.auth.delete', [authId]);

  Future<OperationReceipt> _mutate(String method, List<Object?> params) async {
    final result = await _client.call(method, params: params);
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> startApp(String appId) =>
      _appControl('app.start', appId);

  Future<OperationReceipt> stopApp(String appId) =>
      _appControl('app.stop', appId);

  /// Redeploys the app without changing its version. 25.10 exposes this as a
  /// job; it stops the running instance, recreates containers, and restarts
  /// the app, so users lose access until the job completes.
  Future<OperationReceipt> redeployApp(String appId) =>
      _appControl('app.redeploy', appId);

  /// Rolls the app back to [appVersion]. 25.10 exposes this as a job that
  /// rebuilds the app from the previous image and restarts it; the app is
  /// stopped during the rollback.
  ///
  /// `app.rollback` takes the same leading `appId` argument as the other
  /// `app.*` jobs followed by an options object carrying `app_version`, the
  /// image version to roll back to. The version is sourced from
  /// `app.upgrade_summary` so the user picks a target the server actually
  /// advertises. A live TrueNAS 25.10 server should verify the options shape
  /// because the middleware is documented but not yet exercised here.
  Future<OperationReceipt> rollbackApp(
    String appId, {
    required String appVersion,
  }) async {
    const method = 'app.rollback';
    final result = await _client.call(
      method,
      params: [
        appId,
        {'app_version': appVersion},
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Removes the app from the TrueNAS system. 25.10 exposes this as a job that
  /// removes the app's containers; pass [removeImages] to also delete the
  /// pulled images, and [keepVolumes] false to delete its TrueNAS-managed
  /// (ix_volumes) storage.
  ///
  /// The middleware names the volume flag `remove_ix_volumes`, not
  /// `keep_volumes`, and rejects unknown keys, so the polarity is inverted
  /// here rather than at the call sites. `force_remove_ix_volumes` is required
  /// as well, because the server refuses to drop a volume that still holds
  /// data without it — and a user who turned "keep volumes" off has already
  /// typed the app name to confirm exactly that.
  Future<OperationReceipt> deleteApp(
    String appId, {
    required bool removeImages,
    required bool keepVolumes,
  }) async {
    const method = 'app.delete';
    final result = await _client.call(
      method,
      params: [
        appId,
        {
          'remove_images': removeImages,
          'remove_ix_volumes': !keepVolumes,
          'force_remove_ix_volumes': !keepVolumes,
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<OperationReceipt> installCatalogApp(AppInstallRequest request) async {
    const method = 'app.create';
    final result = await _client.call(
      method,
      params: [
        {
          'custom_app': false,
          'values': request.values,
          'catalog_app': request.catalogApp,
          'app_name': request.appName,
          'train': request.train,
          'version': request.version,
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  Future<AppUpgradeSummary> getAppUpgradeSummary(String appId) async {
    const method = 'app.upgrade_summary';
    final result = await _client.call(
      method,
      params: [
        appId,
        {'app_version': 'latest'},
      ],
    );
    if (result is! UpgradeJson) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'app.upgrade_summary returned invalid data.',
      );
    }
    return AppUpgradeSummary.fromJson(result);
  }

  /// Lists the versions an app can be rolled back to, via
  /// `app.rollback_versions`.
  ///
  /// This is deliberately not `app.upgrade_summary`. That method describes
  /// *upgrade* targets and raises `[EFAULT] No upgrade available` when the app
  /// is already on the newest version — which is precisely when a user needs to
  /// roll back. Sourcing the rollback picker from it made rollback unreachable
  /// for an up-to-date app.
  Future<List<String>> getAppRollbackVersions(String appId) async {
    const method = 'app.rollback_versions';
    final result = await _client.call(method, params: [appId]);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'app.rollback_versions returned invalid data.',
      );
    }
    return result.whereType<String>().toList(growable: false);
  }

  Future<OperationReceipt> upgradeApp(
    String appId, {
    required String version,
    required bool snapshotHostPaths,
  }) async {
    const method = 'app.upgrade';
    final result = await _client.call(
      method,
      params: [
        appId,
        {
          'app_version': version,
          'values': <String, Object?>{},
          'snapshot_hostpaths': snapshotHostPaths,
        },
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Reconfigures an installed app with a new [values] object.
  /// `app.update` in TrueNAS 25.10 runs as a job that recreates the app with
  /// the supplied values; pass the full resolved values, not a diff.
  Future<OperationReceipt> updateApp(
    String appId, {
    Map<String, Object?>? values,
    Map<String, Object?>? customComposeConfig,
  }) async {
    const method = 'app.update';
    final result = await _client.call(
      method,
      params: [
        appId,
        {'values': ?values, 'custom_compose_config': ?customComposeConfig},
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Fetches the live configuration of an installed app, including the
  /// current `values` and the catalog reference needed to reconfigure it.
  Future<AppConfiguration> getAppConfig(Object appOrId) async {
    const method = 'app.config';
    final app = appOrId is InstalledApp ? appOrId : null;
    final appId = app?.id ?? '$appOrId';
    final result = await _client.call(method, params: [appId]);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'app.config returned invalid data.',
      );
    }
    return AppConfiguration.forInstalledApp(
      result,
      appId: appId,
      name: app?.name ?? appId,
      catalogApp: app?.catalogApp,
      train: app?.train,
      version: app?.technicalVersion,
    );
  }

  Future<OperationReceipt> _appControl(String method, String appId) async {
    final result = await _client.call(method, params: [appId]);
    return OperationReceipt.fromResult(method, result);
  }

  /// Controls a virtual machine. TrueNAS 25.10 exposes `vm.start`, `vm.stop`,
  /// `vm.restart`, and `vm.poweroff`; stop runs as a job.
  Future<OperationReceipt> controlVirtualMachine(int vmId, InstanceVerb verb) {
    return switch (verb) {
      InstanceVerb.start => _mutate('vm.start', [vmId]),
      InstanceVerb.stop => _mutate('vm.stop', [
        vmId,
        {'force': false, 'force_after_timeout': false},
      ]),
      InstanceVerb.restart => _mutate('vm.restart', [vmId]),
      InstanceVerb.powerOff => _mutate('vm.poweroff', [vmId]),
    };
  }

  /// Controls a standalone container on servers that expose the 26+
  /// `container.*` surface. Callers must gate on discovered methods.
  Future<OperationReceipt> controlContainer(int id, InstanceVerb verb) {
    return switch (verb) {
      InstanceVerb.start => _mutate('container.start', [id]),
      InstanceVerb.stop => _mutate('container.stop', [
        id,
        {'force': false},
      ]),
      InstanceVerb.restart => _mutate('container.restart', [id]),
      InstanceVerb.powerOff => _mutate('container.stop', [
        id,
        {'force': true},
      ]),
    };
  }

  /// Replaces a standalone container's configuration via `container.update`.
  /// The caller sends the whole config object because TrueNAS does not merge
  /// partial updates; the editor preserves fields it does not surface.
  Future<OperationReceipt> updateContainer(
    int containerId,
    ContainerConfiguration configuration,
  ) => _mutate('container.update', [containerId, configuration.toApiJson()]);

  /// Controls an instance on 25.10's `virt.instance.*` surface.
  ///
  /// The identifier is the instance *name*, not a number. Stop and restart take
  /// an options object carrying `timeout` and `force`; a graceful stop passes
  /// `force: false` with a bounded timeout so a wedged guest cannot hang the
  /// job indefinitely, while power off forces immediately. The schema documents
  /// `timeout: -1` as "no timeout", which is only meaningful with `force`, so
  /// it is sent only on the forced paths.
  Future<OperationReceipt> controlVirtInstance(
    String instanceId,
    InstanceVerb verb, {
    int gracefulTimeoutSeconds = 90,
  }) {
    return switch (verb) {
      InstanceVerb.start => _mutate('virt.instance.start', [instanceId]),
      InstanceVerb.stop => _mutate('virt.instance.stop', [
        instanceId,
        {'timeout': gracefulTimeoutSeconds, 'force': false},
      ]),
      InstanceVerb.restart => _mutate('virt.instance.restart', [
        instanceId,
        {'timeout': gracefulTimeoutSeconds, 'force': false},
      ]),
      InstanceVerb.powerOff => _mutate('virt.instance.stop', [
        instanceId,
        {'timeout': -1, 'force': true},
      ]),
    };
  }

  /// Deletes an instance and its root storage via `virt.instance.delete`.
  ///
  /// Irreversible: the instance's own disk is destroyed with it, so callers must
  /// use a typed confirmation.
  Future<OperationReceipt> deleteVirtInstance(String instanceId) =>
      _mutate('virt.instance.delete', [instanceId]);

  /// Updates the mutable fields of an instance via `virt.instance.update`.
  ///
  /// Only the fields the caller supplies are sent. Unlike `container.update`,
  /// this method accepts a partial object, so sending a whole config would
  /// overwrite values the editor does not surface.
  Future<OperationReceipt> updateVirtInstance(
    String instanceId,
    VirtInstanceConfiguration configuration,
  ) => _mutate('virt.instance.update', [instanceId, configuration.toApiJson()]);

  /// Creates an instance via `virt.instance.create`.
  Future<OperationReceipt> createVirtInstance(
    VirtInstanceCreateConfiguration configuration,
  ) => _mutate('virt.instance.create', [configuration.toApiJson()]);

  /// Reads the devices attached to an instance via
  /// `virt.instance.device_list`.
  Future<List<VirtInstanceDevice>> getVirtInstanceDevices(
    String instanceId,
  ) async {
    const method = 'virt.instance.device_list';
    final result = await _client.call(method, params: [instanceId]);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'virt.instance.device_list returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(VirtInstanceDevice.fromJson)
        .toList(growable: false);
  }

  /// Reads `virt.global.config`, which reports whether the Instances platform
  /// has a storage pool and is therefore usable at all.
  Future<VirtGlobalConfig> getVirtGlobalConfig() async {
    const method = 'virt.global.config';
    final result = await _client.call(method);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'virt.global.config returned invalid data.',
      );
    }
    return VirtGlobalConfig.fromJson(result);
  }

  /// Storage pools the Instances platform can be pointed at, from
  /// `virt.global.pool_choices`.
  Future<Map<String, String>> getVirtPoolChoices() async {
    const method = 'virt.global.pool_choices';
    final result = await _client.call(method);
    if (result is! Map<Object?, Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'virt.global.pool_choices returned invalid data.',
      );
    }
    return {
      for (final entry in result.entries) '${entry.key}': '${entry.value}',
    };
  }

  /// Points the Instances platform at [pool] via `virt.global.update`.
  ///
  /// Server-wide and disruptive: it creates the hidden `.ix-virt` dataset on
  /// that pool and every instance lives there afterwards, so the caller must
  /// confirm before invoking it.
  Future<OperationReceipt> updateVirtStoragePool(String pool) =>
      _mutate('virt.global.update', [
        {
          'pool': pool,
          'storage_pools': [pool],
        },
      ]);

  /// Container images the server can install, from
  /// `virt.instance.image_choices`.
  Future<List<VirtImageChoice>> getVirtImageChoices() async {
    const method = 'virt.instance.image_choices';
    final result = await _client.call(
      method,
      params: [
        {'remote': 'LINUX_CONTAINERS'},
      ],
    );
    if (result is! Map<Object?, Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'virt.instance.image_choices returned invalid data.',
      );
    }
    final choices = <VirtImageChoice>[];
    for (final entry in result.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        choices.add(VirtImageChoice.fromJson('${entry.key}', value));
      }
    }
    choices.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return choices;
  }

  /// Reads the host devices available to attach to a container via
  /// `container.device_choices`. Returns a label-by-value map the editor
  /// surfaces as a picker.
  Future<Map<String, String>> getContainerDeviceChoices() async {
    const method = 'container.device_choices';
    final result = await _client.call(method);
    if (result is! Map<Object?, Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'container.device_choices returned invalid data.',
      );
    }
    final choices = <String, String>{};
    for (final entry in result.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const TrueNasRpcException(
          code: -1,
          message: 'container.device_choices returned invalid data.',
        );
      }
      choices[entry.key! as String] = entry.value! as String;
    }
    return Map.unmodifiable(choices);
  }

  /// Reads the full configuration for a single container via
  /// `container.query` filtered by id. Returns the raw object so the editor
  /// can preserve devices, volumes, and environment it does not surface.
  Future<Map<String, dynamic>> getContainerConfig(int containerId) async {
    const method = 'container.query';
    final result = await _client.call(
      method,
      params: [
        [],
        {
          'filters': [
            ['id', '=', containerId],
          ],
        },
      ],
    );
    if (result is! List<Object?> || result.isEmpty) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'container.query returned invalid data.',
      );
    }
    final entry = result.first;
    if (entry is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'container.query returned invalid data.',
      );
    }
    return entry;
  }

  /// Updates a virtual machine with only the changed fields. TrueNAS applies
  /// the update synchronously; memory/CPU changes take effect on the next
  /// start. The caller must confirm the consequence of changing a running VM.
  Future<OperationReceipt> updateVirtualMachine(
    int vmId, {
    required VmConfiguration next,
    required VmConfiguration baseline,
  }) {
    final fields = next.changedFields(baseline);
    return _mutate('vm.update', [vmId, fields]);
  }

  /// Reads the devices attached to a VM via `vm.device.query`. TrueNAS returns
  /// a flat list of device objects scoped to [vmId].
  Future<List<VmDevice>> getVirtualMachineDevices(int vmId) async {
    const method = 'vm.device.query';
    final result = await _client.call(
      method,
      params: [
        [vmId],
      ],
    );
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'vm.device.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(VmDevice.fromJson)
        .toList(growable: false);
  }

  /// Adds a device to a VM via `vm.device.create`. The owning VM id and the
  /// device type/attributes come from [configuration].
  Future<OperationReceipt> createVirtualMachineDevice(
    VmDeviceConfiguration configuration,
    int vmId,
  ) => _mutate('vm.device.create', [configuration.toCreateApiJson(vmId)]);

  /// Updates an existing device via `vm.device.update`. Only the changed
  /// attributes are sent; the caller supplies the full replacement payload
  /// because TrueNAS rewrites the whole device entry.
  Future<OperationReceipt> updateVirtualMachineDevice(
    int deviceId,
    VmDeviceConfiguration configuration,
  ) => _mutate('vm.device.update', [deviceId, configuration.toUpdateApiJson()]);

  /// Removes a device from a VM via `vm.device.delete`. Removing a disk device
  /// does not delete the underlying zvol; the caller confirms the consequence.
  Future<OperationReceipt> deleteVirtualMachineDevice(int deviceId) =>
      _mutate('vm.device.delete', [deviceId]);

  /// Reads the editable general-system values from their 25.10 namespaces.
  Future<Map<String, dynamic>> getSystemGeneralConfig() async {
    final generalResult = await _client.call('system.general.config');
    if (generalResult is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'General system configuration returned invalid data.',
      );
    }
    final general = Map<String, dynamic>.from(generalResult);

    // Some compatible fixtures and older adapters already return a combined
    // view. Avoid redundant reads in that case while 25.10's strict response
    // is completed from the namespaces that actually own these fields.
    Map<String, dynamic> network = const {};
    if (general['hostname'] is! String) {
      final result = await _client.call('network.configuration.config');
      if (result is! Map<String, dynamic>) {
        throw const TrueNasRpcException(
          code: -1,
          message: 'Network configuration returned invalid data.',
        );
      }
      network = result;
    }
    Map<String, dynamic> advanced = const {};
    if (general['sysloglevel'] is! String) {
      final result = await _client.call('system.advanced.config');
      if (result is! Map<String, dynamic>) {
        throw const TrueNasRpcException(
          code: -1,
          message: 'Advanced system configuration returned invalid data.',
        );
      }
      advanced = result;
    }
    return {
      ...general,
      if (general['hostname'] is! String) 'hostname': network['hostname'],
      if (general['sysloglevel'] is! String)
        'sysloglevel': advanced['sysloglevel'],
    };
  }

  /// Reads the timezone choices the server exposes via
  /// `system.general.timezone_choices`.
  ///
  /// SCALE 25.10 returns an object mapping identifiers to labels. Older
  /// middleware fixtures and some compatible releases return a list of
  /// `[identifier, label]` pairs (or bare identifiers), so accept both wire
  /// shapes and normalize them at this boundary.
  Future<List<({String id, String label})>> getSystemTimezoneChoices() async {
    const method = 'system.general.timezone_choices';
    final result = await _client.call(method);
    final choices = <({String id, String label})>[];
    if (result is Map) {
      for (final entry in result.entries) {
        final id = entry.key;
        final label = entry.value;
        if (id is String && label is String) {
          choices.add((id: id, label: label));
        }
      }
    } else if (result is List) {
      for (final entry in result) {
        if (entry is List && entry.length >= 2) {
          final id = entry[0];
          final label = entry[1];
          if (id is String && label is String) {
            choices.add((id: id, label: label));
          }
        } else if (entry is Map) {
          final id = entry['id'] ?? entry['value'];
          final label = entry['label'] ?? entry['name'] ?? id;
          if (id is String && label is String) {
            choices.add((id: id, label: label));
          }
        } else if (entry is String) {
          choices.add((id: entry, label: entry));
        }
      }
    } else {
      throw const TrueNasRpcException(
        code: -1,
        message: 'system.general.timezone_choices returned invalid data.',
      );
    }
    return List.unmodifiable(choices);
  }

  /// Routes each field to the namespace that owns it in TrueNAS 25.10.
  Future<OperationReceipt> updateSystemGeneralConfig({
    required SystemGeneralConfiguration next,
    required SystemGeneralConfiguration baseline,
  }) {
    final calls = <Future<Object?>>[];
    final methods = <String>[];
    if (next.hostname != baseline.hostname) {
      methods.add('network.configuration.update');
      calls.add(
        _client.call(
          'network.configuration.update',
          params: [
            {'hostname': next.hostname},
          ],
        ),
      );
    }
    if (next.timezone != baseline.timezone) {
      methods.add('system.general.update');
      calls.add(
        _client.call(
          'system.general.update',
          params: [
            {'timezone': next.timezone},
          ],
        ),
      );
    }
    if (next.syslogLevel != baseline.syslogLevel) {
      methods.add('system.advanced.update');
      calls.add(
        _client.call(
          'system.advanced.update',
          params: [
            {'sysloglevel': next.syslogLevel.apiName},
          ],
        ),
      );
    }
    return Future.wait(calls).then(
      (results) => OperationReceipt(method: methods.join('+'), result: results),
    );
  }

  Future<OperationReceipt> controlService({
    required String service,
    required ServiceVerb verb,
  }) async {
    const method = 'service.control';
    final result = await _client.call(
      method,
      params: [
        verb.apiValue,
        service,
        {'silent': false, 'ha_propagate': false, 'timeout': 120},
      ],
    );
    return OperationReceipt.fromResult(method, result);
  }

  /// Persists whether a service starts automatically on boot via
  /// `service.update`.
  ///
  /// `service.control` only changes the current run state and is forgotten on
  /// reboot, so start-on-boot is a separate mutation. The service is addressed
  /// by its numeric id because `service.update` takes the record id rather than
  /// the service name.
  Future<OperationReceipt> setServiceStartOnBoot(
    int serviceId, {
    required bool enabled,
  }) => _mutate('service.update', [
    serviceId,
    {'enable': enabled},
  ]);

  /// Selects the boot environment to start at the next boot via
  /// `boot.environment.activate`.
  ///
  /// This does not reboot: the change takes effect only on the next boot, and
  /// the caller states that consequence.
  Future<OperationReceipt> activateBootEnvironment(String id) =>
      _mutate('boot.environment.activate', [
        {'id': id},
      ]);

  /// Marks a boot environment to survive automatic pruning, or releases it,
  /// via `boot.environment.keep`.
  Future<OperationReceipt> setBootEnvironmentKept(
    String id, {
    required bool keep,
  }) => _mutate('boot.environment.keep', [
    {'id': id, 'value': keep},
  ]);

  /// Permanently removes a boot environment via `boot.environment.destroy`.
  /// The active and next-boot environments must never be passed here; the
  /// caller enforces that.
  Future<OperationReceipt> destroyBootEnvironment(String id) =>
      _mutate('boot.environment.destroy', [
        {'id': id},
      ]);

  Future<OperationReceipt> setAlertDismissed(
    String uuid, {
    required bool dismissed,
  }) async {
    final method = dismissed ? 'alert.dismiss' : 'alert.restore';
    final result = await _client.call(method, params: [uuid]);
    return OperationReceipt.fromResult(method, result);
  }

  /// Updates a local user account. Password and privilege changes are
  /// intentionally excluded; those belong to a separate credential flow.
  Future<OperationReceipt> updateUser(
    int userId,
    Map<String, Object?> payload,
  ) => _mutate('user.update', [userId, payload]);

  /// Sets a new password for a local user through `user.update`. This is a
  /// high-risk credential change: callers must confirm it explicitly and the
  /// password is sent only to the server, never stored or logged.
  Future<OperationReceipt> changeUserPassword(
    int userId, {
    required String password,
  }) => _mutate('user.update', [
    userId,
    {'password': password},
  ]);

  /// Updates a local group, including its membership list.
  Future<OperationReceipt> updateGroup(
    int groupId,
    Map<String, Object?> payload,
  ) => _mutate('group.update', [groupId, payload]);

  Future<OperationReceipt> createUser(Map<String, Object?> payload) =>
      _mutate('user.create', [payload]);

  /// Deletes a local user. [deletePrimaryGroup] also removes the group that
  /// was created alongside the account, when it has no other members.
  Future<OperationReceipt> deleteUser(
    int userId, {
    required bool deletePrimaryGroup,
  }) => _mutate('user.delete', [
    userId,
    {'delete_group': deletePrimaryGroup},
  ]);

  Future<OperationReceipt> createGroup(Map<String, Object?> payload) =>
      _mutate('group.create', [payload]);

  /// Deletes a local group. [deleteUsers] also removes users whose primary
  /// group this is, so it is kept off by default.
  Future<OperationReceipt> deleteGroup(
    int groupId, {
    required bool deleteUsers,
  }) => _mutate('group.delete', [
    groupId,
    {'delete_users': deleteUsers},
  ]);

  /// Aborts a running TrueNAS job. Only call this for jobs the server reports
  /// as abortable; middleware rejects the request for anything else.
  Future<OperationReceipt> abortJob(int jobId) =>
      _mutate('core.job_abort', [jobId]);

  Future<OperationReceipt> runReplication(int taskId) =>
      _runTask('replication.run', [taskId]);

  Future<OperationReceipt> runCloudSync(int taskId, {required bool dryRun}) =>
      _runTask('cloudsync.sync', [
        taskId,
        {'dry_run': dryRun},
      ]);

  Future<OperationReceipt> runRsync(int taskId) =>
      _runTask('rsynctask.run', [taskId]);

  Future<OperationReceipt> startPoolScrub(String poolName) =>
      _runTask('pool.scrub.scrub', [poolName, 'START']);

  /// Pauses or stops a running scrub. Stopping discards scrub progress, so the
  /// caller must confirm it.
  Future<OperationReceipt> controlPoolScrub(
    String poolName,
    ScrubControlAction action,
  ) => _runTask('pool.scrub.scrub', [poolName, action.apiValue]);

  /// Exports a pool. With [destroyData] the underlying disks are wiped, which
  /// is the single most destructive action TrueDock exposes.
  Future<OperationReceipt> exportPool(
    int poolId, {
    required bool destroyData,
    required bool takeSnapshotsOffline,
  }) => _mutate('pool.export', [
    poolId,
    {
      'cascade': takeSnapshotsOffline,
      'restart_services': false,
      'destroy': destroyData,
    },
  ]);

  /// Takes a pool member disk offline. The pool runs degraded until it is
  /// brought back online or replaced.
  Future<OperationReceipt> offlinePoolDisk(int poolId, String label) =>
      _mutate('pool.offline', [
        poolId,
        {'label': label},
      ]);

  /// Brings a previously offlined pool member back online.
  Future<OperationReceipt> onlinePoolDisk(int poolId, String label) =>
      _mutate('pool.online', [
        poolId,
        {'label': label},
      ]);

  /// Attaches [disk] to an existing mirror or stripe vdev identified by
  /// [targetVdev]. TrueNAS runs this as a job; attaching to a mirror starts a
  /// resilver that the caller must surface as progress.
  Future<OperationReceipt> attachPoolDisk({
    required int poolId,
    required String targetVdev,
    required String disk,
    bool allowDuplicateSerials = false,
  }) => _runTask('pool.attach', [
    poolId,
    {
      'target_vdev': targetVdev,
      'new_disk': disk,
      'allow_duplicate_serials': allowDuplicateSerials,
    },
  ]);

  /// Replaces the pool member identified by [label] with [disk]. TrueNAS runs
  /// this as a job; the old disk is removed from the pool once the resilver
  /// finishes and is safe to remove.
  Future<OperationReceipt> replacePoolDisk({
    required int poolId,
    required String label,
    required String disk,
    bool force = false,
    bool preserveSettings = true,
    bool preserveDescription = true,
  }) => _runTask('pool.replace', [
    poolId,
    {
      'label': label,
      'disk': disk,
      'force': force,
      'preserve_settings': preserveSettings,
      'preserve_description': preserveDescription,
    },
  ]);

  /// Creates a new storage pool via `pool.create`. The configuration carries
  /// the pool name, the topology (data vdevs and optional cache/log/spares/
  /// dedup/special), and options like encryption, dedup, and checksum.
  /// TrueNAS runs this as a job.
  ///
  /// Auto-TRIM is deliberately not part of that payload: the 25.10 schema puts
  /// `autotrim` on `pool.update`, not `pool.create`, so it is applied as a
  /// follow-up once the pool exists. A failure to apply it is reported, but it
  /// does not invalidate the pool that was just created.
  Future<OperationReceipt> createPool(PoolConfiguration configuration) async {
    final receipt = await _runTask('pool.create', [configuration.toApiJson()]);
    if (!configuration.autoTrim) {
      // The server default is ON, so only an opt-out needs a second call.
      final pools = await _client.call(
        'pool.query',
        params: [
          [
            ['name', '=', configuration.name],
          ],
        ],
      );
      if (pools is List && pools.isNotEmpty) {
        final pool = pools.first;
        if (pool is Map && pool['id'] != null) {
          await _client.call(
            'pool.update',
            params: [
              pool['id'],
              {'autotrim': 'OFF'},
            ],
          );
        }
      }
    }
    return receipt;
  }

  /// Reads the state of staged network changes so TrueDock can show what a
  /// commit would apply before the user confirms it.
  ///
  /// 25.10 has no single "commit node" method. It exposes the three separate
  /// reads combined here: whether anything is staged at all, how many seconds
  /// remain on an in-flight check-in window, and which
  /// `network.configuration` fields the next check-in will wipe. The last one
  /// matters most: checking in can clear the gateway or a nameserver, which is
  /// exactly the kind of change that severs the session TrueDock is using.
  Future<PendingNetworkChanges> getPendingNetworkChanges() async {
    final hasPending = await _client.call('interface.has_pending_changes');
    if (hasPending is! bool) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'interface.has_pending_changes returned invalid data.',
      );
    }
    final waiting = await _client.call('interface.checkin_waiting');
    final removed = await _client.call(
      'interface.network_config_to_be_removed',
    );
    return PendingNetworkChanges(
      hasPendingChanges: hasPending,
      checkInSecondsRemaining: waiting is int ? waiting : null,
      fieldsClearedOnCheckIn: removed is List
          ? removed.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  /// Queries the audit log.
  ///
  /// `audit.query` nests its filters under hyphenated keys inside a single
  /// object (`query-filters`, `query-options`) rather than taking the positional
  /// `[filters, options]` pair every other query method uses, so the payload is
  /// built by [AuditQuery] instead of the shared helper.
  Future<List<AuditEntry>> getAuditEntries(AuditQuery query) async {
    const method = 'audit.query';
    final result = await _client.call(method, params: [query.toApiJson()]);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'audit.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(AuditEntry.fromJson)
        .toList(growable: false);
  }

  /// Reads audit retention and the space the audit databases consume.
  Future<AuditConfiguration> getAuditConfiguration() async {
    const method = 'audit.config';
    final result = await _client.call(method);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'audit.config returned invalid data.',
      );
    }
    return AuditConfiguration.fromJson(result);
  }

  /// Updates audit retention. Shortening it discards history the server has
  /// already recorded, so the caller confirms first.
  Future<OperationReceipt> updateAuditConfiguration(
    AuditConfigurationEdit edit,
  ) => _mutate('audit.update', [edit.toApiJson()]);

  /// Prepares a configuration backup download.
  ///
  /// `config.save` writes to a job pipe, which a JSON-RPC client cannot read —
  /// calling it directly answers `Pipe 'output' is not open`. `core.download`
  /// wraps it and returns a job id plus a tokenized HTTPS path, which is the
  /// only way TrueDock can reach the archive.
  ///
  /// `buffered: true` is sent because the unbuffered mode blocks the job until a
  /// client starts reading or 60 seconds elapse; the app hands the URL to the
  /// platform, so there is no guarantee anything reads it inside that window.
  Future<ConfigBackupDownload> prepareConfigBackup({
    required ConfigBackupOptions options,
    required String filename,
  }) async {
    final result = await _client.call(
      'core.download',
      params: [
        'config.save',
        [options.toApiJson()],
        filename,
        true,
      ],
    );
    try {
      return ConfigBackupDownload.fromApi(result, filename: filename);
    } on FormatException catch (error) {
      throw TrueNasRpcException(code: -1, message: error.message);
    }
  }

  /// Resets the configuration to defaults via `config.reset`.
  ///
  /// Irreversible and total: shares, users, tasks, and network settings all
  /// revert. `reboot` is sent explicitly rather than left to the server's
  /// default of true, so the caller decides whether the session ends now or the
  /// reset applies on the next restart.
  Future<OperationReceipt> resetConfiguration({required bool reboot}) =>
      _mutate('config.reset', [
        {'reboot': reboot},
      ]);

  /// Lists privileges via `privilege.query`.
  Future<List<Privilege>> getPrivileges() async {
    const method = 'privilege.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'privilege.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(Privilege.fromJson)
        .toList(growable: false);
  }

  /// Lists the roles a privilege can grant, via `privilege.roles`.
  ///
  /// Roles compose — `ACCOUNT_WRITE` includes `ACCOUNT_READ` — so the catalog is
  /// needed to show the effective grant rather than only what was selected.
  Future<List<PrivilegeRole>> getPrivilegeRoles() async {
    const method = 'privilege.roles';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'privilege.roles returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(PrivilegeRole.fromJson)
        .toList(growable: false);
  }

  Future<OperationReceipt> createPrivilege(
    PrivilegeConfiguration configuration,
  ) => _mutate('privilege.create', [configuration.toApiJson()]);

  /// Updates a privilege. Editing a built-in one is how an administrator locks
  /// themselves out, so the caller confirms first.
  Future<OperationReceipt> updatePrivilege(
    int privilegeId,
    PrivilegeConfiguration configuration,
  ) => _mutate('privilege.update', [privilegeId, configuration.toApiJson()]);

  Future<OperationReceipt> deletePrivilege(int privilegeId) =>
      _mutate('privilege.delete', [privilegeId]);

  /// Lists cloud backup tasks via `cloud_backup.query`.
  Future<List<CloudBackupTask>> getCloudBackupTasks() async {
    const method = 'cloud_backup.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'cloud_backup.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(CloudBackupTask.fromJson)
        .toList(growable: false);
  }

  Future<OperationReceipt> createCloudBackupTask(
    CloudBackupConfiguration configuration,
    CloudCredential? credential,
  ) => _mutate('cloud_backup.create', [
    configuration.toApiJson(credential: credential),
  ]);

  /// Updates a cloud backup task.
  ///
  /// [storedPassword] stands in when the editor left the repository password
  /// blank, which means "unchanged": the server requires `password`, so omitting
  /// it would fail the call, and sending a blank would break the repository.
  Future<OperationReceipt> updateCloudBackupTask(
    int taskId,
    CloudBackupConfiguration configuration,
    CloudCredential? credential, {
    String? storedPassword,
  }) => _mutate('cloud_backup.update', [
    taskId,
    configuration.toApiJson(
      credential: credential,
      storedPassword: storedPassword,
    ),
  ]);

  Future<OperationReceipt> deleteCloudBackupTask(int taskId) =>
      _mutate('cloud_backup.delete', [taskId]);

  /// Runs a cloud backup now. [dryRun] simulates without writing.
  Future<OperationReceipt> runCloudBackup(int taskId, {bool dryRun = false}) =>
      _runTask('cloud_backup.sync', [
        taskId,
        {'dry_run': dryRun},
      ]);

  /// Aborts the running backup for a task.
  Future<OperationReceipt> abortCloudBackup(int taskId) =>
      _mutate('cloud_backup.abort', [taskId]);

  /// Lists the snapshots held in a task's repository.
  Future<List<CloudBackupSnapshot>> getCloudBackupSnapshots(int taskId) async {
    const method = 'cloud_backup.list_snapshots';
    final result = await _client.call(method, params: [taskId]);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'cloud_backup.list_snapshots returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(CloudBackupSnapshot.fromJson)
        .toList(growable: false);
  }

  /// Restores a snapshot into [destinationPath].
  ///
  /// All four leading arguments are positional and required, including
  /// `subfolder`; the whole snapshot is `/`, not an empty string.
  Future<OperationReceipt> restoreCloudBackup({
    required int taskId,
    required String snapshotId,
    required String subfolder,
    required String destinationPath,
  }) => _runTask('cloud_backup.restore', [
    taskId,
    snapshotId,
    subfolder,
    destinationPath,
  ]);

  /// Deletes one snapshot from a task's repository. Irreversible.
  Future<OperationReceipt> deleteCloudBackupSnapshot(
    int taskId,
    String snapshotId,
  ) => _mutate('cloud_backup.delete_snapshot', [taskId, snapshotId]);

  /// Reads every alert class and its effective policy.
  ///
  /// Two calls, because neither is sufficient alone: `alert.list_categories` is
  /// the catalog of classes with their server defaults, while
  /// `alertclasses.config` returns *only* the classes an administrator
  /// overrode. Showing just the overrides would render an empty list on a stock
  /// server and hide everything that could be changed.
  Future<AlertClassConfiguration> getAlertClasses() async {
    final categories = await _client.call('alert.list_categories');
    if (categories is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'alert.list_categories returned invalid data.',
      );
    }
    final config = await _client.call('alertclasses.config');
    final classes = config is Map<String, dynamic> ? config['classes'] : null;
    return AlertClassConfiguration.merge(
      definitions: AlertClassConfiguration.parseCategories(categories),
      overrides: classes is Map
          ? {for (final e in classes.entries) '${e.key}': e.value}
          : const {},
    );
  }

  /// Persists alert class policies via `alertclasses.update`.
  ///
  /// The method replaces the whole `classes` map, so the caller sends every
  /// override that should survive; sending one class would silently reset the
  /// rest.
  Future<OperationReceipt> updateAlertClasses(AlertClassEdit edit) =>
      _mutate('alertclasses.update', [edit.toApiJson()]);

  /// Lists alert destinations via `alertservice.query`.
  Future<List<AlertServiceEntry>> getAlertServices() async {
    const method = 'alertservice.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'alertservice.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(AlertServiceEntry.fromJson)
        .toList(growable: false);
  }

  Future<OperationReceipt> createAlertService(
    AlertServiceConfiguration configuration,
  ) => _mutate('alertservice.create', [configuration.toApiJson()]);

  /// Updates an alert destination.
  ///
  /// [storedSecrets] are the credential values the server already holds, taken
  /// from the queried entry. A blank credential field in the editor means
  /// "unchanged", and the stored value is substituted rather than omitted:
  /// `alertservice.update` rejects the call outright when a variant's required
  /// secret is missing.
  Future<OperationReceipt> updateAlertService(
    int id,
    AlertServiceConfiguration configuration, {
    Map<String, Object?> storedSecrets = const {},
  }) => _mutate('alertservice.update', [
    id,
    configuration.toApiJson(storedSecrets: storedSecrets),
  ]);

  Future<OperationReceipt> deleteAlertService(int id) =>
      _mutate('alertservice.delete', [id]);

  /// Sends a test alert through a destination via `alertservice.test`.
  ///
  /// Takes the full configuration rather than an id, so a destination can be
  /// proven before it is saved — which matters because a wrong webhook or token
  /// only fails at delivery time.
  Future<OperationReceipt> testAlertService(
    AlertServiceConfiguration configuration,
  ) => _mutate('alertservice.test', [configuration.toApiJson()]);

  /// Reads a service's configuration via `<service>.config`.
  ///
  /// Returned as the raw object rather than a typed model per service, because
  /// TrueDock edits a documented subset and updates are partial: reshaping the
  /// response would risk dropping fields it does not surface.
  Future<ServiceConfiguration> getServiceConfiguration(
    ConfigurableService service,
  ) async {
    final result = await _client.call(service.configMethod);
    if (result is! Map<String, dynamic>) {
      throw TrueNasRpcException(
        code: -1,
        message: '${service.configMethod} returned invalid data.',
      );
    }
    return ServiceConfiguration(service: service, values: result);
  }

  /// Applies a partial service configuration edit via `<service>.update`.
  ///
  /// Every one of these methods accepts a partial object, so only changed fields
  /// are sent and anything TrueDock does not surface keeps its server value.
  Future<OperationReceipt> updateServiceConfiguration(
    ServiceConfigurationEdit edit,
  ) => _mutate(edit.service.updateMethod, [edit.toApiJson()]);

  /// Reads the outgoing mail settings via `mail.config`.
  ///
  /// The response carries no SMTP password, so [MailConfiguration] has no field
  /// for one: there is nothing for a log or a state dump to leak.
  Future<MailConfiguration> getMailConfiguration() async {
    const method = 'mail.config';
    final result = await _client.call(method);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'mail.config returned invalid data.',
      );
    }
    return MailConfiguration.fromJson(result);
  }

  /// Applies a mail settings edit via `mail.update`.
  ///
  /// Only changed fields are sent, plus `fromemail`: the server rejects the call
  /// with "this field is required" when `fromemail` is absent and not already
  /// stored, so a first-time configuration cannot be a pure partial update. The
  /// password is still only sent when the user typed one, because `mail.config`
  /// never returns it and resending the whole object would blank it.
  Future<OperationReceipt> updateMailConfiguration(
    MailConfigurationEdit edit, {
    required MailConfiguration current,
  }) => _mutate('mail.update', [edit.toApiJsonFor(current)]);

  /// Sends a test message via `mail.send`.
  ///
  /// Proves the settings actually work, which validation cannot: a wrong
  /// password or a blocked port only surfaces on a real send.
  Future<OperationReceipt> sendTestMail({
    required String subject,
    required String body,
  }) => _runTask('mail.send', [
    {'subject': subject, 'text': body},
  ]);

  /// The address TrueNAS treats as the local administrator's, used as the
  /// default test recipient.
  Future<String?> getLocalAdministratorEmail() async {
    final result = await _client.call('mail.local_administrator_email');
    return result is String && result.isNotEmpty ? result : null;
  }

  /// Lists scheduled commands via `cronjob.query`.
  Future<List<CronJob>> getCronJobs() async {
    const method = 'cronjob.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'cronjob.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(CronJob.fromJson)
        .toList(growable: false);
  }

  Future<OperationReceipt> createCronJob(CronJobConfiguration configuration) =>
      _mutate('cronjob.create', [configuration.toApiJson()]);

  Future<OperationReceipt> updateCronJob(
    int jobId,
    CronJobConfiguration configuration,
  ) => _mutate('cronjob.update', [jobId, configuration.toApiJson()]);

  Future<OperationReceipt> deleteCronJob(int jobId) =>
      _mutate('cronjob.delete', [jobId]);

  /// Runs a cron job now via `cronjob.run`.
  ///
  /// `skip_disabled` is sent as false so a disabled job the user explicitly
  /// asked to run actually runs; the server would otherwise silently do nothing
  /// and TrueDock would report success.
  Future<OperationReceipt> runCronJob(int jobId) =>
      _runTask('cronjob.run', [jobId, false]);

  Future<List<Tunable>> getTunables() async {
    const method = 'tunable.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'tunable.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(Tunable.fromJson)
        .toList(growable: false);
  }

  /// Creation is a TrueNAS job because ZFS tunables can rebuild initramfs.
  Future<OperationReceipt> createTunable(TunableConfiguration configuration) =>
      _runTask('tunable.create', [configuration.toCreateApiJson()]);

  Future<OperationReceipt> updateTunable(
    int tunableId,
    TunableConfiguration configuration,
  ) => _mutate('tunable.update', [tunableId, configuration.toUpdateApiJson()]);

  Future<OperationReceipt> deleteTunable(int tunableId) =>
      _mutate('tunable.delete', [tunableId]);

  /// Reads the global network settings via `network.configuration.config`.
  ///
  /// The response separates configured values from the ones actually in effect
  /// (its nested `state` object), which matters on DHCP: the configured gateway
  /// and nameservers are empty strings while `state` holds the leased values.
  Future<NetworkConfiguration> getNetworkConfiguration() async {
    const method = 'network.configuration.config';
    final result = await _client.call(method);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'network.configuration.config returned invalid data.',
      );
    }
    return NetworkConfiguration.fromJson(result);
  }

  /// Applies a global network edit via `network.configuration.update`.
  ///
  /// Only changed fields are sent: the method merges a partial object, and
  /// resending everything would rewrite `activity` and `service_announcement`,
  /// which TrueDock does not surface. Changing a gateway or nameserver can
  /// sever the session, so the caller confirms first.
  Future<OperationReceipt> updateNetworkConfiguration(
    NetworkConfigurationEdit edit,
  ) => _mutate('network.configuration.update', [edit.toApiJson()]);

  /// Reads the live interface/route/DNS summary via `network.general.summary`.
  ///
  /// This is the authoritative view of what the server is using right now,
  /// independent of what is configured.
  Future<NetworkSummary> getNetworkSummary() async {
    const method = 'network.general.summary';
    final result = await _client.call(method);
    if (result is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'network.general.summary returned invalid data.',
      );
    }
    return NetworkSummary.fromJson(result);
  }

  /// Commits pending network changes. TrueNAS starts a rollback countdown, so
  /// the caller must check in through
  /// [checkInInterfaceChanges] before the timer elapses or the server reverts
  /// everything. Network changes can sever the TrueDock session, so the caller
  /// must confirm before invoking this method.
  ///
  /// `rollback` and `checkin_timeout` are sent explicitly rather than left to
  /// the server's defaults, because both defaults are the safety mechanism
  /// this sheet depends on and a future server release changing them silently
  /// would change TrueDock's behaviour.
  Future<OperationReceipt> commitInterfaceChanges({
    int checkInTimeoutSeconds = 60,
  }) => _runTask('interface.commit', [
    {'rollback': true, 'checkin_timeout': checkInTimeoutSeconds},
  ]);

  /// Cancels the rollback countdown started by [commitInterfaceChanges]
  /// without locking the changes in. Exposed for completeness; the sheet
  /// prefers [checkInInterfaceChanges] or [rollbackInterfaceChanges].
  Future<OperationReceipt> cancelInterfaceRollback() =>
      _runTask('interface.cancel_rollback', []);

  /// Checks in pending network changes, locking them permanently. Call this
  /// only after the connection survives a [commitInterfaceChanges] job; a
  /// failed or skipped check-in rolls every staged change back.
  Future<OperationReceipt> checkInInterfaceChanges() =>
      _runTask('interface.checkin', []);

  /// Rolls back pending network changes that have not been checked in. Use
  /// this when a commit broke the session, the verification window elapsed,
  /// or the user abandoned the change.
  Future<OperationReceipt> rollbackInterfaceChanges() =>
      _runTask('interface.rollback', []);

  /// Creates a static route. The route becomes active only after the pending
  /// network changes are committed and checked in.
  Future<OperationReceipt> createStaticRoute(
    StaticRouteConfiguration configuration,
  ) => _mutate('staticroute.create', [configuration.toApiJson()]);

  /// Updates an existing static route. Like create, the change is staged until
  /// the network commit/checkin workflow runs.
  Future<OperationReceipt> updateStaticRoute(
    int routeId,
    StaticRouteConfiguration configuration,
  ) => _mutate('staticroute.update', [routeId, configuration.toApiJson()]);

  /// Deletes a static route definition. Pending routes require a commit
  /// before they actually disappear from the live routing table.
  Future<OperationReceipt> deleteStaticRoute(int routeId) =>
      _mutate('staticroute.delete', [routeId]);

  /// Reads the full configuration of a single interface through
  /// `interface.query` filtered by id, so the editor can seed aliases, MTU,
  /// and the DHCP flag from the configured (not merely the live) values.
  Future<Map<String, dynamic>> getInterfaceConfig(String interfaceId) async {
    const method = 'interface.query';
    final result = await _client.call(
      method,
      params: [
        [
          ['id', '=', interfaceId],
        ],
      ],
    );
    if (result is! List<Object?> || result.isEmpty) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'interface.query returned invalid data.',
      );
    }
    final entry = result.first;
    if (entry is! Map<String, dynamic>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'interface.query returned invalid data.',
      );
    }
    return entry;
  }

  /// Stages an interface configuration change via `interface.update`.
  ///
  /// The change is not live until `interface.commit` runs, and the server
  /// reverts it unless `interface.checkin` follows inside the verification
  /// window. Callers must drive that workflow after this call succeeds.
  Future<OperationReceipt> updateInterface(
    InterfaceConfiguration configuration,
  ) => _mutate('interface.update', [
    configuration.id,
    configuration.toApiJson(),
  ]);

  /// Reads saved SSH connections via `keychaincredential.query`.
  ///
  /// Replication over `SSH`/`SSH+NETCAT` and rsync in `SSH` mode reference
  /// these by integer id. The query is filtered to `SSH_CREDENTIALS` so key
  /// pairs (`SSH_KEY_PAIR`) are not offered as connections, and no private
  /// key material is read into the client.
  Future<List<SshCredential>> getSshCredentials() async {
    const method = 'keychaincredential.query';
    final result = await _client.call(
      method,
      params: [
        [
          ['type', '=', 'SSH_CREDENTIALS'],
        ],
      ],
    );
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'keychaincredential.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(SshCredential.fromJson)
        .toList(growable: false);
  }

  /// Creates a replication task via `replication.create`.
  Future<OperationReceipt> createReplicationTask(
    ReplicationConfiguration configuration,
  ) => _mutate('replication.create', [configuration.toApiJson()]);

  /// Updates a replication task via `replication.update`. TrueNAS merges the
  /// supplied fields, and the editor sends the full configuration it manages.
  Future<OperationReceipt> updateReplicationTask(
    int taskId,
    ReplicationConfiguration configuration,
  ) => _mutate('replication.update', [taskId, configuration.toApiJson()]);

  /// Creates an rsync task via `rsynctask.create`.
  Future<OperationReceipt> createRsyncTask(RsyncConfiguration configuration) =>
      _mutate('rsynctask.create', [configuration.toApiJson()]);

  /// Updates an rsync task via `rsynctask.update`.
  Future<OperationReceipt> updateRsyncTask(
    int taskId,
    RsyncConfiguration configuration,
  ) => _mutate('rsynctask.update', [taskId, configuration.toApiJson()]);

  /// Reads the full configuration of a single replication task through
  /// `replication.query` filtered by id, so the editor can seed fields the
  /// list view does not carry.
  Future<Map<String, dynamic>> getReplicationTaskConfig(int taskId) =>
      _queryById('replication.query', taskId);

  /// Reads the full configuration of a single rsync task.
  Future<Map<String, dynamic>> getRsyncTaskConfig(int taskId) =>
      _queryById('rsynctask.query', taskId);

  /// Reads saved cloud credentials via `cloudsync.credentials.query`.
  ///
  /// Cloud sync tasks reference these by integer id. Only the id, name, and
  /// provider type are modelled; provider secrets are never read into the
  /// client.
  Future<List<CloudCredential>> getCloudCredentials() async {
    const method = 'cloudsync.credentials.query';
    final result = await _client.call(method);
    if (result is! List<Object?>) {
      throw const TrueNasRpcException(
        code: -1,
        message: 'cloudsync.credentials.query returned invalid data.',
      );
    }
    return result
        .whereType<Map<String, dynamic>>()
        .map(CloudCredential.fromJson)
        .toList(growable: false);
  }

  /// Reads the full configuration of a single cloud sync task, so the editor
  /// can preserve attributes and fields it does not surface.
  Future<Map<String, dynamic>> getCloudSyncTaskConfig(int taskId) =>
      _queryById('cloudsync.query', taskId);

  /// Creates a cloud sync task via `cloudsync.create`.
  ///
  /// [credential] supplies the provider type, which decides whether the
  /// `attributes` object carries a bucket. Encryption secrets travel only in
  /// this call and are never persisted or logged by TrueDock.
  Future<OperationReceipt> createCloudSyncTask(
    CloudSyncConfiguration configuration,
    CloudCredential? credential,
  ) => _mutate('cloudsync.create', [configuration.toApiJson(credential)]);

  /// Updates a cloud sync task via `cloudsync.update`.
  Future<OperationReceipt> updateCloudSyncTask(
    int taskId,
    CloudSyncConfiguration configuration,
    CloudCredential? credential,
  ) => _mutate('cloudsync.update', [
    taskId,
    configuration.toApiJson(credential),
  ]);

  Future<Map<String, dynamic>> _queryById(String method, int id) async {
    final result = await _client.call(
      method,
      params: [
        [
          ['id', '=', id],
        ],
      ],
    );
    if (result is! List<Object?> || result.isEmpty) {
      throw TrueNasRpcException(
        code: -1,
        message: '$method returned invalid data.',
      );
    }
    final entry = result.first;
    if (entry is! Map<String, dynamic>) {
      throw TrueNasRpcException(
        code: -1,
        message: '$method returned invalid data.',
      );
    }
    return entry;
  }

  Future<OperationReceipt> _runTask(String method, List<Object?> params) async {
    final result = await _client.call(method, params: params);
    return OperationReceipt.fromResult(method, result);
  }
}
