import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../../core/l10n/data_message_localizations.dart';
import '../../../core/widgets/destructive_confirmation.dart';
import 'job_localizations.dart';

/// Filters offered by the job center. TrueNAS reports many terminal jobs, so
/// the default view prioritises in-flight and failed work.
enum JobFilter { active, failed, completed, all }

extension JobFilterLabel on JobFilter {
  /// English fallback used by logs and tests; the UI renders
  /// [JobCenterLocalizations.jobFilterLabel] instead.
  String get label => switch (this) {
    JobFilter.active => 'Active',
    JobFilter.failed => 'Failed',
    JobFilter.completed => 'Completed',
    JobFilter.all => 'All',
  };

  bool matches(SystemJob job) => switch (this) {
    JobFilter.active => job.isActive,
    JobFilter.failed => job.hasFailed || job.error != null,
    JobFilter.completed => job.isSuccessful,
    JobFilter.all => true,
  };
}

/// Central job center: progress, history, failures, and abort for the jobs the
/// server marks abortable.
class JobCenter extends ConsumerStatefulWidget {
  const JobCenter({required this.section, super.key});

  final ResourceSection<SystemJob> section;

  @override
  ConsumerState<JobCenter> createState() => _JobCenterState();
}

class _JobCenterState extends ConsumerState<JobCenter> {
  JobFilter _filter = JobFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final section = widget.section;
    if (section.hasError) {
      return _JobMessage(
        icon: Icons.lock_outline_rounded,
        message: l10n.dataMessage(section.error!),
      );
    }

    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canAbort = capabilities?.supports('core.job_abort') == true;
    final actions = ref.watch(serverActionControllerProvider);
    final jobs = section.items.where(_filter.matches).toList(growable: false)
      ..sort((a, b) => b.id.compareTo(a.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in JobFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _filter == filter,
                    label: Text(
                      l10n.jobsFilterChipLabel(
                        l10n.jobFilterLabel(filter),
                        section.items.where(filter.matches).length,
                      ),
                    ),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (jobs.isEmpty)
          _JobMessage(
            icon: Icons.pending_actions_outlined,
            message: l10n.jobFilterEmptyMessage(_filter),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, job) in jobs.take(100).indexed) ...[
                  _JobTile(
                    job: job,
                    busy: actions.isBusy('job-abort:${job.id}'),
                    canAbort: canAbort,
                    onAbort: () => _confirmAbort(job),
                    onOpen: () => _openDetail(job, canAbort: canAbort),
                  ),
                  if (index < jobs.take(100).length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openDetail(SystemJob job, {required bool canAbort}) async {
    final abort = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => LiveJobDetailSheet(
        initialJob: job,
        canAbort: canAbort && job.canAbort,
      ),
    );
    if (abort == true) await _confirmAbort(job);
  }

  /// Confirms and aborts a running job.
  ///
  /// This used to raise its own `AlertDialog`. It asked the right question, but
  /// being a bespoke surface it never named the server - and this screen can be
  /// looking at any registered one. Aborting a job on the wrong server is
  /// exactly the mistake naming it prevents, so it now uses the shared
  /// confirmation like every other disruptive action.
  Future<void> _confirmAbort(SystemJob job) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.jobsAbortDialogTitle,
      server: serverName,
      target: l10n.jobsAbortTarget(job.id, l10n.jobMethodLabel(job.method)),
      actionLabel: l10n.jobsAbortConfirm,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.undo_rounded,
          text: l10n.jobsAbortConsequenceNoRollback,
        ),
        ImpactDetail(
          icon: Icons.timer_outlined,
          text: l10n.jobsAbortConsequenceRace,
        ),
      ],
    );
    if (!confirmed || !mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .abortJob(job.id);
    if (!mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.jobsAbortFailed
              : l10n.jobsAbortRequested(job.id),
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.busy,
    required this.canAbort,
    required this.onAbort,
    required this.onOpen,
  });

  final SystemJob job;
  final bool busy;
  final bool canAbort;
  final VoidCallback onAbort;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final percent = job.percent;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      onTap: onOpen,
      leading: Icon(jobIcon(job), color: jobColor(job, colors)),
      title: Text(l10n.jobMethodLabel(job.method)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.error ?? job.description ?? l10n.jobStateLabel(job),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (job.isRunning) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percent == null ? null : (percent / 100).clamp(0, 1),
            ),
          ],
        ],
      ),
      isThreeLine: job.isRunning,
      trailing: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : canAbort && job.canAbort
          ? IconButton.filledTonal(
              onPressed: onAbort,
              tooltip: l10n.jobsAbortTooltip,
              icon: const Icon(Icons.stop_rounded),
            )
          : percent == null
          ? null
          : Text('${percent.toInt()}%'),
    );
  }
}

class JobDetailSheet extends StatelessWidget {
  const JobDetailSheet({required this.job, required this.canAbort, super.key});

  final SystemJob job;
  final bool canAbort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(jobIcon(job), color: jobColor(job, theme.colorScheme)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.jobMethodLabel(job.method),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _JobDetailRow(label: l10n.jobsDetailJobId, value: '${job.id}'),
              _JobDetailRow(label: l10n.jobsDetailMethod, value: job.method),
              _JobDetailRow(
                label: l10n.jobsDetailState,
                value: l10n.jobStateLabel(job),
              ),
              if (job.percent case final percent?)
                _JobDetailRow(
                  label: l10n.jobsDetailProgress,
                  value: '${percent.toInt()}%',
                ),
              if (job.description case final description?)
                _JobDetailRow(label: l10n.jobsDetailStep, value: description),
              _JobDetailRow(
                label: l10n.jobsDetailStarted,
                value: formatJobTimestamp(job.startedAt),
              ),
              _JobDetailRow(
                label: l10n.jobsDetailFinished,
                value: formatJobTimestamp(job.finishedAt),
              ),
              _JobDetailRow(
                label: l10n.jobsDetailDuration,
                value: formatJobDuration(job.duration),
              ),
              if (job.error case final error?) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ],
              if (job.logsExcerpt case final logs?) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.jobsDetailLogExcerpt,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      logs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (canAbort)
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.jobsAbortConfirm),
                )
              else if (job.isActive)
                Text(
                  l10n.jobsNotAbortable,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Polls the selected job while its bottom sheet remains open.
///
/// The active-jobs feed deliberately drops terminal jobs, so detail uses a
/// job-id query and can show the final SUCCESS/FAILED/ABORTED state too.
class LiveJobDetailSheet extends ConsumerStatefulWidget {
  const LiveJobDetailSheet({
    required this.initialJob,
    required this.canAbort,
    super.key,
  });

  final SystemJob initialJob;
  final bool canAbort;

  @override
  ConsumerState<LiveJobDetailSheet> createState() => _LiveJobDetailSheetState();
}

class _LiveJobDetailSheetState extends ConsumerState<LiveJobDetailSheet> {
  Timer? _timer;
  bool _refreshing = false;
  late SystemJob _latestJob = widget.initialJob;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_refresh);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted ||
        _refreshing ||
        !ref.read(connectionControllerProvider).isConnected) {
      return;
    }

    _refreshing = true;
    try {
      final current = await ref.refresh(
        jobDetailProvider(widget.initialJob.id).future,
      );
      if (!mounted || current == null) return;
      setState(() => _latestJob = current);
    } catch (_) {
      // Keep the last confirmed snapshot during a transient polling failure.
      // The next timer tick retries the read without blanking the sheet.
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JobDetailSheet(
      job: _latestJob,
      canAbort: widget.canAbort && _latestJob.canAbort,
    );
  }
}

class _JobDetailRow extends StatelessWidget {
  const _JobDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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

class _JobMessage extends StatelessWidget {
  const _JobMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

IconData jobIcon(SystemJob job) {
  if (job.hasFailed || job.error != null) return Icons.error_outline_rounded;
  if (job.isRunning) return Icons.sync_rounded;
  if (job.isActive) return Icons.schedule_rounded;
  return Icons.check_circle_outline_rounded;
}

Color jobColor(SystemJob job, ColorScheme colors) {
  if (job.hasFailed || job.error != null) return colors.error;
  if (job.isActive) return colors.primary;
  return colors.onSurfaceVariant;
}

String formatJobTimestamp(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

String formatJobDuration(Duration? value) {
  if (value == null || value.isNegative) return '—';
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}

/// Maps job-center enums and states onto ARB-localized strings.
extension JobCenterLocalizations on AppLocalizations {
  String jobFilterLabel(JobFilter filter) => switch (filter) {
    JobFilter.active => jobsFilterActive,
    JobFilter.failed => jobsFilterFailed,
    JobFilter.completed => jobsFilterCompleted,
    JobFilter.all => jobsFilterAll,
  };

  String jobFilterEmptyMessage(JobFilter filter) => switch (filter) {
    JobFilter.active => jobsEmptyActive,
    JobFilter.failed => jobsEmptyFailed,
    JobFilter.completed => jobsEmptyCompleted,
    JobFilter.all => jobsEmptyAll,
  };

  String jobStateLabel(SystemJob job) => switch (job.state) {
    'RUNNING' => jobsStateRunning,
    'WAITING' => jobsStateWaiting,
    'SUCCESS' => jobsStateSucceeded,
    'FAILED' => jobsStateFailed,
    'ABORTED' => jobsStateAborted,
    final other => other,
  };
}
