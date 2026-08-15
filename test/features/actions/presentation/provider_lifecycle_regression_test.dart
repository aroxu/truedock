import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/apps/presentation/instance_sheets.dart';
import 'package:true_dock/features/apps/presentation/instances_section.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/presentation/network_commit_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  testWidgets('initial action loads wait until after the first frame', (
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
          home: _WatchingHost(child: InstancesSection(instances: [])),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(client.methods, contains('virt.global.config'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('details and network sheets also defer their initial reads', (
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
          home: _WatchingHost(
            child: Column(
              children: [
                Expanded(child: InstanceDetailsSheet(instance: _instance)),
                Expanded(
                  child: NetworkCommitSheet(
                    serverName: 'nas',
                    serverAddress: 'https://nas.local',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(client.methods, contains('virt.instance.device_list'));
    expect(client.methods, contains('interface.has_pending_changes'));
    expect(tester.takeException(), isNull);
  });
}

class _WatchingHost extends ConsumerWidget {
  const _WatchingHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(serverActionControllerProvider);
    return Scaffold(body: child);
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
      'virt.instance.device_list' => <Object?>[],
      'interface.has_pending_changes' => false,
      'interface.checkin_waiting' => null,
      'interface.network_config_to_be_removed' => <Object?>[],
      _ => null,
    };
  }
}

const _instance = VirtInstance(
  id: 'web',
  name: 'web',
  type: 'CONTAINER',
  status: 'STOPPED',
  autostart: false,
  privileged: false,
  vncEnabled: false,
);
