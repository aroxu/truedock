import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/app_stats.dart';

void main() {
  test('parses app stats notification fields', () {
    final stats = appStatsFromNotification({
      'collection': 'app.stats:{"interval":2}',
      'fields': [
        {
          'app_name': 'immich',
          'cpu_usage': 12.5,
          'memory': 1073741824,
          'networks': [
            {'interface_name': 'eth0', 'rx_bytes': 1200, 'tx_bytes': 800},
          ],
          'blkio': {'read': 4096, 'write': 8192},
        },
      ],
    }).single;

    expect(stats.appName, 'immich');
    expect(stats.cpuUsage, 12.5);
    expect(stats.memoryBytes, 1073741824);
    expect(stats.networks.single.interfaceName, 'eth0');
    expect(stats.blockWriteBytes, 8192);
  });
}
