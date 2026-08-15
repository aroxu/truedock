import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/smb_share_configuration.dart';

void main() {
  test('serializes a default SMB share with common and purpose options', () {
    const configuration = SmbShareConfiguration(
      name: 'Projects',
      path: '/mnt/tank/projects',
      purpose: SmbSharePurpose.defaultShare,
      enabled: true,
      comment: 'Team projects',
      readOnly: false,
      browsable: true,
      accessBasedEnumeration: true,
      auditEnabled: true,
      auditWatchList: ['interns'],
      auditIgnoreList: ['automation'],
      aaplNameMangling: false,
      hostsAllow: ['10.0.0.0/24'],
      hostsDeny: ['ALL'],
      timeMachineQuota: 0,
      autoSnapshot: false,
      autoDatasetCreation: false,
      datasetNamingSchema: null,
      volumeUuid: null,
      gracePeriod: 900,
      autoQuota: 0,
      remotePaths: [],
    );

    expect(configuration.validate(), isEmpty);
    expect(configuration.toApiJson(), {
      'purpose': 'DEFAULT_SHARE',
      'name': 'Projects',
      'path': '/mnt/tank/projects',
      'enabled': true,
      'comment': 'Team projects',
      'readonly': false,
      'browsable': true,
      'access_based_share_enumeration': true,
      'audit': {
        'enable': true,
        'watch_list': ['interns'],
        'ignore_list': ['automation'],
      },
      'options': {
        'aapl_name_mangling': false,
        'hostsallow': ['10.0.0.0/24'],
        'hostsdeny': ['ALL'],
      },
    });
  });

  test('restores and preserves Time Machine purpose-specific values', () {
    final share = SmbShare.fromJson({
      'id': 4,
      'name': 'Backups',
      'path': '/mnt/tank/backups',
      'purpose': 'TIMEMACHINE_SHARE',
      'enabled': true,
      'readonly': false,
      'browsable': true,
      'access_based_share_enumeration': false,
      'locked': false,
      'audit': {'enable': false, 'watch_list': [], 'ignore_list': []},
      'options': {
        'timemachine_quota': 1073741824,
        'auto_snapshot': true,
        'auto_dataset_creation': true,
        'dataset_naming_schema': '%U',
        'vuid': 'volume-uuid',
        'hostsallow': [],
        'hostsdeny': [],
      },
    });

    final configuration = SmbShareConfiguration.fromShare(share);
    final options = configuration.toApiJson()['options'] as Map;

    expect(configuration.purpose, SmbSharePurpose.timeMachine);
    expect(options['timemachine_quota'], 1073741824);
    expect(options['auto_snapshot'], isTrue);
    expect(options['dataset_naming_schema'], '%U');
    expect(options['vuid'], 'volume-uuid');
  });

  test('validates reserved names, paths, DFS targets, and grace periods', () {
    final defaults = SmbShareConfiguration.defaults();
    final invalidName = SmbShareConfiguration(
      name: 'homes',
      path: 'tank/data',
      purpose: defaults.purpose,
      enabled: defaults.enabled,
      comment: defaults.comment,
      readOnly: defaults.readOnly,
      browsable: defaults.browsable,
      accessBasedEnumeration: defaults.accessBasedEnumeration,
      auditEnabled: defaults.auditEnabled,
      auditWatchList: defaults.auditWatchList,
      auditIgnoreList: defaults.auditIgnoreList,
      aaplNameMangling: defaults.aaplNameMangling,
      hostsAllow: defaults.hostsAllow,
      hostsDeny: defaults.hostsDeny,
      timeMachineQuota: defaults.timeMachineQuota,
      autoSnapshot: defaults.autoSnapshot,
      autoDatasetCreation: defaults.autoDatasetCreation,
      datasetNamingSchema: defaults.datasetNamingSchema,
      volumeUuid: defaults.volumeUuid,
      gracePeriod: defaults.gracePeriod,
      autoQuota: defaults.autoQuota,
      remotePaths: defaults.remotePaths,
    );
    expect(invalidName.validate(), containsPair('name', isNotEmpty));
    expect(invalidName.validate(), containsPair('path', isNotEmpty));

    final external = SmbShareConfiguration(
      name: 'Proxy',
      path: '',
      purpose: SmbSharePurpose.external,
      enabled: true,
      comment: '',
      readOnly: false,
      browsable: true,
      accessBasedEnumeration: false,
      auditEnabled: false,
      auditWatchList: const [],
      auditIgnoreList: const [],
      aaplNameMangling: false,
      hostsAllow: const [],
      hostsDeny: const [],
      timeMachineQuota: 0,
      autoSnapshot: false,
      autoDatasetCreation: false,
      datasetNamingSchema: null,
      volumeUuid: null,
      gracePeriod: 900,
      autoQuota: 0,
      remotePaths: const ['server-only'],
    );
    expect(external.validate(), containsPair('remotePaths', isNotEmpty));
  });

  test('parses server preset maps and filters unsupported purposes', () {
    final presets = SmbSharePreset.fromResult({
      'DEFAULT_SHARE': {'name': 'Default'},
      'time-machine': {
        'name': 'Apple backups',
        'params': {'purpose': 'TIMEMACHINE_SHARE'},
      },
      'VEEAM_REPOSITORY_SHARE': {'name': 'Enterprise only'},
    });

    expect(presets.map((preset) => preset.purpose), [
      SmbSharePurpose.defaultShare,
      SmbSharePurpose.timeMachine,
    ]);
  });
}
