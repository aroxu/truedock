import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/container_configuration.dart';

void main() {
  group('ContainerConfiguration.fromRawConfig', () {
    test('seeds editable fields and preserves raw device/volume/env lists', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'plex',
        'description': 'Media server',
        'dataset': 'tank/apps/plex',
        'autostart': true,
        'vcpus': 2,
        'memory': 2048,
        'devices': [
          {'type': 'NIC', 'name': 'eth0'},
        ],
        'volumes': [
          {'host': '/mnt/media', 'container': '/media'},
        ],
        'environment': {'PLEX_TOKEN': 'abc', 'TZ': 'UTC'},
      });
      expect(config.name, 'plex');
      expect(config.description, 'Media server');
      expect(config.dataset, 'tank/apps/plex');
      expect(config.autostart, isTrue);
      expect(config.vcpus, 2);
      expect(config.memoryLimitMiB, 2048);
      expect(config.devices.length, 1);
      expect(config.devices.first['name'], 'eth0');
      expect(config.volumes.length, 1);
      expect(config.environment, {'PLEX_TOKEN': 'abc', 'TZ': 'UTC'});
    });

    test('falls back to safe defaults for a sparse raw config', () {
      final config = ContainerConfiguration.fromRawConfig({'name': 'empty'});
      expect(config.name, 'empty');
      expect(config.description, isEmpty);
      expect(config.dataset, isEmpty);
      expect(config.autostart, isFalse);
      expect(config.vcpus, isNull);
      expect(config.memoryLimitMiB, isNull);
      expect(config.devices, isEmpty);
      expect(config.volumes, isEmpty);
      expect(config.environment, isEmpty);
    });
  });

  group('ContainerConfiguration.toApiJson', () {
    test('emits the full config, nulling an empty description', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'plex',
        'description': '',
        'dataset': 'tank/apps/plex',
        'autostart': true,
        'vcpus': 2,
        'memory': 2048,
        'devices': [
          {'type': 'NIC', 'name': 'eth0'},
        ],
        'volumes': [],
        'environment': {'TZ': 'UTC'},
      });
      final json = config.toApiJson();
      expect(json['name'], 'plex');
      expect(json['description'], isNull);
      expect(json['dataset'], 'tank/apps/plex');
      expect(json['autostart'], isTrue);
      expect(json['vcpus'], 2);
      expect(json['memory'], 2048);
      expect((json['devices'] as List).length, 1);
      expect(json['volumes'], isEmpty);
      expect(json['environment'], {'TZ': 'UTC'});
    });

    test('omits vcpus and memory when not set', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'nolimits',
        'dataset': 'tank/apps/x',
      });
      final json = config.toApiJson();
      expect(json.containsKey('vcpus'), isFalse);
      expect(json.containsKey('memory'), isFalse);
    });
  });

  group('validateContainerConfiguration', () {
    test('accepts a valid configuration', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'plex',
        'dataset': 'tank/apps/plex',
      });
      expect(validateContainerConfiguration(config), isEmpty);
    });

    test('rejects an empty name', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': '',
        'dataset': 'tank/apps/plex',
      });
      expect(validateContainerConfiguration(config), contains('name'));
    });

    test('rejects zero vCPUs', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'plex',
        'dataset': 'tank/apps/plex',
        'vcpus': 0,
      });
      expect(validateContainerConfiguration(config), contains('vcpus'));
    });

    test('rejects less than 16 MiB of memory', () {
      final config = ContainerConfiguration.fromRawConfig({
        'name': 'plex',
        'dataset': 'tank/apps/plex',
        'memory': 8,
      });
      expect(validateContainerConfiguration(config), contains('memory'));
    });
  });
}
