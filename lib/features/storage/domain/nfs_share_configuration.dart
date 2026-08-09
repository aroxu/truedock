import 'dart:io';

import '../../resources/domain/server_resources.dart';

/// Stable validation codes for NFS share configuration. The presentation
/// layer maps each code to a localized message.
enum NfsValidationCode { path, networksCount, networksFormat, hosts, mapping }

enum NfsSecurity { sys, krb5, krb5i, krb5p }

extension NfsSecurityApi on NfsSecurity {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    NfsSecurity.sys => 'SYS',
    NfsSecurity.krb5 => 'Kerberos',
    NfsSecurity.krb5i => 'Kerberos + integrity',
    NfsSecurity.krb5p => 'Kerberos + privacy',
  };

  static NfsSecurity? fromApi(String value) {
    for (final security in NfsSecurity.values) {
      if (security.apiValue == value) return security;
    }
    return null;
  }
}

class NfsShareConfiguration {
  const NfsShareConfiguration({
    required this.path,
    required this.comment,
    required this.networks,
    required this.hosts,
    required this.readOnly,
    required this.mapRootUser,
    required this.mapRootGroup,
    required this.mapAllUser,
    required this.mapAllGroup,
    required this.security,
    required this.enabled,
    required this.exposeSnapshots,
  });

  factory NfsShareConfiguration.defaults() => const NfsShareConfiguration(
    path: '',
    comment: '',
    networks: [],
    hosts: [],
    readOnly: false,
    mapRootUser: null,
    mapRootGroup: null,
    mapAllUser: null,
    mapAllGroup: null,
    security: {},
    enabled: true,
    exposeSnapshots: false,
  );

  factory NfsShareConfiguration.fromShare(NfsShare share) =>
      NfsShareConfiguration(
        path: share.path,
        comment: share.comment ?? '',
        networks: share.networks,
        hosts: share.hosts,
        readOnly: share.readOnly,
        mapRootUser: share.mapRootUser,
        mapRootGroup: share.mapRootGroup,
        mapAllUser: share.mapAllUser,
        mapAllGroup: share.mapAllGroup,
        security: share.security
            .map(NfsSecurityApi.fromApi)
            .whereType<NfsSecurity>()
            .toSet(),
        enabled: share.enabled,
        exposeSnapshots: share.exposeSnapshots,
      );

  final String path;
  final String comment;
  final List<String> networks;
  final List<String> hosts;
  final bool readOnly;
  final String? mapRootUser;
  final String? mapRootGroup;
  final String? mapAllUser;
  final String? mapAllGroup;
  final Set<NfsSecurity> security;
  final bool enabled;
  final bool exposeSnapshots;

  Map<String, Object?> toApiJson() => {
    'path': path,
    'aliases': <String>[],
    'comment': comment,
    'networks': networks,
    'hosts': hosts,
    'ro': readOnly,
    'maproot_user': _nullIfEmpty(mapRootUser),
    'maproot_group': _nullIfEmpty(mapRootGroup),
    'mapall_user': _nullIfEmpty(mapAllUser),
    'mapall_group': _nullIfEmpty(mapAllGroup),
    'security': NfsSecurity.values
        .where(security.contains)
        .map((value) => value.apiValue)
        .toList(growable: false),
    'enabled': enabled,
    'expose_snapshots': exposeSnapshots,
  };

  Map<String, NfsValidationCode> validate() {
    final errors = <String, NfsValidationCode>{};
    if (!path.startsWith('/mnt/')) {
      errors['path'] = NfsValidationCode.path;
    }
    if (networks.length > 42) {
      errors['networks'] = NfsValidationCode.networksCount;
    } else if (networks.toSet().length != networks.length ||
        networks.any((network) => !_isCidr(network))) {
      errors['networks'] = NfsValidationCode.networksFormat;
    }
    if (hosts.toSet().length != hosts.length ||
        hosts.any(
          (host) =>
              host.isEmpty ||
              host.contains(RegExp(r'\s')) ||
              host.contains('"') ||
              host.contains("'"),
        )) {
      errors['hosts'] = NfsValidationCode.hosts;
    }
    final hasRootMapping =
        _nullIfEmpty(mapRootUser) != null || _nullIfEmpty(mapRootGroup) != null;
    final hasAllMapping =
        _nullIfEmpty(mapAllUser) != null || _nullIfEmpty(mapAllGroup) != null;
    if (hasRootMapping && hasAllMapping) {
      errors['mapping'] = NfsValidationCode.mapping;
    }
    return errors;
  }

  bool get unrestricted => networks.isEmpty && hosts.isEmpty;
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _isCidr(String value) {
  final parts = value.split('/');
  if (parts.length != 2) return false;
  final address = InternetAddress.tryParse(parts[0]);
  final prefix = int.tryParse(parts[1]);
  if (address == null || prefix == null) return false;
  return address.type == InternetAddressType.IPv4
      ? prefix >= 0 && prefix <= 32
      : prefix >= 0 && prefix <= 128;
}
