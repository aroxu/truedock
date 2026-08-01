// Live verification of the scheduled-command surface (`cronjob.*`).
//
// Creates a harmless probe job, edits it, runs it, and deletes it. The command
// is `/usr/bin/true`, so running it cannot affect the server.
//
// Usage:
//   dart run tool/live_cron_probe.dart <host> <username> <password>
//
// Payloads are built from the app's own domain types. Credentials come from
// argv and are never persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:true_dock/features/data_protection/domain/task_schedule.dart';
import 'package:true_dock/features/system/domain/cron_job_configuration.dart';

const _description = 'truedock probe';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_cron_probe.dart <host> <username> <password>',
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

  int? jobId;

  try {
    await check('connect and authenticate', () async {
      await session.open();
      await session.login(args[1], args[2]);
    });

    await check('previous probe jobs are cleared', () async {
      final rows = await session.call('cronjob.query') as List;
      var removed = 0;
      for (final row in rows.cast<Map>()) {
        if ('${row['description']}' == _description) {
          await session.call('cronjob.delete', params: [row['id']]);
          removed++;
        }
      }
      if (removed > 0) print('      (cleared $removed leftover job(s))');
    });

    await check('cronjob.create accepts the app payload', () async {
      const configuration = CronJobConfiguration(
        command: '/usr/bin/true',
        user: 'root',
        description: _description,
        schedule: TaskSchedule(minute: '30', hour: '3'),
        captureStdout: true,
        captureStderr: true,
      );
      final result = await session.call(
        'cronjob.create',
        params: [configuration.toApiJson()],
      );
      jobId = (result as Map)['id'] as int?;
      if (jobId == null) throw StateError('no id was returned');
      print('      (created job $jobId)');
    });

    await check('the round trip preserves every field', () async {
      final rows =
          await session.call(
                'cronjob.query',
                params: [
                  [
                    ['id', '=', jobId],
                  ],
                ],
              )
              as List;
      if (rows.isEmpty) throw StateError('the job is not listed');
      final job = CronJob.fromJson(rows.first as Map<String, dynamic>);
      if (job.command != '/usr/bin/true') {
        throw StateError('command is ${job.command}');
      }
      if (job.schedule.minute != '30' || job.schedule.hour != '3') {
        throw StateError('schedule is ${job.schedule.cronExpression}');
      }
      // The inversion is the part worth proving: the app stores "capture" while
      // the API states suppression, so a naive passthrough would flip these.
      if (!job.configuration.captureStdout ||
          !job.configuration.captureStderr) {
        throw StateError(
          'output flags came back as stdout='
          '${job.configuration.captureStdout} '
          'stderr=${job.configuration.captureStderr}',
        );
      }
      print('      (command, schedule, and output flags all round-tripped)');
    });

    await check('cronjob.update accepts a full payload', () async {
      final configuration = CronJobConfiguration(
        command: '/usr/bin/true',
        user: 'root',
        description: _description,
        schedule: const TaskSchedule(minute: '45', hour: '4'),
        enabled: false,
      );
      await session.call(
        'cronjob.update',
        params: [jobId, configuration.toApiJson()],
      );
      final rows =
          await session.call(
                'cronjob.query',
                params: [
                  [
                    ['id', '=', jobId],
                  ],
                ],
              )
              as List;
      final job = CronJob.fromJson(rows.first as Map<String, dynamic>);
      if (job.schedule.minute != '45' || job.enabled) {
        throw StateError(
          'update did not apply: ${job.schedule.cronExpression}',
        );
      }
    });

    await check('cronjob.run executes a disabled job', () async {
      // skip_disabled false is the point: the job was just disabled above, and
      // the server default would silently do nothing.
      final result = await session.call('cronjob.run', params: [jobId, false]);
      if (result is int) {
        await session.awaitJob(result);
      }
      print('      (ran despite being disabled)');
    });
  } finally {
    if (jobId != null) {
      await check('cronjob.delete removes it', () async {
        await session.call('cronjob.delete', params: [jobId]);
        final rows =
            await session.call(
                  'cronjob.query',
                  params: [
                    [
                      ['id', '=', jobId],
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

  Future<void> awaitJob(int jobId) async {
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
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
      switch (job['state']) {
        case 'SUCCESS':
          return;
        case 'FAILED':
        case 'ABORTED':
          throw StateError('job $jobId ${job['state']}: ${job['error']}');
      }
    }
    throw StateError('job $jobId did not finish');
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
