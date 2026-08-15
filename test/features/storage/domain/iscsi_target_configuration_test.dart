import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_configuration.dart';

void main() {
  test('serializes the complete TrueNAS 25.10 target payload', () {
    const configuration = IscsiTargetConfiguration(
      name: '  iqn.2026-08.me.aroxu:media  ',
      alias: '  Media target  ',
      groups: [
        IscsiTargetGroupConfiguration(
          portalId: 1,
          initiatorId: null,
          authMethod: 'NONE',
          authId: null,
        ),
        IscsiTargetGroupConfiguration(
          portalId: 2,
          initiatorId: 4,
          authMethod: 'CHAP_MUTUAL',
          authId: 7,
        ),
      ],
      authNetworks: ['10.0.0.0/24', '2001:db8::/64'],
      queuedCommands: 128,
    );

    expect(configuration.toApiJson(), {
      'name': 'iqn.2026-08.me.aroxu:media',
      'alias': 'Media target',
      'mode': 'ISCSI',
      'groups': [
        {'portal': 1, 'initiator': null, 'authmethod': 'NONE', 'auth': null},
        {'portal': 2, 'initiator': 4, 'authmethod': 'CHAP_MUTUAL', 'auth': 7},
      ],
      'auth_networks': ['10.0.0.0/24', '2001:db8::/64'],
      'iscsi_parameters': {'QueuedCommands': 128},
    });
  });

  test('restores target fields and preserves authenticated groups exactly', () {
    final target = IscsiTarget.fromJson({
      'id': 3,
      'name': 'iqn.2026-08.me.aroxu:archive',
      'alias': 'Archive',
      'mode': 'ISCSI',
      'groups': [
        {'portal': 9, 'initiator': 5, 'authmethod': 'CHAP', 'auth': 11},
        {'portal': 10, 'initiator': 6, 'authmethod': 'CHAP_MUTUAL', 'auth': 12},
      ],
      'auth_networks': ['192.0.2.0/24'],
      'iscsi_parameters': {'QueuedCommands': 32},
    });

    final configuration = IscsiTargetConfiguration.fromTarget(target);

    expect(configuration.authNetworks, ['192.0.2.0/24']);
    expect(configuration.queuedCommands, 32);
    expect(configuration.toApiJson()['groups'], [
      {'portal': 9, 'initiator': 5, 'authmethod': 'CHAP', 'auth': 11},
      {'portal': 10, 'initiator': 6, 'authmethod': 'CHAP_MUTUAL', 'auth': 12},
    ]);
  });

  test('defaults to a NONE group for the selected portal', () {
    final portal = IscsiPortal.fromJson({
      'id': 4,
      'tag': 1,
      'comment': '',
      'listen': [
        {'ip': '0.0.0.0', 'port': 3260},
      ],
    });

    final configuration = IscsiTargetConfiguration.defaults(portal: portal);

    expect(configuration.groups.single.toApiJson(), {
      'portal': 4,
      'initiator': null,
      'authmethod': 'NONE',
      'auth': null,
    });
    expect(configuration.toApiJson()['iscsi_parameters'], isNull);
  });

  test('validates names, choices, group tuples, auth pairs, and networks', () {
    final portal = IscsiPortal.fromJson({
      'id': 1,
      'tag': 1,
      'comment': '',
      'listen': const [],
    });
    final initiator = IscsiInitiator.fromJson({
      'id': 2,
      'initiators': const [],
      'comment': '',
    });
    const duplicateGroup = IscsiTargetGroupConfiguration(
      portalId: 9,
      initiatorId: 8,
      authMethod: 'NONE',
      authId: 5,
    );
    const configuration = IscsiTargetConfiguration(
      name:
          'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      alias: null,
      groups: [duplicateGroup, duplicateGroup],
      authNetworks: ['10.0.0.0/33', 'not-a-network'],
      queuedCommands: 64,
    );

    expect(
      configuration
          .validate(
            availablePortals: [portal],
            availableInitiators: [initiator],
          )
          .keys,
      {'name', 'groups', 'authNetworks', 'queuedCommands'},
    );
  });

  test('accepts available portal and initiator IDs with coherent CHAP', () {
    final portal = IscsiPortal.fromJson({
      'id': 3,
      'tag': 1,
      'comment': '',
      'listen': const [],
    });
    final initiator = IscsiInitiator.fromJson({
      'id': 6,
      'initiators': ['iqn.2026-08.me.aroxu:client'],
      'comment': '',
    });
    const configuration = IscsiTargetConfiguration(
      name: 'iqn.2026-08.me.aroxu:data',
      alias: null,
      groups: [
        IscsiTargetGroupConfiguration(
          portalId: 3,
          initiatorId: 6,
          authMethod: 'CHAP',
          authId: 12,
        ),
      ],
      authNetworks: [],
      queuedCommands: null,
    );

    expect(
      configuration.validate(
        availablePortals: [portal],
        availableInitiators: [initiator],
      ),
      isEmpty,
    );
  });

  test(
    'accepts an empty group list for an intentionally unreachable target',
    () {
      const configuration = IscsiTargetConfiguration(
        name: 'offline-target',
        alias: null,
        groups: [],
        authNetworks: [],
        queuedCommands: null,
      );

      expect(configuration.validate(), isEmpty);
      expect(configuration.toApiJson()['groups'], isEmpty);
    },
  );
}
