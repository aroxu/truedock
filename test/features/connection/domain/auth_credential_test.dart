import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';

void main() {
  test('API key credentials use the TrueNAS 25.10 login_ex payload', () {
    const credential = ApiKeyCredential(username: 'admin', apiKey: 'secret');

    expect(credential.toLoginPayload(), {
      'mechanism': 'API_KEY_PLAIN',
      'username': 'admin',
      'api_key': 'secret',
      'login_options': {'user_info': true},
    });
  });

  test('password credentials use the TrueNAS 25.10 login_ex payload', () {
    const credential = PasswordCredential(
      username: 'admin',
      password: 'secret',
    );

    expect(credential.toLoginPayload(), {
      'mechanism': 'PASSWORD_PLAIN',
      'username': 'admin',
      'password': 'secret',
      'login_options': {'user_info': true},
    });
  });

  test('parses an OTP challenge', () {
    final result = AuthResult.fromJson({
      'response_type': 'OTP_REQUIRED',
      'username': 'admin',
    });

    expect(result.outcome, AuthOutcome.otpRequired);
    expect(result.username, 'admin');
  });

  test('round-trips an API key through the secure vault payload', () {
    const credential = ApiKeyCredential(
      username: 'mobile-admin',
      apiKey: 'secret-key',
    );

    final restored = AuthCredential.fromVaultJson(credential.toVaultJson());

    expect(restored, isA<ApiKeyCredential>());
    expect(restored.username, 'mobile-admin');
    expect((restored as ApiKeyCredential).apiKey, 'secret-key');
  });
}
