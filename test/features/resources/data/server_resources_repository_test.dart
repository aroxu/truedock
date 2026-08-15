import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/core/domain/data_message.dart';
import 'package:true_dock/features/resources/data/server_resources_repository.dart';

void main() {
  test('loads only active jobs for the global job FAB', () async {
    final client = _FakeClient({
      'core.get_jobs': [
        {'id': 42, 'method': 'pool.scrub.scrub', 'state': 'RUNNING'},
      ],
    });
    final section = await ServerResourcesRepository(
      client,
    ).loadActiveJobs(supportedMethods: const {'core.get_jobs'});

    expect(section.items.single.id, 42);
    expect(client.paramsFor('core.get_jobs'), [
      [
        [
          'state',
          'in',
          ['WAITING', 'RUNNING'],
        ],
      ],
      {
        'order_by': ['-id'],
        'limit': 100,
      },
    ]);
  });

  test('loads one job by id including its terminal state', () async {
    final client = _FakeClient({
      'core.get_jobs': [
        {'id': 42, 'method': 'pool.scrub.scrub', 'state': 'SUCCESS'},
      ],
    });

    final job = await ServerResourcesRepository(
      client,
    ).loadJob(42, supportedMethods: const {'core.get_jobs'});

    expect(job?.state, 'SUCCESS');
    expect(client.paramsFor('core.get_jobs'), [
      [
        ['id', '=', 42],
      ],
      {'limit': 1},
    ]);
  });

  test('loads and maps all supported read sections', () async {
    final repository = ServerResourcesRepository(
      _FakeClient({
        'pool.query': [
          {
            'id': 1,
            'name': 'tank',
            'status': 'ONLINE',
            'size': 100,
            'allocated': 40,
            'free': 60,
          },
        ],
        'pool.dataset.query': [
          {'id': 'tank/media', 'name': 'tank/media'},
        ],
        'app.query': [
          {
            'id': 'plex',
            'name': 'Plex',
            'state': 'RUNNING',
            'human_version': '1.0',
            'upgrade_available': false,
          },
        ],
        'service.query': [
          {'id': 1, 'service': 'ssh', 'state': 'RUNNING', 'enable': true},
        ],
        'alert.list': const [],
        'core.get_jobs': const [],
        'replication.query': const [],
        'pool.snapshottask.query': const [],
        'disk.query': [
          {
            'identifier': '{serial}ABC',
            'name': 'sda',
            'model': 'Example SSD',
            'serial': 'ABC',
            'type': 'SSD',
            'size': 1000,
            'pool': 'tank',
          },
        ],
        'sharing.smb.query': [
          {
            'id': 2,
            'name': 'Media',
            'path': '/mnt/tank/media',
            'enabled': true,
            'readonly': false,
            'purpose': 'DEFAULT_SHARE',
            'locked': false,
          },
        ],
        'sharing.nfs.query': const [],
        'vm.query': [
          {
            'id': 9,
            'name': 'Build VM',
            'status': {'state': 'RUNNING'},
            'vcpus': 1,
            'cores': 2,
            'threads': 1,
            'memory': 4096,
            'autostart': true,
            'display_available': true,
          },
        ],
        'pool.snapshot.query': [
          {
            'id': 'tank/media@auto-1',
            'dataset': 'tank/media',
            'snapshot_name': 'auto-1',
            'createtxg': '1234',
          },
        ],
        'pool.scrub.query': [
          {
            'id': 5,
            'pool_name': 'tank',
            'enabled': true,
            'threshold': 35,
            'schedule': {'hour': '00', 'minute': '00', 'dow': '7'},
          },
        ],
        'cloudsync.query': const [],
        'rsynctask.query': const [],
        'container.query': [
          {
            'id': 12,
            'uuid': 'container-uuid',
            'name': 'Worker',
            'dataset': 'tank/containers/worker',
            'autostart': true,
            'devices': const [],
            'status': {'state': 'RUNNING'},
          },
        ],
        'iscsi.target.query': [
          {
            'id': 13,
            'name': 'iqn.2026-08.me.aroxu:media',
            'mode': 'ISCSI',
            'groups': const [],
          },
        ],
        'iscsi.extent.query': [
          {
            'id': 14,
            'name': 'Media',
            'type': 'DISK',
            'disk': 'zvol/tank/media',
            'blocksize': 512,
            'enabled': true,
            'ro': false,
            'locked': false,
          },
        ],
        'sharing.webshare.query': [
          {
            'id': 15,
            'name': 'Projects',
            'path': '/mnt/tank/projects',
            'enabled': true,
            'locked': false,
          },
        ],
        'iscsi.portal.query': [
          {
            'id': 16,
            'tag': 1,
            'comment': 'Storage network',
            'listen': [
              {'ip': '10.0.0.10', 'port': 3260},
            ],
          },
        ],
        'iscsi.initiator.query': [
          {
            'id': 17,
            'initiators': ['iqn.2026-08.me.aroxu:build-client'],
            'comment': 'Build client',
          },
        ],
        'iscsi.targetextent.query': [
          {'id': 18, 'target': 13, 'extent': 14, 'lunid': 0},
        ],
      }),
    );

    final resources = await repository.load();

    expect(resources.pools.items.single.name, 'tank');
    expect(resources.datasets.items.single.leafName, 'media');
    expect(resources.apps.items.single.state, 'RUNNING');
    expect(resources.services.items.single.enabled, isTrue);
    expect(resources.alerts.hasError, isFalse);
    expect(resources.disks.items.single.pool, 'tank');
    expect(resources.smbShares.items.single.name, 'Media');
    expect(resources.virtualMachines.items.single.isRunning, isTrue);
    expect(resources.snapshots.items.single.name, 'auto-1');
    expect(resources.scrubTasks.items.single.poolName, 'tank');
    expect(resources.containers.items.single.isRunning, isTrue);
    expect(resources.iscsiTargets.items.single.mode, 'ISCSI');
    expect(resources.iscsiExtents.items.single.backingStore, 'zvol/tank/media');
    expect(resources.webShares.items.single.name, 'Projects');
    expect(
      resources.iscsiPortals.items.single.addressSummary,
      '10.0.0.10:3260',
    );
    expect(resources.iscsiInitiators.items.single.initiators, [
      'iqn.2026-08.me.aroxu:build-client',
    ]);
    expect(resources.iscsiTargetExtents.items.single.targetId, 13);
    expect(resources.iscsiTargetExtents.items.single.extentId, 14);
    expect(resources.iscsiTargetExtents.items.single.lunId, 0);
  });

  test('loads only discovered iSCSI relationship query sections', () async {
    final client = _RecordingClient();
    final repository = ServerResourcesRepository(client);

    final resources = await repository.load(
      supportedMethods: const {
        'iscsi.portal.query',
        'iscsi.initiator.query',
        'iscsi.targetextent.query',
      },
    );

    expect(client.calledMethods, [
      'iscsi.portal.query',
      'iscsi.initiator.query',
      'iscsi.targetextent.query',
    ]);
    expect(resources.iscsiPortals.hasError, isFalse);
    expect(resources.iscsiInitiators.hasError, isFalse);
    expect(resources.iscsiTargetExtents.hasError, isFalse);
    expect(resources.iscsiTargets.hasError, isTrue);
    expect(
      resources.iscsiTargets.errorMessage,
      'iscsi.target.query is not available on this TrueNAS version.',
    );
  });

  test(
    'does not call methods absent from the discovered API surface',
    () async {
      final client = _RecordingClient();
      final repository = ServerResourcesRepository(client);

      final resources = await repository.load(
        supportedMethods: const {'pool.query'},
      );

      expect(client.calledMethods, ['pool.query']);
      expect(resources.pools.hasError, isFalse);
      expect(resources.containers.hasError, isTrue);
      expect(
        resources.containers.errorMessage,
        'container.query is not available on this TrueNAS version.',
      );
    },
  );

  test('keeps successful sections when one API call is forbidden', () async {
    final repository = ServerResourcesRepository(
      _FakeClient(
        {
          'pool.query': const [],
          'pool.dataset.query': const [],
          'app.query': const [],
          'service.query': const [],
          'alert.list': const [],
          'core.get_jobs': const [],
          'replication.query': const [],
        },
        failures: {
          'pool.snapshottask.query': const TrueNasRpcException(
            code: -32001,
            message: 'Not authorized',
          ),
        },
      ),
    );

    final resources = await repository.load();

    expect(resources.pools.hasError, isFalse);
    expect(resources.snapshotTasks.hasError, isTrue);
    expect(resources.snapshotTasks.errorMessage, 'Not authorized');
  });

  test('treats a runtime missing WebShare method as unavailable', () async {
    final resources = await ServerResourcesRepository(
      _FakeClient(
        const {},
        failures: {
          'sharing.webshare.query': const TrueNasRpcException(
            code: -32601,
            message: 'Method does not exist',
          ),
        },
      ),
    ).load();

    expect(resources.webShares.items, isEmpty);
    expect(resources.webShares.error?.code, DataMessageCode.methodUnavailable);
    expect(
      resources.webShares.errorMessage,
      'sharing.webshare.query is not available on this TrueNAS version.',
    );
  });

  test('reads disk temperatures for the disks it found', () async {
    final client = _FakeClient({
      'disk.query': [
        {'name': 'sda', 'identifier': 'a'},
        {'name': 'nvme0n1', 'identifier': 'b'},
      ],
      'disk.temperatures': {'sda': 34, 'nvme0n1': 41},
    });
    final repository = ServerResourcesRepository(client);

    final resources = await repository.load();

    // The device names must come from the inventory: an empty list would make
    // the server poll every disk it knows about.
    expect(client.paramsFor('disk.temperatures'), [
      ['sda', 'nvme0n1'],
    ]);
    expect(resources.diskTemperatures.forDisk('sda')?.celsius, 34);
    expect(resources.diskTemperatures.forDisk('nvme0n1')?.celsius, 41);
  });

  test('treats an unreadable drive as unknown rather than cold', () async {
    final repository = ServerResourcesRepository(
      _FakeClient({
        'disk.query': [
          {'name': 'sda', 'identifier': 'a'},
        ],
        'disk.temperatures': {'sda': null},
      }),
    );

    final resources = await repository.load();

    final reading = resources.diskTemperatures.forDisk('sda');
    expect(reading, isNotNull);
    expect(reading!.isKnown, isFalse);
    // 0 would render as a very cold disk instead of "unavailable".
    expect(reading.celsius, isNull);
  });

  test('accepts a per-drive object carrying thresholds', () async {
    final repository = ServerResourcesRepository(
      _FakeClient({
        'disk.query': [
          {'name': 'sda', 'identifier': 'a'},
        ],
        'disk.temperatures': {
          'sda': {'temperature': 58, 'critical': 60, 'maximum': 55},
        },
      }),
    );

    final resources = await repository.load();

    final reading = resources.diskTemperatures.forDisk('sda')!;
    expect(reading.celsius, 58);
    expect(reading.maximum, 55);
    expect(reading.critical, 60);
    // Thresholds are per-drive, so the warning is relative, not a fixed number.
    expect(reading.isOverMaximum, isTrue);
    expect(reading.isCritical, isFalse);
  });

  test('skips the temperature call when no disks were found', () async {
    final client = _RecordingClient();
    final repository = ServerResourcesRepository(client);

    final resources = await repository.load();

    expect(client.calledMethods, isNot(contains('disk.temperatures')));
    expect(resources.diskTemperatures.readings, isEmpty);
    expect(resources.diskTemperatures.hasError, isFalse);
  });

  test('gates temperatures on the discovered API surface', () async {
    final client = _RecordingClient();
    final repository = ServerResourcesRepository(client);

    final resources = await repository.load(
      supportedMethods: const {'disk.query'},
    );

    expect(client.calledMethods, ['disk.query']);
    expect(resources.diskTemperatures.hasError, isTrue);
    expect(
      resources.diskTemperatures.errorMessage,
      'disk.temperatures is not available on this TrueNAS version.',
    );
  });

  test('a failed temperature read keeps the disk inventory', () async {
    final repository = ServerResourcesRepository(
      _FakeClient(
        {
          'disk.query': [
            {'name': 'sda', 'identifier': 'a', 'model': 'Example'},
          ],
        },
        failures: {
          'disk.temperatures': const TrueNasRpcException(
            code: -32001,
            message: 'Not authorized',
          ),
        },
      ),
    );

    final resources = await repository.load();

    expect(resources.disks.items.single.name, 'sda');
    expect(resources.disks.hasError, isFalse);
    expect(resources.diskTemperatures.hasError, isTrue);
    expect(resources.diskTemperatures.errorMessage, 'Not authorized');
  });

  test('rejects a non-map temperature response', () async {
    final repository = ServerResourcesRepository(
      _FakeClient({
        'disk.query': [
          {'name': 'sda', 'identifier': 'a'},
        ],
        'disk.temperatures': const ['34'],
      }),
    );

    final resources = await repository.load();

    expect(resources.diskTemperatures.hasError, isTrue);
    expect(
      resources.diskTemperatures.errorMessage,
      'disk.temperatures returned invalid data.',
    );
  });
}

class _RecordingClient extends TrueNasJsonRpcClient {
  final List<String> calledMethods = [];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calledMethods.add(method);
    return const [];
  }
}

class _FakeClient extends TrueNasJsonRpcClient {
  _FakeClient(this.responses, {this.failures = const {}});

  final Map<String, Object?> responses;
  final Map<String, Object> failures;
  final Map<String, List<Object?>> _params = {};

  List<Object?>? paramsFor(String method) => _params[method];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _params[method] = params;
    final failure = failures[method];
    if (failure != null) throw failure;
    return responses[method] ?? const [];
  }
}
