import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/sliding_indexed_stack.dart';

Widget _app(int index, {bool reduced = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: SlidingIndexedStack(
        index: index,
        children: const [
          ColoredBox(
            color: Colors.red,
            child: Column(children: [Text('first-a'), Text('first-b')]),
          ),
          ColoredBox(
            color: Colors.blue,
            child: Column(children: [Text('second-a'), Text('second-b')]),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('slides complete destination layers together', (tester) async {
    await tester.pumpWidget(_app(0));
    expect(find.text('first-a'), findsOneWidget);
    expect(find.text('second-a'), findsNothing);

    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('first-a'), findsOneWidget);
    expect(find.text('first-b'), findsOneWidget);
    expect(find.text('second-a'), findsOneWidget);
    expect(find.text('second-b'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SlidingIndexedStack),
        matching: find.byType(FractionalTranslation),
      ),
      findsNWidgets(2),
    );

    await tester.pumpAndSettle();
    expect(find.text('first-a'), findsNothing);
    expect(find.text('second-a'), findsOneWidget);
  });

  testWidgets('reduced animation changes destinations immediately', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0, reduced: true));
    await tester.pumpWidget(_app(1, reduced: true));
    await tester.pump();

    expect(find.text('first-a'), findsNothing);
    expect(find.text('second-a'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
