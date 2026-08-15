import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/core/security/device_data_reset_service.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

class _EmptyVault implements CredentialVault {
  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.unsupported);

  @override
  Future<void> delete(ServerProfile profile) async {}

  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {}

  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async => null;
}

void main() {
  test('clears secure stores and all local preferences', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'security.biometric_unlock': true,
      'appearance.theme_mode': 'dark',
    });
    var savedServersCleared = false;
    var certificateTrustCleared = false;
    final service = DeviceDataResetService(
      savedServers: SavedServerRepository(vault: _EmptyVault()),
      clearSavedServerData: () async => savedServersCleared = true,
      clearCertificateTrust: () async => certificateTrustCleared = true,
    );

    await service.reset();

    expect(savedServersCleared, isTrue);
    expect(certificateTrustCleared, isTrue);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
