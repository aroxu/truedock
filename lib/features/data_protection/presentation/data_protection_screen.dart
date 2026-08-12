import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/widgets/resource_landing_screen.dart';
import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../system/presentation/system_resources_provider.dart';
import '../domain/snapshot_task_configuration.dart';
import '../domain/replication_configuration.dart';
import '../domain/cloud_sync_configuration.dart';
import '../domain/rsync_configuration.dart';
import '../domain/task_schedule.dart';
import 'snapshot_actions_sheet.dart';
import 'snapshot_task_sheet.dart';
import 'replication_task_sheet.dart';
import 'cloud_sync_task_sheet.dart';
import 'cloud_backup_section.dart';
import 'rsync_task_sheet.dart';
import '../../../core/l10n/data_message_localizations.dart';

class DataProtectionScreen extends ConsumerWidget {
  const DataProtectionScreen({super.key});

  ResourceLandingScreen _landing(AppLocalizations l10n) =>
      ResourceLandingScreen(
        title: l10n.protectionTitle,
        description: l10n.protectionLandingDescription,
        icon: Icons.shield_rounded,
        features: [
          (
            icon: Icons.copy_all_outlined,
            title: l10n.protectionReplication,
            subtitle: l10n.protectionReplicationSubtitle,
          ),
          (
            icon: Icons.schedule_outlined,
            title: l10n.protectionSnapshotTasks,
            subtitle: l10n.protectionSnapshotTasksSubtitle,
          ),
          (
            icon: Icons.cloud_sync_outlined,
            title: l10n.protectionCloudSync,
            subtitle: l10n.protectionCloudSyncSubtitle,
          ),
          (
            icon: Icons.cleaning_services_outlined,
            title: l10n.protectionScrubs,
            subtitle: l10n.protectionScrubsSubtitle,
          ),
          (
            icon: Icons.sync_alt_rounded,
            title: l10n.protectionRsync,
            subtitle: l10n.protectionRsyncSubtitle,
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    if (!connection.hasRetainedSession) return _landing(l10n);
    final resources = ref.watch(serverResourcesProvider);
    final actions = ref.watch(serverActionControllerProvider);
    final canDeleteSnapshot =
        connection.capabilities?.supports('pool.snapshot.delete') == true;
    final canRollbackSnapshot =
        connection.capabilities?.supports('pool.snapshot.rollback') == true;
    final canCloneSnapshot =
        connection.capabilities?.supports('pool.snapshot.clone') == true;
    final canHoldSnapshot =
        connection.capabilities?.supports('pool.snapshot.hold') == true &&
        connection.capabilities?.supports('pool.snapshot.release') == true;
    return SafeRefreshIndicator(
      onRefresh: () async {
        refreshServerResources(ref);
        await ref.read(serverResourcesProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(title: Text(l10n.protectionTitle)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: resources.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, _) =>
                  SliverToBoxAdapter(child: Text(l10n.protectionLoadFailed)),
              data: (data) => SliverList.list(
                children: [
                  _ProtectionSummary(resources: data),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.protectionReplication,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed:
                            connection.capabilities?.supports(
                                  'replication.create',
                                ) ==
                                true
                            ? () => _createReplicationTask(
                                context,
                                ref,
                                data.datasets.items,
                              )
                            : null,
                        tooltip: l10n.protectionNewReplication,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ReplicationList(
                    section: data.replications,
                    canRun:
                        connection.capabilities?.supports('replication.run') ==
                        true,
                    canDelete:
                        connection.capabilities?.supports(
                          'replication.delete',
                        ) ==
                        true,
                    canEdit:
                        connection.capabilities?.supports(
                          'replication.update',
                        ) ==
                        true,
                    onEdit: (task) => _editReplicationTask(
                      context,
                      ref,
                      task,
                      data.datasets.items,
                    ),
                    isBusy: (task) => actions.isBusy('replication:${task.id}'),
                    onRun: (task) => _runReviewedTask(
                      context,
                      ref,
                      title: l10n.protectionRunTaskTitle(task.name),
                      message: l10n.protectionRunReplicationMessage(
                        task.direction.toLowerCase(),
                      ),
                      actionLabel: l10n.protectionRunReplication,
                      operation: () => ref
                          .read(serverActionControllerProvider.notifier)
                          .runReplication(task.id),
                    ),
                    onDelete: (task) =>
                        _deleteReplicationTask(context, ref, task),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.protectionSnapshotTasks,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed:
                            connection.capabilities?.supports(
                                  'pool.snapshottask.create',
                                ) ==
                                true
                            ? () => _createSnapshotTask(
                                context,
                                ref,
                                data.datasets.items,
                              )
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        tooltip:
                            connection.capabilities?.supports(
                                  'pool.snapshottask.create',
                                ) ==
                                true
                            ? l10n.protectionNewSnapshotTask
                            : l10n.protectionSnapshotTaskCreateUnsupported,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SnapshotList(
                    section: data.snapshotTasks,
                    canEdit:
                        connection.capabilities?.supports(
                              'pool.snapshottask.update',
                            ) ==
                            true &&
                        connection.capabilities?.supports(
                              'pool.snapshottask.update_will_change_retention_for',
                            ) ==
                            true,
                    canDelete:
                        connection.capabilities?.supports(
                          'pool.snapshottask.delete',
                        ) ==
                        true,
                    canRun:
                        connection.capabilities?.supports(
                          'pool.snapshottask.run',
                        ) ==
                        true,
                    serverTaskRunning: data.jobs.items.any(
                      (job) =>
                          job.isActive && job.method == 'pool.snapshottask.run',
                    ),
                    isBusy: (task) =>
                        actions.isBusy('snapshot-task-run:${task.id}') ||
                        actions.isBusy('snapshot-task-update:${task.id}') ||
                        actions.isBusy('snapshot-task-impact:${task.id}'),
                    onEdit: (task) => _editSnapshotTask(
                      context,
                      ref,
                      task,
                      data.datasets.items,
                    ),
                    onDelete: (task) => _deleteSnapshotTask(context, ref, task),
                    onRun: (task) => _runSnapshotTask(context, ref, task),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.protectionRecentSnapshots,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _RecentSnapshotList(
                    section: data.snapshots,
                    hasActions:
                        canDeleteSnapshot ||
                        canRollbackSnapshot ||
                        canCloneSnapshot ||
                        canHoldSnapshot,
                    onOpen: (snapshot) => _openSnapshotActions(
                      context,
                      ref,
                      snapshot,
                      data.snapshots.items,
                      canDelete: canDeleteSnapshot,
                      canRollback: canRollbackSnapshot,
                      canClone: canCloneSnapshot,
                      canHold: canHoldSnapshot,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.protectionScrubSchedules,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _ScrubList(
                    section: data.scrubTasks,
                    canRun:
                        connection.capabilities?.supports('pool.scrub.scrub') ==
                        true,
                    serverScrubRunning: data.jobs.items.any(
                      (job) =>
                          job.isActive &&
                          job.method.toLowerCase().contains('scrub'),
                    ),
                    isBusy: (task) => actions.isBusy('scrub:${task.poolName}'),
                    onRun: (task) => _runReviewedTask(
                      context,
                      ref,
                      title: l10n.protectionStartScrubTitle(task.poolName),
                      message: l10n.protectionStartScrubMessage,
                      actionLabel: l10n.protectionStartScrub,
                      operation: () => ref
                          .read(serverActionControllerProvider.notifier)
                          .startPoolScrub(task.poolName),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.protectionCloudSync,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed:
                            connection.capabilities?.supports(
                                  'cloudsync.create',
                                ) ==
                                true
                            ? () => _createCloudSyncTask(context, ref)
                            : null,
                        tooltip: l10n.protectionNewCloudSync,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CloudSyncList(
                    section: data.cloudSyncTasks,
                    canRun:
                        connection.capabilities?.supports('cloudsync.sync') ==
                        true,
                    canDelete:
                        connection.capabilities?.supports('cloudsync.delete') ==
                        true,
                    canEdit:
                        connection.capabilities?.supports('cloudsync.update') ==
                        true,
                    onEdit: (task) => _editCloudSyncTask(context, ref, task),
                    isBusy: (task) => actions.isBusy('cloudsync:${task.id}'),
                    onRun: (task) => _runCloudSync(context, ref, task),
                    onDelete: (task) =>
                        _deleteCloudSyncTask(context, ref, task),
                  ),
                  const SizedBox(height: 28),
                  // Cloud backup sits beside cloud sync but is a different
                  // mechanism: a restic repository with retention and browsable
                  // snapshots rather than a file mirror.
                  if (connection.capabilities?.supports('cloud_backup.query') ==
                      true)
                    const CloudBackupSection(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.protectionRsync,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed:
                            connection.capabilities?.supports(
                                  'rsynctask.create',
                                ) ==
                                true
                            ? () => _createRsyncTask(context, ref)
                            : null,
                        tooltip: l10n.protectionNewRsync,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RsyncList(
                    section: data.rsyncTasks,
                    canRun:
                        connection.capabilities?.supports('rsynctask.run') ==
                        true,
                    canDelete:
                        connection.capabilities?.supports('rsynctask.delete') ==
                        true,
                    canEdit:
                        connection.capabilities?.supports('rsynctask.update') ==
                        true,
                    onEdit: (task) => _editRsyncTask(context, ref, task),
                    isBusy: (task) => actions.isBusy('rsync:${task.id}'),
                    onRun: (task) => _runReviewedTask(
                      context,
                      ref,
                      title: l10n.protectionRunRsyncTitle,
                      message: l10n.protectionRunRsyncMessage(
                        task.direction.toLowerCase(),
                        task.path,
                        task.remote,
                      ),
                      actionLabel: l10n.protectionRunRsync,
                      operation: () => ref
                          .read(serverActionControllerProvider.notifier)
                          .runRsync(task.id),
                    ),
                    onDelete: (task) => _deleteRsyncTask(context, ref, task),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runCloudSync(
    BuildContext context,
    WidgetRef ref,
    CloudSyncTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    var dryRun = false;
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.cloud_sync_outlined),
          title: Text(l10n.protectionRunTaskTitle(task.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.protectionRunCloudSyncMessage(
                  task.direction.toLowerCase(),
                  task.path,
                  task.provider,
                  task.transferMode.toLowerCase(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: dryRun,
                onChanged: (value) =>
                    setDialogState(() => dryRun = value ?? false),
                title: Text(l10n.protectionDryRun),
                subtitle: Text(l10n.protectionDryRunSubtitle),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, dryRun),
              child: Text(
                dryRun
                    ? l10n.protectionRunPreview
                    : l10n.protectionRunCloudSync,
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .runCloudSync(task.id, dryRun: choice);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: task.name);
  }

  Future<void> _createSnapshotTask(
    BuildContext context,
    WidgetRef ref,
    List<Dataset> datasets,
  ) async {
    final l10n = AppLocalizations.of(context);
    final request = await showModalBottomSheet<CreateSnapshotTaskRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SnapshotTaskSheet(datasets: datasets),
    );
    if (request == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createSnapshotTask(request);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.protectionSnapshotTaskCreateFailed
              : l10n.protectionSnapshotTaskCreated(request.dataset),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _editSnapshotTask(
    BuildContext context,
    WidgetRef ref,
    SnapshotTask task,
    List<Dataset> datasets,
  ) async {
    final l10n = AppLocalizations.of(context);
    final request = await showModalBottomSheet<CreateSnapshotTaskRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          SnapshotTaskSheet(datasets: datasets, existingTask: task),
    );
    if (request == null || !context.mounted) return;
    final controller = ref.read(serverActionControllerProvider.notifier);
    final impact = await controller.inspectSnapshotTaskUpdate(task.id, request);
    if (!context.mounted) return;
    if (impact == null) {
      _showTaskResult(
        context,
        ref,
        null,
        label: l10n.protectionSnapshotTaskUpdateLabel,
      );
      return;
    }
    // A retention change is not an ordinary edit when the server says existing
    // snapshots are affected: shortening a lifetime makes ZFS prune snapshots
    // that already exist, and nothing restores them. The server computes that
    // count for us, so the confirmation reports it per dataset and escalates
    // rather than reading like a schedule tweak. With no affected snapshots it
    // really is just a schedule edit, and a plain dialog is right.
    final bool confirmed;
    if (impact.hasChanges) {
      confirmed = await confirmDestructiveAction(
        context,
        title: l10n.protectionUpdateTaskTitle(task.dataset),
        server: _serverName(ref, l10n),
        target: task.dataset,
        actionLabel: l10n.protectionApplyChanges,
        impact: MutationImpact.high,
        consequences: [
          ImpactDetail(
            icon: Icons.auto_delete_outlined,
            text: l10n.protectionRetentionConsequence(impact.total),
          ),
          for (final entry in impact.counts.entries)
            ImpactDetail(
              icon: Icons.dataset_outlined,
              text: l10n.protectionRetentionEntry(entry.key, '${entry.value}'),
            ),
        ],
        note: l10n.protectionUpdateTaskBody,
      );
    } else {
      confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.edit_calendar_outlined),
              title: Text(l10n.protectionUpdateTaskTitle(task.dataset)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.protectionUpdateTaskBody),
                  const SizedBox(height: 12),
                  Text(l10n.protectionNoRetentionChanges),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.protectionApplyChanges),
                ),
              ],
            ),
          ) ==
          true;
    }
    if (!confirmed || !context.mounted) return;
    final receipt = await controller.updateSnapshotTask(task.id, request);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.protectionSnapshotTaskUpdateFailed
              : l10n.protectionSnapshotTaskUpdated(request.dataset),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _runSnapshotTask(
    BuildContext context,
    WidgetRef ref,
    SnapshotTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    await _runReviewedTask(
      context,
      ref,
      title: l10n.protectionRunSnapshotTaskTitle,
      message: l10n.protectionRunSnapshotTaskMessage(
        task.recursive ? l10n.protectionScopeRecursive : '',
        task.dataset,
        task.namingSchema,
      ),
      actionLabel: l10n.protectionRunSnapshotTask,
      operation: () => ref
          .read(serverActionControllerProvider.notifier)
          .runSnapshotTask(task.id),
    );
  }

  Future<void> _deleteSnapshotTask(
    BuildContext context,
    WidgetRef ref,
    SnapshotTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionDeleteSnapshotTaskTitle,
      server: _serverName(ref, l10n),
      target: task.dataset,
      actionLabel: l10n.protectionDeleteTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_outline_rounded,
          text: l10n.protectionDeleteSnapshotTaskConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteSnapshotTask(task.id);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: task.dataset);
  }

  /// Opens the snapshot action chooser, then routes destructive choices
  /// through the shared confirmation before touching the server.
  Future<void> _openSnapshotActions(
    BuildContext context,
    WidgetRef ref,
    SnapshotEntry snapshot,
    List<SnapshotEntry> allSnapshots, {
    required bool canDelete,
    required bool canRollback,
    required bool canClone,
    required bool canHold,
  }) async {
    // `pool.snapshot.query` is ordered newest first, so anything listed before
    // this snapshot on the same dataset is newer than it.
    final sameDataset = allSnapshots
        .where((item) => item.dataset == snapshot.dataset)
        .toList(growable: false);
    final index = sameDataset.indexWhere((item) => item.id == snapshot.id);
    final newerCount = index < 0 ? 0 : index;

    final action = await showModalBottomSheet<SnapshotAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SnapshotActionsSheet(
        snapshot: snapshot,
        newerSnapshotCount: newerCount,
        canDelete: canDelete,
        canRollback: canRollback,
        canClone: canClone,
        canHold: canHold,
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case SnapshotCloneAction(:final destination):
        await _cloneSnapshot(context, ref, snapshot, destination);
      case SnapshotDeleteAction():
        await _deleteSnapshot(context, ref, snapshot);
      case SnapshotHoldAction(:final held):
        await _setSnapshotHeld(context, ref, snapshot, held);
      case SnapshotRollbackAction(:final mode, :final force):
        await _rollbackSnapshot(
          context,
          ref,
          snapshot,
          mode,
          force,
          newerCount,
        );
    }
  }

  /// Holding and releasing are reversible, so neither needs a destructive
  /// confirmation.
  Future<void> _setSnapshotHeld(
    BuildContext context,
    WidgetRef ref,
    SnapshotEntry snapshot,
    bool held,
  ) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setSnapshotHeld(snapshot.id, held: held);
    if (!context.mounted) return;
    _showSnapshotResult(
      context,
      ref,
      receipt,
      action: held
          ? l10n.protectionSnapshotHoldAction(snapshot.name)
          : l10n.protectionSnapshotReleaseAction(snapshot.name),
      success: held
          ? l10n.protectionSnapshotHeld(snapshot.name)
          : l10n.protectionSnapshotReleased(snapshot.name),
    );
  }

  Future<void> _cloneSnapshot(
    BuildContext context,
    WidgetRef ref,
    SnapshotEntry snapshot,
    String destination,
  ) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .cloneSnapshot(snapshot.id, datasetDestination: destination);
    if (!context.mounted) return;
    _showSnapshotResult(
      context,
      ref,
      receipt,
      action: l10n.protectionSnapshotCloneAction(snapshot.name),
      success: l10n.protectionSnapshotCloned(destination),
    );
  }

  Future<void> _deleteSnapshot(
    BuildContext context,
    WidgetRef ref,
    SnapshotEntry snapshot,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionDeleteSnapshotTitle,
      server: _serverName(ref, l10n),
      target: l10n.protectionSnapshotTarget(snapshot.dataset, snapshot.name),
      actionLabel: l10n.protectionDeleteSnapshotAction,
      impact: MutationImpact.critical,
      confirmationText: snapshot.name,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.protectionDeleteSnapshotConsequenceRestore,
        ),
        ImpactDetail(
          icon: Icons.history_toggle_off_rounded,
          text: l10n.protectionDeleteSnapshotConsequenceReplication,
        ),
      ],
      note: l10n.protectionDeleteSnapshotNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteSnapshot(snapshot.id);
    if (!context.mounted) return;
    _showSnapshotResult(
      context,
      ref,
      receipt,
      action: l10n.protectionSnapshotDeleteAction(snapshot.name),
      success: l10n.protectionSnapshotDeleted(snapshot.name),
    );
  }

  Future<void> _rollbackSnapshot(
    BuildContext context,
    WidgetRef ref,
    SnapshotEntry snapshot,
    SnapshotRollbackMode mode,
    bool force,
    int newerCount,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionRollbackTitle,
      server: _serverName(ref, l10n),
      target: l10n.protectionSnapshotTarget(snapshot.dataset, snapshot.name),
      actionLabel: l10n.protectionRollbackAction,
      impact: MutationImpact.critical,
      confirmationText: snapshot.dataset,
      consequences: [
        ImpactDetail(
          icon: Icons.undo_rounded,
          text: l10n.protectionRollbackConsequenceChanges(snapshot.dataset),
        ),
        if (mode.recursive && newerCount > 0)
          ImpactDetail(
            icon: Icons.camera_outlined,
            text: l10n.protectionRollbackConsequenceNewer(newerCount),
          ),
        if (mode.recursiveClones)
          ImpactDetail(
            icon: Icons.account_tree_outlined,
            text: l10n.protectionRollbackConsequenceClones,
          ),
        if (force)
          ImpactDetail(
            icon: Icons.eject_outlined,
            text: l10n.protectionRollbackConsequenceForce,
          ),
      ],
      note: l10n.protectionRollbackNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .rollbackSnapshot(snapshot.id, mode: mode, force: force);
    if (!context.mounted) return;
    _showSnapshotResult(
      context,
      ref,
      receipt,
      action: l10n.protectionSnapshotRollbackAction(snapshot.dataset),
      success: l10n.protectionSnapshotRolledBack(
        snapshot.dataset,
        snapshot.name,
      ),
    );
  }

  void _showSnapshotResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String action,
    required String success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ??
                    AppLocalizations.of(
                      context,
                    ).protectionSnapshotActionFailed(action)
              : success,
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  String _serverName(WidgetRef ref, AppLocalizations l10n) =>
      ref.read(connectionControllerProvider).profile?.name ??
      l10n.systemServerFallback;

  /// Loads saved SSH connections for the replication and rsync editors.
  ///
  /// Returns the list plus whether the query failed, so the editors can tell
  /// "no connections configured" apart from "could not read credentials".
  Future<({List<SshCredential> credentials, bool failed})> _loadSshCredentials(
    WidgetRef ref,
  ) async {
    final credentials = await ref
        .read(serverActionControllerProvider.notifier)
        .getSshCredentials();
    return (
      credentials: credentials ?? const <SshCredential>[],
      failed: credentials == null,
    );
  }

  /// Loads saved cloud credentials for the cloud sync editor.
  ///
  /// Returns the list plus whether the query failed, so the editor can tell
  /// "none configured" apart from "could not read credentials".
  Future<({List<CloudCredential> credentials, bool failed})>
  _loadCloudCredentials(WidgetRef ref) async {
    final credentials = await ref
        .read(serverActionControllerProvider.notifier)
        .getCloudCredentials();
    return (
      credentials: credentials ?? const <CloudCredential>[],
      failed: credentials == null,
    );
  }

  Future<void> _createCloudSyncTask(BuildContext context, WidgetRef ref) async {
    final cloud = await _loadCloudCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<CloudSyncConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => CloudSyncTaskSheet(
        baseline: const CloudSyncConfiguration(
          description: '',
          direction: CloudSyncDirection.push,
          transferMode: CloudSyncTransferMode.copy,
          path: '',
        ),
        credentials: cloud.credentials,
        credentialsFailed: cloud.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final credential = cloud.credentials
        .where((c) => c.id == configuration.credentialId)
        .firstOrNull;
    final confirmed = await _confirmCloudSync(
      context,
      ref,
      configuration,
      credential,
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createCloudSyncTask(configuration, credential);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.description);
  }

  Future<void> _editCloudSyncTask(
    BuildContext context,
    WidgetRef ref,
    CloudSyncTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final raw = await controller.getCloudSyncTaskConfig(task.id);
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.protectionCloudSyncConfigLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final cloud = await _loadCloudCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<CloudSyncConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => CloudSyncTaskSheet(
        baseline: CloudSyncConfiguration.fromJson(raw),
        credentials: cloud.credentials,
        credentialsFailed: cloud.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final credential = cloud.credentials
        .where((c) => c.id == configuration.credentialId)
        .firstOrNull;
    final confirmed = await _confirmCloudSync(
      context,
      ref,
      configuration,
      credential,
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await controller.updateCloudSyncTask(
      task.id,
      configuration,
      credential,
    );
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.description);
  }

  /// Cloud sync writes into whichever side it targets, and SYNC/MOVE delete
  /// data, so both create and edit route through the shared high-impact
  /// confirmation naming the side that loses files.
  Future<bool> _confirmCloudSync(
    BuildContext context,
    WidgetRef ref,
    CloudSyncConfiguration configuration,
    CloudCredential? credential,
  ) {
    final l10n = AppLocalizations.of(context);
    final pushing = configuration.direction == CloudSyncDirection.push;
    final usesBucket = configuration.usesBucketFor(credential);
    final remote = usesBucket
        ? '${configuration.bucket}/${configuration.folder}'
        : (configuration.folder.isEmpty ? '/' : configuration.folder);
    return confirmDestructiveAction(
      context,
      title: configuration.isCreate
          ? l10n.protectionCreateCloudSyncTitle(configuration.description)
          : l10n.protectionSaveCloudSyncTitle(configuration.description),
      server: _serverName(ref, l10n),
      target: pushing ? remote : configuration.path,
      actionLabel: configuration.isCreate
          ? l10n.protectionCreateTask
          : l10n.protectionSaveTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.cloud_sync_outlined,
          text: pushing
              ? l10n.protectionCloudSyncPushConsequence(
                  configuration.path,
                  remote,
                  credential?.label ?? l10n.protectionSelectedProvider,
                )
              : l10n.protectionCloudSyncPullConsequence(
                  remote,
                  configuration.path,
                ),
        ),
        if (configuration.transferMode == CloudSyncTransferMode.sync)
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: pushing
                ? l10n.protectionCloudSyncSyncPush(remote, configuration.path)
                : l10n.protectionCloudSyncSyncPull(configuration.path, remote),
          )
        else if (configuration.transferMode == CloudSyncTransferMode.move)
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: pushing
                ? l10n.protectionCloudSyncMovePush(configuration.path)
                : l10n.protectionCloudSyncMovePull(remote),
          )
        else
          ImpactDetail(
            icon: Icons.check_circle_outline_rounded,
            text: l10n.protectionCloudSyncCopyNote,
          ),
        if (configuration.encryption)
          ImpactDetail(
            icon: Icons.key_rounded,
            text: l10n.protectionCloudSyncEncryptionNote,
          ),
      ],
    );
  }

  Future<void> _createReplicationTask(
    BuildContext context,
    WidgetRef ref,
    List<Dataset> datasets,
  ) async {
    final ssh = await _loadSshCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<ReplicationConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => ReplicationTaskSheet(
        baseline: const ReplicationConfiguration(
          name: '',
          direction: ReplicationDirection.push,
          transport: ReplicationTransport.ssh,
          sourceDatasets: [],
          targetDataset: '',
        ),
        datasets: datasets.map((dataset) => dataset.name).toList(),
        sshCredentials: ssh.credentials,
        sshCredentialsFailed: ssh.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final confirmed = await _confirmReplication(context, ref, configuration);
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createReplicationTask(configuration);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.name);
  }

  Future<void> _editReplicationTask(
    BuildContext context,
    WidgetRef ref,
    ReplicationTask task,
    List<Dataset> datasets,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final raw = await controller.getReplicationTaskConfig(task.id);
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.protectionReplicationConfigLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final ssh = await _loadSshCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<ReplicationConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => ReplicationTaskSheet(
        baseline: _replicationBaseline(raw, task),
        datasets: datasets.map((dataset) => dataset.name).toList(),
        sshCredentials: ssh.credentials,
        sshCredentialsFailed: ssh.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final confirmed = await _confirmReplication(context, ref, configuration);
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateReplicationTask(task.id, configuration);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.name);
  }

  /// Seeds the editor from a `replication.query` row.
  ReplicationConfiguration _replicationBaseline(
    Map<String, dynamic> raw,
    ReplicationTask task,
  ) {
    final sshCredentials = raw['ssh_credentials'];
    int? credentialId;
    if (sshCredentials is num) {
      credentialId = sshCredentials.toInt();
    } else if (sshCredentials is Map && sshCredentials['id'] is num) {
      credentialId = (sshCredentials['id'] as num).toInt();
    } else if (sshCredentials is List && sshCredentials.isNotEmpty) {
      final first = sshCredentials.first;
      if (first is num) {
        credentialId = first.toInt();
      } else if (first is Map && first['id'] is num) {
        credentialId = (first['id'] as num).toInt();
      }
    }
    final sources = raw['source_datasets'];
    final schemas = raw['also_include_naming_schema'] ?? raw['naming_schema'];
    final schedule = raw['schedule'];
    return ReplicationConfiguration(
      id: task.id,
      name: raw['name'] is String ? raw['name'] as String : task.name,
      direction: ReplicationDirectionApi.fromApi(raw['direction'] as String?),
      transport: ReplicationTransportApi.fromApi(raw['transport'] as String?),
      sshCredentialId: credentialId,
      sourceDatasets: sources is List
          ? sources.whereType<String>().toList(growable: false)
          : const <String>[],
      targetDataset: raw['target_dataset'] is String
          ? raw['target_dataset'] as String
          : '',
      recursive: raw['recursive'] == true,
      auto: raw['auto'] != false,
      enabled: raw['enabled'] != false,
      retentionPolicy: switch (raw['retention_policy']) {
        'CUSTOM' => ReplicationRetentionPolicy.custom,
        'NONE' => ReplicationRetentionPolicy.none,
        _ => ReplicationRetentionPolicy.source,
      },
      lifetimeValue: raw['lifetime_value'] is num
          ? (raw['lifetime_value'] as num).toInt()
          : 2,
      lifetimeUnit: ReplicationLifetimeUnitApi.fromApi(
        raw['lifetime_unit'] as String?,
      ),
      namingSchema: switch (schemas) {
        final List<Object?> list when list.whereType<String>().isNotEmpty =>
          list.whereType<String>().first,
        final String value when value.isNotEmpty => value,
        _ => 'auto-%Y-%m-%d_%H-%M',
      },
      schedule: schedule is Map<String, dynamic>
          ? TaskSchedule.fromJson(schedule)
          : const TaskSchedule(hour: '00'),
    );
  }

  /// Replication writes into the target dataset and can destroy destination
  /// snapshots, so both create and update route through the shared
  /// high-impact confirmation.
  Future<bool> _confirmReplication(
    BuildContext context,
    WidgetRef ref,
    ReplicationConfiguration configuration,
  ) {
    final l10n = AppLocalizations.of(context);
    final pushing = configuration.direction == ReplicationDirection.push;
    return confirmDestructiveAction(
      context,
      title: configuration.isCreate
          ? l10n.protectionCreateReplicationTitle(configuration.name)
          : l10n.protectionSaveReplicationTitle(configuration.name),
      server: _serverName(ref, l10n),
      target: configuration.targetDataset,
      actionLabel: configuration.isCreate
          ? l10n.protectionCreateTask
          : l10n.protectionSaveTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.sync_alt_rounded,
          text: pushing
              ? l10n.protectionReplicationPushConsequence(
                  configuration.sourceDatasets.length,
                  configuration.targetDataset,
                )
              : l10n.protectionReplicationPullConsequence(
                  configuration.targetDataset,
                ),
        ),
        ImpactDetail(
          icon: Icons.warning_amber_rounded,
          text: l10n.protectionReplicationOverwriteNote,
        ),
        if (configuration.retentionPolicy == ReplicationRetentionPolicy.custom)
          ImpactDetail(
            icon: Icons.auto_delete_outlined,
            text: l10n.protectionReplicationRetentionNote(
              configuration.lifetimeValue,
              switch (configuration.lifetimeUnit) {
                ReplicationLifetimeUnit.hour => l10n.replicationUnitHours,
                ReplicationLifetimeUnit.day => l10n.replicationUnitDays,
                ReplicationLifetimeUnit.week => l10n.replicationUnitWeeks,
                ReplicationLifetimeUnit.month => l10n.replicationUnitMonths,
                ReplicationLifetimeUnit.year => l10n.replicationUnitYears,
              }.toLowerCase(),
            ),
          ),
        if (configuration.transport == ReplicationTransport.local)
          ImpactDetail(
            icon: Icons.storage_rounded,
            text: l10n.protectionReplicationLocalNote,
          ),
      ],
    );
  }

  /// Loads local usernames for the rsync editor's "run as" picker.
  ///
  /// Rsync runs as a local account, and in SSH mode that account must match
  /// the SSH connection user, so the editor offers the server's own list
  /// instead of a free-text field.
  Future<List<String>> _loadLocalUsers(WidgetRef ref) async {
    try {
      final system = await ref.read(systemResourcesProvider.future);
      return system.users.items
          .map((user) => user.username)
          .toList(growable: false)
        ..sort();
    } on Object {
      return const <String>[];
    }
  }

  Future<void> _createRsyncTask(BuildContext context, WidgetRef ref) async {
    final users = await _loadLocalUsers(ref);
    if (!context.mounted) return;
    final ssh = await _loadSshCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<RsyncConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => RsyncTaskSheet(
        baseline: const RsyncConfiguration(
          path: '',
          user: '',
          direction: RsyncDirection.push,
          mode: RsyncMode.ssh,
        ),
        users: users,
        sshCredentials: ssh.credentials,
        sshCredentialsFailed: ssh.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final confirmed = await _confirmRsync(context, ref, configuration);
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createRsyncTask(configuration);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.path);
  }

  Future<void> _editRsyncTask(
    BuildContext context,
    WidgetRef ref,
    RsyncTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final raw = await controller.getRsyncTaskConfig(task.id);
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.protectionRsyncConfigLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final users = await _loadLocalUsers(ref);
    if (!context.mounted) return;
    final ssh = await _loadSshCredentials(ref);
    if (!context.mounted) return;
    final configuration = await showModalBottomSheet<RsyncConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => RsyncTaskSheet(
        baseline: _rsyncBaseline(raw, task),
        users: users,
        sshCredentials: ssh.credentials,
        sshCredentialsFailed: ssh.failed,
      ),
    );
    if (configuration == null || !context.mounted) return;
    final confirmed = await _confirmRsync(context, ref, configuration);
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateRsyncTask(task.id, configuration);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: configuration.path);
  }

  /// Seeds the editor from an `rsynctask.query` row.
  RsyncConfiguration _rsyncBaseline(Map<String, dynamic> raw, RsyncTask task) {
    final sshCredentials = raw['ssh_credentials'];
    int? credentialId;
    if (sshCredentials is num) {
      credentialId = sshCredentials.toInt();
    } else if (sshCredentials is Map && sshCredentials['id'] is num) {
      credentialId = (sshCredentials['id'] as num).toInt();
    }
    final schedule = raw['schedule'];
    return RsyncConfiguration(
      id: task.id,
      path: raw['path'] is String ? raw['path'] as String : task.path,
      user: raw['user'] is String ? raw['user'] as String : '',
      direction: RsyncDirectionApi.fromApi(raw['direction'] as String?),
      mode: RsyncModeApi.fromApi(raw['mode'] as String?),
      description: raw['desc'] is String ? raw['desc'] as String : '',
      remoteHost: raw['remotehost'] is String
          ? raw['remotehost'] as String
          : '',
      remotePort: raw['remoteport'] is num
          ? (raw['remoteport'] as num).toInt()
          : null,
      remotePath: raw['remotepath'] is String
          ? raw['remotepath'] as String
          : '',
      remoteModule: raw['remotemodule'] is String
          ? raw['remotemodule'] as String
          : '',
      sshCredentialId: credentialId,
      enabled: raw['enabled'] != false,
      validateRemotePath: raw['validate_rpath'] != false,
      schedule: schedule is Map<String, dynamic>
          ? TaskSchedule.fromJson(schedule)
          : const TaskSchedule(hour: '00'),
    );
  }

  /// Rsync overwrites files on whichever side it writes into, so both create
  /// and update route through the shared high-impact confirmation.
  Future<bool> _confirmRsync(
    BuildContext context,
    WidgetRef ref,
    RsyncConfiguration configuration,
  ) {
    final l10n = AppLocalizations.of(context);
    final pushing = configuration.direction == RsyncDirection.push;
    final remote = configuration.mode == RsyncMode.ssh
        ? '${configuration.remoteHost}:${configuration.remotePath}'
        : '${configuration.remoteHost}::${configuration.remoteModule}';
    return confirmDestructiveAction(
      context,
      title: configuration.isCreate
          ? l10n.protectionCreateRsyncTitle(configuration.path)
          : l10n.protectionSaveRsyncTitle(configuration.path),
      server: _serverName(ref, l10n),
      target: pushing ? remote : configuration.path,
      actionLabel: configuration.isCreate
          ? l10n.protectionCreateTask
          : l10n.protectionSaveTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.sync_rounded,
          text: pushing
              ? l10n.protectionRsyncPushConsequence(configuration.path, remote)
              : l10n.protectionRsyncPullConsequence(remote, configuration.path),
        ),
        ImpactDetail(
          icon: Icons.person_outline_rounded,
          text: l10n.protectionRsyncRunAsNote(
            configuration.user,
            '${configuration.effectivePort}',
          ),
        ),
        ImpactDetail(
          icon: Icons.schedule_outlined,
          text: l10n.protectionRsyncScheduleNote,
        ),
      ],
    );
  }

  Future<void> _deleteReplicationTask(
    BuildContext context,
    WidgetRef ref,
    ReplicationTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionDeleteReplicationTitle,
      server: _serverName(ref, l10n),
      target: task.name,
      actionLabel: l10n.protectionDeleteTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_outline_rounded,
          text: l10n.protectionDeleteReplicationConsequence,
        ),
        ImpactDetail(
          icon: Icons.history_rounded,
          text: l10n.protectionDeleteReplicationKeepNote,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteReplicationTask(task.id);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: task.name);
  }

  Future<void> _deleteCloudSyncTask(
    BuildContext context,
    WidgetRef ref,
    CloudSyncTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionDeleteCloudSyncTitle,
      server: _serverName(ref, l10n),
      target: task.name,
      actionLabel: l10n.protectionDeleteTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_outline_rounded,
          text: l10n.protectionDeleteCloudSyncConsequence,
        ),
        ImpactDetail(
          icon: Icons.cloud_done_outlined,
          text: l10n.protectionDeleteCloudSyncKeepNote,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteCloudSyncTask(task.id);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: task.name);
  }

  Future<void> _deleteRsyncTask(
    BuildContext context,
    WidgetRef ref,
    RsyncTask task,
  ) async {
    final l10n = AppLocalizations.of(context);
    final label = task.description ?? task.remote;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionDeleteRsyncTitle,
      server: _serverName(ref, l10n),
      target: label,
      actionLabel: l10n.protectionDeleteTask,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_outline_rounded,
          text: l10n.protectionDeleteRsyncConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteRsyncTask(task.id);
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: label);
  }

  Future<void> _runReviewedTask(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String actionLabel,
    required Future<OperationReceipt?> Function() operation,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.play_circle_outline_rounded),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final receipt = await operation();
    if (!context.mounted) return;
    _showTaskResult(context, ref, receipt, label: actionLabel);
  }

  void _showTaskResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt, {
    required String label,
  }) {
    final l10n = AppLocalizations.of(context);
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.protectionTaskStartFailed
              : l10n.protectionTaskStarted(label) +
                    (receipt.jobId == null
                        ? ''
                        : l10n.protectionJobSuffix('${receipt.jobId}')),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

class _ProtectionSummary extends StatelessWidget {
  const _ProtectionSummary({required this.resources});
  final ServerResources resources;

  @override
  Widget build(BuildContext context) {
    final enabledReplications = resources.replications.items
        .where((e) => e.enabled)
        .length;
    final enabledSnapshots = resources.snapshotTasks.items
        .where((e) => e.enabled)
        .length;
    final enabledOther =
        resources.scrubTasks.items.where((task) => task.enabled).length +
        resources.cloudSyncTasks.items.where((task) => task.enabled).length +
        resources.rsyncTasks.items.where((task) => task.enabled).length;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_rounded,
            size: 42,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              AppLocalizations.of(context).protectionSummary(
                enabledReplications,
                enabledSnapshots,
                enabledOther,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplicationList extends StatelessWidget {
  const _ReplicationList({
    required this.section,
    required this.canRun,
    required this.isBusy,
    required this.onRun,
    required this.canDelete,
    required this.onDelete,
    required this.canEdit,
    required this.onEdit,
  });
  final ResourceSection<ReplicationTask> section;
  final bool canRun;
  final bool Function(ReplicationTask task) isBusy;
  final ValueChanged<ReplicationTask> onRun;
  final bool canDelete;
  final ValueChanged<ReplicationTask> onDelete;
  final bool canEdit;
  final ValueChanged<ReplicationTask> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoReplicationTasks);
    }
    return Card(
      child: Column(
        children: [
          for (final (index, task) in section.items.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              leading: Icon(
                task.enabled ? Icons.sync_rounded : Icons.sync_disabled_rounded,
              ),
              title: Text(task.name),
              subtitle: Text(
                l10n.protectionReplicationSubtitleRow(
                  task.direction,
                  task.state ?? l10n.protectionStateIdle,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    IconButton(
                      tooltip: l10n.protectionEditTask,
                      onPressed: isBusy(task) ? null : () => onEdit(task),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (canDelete)
                    IconButton(
                      tooltip: l10n.protectionDeleteTask,
                      onPressed: isBusy(task) ? null : () => onDelete(task),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  _RunTaskButton(
                    busy: isBusy(task),
                    running: task.isRunning,
                    supported: canRun,
                    onPressed: () => onRun(task),
                  ),
                ],
              ),
              onTap: canEdit && !isBusy(task)
                  ? () => onEdit(task)
                  : (task.isRunning || isBusy(task) || !canRun
                        ? null
                        : () => onRun(task)),
            ),
            if (index < section.items.length - 1)
              const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

class _SnapshotList extends StatelessWidget {
  const _SnapshotList({
    required this.section,
    required this.canEdit,
    required this.canRun,
    required this.serverTaskRunning,
    required this.isBusy,
    required this.onEdit,
    required this.onRun,
    required this.canDelete,
    required this.onDelete,
  });
  final ResourceSection<SnapshotTask> section;
  final bool canEdit;
  final bool canRun;
  final bool serverTaskRunning;
  final bool Function(SnapshotTask task) isBusy;
  final ValueChanged<SnapshotTask> onEdit;
  final ValueChanged<SnapshotTask> onRun;
  final bool canDelete;
  final ValueChanged<SnapshotTask> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoSnapshotTasks);
    }
    return Card(
      child: Column(
        children: [
          for (final (index, task) in section.items.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              leading: Icon(
                task.enabled
                    ? Icons.schedule_rounded
                    : Icons.event_busy_outlined,
              ),
              title: Text(task.dataset),
              subtitle: Text(
                l10n.protectionSnapshotTaskSubtitle(
                      task.schedule,
                      _snapshotRetentionLabel(l10n, task),
                    ) +
                    (task.recursive ? l10n.protectionRecursiveSuffix : ''),
              ),
              trailing: isBusy(task)
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : PopupMenuButton<_SnapshotTaskAction>(
                      tooltip: l10n.protectionSnapshotTaskActions,
                      onSelected: (action) => switch (action) {
                        _SnapshotTaskAction.run => onRun(task),
                        _SnapshotTaskAction.edit => onEdit(task),
                        _SnapshotTaskAction.delete => onDelete(task),
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _SnapshotTaskAction.run,
                          enabled: canRun && !serverTaskRunning,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.play_arrow_rounded),
                            title: Text(l10n.protectionRunNow),
                          ),
                        ),
                        PopupMenuItem(
                          value: _SnapshotTaskAction.edit,
                          enabled: canEdit,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.edit_calendar_outlined),
                            title: Text(l10n.protectionEditTask),
                          ),
                        ),
                        if (canDelete)
                          PopupMenuItem(
                            value: _SnapshotTaskAction.delete,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                l10n.protectionDeleteTask,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
              onTap: () => _showSnapshotTaskDetails(context, task),
            ),
            if (index < section.items.length - 1)
              const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

enum _SnapshotTaskAction { run, edit, delete }

void _showSnapshotTaskDetails(BuildContext context, SnapshotTask task) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              task.dataset,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _SnapshotDetailRow(
              label: l10n.protectionLabelSchedule,
              value: task.schedule,
            ),
            _SnapshotDetailRow(
              label: l10n.protectionLabelRetention,
              value: _snapshotRetentionLabel(l10n, task),
            ),
            _SnapshotDetailRow(
              label: l10n.protectionLabelNaming,
              value: task.namingSchema,
            ),
            _SnapshotDetailRow(
              label: l10n.protectionLabelScope,
              value: task.recursive
                  ? l10n.protectionScopeRecursiveValue
                  : l10n.protectionScopeSelectedOnly,
            ),
            _SnapshotDetailRow(
              label: l10n.protectionLabelNoChanges,
              value: task.allowEmpty
                  ? l10n.protectionCreateSnapshotAnyway
                  : l10n.protectionSkipSnapshot,
            ),
            _SnapshotDetailRow(
              label: l10n.protectionLabelState,
              value: task.enabled
                  ? l10n.protectionEnabled
                  : l10n.protectionDisabled,
            ),
            if (task.excludes.isNotEmpty)
              _SnapshotDetailRow(
                label: l10n.protectionLabelExcludes,
                value: task.excludes.join('\n'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SnapshotDetailRow extends StatelessWidget {
  const _SnapshotDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _RecentSnapshotList extends StatelessWidget {
  const _RecentSnapshotList({
    required this.section,
    required this.hasActions,
    required this.onOpen,
  });

  final ResourceSection<SnapshotEntry> section;
  final bool hasActions;
  final ValueChanged<SnapshotEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoSnapshots);
    }
    return Card(
      child: Column(
        children: [
          for (final (index, snapshot) in section.items.take(50).indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const Icon(Icons.camera_outlined),
              title: Text(snapshot.name),
              subtitle: Text(snapshot.dataset),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.protectionTransactionGroup(snapshot.transactionGroup),
                  ),
                  if (hasActions) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ],
              ),
              onTap: hasActions ? () => onOpen(snapshot) : null,
            ),
            if (index < section.items.take(50).length - 1)
              const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

class _ScrubList extends StatelessWidget {
  const _ScrubList({
    required this.section,
    required this.canRun,
    required this.serverScrubRunning,
    required this.isBusy,
    required this.onRun,
  });

  final ResourceSection<ScrubTask> section;
  final bool canRun;
  final bool serverScrubRunning;
  final bool Function(ScrubTask task) isBusy;
  final ValueChanged<ScrubTask> onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoScrubSchedules);
    }
    return _ProtectionCard(
      items: [
        for (final task in section.items)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: Icon(
              task.enabled
                  ? Icons.cleaning_services_rounded
                  : Icons.event_busy_outlined,
            ),
            title: Text(task.poolName),
            subtitle: Text(
              l10n.protectionScrubSubtitle(
                _scrubScheduleLabel(l10n, task),
                task.thresholdDays,
              ),
            ),
            trailing: _RunTaskButton(
              busy: isBusy(task),
              running: serverScrubRunning,
              supported: canRun,
              onPressed: () => onRun(task),
            ),
            onTap: serverScrubRunning || isBusy(task) || !canRun
                ? null
                : () => onRun(task),
          ),
      ],
    );
  }
}

class _CloudSyncList extends StatelessWidget {
  const _CloudSyncList({
    required this.section,
    required this.canRun,
    required this.isBusy,
    required this.onRun,
    required this.canDelete,
    required this.onDelete,
    required this.canEdit,
    required this.onEdit,
  });

  final ResourceSection<CloudSyncTask> section;
  final bool canRun;
  final bool Function(CloudSyncTask task) isBusy;
  final ValueChanged<CloudSyncTask> onRun;
  final bool canDelete;
  final ValueChanged<CloudSyncTask> onDelete;
  final bool canEdit;
  final ValueChanged<CloudSyncTask> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoCloudSyncTasks);
    }
    return _ProtectionCard(
      items: [
        for (final task in section.items)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(task.name),
            subtitle: Text(
              l10n.protectionCloudSyncSubtitleRow(
                task.direction,
                task.transferMode,
                task.provider,
                task.path,
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  IconButton(
                    tooltip: l10n.protectionEditTask,
                    onPressed: isBusy(task) ? null : () => onEdit(task),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (canDelete)
                  IconButton(
                    tooltip: l10n.protectionDeleteTask,
                    onPressed: isBusy(task) ? null : () => onDelete(task),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                _RunTaskButton(
                  busy: isBusy(task),
                  running: task.isRunning,
                  supported: canRun,
                  onPressed: () => onRun(task),
                ),
              ],
            ),
            onTap: canEdit && !isBusy(task)
                ? () => onEdit(task)
                : (task.isRunning || isBusy(task) || !canRun
                      ? null
                      : () => onRun(task)),
          ),
      ],
    );
  }
}

class _RsyncList extends StatelessWidget {
  const _RsyncList({
    required this.section,
    required this.canRun,
    required this.isBusy,
    required this.onRun,
    required this.canDelete,
    required this.onDelete,
    required this.canEdit,
    required this.onEdit,
  });

  final ResourceSection<RsyncTask> section;
  final bool canRun;
  final bool Function(RsyncTask task) isBusy;
  final ValueChanged<RsyncTask> onRun;
  final bool canDelete;
  final ValueChanged<RsyncTask> onDelete;
  final bool canEdit;
  final ValueChanged<RsyncTask> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _TaskMessage(
        AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _TaskMessage(l10n.protectionNoRsyncTasks);
    }
    return _ProtectionCard(
      items: [
        for (final task in section.items)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: const Icon(Icons.sync_alt_rounded),
            title: Text(task.description ?? task.remote),
            subtitle: Text(
              l10n.protectionRsyncSubtitleRow(
                task.direction,
                task.mode,
                task.path,
                task.remote,
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  IconButton(
                    tooltip: l10n.protectionEditTask,
                    onPressed: isBusy(task) ? null : () => onEdit(task),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (canDelete)
                  IconButton(
                    tooltip: l10n.protectionDeleteTask,
                    onPressed: isBusy(task) ? null : () => onDelete(task),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                _RunTaskButton(
                  busy: isBusy(task),
                  running: task.isRunning,
                  supported: canRun,
                  onPressed: () => onRun(task),
                ),
              ],
            ),
            onTap: canEdit && !isBusy(task)
                ? () => onEdit(task)
                : (task.isRunning || isBusy(task) || !canRun
                      ? null
                      : () => onRun(task)),
          ),
      ],
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (final (index, item) in items.indexed) ...[
          item,
          if (index < items.length - 1) const Divider(indent: 68, height: 1),
        ],
      ],
    ),
  );
}

class _RunTaskButton extends StatelessWidget {
  const _RunTaskButton({
    required this.busy,
    required this.running,
    required this.supported,
    required this.onPressed,
  });

  final bool busy;
  final bool running;
  final bool supported;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (busy) {
      return const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    return IconButton.filledTonal(
      onPressed: supported && !running ? onPressed : null,
      icon: Icon(running ? Icons.sync_rounded : Icons.play_arrow_rounded),
      tooltip: !supported
          ? l10n.protectionActionUnsupported
          : running
          ? l10n.protectionTaskAlreadyRunning
          : l10n.protectionRunNow,
    );
  }
}

class _TaskMessage extends StatelessWidget {
  const _TaskMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Text(message)),
    );
  }
}

String _snapshotRetentionLabel(AppLocalizations l10n, SnapshotTask task) {
  return switch (task.lifetimeUnit.toUpperCase()) {
    'HOUR' || 'HOURS' => l10n.protectionRetentionHours(task.lifetimeValue),
    'DAY' || 'DAYS' => l10n.protectionRetentionDays(task.lifetimeValue),
    'MONTH' || 'MONTHS' => l10n.protectionRetentionMonths(task.lifetimeValue),
    'YEAR' || 'YEARS' => l10n.protectionRetentionYears(task.lifetimeValue),
    _ => l10n.protectionRetentionWeeks(task.lifetimeValue),
  };
}

String _scrubScheduleLabel(AppLocalizations l10n, ScrubTask task) {
  if (!task.scheduleAvailable) return l10n.protectionScheduleUnavailable;
  return l10n.protectionScrubSchedule(
    task.scheduleHour,
    task.scheduleMinute,
    task.scheduleDayOfWeek,
  );
}
