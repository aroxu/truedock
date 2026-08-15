import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/security/app_password_vault.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';

final _firstProfile = ServerProfile(
  name: 'First NAS',
  baseUri: Uri.parse('https://first.local'),
);
final _secondProfile = ServerProfile(
  name: 'Second NAS',
  baseUri: Uri.parse('https://second.local'),
);
const _password = '123456';

AppPasswordVaultCodec _fastCodec([int seed = 7]) => AppPasswordVaultCodec(
  keyDerivation: Argon2id(
    memory: 64,
    parallelism: 1,
    iterations: 1,
    hashLength: 32,
  ),
  random: Random(seed),
);

void main() {
  test(
    'production envelope records the approved Argon2id parameters',
    () async {
      final envelope =
          jsonDecode(
                await AppPasswordVaultCodec().encrypt(
                  clearText: 'credential',
                  password: _password,
                  context: _firstProfile.id,
                ),
              )
              as Map<String, dynamic>;
      final kdf = envelope['kdf'] as Map<String, dynamic>;

      expect(envelope['version'], 1);
      expect(envelope['protection'], 'app_password');
      expect(kdf, {
        'algorithm': 'argon2id',
        'memory_kib': 19 * 1024,
        'iterations': 2,
        'parallelism': 1,
        'key_length': 32,
      });
      expect(base64Decode(envelope['salt'] as String), hasLength(16));
    },
  );

  test('round trips a credential and rejects a wrong PIN', () async {
    final codec = _fastCodec();
    final envelope = await codec.encrypt(
      clearText: 'secret payload',
      password: _password,
      context: _firstProfile.id,
    );

    expect(
      await codec.decrypt(
        envelope: envelope,
        password: _password,
        context: _firstProfile.id,
      ),
      'secret payload',
    );
    await expectLater(
      codec.decrypt(
        envelope: envelope,
        password: '654321',
        context: _firstProfile.id,
      ),
      throwsA(
        isA<AppPasswordVaultException>().having(
          (error) => error.message,
          'message',
          contains('incorrect'),
        ),
      ),
    );
  });

  test('server context prevents moving an encrypted credential', () async {
    final codec = _fastCodec();
    final envelope = await codec.encrypt(
      clearText: 'secret payload',
      password: _password,
      context: _firstProfile.id,
    );

    await expectLater(
      codec.decrypt(
        envelope: envelope,
        password: _password,
        context: _secondProfile.id,
      ),
      throwsA(isA<AppPasswordVaultException>()),
    );
  });

  test('authenticated encryption rejects a modified ciphertext', () async {
    final codec = _fastCodec();
    final decoded =
        jsonDecode(
              await codec.encrypt(
                clearText: 'secret payload',
                password: _password,
                context: _firstProfile.id,
              ),
            )
            as Map<String, dynamic>;
    final box = base64Decode(decoded['box'] as String);
    box[box.length ~/ 2] ^= 1;
    decoded['box'] = base64Encode(box);

    await expectLater(
      codec.decrypt(
        envelope: jsonEncode(decoded),
        password: _password,
        context: _firstProfile.id,
      ),
      throwsA(isA<AppPasswordVaultException>()),
    );
  });

  test('one app PIN unlocks independently encrypted servers', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final vault = PlatformAppPasswordCredentialVault(
      storage: storage,
      codec: _fastCodec(),
    );
    const first = PasswordCredential(username: 'alice', password: 'first');
    const second = ApiKeyCredential(username: 'bob', apiKey: 'second');

    await vault.save(_firstProfile, first, _password);
    await vault.save(_secondProfile, second, _password);

    expect(await vault.isConfigured(), isTrue);
    expect(
      await vault.unlock(_firstProfile, _password),
      isA<PasswordCredential>(),
    );
    expect(
      await vault.unlock(_secondProfile, _password),
      isA<ApiKeyCredential>(),
    );
    final stored = await storage.readAll();
    expect(
      stored['credential.${_firstProfile.id}'],
      isNot(stored['credential.${_secondProfile.id}']),
    );
    expect(jsonEncode(stored), isNot(contains('first')));
    expect(jsonEncode(stored), isNot(contains('second')));
  });

  test('a different PIN cannot add another server', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final vault = PlatformAppPasswordCredentialVault(
      storage: const FlutterSecureStorage(),
      codec: _fastCodec(),
    );
    const credential = PasswordCredential(
      username: 'alice',
      password: 'secret',
    );
    await vault.save(_firstProfile, credential, _password);

    await expectLater(
      vault.save(_secondProfile, credential, '654321'),
      throwsA(isA<AppPasswordVaultException>()),
    );
    expect(await vault.unlock(_secondProfile, _password), isNull);
  });

  test(
    'clearing the global vault removes verifier and every ciphertext',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();
      final vault = PlatformAppPasswordCredentialVault(
        storage: storage,
        codec: _fastCodec(),
      );
      const credential = PasswordCredential(
        username: 'alice',
        password: 'secret',
      );
      await vault.save(_firstProfile, credential, _password);
      await vault.save(_secondProfile, credential, _password);

      await vault.clearAll();

      expect(await vault.isConfigured(), isFalse);
      expect(await storage.readAll(), isEmpty);
    },
  );

  test('new vaults require an exact six-digit PIN', () async {
    final codec = _fastCodec();

    for (final invalid in ['12345', '1234567', 'abcdef']) {
      await expectLater(
        codec.encrypt(
          clearText: 'secret',
          password: invalid,
          context: _firstProfile.id,
        ),
        throwsA(isA<AppPasswordVaultException>()),
      );
    }
  });
}
