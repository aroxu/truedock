// Uses meta rather than flutter/foundation so this pure-domain type loads on
// the Dart VM, letting tool/live_mutation_probe.dart send the app's own payload.
import 'package:meta/meta.dart';

/// The layout of a single vdev within a pool's topology.
///
/// TrueNAS 25.10 accepts STRIPE, MIRROR, RAIDZ1, RAIDZ2, and RAIDZ3 for the
/// data category. STRIPE offers no redundancy; RAIDZ1/2/3 tolerate 1/2/3 disk
/// failures respectively; MIRROR tolerates one disk failure per mirrored
/// pair. The editor surfaces the redundancy trade-off so the user cannot
/// create a non-redundant pool by accident.
enum VdevType {
  stripe(
    'STRIPE',
    'Stripe',
    0,
    'No redundancy. A single disk failure loses the pool.',
  ),
  mirror('MIRROR', 'Mirror', 1, 'Tolerates one disk failure per pair.'),
  raidz1('RAIDZ1', 'RAIDZ1', 1, 'Tolerates one disk failure.'),
  raidz2('RAIDZ2', 'RAIDZ2', 2, 'Tolerates two disk failures.'),
  raidz3('RAIDZ3', 'RAIDZ3', 3, 'Tolerates three disk failures.');

  const VdevType(this.apiName, this.label, this.faultTolerance, this.warning);

  final String apiName;
  final String label;

  /// Number of disk failures this layout tolerates per vdev.
  final int faultTolerance;

  /// A short consequence note shown when the user picks this layout.
  final String warning;

  static VdevType fromApi(String? value) {
    for (final t in VdevType.values) {
      if (t.apiName == value) return t;
    }
    return VdevType.stripe;
  }
}

/// The vdev category within a pool topology. The data category is required
/// and carries the pool's main storage; the others are optional.
enum VdevCategory {
  data('data', 'Data'),
  cache('cache', 'Cache (L2ARC)'),
  log('log', 'Log (ZIL/SLOG)'),
  spare('spare', 'Spare'),
  dedup('dedup', 'Dedup'),
  special('special', 'Special');

  const VdevCategory(this.apiName, this.label);

  final String apiName;
  final String label;

  /// Whether this category is the required data tier.
  bool get isData => this == VdevCategory.data;
}

/// A single vdev in the pool's topology: a layout plus the disks it groups.
@immutable
class VdevSpec {
  const VdevSpec({required this.type, required this.disks});

  final VdevType type;

  /// Disk names (devnames) the vdev groups. Stripe/RAIDZ accept 1+; mirror
  /// expects an even count for mirrored pairs.
  final List<String> disks;

  /// Payload for `pool.create` topology.
  ///
  /// The field is `disks`, not `devices`: the 25.10 schema
  /// (`PoolCreateTopologyDataVdevNonDRAID`) requires `disks` and rejects
  /// `devices` as an extra input. Verified against a live server by
  /// `tool/live_mutation_probe.dart`.
  Map<String, Object?> toApiJson() => {
    'type': type.apiName,
    'disks': List<String>.from(disks),
  };

  VdevSpec copyWith({VdevType? type, List<String>? disks}) =>
      VdevSpec(type: type ?? this.type, disks: disks ?? this.disks);
}

/// The full pool-create configuration collected by the editor and sent to
/// `pool.create`.
@immutable
class PoolConfiguration {
  const PoolConfiguration({
    required this.name,
    required this.dataVdevs,
    this.cacheVdevs = const [],
    this.logVdevs = const [],
    this.spareVdevs = const [],
    this.dedupVdevs = const [],
    this.specialVdevs = const [],
    this.encryption = false,
    this.dedup = false,
    this.checksum,
    this.autoTrim = true,
  });

  final String name;

  /// The required data tier. At least one vdev is required.
  final List<VdevSpec> dataVdevs;
  final List<VdevSpec> cacheVdevs;
  final List<VdevSpec> logVdevs;
  final List<VdevSpec> spareVdevs;
  final List<VdevSpec> dedupVdevs;
  final List<VdevSpec> specialVdevs;

  /// Whether the pool is encrypted at rest. The caller confirms the key
  /// management consequence.
  final bool encryption;

  /// Enable block-based deduplication. Warns about memory pressure.
  final bool dedup;

  /// Optional checksum algorithm; null means the server default (on).
  final String? checksum;

  /// Enable automatic TRIM/discard.
  final bool autoTrim;

  /// Payload for `pool.create`. TrueNAS takes `name` and a `topology` map keyed
  /// by category, where each value is a list of vdev specs.
  Map<String, Object?> toApiJson() {
    final topology = <String, Object?>{};
    void emit(String category, List<VdevSpec> vdevs) {
      if (vdevs.isEmpty) return;
      topology[category] = vdevs.map((v) => v.toApiJson()).toList();
    }

    emit('data', dataVdevs);
    emit('cache', cacheVdevs);
    emit('log', logVdevs);
    // The schema names this category `spares`, not `spare`.
    emit('spares', spareVdevs);
    emit('dedup', dedupVdevs);
    emit('special', specialVdevs);
    return {
      'name': name,
      'topology': topology,
      // `encryption` is the flag; `encryption_options` is only meaningful
      // alongside it and must be omitted rather than sent as null, which the
      // schema rejects as not-a-dictionary.
      'encryption': encryption,
      if (encryption) 'encryption_options': {'algorithm': 'AES-256-GCM'},
      // `deduplication` accepts ON/VERIFY/OFF/null. Send it only when the
      // user opted in so the server keeps its own default otherwise.
      if (dedup) 'deduplication': 'ON',
      if (checksum != null) 'checksum': checksum,
    };
  }

  /// All disks used across every category, so the editor can prevent the same
  /// disk from being assigned twice.
  Set<String> get usedDisks => {
    for (final v in dataVdevs) ...v.disks,
    for (final v in cacheVdevs) ...v.disks,
    for (final v in logVdevs) ...v.disks,
    for (final v in spareVdevs) ...v.disks,
    for (final v in dedupVdevs) ...v.disks,
    for (final v in specialVdevs) ...v.disks,
  };
}

/// A stable validation code that presentation layers can localize without
/// parsing the English compatibility messages returned by
/// [validatePoolConfiguration].
enum PoolValidationCode {
  nameRequired,
  nameInvalid,
  dataVdevRequired,
  dataVdevNoDisks,
  dataVdevMinimumDisks,
}

@immutable
class PoolValidationIssue {
  const PoolValidationIssue(
    this.code, {
    this.vdevIndex,
    this.vdevType,
    this.minimumDisks,
  });

  final PoolValidationCode code;
  final int? vdevIndex;
  final VdevType? vdevType;
  final int? minimumDisks;

  String get field => switch (code) {
    PoolValidationCode.nameRequired || PoolValidationCode.nameInvalid => 'name',
    _ => 'data',
  };

  String get message => switch (code) {
    PoolValidationCode.nameRequired => 'Enter a pool name.',
    PoolValidationCode.nameInvalid =>
      'Start with a letter and use letters, numbers, or . _ : -.',
    PoolValidationCode.dataVdevRequired => 'Add at least one data vdev.',
    PoolValidationCode.dataVdevNoDisks =>
      'Data vdev ${vdevIndex! + 1} has no disks.',
    PoolValidationCode.dataVdevMinimumDisks =>
      '${vdevType!.label} vdev ${vdevIndex! + 1} needs at least '
          '$minimumDisks disks.',
  };
}

/// Returns typed validation issues so UI clients can localize messages while
/// retaining the same domain rules and field association.
List<PoolValidationIssue> poolConfigurationIssues(PoolConfiguration config) {
  final issues = <PoolValidationIssue>[];
  if (config.name.trim().isEmpty) {
    issues.add(const PoolValidationIssue(PoolValidationCode.nameRequired));
  } else if (!RegExp(r'^[A-Za-z][A-Za-z0-9._:-]*$').hasMatch(config.name)) {
    issues.add(const PoolValidationIssue(PoolValidationCode.nameInvalid));
  }

  if (config.dataVdevs.isEmpty) {
    issues.add(const PoolValidationIssue(PoolValidationCode.dataVdevRequired));
    return issues;
  }

  for (var index = 0; index < config.dataVdevs.length; index++) {
    final vdev = config.dataVdevs[index];
    if (vdev.disks.isEmpty) {
      issues.add(
        PoolValidationIssue(
          PoolValidationCode.dataVdevNoDisks,
          vdevIndex: index,
        ),
      );
      break;
    }
    final minimumDisks = switch (vdev.type) {
      VdevType.stripe => 1,
      VdevType.mirror || VdevType.raidz1 => 2,
      VdevType.raidz2 => 3,
      VdevType.raidz3 => 4,
    };
    if (vdev.disks.length < minimumDisks) {
      issues.add(
        PoolValidationIssue(
          PoolValidationCode.dataVdevMinimumDisks,
          vdevIndex: index,
          vdevType: vdev.type,
          minimumDisks: minimumDisks,
        ),
      );
      break;
    }
  }
  return issues;
}

/// Validates a [PoolConfiguration] before it is sent to the server. Returns a
/// map of field-key to error message; empty means valid.
Map<String, String> validatePoolConfiguration(PoolConfiguration config) {
  final errors = <String, String>{};
  for (final issue in poolConfigurationIssues(config)) {
    errors[issue.field] = issue.message;
  }
  return errors;
}
