import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/connection/domain/auth_credential.dart';
import '../../features/connection/domain/server_profile.dart';

const trueDockPinLength = 6;

bool isValidTrueDockPin(String value) => RegExp(r'^\d{6}$').hasMatch(value);

/// Versioned Argon2id + AES-256-GCM envelope used by Android devices that
/// cannot offer a usable system biometric prompt.
class AppPasswordVaultCodec {
  AppPasswordVaultCodec({
    Argon2id? keyDerivation,
    Cipher? cipher,
    Random? random,
  }) : _keyDerivation =
           keyDerivation ??
           Argon2id(
             memory: memoryKib,
             parallelism: parallelism,
             iterations: iterations,
             hashLength: keyLength,
           ),
       _cipher = cipher ?? AesGcm.with256bits(),
       _random = random ?? SecureRandom.defaultRandom;

  static const version = 1;
  static const memoryKib = 19 * 1024;
  static const parallelism = 1;
  static const iterations = 2;
  static const keyLength = 32;
  static const saltLength = 16;

  final Argon2id _keyDerivation;
  final Cipher _cipher;
  final Random _random;

  Future<String> encrypt({
    required String clearText,
    required String password,
    required String context,
  }) async {
    _validateNewPin(password);
    final salt = List<int>.generate(saltLength, (_) => _random.nextInt(256));
    final key = await _keyDerivation.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final box = await _cipher.encrypt(
      utf8.encode(clearText),
      secretKey: key,
      aad: _associatedData(context),
    );
    return jsonEncode({
      'version': version,
      'protection': 'app_password',
      'kdf': {
        'algorithm': 'argon2id',
        'memory_kib': memoryKib,
        'iterations': iterations,
        'parallelism': parallelism,
        'key_length': keyLength,
      },
      'salt': base64Encode(salt),
      'box': base64Encode(box.concatenation()),
    });
  }

  Future<String> decrypt({
    required String envelope,
    required String password,
    required String context,
  }) async {
    _validateNewPin(password);
    try {
      final decoded = jsonDecode(envelope);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != version ||
          decoded['protection'] != 'app_password') {
        throw const AppPasswordVaultException(
          'The saved credential uses an unsupported vault format.',
        );
      }
      final kdf = decoded['kdf'];
      if (kdf is! Map<String, dynamic> ||
          kdf['algorithm'] != 'argon2id' ||
          kdf['memory_kib'] != memoryKib ||
          kdf['iterations'] != iterations ||
          kdf['parallelism'] != parallelism ||
          kdf['key_length'] != keyLength) {
        throw const AppPasswordVaultException(
          'The saved credential uses unsupported key settings.',
        );
      }
      final salt = base64Decode(decoded['salt'] as String);
      if (salt.length != saltLength) {
        throw const AppPasswordVaultException('The saved vault is damaged.');
      }
      final concatenated = base64Decode(decoded['box'] as String);
      final box = SecretBox.fromConcatenation(
        concatenated,
        nonceLength: _cipher.nonceLength,
        macLength: _cipher.macAlgorithm.macLength,
      );
      final key = await _keyDerivation.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      final clearBytes = await _cipher.decrypt(
        box,
        secretKey: key,
        aad: _associatedData(context),
      );
      return utf8.decode(clearBytes);
    } on AppPasswordVaultException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const AppPasswordVaultException('The TrueDock PIN is incorrect.');
    } on Object {
      throw const AppPasswordVaultException('The saved vault is damaged.');
    }
  }

  List<int> _associatedData(String context) =>
      utf8.encode('me.aroxu.truedock:v$version:$context');

  void _validateNewPin(String pin) {
    if (!isValidTrueDockPin(pin)) {
      throw const AppPasswordVaultException('Enter the 6-digit TrueDock PIN.');
    }
  }
}

class AppPasswordVaultException implements Exception {
  const AppPasswordVaultException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AppPasswordCredentialVault {
  Future<bool> isConfigured();

  Future<void> configurePassword(String password);

  Future<void> verifyPassword(String password);

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    Map<ServerProfile, AuthCredential> credentials,
  );

  Future<void> save(
    ServerProfile profile,
    AuthCredential credential,
    String password,
  );

  Future<AuthCredential?> unlock(ServerProfile profile, String password);

  Future<void> delete(ServerProfile profile);

  Future<void> clearAll();
}

class PlatformAppPasswordCredentialVault implements AppPasswordCredentialVault {
  PlatformAppPasswordCredentialVault({
    FlutterSecureStorage? storage,
    AppPasswordVaultCodec? codec,
  }) : _storage = storage ?? _createStorage(),
       _codec = codec ?? AppPasswordVaultCodec();

  final FlutterSecureStorage _storage;
  final AppPasswordVaultCodec _codec;

  static FlutterSecureStorage _createStorage() => const FlutterSecureStorage(
    iOptions: IOSOptions(
      accountName: 'me.aroxu.truedock.app-password-vault',
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
    aOptions: AndroidOptions(
      storageNamespace: 'truedock_app_password_vault',
      resetOnError: false,
    ),
  );

  String _key(ServerProfile profile) => 'credential.${profile.id}';
  static const _verifierKey = 'vault.verifier';
  static const _verifierContext = 'global-app-password';
  static const _verifierClearText = 'TrueDock app password verifier v1';

  @override
  Future<bool> isConfigured() => _storage.containsKey(key: _verifierKey);

  @override
  Future<void> configurePassword(String password) =>
      _verifyOrConfigure(password);

  @override
  Future<void> verifyPassword(String password) => _verify(password);

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    Map<ServerProfile, AuthCredential> credentials,
  ) async {
    await _verify(currentPassword);
    _codec._validateNewPin(newPassword);

    final replacements = <String, String>{};
    for (final entry in credentials.entries) {
      replacements[_key(entry.key)] = await _codec.encrypt(
        clearText: jsonEncode(entry.value.toVaultJson()),
        password: newPassword,
        context: entry.key.id,
      );
    }
    replacements[_verifierKey] = await _codec.encrypt(
      clearText: _verifierClearText,
      password: newPassword,
      context: _verifierContext,
    );

    final previous = <String, String?>{};
    try {
      for (final key in replacements.keys) {
        previous[key] = await _storage.read(key: key);
      }
      // Write the verifier last. Until then the current password remains the
      // authoritative key; a partial write is rolled back below.
      for (final entry in replacements.entries.where(
        (entry) => entry.key != _verifierKey,
      )) {
        await _storage.write(key: entry.key, value: entry.value);
      }
      await _storage.write(
        key: _verifierKey,
        value: replacements[_verifierKey],
      );
    } on Object {
      for (final entry in previous.entries) {
        if (entry.value == null) {
          await _storage.delete(key: entry.key);
        } else {
          await _storage.write(key: entry.key, value: entry.value);
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> save(
    ServerProfile profile,
    AuthCredential credential,
    String password,
  ) async {
    try {
      await _verifyOrConfigure(password);
      final envelope = await _codec.encrypt(
        clearText: jsonEncode(credential.toVaultJson()),
        password: password,
        context: profile.id,
      );
      await _storage.write(key: _key(profile), value: envelope);
    } on AppPasswordVaultException {
      rethrow;
    } on PlatformException catch (error) {
      throw AppPasswordVaultException(
        error.message ?? 'Could not save the encrypted credential.',
      );
    }
  }

  @override
  Future<AuthCredential?> unlock(ServerProfile profile, String password) async {
    try {
      await _verify(password);
      final envelope = await _storage.read(key: _key(profile));
      if (envelope == null) return null;
      final clearText = await _codec.decrypt(
        envelope: envelope,
        password: password,
        context: profile.id,
      );
      final decoded = jsonDecode(clearText);
      if (decoded is! Map<String, dynamic>) {
        throw const AppPasswordVaultException('The saved vault is damaged.');
      }
      return AuthCredential.fromVaultJson(decoded);
    } on AppPasswordVaultException {
      rethrow;
    } on FormatException {
      throw const AppPasswordVaultException('The saved vault is damaged.');
    } on PlatformException catch (error) {
      throw AppPasswordVaultException(
        error.message ?? 'Could not read the encrypted credential.',
      );
    }
  }

  @override
  Future<void> delete(ServerProfile profile) =>
      _storage.delete(key: _key(profile));

  @override
  Future<void> clearAll() => _storage.deleteAll();

  Future<void> _verifyOrConfigure(String password) async {
    final verifier = await _storage.read(key: _verifierKey);
    if (verifier != null) {
      await _verify(password, envelope: verifier);
      return;
    }
    final envelope = await _codec.encrypt(
      clearText: _verifierClearText,
      password: password,
      context: _verifierContext,
    );
    await _storage.write(key: _verifierKey, value: envelope);
  }

  Future<void> _verify(String password, {String? envelope}) async {
    final saved = envelope ?? await _storage.read(key: _verifierKey);
    if (saved == null) {
      throw const AppPasswordVaultException(
        'The TrueDock PIN has not been created.',
      );
    }
    final clearText = await _codec.decrypt(
      envelope: saved,
      password: password,
      context: _verifierContext,
    );
    if (clearText != _verifierClearText) {
      throw const AppPasswordVaultException('The saved vault is damaged.');
    }
  }
}
