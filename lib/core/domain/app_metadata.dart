/// Static application metadata surfaced by the in-app About page.
///
/// The version is injected at build time so a release artifact always reports
/// the same value as `pubspec.yaml`, without adding a plugin dependency just to
/// read the package manifest at runtime. Source builds that omit the define
/// fall back to [fallbackVersion], which `tool/release_check.sh` keeps aligned
/// with the manifest.
library;

/// Semantic version name, for example `1.0.0`.
const String appVersionName = String.fromEnvironment(
  'TRUEDOCK_VERSION_NAME',
  defaultValue: _fallbackVersionName,
);

/// Build number, for example `3`.
const String appBuildNumber = String.fromEnvironment(
  'TRUEDOCK_BUILD_NUMBER',
  defaultValue: _fallbackBuildNumber,
);

const String _fallbackVersionName = '1.0.0';
const String _fallbackBuildNumber = '3';

/// Canonical public repository for issues, sources, and releases.
const String appRepositoryUrl = 'https://github.com/aroxu/truedock';

/// License the project itself is distributed under.
const String appLicenseSpdxId = 'GPL-3.0-or-later';

/// A third-party package bundled into TrueDock builds.
///
/// Only runtime dependencies are listed: development-only tooling is not
/// shipped to users, so it is not part of the distributed work.
class OpenSourceComponent {
  const OpenSourceComponent({
    required this.name,
    required this.license,
    required this.url,
  });

  /// Package name exactly as published, so it can be looked up verbatim.
  final String name;

  /// SPDX identifier of the license the package is distributed under.
  final String license;

  /// Canonical package page.
  final String url;
}

/// Runtime dependencies bundled into TrueDock, sorted by package name.
///
/// Keep this aligned with the `dependencies` block in `pubspec.yaml`.
const List<OpenSourceComponent> openSourceComponents = <OpenSourceComponent>[
  OpenSourceComponent(
    name: 'crypto',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/crypto',
  ),
  OpenSourceComponent(
    name: 'cryptography',
    license: 'Apache-2.0',
    url: 'https://pub.dev/packages/cryptography',
  ),
  OpenSourceComponent(
    name: 'cupertino_icons',
    license: 'MIT',
    url: 'https://pub.dev/packages/cupertino_icons',
  ),
  OpenSourceComponent(
    name: 'dio',
    license: 'MIT',
    url: 'https://pub.dev/packages/dio',
  ),
  OpenSourceComponent(
    name: 'dynamic_color',
    license: 'Apache-2.0',
    url: 'https://pub.dev/packages/dynamic_color',
  ),
  OpenSourceComponent(
    name: 'fl_chart',
    license: 'MIT',
    url: 'https://pub.dev/packages/fl_chart',
  ),
  OpenSourceComponent(
    name: 'flutter',
    license: 'BSD-3-Clause',
    url: 'https://github.com/flutter/flutter',
  ),
  OpenSourceComponent(
    name: 'flutter_riverpod',
    license: 'MIT',
    url: 'https://pub.dev/packages/flutter_riverpod',
  ),
  OpenSourceComponent(
    name: 'flutter_secure_storage',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/flutter_secure_storage',
  ),
  OpenSourceComponent(
    name: 'flutter_svg',
    license: 'MIT',
    url: 'https://pub.dev/packages/flutter_svg',
  ),
  OpenSourceComponent(
    name: 'go_router',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/go_router',
  ),
  OpenSourceComponent(
    name: 'intl',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/intl',
  ),
  OpenSourceComponent(
    name: 'local_auth',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/local_auth',
  ),
  OpenSourceComponent(
    name: 'meta',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/meta',
  ),
  OpenSourceComponent(
    name: 'sentry_flutter',
    license: 'MIT',
    url: 'https://pub.dev/packages/sentry_flutter',
  ),
  OpenSourceComponent(
    name: 'shared_preferences',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/shared_preferences',
  ),
  OpenSourceComponent(
    name: 'url_launcher',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/url_launcher',
  ),
  OpenSourceComponent(
    name: 'web_socket_channel',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/web_socket_channel',
  ),
];
