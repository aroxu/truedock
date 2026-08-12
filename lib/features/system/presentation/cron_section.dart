import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../data_protection/presentation/task_schedule_localizations.dart';
import '../domain/cron_job_configuration.dart';
import 'cron_job_sheet.dart';

/// Scheduled commands (`cronjob.*`).
///
/// Loads its own list rather than joining the shared resource batch: cron jobs
/// are not part of the dashboard, and the shared load already fans out enough
/// concurrent reads to matter against the server's per-connection call cap.
class CronSection extends ConsumerStatefulWidget {
  const CronSection({super.key});

  @override
  ConsumerState<CronSection> createState() => _CronSectionState();
}

class _CronSectionState extends ConsumerState<CronSection> {
  List<CronJob>? _jobs;
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
    final jobs = await ref
        .read(serverActionControllerProvider.notifier)
        .loadCronJobs();
    if (!mounted) return;
    setState(() {
      _jobs = jobs;
      _error = jobs == null
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
    final canCreate = capabilities?.supports('cronjob.create') == true;
    final canUpdate = capabilities?.supports('cronjob.update') == true;
    final canDelete = capabilities?.supports('cronjob.delete') == true;
    final canRun = capabilities?.supports('cronjob.run') == true;
    final jobs = _jobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sysCronSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
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
        else if (jobs == null || jobs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.sysCronEmpty),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, job) in jobs.indexed) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Icon(
                        job.enabled
                            ? Icons.schedule_rounded
                            : Icons.pause_circle_outline_rounded,
                      ),
                    ),
                    title: Text(
                      job.description.isEmpty ? job.command : job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${l10n.scheduleSummary(job.schedule)} · ${job.user}'
                      '${job.enabled ? '' : ' · ${l10n.sysCronDisabled}'}',
                    ),
                    trailing: canRun || canUpdate || canDelete
                        ? PopupMenuButton<_CronAction>(
                            itemBuilder: (context) => [
                              if (canRun)
                                PopupMenuItem(
                                  value: _CronAction.run,
                                  child: Text(l10n.sysCronRunNow),
                                ),
                              if (canUpdate)
                                PopupMenuItem(
                                  value: _CronAction.edit,
                                  child: Text(l10n.sysEdit),
                                ),
                              if (canDelete)
                                PopupMenuItem(
                                  value: _CronAction.delete,
                                  child: Text(l10n.sysDelete),
                                ),
                            ],
                            onSelected: (action) => switch (action) {
                              _CronAction.run => _run(job),
                              _CronAction.edit => _edit(job),
                              _CronAction.delete => _delete(job),
                            },
                          )
                        : null,
                    onTap: canUpdate ? () => _edit(job) : null,
                  ),
                  if (index < jobs.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
        if (canCreate) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sysCronCreate),
          ),
        ],
      ],
    );
  }

  String get _serverName =>
      ref.read(connectionControllerProvider).profile?.name ??
      AppLocalizations.of(context).systemServerFallback;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<CronJobConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const CronJobSheet(
        baseline: CronJobConfiguration(command: '', user: 'root'),
      ),
    );
    if (configuration == null || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createCronJob(configuration);
    if (!mounted) return;
    _report(receipt != null, l10n.sysCronCreated);
    if (receipt != null) await _load();
  }

  Future<void> _edit(CronJob job) async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<CronJobConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CronJobSheet(baseline: job.configuration),
    );
    if (configuration == null || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateCronJob(job.id, configuration);
    if (!mounted) return;
    _report(receipt != null, l10n.sysCronUpdated);
    if (receipt != null) await _load();
  }

  /// Runs the command now. This executes arbitrary shell with the configured
  /// account's privileges, so it is confirmed rather than a bare tap.
  Future<void> _run(CronJob job) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysCronRunTitle,
      server: _serverName,
      target: job.description.isEmpty ? job.command : job.description,
      actionLabel: l10n.sysCronRunAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.terminal_rounded,
          text: l10n.sysCronRunConsequence(_serverName, job.user),
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .runCronJob(job.id);
    if (!mounted) return;
    _report(receipt != null, l10n.sysCronRunRequested);
  }

  Future<void> _delete(CronJob job) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysCronDeleteTitle,
      server: _serverName,
      target: job.description.isEmpty ? job.command : job.description,
      actionLabel: l10n.sysCronDeleteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.schedule_rounded,
          text: l10n.sysCronDeleteConsequence,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteCronJob(job.id);
    if (!mounted) return;
    _report(receipt != null, l10n.sysCronDeleted);
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

enum _CronAction { run, edit, delete }
