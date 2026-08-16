import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the connected adaptive shell is currently visible.
bool adaptiveShellIsVisible() =>
    find.byType(NavigationBar).evaluate().isNotEmpty ||
    find.byType(NavigationRail).evaluate().isNotEmpty;

/// Finds the destination at [index] for either compact or tablet navigation.
Finder adaptiveDestinationAt(int index) {
  if (find.byType(NavigationRail).evaluate().isNotEmpty) {
    return find.byType(NavigationRailDestination).at(index);
  }
  return find.byType(NavigationDestination).at(index);
}

/// Number of destinations exposed by the currently visible adaptive shell.
int adaptiveDestinationCount(WidgetTester tester) {
  final rail = find.byType(NavigationRail);
  if (rail.evaluate().isNotEmpty) {
    return tester.widget<NavigationRail>(rail).destinations.length;
  }
  return tester
      .widget<NavigationBar>(find.byType(NavigationBar))
      .destinations
      .length;
}

/// Human-readable destination label for diagnostics.
String adaptiveDestinationLabel(WidgetTester tester, int index) {
  final rail = find.byType(NavigationRail);
  if (rail.evaluate().isNotEmpty) {
    final destination = tester.widget<NavigationRail>(rail).destinations[index];
    return (destination.label as Text).data ?? 'destination $index';
  }
  final destination =
      tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .destinations[index]
          as NavigationDestination;
  return destination.label;
}
