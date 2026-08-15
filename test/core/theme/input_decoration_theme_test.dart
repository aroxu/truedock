import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/theme/app_theme.dart';

void main() {
  testWidgets('filled fields never float labels above their outline', (
    tester,
  ) async {
    final theme = AppTheme.build(
      ColorScheme.fromSeed(seedColor: AppTheme.defaultSeed),
    );
    final controller = TextEditingController(text: 'Server default');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Queued commands',
                helperText: 'Use the server default unless tuning is needed.',
                prefixIcon: Icon(Icons.queue_rounded),
              ),
            ),
          ),
        ),
      ),
    );

    final decoration = theme.inputDecorationTheme;
    expect(decoration.floatingLabelBehavior, FloatingLabelBehavior.never);
    expect(decoration.errorMaxLines, 20);
    expect(decoration.helperMaxLines, 10);
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.style,
      BorderStyle.solid,
    );
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.width,
      greaterThan(0),
    );
    final inputDecorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(
      inputDecorator.decoration.floatingLabelBehavior,
      FloatingLabelBehavior.never,
    );
    // Flutter keeps the label widget mounted for semantics and animation even
    // when the theme prevents it from floating visually.
    expect(find.text('Queued commands'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long validation text wraps instead of using an ellipsis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const error = 'root에는 할당량을 설정할 수 없습니다. TrueNAS가 이 작업을 거부합니다.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          ColorScheme.fromSeed(seedColor: AppTheme.defaultSeed),
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: '사용자 또는 그룹',
                errorText: error,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final errorText = tester.widget<Text>(find.text(error));
    expect(errorText.maxLines, 20);
    expect(errorText.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.text(error)).height, greaterThan(20));
    expect(tester.takeException(), isNull);
  });
}
