import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/security/tls_certificate_service.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

void main() {
  final profile = ServerProfile.parse(
    name: 'Home NAS',
    address: 'https://nas.local',
  );

  test('formats the SHA-256 fingerprint for human comparison', () {
    final certificate = _certificate('aabbccdd', trusted: false);

    expect(certificate.formattedSha256, 'AA:BB:CC:DD');
  });

  test('reports expiry relative to a given instant', () {
    final certificate = TlsCertificateIdentity(
      sha256: 'aa' * 32,
      subject: '/CN=nas.local',
      issuer: '/CN=TrueNAS',
      validFrom: DateTime.utc(2026),
      validTo: DateTime.utc(2026, 6, 1),
      isTrustedBySystem: true,
    );

    expect(certificate.isExpiredAt(DateTime.utc(2026, 5, 1)), isFalse);
    expect(certificate.isExpiredAt(DateTime.utc(2026, 7, 1)), isTrue);
    expect(
      certificate.isExpiringSoonAt(
        DateTime.utc(2026, 5, 25),
        window: const Duration(days: 14),
      ),
      isTrue,
    );
    expect(
      certificate.isExpiringSoonAt(
        DateTime.utc(2026, 5, 1),
        window: const Duration(days: 14),
      ),
      isFalse,
    );
    // Already expired is not "expiring soon"; it needs its own handling.
    expect(
      certificate.isExpiringSoonAt(
        DateTime.utc(2026, 7, 1),
        window: const Duration(days: 14),
      ),
      isFalse,
    );
  });

  test(
    'reports the certificate verified for the most recent connection',
    () async {
      final certificate = _certificate('cc' * 32, trusted: true);
      final store = _MemoryTrustStore()
        ..values[profile.id] = certificate.sha256;
      final transport = SecureWebSocketTransport(
        inspector: _FixedInspector(certificate),
        trustStore: store,
        opener: (_, _, _) async => throw const _ChannelOpened(),
      );

      await expectLater(
        transport.connect(profile),
        throwsA(isA<_ChannelOpened>()),
      );
    },
  );

  test('requires explicit trust before opening an untrusted server', () async {
    final store = _MemoryTrustStore();
    var opened = false;
    final transport = SecureWebSocketTransport(
      inspector: _FixedInspector(_certificate('aa' * 32, trusted: false)),
      trustStore: store,
      opener: (_, _, _) async {
        opened = true;
        throw const _ChannelOpened();
      },
    );

    await expectLater(
      transport.connect(profile),
      throwsA(
        isA<TlsCertificateTrustRequired>()
            .having((error) => error.isCertificateChange, 'changed', false)
            .having(
              (error) => error.certificate.sha256,
              'fingerprint',
              'aa' * 32,
            ),
      ),
    );
    expect(opened, isFalse);
  });

  test('opens only the explicitly pinned untrusted certificate', () async {
    final certificate = _certificate('bb' * 32, trusted: false);
    final store = _MemoryTrustStore();
    late bool allowedPinnedCertificate;
    final transport = SecureWebSocketTransport(
      inspector: _FixedInspector(certificate),
      trustStore: store,
      opener: (_, observed, allowPinned) async {
        expect(observed.sha256, certificate.sha256);
        allowedPinnedCertificate = allowPinned;
        throw const _ChannelOpened();
      },
    );

    final pinnedProfile = await transport.trust(profile, certificate);
    expect(store.values[profile.id], certificate.sha256);
    await expectLater(
      transport.connect(pinnedProfile),
      throwsA(isA<_ChannelOpened>()),
    );
    expect(allowedPinnedCertificate, isTrue);
  });

  test('stops when a previously trusted certificate changes', () async {
    final store = _MemoryTrustStore()..values[profile.id] = '11' * 32;
    final transport = SecureWebSocketTransport(
      inspector: _FixedInspector(_certificate('22' * 32, trusted: true)),
      trustStore: store,
      opener: (_, _, _) async => throw const _ChannelOpened(),
    );

    await expectLater(
      transport.connect(profile),
      throwsA(
        isA<TlsCertificateTrustRequired>()
            .having((error) => error.isCertificateChange, 'changed', true)
            .having(
              (error) => error.previousFingerprint,
              'previous fingerprint',
              '11' * 32,
            ),
      ),
    );
  });

  test(
    'requires verification for a previously unseen trusted certificate',
    () async {
      var opened = false;
      final certificate = _certificate('33' * 32, trusted: true);
      final store = _MemoryTrustStore();
      final transport = SecureWebSocketTransport(
        inspector: _FixedInspector(certificate),
        trustStore: store,
        opener: (_, _, allowPinned) async {
          opened = true;
          throw const _ChannelOpened();
        },
      );

      await expectLater(
        transport.connect(profile),
        throwsA(
          isA<TlsCertificateTrustRequired>().having(
            (error) => error.certificate.isTrustedBySystem,
            'system trusted',
            true,
          ),
        ),
      );
      expect(opened, isFalse);

      final pinnedProfile = await transport.trust(profile, certificate);
      await expectLater(
        transport.connect(pinnedProfile),
        throwsA(isA<_ChannelOpened>()),
      );
    },
  );

  test('HTTP policy reads a self-signed pin from the secure store', () async {
    final certificate = _certificate('44' * 32, trusted: false);
    final store = _MemoryTrustStore()..values[profile.id] = certificate.sha256;
    final policy = SecureHttpCertificatePolicy(
      inspector: _FixedInspector(certificate),
      trustStore: store,
    );

    final verified = await policy.verify(profile);

    expect(verified.sha256, certificate.sha256);
    expect(verified.isTrustedBySystem, isFalse);
  });

  test('HTTP policy refuses a changed certificate from the secure store', () {
    final store = _MemoryTrustStore()..values[profile.id] = '55' * 32;
    final policy = SecureHttpCertificatePolicy(
      inspector: _FixedInspector(_certificate('66' * 32, trusted: false)),
      trustStore: store,
    );

    expect(
      policy.verify(profile),
      throwsA(
        isA<TlsCertificateTrustRequired>()
            .having((error) => error.isCertificateChange, 'changed', true)
            .having(
              (error) => error.previousFingerprint,
              'previous fingerprint',
              '55' * 32,
            ),
      ),
    );
  });
}

TlsCertificateIdentity _certificate(
  String fingerprint, {
  required bool trusted,
}) {
  return TlsCertificateIdentity(
    sha256: fingerprint,
    subject: '/CN=nas.local',
    issuer: '/CN=TrueNAS',
    validFrom: DateTime.utc(2026),
    validTo: DateTime.utc(2030),
    isTrustedBySystem: trusted,
  );
}

class _FixedInspector implements TlsCertificateInspector {
  const _FixedInspector(this.certificate);

  final TlsCertificateIdentity certificate;

  @override
  Future<TlsCertificateIdentity> inspect(Uri uri) async => certificate;
}

class _MemoryTrustStore implements CertificateTrustStore {
  final values = <String, String>{};

  @override
  Future<void> deleteFingerprint(String serverId) async {
    values.remove(serverId);
  }

  @override
  Future<String?> readFingerprint(String serverId) async => values[serverId];

  @override
  Future<void> writeFingerprint(String serverId, String fingerprint) async {
    values[serverId] = fingerprint;
  }
}

class _ChannelOpened implements Exception {
  const _ChannelOpened();
}
