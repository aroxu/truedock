import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/system/domain/system_general_configuration.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('general settings use their TrueNAS 25.10 API owners', (
    tester,
  ) async {
    final client = _RoutingClient();
    final baseline = SystemGeneralConfiguration.fromConfig({
      'hostname': 'nas01',
      'description': 'Lab',
      'timezone': 'UTC',
      'sysloglevel': 'INFO',
    });

    await ServerActionsRepository(client).updateSystemGeneralConfig(
      baseline: baseline,
      next: baseline.copyWith(
        hostname: 'nas02',
        timezone: 'Asia/Seoul',
        syslogLevel: SystemSyslogLevel.warning,
      ),
    );

    expect(client.calls, {
      'network.configuration.update': [
        {'hostname': 'nas02'},
      ],
      'system.general.update': [
        {'timezone': 'Asia/Seoul'},
      ],
      'system.advanced.update': [
        {'sysloglevel': 'WARNING'},
      ],
    });
  });
}

class _RoutingClient extends TrueNasJsonRpcClient {
  final calls = <String, List<Object?>>{};

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls[method] = params;
    return null;
  }
}
