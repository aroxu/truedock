import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/widgets/resource_landing_screen.dart';
import '../../../core/widgets/destructive_confirmation.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../system/presentation/system_resources_provider.dart';
import '../domain/iscsi_configuration.dart';
import '../domain/dataset_configuration.dart';
import '../domain/iscsi_extent_configuration.dart';
import '../domain/iscsi_target_configuration.dart';
import '../domain/iscsi_target_extent_configuration.dart';
import '../domain/nfs_share_configuration.dart';
import '../domain/smb_acl_configuration.dart';
import '../domain/dataset_acl.dart';
import '../domain/smb_share_configuration.dart';
import 'create_dataset_sheet.dart';
import 'dataset_tile.dart';
import 'dataset_tree_list.dart';
import 'dataset_quota_sheet.dart';
import 'dataset_acl_sheet.dart';
import 'disk_temperature_label.dart';
import 'dataset_edit_sheet.dart';
import 'dataset_rename_sheet.dart';
import 'dataset_unlock_sheet.dart';
import 'pool_actions_sheet.dart';
import 'pool_create_sheet.dart';
import '../domain/pool_configuration.dart';
import 'iscsi_configuration_sheets.dart';
import '../domain/iscsi_auth_configuration.dart';
import 'iscsi_auth_management_sheet.dart';
import 'iscsi_auth_sheet.dart';
import 'iscsi_extent_sheet.dart';
import 'iscsi_target_extent_sheet.dart';
import 'iscsi_target_sheet.dart';
import 'nfs_share_sheet.dart';
import 'smb_acl_sheet.dart';
import 'smb_share_sheet.dart';
import 'storage_localizations.dart';
import '../../../core/l10n/data_message_localizations.dart';
import '../../../core/domain/data_message.dart';

enum _ShareCreateType {
  smb,
  nfs,
  iscsiPortal,
  iscsiInitiator,
  iscsiTarget,
  iscsiExtent,
  iscsiAssociation,
}

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  ResourceLandingScreen _landing(AppLocalizations l10n) =>
      ResourceLandingScreen(
        title: l10n.storageTitle,
        description: l10n.storageLandingDescription,
        icon: Icons.storage_rounded,
        features: [
          (
            icon: Icons.layers_outlined,
            title: l10n.storageFeaturePools,
            subtitle: l10n.storageFeaturePoolsSubtitle,
          ),
          (
            icon: Icons.dataset_outlined,
            title: l10n.storageFeatureDatasets,
            subtitle: l10n.storageFeatureDatasetsSubtitle,
          ),
          (
            icon: Icons.camera_outlined,
            title: l10n.storageFeatureSnapshots,
            subtitle: l10n.storageFeatureSnapshotsSubtitle,
          ),
          (
            icon: Icons.disc_full_outlined,
            title: l10n.storageFeatureDisks,
            subtitle: l10n.storageFeatureDisksSubtitle,
          ),
          (
            icon: Icons.folder_shared_outlined,
            title: l10n.storageFeatureShares,
            subtitle: l10n.storageFeatureSharesSubtitle,
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    if (!connection.hasRetainedSession) return _landing(l10n);
    final resources = ref.watch(serverResourcesProvider);
    final capabilities = connection.capabilities;
    final canCreateSmb =
        capabilities?.supports('sharing.smb.presets') == true &&
        capabilities?.supports('sharing.smb.share_precheck') == true &&
        capabilities?.supports('sharing.smb.create') == true;
    final canEditSmb =
        capabilities?.supports('sharing.smb.presets') == true &&
        capabilities?.supports('sharing.smb.share_precheck') == true &&
        capabilities?.supports('sharing.smb.update') == true;
    final canCreateNfs = capabilities?.supports('sharing.nfs.create') == true;
    final canEditNfs = capabilities?.supports('sharing.nfs.update') == true;
    final canCreateIscsiPortal =
        capabilities?.supports('iscsi.portal.create') == true &&
        capabilities?.supports('iscsi.portal.listen_ip_choices') == true;
    final canEditIscsiPortal =
        capabilities?.supports('iscsi.portal.update') == true &&
        capabilities?.supports('iscsi.portal.listen_ip_choices') == true;
    final canCreateIscsiInitiator =
        capabilities?.supports('iscsi.initiator.create') == true;
    final canEditIscsiInitiator =
        capabilities?.supports('iscsi.initiator.update') == true;
    final canCreateIscsiTarget =
        capabilities?.supports('iscsi.target.create') == true &&
        capabilities?.supports('iscsi.target.validate_name') == true;
    final canEditIscsiTarget =
        capabilities?.supports('iscsi.target.update') == true &&
        capabilities?.supports('iscsi.target.validate_name') == true;
    final canCreateIscsiExtent =
        capabilities?.supports('iscsi.extent.create') == true &&
        capabilities?.supports('iscsi.extent.disk_choices') == true;
    final canEditIscsiExtent =
        capabilities?.supports('iscsi.extent.update') == true &&
        capabilities?.supports('iscsi.extent.disk_choices') == true;
    final canCreateIscsiAssociation =
        capabilities?.supports('iscsi.targetextent.create') == true;
    final canEditIscsiAssociation =
        capabilities?.supports('iscsi.targetextent.update') == true;
    final canEditDataset =
        capabilities?.supports('pool.dataset.update') == true;
    final canRenameDataset =
        capabilities?.supports('pool.dataset.rename') == true;
    final canDeleteDataset =
        capabilities?.supports('pool.dataset.delete') == true;
    final canLockDataset =
        capabilities?.supports('pool.dataset.lock') == true &&
        capabilities?.supports('pool.dataset.unlock') == true;
    final canPromoteDataset =
        capabilities?.supports('pool.dataset.promote') == true;
    // Both halves are required: listing quotas without being able to change
    // them would offer an editor that always fails.
    final canManageQuotas =
        capabilities?.supports('pool.dataset.get_quota') == true &&
        capabilities?.supports('pool.dataset.set_quota') == true;
    final canManageDatasetAcl =
        capabilities?.supports('filesystem.getacl') == true &&
        capabilities?.supports('filesystem.setacl') == true;
    final canDeleteIscsiPortal =
        capabilities?.supports('iscsi.portal.delete') == true;
    final canDeleteIscsiInitiator =
        capabilities?.supports('iscsi.initiator.delete') == true;
    final canDeleteIscsiTarget =
        capabilities?.supports('iscsi.target.delete') == true;
    final canDeleteIscsiExtent =
        capabilities?.supports('iscsi.extent.delete') == true;
    final canDeleteIscsiAssociation =
        capabilities?.supports('iscsi.targetextent.delete') == true;
    final canManageIscsiAuth =
        capabilities?.supports('iscsi.auth.query') == true;
    final canCreateIscsiAuth =
        capabilities?.supports('iscsi.auth.create') == true;
    final canEditIscsiAuth =
        capabilities?.supports('iscsi.auth.update') == true;
    final canDeleteIscsiAuth =
        capabilities?.supports('iscsi.auth.delete') == true;
    final canDeleteSmb = capabilities?.supports('sharing.smb.delete') == true;
    final canDeleteNfs = capabilities?.supports('sharing.nfs.delete') == true;
    final canEditSmbAcl =
        capabilities?.supports('sharing.smb.getacl') == true &&
        capabilities?.supports('sharing.smb.setacl') == true;
    final canScrubPool = capabilities?.supports('pool.scrub.scrub') == true;
    // Pause, resume, and stop all route through the same scrub method.
    final canControlScrub = canScrubPool;
    final canTogglePoolMembers =
        capabilities?.supports('pool.offline') == true &&
        capabilities?.supports('pool.online') == true;
    final canExportPool = capabilities?.supports('pool.export') == true;
    final canCreatePool = capabilities?.supports('pool.create') == true;
    final canAttachPoolDisk = capabilities?.supports('pool.attach') == true;
    final canReplacePoolDisk = capabilities?.supports('pool.replace') == true;
    final canOpenPoolActions =
        canScrubPool ||
        canTogglePoolMembers ||
        canExportPool ||
        canAttachPoolDisk ||
        canReplacePoolDisk;

    return SafeRefreshIndicator(
      onRefresh: () async {
        refreshServerResources(ref);
        await ref.read(serverResourcesProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(title: Text(l10n.storageTitle)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: resources.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: _SectionError(message: l10n.storageLoadFailed),
              ),
              data: (data) => SliverList.list(
                children: [
                  _SectionHeading(
                    title: l10n.storageSectionPools,
                    count: data.pools.items.length,
                    action: l10n.storageSectionCreatePool,
                    onAction: canCreatePool
                        ? () => _createPool(context, ref, data.disks.items)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (data.pools.hasError)
                    _SectionError(message: l10n.dataMessage(data.pools.error!))
                  else if (data.pools.items.isEmpty)
                    _EmptySection(
                      icon: Icons.layers_clear_outlined,
                      message: l10n.storageSectionNoPools,
                    )
                  else
                    ...data.pools.items.map(
                      (pool) => _PoolCard(
                        pool,
                        onOpen: canOpenPoolActions
                            ? () => _openPoolActions(
                                context,
                                ref,
                                pool,
                                data,
                                canScrub: canScrubPool,
                                canControlScrub: canControlScrub,
                                canToggleMembers: canTogglePoolMembers,
                                canExport: canExportPool,
                                canAttach: canAttachPoolDisk,
                                canReplace: canReplacePoolDisk,
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeading(
                    title: l10n.storageSectionDatasets,
                    count: data.datasets.items.length,
                    action: l10n.storageSectionCreateDataset,
                    onAction: data.pools.items.isEmpty
                        ? null
                        : () async {
                            final created = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => CreateDatasetSheet(
                                pools: data.pools.items,
                                datasets: data.datasets.items,
                              ),
                            );
                            if (created == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).storageDatasetCreated,
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  if (data.datasets.hasError)
                    _SectionError(
                      message: l10n.dataMessage(data.datasets.error!),
                    )
                  else if (data.datasets.items.isEmpty)
                    _EmptySection(
                      icon: Icons.dataset_outlined,
                      message: l10n.storageSectionNoDatasets,
                    )
                  else
                    DatasetTreeList(
                      datasets: data.datasets.items,
                      itemBuilder:
                          (
                            context,
                            dataset,
                            hasChildren,
                            isExpanded,
                            onToggle,
                          ) => DatasetTile(
                            key: ValueKey('dataset-${dataset.id}'),
                            dataset: dataset,
                            hasChildren: hasChildren,
                            isExpanded: isExpanded,
                            onToggle: onToggle,
                            canEdit: canEditDataset,
                            canRename: canRenameDataset,
                            canDelete: canDeleteDataset,
                            onEdit: () => _editDataset(context, ref, dataset),
                            onRename: () =>
                                _renameDataset(context, ref, dataset),
                            onDelete: () =>
                                _deleteDataset(context, ref, dataset, data),
                            canLock: canLockDataset,
                            onLock: () =>
                                _lockDataset(context, ref, dataset, data),
                            onUnlock: () =>
                                _unlockDataset(context, ref, dataset),
                            canPromote: canPromoteDataset,
                            onPromote: () =>
                                _promoteDataset(context, ref, dataset),
                            canManageQuotas: canManageQuotas,
                            onManageQuotas: () =>
                                _manageQuotas(context, dataset),
                            canManageAcl: canManageDatasetAcl,
                            onManageAcl: () =>
                                _manageDatasetAcl(context, ref, dataset),
                            onCreateSnapshot: () async {
                              final created = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (context) =>
                                    _CreateSnapshotSheet(dataset: dataset),
                              );
                              if (created == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.storageSnapshotCreated),
                                  ),
                                );
                              }
                            },
                          ),
                    ),
                  const SizedBox(height: 28),
                  _ReadOnlyHeading(
                    title: l10n.storageSectionDisks,
                    count: data.disks.items.length,
                  ),
                  const SizedBox(height: 12),
                  if (data.disks.hasError)
                    _SectionError(message: l10n.dataMessage(data.disks.error!))
                  else if (data.disks.items.isEmpty)
                    _EmptySection(
                      icon: Icons.disc_full_outlined,
                      message: l10n.storageSectionNoDisks,
                    )
                  else
                    StorageDiskList(
                      disks: data.disks.items,
                      temperatures: data.diskTemperatures,
                    ),
                  const SizedBox(height: 28),
                  _ShareSectionHeading(
                    title: l10n.storageSectionShares,
                    count:
                        data.smbShares.items.length +
                        data.nfsShares.items.length +
                        data.webShares.items.length +
                        data.iscsiTargets.items.length +
                        data.iscsiExtents.items.length +
                        data.iscsiPortals.items.length +
                        data.iscsiInitiators.items.length +
                        data.iscsiTargetExtents.items.length,
                    canCreateSmb: canCreateSmb,
                    canCreateNfs: canCreateNfs,
                    canCreateIscsiPortal: canCreateIscsiPortal,
                    canCreateIscsiInitiator: canCreateIscsiInitiator,
                    canCreateIscsiTarget: canCreateIscsiTarget,
                    canCreateIscsiExtent: canCreateIscsiExtent,
                    canCreateIscsiAssociation: canCreateIscsiAssociation,
                    onSelected: (type) => switch (type) {
                      _ShareCreateType.smb => _createSmbShare(
                        context,
                        ref,
                        data.datasets.items,
                      ),
                      _ShareCreateType.nfs => _createNfsShare(
                        context,
                        ref,
                        data.datasets.items,
                      ),
                      _ShareCreateType.iscsiPortal => _createIscsiPortal(
                        context,
                        ref,
                      ),
                      _ShareCreateType.iscsiInitiator => _createIscsiInitiator(
                        context,
                        ref,
                      ),
                      _ShareCreateType.iscsiTarget => _createIscsiTarget(
                        context,
                        ref,
                        data.iscsiPortals.items,
                        data.iscsiInitiators.items,
                        data.iscsiAuths.items,
                      ),
                      _ShareCreateType.iscsiExtent => _createIscsiExtent(
                        context,
                        ref,
                      ),
                      _ShareCreateType.iscsiAssociation =>
                        _createIscsiAssociation(
                          context,
                          ref,
                          data.iscsiTargets.items,
                          data.iscsiExtents.items,
                        ),
                    },
                  ),
                  const SizedBox(height: 12),
                  _ShareList(
                    smb: data.smbShares,
                    nfs: data.nfsShares,
                    web: data.webShares,
                    iscsiTargets: data.iscsiTargets,
                    iscsiExtents: data.iscsiExtents,
                    iscsiPortals: data.iscsiPortals,
                    iscsiInitiators: data.iscsiInitiators,
                    iscsiTargetExtents: data.iscsiTargetExtents,
                    iscsiAuths: data.iscsiAuths,
                    canManageIscsiAuth: canManageIscsiAuth,
                    canCreateIscsiAuth: canCreateIscsiAuth,
                    canEditIscsiAuth: canEditIscsiAuth,
                    canDeleteIscsiAuth: canDeleteIscsiAuth,
                    onManageIscsiAuth: () => _manageIscsiAuth(
                      context,
                      ref,
                      data.iscsiAuths.items,
                      canCreate: canCreateIscsiAuth,
                      canEdit: canEditIscsiAuth,
                      canDelete: canDeleteIscsiAuth,
                    ),
                    canEditSmb: canEditSmb,
                    canEditNfs: canEditNfs,
                    canDeleteSmb: canDeleteSmb,
                    canDeleteNfs: canDeleteNfs,
                    canEditSmbAcl: canEditSmbAcl,
                    canEditIscsiPortal: canEditIscsiPortal,
                    canEditIscsiInitiator: canEditIscsiInitiator,
                    canEditIscsiTarget: canEditIscsiTarget,
                    canEditIscsiExtent: canEditIscsiExtent,
                    canEditIscsiAssociation: canEditIscsiAssociation,
                    onEditSmb: (share) =>
                        _editSmbShare(context, ref, share, data.datasets.items),
                    onEditNfs: (share) =>
                        _editNfsShare(context, ref, share, data.datasets.items),
                    onDeleteSmb: (share) =>
                        _deleteSmbShare(context, ref, share),
                    onEditSmbAcl: (share) => _editSmbAcl(context, ref, share),
                    onDeleteNfs: (share) =>
                        _deleteNfsShare(context, ref, share),
                    onDeleteIscsiPortal: canDeleteIscsiPortal
                        ? (portal) =>
                              _deleteIscsiPortal(context, ref, portal, data)
                        : null,
                    onDeleteIscsiInitiator: canDeleteIscsiInitiator
                        ? (initiator) =>
                              _deleteIscsiInitiator(context, ref, initiator)
                        : null,
                    onDeleteIscsiTarget: canDeleteIscsiTarget
                        ? (target) =>
                              _deleteIscsiTarget(context, ref, target, data)
                        : null,
                    onDeleteIscsiExtent: canDeleteIscsiExtent
                        ? (extent) =>
                              _deleteIscsiExtent(context, ref, extent, data)
                        : null,
                    onDeleteIscsiAssociation: canDeleteIscsiAssociation
                        ? (association) =>
                              _deleteIscsiAssociation(context, ref, association)
                        : null,
                    onEditIscsiPortal: (portal) =>
                        _editIscsiPortal(context, ref, portal),
                    onEditIscsiInitiator: (initiator) =>
                        _editIscsiInitiator(context, ref, initiator),
                    onEditIscsiTarget: (target) => _editIscsiTarget(
                      context,
                      ref,
                      target,
                      data.iscsiPortals.items,
                      data.iscsiInitiators.items,
                      data.iscsiAuths.items,
                    ),
                    onEditIscsiExtent: (extent) =>
                        _editIscsiExtent(context, ref, extent),
                    onEditIscsiAssociation: (association) =>
                        _editIscsiAssociation(
                          context,
                          ref,
                          association,
                          data.iscsiTargets.items,
                          data.iscsiExtents.items,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createSmbShare(
    BuildContext context,
    WidgetRef ref,
    List<Dataset> datasets,
  ) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final presets = await controller.loadSmbSharePresets();
    if (!context.mounted) return;
    if (presets == null) {
      _showSmbResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageSmbFailedLoadPresets,
      );
      return;
    }
    final configuration = await showModalBottomSheet<SmbShareConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SmbShareSheet(datasets: datasets, presets: presets),
    );
    if (configuration == null || !context.mounted) return;
    final valid = await controller.precheckSmbShareName(configuration.name);
    if (!context.mounted) return;
    if (!valid) {
      _showSmbResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageSmbFailedValidate,
      );
      return;
    }
    final receipt = await controller.createSmbShare(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showSmbResult(
      context,
      ref,
      receipt,
      failure: l10n.storageSmbFailedCreate(configuration.name),
      success: l10n.storageSmbSuccessCreate(configuration.name),
    );
  }

  Future<void> _editSmbShare(
    BuildContext context,
    WidgetRef ref,
    SmbShare share,
    List<Dataset> datasets,
  ) async {
    if (SmbSharePurposeApi.fromApi(share.purpose) ==
        SmbSharePurpose.unsupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).storageSmbPurposeReadOnly),
        ),
      );
      return;
    }
    final controller = ref.read(serverActionControllerProvider.notifier);
    final presets = await controller.loadSmbSharePresets();
    if (!context.mounted) return;
    if (presets == null) {
      _showSmbResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageSmbFailedLoadPresets,
      );
      return;
    }
    final configuration = await showModalBottomSheet<SmbShareConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SmbShareSheet(
        datasets: datasets,
        presets: presets,
        existingShare: share,
      ),
    );
    if (configuration == null || !context.mounted) return;
    if (configuration.name.toLowerCase() != share.name.toLowerCase()) {
      final valid = await controller.precheckSmbShareName(configuration.name);
      if (!context.mounted) return;
      if (!valid) {
        _showSmbResult(
          context,
          ref,
          null,
          failure: AppLocalizations.of(context).storageSmbFailedValidate,
        );
        return;
      }
    }
    final receipt = await controller.updateSmbShare(share.id, configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showSmbResult(
      context,
      ref,
      receipt,
      failure: l10n.storageSmbFailedUpdate(configuration.name),
      success: l10n.storageSmbSuccessUpdate(configuration.name),
    );
  }

  Future<void> _editSmbAcl(
    BuildContext context,
    WidgetRef ref,
    SmbShare share,
  ) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final acl = await controller.loadSmbShareAcl(share.name);
    if (!context.mounted) return;
    if (acl == null) {
      _showSmbResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageSmbFailedLoadAcl,
      );
      return;
    }
    final resources = ref.read(systemResourcesProvider).value;
    // Carry the uid/gid: sharing.smb.setacl identifies a principal by SID or
    // Unix id, and rejects a bare name.
    final users =
        resources?.users.items
            .where((u) => u.isEditable)
            .map((u) => SmbAclPrincipal(name: u.username, unixId: u.uid))
            .toList(growable: false) ??
        const <SmbAclPrincipal>[];
    final groups =
        resources?.groups.items
            .map((g) => SmbAclPrincipal(name: g.name, unixId: g.gid))
            .toList(growable: false) ??
        const <SmbAclPrincipal>[];
    if (!context.mounted) return;
    final result = await showModalBottomSheet<List<SmbAclEntry>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SmbAclSheet(
        share: share,
        users: users,
        groups: groups,
        initialAcl: acl,
      ),
    );
    if (result == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final serverName = _serverName(context, ref);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageAclConfirmTitle(share.name),
      server: serverName,
      target: share.name,
      actionLabel: l10n.storageAclConfirmAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.security_outlined,
          text: l10n.storageAclConfirmRules(result.length),
        ),
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageAclConfirmUnlisted,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await controller.setSmbShareAcl(share.name, result);
    if (!context.mounted) return;
    _showSmbResult(
      context,
      ref,
      receipt,
      failure: l10n.storageSmbFailedSetAcl,
      success: l10n.storageSmbSuccessSetAcl(share.name),
    );
  }

  Future<void> _createNfsShare(
    BuildContext context,
    WidgetRef ref,
    List<Dataset> datasets,
  ) async {
    final configuration = await showModalBottomSheet<NfsShareConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => NfsShareSheet(datasets: datasets),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createNfsShare(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showNfsResult(
      context,
      ref,
      receipt,
      failure: l10n.storageNfsFailedCreate(configuration.path),
      success: l10n.storageNfsSuccessCreate(configuration.path),
    );
  }

  Future<void> _editNfsShare(
    BuildContext context,
    WidgetRef ref,
    NfsShare share,
    List<Dataset> datasets,
  ) async {
    final configuration = await showModalBottomSheet<NfsShareConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          NfsShareSheet(datasets: datasets, existingShare: share),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateNfsShare(share.id, configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showNfsResult(
      context,
      ref,
      receipt,
      failure: l10n.storageNfsFailedUpdate(configuration.path),
      success: l10n.storageNfsSuccessUpdate(configuration.path),
    );
  }

  Future<void> _createIscsiPortal(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final choices = await controller.loadIscsiPortalListenIpChoices();
    if (!context.mounted) return;
    if (choices == null) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedLoadPortals,
      );
      return;
    }
    await _openIscsiPortalSheet(context, ref, controller, choices);
  }

  /// Opens per-account quotas for a dataset.
  ///
  /// The sheet owns its own reads and mutations because quotas are fetched per
  /// subject - `pool.dataset.get_quota` takes one `quota_type` at a time - so
  /// there is nothing useful for the screen to preload.
  Future<void> _manageQuotas(BuildContext context, Dataset dataset) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DatasetQuotaSheet(dataset: dataset),
    );
  }

  Future<void> _manageDatasetAcl(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
  ) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final acl = await controller.loadDatasetAcl(dataset.name);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    if (acl == null) {
      _showDatasetResult(
        context,
        ref,
        null,
        failure: l10n.storageDatasetAclLoadFailed,
        success: l10n.storageDatasetAclSaved,
      );
      return;
    }
    var resources = ref.read(systemResourcesProvider).value;
    if (resources == null) {
      try {
        resources = await ref.read(systemResourcesProvider.future);
      } catch (_) {
        // The sheet still exposes the current uid/gid as fallback choices.
        // Account discovery failure must not disable ownership editing.
      }
    }
    if (!context.mounted) return;
    final users =
        resources?.users.items
            .where((user) => user.local)
            .map(
              (user) => DatasetAclPrincipal(
                name: user.username,
                id: user.uid,
                kind: DatasetAclPrincipalKind.user,
              ),
            )
            .toList(growable: false) ??
        const <DatasetAclPrincipal>[];
    final groups =
        resources?.groups.items
            .where((group) => group.local)
            .map(
              (group) => DatasetAclPrincipal(
                name: group.name,
                id: group.gid,
                kind: DatasetAclPrincipalKind.group,
              ),
            )
            .toList(growable: false) ??
        const <DatasetAclPrincipal>[];
    final result = await showModalBottomSheet<DatasetAclEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DatasetAclSheet(
        datasetName: dataset.name,
        initialAcl: acl,
        users: users,
        groups: groups,
      ),
    );
    if (result == null || !context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDatasetAclConfirmTitle,
      server: _serverName(context, ref),
      target: dataset.name,
      actionLabel: l10n.storageDatasetAclConfirmAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.admin_panel_settings_outlined,
          text: l10n.storageDatasetAclConfirmRules(result.acl.entries.length),
        ),
        if (result.ownerChanged)
          ImpactDetail(
            icon: Icons.badge_outlined,
            text: l10n.storageDatasetAclConfirmOwnership(
              result.acl.user ?? result.acl.uid?.toString() ?? '-',
              result.acl.group ?? result.acl.gid?.toString() ?? '-',
            ),
          ),
        if (result.typeChanged)
          ImpactDetail(
            icon: Icons.transform_rounded,
            text: l10n.storageDatasetAclConfirmTypeChange(
              acl.type == DatasetAclType.nfs4 ? 'TrueNAS ACL' : 'POSIX',
              result.acl.type == DatasetAclType.nfs4 ? 'TrueNAS ACL' : 'POSIX',
            ),
          ),
        ImpactDetail(
          icon: result.recursive
              ? Icons.account_tree_outlined
              : Icons.folder_outlined,
          text: result.recursive
              ? l10n.storageDatasetAclConfirmRecursive
              : l10n.storageDatasetAclConfirmDatasetOnly,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    if (result.typeChanged) {
      final typeReceipt = await controller.setDatasetAclType(
        dataset.id,
        result.acl.type,
      );
      if (typeReceipt == null || !context.mounted) {
        if (context.mounted) {
          _showDatasetResult(
            context,
            ref,
            null,
            failure: l10n.storageDatasetAclTypeChangeFailed,
            success: l10n.storageDatasetAclSaved,
          );
        }
        return;
      }
    }
    final receipt = await controller.setDatasetAcl(
      result.acl,
      recursive: result.recursive,
    );
    if (!context.mounted) return;
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetAclSaveFailed,
      success: l10n.storageDatasetAclSaved,
      localizeError: l10n.datasetAclSetAclError,
    );
  }

  Future<void> _editDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
  ) async {
    final payload = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DatasetEditSheet(dataset: dataset),
    );
    if (payload == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateDataset(dataset.id, payload);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedUpdate(dataset.name),
      success: l10n.storageDatasetSuccessUpdate(dataset.name),
    );
  }

  Future<void> _renameDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
  ) async {
    final request = await showModalBottomSheet<DatasetRenameRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DatasetRenameSheet(dataset: dataset),
    );
    if (request == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .renameDataset(dataset.id, request);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedRename(dataset.name),
      success: l10n.storageDatasetSuccessRename(request.newName),
    );
  }

  /// Shows the outcome of a dataset operation.
  ///
  /// [failure] and [success] are whole localized sentences rather than verb
  /// fragments, because a fragment composed into a surrounding sentence
  /// cannot be translated correctly.
  void _showDatasetResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String failure,
    required String success,
    String Function(String error)? localizeError,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    final message = receipt == null
        ? error == null
              ? failure
              : localizeError?.call(error) ?? error
        : success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), showCloseIcon: receipt == null),
    );
  }

  /// Destroying a dataset is irreversible, so the confirmation names the
  /// server and dataset, counts what else disappears with it, and requires the
  /// full dataset path to be typed.
  Future<void> _deleteDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
    ServerResources data,
  ) async {
    final children = data.datasets.items
        .where((item) => item.name.startsWith('${dataset.name}/'))
        .toList(growable: false);
    final snapshots = data.snapshots.items
        .where(
          (item) =>
              item.dataset == dataset.name ||
              item.dataset.startsWith('${dataset.name}/'),
        )
        .length;
    final mountPath = '/mnt/${dataset.name}';
    final affectedShares =
        data.smbShares.items.where((share) => share.path == mountPath).length +
        data.nfsShares.items.where((share) => share.path == mountPath).length;

    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeleteDatasetTitle,
      server: _serverName(context, ref),
      target: dataset.name,
      actionLabel: l10n.storageDeleteDatasetAction,
      impact: MutationImpact.critical,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.storageDeleteDatasetData(formatBytes(dataset.usedBytes)),
        ),
        if (children.isNotEmpty)
          ImpactDetail(
            icon: Icons.account_tree_outlined,
            text: l10n.storageDeleteDatasetChildren(children.length),
          ),
        if (snapshots > 0)
          ImpactDetail(
            icon: Icons.camera_outlined,
            text: l10n.storageDeleteDatasetSnapshots(snapshots),
          ),
        if (affectedShares > 0)
          ImpactDetail(
            icon: Icons.folder_off_outlined,
            text: l10n.storageDeleteDatasetShares(affectedShares, mountPath),
          ),
      ],
      note: children.isEmpty
          ? l10n.storageDeleteDatasetNoteLeaf
          : l10n.storageDeleteDatasetNoteRecursive,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteDataset(dataset.id, recursive: children.isNotEmpty, force: true);
    if (!context.mounted) return;
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedDelete(dataset.name),
      success: l10n.storageDatasetSuccessDelete(dataset.name),
    );
  }

  /// Deleting a share stops clients reaching the path but leaves the data in
  /// place, so this is high impact rather than irreversible.
  Future<void> _deleteSmbShare(
    BuildContext context,
    WidgetRef ref,
    SmbShare share,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeleteSmbTitle,
      server: _serverName(context, ref),
      target: '${share.name} · ${share.path}',
      actionLabel: l10n.storageDeleteShareAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageDeleteSmbClients,
        ),
        ImpactDetail(
          icon: Icons.settings_backup_restore_rounded,
          text: l10n.storageDeleteSmbConfig,
        ),
      ],
      note: l10n.storageDeleteShareNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteSmbShare(share.id);
    if (!context.mounted) return;
    _showSmbResult(
      context,
      ref,
      receipt,
      failure: l10n.storageSmbFailedDelete(share.name),
      success: l10n.storageSmbSuccessDelete(share.name),
    );
  }

  Future<void> _deleteNfsShare(
    BuildContext context,
    WidgetRef ref,
    NfsShare share,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeleteNfsTitle,
      server: _serverName(context, ref),
      target: share.path,
      actionLabel: l10n.storageDeleteShareAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageDeleteNfsClients,
        ),
        ImpactDetail(
          icon: Icons.settings_backup_restore_rounded,
          text: l10n.storageDeleteNfsRules,
        ),
      ],
      note: l10n.storageDeleteShareNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteNfsShare(share.id);
    if (!context.mounted) return;
    _showNfsResult(
      context,
      ref,
      receipt,
      failure: l10n.storageNfsFailedDelete(share.path),
      success: l10n.storageNfsSuccessDelete(share.path),
    );
  }

  String _serverName(BuildContext context, WidgetRef ref) =>
      ref.read(connectionControllerProvider).profile?.name ??
      AppLocalizations.of(context).storageServerFallbackName;

  /// Removing a portal breaks the addresses initiators connect through.
  Future<void> _deleteIscsiPortal(
    BuildContext context,
    WidgetRef ref,
    IscsiPortal portal,
    ServerResources data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = portal.comment.isEmpty
        ? l10n.storageIscsiPortalFallbackLabel(portal.tag)
        : portal.comment;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeletePortalTitle,
      server: _serverName(context, ref),
      target: '$label · ${portal.addressSummary}',
      actionLabel: l10n.storageDeletePortalAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageDeletePortalInitiators,
        ),
        ImpactDetail(
          icon: Icons.block_rounded,
          text: l10n.storageDeleteIscsiInUse,
        ),
      ],
      note: l10n.storageDeletePortalNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiPortal(portal.id);
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedDeletePortal(label),
      success: l10n.storageIscsiSuccessDeletePortal(label),
    );
  }

  Future<void> _deleteIscsiInitiator(
    BuildContext context,
    WidgetRef ref,
    IscsiInitiator initiator,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = initiator.comment.isEmpty
        ? l10n.storageIscsiInitiatorFallbackLabel(initiator.id)
        : initiator.comment;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeleteInitiatorTitle,
      server: _serverName(context, ref),
      target: label,
      actionLabel: l10n.storageDeleteInitiatorAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.devices_other_outlined,
          text: l10n.storageDeleteInitiatorAllowList,
        ),
        ImpactDetail(
          icon: Icons.block_rounded,
          text: l10n.storageDeleteIscsiInUse,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiInitiator(initiator.id);
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedDeleteInitiator(label),
      success: l10n.storageIscsiSuccessDeleteInitiator(label),
    );
  }

  Future<void> _deleteIscsiTarget(
    BuildContext context,
    WidgetRef ref,
    IscsiTarget target,
    ServerResources data,
  ) async {
    final luns = data.iscsiTargetExtents.items
        .where((association) => association.targetId == target.id)
        .length;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageDeleteTargetTitle,
      server: _serverName(context, ref),
      target: target.name,
      actionLabel: l10n.storageDeleteTargetAction,
      impact: MutationImpact.critical,
      confirmationText: target.alias ?? target.name,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageDeleteTargetInitiators,
        ),
        if (luns > 0)
          ImpactDetail(
            icon: Icons.layers_clear_outlined,
            text: l10n.storageDeleteTargetLuns(luns),
          ),
      ],
      note: l10n.storageDeleteTargetNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiTarget(target.id, force: true);
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedDeleteTarget(target.name),
      success: l10n.storageIscsiSuccessDeleteTarget(target.name),
    );
  }

  /// Deleting an extent optionally destroys its backing file or zvol, so the
  /// two outcomes are separated with an explicit choice.
  Future<void> _deleteIscsiExtent(
    BuildContext context,
    WidgetRef ref,
    IscsiExtent extent,
    ServerResources data,
  ) async {
    final removeBacking = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _IscsiExtentDeleteSheet(extent: extent),
    );
    if (removeBacking == null || !context.mounted) return;

    final luns = data.iscsiTargetExtents.items
        .where((association) => association.extentId == extent.id)
        .length;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: removeBacking
          ? l10n.storageDestroyExtentTitle
          : l10n.storageDeleteExtentTitle,
      server: _serverName(context, ref),
      target: '${extent.name} · ${extent.backingStore}',
      actionLabel: removeBacking
          ? l10n.storageDeleteExtentDestroyAction
          : l10n.storageDeleteExtentAction,
      impact: MutationImpact.critical,
      confirmationText: extent.name,
      consequences: [
        if (removeBacking)
          ImpactDetail(
            icon: Icons.delete_forever_rounded,
            text: l10n.storageDeleteExtentBackingDestroyed(
              extent.type.toLowerCase(),
              extent.backingStore,
            ),
          )
        else
          ImpactDetail(
            icon: Icons.link_off_rounded,
            text: l10n.storageDeleteExtentBackingKept,
          ),
        if (luns > 0)
          ImpactDetail(
            icon: Icons.layers_clear_outlined,
            text: l10n.storageDeleteExtentLuns(luns),
          ),
        ImpactDetail(
          icon: Icons.warning_amber_rounded,
          text: l10n.storageDeleteExtentInitiators,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiExtent(
          extent.id,
          removeBackingFile: removeBacking,
          force: true,
        );
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedDeleteExtent(extent.name),
      success: l10n.storageIscsiSuccessDeleteExtent(extent.name),
    );
  }

  Future<void> _deleteIscsiAssociation(
    BuildContext context,
    WidgetRef ref,
    IscsiTargetExtent association,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = l10n.storageIscsiAssociationLabel(
      association.targetId,
      association.extentId,
    );
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageRemoveLunTitle,
      server: _serverName(context, ref),
      target: label,
      actionLabel: l10n.storageRemoveLunAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageRemoveLunDisappears,
        ),
        ImpactDetail(
          icon: Icons.storage_outlined,
          text: l10n.storageRemoveLunExtentKept,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiTargetExtent(association.id, force: true);
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedRemoveLun(label),
      success: l10n.storageIscsiSuccessRemoveLun(label),
    );
  }

  /// Locking evicts the encryption key, so anything reading the dataset stops
  /// working until it is unlocked again.
  Future<void> _lockDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
    ServerResources data,
  ) async {
    final mountPath = '/mnt/${dataset.name}';
    final affectedShares =
        data.smbShares.items.where((share) => share.path == mountPath).length +
        data.nfsShares.items.where((share) => share.path == mountPath).length;
    final children = data.datasets.items
        .where((item) => item.name.startsWith('${dataset.name}/'))
        .length;

    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageLockDatasetTitle,
      server: _serverName(context, ref),
      target: dataset.name,
      actionLabel: l10n.storageLockDatasetAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.lock_outline_rounded,
          text: l10n.storageLockDatasetKey,
        ),
        if (children > 0)
          ImpactDetail(
            icon: Icons.account_tree_outlined,
            text: l10n.storageLockDatasetChildren(children),
          ),
        if (affectedShares > 0)
          ImpactDetail(
            icon: Icons.folder_off_outlined,
            text: l10n.storageLockDatasetShares(affectedShares),
          ),
      ],
      note: dataset.usesPassphrase
          ? l10n.storageLockDatasetNotePassphrase
          : l10n.storageLockDatasetNoteKey,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .lockDataset(dataset.id, forceUmount: true);
    if (!context.mounted) return;
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedLock(dataset.name),
      success: l10n.storageDatasetSuccessLock(dataset.name),
    );
  }

  /// Promotes a cloned dataset so it stops depending on its origin snapshot.
  ///
  /// This is not destructive, but it is not obvious either: it reverses which
  /// dataset owns the shared data, so the confirmation names the origin and
  /// says what becomes deletable afterwards.
  Future<void> _promoteDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
  ) async {
    final origin = dataset.origin;
    if (origin == null || origin.isEmpty) return;
    final originDataset = origin.split('@').first;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storagePromoteTitle(dataset.leafName),
      server: _serverName(context, ref),
      target: dataset.name,
      actionLabel: l10n.storagePromoteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.upgrade_rounded,
          text: l10n.storagePromoteOwnership(dataset.name, origin),
        ),
        ImpactDetail(
          icon: Icons.swap_horiz_rounded,
          text: l10n.storagePromoteReverses(originDataset, origin),
        ),
        ImpactDetail(
          icon: Icons.storage_rounded,
          text: l10n.storagePromoteSpace,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .promoteDataset(dataset.id);
    if (!context.mounted) return;
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedPromote(dataset.name),
      success: l10n.storageDatasetSuccessPromote(dataset.name),
    );
  }

  /// Unlocking is non-destructive, so it needs the secret rather than a
  /// destructive confirmation.
  Future<void> _unlockDataset(
    BuildContext context,
    WidgetRef ref,
    Dataset dataset,
  ) async {
    final request = await showModalBottomSheet<DatasetUnlockRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DatasetUnlockSheet(dataset: dataset),
    );
    if (request == null || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .unlockDataset(
          dataset.id,
          secret: request.secret,
          usePassphrase: request.usePassphrase,
          unlockChildren: request.unlockChildren,
        );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showDatasetResult(
      context,
      ref,
      receipt,
      failure: l10n.storageDatasetFailedUnlock(dataset.name),
      success: l10n.storageDatasetSuccessUnlock(dataset.name),
    );
  }

  /// Creates a new storage pool. The candidate disks are those not already
  /// part of a pool; the editor lets the user group them into data and cache
  /// vdevs. The whole flow routes through the shared high-impact confirmation
  /// because pool creation formats every selected disk.
  Future<void> _createPool(
    BuildContext context,
    WidgetRef ref,
    List<StorageDisk> disks,
  ) async {
    final used = disks
        .where((disk) => disk.pool != null && disk.pool!.isNotEmpty)
        .map((disk) => disk.name)
        .toSet();
    final candidates = disks
        .where((disk) => !used.contains(disk.name))
        .toList(growable: false);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).storageNoUnusedDisksForPool,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final configuration = await showModalBottomSheet<PoolConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => PoolCreateSheet(candidateDisks: candidates),
    );
    if (configuration == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final serverName = _serverName(context, ref);
    final diskCount = configuration.usedDisks.length;
    final hasRedundancy = configuration.dataVdevs.every(
      (v) => v.type != VdevType.stripe,
    );
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageCreatePoolTitle(configuration.name),
      server: serverName,
      target: configuration.name,
      actionLabel: l10n.storageCreatePoolAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.storageCreatePoolDisks(diskCount),
        ),
        if (!hasRedundancy)
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: l10n.storageCreatePoolNoRedundancy,
          ),
        if (configuration.encryption)
          ImpactDetail(
            icon: Icons.key_outlined,
            text: l10n.storageCreatePoolEncrypted,
          ),
      ],
      note: l10n.storageCreatePoolNote,
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createPool(configuration);
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: l10n.storagePoolFailedCreate(configuration.name),
      success: l10n.storagePoolSuccessCreate(configuration.name),
    );
  }

  /// Opens pool operations, then routes each destructive choice through the
  /// shared confirmation before calling the server.
  Future<void> _openPoolActions(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    ServerResources data, {
    required bool canScrub,
    required bool canControlScrub,
    required bool canToggleMembers,
    required bool canExport,
    required bool canAttach,
    required bool canReplace,
  }) async {
    final poolMemberNames = pool.members.map((member) => member.name).toSet();
    final candidateDisks = data.disks.items
        .where((disk) => disk.pool == null || disk.pool!.isEmpty)
        .where((disk) => !poolMemberNames.contains(disk.name))
        .toList(growable: false);
    final action = await showModalBottomSheet<PoolAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => PoolActionsSheet(
        pool: pool,
        candidateDisks: candidateDisks,
        canScrub: canScrub,
        canControlScrub: canControlScrub,
        canToggleMembers: canToggleMembers,
        canExport: canExport,
        canAttach: canAttach,
        canReplace: canReplace,
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case PoolScrubAction(:final action):
        await _controlScrub(context, ref, pool, action);
      case PoolMemberAction(:final member, :final online):
        await _togglePoolMember(context, ref, pool, member, online);
      case PoolAttachAction(:final targetVdev, :final disk):
        await _attachPoolDisk(context, ref, pool, targetVdev, disk);
      case PoolReplaceAction(:final member, :final disk, :final force):
        await _replacePoolDisk(context, ref, pool, member, disk, force: force);
      case PoolExportAction(:final destroyData, :final takeSnapshotsOffline):
        await _exportPool(
          context,
          ref,
          pool,
          data,
          destroyData: destroyData,
          takeSnapshotsOffline: takeSnapshotsOffline,
        );
    }
  }

  /// Starting or pausing a scrub is reversible; stopping discards progress and
  /// therefore needs confirmation.
  Future<void> _controlScrub(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    ScrubControlAction? action,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (action == ScrubControlAction.stop) {
      final confirmed = await confirmDestructiveAction(
        context,
        title: l10n.storageStopScrubTitle,
        server: _serverName(context, ref),
        target: pool.name,
        actionLabel: l10n.storageStopScrubAction,
        impact: MutationImpact.high,
        consequences: [
          ImpactDetail(
            icon: Icons.restart_alt_rounded,
            text: l10n.storageStopScrubProgress,
          ),
          ImpactDetail(
            icon: Icons.shield_outlined,
            text: l10n.storageStopScrubUnverified,
          ),
        ],
      );
      if (!confirmed || !context.mounted) return;
    }

    final controller = ref.read(serverActionControllerProvider.notifier);
    final receipt = action == null
        ? await controller.startPoolScrub(pool.name)
        : await controller.controlPoolScrub(pool.name, action);
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: l10n.storagePoolFailedScrub(pool.name),
      success: action == null
          ? l10n.storagePoolSuccessScrubStarted(pool.name)
          : l10n.storagePoolSuccessScrubAction(
              l10n.scrubControlActionLabel(action),
              pool.name,
            ),
    );
  }

  Future<void> _togglePoolMember(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    PoolMember member,
    bool online,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!online) {
      final confirmed = await confirmDestructiveAction(
        context,
        title: l10n.storageOfflineTitle(member.name),
        server: _serverName(context, ref),
        target: '${pool.name} · ${member.name}',
        actionLabel: l10n.storageOfflineAction,
        impact: MutationImpact.high,
        consequences: [
          ImpactDetail(
            icon: Icons.health_and_safety_outlined,
            text: l10n.storageOfflineDegraded(pool.name),
          ),
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: l10n.storageOfflineSecondFailure,
          ),
        ],
        note: l10n.storageOfflineNote,
      );
      if (!confirmed || !context.mounted) return;
    }

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setPoolDiskOnline(pool.id, member.label, online: online);
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: online
          ? l10n.storagePoolFailedOnline(member.name)
          : l10n.storagePoolFailedOffline(member.name),
      success: online
          ? l10n.storagePoolSuccessOnline(member.name)
          : l10n.storagePoolSuccessOffline(member.name),
    );
  }

  Future<void> _attachPoolDisk(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    String targetVdev,
    String disk,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageAttachTitle(disk),
      server: _serverName(context, ref),
      target: '${pool.name} · $disk',
      actionLabel: l10n.storageAttachAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.sync_rounded,
          text: l10n.storageAttachResilver,
        ),
        ImpactDetail(
          icon: Icons.layers_outlined,
          text: l10n.storageAttachJoins(disk, pool.name),
        ),
      ],
      note: l10n.storageAttachNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .attachPoolDisk(poolId: pool.id, targetVdev: targetVdev, disk: disk);
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: l10n.storagePoolFailedAttach(disk, pool.name),
      success: l10n.storagePoolSuccessAttach(disk, pool.name),
    );
  }

  Future<void> _replacePoolDisk(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    PoolMember member,
    String disk, {
    required bool force,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageReplaceTitle(member.name, disk),
      server: _serverName(context, ref),
      target: '${pool.name} · ${member.name}',
      actionLabel: l10n.storageReplaceAction,
      // AGENTS.md names forced disk removal as critical: an ordinary replace
      // resilvers onto the new disk and can be undone, but forcing detaches a
      // member that is still being read. Only that variant demands typing.
      impact: force ? MutationImpact.critical : MutationImpact.high,
      confirmationText: force ? member.name : null,
      consequences: [
        ImpactDetail(
          icon: Icons.sync_rounded,
          text: l10n.storageReplaceResilver,
        ),
        ImpactDetail(
          icon: Icons.swap_horiz_rounded,
          text: l10n.storageReplaceRemoved(member.name, pool.name),
        ),
        if (force)
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: l10n.storageReplaceForce,
          ),
      ],
      note: l10n.storageReplaceNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .replacePoolDisk(
          poolId: pool.id,
          label: member.label,
          disk: disk,
          force: force,
        );
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: l10n.storagePoolFailedReplace(member.name, pool.name),
      success: l10n.storagePoolSuccessReplace(disk, pool.name),
    );
  }

  Future<void> _exportPool(
    BuildContext context,
    WidgetRef ref,
    StoragePool pool,
    ServerResources data, {
    required bool destroyData,
    required bool takeSnapshotsOffline,
  }) async {
    final datasets = data.datasets.items
        .where(
          (item) =>
              item.name == pool.name || item.name.startsWith('${pool.name}/'),
        )
        .length;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: destroyData
          ? l10n.storageDestroyPoolTitle
          : l10n.storageExportPoolTitle,
      server: _serverName(context, ref),
      target: pool.name,
      actionLabel: destroyData
          ? l10n.storageDestroyPoolAction
          : l10n.storageExportPoolAction,
      impact: MutationImpact.critical,
      confirmationText: pool.name,
      consequences: [
        if (destroyData)
          ImpactDetail(
            icon: Icons.delete_forever_rounded,
            text: l10n.storageDestroyPoolWiped(
              pool.name,
              formatBytes(pool.allocatedBytes),
            ),
          )
        else
          ImpactDetail(
            icon: Icons.eject_outlined,
            text: l10n.storageExportPoolDetached,
          ),
        ImpactDetail(
          icon: Icons.dataset_outlined,
          text: l10n.storageExportPoolDatasets(datasets),
        ),
        if (takeSnapshotsOffline)
          ImpactDetail(
            icon: Icons.link_off_rounded,
            text: l10n.storageExportPoolSharesDeleted,
          ),
      ],
      note: destroyData
          ? l10n.storageDestroyPoolNote
          : l10n.storageExportPoolNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .exportPool(
          pool.id,
          destroyData: destroyData,
          takeSnapshotsOffline: takeSnapshotsOffline,
        );
    if (!context.mounted) return;
    _showPoolResult(
      context,
      ref,
      receipt,
      failure: l10n.storagePoolFailedExport(pool.name),
      success: destroyData
          ? l10n.storagePoolSuccessDestroying(pool.name)
          : l10n.storagePoolSuccessExporting(pool.name),
    );
  }

  /// Shows the outcome of a pool operation.
  ///
  /// [failure] and [success] are whole localized sentences rather than verb
  /// fragments, because a fragment composed into a surrounding sentence
  /// cannot be translated correctly.
  void _showPoolResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String failure,
    required String success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(receipt == null ? error ?? failure : success),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _openIscsiPortalSheet(
    BuildContext context,
    WidgetRef ref,
    ServerActionController controller,
    List<String> choices,
  ) async {
    final configuration = await showModalBottomSheet<IscsiPortalConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => IscsiPortalSheet(availableAddresses: choices),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await controller.createIscsiPortal(configuration);
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: AppLocalizations.of(context).storageIscsiFailedCreatePortal,
      success: AppLocalizations.of(context).storageIscsiSuccessCreatePortal,
    );
  }

  Future<void> _editIscsiPortal(
    BuildContext context,
    WidgetRef ref,
    IscsiPortal portal,
  ) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final choices = await controller.loadIscsiPortalListenIpChoices();
    if (!context.mounted) return;
    if (choices == null) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedLoadPortals,
      );
      return;
    }
    final configuration = await showModalBottomSheet<IscsiPortalConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          IscsiPortalSheet(availableAddresses: choices, existingPortal: portal),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await controller.updateIscsiPortal(
      portal.id,
      configuration,
    );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdatePortal(portal.tag),
      success: l10n.storageIscsiSuccessUpdatePortal(portal.tag),
    );
  }

  Future<void> _createIscsiInitiator(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final configuration =
        await showModalBottomSheet<IscsiInitiatorConfiguration>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) => const IscsiInitiatorSheet(),
        );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createIscsiInitiator(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedCreateInitiator,
      success: l10n.storageIscsiSuccessCreateInitiator,
    );
  }

  Future<void> _editIscsiInitiator(
    BuildContext context,
    WidgetRef ref,
    IscsiInitiator initiator,
  ) async {
    final configuration =
        await showModalBottomSheet<IscsiInitiatorConfiguration>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) =>
              IscsiInitiatorSheet(existingInitiator: initiator),
        );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateIscsiInitiator(initiator.id, configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdateInitiator(initiator.id),
      success: l10n.storageIscsiSuccessUpdateInitiator(initiator.id),
    );
  }

  Future<void> _createIscsiTarget(
    BuildContext context,
    WidgetRef ref,
    List<IscsiPortal> portals,
    List<IscsiInitiator> initiators,
    List<IscsiAuth> auths,
  ) async {
    final configuration = await showModalBottomSheet<IscsiTargetConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => IscsiTargetSheet(
        portals: portals,
        initiators: initiators,
        auths: auths,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final controller = ref.read(serverActionControllerProvider.notifier);
    final valid = await controller.validateIscsiTargetName(configuration.name);
    if (!context.mounted) return;
    if (!valid) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedValidateTarget,
      );
      return;
    }
    final receipt = await controller.createIscsiTarget(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedCreateTarget(configuration.name),
      success: l10n.storageIscsiSuccessCreateTarget(configuration.name),
    );
  }

  Future<void> _editIscsiTarget(
    BuildContext context,
    WidgetRef ref,
    IscsiTarget target,
    List<IscsiPortal> portals,
    List<IscsiInitiator> initiators,
    List<IscsiAuth> auths,
  ) async {
    final configuration = await showModalBottomSheet<IscsiTargetConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => IscsiTargetSheet(
        portals: portals,
        initiators: initiators,
        auths: auths,
        existingTarget: target,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final controller = ref.read(serverActionControllerProvider.notifier);
    final valid = await controller.validateIscsiTargetName(
      configuration.name,
      existingId: target.id,
    );
    if (!context.mounted) return;
    if (!valid) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedValidateTarget,
      );
      return;
    }
    final receipt = await controller.updateIscsiTarget(
      target.id,
      configuration,
    );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdateTarget(configuration.name),
      success: l10n.storageIscsiSuccessUpdateTarget(configuration.name),
    );
  }

  Future<void> _createIscsiExtent(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final choices = await controller.loadIscsiExtentDiskChoices();
    if (!context.mounted) return;
    if (choices == null) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedLoadExtents,
      );
      return;
    }
    final configuration = await showModalBottomSheet<IscsiExtentConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => IscsiExtentSheet(diskChoices: choices),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await controller.createIscsiExtent(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedCreateExtent(configuration.name),
      success: l10n.storageIscsiSuccessCreateExtent(configuration.name),
    );
  }

  Future<void> _editIscsiExtent(
    BuildContext context,
    WidgetRef ref,
    IscsiExtent extent,
  ) async {
    final controller = ref.read(serverActionControllerProvider.notifier);
    final choices = await controller.loadIscsiExtentDiskChoices();
    if (!context.mounted) return;
    if (choices == null) {
      _showIscsiResult(
        context,
        ref,
        null,
        failure: AppLocalizations.of(context).storageIscsiFailedLoadExtents,
      );
      return;
    }
    final configuration = await showModalBottomSheet<IscsiExtentConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          IscsiExtentSheet(diskChoices: choices, existingExtent: extent),
    );
    if (configuration == null || !context.mounted) return;
    final receipt = await controller.updateIscsiExtent(
      extent.id,
      configuration,
    );
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdateExtent(configuration.name),
      success: l10n.storageIscsiSuccessUpdateExtent(configuration.name),
    );
  }

  Future<void> _createIscsiAssociation(
    BuildContext context,
    WidgetRef ref,
    List<IscsiTarget> targets,
    List<IscsiExtent> extents,
  ) async {
    if (targets.isEmpty || extents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).storageCreateTargetExtentFirst,
          ),
        ),
      );
      return;
    }
    final configuration =
        await showModalBottomSheet<IscsiTargetExtentConfiguration>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) =>
              IscsiTargetExtentSheet(targets: targets, extents: extents),
        );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createIscsiTargetExtent(configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedAssociate,
      success: l10n.storageIscsiSuccessAssociate,
    );
  }

  Future<void> _editIscsiAssociation(
    BuildContext context,
    WidgetRef ref,
    IscsiTargetExtent association,
    List<IscsiTarget> targets,
    List<IscsiExtent> extents,
  ) async {
    final configuration =
        await showModalBottomSheet<IscsiTargetExtentConfiguration>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (context) => IscsiTargetExtentSheet(
            targets: targets,
            extents: extents,
            existingAssociation: association,
          ),
        );
    if (configuration == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateIscsiTargetExtent(association.id, configuration);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final lunLabel =
        configuration.lunId?.toString() ?? l10n.storageLunAutomatic;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdateLun(lunLabel),
      success: l10n.storageIscsiSuccessUpdateLun(lunLabel),
    );
  }

  /// Shows the outcome of a SMB share operation.
  ///
  /// [failure] and [success] are whole localized sentences rather than verb
  /// fragments, because a fragment composed into a surrounding sentence
  /// cannot be translated correctly.
  void _showSmbResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String failure,
    String? success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(receipt == null ? error ?? failure : success ?? failure),
        showCloseIcon: receipt == null,
      ),
    );
  }

  /// Shows the outcome of a NFS share operation.
  ///
  /// [failure] and [success] are whole localized sentences rather than verb
  /// fragments, because a fragment composed into a surrounding sentence
  /// cannot be translated correctly.
  void _showNfsResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String failure,
    String? success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(receipt == null ? error ?? failure : success ?? failure),
        showCloseIcon: receipt == null,
      ),
    );
  }

  /// Opens the CHAP credential manager. Create/edit/delete route back here
  /// and through the shared confirmation before any server call.
  Future<void> _manageIscsiAuth(
    BuildContext context,
    WidgetRef ref,
    List<IscsiAuth> auths, {
    required bool canCreate,
    required bool canEdit,
    required bool canDelete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, sheetSetState) {
          return IscsiAuthManagementSheet(
            auths: auths,
            canCreate: canCreate,
            canEdit: canEdit,
            canDelete: canDelete,
            onNextTag: () => _nextIscsiAuthTag(auths),
            onCreate: (nextTag) async {
              final configuration = await _promptCreateIscsiAuth(
                context,
                nextTag,
              );
              if (configuration == null || !context.mounted) return null;
              Navigator.of(sheetContext).maybePop();
              await _createIscsiAuth(context, ref, configuration);
              return null;
            },
            onEdit: (existing) async {
              final configuration = await _promptEditIscsiAuth(
                context,
                existing,
              );
              if (configuration == null || !context.mounted) return null;
              Navigator.of(sheetContext).maybePop();
              await _editIscsiAuth(context, ref, existing, configuration);
              return null;
            },
            onDelete: (auth) async {
              final did = await _deleteIscsiAuth(context, ref, auth, auths);
              if (did) sheetSetState(() {});
              return did;
            },
          );
        },
      ),
    );
    if (context.mounted) {
      refreshServerResources(ref);
    }
  }

  /// The next free tag for a new CHAP credential. TrueNAS tags credentials
  /// with a small positive integer; reuse the lowest unused one.
  int _nextIscsiAuthTag(List<IscsiAuth> existing) {
    final used = existing.map((auth) => auth.tag).toSet();
    var tag = 1;
    while (used.contains(tag)) {
      tag++;
    }
    return tag;
  }

  Future<IscsiAuthConfiguration?> _promptCreateIscsiAuth(
    BuildContext context,
    int nextTag,
  ) async {
    return showModalBottomSheet<IscsiAuthConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => IscsiAuthSheet(nextTag: nextTag),
    );
  }

  Future<IscsiAuthConfiguration?> _promptEditIscsiAuth(
    BuildContext context,
    IscsiAuth existing,
  ) async {
    return showModalBottomSheet<IscsiAuthConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => IscsiAuthSheet(existingAuth: existing),
    );
  }

  /// Creates a CHAP credential. The secret is sent only to the server over the
  /// authenticated session and discarded afterwards.
  Future<void> _createIscsiAuth(
    BuildContext context,
    WidgetRef ref,
    IscsiAuthConfiguration configuration,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageChapCreateTitle,
      server: _serverName(context, ref),
      target: configuration.user,
      actionLabel: l10n.storageChapCreateAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.key_outlined,
          text: l10n.storageChapCreateStored,
        ),
        if (configuration.isMutual)
          ImpactDetail(
            icon: Icons.shield_moon_outlined,
            text: l10n.storageChapCreateMutual,
          ),
      ],
      note: l10n.storageChapCreateNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createIscsiAuth(
          tag: configuration.tag,
          user: configuration.user,
          secret: configuration.secret ?? '',
          peerUser: configuration.isMutual && configuration.peerUser.isNotEmpty
              ? configuration.peerUser
              : null,
          peerSecret: configuration.peerSecret,
        );
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedCreateChap(configuration.user),
      success: l10n.storageIscsiSuccessCreateChap(configuration.user),
    );
  }

  /// Updates a CHAP credential. Secrets left blank keep the server-side value;
  /// typing a new one rotates it.
  Future<void> _editIscsiAuth(
    BuildContext context,
    WidgetRef ref,
    IscsiAuth existing,
    IscsiAuthConfiguration configuration,
  ) async {
    final rotatingSecret =
        configuration.secret != null && configuration.secret!.isNotEmpty;
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageChapUpdateTitle(existing.user),
      server: _serverName(context, ref),
      target: existing.user,
      actionLabel: l10n.storageChapUpdateAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.sync_rounded,
          text: l10n.storageChapUpdateImmediate,
        ),
        if (rotatingSecret)
          ImpactDetail(
            icon: Icons.key_outlined,
            text: l10n.storageChapUpdateRotated,
          ),
      ],
      note: rotatingSecret
          ? l10n.storageChapUpdateNoteRotating
          : l10n.storageChapUpdateNoteUnchanged,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateIscsiAuth(
          existing.id,
          tag: configuration.tag,
          user: configuration.user,
          secret: configuration.secret,
          peerUser: configuration.isMutual ? configuration.peerUser : '',
          peerSecret: configuration.peerSecret,
        );
    if (!context.mounted) return;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedUpdateChap(existing.user),
      success: l10n.storageIscsiSuccessUpdateChap(existing.user),
    );
  }

  /// Deletes a CHAP credential. Targets and initiator groups that still
  /// reference it must be updated first; the confirmation counts references.
  Future<bool> _deleteIscsiAuth(
    BuildContext context,
    WidgetRef ref,
    IscsiAuth auth,
    List<IscsiAuth> allAuths,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.storageChapDeleteTitle(auth.user),
      server: _serverName(context, ref),
      target: auth.user,
      actionLabel: l10n.storageChapDeleteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.storageChapDeleteAuth,
        ),
        ImpactDetail(
          icon: Icons.delete_outline_rounded,
          text: l10n.storageChapDeleteSecret,
        ),
      ],
      note: l10n.storageChapDeleteNote,
    );
    if (!confirmed || !context.mounted) return false;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteIscsiAuth(auth.id);
    if (!context.mounted) return false;
    _showIscsiResult(
      context,
      ref,
      receipt,
      failure: l10n.storageIscsiFailedDeleteChap(auth.user),
      success: l10n.storageIscsiSuccessDeleteChap(auth.user),
    );
    return receipt != null;
  }

  /// Shows the outcome of a iSCSI operation.
  ///
  /// [failure] and [success] are whole localized sentences rather than verb
  /// fragments, because a fragment composed into a surrounding sentence
  /// cannot be translated correctly.
  void _showIscsiResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String failure,
    String? success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(receipt == null ? error ?? failure : success ?? failure),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard(this.pool, {this.onOpen});
  final StoragePool pool;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final online = pool.status == 'ONLINE';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pool.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _StatusPill(
                      label: pool.status,
                      good: online,
                      warning: pool.status == 'DEGRADED',
                    ),
                    if (onOpen != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ],
                ),
                if (pool.scan case final scan? when scan.isRunning) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${scan.isScrub ? l10n.storageScanScrubInProgress : l10n.storageScanResilverInProgress}'
                    '${scan.percentage == null ? '' : ' · '
                              '${scan.percentage!.toStringAsFixed(1)}%'}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 18),
                if (pool.usedFraction case final fraction?) ...[
                  LinearProgressIndicator(
                    value: fraction,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _ValueLabel(
                        value: formatBytes(pool.allocatedBytes),
                        label: l10n.storageLabelUsed,
                      ),
                    ),
                    Expanded(
                      child: _ValueLabel(
                        value: formatBytes(pool.freeBytes),
                        label: l10n.storageLabelFree,
                      ),
                    ),
                    Expanded(
                      child: _ValueLabel(
                        value: pool.fragmentation ?? '—',
                        label: l10n.storageLabelFragmentation,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.count,
    required this.action,
    required this.onAction,
  });
  final String title;
  final int count;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$title  $count',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(action),
        ),
      ],
    );
  }
}

class _ShareSectionHeading extends StatelessWidget {
  const _ShareSectionHeading({
    required this.title,
    required this.count,
    required this.canCreateSmb,
    required this.canCreateNfs,
    required this.canCreateIscsiPortal,
    required this.canCreateIscsiInitiator,
    required this.canCreateIscsiTarget,
    required this.canCreateIscsiExtent,
    required this.canCreateIscsiAssociation,
    required this.onSelected,
  });

  final String title;
  final int count;
  final bool canCreateSmb;
  final bool canCreateNfs;
  final bool canCreateIscsiPortal;
  final bool canCreateIscsiInitiator;
  final bool canCreateIscsiTarget;
  final bool canCreateIscsiExtent;
  final bool canCreateIscsiAssociation;
  final ValueChanged<_ShareCreateType> onSelected;

  bool get _canCreateAny =>
      canCreateSmb ||
      canCreateNfs ||
      canCreateIscsiPortal ||
      canCreateIscsiInitiator ||
      canCreateIscsiTarget ||
      canCreateIscsiExtent ||
      canCreateIscsiAssociation;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$title  $count',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      PopupMenuButton<_ShareCreateType>(
        enabled: _canCreateAny,
        onSelected: onSelected,
        itemBuilder: (context) {
          final l10n = AppLocalizations.of(context);
          return [
            PopupMenuItem(
              value: _ShareCreateType.smb,
              enabled: canCreateSmb,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.computer_rounded),
                title: Text(l10n.storageSmbShare),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.nfs,
              enabled: canCreateNfs,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_shared_outlined),
                title: Text(l10n.storageNfsShare),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.iscsiPortal,
              enabled: canCreateIscsiPortal,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.router_outlined),
                title: Text(l10n.storageIscsiPortal),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.iscsiInitiator,
              enabled: canCreateIscsiInitiator,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.devices_other_outlined),
                title: Text(l10n.storageIscsiInitiatorGroup),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.iscsiTarget,
              enabled: canCreateIscsiTarget,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.hub_outlined),
                title: Text(l10n.storageIscsiTarget),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.iscsiExtent,
              enabled: canCreateIscsiExtent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.dns_outlined),
                title: Text(l10n.storageIscsiExtent),
              ),
            ),
            PopupMenuItem(
              value: _ShareCreateType.iscsiAssociation,
              enabled: canCreateIscsiAssociation,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link_rounded),
                title: Text(l10n.storageIscsiLunAssociation),
              ),
            ),
          ];
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _canCreateAny
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: _canCreateAny
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).storageCreateShort,
                style: TextStyle(
                  color: _canCreateAny
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ReadOnlyHeading extends StatelessWidget {
  const _ReadOnlyHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) =>
      Text('$title  $count', style: Theme.of(context).textTheme.titleLarge);
}

class StorageDiskList extends StatelessWidget {
  const StorageDiskList({
    required this.disks,
    required this.temperatures,
    super.key,
  });

  final List<StorageDisk> disks;
  final DiskTemperatureReport temperatures;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sortedDisks = sortStorageDisksNaturally(disks);
    return Card(
      child: Column(
        children: [
          for (final (index, disk) in sortedDisks.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              leading: Icon(
                disk.isSolidState
                    ? Icons.memory_rounded
                    : Icons.disc_full_outlined,
              ),
              title: Text(
                l10n.storageDiskTitle(
                  disk.name,
                  l10n.diskModelLabel(disk.model),
                ),
              ),
              subtitle: Text(
                '${formatBytes(disk.sizeBytes)} · ${l10n.diskSerialLabel(disk.serial)}'
                '${disk.pool == null ? '' : ' · ${disk.pool}'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DiskTemperatureLabel(
                    temperature: temperatures.forDisk(disk.name),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => _DiskDetails(
                  disk: disk,
                  temperature: temperatures.forDisk(disk.name),
                ),
              ),
            ),
            if (index < sortedDisks.length - 1)
              const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

class _DiskDetails extends StatelessWidget {
  const _DiskDetails({required this.disk, required this.temperature});

  final StorageDisk disk;
  final DiskTemperature? temperature;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(disk.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            _StorageDetail(
              label: l10n.storageDiskLabelModel,
              value: l10n.diskModelLabel(disk.model),
            ),
            _StorageDetail(
              label: l10n.storageDiskLabelSerial,
              value: l10n.diskSerialLabel(disk.serial),
            ),
            _StorageDetail(
              label: l10n.storageDiskLabelCapacity,
              value: formatBytes(disk.sizeBytes),
            ),
            _StorageDetail(label: l10n.storageDiskLabelMedia, value: disk.type),
            _StorageDetail(
              label: l10n.storageDiskLabelPool,
              value: disk.pool ?? l10n.storageDiskLabelUnassigned,
            ),
            if (disk.rotationRate != null)
              _StorageDetail(
                label: l10n.storageDiskLabelRotation,
                value: disk.rotationRate == 0
                    ? l10n.storageDiskSolidState
                    : '${disk.rotationRate} RPM',
              ),
            _StorageDetail(
              label: l10n.storageDiskLabelTemperature,
              // A drive TrueNAS could not read is unknown, not cold.
              value: temperature?.isKnown == true
                  ? '${temperature!.celsius}°C'
                  : l10n.storageDiskUnavailable,
            ),
            if (temperature?.maximum != null)
              _StorageDetail(
                label: l10n.storageDiskLabelRatedMaximum,
                value: '${temperature!.maximum}°C',
              ),
            if (temperature?.critical != null)
              _StorageDetail(
                label: l10n.storageDiskLabelCriticalAt,
                value: '${temperature!.critical}°C',
              ),
          ],
        ),
      ),
    );
  }
}

class _StorageDetail extends StatelessWidget {
  const _StorageDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _ShareList extends StatelessWidget {
  const _ShareList({
    required this.smb,
    required this.nfs,
    required this.web,
    required this.iscsiTargets,
    required this.iscsiExtents,
    required this.iscsiPortals,
    required this.iscsiInitiators,
    required this.iscsiTargetExtents,
    required this.iscsiAuths,
    required this.canManageIscsiAuth,
    required this.canCreateIscsiAuth,
    required this.canEditIscsiAuth,
    required this.canDeleteIscsiAuth,
    required this.onManageIscsiAuth,
    required this.canEditSmb,
    required this.canEditNfs,
    required this.canDeleteSmb,
    required this.canDeleteNfs,
    required this.canEditSmbAcl,
    required this.canEditIscsiPortal,
    required this.canEditIscsiInitiator,
    required this.canEditIscsiTarget,
    required this.canEditIscsiExtent,
    required this.canEditIscsiAssociation,
    required this.onEditSmb,
    required this.onEditNfs,
    required this.onDeleteSmb,
    required this.onEditSmbAcl,
    required this.onDeleteNfs,
    required this.onEditIscsiPortal,
    required this.onEditIscsiInitiator,
    required this.onEditIscsiTarget,
    required this.onEditIscsiExtent,
    required this.onEditIscsiAssociation,
    required this.onDeleteIscsiPortal,
    required this.onDeleteIscsiInitiator,
    required this.onDeleteIscsiTarget,
    required this.onDeleteIscsiExtent,
    required this.onDeleteIscsiAssociation,
  });

  final ResourceSection<SmbShare> smb;
  final ResourceSection<NfsShare> nfs;
  final ResourceSection<WebShare> web;
  final ResourceSection<IscsiTarget> iscsiTargets;
  final ResourceSection<IscsiExtent> iscsiExtents;
  final ResourceSection<IscsiPortal> iscsiPortals;
  final ResourceSection<IscsiInitiator> iscsiInitiators;
  final ResourceSection<IscsiTargetExtent> iscsiTargetExtents;
  final ResourceSection<IscsiAuth> iscsiAuths;
  final bool canManageIscsiAuth;
  final bool canCreateIscsiAuth;
  final bool canEditIscsiAuth;
  final bool canDeleteIscsiAuth;
  final VoidCallback onManageIscsiAuth;
  final bool canEditSmb;
  final bool canEditNfs;
  final bool canDeleteSmb;
  final bool canDeleteNfs;
  final bool canEditSmbAcl;
  final bool canEditIscsiPortal;
  final bool canEditIscsiInitiator;
  final bool canEditIscsiTarget;
  final bool canEditIscsiExtent;
  final bool canEditIscsiAssociation;
  final ValueChanged<SmbShare> onEditSmb;
  final ValueChanged<NfsShare> onEditNfs;
  final ValueChanged<SmbShare> onDeleteSmb;
  final ValueChanged<SmbShare> onEditSmbAcl;
  final ValueChanged<NfsShare> onDeleteNfs;
  final ValueChanged<IscsiPortal> onEditIscsiPortal;
  final ValueChanged<IscsiInitiator> onEditIscsiInitiator;
  final ValueChanged<IscsiTarget> onEditIscsiTarget;
  final ValueChanged<IscsiExtent> onEditIscsiExtent;
  final ValueChanged<IscsiTargetExtent> onEditIscsiAssociation;

  /// Null when the connected account cannot delete that resource type.
  final ValueChanged<IscsiPortal>? onDeleteIscsiPortal;
  final ValueChanged<IscsiInitiator>? onDeleteIscsiInitiator;
  final ValueChanged<IscsiTarget>? onDeleteIscsiTarget;
  final ValueChanged<IscsiExtent>? onDeleteIscsiExtent;
  final ValueChanged<IscsiTargetExtent>? onDeleteIscsiAssociation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A section the server does not expose is not an error worth showing:
    // the surface simply is not there on this version.
    String? reportable(DataMessage? error) =>
        error == null || error.code == DataMessageCode.methodUnavailable
        ? null
        : l10n.dataMessage(error);
    final errors = <String>[
      if (reportable(smb.error) case final detail?)
        l10n.storageSectionError('SMB', detail),
      if (reportable(nfs.error) case final detail?)
        l10n.storageSectionError('NFS', detail),
      if (reportable(web.error) case final detail?)
        l10n.storageSectionError('WebShare', detail),
      if (reportable(iscsiTargets.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiTargetsLabel, detail),
      if (reportable(iscsiExtents.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiExtentsLabel, detail),
      if (reportable(iscsiPortals.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiPortalsLabel, detail),
      if (reportable(iscsiInitiators.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiInitiatorsLabel, detail),
      if (reportable(iscsiTargetExtents.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiAssociationsLabel, detail),
      if (reportable(iscsiAuths.error) case final detail?)
        l10n.storageSectionError(l10n.storageIscsiChapLabel, detail),
    ];
    if (smb.items.isEmpty &&
        nfs.items.isEmpty &&
        web.items.isEmpty &&
        iscsiTargets.items.isEmpty &&
        iscsiExtents.items.isEmpty &&
        iscsiPortals.items.isEmpty &&
        iscsiInitiators.items.isEmpty &&
        iscsiTargetExtents.items.isEmpty &&
        iscsiAuths.items.isEmpty &&
        errors.isEmpty) {
      return _EmptySection(
        icon: Icons.folder_shared_outlined,
        message: l10n.storageNoSharesFound,
      );
    }
    final entries = <Widget>[
      for (final share in smb.items)
        _ShareTile(
          icon: Icons.computer_rounded,
          title: share.name,
          subtitle:
              l10n.storageShareProtocolPath('SMB', share.path) +
              (share.readOnly ? l10n.storageReadOnlySuffix : ''),
          enabled: share.enabled,
          locked: share.locked,
          onTap: canEditSmb ? () => onEditSmb(share) : null,
          onDelete: canDeleteSmb ? () => onDeleteSmb(share) : null,
          onEditAcl: canEditSmbAcl ? () => onEditSmbAcl(share) : null,
          aclTooltip: l10n.storageEditSmbPermissions,
        ),
      for (final share in nfs.items)
        _ShareTile(
          icon: Icons.folder_shared_outlined,
          title: share.comment ?? share.path.split('/').last,
          subtitle:
              l10n.storageNfsListSubtitle(
                share.path,
                share.networks.isEmpty && share.hosts.isEmpty
                    ? l10n.storageNfsReviewClientsAll
                    : [...share.networks, ...share.hosts].join(', '),
              ) +
              (share.readOnly ? l10n.storageReadOnlySuffix : ''),
          enabled: share.enabled,
          locked: share.locked,
          onTap: canEditNfs ? () => onEditNfs(share) : null,
          onDelete: canDeleteNfs ? () => onDeleteNfs(share) : null,
        ),
      for (final share in web.items)
        _ShareTile(
          icon: Icons.language_rounded,
          title: share.name,
          subtitle: l10n.storageWebShareSubtitle(share.path),
          enabled: share.enabled,
          locked: share.locked,
        ),
      for (final target in iscsiTargets.items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.hub_outlined),
          title: Text(target.alias ?? target.name),
          subtitle: Text(
            l10n.storageIscsiTargetListSubtitle(
              l10n.storageServerValue(target.mode),
              target.name,
              target.groupCount,
            ),
          ),
          trailing: _IscsiTrailing(
            onDelete: onDeleteIscsiTarget == null
                ? null
                : () => onDeleteIscsiTarget!(target),
          ),
          onTap: canEditIscsiTarget
              ? () => onEditIscsiTarget(target)
              : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _IscsiTargetDetails(target: target),
                ),
        ),
      for (final portal in iscsiPortals.items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.router_outlined),
          title: Text(
            portal.comment.isEmpty
                ? l10n.storageIscsiPortalFallbackLabel(portal.tag)
                : portal.comment,
          ),
          subtitle: Text(
            l10n.storageIscsiPortalWithAddress(portal.addressSummary),
          ),
          trailing: _IscsiTrailing(
            onDelete: onDeleteIscsiPortal == null
                ? null
                : () => onDeleteIscsiPortal!(portal),
          ),
          onTap: canEditIscsiPortal ? () => onEditIscsiPortal(portal) : null,
        ),
      for (final initiator in iscsiInitiators.items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.devices_other_outlined),
          title: Text(
            initiator.comment.isEmpty
                ? l10n.storageIscsiInitiatorFallbackLabel(initiator.id)
                : initiator.comment,
          ),
          subtitle: Text(
            initiator.allowsAll
                ? l10n.storageIscsiInitiatorListAll
                : l10n.storageIscsiInitiatorListAllowed(
                    initiator.initiators.length,
                  ),
          ),
          trailing: _IscsiTrailing(
            onDelete: onDeleteIscsiInitiator == null
                ? null
                : () => onDeleteIscsiInitiator!(initiator),
          ),
          onTap: canEditIscsiInitiator
              ? () => onEditIscsiInitiator(initiator)
              : null,
        ),
      for (final association in iscsiTargetExtents.items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.link_rounded),
          title: Text(
            l10n.storageIscsiAssociationLabel(
              association.targetId,
              association.extentId,
            ),
          ),
          subtitle: Text(
            l10n.storageIscsiLunSubtitle(
              association.lunId?.toString() ?? l10n.storageLunAutomatic,
            ),
          ),
          trailing: _IscsiTrailing(
            onDelete: onDeleteIscsiAssociation == null
                ? null
                : () => onDeleteIscsiAssociation!(association),
          ),
          onTap: canEditIscsiAssociation
              ? () => onEditIscsiAssociation(association)
              : null,
        ),
      for (final extent in iscsiExtents.items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.dns_outlined),
          title: Text(extent.name),
          subtitle: Text(
            extent.readOnly
                ? l10n.storageIscsiExtentListSubtitleReadOnly(
                    l10n.storageServerValue(extent.type),
                    extent.backingStore,
                  )
                : l10n.storageIscsiExtentListSubtitle(
                    l10n.storageServerValue(extent.type),
                    extent.backingStore,
                  ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusPill(
                label: extent.locked
                    ? l10n.storageBadgeLocked
                    : extent.enabled
                    ? l10n.storageBadgeEnabled
                    : l10n.storageBadgeDisabled,
                good: extent.enabled && !extent.locked,
                warning: !extent.enabled && !extent.locked,
              ),
              if (onDeleteIscsiExtent != null)
                IconButton(
                  onPressed: () => onDeleteIscsiExtent!(extent),
                  tooltip: l10n.storageDeleteExtentTooltip,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
          onTap: canEditIscsiExtent && !extent.locked
              ? () => onEditIscsiExtent(extent)
              : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => _IscsiExtentDetails(extent: extent),
                ),
        ),
      if (canManageIscsiAuth || iscsiAuths.items.isNotEmpty)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          leading: const Icon(Icons.shield_outlined),
          title: Text(l10n.storageChapCredentials),
          subtitle: Text(
            iscsiAuths.items.isEmpty
                ? l10n.storageIscsiAuthListEmpty
                : l10n.storageIscsiAuthListCount(iscsiAuths.items.length),
          ),
          onTap: canManageIscsiAuth ? onManageIscsiAuth : null,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errors.isNotEmpty) ...[
          _SectionError(message: errors.join('\n')),
          const SizedBox(height: 10),
        ],
        if (entries.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (final (index, entry) in entries.indexed) ...[
                  entry,
                  if (index < entries.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.locked,
    this.onTap,
    this.onDelete,
    this.onEditAcl,
    this.aclTooltip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEditAcl;
  final String? aclTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPill(
            label: locked
                ? l10n.storageBadgeLocked
                : enabled
                ? l10n.storageBadgeEnabled
                : l10n.storageBadgeDisabled,
            good: enabled && !locked,
            warning: !enabled && !locked,
          ),
          if (onEditAcl != null)
            IconButton(
              onPressed: onEditAcl,
              tooltip: aclTooltip ?? l10n.storageEditSharePermissions,
              icon: const Icon(Icons.security_outlined),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: l10n.storageDeleteShareTooltip,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Asks whether an extent's backing file or zvol should be destroyed along
/// with the extent record. Returns true to destroy, false to keep the data.
class _IscsiExtentDeleteSheet extends StatefulWidget {
  const _IscsiExtentDeleteSheet({required this.extent});

  final IscsiExtent extent;

  @override
  State<_IscsiExtentDeleteSheet> createState() =>
      _IscsiExtentDeleteSheetState();
}

class _IscsiExtentDeleteSheetState extends State<_IscsiExtentDeleteSheet> {
  bool _removeBacking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.storageDeleteExtentSheetTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.extent.name} · ${widget.extent.backingStore}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.storageDeleteExtentAlsoDestroy,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              subtitle: Text(
                l10n.storageDeleteExtentBackingWarning(
                  widget.extent.backingStore,
                ),
              ),
              value: _removeBacking,
              onChanged: (value) => setState(() => _removeBacking = value),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_removeBacking),
              child: Text(l10n.actionContinue),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing affordance for an iSCSI row: a chevron, plus a delete button when
/// the connected account is allowed to remove that resource.
class _IscsiTrailing extends StatelessWidget {
  const _IscsiTrailing({required this.onDelete});

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (onDelete == null) return const Icon(Icons.chevron_right_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.chevron_right_rounded),
        IconButton(
          onPressed: onDelete,
          tooltip: AppLocalizations.of(context).storageDeleteTooltip,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _IscsiTargetDetails extends StatelessWidget {
  const _IscsiTargetDetails({required this.target});

  final IscsiTarget target;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              target.alias ?? target.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            _StorageDetail(label: l10n.storageDetailTarget, value: target.name),
            _StorageDetail(label: l10n.storageDetailMode, value: target.mode),
            _StorageDetail(
              label: l10n.storageDetailGroups,
              value: '${target.groupCount} configured',
            ),
          ],
        ),
      ),
    );
  }
}

class _IscsiExtentDetails extends StatelessWidget {
  const _IscsiExtentDetails({required this.extent});

  final IscsiExtent extent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(extent.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            _StorageDetail(label: l10n.storageDetailType, value: extent.type),
            _StorageDetail(
              label: l10n.storageDetailBacking,
              value: extent.backingStore,
            ),
            if (extent.type == 'FILE')
              _StorageDetail(
                label: l10n.storageDetailCapacity,
                value: formatBytes(extent.sizeBytes),
              ),
            _StorageDetail(
              label: l10n.storageDetailBlockSize,
              value: l10n.storageDetailBlockSizeValue(extent.blockSize),
            ),
            _StorageDetail(
              label: l10n.storageDetailAccess,
              value: extent.readOnly
                  ? l10n.storageDetailAccessReadOnly
                  : l10n.storageDetailAccessReadWrite,
            ),
            _StorageDetail(
              label: l10n.storageDetailState,
              value: extent.locked
                  ? l10n.storageDetailStateLocked
                  : extent.enabled
                  ? l10n.storageDetailStateEnabled
                  : l10n.storageDetailStateDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateSnapshotSheet extends ConsumerStatefulWidget {
  const _CreateSnapshotSheet({required this.dataset});
  final Dataset dataset;

  @override
  ConsumerState<_CreateSnapshotSheet> createState() =>
      _CreateSnapshotSheetState();
}

class _CreateSnapshotSheetState extends ConsumerState<_CreateSnapshotSheet> {
  late final TextEditingController _nameController;
  bool _recursive = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    _nameController = TextEditingController(
      text:
          'manual-${now.year}${two(now.month)}${two(now.day)}-'
          '${two(now.hour)}${two(now.minute)}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref
        .watch(serverActionControllerProvider)
        .isBusy('snapshot:${widget.dataset.name}');
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.storageCreateSnapshotTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(widget.dataset.name),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              enabled: !busy,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.storageSnapshotNameLabel,
                prefixIcon: const Icon(Icons.camera_outlined),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.storageIncludeChildDatasets),
              subtitle: Text(l10n.storageCreateSnapshotRecursively),
              value: _recursive,
              onChanged: busy
                  ? null
                  : (value) => setState(() => _recursive = value),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: busy || _nameController.text.trim().isEmpty
                  ? null
                  : _create,
              icon: const Icon(Icons.camera_rounded),
              label: Text(
                busy
                    ? l10n.storageSnapshotCreating
                    : l10n.storageCreateSnapshotTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createSnapshot(
          dataset: widget.dataset.name,
          name: _nameController.text.trim(),
          recursive: _recursive,
        );
    if (!mounted) return;
    if (receipt != null) {
      Navigator.pop(context, true);
    } else {
      _showActionError(
        context,
        ref.read(serverActionControllerProvider).errorMessage,
      );
    }
  }
}

void _showActionError(BuildContext context, String? message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message ?? AppLocalizations.of(context).storageActionFailed,
      ),
    ),
  );
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    this.good = false,
    this.warning = false,
  });
  final String label;
  final bool good;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = good
        ? const Color(0xFFD8F3E4)
        : warning
        ? const Color(0xFFFFE8B6)
        : colors.errorContainer;
    final foreground = good
        ? const Color(0xFF175C38)
        : warning
        ? const Color(0xFF6B4E00)
        : colors.onErrorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
