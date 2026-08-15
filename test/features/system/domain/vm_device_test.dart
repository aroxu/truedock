import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/vm_device.dart';

void main() {
  group('VmDevice.fromJson', () {
    test('parses a disk device with nested attributes', () {
      final device = VmDevice.fromJson({
        'id': 7,
        'vm': 1,
        'dtype': 'DISK',
        'attributes': {'path': '/dev/zvol/tank/vm', 'size': 21474836480},
      });
      expect(device.id, 7);
      expect(device.vmId, 1);
      expect(device.type, VmDeviceType.disk);
      expect(device.attributes['path'], '/dev/zvol/tank/vm');
      expect(device.summary, '/dev/zvol/tank/vm · 20.0 GiB');
    });

    test('parses a NIC device with a MAC', () {
      final device = VmDevice.fromJson({
        'id': 8,
        'vm': 1,
        'dtype': 'NIC',
        'attributes': {'mac': '52:54:00:aa:bb:cc'},
      });
      expect(device.type, VmDeviceType.nic);
      expect(device.summary, 'NIC · 52:54:00:aa:bb:cc');
    });

    test('parses a display device', () {
      final device = VmDevice.fromJson({
        'id': 9,
        'vm': 1,
        'dtype': 'DISPLAY',
        'attributes': {'mode': 'VNC'},
      });
      expect(device.type, VmDeviceType.display);
      expect(device.summary, 'Display · VNC');
    });

    test('falls back to OTHER for an unknown dtype', () {
      final device = VmDevice.fromJson({'id': 10, 'vm': 1, 'dtype': 'WIDGET'});
      expect(device.type, VmDeviceType.other);
    });

    test('accepts a flattened shape without an attributes sub-map', () {
      final device = VmDevice.fromJson({
        'id': 11,
        'vm': 1,
        'dtype': 'CDROM',
        'path': '/iso/install.iso',
      });
      expect(device.type, VmDeviceType.cdrom);
      expect(device.attributes['path'], '/iso/install.iso');
      expect(device.attributes.containsKey('id'), isFalse);
    });
  });

  group('VmDeviceConfiguration', () {
    test('toCreateApiJson includes vm id and dtype', () {
      const configuration = VmDeviceConfiguration(
        dtype: VmDeviceType.disk,
        attributes: {'path': '/dev/zvol/tank/vm', 'size': 10240},
      );
      expect(configuration.toCreateApiJson(1), {
        'vm': 1,
        'dtype': 'DISK',
        'path': '/dev/zvol/tank/vm',
        'size': 10240,
      });
    });

    test('toUpdateApiJson omits vm id', () {
      const configuration = VmDeviceConfiguration(
        dtype: VmDeviceType.nic,
        attributes: {'mac': '52:54:00:aa:bb:cc'},
      );
      expect(configuration.toUpdateApiJson(), {
        'dtype': 'NIC',
        'mac': '52:54:00:aa:bb:cc',
      });
    });
  });
}
