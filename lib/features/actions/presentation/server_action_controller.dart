import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../../core/api/truenas_json_rpc_client.dart';
import '../../../core/logging/redacted_logger.dart';
import '../../connection/domain/server_profile.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../apps/domain/app_configuration.dart';
import '../../apps/domain/app_installation.dart';
import '../../apps/domain/app_upgrade.dart';
import '../../data_protection/domain/snapshot_task_configuration.dart';
import '../../storage/domain/dataset_configuration.dart';
import '../../storage/domain/dataset_quota.dart';
import '../../storage/domain/iscsi_configuration.dart';
import '../../storage/domain/iscsi_extent_configuration.dart';
import '../../storage/domain/iscsi_target_configuration.dart';
import '../../storage/domain/iscsi_target_extent_configuration.dart';
import '../../system/domain/vm_configuration.dart';
import '../../system/domain/vm_device.dart';
import '../../system/domain/container_configuration.dart';
import '../../system/domain/system_general_configuration.dart';
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
import '../../storage/domain/pool_configuration.dart';
import '../../storage/domain/nfs_share_configuration.dart';
import '../../storage/domain/smb_acl_configuration.dart';
import '../../storage/domain/dataset_acl.dart';
import '../../storage/domain/smb_share_configuration.dart';
import '../../system/presentation/system_resources_provider.dart';
import '../data/server_actions_repository.dart';

class ServerActionState {
  const ServerActionState({this.busyKeys = const {}, this.errorMessage});

  final Set<String> busyKeys;
  final String? errorMessage;

  bool isBusy(String key) => busyKeys.contains(key);
}

final serverActionsRepositoryProvider = Provider<ServerActionsRepository>((
  ref,
) {
  return ServerActionsRepository(ref.watch(trueNasClientProvider));
});

final serverActionControllerProvider =
    StateNotifierProvider<ServerActionController, ServerActionState>((ref) {
      return ServerActionController(
        ref,
        ref.watch(serverActionsRepositoryProvider),
      );
    });

class ServerActionController extends StateNotifier<ServerActionState> {
  ServerActionController(this._ref, this._repository)
    : super(const ServerActionState());

  final Ref _ref;
  final ServerActionsRepository _repository;

  Future<OperationReceipt?> createDataset({
    required String fullName,
    required DatasetShareType shareType,
  }) {
    return _run(
      'dataset:$fullName',
      () => _repository.createDataset(fullName: fullName, shareType: shareType),
    );
  }

  /// Creates a zvol. Shares the busy key with dataset creation because both
  /// create the same named resource and only one can win.
  Future<OperationReceipt?> createVolume({
    required String fullName,
    required int sizeBytes,
    bool sparse = false,
    int? blockSizeBytes,
  }) {
    return _run(
      'dataset:$fullName',
      () => _repository.createVolume(
        fullName: fullName,
        sizeBytes: sizeBytes,
        sparse: sparse,
        blockSizeBytes: blockSizeBytes,
      ),
    );
  }

  Future<OperationReceipt?> createSnapshot({
    required String dataset,
    required String name,
    required bool recursive,
  }) {
    return _run(
      'snapshot:$dataset',
      () => _repository.createSnapshot(
        dataset: dataset,
        name: name,
        recursive: recursive,
      ),
    );
  }

  /// Reads per-account quotas for a dataset.
  ///
  /// Goes through `_execute` with `refreshAfter: false` because this is a read:
  /// invalidating the resource providers afterwards would refetch every section
  /// on the screen to no purpose.
  Future<List<DatasetQuota>?> loadDatasetQuotas(
    String datasetId,
    QuotaSubject subject,
  ) {
    return _execute(
      'dataset-quota-load:$datasetId:${subject.name}',
      () => _repository.getDatasetQuotas(datasetId, subject),
      refreshAfter: false,
    );
  }

  /// Applies quota changes to a dataset.
  ///
  /// The batch is passed through intact rather than split per account: the
  /// server applies it atomically, so a rejected entry leaves nothing half
  /// applied.
  Future<OperationReceipt?> setDatasetQuotas(
    String datasetId,
    List<DatasetQuotaEdit> edits,
  ) {
    return _run(
      'dataset-quota-set:$datasetId',
      () => _repository.setDatasetQuotas(datasetId, edits),
    );
  }

  Future<OperationReceipt?> updateDataset(
    String datasetId,
    Map<String, Object?> payload,
  ) {
    return _run(
      'dataset-update:$datasetId',
      () => _repository.updateDataset(datasetId, payload),
    );
  }

  Future<OperationReceipt?> renameDataset(
    String datasetId,
    DatasetRenameRequest request,
  ) {
    return _run(
      'dataset-rename:$datasetId',
      () => _repository.renameDataset(datasetId, request),
    );
  }

  Future<OperationReceipt?> deleteDataset(
    String datasetId, {
    required bool recursive,
    required bool force,
  }) {
    return _run(
      'dataset-delete:$datasetId',
      () => _repository.deleteDataset(
        datasetId,
        recursive: recursive,
        force: force,
      ),
    );
  }

  Future<OperationReceipt?> lockDataset(
    String datasetId, {
    required bool forceUmount,
  }) {
    return _run(
      'dataset-lock:$datasetId',
      () => _repository.lockDataset(datasetId, forceUmount: forceUmount),
    );
  }

  Future<OperationReceipt?> unlockDataset(
    String datasetId, {
    required String secret,
    required bool usePassphrase,
    required bool unlockChildren,
  }) {
    return _run(
      'dataset-unlock:$datasetId',
      () => _repository.unlockDataset(
        datasetId,
        secret: secret,
        usePassphrase: usePassphrase,
        unlockChildren: unlockChildren,
      ),
    );
  }

  Future<OperationReceipt?> deleteSnapshot(
    String snapshotId, {
    bool defer = false,
  }) {
    return _run(
      'snapshot-delete:$snapshotId',
      () => _repository.deleteSnapshot(snapshotId, defer: defer),
    );
  }

  Future<OperationReceipt?> rollbackSnapshot(
    String snapshotId, {
    required SnapshotRollbackMode mode,
    required bool force,
  }) {
    return _run(
      'snapshot-rollback:$snapshotId',
      () => _repository.rollbackSnapshot(snapshotId, mode: mode, force: force),
    );
  }

  Future<OperationReceipt?> cloneSnapshot(
    String snapshotId, {
    required String datasetDestination,
  }) {
    return _run(
      'snapshot-clone:$snapshotId',
      () => _repository.cloneSnapshot(
        snapshotId,
        datasetDestination: datasetDestination,
      ),
    );
  }

  /// Promotes a cloned dataset so it no longer depends on its origin snapshot.
  Future<OperationReceipt?> promoteDataset(String datasetId) {
    return _run(
      'dataset-promote:$datasetId',
      () => _repository.promoteDataset(datasetId),
    );
  }

  /// Revokes an API key. API keys live in the system resources provider, which
  /// the shared refresh does not touch.
  Future<OperationReceipt?> deleteApiKey(int keyId) {
    return _run('api-key-delete:$keyId', () async {
      final receipt = await _repository.deleteApiKey(keyId);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  /// Ends a single authenticated session.
  ///
  /// Refreshes the system resources afterwards so the list reflects the server
  /// rather than assuming the terminate took effect.
  Future<OperationReceipt?> terminateSession(String sessionId) {
    return _run('session-terminate:$sessionId', () async {
      final receipt = await _repository.terminateSession(sessionId);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  /// Ends every session but this one.
  Future<OperationReceipt?> terminateOtherSessions() {
    return _run('session-terminate-others', () async {
      final receipt = await _repository.terminateOtherSessions();
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> deleteSmbShare(int shareId) {
    return _run(
      'smb-share-delete:$shareId',
      () => _repository.deleteSmbShare(shareId),
    );
  }

  Future<OperationReceipt?> deleteNfsShare(int shareId) {
    return _run(
      'nfs-share-delete:$shareId',
      () => _repository.deleteNfsShare(shareId),
    );
  }

  Future<OperationReceipt?> deleteIscsiPortal(int portalId) => _run(
    'iscsi-portal-delete:$portalId',
    () => _repository.deleteIscsiPortal(portalId),
  );

  Future<OperationReceipt?> deleteIscsiInitiator(int initiatorId) => _run(
    'iscsi-initiator-delete:$initiatorId',
    () => _repository.deleteIscsiInitiator(initiatorId),
  );

  Future<OperationReceipt?> deleteIscsiTarget(
    int targetId, {
    required bool force,
  }) => _run(
    'iscsi-target-delete:$targetId',
    () => _repository.deleteIscsiTarget(targetId, force: force),
  );

  Future<OperationReceipt?> deleteIscsiExtent(
    int extentId, {
    required bool removeBackingFile,
    required bool force,
  }) => _run(
    'iscsi-extent-delete:$extentId',
    () => _repository.deleteIscsiExtent(
      extentId,
      removeBackingFile: removeBackingFile,
      force: force,
    ),
  );

  Future<OperationReceipt?> deleteIscsiTargetExtent(
    int associationId, {
    required bool force,
  }) => _run(
    'iscsi-targetextent-delete:$associationId',
    () => _repository.deleteIscsiTargetExtent(associationId, force: force),
  );

  Future<OperationReceipt?> setSnapshotHeld(
    String snapshotId, {
    required bool held,
  }) => _run(
    'snapshot-hold:$snapshotId',
    () => held
        ? _repository.holdSnapshot(snapshotId)
        : _repository.releaseSnapshot(snapshotId),
  );

  /// Restart, shutdown, and update all terminate the current session, so these
  /// intentionally skip the resource refresh a normal mutation performs.
  Future<OperationReceipt?> rebootServer({required String reason}) {
    return _execute(
      'system-reboot',
      () => _repository.rebootServer(reason: reason),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> shutdownServer({required String reason}) {
    return _execute(
      'system-shutdown',
      () => _repository.shutdownServer(reason: reason),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> runSystemUpdate({required bool rebootAfter}) {
    return _execute(
      'system-update',
      () => _repository.runSystemUpdate(rebootAfter: rebootAfter),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> changeSystemUpdateProfile(String profileId) {
    return _execute('system-update-profile', () async {
      final receipt = await _repository.changeSystemUpdateProfile(profileId);
      _ref.invalidate(systemUpdateProfilesProvider);
      _ref.invalidate(systemUpdateStatusProvider);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    }, refreshAfter: false);
  }

  Future<OperationReceipt?> uploadSystemUpdate({
    required ServerProfile profile,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) {
    return _execute(
      'system-update',
      () => _repository.uploadSystemUpdate(
        profile: profile,
        filePath: filePath,
        fileName: fileName,
        onProgress: onProgress,
      ),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> createSnapshotTask(
    CreateSnapshotTaskRequest request,
  ) {
    return _run(
      'snapshot-task:${request.dataset}',
      () => _repository.createSnapshotTask(request),
    );
  }

  Future<SnapshotRetentionImpact?> inspectSnapshotTaskUpdate(
    int taskId,
    CreateSnapshotTaskRequest request,
  ) {
    return _execute(
      'snapshot-task-impact:$taskId',
      () => _repository.inspectSnapshotTaskUpdate(taskId, request),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> updateSnapshotTask(
    int taskId,
    CreateSnapshotTaskRequest request,
  ) {
    return _run(
      'snapshot-task-update:$taskId',
      () => _repository.updateSnapshotTask(taskId, request),
    );
  }

  Future<OperationReceipt?> runSnapshotTask(int taskId) {
    return _run(
      'snapshot-task-run:$taskId',
      () => _repository.runSnapshotTask(taskId),
    );
  }

  Future<OperationReceipt?> deleteSnapshotTask(int taskId) {
    return _run(
      'snapshot-task-delete:$taskId',
      () => _repository.deleteSnapshotTask(taskId),
    );
  }

  Future<OperationReceipt?> deleteReplicationTask(int taskId) {
    return _run(
      'replication-delete:$taskId',
      () => _repository.deleteReplicationTask(taskId),
    );
  }

  Future<OperationReceipt?> deleteCloudSyncTask(int taskId) {
    return _run(
      'cloudsync-delete:$taskId',
      () => _repository.deleteCloudSyncTask(taskId),
    );
  }

  Future<OperationReceipt?> deleteRsyncTask(int taskId) {
    return _run(
      'rsync-delete:$taskId',
      () => _repository.deleteRsyncTask(taskId),
    );
  }

  Future<List<SmbSharePreset>?> loadSmbSharePresets() {
    return _execute(
      'smb-share-presets',
      _repository.getSmbSharePresets,
      refreshAfter: false,
    );
  }

  Future<bool> precheckSmbShareName(String name) async {
    final result = await _execute('smb-share-precheck:$name', () async {
      await _repository.precheckSmbShareName(name);
      return true;
    }, refreshAfter: false);
    return result == true;
  }

  Future<OperationReceipt?> createSmbShare(
    SmbShareConfiguration configuration,
  ) {
    return _run(
      'smb-share-create:${configuration.name}',
      () => _repository.createSmbShare(configuration),
    );
  }

  Future<OperationReceipt?> updateSmbShare(
    int shareId,
    SmbShareConfiguration configuration,
  ) {
    return _run(
      'smb-share-update:$shareId',
      () => _repository.updateSmbShare(shareId, configuration),
    );
  }

  /// Keyed by share *name*: `sharing.smb.getacl` identifies the share that
  /// way, not by id.
  Future<List<SmbAclEntry>?> loadSmbShareAcl(String shareName) {
    return _execute(
      'smb-share-acl:$shareName',
      () => _repository.getSmbShareAcl(shareName),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> setSmbShareAcl(
    String shareName,
    List<SmbAclEntry> acl,
  ) {
    return _run(
      'smb-share-acl-set:$shareName',
      () => _repository.setSmbShareAcl(shareName, acl),
    );
  }

  Future<DatasetAcl?> loadDatasetAcl(String datasetName) {
    return _execute(
      'dataset-acl:$datasetName',
      () => _repository.getDatasetAcl(datasetName),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> setDatasetAcl(
    DatasetAcl acl, {
    required bool recursive,
  }) {
    return _run(
      'dataset-acl-set:${acl.path}',
      () => _repository.setDatasetAcl(acl, recursive: recursive),
    );
  }

  Future<OperationReceipt?> setDatasetAclType(
    String datasetId,
    DatasetAclType type,
  ) {
    return _run(
      'dataset-acl-type:$datasetId',
      () => _repository.setDatasetAclType(datasetId, type),
    );
  }

  Future<OperationReceipt?> createNfsShare(
    NfsShareConfiguration configuration,
  ) {
    return _run(
      'nfs-share-create:${configuration.path}',
      () => _repository.createNfsShare(configuration),
    );
  }

  Future<OperationReceipt?> updateNfsShare(
    int shareId,
    NfsShareConfiguration configuration,
  ) {
    return _run(
      'nfs-share-update:$shareId',
      () => _repository.updateNfsShare(shareId, configuration),
    );
  }

  Future<List<String>?> loadIscsiPortalListenIpChoices() => _execute(
    'iscsi-portal-listen-ip-choices',
    _repository.getIscsiPortalListenIpChoices,
    refreshAfter: false,
  );

  Future<OperationReceipt?> createIscsiPortal(
    IscsiPortalConfiguration configuration,
  ) => _run(
    'iscsi-portal-create:${configuration.listenAddresses.join(',')}',
    () => _repository.createIscsiPortal(configuration),
  );

  Future<OperationReceipt?> updateIscsiPortal(
    int portalId,
    IscsiPortalConfiguration configuration,
  ) => _run(
    'iscsi-portal-update:$portalId',
    () => _repository.updateIscsiPortal(portalId, configuration),
  );

  Future<OperationReceipt?> createIscsiInitiator(
    IscsiInitiatorConfiguration configuration,
  ) => _run(
    'iscsi-initiator-create:${configuration.comment}',
    () => _repository.createIscsiInitiator(configuration),
  );

  Future<OperationReceipt?> updateIscsiInitiator(
    int initiatorId,
    IscsiInitiatorConfiguration configuration,
  ) => _run(
    'iscsi-initiator-update:$initiatorId',
    () => _repository.updateIscsiInitiator(initiatorId, configuration),
  );

  Future<bool> validateIscsiTargetName(String name, {int? existingId}) async {
    final result = await _execute('iscsi-target-name:$name', () async {
      await _repository.validateIscsiTargetName(name, existingId: existingId);
      return true;
    }, refreshAfter: false);
    return result == true;
  }

  Future<OperationReceipt?> createIscsiTarget(
    IscsiTargetConfiguration configuration,
  ) => _run(
    'iscsi-target-create:${configuration.name}',
    () => _repository.createIscsiTarget(configuration),
  );

  Future<OperationReceipt?> updateIscsiTarget(
    int targetId,
    IscsiTargetConfiguration configuration,
  ) => _run(
    'iscsi-target-update:$targetId',
    () => _repository.updateIscsiTarget(targetId, configuration),
  );

  Future<Map<String, String>?> loadIscsiExtentDiskChoices() => _execute(
    'iscsi-extent-disk-choices',
    _repository.getIscsiExtentDiskChoices,
    refreshAfter: false,
  );

  Future<OperationReceipt?> createIscsiExtent(
    IscsiExtentConfiguration configuration,
  ) => _run(
    'iscsi-extent-create:${configuration.name}',
    () => _repository.createIscsiExtent(configuration),
  );

  Future<OperationReceipt?> updateIscsiExtent(
    int extentId,
    IscsiExtentConfiguration configuration,
  ) => _run(
    'iscsi-extent-update:$extentId',
    () => _repository.updateIscsiExtent(extentId, configuration),
  );

  Future<OperationReceipt?> createIscsiTargetExtent(
    IscsiTargetExtentConfiguration configuration,
  ) => _run(
    'iscsi-targetextent-create:${configuration.targetId}:${configuration.extentId}',
    () => _repository.createIscsiTargetExtent(configuration),
  );

  Future<OperationReceipt?> updateIscsiTargetExtent(
    int associationId,
    IscsiTargetExtentConfiguration configuration,
  ) => _run(
    'iscsi-targetextent-update:$associationId',
    () => _repository.updateIscsiTargetExtent(associationId, configuration),
  );

  Future<OperationReceipt?> setAppRunning(
    String appId, {
    required bool running,
  }) {
    return _run(
      'app:$appId',
      () => running ? _repository.startApp(appId) : _repository.stopApp(appId),
    );
  }

  Future<AppUpgradeSummary?> loadAppUpgradeSummary(String appId) {
    return _execute(
      'app-upgrade:$appId',
      () => _repository.getAppUpgradeSummary(appId),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> upgradeApp(
    String appId, {
    required String version,
    required bool snapshotHostPaths,
  }) {
    return _run(
      'app-upgrade:$appId',
      () => _repository.upgradeApp(
        appId,
        version: version,
        snapshotHostPaths: snapshotHostPaths,
      ),
    );
  }

  Future<OperationReceipt?> installCatalogApp(AppInstallRequest request) {
    return _run(
      'app-install:${request.appName}',
      () => _repository.installCatalogApp(request),
    );
  }

  Future<OperationReceipt?> redeployApp(String appId) {
    return _run('app-redeploy:$appId', () => _repository.redeployApp(appId));
  }

  Future<OperationReceipt?> rollbackApp(
    String appId, {
    required String appVersion,
  }) {
    return _run(
      'app-rollback:$appId',
      () => _repository.rollbackApp(appId, appVersion: appVersion),
    );
  }

  /// Loads the versions the rollback picker can target.
  ///
  /// Uses `app.rollback_versions` rather than the upgrade summary: the summary
  /// raises an error once an app is on the newest version, which is exactly
  /// when a rollback is wanted.
  Future<List<String>?> loadAppRollbackVersions(String appId) {
    return _execute(
      'app-rollback:$appId',
      () => _repository.getAppRollbackVersions(appId),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> deleteApp(
    String appId, {
    required bool removeImages,
    required bool keepVolumes,
  }) {
    return _run(
      'app-delete:$appId',
      () => _repository.deleteApp(
        appId,
        removeImages: removeImages,
        keepVolumes: keepVolumes,
      ),
    );
  }

  Future<AppConfiguration?> loadAppConfig(InstalledApp app) {
    return _execute(
      'app-config:${app.id}',
      () => _repository.getAppConfig(app),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> updateApp(
    String appId, {
    Map<String, Object?>? values,
    Map<String, Object?>? customComposeConfig,
  }) {
    return _run(
      'app-update:$appId',
      () => _repository.updateApp(
        appId,
        values: values,
        customComposeConfig: customComposeConfig,
      ),
    );
  }

  Future<OperationReceipt?> controlVirtualMachine(int vmId, InstanceVerb verb) {
    return _run(
      'vm:$vmId',
      () => _repository.controlVirtualMachine(vmId, verb),
    );
  }

  Future<OperationReceipt?> controlContainer(int id, InstanceVerb verb) {
    return _run('container:$id', () => _repository.controlContainer(id, verb));
  }

  /// Controls an instance on 25.10's `virt.instance.*` surface. Keyed by name,
  /// which is what that API uses as an identifier.
  Future<OperationReceipt?> controlVirtInstance(
    String instanceId,
    InstanceVerb verb,
  ) {
    return _run(
      'virt:$instanceId',
      () => _repository.controlVirtInstance(instanceId, verb),
    );
  }

  /// Deletes an instance and its root disk. Irreversible; the caller must have
  /// taken a typed confirmation first.
  Future<OperationReceipt?> deleteVirtInstance(String instanceId) {
    return _run(
      'virt-delete:$instanceId',
      () => _repository.deleteVirtInstance(instanceId),
    );
  }

  Future<OperationReceipt?> updateVirtInstance(
    String instanceId,
    VirtInstanceConfiguration configuration,
  ) {
    return _run(
      'virt-update:$instanceId',
      () => _repository.updateVirtInstance(instanceId, configuration),
    );
  }

  Future<OperationReceipt?> createVirtInstance(
    VirtInstanceCreateConfiguration configuration,
  ) {
    return _run(
      'virt-create:${configuration.name}',
      () => _repository.createVirtInstance(configuration),
    );
  }

  /// Points the Instances platform at [pool]. Server-wide and disruptive, so
  /// the caller confirms first.
  Future<OperationReceipt?> updateVirtStoragePool(String pool) {
    return _run(
      'virt-pool:$pool',
      () => _repository.updateVirtStoragePool(pool),
    );
  }

  Future<List<VirtInstanceDevice>?> loadVirtInstanceDevices(String instanceId) {
    return _execute(
      'virt-devices:$instanceId',
      () => _repository.getVirtInstanceDevices(instanceId),
      refreshAfter: false,
    );
  }

  Future<VirtGlobalConfig?> loadVirtGlobalConfig() {
    return _execute(
      'virt-config',
      () => _repository.getVirtGlobalConfig(),
      refreshAfter: false,
    );
  }

  Future<Map<String, String>?> loadVirtPoolChoices() {
    return _execute(
      'virt-pools',
      () => _repository.getVirtPoolChoices(),
      refreshAfter: false,
    );
  }

  Future<List<VirtImageChoice>?> loadVirtImageChoices() {
    return _execute(
      'virt-images',
      () => _repository.getVirtImageChoices(),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> updateContainer(
    int containerId,
    ContainerConfiguration configuration,
  ) {
    return _run(
      'container-update:$containerId',
      () => _repository.updateContainer(containerId, configuration),
    );
  }

  Future<Map<String, String>?> getContainerDeviceChoices() async {
    try {
      return await _repository.getContainerDeviceChoices();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'container.device_choices failed: ${error.displayMessage}',
            category: 'container-devices',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getContainerConfig(int containerId) async {
    try {
      return await _repository.getContainerConfig(containerId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'container.query failed: ${error.displayMessage}',
            category: 'container-config',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSystemGeneralConfig() async {
    try {
      return await _repository.getSystemGeneralConfig();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'system.general.config failed: ${error.displayMessage}',
            category: 'system-general',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<List<({String id, String label})>?> getSystemTimezoneChoices() async {
    try {
      return await _repository.getSystemTimezoneChoices();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'system.general.timezone_choices failed: ${error.displayMessage}',
            category: 'system-general',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<OperationReceipt?> updateSystemGeneralConfig({
    required SystemGeneralConfiguration next,
    required SystemGeneralConfiguration baseline,
  }) {
    return _run(
      'system-general:update',
      () =>
          _repository.updateSystemGeneralConfig(next: next, baseline: baseline),
    );
  }

  Future<OperationReceipt?> updateVirtualMachine(
    int vmId, {
    required VmConfiguration next,
    required VmConfiguration baseline,
  }) {
    return _run(
      'vm-update:$vmId',
      () => _repository.updateVirtualMachine(
        vmId,
        next: next,
        baseline: baseline,
      ),
    );
  }

  Future<List<VmDevice>?> getVirtualMachineDevices(int vmId) async {
    try {
      return await _repository.getVirtualMachineDevices(vmId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'vm.device.query failed: ${error.displayMessage}',
            category: 'vm-devices',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<OperationReceipt?> createVirtualMachineDevice(
    int vmId,
    VmDeviceConfiguration configuration,
  ) {
    return _run(
      'vm-device:create:$vmId',
      () => _repository.createVirtualMachineDevice(configuration, vmId),
    );
  }

  Future<OperationReceipt?> updateVirtualMachineDevice(
    int deviceId,
    VmDeviceConfiguration configuration,
  ) {
    return _run(
      'vm-device:update:$deviceId',
      () => _repository.updateVirtualMachineDevice(deviceId, configuration),
    );
  }

  Future<OperationReceipt?> deleteVirtualMachineDevice(int deviceId) {
    return _run(
      'vm-device:delete:$deviceId',
      () => _repository.deleteVirtualMachineDevice(deviceId),
    );
  }

  Future<OperationReceipt?> setServiceRunning(
    String service, {
    required bool running,
  }) {
    return _run(
      'service:$service',
      () => _repository.controlService(
        service: service,
        verb: running ? ServiceVerb.start : ServiceVerb.stop,
      ),
    );
  }

  /// Persists a service's start-on-boot setting. Keyed separately from the
  /// run-state toggle so a boot change and a start/stop cannot mask each
  /// other's busy state on the same row.
  Future<OperationReceipt?> setServiceStartOnBoot(
    int serviceId, {
    required bool enabled,
  }) {
    return _run(
      'service-boot:$serviceId',
      () => _repository.setServiceStartOnBoot(serviceId, enabled: enabled),
    );
  }

  /// Selects the boot environment for the next boot. Refreshing the system
  /// resources afterwards is what makes the pending activation visible.
  Future<OperationReceipt?> activateBootEnvironment(String id) {
    return _run('boot-env-activate:$id', () async {
      final receipt = await _repository.activateBootEnvironment(id);
      // Boot environments live in the system resources provider, which the
      // shared refresh does not touch; without this the pending activation
      // would stay invisible.
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> setBootEnvironmentKept(
    String id, {
    required bool keep,
  }) {
    return _run('boot-env-keep:$id', () async {
      final receipt = await _repository.setBootEnvironmentKept(id, keep: keep);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> destroyBootEnvironment(String id) {
    return _run('boot-env-destroy:$id', () async {
      final receipt = await _repository.destroyBootEnvironment(id);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> setAlertDismissed(
    String uuid, {
    required bool dismissed,
  }) {
    return _run(
      'alert:$uuid',
      () => _repository.setAlertDismissed(uuid, dismissed: dismissed),
    );
  }

  Future<OperationReceipt?> updateUser(
    int userId,
    Map<String, Object?> payload,
  ) {
    return _run('user-update:$userId', () async {
      final receipt = await _repository.updateUser(userId, payload);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> changeUserPassword(
    int userId, {
    required String password,
  }) {
    return _run('user-password:$userId', () async {
      final receipt = await _repository.changeUserPassword(
        userId,
        password: password,
      );
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> updateGroup(
    int groupId,
    Map<String, Object?> payload,
  ) {
    return _run('group-update:$groupId', () async {
      final receipt = await _repository.updateGroup(groupId, payload);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> createUser(Map<String, Object?> payload) {
    return _run('user-create', () async {
      final receipt = await _repository.createUser(payload);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> deleteUser(
    int userId, {
    required bool deletePrimaryGroup,
  }) {
    return _run('user-delete:$userId', () async {
      final receipt = await _repository.deleteUser(
        userId,
        deletePrimaryGroup: deletePrimaryGroup,
      );
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> createGroup(Map<String, Object?> payload) {
    return _run('group-create', () async {
      final receipt = await _repository.createGroup(payload);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> deleteGroup(
    int groupId, {
    required bool deleteUsers,
  }) {
    return _run('group-delete:$groupId', () async {
      final receipt = await _repository.deleteGroup(
        groupId,
        deleteUsers: deleteUsers,
      );
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  Future<OperationReceipt?> runReplication(int taskId) {
    return _run(
      'replication:$taskId',
      () => _repository.runReplication(taskId),
    );
  }

  Future<OperationReceipt?> runCloudSync(int taskId, {required bool dryRun}) {
    return _run(
      'cloudsync:$taskId',
      () => _repository.runCloudSync(taskId, dryRun: dryRun),
    );
  }

  Future<OperationReceipt?> runRsync(int taskId) {
    return _run('rsync:$taskId', () => _repository.runRsync(taskId));
  }

  Future<OperationReceipt?> startPoolScrub(String poolName) {
    return _run('scrub:$poolName', () => _repository.startPoolScrub(poolName));
  }

  Future<OperationReceipt?> controlPoolScrub(
    String poolName,
    ScrubControlAction action,
  ) {
    return _run(
      'scrub-control:$poolName',
      () => _repository.controlPoolScrub(poolName, action),
    );
  }

  Future<OperationReceipt?> exportPool(
    int poolId, {
    required bool destroyData,
    required bool takeSnapshotsOffline,
  }) {
    return _run(
      'pool-export:$poolId',
      () => _repository.exportPool(
        poolId,
        destroyData: destroyData,
        takeSnapshotsOffline: takeSnapshotsOffline,
      ),
    );
  }

  Future<OperationReceipt?> setPoolDiskOnline(
    int poolId,
    String label, {
    required bool online,
  }) {
    return _run(
      'pool-disk:$poolId:$label',
      () => online
          ? _repository.onlinePoolDisk(poolId, label)
          : _repository.offlinePoolDisk(poolId, label),
    );
  }

  Future<OperationReceipt?> attachPoolDisk({
    required int poolId,
    required String targetVdev,
    required String disk,
  }) {
    return _run(
      'pool-attach:$poolId:$targetVdev',
      () => _repository.attachPoolDisk(
        poolId: poolId,
        targetVdev: targetVdev,
        disk: disk,
      ),
    );
  }

  /// Replaces a pool member with [disk].
  ///
  /// [force] must be threaded through rather than left to the repository
  /// default: the sheet offers it, and the confirmation warns that it removes a
  /// disk still being read. Dropping it here would make the app promise a
  /// forced replacement and then quietly perform an ordinary one, which fails
  /// on exactly the degraded pool the option exists for.
  Future<OperationReceipt?> replacePoolDisk({
    required int poolId,
    required String label,
    required String disk,
    bool force = false,
  }) {
    return _run(
      'pool-replace:$poolId:$label',
      () => _repository.replacePoolDisk(
        poolId: poolId,
        label: label,
        disk: disk,
        force: force,
      ),
    );
  }

  Future<OperationReceipt?> createIscsiAuth({
    required int tag,
    required String user,
    required String secret,
    String? peerUser,
    String? peerSecret,
  }) {
    return _run(
      'iscsi-auth:create:$user',
      () => _repository.createIscsiAuth(
        tag: tag,
        user: user,
        secret: secret,
        peerUser: peerUser,
        peerSecret: peerSecret,
      ),
    );
  }

  Future<OperationReceipt?> updateIscsiAuth(
    int authId, {
    required int tag,
    required String user,
    String? secret,
    String? peerUser,
    String? peerSecret,
  }) {
    return _run(
      'iscsi-auth:update:$authId',
      () => _repository.updateIscsiAuth(
        authId,
        tag: tag,
        user: user,
        secret: secret,
        peerUser: peerUser,
        peerSecret: peerSecret,
      ),
    );
  }

  Future<OperationReceipt?> deleteIscsiAuth(int authId) {
    return _run(
      'iscsi-auth:delete:$authId',
      () => _repository.deleteIscsiAuth(authId),
    );
  }

  Future<OperationReceipt?> createPool(PoolConfiguration configuration) {
    return _run(
      'pool-create:${configuration.name}',
      () => _repository.createPool(configuration),
    );
  }

  /// Queries the audit log.
  Future<List<AuditEntry>?> loadAuditEntries(AuditQuery query) {
    return _execute(
      'audit-query',
      () => _repository.getAuditEntries(query),
      refreshAfter: false,
    );
  }

  /// Reads audit retention and space usage.
  Future<AuditConfiguration?> loadAuditConfiguration() {
    return _execute(
      'audit-config',
      () => _repository.getAuditConfiguration(),
      refreshAfter: false,
    );
  }

  /// Updates audit retention. The caller must already have confirmed that
  /// shortening it discards recorded history.
  Future<OperationReceipt?> updateAuditConfiguration(
    AuditConfigurationEdit edit,
  ) {
    return _run(
      'audit-update',
      () => _repository.updateAuditConfiguration(edit),
    );
  }

  /// Prepares a configuration backup download and returns its tokenized URL.
  Future<ConfigBackupDownload?> prepareConfigBackup({
    required ConfigBackupOptions options,
    required String filename,
  }) {
    return _execute(
      'config-backup',
      () =>
          _repository.prepareConfigBackup(options: options, filename: filename),
      refreshAfter: false,
    );
  }

  /// Resets the configuration to defaults. Irreversible; the caller must have
  /// taken a typed confirmation.
  Future<OperationReceipt?> resetConfiguration({required bool reboot}) {
    // _execute rather than _run: the server reboots or drops the session, so a
    // post-action refresh would only surface a connection error on top of an
    // expected outcome.
    return _execute(
      'config-reset',
      () => _repository.resetConfiguration(reboot: reboot),
      refreshAfter: false,
    );
  }

  /// Lists privileges.
  Future<List<Privilege>?> loadPrivileges() {
    return _execute(
      'privileges',
      () => _repository.getPrivileges(),
      refreshAfter: false,
    );
  }

  /// Lists the role catalog, needed to show effective grants.
  Future<List<PrivilegeRole>?> loadPrivilegeRoles() {
    return _execute(
      'privilege-roles',
      () => _repository.getPrivilegeRoles(),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> createPrivilege(
    PrivilegeConfiguration configuration,
  ) {
    return _run(
      'privilege-create',
      () => _repository.createPrivilege(configuration),
    );
  }

  Future<OperationReceipt?> updatePrivilege(
    int privilegeId,
    PrivilegeConfiguration configuration,
  ) {
    return _run(
      'privilege-update:$privilegeId',
      () => _repository.updatePrivilege(privilegeId, configuration),
    );
  }

  Future<OperationReceipt?> deletePrivilege(int privilegeId) {
    return _run(
      'privilege-delete:$privilegeId',
      () => _repository.deletePrivilege(privilegeId),
    );
  }

  /// Lists cloud backup tasks.
  Future<List<CloudBackupTask>?> loadCloudBackupTasks() {
    return _execute(
      'cloud-backups',
      () => _repository.getCloudBackupTasks(),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> createCloudBackupTask(
    CloudBackupConfiguration configuration,
    CloudCredential? credential,
  ) {
    return _run(
      'cloud-backup-create',
      () => _repository.createCloudBackupTask(configuration, credential),
    );
  }

  /// Updates a cloud backup task. A blank repository password means
  /// "unchanged", so the stored value is substituted rather than sent blank.
  Future<OperationReceipt?> updateCloudBackupTask(
    int taskId,
    CloudBackupConfiguration configuration,
    CloudCredential? credential, {
    String? storedPassword,
  }) {
    return _run(
      'cloud-backup-update:$taskId',
      () => _repository.updateCloudBackupTask(
        taskId,
        configuration,
        credential,
        storedPassword: storedPassword,
      ),
    );
  }

  Future<OperationReceipt?> deleteCloudBackupTask(int taskId) {
    return _run(
      'cloud-backup-delete:$taskId',
      () => _repository.deleteCloudBackupTask(taskId),
    );
  }

  /// Runs a backup now. A dry run simulates it without writing anything.
  Future<OperationReceipt?> runCloudBackup(int taskId, {bool dryRun = false}) {
    return _run(
      'cloud-backup-run:$taskId',
      () => _repository.runCloudBackup(taskId, dryRun: dryRun),
    );
  }

  Future<OperationReceipt?> abortCloudBackup(int taskId) {
    return _run(
      'cloud-backup-abort:$taskId',
      () => _repository.abortCloudBackup(taskId),
    );
  }

  Future<List<CloudBackupSnapshot>?> loadCloudBackupSnapshots(int taskId) {
    return _execute(
      'cloud-backup-snapshots:$taskId',
      () => _repository.getCloudBackupSnapshots(taskId),
      refreshAfter: false,
    );
  }

  /// Restores a snapshot. The caller must confirm: this writes into a live
  /// dataset.
  Future<OperationReceipt?> restoreCloudBackup({
    required int taskId,
    required String snapshotId,
    required String subfolder,
    required String destinationPath,
  }) {
    return _run(
      'cloud-backup-restore:$taskId',
      () => _repository.restoreCloudBackup(
        taskId: taskId,
        snapshotId: snapshotId,
        subfolder: subfolder,
        destinationPath: destinationPath,
      ),
    );
  }

  /// Deletes one snapshot from a repository. Irreversible.
  Future<OperationReceipt?> deleteCloudBackupSnapshot(
    int taskId,
    String snapshotId,
  ) {
    return _run(
      'cloud-backup-snapshot-delete:$taskId',
      () => _repository.deleteCloudBackupSnapshot(taskId, snapshotId),
    );
  }

  /// Reads every alert class merged with its saved override.
  Future<AlertClassConfiguration?> loadAlertClasses() {
    return _execute(
      'alert-classes',
      () => _repository.getAlertClasses(),
      refreshAfter: false,
    );
  }

  /// Persists alert class policies. The whole override map is replaced, so the
  /// caller passes the full merged configuration.
  Future<OperationReceipt?> updateAlertClasses(AlertClassEdit edit) {
    return _run(
      'alert-classes-update',
      () => _repository.updateAlertClasses(edit),
    );
  }

  /// Lists alert destinations.
  Future<List<AlertServiceEntry>?> loadAlertServices() {
    return _execute(
      'alert-services',
      () => _repository.getAlertServices(),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> createAlertService(
    AlertServiceConfiguration configuration,
  ) {
    return _run(
      'alert-service-create',
      () => _repository.createAlertService(configuration),
    );
  }

  Future<OperationReceipt?> updateAlertService(
    int id,
    AlertServiceConfiguration configuration, {
    Map<String, Object?> storedSecrets = const {},
  }) {
    return _run(
      'alert-service-update:$id',
      () => _repository.updateAlertService(
        id,
        configuration,
        storedSecrets: storedSecrets,
      ),
    );
  }

  Future<OperationReceipt?> deleteAlertService(int id) {
    return _run(
      'alert-service-delete:$id',
      () => _repository.deleteAlertService(id),
    );
  }

  /// Sends a test alert, which is the only way to prove a destination works.
  Future<OperationReceipt?> testAlertService(
    AlertServiceConfiguration configuration,
  ) {
    return _run(
      'alert-service-test',
      () => _repository.testAlertService(configuration),
    );
  }

  /// Reads a service's configuration.
  Future<ServiceConfiguration?> loadServiceConfiguration(
    ConfigurableService service,
  ) {
    return _execute(
      'service-config:${service.namespace}',
      () => _repository.getServiceConfiguration(service),
      refreshAfter: false,
    );
  }

  /// Applies a partial service configuration edit. A running service picks the
  /// change up on restart, so the caller says so before confirming.
  Future<OperationReceipt?> updateServiceConfiguration(
    ServiceConfigurationEdit edit,
  ) {
    return _run(
      'service-update:${edit.service.namespace}',
      () => _repository.updateServiceConfiguration(edit),
    );
  }

  /// Reads the outgoing mail settings.
  Future<MailConfiguration?> loadMailConfiguration() {
    return _execute(
      'mail-config',
      () => _repository.getMailConfiguration(),
      refreshAfter: false,
    );
  }

  /// Applies a mail settings edit. The payload may carry an SMTP password, so
  /// no part of it is logged.
  Future<OperationReceipt?> updateMailConfiguration(
    MailConfigurationEdit edit, {
    required MailConfiguration current,
  }) {
    return _run(
      'mail-update',
      () => _repository.updateMailConfiguration(edit, current: current),
    );
  }

  /// Sends a test message, which is the only way to prove the settings work.
  Future<OperationReceipt?> sendTestMail({
    required String subject,
    required String body,
  }) {
    return _run(
      'mail-test',
      () => _repository.sendTestMail(subject: subject, body: body),
    );
  }

  Future<String?> loadLocalAdministratorEmail() async {
    try {
      return await _repository.getLocalAdministratorEmail();
    } on TrueNasRpcException {
      // Only used to prefill a recipient hint, so a failure is not worth
      // surfacing.
      return null;
    }
  }

  /// Lists scheduled commands.
  Future<List<CronJob>?> loadCronJobs() {
    return _execute(
      'cronjobs',
      () => _repository.getCronJobs(),
      refreshAfter: false,
    );
  }

  Future<OperationReceipt?> createCronJob(CronJobConfiguration configuration) {
    return _run(
      'cronjob-create',
      () => _repository.createCronJob(configuration),
    );
  }

  Future<OperationReceipt?> updateCronJob(
    int jobId,
    CronJobConfiguration configuration,
  ) {
    return _run(
      'cronjob-update:$jobId',
      () => _repository.updateCronJob(jobId, configuration),
    );
  }

  Future<OperationReceipt?> deleteCronJob(int jobId) {
    return _run(
      'cronjob-delete:$jobId',
      () => _repository.deleteCronJob(jobId),
    );
  }

  /// Runs a cron job immediately. The command runs as its configured user, so
  /// the caller confirms first.
  Future<OperationReceipt?> runCronJob(int jobId) {
    return _run('cronjob-run:$jobId', () => _repository.runCronJob(jobId));
  }

  Future<List<Tunable>?> loadTunables() => _execute(
    'tunables',
    () => _repository.getTunables(),
    refreshAfter: false,
  );

  Future<OperationReceipt?> createTunable(TunableConfiguration configuration) =>
      _run('tunable-create', () => _repository.createTunable(configuration));

  Future<OperationReceipt?> updateTunable(
    int tunableId,
    TunableConfiguration configuration,
  ) => _run(
    'tunable-update:$tunableId',
    () => _repository.updateTunable(tunableId, configuration),
  );

  Future<OperationReceipt?> deleteTunable(int tunableId) => _run(
    'tunable-delete:$tunableId',
    () => _repository.deleteTunable(tunableId),
  );

  /// Reads the global network settings, including the values actually in effect.
  Future<NetworkConfiguration?> loadNetworkConfiguration() {
    return _execute(
      'network-config',
      () => _repository.getNetworkConfiguration(),
      refreshAfter: false,
    );
  }

  /// Reads the live interface, route, and DNS summary.
  Future<NetworkSummary?> loadNetworkSummary() {
    return _execute(
      'network-summary',
      () => _repository.getNetworkSummary(),
      refreshAfter: false,
    );
  }

  /// Applies a global network edit. The caller must already have confirmed the
  /// consequence, since changing a gateway or nameserver can sever the session.
  Future<OperationReceipt?> updateNetworkConfiguration(
    NetworkConfigurationEdit edit,
  ) {
    return _run(
      'network-config-update',
      () => _repository.updateNetworkConfiguration(edit),
    );
  }

  /// Reads the staged-network-change state so the UI can preview what a commit
  /// would apply, including which network fields a check-in would clear.
  /// Does not modify state.
  Future<PendingNetworkChanges?> getPendingNetworkChanges() async {
    try {
      return await _repository.getPendingNetworkChanges();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'reading pending network changes failed: ${error.displayMessage}',
            category: 'network',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  /// Commits pending network changes. The caller must already have confirmed
  /// the consequences; the session may drop, so the controller does not refresh
  /// server resources afterwards. Pair with [checkInInterfaceChanges] once the
  /// connection survives.
  Future<OperationReceipt?> commitInterfaceChanges() {
    return _execute(
      'network-commit',
      () => _repository.commitInterfaceChanges(),
      refreshAfter: false,
    );
  }

  /// Checks in pending network changes. Call only after a successful
  /// [commitInterfaceChanges] left the session intact; otherwise the server
  /// rolls everything back at the end of the verification window.
  Future<OperationReceipt?> checkInInterfaceChanges() {
    return _execute(
      'network-checkin',
      () => _repository.checkInInterfaceChanges(),
      refreshAfter: false,
    );
  }

  /// Rolls back pending network changes that have not been checked in. Safe to
  /// call when the user abandons a change or after a failed verification
  /// window.
  Future<OperationReceipt?> rollbackInterfaceChanges() {
    return _execute(
      'network-rollback',
      () => _repository.rollbackInterfaceChanges(),
      refreshAfter: false,
    );
  }

  /// Creates a static route. The route only takes effect once the network
  /// commit/checkin workflow runs, so the caller must follow up with
  /// [commitInterfaceChanges] and [checkInInterfaceChanges].
  Future<OperationReceipt?> createStaticRoute(
    StaticRouteConfiguration configuration,
  ) {
    return _run(
      'staticroute-create:${configuration.destination}',
      () => _repository.createStaticRoute(configuration),
    );
  }

  Future<OperationReceipt?> updateStaticRoute(
    int routeId,
    StaticRouteConfiguration configuration,
  ) {
    return _run(
      'staticroute-update:$routeId',
      () => _repository.updateStaticRoute(routeId, configuration),
    );
  }

  Future<OperationReceipt?> deleteStaticRoute(int routeId) {
    return _run('staticroute-delete:$routeId', () async {
      final receipt = await _repository.deleteStaticRoute(routeId);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  /// Reads a single interface's configured values so the editor can seed
  /// aliases, MTU, and the DHCP flag.
  Future<Map<String, dynamic>?> getInterfaceConfig(String interfaceId) async {
    try {
      return await _repository.getInterfaceConfig(interfaceId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'interface.query failed: ${error.displayMessage}',
            category: 'interface-config',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  /// Stages an interface configuration change. The change only becomes live
  /// after the network commit/checkin workflow runs, so the caller must drive
  /// that afterwards.
  Future<OperationReceipt?> updateInterface(
    InterfaceConfiguration configuration,
  ) {
    return _run('interface-update:${configuration.id}', () async {
      final receipt = await _repository.updateInterface(configuration);
      _ref.invalidate(systemResourcesProvider);
      return receipt;
    });
  }

  /// Reads saved SSH connections for the replication and rsync editors.
  /// Returns null when the server rejects the call so the caller can explain
  /// that no connections could be loaded instead of showing an empty picker.
  Future<List<SshCredential>?> getSshCredentials() async {
    try {
      return await _repository.getSshCredentials();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'keychaincredential.query failed: ${error.displayMessage}',
            category: 'ssh-credentials',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getReplicationTaskConfig(int taskId) async {
    try {
      return await _repository.getReplicationTaskConfig(taskId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'replication.query failed: ${error.displayMessage}',
            category: 'replication-config',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRsyncTaskConfig(int taskId) async {
    try {
      return await _repository.getRsyncTaskConfig(taskId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'rsynctask.query failed: ${error.displayMessage}',
            category: 'rsync-config',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  /// Reads saved cloud credentials for the cloud sync editor. Returns null
  /// when the query fails so the caller can distinguish "none configured"
  /// from "could not read credentials".
  Future<List<CloudCredential>?> getCloudCredentials() async {
    try {
      return await _repository.getCloudCredentials();
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'cloudsync.credentials.query failed: ${error.displayMessage}',
            category: 'cloud-credentials',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCloudSyncTaskConfig(int taskId) async {
    try {
      return await _repository.getCloudSyncTaskConfig(taskId);
    } on TrueNasRpcException catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'cloudsync.query failed: ${error.displayMessage}',
            category: 'cloudsync-config',
            errorType: error.runtimeType.toString(),
          );
      return null;
    }
  }

  Future<OperationReceipt?> createCloudSyncTask(
    CloudSyncConfiguration configuration,
    CloudCredential? credential,
  ) {
    return _run(
      'cloudsync-create:${configuration.description}',
      () => _repository.createCloudSyncTask(configuration, credential),
    );
  }

  Future<OperationReceipt?> updateCloudSyncTask(
    int taskId,
    CloudSyncConfiguration configuration,
    CloudCredential? credential,
  ) {
    return _run(
      'cloudsync-update:$taskId',
      () => _repository.updateCloudSyncTask(taskId, configuration, credential),
    );
  }

  Future<OperationReceipt?> createReplicationTask(
    ReplicationConfiguration configuration,
  ) {
    return _run(
      'replication-create:${configuration.name}',
      () => _repository.createReplicationTask(configuration),
    );
  }

  Future<OperationReceipt?> updateReplicationTask(
    int taskId,
    ReplicationConfiguration configuration,
  ) {
    return _run(
      'replication-update:$taskId',
      () => _repository.updateReplicationTask(taskId, configuration),
    );
  }

  Future<OperationReceipt?> createRsyncTask(RsyncConfiguration configuration) {
    return _run(
      'rsync-create:${configuration.path}',
      () => _repository.createRsyncTask(configuration),
    );
  }

  Future<OperationReceipt?> updateRsyncTask(
    int taskId,
    RsyncConfiguration configuration,
  ) {
    return _run(
      'rsync-update:$taskId',
      () => _repository.updateRsyncTask(taskId, configuration),
    );
  }

  Future<OperationReceipt?> abortJob(int jobId) {
    return _run('job-abort:$jobId', () => _repository.abortJob(jobId));
  }

  Future<OperationReceipt?> _run(
    String key,
    Future<OperationReceipt> Function() operation,
  ) => _execute(key, operation);

  Future<T?> _execute<T>(
    String key,
    Future<T> Function() operation, {
    bool refreshAfter = true,
  }) async {
    if (state.isBusy(key)) return null;
    final connection = _ref.read(connectionControllerProvider);
    if (connection.hasRetainedSession && !connection.isConnected) {
      // Capability metadata may be retained to keep the layout stable during
      // resume recovery. A live connection is still mandatory for every
      // mutation, so no stale control can reach the network.
      return null;
    }
    state = ServerActionState(busyKeys: {...state.busyKeys, key});
    try {
      final result = await operation();
      if (refreshAfter) _ref.invalidate(serverResourcesProvider);
      state = ServerActionState(busyKeys: {...state.busyKeys}..remove(key));
      return result;
    } on Object catch (error) {
      _ref
          .read(redactedLoggerProvider)
          .error(
            'action $key failed: $error',
            category: 'actions',
            errorType: error.runtimeType.toString(),
          );
      state = ServerActionState(
        busyKeys: {...state.busyKeys}..remove(key),
        errorMessage: error is TrueNasRpcException
            ? error.displayMessage
            : null,
      );
      return null;
    }
  }
}
