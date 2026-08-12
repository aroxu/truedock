import 'package:flutter/foundation.dart';

/// Stable codes for interface configuration validation failures.
enum InterfaceValidationCode {
  mtuRange,
  aliasesRequired,
  aliasAddressInvalid,
  aliasPrefixRange,
  aliasDuplicate,
}

/// Context attached to an [InterfaceValidationCode] so presentation layers can
/// translate the message without parsing the English fallback.
@immutable
class InterfaceValidationContext {
  const InterfaceValidationContext({this.address, this.maxPrefix, this.ipv6});

  final String? address;
  final int? maxPrefix;
  final bool? ipv6;
}

/// A typed validation issue for an interface configuration.
@immutable
class InterfaceValidationIssue {
  const InterfaceValidationIssue(this.code, this.context);

  final InterfaceValidationCode code;
  final InterfaceValidationContext context;
}

/// A static address assigned to a network interface.
///
/// `interface.update` takes aliases as `{address, netmask, type}` objects where
/// `netmask` is the CIDR prefix length (an integer, not a dotted mask) and
/// `type` is `INET` for IPv4 or `INET6` for IPv6.
@immutable
class InterfaceAlias {
  const InterfaceAlias({
    required this.address,
    required this.netmask,
    this.type = 'INET',
  });

  factory InterfaceAlias.fromJson(Map<String, dynamic> json) {
    final rawNetmask = json['netmask'];
    return InterfaceAlias(
      address: json['address'] is String ? json['address'] as String : '',
      netmask: rawNetmask is num
          ? rawNetmask.toInt()
          : int.tryParse('$rawNetmask') ?? 24,
      type: json['type'] is String ? json['type'] as String : 'INET',
    );
  }

  final String address;

  /// CIDR prefix length, e.g. 24 for a /24 IPv4 network.
  final int netmask;

  /// `INET` (IPv4) or `INET6` (IPv6).
  final String type;

  bool get isIpv6 => type == 'INET6';

  String get label => '$address/$netmask';

  Map<String, Object?> toApiJson() => {
    'address': address,
    'netmask': netmask,
    'type': type,
  };

  InterfaceAlias copyWith({String? address, int? netmask, String? type}) =>
      InterfaceAlias(
        address: address ?? this.address,
        netmask: netmask ?? this.netmask,
        type: type ?? this.type,
      );
}

/// Configuration collected by the interface editor and sent to
/// `interface.update`.
///
/// Changes are staged: TrueNAS applies them only after `interface.commit`,
/// and reverts them unless `interface.checkin` runs inside the verification
/// window. The caller must run that workflow after saving.
@immutable
class InterfaceConfiguration {
  const InterfaceConfiguration({
    required this.id,
    required this.name,
    this.description = '',
    required this.ipv4Dhcp,
    this.aliases = const [],
    this.mtu,
  });

  /// Seeds a configuration from an `interface.query` row.
  factory InterfaceConfiguration.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    return InterfaceConfiguration(
      id: json['id'] is String
          ? json['id'] as String
          : (json['name'] is String ? json['name'] as String : ''),
      name: json['name'] is String ? json['name'] as String : '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      ipv4Dhcp: json['ipv4_dhcp'] == true,
      aliases: rawAliases is List
          ? rawAliases
                .whereType<Map<String, dynamic>>()
                .map(InterfaceAlias.fromJson)
                .where((alias) => alias.address.isNotEmpty)
                .toList(growable: false)
          : const <InterfaceAlias>[],
      mtu: json['mtu'] is num ? (json['mtu'] as num).toInt() : null,
    );
  }

  final String id;
  final String name;
  final String description;

  /// Only one interface on the system may use DHCP.
  final bool ipv4Dhcp;

  /// Static addresses. Ignored by the server while DHCP is on.
  final List<InterfaceAlias> aliases;

  /// Null leaves the MTU unset so the interface keeps the default (1500).
  final int? mtu;

  /// Payload for `interface.update`.
  ///
  /// Aliases are sent as an empty list while DHCP is on, because a static
  /// address and DHCP on the same interface is contradictory. `mtu` is only
  /// included when set so the server keeps its default otherwise.
  Map<String, Object?> toApiJson() => {
    'description': description,
    'ipv4_dhcp': ipv4Dhcp,
    'aliases': ipv4Dhcp
        ? const <Map<String, Object?>>[]
        : aliases.map((alias) => alias.toApiJson()).toList(),
    if (mtu != null) 'mtu': mtu,
  };

  InterfaceConfiguration copyWith({
    String? id,
    String? name,
    String? description,
    bool? ipv4Dhcp,
    List<InterfaceAlias>? aliases,
    int? mtu,
    bool clearMtu = false,
  }) => InterfaceConfiguration(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    ipv4Dhcp: ipv4Dhcp ?? this.ipv4Dhcp,
    aliases: aliases ?? this.aliases,
    mtu: clearMtu ? null : (mtu ?? this.mtu),
  );

  /// True when the editor would change anything the server stores.
  bool differsFrom(InterfaceConfiguration baseline) {
    if (description != baseline.description) return true;
    if (ipv4Dhcp != baseline.ipv4Dhcp) return true;
    if (mtu != baseline.mtu) return true;
    if (aliases.length != baseline.aliases.length) return true;
    for (var i = 0; i < aliases.length; i++) {
      final a = aliases[i];
      final b = baseline.aliases[i];
      if (a.address != b.address ||
          a.netmask != b.netmask ||
          a.type != b.type) {
        return true;
      }
    }
    return false;
  }
}

/// Validates an [InterfaceConfiguration]. Returns field-keyed errors.
Map<String, InterfaceValidationIssue> validateInterfaceConfiguration(
  InterfaceConfiguration config,
) {
  final errors = <String, InterfaceValidationIssue>{};
  final mtu = config.mtu;
  if (mtu != null && (mtu < 68 || mtu > 9216)) {
    errors['mtu'] = const InterfaceValidationIssue(
      InterfaceValidationCode.mtuRange,
      InterfaceValidationContext(),
    );
  }
  if (!config.ipv4Dhcp) {
    if (config.aliases.isEmpty) {
      errors['aliases'] = const InterfaceValidationIssue(
        InterfaceValidationCode.aliasesRequired,
        InterfaceValidationContext(),
      );
    }
    final seen = <String>{};
    for (final alias in config.aliases) {
      if (!isValidIpAddress(alias.address, ipv6: alias.isIpv6)) {
        errors['aliases'] = InterfaceValidationIssue(
          InterfaceValidationCode.aliasAddressInvalid,
          InterfaceValidationContext(ipv6: alias.isIpv6),
        );
        break;
      }
      final maxPrefix = alias.isIpv6 ? 128 : 32;
      if (alias.netmask < 1 || alias.netmask > maxPrefix) {
        errors['aliases'] = InterfaceValidationIssue(
          InterfaceValidationCode.aliasPrefixRange,
          InterfaceValidationContext(
            address: alias.address,
            maxPrefix: maxPrefix,
          ),
        );
        break;
      }
      if (!seen.add(alias.address)) {
        errors['aliases'] = InterfaceValidationIssue(
          InterfaceValidationCode.aliasDuplicate,
          InterfaceValidationContext(address: alias.address),
        );
        break;
      }
    }
  }
  return errors;
}

/// Minimal address check. TrueNAS performs authoritative validation, so this
/// only catches obvious mistakes before the round-trip.
bool isValidIpAddress(String value, {required bool ipv6}) {
  if (value.isEmpty) return false;
  if (ipv6) {
    if (!value.contains(':')) return false;
    final groups = value.split(':');
    if (groups.length > 8) return false;
    for (final group in groups) {
      if (group.isEmpty) continue;
      if (group.length > 4) return false;
      if (int.tryParse(group, radix: 16) == null) return false;
    }
    return true;
  }
  final octets = value.split('.');
  if (octets.length != 4) return false;
  for (final octet in octets) {
    final n = int.tryParse(octet);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}
