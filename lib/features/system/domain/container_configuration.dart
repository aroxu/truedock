import 'package:flutter/foundation.dart';

/// Stable validation codes for [ContainerConfiguration]. The presentation
/// layer maps each code to a localized message; the domain keeps an English
/// fallback for logs and tests.
enum ContainerValidationCode {
  nameRequired,
  datasetRequired,
  vcpusMinimum,
  memoryMinimum,
}

/// Mutable container configuration collected by the editor and sent to
/// `container.update`. TrueNAS 25.10's container surface is experimental and
/// replaces the whole config object on update, so the editor keeps the
/// existing config fields it does not surface and re-sends them unchanged.
@immutable
class ContainerConfiguration {
  const ContainerConfiguration({
    required this.name,
    required this.description,
    required this.dataset,
    required this.autostart,
    required this.vcpus,
    required this.memoryLimitMiB,
    required this.devices,
    required this.volumes,
    required this.environment,
  });

  /// Raw device/volume/env maps preserved from the existing container so the
  /// update round-trips fields the editor does not expose.
  final List<Map<String, Object?>> devices;
  final List<Map<String, Object?>> volumes;
  final Map<String, String> environment;

  final String name;
  final String description;
  final String dataset;
  final bool autostart;
  final int? vcpus;
  final int? memoryLimitMiB;

  /// Builds a [ContainerConfiguration] from a raw `container.query` object so
  /// the editor preserves the fields it does not surface.
  factory ContainerConfiguration.fromRawConfig(Map<String, dynamic> json) {
    Object? asList(Object? v) {
      if (v is List) return v;
      return const <Map<String, Object?>>[];
    }

    final devices = asList(json['devices']);
    final volumes = asList(json['volumes']);
    final env = json['environment'];
    final environment = <String, String>{};
    if (env is Map) {
      env.forEach((key, value) {
        if (key is String && value is String) environment[key] = value;
      });
    }
    return ContainerConfiguration(
      name: json['name'] is String ? json['name'] as String : 'Container',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      dataset: json['dataset'] is String ? json['dataset'] as String : '',
      autostart: json['autostart'] == true,
      vcpus: json['vcpus'] is num ? (json['vcpus'] as num).toInt() : null,
      memoryLimitMiB: json['memory'] is num
          ? (json['memory'] as num).toInt()
          : null,
      devices: devices is List
          ? devices
                .whereType<Map<String, dynamic>>()
                .map(Map<String, Object?>.from)
                .toList(growable: false)
          : const <Map<String, Object?>>[],
      volumes: volumes is List
          ? volumes
                .whereType<Map<String, dynamic>>()
                .map(Map<String, Object?>.from)
                .toList(growable: false)
          : const <Map<String, Object?>>[],
      environment: environment,
    );
  }

  /// Payload for `container.update`. TrueNAS replaces the whole config, so the
  /// editor re-sends every field, preserving the raw device/volume/env lists.
  Map<String, Object?> toApiJson() => {
    'name': name,
    'description': description.isEmpty ? null : description,
    'dataset': dataset,
    'autostart': autostart,
    if (vcpus != null) 'vcpus': vcpus,
    if (memoryLimitMiB != null) 'memory': memoryLimitMiB,
    'devices': devices,
    'volumes': volumes,
    'environment': environment,
  };

  ContainerConfiguration copyWith({
    String? name,
    String? description,
    String? dataset,
    bool? autostart,
    int? vcpus,
    int? memoryLimitMiB,
    List<Map<String, Object?>>? devices,
    List<Map<String, Object?>>? volumes,
    Map<String, String>? environment,
  }) => ContainerConfiguration(
    name: name ?? this.name,
    description: description ?? this.description,
    dataset: dataset ?? this.dataset,
    autostart: autostart ?? this.autostart,
    vcpus: vcpus ?? this.vcpus,
    memoryLimitMiB: memoryLimitMiB ?? this.memoryLimitMiB,
    devices: devices ?? this.devices,
    volumes: volumes ?? this.volumes,
    environment: environment ?? this.environment,
  );
}

/// Validates a [ContainerConfiguration]. Returns field-keyed validation codes
/// the presentation layer maps onto localized messages.
Map<String, ContainerValidationCode> validateContainerConfiguration(
  ContainerConfiguration config,
) {
  final errors = <String, ContainerValidationCode>{};
  if (config.name.trim().isEmpty) {
    errors['name'] = ContainerValidationCode.nameRequired;
  }
  if (config.dataset.trim().isEmpty) {
    errors['dataset'] = ContainerValidationCode.datasetRequired;
  }
  if (config.vcpus != null && config.vcpus! < 1) {
    errors['vcpus'] = ContainerValidationCode.vcpusMinimum;
  }
  if (config.memoryLimitMiB != null && config.memoryLimitMiB! < 16) {
    errors['memory'] = ContainerValidationCode.memoryMinimum;
  }
  return errors;
}
