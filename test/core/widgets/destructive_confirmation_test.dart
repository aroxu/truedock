import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/destructive_confirmation.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('names the server and target and lists consequences', (
    tester,
  ) async {
    await _open(tester, impact: MutationImpact.high);

    expect(find.text('nas.example.invalid'), findsOneWidget);
    expect(find.text('tank/projects'), findsOneWidget);
    expect(find.text('Shares stop serving this path'), findsOneWidget);
  });

  testWidgets('a high-impact action confirms without typing', (tester) async {
    bool? result;
    await _open(
      tester,
      impact: MutationImpact.high,
      onResult: (value) => result = value,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('a critical action stays disabled until the name matches', (
    tester,
  ) async {
    bool? result;
    await _open(
      tester,
      impact: MutationImpact.critical,
      onResult: (value) => result = value,
    );

    expect(find.textContaining('This cannot be undone'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'tank/wrong');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'tank/projects');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('cancelling reports a declined action', (tester) async {
    bool? result;
    await _open(
      tester,
      impact: MutationImpact.critical,
      onResult: (value) => result = value,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('dismissing the sheet does not confirm', (tester) async {
    bool? result;
    await _open(
      tester,
      impact: MutationImpact.high,
      onResult: (value) => result = value,
    );

    // Tapping the scrim dismisses the modal without a decision.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}

Future<void> _open(
  WidgetTester tester, {
  required MutationImpact impact,
  ValueChanged<bool>? onResult,
}) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          builder: (context) => TextButton(
            onPressed: () async {
              final confirmed = await confirmDestructiveAction(
                context,
                title: 'Delete dataset?',
                server: 'nas.example.invalid',
                target: 'tank/projects',
                actionLabel: 'Delete',
                impact: impact,
                consequences: const [
                  ImpactDetail(
                    icon: Icons.delete_forever_rounded,
                    text: 'All data in the dataset is destroyed',
                  ),
                  ImpactDetail(
                    icon: Icons.folder_off_outlined,
                    text: 'Shares stop serving this path',
                  ),
                ],
              );
              onResult?.call(confirmed);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
