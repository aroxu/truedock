import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/system_info.dart';

void main() {
  const info = SystemInfo(
    hostname: 'nas',
    version: 'TrueNAS-SCALE-25.10.2',
    uptime: '1 day',
    uptimeSeconds: 86400,
    physicalMemoryBytes: 1024,
    cpuModel: 'CPU',
    cores: 4,
  );

  test('accepts Community Edition 25.10 with required methods', () {
    final capabilities = ServerCapabilities.fromDiscovery(
      systemInfo: info,
      productType: 'COMMUNITY_EDITION',
      methods: {
        'auth.login_ex': const {},
        'system.info': const {},
        'pool.query': const {},
        'vm.query': const {},
      },
    );

    expect(() => capabilities.validateForTrueDock(), returnsNormally);
    expect(capabilities.version, const TrueNasVersion(25, 10, 2));
    expect(capabilities.supports('vm.query'), isTrue);
  });

  test('rejects Enterprise and pre-25.10 systems', () {
    final enterprise = ServerCapabilities(
      productType: 'ENTERPRISE',
      version: const TrueNasVersion(25, 10, 0),
      methods: const {'auth.login_ex', 'system.info', 'pool.query'},
    );
    final old = ServerCapabilities(
      productType: 'COMMUNITY_EDITION',
      version: const TrueNasVersion(25, 4, 2),
      methods: const {'auth.login_ex', 'system.info', 'pool.query'},
    );

    expect(
      enterprise.validateForTrueDock,
      throwsA(isA<UnsupportedServerException>()),
    );
    expect(old.validateForTrueDock, throwsA(isA<UnsupportedServerException>()));
  });

  test('gates 26+ container features using discovered methods', () {
    final capabilities = ServerCapabilities(
      productType: 'COMMUNITY_EDITION',
      version: const TrueNasVersion(26, 0, 0),
      methods: const {'container.query', 'container.start'},
    );

    expect(capabilities.supportsContainers, isTrue);
  });
}
