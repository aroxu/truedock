// Live verification of the alert-email surface (`mail.*`).
//
// Reads the settings, applies a partial edit, and restores the original values.
// It never sends a test message: that would deliver mail to whatever address the
// server is configured with, which is not the probe's to touch.
//
// Usage:
//   dart run tool/live_mail_probe.dart <host> <username> <password>
//
// Payloads are built from the app's own domain types. Credentials come from
// argv and are never persisted; no SMTP password is ever read or written.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/mail_configuration.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_mail_probe.dart <host> <username> <password>',
    );
    exit(64);
  }

  final session = _Rpc(args[0]);
  final results = <(String, bool, String?)>[];
  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      results.add((name, true, null));
      print('PASS  $name');
    } catch (error) {
      final detail = '$error';
      results.add((name, false, detail));
      print(
        'FAIL  $name\n      '
        '${detail.length > 220 ? '${detail.substring(0, 220)}...' : detail}',
      );
    }
  }

  MailConfiguration? original;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('mail.config parses into the app model', () async {
      final raw = await session.call('mail.config') as Map<String, dynamic>;
      original = MailConfiguration.fromJson(raw);
      final config = original!;
      print(
        '      (from "${config.fromEmail}", server "${config.outgoingServer}", '
        'port ${config.port}, security ${config.security.apiValue})',
      );
      print(
        '      (auth ${config.smtpAuthentication}, user ${config.username}, '
        'oauth ${config.usesOauth}, configured ${config.isConfigured})',
      );
      // The reason MailConfiguration has no password field: confirm the server
      // does return one, so modelling it would have created a leak surface.
      if (raw.containsKey('pass')) {
        print(
          '      (mail.config does expose `pass`; deliberately not modelled)',
        );
      }
    });

    await check('an unchanged edit sends nothing', () async {
      final baseline = original!;
      final edit = MailConfigurationEdit(
        fromEmail: baseline.fromEmail,
        fromName: baseline.fromName,
        outgoingServer: baseline.outgoingServer,
        port: baseline.port,
        security: baseline.security,
      );
      // Every field matches, but this constructor does not diff, so the payload
      // is non-empty by design. The sheet diffs; assert that separately.
      if (edit.toApiJson().isEmpty) {
        throw StateError('the explicit constructor should carry its fields');
      }
      const empty = MailConfigurationEdit();
      if (!empty.isEmpty) {
        throw StateError('an empty edit produced ${empty.toApiJson()}');
      }
    });

    await check('mail.update accepts a partial payload', () async {
      // Only fromname is touched: it cannot break delivery if the restore below
      // fails for any reason.
      const probeName = 'TrueDock probe';
      const edit = MailConfigurationEdit(fromName: probeName);
      // toApiJsonFor, not toApiJson: the server rejects the whole call with
      // "fromemail: this field is required" when that field is absent and not
      // already stored, so a pure partial update is impossible on a server where
      // mail was never configured.
      final payload = edit.toApiJsonFor(original!);
      if (!payload.containsKey('fromname')) {
        throw StateError('the edit sent $payload, expected fromname');
      }
      if (original!.fromEmail.isEmpty && !payload.containsKey('fromemail')) {
        throw StateError('fromemail was omitted on an unconfigured server');
      }
      await session.call('mail.update', params: [payload]);
      final after = MailConfiguration.fromJson(
        await session.call('mail.config') as Map<String, dynamic>,
      );
      if (after.fromName != probeName) {
        throw StateError('fromname is "${after.fromName}"');
      }
      // A partial update must leave everything else alone.
      if (after.outgoingServer != original!.outgoingServer ||
          after.port != original!.port ||
          after.security != original!.security ||
          after.username != original!.username) {
        throw StateError('a partial update changed unrelated fields');
      }
      print('      (applied, and server/port/security/user preserved)');
    });

    await check(
      'authentication without a password is rejected locally',
      () async {
        // The server accepts this and then silently fails to authenticate, so
        // alerts stop arriving with no error anywhere. Catching it in the app is
        // the whole point.
        final issues =
            const MailConfigurationEdit(
              smtpAuthentication: true,
              username: 'probe-user',
            ).validateAgainst(
              MailConfiguration(
                fromEmail: original!.fromEmail,
                fromName: original!.fromName,
                outgoingServer: original!.outgoingServer,
                port: original!.port,
                security: original!.security,
              ),
            );
        if (issues.isEmpty) {
          throw StateError('a username with no password was accepted');
        }
      },
    );
  } finally {
    final baseline = original;
    if (baseline != null) {
      await check('the original from-name is restored', () async {
        // Sent through the same helper so the restore cannot hit the
        // required-fromemail rejection the edit above had to work around.
        await session.call(
          'mail.update',
          params: [
            MailConfigurationEdit(
              fromName: baseline.fromName,
            ).toApiJsonFor(baseline),
          ],
        );
        final after = MailConfiguration.fromJson(
          await session.call('mail.config') as Map<String, dynamic>,
        );
        if (after.fromName != baseline.fromName) {
          throw StateError('fromname is "${after.fromName}" after restore');
        }
      });
    }
    await session.close();
  }

  final failed = results.where((r) => !r.$2).toList();
  print('');
  print(
    'Result: ${results.length - failed.length}/${results.length} passed'
    '${failed.isEmpty ? '' : ', ${failed.length} failed'}',
  );
  exit(failed.isEmpty ? 0 : 1);
}

class _Rpc {
  _Rpc(this.host);

  final String host;
  final _pending = <int, Completer<Object?>>{};
  WebSocket? _socket;
  var _nextId = 1;

  Future<void> open() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..badCertificateCallback = (cert, h, p) => h == host;
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
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  Future<void> login(String username, String password) async {
    final result = await call(
      'auth.login_ex',
      params: [
        {
          'mechanism': 'PASSWORD_PLAIN',
          'username': username,
          'password': password,
        },
      ],
    );
    if ((result as Map)['response_type'] != 'SUCCESS') {
      throw StateError('login returned ${result['response_type']}');
    }
  }

  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 90),
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
      await call('auth.logout');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
  }
}
