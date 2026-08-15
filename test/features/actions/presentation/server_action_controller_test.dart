import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/logging/redacted_logger.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/actions/presentation/server_action_controller.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/replication_configuration.dart';
import 'package:true_dock/features/data_protection/domain/rsync_configuration.dart';
import 'package:true_dock/features/system/domain/interface_configuration.dart';

/// Fails every call with a supplied error, standing in for a server that
/// rejects the request: permission denied, expired session, or transport loss.
class _FailingClient extends TrueNasJsonRpcClient {
  _FailingClient(this.error);

  final Object error;
  String? method;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    this.method = method;
    throw error;
  }
}

/// Blocks until released, so a second call can be attempted while the first
/// is still in flight.
class _BlockingClient extends TrueNasJsonRpcClient {
  final List<String> calls = [];
  bool release = false;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls.add(method);
    while (!release) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    return {'id': 1};
  }
}

/// Records the params of every call, so a test can assert what actually
/// reached the wire rather than only that a call happened.
class _RecordingClient extends TrueNasJsonRpcClient {
  final List<(String, List<Object?>)> calls = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls.add((method, params));
    return 1;
  }
}

ProviderContainer _containerFor(
  TrueNasJsonRpcClient client, {
  RecordingLogSink? sink,
}) {
  final container = ProviderContainer(
    overrides: [
      serverActionsRepositoryProvider.overrideWithValue(
        ServerActionsRepository(client),
      ),
      if (sink != null)
        redactedLoggerProvider.overrideWithValue(RedactedLogger(sink: sink)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _replication = ReplicationConfiguration(
  name: 'Nightly offsite',
  direction: ReplicationDirection.push,
  transport: ReplicationTransport.ssh,
  sshCredentialId: 3,
  sourceDatasets: ['tank/media'],
  targetDataset: 'backup/media',
);

const _rsync = RsyncConfiguration(
  path: '/mnt/tank/media',
  user: 'backup',
  direction: RsyncDirection.push,
  mode: RsyncMode.ssh,
  remoteHost: 'offsite.example',
  remotePath: '/srv/media',
  sshCredentialId: 4,
);

const _cloudSync = CloudSyncConfiguration(
  description: 'Nightly offsite',
  direction: CloudSyncDirection.push,
  transferMode: CloudSyncTransferMode.copy,
  path: '/mnt/tank/media',
  credentialId: 3,
  bucket: 'my-bucket',
  folder: 'media',
);

const _s3 = CloudCredential(id: 3, name: 'Backblaze', provider: 'S3');

const _interface = InterfaceConfiguration(
  id: 'eno1',
  name: 'eno1',
  ipv4Dhcp: false,
  aliases: [InterfaceAlias(address: '192.168.1.10', netmask: 24)],
);

void main() {
  group('permission denied', () {
    test('surfaces the server reason instead of a generic failure', () async {
      const denied = TrueNasRpcException(
        code: 13,
        message: 'Not authenticated',
        reason: 'Account lacks the REPLICATION_TASK_WRITE role.',
      );
      final container = _containerFor(_FailingClient(denied));
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      final receipt = await controller.createReplicationTask(_replication);

      expect(
        receipt,
        isNull,
        reason: 'a rejected mutation must not report success',
      );
      expect(
        container.read(serverActionControllerProvider).errorMessage,
        'Account lacks the REPLICATION_TASK_WRITE role.',
      );
    });

    test('falls back to the message when the server sends no reason', () async {
      const denied = TrueNasRpcException(
        code: 13,
        message: 'Not authenticated',
      );
      final container = _containerFor(_FailingClient(denied));
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      await controller.createRsyncTask(_rsync);

      expect(
        container.read(serverActionControllerProvider).errorMessage,
        'Not authenticated',
      );
    });
  });

  group('transport loss', () {
    test('a dropped socket does not surface a raw exception string', () async {
      final container = _containerFor(
        _FailingClient(StateError('WebSocket is closed')),
      );
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      final receipt = await controller.createCloudSyncTask(_cloudSync, _s3);

      expect(receipt, isNull);
      // Presentation owns the localized generic fallback. Keeping this null
      // prevents a controller-level English sentence from leaking into Korean.
      expect(
        container.read(serverActionControllerProvider).errorMessage,
        isNull,
      );
    });

    test('a failed read returns null rather than throwing', () async {
      const expired = TrueNasRpcException(
        code: 401,
        message: 'Session expired',
      );
      final container = _containerFor(_FailingClient(expired));
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      // Reads used to seed editors must degrade to null so the caller can
      // explain the failure instead of crashing the sheet.
      expect(await controller.getSshCredentials(), isNull);
      expect(await controller.getCloudCredentials(), isNull);
      expect(await controller.getReplicationTaskConfig(1), isNull);
      expect(await controller.getRsyncTaskConfig(1), isNull);
      expect(await controller.getCloudSyncTaskConfig(1), isNull);
      expect(await controller.getInterfaceConfig('eno1'), isNull);
    });
  });

  group('failure logging', () {
    test('logs the failure without leaking the payload secrets', () async {
      final sink = RecordingLogSink();
      const denied = TrueNasRpcException(
        code: 13,
        message: 'Not authenticated',
      );
      final container = _containerFor(_FailingClient(denied), sink: sink);
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      await controller.createCloudSyncTask(
        _cloudSync.copyWith(
          encryption: true,
          encryptionPassword: 'SuperSecretValue1',
        ),
        _s3,
      );

      expect(sink.entries, isNotEmpty);
      final logged = sink.entries.map((e) => e.message).join('\n');
      expect(
        logged,
        isNot(contains('SuperSecretValue1')),
        reason: 'an encryption password must never reach the log',
      );
    });
  });

  group('non-idempotent mutation safety', () {
    test(
      'a second identical mutation is dropped while the first is in flight',
      () async {
        final client = _BlockingClient();
        final container = _containerFor(client);
        final controller = container.read(
          serverActionControllerProvider.notifier,
        );

        // Fire the same create twice without awaiting the first. TrueNAS would
        // otherwise create two tasks from one user intent.
        final first = controller.createReplicationTask(_replication);
        final second = controller.createReplicationTask(_replication);

        expect(await second, isNull, reason: 'the duplicate must be dropped');
        client.release = true;
        expect(await first, isNotNull);
        expect(
          client.calls.length,
          1,
          reason: 'only one request may reach the server',
        );
      },
    );

    test('distinct targets are not blocked by each other', () async {
      final client = _BlockingClient();
      final container = _containerFor(client);
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      final a = controller.createReplicationTask(_replication);
      final b = controller.createReplicationTask(
        _replication.copyWith(name: 'Weekly offsite'),
      );
      client.release = true;

      expect(await a, isNotNull);
      expect(await b, isNotNull);
      expect(client.calls.length, 2);
    });
  });

  group('pool.replace', () {
    // The sheet offers a force switch and the confirmation warns that it
    // removes a disk still being read, but the controller used to drop the flag
    // on the floor: its signature had no `force` parameter, so the repository
    // default of false was always sent. The app promised a forced replacement
    // and quietly performed an ordinary one, which fails on exactly the
    // degraded pool the option exists for.
    test('forwards force to the server instead of dropping it', () async {
      final client = _RecordingClient();
      final controller = _containerFor(
        client,
      ).read(serverActionControllerProvider.notifier);

      await controller.replacePoolDisk(
        poolId: 7,
        label: 'sdb1',
        disk: 'sdc',
        force: true,
      );

      final (method, params) = client.calls.single;
      expect(method, 'pool.replace');
      expect(params.first, 7);
      expect(
        (params[1]! as Map)['force'],
        isTrue,
        reason: 'the force the user asked for never reached the server',
      );
    });

    test('defaults to an unforced replacement', () async {
      final client = _RecordingClient();
      final controller = _containerFor(
        client,
      ).read(serverActionControllerProvider.notifier);

      await controller.replacePoolDisk(poolId: 7, label: 'sdb1', disk: 'sdc');

      // Forcing must be opt-in: defaulting to true would detach a live disk
      // from a user who never asked for it.
      expect((client.calls.single.$2[1]! as Map)['force'], isFalse);
    });
  });

  group('busy state', () {
    test('clears after a failure so the action can be retried', () async {
      const denied = TrueNasRpcException(
        code: 13,
        message: 'Not authenticated',
      );
      final container = _containerFor(_FailingClient(denied));
      final controller = container.read(
        serverActionControllerProvider.notifier,
      );

      await controller.updateInterface(_interface);

      // A stuck busy key would leave the control permanently disabled.
      expect(container.read(serverActionControllerProvider).busyKeys, isEmpty);
    });
  });
}
