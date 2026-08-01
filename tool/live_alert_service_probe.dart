// Live verification of the alert-destination surface (`alertservice.*`).
//
// Creates a destination, edits it, confirms a blank credential field keeps the
// stored secret, and deletes it. It uses the Mail destination type so nothing is
// delivered anywhere: the demo server has no configured SMTP server, so a test
// send cannot reach a real inbox.
//
// Usage:
//   dart run tool/live_alert_service_probe.dart <host> <username> <password>
//
// Payloads are built from the app's own domain types. Credentials come from argv
// and are never persisted; no real webhook or token is ever written.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/alert_service_configuration.dart';

const _name = 'truedock-probe';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_alert_service_probe.dart <host> <username> '
      '<password>',
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

  int? id;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('previous probe destinations are cleared', () async {
      final rows = await session.call('alertservice.query') as List;
      var removed = 0;
      for (final row in rows.cast<Map>()) {
        if ('${row['name']}' == _name) {
          await session.call('alertservice.delete', params: [row['id']]);
          removed++;
        }
      }
      if (removed > 0) print('      (cleared $removed leftover)');
    });

    await check('alertservice.create nests type inside attributes', () async {
      const configuration = AlertServiceConfiguration(
        name: _name,
        kind: AlertServiceKind.mail,
        level: AlertLevel.warning,
        attributes: {'email': 'truedock-probe@example.invalid'},
      );
      final payload = configuration.toApiJson();
      final attributes = payload['attributes'] as Map<String, Object?>;
      if (attributes['type'] != 'Mail') {
        throw StateError('type is not inside attributes: $payload');
      }
      final result = await session.call(
        'alertservice.create',
        params: [payload],
      );
      id = (result as Map)['id'] as int?;
      if (id == null) throw StateError('no id was returned');
      print('      (created destination $id)');
    });

    await check('the round trip preserves the destination', () async {
      final rows =
          await session.call(
                'alertservice.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      if (rows.isEmpty) throw StateError('not listed');
      final entry = AlertServiceEntry.fromJson(
        rows.first as Map<String, dynamic>,
      );
      if (entry.kind != AlertServiceKind.mail) {
        throw StateError('kind parsed as ${entry.kind}');
      }
      if (entry.level != AlertLevel.warning) {
        throw StateError('level parsed as ${entry.level}');
      }
      if (entry.attribute('email') != 'truedock-probe@example.invalid') {
        throw StateError('email is ${entry.attribute('email')}');
      }
      print('      (kind, level, and attributes all round-tripped)');
    });

    await check('alertservice.update applies a change', () async {
      const configuration = AlertServiceConfiguration(
        name: _name,
        kind: AlertServiceKind.mail,
        level: AlertLevel.critical,
        attributes: {'email': 'truedock-probe2@example.invalid'},
        enabled: false,
      );
      await session.call(
        'alertservice.update',
        params: [id, configuration.toApiJson()],
      );
      final rows =
          await session.call(
                'alertservice.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      final entry = AlertServiceEntry.fromJson(
        rows.first as Map<String, dynamic>,
      );
      if (entry.level != AlertLevel.critical || entry.enabled) {
        throw StateError('update did not apply');
      }
    });

    await check('a blank credential field is omitted, not cleared', () async {
      // Switch to a destination that has a secret, save it, then re-save with
      // the secret field blank. The server must still hold the original value,
      // which is the whole reason the editor never prefills one.
      const withSecret = AlertServiceConfiguration(
        name: _name,
        kind: AlertServiceKind.pagerDuty,
        level: AlertLevel.warning,
        attributes: {
          'service_key': 'truedock-probe-key',
          'client_name': 'truedock',
        },
      );
      await session.call(
        'alertservice.update',
        params: [id, withSecret.toApiJson()],
      );

      // Re-read the entry the way the app does, so the stored secret comes from
      // the query rather than from anything the probe kept in memory.
      final storedRows =
          await session.call(
                'alertservice.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      final stored = AlertServiceEntry.fromJson(
        storedRows.first as Map<String, dynamic>,
      );

      const blanked = AlertServiceConfiguration(
        name: _name,
        kind: AlertServiceKind.pagerDuty,
        level: AlertLevel.error,
        attributes: {'service_key': '', 'client_name': 'truedock-renamed'},
      );
      final payload = blanked.toApiJson(storedSecrets: stored.attributes);
      final attributes = payload['attributes'] as Map<String, Object?>;
      // Omitting it is not an option: the server rejects the call with "field
      // required". The stored value is substituted instead.
      if (attributes['service_key'] != 'truedock-probe-key') {
        throw StateError(
          'the stored secret was not substituted: ${attributes['service_key']}',
        );
      }
      await session.call('alertservice.update', params: [id, payload]);

      final rows =
          await session.call(
                'alertservice.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      final entry = AlertServiceEntry.fromJson(
        rows.first as Map<String, dynamic>,
      );
      if (entry.attribute('client_name') != 'truedock-renamed') {
        throw StateError('the non-secret change did not apply');
      }
      if (entry.attribute('service_key') != 'truedock-probe-key') {
        throw StateError(
          'the stored secret became "${entry.attribute('service_key')}"',
        );
      }
      print('      (secret preserved while the rest of the edit applied)');
    });
  } finally {
    if (id != null) {
      await check('alertservice.delete removes it', () async {
        await session.call('alertservice.delete', params: [id]);
        final rows =
            await session.call(
                  'alertservice.query',
                  params: [
                    [
                      ['id', '=', id],
                    ],
                  ],
                )
                as List;
        if (rows.isNotEmpty) throw StateError('still listed');
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
          Object? reason;
          if (error is Map) {
            final data = error['data'];
            if (data is Map) reason = data['reason'];
          }
          completer.completeError(StateError('${reason ?? jsonEncode(error)}'));
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
