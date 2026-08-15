import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/safe_refresh_indicator.dart';

void main() {
  testWidgets('places the indicator below the top safe area', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 59)),
          child: SafeRefreshIndicator(
            onRefresh: () async {},
            child: ListView(children: const [SizedBox(height: 800)]),
          ),
        ),
      ),
    );

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.edgeOffset, 59);
    expect(indicator.displacement, 99);
  });

  testWidgets('does not add an inset when a SafeArea already consumed it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 59)),
          child: SafeArea(
            child: SafeRefreshIndicator(
              onRefresh: () async {},
              child: ListView(children: const [SizedBox(height: 800)]),
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    expect(indicator.edgeOffset, 0);
    expect(indicator.displacement, 40);
  });
}
