// Dumps the live server's advertised method schemas to a JSON file so the
// static audit (tool/schema_audit.py) can compare them against the method
// names and payload keys TrueDock actually sends.
//
// Usage:
//   dart run tool/schema_dump.dart <host> <username> <password> [outPath]
//
// Read-only: it calls core.get_methods and nothing else. Credentials come
// from argv and are never persisted.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/schema_dump.dart <host> <username> <password> '
      '[outPath]',
    );
    exit(64);
  }
  final host = args[0];
  final out = args.length > 3 ? args[3] : '/tmp/td_all_methods.json';
  var nextId = 1;
  final pending = <int, Completer<Object?>>{};
  final httpClient = HttpClient()
    ..badCertificateCallback = (cert, h, p) => h == host;
  final channel = IOWebSocketChannel.connect(
    'wss://$host/api/current',
    customClient: httpClient,
  );
  channel.stream.listen((message) {
    final decoded = jsonDecode(message.toString());
    if (decoded is Map && decoded['id'] is int) {
      final completer = pending.remove(decoded['id'] as int);
      if (completer != null && !completer.isCompleted) {
        if (decoded['error'] != null) {
          completer.completeError(StateError(jsonEncode(decoded['error'])));
        } else {
          completer.complete(decoded['result']);
        }
      }
    }
  });
  Future<Object?> call(String method, [List<Object?> params = const []]) {
    final id = nextId++;
    final completer = Completer<Object?>();
    pending[id] = completer;
    channel.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future.timeout(const Duration(seconds: 120));
  }

  await Future<void>.delayed(const Duration(milliseconds: 400));
  await call('auth.login_ex', [
    {
      'mechanism': 'PASSWORD_PLAIN',
      'username': args[1],
      'password': args[2],
    },
  ]);
  final version = await call('system.version');
  final methods = await call('core.get_methods', [null, 'WS']) as Map;
  File(out).writeAsStringSync(
    jsonEncode({'version': version, 'methods': methods}),
  );
  print('wrote $out: ${methods.length} methods from $version');
  await channel.sink.close();
  exit(0);
}
