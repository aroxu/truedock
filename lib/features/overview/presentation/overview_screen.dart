import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../connection/domain/system_info.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../reporting/domain/reporting_series.dart';
import '../../reporting/domain/reporting_memory.dart';
import '../../reporting/presentation/reporting_provider.dart';
import '../../reporting/presentation/sparkline.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../../jobs/presentation/job_localizations.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/l10n/data_message_localizations.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';
import '../../../core/theme/chart_palette.dart';
import '../../../core/theme/app_motion.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final resources = ref.watch(serverResourcesProvider);
    final reporting = ref.watch(overviewReportingProvider);
    return SafeRefreshIndicator(
      onRefresh: () async {
        if (!connection.isConnected) return;
        final info = ref
            .read(connectionControllerProvider.notifier)
            .refreshSystemInfo();
        refreshServerResources(ref);
        refreshOverviewReporting(ref);
        await Future.wait([
          info,
          ref.read(serverResourcesProvider.future),
          ref.read(overviewReportingProvider.future),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            toolbarHeight: kToolbarHeight,
            title: Text(l10n.navOverview),
            actions: [
              if (!connection.hasRetainedSession)
                IconButton(
                  onPressed: () => context.push('/servers/new'),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: l10n.actionAddServer,
                ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList.list(
              children: [
                _MetricsGrid(
                  info: connection.systemInfo,
                  resources: resources.value,
                ),
                if (connection.hasRetainedSession) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.overviewLivePerformance,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _PerformanceStrip(reporting: reporting),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.overviewRecentActivity,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _RecentActivity(
                  connected: connection.isConnected,
                  resources: resources,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.info, required this.resources});
  final SystemInfo? info;
  final ServerResources? resources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final memory = info == null ? '—' : _formatBytes(info!.physicalMemoryBytes);
    final activeAlerts =
        resources?.alerts.items
            .where((alert) => !alert.dismissed)
            .toList(growable: false) ??
        const <SystemAlert>[];
    final unhealthyPools =
        resources?.pools.items
            .where((pool) => pool.status != 'ONLINE')
            .length ??
        0;
    final health = info == null
        ? '—'
        : unhealthyPools > 0
        ? l10n.healthPoolIssues(unhealthyPools)
        : activeAlerts.any((alert) => alert.isCritical)
        ? l10n.healthAttention
        : l10n.healthHealthy;
    final items = <(IconData, String, Widget)>[
      (
        Icons.developer_board_outlined,
        l10n.metricCpuCores,
        Text(
          info?.cores.toString() ?? '—',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      (
        Icons.memory_rounded,
        l10n.metricMemory,
        Text(
          memory,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      (Icons.schedule_rounded, l10n.metricUptime, _LiveUptime(info: info)),
      (
        Icons.health_and_safety_outlined,
        l10n.metricHealth,
        Text(
          health,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          // This grid is already inside the page's CustomScrollView. Without
          // an explicit zero, GridView applies the device safe-area padding a
          // second time and leaves a large blank strip below the app bar.
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 4 ? 1.4 : 1.5,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(item.$1, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    item.$3,
                    Text(item.$2, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    final gib = bytes / (1024 * 1024 * 1024);
    return '${gib.toStringAsFixed(gib >= 10 ? 0 : 1)} GiB';
  }
}

class _LiveUptime extends StatelessWidget {
  const _LiveUptime({required this.info});

  final SystemInfo? info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (info == null) {
      return Text(
        '—',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      );
    }
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          info!.formattedUptime(l10n),
          maxLines: 1,
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  const _PerformanceStrip({required this.reporting});

  final AsyncValue<ReportingSnapshot> reporting;

  @override
  Widget build(BuildContext context) {
    final chartColors = context.chartPalette;
    final l10n = AppLocalizations.of(context);
    return reporting.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) =>
          _ActivityMessage(message: l10n.dataMsgReportingUnreadable),
      data: (snapshot) {
        if (snapshot.hasError) {
          return _ActivityMessage(
            message: AppLocalizations.of(context).dataMessage(snapshot.error!),
          );
        }
        if (snapshot.isEmpty) {
          return _ActivityMessage(message: l10n.reportingNoSamples);
        }
        final cpu = snapshot.cpu?.cpuUtilisation ?? const <double?>[];
        final load = snapshot.load?.valuesFor('load1') ?? const <double?>[];
        final memory = reportingMemoryUsedBytes(snapshot);
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cpu.isNotEmpty)
                  _HistoryLink(
                    key: const ValueKey('reporting-cpu-chart'),
                    route: '/reporting/cpu',
                    child: Sparkline(
                      values: cpu,
                      label: l10n.reportingCpuUtilisation,
                      minimum: 0,
                      maximum: 100,
                      color: chartColors.cpu,
                      formatValue: (value) => '${value.toStringAsFixed(0)}%',
                    ),
                  ),
                if (memory.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _HistoryLink(
                    key: const ValueKey('reporting-memory-chart'),
                    route: '/reporting/memory',
                    child: Sparkline(
                      values: memory,
                      label: l10n.reportingMemoryInUse,
                      minimum: 0,
                      color: chartColors.memory,
                      formatValue: (value) => formatBytes(value.round()),
                    ),
                  ),
                ],
                if (load.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Sparkline(
                    values: load,
                    label: l10n.reportingLoadAverage,
                    minimum: 0,
                    color: chartColors.load,
                    formatValue: (value) => value.toStringAsFixed(2),
                  ),
                ],
                if (snapshot.network.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _PerformanceCarousel(
                    key: const ValueKey('reporting-network-carousel'),
                    title: l10n.reportingNetworkTraffic,
                    series: snapshot.network,
                    inboundLabel: l10n.reportingNetworkReceived,
                    outboundLabel: l10n.reportingNetworkSent,
                    inboundDimension: 'received',
                    outboundDimension: 'sent',
                    formatValue: _formatKilobits,
                    historyRoute: '/reporting/network',
                    firstColor: chartColors.networkReceived,
                    secondColor: chartColors.networkSent,
                  ),
                ],
                if (snapshot.disks.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _PerformanceCarousel(
                    key: const ValueKey('reporting-disk-carousel'),
                    title: l10n.reportingDiskIo,
                    series: snapshot.disks,
                    inboundLabel: l10n.reportingDiskReads,
                    outboundLabel: l10n.reportingDiskWrites,
                    inboundDimension: 'reads',
                    outboundDimension: 'writes',
                    formatValue: _formatKibibytes,
                    historyRoute: '/reporting/disk',
                    firstColor: chartColors.diskReads,
                    secondColor: chartColors.diskWrites,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatKilobits(double value) {
    final absolute = value.abs();
    if (absolute >= 1000) return '${(absolute / 1000).toStringAsFixed(1)} Mb/s';
    return '${absolute.toStringAsFixed(0)} kb/s';
  }

  static String _formatKibibytes(double value) {
    final absolute = value.abs();
    if (absolute >= 1024) {
      return '${(absolute / 1024).toStringAsFixed(1)} MiB/s';
    }
    return '${absolute.toStringAsFixed(0)} KiB/s';
  }
}

class _PerformanceCarousel extends StatefulWidget {
  const _PerformanceCarousel({
    required this.title,
    required this.series,
    required this.inboundLabel,
    required this.outboundLabel,
    required this.inboundDimension,
    required this.outboundDimension,
    required this.formatValue,
    required this.historyRoute,
    required this.firstColor,
    required this.secondColor,
    super.key,
  });

  final String title;
  final List<ReportingSeries> series;
  final String inboundLabel;
  final String outboundLabel;
  final String inboundDimension;
  final String outboundDimension;
  final String Function(double) formatValue;
  final String historyRoute;
  final Color firstColor;
  final Color secondColor;

  @override
  State<_PerformanceCarousel> createState() => _PerformanceCarouselState();
}

class _PerformanceCarouselState extends State<_PerformanceCarousel> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.title, style: theme.textTheme.titleSmall),
            ),
            if (widget.series.length > 1)
              Text(
                '${_page + 1} / ${widget.series.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          // Two shared fl_chart widgets include a value header and range
          // footer in addition to the plot. Keep enough room for both at the
          // phone width used by the overview carousel.
          height: 232,
          child: PageView.builder(
            itemCount: widget.series.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final series = widget.series[index];
              final inbound = _absoluteValues(
                series.valuesFor(widget.inboundDimension),
              );
              final outbound = _absoluteValues(
                series.valuesFor(widget.outboundDimension),
              );
              return _HistoryLink(
                route: widget.historyRoute,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _shortIdentifier(series),
                        style: theme.textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Sparkline(
                        values: inbound,
                        label: widget.inboundLabel,
                        minimum: 0,
                        height: 38,
                        color: widget.firstColor,
                        formatValue: widget.formatValue,
                      ),
                      const SizedBox(height: 12),
                      Sparkline(
                        values: outbound,
                        label: widget.outboundLabel,
                        minimum: 0,
                        height: 38,
                        color: widget.secondColor,
                        formatValue: widget.formatValue,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.series.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < widget.series.length; index++)
                AnimatedContainer(
                  duration: context.motionDuration(AppMotion.quick),
                  curve: AppMotion.standardCurve,
                  width: index == _page ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static List<double?> _absoluteValues(List<double?> values) => [
    for (final value in values) value?.abs(),
  ];

  static String _shortIdentifier(ReportingSeries series) {
    final identifier = series.identifier ?? series.name;
    return identifier.split(' | ').first;
  }
}

class _HistoryLink extends StatelessWidget {
  const _HistoryLink({required this.route, required this.child, super.key});

  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(route),
      child: Padding(padding: const EdgeInsets.all(4), child: child),
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.connected, required this.resources});

  final bool connected;
  final AsyncValue<ServerResources> resources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!connected) return const _ActivityMessage();
    return resources.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) =>
          _ActivityMessage(message: l10n.overviewActivityLoadFailed),
      data: (data) {
        final jobs = data.jobs.items
            .where((job) => job.isActive || job.state == 'FAILED')
            .take(5)
            .toList(growable: false);
        final alerts = data.alerts.items
            .where((alert) => !alert.dismissed)
            .take(5)
            .toList(growable: false);
        if (jobs.isEmpty && alerts.isEmpty) {
          return _ActivityMessage(message: l10n.activityNoAttention);
        }
        return Card(
          child: Column(
            children: [
              for (final (index, alert) in alerts.indexed) ...[
                _AlertTile(alert: alert),
                if (index < alerts.length - 1 || jobs.isNotEmpty)
                  const Divider(indent: 68, height: 1),
              ],
              for (final (index, job) in jobs.indexed) ...[
                _JobTile(job: job),
                if (index < jobs.length - 1)
                  const Divider(indent: 68, height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final SystemAlert alert;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(
        alert.isCritical
            ? Icons.error_rounded
            : alert.isWarning
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded,
        color: alert.isCritical ? colors.error : colors.tertiary,
      ),
      title: Text(alert.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(alert.level),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => _AlertDetailsDialog(alert: alert),
      ),
    );
  }
}

class _AlertDetailsDialog extends StatelessWidget {
  const _AlertDetailsDialog({required this.alert});

  final SystemAlert alert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final occurredAt = alert.lastOccurredAt ?? alert.occurredAt;
    return AlertDialog(
      icon: Icon(
        alert.isCritical
            ? Icons.error_rounded
            : alert.isWarning
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded,
        color: alert.isCritical ? colors.error : colors.tertiary,
      ),
      title: Text(l10n.activityAlertDetails),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AlertDetailField(
                label: l10n.activityAlertSeverity,
                value: _localizedAlertLevel(l10n, alert.level),
              ),
              if (occurredAt != null)
                _AlertDetailField(
                  label: l10n.activityAlertOccurredAt,
                  value: MaterialLocalizations.of(
                    context,
                  ).formatFullDate(occurredAt.toLocal()),
                ),
              Text(
                _plainAlertText(alert.formattedText ?? alert.text),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

class _AlertDetailField extends StatelessWidget {
  const _AlertDetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}

String _localizedAlertLevel(AppLocalizations l10n, String level) =>
    switch (level.toUpperCase()) {
      'CRITICAL' || 'ERROR' => l10n.activityAlertCritical,
      'WARNING' || 'WARN' => l10n.activityAlertWarning,
      _ => l10n.activityAlertInfo,
    };

String _plainAlertText(String value) => value
    .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .trim();

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});
  final SystemJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: job.isActive
          ? const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : const Icon(Icons.error_outline_rounded),
      title: Text(job.description ?? l10n.jobMethodLabel(job.method)),
      subtitle: Text(job.error ?? job.state),
      trailing: job.percent == null ? null : Text('${job.percent!.round()}%'),
      onTap: () {},
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message ?? AppLocalizations.of(context).activityEmpty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
