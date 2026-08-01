import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/storage/domain/dataset_acl.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _dataset = 'truedock_data/truedock_acl_probe';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_dataset_acl_probe.dart host user password',
    );
    exit(64);
  }
  final [host, username, password] = args;
  WebSocketChannel? channel;
  final pending = <int, Completer<Object?>>{};
  var nextId = 1;

  Future<Object?> call(String method, {List<Object?> params = const []}) async {
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
    return completer.future.timeout(const Duration(seconds: 30));
  }

  Future<void> runJob(String method, List<Object?> params) async {
    final result = await call(method, params: params);
    if (result is! int) return;
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final jobs = await call(
        'core.get_jobs',
        params: [
          [
            ['id', '=', result],
          ],
        ],
      );
      if (jobs is! List || jobs.isEmpty) continue;
      final job = jobs.first as Map;
      if (job['state'] == 'SUCCESS') return;
      if (job['state'] == 'FAILED' || job['state'] == 'ABORTED') {
        throw StateError('$method failed: ${job['error']}');
      }
    }
    throw TimeoutException('$method job did not finish');
  }

  var created = false;
  try {
    final httpClient = HttpClient()
      ..badCertificateCallback = (certificate, server, port) {
        stderr.writeln(
          'Trusting ${sha256.convert(certificate.der)} for $server:$port',
        );
        return server == host;
      };
    channel = IOWebSocketChannel.connect(
      'wss://$host/api/current',
      customClient: httpClient,
    );
    channel.stream.listen((message) {
      final decoded = jsonDecode(message.toString());
      if (decoded is! Map || decoded['id'] is! int) return;
      final completer = pending.remove(decoded['id'] as int);
      if (completer == null) return;
      if (decoded['error'] != null) {
        completer.completeError(StateError(jsonEncode(decoded['error'])));
      } else {
        completer.complete(decoded['result']);
      }
    });
    await channel.ready;

    final auth = await call(
      'auth.login_ex',
      params: [
        {
          'mechanism': 'PASSWORD_PLAIN',
          'username': username,
          'password': password,
        },
      ],
    );
    if (auth is! Map || auth['response_type'] != 'SUCCESS') {
      throw StateError('Authentication failed');
    }
    stdout.writeln('PASS authenticate');

    final leftovers = await call(
      'pool.dataset.query',
      params: [
        [
          ['id', '=', _dataset],
        ],
      ],
    );
    if (leftovers is List && leftovers.isNotEmpty) {
      await call(
        'pool.dataset.delete',
        params: [
          _dataset,
          {'recursive': true},
        ],
      );
      stdout.writeln('PASS remove previous probe dataset');
    }

    await call(
      'pool.dataset.create',
      params: [
        {
          'name': _dataset,
          'type': 'FILESYSTEM',
          'share_type': 'GENERIC',
          'inherit_encryption': true,
        },
      ],
    );
    created = true;
    stdout.writeln('PASS create $_dataset');

    final users = await call(
      'user.query',
      params: [
        [
          ['username', '=', username],
        ],
      ],
    );
    if (users is! List || users.isEmpty) {
      throw StateError('Could not resolve $username');
    }
    final uid = ((users.first as Map)['uid'] as num).toInt();

    final raw = await call(
      'filesystem.getacl',
      params: ['/mnt/$_dataset', true, true],
    );
    if (raw is! Map) throw StateError('filesystem.getacl returned $raw');
    final baseline = DatasetAcl.fromJson(Map<String, dynamic>.from(raw));
    if (baseline.type != DatasetAclType.posix1e) {
      throw StateError('Expected POSIX1E, got ${baseline.type}');
    }
    stdout.writeln('PASS read baseline POSIX1E ACL');

    final entries = List<DatasetAclEntry>.of(baseline.entries)
      ..add(
        DatasetAclEntry.named(
          DatasetAclPrincipal(
            name: username,
            id: uid,
            kind: DatasetAclPrincipalKind.user,
          ),
          DatasetAclType.posix1e,
        ),
      );
    if (!entries.any((entry) => entry.tag == 'MASK')) {
      entries.add(
        const DatasetAclEntry(
          tag: 'MASK',
          permissions: {'READ': true, 'WRITE': false, 'EXECUTE': true},
          id: -1,
          isDefault: false,
        ),
      );
    }
    final edited = baseline.copyWith(entries: entries);
    await runJob('filesystem.setacl', [edited.toSetApiJson(recursive: false)]);
    stdout.writeln('PASS apply ACL through filesystem.setacl');

    final verifiedRaw = await call(
      'filesystem.getacl',
      params: ['/mnt/$_dataset', true, true],
    );
    final verified = DatasetAcl.fromJson(
      Map<String, dynamic>.from(verifiedRaw! as Map),
    );
    final applied = verified.entries.any(
      (entry) => entry.tag == 'USER' && entry.id == uid,
    );
    if (!applied) throw StateError('Applied user ACL was not returned');
    stdout.writeln('PASS verify $username ACL after read-back');

    final nfs4 = verified.convertedTo(DatasetAclType.nfs4);
    await runJob('pool.dataset.update', [
      _dataset,
      {'acltype': 'NFSV4', 'aclmode': 'PASSTHROUGH'},
    ]);
    await runJob('filesystem.setacl', [nfs4.toSetApiJson(recursive: false)]);
    final nfs4Raw = await call(
      'filesystem.getacl',
      params: ['/mnt/$_dataset', true, true],
    );
    final nfs4Verified = DatasetAcl.fromJson(
      Map<String, dynamic>.from(nfs4Raw! as Map),
    );
    if (nfs4Verified.type != DatasetAclType.nfs4 ||
        !nfs4Verified.entries.any(
          (entry) => entry.tag == 'USER' && entry.id == uid,
        )) {
      throw StateError('POSIX to NFS4 conversion did not survive read-back');
    }
    stdout.writeln('PASS convert POSIX1E to TrueNAS NFS4 ACL');

    final posix = nfs4Verified
        .convertedTo(DatasetAclType.posix1e)
        .copyWith(uid: uid, user: username);
    await runJob('pool.dataset.update', [
      _dataset,
      {'acltype': 'POSIX', 'aclmode': 'DISCARD'},
    ]);
    await runJob('filesystem.setacl', [posix.toSetApiJson(recursive: false)]);
    final finalRaw = await call(
      'filesystem.getacl',
      params: ['/mnt/$_dataset', true, true],
    );
    final finalAcl = DatasetAcl.fromJson(
      Map<String, dynamic>.from(finalRaw! as Map),
    );
    if (finalAcl.type != DatasetAclType.posix1e || finalAcl.uid != uid) {
      throw StateError('NFS4 to POSIX conversion or owner change failed');
    }
    stdout.writeln('PASS convert NFS4 to POSIX1E and change owner');
  } finally {
    if (created && channel != null) {
      try {
        await call(
          'pool.dataset.delete',
          params: [
            _dataset,
            {'recursive': true},
          ],
        );
        stdout.writeln('PASS delete $_dataset');
      } on Object catch (error) {
        stderr.writeln('CLEANUP FAILED: $error');
      }
    }
    try {
      await call('auth.logout');
    } on Object catch (_) {}
    await channel?.sink.close();
  }
}
