import 'package:flutter/foundation.dart';

typedef VmDeviceJson = Map<String, dynamic>;

/// The kind of VM device. TrueNAS groups devices by `dtype`; the editor only
/// needs the display label and the create payload shape for the most common
/// device types.
enum VmDeviceType {
  disk('DISK', 'Disk'),
  cdrom('CDROM', 'CD-ROM'),
  nic('NIC', 'Network interface'),
  display('DISPLAY', 'Display'),
  memory('MEMORY', 'Memory balloon'),
  usb('USB', 'USB redirect'),
  pci('PCI', 'PCI device'),
  serial('SERIAL', 'Serial port'),
  other('OTHER', 'Other');

  const VmDeviceType(this.apiName, this.label);

  final String apiName;
  final String label;

  static VmDeviceType fromApi(String? value) {
    for (final t in VmDeviceType.values) {
      if (t.apiName == value) return t;
    }
    return VmDeviceType.other;
  }
}

/// A device attached to a virtual machine, read from `vm.device.query`.
@immutable
class VmDevice {
  const VmDevice({
    required this.id,
    required this.vmId,
    required this.type,
    required this.attributes,
  });

  factory VmDevice.fromJson(VmDeviceJson json) => VmDevice(
    id: _integer(json['id']),
    vmId: _integer(json['vm']),
    type: VmDeviceType.fromApi(_string(json['dtype'], fallback: 'OTHER')),
    attributes: _attributes(json),
  );

  final int id;
  final int vmId;
  final VmDeviceType type;

  /// Raw device attributes. TrueNAS returns a varied schema per device type
  /// (disk vs NIC vs display); the editor keeps the raw map so it can be
  /// re-sent on update without losing unknown keys.
  final Map<String, Object?> attributes;

  /// A short human label for this device derived from its attributes.
  String get summary {
    final attrs = attributes;
    switch (type) {
      case VmDeviceType.disk:
        final path = attrs['path'];
        final size = attrs['size'];
        return size is num
            ? '${path ?? 'Disk'} · ${_humanSize(size)}'
            : (path is String ? path : 'Disk');
      case VmDeviceType.nic:
        final mac = attrs['mac'];
        return mac is String && mac.isNotEmpty
            ? 'NIC · $mac'
            : 'Network interface';
      case VmDeviceType.display:
        return 'Display · ${attrs['mode'] ?? 'VNC'}';
      case VmDeviceType.cdrom:
        return 'CD-ROM · ${attrs['path'] ?? 'empty'}';
      default:
        return type.label;
    }
  }
}

/// Mutable configuration for a new or edited VM device, sent to
/// `vm.device.create` or `vm.device.update`.
@immutable
class VmDeviceConfiguration {
  const VmDeviceConfiguration({required this.dtype, required this.attributes});

  final VmDeviceType dtype;

  /// Attributes merged into the create/update payload. The editor only
  /// surfaces the type-specific fields it understands; anything else stays
  /// in [attributes] so it is preserved on update.
  final Map<String, Object?> attributes;

  /// Payload for `vm.device.create` (requires the owning VM id separately).
  VmDeviceJson toCreateApiJson(int vmId) => {
    'vm': vmId,
    'dtype': dtype.apiName,
    ...attributes,
  };

  /// Payload for `vm.device.update` (device id supplied separately).
  VmDeviceJson toUpdateApiJson() => {'dtype': dtype.apiName, ...attributes};
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

/// Extracts the `attributes` sub-map that TrueNAS nests under each device, or
/// an empty map when the build flattens attributes to the top level.
Map<String, Object?> _attributes(VmDeviceJson json) {
  final attrs = json['attributes'];
  if (attrs is Map<String, dynamic>) {
    // Avoid copying the dtype/vm/id keys that live at the top level.
    return Map<String, Object?>.from(attrs);
  }
  // Flattened shape: keep everything except the metadata keys.
  final out = Map<String, Object?>.from(json);
  out.remove('id');
  out.remove('vm');
  out.remove('dtype');
  return out;
}

String _humanSize(num bytes) {
  final mib = bytes / (1024 * 1024);
  return mib >= 1024
      ? '${(mib / 1024).toStringAsFixed(1)} GiB'
      : '${mib.toStringAsFixed(0)} MiB';
}
