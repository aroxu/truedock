import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

void main() {
  group('ServerProfile.parse', () {
    test('normalizes a host to the secure current API endpoint', () {
      final profile = ServerProfile.parse(
        name: 'Home',
        address: 'nas.local:8443',
      );

      expect(profile.name, 'Home');
      expect(profile.baseUri, Uri.parse('https://nas.local:8443'));
      expect(
        profile.websocketUri,
        Uri.parse('wss://nas.local:8443/api/current'),
      );
    });

    test('rejects insecure transport', () {
      expect(
        () => ServerProfile.parse(name: 'NAS', address: 'http://nas.local'),
        throwsFormatException,
      );
    });

    test('round-trips saved profile metadata with a stable server id', () {
      final profile = ServerProfile.parse(
        name: 'Home',
        address: 'nas.local:8443',
      ).copyWith(pinnedCertificateSha256: 'aa' * 32);

      final restored = ServerProfile.fromJson(profile.toJson());

      expect(restored.name, profile.name);
      expect(restored.baseUri, profile.baseUri);
      expect(restored.id, profile.id);
      expect(restored.pinnedCertificateSha256, 'aa' * 32);
    });
  });

  test('renaming preserves the stable profile identity and TLS pin', () {
    final original = ServerProfile(
      name: 'Home NAS',
      baseUri: Uri.parse('https://nas.local'),
      pinnedCertificateSha256: 'AA:BB',
    );

    final renamed = original.copyWith(name: 'Backup NAS');

    expect(renamed.name, 'Backup NAS');
    expect(renamed.id, original.id);
    expect(renamed.baseUri, original.baseUri);
    expect(renamed.pinnedCertificateSha256, 'AA:BB');
  });
}
