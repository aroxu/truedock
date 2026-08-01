// Live verification of the alert class policy surface.
//
// `alertclasses.config` returns only the classes an administrator overrode, so
// it answers with an empty map on a stock server. The catalog of classes comes
// from `alert.list_categories`. This probe verifies the merge, applies an
// override, and restores the original map.
//
// Usage:
//   dart run tool/live_alert_class_probe.dart <host> <username> <password>
//
// MUTATING BUT SELF-REVERTING. It overrides one low-severity informational
// class and restores the server's original override map afterwards.
//
// Credentials come from argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/alert_class_configuration.dart';
import 'package:true_dock/features/system/domain/alert_service_configuration.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_alert_class_probe.dart <host> <username> '
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

  Map<String, Object?>? originalOverrides;
  AlertClassConfiguration? merged;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('alert.list_categories yields the class catalog', () async {
      final categories = await session.call('alert.list_categories') as List;
      final definitions = AlertClassConfiguration.parseCategories(categories);
      if (definitions.length < 20) {
        throw StateError('only ${definitions.length} classes parsed');
      }
      final categoryCount = definitions.map((d) => d.category).toSet().length;
      print(
        '      (${definitions.length} classes across $categoryCount categories)',
      );
    });

    await check('alertclasses.config returns only overrides', () async {
      final config = await session.call('alertclasses.config') as Map;
      final classes = config['classes'];
      originalOverrides = classes is Map
          ? {for (final e in classes.entries) '${e.key}': e.value}
          : <String, Object?>{};
      print('      (${originalOverrides!.length} override(s) stored)');
    });

    await check('the merge reports effective policies', () async {
      final categories = await session.call('alert.list_categories') as List;
      merged = AlertClassConfiguration.merge(
        definitions: AlertClassConfiguration.parseCategories(categories),
        overrides: originalOverrides!,
      );
      final config = merged!;
      if (config.policies.isEmpty) throw StateError('merged to nothing');
      // Every class must have an effective policy, even with no override: the
      // whole point of merging rather than listing the override map.
      if (config.policies.length < 20) {
        throw StateError('merged only ${config.policies.length}');
      }
      print(
        '      (${config.policies.length} effective policies, '
        '${config.overriddenCount} differing from default, '
        '${config.silenced.length} silenced)',
      );
    });

    late String probeClass;
    await check('alertclasses.update stores an override', () async {
      // Pick an informational class so silencing it cannot hide anything that
      // matters, even if the restore below fails.
      final candidate = merged!.policies.firstWhere(
        (policy) =>
            policy.definition.level == AlertLevel.info &&
            !policy.differsFromDefault,
        orElse: () => merged!.policies.first,
      );
      probeClass = candidate.id;
      final edited = AlertClassConfiguration(
        policies: [
          for (final policy in merged!.policies)
            if (policy.id == probeClass)
              policy.copyWith(policy: AlertPolicy.daily)
            else
              policy,
        ],
      );
      final payload = AlertClassEdit.fromConfiguration(edited).toApiJson();
      final classes = payload['classes'] as Map<String, Object?>;
      if (!classes.containsKey(probeClass)) {
        throw StateError('the probe class was not in the payload');
      }
      print('      (overriding $probeClass to DAILY)');
      await session.call('alertclasses.update', params: [payload]);

      final after = await session.call('alertclasses.config') as Map;
      final stored = after['classes'] as Map;
      final entry = stored[probeClass];
      if (entry is! Map || entry['policy'] != 'DAILY') {
        throw StateError('stored as $entry');
      }
    });

    await check('an unchanged class is not stored as an override', () async {
      // The payload carries only classes that differ from their default, so a
      // stock class must not end up pinned in the override map forever.
      final after = await session.call('alertclasses.config') as Map;
      final stored = after['classes'] as Map;
      final unexpected = stored.keys
          .map((key) => '$key')
          .where(
            (key) => key != probeClass && !originalOverrides!.containsKey(key),
          )
          .toList();
      if (unexpected.isNotEmpty) {
        throw StateError('unexpected overrides stored: $unexpected');
      }
      print('      (${stored.length} override(s), none spurious)');
    });
  } finally {
    if (originalOverrides != null) {
      await check('the original override map is restored', () async {
        await session.call(
          'alertclasses.update',
          params: [
            {'classes': originalOverrides},
          ],
        );
        final after = await session.call('alertclasses.config') as Map;
        final stored = after['classes'] as Map;
        if (stored.length != originalOverrides!.length) {
          throw StateError(
            '${stored.length} override(s) after restore, expected '
            '${originalOverrides!.length}',
          );
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
