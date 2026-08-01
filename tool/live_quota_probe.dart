// Live verification of per-account dataset quotas
// (`pool.dataset.get_quota`, `pool.dataset.set_quota`).
//
// Quotas are worth probing rather than trusting the schema for, because the two
// halves of the API disagree. `set_quota` accepts USER/USEROBJ/GROUP/GROUPOBJ,
// but `get_quota` rejects the `*OBJ` variants outright - object limits are
// written under their own type and read back as an `obj_quota` field on the
// plain row. A fixture would happily encode either reading.
//
// Usage:
//   dart run tool/live_quota_probe.dart <host> <username> <password> [dataset]
//
// MUTATING, but only of quotas it sets and clears on the target dataset.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/storage/domain/dataset_quota.dart';

void main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/live_quota_probe.dart '
      '<host> <user> <password> [dataset]',
    );
    exit(64);
  }
  final dataset = args.length > 3 ? args[3] : 'truedock_data';

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
        '${detail.length > 300 ? '${detail.substring(0, 300)}...' : detail}',
      );
    }
  }

  String? account;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('get_quota parses into the app model', () async {
      final rows =
          await session.call(
                'pool.dataset.get_quota',
                params: [dataset, QuotaSubject.user.spaceType],
              )
              as List;
      final parsed = rows
          .whereType<Map<String, dynamic>>()
          .map(DatasetQuota.fromJson)
          .toList();
      if (parsed.isEmpty) throw StateError('no quota rows returned');
      // Every account that has written to the dataset shows up, limit or not,
      // which is why the UI cannot simply list what comes back.
      final limited = parsed.where((q) => q.hasAnyQuota).length;
      print('      (${parsed.length} row(s), $limited with a limit set)');
    });

    await check('get_quota refuses the *OBJ types set_quota requires', () async {
      // The asymmetry the model is built around. If a release ever accepts it,
      // this fails and the model can be simplified.
      try {
        await session.call(
          'pool.dataset.get_quota',
          params: [dataset, QuotaSubject.user.objectType],
        );
      } on StateError catch (error) {
        if (!'$error'.contains('Input should be')) rethrow;
        print('      (USEROBJ rejected on read, as modelled)');
        return;
      }
      throw StateError('USEROBJ was accepted on read; the model assumes not');
    });

    await check('a non-builtin account is available to test against', () async {
      final users =
          await session.call(
                'user.query',
                params: [
                  [
                    ['local', '=', true],
                  ],
                ],
              )
              as List;
      final target = users
          .whereType<Map<String, dynamic>>()
          .where((u) => (u['uid'] as int? ?? 0) > 0 && u['builtin'] != true)
          .firstOrNull;
      if (target == null) throw StateError('no non-builtin local user');
      account = target['username'] as String;
      print('      (using $account, uid ${target['uid']})');
    });

    await check('the app payload sets both space and object limits', () async {
      const gib = 2 * 1024 * 1024 * 1024;
      final edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: account!,
        spaceBytes: gib,
        objectCount: 5000,
      );
      if (edit.validate().isNotEmpty) {
        throw StateError('rejected locally: ${edit.validate()}');
      }
      // Exactly what ServerActionsRepository.setDatasetQuotas sends.
      final entries = edit.toApiJson();
      if (entries.length != 2) {
        throw StateError('expected 2 entries, got ${entries.length}');
      }
      await session.call('pool.dataset.set_quota', params: [dataset, entries]);

      final rows =
          await session.call(
                'pool.dataset.get_quota',
                params: [dataset, QuotaSubject.user.spaceType],
              )
              as List;
      final mine = rows
          .whereType<Map<String, dynamic>>()
          .map(DatasetQuota.fromJson)
          .firstWhere(
            (q) => q.name == account,
            orElse: () => throw StateError('$account not in the quota list'),
          );
      if (mine.quotaBytes != gib) {
        throw StateError('space quota is ${mine.quotaBytes}, expected $gib');
      }
      // The object limit was written as USEROBJ and must read back here.
      if (mine.objectQuota != 5000) {
        throw StateError('object quota is ${mine.objectQuota}, expected 5000');
      }
      print('      (space ${mine.quotaBytes}, objects ${mine.objectQuota})');
    });

    await check('uid 0 is refused, as the model predicts', () async {
      // Validated locally so the user gets an explanation rather than a raw
      // EINVAL; this proves the server really does refuse it.
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'root',
        spaceBytes: 1024 * 1024 * 1024,
      );
      if (edit.validate().isEmpty) {
        throw StateError('the model should reject root locally');
      }
      try {
        await session.call(
          'pool.dataset.set_quota',
          params: [
            dataset,
            [
              {
                'quota_type': 'USER',
                'id': 'root',
                'quota_value': 1024 * 1024 * 1024,
              },
            ],
          ],
        );
      } on StateError catch (error) {
        if (!'$error'.contains('not permitted')) rethrow;
        print('      (server refuses uid 0, matching local validation)');
        return;
      }
      throw StateError('the server accepted a quota on uid 0');
    });

    await check('an unknown account is refused', () async {
      try {
        await session.call(
          'pool.dataset.set_quota',
          params: [
            dataset,
            [
              {
                'quota_type': 'USER',
                'id': 'truedock_no_such_user',
                'quota_value': 1024,
              },
            ],
          ],
        );
      } on StateError catch (error) {
        if (!'$error'.contains('is not valid')) rethrow;
        print('      (unknown account rejected server-side)');
        return;
      }
      throw StateError('an unknown account was accepted');
    });

    await check('zero clears both limits', () async {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: '',
        spaceBytes: 0,
        objectCount: 0,
      );
      // Build the payload with the real account.
      final real = DatasetQuotaEdit(
        subject: edit.subject,
        target: account!,
        spaceBytes: 0,
        objectCount: 0,
      );
      await session.call(
        'pool.dataset.set_quota',
        params: [dataset, real.toApiJson()],
      );

      final rows =
          await session.call(
                'pool.dataset.get_quota',
                params: [dataset, QuotaSubject.user.spaceType],
              )
              as List;
      final mine = rows
          .whereType<Map<String, dynamic>>()
          .map(DatasetQuota.fromJson)
          .where((q) => q.name == account)
          .firstOrNull;
      // The row may vanish entirely once nothing limits it, which is also fine.
      if (mine != null && mine.hasAnyQuota) {
        throw StateError(
          'limits survived: space ${mine.quotaBytes}, '
          'objects ${mine.objectQuota}',
        );
      }
      print('      (cleared)');
    });
  } finally {
    // Leave nothing behind even if a check failed midway.
    if (account != null) {
      try {
        await session.call(
          'pool.dataset.set_quota',
          params: [
            dataset,
            DatasetQuotaEdit(
              subject: QuotaSubject.user,
              target: account!,
              spaceBytes: 0,
              objectCount: 0,
            ).toApiJson(),
          ],
        );
      } catch (_) {}
    }
    await session.close();
  }

  final failed = results.where((r) => !r.$2).length;
  print('\nResult: ${results.length - failed}/${results.length} passed');
  exit(failed == 0 ? 0 : 1);
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
            reason ??= error['message'];
          }
          var text = '${reason ?? jsonEncode(error)}';
          if (text.length > 400) text = '${text.substring(0, 400)}...';
          completer.completeError(StateError(text));
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
      await call('auth.logout');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
  }
}
