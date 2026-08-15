import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/system/presentation/network_commit_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('changed address is tested before network check-in', (
    tester,
  ) async {
    final tested = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverActionsRepositoryProvider.overrideWithValue(
            ServerActionsRepository(_NetworkClient()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NetworkCommitSheet(
              serverName: 'Demo NAS',
              serverAddress: 'https://10.24.30.81',
              testChangedAddress: (address) async {
                tested.add(address);
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경 사항 커밋'));
    await tester.pumpAndSettle();

    expect(find.text('네트워크 주소를 변경하였나요?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('network-address-changed')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '체크인'))
          .onPressed,
      isNull,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).hitTestable().first,
      'https://10.24.30.82',
    );
    await tester.tap(find.byKey(const ValueKey('test-network-address')));
    await tester.pumpAndSettle();

    expect(tested, ['https://10.24.30.82']);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '체크인'))
          .onPressed,
      isNotNull,
    );
  });
}

class _NetworkClient extends TrueNasJsonRpcClient {
  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async => switch (method) {
    'interface.has_pending_changes' => true,
    'interface.checkin_waiting' => null,
    'interface.network_config_to_be_removed' => [],
    'interface.commit' => 1,
    'interface.checkin' => 2,
    _ => null,
  };
}
