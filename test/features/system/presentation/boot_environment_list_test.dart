import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/boot_environment_list.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:true_dock/core/domain/data_message.dart';

BootEnvironment _environment({
  required String id,
  bool active = false,
  bool activated = false,
  bool keep = false,
}) => BootEnvironment(id: id, active: active, activated: activated, keep: keep);

Future<
  ({List<String> activated, List<(String, bool)> kept, List<String> destroyed})
>
_pump(
  WidgetTester tester, {
  required ResourceSection<BootEnvironment> section,
  bool canActivate = true,
  bool canKeep = true,
  bool canDestroy = true,
  Set<String> busyIds = const {},
}) async {
  final activated = <String>[];
  final kept = <(String, bool)>[];
  final destroyed = <String>[];
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
        body: SingleChildScrollView(
          child: BootEnvironmentList(
            section: section,
            canActivate: canActivate,
            canKeep: canKeep,
            canDestroy: canDestroy,
            busyIds: busyIds,
            onActivate: (environment) => activated.add(environment.id),
            onSetKept: (environment, keep) => kept.add((environment.id, keep)),
            onDestroy: (environment) => destroyed.add(environment.id),
          ),
        ),
      ),
    ),
  );
  return (activated: activated, kept: kept, destroyed: destroyed);
}

void main() {
  testWidgets('separates the running environment from the next boot', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
    );

    expect(find.textContaining('Running now'), findsOneWidget);
    // Nothing is queued, so no pending-activation banner.
    expect(find.textContaining('the next time it restarts'), findsNothing);
  });

  testWidgets('warns when a different environment is queued for next boot', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true),
          _environment(id: 'rollback-target', activated: true),
        ],
      ),
    );

    // The server is not running what it will run after a reboot; that gap is
    // the whole reason this surface exists.
    expect(
      find.textContaining('will boot into rollback-target'),
      findsOneWidget,
    );
    expect(find.textContaining('Replaced at next boot'), findsOneWidget);
    expect(find.textContaining('Next boot'), findsWidgets);
  });

  testWidgets('offers activation only for environments not already selected', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
    );

    expect(find.text('Use at next boot'), findsOneWidget);
  });

  testWidgets('activating reports the chosen environment', (tester) async {
    final calls = await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
    );

    await tester.tap(find.text('Use at next boot'));
    await tester.pumpAndSettle();

    expect(calls.activated, ['previous']);
  });

  testWidgets('never offers to delete the running environment', (tester) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [_environment(id: 'current', active: true, activated: true)],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Destroying it would break the server's ability to boot.
    expect(find.text('Delete environment'), findsNothing);
    expect(find.text('Keep this environment'), findsOneWidget);
  });

  testWidgets('never offers to delete the next-boot environment', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true),
          _environment(id: 'queued', activated: true),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    expect(find.text('Delete environment'), findsNothing);
  });

  testWidgets('deletes an idle environment through the menu', (tester) async {
    final calls = await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete environment'));
    await tester.pumpAndSettle();

    expect(calls.destroyed, ['previous']);
  });

  testWidgets('toggles the keep flag in the direction it is not already in', (
    tester,
  ) async {
    final calls = await _pump(
      tester,
      section: ResourceSection(items: [_environment(id: 'pinned', keep: true)]),
    );

    expect(find.textContaining('Kept'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow automatic removal'));
    await tester.pumpAndSettle();

    expect(calls.kept, [('pinned', false)]);
  });

  testWidgets('hides every mutation the server does not expose', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
      canActivate: false,
      canKeep: false,
      canDestroy: false,
    );

    expect(find.text('Use at next boot'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    // The inventory itself stays readable.
    expect(find.text('current'), findsOneWidget);
    expect(find.text('previous'), findsOneWidget);
  });

  testWidgets('an in-flight change replaces that row\'s controls', (
    tester,
  ) async {
    await _pump(
      tester,
      section: ResourceSection(
        items: [
          _environment(id: 'current', active: true, activated: true),
          _environment(id: 'previous'),
        ],
      ),
      busyIds: const {'previous'},
    );

    expect(find.text('Use at next boot'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The other row keeps its menu.
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('surfaces a permission error instead of an empty list', (
    tester,
  ) async {
    await _pump(
      tester,
      section: const ResourceSection(error: DataMessage.raw('Not authorized')),
    );

    expect(find.text('Not authorized'), findsOneWidget);
  });

  testWidgets('explains an empty inventory', (tester) async {
    await _pump(tester, section: const ResourceSection());

    expect(find.text('No boot environments were reported.'), findsOneWidget);
  });
}
