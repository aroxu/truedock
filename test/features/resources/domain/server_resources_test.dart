import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';

void main() {
  test('parses pool capacity and health', () {
    final pool = StoragePool.fromJson({
      'id': 7,
      'name': 'tank',
      'status': 'ONLINE',
      'size': 1000,
      'allocated': 250,
      'free': 750,
      'fragmentation': '4%',
    });

    expect(pool.name, 'tank');
    expect(pool.usedFraction, .25);
    expect(pool.status, 'ONLINE');
  });

  test('parses nested TrueNAS dataset property values', () {
    final dataset = Dataset.fromJson({
      'id': 'tank/media',
      'name': 'tank/media',
      'type': 'FILESYSTEM',
      'used': {'parsed': 1024},
      'available': {'rawvalue': '2048'},
      'encrypted': true,
      'locked': false,
    });

    expect(dataset.leafName, 'media');
    expect(dataset.depth, 1);
    expect(dataset.usedBytes, 1024);
    expect(dataset.availableBytes, 2048);
    expect(dataset.encrypted, isTrue);
  });

  test('detects a cloned dataset from its origin', () {
    final dataset = Dataset.fromJson({
      'id': 'tank/restored',
      'name': 'tank/restored',
      'type': 'FILESYSTEM',
      'origin': {'parsed': 'tank/media@auto-1'},
    });

    expect(dataset.isClone, isTrue);
    expect(dataset.origin, 'tank/media@auto-1');
  });

  test('an ordinary dataset reports an empty origin, not a clone', () {
    // ZFS returns an empty string here rather than omitting the property, so
    // a plain null check would call every dataset a clone.
    final dataset = Dataset.fromJson({
      'id': 'tank/media',
      'name': 'tank/media',
      'type': 'FILESYSTEM',
      'origin': {'parsed': '', 'rawvalue': ''},
    });

    expect(dataset.isClone, isFalse);
  });

  test('a dataset without an origin property is not a clone', () {
    final dataset = Dataset.fromJson({
      'id': 'tank/media',
      'name': 'tank/media',
      'type': 'FILESYSTEM',
    });

    expect(dataset.isClone, isFalse);
    expect(dataset.origin, isNull);
  });

  test('formats storage values with binary units', () {
    expect(formatBytes(1024), '1.0 KiB');
    expect(formatBytes(10 * 1024 * 1024 * 1024), '10 GiB');
    expect(formatBytes(null), '—');
  });

  test('parses installed app workload resources', () {
    final app = InstalledApp.fromJson({
      'id': 'immich',
      'name': 'Immich',
      'state': 'RUNNING',
      'human_version': '1.0',
      'upgrade_available': false,
      'image_updates_available': false,
      'metadata': {'name': 'immich', 'train': 'stable'},
      'active_workloads': {
        'containers': 1,
        'container_details': [
          {
            'id': 'abc',
            'service_name': 'server',
            'image': 'immich/server',
            'state': 'running',
          },
        ],
        'volumes': [
          {
            'source': '/mnt/tank/photos',
            'destination': '/photos',
            'mode': 'rw',
            'type': 'bind',
          },
        ],
        'networks': [
          {'Name': 'ix-immich'},
        ],
        'used_ports': [
          {
            'container_port': 2283,
            'protocol': 'tcp',
            'host_ports': [
              {'host_port': 2283, 'host_ip': '0.0.0.0'},
            ],
          },
        ],
      },
    });

    expect(app.catalogApp, 'immich');
    expect(app.train, 'stable');
    expect(app.workloads.containerCount, 1);
    expect(app.workloads.volumes.single.source, '/mnt/tank/photos');
    expect(app.workloads.ports.single.hostPort, 2283);
  });

  test('keeps the alert UUID used by dismiss and restore operations', () {
    final alert = SystemAlert.fromJson({
      'id': 'node-a:DiskTemperature',
      'uuid': '3a29234c-c27b-4d83-bb50-57fe909c9a57',
      'level': 'WARNING',
      'text': 'Disk temperature is high.',
      'formatted': 'Disk temperature is <b>high</b>.<br>Check sda.',
      'datetime': {r'$date': 1760000000000},
      'last_occurrence': {r'$date': 1760000060000},
      'dismissed': false,
    });

    expect(alert.id, 'node-a:DiskTemperature');
    expect(alert.uuid, '3a29234c-c27b-4d83-bb50-57fe909c9a57');
    expect(alert.isWarning, isTrue);
    expect(alert.formattedText, contains('Check sda'));
    expect(
      alert.lastOccurredAt,
      DateTime.fromMillisecondsSinceEpoch(1760000060000, isUtc: true),
    );
  });

  test('resolves TrueNAS named alert placeholders from args', () {
    final alert = SystemAlert.fromJson({
      'uuid': 'app-update-alert',
      'level': 'INFO',
      'text':
          'Updates are available for %(count)d application%(plural)s: %(app)s',
      'formatted': '<b>%(count)d application%(plural)s</b>: %(app)s',
      'args': {'count': 2, 'plural': 's', 'app': 'Immich, Syncthing'},
      'dismissed': false,
    });

    expect(
      alert.text,
      'Updates are available for 2 applications: Immich, Syncthing',
    );
    expect(alert.formattedText, '<b>2 applications</b>: Immich, Syncthing');
    expect(alert.arguments['count'], 2);
  });

  test('parses disk inventory and share access details', () {
    final disk = StorageDisk.fromJson({
      'identifier': '{serial}XYZ',
      'name': 'sdb',
      'model': 'Flash Drive',
      'serial': 'XYZ',
      'type': 'SSD',
      'size': 2048,
      'pool': 'tank',
      'rotationrate': 0,
    });
    final share = NfsShare.fromJson({
      'id': 4,
      'path': '/mnt/tank/projects',
      'enabled': true,
      'ro': true,
      'locked': false,
      'networks': ['10.0.0.0/24'],
      'maproot_user': 'nobody',
      'maproot_group': 'nogroup',
      'mapall_user': null,
      'mapall_group': null,
      'security': ['SYS', 'KRB5P'],
      'expose_snapshots': false,
    });

    expect(disk.isSolidState, isTrue);
    expect(disk.pool, 'tank');
    expect(share.readOnly, isTrue);
    expect(share.accessSummary, '10.0.0.0/24');
    expect(share.mapRootUser, 'nobody');
    expect(share.security, ['SYS', 'KRB5P']);
    expect(share.exposeSnapshots, isFalse);
  });

  test('parses SMB common, audit, and purpose-specific configuration', () {
    final share = SmbShare.fromJson({
      'id': 6,
      'name': 'Backups',
      'path': '/mnt/tank/backups',
      'enabled': true,
      'readonly': false,
      'purpose': 'TIMEMACHINE_SHARE',
      'locked': false,
      'comment': 'Mac backups',
      'browsable': true,
      'access_based_share_enumeration': true,
      'audit': {
        'enable': true,
        'watch_list': ['staff'],
        'ignore_list': ['automation'],
      },
      'options': {
        'timemachine_quota': 1024,
        'auto_snapshot': true,
        'auto_dataset_creation': true,
        'dataset_naming_schema': '%U',
        'vuid': 'volume-id',
        'hostsallow': ['10.0.0.0/24'],
        'hostsdeny': [],
      },
    });

    expect(share.comment, 'Mac backups');
    expect(share.accessBasedEnumeration, isTrue);
    expect(share.auditWatchList, ['staff']);
    expect(share.timeMachineQuota, 1024);
    expect(share.autoSnapshot, isTrue);
    expect(share.datasetNamingSchema, '%U');
    expect(share.volumeUuid, 'volume-id');
    expect(share.hostsAllow, ['10.0.0.0/24']);
  });

  test('parses virtual machine runtime and allocation', () {
    final vm = VirtualMachine.fromJson({
      'id': 3,
      'name': 'Linux',
      'status': {'state': 'RUNNING'},
      'vcpus': 1,
      'cores': 4,
      'threads': 2,
      'memory': 8192,
      'autostart': true,
      'display_available': false,
    });

    expect(vm.isRunning, isTrue);
    expect(vm.vcpus * vm.cores * vm.threads, 8);
    expect(vm.memoryMiB, 8192);
  });

  test('distinguishes catalog upgrades from image-only app updates', () {
    final catalogApp = InstalledApp.fromJson({
      'id': 'immich',
      'name': 'Immich',
      'state': 'RUNNING',
      'human_version': '1.0.0',
      'upgrade_available': true,
      'image_updates_available': false,
      'latest_version': '2.0.0',
      'custom_app': false,
    });
    final customApp = InstalledApp.fromJson({
      'id': 'worker',
      'name': 'Worker',
      'state': 'RUNNING',
      'human_version': 'latest',
      'upgrade_available': false,
      'image_updates_available': true,
      'custom_app': true,
    });

    expect(catalogApp.catalogUpgradeAvailable, isTrue);
    expect(catalogApp.latestVersion, '2.0.0');
    expect(customApp.catalogUpgradeAvailable, isFalse);
    expect(customApp.imageUpdatesAvailable, isTrue);
    expect(customApp.upgradeAvailable, isTrue);
  });

  test('parses container inventory without retaining init environment', () {
    final container = ManagedContainer.fromJson({
      'id': 12,
      'uuid': '4af8ef59-2eaa-42b4-b559-26a03cc26bbc',
      'name': 'build-agent',
      'description': 'Ephemeral builder',
      'dataset': 'tank/containers/build-agent',
      'autostart': true,
      'default_network': 'br0',
      'devices': [
        {'id': 1},
        {'id': 2},
      ],
      'status': {'state': 'RUNNING', 'pid': 1234},
      'initenv': {'TOKEN': 'must-not-be-modeled'},
    });

    expect(container.id, 12);
    expect(container.isRunning, isTrue);
    expect(container.deviceCount, 2);
    expect(container.defaultNetwork, 'br0');
    expect(container.toString(), isNot(contains('must-not-be-modeled')));
  });

  test('parses iSCSI and WebShare inventory', () {
    final target = IscsiTarget.fromJson({
      'id': 3,
      'name': 'iqn.2026-08.me.aroxu:media',
      'alias': 'Media target',
      'mode': 'ISCSI',
      'auth_networks': ['10.0.0.0/24', '2001:db8::/64'],
      'rel_tgt_id': 17,
      'iscsi_parameters': {'QueuedCommands': 128},
      'groups': [
        {'portal': 1, 'initiator': 2, 'authmethod': 'CHAP_MUTUAL', 'auth': 3},
      ],
    });
    final extent = IscsiExtent.fromJson({
      'id': 4,
      'name': 'media-zvol',
      'type': 'DISK',
      'disk': 'zvol/tank/media',
      'filesize': '0',
      'blocksize': 4096,
      'serial': 'TD-MEDIA-01',
      'path': '/mnt/tank/extents/media.img',
      'pblocksize': true,
      'avail_threshold': 20,
      'comment': 'Media extent',
      'insecure_tpc': false,
      'xen': true,
      'rpm': '7200',
      'ro': false,
      'enabled': true,
      'locked': false,
      'product_id': 'TRUEDOCK',
    });
    final portal = IscsiPortal.fromJson({
      'id': 6,
      'tag': 12,
      'comment': 'Storage network',
      'listen': [
        {'ip': '10.0.0.10', 'port': 3260},
        {'ip': '2001:db8::10', 'port': 3261},
      ],
    });
    final initiator = IscsiInitiator.fromJson({
      'id': 7,
      'initiators': ['iqn.2026-08.me.aroxu:build-client'],
      'comment': 'Build client',
    });
    final targetExtent = IscsiTargetExtent.fromJson({
      'id': 8,
      'target': 3,
      'extent': 4,
      'lunid': 5,
    });
    final webShare = WebShare.fromJson({
      'id': 5,
      'name': 'Projects',
      'path': '/mnt/tank/projects',
      'enabled': true,
      'locked': false,
    });

    expect(target.alias, 'Media target');
    expect(target.groupCount, 1);
    expect(target.groups.single.portalId, 1);
    expect(target.groups.single.initiatorId, 2);
    expect(target.groups.single.authMethod, 'CHAP_MUTUAL');
    expect(target.groups.single.authId, 3);
    expect(target.authNetworks, ['10.0.0.0/24', '2001:db8::/64']);
    expect(target.relativeTargetId, 17);
    expect(target.queuedCommands, 128);
    expect(extent.id, 4);
    expect(extent.name, 'media-zvol');
    expect(extent.type, 'DISK');
    expect(extent.backingStore, 'zvol/tank/media');
    expect(extent.sizeBytes, 0);
    expect(extent.disk, 'zvol/tank/media');
    expect(extent.blockSize, 4096);
    expect(extent.serial, 'TD-MEDIA-01');
    expect(extent.path, '/mnt/tank/extents/media.img');
    expect(extent.physicalBlockSize, isTrue);
    expect(extent.availableThreshold, 20);
    expect(extent.comment, 'Media extent');
    expect(extent.insecureTpc, isFalse);
    expect(extent.xen, isTrue);
    expect(extent.rpm, '7200');
    expect(extent.readOnly, isFalse);
    expect(extent.enabled, isTrue);
    expect(extent.locked, isFalse);
    expect(extent.productId, 'TRUEDOCK');
    expect(portal.id, 6);
    expect(portal.tag, 12);
    expect(portal.comment, 'Storage network');
    expect(portal.listen.first.ip, '10.0.0.10');
    expect(portal.listen.first.port, 3260);
    expect(portal.addressSummary, '10.0.0.10:3260, 2001:db8::10:3261');
    expect(initiator.id, 7);
    expect(initiator.initiators, ['iqn.2026-08.me.aroxu:build-client']);
    expect(initiator.comment, 'Build client');
    expect(initiator.allowsAll, isFalse);
    expect(targetExtent.id, 8);
    expect(targetExtent.targetId, 3);
    expect(targetExtent.extentId, 4);
    expect(targetExtent.lunId, 5);
    expect(webShare.path, '/mnt/tank/projects');
  });

  test('uses safe iSCSI defaults for optional and missing fields', () {
    final target = IscsiTarget.fromJson({
      'id': 1,
      'name': 'target',
      'groups': [
        {'portal': 4},
      ],
    });
    final portal = IscsiPortal.fromJson({
      'id': 4,
      'tag': 1,
      'listen': [
        {'ip': '0.0.0.0'},
      ],
    });
    final initiator = IscsiInitiator.fromJson({'id': 2});
    final targetExtent = IscsiTargetExtent.fromJson({
      'id': 3,
      'target': 1,
      'extent': 2,
    });

    expect(target.mode, 'ISCSI');
    expect(target.groups.single.authMethod, 'NONE');
    expect(target.groups.single.initiatorId, isNull);
    expect(target.groups.single.authId, isNull);
    expect(portal.comment, isEmpty);
    expect(portal.listen.single.port, 3260);
    expect(initiator.initiators, isEmpty);
    expect(initiator.allowsAll, isTrue);
    expect(targetExtent.lunId, isNull);
  });

  test('parses protection tasks without retaining credential secrets', () {
    final cloud = CloudSyncTask.fromJson({
      'id': 8,
      'description': 'Offsite copy',
      'path': '/mnt/tank/data',
      'direction': 'PUSH',
      'transfer_mode': 'SYNC',
      'enabled': true,
      'credentials': {
        'name': 'Backups',
        'provider': {'type': 'S3', 'access_key_id': 'must-not-be-modeled'},
      },
      'job': {'state': 'SUCCESS'},
    });
    final scrub = ScrubTask.fromJson({
      'id': 2,
      'pool_name': 'tank',
      'enabled': true,
      'threshold': 30,
      'schedule': {'hour': '03', 'minute': '15', 'dow': '7'},
    });
    final rsync = RsyncTask.fromJson({
      'id': 9,
      'path': '/mnt/tank/media',
      'direction': 'PUSH',
      'mode': 'SSH',
      'enabled': true,
      'remotehost': 'backup.local',
      'job': {'state': 'RUNNING'},
    });

    expect(cloud.provider, 'S3');
    expect(cloud.state, 'SUCCESS');
    expect(scrub.schedule, '15 03 * * 7');
    expect(scrub.scheduleHour, '03');
    expect(scrub.scheduleMinute, '15');
    expect(scrub.scheduleDayOfWeek, '7');
    expect(scrub.scheduleAvailable, isTrue);
    expect(rsync.remote, 'backup.local');
    expect(rsync.isRunning, isTrue);
  });

  test('parses periodic snapshot schedule and retention details', () {
    final task = SnapshotTask.fromJson({
      'id': 4,
      'dataset': 'tank/documents',
      'recursive': true,
      'lifetime_value': 2,
      'lifetime_unit': 'WEEK',
      'enabled': true,
      'exclude': ['tank/documents/cache'],
      'naming_schema': 'auto-%Y-%m-%d_%H-%M',
      'allow_empty': false,
      'schedule': {
        'minute': '30',
        'hour': '*/2',
        'dom': '*',
        'month': '*',
        'dow': '1-5',
      },
    });

    expect(task.schedule, '30 */2 * * 1-5');
    expect(task.minute, '30');
    expect(task.hour, '*/2');
    expect(task.begin, '00:00');
    expect(task.end, '23:59');
    expect(task.lifetimeValue, 2);
    expect(task.lifetimeUnit, 'WEEK');
    expect(task.lifetimeLabel, '2 week');
    expect(task.namingSchema, 'auto-%Y-%m-%d_%H-%M');
    expect(task.allowEmpty, isFalse);
    expect(task.excludes, ['tank/documents/cache']);
  });

  test('parses job progress, timing, and abort eligibility', () {
    final running = SystemJob.fromJson({
      'id': 42,
      'method': 'pool.scrub.scrub',
      'state': 'RUNNING',
      'abortable': true,
      'progress': {'percent': 61.5, 'description': 'Scrubbing tank'},
      'time_started': {r'$date': 1760000000000},
      'logs_excerpt': 'scanning tank...',
    });

    expect(running.percent, 61.5);
    expect(running.description, 'Scrubbing tank');
    expect(running.isRunning, isTrue);
    expect(running.canAbort, isTrue);
    expect(
      running.startedAt,
      DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
    );
    expect(running.finishedAt, isNull);
    expect(running.logsExcerpt, 'scanning tank...');
  });

  test('reports terminal job outcomes and duration', () {
    final failed = SystemJob.fromJson({
      'id': 41,
      'method': 'app.upgrade',
      'state': 'FAILED',
      'abortable': true,
      'error': 'Image pull failed.',
      'time_started': {r'$date': 1759999000000},
      'time_finished': {r'$date': 1759999060000},
    });

    expect(failed.hasFailed, isTrue);
    expect(failed.isActive, isFalse);
    // Abortable is meaningless once the job reached a terminal state.
    expect(failed.canAbort, isFalse);
    expect(failed.duration, const Duration(minutes: 1));
  });

  test('accepts bare epoch-second job timestamps', () {
    final job = SystemJob.fromJson({
      'id': 40,
      'method': 'pool.dataset.create',
      'state': 'SUCCESS',
      'time_started': 1759998000,
      'time_finished': 1759998005,
    });

    expect(job.isSuccessful, isTrue);
    expect(
      job.startedAt,
      DateTime.fromMillisecondsSinceEpoch(1759998000000, isUtc: true),
    );
    expect(job.duration, const Duration(seconds: 5));
  });

  test('flattens nested pool topology into leaf members', () {
    final pool = StoragePool.fromJson({
      'id': 1,
      'name': 'tank',
      'status': 'DEGRADED',
      'size': 1000,
      'allocated': 400,
      'topology': {
        'data': [
          {
            'type': 'MIRROR',
            'children': [
              {'guid': '111', 'disk': 'sda', 'status': 'ONLINE'},
              {'guid': '222', 'disk': 'sdb', 'status': 'OFFLINE'},
            ],
          },
        ],
        'cache': [
          {'guid': '333', 'disk': 'nvme0', 'status': 'ONLINE'},
        ],
        'spare': <Object?>[],
      },
    });

    expect(pool.isDegraded, isTrue);
    expect(pool.members, hasLength(3));
    // The mirror itself is not a member; only its leaf disks are.
    expect(pool.members.map((member) => member.name), ['sda', 'sdb', 'nvme0']);
    expect(pool.members.first.label, '111');
    expect(pool.members.first.category, 'data');
    expect(pool.members[1].isOffline, isTrue);
    expect(pool.members.last.category, 'cache');
  });

  test('reads an in-progress scrub from the pool scan', () {
    final pool = StoragePool.fromJson({
      'id': 1,
      'name': 'tank',
      'status': 'ONLINE',
      'scan': {
        'function': 'SCRUB',
        'state': 'SCANNING',
        'percentage': 42.5,
        'errors': 0,
      },
    });

    expect(pool.scan?.isScrub, isTrue);
    expect(pool.scan?.isRunning, isTrue);
    expect(pool.scan?.isPaused, isFalse);
    expect(pool.scan?.percentage, 42.5);
  });

  test('a pool without topology reports no members', () {
    final pool = StoragePool.fromJson({
      'id': 2,
      'name': 'backup',
      'status': 'ONLINE',
    });

    expect(pool.members, isEmpty);
    expect(pool.scan, isNull);
    expect(pool.isHealthy, isTrue);
  });

  test('detects a snapshot hold from the holds map', () {
    final held = SnapshotEntry.fromJson(const {
      'id': 'tank/media@daily',
      'dataset': 'tank/media',
      'snapshot_name': 'daily',
      'createtxg': '4210',
      'holds': {'truenas': 1},
    });
    final free = SnapshotEntry.fromJson(const {
      'id': 'tank/media@hourly',
      'dataset': 'tank/media',
      'snapshot_name': 'hourly',
      'createtxg': '4211',
      'holds': <String, Object?>{},
    });
    final missing = SnapshotEntry.fromJson(const {
      'id': 'tank/media@weekly',
      'dataset': 'tank/media',
      'snapshot_name': 'weekly',
      'createtxg': '4212',
    });

    expect(held.held, isTrue);
    expect(free.held, isFalse);
    // Absent holds must not be treated as a hold.
    expect(missing.held, isFalse);
  });

  test('sorts storage disks in natural device-name order', () {
    StorageDisk disk(String name) => StorageDisk(
      id: name,
      name: name,
      model: 'Test',
      serial: name,
      type: 'HDD',
    );

    final sorted = sortStorageDisksNaturally([
      disk('sdb'),
      disk('nvme10p1'),
      disk('sda'),
      disk('nvme2p1'),
      disk('sdc'),
      disk('nvme1p1'),
    ]);

    expect(sorted.map((disk) => disk.name), [
      'nvme1p1',
      'nvme2p1',
      'nvme10p1',
      'sda',
      'sdb',
      'sdc',
    ]);
  });
}
