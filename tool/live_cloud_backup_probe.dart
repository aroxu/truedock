// Live verification of the cloud backup surface (`cloud_backup.*`).
//
// A real backup needs cloud provider credentials, which a disposable test server
// has none of and which are not a probe's to create. So this verifies what can
// be verified without them: the read path, and that a create built by the app's
// own domain types is rejected for the *credential* rather than for its payload
// shape. A shape rejection names a field; a credential rejection does not.
//
// That distinction is the whole point. Every payload defect this project found
// (`keep_volumes`, `system.reboot`, `alertservice` secrets) surfaced as a field
// error, so proving the middleware got past validation is proof the shape is
// right even when the call cannot succeed.
//
// Usage:
//   dart run tool/live_cloud_backup_probe.dart <host> <username> <password>
//
// Creates nothing that survives: the only mutating call is expected to fail.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/data_protection/domain/cloud_backup_configuration.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_cloud_backup_probe.dart <host> <username> '
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

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('cloud_backup.query parses into the app model', () async {
      final rows = await session.call('cloud_backup.query') as List;
      final tasks = rows
          .whereType<Map<String, dynamic>>()
          .map(CloudBackupTask.fromJson)
          .toList();
      print('      (${tasks.length} task(s) configured)');
      for (final task in tasks) {
        if (task.configuration.password.isNotEmpty) {
          throw StateError('the repository password was modelled from a read');
        }
      }
    });

    await check('the app payload clears schema validation', () async {
      // Credential 999999 does not exist. The middleware validates the payload
      // first, so a field error here would mean the shape is wrong, while a
      // credential error means every field was accepted.
      final configuration = CloudBackupConfiguration(
        path: '/mnt/truedock_data/media',
        credentialId: 999999,
        keepLast: 7,
        password: 'truedock-probe-password',
        description: 'truedock probe',
        bucket: 'truedock-probe-bucket',
        folder: 'probe',
        schedule: const TaskSchedule(minute: '0', hour: '3'),
        snapshot: true,
      );
      const credential = CloudCredential(
        id: 999999,
        name: 'probe',
        provider: 'B2',
      );
      final payload = configuration.toApiJson(credential: credential);

      try {
        final result = await session.call(
          'cloud_backup.create',
          params: [payload],
        );
        throw StateError('a nonexistent credential was accepted: $result');
      } on _RpcError catch (error) {
        final message = error.toString();
        // A payload-shape rejection names a field: "extra_forbidden",
        // "Field required", or "Input should be".
        final shapeRejected =
            message.contains('extra_forbidden') ||
            message.contains('Field required') ||
            message.contains('Input should be') ||
            message.contains('This field is required');
        if (shapeRejected) {
          throw StateError('the payload shape was rejected: $message');
        }
        print('      (validation passed; rejected on the credential)');
        print('      (${_short(message)})');
      }
    });

    await check('the schedule and attributes match the schema', () async {
      // Asserted against the advertised schema rather than the server's
      // acceptance, because the call above cannot complete without a real
      // credential.
      final methods = await session.call(
        'core.get_methods',
        params: [null, 'WS'],
      );
      final accepts =
          ((methods as Map)['cloud_backup.create'] as Map)['accepts'] as List;
      final properties =
          (accepts.first as Map)['properties'] as Map<String, Object?>;
      final payload = const CloudBackupConfiguration(
        path: '/mnt/tank/docs',
        credentialId: 1,
        keepLast: 7,
        password: 'p',
      ).toApiJson();
      final unknown = payload.keys
          .where((key) => !properties.containsKey(key))
          .toList();
      if (unknown.isNotEmpty) {
        throw StateError('keys absent from the schema: $unknown');
      }
      final required =
          ((accepts.first as Map)['required'] as List?)?.cast<String>() ??
          const [];
      final missing = required
          .where((key) => !payload.containsKey(key))
          .toList();
      if (missing.isNotEmpty) {
        throw StateError('required keys not sent: $missing');
      }
      print(
        '      (${payload.length} keys, all in the schema; '
        '${required.length} required, all present)',
      );
    });

    await check('reads and restores are advertised as expected', () async {
      // These cannot be exercised without a repository, so confirm the argument
      // shapes the app sends match what the server declares.
      final methods =
          await session.call('core.get_methods', params: [null, 'WS']) as Map;
      final restore =
          (methods['cloud_backup.restore'] as Map)['accepts'] as List;
      final names = restore.map((arg) => (arg as Map)['_name_']).toList();
      if (names.take(4).join(',') !=
          'id,snapshot_id,subfolder,destination_path') {
        throw StateError('restore arguments are $names');
      }
      final requiredCount = restore
          .where((arg) => (arg as Map)['_required_'] == true)
          .length;
      if (requiredCount != 4) {
        throw StateError('$requiredCount required restore arguments');
      }
      print('      (restore takes 4 required positional arguments)');
    });
  } finally {
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

String _short(String value) =>
    value.length <= 160 ? value : '${value.substring(0, 160)}...';

class _RpcError implements Exception {
  _RpcError(this.detail);
  final String detail;
  @override
  String toString() => detail;
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
          completer.completeError(_RpcError('${reason ?? jsonEncode(error)}'));
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
