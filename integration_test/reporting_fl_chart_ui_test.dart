import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/reporting/domain/reporting_memory.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/sparkline.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shared fl_chart design renders compact and history charts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E999C)),
        ),
        home: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Sparkline(
                      key: const ValueKey('compact-fl-chart'),
                      values: const [12, 18, null, 34, 41, 37],
                      label: 'CPU 사용률',
                      minimum: 0,
                      maximum: 100,
                      formatValue: (value) => '${value.round()}%',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Sparkline(
                      key: const ValueKey('history-fl-chart'),
                      values: const [12, 18, 28, 34, 41, 37],
                      label: 'CPU 기록',
                      minimum: 0,
                      maximum: 100,
                      height: 190,
                      formatValue: (value) => '${value.round()}%',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 314,
                  height: 232,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'enp0s1',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Sparkline(
                          values: const [12, 18, 34, 41, 37],
                          label: '수신',
                          minimum: 0,
                          height: 38,
                          formatValue: (value) => '${value.round()} kb/s',
                        ),
                        const SizedBox(height: 12),
                        Sparkline(
                          values: const [8, 15, 22, 19, 25],
                          label: '송신',
                          minimum: 0,
                          height: 38,
                          formatValue: (value) => '${value.round()} kb/s',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNWidgets(4));
    for (final chart in tester.widgetList<LineChart>(find.byType(LineChart))) {
      expect(chart.duration, Duration.zero);
    }
    const total = 32 * 1024 * 1024 * 1024;
    const available = 20 * 1024 * 1024 * 1024;
    final memory = reportingMemoryUsedBytes(
      ReportingSnapshot(
        totalMemoryBytes: total,
        memory: ReportingSeries(
          name: 'memory',
          unit: 'bytes',
          legend: ['available'],
          points: [
            ReportingPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(0),
              values: [available.toDouble()],
            ),
          ],
        ),
      ),
    );
    expect(memory.single, 12 * 1024 * 1024 * 1024);
    expect(memory.single, isNot(0));
    expect(find.text('37%'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    final chart = find.descendant(
      of: find.byKey(const ValueKey('history-fl-chart')),
      matching: find.byType(LineChart),
    );
    await tester.tapAt(tester.getCenter(chart));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
