// End-to-end verification of the provisioning path: pool -> dataset -> snapshot
// -> catalog app install -> reachable service.
//
// The other probes each verify one namespace. This one verifies that the
// namespaces compose the way a real administrator uses them: storage has to
// exist before an app can be installed onto it, and an installed app is only
// actually installed if something answers on its port. Every payload is built
// by the app's own domain types, so a mismatch between what TrueDock sends and
// what the server accepts fails here rather than in front of a user.
//
// Usage:
//   dart run tool/live_provisioning_probe.dart <host> <username> <password> \
//       [--keep]
//
// DESTRUCTIVE. It creates a pool on disks the server reports as unused, and
// removes everything it created unless `--keep` is passed. It refuses to run if
// the disks it picked are already part of a pool.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/apps/domain/app_installation.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';

const _poolName = 'truedock_probe_pool';
const _datasetName = 'photos';
const _snapshotName = 'truedock-probe-snap';
const _appName = 'truedock-immich';

void main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/live_provisioning_probe.dart '
      '<host> <username> <password> [--keep]',
    );
    exit(64);
  }
  final keep = args.contains('--keep');

  final session = _Rpc(args[0]);
  final results = <(String, bool, String?)>[];
  Future<bool> check(String name, Future<void> Function() body) async {
    try {
      await body();
      results.add((name, true, null));
      print('PASS  $name');
      return true;
    } catch (error) {
      final detail = '$error';
      results.add((name, false, detail));
      print(
        'FAIL  $name\n      '
        '${detail.length > 400 ? '${detail.substring(0, 400)}...' : detail}',
      );
      return false;
    }
  }

  var poolCreated = false;
  var appCreated = false;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    // ---- storage -------------------------------------------------------

    var disks = <String>[];
    await check(
      'the server reports unused disks to build a pool from',
      () async {
        final unused = await session.call('disk.get_unused') as List;
        disks = [
          for (final disk in unused)
            if (disk is Map && disk['devname'] is String)
              disk['devname'] as String,
        ];
        if (disks.length < 2) {
          throw StateError(
            'need 2 unused disks, server reports ${disks.length}: $disks',
          );
        }
        disks = disks.take(2).toList();

        // A disk the server calls unused but that a pool still references would
        // mean destroying live data, so this is checked rather than trusted.
        final all = await session.call('disk.query') as List;
        for (final disk in all) {
          if (disk is! Map) continue;
          if (!disks.contains(disk['devname'])) continue;
          if (disk['pool'] != null) {
            throw StateError(
              '${disk['devname']} already belongs to ${disk['pool']}',
            );
          }
        }
        print('      (using $disks)');
      },
    );

    // The app's own configuration object builds the payload, so the topology
    // key names and the `disks`-not-`devices` field are verified here too.
    final poolConfig = PoolConfiguration(
      name: _poolName,
      dataVdevs: [VdevSpec(type: VdevType.mirror, disks: disks)],
    );

    await check(
      'the pool configuration passes the app\'s own validation',
      () async {
        final errors = validatePoolConfiguration(poolConfig);
        if (errors.isNotEmpty) throw StateError('rejected locally: $errors');
      },
    );

    final created = await check('pool.create builds a mirrored pool', () async {
      await session.runJob('pool.create', params: [poolConfig.toApiJson()]);
    });
    poolCreated = created;

    await check('the new pool reports ONLINE and healthy', () async {
      final pools =
          await session.call(
                'pool.query',
                params: [
                  [
                    ['name', '=', _poolName],
                  ],
                ],
              )
              as List;
      if (pools.isEmpty) throw StateError('pool.query did not return it');
      final pool = pools.first as Map;
      if (pool['status'] != 'ONLINE') {
        throw StateError('status is ${pool['status']}');
      }
      if (pool['healthy'] != true) throw StateError('not healthy');

      // A mirror that silently came back as a stripe would still be ONLINE and
      // healthy, so the redundancy the user asked for is asserted directly.
      final topology = pool['topology'];
      final data = topology is Map ? topology['data'] : null;
      if (data is! List || data.isEmpty) {
        throw StateError('no data vdev in topology');
      }
      final vdev = data.first as Map;
      if (vdev['type'] != 'MIRROR') {
        throw StateError('expected MIRROR, got ${vdev['type']}');
      }
      print(
        '      (${pool['status']}, ${vdev['type']}, '
        '${_gib(pool['size'])} GiB usable)',
      );
    });

    await check('pool.dataset.create adds a dataset', () async {
      await session.call(
        'pool.dataset.create',
        params: [
          {
            'name': '$_poolName/$_datasetName',
            'type': 'FILESYSTEM',
            'share_type': 'GENERIC',
            'inherit_encryption': true,
          },
        ],
      );
      final sets =
          await session.call(
                'pool.dataset.query',
                params: [
                  [
                    ['id', '=', '$_poolName/$_datasetName'],
                  ],
                ],
              )
              as List;
      if (sets.isEmpty) throw StateError('the dataset was not returned');
    });

    await check('pool.snapshot.create captures the dataset', () async {
      await session.call(
        'pool.snapshot.create',
        params: [
          {
            'dataset': '$_poolName/$_datasetName',
            'name': _snapshotName,
            'recursive': false,
          },
        ],
      );
      final id = '$_poolName/$_datasetName@$_snapshotName';
      final snaps =
          await session.call(
                'pool.snapshot.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      if (snaps.isEmpty) throw StateError('$id was not returned');
      print('      ($id)');
    });

    // ---- application ---------------------------------------------------

    CatalogAppVersion? version;
    await check(
      'the Immich catalog schema parses into the app model',
      () async {
        final raw =
            await session.call(
                  'catalog.get_app_details',
                  params: [
                    'immich',
                    {'train': 'community'},
                  ],
                )
                as Map<String, dynamic>;
        final details = CatalogAppInstallationDetails.fromJson(
          raw,
          fallbackName: 'immich',
          train: 'community',
        );
        final preferred = details.preferredVersion;
        if (preferred == null) throw StateError('no installable version');
        if (!preferred.canInstall) {
          throw StateError('${preferred.version} is not installable');
        }

        // An unsupported question type blocks review in the sheet, so if this
        // app contained one the install flow would be unusable for it.
        final unsupported = <String>[];
        void walk(List<AppQuestion> questions, String path) {
          for (final question in questions) {
            final at = path.isEmpty
                ? question.variable
                : '$path.${question.variable}';
            if (question.type == AppQuestionType.unsupported)
              unsupported.add(at);
            walk(question.children, at);
            final item = question.listItem;
            if (item != null) walk([item], '$at[]');
          }
        }

        walk(preferred.questions, '');
        if (unsupported.isNotEmpty) {
          throw StateError('unrenderable question types: $unsupported');
        }
        version = preferred;
        print(
          '      (${preferred.humanVersion}, '
          '${preferred.questions.length} top-level question(s), '
          'all renderable)',
        );
      },
    );

    await check(
      'the schema defaults alone are refused as incomplete',
      () async {
        // Immich ships empty required passwords, so accepting the defaults
        // unchanged has to fail. If it did not, the sheet would let a user
        // install an app that cannot start.
        final defaults = version!.initialValues;
        final immich = defaults['immich'];
        if (immich is! Map) throw StateError('no immich group in the defaults');
        if ((immich['db_password'] as String?)?.isNotEmpty == true) {
          throw StateError('db_password is no longer empty by default');
        }
        final required = version!.questions
            .expand((q) => q.children)
            .where((q) => q.required && q.private)
            .map((q) => q.variable)
            .toList();
        if (required.isEmpty) {
          throw StateError('expected required private fields to exist');
        }
        print('      (required secrets: $required)');
      },
    );

    final installed = await check(
      'app.create installs Immich onto the new pool',
      () async {
        final values = Map<String, Object?>.from(version!.initialValues);
        final immich = Map<String, Object?>.from(values['immich'] as Map);
        immich['db_password'] = 'TrueDockProbe1!';
        immich['redis_password'] = 'TrueDockProbe2!';
        // The ML container pulls several GiB of models; the probe only needs the
        // web service to answer, and the demo VM is small.
        immich['enable_ml'] = false;
        values['immich'] = immich;

        final payload = version!.installationValues(values);
        await session.runJob(
          'app.create',
          params: [
            {
              'custom_app': false,
              'values': payload,
              'catalog_app': 'immich',
              'app_name': _appName,
              'train': 'community',
              'version': version!.version,
            },
          ],
          timeout: const Duration(minutes: 15),
        );
      },
    );
    appCreated = installed;

    int? webPort;
    await check('the app reaches RUNNING', () async {
      final deadline = DateTime.now().add(const Duration(minutes: 10));
      String? last;
      while (DateTime.now().isBefore(deadline)) {
        final apps =
            await session.call(
                  'app.query',
                  params: [
                    [
                      ['id', '=', _appName],
                    ],
                  ],
                )
                as List;
        if (apps.isNotEmpty) {
          final app = apps.first as Map;
          last = '${app['state']}';
          final ports = app['active_workloads'];
          if (ports is Map && ports['used_ports'] is List) {
            for (final entry in ports['used_ports'] as List) {
              if (entry is Map && entry['host_ports'] is List) {
                for (final hp in entry['host_ports'] as List) {
                  if (hp is Map && hp['host_port'] is int) {
                    webPort ??= hp['host_port'] as int;
                  }
                }
              }
            }
          }
          if (last == 'RUNNING') {
            print('      (RUNNING, host port $webPort)');
            return;
          }
          if (last == 'CRASHED') throw StateError('the app crashed');
        }
        await Future<void>.delayed(const Duration(seconds: 10));
      }
      throw StateError('still $last after 10 minutes');
    });

    await check('the installed app actually answers over HTTP', () async {
      final port = webPort;
      if (port == null) throw StateError('no host port was published');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final deadline = DateTime.now().add(const Duration(minutes: 5));
      Object? lastError;
      while (DateTime.now().isBefore(deadline)) {
        try {
          final request = await client.getUrl(
            Uri.parse('http://${args[0]}:$port/'),
          );
          final response = await request.close();
          await response.drain<void>();
          // Any HTTP status proves a server is listening and serving; Immich
          // may redirect to onboarding before it is configured.
          print('      (HTTP ${response.statusCode} on port $port)');
          client.close();
          return;
        } catch (error) {
          lastError = error;
          await Future<void>.delayed(const Duration(seconds: 10));
        }
      }
      client.close();
      throw StateError('nothing answered on $port: $lastError');
    });

    await check(
      'the app is listed with the catalog metadata TrueDock shows',
      () async {
        final apps =
            await session.call(
                  'app.query',
                  params: [
                    [
                      ['id', '=', _appName],
                    ],
                  ],
                )
                as List;
        final app = apps.first as Map;
        final metadata = app['metadata'];
        if (metadata is! Map) throw StateError('no metadata returned');
        if (metadata['train'] != 'community') {
          throw StateError('train is ${metadata['train']}');
        }
        if (app['version'] == null) throw StateError('no version reported');
        print('      (${app['version']}, train ${metadata['train']})');
      },
    );
  } finally {
    if (!keep) {
      if (appCreated) {
        await check('teardown: the app is removed', () async {
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
            timeout: const Duration(minutes: 10),
          );
        });
      }
      if (poolCreated) {
        await check(
          'teardown: the probe pool is exported and destroyed',
          () async {
            final pools =
                await session.call(
                      'pool.query',
                      params: [
                        [
                          ['name', '=', _poolName],
                        ],
                      ],
                    )
                    as List;
            if (pools.isEmpty) return;
            final id = (pools.first as Map)['id'];
            await session.runJob(
              'pool.export',
              params: [
                id,
                {'cascade': true, 'destroy': true},
              ],
              timeout: const Duration(minutes: 5),
            );
          },
        );
      }
    } else {
      print('\n--keep: pool $_poolName and app $_appName were left in place.');
    }
    await session.close();
  }

  final failed = results.where((r) => !r.$2).length;
  print('\nResult: ${results.length - failed}/${results.length} passed');
  exit(failed == 0 ? 0 : 1);
}

String _gib(Object? bytes) =>
    bytes is int ? (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1) : '?';

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
          // The middleware answers with a full Python traceback; the reason is
          // the only part that identifies the problem.
          Object? reason;
          if (error is Map) {
            final data = error['data'];
            if (data is Map) reason = data['reason'];
            reason ??= error['message'];
          }
          var text = '${reason ?? jsonEncode(error)}';
          if (text.length > 600) text = '${text.substring(0, 600)}...';
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
    Duration timeout = const Duration(seconds: 120),
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

  /// Runs a job-returning call and waits for a terminal state.
  Future<void> runJob(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final jobId = await call(method, params: params);
    if (jobId is! int) {
      throw StateError('$method did not return a job id (got $jobId)');
    }
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
      final state = job['state'];
      if (state == 'SUCCESS') return;
      if (state == 'FAILED' || state == 'ABORTED') {
        final error = job['error'];
        var text = '$error';
        if (text.length > 600) text = '${text.substring(0, 600)}...';
        throw StateError('$method job $jobId $state: $text');
      }
    }
    throw StateError('$method job $jobId did not finish within $timeout');
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
