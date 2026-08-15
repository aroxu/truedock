import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:true_dock/features/reporting/presentation/reporting_history_screen.dart';
import 'package:true_dock/features/reporting/presentation/reporting_provider.dart';
import 'package:true_dock/l10n/app_localizations.dart';

ReportingSeries _series(
  String name,
  List<String> legend,
  List<List<Object?>> data, {
  String? identifier,
}) => ReportingSeries.fromJson({
  'name': name,
  'identifier': ?identifier,
  'legend': ['time', ...legend],
  'data': data,
});

final _snapshot = ReportingSnapshot(
  cpu: _series(
    'cpu',
    ['user'],
    [
      [1760000000, 10.0],
      [1760000030, 20.0],
      [1760000060, 30.0],
    ],
  ),
  memory: _series(
    'memory',
    ['available'],
    [
      [1760000000, 4096.0],
      [1760000060, 3072.0],
    ],
  ),
  totalMemoryBytes: 8 * 1024 * 1024 * 1024,
  network: [
    _series(
      'interface',
      ['received', 'sent'],
      [
        [1760000000, 100.0, -50.0],
        [1760000060, 200.0, -75.0],
      ],
      identifier: 'ens18',
    ),
    _series(
      'interface',
      ['received', 'sent'],
      [
        [1760000000, 1.0, -2.0],
      ],
      identifier: 'ens19',
    ),
  ],
  disks: [
    _series(
      'disk',
      ['reads', 'writes'],
      [
        [1760000000, 12.0, -8.0],
      ],
      identifier: 'sda | Model: Test',
    ),
  ],
);

Future<void> _pump(WidgetTester tester, ReportingHistoryMetric metric) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        for (final range in ReportingHistoryRange.values)
          reportingHistoryProvider(
            range,
          ).overrideWith((ref) async => _snapshot),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReportingHistoryScreen(metric: metric),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('CPU history shows a large chart and statistics', (tester) async {
    await _pump(tester, ReportingHistoryMetric.cpu);

    expect(find.byKey(const ValueKey('reporting-history-cpu')), findsOneWidget);
    expect(find.text('CPU history'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('30%'), findsWidgets);
    expect(find.byType(LineChart), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final line = chart.data.lineBarsData.single;
    expect(line.isCurved, isTrue);
    expect(line.curveSmoothness, .35);
    expect(line.preventCurveOverShooting, isTrue);
  });

  testWidgets('RAM history derives used memory from available memory', (
    tester,
  ) async {
    await _pump(tester, ReportingHistoryMetric.memory);

    expect(
      find.byKey(const ValueKey('reporting-history-memory')),
      findsOneWidget,
    );
    expect(find.text('RAM history'), findsOneWidget);
    expect(find.textContaining('GiB'), findsWidgets);
  });

  testWidgets('network history pages through interfaces', (tester) async {
    await _pump(tester, ReportingHistoryMetric.network);

    expect(
      find.byKey(const ValueKey('reporting-history-network')),
      findsOneWidget,
    );
    expect(find.text('ens18'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();

    expect(find.text('ens19'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('disk history renders read and write throughput', (tester) async {
    await _pump(tester, ReportingHistoryMetric.disk);

    expect(
      find.byKey(const ValueKey('reporting-history-disk')),
      findsOneWidget,
    );
    expect(find.text('sda'), findsOneWidget);
    expect(find.text('Reads'), findsOneWidget);
    expect(find.text('Writes'), findsOneWidget);
    expect(find.textContaining('KiB/s'), findsWidgets);
  });
}
