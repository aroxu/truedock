// Heap-growth probe for the Overview refresh loop.
//
// `Exhausted heap space` in a long-running session has two very different
// causes, and a static audit cannot tell them apart:
//
//   1. a retained-growth leak — something holds on to every response, so the
//      live set grows without bound and the floor never comes back down;
//   2. allocation pressure — each refresh builds a large short-lived object
//      graph that is collectable, so usage oscillates around a plateau.
//
// The fix for (1) is to release the retained reference. The fix for (2) is to
// allocate less per refresh. Shipping the wrong one wastes the change, so this
// probe reproduces the app's one-second Overview refresh against a real server
// and reports heap usage over time. A rising floor means (1); a flat floor
// with a noisy ceiling means (2).
//
// Usage:
//   dart run tool/live_heap_probe.dart <host> <username> <password> [seconds]
//       [--live-tail]
//   dart run tool/live_heap_probe.dart --offline [seconds]
//
// `--offline` answers the same retained-vs-churn question without a server by
// replaying a synthetic hour of Netdata rows through the same decoder at the
// same cadence. It cannot measure real payload sizes, but retention is a
// property of the code, not of the numbers in the rows: if the decoder or the
// derived getters held on to anything, the floor would climb here too.
//
// The probe speaks the wire protocol directly rather than going through
// `TrueNasJsonRpcClient`, because that class reaches the platform keychain via
// flutter_secure_storage and cannot be compiled for the plain Dart VM. It does
// reuse the real `ReportingSeries` decoder and the real chart reducer, which
// are pure Dart — those are exactly the allocations under investigation.
//
// A server with two-factor authentication enabled will refuse the plain
// password login; pass the current OTP as TRUEDOCK_OTP in the environment.
//
// Read-only against the server. Credentials come from argv and are never
// persisted.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/reporting/domain/reporting_series.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Mirrors `Sparkline`'s bucket-averaging reducer.
///
/// Copied rather than imported because the original lives in a widget library
/// that pulls in Flutter. The arithmetic is what allocates, and it is
/// identical; `test/features/reporting/heap_probe_reducer_test.dart` pins the
/// two implementations together so this copy cannot silently drift.
List<double?> reduceChartDensity(
  List<double?> values, {
  int maximumSamples = 100,
}) {
  if (values.length <= maximumSamples) return values;
  return [
    for (var bucket = 0; bucket < maximumSamples; bucket++)
      _bucketMean(
        values,
        (bucket * values.length / maximumSamples).floor(),
        ((bucket + 1) * values.length / maximumSamples).floor(),
      ),
  ];
}

double? _bucketMean(List<double?> values, int start, int end) {
  var sum = 0.0;
  var count = 0;
  var gaps = 0;
  for (var index = start; index < end; index++) {
    final value = values[index];
    if (value == null) {
      gaps++;
    } else {
      sum += value;
      count++;
    }
  }
  if (count == 0 || gaps >= count) return null;
  return sum / count;
}

Future<void> main(List<String> args) async {
  if (args.isNotEmpty && args.first == '--offline') {
    final seconds = int.tryParse(args.length > 1 ? args[1] : '') ?? 120;
    await _runOffline(Duration(seconds: seconds), tail: false);
    return;
  }
  if (args.isNotEmpty && args.first == '--offline-tail') {
    final seconds = int.tryParse(args.length > 1 ? args[1] : '') ?? 120;
    await _runOffline(Duration(seconds: seconds), tail: true);
    return;
  }
  if (args.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/live_heap_probe.dart <host> <username> '
      '<password> [seconds]\n'
      '       dart run tool/live_heap_probe.dart --offline [seconds]',
    );
    exit(64);
  }
  final host = args[0];
  final username = args[1];
  final password = args[2];
  var durationSeconds = 120;
  for (final argument in args.skip(3)) {
    final parsed = int.tryParse(argument);
    if (parsed != null) {
      durationSeconds = parsed;
      break;
    }
  }
  final duration = Duration(seconds: durationSeconds);

  final pending = <int, Completer<Object?>>{};
  var nextId = 1;
  WebSocketChannel? channel;

  Future<Object?> call(String method, {List<Object?> params = const []}) {
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

  final httpClient = HttpClient()
    ..badCertificateCallback = (certificate, presentedHost, port) {
      final fingerprint = sha256.convert(certificate.der).toString();
      stderr.writeln('      (trusting cert fingerprint $fingerprint)');
      return presentedHost == host;
    };
  channel = IOWebSocketChannel.connect(
    'wss://$host/api/current',
    customClient: httpClient,
    connectTimeout: const Duration(seconds: 15),
  );
  await channel.ready.timeout(const Duration(seconds: 15));
  channel.stream.listen(
    (message) {
      final decoded = jsonDecode(message.toString());
      if (decoded is! Map || decoded['id'] is! int) return;
      final completer = pending.remove(decoded['id'] as int);
      if (completer == null || completer.isCompleted) return;
      final error = decoded['error'];
      if (error != null) {
        completer.completeError(StateError(jsonEncode(error)));
      } else {
        completer.complete(decoded['result']);
      }
    },
    onError: (Object error) {
      for (final completer in pending.values) {
        if (!completer.isCompleted) completer.completeError(error);
      }
      pending.clear();
    },
  );

  var login = await call(
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
  if (login is Map && login['response_type'] == 'OTP_REQUIRED') {
    // A TOTP code is valid for about thirty seconds, so reading it from the
    // environment means it has to survive process start-up, the TLS handshake,
    // and the first login round trip. Prompting here instead spends that
    // budget on the code itself: everything slow has already happened by the
    // time the operator is asked. The environment variable stays supported for
    // unattended runs.
    var otp = Platform.environment['TRUEDOCK_OTP'] ?? '';
    if (otp.isEmpty) {
      stdout.writeln(
        'This server requires two-factor authentication.\n'
        'The connection is open and waiting, so enter the code that is '
        'current right now:',
      );
      stdout.write('OTP: ');
      var echoDisabled = false;
      try {
        if (stdin.hasTerminal) {
          stdin.echoMode = false;
          echoDisabled = true;
        }
        otp = (stdin.readLineSync() ?? '').trim();
      } finally {
        if (echoDisabled) {
          stdin.echoMode = true;
          stdout.writeln();
        }
      }
    }
    if (otp.isEmpty) {
      stderr.writeln(
        'No code supplied. Use --offline to run without a server.',
      );
      await channel.sink.close();
      exit(1);
    }
    login = await call(
      'auth.login_ex_continue',
      params: [
        {
          'mechanism': 'OTP_TOKEN',
          'otp_token': otp,
          'login_options': {'user_info': true},
        },
      ],
    );
  }
  if (login is! Map || login['response_type'] != 'SUCCESS') {
    stderr.writeln('Authentication failed: $login');
    await channel.sink.close();
    exit(1);
  }

  final systemInfo = await call('system.info');
  final totalMemoryBytes = systemInfo is Map
      ? systemInfo['physmem'] as int?
      : null;

  // Discover the interface/disk identifiers exactly as ReportingRepository
  // does, so the request fan-out matches the app's.
  final graphs = await call('reporting.netdata_graphs');
  final requests = <Map<String, Object?>>[
    {'name': 'cpu'},
    {'name': 'memory'},
    {'name': 'load'},
  ];
  if (graphs is List) {
    for (final entry in graphs) {
      if (entry is! Map) continue;
      final name = entry['name'];
      if (name != 'interface' && name != 'disk') continue;
      final identifiers = entry['identifiers'];
      if (identifiers is! List) continue;
      for (final identifier in identifiers.whereType<String>()) {
        requests.add({'name': name, 'identifier': identifier});
      }
    }
  }

  final samples = <_Sample>[];
  final started = DateTime.now();
  var refreshes = 0;
  var totalPoints = 0;
  var totalDecoded = 0;
  final retained = <String, ReportingSeries>{};
  var cursorSeconds = 0;

  final tailMode = args.contains('--live-tail');

  stdout.writeln(
    'Probing wss://$host for ${duration.inSeconds}s at the app\'s 1s '
    'Overview cadence across ${requests.length} series.',
  );
  stdout.writeln(
    tailMode
        ? 'Mode: tail refresh (only requesting elapsed seconds per tick)'
        : 'Mode: full window (requesting full hour per tick)',
  );
  stdout.writeln('elapsed_s   rss_mib   decoded  retained   refreshes');

  while (DateTime.now().difference(started) < duration) {
    final tick = DateTime.now();
    final now = DateTime.now().toUtc();

    // For full window, we always request 1 hour. For tail mode, we request 1 hour on the first tick,
    // and only a short window (e.g. 120 seconds) on subsequent ticks.
    final firstPass = refreshes == 0;
    final startOffset = tailMode && !firstPass
        ? const Duration(seconds: 120)
        : const Duration(hours: 1);

    final result = await call(
      'reporting.netdata_get_data',
      params: [
        requests,
        {
          'start': now.subtract(startOffset).millisecondsSinceEpoch ~/ 1000,
          'end': now.millisecondsSinceEpoch ~/ 1000,
        },
      ],
    );
    refreshes++;

    var decoded = 0;
    var held = 0;

    if (result is List) {
      for (final entry in result) {
        if (entry is! Map<String, dynamic>) continue;
        final series = ReportingSeries.fromJson(entry);
        decoded += series.points.length;

        final key = series.graphKey;
        final merged = tailMode
            ? series.appendTo(retained[key], keep: const Duration(hours: 1))
            : series;
        retained[key] = merged;
        held += merged.points.length;

        // Touch the derived getters the Overview widgets read every frame.
        // They are recomputed per call, so they are part of the cost.
        reduceChartDensity(
          merged.name == 'cpu' ? merged.cpuUtilisation : merged.totals,
        );
        if (merged.name == 'memory') {
          reduceChartDensity(merged.valuesFor('available'));
        }
        if (totalMemoryBytes != null && merged.name == 'memory') {
          merged.valuesFor('used');
        }
      }
    }
    totalDecoded += decoded;
    totalPoints += held;

    final elapsed = DateTime.now().difference(started);
    final heap = _heapUsedBytes();
    samples.add(_Sample(elapsed, heap, decoded));
    stdout.writeln(
      '${elapsed.inSeconds.toString().padLeft(9)}   '
      '${(heap / (1024 * 1024)).toStringAsFixed(1).padLeft(7)}  '
      '${decoded.toString().padLeft(8)}  '
      '${held.toString().padLeft(8)}  '
      '${refreshes.toString().padLeft(10)}',
    );

    final remaining =
        const Duration(seconds: 1) - DateTime.now().difference(tick);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  await channel.sink.close();
  httpClient.close(force: true);
  _report(samples, refreshes, totalDecoded);
  exit(0);
}

/// Replays synthetic Netdata rows through the real decoder.
///
/// The row shape mirrors `reporting.netdata_get_data`: a `legend` whose first
/// column is the timestamp, then one column per dimension. An hour at the
/// one-second resolution TrueNAS reports for the live graphs is 3600 rows per
/// series, which is what made a single Overview refresh expensive.
///
/// With [tail] false this reproduces the original behaviour: every tick decodes
/// the whole displayed hour. With [tail] true it reproduces the current one:
/// the first tick loads the hour, and each later tick decodes only a two-minute
/// window and stitches it onto the retained history through `appendTo`. Running
/// both is how the change is shown to have actually reduced the work rather
/// than moved it.
Future<void> _runOffline(Duration duration, {required bool tail}) async {
  const secondsPerHour = 3600;
  const tailSeconds = 120;
  const dimensions = <({String name, String? id, List<String> columns})>[
    (name: 'cpu', id: null, columns: ['user', 'system', 'nice', 'iowait']),
    (name: 'memory', id: null, columns: ['available', 'used', 'cached']),
    (name: 'load', id: null, columns: ['load1', 'load5', 'load15']),
    (name: 'interface', id: 'enp6s18', columns: ['received', 'sent']),
    (name: 'interface', id: 'enp6s19', columns: ['received', 'sent']),
    (name: 'interface', id: 'enp6s20', columns: ['received', 'sent']),
    (name: 'disk', id: 'sda', columns: ['reads', 'writes']),
    (name: 'disk', id: 'sdb', columns: ['reads', 'writes']),
    (name: 'disk', id: 'sdc', columns: ['reads', 'writes']),
    (name: 'disk', id: 'sdd', columns: ['reads', 'writes']),
    (name: 'disk', id: 'vda', columns: ['reads', 'writes']),
  ];

  final samples = <_Sample>[];
  final started = DateTime.now();
  var refreshes = 0;
  var totalPoints = 0;
  var totalDecoded = 0;
  // Retained history, keyed the same way the snapshot merge keys it.
  final retained = <String, ReportingSeries>{};
  // Where the next window begins, in seconds since the synthetic epoch.
  var cursor = 0;

  stdout.writeln(
    'Offline replay for ${duration.inSeconds}s at the app\'s 1s Overview '
    'cadence across ${dimensions.length} series.',
  );
  stdout.writeln(
    tail
        ? 'Mode: tail refresh (${tailSeconds}s per tick, '
              '${secondsPerHour}s retained).'
        : 'Mode: full window (${secondsPerHour}s per tick).',
  );
  stdout.writeln('elapsed_s   rss_mib   decoded   retained   refreshes');

  while (DateTime.now().difference(started) < duration) {
    final tick = DateTime.now();
    final firstPass = refreshes == 0;
    final windowSeconds = !tail || firstPass ? secondsPerHour : tailSeconds;
    // A tail overlaps the retained history by design, so it starts a window
    // before the cursor rather than at it.
    final windowStart = !tail || firstPass
        ? cursor
        : cursor + secondsPerHour - tailSeconds;

    var decoded = 0;
    var held = 0;
    for (final spec in dimensions) {
      final raw = _syntheticSeries(
        spec.name,
        spec.id,
        spec.columns,
        windowSeconds,
        firstSecond: windowStart,
      );
      final series = ReportingSeries.fromJson(raw);
      decoded += series.points.length;

      final key = spec.id == null ? spec.name : '${spec.name}\u0000${spec.id}';
      final merged = tail
          ? series.appendTo(
              retained[key],
              keep: const Duration(seconds: secondsPerHour),
            )
          : series;
      retained[key] = merged;
      held += merged.points.length;

      // Touch the derived projections the Overview widgets read every frame.
      reduceChartDensity(
        merged.name == 'cpu' ? merged.cpuUtilisation : merged.totals,
      );
      if (merged.name == 'memory') {
        reduceChartDensity(merged.valuesFor('available'));
        merged.valuesFor('used');
      }
    }
    refreshes++;
    totalDecoded += decoded;
    totalPoints += held;
    if (tail && !firstPass) cursor += tailSeconds;

    final elapsed = DateTime.now().difference(started);
    final rss = _heapUsedBytes();
    samples.add(_Sample(elapsed, rss, decoded));
    stdout.writeln(
      '${elapsed.inSeconds.toString().padLeft(9)}   '
      '${(rss / (1024 * 1024)).toStringAsFixed(1).padLeft(7)}  '
      '${decoded.toString().padLeft(8)}  '
      '${held.toString().padLeft(9)}  '
      '${refreshes.toString().padLeft(10)}',
    );

    final remaining =
        const Duration(seconds: 1) - DateTime.now().difference(tick);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  _report(samples, refreshes, totalDecoded);
  stdout.writeln(
    'points on screen:     ${(totalPoints / refreshes).toStringAsFixed(0)} '
    'per refresh (chart content, unchanged by the mode)',
  );
}

Map<String, dynamic> _syntheticSeries(
  String name,
  String? identifier,
  List<String> dimensions,
  int rows, {
  int firstSecond = 0,
}) {
  const epoch = 1760000000;
  final series = <String, dynamic>{
    'name': name,
    'legend': ['time', ...dimensions],
    'start': epoch + firstSecond,
    'end': epoch + firstSecond + rows,
    'step': 1,
    'unit': name == 'memory' ? 'MiB' : null,
    'data': [
      for (var row = 0; row < rows; row++)
        <Object?>[
          epoch + firstSecond + row,
          for (var index = 0; index < dimensions.length; index++)
            // A deterministic sawtooth keeps the values realistic without a
            // random source, and the periodic null reproduces the reporting
            // gaps the reducer has to preserve.
            (row + index) % 97 == 0 ? null : ((row * (index + 3)) % 100) / 3.0,
        ],
    ],
  };
  if (identifier != null) series['identifier'] = identifier;
  return series;
}

/// Resident set size for this process.
///
/// RSS lags the Dart heap because the VM keeps freed pages mapped, which makes
/// it a poor absolute measure but a sound *trend* measure: a genuine leak has
/// to push RSS monotonically upward, because the retained objects can never be
/// reclaimed. Pure churn lets RSS settle onto a plateau once the VM has grown
/// enough old space to recycle. The verdict below therefore reads the floor of
/// the last third against the floor of the first, not any single sample.
int _heapUsedBytes() => ProcessInfo.currentRss;

/// Compares the first and last thirds of the run.
///
/// A leak shows up as a rising *minimum*: even right after a collection the
/// process cannot get back to where it started. Allocation pressure raises the
/// average and the maximum while leaving the minimum flat.
void _report(List<_Sample> samples, int refreshes, int totalPoints) {
  if (samples.length < 6) {
    stdout.writeln('\nToo few samples to judge a trend.');
    return;
  }
  final third = samples.length ~/ 3;
  final head = samples.take(third).toList();
  final tail = samples.skip(samples.length - third).toList();

  double minOf(List<_Sample> window) => window
      .map((sample) => sample.heap / (1024 * 1024))
      .reduce((a, b) => a < b ? a : b);
  double maxOf(List<_Sample> window) => window
      .map((sample) => sample.heap / (1024 * 1024))
      .reduce((a, b) => a > b ? a : b);

  final headMin = minOf(head);
  final tailMin = minOf(tail);
  final drift = tailMin - headMin;

  stdout.writeln('\n--- summary ---');
  stdout.writeln('refreshes:            $refreshes');
  stdout.writeln(
    'points decoded:       $totalPoints '
    '(${(totalPoints / refreshes).toStringAsFixed(0)} per refresh)',
  );
  stdout.writeln(
    'first third:          min ${headMin.toStringAsFixed(1)} MiB, '
    'max ${maxOf(head).toStringAsFixed(1)} MiB',
  );
  stdout.writeln(
    'last third:           min ${tailMin.toStringAsFixed(1)} MiB, '
    'max ${maxOf(tail).toStringAsFixed(1)} MiB',
  );
  stdout.writeln('floor drift:          ${drift.toStringAsFixed(1)} MiB');
  stdout.writeln(
    drift > 8
        ? 'VERDICT: retained growth — the live set is not being released.'
        : 'VERDICT: no retained growth — the cost is per-refresh allocation.',
  );
}

class _Sample {
  const _Sample(this.elapsed, this.heap, this.points);
  final Duration elapsed;
  final int heap;
  final int points;
}
