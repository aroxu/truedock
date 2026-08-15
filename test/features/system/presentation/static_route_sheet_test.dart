import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/features/system/presentation/static_route_sheet.dart';
import 'package:true_dock/features/system/domain/static_route_configuration.dart';

Widget _harness(StaticRouteConfiguration baseline) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showModalBottomSheet<StaticRouteConfiguration>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => StaticRouteSheet(baseline: baseline),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndPump(WidgetTester tester) async {
  await tester.pumpWidget(
    _harness(const StaticRouteConfiguration(destination: '', gateway: '')),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('blocks review when destination and gateway are empty', (
    tester,
  ) async {
    await _openAndPump(tester);
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a destination network.'), findsOneWidget);
    expect(find.text('Enter a gateway address.'), findsOneWidget);
    expect(find.text('Review route'), findsNothing);
  });

  testWidgets('blocks review when destination is missing a CIDR prefix', (
    tester,
  ) async {
    await _openAndPump(tester);
    await tester.enterText(find.byType(TextField).at(0), '192.168.1.0');
    await tester.enterText(find.byType(TextField).at(1), '10.0.0.1');
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a destination as A.B.C.D/E.'), findsOneWidget);
  });

  testWidgets('shows the review step for a valid route', (tester) async {
    await _openAndPump(tester);
    await tester.enterText(find.byType(TextField).at(0), '192.168.50.0/24');
    await tester.enterText(find.byType(TextField).at(1), '10.0.0.1');
    await tester.enterText(find.byType(TextField).at(2), 'Branch office');
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review route'), findsOneWidget);
    expect(find.text('192.168.50.0/24'), findsWidgets);
    expect(find.text('10.0.0.1'), findsWidgets);
    expect(find.text('Branch office'), findsWidgets);
  });

  testWidgets('returns the configuration on Save route', (tester) async {
    final completer = Completer<StaticRouteConfiguration?>();
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final future = showModalBottomSheet<StaticRouteConfiguration>(
      context: capturedContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const StaticRouteSheet(
        baseline: StaticRouteConfiguration(destination: '', gateway: ''),
      ),
    );
    future.then(completer.complete);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10.0.0.0/24');
    await tester.enterText(find.byType(TextField).at(1), '10.0.0.254');
    await tester.pump();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save route'));
    await tester.pumpAndSettle();
    final result = await completer.future;
    expect(result, isNotNull);
    expect(result!.destination, '10.0.0.0/24');
    expect(result.gateway, '10.0.0.254');
    expect(result.id, isNull);
  });

  testWidgets('seeds fields from the baseline when editing', (tester) async {
    await tester.pumpWidget(
      _harness(
        const StaticRouteConfiguration(
          id: 7,
          destination: '172.16.0.0/12',
          gateway: '10.0.0.1',
          description: 'Private range',
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit route'), findsOneWidget);
    expect(find.text('172.16.0.0/12'), findsOneWidget);
    expect(find.text('10.0.0.1'), findsOneWidget);
    expect(find.text('Private range'), findsOneWidget);
  });
}
