import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/connection/domain/server_profile.dart';

class TlsCertificateIdentity {
  const TlsCertificateIdentity({
    required this.sha256,
    required this.subject,
    required this.issuer,
    required this.validFrom,
    required this.validTo,
    required this.isTrustedBySystem,
  });

  final String sha256;
  final String subject;
  final String issuer;
  final DateTime validFrom;
  final DateTime validTo;
  final bool isTrustedBySystem;

  /// True once [validTo] has already passed at [now].
  bool isExpiredAt(DateTime now) => now.isAfter(validTo);

  /// True when the certificate expires within [window] of [now] but has not
  /// expired yet. Used to warn ahead of an outage instead of only after one.
  bool isExpiringSoonAt(
    DateTime now, {
    Duration window = const Duration(days: 14),
  }) => !isExpiredAt(now) && validTo.difference(now) <= window;

  String get formattedSha256 {
    final buffer = StringBuffer();
    for (var index = 0; index < sha256.length; index += 2) {
      if (buffer.isNotEmpty) buffer.write(':');
      buffer.write(sha256.substring(index, index + 2).toUpperCase());
    }
    return buffer.toString();
  }
}

abstract interface class TlsCertificateInspector {
  Future<TlsCertificateIdentity> inspect(Uri uri);
}

class IoTlsCertificateInspector implements TlsCertificateInspector {
  const IoTlsCertificateInspector();

  @override
  Future<TlsCertificateIdentity> inspect(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'wss') {
      throw const TlsCertificateException(
        'TrueDock only inspects secure TLS endpoints.',
      );
    }

    var systemTrusted = true;
    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        uri.host,
        uri.hasPort ? uri.port : 443,
        timeout: const Duration(seconds: 12),
        onBadCertificate: (_) {
          systemTrusted = false;
          return true;
        },
      );
      final certificate = socket.peerCertificate;
      if (certificate == null) {
        throw const TlsCertificateException(
          'The server did not present a TLS certificate.',
        );
      }
      return TlsCertificateIdentity(
        sha256: sha256.convert(certificate.der).toString(),
        subject: certificate.subject,
        issuer: certificate.issuer,
        validFrom: certificate.startValidity,
        validTo: certificate.endValidity,
        isTrustedBySystem: systemTrusted,
      );
    } on TlsCertificateException {
      rethrow;
    } on Object catch (error) {
      throw TlsCertificateException(
        'Could not inspect the server certificate: $error',
      );
    } finally {
      await socket?.close();
    }
  }
}

abstract interface class CertificateTrustStore {
  Future<String?> readFingerprint(String serverId);
  Future<void> writeFingerprint(String serverId, String fingerprint);
  Future<void> deleteFingerprint(String serverId);
}

typedef SecureWebSocketOpener =
    Future<WebSocketChannel> Function(
      ServerProfile profile,
      TlsCertificateIdentity certificate,
      bool allowPinnedCertificate,
    );

/// A live channel paired with the certificate that was verified to open it.
///
/// Callers that need to warn about an expiring certificate cannot re-inspect
/// the socket after the fact, so the identity travels with the channel.
class SecureWebSocketConnection {
  const SecureWebSocketConnection({
    required this.channel,
    required this.certificate,
  });

  final WebSocketChannel channel;
  final TlsCertificateIdentity certificate;
}

class SecureCertificateTrustStore implements CertificateTrustStore {
  SecureCertificateTrustStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accountName: 'me.aroxu.truedock.certificate-trust',
              accessibility: KeychainAccessibility.unlocked_this_device,
              synchronizable: false,
            ),
            aOptions: AndroidOptions(
              storageNamespace: 'truedock_certificate_trust',
              resetOnError: false,
            ),
          );

  final FlutterSecureStorage _storage;

  String _key(String serverId) => 'tls.$serverId';

  @override
  Future<String?> readFingerprint(String serverId) =>
      _storage.read(key: _key(serverId));

  @override
  Future<void> writeFingerprint(String serverId, String fingerprint) =>
      _storage.write(key: _key(serverId), value: fingerprint.toLowerCase());

  @override
  Future<void> deleteFingerprint(String serverId) =>
      _storage.delete(key: _key(serverId));

  /// Clears the app-specific certificate trust namespace on both platforms.
  Future<void> clearAll() => _storage.deleteAll();
}

class SecureWebSocketTransport {
  SecureWebSocketTransport({
    TlsCertificateInspector? inspector,
    CertificateTrustStore? trustStore,
    SecureWebSocketOpener? opener,
  }) : _inspector = inspector ?? const IoTlsCertificateInspector(),
       _trustStore = trustStore ?? SecureCertificateTrustStore(),
       _opener = opener ?? _openChannel;

  final TlsCertificateInspector _inspector;
  final CertificateTrustStore _trustStore;
  final SecureWebSocketOpener _opener;

  Future<SecureWebSocketConnection> connect(ServerProfile profile) async {
    final certificate = await _inspector.inspect(profile.websocketUri);
    final savedFingerprint =
        profile.pinnedCertificateSha256 ??
        await _trustStore.readFingerprint(profile.id);

    if (savedFingerprint != null &&
        savedFingerprint.toLowerCase() != certificate.sha256.toLowerCase()) {
      throw TlsCertificateTrustRequired(
        certificate: certificate,
        previousFingerprint: savedFingerprint,
      );
    }

    // Every previously unseen certificate must be shown to the user, even
    // when the operating system already trusts its issuer. Approval pins the
    // exact certificate to this server profile and prevents this prompt from
    // repeating until the certificate changes.
    if (savedFingerprint == null) {
      throw TlsCertificateTrustRequired(certificate: certificate);
    }

    // The same certificate is still pinned, but it has expired since it was
    // trusted. Ask again rather than silently connecting through it.
    if (certificate.isExpiredAt(DateTime.now())) {
      throw TlsCertificateTrustRequired(
        certificate: certificate,
        isExpired: true,
      );
    }

    final channel = await _opener(
      profile,
      certificate,
      !certificate.isTrustedBySystem,
    );
    return SecureWebSocketConnection(
      channel: channel,
      certificate: certificate,
    );
  }

  static Future<WebSocketChannel> _openChannel(
    ServerProfile profile,
    TlsCertificateIdentity certificate,
    bool allowPinnedCertificate,
  ) async {
    final client = HttpClient();
    if (allowPinnedCertificate) {
      client.badCertificateCallback = (presented, host, port) {
        final fingerprint = sha256.convert(presented.der).toString();
        return host == profile.baseUri.host &&
            port == (profile.baseUri.hasPort ? profile.baseUri.port : 443) &&
            fingerprint.toLowerCase() == certificate.sha256.toLowerCase();
      };
    }

    try {
      final channel = IOWebSocketChannel.connect(
        profile.websocketUri,
        customClient: client,
        connectTimeout: const Duration(seconds: 15),
        pingInterval: const Duration(seconds: 20),
      );
      await channel.ready.timeout(const Duration(seconds: 15));
      client.close();
      return channel;
    } on Object {
      client.close(force: true);
      rethrow;
    }
  }

  Future<ServerProfile> trust(
    ServerProfile profile,
    TlsCertificateIdentity certificate,
  ) async {
    await _trustStore.writeFingerprint(profile.id, certificate.sha256);
    return profile.copyWith(pinnedCertificateSha256: certificate.sha256);
  }
}

/// Resolves and verifies the certificate pin used by non-WebSocket transports.
///
/// A trusted self-signed certificate can live only in the secure trust store:
/// older saved profile objects do not necessarily carry the fingerprint. HTTP
/// uploads must therefore consult the same store as the WebSocket transport.
class SecureHttpCertificatePolicy {
  SecureHttpCertificatePolicy({
    TlsCertificateInspector? inspector,
    CertificateTrustStore? trustStore,
  }) : _inspector = inspector ?? const IoTlsCertificateInspector(),
       _trustStore = trustStore ?? SecureCertificateTrustStore();

  final TlsCertificateInspector _inspector;
  final CertificateTrustStore _trustStore;

  Future<TlsCertificateIdentity> verify(ServerProfile profile) async {
    final certificate = await _inspector.inspect(profile.baseUri);
    final savedFingerprint =
        profile.pinnedCertificateSha256 ??
        await _trustStore.readFingerprint(profile.id);

    if (savedFingerprint != null &&
        savedFingerprint.toLowerCase() != certificate.sha256.toLowerCase()) {
      throw TlsCertificateTrustRequired(
        certificate: certificate,
        previousFingerprint: savedFingerprint,
      );
    }
    if (!certificate.isTrustedBySystem && savedFingerprint == null) {
      throw TlsCertificateTrustRequired(certificate: certificate);
    }
    if (savedFingerprint != null && certificate.isExpiredAt(DateTime.now())) {
      throw TlsCertificateTrustRequired(
        certificate: certificate,
        isExpired: true,
      );
    }
    return certificate;
  }
}

class TlsCertificateTrustRequired implements Exception {
  const TlsCertificateTrustRequired({
    required this.certificate,
    this.previousFingerprint,
    this.isExpired = false,
  });

  final TlsCertificateIdentity certificate;
  final String? previousFingerprint;

  /// True when the same certificate is still pinned/trusted but has expired.
  ///
  /// Distinct from [isCertificateChange]: the fingerprint has not changed, so
  /// this is a warning about the certificate itself, not about a possible
  /// impersonation.
  final bool isExpired;

  bool get isCertificateChange => previousFingerprint != null;
}

class TlsCertificateException implements Exception {
  const TlsCertificateException(this.message);

  final String message;

  @override
  String toString() => message;
}
