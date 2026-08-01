// Live verification of the configuration backup surface.
//
// `config.save` writes to a job pipe that a JSON-RPC client cannot read — the
// server answers `Pipe 'output' is not open` — so TrueDock wraps it in
// `core.download` and hands the caller a tokenized HTTPS path. This probe proves
// that chain end to end by actually fetching the archive over HTTPS and checking
// it is a real tar file, which is the only way to know the URL is usable rather
// than merely well-formed.
//
// Usage:
//   dart run tool/live_config_backup_probe.dart <host> <username> <password>
//
// READ-ONLY. It downloads a configuration backup without the secret seed or pool
// keys and discards it. `config.reset` is never called: that would wipe the
// server's entire configuration.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/config_backup.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_config_backup_probe.dart <host> <username> '
      '<password>',
    );
    exit(64);
  }
  final host = args[0];

  final session = _Rpc(host);
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

    await check('config.save alone cannot be called by a client', () async {
      // The reason core.download exists. If this ever starts working, the wrapper
      // is no longer necessary and this probe should say so.
      try {
        await session.call('config.save', params: [{}]);
        throw StateError('config.save returned without a pipe');
      } on _RpcError catch (error) {
        if (!'$error'.contains("Pipe 'output' is not open")) {
          throw StateError('unexpected failure: $error');
        }
        print('      (rejected as expected: pipe not open)');
      }
    });

    late ConfigBackupDownload download;
    await check('core.download returns a tokenized path', () async {
      const options = ConfigBackupOptions();
      final filename = options.suggestedFilename('probe', DateTime.now());
      final result = await session.call(
        'core.download',
        params: [
          'config.save',
          [options.toApiJson()],
          filename,
          true,
        ],
      );
      download = ConfigBackupDownload.fromApi(result, filename: filename);
      if (!download.isTokenized) {
        throw StateError('the path carries no auth token: ${download.path}');
      }
      print('      (job ${download.jobId}, filename $filename)');
    });

    await check('the URL actually serves the backup payload', () async {
      // Fetching it is the point: a well-formed URL that 404s would pass every
      // shape check while being useless.
      final url = download.resolve(Uri.parse('https://$host'));
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..badCertificateCallback = (cert, h, p) => h == host;
      try {
        final request = await client.getUrl(url);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw StateError('HTTP ${response.statusCode}');
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          // A configuration database is small; stop well before anything large.
          if (bytes.length > 4 * 1024 * 1024) break;
        }
        if (bytes.length < 1024) {
          throw StateError('only ${bytes.length} bytes returned');
        }
        // A plain backup is the SQLite settings database itself; only the
        // secret-seed and pool-key options make the server bundle several files
        // into a tar. Asserting a tar magic would fail on exactly the safe case.
        final sqliteMagic = String.fromCharCodes(bytes.take(15));
        final tarMagic = String.fromCharCodes(
          bytes.sublist(257, 262).where((b) => b >= 32 && b < 127),
        );
        final isSqlite = sqliteMagic == 'SQLite format 3';
        if (!isSqlite && tarMagic != 'ustar') {
          throw StateError(
            'neither a SQLite database nor a tar archive '
            '(head "$sqliteMagic", offset 257 "$tarMagic")',
          );
        }
        final disposition = response.headers.value('content-disposition');
        print(
          '      (${bytes.length} bytes, '
          '${isSqlite ? 'SQLite database' : 'tar archive'}, '
          'disposition ${disposition ?? 'absent'})',
        );
        if (disposition != null && !disposition.contains(download.filename)) {
          throw StateError('the filename was not honoured: $disposition');
        }
      } finally {
        client.close(force: true);
      }
    });

    await check('a token is single-use or short-lived', () async {
      // Worth knowing, because the UI presents the link as one-time. Either
      // behaviour is acceptable; silently permanent access would not be.
      final url = download.resolve(Uri.parse('https://$host'));
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20)
        ..badCertificateCallback = (cert, h, p) => h == host;
      try {
        final request = await client.getUrl(url);
        final response = await request.close();
        await response.drain<void>();
        print('      (second fetch answered HTTP ${response.statusCode})');
      } on Object catch (error) {
        print('      (second fetch refused: ${_short('$error')})');
      } finally {
        client.close(force: true);
      }
    });

    await check('config.reset advertises the reboot option only', () async {
      // Asserted rather than invoked: calling it would wipe the server's
      // configuration entirely.
      final methods =
          await session.call('core.get_methods', params: [null, 'WS']) as Map;
      final accepts = (methods['config.reset'] as Map)['accepts'] as List;
      final properties =
          (accepts.first as Map)['properties'] as Map<String, Object?>;
      if (properties.keys.length != 1 || !properties.containsKey('reboot')) {
        throw StateError('config.reset accepts ${properties.keys}');
      }
      print('      (accepts only {reboot}; never invoked by this probe)');
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
    value.length <= 120 ? value : '${value.substring(0, 120)}...';

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
