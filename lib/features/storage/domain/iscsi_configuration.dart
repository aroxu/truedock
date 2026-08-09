import 'dart:io';

import '../../resources/domain/server_resources.dart';

/// Stable validation codes for iSCSI portal configuration.
enum IscsiPortalValidationCode {
  listenRequired,
  listenFormat,
  listenUnavailable,
}

/// Stable validation codes for iSCSI initiator group configuration.
enum IscsiInitiatorValidationCode { format }

class IscsiPortalConfiguration {
  const IscsiPortalConfiguration({
    required this.listenAddresses,
    required this.comment,
  });

  factory IscsiPortalConfiguration.defaults(List<String> choices) =>
      IscsiPortalConfiguration(
        listenAddresses: choices.isEmpty ? const [] : [choices.first],
        comment: '',
      );

  factory IscsiPortalConfiguration.fromPortal(IscsiPortal portal) =>
      IscsiPortalConfiguration(
        listenAddresses: portal.listen.map((entry) => entry.ip).toList(),
        comment: portal.comment,
      );

  final List<String> listenAddresses;
  final String comment;

  Map<String, Object?> toApiJson() => {
    'listen': listenAddresses
        .map((address) => <String, Object?>{'ip': address})
        .toList(growable: false),
    'comment': comment.trim(),
  };

  Map<String, IscsiPortalValidationCode> validate({
    List<String> availableAddresses = const [],
  }) {
    final errors = <String, IscsiPortalValidationCode>{};
    if (listenAddresses.isEmpty) {
      errors['listen'] = IscsiPortalValidationCode.listenRequired;
    } else if (listenAddresses.toSet().length != listenAddresses.length ||
        listenAddresses.any(
          (address) => InternetAddress.tryParse(address) == null,
        )) {
      errors['listen'] = IscsiPortalValidationCode.listenFormat;
    } else if (availableAddresses.isNotEmpty &&
        listenAddresses.any(
          (address) => !availableAddresses.contains(address),
        )) {
      errors['listen'] = IscsiPortalValidationCode.listenUnavailable;
    }
    return errors;
  }
}

class IscsiInitiatorConfiguration {
  const IscsiInitiatorConfiguration({
    required this.initiators,
    required this.comment,
  });

  factory IscsiInitiatorConfiguration.defaults() =>
      const IscsiInitiatorConfiguration(initiators: [], comment: '');

  factory IscsiInitiatorConfiguration.fromInitiator(IscsiInitiator initiator) =>
      IscsiInitiatorConfiguration(
        initiators: initiator.initiators,
        comment: initiator.comment,
      );

  final List<String> initiators;
  final String comment;

  Map<String, Object?> toApiJson() => {
    'initiators': initiators,
    'comment': comment.trim(),
  };

  Map<String, IscsiInitiatorValidationCode> validate() {
    final errors = <String, IscsiInitiatorValidationCode>{};
    if (initiators.toSet().length != initiators.length ||
        initiators.any(
          (value) => value.isEmpty || value.contains(RegExp(r'\s')),
        )) {
      errors['initiators'] = IscsiInitiatorValidationCode.format;
    }
    return errors;
  }

  bool get allowsAll => initiators.isEmpty;
}
