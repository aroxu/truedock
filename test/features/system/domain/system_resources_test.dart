import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';

void main() {
  test('classifies update profiles as stable, beta, and nightly', () {
    final stable = SystemUpdateProfile.fromEntry('GENERAL', {
      'name': 'General',
      'available': true,
    });
    final beta = SystemUpdateProfile.fromEntry('EARLY_ADOPTER', {
      'name': 'Early Adopter',
      'available': true,
    });
    final nightly = SystemUpdateProfile.fromEntry('DEVELOPER', {
      'name': 'Developer',
      'available': true,
    });

    expect(stable.channel, SystemUpdateChannel.general);
    expect(beta.channel, SystemUpdateChannel.earlyAdopter);
    expect(nightly.channel, SystemUpdateChannel.developer);
  });

  test('developer is nightly rather than a second beta channel', () {
    final developer = SystemUpdateProfile.fromEntry('DEVELOPER', {
      'name': 'Developer',
      'description': 'Developer preview builds',
    });

    expect(developer.channel, SystemUpdateChannel.developer);
  });

  test('parses interface runtime state and addresses', () {
    final item = NetworkInterface.fromJson({
      'id': 'eno1',
      'name': 'eno1',
      'type': 'PHYSICAL',
      'ipv4_dhcp': true,
      'mtu': 1500,
      'state': {
        'link_state': 'LINK_STATE_UP',
        'active_media_subtype': '1000baseT',
        'aliases': [
          {'type': 'INET', 'address': '10.0.0.5', 'netmask': 24},
        ],
      },
    });

    expect(item.isUp, isTrue);
    expect(item.dhcp, isTrue);
    expect(item.addresses.single.label, '10.0.0.5/24');
    expect(item.activeMediaSubtype, '1000baseT');
  });

  test('parses nested update status and download progress', () {
    final status = SystemUpdateStatus.fromJson({
      'code': 'NORMAL',
      'status': {
        'current_version': {
          'train': 'TrueNAS-SCALE-25.10',
          'profile': 'GENERAL',
        },
        'new_version': {
          'version': '25.10.2',
          'release_notes_url': 'https://example.invalid/notes',
        },
      },
      'error': null,
      'update_download_progress': {
        'percent': 42.5,
        'description': 'Downloading update',
      },
    });

    expect(status.updateAvailable, isTrue);
    expect(status.newVersion, '25.10.2');
    expect(status.downloadPercent, 42.5);
    expect(status.hasError, isFalse);
  });

  test('parses account roles without exposing credential fields', () {
    final user = NasUser.fromJson({
      'id': 7,
      'username': 'mobile-admin',
      'full_name': 'Mobile Admin',
      'uid': 3000,
      'local': true,
      'builtin': false,
      'smb': false,
      'password_disabled': false,
      'roles': ['FULL_ADMIN'],
    });

    expect(user.isAdministrator, isTrue);
    expect(user.username, 'mobile-admin');
  });

  test('distinguishes the running environment from the next boot', () {
    final environment = BootEnvironment.fromJson({
      'id': '25.10.2',
      'active': false,
      'activated': true,
      'keep': false,
    });

    // Rebooting would leave the currently running system, which is exactly
    // what the user needs to know before restarting.
    expect(environment.activationPending, isTrue);
    expect(environment.supersededByPendingActivation, isFalse);
  });

  test('reports an environment that is about to be replaced', () {
    final environment = BootEnvironment.fromJson({
      'id': '25.10.1',
      'active': true,
      'activated': false,
      'keep': false,
    });

    expect(environment.supersededByPendingActivation, isTrue);
    expect(environment.activationPending, isFalse);
  });

  test('a settled environment reports no pending activation', () {
    final environment = BootEnvironment.fromJson({
      'id': '25.10.2',
      'active': true,
      'activated': true,
      'keep': true,
    });

    expect(environment.activationPending, isFalse);
    expect(environment.supersededByPendingActivation, isFalse);
    expect(environment.keep, isTrue);
  });

  test('legacy payloads without activated do not fake a pending boot', () {
    final environment = BootEnvironment.fromJson({
      'id': '25.10.2',
      'active': true,
      'keep': false,
    });

    // Treating a missing `activated` as false would claim every server has a
    // pending activation.
    expect(environment.activated, isTrue);
    expect(environment.supersededByPendingActivation, isFalse);
  });

  test('parses the creation date from either serialization', () {
    final wrapped = BootEnvironment.fromJson({
      'id': 'a',
      r'created': {r'$date': 1767225600000},
    });
    final iso = BootEnvironment.fromJson({
      'id': 'b',
      'created': '2026-01-01T00:00:00Z',
    });

    expect(wrapped.created?.year, 2026);
    expect(iso.created?.year, 2026);
  });

  test('falls back to name when the payload has no id', () {
    final environment = BootEnvironment.fromJson({
      'name': '25.10.0',
      'active': false,
    });

    expect(environment.id, '25.10.0');
  });

  test('parses an API key without carrying any key material', () {
    final apiKey = NasApiKey.fromJson({
      'id': 4,
      'name': 'backup-runner',
      'username': 'admin',
      'revoked': false,
      'created_at': {r'$date': 1767225600000},
      'expires_at': null,
      'key': 'should-never-be-retained',
    });

    expect(apiKey.name, 'backup-runner');
    expect(apiKey.username, 'admin');
    expect(apiKey.revoked, isFalse);
    expect(apiKey.createdAt?.year, 2026);
    // A key with no expiry never expires; that is not the same as expired.
    expect(apiKey.expires, isFalse);
    expect(apiKey.isUsableAt(DateTime.utc(2030)), isTrue);
  });

  test('distinguishes an expired key from a revoked one', () {
    final expired = NasApiKey.fromJson({
      'id': 5,
      'name': 'stale',
      'revoked': false,
      'expires_at': '2026-01-01T00:00:00Z',
    });
    final revoked = NasApiKey.fromJson({
      'id': 6,
      'name': 'withdrawn',
      'revoked': true,
    });

    final now = DateTime.utc(2026, 8, 11);
    expect(expired.isExpiredAt(now), isTrue);
    expect(expired.revoked, isFalse);
    expect(revoked.isExpiredAt(now), isFalse);
    expect(revoked.revoked, isTrue);
    // Either way the key cannot authenticate.
    expect(expired.isUsableAt(now), isFalse);
    expect(revoked.isUsableAt(now), isFalse);
  });

  test('a key expiring in the future is still usable', () {
    final apiKey = NasApiKey.fromJson({
      'id': 7,
      'name': 'rotating',
      'revoked': false,
      'expires_at': '2027-01-01T00:00:00Z',
    });

    final now = DateTime.utc(2026, 8, 11);
    expect(apiKey.expires, isTrue);
    expect(apiKey.isExpiredAt(now), isFalse);
    expect(apiKey.isUsableAt(now), isTrue);
  });
}
