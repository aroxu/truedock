import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../features/connection/data/saved_server_repository.dart';
import 'app_password_vault.dart';
import 'credential_vault.dart';
import 'tls_certificate_service.dart';

final tlsCertificateInspectorProvider = Provider<TlsCertificateInspector>((
  ref,
) {
  return const IoTlsCertificateInspector();
});

/// Strings for Android's system biometric prompt.
///
/// The prompt is drawn by the OS and its text is handed to the platform
/// channel when the vault is constructed, so it cannot be resolved from a
/// [BuildContext] at display time. [TrueDockApp] overrides this once
/// localizations resolve; the default keeps the English wording.
final biometricPromptStringsProvider = StateProvider<BiometricPromptStrings>((
  ref,
) {
  return BiometricPromptStrings.fallback;
});

final credentialVaultProvider = Provider<CredentialVault>((ref) {
  return PlatformCredentialVault(
    prompt: ref.watch(biometricPromptStringsProvider),
  );
});

final appPasswordCredentialVaultProvider = Provider<AppPasswordCredentialVault>(
  (ref) {
    return PlatformAppPasswordCredentialVault();
  },
);

final biometricVaultAvailabilityProvider =
    FutureProvider.autoDispose<BiometricVaultAvailability>((ref) {
      return ref.watch(credentialVaultProvider).availability();
    });

final appPasswordConfiguredProvider = FutureProvider<bool>((ref) {
  return ref.watch(appPasswordCredentialVaultProvider).isConfigured();
});

final biometricUnlockEnabledProvider = FutureProvider<bool>((ref) async {
  final servers = await ref.watch(savedServersProvider.future);
  return servers.any(
    (server) =>
        server.hasSavedCredential &&
        server.credentialProtection ==
            CredentialProtection.appPasswordWithBiometric,
  );
});

final savedServerRepositoryProvider = Provider<SavedServerRepository>((ref) {
  return SavedServerRepository(
    vault: ref.watch(credentialVaultProvider),
    appPasswordVault: ref.watch(appPasswordCredentialVaultProvider),
  );
});

final savedServersProvider = FutureProvider<List<SavedServer>>((ref) {
  return ref.watch(savedServerRepositoryProvider).list();
});
