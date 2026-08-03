import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/connection/data/saved_server_repository.dart';
import 'security_providers.dart';
import 'tls_certificate_service.dart';

abstract interface class DeviceDataResetter {
  Future<void> reset();
}

class DeviceDataResetService implements DeviceDataResetter {
  DeviceDataResetService({
    required SavedServerRepository savedServers,
    Future<void> Function()? clearSavedServerData,
    Future<void> Function()? clearCertificateTrust,
    Future<SharedPreferences> Function()? preferences,
  }) : _clearSavedServerData =
           clearSavedServerData ?? savedServers.clearAllDeviceData,
       _clearCertificateTrust =
           clearCertificateTrust ?? SecureCertificateTrustStore().clearAll,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<void> Function() _clearSavedServerData;
  final Future<void> Function() _clearCertificateTrust;
  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<void> reset() async {
    await _clearSavedServerData();
    await _clearCertificateTrust();
    await (await _preferences()).clear();
  }
}

final deviceDataResetterProvider = Provider<DeviceDataResetter>((ref) {
  return DeviceDataResetService(
    savedServers: ref.watch(savedServerRepositoryProvider),
  );
});
