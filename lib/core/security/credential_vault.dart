import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../features/connection/domain/auth_credential.dart';
import '../../features/connection/domain/server_profile.dart';
import '../../l10n/app_localizations_en.dart';

enum BiometricVaultStatus { available, unsupported, notEnrolled, unavailable }

class BiometricVaultAvailability {
  const BiometricVaultAvailability(
    this.status, {
    this.types = const [],
    this.canUseAppPassword = false,
  });

  final BiometricVaultStatus status;
  final List<BiometricType> types;
  final bool canUseAppPassword;

  bool get canSave => status == BiometricVaultStatus.available;

  String get description => switch (status) {
    BiometricVaultStatus.available => 'Protected by device biometrics',
    BiometricVaultStatus.notEnrolled =>
      'Set up Face ID, Touch ID, or fingerprint first',
    BiometricVaultStatus.unsupported =>
      'This device does not support biometric sign-in',
    BiometricVaultStatus.unavailable =>
      'Biometric sign-in is currently unavailable',
  };
}

abstract interface class CredentialVault {
  Future<BiometricVaultAvailability> availability();
  Future<void> save(ServerProfile profile, AuthCredential credential);
  Future<AuthCredential?> unlock(ServerProfile profile);
  Future<void> delete(ServerProfile profile);
}

/// The strings Android shows in its system biometric prompt.
///
/// The prompt is drawn by the OS, not by Flutter, so the text has to be handed
/// to the platform channel up front rather than resolved from a
/// [BuildContext]. [BiometricPromptStrings.fallback] keeps the English wording
/// used before a locale is known.
class BiometricPromptStrings {
  const BiometricPromptStrings({
    required this.title,
    required this.subtitle,
    required this.negativeButton,
  });

  /// English ARB wording, used until the app supplies the active locale.
  static final fallback = _englishFallback();

  static BiometricPromptStrings _englishFallback() {
    final l10n = AppLocalizationsEn();
    return BiometricPromptStrings(
      title: l10n.securityBiometricPromptTitle,
      subtitle: l10n.securityBiometricPromptSubtitle,
      negativeButton: l10n.securityBiometricPromptCancel,
    );
  }

  final String title;
  final String subtitle;
  final String negativeButton;
}

class PlatformCredentialVault implements CredentialVault {
  PlatformCredentialVault({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuthentication,
    BiometricPromptStrings? prompt,
  }) : _storage =
           storage ?? _createStorage(prompt ?? BiometricPromptStrings.fallback),
       _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _prompt = prompt ?? BiometricPromptStrings.fallback;

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuthentication;
  final BiometricPromptStrings _prompt;

  static FlutterSecureStorage _createStorage(BiometricPromptStrings prompt) =>
      FlutterSecureStorage(
        iOptions: const IOSOptions(
          accountName: 'me.aroxu.truedock.credentials',
          accessibility: KeychainAccessibility.passcode,
          synchronizable: false,
        ),
        aOptions: AndroidOptions(
          storageNamespace: 'truedock_credentials',
          resetOnError: false,
        ),
      );

  String _key(ServerProfile profile) => 'credential.${profile.id}';

  @override
  Future<BiometricVaultAvailability> availability() async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      return const BiometricVaultAvailability(BiometricVaultStatus.unsupported);
    }
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      if (!supported) {
        return BiometricVaultAvailability(
          BiometricVaultStatus.unsupported,
          canUseAppPassword: Platform.isAndroid,
        );
      }
      final types = await _localAuthentication.getAvailableBiometrics();
      if (types.isEmpty) {
        return BiometricVaultAvailability(
          BiometricVaultStatus.notEnrolled,
          canUseAppPassword: Platform.isAndroid,
        );
      }
      return BiometricVaultAvailability(
        BiometricVaultStatus.available,
        types: types,
      );
    } on LocalAuthException {
      return const BiometricVaultAvailability(BiometricVaultStatus.unavailable);
    } on PlatformException {
      return const BiometricVaultAvailability(BiometricVaultStatus.unavailable);
    }
  }

  @override
  Future<void> save(ServerProfile profile, AuthCredential credential) async {
    final support = await availability();
    if (!support.canSave) {
      throw CredentialVaultException(support.description);
    }
    try {
      await _storage.write(
        key: _key(profile),
        value: jsonEncode(credential.toVaultJson()),
      );
    } on PlatformException catch (error) {
      throw CredentialVaultException(
        error.message ?? 'Could not protect the saved credential.',
      );
    }
  }

  @override
  Future<AuthCredential?> unlock(ServerProfile profile) async {
    try {
      final key = _key(profile);
      if (!await _storage.containsKey(key: key)) return null;
      await _requireAuthentication();
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Saved credential is invalid.');
      }
      return AuthCredential.fromVaultJson(decoded);
    } on FormatException {
      rethrow;
    } on PlatformException catch (error) {
      throw CredentialVaultException(
        error.message ?? 'Biometric authentication was not completed.',
      );
    }
  }

  /// Requires a successful device authentication, or throws.
  ///
  /// Biometric Unlock is deliberately biometric-only. The TrueDock app
  /// password is the explicit fallback, so a device PIN/passcode must not
  /// silently become a second way to decrypt a saved server sign-in.
  ///
  /// The reason string is the one piece of wording the app controls without
  /// pulling in `local_auth_ios`/`local_auth_android` for their message
  /// classes; the surrounding button labels stay with the platform defaults,
  /// which are already localized by the OS.
  Future<void> _requireAuthentication() async {
    final bool authenticated;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: _prompt.subtitle,
        biometricOnly: true,
      );
    } on LocalAuthException catch (error) {
      throw CredentialVaultException(
        error.description ?? 'Authentication was not completed.',
      );
    }
    if (!authenticated) {
      throw const CredentialVaultException(
        'Authentication was cancelled, so the saved credential stays locked.',
      );
    }
  }

  @override
  Future<void> delete(ServerProfile profile) =>
      _storage.delete(key: _key(profile));

  /// Removes every credential in this app-specific Keychain/Keystore
  /// namespace, including entries whose server metadata was damaged or lost.
  Future<void> clearAll() => _storage.deleteAll();
}

class CredentialVaultException implements Exception {
  const CredentialVaultException(this.message);

  final String message;

  @override
  String toString() => message;
}
