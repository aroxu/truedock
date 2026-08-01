// Live verification of the disruptive system lifecycle calls.
//
// `system.reboot` and `system.shutdown` were the last unverified surfaces:
// they cannot be exercised from fixtures, and a schema audit found TrueDock was
// sending `{'reason': ...}` where 25.10 declares `reason` as a required
// *positional* string with an options object that accepts only `delay`. This
// probe proves the corrected payload is accepted, that the server actually
// restarts, and that the connection can be re-established afterwards.
//
// Usage:
//   dart run tool/live_reboot_probe.dart <host> <username> <password>
//
// DISRUPTIVE. It restarts the target server. Only run it against a disposable
// test system. `system.shutdown` is deliberately *not* invoked: recovering from
// it needs physical or out-of-band access, so the probe verifies its payload is
// accepted by the schema without submitting it.
//
// Credentials come from argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_reboot_probe.dart <host> <username> '
      '<password>',
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
      print(
        'FAIL  $name\n      ${detail.length > 200 ? '${detail.substring(0, 200)}...' : detail}',
      );
    }
  }

  var bootIdBefore = '';
  var uptimeBefore = 0.0;

  final before = _Rpc(host);
  await check('connect and authenticate', () async {
    await before.open();
    await before.login(username, password);
  });

  await check('record the pre-restart boot identity', () async {
    final info = await before.call('system.info') as Map;
    uptimeBefore = (info['uptime_seconds'] as num).toDouble();
    bootIdBefore = '${info['boottime']}';
    print(
      '      (uptime ${uptimeBefore.toStringAsFixed(0)}s, boot $bootIdBefore)',
    );
  });

  // Verify the shutdown payload without submitting it. `delay` is the only
  // documented option; sending the reason as an object member (which TrueDock
  // used to do) is rejected here, which is the regression this guards.
  await check('system.shutdown declares reason positionally', () async {
    final methods = await before.call('core.get_methods', params: [null, 'WS']);
    final accepts = ((methods as Map)['system.shutdown'] as Map)['accepts'];
    if (accepts is! List || accepts.isEmpty) {
      throw StateError('system.shutdown advertises no arguments');
    }
    final first = accepts.first as Map;
    if (first['type'] != 'string' || first['_name_'] != 'reason') {
      throw StateError('first argument is ${jsonEncode(first)}');
    }
    final options = accepts.length > 1 ? accepts[1] as Map : const {};
    final keys = (options['properties'] as Map?)?.keys.toList() ?? const [];
    if (!keys.contains('delay') || keys.length != 1) {
      throw StateError('options accept $keys, expected only [delay]');
    }
    print('      (reason is positional; options accept $keys)');
  });

  await check('system.reboot accepts the positional reason', () async {
    // Exactly what ServerActionsRepository.rebootServer now sends.
    final result = await before.call(
      'system.reboot',
      params: ['Verified by TrueDock probe'],
      timeout: const Duration(seconds: 30),
    );
    print('      (accepted, job $result)');
  });

  await before.close();

  await check('the server goes away', () async {
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(deadline)) {
      final probe = _Rpc(host);
      try {
        await probe.open(timeout: const Duration(seconds: 5));
        await probe.close();
      } catch (_) {
        print('      (connection refused, the restart is under way)');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw StateError('the server never stopped answering');
  });

  late _Rpc after;
  await check('the server comes back and authenticates', () async {
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      final probe = _Rpc(host);
      try {
        await probe.open(timeout: const Duration(seconds: 8));
        await probe.login(username, password);
        after = probe;
        return;
      } catch (error) {
        lastError = error;
        await probe.close();
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
    throw StateError('never came back: $lastError');
  });

  await check('uptime confirms a real restart', () async {
    final info = await after.call('system.info') as Map;
    final uptime = (info['uptime_seconds'] as num).toDouble();
    final boot = '${info['boottime']}';
    print('      (uptime ${uptime.toStringAsFixed(0)}s, boot $boot)');
    if (boot == bootIdBefore) {
      throw StateError('boot time is unchanged, so the server did not restart');
    }
    if (uptime >= uptimeBefore) {
      throw StateError('uptime did not reset ($uptime >= $uptimeBefore)');
    }
  });

  // A restart that leaves the pool or the app platform broken is not a
  // successful restart from the user's point of view, so verify both recovered.
  await check('pools import automatically after the restart', () async {
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline)) {
      final pools = await after.call('pool.query') as List;
      if (pools.isEmpty) {
        print('      (no pools configured; nothing to import)');
        return;
      }
      final offline = pools
          .cast<Map>()
          .where((pool) => pool['status'] != 'ONLINE')
          .toList();
      if (offline.isEmpty) {
        final names = pools.cast<Map>().map((p) => p['name']).join(', ');
        print('      ($names back ONLINE)');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    throw StateError('a pool stayed offline after the restart');
  });

  await check('installed apps return to a running state', () async {
    final deadline = DateTime.now().add(const Duration(minutes: 8));
    var last = '';
    while (DateTime.now().isBefore(deadline)) {
      // The app platform starts after middleware accepts connections, and
      // app.query answers with an empty list until it does. Reading it too
      // early reports "no apps installed" for a server that has one, so wait
      // for Docker to come up before trusting the answer.
      final docker = await after.call('docker.status') as Map;
      if (docker['status'] != 'RUNNING') {
        last = 'docker ${docker['status']}';
        await Future<void>.delayed(const Duration(seconds: 10));
        continue;
      }
      final apps = await after.call('app.query') as List;
      if (apps.isEmpty) {
        print('      (no apps installed; nothing to recover)');
        return;
      }
      final states = apps.cast<Map>().map((a) => '${a['state']}').toSet();
      last = states.join('/');
      if (states.every((state) => state == 'RUNNING' || state == 'STOPPED')) {
        print('      (app states: $last)');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    throw StateError('apps stayed in $last after the restart');
  });

  await after.close();

  final failed = results.where((r) => !r.$2).toList();
  print('');
  print(
    'Result: ${results.length - failed.length}/${results.length} passed'
    '${failed.isEmpty ? '' : ', ${failed.length} failed'}',
  );
  exit(failed.isEmpty ? 0 : 1);
}

/// Minimal JSON-RPC client over the TrueNAS WebSocket API.
class _Rpc {
  _Rpc(this.host);

  final String host;
  final _pending = <int, Completer<Object?>>{};
  WebSocket? _socket;
  var _nextId = 1;

  Future<void> open({Duration timeout = const Duration(seconds: 20)}) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..badCertificateCallback = (cert, h, p) => h == host;
    final socket = await WebSocket.connect(
      'wss://$host/api/current',
      customClient: client,
    ).timeout(timeout);
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
