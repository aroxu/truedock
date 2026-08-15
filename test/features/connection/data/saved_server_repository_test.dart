import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/security/app_password_vault.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/data/saved_server_repository.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

const _storage = FlutterSecureStorage();
final _profile = ServerProfile(
  name: 'Home NAS',
  baseUri: Uri.parse('https://nas.local'),
);
const _credential = ApiKeyCredential(username: 'admin', apiKey: 'top-secret');

class _RecordingVault implements CredentialVault {
  final Map<String, AuthCredential> credentials = {};
  final List<String> deleted = [];

  @override
  Future<BiometricVaultAvailability> availability() async =>
      const BiometricVaultAvailability(BiometricVaultStatus.available);

  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {
    credentials[profile.id] = credential;
  }

  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async =>
      credentials[profile.id];

  @override
  Future<void> delete(ServerProfile profile) async {
    credentials.remove(profile.id);
    deleted.add(profile.id);
  }
}

class _RecordingAppPasswordVault implements AppPasswordCredentialVault {
  final Map<String, AuthCredential> credentials = {};
  final List<String> deleted = [];
  String? password;
  bool cleared = false;

  @override
  Future<bool> isConfigured() async => password != null;

  @override
  Future<void> configurePassword(String password) async {
    this.password ??= password;
    if (this.password != password) {
      throw const AppPasswordVaultException('wrong password');
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    Map<ServerProfile, AuthCredential> credentials,
  ) async {
    await verifyPassword(currentPassword);
    password = newPassword;
    this.credentials
      ..clear()
      ..addEntries(
        credentials.entries.map((entry) => MapEntry(entry.key.id, entry.value)),
      );
  }

  @override
  Future<void> verifyPassword(String password) async {
    if (this.password != password) {
      throw const AppPasswordVaultException('wrong password');
    }
  }

  @override
  Future<void> save(
    ServerProfile profile,
    AuthCredential credential,
    String password,
  ) async {
    this.password ??= password;
    if (this.password != password) {
      throw const AppPasswordVaultException('wrong password');
    }
    credentials[profile.id] = credential;
  }

  @override
  Future<AuthCredential?> unlock(ServerProfile profile, String password) async {
    if (this.password != password) {
      throw const AppPasswordVaultException('wrong password');
    }
    return credentials[profile.id];
  }

  @override
  Future<void> delete(ServerProfile profile) async {
    credentials.remove(profile.id);
    deleted.add(profile.id);
  }

  @override
  Future<void> clearAll() async {
    credentials.clear();
    password = null;
    cleared = true;
  }
}

class _FailingMetadataStorage implements FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw StateError('metadata write failed');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'registers server metadata without persisting an opted-out secret',
    () async {
      final vault = _RecordingVault();
      final repository = SavedServerRepository(
        vault: vault,
        metadataStorage: _storage,
      );

      await repository.register(_profile, _credential, saveCredential: false);

      final servers = await repository.list();
      expect(servers, hasLength(1));
      expect(servers.single.profile.name, _profile.name);
      expect(servers.single.profile.baseUri, _profile.baseUri);
      expect(servers.single.username, 'admin');
      expect(servers.single.authMethod, AuthMethod.apiKey);
      expect(servers.single.hasSavedCredential, isFalse);
      expect(vault.credentials, isEmpty);

      final metadata = jsonEncode(await _storage.readAll());
      expect(metadata, isNot(contains('top-secret')));
    },
  );

  test(
    'persists the credential only when keep-signed-in is selected',
    () async {
      final vault = _RecordingVault();
      final repository = SavedServerRepository(
        vault: vault,
        metadataStorage: _storage,
      );

      await repository.register(
        _profile,
        _credential,
        saveCredential: true,
        appPassword: '123456',
      );

      final server = (await repository.list()).single;
      expect(server.hasSavedCredential, isTrue);
      expect(
        (await repository.unlock(server, appPassword: '123456'))?.toVaultJson(),
        _credential.toVaultJson(),
      );
    },
  );

  test(
    'updates an address without changing the profile or vault key',
    () async {
      final vault = _RecordingVault();
      final repository = SavedServerRepository(
        vault: vault,
        metadataStorage: _storage,
      );
      await repository.register(
        _profile,
        _credential,
        saveCredential: true,
        appPassword: '123456',
      );
      final changed = _profile.copyWith(
        name: 'Renamed NAS',
        baseUri: Uri.parse('https://new.local'),
      );

      await repository.updateProfile(changed);

      final server = (await repository.list()).single;
      expect(server.profile.name, 'Renamed NAS');
      expect(server.profile.baseUri, Uri.parse('https://new.local'));
      expect(server.profile.id, _profile.id);
      expect(
        (await repository.unlock(server, appPassword: '123456'))?.toVaultJson(),
        _credential.toVaultJson(),
      );
    },
  );

  test('treats legacy metadata as having a saved credential', () {
    final legacy = SavedServer.fromJson({
      'profile': _profile.toJson(),
      'username': 'admin',
      'auth_method': 'api_key',
    });

    expect(legacy.hasSavedCredential, isTrue);
    expect(legacy.credentialProtection, CredentialProtection.biometric);
  });

  test(
    'uses one app password for multiple independently saved servers',
    () async {
      final biometric = _RecordingVault();
      final appPassword = _RecordingAppPasswordVault();
      final repository = SavedServerRepository(
        vault: biometric,
        appPasswordVault: appPassword,
        metadataStorage: _storage,
      );
      final secondProfile = ServerProfile(
        name: 'Backup NAS',
        baseUri: Uri.parse('https://backup.local'),
      );

      await repository.register(
        _profile,
        _credential,
        saveCredential: true,
        appPassword: '123456',
      );
      await repository.register(
        secondProfile,
        _credential,
        saveCredential: true,
        appPassword: '123456',
      );

      final servers = await repository.list();
      expect(servers, hasLength(2));
      expect(
        servers.every(
          (server) =>
              server.credentialProtection == CredentialProtection.appPassword,
        ),
        isTrue,
      );
      expect(biometric.credentials, isEmpty);
      expect(
        await repository.unlock(
          servers.firstWhere((server) => server.profile.id == _profile.id),
          appPassword: '123456',
        ),
        same(_credential),
      );
    },
  );

  test('biometric unlock is an optional copy of app-password login', () async {
    final biometric = _RecordingVault();
    final appPassword = _RecordingAppPasswordVault();
    final repository = SavedServerRepository(
      vault: biometric,
      appPasswordVault: appPassword,
      metadataStorage: _storage,
    );

    await repository.register(
      _profile,
      _credential,
      saveCredential: true,
      appPassword: '123456',
      enableBiometricUnlock: true,
    );

    final server = (await repository.list()).single;
    expect(
      server.credentialProtection,
      CredentialProtection.appPasswordWithBiometric,
    );
    expect(await repository.unlock(server), same(_credential));
    expect(
      (await repository.unlock(server, appPassword: '123456'))?.toVaultJson(),
      _credential.toVaultJson(),
    );
  });

  test('saved login cannot bypass the TrueDock app password', () async {
    final biometric = _RecordingVault();
    final appPassword = _RecordingAppPasswordVault();
    final repository = SavedServerRepository(
      vault: biometric,
      appPasswordVault: appPassword,
      metadataStorage: _storage,
    );

    await expectLater(
      repository.register(_profile, _credential, saveCredential: true),
      throwsA(isA<AppPasswordVaultException>()),
    );

    expect(biometric.credentials, isEmpty);
    expect(appPassword.credentials, isEmpty);
    expect(await repository.list(), isEmpty);
  });

  test('global reset clears only app-password sign-ins', () async {
    final biometric = _RecordingVault();
    final appPassword = _RecordingAppPasswordVault();
    final repository = SavedServerRepository(
      vault: biometric,
      appPasswordVault: appPassword,
      metadataStorage: _storage,
    );
    final biometricProfile = ServerProfile(
      name: 'Biometric NAS',
      baseUri: Uri.parse('https://biometric.local'),
    );
    await repository.register(
      _profile,
      _credential,
      saveCredential: true,
      appPassword: '123456',
    );
    await biometric.save(biometricProfile, _credential);
    await _storage.write(
      key: 'server.${biometricProfile.id}',
      value: jsonEncode(
        SavedServer(
          profile: biometricProfile,
          username: _credential.username,
          authMethod: AuthMethod.apiKey,
          hasSavedCredential: true,
          credentialProtection: CredentialProtection.biometric,
        ).toJson(),
      ),
    );

    await repository.clearAllAppPasswordCredentials();

    final servers = await repository.list();
    final reset = servers.firstWhere(
      (server) => server.profile.id == _profile.id,
    );
    final preserved = servers.firstWhere(
      (server) => server.profile.id == biometricProfile.id,
    );
    expect(reset.hasSavedCredential, isFalse);
    expect(reset.credentialProtection, CredentialProtection.none);
    expect(preserved.hasSavedCredential, isTrue);
    expect(preserved.credentialProtection, CredentialProtection.biometric);
    expect(biometric.credentials[biometricProfile.id], same(_credential));
    expect(appPassword.cleared, isTrue);
  });

  test('failed first registration rolls back the global verifier', () async {
    final appPassword = _RecordingAppPasswordVault();
    final repository = SavedServerRepository(
      vault: _RecordingVault(),
      appPasswordVault: appPassword,
      metadataStorage: _FailingMetadataStorage(),
    );

    await expectLater(
      repository.register(
        _profile,
        _credential,
        saveCredential: true,
        appPassword: '123456',
      ),
      throwsStateError,
    );

    expect(appPassword.cleared, isTrue);
    expect(await appPassword.isConfigured(), isFalse);
    expect(appPassword.credentials, isEmpty);
  });

  test('forget removes both the registered profile and credential', () async {
    final vault = _RecordingVault();
    final repository = SavedServerRepository(
      vault: vault,
      metadataStorage: _storage,
    );
    await repository.register(
      _profile,
      _credential,
      saveCredential: true,
      appPassword: '123456',
      enableBiometricUnlock: true,
    );

    await repository.delete(_profile);

    expect(await repository.list(), isEmpty);
    expect(vault.credentials, isEmpty);
  });

  test('device reset clears profiles and every credential vault', () async {
    final biometric = _RecordingVault();
    final appPassword = _RecordingAppPasswordVault();
    final repository = SavedServerRepository(
      vault: biometric,
      appPasswordVault: appPassword,
      metadataStorage: _storage,
    );
    await repository.register(
      _profile,
      _credential,
      saveCredential: true,
      appPassword: '123456',
      enableBiometricUnlock: true,
    );

    await repository.clearAllDeviceData();

    expect(await repository.list(), isEmpty);
    expect(biometric.credentials, isEmpty);
    expect(appPassword.credentials, isEmpty);
    expect(appPassword.cleared, isTrue);
    expect(await _storage.readAll(), isEmpty);
  });
}
