import '../../../l10n/app_localizations.dart';
import '../domain/vm_device.dart';

/// Maps VM device-domain types and summaries onto ARB-localized strings.
extension VmDeviceLocalizations on AppLocalizations {
  String vmDeviceTypeLabel(VmDeviceType type) => switch (type) {
    VmDeviceType.disk => sysVmDeviceTypeDisk,
    VmDeviceType.cdrom => sysVmDeviceTypeCdrom,
    VmDeviceType.nic => sysVmDeviceTypeNic,
    VmDeviceType.display => sysVmDeviceTypeDisplay,
    VmDeviceType.memory => sysVmDeviceTypeMemory,
    VmDeviceType.usb => sysVmDeviceTypeUsb,
    VmDeviceType.pci => sysVmDeviceTypePci,
    VmDeviceType.serial => sysVmDeviceTypeSerial,
    VmDeviceType.other => sysVmDeviceTypeOther,
  };

  String vmDeviceSummary(VmDevice device) {
    final attrs = device.attributes;
    switch (device.type) {
      case VmDeviceType.disk:
        final path = attrs['path'];
        final size = attrs['size'];
        if (size is num) {
          return sysVmDeviceSummaryDiskWithSize(
            path is String ? path : sysVmDeviceSummaryDiskFallback,
            _humanSize(size),
          );
        }
        return path is String ? path : sysVmDeviceSummaryDiskFallback;
      case VmDeviceType.nic:
        final mac = attrs['mac'];
        return mac is String && mac.isNotEmpty
            ? sysVmDeviceSummaryNicWithMac(mac)
            : sysVmDeviceTypeNic;
      case VmDeviceType.display:
        return sysVmDeviceSummaryDisplay('${attrs['mode'] ?? 'VNC'}');
      case VmDeviceType.cdrom:
        final path = attrs['path'];
        return path is String && path.isNotEmpty
            ? sysVmDeviceSummaryCdromWithPath(path)
            : sysVmDeviceSummaryCdromEmpty;
      default:
        return vmDeviceTypeLabel(device.type);
    }
  }
}

String _humanSize(num bytes) {
  final mib = bytes / (1024 * 1024);
  return mib >= 1024
      ? '${(mib / 1024).toStringAsFixed(1)} GiB'
      : '${mib.toStringAsFixed(0)} MiB';
}
