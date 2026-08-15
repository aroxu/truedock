import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/domain/app_upgrade.dart';

void main() {
  test('parses selectable app upgrade versions and release notes', () {
    final summary = AppUpgradeSummary.fromJson({
      'latest_version': '2.0.0',
      'latest_human_version': '2.0.0 release',
      'upgrade_version': '2.0.0',
      'upgrade_human_version': '2.0.0 release',
      'available_versions_for_upgrade': [
        {
          'version': '1.5.0',
          'human_version': '1.5.0 release',
          'changelog': 'Compatibility improvements',
        },
        {
          'version': '2.0.0',
          'human_version': '2.0.0 release',
          'changelog': 'Major upgrade notes',
        },
      ],
    });

    expect(summary.latestVersion, '2.0.0');
    expect(summary.availableVersions, hasLength(2));
    expect(summary.versionOrFallback('2.0.0').changelog, 'Major upgrade notes');
  });

  test('bounds unusually large release notes before presenting them', () {
    final version = AppUpgradeVersion.fromJson({
      'version': '2.0.0',
      'human_version': '2.0.0',
      'changelog': 'x' * 10000,
    });

    expect(version.changelog, hasLength(8000));
  });
}
