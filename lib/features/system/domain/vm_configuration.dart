import 'package:flutter/foundation.dart';

import '../../resources/domain/server_resources.dart';

/// Stable codes for VM configuration validation failures.
enum VmValidationCode {
  nameRequired,
  vcpusMinimum,
  coresMinimum,
  threadsMinimum,
  memoryMinimum,
  minMemoryExceedsMemory,
  shutdownTimeoutRange,
}

/// Bootloader options exposed by TrueNAS 25.10 `vm.update`.
enum VmBootloader {
  uefi('UEFI', 'UEFI'),
  uefiCsm('UEFI_CSM', 'UEFI_CSM'),
  grub('GRUB', 'GRUB');

  const VmBootloader(this.apiName, this.label);

  final String apiName;
  final String label;

  static VmBootloader fromApi(String? value) {
    for (final b in VmBootloader.values) {
      if (b.apiName == value) return b;
    }
    return VmBootloader.uefi;
  }
}

/// CPU mode options for `vm.update.cpu_mode`.
enum VmCpuMode {
  custom('CUSTOM', 'Custom'),
  hostModel('HOST-MODEL', 'Host model'),
  hostPassthrough('HOST-PASSTHROUGH', 'Host passthrough');

  const VmCpuMode(this.apiName, this.label);

  final String apiName;
  final String label;

  static VmCpuMode fromApi(String? value) {
    for (final m in VmCpuMode.values) {
      if (m.apiName == value) return m;
    }
    return VmCpuMode.hostModel;
  }
}

/// Guest time reference for `vm.update.time`.
enum VmGuestTime {
  local('LOCAL', 'Local'),
  utc('UTC', 'UTC');

  const VmGuestTime(this.apiName, this.label);

  final String apiName;
  final String label;

  static VmGuestTime fromApi(String? value) =>
      value == 'UTC' ? VmGuestTime.utc : VmGuestTime.local;
}

/// Mutable VM configuration collected by the editor and sent to `vm.update`.
///
/// Only fields the user changed are emitted by [changedFields]; unchanged
/// fields are omitted so the server keeps its current value. This avoids
/// accidentally resetting fields the editor does not expose.
@immutable
class VmConfiguration {
  const VmConfiguration({
    required this.name,
    required this.description,
    required this.vcpus,
    required this.cores,
    required this.threads,
    required this.memoryMiB,
    required this.minMemoryMiB,
    required this.autostart,
    required this.bootloader,
    required this.cpuMode,
    required this.guestTime,
    required this.shutdownTimeoutSeconds,
    required this.hideFromMsr,
    required this.ensureDisplayDevice,
  });

  factory VmConfiguration.fromVm(VirtualMachine vm) {
    // The resource model does not carry every vm.update field, so the editor
    // seeds the common ones and leaves the rest at server defaults.
    return VmConfiguration(
      name: vm.name,
      description: vm.description ?? '',
      vcpus: vm.vcpus,
      cores: vm.cores,
      threads: vm.threads,
      memoryMiB: vm.memoryMiB,
      minMemoryMiB: null,
      autostart: vm.autostart,
      bootloader: VmBootloader.uefi,
      cpuMode: VmCpuMode.hostModel,
      guestTime: VmGuestTime.local,
      shutdownTimeoutSeconds: 90,
      hideFromMsr: false,
      ensureDisplayDevice: vm.displayAvailable,
    );
  }

  final String name;
  final String description;
  final int vcpus;
  final int cores;
  final int threads;
  final int memoryMiB;
  final int? minMemoryMiB;
  final bool autostart;
  final VmBootloader bootloader;
  final VmCpuMode cpuMode;
  final VmGuestTime guestTime;
  final int shutdownTimeoutSeconds;
  final bool hideFromMsr;
  final bool ensureDisplayDevice;

  /// Returns only the fields that differ from [baseline], as the payload for
  /// `vm.update`. Omitting unchanged fields keeps the server's existing value
  /// for anything the editor does not surface.
  Map<String, Object?> changedFields(VmConfiguration baseline) {
    final out = <String, Object?>{};
    if (name != baseline.name) out['name'] = name;
    if (description != baseline.description) out['description'] = description;
    if (vcpus != baseline.vcpus) out['vcpus'] = vcpus;
    if (cores != baseline.cores) out['cores'] = cores;
    if (threads != baseline.threads) out['threads'] = threads;
    if (memoryMiB != baseline.memoryMiB) out['memory'] = memoryMiB;
    if (minMemoryMiB != baseline.minMemoryMiB) {
      out['min_memory'] = minMemoryMiB;
    }
    if (autostart != baseline.autostart) out['autostart'] = autostart;
    if (bootloader != baseline.bootloader) {
      out['bootloader'] = bootloader.apiName;
    }
    if (cpuMode != baseline.cpuMode) out['cpu_mode'] = cpuMode.apiName;
    if (guestTime != baseline.guestTime) out['time'] = guestTime.apiName;
    if (shutdownTimeoutSeconds != baseline.shutdownTimeoutSeconds) {
      out['shutdown_timeout'] = shutdownTimeoutSeconds;
    }
    if (hideFromMsr != baseline.hideFromMsr) {
      out['hide_from_msr'] = hideFromMsr;
    }
    if (ensureDisplayDevice != baseline.ensureDisplayDevice) {
      out['ensure_display_device'] = ensureDisplayDevice;
    }
    return out;
  }

  VmConfiguration copyWith({
    String? name,
    String? description,
    int? vcpus,
    int? cores,
    int? threads,
    int? memoryMiB,
    int? minMemoryMiB,
    bool? autostart,
    VmBootloader? bootloader,
    VmCpuMode? cpuMode,
    VmGuestTime? guestTime,
    int? shutdownTimeoutSeconds,
    bool? hideFromMsr,
    bool? ensureDisplayDevice,
  }) => VmConfiguration(
    name: name ?? this.name,
    description: description ?? this.description,
    vcpus: vcpus ?? this.vcpus,
    cores: cores ?? this.cores,
    threads: threads ?? this.threads,
    memoryMiB: memoryMiB ?? this.memoryMiB,
    minMemoryMiB: minMemoryMiB ?? this.minMemoryMiB,
    autostart: autostart ?? this.autostart,
    bootloader: bootloader ?? this.bootloader,
    cpuMode: cpuMode ?? this.cpuMode,
    guestTime: guestTime ?? this.guestTime,
    shutdownTimeoutSeconds:
        shutdownTimeoutSeconds ?? this.shutdownTimeoutSeconds,
    hideFromMsr: hideFromMsr ?? this.hideFromMsr,
    ensureDisplayDevice: ensureDisplayDevice ?? this.ensureDisplayDevice,
  );
}

/// Validates a [VmConfiguration] before it is sent to the server. Returns a
/// map of field-key to error message; empty means the configuration is valid.
Map<String, VmValidationCode> validateVmConfiguration(VmConfiguration config) {
  final errors = <String, VmValidationCode>{};
  if (config.name.trim().isEmpty) {
    errors['name'] = VmValidationCode.nameRequired;
  }
  if (config.vcpus < 1) errors['vcpus'] = VmValidationCode.vcpusMinimum;
  if (config.cores < 1) errors['cores'] = VmValidationCode.coresMinimum;
  if (config.threads < 1) errors['threads'] = VmValidationCode.threadsMinimum;
  if (config.memoryMiB < 128) {
    errors['memory'] = VmValidationCode.memoryMinimum;
  }
  final minMemory = config.minMemoryMiB;
  if (minMemory != null && minMemory > config.memoryMiB) {
    errors['min_memory'] = VmValidationCode.minMemoryExceedsMemory;
  }
  if (config.shutdownTimeoutSeconds < 5 ||
      config.shutdownTimeoutSeconds > 300) {
    errors['shutdown_timeout'] = VmValidationCode.shutdownTimeoutRange;
  }
  return errors;
}
