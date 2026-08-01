// Live verification of the global network settings surface.
//
// `network.configuration.*` was uncovered until now, which mattered because the
// commit sheet warns that a check-in can clear the gateway or nameservers while
// the app had no way to show or edit those values. This probe verifies the read
// shape (including the configured-versus-effective split that DHCP exposes) and
// that an edit is accepted and reverted.
//
// Usage:
//   dart run tool/live_network_probe.dart <host> <username> <password>
//
// MUTATING BUT SELF-REVERTING. It changes only the search-domain-adjacent
// `httpproxy` field, which does not affect routing, and restores the original
// value afterwards. It never clears a gateway or nameserver: on a DHCP server
// that would sever this connection with no commit window to roll it back.
//
// Payloads are built from the app's own domain types. Credentials come from
// argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/network_configuration.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_network_probe.dart <host> <username> '
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

  NetworkConfiguration? original;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check(
      'network.configuration.config parses into the app model',
      () async {
        final raw = await session.call('network.configuration.config');
        final config = NetworkConfiguration.fromJson(
          raw as Map<String, dynamic>,
        );
        original = config;
        print(
          '      (hostname ${config.hostname}, domain "${config.domain}", '
          'configured gateway "${config.ipv4Gateway}")',
        );
        print(
          '      (in effect: gateway "${config.effective.ipv4Gateway}", '
          'nameservers ${config.effective.nameservers})',
        );
        if (config.hostname.isEmpty) {
          throw StateError('no hostname was reported');
        }
        // The whole point of reading `state`: a server can have an empty
        // configured gateway and still be routing, and the UI must not call that
        // "not set".
        if (config.isDhcpDerived) {
          print(
            '      (DHCP-derived, so configured fields are blank by design)',
          );
          if (config.effective.ipv4Gateway.isEmpty &&
              config.effective.nameservers.isEmpty) {
            throw StateError('reported DHCP-derived with no effective values');
          }
        }
      },
    );

    await check('network.general.summary parses into the app model', () async {
      final raw = await session.call('network.general.summary');
      final summary = NetworkSummary.fromJson(raw as Map<String, dynamic>);
      print(
        '      (${summary.interfaces.length} interfaces, routes '
        '${summary.defaultRoutes}, nameservers ${summary.nameservers})',
      );
      if (summary.interfaces.isEmpty) {
        throw StateError('no interface addresses were reported');
      }
    });

    await check('an unchanged edit sends nothing', () async {
      final baseline = original!;
      final edit = NetworkConfigurationEdit.diff(
        baseline: baseline,
        hostname: baseline.hostname,
        domain: baseline.domain,
        ipv4Gateway: baseline.ipv4Gateway,
        nameserver1: baseline.nameserver1,
        nameserver2: baseline.nameserver2,
        nameserver3: baseline.nameserver3,
        httpProxy: baseline.httpProxy,
      );
      if (!edit.isEmpty) {
        throw StateError('diff produced ${edit.toApiJson()}');
      }
    });

    await check(
      'network.configuration.update accepts a partial payload',
      () async {
        // Only httpproxy is touched: it has no effect on routing, so a failure
        // here cannot strand the probe. Clearing a gateway would.
        const probeProxy = 'http://truedock-probe.invalid:3128';
        final edit = NetworkConfigurationEdit.diff(
          baseline: original!,
          hostname: original!.hostname,
          domain: original!.domain,
          ipv4Gateway: original!.ipv4Gateway,
          nameserver1: original!.nameserver1,
          nameserver2: original!.nameserver2,
          nameserver3: original!.nameserver3,
          httpProxy: probeProxy,
        );
        final payload = edit.toApiJson();
        // Dart Sets compare by identity, so an equality check always fails.
        if (payload.length != 1 || !payload.containsKey('httpproxy')) {
          throw StateError('the diff sent $payload, expected only httpproxy');
        }
        await session.call('network.configuration.update', params: [payload]);
        final after = NetworkConfiguration.fromJson(
          await session.call('network.configuration.config')
              as Map<String, dynamic>,
        );
        if (after.httpProxy != probeProxy) {
          throw StateError(
            'proxy is "${after.httpProxy}", not the probe value',
          );
        }
        // A partial update must not have disturbed anything else.
        if (after.hostname != original!.hostname ||
            after.ipv4Gateway != original!.ipv4Gateway ||
            after.nameserver1 != original!.nameserver1) {
          throw StateError('a partial update changed unrelated fields');
        }
        print('      (applied, and hostname/gateway/nameserver preserved)');
      },
    );

    await check('clearing a routing value is detected as severing', () async {
      // Asserted rather than performed: this is the case the UI escalates to a
      // typed confirmation, and running it would drop the connection.
      final baseline = original!;
      if (baseline.effective.ipv4Gateway.isEmpty) {
        print('      (no effective gateway on this server; nothing to assert)');
        return;
      }
      final withStatic = NetworkConfiguration(
        hostname: baseline.hostname,
        domain: baseline.domain,
        ipv4Gateway: baseline.effective.ipv4Gateway,
        effective: baseline.effective,
      );
      final edit = NetworkConfigurationEdit.diff(
        baseline: withStatic,
        hostname: baseline.hostname,
        domain: baseline.domain,
        ipv4Gateway: '',
        nameserver1: '',
        nameserver2: '',
        nameserver3: '',
        httpProxy: baseline.httpProxy,
      );
      if (!edit.clearsEffectiveRouting(withStatic)) {
        throw StateError('clearing the gateway in use was not flagged');
      }
      print('      (flagged, so the UI requires a typed confirmation)');
    });
  } finally {
    final baseline = original;
    if (baseline != null) {
      await check('the original proxy setting is restored', () async {
        await session.call(
          'network.configuration.update',
          params: [
            {'httpproxy': baseline.httpProxy},
          ],
        );
        final after = NetworkConfiguration.fromJson(
          await session.call('network.configuration.config')
              as Map<String, dynamic>,
        );
        if (after.httpProxy != baseline.httpProxy) {
          throw StateError('proxy is "${after.httpProxy}" after restore');
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
