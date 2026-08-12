import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../domain/cloud_backup_configuration.dart';
import '../domain/cloud_sync_configuration.dart';
import 'cloud_backup_sheet.dart';
import 'task_schedule_localizations.dart';

/// Cloud backup tasks (`cloud_backup.*`).
///
/// Distinct from cloud sync despite sitting next to it: this is a restic-style
/// repository with snapshot retention, so it has a repository password, a
/// `keep_last` count, and browsable snapshots that a sync task has no equivalent
/// for.
///
/// Loads its own list rather than joining the shared resource batch, which
/// already fans out enough concurrent reads to matter against the server's
/// per-connection call cap.
class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});

  @override
  ConsumerState<CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<CloudBackupSection> {
  List<CloudBackupTask>? _tasks;
  List<CloudCredential> _credentials = const [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final tasks = await controller.loadCloudBackupTasks();
    // Credentials drive both the picker and whether a bucket applies, so they
    // are read alongside rather than on demand inside the sheet.
    final credentials = await controller.getCloudCredentials();
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _credentials = credentials ?? const [];
      _error = tasks == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canCreate = capabilities?.supports('cloud_backup.create') == true;
    final canUpdate = capabilities?.supports('cloud_backup.update') == true;
    final canDelete = capabilities?.supports('cloud_backup.delete') == true;
    final canRun = capabilities?.supports('cloud_backup.sync') == true;
    final tasks = _tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.protectionCloudBackups,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (canCreate)
              IconButton(
                // A backup cannot exist without a cloud credential, and those
                // are created in the web UI, so the action explains itself
                // rather than opening a sheet with an empty picker.
                onPressed: _credentials.isEmpty ? null : _create,
                tooltip: l10n.protectionNewCloudBackup,
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!),
            ),
          )
        else ...[
          if (tasks == null || tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(l10n.protectionNoCloudBackups),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final (index, task) in tasks.indexed) ...[
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        child: Icon(
                          task.enabled
                              ? Icons.cloud_upload_outlined
                              : Icons.cloud_off_outlined,
                        ),
                      ),
                      title: Text(
                        task.description.isEmpty ? task.path : task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        l10n.protectionCloudBackupSubtitle(
                          l10n.scheduleSummary(task.schedule),
                          task.keepLast,
                        ),
                      ),
                      trailing: canRun || canUpdate || canDelete
                          ? PopupMenuButton<_BackupAction>(
                              itemBuilder: (context) => [
                                if (canRun) ...[
                                  PopupMenuItem(
                                    value: _BackupAction.run,
                                    child: Text(
                                      l10n.protectionCloudBackupRunAction,
                                    ),
                                  ),
                                  // A dry run is the safe way to check a task
                                  // works before paying for a real transfer.
                                  PopupMenuItem(
                                    value: _BackupAction.dryRun,
                                    child: Text(
                                      l10n.protectionCloudBackupDryRun,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _BackupAction.abort,
                                    child: Text(
                                      l10n.protectionCloudBackupAbort,
                                    ),
                                  ),
                                ],
                                PopupMenuItem(
                                  value: _BackupAction.snapshots,
                                  child: Text(
                                    l10n.protectionCloudBackupSnapshots,
                                  ),
                                ),
                                if (canUpdate)
                                  PopupMenuItem(
                                    value: _BackupAction.edit,
                                    child: Text(l10n.sysEdit),
                                  ),
                                if (canDelete)
                                  PopupMenuItem(
                                    value: _BackupAction.delete,
                                    child: Text(l10n.sysDelete),
                                  ),
                              ],
                              onSelected: (action) => switch (action) {
                                _BackupAction.run => _run(task),
                                _BackupAction.dryRun => _run(
                                  task,
                                  dryRun: true,
                                ),
                                _BackupAction.abort => _abort(task),
                                _BackupAction.snapshots => _showSnapshots(task),
                                _BackupAction.edit => _edit(task),
                                _BackupAction.delete => _delete(task),
                              },
                            )
                          : null,
                      onTap: canUpdate ? () => _edit(task) : null,
                    ),
                    if (index < tasks.length - 1)
                      const Divider(indent: 68, height: 1),
                  ],
                ],
              ),
            ),
          if (canCreate && _credentials.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.protectionCloudBackupNeedsCredential,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ],
    );
  }

  CloudCredential? _credentialFor(int? id) {
    for (final credential in _credentials) {
      if (credential.id == id) return credential;
    }
    return null;
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<CloudBackupConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CloudBackupSheet(
        baseline: CloudBackupConfiguration(
          path: '',
          credentialId: _credentials.first.id,
          keepLast: 7,
        ),
        credentials: _credentials,
      ),
    );
    if (configuration == null || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createCloudBackupTask(
          configuration,
          _credentialFor(configuration.credentialId),
        );
    if (!mounted) return;
    _report(receipt != null, l10n.protectionCloudBackupCreated);
    if (receipt != null) await _load();
  }

  Future<void> _edit(CloudBackupTask task) async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<CloudBackupConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CloudBackupSheet(
        baseline: task.configuration,
        credentials: _credentials,
        isNew: false,
      ),
    );
    if (configuration == null || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateCloudBackupTask(
          task.id,
          configuration,
          _credentialFor(configuration.credentialId),
          // The editor leaves the repository password blank to keep the stored
          // one, and the server requires the field, so it is read back here and
          // nowhere else.
          storedPassword: task.storedPassword,
        );
    if (!mounted) return;
    _report(receipt != null, l10n.protectionCloudBackupUpdated);
    if (receipt != null) await _load();
  }

  /// Runs a backup. A real run costs provider bandwidth and requests, so it is
  /// confirmed; a dry run changes nothing and is not.
  Future<void> _run(CloudBackupTask task, {bool dryRun = false}) async {
    final l10n = AppLocalizations.of(context);
    if (!dryRun) {
      final serverName =
          ref.read(connectionControllerProvider).profile?.name ??
          l10n.systemServerFallback;
      final confirmed = await confirmDestructiveAction(
        context,
        title: l10n.protectionCloudBackupRunTitle(task.path),
        server: serverName,
        target: task.path,
        actionLabel: l10n.protectionCloudBackupRunAction,
        impact: MutationImpact.high,
        consequences: [
          ImpactDetail(
            icon: Icons.cloud_upload_outlined,
            text: l10n.protectionCloudBackupRunConsequence,
          ),
        ],
      );
      if (!confirmed || !mounted) return;
    }
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .runCloudBackup(task.id, dryRun: dryRun);
    if (!mounted) return;
    _report(
      receipt != null,
      dryRun
          ? l10n.protectionCloudBackupDryRunStarted(task.path)
          : l10n.protectionCloudBackupRunning(task.path),
    );
  }

  /// Aborts a running backup.
  ///
  /// Confirmed for the same reason starting one is: the run is interrupted
  /// partway, so it produces no usable snapshot, and backing up again re-sends
  /// the data at the provider's expense. Starting a backup already asked, so
  /// throwing that work away on a single menu tap was the inconsistency.
  Future<void> _abort(CloudBackupTask task) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionCloudBackupAbortTitle(task.path),
      server: serverName,
      target: task.path,
      actionLabel: l10n.protectionCloudBackupAbortAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.cloud_off_outlined,
          text: l10n.protectionCloudBackupAbortConsequence,
        ),
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: l10n.protectionCloudBackupAbortConsequenceRestart,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .abortCloudBackup(task.id);
    if (!mounted) return;
    _report(receipt != null, l10n.protectionCloudBackupAborted);
  }

  Future<void> _showSnapshots(CloudBackupTask task) async {
    final l10n = AppLocalizations.of(context);
    final snapshots = await ref
        .read(serverActionControllerProvider.notifier)
        .loadCloudBackupSnapshots(task.id);
    if (!mounted) return;
    if (snapshots == null) {
      _report(false, '');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.protectionCloudBackupSnapshots,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              if (snapshots.isEmpty)
                Text(l10n.protectionCloudBackupSnapshotsEmpty)
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final snapshot in snapshots)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.photo_camera_back_outlined),
                          title: Text(snapshot.id),
                          subtitle: Text(
                            [
                              if (snapshot.time != null)
                                snapshot.time!.toLocal().toString(),
                              if (snapshot.hostname != null) snapshot.hostname!,
                            ].join(' · '),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(CloudBackupTask task) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.protectionCloudBackupDeleteTitle,
      server: serverName,
      target: task.path,
      actionLabel: l10n.protectionCloudBackupDeleteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.schedule_rounded,
          text: l10n.protectionCloudBackupDeleteConsequence,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteCloudBackupTask(task.id);
    if (!mounted) return;
    _report(receipt != null, l10n.protectionCloudBackupDeleted);
    if (receipt != null) await _load();
  }

  void _report(bool succeeded, String success) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? success
              : ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed,
        ),
        showCloseIcon: !succeeded,
      ),
    );
  }
}

enum _BackupAction { run, dryRun, abort, snapshots, edit, delete }
