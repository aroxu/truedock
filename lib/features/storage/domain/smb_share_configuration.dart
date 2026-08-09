import '../../resources/domain/server_resources.dart';

enum SmbSharePurpose {
  defaultShare,
  timeMachine,
  multiprotocol,
  timeLocked,
  privateDatasets,
  external,
  finalCutPro,
  unsupported,
}

extension SmbSharePurposeApi on SmbSharePurpose {
  String get apiValue => switch (this) {
    SmbSharePurpose.defaultShare => 'DEFAULT_SHARE',
    SmbSharePurpose.timeMachine => 'TIMEMACHINE_SHARE',
    SmbSharePurpose.multiprotocol => 'MULTIPROTOCOL_SHARE',
    SmbSharePurpose.timeLocked => 'TIME_LOCKED_SHARE',
    SmbSharePurpose.privateDatasets => 'PRIVATE_DATASETS_SHARE',
    SmbSharePurpose.external => 'EXTERNAL_SHARE',
    SmbSharePurpose.finalCutPro => 'FCP_SHARE',
    SmbSharePurpose.unsupported => 'UNSUPPORTED',
  };

  String get label => switch (this) {
    SmbSharePurpose.defaultShare => 'Default share',
    SmbSharePurpose.timeMachine => 'Time Machine',
    SmbSharePurpose.multiprotocol => 'Multiprotocol',
    SmbSharePurpose.timeLocked => 'Time locked',
    SmbSharePurpose.privateDatasets => 'Private datasets',
    SmbSharePurpose.external => 'External DFS',
    SmbSharePurpose.finalCutPro => 'Final Cut Pro',
    SmbSharePurpose.unsupported => 'Unsupported',
  };

  String get description => switch (this) {
    SmbSharePurpose.defaultShare =>
      'Best compatibility for ordinary SMB clients.',
    SmbSharePurpose.timeMachine =>
      'Advertise storage as an Apple Time Machine destination.',
    SmbSharePurpose.multiprotocol =>
      'Safer interoperability when the same data is accessed outside SMB.',
    SmbSharePurpose.timeLocked =>
      'Make files read-only through SMB after a grace period.',
    SmbSharePurpose.privateDatasets =>
      'Create a separate ZFS dataset for each connecting user.',
    SmbSharePurpose.external =>
      'Proxy clients to a share hosted on another SMB server.',
    SmbSharePurpose.finalCutPro =>
      'Storage configured for Apple Final Cut Pro workflows.',
    SmbSharePurpose.unsupported =>
      'This server share purpose cannot be edited by TrueDock.',
  };

  bool get usesLocalPath => this != SmbSharePurpose.external;

  static SmbSharePurpose fromApi(String value) =>
      SmbSharePurpose.values.firstWhere(
        (purpose) => purpose.apiValue == value,
        orElse: () => SmbSharePurpose.unsupported,
      );
}

class SmbSharePreset {
  const SmbSharePreset({required this.purpose, required this.label});

  final SmbSharePurpose purpose;
  final String label;

  static List<SmbSharePreset> fromResult(Object? result) {
    if (result is! Map) {
      throw const FormatException('Invalid SMB preset response.');
    }
    final presets = <SmbSharePreset>[];
    for (final entry in result.entries) {
      final value = entry.value;
      final nestedPurpose = value is Map
          ? value['purpose'] ??
                (value['params'] is Map
                    ? (value['params'] as Map)['purpose']
                    : null)
          : null;
      final purpose = SmbSharePurposeApi.fromApi(
        nestedPurpose == null ? '${entry.key}' : '$nestedPurpose',
      );
      if (purpose == SmbSharePurpose.unsupported) continue;
      final label = value is Map && value['name'] is String
          ? value['name'] as String
          : purpose.label;
      presets.add(SmbSharePreset(purpose: purpose, label: label));
    }
    if (presets.isEmpty) {
      presets.add(
        const SmbSharePreset(
          purpose: SmbSharePurpose.defaultShare,
          label: 'Default share',
        ),
      );
    }
    return List.unmodifiable(presets);
  }
}

class SmbShareConfiguration {
  const SmbShareConfiguration({
    required this.name,
    required this.path,
    required this.purpose,
    required this.enabled,
    required this.comment,
    required this.readOnly,
    required this.browsable,
    required this.accessBasedEnumeration,
    required this.auditEnabled,
    required this.auditWatchList,
    required this.auditIgnoreList,
    required this.aaplNameMangling,
    required this.hostsAllow,
    required this.hostsDeny,
    required this.timeMachineQuota,
    required this.autoSnapshot,
    required this.autoDatasetCreation,
    required this.datasetNamingSchema,
    required this.volumeUuid,
    required this.gracePeriod,
    required this.autoQuota,
    required this.remotePaths,
  });

  factory SmbShareConfiguration.defaults() => const SmbShareConfiguration(
    name: '',
    path: '',
    purpose: SmbSharePurpose.defaultShare,
    enabled: true,
    comment: '',
    readOnly: false,
    browsable: true,
    accessBasedEnumeration: false,
    auditEnabled: false,
    auditWatchList: [],
    auditIgnoreList: [],
    aaplNameMangling: false,
    hostsAllow: [],
    hostsDeny: [],
    timeMachineQuota: 0,
    autoSnapshot: false,
    autoDatasetCreation: false,
    datasetNamingSchema: null,
    volumeUuid: null,
    gracePeriod: 900,
    autoQuota: 0,
    remotePaths: [],
  );

  factory SmbShareConfiguration.fromShare(SmbShare share) =>
      SmbShareConfiguration(
        name: share.name,
        path: share.path,
        purpose: SmbSharePurposeApi.fromApi(share.purpose),
        enabled: share.enabled,
        comment: share.comment ?? '',
        readOnly: share.readOnly,
        browsable: share.browsable,
        accessBasedEnumeration: share.accessBasedEnumeration,
        auditEnabled: share.auditEnabled,
        auditWatchList: share.auditWatchList,
        auditIgnoreList: share.auditIgnoreList,
        aaplNameMangling: share.aaplNameMangling,
        hostsAllow: share.hostsAllow,
        hostsDeny: share.hostsDeny,
        timeMachineQuota: share.timeMachineQuota,
        autoSnapshot: share.autoSnapshot,
        autoDatasetCreation: share.autoDatasetCreation,
        datasetNamingSchema: share.datasetNamingSchema,
        volumeUuid: share.volumeUuid,
        gracePeriod: share.gracePeriod,
        autoQuota: share.autoQuota,
        remotePaths: share.remotePaths,
      );

  final String name;
  final String path;
  final SmbSharePurpose purpose;
  final bool enabled;
  final String comment;
  final bool readOnly;
  final bool browsable;
  final bool accessBasedEnumeration;
  final bool auditEnabled;
  final List<String> auditWatchList;
  final List<String> auditIgnoreList;
  final bool aaplNameMangling;
  final List<String> hostsAllow;
  final List<String> hostsDeny;
  final int timeMachineQuota;
  final bool autoSnapshot;
  final bool autoDatasetCreation;
  final String? datasetNamingSchema;
  final String? volumeUuid;
  final int gracePeriod;
  final int autoQuota;
  final List<String> remotePaths;

  Map<String, Object?> toApiJson() => {
    'purpose': purpose.apiValue,
    'name': name,
    'path': purpose == SmbSharePurpose.external ? 'EXTERNAL' : path,
    'enabled': enabled,
    'comment': comment,
    'readonly': readOnly,
    'browsable': browsable,
    'access_based_share_enumeration': accessBasedEnumeration,
    'audit': {
      'enable': auditEnabled,
      'watch_list': auditEnabled ? auditWatchList : <String>[],
      'ignore_list': auditEnabled ? auditIgnoreList : <String>[],
    },
    'options': _optionsJson(),
  };

  Map<String, Object?> _optionsJson() => switch (purpose) {
    SmbSharePurpose.defaultShare ||
    SmbSharePurpose.multiprotocol ||
    SmbSharePurpose.finalCutPro => {
      'aapl_name_mangling':
          purpose == SmbSharePurpose.finalCutPro || aaplNameMangling,
      'hostsallow': hostsAllow,
      'hostsdeny': hostsDeny,
    },
    SmbSharePurpose.timeMachine => {
      'timemachine_quota': timeMachineQuota,
      'auto_snapshot': autoSnapshot,
      'auto_dataset_creation': autoDatasetCreation,
      'dataset_naming_schema': autoDatasetCreation ? datasetNamingSchema : null,
      'vuid': volumeUuid,
      'hostsallow': hostsAllow,
      'hostsdeny': hostsDeny,
    },
    SmbSharePurpose.timeLocked => {
      'grace_period': gracePeriod,
      'aapl_name_mangling': aaplNameMangling,
      'hostsallow': hostsAllow,
      'hostsdeny': hostsDeny,
    },
    SmbSharePurpose.privateDatasets => {
      'dataset_naming_schema': datasetNamingSchema,
      'auto_quota': autoQuota,
      'aapl_name_mangling': aaplNameMangling,
      'hostsallow': hostsAllow,
      'hostsdeny': hostsDeny,
    },
    SmbSharePurpose.external => {'remote_path': remotePaths},
    SmbSharePurpose.unsupported => <String, Object?>{},
  };

  Map<String, String> validate() {
    final errors = <String, String>{};
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      errors['name'] = 'Enter a share name.';
    } else if (trimmedName.length > 80 ||
        RegExp(r'[\\/\[\]:|<>+=;,*?"]').hasMatch(trimmedName) ||
        const {
          'global',
          'printers',
          'homes',
        }.contains(trimmedName.toLowerCase())) {
      errors['name'] = 'Enter a valid unique SMB share name.';
    }
    if (purpose == SmbSharePurpose.unsupported) {
      errors['purpose'] = 'This SMB share purpose cannot be edited.';
    } else if (purpose.usesLocalPath && !path.startsWith('/mnt/')) {
      errors['path'] = 'Choose a dataset path under /mnt/.';
    }
    if (purpose == SmbSharePurpose.external) {
      if (remotePaths.isEmpty ||
          remotePaths.any((path) {
            final parts = path.split('\\');
            return parts.length != 2 || parts.any((part) => part.isEmpty);
          })) {
        errors['remotePaths'] = 'Use one SERVER\\SHARE destination per line.';
      }
    }
    if (purpose == SmbSharePurpose.timeMachine && timeMachineQuota < 0) {
      errors['timeMachineQuota'] = 'Quota cannot be negative.';
    }
    if (purpose == SmbSharePurpose.timeLocked &&
        (gracePeriod < 60 || gracePeriod > 15552000)) {
      errors['gracePeriod'] = 'Grace period must be 60–15,552,000 seconds.';
    }
    if (purpose == SmbSharePurpose.privateDatasets && autoQuota < 0) {
      errors['autoQuota'] = 'Automatic quota cannot be negative.';
    }
    if ((purpose == SmbSharePurpose.privateDatasets ||
            purpose == SmbSharePurpose.timeMachine && autoDatasetCreation) &&
        (datasetNamingSchema?.trim().isEmpty ?? true)) {
      errors['datasetNamingSchema'] = 'Enter a dataset naming schema.';
    }
    return errors;
  }
}
