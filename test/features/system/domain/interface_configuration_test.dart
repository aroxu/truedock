import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/interface_configuration.dart';

const _static = InterfaceConfiguration(
  id: 'eno1',
  name: 'eno1',
  description: 'LAN',
  ipv4Dhcp: false,
  aliases: [InterfaceAlias(address: '192.168.1.10', netmask: 24)],
  mtu: 1500,
);

void main() {
  group('InterfaceAlias', () {
    test('toApiJson uses an integer CIDR prefix and the type field', () {
      const alias = InterfaceAlias(address: '10.0.0.5', netmask: 8);
      expect(alias.toApiJson(), {
        'address': '10.0.0.5',
        'netmask': 8,
        'type': 'INET',
      });
    });

    test('fromJson coerces a string netmask to an int', () {
      final alias = InterfaceAlias.fromJson(const {
        'address': '10.0.0.5',
        'netmask': '16',
        'type': 'INET',
      });
      expect(alias.netmask, 16);
    });

    test('recognises IPv6 aliases', () {
      const alias = InterfaceAlias(
        address: 'fd00::10',
        netmask: 64,
        type: 'INET6',
      );
      expect(alias.isIpv6, isTrue);
      expect(alias.label, 'fd00::10/64');
    });
  });

  group('fromJson', () {
    test('seeds the configured values, not just the live state', () {
      final config = InterfaceConfiguration.fromJson(const {
        'id': 'eno1',
        'name': 'eno1',
        'description': 'LAN',
        'ipv4_dhcp': false,
        'mtu': 9000,
        'aliases': [
          {'address': '192.168.1.10', 'netmask': 24, 'type': 'INET'},
          {'address': 'fd00::10', 'netmask': 64, 'type': 'INET6'},
        ],
      });
      expect(config.id, 'eno1');
      expect(config.ipv4Dhcp, isFalse);
      expect(config.mtu, 9000);
      expect(config.aliases.length, 2);
      expect(config.aliases.last.isIpv6, isTrue);
    });

    test('drops aliases without an address', () {
      final config = InterfaceConfiguration.fromJson(const {
        'id': 'eno1',
        'name': 'eno1',
        'aliases': [
          {'address': '', 'netmask': 24},
          {'address': '10.0.0.1', 'netmask': 24},
        ],
      });
      expect(config.aliases.length, 1);
      expect(config.aliases.single.address, '10.0.0.1');
    });
  });

  group('toApiJson', () {
    test('sends aliases and mtu for a static interface', () {
      final json = _static.toApiJson();
      expect(json['ipv4_dhcp'], false);
      expect(json['mtu'], 1500);
      expect(json['aliases'], [
        {'address': '192.168.1.10', 'netmask': 24, 'type': 'INET'},
      ]);
    });

    test('clears aliases while DHCP is on', () {
      final json = _static.copyWith(ipv4Dhcp: true).toApiJson();
      expect(json['ipv4_dhcp'], true);
      expect(json['aliases'], isEmpty);
    });

    test('omits mtu when unset so the server keeps its default', () {
      final json = _static.copyWith(clearMtu: true).toApiJson();
      expect(json.containsKey('mtu'), isFalse);
    });
  });

  group('differsFrom', () {
    test('is false for an untouched configuration', () {
      expect(_static.differsFrom(_static), isFalse);
    });

    test('detects a DHCP toggle, mtu change, and alias edits', () {
      expect(_static.copyWith(ipv4Dhcp: true).differsFrom(_static), isTrue);
      expect(_static.copyWith(mtu: 9000).differsFrom(_static), isTrue);
      expect(_static.copyWith(aliases: const []).differsFrom(_static), isTrue);
      expect(
        _static
            .copyWith(
              aliases: const [
                InterfaceAlias(address: '192.168.1.11', netmask: 24),
              ],
            )
            .differsFrom(_static),
        isTrue,
      );
    });
  });

  group('validate', () {
    test('accepts a valid static configuration', () {
      expect(validateInterfaceConfiguration(_static), isEmpty);
    });

    test('accepts DHCP with no aliases', () {
      final config = _static.copyWith(ipv4Dhcp: true, aliases: const []);
      expect(validateInterfaceConfiguration(config), isEmpty);
    });

    test('requires at least one address when DHCP is off', () {
      final config = _static.copyWith(aliases: const []);
      expect(validateInterfaceConfiguration(config)['aliases'], isNotNull);
    });

    test('rejects an invalid address', () {
      final config = _static.copyWith(
        aliases: const [InterfaceAlias(address: '999.1.1.1', netmask: 24)],
      );
      expect(validateInterfaceConfiguration(config)['aliases'], isNotNull);
    });

    test('rejects an out-of-range IPv4 prefix', () {
      final config = _static.copyWith(
        aliases: const [InterfaceAlias(address: '10.0.0.1', netmask: 40)],
      );
      expect(validateInterfaceConfiguration(config)['aliases'], isNotNull);
    });

    test('allows an IPv6 prefix above 32', () {
      final config = _static.copyWith(
        aliases: const [
          InterfaceAlias(address: 'fd00::10', netmask: 64, type: 'INET6'),
        ],
      );
      expect(validateInterfaceConfiguration(config), isEmpty);
    });

    test('rejects duplicate addresses', () {
      final config = _static.copyWith(
        aliases: const [
          InterfaceAlias(address: '10.0.0.1', netmask: 24),
          InterfaceAlias(address: '10.0.0.1', netmask: 24),
        ],
      );
      expect(
        validateInterfaceConfiguration(config)['aliases'],
        isA<InterfaceValidationIssue>().having(
          (e) => e.code,
          'code',
          InterfaceValidationCode.aliasDuplicate,
        ),
      );
    });

    test('rejects an out-of-range MTU', () {
      expect(
        validateInterfaceConfiguration(_static.copyWith(mtu: 10))['mtu'],
        isNotNull,
      );
      expect(
        validateInterfaceConfiguration(_static.copyWith(mtu: 99999))['mtu'],
        isNotNull,
      );
    });

    test('skips alias validation entirely while DHCP is on', () {
      final config = _static.copyWith(
        ipv4Dhcp: true,
        aliases: const [InterfaceAlias(address: 'bogus', netmask: 99)],
      );
      expect(validateInterfaceConfiguration(config), isEmpty);
    });
  });

  group('isValidIpAddress', () {
    test('accepts valid IPv4 and rejects malformed input', () {
      expect(isValidIpAddress('192.168.1.1', ipv6: false), isTrue);
      expect(isValidIpAddress('256.1.1.1', ipv6: false), isFalse);
      expect(isValidIpAddress('1.1.1', ipv6: false), isFalse);
      expect(isValidIpAddress('', ipv6: false), isFalse);
    });

    test('accepts valid IPv6 and rejects malformed input', () {
      expect(isValidIpAddress('fd00::10', ipv6: true), isTrue);
      expect(isValidIpAddress('192.168.1.1', ipv6: true), isFalse);
      expect(isValidIpAddress('fd00::zzzz', ipv6: true), isFalse);
    });
  });
}
