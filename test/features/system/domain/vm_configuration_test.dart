import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/vm_configuration.dart';

VirtualMachine _vm({
  String name = 'media',
  int vcpus = 2,
  int cores = 2,
  int threads = 1,
  int memoryMiB = 4096,
  bool autostart = true,
}) => VirtualMachine.fromJson({
  'id': 1,
  'name': name,
  'status': {'state': 'STOPPED'},
  'vcpus': vcpus,
  'cores': cores,
  'threads': threads,
  'memory': memoryMiB,
  'autostart': autostart,
});

void main() {
  group('VmConfiguration.fromVm', () {
    test('seeds the editable fields from the resource model', () {
      final config = VmConfiguration.fromVm(_vm());
      expect(config.name, 'media');
      expect(config.vcpus, 2);
      expect(config.cores, 2);
      expect(config.threads, 1);
      expect(config.memoryMiB, 4096);
      expect(config.autostart, isTrue);
      expect(config.minMemoryMiB, isNull);
      expect(config.bootloader, VmBootloader.uefi);
      expect(config.cpuMode, VmCpuMode.hostModel);
      expect(config.guestTime, VmGuestTime.local);
      expect(config.shutdownTimeoutSeconds, 90);
    });
  });

  group('VmConfiguration.changedFields', () {
    test('emits only the changed fields', () {
      final baseline = VmConfiguration.fromVm(_vm());
      final next = baseline.copyWith(
        vcpus: 4,
        memoryMiB: 8192,
        autostart: false,
      );
      final diff = next.changedFields(baseline);
      expect(diff, {'vcpus': 4, 'memory': 8192, 'autostart': false});
    });

    test('emits nothing when nothing changed', () {
      final baseline = VmConfiguration.fromVm(_vm());
      expect(baseline.changedFields(baseline), isEmpty);
    });

    test('emits bootloader and cpu mode by their API names', () {
      final baseline = VmConfiguration.fromVm(_vm());
      final next = baseline.copyWith(
        bootloader: VmBootloader.grub,
        cpuMode: VmCpuMode.hostPassthrough,
        guestTime: VmGuestTime.utc,
      );
      expect(next.changedFields(baseline), {
        'bootloader': 'GRUB',
        'cpu_mode': 'HOST-PASSTHROUGH',
        'time': 'UTC',
      });
    });

    test('emits min_memory when set and when cleared', () {
      final baseline = VmConfiguration.fromVm(_vm());
      // Setting a minimum emits it.
      final withMin = VmConfiguration.fromVm(
        _vm(),
      ).copyWith(minMemoryMiB: 2048);
      expect(withMin.changedFields(baseline), {'min_memory': 2048});
      // Clearing it emits null. copyWith cannot set a nullable to null, so
      // construct the cleared configuration directly.
      final cleared = VmConfiguration.fromVm(_vm());
      expect(cleared.changedFields(withMin), {'min_memory': null});
    });
  });

  group('validateVmConfiguration', () {
    test('accepts a valid configuration', () {
      final config = VmConfiguration.fromVm(_vm());
      expect(validateVmConfiguration(config), isEmpty);
    });

    test('rejects an empty name', () {
      final config = VmConfiguration.fromVm(_vm()).copyWith(name: '');
      expect(validateVmConfiguration(config), contains('name'));
    });

    test('rejects fewer than 128 MiB of memory', () {
      final config = VmConfiguration.fromVm(_vm()).copyWith(memoryMiB: 64);
      expect(validateVmConfiguration(config), contains('memory'));
    });

    test('rejects minimum memory greater than memory', () {
      final config = VmConfiguration.fromVm(
        _vm(),
      ).copyWith(memoryMiB: 1024, minMemoryMiB: 2048);
      expect(validateVmConfiguration(config), contains('min_memory'));
    });

    test('rejects an out-of-range shutdown timeout', () {
      final config = VmConfiguration.fromVm(
        _vm(),
      ).copyWith(shutdownTimeoutSeconds: 2);
      expect(validateVmConfiguration(config), contains('shutdown_timeout'));
    });
  });

  group('enum fromApi helpers', () {
    test('VmBootloader.fromApi falls back to UEFI', () {
      expect(VmBootloader.fromApi('UNKNOWN'), VmBootloader.uefi);
      expect(VmBootloader.fromApi('GRUB'), VmBootloader.grub);
    });
    test('VmCpuMode.fromApi falls back to host model', () {
      expect(VmCpuMode.fromApi('NOPE'), VmCpuMode.hostModel);
      expect(VmCpuMode.fromApi('HOST-PASSTHROUGH'), VmCpuMode.hostPassthrough);
    });
    test('VmGuestTime.fromApi maps UTC and falls back to local', () {
      expect(VmGuestTime.fromApi('UTC'), VmGuestTime.utc);
      expect(VmGuestTime.fromApi('whatever'), VmGuestTime.local);
    });
  });
}
