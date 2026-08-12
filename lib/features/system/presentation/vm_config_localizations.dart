import '../../../l10n/app_localizations.dart';
import '../domain/vm_configuration.dart';

/// Maps VM configuration codes and enum labels onto ARB-localized strings.
extension VmConfigLocalizations on AppLocalizations {
  String vmValidationMessage(VmValidationCode code) => switch (code) {
    VmValidationCode.nameRequired => sysVmConfigValidationNameRequired,
    VmValidationCode.vcpusMinimum => sysVmConfigValidationVcpusMinimum,
    VmValidationCode.coresMinimum => sysVmConfigValidationCoresMinimum,
    VmValidationCode.threadsMinimum => sysVmConfigValidationThreadsMinimum,
    VmValidationCode.memoryMinimum => sysVmConfigValidationMemoryMinimum,
    VmValidationCode.minMemoryExceedsMemory =>
      sysVmConfigValidationMinMemoryExceeds,
    VmValidationCode.shutdownTimeoutRange =>
      sysVmConfigValidationShutdownTimeoutRange,
  };

  String vmBootloaderLabel(VmBootloader bootloader) => switch (bootloader) {
    VmBootloader.uefi => sysVmBootloaderUefi,
    VmBootloader.uefiCsm => sysVmBootloaderUefiCsm,
    VmBootloader.grub => sysVmBootloaderGrub,
  };

  String vmCpuModeLabel(VmCpuMode mode) => switch (mode) {
    VmCpuMode.custom => sysVmCpuModeCustom,
    VmCpuMode.hostModel => sysVmCpuModeHostModel,
    VmCpuMode.hostPassthrough => sysVmCpuModeHostPassthrough,
  };
}
