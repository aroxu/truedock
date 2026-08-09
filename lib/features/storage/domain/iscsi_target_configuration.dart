import 'dart:io';

import '../../resources/domain/server_resources.dart';

const Set<String> _supportedAuthMethods = {'NONE', 'CHAP', 'CHAP_MUTUAL'};

class IscsiTargetGroupConfiguration {
  const IscsiTargetGroupConfiguration({
    required this.portalId,
    required this.authMethod,
    this.initiatorId,
    this.authId,
  });

  factory IscsiTargetGroupConfiguration.defaults({required int portalId}) =>
      IscsiTargetGroupConfiguration(portalId: portalId, authMethod: 'NONE');

  factory IscsiTargetGroupConfiguration.fromGroup(IscsiTargetGroup group) =>
      IscsiTargetGroupConfiguration(
        portalId: group.portalId,
        initiatorId: group.initiatorId,
        authMethod: group.authMethod,
        authId: group.authId,
      );

  final int portalId;
  final int? initiatorId;
  final String authMethod;
  final int? authId;

  Map<String, Object?> toApiJson() => {
    'portal': portalId,
    'initiator': initiatorId,
    'authmethod': authMethod,
    'auth': authMethod == 'NONE' ? null : authId,
  };
}

class IscsiTargetConfiguration {
  const IscsiTargetConfiguration({
    required this.name,
    required this.alias,
    required this.groups,
    required this.authNetworks,
    required this.queuedCommands,
  });

  factory IscsiTargetConfiguration.defaults({IscsiPortal? portal}) =>
      IscsiTargetConfiguration(
        name: '',
        alias: null,
        groups: portal == null
            ? const []
            : [IscsiTargetGroupConfiguration.defaults(portalId: portal.id)],
        authNetworks: const [],
        queuedCommands: null,
      );

  factory IscsiTargetConfiguration.fromTarget(IscsiTarget target) =>
      IscsiTargetConfiguration(
        name: target.name,
        alias: target.alias,
        groups: target.groups
            .map(IscsiTargetGroupConfiguration.fromGroup)
            .toList(growable: false),
        authNetworks: List.unmodifiable(target.authNetworks),
        queuedCommands: target.queuedCommands,
      );

  final String name;
  final String? alias;
  final List<IscsiTargetGroupConfiguration> groups;
  final List<String> authNetworks;
  final int? queuedCommands;

  Map<String, Object?> toApiJson() => {
    'name': name.trim(),
    'alias': _nullIfEmpty(alias),
    'mode': 'ISCSI',
    'groups': groups.map((group) => group.toApiJson()).toList(growable: false),
    'auth_networks': authNetworks,
    'iscsi_parameters': queuedCommands == null
        ? null
        : <String, Object?>{'QueuedCommands': queuedCommands},
  };

  Map<String, String> validate({
    List<IscsiPortal>? availablePortals,
    List<IscsiInitiator>? availableInitiators,
  }) {
    final errors = <String, String>{};
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 120) {
      errors['name'] = 'Enter a target name between 1 and 120 characters.';
    }

    final portalIds = availablePortals?.map((portal) => portal.id).toSet();
    final initiatorIds = availableInitiators
        ?.map((initiator) => initiator.id)
        .toSet();
    final groupTuples = <(int, int?, String, int?)>{};
    var groupsAreValid = true;
    for (final group in groups) {
      final authMethodIsValid = _supportedAuthMethods.contains(
        group.authMethod,
      );
      final authPairIsValid = group.authMethod == 'NONE'
          ? group.authId == null
          : authMethodIsValid && group.authId != null;
      final tuple = (
        group.portalId,
        group.initiatorId,
        group.authMethod,
        group.authId,
      );
      if ((portalIds != null && !portalIds.contains(group.portalId)) ||
          (group.initiatorId != null &&
              initiatorIds != null &&
              !initiatorIds.contains(group.initiatorId)) ||
          !authMethodIsValid ||
          !authPairIsValid ||
          !groupTuples.add(tuple)) {
        groupsAreValid = false;
      }
    }
    if (!groupsAreValid) {
      errors['groups'] =
          'Use available portals and initiators with unique, valid authentication groups.';
    }

    if (authNetworks.toSet().length != authNetworks.length ||
        authNetworks.any((network) => !_isCidr(network))) {
      errors['authNetworks'] =
          'Use unique IPv4 or IPv6 networks in CIDR notation.';
    }

    if (queuedCommands != null &&
        queuedCommands != 32 &&
        queuedCommands != 128) {
      errors['queuedCommands'] = 'Queued commands must be 32 or 128.';
    }
    return errors;
  }
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _isCidr(String value) {
  final parts = value.split('/');
  if (parts.length != 2) return false;
  final address = InternetAddress.tryParse(parts.first);
  final prefix = int.tryParse(parts.last);
  if (address == null || prefix == null) return false;
  return address.type == InternetAddressType.IPv4
      ? prefix >= 0 && prefix <= 32
      : prefix >= 0 && prefix <= 128;
}
