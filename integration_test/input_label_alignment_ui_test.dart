import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('form labels stay inside fields instead of floating', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          ColorScheme.fromSeed(seedColor: AppTheme.defaultSeed),
        ),
        home: Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: '공유 이름',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: 'default',
                  decoration: const InputDecoration(
                    labelText: '대기 명령 수',
                    helperText: '필요하지 않으면 서버 기본값을 사용하세요.',
                    prefixIcon: Icon(Icons.queue_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('서버 기본값')),
                  ],
                  onChanged: null,
                ),
                const SizedBox(height: 18),
                const TextField(
                  controller: null,
                  decoration: InputDecoration(
                    labelText: '공유 경로',
                    hintText: '/mnt/pool/dataset',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                const TextField(
                  decoration: InputDecoration(
                    labelText: '사용자 또는 그룹',
                    errorText: 'root에는 할당량을 설정할 수 없습니다. TrueNAS가 이 작업을 거부합니다.',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(TextField).first));
    final enabled = theme.inputDecorationTheme.enabledBorder!;
    expect(enabled, isA<OutlineInputBorder>());
    expect((enabled as OutlineInputBorder).borderSide.width, greaterThan(0));
    expect(
      theme.inputDecorationTheme.floatingLabelBehavior,
      FloatingLabelBehavior.never,
    );
    expect(theme.inputDecorationTheme.errorMaxLines, 20);
    expect(
      tester
          .getSize(find.text('root에는 할당량을 설정할 수 없습니다. TrueNAS가 이 작업을 거부합니다.'))
          .height,
      greaterThan(20),
    );
    for (final input in tester.widgetList<InputDecorator>(
      find.byType(InputDecorator),
    )) {
      expect(
        input.decoration.floatingLabelBehavior,
        FloatingLabelBehavior.never,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
