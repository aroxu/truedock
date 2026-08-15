import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/presentation/service_row.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/l10n/app_localizations.dart';

SystemService _service({
  String state = 'RUNNING',
  bool enabled = true,
  int id = 4,
  String name = 'smb',
}) => SystemService(id: id, name: name, state: state, enabled: enabled);

Future<void> _pump(
  WidgetTester tester, {
  required SystemService service,
  bool canEditStartOnBoot = true,
  bool busy = false,
  bool bootBusy = false,
  ValueChanged<bool>? onToggle,
  ValueChanged<bool>? onToggleStartOnBoot,
}) async {
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
        body: ServiceRow(
          service: service,
          busy: busy,
          onToggle: onToggle ?? (_) {},
          canEditStartOnBoot: canEditStartOnBoot,
          bootBusy: bootBusy,
          onToggleStartOnBoot: onToggleStartOnBoot ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the persisted boot setting, not just the run state', (
    tester,
  ) async {
    await _pump(tester, service: _service(enabled: false));

    expect(find.text('SMB'), findsOneWidget);
    expect(find.text('Manual start'), findsOneWidget);
    // Running now while not starting on boot is exactly the state the boot
    // setting exists to make visible.
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('the run switch reflects a stopped service', (tester) async {
    await _pump(tester, service: _service(state: 'STOPPED'));

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Starts automatically'), findsOneWidget);
  });

  testWidgets('toggling the switch reports the requested run state', (
    tester,
  ) async {
    final requested = <bool>[];
    await _pump(
      tester,
      service: _service(state: 'STOPPED'),
      onToggle: requested.add,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(requested, [true]);
  });

  testWidgets('offers to disable boot start for an autostarting service', (
    tester,
  ) async {
    final requested = <bool>[];
    await _pump(
      tester,
      service: _service(enabled: true),
      onToggleStartOnBoot: requested.add,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Do not start on boot'), findsOneWidget);

    await tester.tap(find.text('Do not start on boot'));
    await tester.pumpAndSettle();

    expect(requested, [false]);
  });

  testWidgets('offers to enable boot start for a manual service', (
    tester,
  ) async {
    final requested = <bool>[];
    await _pump(
      tester,
      service: _service(enabled: false),
      onToggleStartOnBoot: requested.add,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Start on boot'), findsOneWidget);

    await tester.tap(find.text('Start on boot'));
    await tester.pumpAndSettle();

    expect(requested, [true]);
  });

  testWidgets('hides the boot control when service.update is missing', (
    tester,
  ) async {
    await _pump(tester, service: _service(), canEditStartOnBoot: false);

    // The setting stays visible as information; only the mutation is gone.
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Starts automatically'), findsOneWidget);
  });

  testWidgets('an in-flight boot change replaces its own control only', (
    tester,
  ) async {
    await _pump(tester, service: _service(), bootBusy: true);

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The run switch must stay usable: the two mutations are independent.
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('an in-flight run change replaces the switch only', (
    tester,
  ) async {
    await _pump(tester, service: _service(), busy: true);

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
