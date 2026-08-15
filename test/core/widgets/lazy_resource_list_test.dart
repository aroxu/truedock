import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/lazy_resource_list.dart';

/// The point of this widget is a number, so the tests assert the number.
///
/// Frame timings cannot be measured meaningfully on a simulator - they would
/// report the host Mac's speed - but how many rows get built is the same in
/// every build mode and on every device, and it is the quantity that causes
/// jank in the first place.
Widget _host({required int rows, double indent = 0}) => MaterialApp(
  home: Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverLazyResourceList(
          itemCount: rows,
          dividerIndent: indent,
          itemBuilder: (context, index) => ListTile(title: Text('row $index')),
        ),
      ],
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('builds only what fits, not the whole list', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(rows: 500));

    final built = find.byType(ListTile).evaluate().length;
    // A screenful plus the viewport's cache extent. The precise number depends
    // on row height, so this asserts the property rather than a magic value:
    // it must be a small fraction of the list.
    expect(
      built,
      lessThan(60),
      reason: 'a 500-row list built $built rows; laziness is not working',
    );
    expect(built, greaterThan(0));
  });

  testWidgets('the build count does not grow with the list', (tester) async {
    // The regression that matters. An eager list builds 100 rows for 100 items
    // and 500 for 500; a lazy one builds the same handful either way.
    _phone(tester);

    await tester.pumpWidget(_host(rows: 100));
    final small = find.byType(ListTile).evaluate().length;

    await tester.pumpWidget(_host(rows: 1000));
    final large = find.byType(ListTile).evaluate().length;

    expect(
      large,
      small,
      reason:
          'building $small rows for 100 items but $large for 1000 means the '
          'list is still eager',
    );
  });

  testWidgets('scrolling reaches rows far past the first screen', (
    tester,
  ) async {
    // Laziness is only correct if the rest of the list is still reachable.
    _phone(tester);
    await tester.pumpWidget(_host(rows: 500));
    expect(find.text('row 400'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('row 400'),
      600,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('row 400'), findsOneWidget);
  });

  testWidgets('draws dividers between rows but not at the ends', (
    tester,
  ) async {
    // The card look has to survive the change, or this trades jank for a
    // visual regression.
    _phone(tester);
    await tester.pumpWidget(_host(rows: 3));

    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('an empty list renders nothing at all', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(rows: 0));

    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('a single row has no divider', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_host(rows: 1));

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });
}
