import 'package:meta/meta.dart';

/// Stable codes for instance validation failures, so the domain layer can
/// reject a payload without needing a `BuildContext` to localize the reason.
enum VirtInstanceValidationCode {
  nameRequired,
  nameInvalid,
  imageRequired,
  cpuInvalid,
  memoryRange,
  rootDiskRange,
  environmentKeyInvalid,
}

/// A single validation failure, carrying any numeric bound the presentation
/// layer needs to substitute into the localized message.
@immutable
class VirtInstanceValidationIssue {
  const VirtInstanceValidationIssue(this.code, {this.bound});

  final VirtInstanceValidationCode code;
  final int? bound;
}

/// Smallest memory the server accepts, in MiB. Below this the guest cannot
/// boot, and the middleware's own error is opaque.
const virtMinimumMemoryMiB = 64;

/// Largest root disk TrueDock offers, in GiB. Not a server limit; a guard so a
/// mistyped value cannot request a disk larger than any plausible pool.
const virtMaximumRootDiskGiB = 65536;

/// Mutable fields of an existing instance, for `virt.instance.update`.
///
/// The method merges a partial object, so only fields the user actually changed
/// are emitted. Sending the whole object would overwrite values TrueDock does
/// not surface, such as `raw` or the userns idmap.
@immutable
class VirtInstanceConfiguration {
  const VirtInstanceConfiguration({
    this.cpu,
    this.memoryMiB,
    this.autostart,
    this.environment,
    this.privileged,
    this.rootDiskSizeGiB,
  });

  /// Core count or a pinned CPU set, as the server reports and accepts it.
  final String? cpu;
  final int? memoryMiB;
  final bool? autostart;
  final Map<String, String>? environment;
  final bool? privileged;
  final int? rootDiskSizeGiB;

  List<VirtInstanceValidationIssue> validate() {
    final issues = <VirtInstanceValidationIssue>[];
    final cpuValue = cpu?.trim();
    if (cpuValue != null && cpuValue.isNotEmpty && !_isValidCpu(cpuValue)) {
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.cpuInvalid,
        ),
      );
    }
    final memory = memoryMiB;
    if (memory != null && memory < virtMinimumMemoryMiB) {
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.memoryRange,
          bound: virtMinimumMemoryMiB,
        ),
      );
    }
    final disk = rootDiskSizeGiB;
    if (disk != null && (disk < 1 || disk > virtMaximumRootDiskGiB)) {
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.rootDiskRange,
          bound: virtMaximumRootDiskGiB,
        ),
      );
    }
    for (final key in environment?.keys ?? const <String>[]) {
      if (!_isValidEnvironmentKey(key)) {
        issues.add(
          const VirtInstanceValidationIssue(
            VirtInstanceValidationCode.environmentKeyInvalid,
          ),
        );
        break;
      }
    }
    return issues;
  }

  /// Partial payload for `virt.instance.update`. Memory is converted to bytes,
  /// which is the unit the server reports and accepts.
  Map<String, Object?> toApiJson() {
    final payload = <String, Object?>{};
    final cpuValue = cpu?.trim();
    if (cpuValue != null) payload['cpu'] = cpuValue.isEmpty ? null : cpuValue;
    if (memoryMiB != null) payload['memory'] = memoryMiB! * 1024 * 1024;
    if (autostart != null) payload['autostart'] = autostart;
    if (environment != null) payload['environment'] = environment;
    if (privileged != null) payload['privileged_mode'] = privileged;
    if (rootDiskSizeGiB != null) payload['root_disk_size'] = rootDiskSizeGiB;
    return payload;
  }

  /// True when nothing would be sent, so the caller can skip a no-op job.
  bool get isEmpty => toApiJson().isEmpty;
}

/// A new instance, for `virt.instance.create`.
@immutable
class VirtInstanceCreateConfiguration {
  const VirtInstanceCreateConfiguration({
    required this.name,
    required this.image,
    this.cpu,
    this.memoryMiB,
    this.autostart = true,
    this.storagePool,
    this.rootDiskSizeGiB,
    this.environment = const {},
  });

  final String name;

  /// Catalog image identifier, for example `alpine/3.22/default`.
  final String image;
  final String? cpu;
  final int? memoryMiB;
  final bool autostart;
  final String? storagePool;
  final int? rootDiskSizeGiB;
  final Map<String, String> environment;

  List<VirtInstanceValidationIssue> validate() {
    final issues = <VirtInstanceValidationIssue>[];
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.nameRequired,
        ),
      );
    } else if (!_isValidName(trimmed)) {
      // Incus derives a hostname from the instance name, so the server rejects
      // anything that is not a DNS label. Catching it here gives the user a
      // reason instead of a middleware validation dump.
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.nameInvalid,
        ),
      );
    }
    if (image.trim().isEmpty) {
      issues.add(
        const VirtInstanceValidationIssue(
          VirtInstanceValidationCode.imageRequired,
        ),
      );
    }
    issues.addAll(
      VirtInstanceConfiguration(
        cpu: cpu,
        memoryMiB: memoryMiB,
        rootDiskSizeGiB: rootDiskSizeGiB,
        environment: environment,
      ).validate(),
    );
    return issues;
  }

  Map<String, Object?> toApiJson() {
    final cpuValue = cpu?.trim();
    return <String, Object?>{
      'name': name.trim(),
      'image': image.trim(),
      // Only CONTAINER instances are created here. 25.10 accepts VM through the
      // same method, but a VM needs a bootable volume rather than a catalog
      // image, so that is a separate flow rather than a flag on this one.
      'instance_type': 'CONTAINER',
      'source_type': 'IMAGE',
      'autostart': autostart,
      if (cpuValue != null && cpuValue.isNotEmpty) 'cpu': cpuValue,
      if (memoryMiB != null) 'memory': memoryMiB! * 1024 * 1024,
      if (storagePool != null) 'storage_pool': storagePool,
      if (rootDiskSizeGiB != null) 'root_disk_size': rootDiskSizeGiB,
      if (environment.isNotEmpty) 'environment': environment,
    };
  }
}

/// One entry from `virt.instance.image_choices`.
@immutable
class VirtImageChoice {
  const VirtImageChoice({
    required this.id,
    required this.label,
    required this.os,
    required this.release,
    required this.variant,
    required this.architectures,
    required this.instanceTypes,
  });

  factory VirtImageChoice.fromJson(String id, Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List
        ? value.whereType<String>().toList(growable: false)
        : const [];
    return VirtImageChoice(
      id: id,
      label: json['label'] is String && (json['label'] as String).isNotEmpty
          ? json['label'] as String
          : id,
      os: json['os'] as String? ?? '',
      release: json['release'] as String? ?? '',
      variant: json['variant'] as String? ?? '',
      architectures: strings(json['archs']),
      instanceTypes: strings(json['instance_types']),
    );
  }

  final String id;
  final String label;
  final String os;
  final String release;
  final String variant;
  final List<String> architectures;
  final List<String> instanceTypes;

  bool get supportsContainer => instanceTypes.contains('CONTAINER');
}

/// DNS-label rules, which is what Incus requires of an instance name.
bool _isValidName(String value) {
  if (value.length > 63) return false;
  return RegExp(
    r'^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z]$',
  ).hasMatch(value);
}

/// Accepts a plain core count or a pinned set such as `0-3` or `0,2,4`.
bool _isValidCpu(String value) =>
    RegExp(r'^\d+$').hasMatch(value) ||
    RegExp(r'^\d+(-\d+)?(,\d+(-\d+)?)*$').hasMatch(value);

/// Environment names must be shell-safe; the server passes them straight
/// through to the guest.
bool _isValidEnvironmentKey(String key) =>
    key.isNotEmpty && RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(key);
