// Live verification of the active-session surface (`auth.sessions`,
// `auth.terminate_session`, `auth.terminate_other_sessions`).
//
// Sessions are the one credential surface where reading is not enough to know
// the model is right: the account lives inside `credentials_data`, the server
// mixes its own internal UNIX-socket connections into the same list, and
// terminating has to hit exactly one connection without disturbing the caller's.
// This opens a second real session, ends it from the first, and proves both
// halves of that.
//
// Usage:
//   dart run tool/live_session_probe.dart <host> <username> <password>
//
// MUTATING, but only of sessions it creates itself.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/system_resources.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_session_probe.dart <host> <user> <password>',
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
        '${detail.length > 300 ? '${detail.substring(0, 300)}...' : detail}',
      );
    }
  }

  _Rpc? second;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('auth.sessions parses into the app model', () async {
      final rows = await session.call('auth.sessions') as List;
      final parsed = rows
          .whereType<Map<String, dynamic>>()
          .map(NasSession.fromJson)
          .toList();
      if (parsed.isEmpty) throw StateError('no sessions returned');

      final current = parsed.where((s) => s.current).toList();
      if (current.length != 1) {
        throw StateError(
          'expected exactly one current session, '
          'got ${current.length}',
        );
      }
      // The account is nested inside `credentials_data`; reading the top level
      // would silently produce an unlabelled session.
      if (current.single.username != args[1]) {
        throw StateError(
          'current session username is '
          '${current.single.username}, expected ${args[1]}',
        );
      }
      final internal = parsed.where((s) => !s.isUserSession).length;
      print(
        '      (${parsed.length} session(s): '
        '${parsed.length - internal} user, $internal internal)',
      );
    });

    await check(
      'the server reports internal connections we must not list',
      () async {
        final rows = await session.call('auth.sessions') as List;
        final parsed = rows
            .whereType<Map<String, dynamic>>()
            .map(NasSession.fromJson)
            .toList();
        final internal = parsed.where((s) => !s.isUserSession).toList();
        if (internal.isEmpty) {
          throw StateError(
            'expected middleware UNIX-socket sessions; the filter would be '
            'untested if the server stopped reporting them',
          );
        }
        // These are the middleware talking to itself. Listing them as root
        // logins would be alarming and wrong.
        for (final entry in internal) {
          if (!entry.origin.toUpperCase().contains('UNIX')) {
            throw StateError('unexpected internal origin: ${entry.origin}');
          }
        }
      },
    );

    await check('a second login appears as a separate session', () async {
      second = _Rpc(args[0]);
      await second!.open();
      await second!.login(args[1], args[2]);

      final rows = await session.call('auth.sessions') as List;
      final users = rows
          .whereType<Map<String, dynamic>>()
          .map(NasSession.fromJson)
          .where((s) => s.isUserSession)
          .toList();
      if (users.length < 2) {
        throw StateError(
          'expected at least 2 user sessions, '
          'got ${users.length}',
        );
      }
      final others = users.where((s) => !s.current).toList();
      if (others.isEmpty) throw StateError('no non-current session found');
      print('      (${users.length} user session(s) now)');
    });

    await check(
      'terminating ends that session and not the caller\'s',
      () async {
        final rows = await session.call('auth.sessions') as List;
        final users = rows
            .whereType<Map<String, dynamic>>()
            .map(NasSession.fromJson)
            .where((s) => s.isUserSession)
            .toList();
        final victim = users.firstWhere((s) => !s.current);

        await session.call('auth.terminate_session', params: [victim.id]);

        // The caller must still work. A terminate that killed the wrong session
        // would surface here rather than as a mysterious disconnect later.
        final after = await session.call('auth.sessions') as List;
        final remaining = after
            .whereType<Map<String, dynamic>>()
            .map(NasSession.fromJson)
            .where((s) => s.isUserSession)
            .toList();
        if (remaining.any((s) => s.id == victim.id)) {
          throw StateError('the session was still listed after terminating');
        }
        if (!remaining.any((s) => s.current)) {
          throw StateError('the calling session disappeared');
        }
        print('      (ended ${victim.origin}, caller intact)');
      },
    );

    await check(
      'terminate_other_sessions leaves the caller signed in',
      () async {
        // Open one more so the call has something to do.
        final extra = _Rpc(args[0]);
        await extra.open();
        await extra.login(args[1], args[2]);

        await session.call('auth.terminate_other_sessions');

        final after = await session.call('auth.sessions') as List;
        final users = after
            .whereType<Map<String, dynamic>>()
            .map(NasSession.fromJson)
            .where((s) => s.isUserSession)
            .toList();
        if (!users.any((s) => s.current)) {
          throw StateError('the calling session was terminated too');
        }
        if (users.where((s) => !s.current).isNotEmpty) {
          throw StateError(
            'other sessions survived: '
            '${users.where((s) => !s.current).length}',
          );
        }
        try {
          await extra.close();
        } catch (_) {}
        print('      (only the caller remains)');
      },
    );
  } finally {
    try {
      await second?.close();
    } catch (_) {}
    await session.close();
  }

  final failed = results.where((r) => !r.$2).length;
  print('\nResult: ${results.length - failed}/${results.length} passed');
  exit(failed == 0 ? 0 : 1);
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
            reason ??= error['message'];
          }
          var text = '${reason ?? jsonEncode(error)}';
          if (text.length > 400) text = '${text.substring(0, 400)}...';
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
      await call('auth.logout');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
  }
}
