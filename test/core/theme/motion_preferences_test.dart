import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/core/theme/app_motion.dart';
import 'package:true_dock/core/theme/theme_controller.dart';

class _MotionProbe extends StatelessWidget {
  const _MotionProbe();

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: 1,
    duration: context.motionDuration(AppMotion.standard),
    child: const Text('probe'),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reduced animation preference persists across controllers', () async {
    final first = ThemeController(initialSource: ThemeSource.brand);
    await first.load();
    await first.setReduceAnimations(true);
    expect(first.state.reduceAnimations, isTrue);
    first.dispose();

    final restored = ThemeController(initialSource: ThemeSource.brand);
    await restored.load();
    expect(restored.state.reduceAnimations, isTrue);
    restored.dispose();
  });

  testWidgets('micro motion uses shared Material duration when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _MotionProbe())),
    );

    expect(
      tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .first
          .duration,
      AppMotion.standard,
    );
  });

  testWidgets('system or app reduced motion makes custom transitions instant', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(body: _MotionProbe()),
          ),
        ),
      ),
    );

    for (final opacity in tester.widgetList<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    )) {
      expect(opacity.duration, Duration.zero);
    }
  });
}
