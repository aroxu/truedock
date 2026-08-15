import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_configuration.dart';

void main() {
  group('IscsiPortalConfiguration', () {
    test('serializes the documented portal payload exactly', () {
      const configuration = IscsiPortalConfiguration(
        listenAddresses: ['0.0.0.0', '2001:db8::10'],
        comment: '  Storage network  ',
      );

      expect(configuration.toApiJson(), {
        'listen': [
          {'ip': '0.0.0.0'},
          {'ip': '2001:db8::10'},
        ],
        'comment': 'Storage network',
      });
      expect(
        configuration.validate(
          availableAddresses: const ['0.0.0.0', '2001:db8::10'],
        ),
        isEmpty,
      );
    });

    test('restores listen addresses and comment from an existing portal', () {
      final portal = IscsiPortal.fromJson({
        'id': 4,
        'tag': 7,
        'comment': 'Storage network',
        'listen': [
          {'ip': '10.0.0.10', 'port': 3260},
          {'ip': '2001:db8::10', 'port': 3261},
        ],
      });

      final configuration = IscsiPortalConfiguration.fromPortal(portal);

      expect(configuration.listenAddresses, ['10.0.0.10', '2001:db8::10']);
      expect(configuration.comment, 'Storage network');
      expect(configuration.toApiJson()['listen'], [
        {'ip': '10.0.0.10'},
        {'ip': '2001:db8::10'},
      ]);
    });

    test('defaults to the first server-provided listen address', () {
      final configuration = IscsiPortalConfiguration.defaults(const [
        '192.0.2.15',
        '0.0.0.0',
      ]);

      expect(configuration.listenAddresses, ['192.0.2.15']);
      expect(configuration.comment, isEmpty);
      expect(
        IscsiPortalConfiguration.defaults(const []).listenAddresses,
        isEmpty,
      );
    });

    test('rejects missing, duplicate, invalid, and unavailable addresses', () {
      expect(
        const IscsiPortalConfiguration(
          listenAddresses: [],
          comment: '',
        ).validate(),
        containsPair('listen', isA<IscsiPortalValidationCode>()),
      );
      expect(
        const IscsiPortalConfiguration(
          listenAddresses: ['10.0.0.10', '10.0.0.10'],
          comment: '',
        ).validate(),
        containsPair('listen', isA<IscsiPortalValidationCode>()),
      );
      expect(
        const IscsiPortalConfiguration(
          listenAddresses: ['not-an-address'],
          comment: '',
        ).validate(),
        containsPair('listen', isA<IscsiPortalValidationCode>()),
      );
      expect(
        const IscsiPortalConfiguration(
          listenAddresses: ['10.0.0.11'],
          comment: '',
        ).validate(availableAddresses: const ['10.0.0.10']),
        containsPair('listen', isA<IscsiPortalValidationCode>()),
      );
    });
  });

  group('IscsiInitiatorConfiguration', () {
    test('serializes the documented initiator payload exactly', () {
      const configuration = IscsiInitiatorConfiguration(
        initiators: [
          'iqn.2026-08.me.aroxu:client-one',
          'iqn.2026-08.me.aroxu:client-two',
        ],
        comment: '  Build clients  ',
      );

      expect(configuration.toApiJson(), {
        'initiators': [
          'iqn.2026-08.me.aroxu:client-one',
          'iqn.2026-08.me.aroxu:client-two',
        ],
        'comment': 'Build clients',
      });
      expect(configuration.validate(), isEmpty);
      expect(configuration.allowsAll, isFalse);
    });

    test('restores an existing initiator group', () {
      final initiator = IscsiInitiator.fromJson({
        'id': 8,
        'initiators': ['iqn.2026-08.me.aroxu:client-one', '192.0.2.25'],
        'comment': 'Build clients',
      });

      final configuration = IscsiInitiatorConfiguration.fromInitiator(
        initiator,
      );

      expect(configuration.initiators, [
        'iqn.2026-08.me.aroxu:client-one',
        '192.0.2.25',
      ]);
      expect(configuration.comment, 'Build clients');
    });

    test('empty defaults allow every initiator', () {
      final configuration = IscsiInitiatorConfiguration.defaults();

      expect(configuration.initiators, isEmpty);
      expect(configuration.allowsAll, isTrue);
      expect(configuration.validate(), isEmpty);
    });

    test('rejects duplicate, empty, and whitespace-containing entries', () {
      for (final initiators in <List<String>>[
        ['iqn.example:client', 'iqn.example:client'],
        [''],
        ['iqn.example:client one'],
      ]) {
        expect(
          IscsiInitiatorConfiguration(
            initiators: initiators,
            comment: '',
          ).validate(),
          containsPair('initiators', isA<IscsiInitiatorValidationCode>()),
        );
      }
    });
  });
}
