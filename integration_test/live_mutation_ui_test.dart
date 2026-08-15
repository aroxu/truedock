// Drives a real mutation through the shipped UI against a live TrueNAS server.
//
// Every other check in this repository verifies mutations one layer below the
// user: the probes in `tool/` send the app's payloads over a raw socket, and
// the widget tests drive the sheets against fakes. Neither proves the path a
// person actually takes - tap the section action, fill in the sheet, submit,
// and see the result appear in the list. A screen that never wired its button
// to the controller would pass both and fail here.
//
// Usage:
//   flutter test integration_test/live_mutation_ui_test.dart \
//     -d <deviceId> \
//     --dart-define=TRUEDOCK_HOST=10.0.0.2 \
//     --dart-define=TRUEDOCK_USER=truenas_admin \
//     --dart-define=TRUEDOCK_PASSWORD=... \
//     --dart-define=TRUEDOCK_LIVE=1
//
// MUTATING. It creates a dataset and a snapshot under an existing pool. Both
// are named with a run-specific suffix, and the test deletes them again, so a
// failed run leaves at most one clearly-labelled dataset behind.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/app/true_dock_app.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/core/api/truenas_client_provider.dart';
import 'package:true_dock/features/resources/presentation/server_resources_provider.dart';

const _live = String.fromEnvironment('TRUEDOCK_LIVE');
const _host = String.fromEnvironment('TRUEDOCK_HOST');
const _user = String.fromEnvironment('TRUEDOCK_USER');
const _password = String.fromEnvironment('TRUEDOCK_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'live mutation through the UI',
    () {
      testWidgets(
        'creates a dataset and snapshots it from the Storage screen',
        (tester) async {
          // A fixed name would collide with a previous failed run and make the
          // failure look like a bug in the app rather than leftover state.
          final suffix = DateTime.now().millisecondsSinceEpoch
              .toString()
              .substring(7);
          final datasetLeaf = 'tdui$suffix';
          final snapshotName = 'tdui-snap-$suffix';

          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const TrueDockApp(),
            ),
          );
          await _settle(tester);

          await _register(tester);

          expect(
            find.byType(NavigationBar),
            findsOneWidget,
            reason: 'expected the app shell. On screen: ${_text(tester)}',
          );

          // Storage is the second destination.
          await _tap(tester, find.byType(NavigationDestination).at(1));

          // ---- create the dataset ----------------------------------------

          final createDataset = find.widgetWithText(FilledButton, '데이터셋 생성');
          expect(
            createDataset,
            findsWidgets,
            reason: 'no dataset create action. On screen: ${_text(tester)}',
          );
          await _tap(tester, createDataset.first);

          final nameField = find.widgetWithText(TextFormField, '데이터셋 이름');
          expect(
            nameField,
            findsOneWidget,
            reason:
                'the create sheet did not open. On screen: ${_text(tester)}',
          );
          await tester.enterText(nameField, datasetLeaf);
          await _settle(tester, seconds: 1);

          // The submit button carries the same label as the section action, so
          // the sheet's own button is the last one in the tree.
          await _tap(
            tester,
            find.widgetWithText(FilledButton, '데이터셋 생성').last,
            seconds: 12,
          );

          // The dataset must exist on the server, not merely in the UI. Reading
          // it back through the app's own resource provider is what separates a
          // real mutation from an optimistic local update.
          final parent = await _expectDataset(container, datasetLeaf);
          final datasetId = '$parent/$datasetLeaf';

          expect(
            find.textContaining(datasetLeaf),
            findsWidgets,
            reason:
                'the new dataset never appeared in the list. '
                'On screen: ${_text(tester)}',
          );

          // ---- snapshot it -----------------------------------------------

          await _tap(tester, find.textContaining(datasetLeaf).first);

          final snapshotField = find.widgetWithText(TextField, '스냅샷 이름');
          expect(
            snapshotField,
            findsOneWidget,
            reason:
                'tapping the dataset did not open the snapshot sheet. '
                'On screen: ${_text(tester)}',
          );
          await tester.enterText(snapshotField, snapshotName);
          await _settle(tester, seconds: 1);
          await _tap(
            tester,
            find.widgetWithText(FilledButton, '스냅샷 생성').last,
            seconds: 12,
          );

          await _expectSnapshot(container, '$datasetId@$snapshotName');

          // ---- clean up ---------------------------------------------------

          final actions = ServerActionsRepository(
            container.read(trueNasClientProvider),
          );
          await actions.deleteSnapshot('$datasetId@$snapshotName');
          await actions.deleteDataset(datasetId, recursive: true, force: true);
        },
      );
    },
    skip: _live != '1'
        ? 'set --dart-define=TRUEDOCK_LIVE=1 with host/user/password to run'
        : null,
  );
}

/// Fills in the registration form and resolves the certificate prompt.
Future<void> _register(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(
    fields,
    findsAtLeast(4),
    reason: 'expected the registration form. On screen: ${_text(tester)}',
  );
  await tester.enterText(fields.at(0), 'Live');
  await tester.enterText(fields.at(1), _host);
  await tester.enterText(fields.at(2), _user);
  await tester.enterText(fields.at(3), _password);
  await _settle(tester);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 2);

  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    if (find.byType(NavigationBar).evaluate().isNotEmpty) return;
    final trust = find.byIcon(Icons.shield_outlined);
    if (trust.evaluate().isNotEmpty) {
      await tester.tap(trust, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }
    final connect = find.byIcon(Icons.link_rounded);
    if (connect.evaluate().isNotEmpty) {
      await tester.tap(connect, warnIfMissed: false);
      await _settle(tester, seconds: 3);
      continue;
    }
    await _settle(tester, seconds: 2);
  }
  fail('connection did not complete. On screen: ${_text(tester)}');
}

/// Polls the app's resource provider until the dataset shows up, returning its
/// parent so the caller can build the full id.
Future<String> _expectDataset(ProviderContainer container, String leaf) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = container.read(serverResourcesProvider).value;
    for (final dataset in snapshot?.datasets.items ?? const []) {
      if (dataset.name.endsWith('/$leaf')) {
        return dataset.name.substring(0, dataset.name.lastIndexOf('/'));
      }
    }
    container.invalidate(serverResourcesProvider);
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  fail('the server never reported a dataset ending in /$leaf');
}

Future<void> _expectSnapshot(ProviderContainer container, String id) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    final snapshot = container.read(serverResourcesProvider).value;
    for (final entry in snapshot?.snapshots.items ?? const []) {
      // `name` is the leaf the server returns in `snapshot_name`; the full
      // dataset@snapshot path lives in `id`.
      if (entry.id == id) return;
    }
    container.invalidate(serverResourcesProvider);
    await Future<void>.delayed(const Duration(seconds: 3));
  }
  fail('the server never reported snapshot $id');
}

String _text(WidgetTester tester) {
  final seen = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final data = (element.widget as Text).data;
    if (data != null && data.trim().isNotEmpty) seen.add(data.trim());
  }
  return seen.join(' / ');
}

Future<void> _tap(
  WidgetTester tester,
  FinderBase<Element> finder, {
  int seconds = 6,
}) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _settle(tester, seconds: 1);
  await tester.ensureVisible(finder);
  await _settle(tester, seconds: 1);
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester, seconds: seconds);
}

/// `pumpAndSettle` cannot be used: the app holds a live WebSocket and animates
/// progress while jobs run, so the tree never becomes fully idle.
Future<void> _settle(WidgetTester tester, {int seconds = 4}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}
