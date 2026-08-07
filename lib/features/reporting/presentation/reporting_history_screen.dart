import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/l10n/data_message_localizations.dart';
import '../../../core/theme/chart_palette.dart';
import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart' show formatBytes;
import '../domain/reporting_series.dart';
import '../domain/reporting_memory.dart';
import 'reporting_provider.dart';
import 'sparkline.dart';

enum ReportingHistoryMetric {
  cpu('cpu'),
  memory('memory'),
  network('network'),
  disk('disk');

  const ReportingHistoryMetric(this.path);
  final String path;

  static ReportingHistoryMetric fromPath(String path) =>
      values.firstWhere((metric) => metric.path == path, orElse: () => cpu);
}

class ReportingHistoryScreen extends ConsumerStatefulWidget {
  const ReportingHistoryScreen({required this.metric, super.key});

  final ReportingHistoryMetric metric;

  @override
  ConsumerState<ReportingHistoryScreen> createState() =>
      _ReportingHistoryScreenState();
}

class _ReportingHistoryScreenState
    extends ConsumerState<ReportingHistoryScreen> {
  var _range = ReportingHistoryRange.day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(reportingHistoryProvider(_range));
    return Scaffold(
      body: SafeRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportingHistoryProvider(_range));
          await ref.read(reportingHistoryProvider(_range).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(title: Text(_title(l10n))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverList.list(
                children: [
                  SegmentedButton<ReportingHistoryRange>(
                    segments: [
                      ButtonSegment(
                        value: ReportingHistoryRange.hour,
                        label: Text(l10n.reportingRangeHour),
                      ),
                      ButtonSegment(
                        value: ReportingHistoryRange.day,
                        label: Text(l10n.reportingRangeDay),
                      ),
                      ButtonSegment(
                        value: ReportingHistoryRange.week,
                        label: Text(l10n.reportingRangeWeek),
                      ),
                    ],
                    selected: {_range},
                    onSelectionChanged: (selection) =>
                        setState(() => _range = selection.first),
                  ),
                  const SizedBox(height: 20),
                  history.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(56),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => _HistoryMessage(
                      message: l10n.dataMsgReportingUnreadable,
                    ),
                    data: (snapshot) {
                      if (snapshot.hasError) {
                        return _HistoryMessage(
                          message: l10n.dataMessage(snapshot.error!),
                        );
                      }
                      return _content(context, snapshot, l10n);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ReportingSnapshot snapshot,
    AppLocalizations l10n,
  ) => switch (widget.metric) {
    ReportingHistoryMetric.cpu => _SingleHistoryCard(
      key: const ValueKey('reporting-history-cpu'),
      title: l10n.reportingCpuUtilisation,
      values: snapshot.cpu?.cpuUtilisation ?? const [],
      maximum: 100,
      color: context.chartPalette.cpu,
      formatValue: (value) => '${value.toStringAsFixed(0)}%',
    ),
    ReportingHistoryMetric.memory => _SingleHistoryCard(
      key: const ValueKey('reporting-history-memory'),
      title: l10n.reportingMemoryInUse,
      values: reportingMemoryUsedBytes(snapshot),
      maximum: snapshot.totalMemoryBytes?.toDouble(),
      color: context.chartPalette.memory,
      formatValue: (value) => formatBytes(value.round()),
    ),
    ReportingHistoryMetric.network => _DeviceHistoryPager(
      key: const ValueKey('reporting-history-network'),
      series: snapshot.network,
      firstLabel: l10n.reportingNetworkReceived,
      secondLabel: l10n.reportingNetworkSent,
      firstDimension: 'received',
      secondDimension: 'sent',
      formatValue: _formatKilobits,
      firstColor: context.chartPalette.networkReceived,
      secondColor: context.chartPalette.networkSent,
    ),
    ReportingHistoryMetric.disk => _DeviceHistoryPager(
      key: const ValueKey('reporting-history-disk'),
      series: snapshot.disks,
      firstLabel: l10n.reportingDiskReads,
      secondLabel: l10n.reportingDiskWrites,
      firstDimension: 'reads',
      secondDimension: 'writes',
      formatValue: _formatKibibytes,
      firstColor: context.chartPalette.diskReads,
      secondColor: context.chartPalette.diskWrites,
    ),
  };

  String _title(AppLocalizations l10n) => switch (widget.metric) {
    ReportingHistoryMetric.cpu => l10n.reportingCpuHistory,
    ReportingHistoryMetric.memory => l10n.reportingMemoryHistory,
    ReportingHistoryMetric.network => l10n.reportingNetworkHistory,
    ReportingHistoryMetric.disk => l10n.reportingDiskHistory,
  };

  static String _formatKilobits(double value) {
    final absolute = value.abs();
    return absolute >= 1000
        ? '${(absolute / 1000).toStringAsFixed(1)} Mb/s'
        : '${absolute.toStringAsFixed(0)} kb/s';
  }

  static String _formatKibibytes(double value) {
    final absolute = value.abs();
    return absolute >= 1024
        ? '${(absolute / 1024).toStringAsFixed(1)} MiB/s'
        : '${absolute.toStringAsFixed(0)} KiB/s';
  }
}

class _SingleHistoryCard extends StatelessWidget {
  const _SingleHistoryCard({
    required this.title,
    required this.values,
    required this.formatValue,
    required this.color,
    this.maximum,
    super.key,
  });

  final String title;
  final List<double?> values;
  final String Function(double) formatValue;
  final double? maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final samples = values.whereType<double>().toList(growable: false);
    if (samples.isEmpty) {
      return _HistoryMessage(
        message: AppLocalizations.of(context).reportingNoSamples,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Sparkline(
              values: values,
              label: title,
              minimum: 0,
              maximum: maximum,
              height: 190,
              color: color,
              formatValue: formatValue,
            ),
            const SizedBox(height: 20),
            _Statistics(values: samples, formatValue: formatValue),
          ],
        ),
      ),
    );
  }
}

class _DeviceHistoryPager extends StatefulWidget {
  const _DeviceHistoryPager({
    required this.series,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstDimension,
    required this.secondDimension,
    required this.formatValue,
    required this.firstColor,
    required this.secondColor,
    super.key,
  });

  final List<ReportingSeries> series;
  final String firstLabel;
  final String secondLabel;
  final String firstDimension;
  final String secondDimension;
  final String Function(double) formatValue;
  final Color firstColor;
  final Color secondColor;

  @override
  State<_DeviceHistoryPager> createState() => _DeviceHistoryPagerState();
}

class _DeviceHistoryPagerState extends State<_DeviceHistoryPager> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.series.isEmpty) {
      return _HistoryMessage(
        message: AppLocalizations.of(context).reportingNoSamples,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _identifier(widget.series[_page]),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.series.length > 1)
              Text('${_page + 1} / ${widget.series.length}'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 640,
          child: PageView.builder(
            itemCount: widget.series.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final series = widget.series[index];
              final first = _absolute(series.valuesFor(widget.firstDimension));
              final second = _absolute(
                series.valuesFor(widget.secondDimension),
              );
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _SingleHistoryCard(
                      title: widget.firstLabel,
                      values: first,
                      formatValue: widget.formatValue,
                      color: widget.firstColor,
                    ),
                    _SingleHistoryCard(
                      title: widget.secondLabel,
                      values: second,
                      formatValue: widget.formatValue,
                      color: widget.secondColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static List<double?> _absolute(List<double?> values) => [
    for (final value in values) value?.abs(),
  ];

  static String _identifier(ReportingSeries series) =>
      (series.identifier ?? series.name).split(' | ').first;
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.values, required this.formatValue});

  final List<double> values;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final highest = values.reduce((a, b) => a > b ? a : b);
    final average = values.reduce((a, b) => a + b) / values.length;
    return Row(
      children: [
        _Stat(label: l10n.reportingCurrent, value: formatValue(values.last)),
        _Stat(label: l10n.reportingAverage, value: formatValue(average)),
        _Stat(label: l10n.reportingMinimum, value: formatValue(lowest)),
        _Stat(label: l10n.reportingMaximum, value: formatValue(highest)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
