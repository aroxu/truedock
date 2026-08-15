import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/create_dataset_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Records the last request so the payload the sheet builds can be asserted.
class _RecordingClient extends TrueNasJsonRpcClient {
  String? method;
  Map<Object?, Object?>? payload;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    this.method = method;
    if (params.isNotEmpty && params.first is Map<Object?, Object?>) {
      payload = params.first as Map<Object?, Object?>;
    }
    return {'id': 'tank/created'};
  }
}

final _pools = [const StoragePool(id: 1, name: 'tank', status: 'ONLINE')];

Future<_RecordingClient> _openSheet(WidgetTester tester) async {
  final client = _RecordingClient();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverActionsRepositoryProvider.overrideWithValue(
          ServerActionsRepository(client),
        ),
      ],
      child: MaterialApp(
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
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    CreateDatasetSheet(pools: _pools, datasets: const []),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return client;
}

Future<void> _selectVolume(WidgetTester tester) async {
  await tester.tap(find.text('Volume'));
  await tester.pumpAndSettle();
}

/// Taps the sheet's submit button.
///
/// The volume form is taller than the default test viewport, so the button has
/// to be scrolled into view before it can receive the tap.
Future<void> _submit(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('defaults to a filesystem with workload optimization', (
    tester,
  ) async {
    await _openSheet(tester);

    expect(find.text('Create dataset'), findsWidgets);
    expect(find.text('Workload optimization'), findsOneWidget);
    // Size belongs to a volume only.
    expect(find.text('Size in GiB'), findsNothing);
  });

  testWidgets('choosing volume swaps workload options for a size', (
    tester,
  ) async {
    await _openSheet(tester);
    await _selectVolume(tester);

    expect(find.text('Size in GiB'), findsOneWidget);
    expect(find.text('Sparse (thin provision)'), findsOneWidget);
    // Sending share_type with a VOLUME is rejected by the server, so the
    // control must not even be reachable.
    expect(find.text('Workload optimization'), findsNothing);
  });

  testWidgets('the volume label replaces the dataset wording', (tester) async {
    await _openSheet(tester);
    await _selectVolume(tester);

    expect(find.text('Create volume'), findsWidgets);
    expect(find.text('Volume name'), findsOneWidget);
    expect(find.textContaining('block device'), findsOneWidget);
  });

  testWidgets('a filesystem sends the share type and no size', (tester) async {
    final client = await _openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'media');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create dataset');

    expect(client.method, 'pool.dataset.create');
    expect(client.payload?['type'], 'FILESYSTEM');
    expect(client.payload?['name'], 'tank/media');
    expect(client.payload?['share_type'], 'GENERIC');
    expect(client.payload?.containsKey('volsize'), isFalse);
  });

  testWidgets('a volume sends volsize in bytes, converted from GiB', (
    tester,
  ) async {
    final client = await _openSheet(tester);
    await _selectVolume(tester);

    await tester.enterText(find.byType(TextFormField).first, 'block');
    await tester.enterText(find.byType(TextFormField).last, '10');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create volume');

    expect(client.method, 'pool.dataset.create');
    expect(client.payload?['type'], 'VOLUME');
    // The field is GiB because a byte count is unusable on a phone keyboard.
    expect(client.payload?['volsize'], 10 * 1024 * 1024 * 1024);
    expect(client.payload?['sparse'], isFalse);
    expect(client.payload?.containsKey('share_type'), isFalse);
  });

  testWidgets('sparse provisioning is opt-in and reaches the payload', (
    tester,
  ) async {
    final client = await _openSheet(tester);
    await _selectVolume(tester);

    await tester.enterText(find.byType(TextFormField).first, 'thin');
    await tester.enterText(find.byType(TextFormField).last, '2');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await _submit(tester, 'Create volume');

    expect(client.payload?['sparse'], isTrue);
  });

  testWidgets('a volume without a size is rejected before any request', (
    tester,
  ) async {
    final client = await _openSheet(tester);
    await _selectVolume(tester);

    await tester.enterText(find.byType(TextFormField).first, 'block');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create volume');

    expect(find.text('Enter a size in GiB.'), findsOneWidget);
    expect(client.method, isNull);
  });

  testWidgets('a zero size is rejected', (tester) async {
    final client = await _openSheet(tester);
    await _selectVolume(tester);

    await tester.enterText(find.byType(TextFormField).first, 'block');
    await tester.enterText(find.byType(TextFormField).last, '0');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create volume');

    expect(find.text('Enter a size greater than zero.'), findsOneWidget);
    expect(client.method, isNull);
  });

  testWidgets('a missing name is rejected with the volume wording', (
    tester,
  ) async {
    final client = await _openSheet(tester);
    await _selectVolume(tester);

    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create volume');

    expect(find.text('Enter a volume name.'), findsOneWidget);
    expect(client.method, isNull);
  });

  testWidgets('a name containing a path separator is rejected', (tester) async {
    final client = await _openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'media/photos');
    await tester.pumpAndSettle();
    await _submit(tester, 'Create dataset');

    expect(find.text('Use the Parent field for paths.'), findsOneWidget);
    expect(client.method, isNull);
  });
}
