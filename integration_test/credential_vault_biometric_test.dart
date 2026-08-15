import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'saved credential requires device authentication before retrieval',
    (_) async {
      final vault = PlatformCredentialVault(
        prompt: const BiometricPromptStrings(
          title: 'Unlock TrueDock',
          subtitle: 'Authenticate to access your saved server',
          negativeButton: 'Cancel',
        ),
      );
      final profile = ServerProfile(
        name: 'Biometric integration test',
        baseUri: Uri.parse('https://biometric-test.invalid'),
      );
      const credential = PasswordCredential(
        username: 'integration-test',
        password: 'disposable-test-secret',
      );

      await vault.delete(profile);
      addTearDown(() => vault.delete(profile));

      final availability = await vault.availability();
      expect(
        availability.canSave,
        isTrue,
        reason: 'Enroll Face ID in the iOS Simulator before running this test.',
      );
      await vault.save(profile, credential);

      final restored = await vault.unlock(profile);

      expect(restored, isA<PasswordCredential>());
      expect(restored?.username, credential.username);
      expect((restored as PasswordCredential).password, credential.password);
    },
    skip: !Platform.isIOS,
  );
}
