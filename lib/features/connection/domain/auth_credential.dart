enum AuthMethod { apiKey, password }

sealed class AuthCredential {
  const AuthCredential({required this.username});

  final String username;

  Map<String, Object?> toLoginPayload();

  Map<String, Object?> toVaultJson();

  static AuthCredential fromVaultJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final secret = json['secret'] as String? ?? '';
    if (username.isEmpty || secret.isEmpty) {
      throw const FormatException('Saved credential is incomplete.');
    }
    return switch (json['method']) {
      'api_key' => ApiKeyCredential(username: username, apiKey: secret),
      'password' => PasswordCredential(username: username, password: secret),
      _ => throw const FormatException('Saved credential type is invalid.'),
    };
  }
}

class ApiKeyCredential extends AuthCredential {
  const ApiKeyCredential({required super.username, required this.apiKey});

  final String apiKey;

  @override
  Map<String, Object?> toLoginPayload() => {
    'mechanism': 'API_KEY_PLAIN',
    'username': username,
    'api_key': apiKey,
    'login_options': {'user_info': true},
  };

  @override
  Map<String, Object?> toVaultJson() => {
    'method': 'api_key',
    'username': username,
    'secret': apiKey,
  };
}

class PasswordCredential extends AuthCredential {
  const PasswordCredential({required super.username, required this.password});

  final String password;

  @override
  Map<String, Object?> toLoginPayload() => {
    'mechanism': 'PASSWORD_PLAIN',
    'username': username,
    'password': password,
    'login_options': {'user_info': true},
  };

  @override
  Map<String, Object?> toVaultJson() => {
    'method': 'password',
    'username': username,
    'secret': password,
  };
}

enum AuthOutcome {
  success,
  otpRequired,
  authenticationError,
  expired,
  redirect,
}

class AuthResult {
  const AuthResult({
    required this.outcome,
    this.username,
    this.redirectUrls = const [],
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final type = json['response_type'] as String?;
    return switch (type) {
      'SUCCESS' => AuthResult(
        outcome: AuthOutcome.success,
        username: _userName(json['user_info']),
      ),
      'OTP_REQUIRED' => AuthResult(
        outcome: AuthOutcome.otpRequired,
        username: json['username'] as String?,
      ),
      'EXPIRED' => const AuthResult(outcome: AuthOutcome.expired),
      'REDIRECT' => AuthResult(
        outcome: AuthOutcome.redirect,
        redirectUrls: (json['urls'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      ),
      _ => const AuthResult(outcome: AuthOutcome.authenticationError),
    };
  }

  final AuthOutcome outcome;
  final String? username;
  final List<String> redirectUrls;

  static String? _userName(Object? value) {
    if (value is Map<String, dynamic>) return value['pw_name'] as String?;
    return null;
  }
}
