import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/apps/presentation/instance_lifecycle_controls.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('offers only start while the instance is stopped', (
    tester,
  ) async {
    await _pump(tester, running: false);

    expect(find.widgetWithText(FilledButton, 'Start'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
    expect(find.text('Restart'), findsNothing);
    expect(find.text('Force power off'), findsNothing);
  });

  testWidgets('starts without a confirmation dialog', (tester) async {
    final invoked = <InstanceVerb>[];
    await _pump(tester, running: false, onInvoke: invoked.add);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(invoked, [InstanceVerb.start]);
  });

  testWidgets('requires confirmation before stopping', (tester) async {
    final invoked = <InstanceVerb>[];
    await _pump(tester, running: true, onInvoke: invoked.add);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Stop demo-vm?'), findsOneWidget);
    expect(invoked, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(invoked, isEmpty);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pumpAndSettle();
    await tester.tap(_dialogButton('Stop'));
    await tester.pumpAndSettle();

    expect(invoked, [InstanceVerb.stop]);
  });

  testWidgets('warns about data loss before a forced power off', (
    tester,
  ) async {
    final invoked = <InstanceVerb>[];
    await _pump(tester, running: true, onInvoke: invoked.add);

    await tester.tap(find.byIcon(Icons.power_off_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('without a clean shutdown'), findsOneWidget);

    await tester.tap(_dialogButton('Force power off'));
    await tester.pumpAndSettle();

    expect(invoked, [InstanceVerb.powerOff]);
  });

  testWidgets('explains when the server exposes no lifecycle methods', (
    tester,
  ) async {
    await _pump(tester, running: true, supported: const {});

    expect(
      find.textContaining('does not expose lifecycle control'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('hides verbs the server does not support', (tester) async {
    await _pump(tester, running: true, supported: const {InstanceVerb.stop});

    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Restart'), findsNothing);
    expect(find.text('Force power off'), findsNothing);
  });
}

/// Targets the confirmation button inside the dialog, since the control
/// button behind it carries the same label.
Finder _dialogButton(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.widgetWithText(FilledButton, label),
);

Future<void> _pump(
  WidgetTester tester, {
  required bool running,
  ValueChanged<InstanceVerb>? onInvoke,
  Set<InstanceVerb> supported = const {
    InstanceVerb.start,
    InstanceVerb.stop,
    InstanceVerb.restart,
    InstanceVerb.powerOff,
  },
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InstanceLifecycleControls(
            name: 'demo-vm',
            kind: 'virtual machine',
            running: running,
            busyKey: 'vm:1',
            supportedVerbs: supported,
            onInvoke: (verb) async => onInvoke?.call(verb),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
