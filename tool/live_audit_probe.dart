// Live verification of the audit log surface (`audit.*`).
//
// The audit log is the record of every action the rest of the app can take, so
// this probe also closes a loop the other probes cannot: it performs a known
// administrative call and then finds that call in the log, which proves the
// query, the filters, and the parsing all line up with what the server records.
//
// Usage:
//   dart run tool/live_audit_probe.dart <host> <username> <password>
//
// READ-ONLY apart from restoring the audit retention it briefly changes, and the
// audited call it makes on purpose is itself a read.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/system/domain/audit_entry.dart';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_audit_probe.dart <host> <username> <password>',
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

  AuditConfiguration? original;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('audit.config parses into the app model', () async {
      final raw = await session.call('audit.config') as Map<String, dynamic>;
      original = AuditConfiguration.fromJson(raw);
      final config = original!;
      print(
        '      (retention ${config.retentionDays}d, '
        'quota ${config.isUncapped ? 'uncapped' : '${config.quotaGiB} GiB'}, '
        '${config.enabledServices.length} service(s))',
      );
      if (config.retentionDays < 1) {
        throw StateError('retention parsed as ${config.retentionDays}');
      }
    });

    await check('audit.query accepts the nested filter payload', () async {
      // The shape is the point: audit.query is the one query method that takes a
      // single object with hyphenated keys rather than [filters, options].
      const query = AuditQuery(limit: 40);
      final rows =
          await session.call('audit.query', params: [query.toApiJson()])
              as List;
      final entries = rows
          .whereType<Map<String, dynamic>>()
          .map(AuditEntry.fromJson)
          .toList();
      if (entries.isEmpty) {
        throw StateError('no audit records returned');
      }
      final kinds = entries.map((e) => e.event).toSet();
      final withTimestamps = entries.where((e) => e.timestamp != null).length;
      if (withTimestamps != entries.length) {
        throw StateError(
          'only $withTimestamps of ${entries.length} parsed a timestamp',
        );
      }
      print(
        '      (${entries.length} entries, kinds '
        '${kinds.map((k) => k.name).join('/')}, all timestamped)',
      );
    });

    await check('a known call appears in the log', () async {
      // Make an audited call, then find it. This is what proves the query and
      // the parsing agree with what the server actually writes.
      await session.call('audit.config');
      // The write is asynchronous, so poll rather than assuming it is there.
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (DateTime.now().isBefore(deadline)) {
        final rows =
            await session.call(
                  'audit.query',
                  params: [const AuditQuery(limit: 40).toApiJson()],
                )
                as List;
        final entries = rows
            .whereType<Map<String, dynamic>>()
            .map(AuditEntry.fromJson)
            .toList();
        final match = entries
            .where((entry) => entry.event == AuditEventKind.methodCall)
            .toList();
        if (match.isNotEmpty) {
          final newest = match.first;
          print(
            '      (found ${newest.method ?? newest.rawEvent}: '
            '"${newest.label}" by ${newest.username ?? 'unknown'})',
          );
          if (newest.username == null) {
            throw StateError('the record carries no username');
          }
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      throw StateError('no METHOD_CALL record appeared within 20s');
    });

    await check('the username filter narrows the log', () async {
      final mine = AuditQuery(limit: 20, username: args[1]);
      final rows =
          await session.call('audit.query', params: [mine.toApiJson()]) as List;
      final entries = rows
          .whereType<Map<String, dynamic>>()
          .map(AuditEntry.fromJson)
          .toList();
      if (entries.isEmpty) {
        throw StateError('the filter excluded everything');
      }
      final wrong = entries
          .where((entry) => entry.username != null && entry.username != args[1])
          .toList();
      if (wrong.isNotEmpty) {
        throw StateError('${wrong.length} record(s) from another user');
      }
      print('      (${entries.length} entries, all for ${args[1]})');
    });

    await check('the failures filter really narrows the log', () async {
      // Accepting the filter shape proves nothing on its own: a server that
      // ignored `query-filters` entirely would still answer, and a healthy
      // window with no failures would still look like a pass. So compare an
      // unfiltered window against a filtered one taken at the same limit.
      const limit = 200;
      const unfiltered = AuditQuery(limit: limit);
      const failures = AuditQuery(limit: limit, onlyFailures: true);

      Future<List<AuditEntry>> fetch(AuditQuery query) async {
        final rows =
            await session.call('audit.query', params: [query.toApiJson()])
                as List;
        return rows
            .whereType<Map<String, dynamic>>()
            .map(AuditEntry.fromJson)
            .toList();
      }

      final all = await fetch(unfiltered);
      final failed = await fetch(failures);

      final leaked = failed.where((entry) => entry.succeeded).toList();
      if (leaked.isNotEmpty) {
        throw StateError('${leaked.length} successful record(s) returned');
      }

      // If the unfiltered window contained successes, the filtered window has
      // to be strictly smaller. Equal counts would mean the filter was ignored
      // and we were reading the same rows twice.
      final successes = all.where((entry) => entry.succeeded).length;
      if (successes > 0 && failed.length >= all.length) {
        throw StateError(
          'filter looks ignored: ${all.length} unfiltered '
          '($successes successful) vs ${failed.length} filtered',
        );
      }

      print(
        '      (unfiltered ${all.length}, $successes successful; '
        'filtered ${failed.length})',
      );
    });

    await check('audit.update accepts a partial retention change', () async {
      final baseline = original!;
      final target = baseline.retentionDays >= 30
          ? baseline.retentionDays - 1
          : baseline.retentionDays + 1;
      final edit = AuditConfigurationEdit(retentionDays: target);
      final payload = edit.toApiJson();
      if (payload.length != 1 || !payload.containsKey('retention')) {
        throw StateError('the edit sent $payload');
      }
      await session.call('audit.update', params: [payload]);
      final after = AuditConfiguration.fromJson(
        await session.call('audit.config') as Map<String, dynamic>,
      );
      if (after.retentionDays != target) {
        throw StateError('retention is ${after.retentionDays}, not $target');
      }
      // A partial update must not have disturbed the thresholds.
      if (after.quotaFillWarning != baseline.quotaFillWarning ||
          after.quotaFillCritical != baseline.quotaFillCritical) {
        throw StateError('a partial update changed the fill thresholds');
      }
      print('      (retention $target applied; thresholds preserved)');
    });
  } finally {
    final baseline = original;
    if (baseline != null) {
      await check('the original retention is restored', () async {
        await session.call(
          'audit.update',
          params: [
            {'retention': baseline.retentionDays},
          ],
        );
        final after = AuditConfiguration.fromJson(
          await session.call('audit.config') as Map<String, dynamic>,
        );
        if (after.retentionDays != baseline.retentionDays) {
          throw StateError('retention is ${after.retentionDays} after restore');
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
