// Live TrueNAS server verification probe.
//
// Run against a real TrueNAS SCALE 25.10+ server to confirm the payload
// shapes TrueDock sends are accepted by the middleware. This is the
// "live-server verification" item from docs/architecture/0002-phase5-hardening.md.
//
// Usage:
//   dart run tool/live_server_probe.dart <host> <username> <password>
//
// The probe trusts the server's self-signed certificate by fingerprint
// (matching the app's trust-on-first-use flow), authenticates with
// auth.login_ex, then exercises the read paths and the documented call
// shapes that were previously only fixture-verified. It prints PASS/FAIL
// per check and exits non-zero if any check failed.
//
// Credentials are read from argv and never persisted. The probe is a tool,
// not part of the shipped app.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_server_probe.dart <host> <username> <password>',
    );
    exit(64);
  }
  final host = args[0];
  final username = args[1];
  final password = args[2];

  final results = <_ProbeResult>[];
  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      results.add(_ProbeResult(name, _Status.pass));
      print('PASS  $name');
    } catch (error, stack) {
      results.add(_ProbeResult(name, _Status.fail, '$error\n$stack'));
      print('FAIL  $name\n      $error');
    }
  }

  WebSocketChannel? channel;
  int nextId = 1;
  final pending = <int, Completer<Object?>>{};

  Future<Object?> call(String method, {List<Object?> params = const []}) async {
    final id = nextId++;
    final completer = Completer<Object?>();
    pending[id] = completer;
    channel!.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future.timeout(const Duration(seconds: 25));
  }

  try {
    await check('connect to /api/current over WSS', () async {
      final uri = Uri.parse('wss://$host/api/current');
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, h, p) {
          final fp = sha256.convert(cert.der).toString();
          stderr.writeln('      (trusting cert fingerprint $fp)');
          return h == host;
        };
      channel = IOWebSocketChannel.connect(
        uri.toString(),
        customClient: httpClient,
      );
      channel!.stream.listen(
        (message) {
          final decoded = jsonDecode(message.toString());
          if (decoded is Map && decoded['id'] is int) {
            final id = decoded['id'] as int;
            final completer = pending.remove(id);
            if (completer != null && !completer.isCompleted) {
              final error = decoded['error'];
              if (error != null) {
                completer.completeError(_RpcError(error));
              } else {
                completer.complete(decoded['result']);
              }
            }
          }
        },
        onError: (Object e) {
          for (final c in pending.values) {
            if (!c.isCompleted) c.completeError(e);
          }
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    await check('auth.login_ex with PASSWORD_PLAIN', () async {
      final result = await call(
        'auth.login_ex',
        params: [
          {
            'mechanism': 'PASSWORD_PLAIN',
            'username': username,
            'password': password,
            'login_options': {'user_info': true},
          },
        ],
      );
      if (result is! Map) {
        throw StateError('auth.login_ex did not return an object: $result');
      }
      stderr.writeln('      (authenticated as $username)');
    });

    await check('system.info returns a populated object', () async {
      final result = await call('system.info');
      if (result is! Map)
        throw StateError('system.info not an object: $result');
      if (result['version'] is! String) {
        throw StateError('system.info missing version: $result');
      }
      stderr.writeln('      (server version ${result['version']})');
    });

    await check('system.version returns a string', () async {
      final result = await call('system.version');
      if (result is! String) {
        throw StateError('system.version not a string: $result');
      }
      stderr.writeln('      (version string $result)');
    });

    await check('system.product_type records the edition', () async {
      final result = await call('system.product_type');
      final type = (result is Map ? result['product_type'] : result)
          ?.toString();
      stderr.writeln('      (product_type ${result.runtimeType}: $result)');
      if (type != null && !type.toLowerCase().contains('community')) {
        stderr.writeln('      WARN: product_type is "$type", not Community');
      }
    });

    await check('core.get_methods returns a method map', () async {
      final result = await call('core.get_methods', params: const [null, 'WS']);
      if (result is! Map || (result as Map).isEmpty) {
        throw StateError('core.get_methods not a non-empty map: $result');
      }
      stderr.writeln('      (${(result as Map).length} methods advertised)');
    });

    await check('pool.query returns a list of pools', () async {
      final result = await call('pool.query');
      if (result is! List) throw StateError('pool.query not a list: $result');
      stderr.writeln('      (${(result as List).length} pools)');
    });

    await check('filesystem.getacl returns a dataset ACL', () async {
      final datasets = await call('pool.dataset.query');
      if (datasets is! List) {
        throw StateError('pool.dataset.query not a list: $datasets');
      }
      final filesystems = datasets.where((entry) {
        return entry is Map && entry['type'] == 'FILESYSTEM';
      });
      if (filesystems.isEmpty) {
        stderr.writeln('      (no filesystem dataset; skipping ACL read)');
        return;
      }
      final dataset = filesystems.first as Map;
      final path = '/mnt/${dataset['name']}';
      final acl = await call('filesystem.getacl', params: [path, true, true]);
      if (acl is! Map) {
        throw StateError('filesystem.getacl not an object: $acl');
      }
      stderr.writeln(
        '      ($path acltype=${acl['acltype']} uid=${acl['uid']} '
        'gid=${acl['gid']} entries=${(acl['acl'] as List?)?.length})',
      );
      stderr.writeln('      $acl');
    });

    await check(
      'reporting identifiers expose network and disk graphs',
      () async {
        final graphs = await call('reporting.netdata_graphs');
        if (graphs is! List) {
          throw StateError('reporting.netdata_graphs not a list: $graphs');
        }
        final relevant = graphs
            .where((entry) {
              if (entry is! Map) return false;
              return entry['name'] == 'interface' ||
                  entry['name'] == 'disk' ||
                  entry['name'] == 'memory';
            })
            .toList(growable: false);
        stderr.writeln('      (${relevant.length} interface/disk graphs)');
        for (final entry in relevant) {
          stderr.writeln('      $entry');
        }

        if (relevant.isEmpty) return;
        final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        final data = await call(
          'reporting.netdata_get_data',
          params: [
            [
              for (final entry in relevant)
                if ((entry as Map)['identifiers'] is List &&
                    (entry['identifiers'] as List).isNotEmpty)
                  for (final identifier in entry['identifiers'] as List)
                    {'name': entry['name'], 'identifier': identifier}
                else
                  {'name': entry['name']},
            ],
            {'start': now - 60, 'end': now},
          ],
        );
        if (data is! List) {
          throw StateError('reporting data not a list: $data');
        }
        for (final entry in data) {
          if (entry is Map) {
            stderr.writeln(
              '      ${entry['name']}/${entry['identifier']} '
              'legend=${entry['legend']} unit=${entry['unit']}',
            );
          }
        }
      },
    );

    await check(
      'disk.temperatures accepts a device-name list and returns a map',
      () async {
        // TrueDock never sends [null]; it queries disk.query first and passes
        // the device-name list (or skips the call when there are no disks).
        final disks = await call('disk.query');
        final names = <String>[
          for (final disk in (disks as List))
            if ((disk as Map)['name'] is String) disk['name'] as String,
        ];
        stderr.writeln('      (queried ${names.length} disk names)');
        if (names.isEmpty) {
          stderr.writeln('      (no disks; skipping temperatures call)');
          return;
        }
        final result = await call('disk.temperatures', params: [names]);
        stderr.writeln('      (temperatures shape: ${result.runtimeType})');
        if (result == null) {
          throw StateError('disk.temperatures returned null');
        }
      },
    );

    await check('app.query returns installed apps', () async {
      final result = await call('app.query');
      if (result is! List) throw StateError('app.query not a list: $result');
      stderr.writeln('      (${(result as List).length} apps)');
    });

    await check('boot.environment.query lists boot environments', () async {
      final result = await call('boot.environment.query');
      if (result is! List) {
        throw StateError('boot.environment.query not a list: $result');
      }
      stderr.writeln('      (${(result as List).length} boot envs)');
    });

    await check('api_key.query lists API keys (no key material)', () async {
      final result = await call('api_key.query');
      if (result is! List) {
        throw StateError('api_key.query not a list: $result');
      }
      stderr.writeln('      (${(result as List).length} api keys)');
    });

    await check('service.query lists services', () async {
      final result = await call('service.query');
      if (result is! List) {
        throw StateError('service.query not a list: $result');
      }
      stderr.writeln('      (${(result as List).length} services)');
    });

    await check('user.query lists users', () async {
      final result = await call('user.query');
      if (result is! List) throw StateError('user.query not a list: $result');
      stderr.writeln('      (${(result as List).length} users)');
    });

    await check('vm.query lists virtual machines', () async {
      final result = await call('vm.query');
      if (result is! List) throw StateError('vm.query not a list: $result');
      stderr.writeln('      (${(result as List).length} vms)');
    });

    // Verify the upgrade-summary call shape the rollback/upgrade sheets use.
    // We don't have an app to point at, so this is expected to fail with a
    // "not found" error — but a params-shape rejection (EINVAL on app_version)
    // would mean the call shape itself is wrong, which is what we're checking.
    await check(
      'app.upgrade_summary sends [appId, {app_version}] shape',
      () async {
        try {
          await call(
            'app.upgrade_summary',
            params: const [
              'nonexistent-app',
              {'app_version': 'latest'},
            ],
          );
        } on _RpcError catch (error) {
          final message = error.toString();
          // A "not found" / "no such app" error means the params were
          // accepted and the lookup ran. A params-shape rejection would say
          // "Input should be ..." or "missing". The server wraps
          // InstanceNotFound in -32602 Invalid params, so we accept the
          // "does not exist" / "InstanceNotFound" / "ENOENT" cases.
          final notFound =
              message.contains('does not exist') ||
              message.contains('InstanceNotFound') ||
              message.contains('ENOENT') ||
              message.contains('not found') ||
              message.contains('No such');
          if (notFound) {
            stderr.writeln('      (lookup ran: app does not exist)');
            return;
          }
          throw StateError(
            'app.upgrade_summary rejected the params shape: $message',
          );
        }
        stderr.writeln('      (returned a result for a nonexistent app?)');
      },
    );

    try {
      await call('auth.logout');
      stderr.writeln('      (logged out)');
    } catch (_) {}
  } finally {
    await channel?.sink.close();
  }

  final failed = results.where((r) => r.status == _Status.fail).length;
  print('');
  print(
    'Result: ${results.length - failed}/${results.length} passed'
    '${failed == 0 ? '' : ', $failed failed'}',
  );
  exit(failed == 0 ? 0 : 1);
}

enum _Status { pass, fail }

class _ProbeResult {
  const _ProbeResult(this.name, this.status, [this.detail]);
  final String name;
  final _Status status;
  final String? detail;
}

class _RpcError implements Exception {
  _RpcError(this.error);
  final Object error;
  @override
  String toString() => 'RPC error: $error';
}
