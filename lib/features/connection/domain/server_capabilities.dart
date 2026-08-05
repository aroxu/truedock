import 'system_info.dart';

class ServerCapabilities {
  const ServerCapabilities({
    required this.productType,
    required this.version,
    required this.methods,
  });

  factory ServerCapabilities.fromDiscovery({
    required SystemInfo systemInfo,
    required Object? productType,
    required Object? methods,
  }) {
    if (productType is! String || productType.isEmpty) {
      throw const UnsupportedServerException(
        'TrueDock needs permission to read the TrueNAS product type.',
      );
    }
    if (methods is! Map<String, dynamic>) {
      throw const UnsupportedServerException(
        'TrueNAS did not return its WebSocket capability list.',
      );
    }
    return ServerCapabilities(
      productType: productType,
      version: TrueNasVersion.parse(systemInfo.version),
      methods: methods.keys.toSet(),
    );
  }

  final String productType;
  final TrueNasVersion version;
  final Set<String> methods;

  bool supports(String method) => methods.contains(method);

  bool get isCommunityEdition => productType == 'COMMUNITY_EDITION';
  bool get supportsContainers =>
      supports('container.query') && supports('container.start');

  /// Whether the server exposes 25.10's Instances surface.
  ///
  /// Distinct from [supportsContainers]: 25.10 does not advertise
  /// `container.*` at all, having replaced it with `virt.*`. Both are gated
  /// separately so a server exposing either one gets the matching UI, and a
  /// server exposing neither gets an explanation instead of an empty list.
  bool get supportsVirtInstances =>
      supports('virt.instance.query') && supports('virt.global.config');

  void validateForTrueDock() {
    if (!isCommunityEdition) {
      throw UnsupportedServerException(
        'TrueDock supports TrueNAS Community Edition only. '
        'This server reports $productType.',
      );
    }
    if (version < const TrueNasVersion(25, 10, 0)) {
      throw UnsupportedServerException(
        'TrueDock requires TrueNAS Community Edition 25.10 or newer. '
        'This server reports $version.',
      );
    }
    for (final requiredMethod in const [
      'auth.login_ex',
      'system.info',
      'pool.query',
    ]) {
      if (!supports(requiredMethod)) {
        throw UnsupportedServerException(
          'This server does not expose the required $requiredMethod method.',
        );
      }
    }
  }
}

class TrueNasVersion implements Comparable<TrueNasVersion> {
  const TrueNasVersion(this.major, this.minor, this.patch);

  factory TrueNasVersion.parse(String value) {
    final match = RegExp(r'(\d+)\.(\d+)(?:\.(\d+))?').firstMatch(value);
    if (match == null) {
      throw UnsupportedServerException(
        'Could not determine the TrueNAS version from "$value".',
      );
    }
    return TrueNasVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.tryParse(match.group(3) ?? '') ?? 0,
    );
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(TrueNasVersion other) {
    final majorComparison = major.compareTo(other.major);
    if (majorComparison != 0) return majorComparison;
    final minorComparison = minor.compareTo(other.minor);
    if (minorComparison != 0) return minorComparison;
    return patch.compareTo(other.patch);
  }

  bool operator <(TrueNasVersion other) => compareTo(other) < 0;

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      other is TrueNasVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

class UnsupportedServerException implements Exception {
  const UnsupportedServerException(this.message);

  final String message;

  @override
  String toString() => message;
}
