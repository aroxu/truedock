import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/theme/chart_palette.dart';

void main() {
  test('chart palette follows the active Material color scheme', () {
    final teal = ColorScheme.fromSeed(seedColor: const Color(0xFF2E999C));
    final violet = ColorScheme.fromSeed(seedColor: const Color(0xFF7256B8));

    final tealCharts = ChartPalette.fromScheme(teal);
    final violetCharts = ChartPalette.fromScheme(violet);

    expect(tealCharts.cpu, teal.primary);
    expect(tealCharts.memory, teal.tertiary);
    expect(tealCharts.networkSent, teal.tertiary);
    expect(violetCharts.cpu, violet.primary);
    expect(violetCharts.diskReads, violet.secondary);
    expect(violetCharts.cpu, isNot(tealCharts.cpu));
  });
}
