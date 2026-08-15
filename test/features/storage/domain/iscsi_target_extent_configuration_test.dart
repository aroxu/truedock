import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_extent_configuration.dart';

void main() {
  group('IscsiTargetExtentConfiguration', () {
    test('defaults to automatic LUN assignment', () {
      final configuration = IscsiTargetExtentConfiguration.defaults(
        targetId: 3,
        extentId: 7,
      );

      expect(configuration.targetId, 3);
      expect(configuration.extentId, 7);
      expect(configuration.lunId, isNull);
      expect(configuration.validate(), isEmpty);
    });

    test('restores an existing target-extent association', () {
      final targetExtent = IscsiTargetExtent.fromJson({
        'id': 19,
        'target': 3,
        'extent': 7,
        'lunid': 2,
      });

      final configuration = IscsiTargetExtentConfiguration.fromTargetExtent(
        targetExtent,
      );

      expect(configuration.targetId, 3);
      expect(configuration.extentId, 7);
      expect(configuration.lunId, 2);
    });

    test('serializes create payload with nullable automatic LUN', () {
      final automatic = IscsiTargetExtentConfiguration.defaults(
        targetId: 3,
        extentId: 7,
      );
      const explicit = IscsiTargetExtentConfiguration(
        targetId: 3,
        extentId: 7,
        lunId: 4,
      );

      expect(automatic.toCreateApiJson(), {
        'target': 3,
        'extent': 7,
        'lunid': null,
      });
      expect(explicit.toCreateApiJson(), {
        'target': 3,
        'extent': 7,
        'lunid': 4,
      });
    });

    test('serializes update payload without id or nullable lunid', () {
      final automatic = IscsiTargetExtentConfiguration.defaults(
        targetId: 5,
        extentId: 9,
      );
      const explicit = IscsiTargetExtentConfiguration(
        targetId: 5,
        extentId: 9,
        lunId: 0,
      );

      expect(automatic.toUpdateApiJson(), {'target': 5, 'extent': 9});
      expect(explicit.toUpdateApiJson(), {
        'target': 5,
        'extent': 9,
        'lunid': 0,
      });
      expect(explicit.toUpdateApiJson(), isNot(contains('id')));
    });

    test('validates server choices and nonnegative identifiers', () {
      const unavailable = IscsiTargetExtentConfiguration(
        targetId: 3,
        extentId: 7,
        lunId: null,
      );
      const negative = IscsiTargetExtentConfiguration(
        targetId: -1,
        extentId: -2,
        lunId: -3,
      );

      expect(
        unavailable
            .validate(
              availableTargetIds: const [4, 5],
              availableExtentIds: const [8, 9],
            )
            .keys,
        {'target', 'extent'},
      );
      expect(negative.validate().keys, {'target', 'extent', 'lunid'});
    });

    test(
      'accepts IDs offered by the server without an invented upper bound',
      () {
        const configuration = IscsiTargetExtentConfiguration(
          targetId: 1000000,
          extentId: 2000000,
          lunId: 3000000,
        );

        expect(
          configuration.validate(
            availableTargetIds: const [1000000],
            availableExtentIds: const [2000000],
          ),
          isEmpty,
        );
      },
    );
  });
}
