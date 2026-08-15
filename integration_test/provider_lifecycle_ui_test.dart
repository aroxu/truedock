import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/apps/presentation/instances_section.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initial server action starts after the first frame', (
    tester,
  ) async {
    final client = _LifecycleClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverActionsRepositoryProvider.overrideWithValue(
            ServerActionsRepository(client),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _WatchingHost(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(client.methods, contains('virt.global.config'));
    expect(tester.takeException(), isNull);
  });
}

class _WatchingHost extends ConsumerWidget {
  const _WatchingHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(serverActionControllerProvider);
    return const Scaffold(body: InstancesSection(instances: []));
  }
}

class _LifecycleClient extends TrueNasJsonRpcClient {
  final methods = <String>[];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    methods.add(method);
    return switch (method) {
      'virt.global.config' => {'pool': null, 'bridge': null},
      _ => null,
    };
  }
}
