// Live verification of the privilege surface (`privilege.*`).
//
// Creates a scoped privilege, edits it, and deletes it. It never touches the
// three built-in privileges: narrowing one is how an administrator removes their
// own access, and a probe has no business risking that.
//
// Usage:
//   dart run tool/live_privilege_probe.dart <host> <username> <password>
//
// The privilege it creates grants a single read-only role and no groups, so it
// cannot widen anyone's access even if the cleanup below fails.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/privilege_configuration.dart';

const _name = 'truedock-probe';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_privilege_probe.dart <host> <username> '
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

  int? id;
  List<PrivilegeRole> roles = const [];

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('previous probe privileges are cleared', () async {
      final rows = await session.call('privilege.query') as List;
      var removed = 0;
      for (final row in rows.cast<Map>()) {
        if ('${row['name']}' == _name) {
          await session.call('privilege.delete', params: [row['id']]);
          removed++;
        }
      }
      if (removed > 0) print('      (cleared $removed leftover)');
    });

    await check('privilege.roles yields a composing catalog', () async {
      final rows = await session.call('privilege.roles') as List;
      roles = rows
          .whereType<Map<String, dynamic>>()
          .map(PrivilegeRole.fromJson)
          .toList();
      if (roles.length < 50) {
        throw StateError('only ${roles.length} roles advertised');
      }
      // The whole reason the catalog is read: roles imply other roles, so the
      // effective grant is wider than the list on a privilege.
      final composing = roles.where((role) => role.includes.isNotEmpty).length;
      if (composing == 0) {
        throw StateError('no role declares includes');
      }
      print('      (${roles.length} roles, $composing of them composing)');
    });

    await check('privilege.query parses built-ins into the app model', () async {
      final rows = await session.call('privilege.query') as List;
      final privileges = rows
          .whereType<Map<String, dynamic>>()
          .map(Privilege.fromJson)
          .toList();
      final builtins = privileges.where((p) => p.isBuiltin).toList();
      if (builtins.isEmpty) {
        throw StateError('no built-in privilege was recognised');
      }
      for (final privilege in builtins) {
        // local_groups is expanded on read; both the ids to send and the names
        // to display have to survive.
        if (privilege.localGroupIds.length !=
            privilege.localGroupNames.length) {
          throw StateError(
            'group ids and names disagree for ${privilege.name}',
          );
        }
      }
      final admin = privileges.firstWhere(
        (p) => p.grantsFullAdmin,
        orElse: () => builtins.first,
      );
      final effective = admin.effectiveRoles(roles);
      print(
        '      (${privileges.length} privileges, ${builtins.length} built-in; '
        '${admin.name} grants ${effective.length} effective role(s))',
      );
    });

    await check('privilege.create accepts the app payload', () async {
      // A single read-only role and no groups: harmless even if cleanup fails.
      final readOnly = roles.firstWhere(
        (role) => role.name.endsWith('_READ'),
        orElse: () => roles.first,
      );
      final configuration = PrivilegeConfiguration(
        name: _name,
        roles: [readOnly.name],
      );
      if (configuration.grantsUnrestrictedAccess) {
        throw StateError('refusing to create an unrestricted privilege');
      }
      final result = await session.call(
        'privilege.create',
        params: [configuration.toApiJson()],
      );
      id = (result as Map)['id'] as int?;
      if (id == null) throw StateError('no id was returned');
      print('      (created privilege $id granting ${readOnly.name})');
    });

    await check('the round trip preserves the grant', () async {
      final rows =
          await session.call(
                'privilege.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      if (rows.isEmpty) throw StateError('not listed');
      final privilege = Privilege.fromJson(rows.first as Map<String, dynamic>);
      if (privilege.isBuiltin) {
        throw StateError('a created privilege was reported as built-in');
      }
      if (privilege.roles.length != 1) {
        throw StateError('roles came back as ${privilege.roles}');
      }
      if (privilege.webShell) {
        throw StateError('web_shell was enabled unexpectedly');
      }
    });

    await check('privilege.update applies a change', () async {
      final rows =
          await session.call(
                'privilege.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      final current = Privilege.fromJson(rows.first as Map<String, dynamic>);
      final extra = roles.firstWhere(
        (role) =>
            role.name.endsWith('_READ') && role.name != current.roles.first,
        orElse: () => roles.last,
      );
      final configuration = PrivilegeConfiguration(
        name: _name,
        roles: [...current.roles, extra.name],
      );
      await session.call(
        'privilege.update',
        params: [id, configuration.toApiJson()],
      );
      final after =
          await session.call(
                'privilege.query',
                params: [
                  [
                    ['id', '=', id],
                  ],
                ],
              )
              as List;
      final updated = Privilege.fromJson(after.first as Map<String, dynamic>);
      if (updated.roles.length != 2) {
        throw StateError('roles are ${updated.roles} after the update');
      }
      print('      (now grants ${updated.roles.join(', ')})');
    });
  } finally {
    if (id != null) {
      await check('privilege.delete removes it', () async {
        await session.call('privilege.delete', params: [id]);
        final rows =
            await session.call(
                  'privilege.query',
                  params: [
                    [
                      ['id', '=', id],
                    ],
                  ],
                )
                as List;
        if (rows.isNotEmpty) throw StateError('still listed');
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
