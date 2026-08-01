// Live verification of the per-service configuration surfaces.
//
// Covers `ssh`, `smb`, `nfs`, `ftp`, and `snmp`: each exposes a
// `<service>.config` / `<service>.update` pair that TrueDock now edits. For each
// one the probe reads the config, applies a single reversible change through the
// app's own domain types, confirms it landed without disturbing anything else,
// and restores the original value.
//
// Usage:
//   dart run tool/live_service_config_probe.dart <host> <username> <password>
//
// MUTATING BUT SELF-REVERTING. Nothing it changes affects the TrueDock session:
// it never touches SSH's port (which could lock out administration) and never
// writes a shared secret.
//
// Credentials come from argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/service_configuration.dart';

/// One reversible probe per service: a field, and a value that differs from
/// whatever the server currently has.
const _probes = <ConfigurableService, String>{
  // Deliberately not `tcpport`: changing the SSH port on a server an
  // administrator may be relying on is not a probe's to risk.
  ConfigurableService.ssh: 'compression',
  ConfigurableService.smb: 'description',
  ConfigurableService.nfs: 'allow_nonroot',
  ConfigurableService.ftp: 'banner',
  ConfigurableService.snmp: 'location',
};

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_service_config_probe.dart <host> <username> '
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

    for (final entry in _probes.entries) {
      final service = entry.key;
      final field = entry.value;
      final namespace = service.namespace;

      Map<String, dynamic>? original;

      await check('$namespace.config parses into the app model', () async {
        final raw =
            await session.call(service.configMethod) as Map<String, dynamic>;
        original = raw;
        final config = ServiceConfiguration(service: service, values: raw);
        // Every field TrueDock offers must exist in the response, or the editor
        // would render a control for something the server does not have.
        final missing = [
          for (final f in config.fields)
            if (!raw.containsKey(f.key)) f.key,
        ];
        if (missing.isNotEmpty) {
          throw StateError('fields absent from the response: $missing');
        }
        print('      (${config.fields.length} editable fields all present)');
      });

      await check('$namespace.update accepts a partial payload', () async {
        final raw = original!;
        final config = ServiceConfiguration(service: service, values: raw);
        final descriptor = config.fields.firstWhere((f) => f.key == field);

        final Object? probeValue;
        switch (descriptor.kind) {
          case ServiceFieldKind.toggle:
            probeValue = !config.flag(field);
          case ServiceFieldKind.text:
            probeValue = 'truedock-probe';
          case ServiceFieldKind.integer:
          case ServiceFieldKind.choice:
            throw StateError('$field is not a safe probe target');
        }

        final edit = ServiceConfigurationEdit(
          service: service,
          changes: {field: probeValue},
        );
        if (edit.validate().isNotEmpty) {
          throw StateError('the probe edit failed local validation');
        }
        if (edit.carriesSecret) {
          throw StateError('refusing to write a shared secret');
        }

        await session.call(service.updateMethod, params: [edit.toApiJson()]);
        final after =
            await session.call(service.configMethod) as Map<String, dynamic>;
        if (after[field] != probeValue) {
          throw StateError('$field is ${after[field]}, expected $probeValue');
        }
        // A partial update must not have rewritten anything else. Compare every
        // field TrueDock exposes apart from the one just changed.
        for (final other in config.fields) {
          if (other.key == field) continue;
          if (jsonEncode(after[other.key]) != jsonEncode(raw[other.key])) {
            throw StateError(
              '${other.key} changed from ${raw[other.key]} to '
              '${after[other.key]}',
            );
          }
        }
        print('      ($field applied; every other field preserved)');
      });

      await check('$namespace original value restored', () async {
        final raw = original!;
        await session.call(
          service.updateMethod,
          params: [
            {field: raw[field]},
          ],
        );
        final after =
            await session.call(service.configMethod) as Map<String, dynamic>;
        if (jsonEncode(after[field]) != jsonEncode(raw[field])) {
          throw StateError('$field is ${after[field]} after restore');
        }
      });
    }
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
          // Surface the middleware's own reason when there is one; the full
          // error object is a multi-thousand-line Python traceback.
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
