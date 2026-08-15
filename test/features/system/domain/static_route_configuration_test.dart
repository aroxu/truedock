import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/static_route_configuration.dart';

void main() {
  group('StaticRouteConfiguration', () {
    test('toApiJson omits an empty description', () {
      const config = StaticRouteConfiguration(
        destination: '10.0.0.0/24',
        gateway: '10.0.0.1',
      );
      expect(config.toApiJson(), {
        'destination': '10.0.0.0/24',
        'gateway': '10.0.0.1',
      });
    });

    test('toApiJson includes a non-empty description', () {
      const config = StaticRouteConfiguration(
        destination: '10.0.0.0/24',
        gateway: '10.0.0.1',
        description: 'Lab network',
      );
      expect(config.toApiJson(), {
        'destination': '10.0.0.0/24',
        'gateway': '10.0.0.1',
        'description': 'Lab network',
      });
    });

    test('fromJson seeds id, destination, gateway, description', () {
      final config = StaticRouteConfiguration.fromJson({
        'id': 4,
        'destination': '172.16.0.0/12',
        'gateway': '10.0.0.1',
        'description': 'Private range',
      });
      expect(config.id, 4);
      expect(config.destination, '172.16.0.0/12');
      expect(config.gateway, '10.0.0.1');
      expect(config.description, 'Private range');
    });

    test('isCreate is true only when id is null', () {
      const withoutId = StaticRouteConfiguration(
        destination: '10.0.0.0/24',
        gateway: '10.0.0.1',
      );
      expect(withoutId.isCreate, isTrue);
      const withId = StaticRouteConfiguration(
        id: 1,
        destination: '10.0.0.0/24',
        gateway: '10.0.0.1',
      );
      expect(withId.isCreate, isFalse);
    });

    test('copyWith preserves untouched fields', () {
      const base = StaticRouteConfiguration(
        id: 5,
        destination: '10.0.0.0/24',
        gateway: '10.0.0.1',
        description: 'Original',
      );
      final next = base.copyWith(gateway: '10.0.0.254');
      expect(next.id, 5);
      expect(next.destination, '10.0.0.0/24');
      expect(next.gateway, '10.0.0.254');
      expect(next.description, 'Original');
    });
  });

  group('validateStaticRouteConfiguration', () {
    test('accepts a valid IPv4 CIDR and gateway', () {
      const config = StaticRouteConfiguration(
        destination: '192.168.1.0/24',
        gateway: '10.0.0.1',
      );
      expect(validateStaticRouteConfiguration(config), isEmpty);
    });

    test('rejects an empty destination', () {
      const config = StaticRouteConfiguration(
        destination: '',
        gateway: '10.0.0.1',
      );
      final errors = validateStaticRouteConfiguration(config);
      expect(
        errors['destination'],
        StaticRouteValidationCode.destinationRequired,
      );
    });

    test('rejects a destination without a prefix', () {
      const config = StaticRouteConfiguration(
        destination: '192.168.1.0',
        gateway: '10.0.0.1',
      );
      final errors = validateStaticRouteConfiguration(config);
      expect(
        errors['destination'],
        StaticRouteValidationCode.destinationInvalid,
      );
    });

    test('rejects an out-of-range prefix', () {
      const config = StaticRouteConfiguration(
        destination: '192.168.1.0/99',
        gateway: '10.0.0.1',
      );
      final errors = validateStaticRouteConfiguration(config);
      expect(
        errors['destination'],
        StaticRouteValidationCode.destinationInvalid,
      );
    });

    test('rejects a non-IP gateway', () {
      const config = StaticRouteConfiguration(
        destination: '192.168.1.0/24',
        gateway: 'not-an-ip',
      );
      final errors = validateStaticRouteConfiguration(config);
      expect(errors['gateway'], StaticRouteValidationCode.gatewayInvalid);
    });

    test('accepts an IPv6 destination and gateway', () {
      const config = StaticRouteConfiguration(
        destination: 'fd00::/64',
        gateway: 'fd00::1',
      );
      expect(validateStaticRouteConfiguration(config), isEmpty);
    });
  });
}
