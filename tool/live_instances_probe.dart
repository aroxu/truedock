// Live verification of the Instances (`virt.*`) surface.
//
// A coverage audit of every method the server advertises against every method
// TrueDock calls found `virt.*` — 33 methods, the whole container/VM surface on
// 25.10 — with zero coverage, while the app targeted `container.*`, which 25.10
// does not advertise at all. This probe verifies the replacement end to end.
//
// Usage:
//   dart run tool/live_instances_probe.dart <host> <user> <password> [--keep]
//
// DESTRUCTIVE. It initializes the Instances platform against a pool if that is
// not already done (creating a hidden `.ix-virt` dataset), then creates,
// starts, stops, restarts, reconfigures, and deletes a probe instance. With
// `--keep` the instance is left in place for inspection in the TrueDock UI.
//
// Payloads are built from the app's own domain types, so a shape that drifts
// from the shipped app fails here rather than diverging silently. Credentials
// come from argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/system/domain/virt_instance_configuration.dart';

const _instanceName = 'truedock-probe';

void main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final keep = args.contains('--keep');
  if (positional.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_instances_probe.dart <host> <username> '
      '<password> [--keep]',
    );
    exit(64);
  }

  final session = _Rpc(positional[0]);
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

  var created = false;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(positional[1], positional[2]);
    });

    // The platform is unusable until a pool is chosen, and in that state
    // virt.instance.query returns an empty list — indistinguishable from "no
    // instances" unless the config is read. That is why the app reads it.
    late String pool;
    await check('virt.global.config reports the platform state', () async {
      final config = await session.call('virt.global.config') as Map;
      print('      (state ${config['state']}, pool ${config['pool']})');
      if (config['pool'] != null) {
        pool = '${config['pool']}';
        return;
      }
      final choices = await session.call('virt.global.pool_choices') as Map;
      final candidates = choices.keys
          .map((key) => '$key')
          .where((key) => !key.startsWith('['))
          .toList();
      if (candidates.isEmpty) {
        throw StateError('no pool is available to initialize instances');
      }
      pool = candidates.first;
      print('      (initializing against $pool)');
      await session.runJob(
        'virt.global.update',
        params: [
          {
            'pool': pool,
            'storage_pools': [pool],
          },
        ],
        timeout: const Duration(minutes: 5),
      );
      final after = await session.call('virt.global.config') as Map;
      if (after['state'] != 'INITIALIZED') {
        throw StateError('platform state is ${after['state']}');
      }
    });

    late String image;
    await check('virt.instance.image_choices lists container images', () async {
      // Sent exactly as the repository sends it: `remote` is the only accepted
      // key, and passing `instance_type` (the obvious guess) is rejected.
      final result =
          await session.call(
                'virt.instance.image_choices',
                params: [
                  {'remote': 'LINUX_CONTAINERS'},
                ],
              )
              as Map;
      final choices = <String>[];
      for (final entry in result.entries) {
        final value = entry.value;
        if (value is Map &&
            (value['instance_types'] as List?)?.contains('CONTAINER') == true) {
          choices.add('${entry.key}');
        }
      }
      if (choices.isEmpty) throw StateError('no container images offered');
      image = choices.firstWhere(
        (id) => id.startsWith('alpine/'),
        orElse: () => choices.first,
      );
      print('      (${choices.length} container images, using $image)');
    });

    await check('virt.instance.create accepts the app payload', () async {
      final existing =
          await session.call(
                'virt.instance.query',
                params: [
                  [
                    ['name', '=', _instanceName],
                  ],
                ],
              )
              as List;
      if (existing.isNotEmpty) {
        created = true;
        print('      (reusing the instance from an earlier --keep run)');
        return;
      }
      final configuration = VirtInstanceCreateConfiguration(
        name: _instanceName,
        image: image,
        cpu: '1',
        memoryMiB: 256,
        autostart: false,
        storagePool: pool,
      );
      await session.runJob(
        'virt.instance.create',
        params: [configuration.toApiJson()],
        timeout: const Duration(minutes: 10),
      );
      created = true;
    });

    await check('virt.instance.query returns the documented shape', () async {
      final instance = await session.instance(_instanceName);
      // These are the fields VirtInstance.fromJson depends on. The shape
      // differs from vm.query in ways that matter: status is a bare string
      // rather than a nested object, cpu is a string, memory is bytes.
      if (instance['status'] is! String) {
        throw StateError('status is ${instance['status'].runtimeType}');
      }
      if (instance['type'] is! String) {
        throw StateError('type is missing');
      }
      final image = instance['image'];
      if (image is! Map) throw StateError('image is not an object');
      print(
        '      (status ${instance['status']}, type ${instance['type']}, '
        'cpu ${instance['cpu']}, memory ${instance['memory']})',
      );
    });

    await check(
      'virt.instance.device_list returns the root disk and NIC',
      () async {
        final devices =
            await session.call(
                  'virt.instance.device_list',
                  params: [_instanceName],
                )
                as List;
        final types = devices
            .cast<Map>()
            .map((device) => '${device['dev_type']}')
            .toSet();
        print('      (${devices.length} devices: ${types.join(', ')})');
        if (devices.isEmpty) throw StateError('no devices were reported');
        for (final device in devices.cast<Map>()) {
          if (device['name'] is! String || device['dev_type'] is! String) {
            throw StateError('device is missing name/dev_type: $device');
          }
        }
      },
    );

    await check('virt.instance.start runs the instance', () async {
      await session.runJob(
        'virt.instance.start',
        params: [_instanceName],
        timeout: const Duration(minutes: 5),
      );
      await session.awaitStatus(_instanceName, const {'RUNNING'});
    });

    await check('virt.instance.stop accepts the options object', () async {
      // The app sends a bounded timeout with force:false so a wedged guest
      // cannot hang the job indefinitely.
      await session.runJob(
        'virt.instance.stop',
        params: [
          _instanceName,
          {'timeout': 90, 'force': false},
        ],
        timeout: const Duration(minutes: 5),
      );
      await session.awaitStatus(_instanceName, const {'STOPPED'});
    });

    await check('virt.instance.restart accepts the options object', () async {
      await session.runJob(
        'virt.instance.restart',
        params: [
          _instanceName,
          {'timeout': 90, 'force': false},
        ],
        timeout: const Duration(minutes: 5),
      );
      await session.awaitStatus(_instanceName, const {'RUNNING'});
    });

    await check('a forced stop accepts timeout -1', () async {
      await session.runJob(
        'virt.instance.stop',
        params: [
          _instanceName,
          {'timeout': -1, 'force': true},
        ],
        timeout: const Duration(minutes: 5),
      );
      await session.awaitStatus(_instanceName, const {'STOPPED'});
    });

    await check('virt.instance.update merges a partial payload', () async {
      const configuration = VirtInstanceConfiguration(
        memoryMiB: 512,
        autostart: true,
      );
      await session.runJob(
        'virt.instance.update',
        params: [_instanceName, configuration.toApiJson()],
        timeout: const Duration(minutes: 5),
      );
      final instance = await session.instance(_instanceName);
      final memory = instance['memory'];
      if (memory != 512 * 1024 * 1024) {
        throw StateError('memory is $memory, expected ${512 * 1024 * 1024}');
      }
      if (instance['autostart'] != true) {
        throw StateError('autostart was not applied');
      }
      // The partial update must not have cleared the fields it omitted.
      if (instance['cpu'] == null) {
        throw StateError('cpu was cleared by a partial update');
      }
      print('      (memory and autostart applied, cpu preserved)');
    });
  } finally {
    if (created && !keep) {
      await check('virt.instance.delete removes it', () async {
        await session.runJob(
          'virt.instance.delete',
          params: [_instanceName],
          timeout: const Duration(minutes: 5),
        );
        final remaining =
            await session.call(
                  'virt.instance.query',
                  params: [
                    [
                      ['name', '=', _instanceName],
                    ],
                  ],
                )
                as List;
        if (remaining.isNotEmpty) throw StateError('still listed');
      });
    } else if (created) {
      print('      (--keep: leaving $_instanceName in place)');
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
      ..badCertificateCallback = (cert, h, p) {
        stderr.writeln('      (cert ${sha256.convert(cert.der)})');
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

  /// Runs a method that may answer with a job id and waits for a terminal
  /// state. Methods that answer directly are treated as already complete.
  Future<void> runJob(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final jobId = await call(method, params: params);
    if (jobId is! int) return;
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final jobs = await call(
        'core.get_jobs',
        params: [
          [
            ['id', '=', jobId],
          ],
        ],
      );
      if (jobs is! List || jobs.isEmpty) continue;
      final job = jobs.first as Map;
      switch (job['state']) {
        case 'SUCCESS':
          return;
        case 'FAILED':
        case 'ABORTED':
          throw StateError(
            '$method job $jobId ${job['state']}: ${job['error']}',
          );
      }
    }
    throw StateError('$method job $jobId did not finish within $timeout');
  }

  Future<Map<Object?, Object?>> instance(String name) async {
    final rows =
        await call(
              'virt.instance.query',
              params: [
                [
                  ['name', '=', name],
                ],
              ],
            )
            as List;
    if (rows.isEmpty) throw StateError('$name is not present');
    return rows.first as Map;
  }

  Future<void> awaitStatus(String name, Set<String> statuses) async {
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    var last = '';
    while (DateTime.now().isBefore(deadline)) {
      final row = await instance(name);
      last = '${row['status']}';
      if (statuses.contains(last)) {
        print('      (status $last)');
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    throw StateError('stayed $last, never reached ${statuses.join('/')}');
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
