import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_tile.dart';
import 'package:true_dock/features/storage/presentation/dataset_tree_list.dart';
import 'package:true_dock/l10n/app_localizations.dart';

Dataset _dataset(String name) => Dataset(
  id: name,
  name: name,
  type: 'FILESYSTEM',
  usedBytes: 96 * 1024,
  availableBytes: 27 * 1024 * 1024 * 1024,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dataset hierarchy expands on iPhone without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: DatasetTreeList(
              datasets: [
                _dataset('truedock_data'),
                _dataset('truedock_data/media'),
                _dataset('truedock_data/media/photos'),
                _dataset('truedock_probe_pool'),
              ],
              itemBuilder:
                  (context, dataset, hasChildren, isExpanded, onToggle) =>
                      DatasetTile(
                        dataset: dataset,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onToggle: onToggle,
                        onCreateSnapshot: () {},
                        canEdit: false,
                        canRename: false,
                        onEdit: () {},
                        onRename: () {},
                        canDelete: false,
                        onDelete: () {},
                        canLock: false,
                        onLock: () {},
                        onUnlock: () {},
                        canPromote: false,
                        onPromote: () {},
                        canManageQuotas: false,
                        onManageQuotas: () {},
                        canManageAcl: false,
                        onManageAcl: () {},
                      ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('media'), findsNothing);
    expect(find.text('photos'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('truedock_data'));
    await tester.pump(const Duration(milliseconds: 100));
    final rootRotation = tester.widget<AnimatedRotation>(
      find.byKey(const ValueKey('dataset-expansion-truedock_data')),
    );
    expect(rootRotation.turns, .25);
    await tester.pumpAndSettle();
    expect(find.text('media'), findsOneWidget);
    expect(find.text('photos'), findsOneWidget);

    await tester.tap(find.text('media'));
    await tester.pumpAndSettle();
    expect(find.text('photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
