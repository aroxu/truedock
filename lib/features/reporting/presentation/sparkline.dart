import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Maps a real metric value onto the shared logarithmic chart axis.
///
/// `log1p` keeps zero finite and preserves useful detail close to zero. The
/// signed form also remains safe if a future TrueNAS metric contains deltas
/// below zero. Labels, statistics, and tooltips always use the real value.
double logChartValue(double value) => value.sign * math.log(1 + value.abs());

/// Restores a plotted logarithmic coordinate to its real metric value.
double inverseLogChartValue(double value) =>
    value.sign * (math.exp(value.abs()) - 1);

/// Condenses dense reporting data into a readable line without discarding the
/// samples between rendered points.
///
/// Every output point is the mean of its time bucket. This avoids the forest
/// of near-vertical strokes produced when thousands of raw points share a few
/// hundred horizontal pixels. Statistics and the current-value label continue
/// to use the original values.
List<double?> reduceChartDensity(
  List<double?> values, {
  int maximumSamples = 100,
}) {
  if (maximumSamples < 2) {
    throw ArgumentError.value(maximumSamples, 'maximumSamples');
  }
  if (values.length <= maximumSamples) return values;

  return [
    for (var bucket = 0; bucket < maximumSamples; bucket++)
      _bucketMean(
        values,
        (bucket * values.length / maximumSamples).floor(),
        ((bucket + 1) * values.length / maximumSamples).floor(),
      ),
  ];
}

double? _bucketMean(List<double?> values, int start, int end) {
  var sum = 0.0;
  var count = 0;
  var gaps = 0;
  for (var index = start; index < end; index++) {
    final value = values[index];
    if (value == null) {
      gaps++;
    } else {
      sum += value;
      count++;
    }
  }
  // Preserve a reporting outage when it occupies at least half the bucket.
  if (count == 0 || gaps >= count) return null;
  return sum / count;
}

/// TrueDock's shared Material 3 line chart for overview and history screens.
///
/// Null samples split the line instead of inventing data across a reporting
/// gap. Exact values remain available in text, semantics, and touch tooltips.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    required this.label,
    required this.formatValue,
    this.minimum,
    this.maximum,
    this.color,
    this.height = 46,
    super.key,
  });

  final List<double?> values;
  final String label;
  final String Function(double value) formatValue;
  final double? minimum;
  final double? maximum;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final samples = values.whereType<double>().toList(growable: false);
    if (samples.isEmpty) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '—',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final observedLow = samples.reduce((a, b) => a < b ? a : b);
    final observedHigh = samples.reduce((a, b) => a > b ? a : b);
    final low = minimum ?? observedLow;
    final high = maximum ?? observedHigh;
    final chartHigh = high <= low ? low + 1 : high;
    final chartLowLog = logChartValue(low);
    final chartHighLog = logChartValue(chartHigh);
    final latest = samples.last;
    final lineColor = color ?? theme.colorScheme.tertiary;
    final chartValues = reduceChartDensity(values)
        .map((value) => value == null ? null : logChartValue(value))
        .toList(growable: false);

    return Semantics(
      label: AppLocalizations.of(context).reportingChartSemantics(
        label,
        formatValue(latest),
        formatValue(low),
        formatValue(high),
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              Text(
                formatValue(latest),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: LineChart(
              key: ValueKey('fl-chart-$label'),
              duration: Duration.zero,
              LineChartData(
                minX: 0,
                maxX: chartValues.length <= 1
                    ? 1
                    : (chartValues.length - 1).toDouble(),
                minY: chartLowLog,
                maxY: chartHighLog,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (chartHighLog - chartLowLog) / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: .55,
                    ),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          formatValue(inverseLogChartValue(spot.y)),
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  getTouchedSpotIndicator: (bar, indexes) => [
                    for (final _ in indexes)
                      TouchedSpotIndicatorData(
                        FlLine(color: lineColor, strokeWidth: 1),
                        FlDotData(
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: theme.colorScheme.surface,
                                strokeWidth: 2,
                                strokeColor: lineColor,
                              ),
                        ),
                      ),
                  ],
                ),
                lineBarsData: _segments(chartValues, lineColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _segments(List<double?> chartValues, Color lineColor) {
    final result = <LineChartBarData>[];
    var index = 0;
    while (index < chartValues.length) {
      while (index < chartValues.length && chartValues[index] == null) {
        index++;
      }
      final spots = <FlSpot>[];
      while (index < chartValues.length && chartValues[index] != null) {
        spots.add(FlSpot(index.toDouble(), chartValues[index]!));
        index++;
      }
      if (spots.isEmpty) continue;
      result.add(
        LineChartBarData(
          spots: spots,
          isCurved: spots.length > 2,
          // A moderate cubic interpolation rounds the joins between averaged
          // buckets without turning short spikes into wide artificial hills.
          curveSmoothness: .35,
          preventCurveOverShooting: true,
          color: lineColor,
          barWidth: 1.6,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }
    return result;
  }
}
