import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/connection/domain/server_capabilities.dart';
import 'package:true_dock/features/connection/domain/system_info.dart';
import 'package:true_dock/features/resources/data/server_resources_repository.dart';

/// Contract fixtures for the TrueNAS SCALE Community Edition release families
/// TrueDock supports.
///
/// 25.10 is the documented minimum baseline. 26.x adds the `container.*`
/// surface, which TrueDock gates rather than assuming. These fixtures pin the
/// method surface and the shapes TrueDock parses, so a change in either is
/// caught here rather than against a live server.
class ReleaseFamily {
  const ReleaseFamily({
    required this.label,
    required this.version,
    required this.methods,
  });

  final String label;
  final String version;
  final Set<String> methods;

  SystemInfo get systemInfo => SystemInfo(
    hostname: 'nas',
    version: version,
    uptime: '1 day',
    uptimeSeconds: 86400,
    physicalMemoryBytes: 8 * 1024 * 1024 * 1024,
    cpuModel: 'CPU',
    cores: 4,
  );

  ServerCapabilities get capabilities => ServerCapabilities.fromDiscovery(
    systemInfo: systemInfo,
    productType: 'COMMUNITY_EDITION',
    methods: {for (final m in methods) m: const <String, Object?>{}},
  );
}

/// Methods present in every supported family. Each is something TrueDock
/// calls, so losing one is a real capability regression.
const _baseline = <String>{
  'auth.login_ex',
  'auth.login_ex_continue',
  'auth.logout',
  'auth.me',
  'system.info',
  'system.general.config',
  'system.general.update',
  'system.reboot',
  'system.shutdown',
  'update.status',
  'update.run',
  'boot.environment.query',
  'boot.environment.activate',
  'boot.environment.keep',
  'boot.environment.destroy',
  'pool.query',
  'pool.create',
  'pool.dataset.query',
  'pool.dataset.create',
  'pool.dataset.update',
  'pool.dataset.delete',
  'pool.dataset.promote',
  'pool.snapshot.query',
  'pool.snapshot.create',
  'pool.snapshot.delete',
  'pool.snapshot.rollback',
  'pool.scrub.query',
  'pool.scrub.scrub',
  'disk.query',
  'disk.temperatures',
  'replication.query',
  'replication.create',
  'replication.update',
  'replication.delete',
  'replication.run',
  'rsynctask.query',
  'rsynctask.create',
  'rsynctask.update',
  'rsynctask.delete',
  'rsynctask.run',
  'cloudsync.query',
  'cloudsync.create',
  'cloudsync.update',
  'cloudsync.delete',
  'cloudsync.sync',
  'cloudsync.credentials.query',
  'keychaincredential.query',
  'pool.snapshottask.query',
  'sharing.smb.query',
  'sharing.nfs.query',
  'iscsi.target.query',
  'iscsi.extent.query',
  'iscsi.portal.query',
  'iscsi.initiator.query',
  'iscsi.targetextent.query',
  'iscsi.auth.query',
  'interface.query',
  'interface.update',
  'interface.commit',
  'interface.checkin',
  'interface.rollback',
  'staticroute.query',
  'staticroute.create',
  'staticroute.update',
  'staticroute.delete',
  'user.query',
  'group.query',
  'api_key.query',
  'api_key.delete',
  'service.query',
  'service.control',
  'service.update',
  'alert.list',
  'core.get_jobs',
  'core.get_methods',
  'core.job_abort',
  'system.product_type',
  'app.query',
  'app.start',
  'app.stop',
  'app.redeploy',
  'app.rollback',
  'vm.query',
  'vm.start',
  'vm.stop',
  'vm.restart',
  'vm.poweroff',
  'vm.update',
  'vm.device.create',
  'vm.device.update',
  'vm.device.delete',
  'pool.attach',
  'pool.replace',
  'pool.export',
  'pool.offline',
  'pool.online',
  'pool.dataset.rename',
  'pool.dataset.lock',
  'pool.dataset.unlock',
  'pool.snapshot.clone',
  'pool.snapshot.hold',
  'pool.snapshot.release',
  'pool.snapshottask.run',
  'pool.snapshottask.delete',
  'user.create',
  'user.update',
  'user.delete',
  'group.create',
  'group.update',
  'group.delete',
  'sharing.smb.delete',
  'sharing.nfs.delete',
  'iscsi.portal.create',
  'iscsi.portal.update',
  'iscsi.portal.delete',
  'iscsi.initiator.create',
  'iscsi.initiator.update',
  'iscsi.initiator.delete',
  'iscsi.target.create',
  'iscsi.target.update',
  'iscsi.target.delete',
  'iscsi.extent.create',
  'iscsi.extent.update',
  'iscsi.extent.delete',
  'iscsi.targetextent.create',
  'iscsi.targetextent.update',
  'iscsi.targetextent.delete',
  'iscsi.auth.create',
  'iscsi.auth.update',
  'iscsi.auth.delete',
};

/// 25.10's Instances surface. This is the API that actually exists on the
/// baseline: `virt.*` replaced the standalone-container methods, which 25.10
/// does not advertise at all. Both are pinned so the app cannot quietly start
/// depending on one while gating on the other.
const _virtMethods = <String>{
  'virt.instance.query',
  'virt.instance.start',
  'virt.instance.stop',
  'virt.instance.restart',
  'virt.instance.create',
  'virt.instance.update',
  'virt.instance.delete',
  'virt.instance.device_list',
  'virt.instance.image_choices',
  'virt.global.config',
  'virt.global.pool_choices',
  'virt.global.update',
};

/// 26+ adds standalone containers alongside the existing VM surface.
const _containerMethods = <String>{
  'container.query',
  'container.start',
  'container.stop',
  'container.restart',
  'container.update',
  'container.device_choices',
};

const _families = <ReleaseFamily>[
  ReleaseFamily(
    label: '25.10 (minimum baseline)',
    version: 'TrueNAS-SCALE-25.10.2',
    methods: {..._baseline, ..._virtMethods},
  ),
  ReleaseFamily(
    label: '26.04 (adds containers)',
    version: 'TrueNAS-SCALE-26.04.0',
    methods: {..._baseline, ..._virtMethods, ..._containerMethods},
  ),
];

class _FixtureClient extends TrueNasJsonRpcClient {
  _FixtureClient(this.responses);

  final Map<String, Object?> responses;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!responses.containsKey(method)) {
      throw TrueNasRpcException(code: -1, message: 'Method $method not found');
    }
    return responses[method];
  }
}

void main() {
  for (final family in _families) {
    group(family.label, () {
      test('is accepted by TrueDock and parses its version', () {
        final capabilities = family.capabilities;
        expect(() => capabilities.validateForTrueDock(), returnsNormally);
        // Every supported family must sit at or above the 25.10 baseline.
        expect(
          capabilities.version.compareTo(const TrueNasVersion(25, 10, 0)),
          greaterThanOrEqualTo(0),
        );
      });

      test('exposes every method TrueDock depends on', () {
        final capabilities = family.capabilities;
        for (final method in _baseline) {
          expect(
            capabilities.supports(method),
            isTrue,
            reason: '$method is missing from ${family.label}',
          );
        }
      });

      test('gates containers on the discovered surface', () {
        final capabilities = family.capabilities;
        final isContainerFamily = family.methods.contains('container.query');
        expect(capabilities.supportsContainers, isContainerFamily);
      });

      test('gates Instances separately from standalone containers', () {
        // A 25.10 server has virt.* and no container.*, so gating one on the
        // other would hide the surface that exists. That is exactly the defect
        // this pins: the app previously only knew about container.*.
        final capabilities = family.capabilities;
        expect(capabilities.supportsVirtInstances, isTrue);
        expect(
          capabilities.supportsContainers,
          family.methods.contains('container.query'),
        );
      });

      test('reads the Instances section on every supported family', () async {
        final repository = ServerResourcesRepository(
          _FixtureClient({
            for (final m in family.methods) m: const <Object?>[],
          }),
        );
        final resources = await repository.load(
          supportedMethods: family.methods,
        );
        expect(resources.virtInstances.hasError, isFalse);
      });

      test(
        'reports unavailable sections instead of failing the whole load',
        () async {
          // Simulate a server that does not expose containers: the section must
          // carry an explanation rather than aborting every other read.
          final repository = ServerResourcesRepository(
            _FixtureClient({
              for (final m in family.methods) m: const <Object?>[],
            }),
          );
          final resources = await repository.load(
            supportedMethods: family.methods,
          );

          expect(resources.pools.hasError, isFalse);
          if (!family.methods.contains('container.query')) {
            expect(resources.containers.hasError, isTrue);
            expect(
              resources.containers.errorMessage,
              contains('not available on this TrueNAS version'),
            );
          }
        },
      );
    });
  }

  group('unsupported servers', () {
    test('rejects a pre-25.10 Community Edition server', () {
      final capabilities = ServerCapabilities(
        productType: 'COMMUNITY_EDITION',
        version: const TrueNasVersion(25, 4, 2),
        methods: _baseline,
      );
      expect(
        () => capabilities.validateForTrueDock(),
        throwsA(isA<UnsupportedServerException>()),
      );
    });

    test('rejects a non-Community edition even on a supported version', () {
      final capabilities = ServerCapabilities(
        productType: 'ENTERPRISE',
        version: const TrueNasVersion(25, 10, 0),
        methods: _baseline,
      );
      expect(
        () => capabilities.validateForTrueDock(),
        throwsA(isA<UnsupportedServerException>()),
      );
    });

    test('rejects a server missing a required method', () {
      final capabilities = ServerCapabilities(
        productType: 'COMMUNITY_EDITION',
        version: const TrueNasVersion(25, 10, 0),
        methods: const {'auth.login_ex', 'system.info'},
      );
      expect(
        () => capabilities.validateForTrueDock(),
        throwsA(isA<UnsupportedServerException>()),
      );
    });
  });
}
