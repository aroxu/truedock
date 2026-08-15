import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:true_dock/core/security/credential_vault.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

/// Records whether the app asked for identity, and answers however the test
/// wants.
class _FakeAuth implements LocalAuthentication {
  _FakeAuth({this.succeeds = true, this.throws});

  final bool succeeds;
  final Object? throws;
  int prompts = 0;
  String? reason;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const <Object>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    prompts++;
    reason = localizedReason;
    if (throws case final error?) throw error;
    return succeeds;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An in-memory stand-in for the platform keystore.
class _FakeStorage implements FlutterSecureStorage {
  _FakeStorage([this._values = const {}]);

  final Map<String, String> _values;
  int existenceChecks = 0;
  int reads = 0;

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    existenceChecks++;
    return _values.containsKey(key);
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    return _values[key];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _profile = ServerProfile(
  name: 'nas',
  baseUri: Uri.parse('https://nas.local'),
);

String get _storedCredential {
  const credential = ApiKeyCredential(username: 'admin', apiKey: 'secret');
  return '{"method":"api_key","username":"admin","secret":"secret"}'
  // Keep the fixture honest: if the vault format changes, this fails.
  .replaceAll('secret', credential.apiKey);
}

void main() {
  test('unlocking a saved credential asks for identity first', () async {
    // The defect this pins: `local_auth.authenticate` was never called
    // anywhere in the app. The vault relied on the Keychain/Keystore raising a
    // prompt as a side effect of reading, which is invisible from here and not
    // guaranteed, so a saved credential could be handed over silently.
    final auth = _FakeAuth();
    final storage = _FakeStorage({
      'credential.${_profile.id}': _storedCredential,
    });
    final vault = PlatformCredentialVault(
      storage: storage,
      localAuthentication: auth,
    );

    final credential = await vault.unlock(_profile);

    expect(auth.prompts, 1, reason: 'the user was never asked to authenticate');
    expect(storage.existenceChecks, 1);
    expect(storage.reads, 1);
    expect(credential, isA<ApiKeyCredential>());
  });

  test('a cancelled prompt keeps the credential locked', () async {
    // Returning null here would read as "no credential saved" and send the
    // user to a fresh sign-in; it has to be an explicit refusal instead.
    final auth = _FakeAuth(succeeds: false);
    final vault = PlatformCredentialVault(
      storage: _FakeStorage({'credential.${_profile.id}': _storedCredential}),
      localAuthentication: auth,
    );

    await expectLater(
      vault.unlock(_profile),
      throwsA(isA<CredentialVaultException>()),
    );
    expect(auth.prompts, 1);
  });

  test('no prompt when nothing is stored for that server', () async {
    // Asking for a fingerprint and then reporting "nothing saved" would be a
    // pointless interruption, so the non-secret existence check comes first.
    final auth = _FakeAuth();
    final storage = _FakeStorage();
    final vault = PlatformCredentialVault(
      storage: storage,
      localAuthentication: auth,
    );

    expect(await vault.unlock(_profile), isNull);
    expect(auth.prompts, isZero);
    expect(storage.reads, isZero);
  });

  test('the prompt uses the localized reason the app supplies', () async {
    // Android draws the prompt itself, so the wording has to be handed over
    // rather than resolved from a BuildContext at display time.
    final auth = _FakeAuth();
    final vault = PlatformCredentialVault(
      storage: _FakeStorage({'credential.${_profile.id}': _storedCredential}),
      localAuthentication: auth,
      prompt: const BiometricPromptStrings(
        title: '제목',
        subtitle: '저장된 서버에 접근하려면 인증하세요',
        negativeButton: '취소',
      ),
    );

    await vault.unlock(_profile);

    expect(auth.reason, '저장된 서버에 접근하려면 인증하세요');
  });

  test(
    'a platform authentication failure is reported, not swallowed',
    () async {
      final vault = PlatformCredentialVault(
        storage: _FakeStorage({'credential.${_profile.id}': _storedCredential}),
        localAuthentication: _FakeAuth(
          throws: LocalAuthException(
            code: LocalAuthExceptionCode.uiUnavailable,
            description: 'Sensor unavailable',
          ),
        ),
      );

      await expectLater(
        vault.unlock(_profile),
        throwsA(
          isA<CredentialVaultException>().having(
            (error) => error.message,
            'message',
            contains('Sensor unavailable'),
          ),
        ),
      );
    },
  );
}
