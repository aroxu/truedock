import 'package:meta/meta.dart';

/// Stable codes for global network validation failures, so the domain layer can
/// reject a payload without a `BuildContext` to localize the reason.
enum NetworkValidationCode {
  hostnameRequired,
  hostnameInvalid,
  domainInvalid,
  gatewayInvalid,
  ipv6GatewayInvalid,
  nameserverInvalid,
  proxyInvalid,
}

@immutable
class NetworkValidationIssue {
  const NetworkValidationIssue(this.code);
  final NetworkValidationCode code;
}

/// `network.configuration.config`: the server's global network settings.
///
/// The response carries two distinct sets of values, and conflating them would
/// be actively misleading. The top-level fields are what an administrator
/// *configured*; the nested `state` object is what is actually *in effect*. On a
/// DHCP server the configured gateway and nameservers are empty strings while
/// `state` holds the leased values, so showing only the configured side makes a
/// working server look unconfigured, and showing only the effective side makes a
/// DHCP lease look like a saved setting the user could edit.
@immutable
class NetworkConfiguration {
  const NetworkConfiguration({
    required this.hostname,
    required this.domain,
    this.ipv4Gateway = '',
    this.ipv6Gateway = '',
    this.nameserver1 = '',
    this.nameserver2 = '',
    this.nameserver3 = '',
    this.httpProxy = '',
    this.searchDomains = const [],
    this.effective = const EffectiveNetworkState(),
  });

  factory NetworkConfiguration.fromJson(Map<String, dynamic> json) {
    String text(Object? value) => value is String ? value : '';
    final state = json['state'];
    return NetworkConfiguration(
      hostname: text(json['hostname']),
      domain: text(json['domain']),
      ipv4Gateway: text(json['ipv4gateway']),
      ipv6Gateway: text(json['ipv6gateway']),
      nameserver1: text(json['nameserver1']),
      nameserver2: text(json['nameserver2']),
      nameserver3: text(json['nameserver3']),
      httpProxy: text(json['httpproxy']),
      searchDomains: json['domains'] is List
          ? (json['domains'] as List).whereType<String>().toList(
              growable: false,
            )
          : const [],
      effective: state is Map<String, dynamic>
          ? EffectiveNetworkState.fromJson(state)
          : const EffectiveNetworkState(),
    );
  }

  final String hostname;
  final String domain;
  final String ipv4Gateway;
  final String ipv6Gateway;
  final String nameserver1;
  final String nameserver2;
  final String nameserver3;
  final String httpProxy;
  final List<String> searchDomains;

  /// What the system is actually using, which on DHCP differs from the fields
  /// above.
  final EffectiveNetworkState effective;

  /// Configured nameservers, in server order, with blanks removed.
  List<String> get nameservers => [
    nameserver1,
    nameserver2,
    nameserver3,
  ].where((value) => value.isNotEmpty).toList(growable: false);

  /// True when nothing is statically configured, so the values in effect came
  /// from DHCP and editing a field here overrides the lease.
  bool get isDhcpDerived =>
      ipv4Gateway.isEmpty &&
      ipv6Gateway.isEmpty &&
      nameservers.isEmpty &&
      (effective.ipv4Gateway.isNotEmpty ||
          effective.ipv6Gateway.isNotEmpty ||
          effective.nameservers.isNotEmpty);
}

/// The nested `state` object: values currently applied to the system.
@immutable
class EffectiveNetworkState {
  const EffectiveNetworkState({
    this.ipv4Gateway = '',
    this.ipv6Gateway = '',
    this.nameservers = const [],
  });

  factory EffectiveNetworkState.fromJson(Map<String, dynamic> json) {
    String text(Object? value) => value is String ? value : '';
    return EffectiveNetworkState(
      ipv4Gateway: text(json['ipv4gateway']),
      ipv6Gateway: text(json['ipv6gateway']),
      nameservers: [
        for (final key in const ['nameserver1', 'nameserver2', 'nameserver3'])
          if (text(json[key]).isNotEmpty) text(json[key]),
      ],
    );
  }

  final String ipv4Gateway;
  final String ipv6Gateway;
  final List<String> nameservers;
}

/// A global network edit, for `network.configuration.update`.
///
/// Only changed fields are emitted. The method accepts a partial object, and
/// resending everything would rewrite `activity` and `service_announcement`,
/// which TrueDock does not surface.
@immutable
class NetworkConfigurationEdit {
  const NetworkConfigurationEdit({
    this.hostname,
    this.domain,
    this.ipv4Gateway,
    this.ipv6Gateway,
    this.nameserver1,
    this.nameserver2,
    this.nameserver3,
    this.httpProxy,
  });

  /// Builds an edit carrying only what differs from [baseline].
  factory NetworkConfigurationEdit.diff({
    required NetworkConfiguration baseline,
    required String hostname,
    required String domain,
    required String ipv4Gateway,
    String? ipv6Gateway,
    required String nameserver1,
    required String nameserver2,
    required String nameserver3,
    required String httpProxy,
  }) => NetworkConfigurationEdit(
    hostname: hostname == baseline.hostname ? null : hostname,
    domain: domain == baseline.domain ? null : domain,
    ipv4Gateway: ipv4Gateway == baseline.ipv4Gateway ? null : ipv4Gateway,
    ipv6Gateway: ipv6Gateway == null || ipv6Gateway == baseline.ipv6Gateway
        ? null
        : ipv6Gateway,
    nameserver1: nameserver1 == baseline.nameserver1 ? null : nameserver1,
    nameserver2: nameserver2 == baseline.nameserver2 ? null : nameserver2,
    nameserver3: nameserver3 == baseline.nameserver3 ? null : nameserver3,
    httpProxy: httpProxy == baseline.httpProxy ? null : httpProxy,
  );

  final String? hostname;
  final String? domain;
  final String? ipv4Gateway;
  final String? ipv6Gateway;
  final String? nameserver1;
  final String? nameserver2;
  final String? nameserver3;
  final String? httpProxy;

  List<NetworkValidationIssue> validate() {
    final issues = <NetworkValidationIssue>[];
    final host = hostname;
    if (host != null) {
      if (host.trim().isEmpty) {
        issues.add(
          const NetworkValidationIssue(NetworkValidationCode.hostnameRequired),
        );
      } else if (!_isHostLabel(host.trim())) {
        issues.add(
          const NetworkValidationIssue(NetworkValidationCode.hostnameInvalid),
        );
      }
    }
    final domainValue = domain;
    if (domainValue != null &&
        domainValue.isNotEmpty &&
        !_isDomainName(domainValue)) {
      issues.add(
        const NetworkValidationIssue(NetworkValidationCode.domainInvalid),
      );
    }
    // An empty string is how the server is told to clear a gateway or
    // nameserver, so only a non-empty malformed value is an error.
    final gateway = ipv4Gateway;
    if (gateway != null && gateway.isNotEmpty && !_isIpv4(gateway)) {
      issues.add(
        const NetworkValidationIssue(NetworkValidationCode.gatewayInvalid),
      );
    }
    final gateway6 = ipv6Gateway;
    if (gateway6 != null && gateway6.isNotEmpty && !_isIpv6(gateway6)) {
      issues.add(
        const NetworkValidationIssue(NetworkValidationCode.ipv6GatewayInvalid),
      );
    }
    for (final nameserver in [nameserver1, nameserver2, nameserver3]) {
      if (nameserver != null &&
          nameserver.isNotEmpty &&
          !_isIpv4(nameserver) &&
          !_isIpv6(nameserver)) {
        issues.add(
          const NetworkValidationIssue(NetworkValidationCode.nameserverInvalid),
        );
        break;
      }
    }
    final proxy = httpProxy;
    if (proxy != null && proxy.isNotEmpty && Uri.tryParse(proxy) == null) {
      issues.add(
        const NetworkValidationIssue(NetworkValidationCode.proxyInvalid),
      );
    }
    return issues;
  }

  Map<String, Object?> toApiJson() => <String, Object?>{
    if (hostname != null) 'hostname': hostname!.trim(),
    if (domain != null) 'domain': domain!.trim(),
    if (ipv4Gateway != null) 'ipv4gateway': ipv4Gateway,
    if (ipv6Gateway != null) 'ipv6gateway': ipv6Gateway,
    if (nameserver1 != null) 'nameserver1': nameserver1,
    if (nameserver2 != null) 'nameserver2': nameserver2,
    if (nameserver3 != null) 'nameserver3': nameserver3,
    if (httpProxy != null) 'httpproxy': httpProxy,
  };

  bool get isEmpty => toApiJson().isEmpty;

  /// True when this edit would clear a value the system is currently using,
  /// which can sever the session TrueDock is connected over.
  bool clearsEffectiveRouting(NetworkConfiguration baseline) {
    final clearsGateway =
        ipv4Gateway != null &&
        ipv4Gateway!.isEmpty &&
        baseline.effective.ipv4Gateway.isNotEmpty;
    final clearsIpv6Gateway =
        ipv6Gateway != null &&
        ipv6Gateway!.isEmpty &&
        baseline.effective.ipv6Gateway.isNotEmpty;
    final clearsDns =
        [
          nameserver1,
          nameserver2,
          nameserver3,
        ].any((value) => value != null && value.isEmpty) &&
        baseline.effective.nameservers.isNotEmpty;
    return clearsGateway || clearsIpv6Gateway || clearsDns;
  }
}

/// `network.general.summary`: what the server is actually using right now.
///
/// Read alongside the configuration because it is authoritative regardless of
/// how the values were obtained. A DHCP server reports no configured gateway
/// yet appears here with a working default route.
@immutable
class NetworkSummary {
  const NetworkSummary({
    this.interfaces = const {},
    this.defaultRoutes = const [],
    this.nameservers = const [],
  });

  factory NetworkSummary.fromJson(Map<String, dynamic> json) {
    final interfaces = <String, List<String>>{};
    final ips = json['ips'];
    if (ips is Map) {
      for (final entry in ips.entries) {
        final families = entry.value;
        if (families is! Map) continue;
        final addresses = <String>[];
        for (final family in families.values) {
          if (family is List) addresses.addAll(family.whereType<String>());
        }
        interfaces['${entry.key}'] = addresses;
      }
    }
    List<String> strings(Object? value) => value is List
        ? value.whereType<String>().toList(growable: false)
        : const [];
    return NetworkSummary(
      interfaces: interfaces,
      defaultRoutes: strings(json['default_routes']),
      nameservers: strings(json['nameservers']),
    );
  }

  /// Addresses per interface, IPv4 and IPv6 combined in server order.
  final Map<String, List<String>> interfaces;
  final List<String> defaultRoutes;
  final List<String> nameservers;
}

bool _isHostLabel(String value) =>
    value.length <= 63 &&
    RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$').hasMatch(value);

bool _isDomainName(String value) =>
    value.length <= 253 &&
    value.split('.').every((label) => label.isNotEmpty && _isHostLabel(label));

bool _isIpv4(String value) {
  final octets = value.split('.');
  if (octets.length != 4) return false;
  for (final octet in octets) {
    final parsed = int.tryParse(octet);
    if (parsed == null || parsed < 0 || parsed > 255) return false;
    if (octet.length > 1 && octet.startsWith('0')) return false;
  }
  return true;
}

bool _isIpv6(String value) {
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
