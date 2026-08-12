// Uses meta rather than flutter/foundation so this pure-domain type loads on
// the Dart VM, letting tool/live_mutation_probe.dart send the app's own payload.
import 'package:meta/meta.dart';

/// Stable codes for static-route validation failures, so presentation layers
/// can translate the message instead of parsing the English fallback.
enum StaticRouteValidationCode {
  destinationRequired,
  destinationInvalid,
  gatewayRequired,
  gatewayInvalid,
}

/// A static route configured on the TrueNAS server.
///
/// Backed by `staticroute.create`, `staticroute.update`, and
/// `staticroute.delete`. Static routes are applied through the network
/// commit/checkin workflow, so the caller must commit pending changes after a
/// create/update/delete before the route takes effect on the live system.
@immutable
class StaticRouteConfiguration {
  const StaticRouteConfiguration({
    this.id,
    required this.destination,
    required this.gateway,
    this.description = '',
  });

  /// Seeds a configuration from a `staticroute.query` row.
  factory StaticRouteConfiguration.fromJson(Map<String, dynamic> json) =>
      StaticRouteConfiguration(
        id: json['id'] is num ? (json['id'] as num).toInt() : null,
        destination: json['destination'] is String
            ? json['destination'] as String
            : '',
        gateway: json['gateway'] is String ? json['gateway'] as String : '',
        description: json['description'] is String
            ? json['description'] as String
            : '',
      );

  final int? id;
  final String destination;
  final String gateway;
  final String description;

  bool get isCreate => id == null;

  /// Payload for `staticroute.create` / `staticroute.update`.
  ///
  /// The description is omitted when empty so the server keeps its default
  /// behavior of leaving the field blank rather than storing an empty string.
  Map<String, Object?> toApiJson() => {
    'destination': destination,
    'gateway': gateway,
    if (description.isNotEmpty) 'description': description,
  };

  StaticRouteConfiguration copyWith({
    int? id,
    String? destination,
    String? gateway,
    String? description,
  }) => StaticRouteConfiguration(
    id: id ?? this.id,
    destination: destination ?? this.destination,
    gateway: gateway ?? this.gateway,
    description: description ?? this.description,
  );
}

/// Validates a [StaticRouteConfiguration]. Returns field-keyed errors.
///
/// Destination must be a CIDR network (IPv4 or IPv6) and gateway must be a
/// plain IP address. TrueNAS performs the authoritative validation
/// server-side, so these checks only catch obvious mistakes before the
/// round-trip.
Map<String, StaticRouteValidationCode> validateStaticRouteConfiguration(
  StaticRouteConfiguration config,
) {
  final errors = <String, StaticRouteValidationCode>{};
  final destination = config.destination.trim();
  final gateway = config.gateway.trim();
  if (destination.isEmpty) {
    errors['destination'] = StaticRouteValidationCode.destinationRequired;
  } else if (!looksLikeCidr(destination)) {
    errors['destination'] = StaticRouteValidationCode.destinationInvalid;
  }
  if (gateway.isEmpty) {
    errors['gateway'] = StaticRouteValidationCode.gatewayRequired;
  } else if (!looksLikeIp(gateway)) {
    errors['gateway'] = StaticRouteValidationCode.gatewayInvalid;
  }
  return errors;
}

bool looksLikeCidr(String value) {
  final slash = value.lastIndexOf('/');
  if (slash <= 0 || slash == value.length - 1) return false;
  final address = value.substring(0, slash);
  final prefix = value.substring(slash + 1);
  if (!looksLikeIp(address)) return false;
  final mask = int.tryParse(prefix);
  if (mask == null || mask < 0) return false;
  // IPv4 prefixes are 0-32; IPv6 prefixes are 0-128.
  final maxPrefix = address.contains(':') ? 128 : 32;
  return mask <= maxPrefix;
}

bool looksLikeIp(String value) {
  if (value.contains(':')) {
    // Bare minimum IPv6 sanity check: at least one hex group with colons.
    final groups = value.split(':');
    return groups.where((part) => part.isNotEmpty).isNotEmpty &&
        groups.length <= 8;
  }
  final octets = value.split('.');
  if (octets.length != 4) return false;
  for (final octet in octets) {
    final n = int.tryParse(octet);
    if (n == null || n < 0 || n > 255) return false;
  }
  return true;
}
