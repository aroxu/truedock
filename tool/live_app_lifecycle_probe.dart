// Live end-to-end verification of the pool/dataset/snapshot and app
// lifecycle surfaces, against a real TrueNAS SCALE 25.10+ server.
//
// The existing probes cover reads (`live_server_probe.dart`) and the mutating
// payload shapes that can be exercised inside a scratch pool
// (`live_mutation_probe.dart`). Two surfaces could not be reached that way and
// were documented as unverified: the app lifecycle needs an actually installed
// app rather than a fresh VM, and that in turn needs Docker configured against
// a real pool with a synced catalog.
//
// This probe builds that chain and then exercises it:
//
//   pool.create -> docker.update(pool) -> catalog sync -> app.create(Immich)
//   -> app.stop/start -> app.redeploy -> app.config/update
//   -> app.upgrade_summary -> app.rollback (when a prior version exists)
//   -> app.delete
//
// Usage:
//   dart run tool/live_app_lifecycle_probe.dart <host> <user> <password> \
//       [--keep]
//
// DESTRUCTIVE. It consumes disks the server reports as unused and points the
// server-wide Docker pool setting at the pool it creates, restoring the
// previous setting afterwards. With `--keep` the pool and app are left in
// place so the result can be inspected in the TrueDock UI; otherwise both are
// removed.
//
// Payloads are built from the app's own domain types wherever one exists, so a
// shape that drifts from the shipped app fails here rather than diverging
// silently. Credentials come from argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';

/// Distinctive names so anything left behind is obviously probe-created.
const _poolName = 'truedock_data';

/// Catalog app to install. Overridable because the lifecycle being verified is
/// the same for any catalog app, while the resources needed are not: Immich
/// brings up Postgres plus machine-learning containers and needs several GiB
/// more RAM than a small test VM has.
var _appName = 'syncthing';

void main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final keep = args.contains('--keep');
  if (positional.length < 3 || positional.length > 4) {
    stderr.writeln(
      'Usage: dart run tool/live_app_lifecycle_probe.dart <host> <username> '
      '<password> [appName] [--keep]',
    );
    exit(64);
  }
  if (positional.length == 4) _appName = positional[3];
  final session = _Session(
    host: positional[0],
    username: positional[1],
    password: positional[2],
  );

  String? previousDockerPool;
  var poolCreated = false;
  var appInstalled = false;

  try {
    await session.connect();
    await session.login();

    // ---- storage ----------------------------------------------------------

    await session.check(
      'scratch disks are unused before we format them',
      () async {
        for (final pool in await session.call('pool.query') as List) {
          if ((pool as Map)['name'] == _poolName) {
            // Left behind by an earlier --keep run. Reuse it rather than
            // refusing: the pool is probe-created and named distinctively, so
            // rebuilding it would only re-verify pool.create.
            session.reusingPool = true;
            session.note('reusing the existing $_poolName pool');
            return;
          }
        }
        final unused = await session.call('disk.get_unused') as List;
        session.disks = [
          for (final disk in unused)
            if ((disk as Map)['pool'] == null) disk['devname'] as String,
        ];
        if (session.disks.length < 2) {
          throw StateError(
            'need 2 unused disks for a mirror, found ${session.disks.length}',
          );
        }
        session.disks = session.disks.take(2).toList();
        session.note('using ${session.disks.join(', ')} for a mirror');
      },
    );

    await session.check(
      'pool.create builds a real mirrored data pool',
      () async {
        if (session.reusingPool) {
          poolCreated = true;
          session.note('skipped: the pool already exists from a previous run');
          return;
        }
        final configuration = PoolConfiguration(
          name: _poolName,
          dataVdevs: [VdevSpec(type: VdevType.mirror, disks: session.disks)],
        );
        await session.runJob(
          'pool.create',
          params: [configuration.toApiJson()],
        );
        poolCreated = true;
        final pools = await session.call('pool.query') as List;
        final pool = pools.cast<Map>().firstWhere(
          (p) => p['name'] == _poolName,
        );
        if (pool['status'] != 'ONLINE') {
          throw StateError('pool status is ${pool['status']}, not ONLINE');
        }
        session.note('pool ${pool['name']} is ${pool['status']}');
      },
    );

    await session.check('pool.dataset.create makes a dataset', () async {
      final present =
          await session.call(
                'pool.dataset.query',
                params: [
                  [
                    ['id', '=', '$_poolName/media'],
                  ],
                ],
              )
              as List;
      if (present.isEmpty) {
        await session.call(
          'pool.dataset.create',
          params: [
            {'name': '$_poolName/media', 'type': 'FILESYSTEM'},
          ],
        );
      } else {
        session.note('the dataset already exists from a previous run');
      }
      final datasets =
          await session.call(
                'pool.dataset.query',
                params: [
                  [
                    ['id', '=', '$_poolName/media'],
                  ],
                ],
              )
              as List;
      if (datasets.isEmpty) throw StateError('dataset was not created');
    });

    await session.check('pool.snapshot.create takes a snapshot', () async {
      // Unique per run so a reused pool cannot collide with an old snapshot.
      session.snapshot = 'probe-${DateTime.now().millisecondsSinceEpoch}';
      await session.call(
        'pool.snapshot.create',
        params: [
          {
            'dataset': '$_poolName/media',
            'name': session.snapshot,
            'recursive': false,
          },
        ],
      );
      final snapshots =
          await session.call(
                'pool.snapshot.query',
                params: [
                  [
                    ['id', '=', '$_poolName/media@${session.snapshot}'],
                  ],
                ],
              )
              as List;
      if (snapshots.isEmpty) throw StateError('snapshot was not created');
      session.note('snapshot $_poolName/media@${session.snapshot} exists');
    });

    // ---- app platform -----------------------------------------------------

    await session.check(
      'docker.update points the app pool at the new pool',
      () async {
        final config = await session.call('docker.config') as Map;
        previousDockerPool = config['pool'] as String?;
        session.note('previous app pool: ${previousDockerPool ?? 'unset'}');
        await session.runJob(
          'docker.update',
          params: [
            {'pool': _poolName},
          ],
          timeout: const Duration(minutes: 6),
        );
        final status = await session.call('docker.status') as Map;
        session.note('docker status: ${status['status']}');
        if (status['status'] != 'RUNNING') {
          throw StateError('docker did not start: ${status['description']}');
        }
      },
    );

    await session.check('the catalog syncs and advertises $_appName', () async {
      await session.runJob(
        'catalog.sync',
        timeout: const Duration(minutes: 10),
      );
      final available =
          await session.call(
                'app.available',
                params: [
                  [
                    ['name', '=', _appName],
                  ],
                ],
              )
              as List;
      if (available.isEmpty) {
        throw StateError('$_appName is not in the synced catalog');
      }
      final entry = available.first as Map;
      session.trains = '${entry['train']}';
      session.note('$_appName found in train ${entry['train']}');
    });

    await session.check('app.create installs $_appName', () async {
      final present =
          await session.call(
                'app.query',
                params: [
                  [
                    ['name', '=', _appName],
                  ],
                ],
              )
              as List;
      if (present.isNotEmpty) {
        // Left installed by an earlier --keep run. Reuse it: the lifecycle
        // checks below are what matter, and reinstalling would only re-verify
        // app.create.
        appInstalled = true;
        session.note('reusing the already installed $_appName');
        return;
      }
      await session.runJob(
        'app.create',
        params: [
          {
            'custom_app': false,
            'values': <String, Object?>{},
            'catalog_app': _appName,
            'app_name': _appName,
            'train': session.trains,
          },
        ],
        timeout: const Duration(minutes: 25),
      );
      appInstalled = true;
      final app = await session.app();
      session.note('$_appName state: ${app['state']}');
    });

    await session.check('the app reaches a running state', () async {
      final app = await session.awaitAppState(const {
        'RUNNING',
      }, timeout: const Duration(minutes: 10));
      final portals = app['portals'];
      session.note('portals: ${jsonEncode(portals)}');
      if (portals is! Map || portals.isEmpty) {
        throw StateError('no portal was published, so the app is unreachable');
      }
    });

    await session.check('the published portal answers over HTTP', () async {
      final app = await session.app();
      final portals = app['portals'] as Map;
      final url = portals.values.first.toString();
      session.note('probing $url');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20);
      client.badCertificateCallback = (_, _, _) => true;
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        await response.drain<void>();
        session.note('portal responded ${response.statusCode}');
        if (response.statusCode >= 500) {
          throw StateError('portal returned ${response.statusCode}');
        }
      } finally {
        client.close(force: true);
      }
    });

    // ---- app lifecycle ----------------------------------------------------

    await session.check('app.stop stops the app', () async {
      await session.runJob('app.stop', params: [_appName]);
      await session.awaitAppState(const {'STOPPED'});
    });

    await session.check('app.start starts it again', () async {
      await session.runJob('app.start', params: [_appName]);
      await session.awaitAppState(const {'RUNNING', 'DEPLOYING'});
    });

    await session.check('app.config returns the live values', () async {
      final config = await session.call('app.config', params: [_appName]);
      if (config is! Map || config.isEmpty) {
        throw StateError('app.config returned $config');
      }
      session.values = Map<String, Object?>.from(config);
      session.note('${session.values.length} config keys');
    });

    await session.check('app.update accepts the full values object', () async {
      // The app sends the whole resolved values map rather than a diff, which
      // is the contract app.update documents. Re-sending what app.config
      // returned must therefore be accepted as a no-op change.
      await session.runJob(
        'app.update',
        params: [
          _appName,
          {'values': session.values},
        ],
        timeout: const Duration(minutes: 15),
      );
      await session.awaitAppState(const {'RUNNING', 'DEPLOYING', 'STOPPED'});
    });

    await session.check('app.redeploy recreates the containers', () async {
      await session.runJob(
        'app.redeploy',
        params: [_appName],
        timeout: const Duration(minutes: 15),
      );
      await session.awaitAppState(const {'RUNNING', 'DEPLOYING'});
    });

    await session.check(
      'app.upgrade_summary answers for an installed app',
      () async {
        try {
          final summary = await session.call(
            'app.upgrade_summary',
            params: [
              _appName,
              {'app_version': 'latest'},
            ],
          );
          if (summary is! Map) throw StateError('summary was $summary');
          session.note(
            'upgrade available: ${summary['latest_version']} '
            '(installed ${summary['upgrade_version'] ?? 'n/a'})',
          );
        } on _RpcError catch (error) {
          // A freshly installed app is already on the newest version, which the
          // middleware reports as an error rather than an empty summary. That is
          // the same path the UI must render, so accept it explicitly.
          final message = error.toString();
          if (message.contains('no update') ||
              message.contains('not have') ||
              message.contains('latest')) {
            session.note('already newest version: $message');
            return;
          }
          rethrow;
        }
      },
    );

    await session.check(
      'app.rollback_versions backs the rollback picker',
      () async {
        // The rollback sheet used to source its versions from
        // app.upgrade_summary, which raises "No upgrade available" once the app
        // is newest -- exactly when a rollback is wanted. This asserts the
        // method the app now uses answers for an up-to-date app.
        final versions =
            await session.call('app.rollback_versions', params: [_appName])
                as List;
        session.note('rollback targets: ${versions.join(', ')}');
        session.rollbackVersions = versions.whereType<String>().toList();
      },
    );

    await session.check('app.rollback accepts the payload shape', () async {
      if (session.rollbackVersions.isEmpty) {
        // A freshly installed app has no prior deployment, so there is nothing
        // to roll back to. Verify the shape instead: the server must reject the
        // call for the version, not for the payload structure.
        // The middleware validates the payload before it checks whether the
        // version exists, so a bogus version is accepted into a job that then
        // fails. That still proves the shape: what must not happen is a
        // validation rejection naming a field.
        try {
          final jobId = await session.call(
            'app.rollback',
            params: [
              _appName,
              {'app_version': '0.0.0', 'rollback_snapshot': true},
            ],
          );
          session.note('shape accepted (job $jobId, expected to fail)');
        } on _RpcError catch (error) {
          final message = error.toString();
          if (message.contains('Input should be') ||
              message.contains('extra_forbidden') ||
              message.contains('Field required')) {
            throw StateError('app.rollback rejected the shape: $message');
          }
          session.note('version rejected, shape accepted');
        }
        return;
      }
      final target = session.rollbackVersions.first;
      await session.runJob(
        'app.rollback',
        params: [
          _appName,
          {'app_version': target, 'rollback_snapshot': true},
        ],
        timeout: const Duration(minutes: 15),
      );
      final app = await session.awaitAppState(const {
        'RUNNING',
        'DEPLOYING',
        'STOPPED',
      });
      session.note('rolled back to ${app['version']}');
    });
  } finally {
    if (!keep) {
      if (appInstalled) {
        await session.check('app.delete removes the app', () async {
          await session.runJob(
            'app.delete',
            params: [
              _appName,
              {
                'remove_images': true,
                'remove_ix_volumes': true,
                'force_remove_ix_volumes': true,
              },
            ],
            timeout: const Duration(minutes: 15),
          );
          final remaining =
              await session.call(
                    'app.query',
                    params: [
                      [
                        ['name', '=', _appName],
                      ],
                    ],
                  )
                  as List;
          if (remaining.isNotEmpty) throw StateError('the app is still listed');
        });
      }
      if (previousDockerPool != _poolName) {
        await session.check('the app pool setting is restored', () async {
          await session.runJob(
            'docker.update',
            params: [
              {'pool': previousDockerPool},
            ],
            timeout: const Duration(minutes: 6),
          );
        });
      }
      if (poolCreated) {
        await session.check('pool.export removes the probe pool', () async {
          await session.runJob(
            'pool.export',
            params: [
              await session.poolId(),
              {'destroy': true},
            ],
            timeout: const Duration(minutes: 6),
          );
        });
      }
    } else {
      session.note('--keep: leaving $_poolName and $_appName in place');
    }
    await session.close();
  }

  session.report();
}

String _short(String value) =>
    value.length <= 160 ? value : '${value.substring(0, 160)}...';

/// Owns the socket, the JSON-RPC plumbing, and the PASS/FAIL tally.
class _Session {
  _Session({
    required this.host,
    required this.username,
    required this.password,
  });

  final String host;
  final String username;
  final String password;

  final _results = <(String, bool, String?)>[];
  final _pending = <int, Completer<Object?>>{};
  WebSocket? _socket;
  var _nextId = 1;

  List<String> disks = const [];

  /// True when the pool from an earlier `--keep` run is being reused.
  var reusingPool = false;

  /// Snapshot name for this run, unique so a reused pool cannot collide.
  var snapshot = '';

  /// Versions the server says the app can be rolled back to.
  List<String> rollbackVersions = const [];
  String trains = 'community';
  Map<String, Object?> values = const {};

  void note(String message) => print('      ($message)');

  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      _results.add((name, true, null));
      print('PASS  $name');
    } catch (error) {
      _results.add((name, false, '$error'));
      print('FAIL  $name\n      ${_short('$error')}');
    }
  }

  Future<void> connect() async {
    await check('connect to /api/current over WSS', () async {
      final client = HttpClient()
        ..badCertificateCallback = (cert, h, p) {
          note('trusting cert ${sha256.convert(cert.der)}');
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
            completer.completeError(_RpcError(jsonEncode(error)));
          } else {
            completer.complete(decoded['result']);
          }
        },
        onError: (Object error) => _failPending(error),
        onDone: () => _failPending(StateError('socket closed')),
      );
    });
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  Future<void> login() => check('auth.login_ex authenticates', () async {
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
  });

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

  /// Runs a job-returning method and waits for a terminal state. Methods that
  /// answer directly rather than with a job id are accepted as already done.
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

  Future<Map<Object?, Object?>> app() async {
    final apps =
        await call(
              'app.query',
              params: [
                [
                  ['name', '=', _appName],
                ],
              ],
            )
            as List;
    if (apps.isEmpty) throw StateError('$_appName is not installed');
    return apps.first as Map;
  }

  /// Polls until the app settles into one of [states].
  Future<Map<Object?, Object?>> awaitAppState(
    Set<String> states, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var last = '';
    while (DateTime.now().isBefore(deadline)) {
      final current = await app();
      last = '${current['state']}';
      if (states.contains(last)) {
        note('state $last');
        return current;
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    throw StateError('app stayed in $last, never reached ${states.join('/')}');
  }

  Future<int> poolId() async {
    final pools = await call('pool.query') as List;
    final pool = pools.cast<Map>().firstWhere((p) => p['name'] == _poolName);
    return pool['id'] as int;
  }

  Future<void> close() async {
    try {
      await call('auth.logout');
    } catch (_) {}
    await _socket?.close();
  }

  void report() {
    final failed = _results.where((r) => !r.$2).toList();
    print('');
    print(
      'Result: ${_results.length - failed.length}/${_results.length} passed'
      '${failed.isEmpty ? '' : ', ${failed.length} failed'}',
    );
    for (final failure in failed) {
      print('  FAILED ${failure.$1}: ${_short(failure.$3 ?? '')}');
    }
    exit(failed.isEmpty ? 0 : 1);
  }
}

class _RpcError implements Exception {
  _RpcError(this.detail);
  final String detail;
  @override
  String toString() => detail;
}
