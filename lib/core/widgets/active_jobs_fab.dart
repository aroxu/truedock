import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/connection/presentation/connection_controller.dart';
import '../../features/jobs/presentation/job_center.dart';
import '../../features/jobs/presentation/job_localizations.dart';
import '../../features/resources/domain/server_resources.dart';
import '../../features/resources/presentation/server_resources_provider.dart';
import '../../l10n/app_localizations.dart';

/// Refreshes the active-job feed once a second for the whole application.
///
/// The poll used to live in each [ActiveJobsFabHost]'s state, which meant it
/// ran once per mounted host. Every authenticated route is wrapped in a host
/// and go_router keeps pushed routes alive underneath the visible one, so
/// opening a detail screen quietly multiplied the poll: three screens deep
/// sent three `core.get_jobs` calls a second, all invalidating the same
/// provider and decoding the same response.
///
/// Reference counting keeps exactly one timer alive while at least one host is
/// mounted, regardless of how deep the navigation stack goes. Hosts register
/// and release explicitly rather than through `autoDispose`, because the timer
/// must stop the moment the last host unmounts rather than whenever the
/// container next gets around to collecting an unused provider.
class ActiveJobsPoller {
  ActiveJobsPoller(this._ref);

  static const interval = Duration(seconds: 1);

  final Ref _ref;
  Timer? _timer;
  var _hosts = 0;

  /// Number of timers this poller is running. Always 0 or 1.
  int get activeTimers => _timer == null ? 0 : 1;

  void addHost() {
    _hosts++;
    _timer ??= Timer.periodic(interval, (_) => _poll());
  }

  void removeHost() {
    if (_hosts > 0) _hosts--;
    if (_hosts == 0) _stop();
  }

  void _poll() {
    if (!_ref.read(connectionControllerProvider).isConnected) return;
    // Skipping while a read is in flight keeps a slow server from queueing
    // refreshes behind each other.
    if (_ref.read(activeJobsProvider).isLoading) return;
    _ref.invalidate(activeJobsProvider);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final activeJobsPollerProvider = Provider<ActiveJobsPoller>((ref) {
  final poller = ActiveJobsPoller(ref);
  ref.onDispose(poller._stop);
  return poller;
});

/// Displays running TrueNAS jobs above every authenticated application route.
class ActiveJobsFabHost extends ConsumerStatefulWidget {
  const ActiveJobsFabHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ActiveJobsFabHost> createState() => _ActiveJobsFabHostState();
}

class _ActiveJobsFabHostState extends ConsumerState<ActiveJobsFabHost> {
  ActiveJobsPoller? _poller;

  @override
  void initState() {
    super.initState();
    final poller = ref.read(activeJobsPollerProvider);
    _poller = poller;
    poller.addHost();
  }

  @override
  void dispose() {
    _poller?.removeHost();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = ref
        .watch(connectionControllerProvider)
        .hasRetainedSession;
    final section = ref.watch(activeJobsProvider).value;
    final jobs = hasSession
        ? (section?.items
                  .where((job) => job.isActive)
                  .toList(growable: false) ??
              <SystemJob>[])
        : <SystemJob>[];
    jobs.sort((a, b) => b.id.compareTo(a.id));

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (jobs.isNotEmpty)
          Positioned(
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 80,
            child: SafeArea(
              top: false,
              left: false,
              child: FloatingActionButton.small(
                key: const ValueKey('active-jobs-fab'),
                heroTag: 'global-active-jobs',
                tooltip: AppLocalizations.of(
                  context,
                ).jobsActiveFabTooltip(jobs.length),
                onPressed: () => _openJobs(jobs),
                child: Badge.count(
                  count: jobs.length,
                  child: const Icon(Icons.pending_actions_rounded),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openJobs(List<SystemJob> jobs) async {
    final selected = await showDialog<SystemJob>(
      context: context,
      builder: (context) => _ActiveJobsDialog(initialJobs: jobs),
    );
    if (selected == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          LiveJobDetailSheet(initialJob: selected, canAbort: false),
    );
  }
}

class _ActiveJobsDialog extends ConsumerWidget {
  const _ActiveJobsDialog({required this.initialJobs});

  final List<SystemJob> initialJobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final liveSection = ref.watch(activeJobsProvider).value;
    final jobs =
        (liveSection?.items ?? initialJobs)
            .where((job) => job.isActive)
            .toList(growable: false)
          ..sort((a, b) => b.id.compareTo(a.id));
    return AlertDialog(
      icon: const Icon(Icons.pending_actions_rounded),
      title: Text(l10n.jobsActiveDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 360,
        height: ((jobs.isEmpty ? 1 : jobs.length) * 88.0).clamp(
          88.0,
          MediaQuery.sizeOf(context).height * .6,
        ),
        child: jobs.isEmpty
            ? Center(child: Text(l10n.jobsEmptyActive))
            : ListView.separated(
                itemCount: jobs.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 64),
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return ListTile(
                    key: ValueKey('active-job-${job.id}'),
                    leading: Icon(jobIcon(job), color: jobColor(job, colors)),
                    title: Text(l10n.jobMethodLabel(job.method)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.description ?? l10n.jobStateLabel(job)),
                        if (job.percent case final percent?) ...[
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (percent / 100).clamp(0, 1),
                          ),
                        ],
                      ],
                    ),
                    trailing: job.percent == null
                        ? const Icon(Icons.chevron_right_rounded)
                        : Text(
                            '${job.percent!.toInt()}%',
                            key: ValueKey('active-job-percent-${job.id}'),
                          ),
                    onTap: () => Navigator.pop(context, job),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}
