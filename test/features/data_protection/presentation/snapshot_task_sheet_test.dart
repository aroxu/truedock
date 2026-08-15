import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/presentation/snapshot_task_sheet.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Wraps a sheet with the localization delegates the app installs, so the
/// widget resolves the same generated strings it uses in production.
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('reviews a valid periodic snapshot task', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        const SnapshotTaskSheet(
          datasets: [
            Dataset(
              id: 'tank/documents',
              name: 'tank/documents',
              type: 'FILESYSTEM',
            ),
          ],
        ),
      ),
    );

    expect(find.text('New snapshot task'), findsOneWidget);
    expect(find.text('tank/documents'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review snapshot task'), findsOneWidget);
    expect(find.text('At the start of every hour'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create task'), findsOneWidget);
  });

  testWidgets('blocks creation when no eligible dataset exists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(const SnapshotTaskSheet(datasets: [])));

    expect(
      find.textContaining('No unlocked filesystem datasets'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('restores an existing task for editing', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final task = SnapshotTask.fromJson({
      'id': 9,
      'dataset': 'tank/documents',
      'recursive': true,
      'lifetime_value': 3,
      'lifetime_unit': 'MONTH',
      'enabled': false,
      'exclude': ['tank/documents/cache'],
      'naming_schema': 'monthly-%Y-%m',
      'allow_empty': false,
      'schedule': {
        'minute': '00',
        'hour': '00',
        'dom': '1',
        'month': '*',
        'dow': '*',
        'begin': '00:00',
        'end': '23:59',
      },
    });
    await tester.pumpWidget(
      _app(
        SnapshotTaskSheet(
          datasets: const [
            Dataset(
              id: 'tank/documents',
              name: 'tank/documents',
              type: 'FILESYSTEM',
            ),
          ],
          existingTask: task,
        ),
      ),
    );

    expect(find.text('Edit snapshot task'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('monthly-%Y-%m'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Review'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
  });
}
