// Live verification of the authentication paths that were still manual.
//
// The release checklist asked a human to "sign in with an API key as well as a
// password" and to confirm a changed certificate forces a new trust decision.
// Both are verifiable without a person: this probe creates a real API key,
// authenticates with it using the exact payload `ApiKeyCredential` builds,
// revokes it, and proves the revoked key is then refused. It also captures the
// server's certificate fingerprint the same way the app's trust-on-first-use
// flow does, so a pin recorded by TrueDock can be checked against the server.
//
// Usage:
//   dart run tool/live_auth_probe.dart <host> <username> <password>
//
// It creates and deletes one API key named `truedock-probe`. Nothing else on
// the server is modified. Credentials come from argv and are never persisted;
// the generated key is held in memory and revoked before the probe exits.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/connection/domain/auth_credential.dart';

const _keyName = 'truedock-probe';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_auth_probe.dart <host> <username> <password>',
    );
    exit(64);
  }
  final host = args[0];
  final username = args[1];
  final password = args[2];

  final results = <(String, bool, String?)>[];
  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      results.add((name, true, null));
      print('PASS  $name');
    } catch (error) {
      final detail = '$error';
      results.add((name, false, detail));
      final short = detail.length > 200
          ? '${detail.substring(0, 200)}...'
          : detail;
      print('FAIL  $name\n      $short');
    }
  }

  var fingerprint = '';
  int? keyId;
  var apiKey = '';

  final session = _Rpc(host);

  await check('the server presents a pinnable certificate', () async {
    fingerprint = await session.open();
    if (fingerprint.length != 64) {
      throw StateError('unexpected SHA-256 fingerprint: $fingerprint');
    }
    print('      (sha256 $fingerprint)');
  });

  await check('the certificate fingerprint is stable across connections', () async {
    // The app pins one fingerprint per server profile and demands a fresh trust
    // decision when it changes. A server that presents a different certificate
    // per connection would make that prompt fire constantly, so confirm it does
    // not before trusting a pin at all.
    final second = _Rpc(host);
    final again = await second.open();
    await second.close();
    if (again != fingerprint) {
      throw StateError('fingerprint changed between connections: $again');
    }
  });

  await check('password login succeeds with the app payload', () async {
    final credential = PasswordCredential(
      username: username,
      password: password,
    );
    await session.login(credential.toLoginPayload());
  });

  await check('api_key.create issues a key', () async {
    final created =
        await session.call(
              'api_key.create',
              params: [
                {'name': _keyName, 'username': username},
              ],
            )
            as Map;
    keyId = created['id'] as int?;
    apiKey = '${created['key']}';
    if (keyId == null || apiKey.isEmpty || apiKey == 'null') {
      throw StateError('no key material was returned');
    }
    // Never print the key itself.
    print('      (key id $keyId, ${apiKey.length} characters)');
  });

  await check('API_KEY_PLAIN login succeeds with the app payload', () async {
    // Exactly what ApiKeyCredential sends, on its own connection: the point is
    // that a fresh session can authenticate with the key alone.
    final keySession = _Rpc(host);
    await keySession.open();
    try {
      final credential = ApiKeyCredential(username: username, apiKey: apiKey);
      await keySession.login(credential.toLoginPayload());
      final me = await keySession.call('auth.me') as Map;
      print('      (authenticated as ${me['pw_name']})');
    } finally {
      await keySession.close();
    }
  });

  await check('a revoked key is refused', () async {
    await session.call('api_key.delete', params: [keyId]);
    final revoked = _Rpc(host);
    await revoked.open();
    try {
      final credential = ApiKeyCredential(username: username, apiKey: apiKey);
      await revoked.login(credential.toLoginPayload());
      throw StateError('the server accepted a deleted API key');
    } on _LoginRejected {
      keyId = null;
      print('      (rejected, as it must be)');
    } finally {
      await revoked.close();
    }
  });

  await check('two-factor state is discoverable', () async {
    // TrueDock only prompts for an OTP when the server asks, so what has to be
    // verified without a configured authenticator is that the app can read
    // whether 2FA is on. A server with it enabled answers login_ex with
    // OTP_REQUIRED, which the connection controller already routes to its OTP
    // dialog; that branch stays covered by widget tests.
    final config = await session.call('auth.twofactor.config') as Map;
    print('      (2FA enabled: ${config['enabled']})');
    if (config['enabled'] is! bool) {
      throw StateError('unexpected twofactor config: ${jsonEncode(config)}');
    }
  });

  // Leave nothing behind if a check above failed after creating the key.
  if (keyId != null) {
    await check('the probe API key is removed', () async {
      await session.call('api_key.delete', params: [keyId]);
    });
  }
  await check('no probe API key remains', () async {
    final keys = await session.call('api_key.query') as List;
    final leftover = keys
        .cast<Map>()
        .where((key) => '${key['name']}' == _keyName)
        .toList();
    if (leftover.isNotEmpty) {
      throw StateError('${leftover.length} probe key(s) still exist');
    }
  });

  await session.close();

  final failed = results.where((r) => !r.$2).toList();
  print('');
  print(
    'Result: ${results.length - failed.length}/${results.length} passed'
    '${failed.isEmpty ? '' : ', ${failed.length} failed'}',
  );
  exit(failed.isEmpty ? 0 : 1);
}

/// Raised when the server declines a login, as distinct from a transport error.
class _LoginRejected implements Exception {
  _LoginRejected(this.responseType);
  final String responseType;
  @override
  String toString() => 'login rejected: $responseType';
}

class _Rpc {
  _Rpc(this.host);

  final String host;
  final _pending = <int, Completer<Object?>>{};
  WebSocket? _socket;
  var _nextId = 1;

  /// Connects and returns the SHA-256 fingerprint of the presented leaf
  /// certificate, which is what the app pins per server profile.
  Future<String> open() async {
    var fingerprint = '';
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..badCertificateCallback = (cert, h, p) {
        fingerprint = sha256.convert(cert.der).toString();
        return h == host;
      };
    final socket = await WebSocket.connect(
      'wss://$host/api/current',
      customClient: client,
    );
    _socket = socket;
    socket.listen(
      (message) {
        final decoded = jsonDecode(message.toString());
        if (decoded is! Map || decoded['id'] is! int) return;
        final completer = _pending.remove(decoded['id'] as int);
        if (completer == null || completer.isCompleted) return;
        final error = decoded['error'];
        if (error != null) {
          completer.completeError(StateError(jsonEncode(error)));
        } else {
          completer.complete(decoded['result']);
        }
      },
      onError: _failPending,
      onDone: () => _failPending(StateError('socket closed')),
    );
    return fingerprint;
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  /// Sends a login payload built by the app's own credential types.
  Future<void> login(Map<String, Object?> payload) async {
    final result = await call('auth.login_ex', params: [payload]);
    final response = '${(result as Map)['response_type']}';
    if (response != 'SUCCESS') {
      throw _LoginRejected(response);
    }
  }

  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 60),
  }) {
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _socket!.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future.timeout(timeout);
  }

  Future<void> close() async {
    try {
      await _socket?.close();
    } catch (_) {}
  }
}
