import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/security/security_providers.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

void main() {
  test('biometric setting reflects saved server protection', () async {
    final server = SavedServer(
      profile: ServerProfile(
        name: 'Home NAS',
        baseUri: Uri.parse('https://nas.local'),
      ),
      username: 'admin',
      authMethod: AuthMethod.password,
      hasSavedCredential: true,
      credentialProtection: CredentialProtection.appPasswordWithBiometric,
    );
    final container = ProviderContainer(
      overrides: [
        savedServersProvider.overrideWith((ref) async => [server]),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(biometricUnlockEnabledProvider.future), isTrue);
  });

  test(
    'biometric setting is off without a biometric credential copy',
    () async {
      final server = SavedServer(
        profile: ServerProfile(
          name: 'Home NAS',
          baseUri: Uri.parse('https://nas.local'),
        ),
        username: 'admin',
        authMethod: AuthMethod.password,
        hasSavedCredential: true,
        credentialProtection: CredentialProtection.appPassword,
      );
      final container = ProviderContainer(
        overrides: [
          savedServersProvider.overrideWith((ref) async => [server]),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(biometricUnlockEnabledProvider.future),
        isFalse,
      );
    },
  );
}
