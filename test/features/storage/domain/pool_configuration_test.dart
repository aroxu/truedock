import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';

void main() {
  group('VdevType', () {
    test('exposes fault tolerance and warning per layout', () {
      expect(VdevType.stripe.faultTolerance, 0);
      expect(VdevType.mirror.faultTolerance, 1);
      expect(VdevType.raidz2.faultTolerance, 2);
      expect(VdevType.raidz3.faultTolerance, 3);
      expect(VdevType.stripe.warning, contains('No redundancy'));
    });
    test('fromApi falls back to stripe', () {
      expect(VdevType.fromApi('UNKNOWN'), VdevType.stripe);
      expect(VdevType.fromApi('MIRROR'), VdevType.mirror);
    });
  });

  group('VdevSpec.toApiJson', () {
    // The 25.10 schema requires `disks` and rejects `devices`; verified
    // against a live server by tool/live_mutation_probe.dart.
    test('emits type and disks', () {
      const vdev = VdevSpec(
        type: VdevType.raidz1,
        disks: ['sda', 'sdb', 'sdc'],
      );
      expect(vdev.toApiJson(), {
        'type': 'RAIDZ1',
        'disks': ['sda', 'sdb', 'sdc'],
      });
    });
  });

  group('PoolConfiguration.toApiJson', () {
    test('emits name, topology, and options', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
        ],
        cacheVdevs: const [
          VdevSpec(type: VdevType.stripe, disks: ['sdc']),
        ],
        encryption: true,
        dedup: true,
        autoTrim: false,
      );
      final json = config.toApiJson();
      expect(json['name'], 'tank');
      final topology = json['topology'] as Map<String, dynamic>;
      expect(topology.containsKey('data'), isTrue);
      expect(topology.containsKey('cache'), isTrue);
      expect(topology['spares'], isNull);
      expect(json['encryption'], isTrue);
      expect(json['encryption_options'], {'algorithm': 'AES-256-GCM'});
      expect(json['deduplication'], 'ON');
      // autotrim lives on pool.update, not pool.create, so it must not appear
      // in this payload.
      expect(json.containsKey('enable_auto_trim'), isFalse);
      expect(json.containsKey('autotrim'), isFalse);
    });

    test('omits empty categories and disables encryption by default', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.stripe, disks: ['sda']),
        ],
      );
      final json = config.toApiJson();
      final topology = json['topology'] as Map<String, dynamic>;
      expect(topology.keys, ['data']);
      expect(json['encryption'], isFalse);
      // Omitted rather than null: the schema rejects null for this field.
      expect(json.containsKey('encryption_options'), isFalse);
      // Omitted so the server keeps its own dedup default.
      expect(json.containsKey('deduplication'), isFalse);
    });
  });

  group('PoolConfiguration.usedDisks', () {
    test('collects disks across categories', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.stripe, disks: ['sda', 'sdb']),
        ],
        cacheVdevs: const [
          VdevSpec(type: VdevType.stripe, disks: ['sdc']),
        ],
      );
      expect(config.usedDisks, {'sda', 'sdb', 'sdc'});
    });
  });

  group('validatePoolConfiguration', () {
    test('accepts a valid mirror pool', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
        ],
      );
      expect(validatePoolConfiguration(config), isEmpty);
    });

    test('rejects an empty name', () {
      final config = PoolConfiguration(
        name: '',
        dataVdevs: const [
          VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
        ],
      );
      expect(validatePoolConfiguration(config), contains('name'));
    });

    test('rejects a name starting with a number', () {
      final config = PoolConfiguration(
        name: '1tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
        ],
      );
      expect(validatePoolConfiguration(config), contains('name'));
    });

    test('rejects no data vdevs', () {
      const config = PoolConfiguration(name: 'tank', dataVdevs: []);
      expect(validatePoolConfiguration(config), contains('data'));
    });

    test('rejects a mirror with fewer than 2 disks', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.mirror, disks: ['sda']),
        ],
      );
      expect(validatePoolConfiguration(config), contains('data'));
    });

    test('rejects RAIDZ2 with fewer than 3 disks', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.raidz2, disks: ['sda', 'sdb']),
        ],
      );
      expect(validatePoolConfiguration(config), contains('data'));
    });

    test('exposes typed issue details for localized presentation', () {
      final config = PoolConfiguration(
        name: 'tank',
        dataVdevs: const [
          VdevSpec(type: VdevType.raidz3, disks: ['sda', 'sdb']),
        ],
      );

      final issue = poolConfigurationIssues(config).single;
      expect(issue.code, PoolValidationCode.dataVdevMinimumDisks);
      expect(issue.field, 'data');
      expect(issue.vdevIndex, 0);
      expect(issue.vdevType, VdevType.raidz3);
      expect(issue.minimumDisks, 4);
      expect(issue.message, 'RAIDZ3 vdev 1 needs at least 4 disks.');
    });
  });
}
