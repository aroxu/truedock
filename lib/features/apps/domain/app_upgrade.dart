typedef UpgradeJson = Map<String, dynamic>;

class AppUpgradeSummary {
  const AppUpgradeSummary({
    required this.latestVersion,
    required this.latestHumanVersion,
    required this.selectedVersion,
    required this.selectedHumanVersion,
    required this.availableVersions,
  });

  factory AppUpgradeSummary.fromJson(UpgradeJson json) {
    final versions = json['available_versions_for_upgrade'];
    return AppUpgradeSummary(
      latestVersion: _string(json['latest_version'], fallback: 'latest'),
      latestHumanVersion: _string(
        json['latest_human_version'],
        fallback: 'Latest version',
      ),
      selectedVersion: _string(
        json['upgrade_version'],
        fallback: _string(json['latest_version'], fallback: 'latest'),
      ),
      selectedHumanVersion: _string(
        json['upgrade_human_version'],
        fallback: _string(
          json['latest_human_version'],
          fallback: 'Latest version',
        ),
      ),
      availableVersions: versions is List<Object?>
          ? versions
                .whereType<UpgradeJson>()
                .map(AppUpgradeVersion.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  final String latestVersion;
  final String latestHumanVersion;
  final String selectedVersion;
  final String selectedHumanVersion;
  final List<AppUpgradeVersion> availableVersions;

  AppUpgradeVersion versionOrFallback(String version) {
    for (final candidate in availableVersions) {
      if (candidate.version == version) return candidate;
    }
    return AppUpgradeVersion(
      version: selectedVersion,
      humanVersion: selectedHumanVersion,
    );
  }
}

class AppUpgradeVersion {
  const AppUpgradeVersion({
    required this.version,
    required this.humanVersion,
    this.changelog,
  });

  factory AppUpgradeVersion.fromJson(UpgradeJson json) => AppUpgradeVersion(
    version: _string(json['version'], fallback: 'latest'),
    humanVersion: _string(json['human_version'], fallback: 'Latest version'),
    changelog: _boundedText(json['changelog']),
  );

  final String version;
  final String humanVersion;
  final String? changelog;
}

class AppUpgradeChoice {
  const AppUpgradeChoice({
    required this.version,
    required this.snapshotHostPaths,
  });

  final String version;
  final bool snapshotHostPaths;
}

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _boundedText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  final normalized = value.trim();
  return normalized.length <= 8000 ? normalized : normalized.substring(0, 8000);
}
