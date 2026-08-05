import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/security/app_password_vault.dart';
import '../../../core/security/credential_vault.dart';
import '../domain/auth_credential.dart';
import '../domain/server_profile.dart';

enum CredentialProtection {
  none,

  /// Legacy entries saved before TrueDock passwords became the primary lock.
  biometric,
  appPassword,
  appPasswordWithBiometric,
}

class SavedServer {
  const SavedServer({
    required this.profile,
    required this.username,
    required this.authMethod,
    required this.hasSavedCredential,
    CredentialProtection? credentialProtection,
  }) : credentialProtection =
           credentialProtection ??
           (hasSavedCredential
               ? CredentialProtection.biometric
               : CredentialProtection.none);

  factory SavedServer.fromJson(Map<String, dynamic> json) => SavedServer(
    profile: ServerProfile.fromJson(
      (json['profile'] as Map<Object?, Object?>).cast<String, dynamic>(),
    ),
    username: json['username'] as String? ?? '',
    authMethod: switch (json['auth_method']) {
      'password' => AuthMethod.password,
      _ => AuthMethod.apiKey,
    },
    // Metadata written before this field was introduced always accompanied a
    // vault entry, so missing means true for backward compatibility.
    hasSavedCredential: json.containsKey('credential_saved')
        ? json['credential_saved'] == true
        : true,
    credentialProtection: switch (json['credential_protection']) {
      'app_password' => CredentialProtection.appPassword,
      'app_password_biometric' => CredentialProtection.appPasswordWithBiometric,
      'biometric' => CredentialProtection.biometric,
      _ =>
        json.containsKey('credential_saved') && json['credential_saved'] != true
            ? CredentialProtection.none
            : CredentialProtection.biometric,
    },
  );

  final ServerProfile profile;
  final String username;
  final AuthMethod authMethod;
  final bool hasSavedCredential;
  final CredentialProtection credentialProtection;

  Map<String, Object?> toJson() => {
    'profile': profile.toJson(),
    'username': username,
    'auth_method': authMethod == AuthMethod.apiKey ? 'api_key' : 'password',
    'credential_saved': hasSavedCredential,
    'credential_protection': switch (credentialProtection) {
      CredentialProtection.none => 'none',
      CredentialProtection.biometric => 'biometric',
      CredentialProtection.appPassword => 'app_password',
      CredentialProtection.appPasswordWithBiometric => 'app_password_biometric',
    },
  };
}

class SavedServerRepository {
  SavedServerRepository({
    CredentialVault? vault,
    AppPasswordCredentialVault? appPasswordVault,
    FlutterSecureStorage? metadataStorage,
  }) : _vault = vault ?? PlatformCredentialVault(),
       _appPasswordVault =
           appPasswordVault ?? PlatformAppPasswordCredentialVault(),
       _metadataStorage =
           metadataStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accountName: 'me.aroxu.truedock.saved-servers',
               accessibility: KeychainAccessibility.unlocked_this_device,
               synchronizable: false,
             ),
             aOptions: AndroidOptions(
               storageNamespace: 'truedock_saved_servers',
               resetOnError: false,
             ),
           );

  final CredentialVault _vault;
  final AppPasswordCredentialVault _appPasswordVault;
  final FlutterSecureStorage _metadataStorage;

  CredentialVault get vault => _vault;

  Future<bool> isAppPasswordConfigured() => _appPasswordVault.isConfigured();

  Future<void> verifyAppPassword(String password) =>
      _appPasswordVault.verifyPassword(password);

  Future<void> configureAppPassword(String password) =>
      _appPasswordVault.configurePassword(password);

  Future<void> changeAppPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _appPasswordVault.verifyPassword(currentPassword);
    final credentials = <ServerProfile, AuthCredential>{};
    for (final server in await list()) {
      if (server.credentialProtection != CredentialProtection.appPassword &&
          server.credentialProtection !=
              CredentialProtection.appPasswordWithBiometric) {
        continue;
      }
      final credential = await _appPasswordVault.unlock(
        server.profile,
        currentPassword,
      );
      if (credential != null) credentials[server.profile] = credential;
    }
    await _appPasswordVault.changePassword(
      currentPassword,
      newPassword,
      credentials,
    );
  }

  Future<void> setBiometricUnlockEnabled({
    required String appPassword,
    required bool enabled,
  }) async {
    await _appPasswordVault.verifyPassword(appPassword);
    final servers = await list();
    for (final server in servers) {
      if (server.credentialProtection != CredentialProtection.appPassword &&
          server.credentialProtection !=
              CredentialProtection.appPasswordWithBiometric) {
        continue;
      }
      final credential = await _appPasswordVault.unlock(
        server.profile,
        appPassword,
      );
      if (credential == null) continue;
      if (enabled) {
        await _vault.save(server.profile, credential);
      } else {
        await _vault.delete(server.profile);
      }
      final updated = SavedServer(
        profile: server.profile,
        username: server.username,
        authMethod: server.authMethod,
        hasSavedCredential: true,
        credentialProtection: enabled
            ? CredentialProtection.appPasswordWithBiometric
            : CredentialProtection.appPassword,
      );
      await _metadataStorage.write(
        key: _key(server.profile),
        value: jsonEncode(updated.toJson()),
      );
    }
  }

  String _key(ServerProfile profile) => 'server.${profile.id}';

  Future<List<SavedServer>> list() async {
    final values = await _metadataStorage.readAll();
    final servers = <SavedServer>[];
    for (final entry in values.entries) {
      if (!entry.key.startsWith('server.')) continue;
      try {
        final decoded = jsonDecode(entry.value);
        if (decoded is Map<String, dynamic>) {
          servers.add(SavedServer.fromJson(decoded));
        }
      } on Object {
        // Ignore one damaged profile without hiding other saved servers.
      }
    }
    servers.sort((a, b) => a.profile.name.compareTo(b.profile.name));
    return servers;
  }

  /// Registers non-secret server metadata after a successful connection.
  ///
  /// The profile is always retained so the next launch can offer the server.
  /// The reusable credential is persisted only when [saveCredential] is true.
  Future<void> register(
    ServerProfile profile,
    AuthCredential credential, {
    required bool saveCredential,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {
    if (saveCredential && appPassword == null) {
      throw const AppPasswordVaultException(
        'Create or enter your TrueDock password to save this sign-in.',
      );
    }
    final createdAppPassword =
        saveCredential &&
        appPassword != null &&
        !await _appPasswordVault.isConfigured();
    try {
      if (saveCredential) {
        await _appPasswordVault.save(profile, credential, appPassword!);
        if (enableBiometricUnlock) {
          await _vault.save(profile, credential);
        } else {
          await _vault.delete(profile);
        }
      } else {
        // An explicit opt-out also removes an older saved credential for this
        // profile, keeping metadata and vault state consistent.
        await _vault.delete(profile);
        await _appPasswordVault.delete(profile);
      }
      final entry = SavedServer(
        profile: profile,
        username: credential.username,
        authMethod: credential is ApiKeyCredential
            ? AuthMethod.apiKey
            : AuthMethod.password,
        hasSavedCredential: saveCredential,
        credentialProtection: !saveCredential
            ? CredentialProtection.none
            : enableBiometricUnlock
            ? CredentialProtection.appPasswordWithBiometric
            : CredentialProtection.appPassword,
      );
      await _metadataStorage.write(
        key: _key(profile),
        value: jsonEncode(entry.toJson()),
      );
    } on Object {
      if (saveCredential) {
        await _vault.delete(profile);
        await _appPasswordVault.delete(profile);
        if (createdAppPassword) await _appPasswordVault.clearAll();
      }
      rethrow;
    }
  }

  Future<AuthCredential?> unlock(SavedServer server, {String? appPassword}) {
    return switch (server.credentialProtection) {
      CredentialProtection.appPassword when appPassword != null =>
        _appPasswordVault.unlock(server.profile, appPassword),
      CredentialProtection.appPassword => throw const AppPasswordVaultException(
        'Enter your TrueDock password to unlock this server.',
      ),
      CredentialProtection.appPasswordWithBiometric when appPassword != null =>
        _appPasswordVault.unlock(server.profile, appPassword),
      CredentialProtection.appPasswordWithBiometric => _vault.unlock(
        server.profile,
      ),
      CredentialProtection.biometric => _vault.unlock(server.profile),
      CredentialProtection.none => Future<AuthCredential?>.value(null),
    };
  }

  Future<void> clearAllAppPasswordCredentials() async {
    await _appPasswordVault.clearAll();
    final servers = await list();
    for (final server in servers) {
      if (server.credentialProtection != CredentialProtection.appPassword &&
          server.credentialProtection !=
              CredentialProtection.appPasswordWithBiometric) {
        continue;
      }
      await _vault.delete(server.profile);
      final entry = SavedServer(
        profile: server.profile,
        username: server.username,
        authMethod: server.authMethod,
        hasSavedCredential: false,
      );
      await _metadataStorage.write(
        key: _key(server.profile),
        value: jsonEncode(entry.toJson()),
      );
    }
  }

  /// Rewrites only non-secret metadata after the server address changes.
  /// The profile id remains stable, preserving its existing vault entry.
  Future<void> updateProfile(ServerProfile profile) async {
    final matches = (await list()).where(
      (server) => server.profile.id == profile.id,
    );
    if (matches.isEmpty) return;
    final current = matches.single;
    final updated = SavedServer(
      profile: profile,
      username: current.username,
      authMethod: current.authMethod,
      hasSavedCredential: current.hasSavedCredential,
      credentialProtection: current.credentialProtection,
    );
    await _metadataStorage.write(
      key: _key(profile),
      value: jsonEncode(updated.toJson()),
    );
  }

  Future<void> delete(ServerProfile profile) async {
    await _vault.delete(profile);
    await _appPasswordVault.delete(profile);
    await _metadataStorage.delete(key: _key(profile));
  }

  /// Deletes every local server profile and reusable credential.
  ///
  /// This never calls TrueNAS and therefore cannot alter server-side data.
  Future<void> clearAllDeviceData() async {
    final servers = await list();
    for (final server in servers) {
      await _vault.delete(server.profile);
      await _appPasswordVault.delete(server.profile);
    }
    // Production vaults can also remove orphaned entries whose profile
    // metadata no longer exists. Test doubles still receive per-profile
    // deletes above without needing a wider destructive interface.
    if (_vault case final PlatformCredentialVault platformVault) {
      await platformVault.clearAll();
    }
    await _appPasswordVault.clearAll();
    await _metadataStorage.deleteAll();
  }
}
