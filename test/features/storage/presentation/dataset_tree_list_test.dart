import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/dataset_tree_list.dart';

Dataset _dataset(String name) =>
    Dataset(id: name, name: name, type: 'FILESYSTEM');

void main() {
  testWidgets('every dataset with children expands one level at a time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatasetTreeList(
            datasets: [
              _dataset('tank'),
              _dataset('tank/media'),
              _dataset('tank/media/photos'),
              _dataset('backup'),
            ],
            itemBuilder: (context, dataset, hasChildren, isExpanded, onToggle) {
              return ListTile(
                key: ValueKey(dataset.id),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasChildren)
                      Icon(
                        isExpanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                      ),
                    const Icon(Icons.folder_outlined),
                  ],
                ),
                title: Text(dataset.leafName),
                onTap: onToggle,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('tank'), findsOneWidget);
    expect(find.text('backup'), findsOneWidget);
    expect(find.text('media'), findsNothing);
    expect(find.text('photos'), findsNothing);

    await tester.tap(find.text('tank'));
    await tester.pumpAndSettle();
    expect(find.text('media'), findsOneWidget);
    expect(find.text('photos'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tank/media')),
        matching: find.byIcon(Icons.folder_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tank/media')),
        matching: find.byIcon(Icons.chevron_right_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('media'));
    await tester.pumpAndSettle();
    expect(find.text('photos'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('tank/media')),
        matching: find.byIcon(Icons.expand_more_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('media'));
    await tester.pumpAndSettle();
    expect(find.text('photos'), findsNothing);

    await tester.tap(find.text('tank'));
    await tester.pumpAndSettle();
    expect(find.text('media'), findsNothing);
    expect(find.text('photos'), findsNothing);
  });
}
