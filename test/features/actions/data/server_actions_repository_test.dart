import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/api/truenas_json_rpc_client.dart';
import 'package:true_dock/features/actions/data/server_actions_repository.dart';
import 'package:true_dock/features/connection/domain/server_profile.dart';
import 'package:true_dock/features/data_protection/domain/cloud_backup_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';
import 'package:true_dock/features/system/domain/audit_entry.dart';
import 'package:true_dock/features/system/domain/config_backup.dart';
import 'package:true_dock/features/system/domain/cron_job_configuration.dart';
import 'package:true_dock/features/system/domain/tunable_configuration.dart';
import 'package:true_dock/features/system/domain/mail_configuration.dart';
import 'package:true_dock/features/system/domain/alert_class_configuration.dart';
import 'package:true_dock/features/system/domain/alert_service_configuration.dart';
import 'package:true_dock/features/system/domain/service_configuration.dart';
import 'package:true_dock/features/system/domain/network_configuration.dart';
import 'package:true_dock/features/system/domain/privilege_configuration.dart';
import 'package:true_dock/features/system/domain/virt_instance_configuration.dart';
import 'package:true_dock/features/apps/domain/app_installation.dart';
import 'package:true_dock/features/data_protection/domain/snapshot_task_configuration.dart';
import 'package:true_dock/features/storage/domain/dataset_configuration.dart';
import 'package:true_dock/features/storage/domain/dataset_acl.dart';
import 'package:true_dock/features/storage/domain/iscsi_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_extent_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_auth_configuration.dart';
import 'package:true_dock/features/system/domain/vm_configuration.dart';
import 'package:true_dock/features/system/domain/vm_device.dart';
import 'package:true_dock/features/system/domain/container_configuration.dart';
import 'package:true_dock/features/system/domain/system_general_configuration.dart';
import 'package:true_dock/features/system/domain/static_route_configuration.dart';
import 'package:true_dock/features/system/domain/interface_configuration.dart';
import 'package:true_dock/features/data_protection/domain/replication_configuration.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/rsync_configuration.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_extent_configuration.dart';
import 'package:true_dock/features/storage/domain/nfs_share_configuration.dart';
import 'package:true_dock/features/storage/domain/smb_acl_configuration.dart';
import 'package:true_dock/features/storage/domain/smb_share_configuration.dart';

void main() {
  test('manual update delegates to the authenticated upload pipe', () async {
    final client = _UploadRecordingClient();
    final repository = ServerActionsRepository(client);
    final profile = ServerProfile(
      name: 'Lab NAS',
      baseUri: Uri.parse('https://nas.local'),
    );

    final receipt = await repository.uploadSystemUpdate(
      profile: profile,
      filePath: '/tmp/TrueNAS.update.tar',
      fileName: 'TrueNAS.update.tar',
    );

    expect(client.profile, same(profile));
    expect(client.filePath, '/tmp/TrueNAS.update.tar');
    expect(client.fileName, 'TrueNAS.update.tar');
    expect(receipt.method, 'update.file');
    expect(receipt.jobId, 73);
  });

  test(
    'changes the system update profile with the documented payload',
    () async {
      final client = _RecordingClient(response: null);
      final repository = ServerActionsRepository(client);

      await repository.changeSystemUpdateProfile('EARLY_ADOPTER');

      expect(client.method, 'update.update');
      expect(client.params, [
        {'profile': 'EARLY_ADOPTER'},
      ]);
    },
  );

  test('creates a filesystem dataset with inherited encryption', () async {
    final client = _RecordingClient(response: {'id': 'tank/media'});
    final repository = ServerActionsRepository(client);

    await repository.createDataset(
      fullName: 'tank/media',
      shareType: DatasetShareType.smb,
    );

    expect(client.method, 'pool.dataset.create');
    expect(client.params, [
      {
        'name': 'tank/media',
        'type': 'FILESYSTEM',
        'share_type': 'SMB',
        'inherit_encryption': true,
      },
    ]);
  });

  test('creates an explicitly named recursive snapshot', () async {
    final client = _RecordingClient(response: {'id': 'tank/media@manual'});
    final repository = ServerActionsRepository(client);

    await repository.createSnapshot(
      dataset: 'tank/media',
      name: 'manual',
      recursive: true,
    );

    expect(client.method, 'pool.snapshot.create');
    expect(client.params, [
      {'dataset': 'tank/media', 'name': 'manual', 'recursive': true},
    ]);
  });

  test(
    'creates a periodic snapshot task with its full cron schedule',
    () async {
      final client = _RecordingClient(response: {'id': 12});
      final repository = ServerActionsRepository(client);

      await repository.createSnapshotTask(
        const CreateSnapshotTaskRequest(
          dataset: 'tank/media',
          recursive: false,
          lifetimeValue: 3,
          lifetimeUnit: SnapshotLifetimeUnit.month,
          enabled: true,
          excludes: [],
          namingSchema: 'auto-%Y-%m-%d_%H-%M',
          allowEmpty: true,
          schedule: SnapshotTaskSchedule(hour: '00'),
        ),
      );

      expect(client.method, 'pool.snapshottask.create');
      expect(client.params, [
        {
          'dataset': 'tank/media',
          'recursive': false,
          'lifetime_value': 3,
          'lifetime_unit': 'MONTH',
          'enabled': true,
          'exclude': <String>[],
          'naming_schema': 'auto-%Y-%m-%d_%H-%M',
          'allow_empty': true,
          'schedule': {
            'minute': '00',
            'hour': '00',
            'dom': '*',
            'month': '*',
            'dow': '*',
            'begin': '00:00',
            'end': '23:59',
          },
        },
      ]);
    },
  );

  test('previews, updates, and runs a periodic snapshot task', () async {
    const request = CreateSnapshotTaskRequest(
      dataset: 'tank/media',
      recursive: true,
      lifetimeValue: 1,
      lifetimeUnit: SnapshotLifetimeUnit.month,
      enabled: true,
      excludes: ['tank/media/cache'],
      namingSchema: 'monthly-%Y-%m',
      allowEmpty: false,
      schedule: SnapshotTaskSchedule(hour: '01', dayOfMonth: '1'),
    );
    final impactClient = _RecordingClient(
      response: {
        'will_change': ['tank/media@old'],
      },
    );
    final impactRepository = ServerActionsRepository(impactClient);

    final impact = await impactRepository.inspectSnapshotTaskUpdate(7, request);

    expect(impact.total, 1);
    expect(
      impactClient.method,
      'pool.snapshottask.update_will_change_retention_for',
    );
    expect(impactClient.params, [7, request.toApiJson()]);

    final updateClient = _RecordingClient(response: {'id': 7});
    await ServerActionsRepository(updateClient).updateSnapshotTask(7, request);
    expect(updateClient.method, 'pool.snapshottask.update');
    expect(updateClient.params, [7, request.toApiJson()]);

    final runClient = _RecordingClient(response: 88);
    final receipt = await ServerActionsRepository(runClient).runSnapshotTask(7);
    expect(runClient.method, 'pool.snapshottask.run');
    expect(runClient.params, [7]);
    expect(receipt.jobId, 88);
  });

  test('uses job endpoints for app and service lifecycle', () async {
    final client = _RecordingClient(response: 42);
    final repository = ServerActionsRepository(client);

    final app = await repository.stopApp('plex');
    expect(client.method, 'app.stop');
    expect(client.params, ['plex']);
    expect(app.jobId, 42);

    final service = await repository.controlService(
      service: 'smb',
      verb: ServiceVerb.restart,
    );
    expect(client.method, 'service.control');
    expect(client.params, [
      'RESTART',
      'smb',
      {'silent': false, 'ha_propagate': false, 'timeout': 120},
    ]);
    expect(service.jobId, 42);
  });

  test('persists start-on-boot separately from the run state', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.setServiceStartOnBoot(4, enabled: false);

    // service.control only changes the current run state and is forgotten on
    // reboot, so autostart has to go through service.update, keyed by the
    // record id rather than the service name.
    expect(client.method, 'service.update');
    expect(client.params, [
      4,
      {'enable': false},
    ]);
  });

  test('enabling start-on-boot sends only the enable field', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.setServiceStartOnBoot(9, enabled: true);

    expect(client.method, 'service.update');
    expect(client.params, [
      9,
      {'enable': true},
    ]);
  });

  test('selects a boot environment for the next boot', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.activateBootEnvironment('25.10.1');

    expect(client.method, 'boot.environment.activate');
    expect(client.params, [
      {'id': '25.10.1'},
    ]);
  });

  test('marks a boot environment to survive pruning', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.setBootEnvironmentKept('25.10.1', keep: true);

    expect(client.method, 'boot.environment.keep');
    expect(client.params, [
      {'id': '25.10.1', 'value': true},
    ]);
  });

  test('releases a kept boot environment', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.setBootEnvironmentKept('25.10.1', keep: false);

    expect(client.params, [
      {'id': '25.10.1', 'value': false},
    ]);
  });

  test('destroys a boot environment by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.destroyBootEnvironment('25.10.0');

    expect(client.method, 'boot.environment.destroy');
    expect(client.params, [
      {'id': '25.10.0'},
    ]);
  });

  test('promotes a cloned dataset by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.promoteDataset('tank/restored');

    expect(client.method, 'pool.dataset.promote');
    expect(client.params, ['tank/restored']);
  });

  test('revokes an API key by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteApiKey(4);

    expect(client.method, 'api_key.delete');
    expect(client.params, [4]);
  });

  test('creates a zvol with a byte size and no share type', () async {
    final client = _RecordingClient(response: {'id': 'tank/block'});
    final repository = ServerActionsRepository(client);

    await repository.createVolume(
      fullName: 'tank/block',
      sizeBytes: 10 * 1024 * 1024 * 1024,
    );

    expect(client.method, 'pool.dataset.create');
    // share_type applies only to a filesystem; sending it with a VOLUME is
    // rejected by the server.
    expect(client.params, [
      {
        'name': 'tank/block',
        'type': 'VOLUME',
        'volsize': 10737418240,
        'sparse': false,
        'inherit_encryption': true,
      },
    ]);
  });

  test('a sparse zvol opts into thin provisioning', () async {
    final client = _RecordingClient(response: {'id': 'tank/thin'});
    final repository = ServerActionsRepository(client);

    await repository.createVolume(
      fullName: 'tank/thin',
      sizeBytes: 1024,
      sparse: true,
    );

    expect((client.params!.single as Map)['sparse'], isTrue);
  });

  test('an unset block size stays absent so the server default wins', () async {
    final client = _RecordingClient(response: {'id': 'tank/block'});
    final repository = ServerActionsRepository(client);

    await repository.createVolume(fullName: 'tank/block', sizeBytes: 1024);

    expect((client.params!.single as Map).containsKey('volblocksize'), isFalse);
  });

  test('a chosen block size is sent in the documented K notation', () async {
    final client = _RecordingClient(response: {'id': 'tank/block'});
    final repository = ServerActionsRepository(client);

    await repository.createVolume(
      fullName: 'tank/block',
      sizeBytes: 1024,
      blockSizeBytes: 16 * 1024,
    );

    expect((client.params!.single as Map)['volblocksize'], '16K');
  });

  test('loads presets, prechecks, creates, and updates SMB shares', () async {
    final presetsClient = _RecordingClient(
      response: {
        'DEFAULT_SHARE': {'name': 'Default'},
      },
    );
    final presets = await ServerActionsRepository(
      presetsClient,
    ).getSmbSharePresets();
    expect(presets.single.purpose, SmbSharePurpose.defaultShare);
    expect(presetsClient.method, 'sharing.smb.presets');
    expect(presetsClient.params, isEmpty);

    final precheckClient = _RecordingClient(response: null);
    await ServerActionsRepository(
      precheckClient,
    ).precheckSmbShareName('Projects');
    expect(precheckClient.method, 'sharing.smb.share_precheck');
    expect(precheckClient.params, [
      {'name': 'Projects'},
    ]);

    final createClient = _RecordingClient(response: {'id': 8});
    await ServerActionsRepository(
      createClient,
    ).createSmbShare(_smbConfiguration);
    expect(createClient.method, 'sharing.smb.create');
    expect(createClient.params, [_smbConfiguration.toApiJson()]);

    final updateClient = _RecordingClient(response: {'id': 8});
    await ServerActionsRepository(
      updateClient,
    ).updateSmbShare(8, _smbConfiguration);
    expect(updateClient.method, 'sharing.smb.update');
    expect(updateClient.params, [8, _smbConfiguration.toApiJson()]);
  });

  test('creates and updates NFS shares with documented parameters', () async {
    const configuration = NfsShareConfiguration(
      path: '/mnt/tank/projects',
      comment: 'Projects',
      networks: ['10.0.0.0/24'],
      hosts: [],
      readOnly: false,
      mapRootUser: null,
      mapRootGroup: null,
      mapAllUser: null,
      mapAllGroup: null,
      security: {NfsSecurity.sys},
      enabled: true,
      exposeSnapshots: false,
    );
    final createClient = _RecordingClient(response: {'id': 9});

    await ServerActionsRepository(createClient).createNfsShare(configuration);

    expect(createClient.method, 'sharing.nfs.create');
    expect(createClient.params, [configuration.toApiJson()]);

    final updateClient = _RecordingClient(response: {'id': 9});
    await ServerActionsRepository(
      updateClient,
    ).updateNfsShare(9, configuration);
    expect(updateClient.method, 'sharing.nfs.update');
    expect(updateClient.params, [9, configuration.toApiJson()]);
  });

  test('loads and sorts iSCSI portal listen IP choices', () async {
    final client = _RecordingClient(
      response: {
        '2001:db8::10': 'storage-v6',
        '10.0.0.10': 'storage-v4',
        '0.0.0.0': 'All IPv4 addresses',
      },
    );

    final choices = await ServerActionsRepository(
      client,
    ).getIscsiPortalListenIpChoices();

    expect(client.method, 'iscsi.portal.listen_ip_choices');
    expect(client.params, isEmpty);
    expect(choices, ['0.0.0.0', '10.0.0.10', '2001:db8::10']);
  });

  test('rejects an invalid iSCSI portal listen IP choices response', () async {
    final client = _RecordingClient(response: const ['10.0.0.10']);

    expect(
      ServerActionsRepository(client).getIscsiPortalListenIpChoices(),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('creates and updates iSCSI portals with exact parameters', () async {
    const configuration = IscsiPortalConfiguration(
      listenAddresses: ['10.0.0.10', '2001:db8::10'],
      comment: 'Storage network',
    );
    final createClient = _RecordingClient(response: {'id': 4});

    await ServerActionsRepository(
      createClient,
    ).createIscsiPortal(configuration);

    expect(createClient.method, 'iscsi.portal.create');
    expect(createClient.params, [configuration.toApiJson()]);

    final updateClient = _RecordingClient(response: {'id': 4});
    await ServerActionsRepository(
      updateClient,
    ).updateIscsiPortal(4, configuration);
    expect(updateClient.method, 'iscsi.portal.update');
    expect(updateClient.params, [4, configuration.toApiJson()]);
  });

  test('creates and updates iSCSI initiators with exact parameters', () async {
    const configuration = IscsiInitiatorConfiguration(
      initiators: ['iqn.2026-08.me.aroxu:build-client'],
      comment: 'Build client',
    );
    final createClient = _RecordingClient(response: {'id': 8});

    await ServerActionsRepository(
      createClient,
    ).createIscsiInitiator(configuration);

    expect(createClient.method, 'iscsi.initiator.create');
    expect(createClient.params, [configuration.toApiJson()]);

    final updateClient = _RecordingClient(response: {'id': 8});
    await ServerActionsRepository(
      updateClient,
    ).updateIscsiInitiator(8, configuration);
    expect(updateClient.method, 'iscsi.initiator.update');
    expect(updateClient.params, [8, configuration.toApiJson()]);
  });

  test('validates an available iSCSI target name', () async {
    final client = _RecordingClient(response: null);

    await ServerActionsRepository(
      client,
    ).validateIscsiTargetName('media', existingId: 3);

    expect(client.method, 'iscsi.target.validate_name');
    expect(client.params, ['media', 3]);
  });

  test('reports an iSCSI target name validation error', () async {
    final client = _RecordingClient(response: 'Target name is already in use.');

    expect(
      ServerActionsRepository(client).validateIscsiTargetName('media'),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          'Target name is already in use.',
        ),
      ),
    );
    expect(client.method, 'iscsi.target.validate_name');
    expect(client.params, ['media', null]);
  });

  test('creates and updates iSCSI targets with exact parameters', () async {
    const configuration = IscsiTargetConfiguration(
      name: 'media',
      alias: 'Media target',
      groups: [
        IscsiTargetGroupConfiguration(
          portalId: 4,
          initiatorId: 8,
          authMethod: 'CHAP',
          authId: 12,
        ),
      ],
      authNetworks: ['10.0.0.0/24'],
      queuedCommands: 128,
    );
    const payload = {
      'name': 'media',
      'alias': 'Media target',
      'mode': 'ISCSI',
      'groups': [
        {'portal': 4, 'initiator': 8, 'authmethod': 'CHAP', 'auth': 12},
      ],
      'auth_networks': ['10.0.0.0/24'],
      'iscsi_parameters': {'QueuedCommands': 128},
    };
    final createClient = _RecordingClient(response: {'id': 3});

    await ServerActionsRepository(
      createClient,
    ).createIscsiTarget(configuration);

    expect(createClient.method, 'iscsi.target.create');
    expect(createClient.params, [payload]);

    final updateClient = _RecordingClient(response: {'id': 3});
    await ServerActionsRepository(
      updateClient,
    ).updateIscsiTarget(3, configuration);
    expect(updateClient.method, 'iscsi.target.update');
    expect(updateClient.params, [3, payload]);
  });

  test('loads iSCSI extent disk choices', () async {
    final client = _RecordingClient(
      response: {'zvol/tank/media': 'tank/media', '{serial}ABC': 'sda (SSD)'},
    );

    final choices = await ServerActionsRepository(
      client,
    ).getIscsiExtentDiskChoices();

    expect(client.method, 'iscsi.extent.disk_choices');
    expect(client.params, isEmpty);
    expect(choices, {
      'zvol/tank/media': 'tank/media',
      '{serial}ABC': 'sda (SSD)',
    });
  });

  test('rejects invalid iSCSI extent disk choices', () async {
    final client = _RecordingClient(response: {'zvol/tank/media': 42});

    expect(
      ServerActionsRepository(client).getIscsiExtentDiskChoices(),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('creates and updates iSCSI extents with exact parameters', () async {
    const configuration = IscsiExtentConfiguration(
      name: 'media-zvol',
      type: IscsiExtentType.disk,
      disk: 'zvol/tank/media',
      serial: 'TD-MEDIA-01',
      path: null,
      fileSize: 0,
      blockSize: 4096,
      physicalBlockSize: true,
      availableThreshold: 20,
      comment: 'Media extent',
      insecureTpc: false,
      xen: true,
      rpm: IscsiExtentRpm.ssd,
      readOnly: false,
      enabled: true,
      productId: 'TRUEDOCK',
    );
    const payload = {
      'name': 'media-zvol',
      'type': 'DISK',
      'disk': 'zvol/tank/media',
      'serial': 'TD-MEDIA-01',
      'path': null,
      'filesize': 0,
      'blocksize': 4096,
      'pblocksize': true,
      'avail_threshold': 20,
      'comment': 'Media extent',
      'insecure_tpc': false,
      'xen': true,
      'rpm': 'SSD',
      'ro': false,
      'enabled': true,
      'product_id': 'TRUEDOCK',
    };
    final createClient = _RecordingClient(response: {'id': 4});

    await ServerActionsRepository(
      createClient,
    ).createIscsiExtent(configuration);

    expect(createClient.method, 'iscsi.extent.create');
    expect(createClient.params, [payload]);

    final updateClient = _RecordingClient(response: {'id': 4});
    await ServerActionsRepository(
      updateClient,
    ).updateIscsiExtent(4, configuration);
    expect(updateClient.method, 'iscsi.extent.update');
    expect(updateClient.params, [4, payload]);
  });

  test('creates and updates iSCSI target-extent associations', () async {
    const configuration = IscsiTargetExtentConfiguration(
      targetId: 3,
      extentId: 4,
      lunId: null,
    );
    final createClient = _RecordingClient(response: {'id': 8});

    await ServerActionsRepository(
      createClient,
    ).createIscsiTargetExtent(configuration);

    expect(createClient.method, 'iscsi.targetextent.create');
    expect(createClient.params, [
      {'target': 3, 'extent': 4, 'lunid': null},
    ]);

    final updateClient = _RecordingClient(response: {'id': 8});
    await ServerActionsRepository(
      updateClient,
    ).updateIscsiTargetExtent(8, configuration);
    expect(updateClient.method, 'iscsi.targetextent.update');
    expect(updateClient.params, [
      8,
      {'target': 3, 'extent': 4},
    ]);
  });

  test(
    'installs a catalog app with the documented secret values payload',
    () async {
      final client = _RecordingClient(response: 64);
      final repository = ServerActionsRepository(client);

      final receipt = await repository.installCatalogApp(
        const AppInstallRequest(
          appName: 'immich-family',
          catalogApp: 'immich',
          train: 'stable',
          version: '2.0.0',
          values: {
            'database': {'password': 'not-logged-by-the-model'},
          },
        ),
      );

      expect(client.method, 'app.create');
      expect(client.params, [
        {
          'custom_app': false,
          'values': {
            'database': {'password': 'not-logged-by-the-model'},
          },
          'catalog_app': 'immich',
          'app_name': 'immich-family',
          'train': 'stable',
          'version': '2.0.0',
        },
      ]);
      expect(receipt.jobId, 64);
      expect(receipt.toString(), isNot(contains('not-logged-by-the-model')));
    },
  );

  test('dismisses and restores an alert by UUID', () async {
    final client = _RecordingClient(response: null);
    final repository = ServerActionsRepository(client);

    await repository.setAlertDismissed('alert-uuid', dismissed: true);
    expect(client.method, 'alert.dismiss');
    expect(client.params, ['alert-uuid']);

    await repository.setAlertDismissed('alert-uuid', dismissed: false);
    expect(client.method, 'alert.restore');
    expect(client.params, ['alert-uuid']);
  });

  test(
    'loads an upgrade summary and starts the selected app upgrade',
    () async {
      final summaryClient = _RecordingClient(
        response: {
          'latest_version': '2.0.0',
          'latest_human_version': '2.0.0 release',
          'upgrade_version': '2.0.0',
          'upgrade_human_version': '2.0.0 release',
          'available_versions_for_upgrade': const [],
        },
      );
      final summaryRepository = ServerActionsRepository(summaryClient);

      final summary = await summaryRepository.getAppUpgradeSummary('immich');

      expect(summaryClient.method, 'app.upgrade_summary');
      expect(summaryClient.params, [
        'immich',
        {'app_version': 'latest'},
      ]);
      expect(summary.latestVersion, '2.0.0');

      final upgradeClient = _RecordingClient(response: 73);
      final upgradeRepository = ServerActionsRepository(upgradeClient);
      final receipt = await upgradeRepository.upgradeApp(
        'immich',
        version: '2.0.0',
        snapshotHostPaths: true,
      );

      expect(upgradeClient.method, 'app.upgrade');
      expect(upgradeClient.params, [
        'immich',
        {
          'app_version': '2.0.0',
          'values': <String, Object?>{},
          'snapshot_hostpaths': true,
        },
      ]);
      expect(receipt.jobId, 73);
    },
  );

  test(
    'redeploys an app through the documented single-argument call',
    () async {
      final client = _RecordingClient(response: 88);
      final repository = ServerActionsRepository(client);

      expect((await repository.redeployApp('immich')).jobId, 88);
      expect(client.method, 'app.redeploy');
      expect(client.params, ['immich']);
    },
  );

  test('rolls an app back to a selected target version', () async {
    final client = _RecordingClient(response: 89);
    final repository = ServerActionsRepository(client);

    expect(
      (await repository.rollbackApp('immich', appVersion: '1.4.0')).jobId,
      89,
    );
    expect(client.method, 'app.rollback');
    expect(client.params, [
      'immich',
      {'app_version': '1.4.0'},
    ]);
  });

  // A server that already has mail configured, so a partial update is
  // accepted without re-sending fromemail.
  const configuredMail = MailConfiguration(
    fromEmail: 'nas@example.com',
    fromName: 'NAS',
    outgoingServer: 'smtp.example.com',
    port: 587,
    security: MailSecurity.tls,
  );

  group('audit log', () {
    test('nests filters under hyphenated keys inside one object', () async {
      // audit.query is the one query method that does not take the positional
      // [filters, options] pair: everything goes inside a single object with
      // hyphenated keys, so the shared query helper cannot be reused.
      final client = _RecordingClient(response: <Object?>[]);
      await ServerActionsRepository(
        client,
      ).getAuditEntries(const AuditQuery(limit: 25, username: 'truenas_admin'));
      expect(client.method, 'audit.query');
      expect(client.params, [
        {
          'services': ['MIDDLEWARE'],
          'query-filters': [
            ['username', '=', 'truenas_admin'],
          ],
          'query-options': {
            'limit': 25,
            'order_by': ['-message_timestamp'],
          },
        },
      ]);
    });

    test('filters to failures when asked', () async {
      final client = _RecordingClient(response: <Object?>[]);
      await ServerActionsRepository(
        client,
      ).getAuditEntries(const AuditQuery(onlyFailures: true, limit: 10));
      final payload = client.params!.single as Map;
      expect(payload['query-filters'], [
        ['success', '=', false],
      ]);
    });

    test('parses both timestamp shapes', () async {
      // `timestamp` is wrapped as {"\$date": millis} while `message_timestamp`
      // is bare epoch seconds. The wrapped form is preferred because it carries
      // milliseconds.
      final wrapped = AuditEntry.fromJson({
        'audit_id': 'a',
        'event': 'LOGOUT',
        'success': true,
        'timestamp': {r'\$date': 1786491898000},
        'message_timestamp': 1786491898,
      });
      expect(
        wrapped.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1786491898000, isUtc: true),
      );

      final bare = AuditEntry.fromJson({
        'audit_id': 'b',
        'event': 'LOGOUT',
        'success': true,
        'message_timestamp': 1786491898,
      });
      expect(bare.timestamp?.millisecondsSinceEpoch, 1786491898000);
    });

    test('reads the method and description out of event_data', () async {
      // The interesting content of a METHOD_CALL is nested, not top level.
      final entry = AuditEntry.fromJson({
        'audit_id': 'c',
        'event': 'METHOD_CALL',
        'success': true,
        'username': 'truenas_admin',
        'address': '10.0.0.5',
        'service': 'MIDDLEWARE',
        'event_data': {
          'method': 'audit.download_report',
          'params': [<String, Object?>{}],
          'description': 'Download Audit Data',
          'authenticated': true,
          'authorized': true,
        },
      });
      expect(entry.event, AuditEventKind.methodCall);
      expect(entry.method, 'audit.download_report');
      expect(entry.label, 'Download Audit Data');
      expect(entry.service, AuditService.middleware);
      expect(entry.wasDenied, isFalse);
    });

    test('separates a denial from a plain failure', () async {
      // A refused call is an access-control event, not an error, and reads
      // differently in the log.
      final denied = AuditEntry.fromJson({
        'audit_id': 'd',
        'event': 'METHOD_CALL',
        'success': false,
        'event_data': {'method': 'pool.create', 'authorized': false},
      });
      expect(denied.wasDenied, isTrue);

      final failed = AuditEntry.fromJson({
        'audit_id': 'e',
        'event': 'METHOD_CALL',
        'success': false,
        'event_data': {'method': 'pool.create'},
      });
      expect(failed.wasDenied, isFalse);
      expect(failed.succeeded, isFalse);
    });

    test('falls back to the raw event name it does not model', () async {
      final entry = AuditEntry.fromJson({
        'audit_id': 'f',
        'event': 'SOMETHING_NEW',
        'success': true,
      });
      expect(entry.event, AuditEventKind.other);
      expect(entry.label, 'SOMETHING_NEW');
    });

    test('reads retention and space usage', () async {
      final client = _RecordingClient(
        response: {
          'retention': 7,
          'quota': 0,
          'quota_fill_warning': 75,
          'quota_fill_critical': 95,
          'remote_logging_enabled': false,
          'space': {'used': 962560, 'available': 28681981952},
          'enabled_services': {'MIDDLEWARE': [], 'SMB': [], 'SUDO': []},
        },
      );
      final config = await ServerActionsRepository(
        client,
      ).getAuditConfiguration();
      expect(client.method, 'audit.config');
      expect(config.retentionDays, 7);
      expect(config.isUncapped, isTrue);
      expect(config.usedBytes, 962560);
      expect(config.enabledServices, hasLength(3));
    });

    test('sends only changed retention fields', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateAuditConfiguration(
        const AuditConfigurationEdit(retentionDays: 14),
      );
      expect(client.method, 'audit.update');
      expect(client.params, [
        {'retention': 14},
      ]);
    });

    test('rejects a critical threshold at or below the warning', () async {
      // Both alerts would fire at once, which makes the warning useless.
      expect(
        const AuditConfigurationEdit(
          quotaFillWarning: 80,
          quotaFillCritical: 80,
        ).validate().map((issue) => issue.code),
        contains(AuditValidationCode.fillOrder),
      );
      expect(
        const AuditConfigurationEdit(
          quotaFillWarning: 75,
          quotaFillCritical: 95,
        ).validate(),
        isEmpty,
      );
    });

    test('rejects retention outside the documented range', () async {
      expect(
        const AuditConfigurationEdit(retentionDays: 0).validate().single.code,
        AuditValidationCode.retentionRange,
      );
      expect(
        const AuditConfigurationEdit(retentionDays: 31).validate().single.code,
        AuditValidationCode.retentionRange,
      );
    });
  });

  group('configuration backup', () {
    test('wraps config.save in core.download, buffered', () async {
      // config.save writes to a job pipe a JSON-RPC client cannot read; calling
      // it directly answers "Pipe 'output' is not open". core.download wraps it
      // and returns a tokenized HTTPS path.
      //
      // buffered: true matters: the unbuffered mode blocks the job until a
      // client reads or 60 seconds elapse, and the app hands the URL off rather
      // than reading it itself.
      final client = _RecordingClient(
        response: [1079, '/_download/1079?auth_token=abc123'],
      );
      final download = await ServerActionsRepository(client)
          .prepareConfigBackup(
            options: const ConfigBackupOptions(secretSeed: true),
            filename: 'nas-config-20260812-0100.tar',
          );

      expect(client.method, 'core.download');
      expect(client.params, [
        'config.save',
        [
          {
            'secretseed': true,
            'pool_keys': false,
            'root_authorized_keys': false,
          },
        ],
        'nas-config-20260812-0100.tar',
        true,
      ]);
      expect(download.jobId, 1079);
      expect(download.isTokenized, isTrue);
    });

    test('resolves the download path against the server base', () async {
      // Resolved rather than concatenated, so a server on a non-default port
      // still produces a valid URL.
      const download = ConfigBackupDownload(
        jobId: 1,
        path: '/_download/1?auth_token=abc',
        filename: 'c.tar',
      );
      expect(
        download.resolve(Uri.parse('https://nas.local:8443')).toString(),
        'https://nas.local:8443/_download/1?auth_token=abc',
      );
    });

    test('rejects an unexpected core.download response', () async {
      final client = _RecordingClient(response: 'not-a-pair');
      await expectLater(
        ServerActionsRepository(client).prepareConfigBackup(
          options: const ConfigBackupOptions(),
          filename: 'c.tar',
        ),
        throwsA(isA<TrueNasRpcException>()),
      );
    });

    test('flags an archive that would carry secrets', () async {
      // Each option makes the archive as sensitive as the server's own secrets,
      // so the UI escalates its warning rather than treating them as neutral.
      expect(const ConfigBackupOptions().carriesSecrets, isFalse);
      expect(
        const ConfigBackupOptions(secretSeed: true).carriesSecrets,
        isTrue,
      );
      expect(const ConfigBackupOptions(poolKeys: true).carriesSecrets, isTrue);
      expect(
        const ConfigBackupOptions(rootAuthorizedKeys: true).carriesSecrets,
        isTrue,
      );
    });

    test('builds a dated filename safe for a filesystem', () async {
      final name = const ConfigBackupOptions().suggestedFilename(
        'nas/prod 01',
        DateTime(2026, 8, 12, 1, 5),
      );
      expect(name, 'nas-prod-01-config-20260812-0105.db');
    });

    test('names a plain backup .db and a bundled one .tar', () async {
      // Verified live: without the secret-seed or pool-key options the server
      // sends the SQLite settings database itself, not an archive. Calling that
      // `.tar` would leave the file unopenable by the tool its name implies.
      final stamp = DateTime(2026, 8, 12, 1, 5);
      expect(
        const ConfigBackupOptions().suggestedFilename('nas', stamp),
        endsWith('.db'),
      );
      expect(
        const ConfigBackupOptions(
          secretSeed: true,
        ).suggestedFilename('nas', stamp),
        endsWith('.tar'),
      );
      expect(
        const ConfigBackupOptions(
          poolKeys: true,
        ).suggestedFilename('nas', stamp),
        endsWith('.tar'),
      );
    });

    test('sends the reboot choice explicitly on reset', () async {
      // The server defaults to rebooting, so leaving it out would surprise a
      // caller who chose not to.
      final rebooting = _RecordingClient(response: null);
      await ServerActionsRepository(rebooting).resetConfiguration(reboot: true);
      expect(rebooting.method, 'config.reset');
      expect(rebooting.params, [
        {'reboot': true},
      ]);

      final staying = _RecordingClient(response: null);
      await ServerActionsRepository(staying).resetConfiguration(reboot: false);
      expect(staying.params, [
        {'reboot': false},
      ]);
    });
  });

  group('privileges', () {
    test('keeps group ids and names apart', () async {
      // local_groups is expanded into full group objects on read but takes bare
      // gids on write, so a naive round trip would send objects back.
      final client = _RecordingClient(
        response: [
          {
            'id': 1,
            'builtin_name': 'LOCAL_ADMINISTRATOR',
            'name': 'Local Administrator',
            'roles': ['FULL_ADMIN'],
            'web_shell': true,
            'local_groups': [
              {'id': 40, 'name': 'builtin_administrators'},
            ],
            'ds_groups': <Object?>[],
          },
        ],
      );
      final privileges = await ServerActionsRepository(client).getPrivileges();
      expect(client.method, 'privilege.query');
      final privilege = privileges.single;
      expect(privilege.localGroupIds, [40]);
      expect(privilege.localGroupNames, ['builtin_administrators']);
      expect(privilege.isBuiltin, isTrue);
      expect(privilege.grantsFullAdmin, isTrue);
    });

    test('sends group ids, not group objects', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updatePrivilege(
        1,
        const PrivilegeConfiguration(
          name: 'Operators',
          roles: ['SHARING_ADMIN'],
          localGroupIds: [40, 41],
        ),
      );
      expect(client.method, 'privilege.update');
      expect(client.params!.first, 1);
      expect(client.params!.last, {
        'name': 'Operators',
        'roles': ['SHARING_ADMIN'],
        'web_shell': false,
        'local_groups': [40, 41],
        'ds_groups': <Object?>[],
      });
    });

    test('resolves roles implied by the ones selected', () async {
      // ACCOUNT_WRITE includes ACCOUNT_READ, so a privilege listing only the
      // write role still grants the read role. Showing the literal list would
      // understate what was granted.
      final catalog = [
        PrivilegeRole.fromJson({
          'name': 'ACCOUNT_WRITE',
          'includes': ['ACCOUNT_READ'],
        }),
        PrivilegeRole.fromJson({'name': 'ACCOUNT_READ', 'includes': []}),
        PrivilegeRole.fromJson({'name': 'UNRELATED', 'includes': []}),
      ];
      final privilege = Privilege.fromJson({
        'id': 5,
        'name': 'Accounts',
        'roles': ['ACCOUNT_WRITE'],
        'web_shell': false,
      });
      expect(privilege.effectiveRoles(catalog), {
        'ACCOUNT_WRITE',
        'ACCOUNT_READ',
      });
    });

    test('follows a chain of implied roles without looping', () async {
      // A cyclic catalog must not hang the resolver.
      final catalog = [
        PrivilegeRole.fromJson({
          'name': 'A',
          'includes': ['B'],
        }),
        PrivilegeRole.fromJson({
          'name': 'B',
          'includes': ['C'],
        }),
        PrivilegeRole.fromJson({
          'name': 'C',
          'includes': ['A'],
        }),
      ];
      final privilege = Privilege.fromJson({
        'id': 6,
        'name': 'Cycle',
        'roles': ['A'],
        'web_shell': false,
      });
      expect(privilege.effectiveRoles(catalog), {'A', 'B', 'C'});
    });

    test('treats the web shell as unrestricted access', () async {
      // The shell runs as root, so it bypasses whatever the role list restricts.
      expect(
        const PrivilegeConfiguration(
          name: 'Shell only',
          roles: [],
          webShell: true,
        ).grantsUnrestrictedAccess,
        isTrue,
      );
      expect(
        const PrivilegeConfiguration(
          name: 'Full',
          roles: ['FULL_ADMIN'],
        ).grantsUnrestrictedAccess,
        isTrue,
      );
      expect(
        const PrivilegeConfiguration(
          name: 'Scoped',
          roles: ['SHARING_ADMIN'],
        ).grantsUnrestrictedAccess,
        isFalse,
      );
    });

    test('rejects a privilege that grants nothing', () async {
      // The server accepts it, which makes it look configured while granting
      // nothing at all.
      expect(
        const PrivilegeConfiguration(
          name: 'Empty',
          roles: [],
        ).validate().single.code,
        PrivilegeValidationCode.rolesRequired,
      );
      expect(
        const PrivilegeConfiguration(
          name: '  ',
          roles: ['FULL_ADMIN'],
        ).validate().single.code,
        PrivilegeValidationCode.nameRequired,
      );
    });

    test('reads the role catalog', () async {
      final client = _RecordingClient(
        response: [
          {
            'name': 'ACCOUNT_WRITE',
            'title': 'ACCOUNT_WRITE',
            'includes': ['ACCOUNT_READ'],
            'builtin': true,
          },
        ],
      );
      final roles = await ServerActionsRepository(client).getPrivilegeRoles();
      expect(client.method, 'privilege.roles');
      expect(roles.single.includes, ['ACCOUNT_READ']);
    });
  });

  group('cloud backup', () {
    test('accepts credentials as an id or an expanded object', () async {
      // cloud_backup.create takes `credentials` as an integer, while the query
      // response expands it into an object. Both shapes reach fromJson.
      final fromId = CloudBackupConfiguration.fromJson({
        'path': '/mnt/tank/docs',
        'credentials': 3,
        'keep_last': 7,
      });
      expect(fromId.credentialId, 3);

      final fromObject = CloudBackupConfiguration.fromJson({
        'path': '/mnt/tank/docs',
        'credentials': {'id': 4, 'name': 'Backblaze'},
        'keep_last': 7,
      });
      expect(fromObject.credentialId, 4);
    });

    test('never models the repository password from a read', () async {
      // cloud_backup.query returns `password`, so a field for it would create a
      // leak surface. The editor treats blank as "unchanged" instead.
      final task = CloudBackupTask.fromJson({
        'id': 2,
        'path': '/mnt/tank/docs',
        'credentials': {'id': 4, 'name': 'Backblaze'},
        'keep_last': 7,
        'password': 'should-never-be-modelled',
        'attributes': {'bucket': 'my-bucket', 'folder': 'docs'},
        'schedule': {
          'minute': '0',
          'hour': '2',
          'dom': '*',
          'month': '*',
          'dow': '*',
        },
      });
      expect(task.configuration.password, isEmpty);
      expect(task.configuration.bucket, 'my-bucket');
      expect(task.schedule.hour, '2');
      expect(task.credentialName, 'Backblaze');
    });

    test('substitutes the stored password on an edit', () async {
      // The server requires `password`, so a blank field cannot simply be
      // omitted, and sending an empty string would break the repository.
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).updateCloudBackupTask(
        5,
        const CloudBackupConfiguration(
          path: '/mnt/tank/docs',
          credentialId: 4,
          keepLast: 7,
        ),
        const CloudCredential(id: 4, name: 'B2', provider: 'B2'),
        storedPassword: 'stored-repo-password',
      );
      expect(client.method, 'cloud_backup.update');
      expect(client.params!.first, 5);
      expect((client.params!.last as Map)['password'], 'stored-repo-password');
    });

    test('a typed password wins over the stored one', () async {
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).updateCloudBackupTask(
        5,
        const CloudBackupConfiguration(
          path: '/mnt/tank/docs',
          credentialId: 4,
          keepLast: 7,
          password: 'new-password',
        ),
        const CloudCredential(id: 4, name: 'B2', provider: 'B2'),
        storedPassword: 'stored-repo-password',
      );
      expect((client.params!.last as Map)['password'], 'new-password');
    });

    test('omits the bucket for a bucket-less provider', () async {
      // Reuses CloudCredential.usesBucket, so cloud backup and cloud sync
      // cannot disagree about which providers address a bucket.
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).createCloudBackupTask(
        const CloudBackupConfiguration(
          path: '/mnt/tank/docs',
          credentialId: 9,
          keepLast: 7,
          password: 'p',
          bucket: 'ignored',
          folder: 'docs',
        ),
        const CloudCredential(id: 9, name: 'Drive', provider: 'GOOGLE_DRIVE'),
      );
      final attributes =
          (client.params!.single as Map)['attributes'] as Map<String, Object?>;
      expect(attributes.containsKey('bucket'), isFalse);
      expect(attributes['folder'], 'docs');
    });

    test('sends the bucket for a bucket-based provider', () async {
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).createCloudBackupTask(
        const CloudBackupConfiguration(
          path: '/mnt/tank/docs',
          credentialId: 9,
          keepLast: 7,
          password: 'p',
          bucket: 'my-bucket',
        ),
        const CloudCredential(id: 9, name: 'B2', provider: 'B2'),
      );
      final attributes =
          (client.params!.single as Map)['attributes'] as Map<String, Object?>;
      expect(attributes['bucket'], 'my-bucket');
    });

    test('requires a password on create but not on edit', () async {
      const configuration = CloudBackupConfiguration(
        path: '/mnt/tank/docs',
        credentialId: 4,
        keepLast: 7,
      );
      expect(
        configuration.validate().map((issue) => issue.code),
        contains(CloudBackupValidationCode.passwordRequired),
      );
      expect(configuration.validate(requirePassword: false), isEmpty);
    });

    test('rejects a relative path and a zero retention', () async {
      expect(
        const CloudBackupConfiguration(
          path: 'tank/docs',
          credentialId: 4,
          keepLast: 7,
          password: 'p',
        ).validate().single.code,
        CloudBackupValidationCode.pathNotAbsolute,
      );
      expect(
        const CloudBackupConfiguration(
          path: '/mnt/tank/docs',
          credentialId: 4,
          keepLast: 0,
          password: 'p',
        ).validate().single.code,
        CloudBackupValidationCode.keepLastRange,
      );
    });

    test('runs a backup, with and without a dry run', () async {
      final live = _RecordingClient(response: 11);
      await ServerActionsRepository(live).runCloudBackup(3);
      expect(live.method, 'cloud_backup.sync');
      expect(live.params, [
        3,
        {'dry_run': false},
      ]);

      final dry = _RecordingClient(response: 12);
      await ServerActionsRepository(dry).runCloudBackup(3, dryRun: true);
      expect(dry.params, [
        3,
        {'dry_run': true},
      ]);
    });

    test('restores with all four positional arguments', () async {
      // subfolder is required, not optional: the whole snapshot is "/", not an
      // empty string.
      final client = _RecordingClient(response: 13);
      await ServerActionsRepository(client).restoreCloudBackup(
        taskId: 3,
        snapshotId: 'abc123',
        subfolder: '/',
        destinationPath: '/mnt/tank/restore',
      );
      expect(client.method, 'cloud_backup.restore');
      expect(client.params, [3, 'abc123', '/', '/mnt/tank/restore']);
    });

    test('lists and deletes repository snapshots', () async {
      final list = _RecordingClient(
        response: [
          {
            'id': 'abc123',
            'time': '2026-08-11T02:00:00Z',
            'paths': ['/mnt/tank/docs'],
            'hostname': 'truenas',
          },
        ],
      );
      final snapshots = await ServerActionsRepository(
        list,
      ).getCloudBackupSnapshots(3);
      expect(list.method, 'cloud_backup.list_snapshots');
      expect(snapshots.single.id, 'abc123');
      expect(snapshots.single.time?.year, 2026);

      final delete = _RecordingClient(response: null);
      await ServerActionsRepository(
        delete,
      ).deleteCloudBackupSnapshot(3, 'abc123');
      expect(delete.method, 'cloud_backup.delete_snapshot');
      expect(delete.params, [3, 'abc123']);
    });

    test('aborts a running backup', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).abortCloudBackup(3);
      expect(client.method, 'cloud_backup.abort');
      expect(client.params, [3]);
    });
  });

  group('alert class policies', () {
    test('merges the catalog with the sparse override map', () async {
      // alertclasses.config returns only overridden classes, so a stock server
      // answers with an empty map. Presenting just that would render an empty
      // list while hiding everything an administrator can change.
      final client = _ScriptedClient({
        'alert.list_categories': [
          {
            'id': 'STORAGE',
            'title': 'Storage',
            'classes': [
              {
                'id': 'PoolDegraded',
                'title': 'Pool degraded',
                'level': 'CRITICAL',
              },
              {
                'id': 'ScrubFinished',
                'title': 'Scrub finished',
                'level': 'INFO',
              },
            ],
          },
        ],
        'alertclasses.config': {
          'id': 1,
          'classes': {
            'ScrubFinished': {'level': 'NOTICE', 'policy': 'NEVER'},
          },
        },
      });
      final configuration = await ServerActionsRepository(
        client,
      ).getAlertClasses();

      expect(client.calls.map((call) => call.method), [
        'alert.list_categories',
        'alertclasses.config',
      ]);
      expect(configuration.policies, hasLength(2));

      final degraded = configuration.policies.first;
      expect(degraded.level, AlertLevel.critical);
      // No override means the server default, which for delivery is immediate.
      expect(degraded.policy, AlertPolicy.immediately);
      expect(degraded.overridden, isFalse);
      expect(degraded.differsFromDefault, isFalse);

      final scrub = configuration.policies.last;
      expect(scrub.level, AlertLevel.notice);
      expect(scrub.policy, AlertPolicy.never);
      expect(scrub.isSilenced, isTrue);
      expect(configuration.silenced.map((p) => p.id), ['ScrubFinished']);
      expect(configuration.overriddenCount, 1);
    });

    test('groups classes by category for display', () async {
      final configuration = AlertClassConfiguration.merge(
        definitions: AlertClassConfiguration.parseCategories([
          {
            'id': 'STORAGE',
            'title': 'Storage',
            'classes': [
              {'id': 'A', 'title': 'A', 'level': 'INFO'},
            ],
          },
          {
            'id': 'APPS',
            'title': 'Applications',
            'classes': [
              {'id': 'B', 'title': 'B', 'level': 'WARNING'},
            ],
          },
        ]),
        overrides: const {},
      );
      expect(configuration.byCategory.keys, ['Storage', 'Applications']);
    });

    test('sends only classes that differ from their default', () async {
      // The method replaces the whole override map, so the payload has to carry
      // every override that should survive -- but nothing more, or a stock class
      // would be stored as an override forever.
      final definitions = AlertClassConfiguration.parseCategories([
        {
          'id': 'STORAGE',
          'title': 'Storage',
          'classes': [
            {'id': 'Kept', 'title': 'Kept', 'level': 'INFO'},
            {'id': 'Changed', 'title': 'Changed', 'level': 'INFO'},
          ],
        },
      ]);
      final merged = AlertClassConfiguration.merge(
        definitions: definitions,
        overrides: const {},
      );
      final edited = AlertClassConfiguration(
        policies: [
          merged.policies.first,
          merged.policies.last.copyWith(policy: AlertPolicy.daily),
        ],
      );

      final client = _RecordingClient(response: null);
      await ServerActionsRepository(
        client,
      ).updateAlertClasses(AlertClassEdit.fromConfiguration(edited));

      expect(client.method, 'alertclasses.update');
      expect(client.params, [
        {
          'classes': {
            'Changed': {'level': 'INFO', 'policy': 'DAILY'},
          },
        },
      ]);
    });

    test('a level change alone counts as an override', () async {
      final definitions = AlertClassConfiguration.parseCategories([
        {
          'id': 'STORAGE',
          'title': 'Storage',
          'classes': [
            {'id': 'A', 'title': 'A', 'level': 'INFO'},
          ],
        },
      ]);
      final merged = AlertClassConfiguration.merge(
        definitions: definitions,
        overrides: const {},
      );
      final raised = merged.policies.single.copyWith(
        level: AlertLevel.critical,
      );
      expect(raised.differsFromDefault, isTrue);
      expect(
        AlertClassEdit.fromConfiguration(
          AlertClassConfiguration(policies: [raised]),
        ).toApiJson(),
        {
          'classes': {
            'A': {'level': 'CRITICAL', 'policy': 'IMMEDIATELY'},
          },
        },
      );
    });
  });

  group('alert destinations', () {
    test('nests the type discriminator inside attributes', () async {
      // alertservice.create validates `attributes` against one exact variant,
      // so the type has to travel inside that object rather than beside it.
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).createAlertService(
        const AlertServiceConfiguration(
          name: 'Ops Slack',
          kind: AlertServiceKind.slack,
          level: AlertLevel.critical,
          attributes: {'url': 'https://hooks.slack.com/services/T/B/X'},
        ),
      );
      expect(client.method, 'alertservice.create');
      expect(client.params, [
        {
          'name': 'Ops Slack',
          'level': 'CRITICAL',
          'enabled': true,
          'attributes': {
            'type': 'Slack',
            'url': 'https://hooks.slack.com/services/T/B/X',
          },
        },
      ]);
    });

    test('an edit substitutes the stored credential for a blank field', () async {
      // The editor never prefills a secret, so blank means "unchanged". Omitting
      // it is not an option: alertservice.update rejects the call with
      // "attributes.PagerDuty.service_key: Field required". Verified live, which
      // is how the original omit-the-field design was found to be wrong.
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateAlertService(
        5,
        const AlertServiceConfiguration(
          name: 'Ops PagerDuty',
          kind: AlertServiceKind.pagerDuty,
          level: AlertLevel.error,
          attributes: {'service_key': '', 'client_name': 'truenas'},
        ),
        storedSecrets: const {'service_key': 'stored-key'},
      );
      expect(client.method, 'alertservice.update');
      expect(client.params!.first, 5);
      final attributes =
          (client.params!.last as Map)['attributes'] as Map<String, Object?>;
      expect(attributes['service_key'], 'stored-key');
      expect(attributes['client_name'], 'truenas');
    });

    test('a typed credential wins over the stored one', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateAlertService(
        5,
        const AlertServiceConfiguration(
          name: 'Ops PagerDuty',
          kind: AlertServiceKind.pagerDuty,
          level: AlertLevel.error,
          attributes: {'service_key': 'new-key', 'client_name': 'truenas'},
        ),
        storedSecrets: const {'service_key': 'stored-key'},
      );
      final attributes =
          (client.params!.last as Map)['attributes'] as Map<String, Object?>;
      expect(attributes['service_key'], 'new-key');
    });

    test('a create still sends a typed credential', () async {
      final client = _RecordingClient(response: 2);
      const configuration = AlertServiceConfiguration(
        name: 'Ops PagerDuty',
        kind: AlertServiceKind.pagerDuty,
        level: AlertLevel.error,
        attributes: {'service_key': 'abc123', 'client_name': 'truenas'},
      );
      await ServerActionsRepository(client).createAlertService(configuration);
      final attributes =
          (client.params!.single as Map)['attributes'] as Map<String, Object?>;
      expect(attributes['service_key'], 'abc123');
      expect(configuration.carriesSecret, isTrue);
    });

    test('parses chat ids as integers, not a string', () async {
      // Telegram declares chat_ids as an integer array; sending the raw text
      // would fail validation.
      final client = _RecordingClient(response: 3);
      await ServerActionsRepository(client).createAlertService(
        const AlertServiceConfiguration(
          name: 'Telegram',
          kind: AlertServiceKind.telegram,
          level: AlertLevel.warning,
          attributes: {'bot_token': 't', 'chat_ids': '111, 222'},
        ),
      );
      final attributes =
          (client.params!.single as Map)['attributes'] as Map<String, Object?>;
      expect(attributes['chat_ids'], [111, 222]);
    });

    test('rejects a malformed chat id list and webhook URL', () async {
      expect(
        const AlertServiceConfiguration(
          name: 'Telegram',
          kind: AlertServiceKind.telegram,
          level: AlertLevel.warning,
          attributes: {'bot_token': 't', 'chat_ids': 'abc'},
        ).validate().single.code,
        AlertServiceValidationCode.attributeInvalidInteger,
      );
      expect(
        const AlertServiceConfiguration(
          name: 'Slack',
          kind: AlertServiceKind.slack,
          level: AlertLevel.warning,
          attributes: {'url': 'hooks.slack.com/no-scheme'},
        ).validate().single.code,
        AlertServiceValidationCode.attributeInvalidUrl,
      );
    });

    test('requires the attributes the variant declares', () async {
      final issues = const AlertServiceConfiguration(
        name: 'AWS',
        kind: AlertServiceKind.awsSns,
        level: AlertLevel.warning,
        attributes: {'region': 'us-east-1'},
      ).validate();
      expect(
        issues.map((issue) => issue.field),
        containsAll(<String>[
          'topic_arn',
          'aws_access_key_id',
          'aws_secret_access_key',
        ]),
      );
    });

    test('reads a destination whose type it does not model', () async {
      // The server can hold a destination TrueDock has no editor for; it must
      // still be listed rather than dropped or crashing the parse.
      final entry = AlertServiceEntry.fromJson({
        'id': 9,
        'name': 'Custom',
        'level': 'ALERT',
        'enabled': false,
        'attributes': {'type': 'SomethingNew', 'field': 'value'},
      });
      expect(entry.kind, isNull);
      expect(entry.level, AlertLevel.alert);
      expect(entry.enabled, isFalse);
      expect(entry.attribute('field'), 'value');
    });

    test('tests a destination before it is saved', () async {
      // alertservice.test takes the whole configuration rather than an id, so a
      // wrong webhook can be caught before it is stored.
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).testAlertService(
        const AlertServiceConfiguration(
          name: 'Ops Slack',
          kind: AlertServiceKind.slack,
          level: AlertLevel.warning,
          attributes: {'url': 'https://hooks.slack.com/services/T/B/X'},
        ),
      );
      expect(client.method, 'alertservice.test');
      expect(
        ((client.params!.single as Map)['attributes'] as Map)['type'],
        'Slack',
      );
    });

    test('lists destinations', () async {
      final client = _RecordingClient(
        response: [
          {
            'id': 1,
            'name': 'Ops',
            'level': 'WARNING',
            'enabled': true,
            'attributes': {'type': 'Slack', 'url': 'https://example.invalid'},
          },
        ],
      );
      final services = await ServerActionsRepository(client).getAlertServices();
      expect(client.method, 'alertservice.query');
      expect(services.single.kind, AlertServiceKind.slack);
    });
  });

  group('service configuration', () {
    test('reads a service config from its own namespace', () async {
      final client = _RecordingClient(
        response: {'id': 1, 'tcpport': 22, 'passwordauth': true},
      );
      final config = await ServerActionsRepository(
        client,
      ).getServiceConfiguration(ConfigurableService.ssh);

      expect(client.method, 'ssh.config');
      expect(config.integer('tcpport'), 22);
      expect(config.flag('passwordauth'), isTrue);
    });

    test('SMB is keyed as cifs in the service list', () async {
      // service.query names it `cifs` while the config namespace is `smb`, so
      // matching a row to its editor needs the explicit mapping.
      expect(ConfigurableService.smb.serviceName, 'cifs');
      expect(ConfigurableService.smb.configMethod, 'smb.config');
      expect(ConfigurableService.smb.updateMethod, 'smb.update');
      expect(ConfigurableService.ssh.serviceName, 'ssh');
    });

    test('sends only the changed fields to the right method', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateServiceConfiguration(
        const ServiceConfigurationEdit(
          service: ConfigurableService.nfs,
          changes: {'servers': 8, 'allow_nonroot': true},
        ),
      );
      expect(client.method, 'nfs.update');
      expect(client.params, [
        {'servers': 8, 'allow_nonroot': true},
      ]);
    });

    test('rejects an integer outside the documented range', () async {
      final issues = const ServiceConfigurationEdit(
        service: ConfigurableService.ssh,
        changes: {'tcpport': 70000},
      ).validate();
      expect(issues.single.code, ServiceValidationCode.integerRange);
      expect(issues.single.field, 'tcpport');
      expect(issues.single.maximum, 65535);
    });

    test('allows clearing a nullable port but not a required one', () async {
      // mountd_port is optional, so null unsets it. An SSH port is not.
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.nfs,
          changes: {'mountd_port': null},
        ).validate(),
        isEmpty,
      );
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.ssh,
          changes: {'tcpport': null},
        ).validate().single.code,
        ServiceValidationCode.required,
      );
    });

    test('rejects a choice the schema does not list', () async {
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.smb,
          changes: {'encryption': 'MAYBE'},
        ).validate().single.code,
        ServiceValidationCode.invalidText,
      );
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.smb,
          changes: {'encryption': 'REQUIRED'},
        ).validate(),
        isEmpty,
      );
    });

    test('flags a payload carrying a shared secret', () async {
      // SNMP v1/v2c authenticates with the community string, so an edit that
      // carries it must be treated as secret-bearing.
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.snmp,
          changes: {'community': 'public'},
        ).carriesSecret,
        isTrue,
      );
      expect(
        const ServiceConfigurationEdit(
          service: ConfigurableService.snmp,
          changes: {'location': 'rack 4'},
        ).carriesSecret,
        isFalse,
      );
    });
  });

  group('alert email', () {
    test('never models an SMTP password it cannot read back', () async {
      // mail.config does not return the password, so MailConfiguration has no
      // field for one. Anything that claimed to hold it would be wrong, and
      // would give a log or state dump something to leak.
      final client = _RecordingClient(
        response: {
          'fromemail': 'nas@example.com',
          'fromname': 'NAS',
          'outgoingserver': 'smtp.example.com',
          'port': 587,
          'security': 'TLS',
          'smtp': true,
          'user': 'nas',
          'pass': 'should-never-be-modelled',
          'oauth': <String, Object?>{},
        },
      );
      final config = await ServerActionsRepository(
        client,
      ).getMailConfiguration();

      expect(client.method, 'mail.config');
      expect(config.fromEmail, 'nas@example.com');
      expect(config.security, MailSecurity.tls);
      expect(config.smtpAuthentication, isTrue);
      expect(config.username, 'nas');
      expect(config.usesOauth, isFalse);
      expect(config.isConfigured, isTrue);
      // The model exposes no password surface at all.
      expect(config.toString(), isNot(contains('should-never-be-modelled')));
    });

    test('an untouched password is never resent', () async {
      // Resending the whole object would overwrite the stored password with a
      // blank, because the app never had it to begin with.
      final client = _RecordingClient(response: null);
      const edit = MailConfigurationEdit(port: 465, security: MailSecurity.ssl);
      await ServerActionsRepository(
        client,
      ).updateMailConfiguration(edit, current: configuredMail);

      expect(client.method, 'mail.update');
      expect(client.params, [
        {'port': 465, 'security': 'SSL'},
      ]);
      expect(edit.carriesSecret, isFalse);
    });

    test('a typed password is sent as the schema field name', () async {
      final client = _RecordingClient(response: null);
      const edit = MailConfigurationEdit(username: 'nas', password: 'hunter2');
      await ServerActionsRepository(
        client,
      ).updateMailConfiguration(edit, current: configuredMail);
      expect(client.params, [
        {'user': 'nas', 'pass': 'hunter2'},
      ]);
      expect(edit.carriesSecret, isTrue);
    });

    test('an emptied username clears rather than sends a blank', () async {
      // The schema accepts null for `user`, which is how authentication is
      // detached; sending "" would store an empty username instead.
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateMailConfiguration(
        const MailConfigurationEdit(username: ''),
        current: configuredMail,
      );
      expect(client.params, [
        {'user': null},
      ]);
    });

    test('carries fromemail when the server has none stored', () async {
      // mail.update rejects the whole call with "this field is required" when
      // fromemail is absent and not already set, so a first-time configuration
      // cannot be a pure partial update.
      const unconfigured = MailConfiguration(
        fromEmail: '',
        fromName: '',
        outgoingServer: '',
        port: 25,
        security: MailSecurity.plain,
      );
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateMailConfiguration(
        const MailConfigurationEdit(fromName: 'NAS'),
        current: unconfigured,
      );
      expect(client.params, [
        {'fromname': 'NAS', 'fromemail': ''},
      ]);
    });

    test('omits fromemail once the server already has one', () async {
      final client = _RecordingClient(response: null);
      await ServerActionsRepository(client).updateMailConfiguration(
        const MailConfigurationEdit(fromName: 'NAS'),
        current: configuredMail,
      );
      expect(client.params, [
        {'fromname': 'NAS'},
      ]);
    });

    test('rejects authentication with a username and no password', () async {
      // The server would accept this and then silently fail to authenticate,
      // so alerts would stop arriving with no error anywhere.
      const baseline = MailConfiguration(
        fromEmail: 'nas@example.com',
        fromName: 'NAS',
        outgoingServer: 'smtp.example.com',
        port: 587,
        security: MailSecurity.tls,
      );
      final issues = const MailConfigurationEdit(
        smtpAuthentication: true,
        username: 'nas',
      ).validateAgainst(baseline);
      expect(issues.single.code, MailValidationCode.usernameWithoutPassword);
    });

    test('accepts a blank password when one is already stored', () async {
      // The username was already set, so the server has a password the app
      // cannot see; requiring one here would block every unrelated edit.
      const baseline = MailConfiguration(
        fromEmail: 'nas@example.com',
        fromName: 'NAS',
        outgoingServer: 'smtp.example.com',
        port: 587,
        security: MailSecurity.tls,
        smtpAuthentication: true,
        username: 'nas',
      );
      expect(
        const MailConfigurationEdit(
          fromName: 'Storage',
        ).validateAgainst(baseline),
        isEmpty,
      );
    });

    test('rejects a malformed from address and out-of-range port', () async {
      expect(
        const MailConfigurationEdit(
          fromEmail: 'not-an-address',
        ).validate().single.code,
        MailValidationCode.fromAddressInvalid,
      );
      expect(
        const MailConfigurationEdit(port: 0).validate().single.code,
        MailValidationCode.portRange,
      );
    });

    test('sends a test message through mail.send', () async {
      final client = _RecordingClient(response: 12);
      final receipt = await ServerActionsRepository(
        client,
      ).sendTestMail(subject: 'TrueDock test', body: 'hello');
      expect(client.method, 'mail.send');
      expect(client.params, [
        {'subject': 'TrueDock test', 'text': 'hello'},
      ]);
      expect(receipt.jobId, 12);
    });
  });

  group('cron jobs', () {
    test('inverts the stdout flag, which the API states negatively', () async {
      // `stdout: true` means "suppress stdout from the report". Exposing that
      // verbatim would make the switch mean the opposite of what it reads as,
      // so the domain type stores "capture" and inverts on the wire.
      final client = _RecordingClient(response: 1);
      await ServerActionsRepository(client).createCronJob(
        const CronJobConfiguration(
          command: '/usr/bin/true',
          user: 'root',
          captureStdout: true,
          captureStderr: false,
        ),
      );
      expect(client.method, 'cronjob.create');
      final payload = (client.params!.single as Map)..remove('schedule');
      expect(payload, {
        'command': '/usr/bin/true',
        'user': 'root',
        'description': '',
        'enabled': true,
        'stdout': false,
        'stderr': false,
      });
    });

    test('reads the same inversion back out', () async {
      final job = CronJob.fromJson({
        'id': 4,
        'command': '/usr/bin/true',
        'user': 'root',
        'enabled': true,
        'stdout': true,
        'stderr': true,
        'schedule': {
          'minute': '30',
          'hour': '2',
          'dom': '*',
          'month': '*',
          'dow': '*',
        },
      });
      expect(job.id, 4);
      expect(job.configuration.captureStdout, isFalse);
      expect(job.configuration.captureStderr, isTrue);
      expect(job.schedule.hour, '2');
    });

    test('sends the shared schedule object', () async {
      final client = _RecordingClient(response: 2);
      await ServerActionsRepository(client).updateCronJob(
        7,
        const CronJobConfiguration(
          command: 'zpool scrub tank',
          user: 'root',
          schedule: TaskSchedule(minute: '15', hour: '3'),
        ),
      );
      expect(client.method, 'cronjob.update');
      expect(client.params!.first, 7);
      expect((client.params!.last as Map)['schedule'], {
        'minute': '15',
        'hour': '3',
        'dom': '*',
        'month': '*',
        'dow': '*',
      });
    });

    test('runs a job without skipping a disabled one', () async {
      // skip_disabled defaults to true server-side, which would silently do
      // nothing for a disabled job the user explicitly asked to run.
      final client = _RecordingClient(response: 3);
      await ServerActionsRepository(client).runCronJob(9);
      expect(client.method, 'cronjob.run');
      expect(client.params, [9, false]);
    });

    test('requires a command and a user', () async {
      expect(
        const CronJobConfiguration(
          command: '  ',
          user: 'root',
        ).validate().single.code,
        CronJobValidationCode.commandRequired,
      );
      expect(
        const CronJobConfiguration(
          command: 'ls',
          user: '',
        ).validate().single.code,
        CronJobValidationCode.userRequired,
      );
      expect(
        const CronJobConfiguration(command: 'ls', user: 'root').validate(),
        isEmpty,
      );
    });
  });

  group('system tunables', () {
    test('creates with the exact 25.10 payload', () async {
      final client = _RecordingClient(response: 41);
      final receipt = await ServerActionsRepository(client).createTunable(
        const TunableConfiguration(
          type: TunableType.zfs,
          variable: 'zfs_arc_max',
          value: '1073741824',
          comment: 'ARC limit',
          enabled: true,
          updateInitramfs: false,
        ),
      );

      expect(client.method, 'tunable.create');
      expect(client.params, [
        {
          'type': 'ZFS',
          'var': 'zfs_arc_max',
          'value': '1073741824',
          'comment': 'ARC limit',
          'enabled': true,
          'update_initramfs': false,
        },
      ]);
      expect(receipt.jobId, 41);
    });

    test('updates only mutable fields', () async {
      final client = _RecordingClient(response: true);
      await ServerActionsRepository(client).updateTunable(
        9,
        const TunableConfiguration(
          type: TunableType.sysctl,
          variable: 'kernel.watchdog',
          value: '0',
          comment: 'off',
          enabled: false,
        ),
      );

      expect(client.method, 'tunable.update');
      expect(client.params, [
        9,
        {
          'value': '0',
          'comment': 'off',
          'enabled': false,
          'update_initramfs': true,
        },
      ]);
    });

    test('reads and deletes tunables', () async {
      final queryClient = _RecordingClient(
        response: [
          {'id': 3, 'type': 'SYSCTL', 'var': 'kernel.watchdog', 'value': '0'},
        ],
      );
      final tunables = await ServerActionsRepository(queryClient).getTunables();
      expect(queryClient.method, 'tunable.query');
      expect(tunables.single.id, 3);

      final deleteClient = _RecordingClient(response: true);
      await ServerActionsRepository(deleteClient).deleteTunable(3);
      expect(deleteClient.method, 'tunable.delete');
      expect(deleteClient.params, [3]);
    });
  });

  group('global network configuration', () {
    test('separates configured values from the ones in effect', () async {
      // On DHCP the configured gateway and nameservers are empty strings while
      // the nested state object holds the leased values. Showing only the
      // configured side makes a working server look unconfigured; showing only
      // the effective side makes a lease look like a saved setting.
      final client = _RecordingClient(
        response: {
          'hostname': 'truenas',
          'domain': 'local',
          'ipv4gateway': '',
          'nameserver1': '',
          'nameserver2': '',
          'nameserver3': '',
          'httpproxy': '',
          'domains': <Object?>[],
          'state': {
            'ipv4gateway': '10.24.30.254',
            'nameserver1': '10.24.30.254',
            'nameserver2': '',
            'nameserver3': '',
          },
        },
      );
      final config = await ServerActionsRepository(
        client,
      ).getNetworkConfiguration();

      expect(client.method, 'network.configuration.config');
      expect(config.hostname, 'truenas');
      expect(config.ipv4Gateway, isEmpty);
      expect(config.nameservers, isEmpty);
      expect(config.effective.ipv4Gateway, '10.24.30.254');
      expect(config.effective.nameservers, ['10.24.30.254']);
      expect(config.isDhcpDerived, isTrue);
    });

    test('a statically configured server is not reported as DHCP', () async {
      final client = _RecordingClient(
        response: {
          'hostname': 'nas',
          'domain': '',
          'ipv4gateway': '192.168.1.1',
          'nameserver1': '1.1.1.1',
          'state': {'ipv4gateway': '192.168.1.1', 'nameserver1': '1.1.1.1'},
        },
      );
      final config = await ServerActionsRepository(
        client,
      ).getNetworkConfiguration();
      expect(config.isDhcpDerived, isFalse);
    });

    test('sends only changed fields', () async {
      // The method merges a partial object, so resending everything would
      // rewrite activity and service_announcement, which TrueDock never shows.
      final client = _RecordingClient(response: null);
      const baseline = NetworkConfiguration(
        hostname: 'truenas',
        domain: 'local',
        nameserver1: '1.1.1.1',
      );
      final edit = NetworkConfigurationEdit.diff(
        baseline: baseline,
        hostname: 'truenas',
        domain: 'local',
        ipv4Gateway: '',
        nameserver1: '9.9.9.9',
        nameserver2: '',
        nameserver3: '',
        httpProxy: '',
      );
      await ServerActionsRepository(client).updateNetworkConfiguration(edit);

      expect(client.method, 'network.configuration.update');
      expect(client.params, [
        {'nameserver1': '9.9.9.9'},
      ]);
    });

    test('detects an edit that would cut the route in use', () async {
      // Clearing a leased gateway applies immediately and has no commit window
      // to roll it back, so the UI must escalate to a typed confirmation.
      const baseline = NetworkConfiguration(
        hostname: 'nas',
        domain: '',
        effective: EffectiveNetworkState(
          ipv4Gateway: '10.0.0.1',
          nameservers: ['10.0.0.1'],
        ),
      );
      final clearing = NetworkConfigurationEdit.diff(
        baseline: baseline,
        hostname: 'nas',
        domain: '',
        ipv4Gateway: '',
        nameserver1: '',
        nameserver2: '',
        nameserver3: '',
        httpProxy: '',
      );
      // Nothing differs from the configured baseline, so nothing is sent.
      expect(clearing.isEmpty, isTrue);

      const withGateway = NetworkConfiguration(
        hostname: 'nas',
        domain: '',
        ipv4Gateway: '10.0.0.1',
        effective: EffectiveNetworkState(ipv4Gateway: '10.0.0.1'),
      );
      final cuts = NetworkConfigurationEdit.diff(
        baseline: withGateway,
        hostname: 'nas',
        domain: '',
        ipv4Gateway: '',
        nameserver1: '',
        nameserver2: '',
        nameserver3: '',
        httpProxy: '',
      );
      expect(cuts.clearsEffectiveRouting(withGateway), isTrue);
    });

    test('an empty value is valid because it clears the field', () async {
      // The schema accepts "" for gateways and nameservers as the way to unset
      // them, so a blank field must not be treated as malformed.
      const edit = NetworkConfigurationEdit(ipv4Gateway: '', nameserver1: '');
      expect(edit.validate(), isEmpty);
    });

    test('rejects a malformed gateway, nameserver, and hostname', () async {
      expect(
        const NetworkConfigurationEdit(
          ipv4Gateway: '10.0.0.256',
        ).validate().single.code,
        NetworkValidationCode.gatewayInvalid,
      );
      expect(
        const NetworkConfigurationEdit(
          nameserver1: 'not-an-ip',
        ).validate().single.code,
        NetworkValidationCode.nameserverInvalid,
      );
      expect(
        const NetworkConfigurationEdit(hostname: '').validate().single.code,
        NetworkValidationCode.hostnameRequired,
      );
      expect(
        const NetworkConfigurationEdit(
          hostname: 'bad host',
        ).validate().single.code,
        NetworkValidationCode.hostnameInvalid,
      );
    });

    test('reads the live summary', () async {
      final client = _RecordingClient(
        response: {
          'ips': {
            'ens18': {
              'IPV4': ['10.24.30.81/24'],
              'IPV6': ['fe80::1/64'],
            },
          },
          'default_routes': ['10.24.30.254'],
          'nameservers': ['10.24.30.254'],
        },
      );
      final summary = await ServerActionsRepository(client).getNetworkSummary();
      expect(client.method, 'network.general.summary');
      expect(summary.interfaces['ens18'], ['10.24.30.81/24', 'fe80::1/64']);
      expect(summary.defaultRoutes, ['10.24.30.254']);
      expect(summary.nameservers, ['10.24.30.254']);
    });
  });

  group('virt instances', () {
    test('controls an instance by name with explicit stop options', () async {
      // virt.instance.* is keyed by the instance name, not a numeric id, and
      // stop/restart take an options object. A graceful stop sends a bounded
      // timeout so a wedged guest cannot hang the job; power off forces
      // immediately, where the schema's -1 "no timeout" is meaningful.
      final start = _RecordingClient(response: 1);
      await ServerActionsRepository(
        start,
      ).controlVirtInstance('web', InstanceVerb.start);
      expect(start.method, 'virt.instance.start');
      expect(start.params, ['web']);

      final stop = _RecordingClient(response: 2);
      await ServerActionsRepository(
        stop,
      ).controlVirtInstance('web', InstanceVerb.stop);
      expect(stop.method, 'virt.instance.stop');
      expect(stop.params, [
        'web',
        {'timeout': 90, 'force': false},
      ]);

      final restart = _RecordingClient(response: 3);
      await ServerActionsRepository(
        restart,
      ).controlVirtInstance('web', InstanceVerb.restart);
      expect(restart.method, 'virt.instance.restart');
      expect(restart.params, [
        'web',
        {'timeout': 90, 'force': false},
      ]);

      final powerOff = _RecordingClient(response: 4);
      await ServerActionsRepository(
        powerOff,
      ).controlVirtInstance('web', InstanceVerb.powerOff);
      expect(powerOff.method, 'virt.instance.stop');
      expect(powerOff.params, [
        'web',
        {'timeout': -1, 'force': true},
      ]);
    });

    test('sends only changed fields on update', () async {
      // virt.instance.update merges a partial object, so sending a whole
      // config would overwrite fields the editor does not surface.
      final client = _RecordingClient(response: 5);
      await ServerActionsRepository(client).updateVirtInstance(
        'web',
        const VirtInstanceConfiguration(memoryMiB: 512, autostart: false),
      );
      expect(client.method, 'virt.instance.update');
      expect(client.params, [
        'web',
        {'memory': 512 * 1024 * 1024, 'autostart': false},
      ]);
    });

    test('creates a container instance from a catalog image', () async {
      final client = _RecordingClient(response: 6);
      await ServerActionsRepository(client).createVirtInstance(
        const VirtInstanceCreateConfiguration(
          name: 'web',
          image: 'alpine/3.22/default',
          cpu: '2',
          memoryMiB: 512,
          storagePool: 'tank',
          rootDiskSizeGiB: 10,
        ),
      );
      expect(client.method, 'virt.instance.create');
      expect(client.params, [
        {
          'name': 'web',
          'image': 'alpine/3.22/default',
          'instance_type': 'CONTAINER',
          'source_type': 'IMAGE',
          'autostart': true,
          'cpu': '2',
          'memory': 512 * 1024 * 1024,
          'storage_pool': 'tank',
          'root_disk_size': 10,
        },
      ]);
    });

    test('deletes an instance by name', () async {
      final client = _RecordingClient(response: 7);
      await ServerActionsRepository(client).deleteVirtInstance('web');
      expect(client.method, 'virt.instance.delete');
      expect(client.params, ['web']);
    });

    test('reads the device list', () async {
      final client = _RecordingClient(
        response: [
          {
            'name': 'eth0',
            'dev_type': 'NIC',
            'readonly': true,
            'description': 'incusbr0',
          },
        ],
      );
      final devices = await ServerActionsRepository(
        client,
      ).getVirtInstanceDevices('web');
      expect(client.method, 'virt.instance.device_list');
      expect(devices.single.name, 'eth0');
      expect(devices.single.deviceType, 'NIC');
      expect(devices.single.readOnly, isTrue);
    });

    test('reads the platform state, which gates the whole surface', () async {
      // NO_POOL means no instance can exist yet, and the server returns an
      // empty list in that state, so the UI needs this to tell "not set up"
      // apart from "none created".
      final client = _RecordingClient(
        response: {
          'state': 'NO_POOL',
          'pool': null,
          'storage_pools': <Object?>[],
        },
      );
      final config = await ServerActionsRepository(
        client,
      ).getVirtGlobalConfig();
      expect(client.method, 'virt.global.config');
      expect(config.needsPool, isTrue);
      expect(config.isInitialized, isFalse);
    });

    test('points the platform at a pool', () async {
      final client = _RecordingClient(response: 8);
      await ServerActionsRepository(client).updateVirtStoragePool('tank');
      expect(client.method, 'virt.global.update');
      expect(client.params, [
        {
          'pool': 'tank',
          'storage_pools': ['tank'],
        },
      ]);
    });

    test('requests image choices with the documented remote', () async {
      final client = _RecordingClient(
        response: {
          'alpine/3.22/default': {
            'label': 'Alpine 3.22 (amd64, default)',
            'os': 'Alpine',
            'release': '3.22',
            'variant': 'default',
            'archs': ['amd64'],
            'instance_types': ['CONTAINER'],
          },
        },
      );
      final images = await ServerActionsRepository(
        client,
      ).getVirtImageChoices();
      expect(client.method, 'virt.instance.image_choices');
      expect(client.params, [
        {'remote': 'LINUX_CONTAINERS'},
      ]);
      expect(images.single.id, 'alpine/3.22/default');
      expect(images.single.supportsContainer, isTrue);
    });

    test('rejects an invalid instance name before sending it', () async {
      // Incus derives the guest hostname from the name, so anything that is
      // not a DNS label is rejected by the server with an opaque error.
      final issues = const VirtInstanceCreateConfiguration(
        name: '1-bad_name',
        image: 'alpine/3.22/default',
      ).validate();
      expect(
        issues.map((issue) => issue.code),
        contains(VirtInstanceValidationCode.nameInvalid),
      );
    });

    test('rejects memory below what a guest can boot with', () async {
      final issues = const VirtInstanceConfiguration(memoryMiB: 8).validate();
      expect(issues.single.code, VirtInstanceValidationCode.memoryRange);
      expect(issues.single.bound, virtMinimumMemoryMiB);
    });

    test('accepts a pinned CPU set as well as a core count', () async {
      expect(const VirtInstanceConfiguration(cpu: '0-3').validate(), isEmpty);
      expect(const VirtInstanceConfiguration(cpu: '4').validate(), isEmpty);
      expect(
        const VirtInstanceConfiguration(cpu: 'two').validate().single.code,
        VirtInstanceValidationCode.cpuInvalid,
      );
    });

    test('an untouched editor sends nothing', () async {
      expect(const VirtInstanceConfiguration().isEmpty, isTrue);
    });
  });

  test('sources rollback targets from app.rollback_versions', () async {
    // Not app.upgrade_summary: that method raises
    // "[EFAULT] No upgrade available" once the app is on the newest version,
    // which is exactly when a rollback is wanted. Sourcing the picker from it
    // made rollback unreachable for an up-to-date app.
    final client = _RecordingClient(response: ['1.4.0', '1.3.12']);
    final versions = await ServerActionsRepository(
      client,
    ).getAppRollbackVersions('immich');

    expect(client.method, 'app.rollback_versions');
    expect(client.params, ['immich']);
    expect(versions, ['1.4.0', '1.3.12']);
  });

  test('rejects a non-list rollback version response', () async {
    final client = _RecordingClient(response: {'versions': []});
    await expectLater(
      ServerActionsRepository(client).getAppRollbackVersions('immich'),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('deletes an app keeping volumes and images by default', () async {
    final client = _RecordingClient(response: 90);
    final repository = ServerActionsRepository(client);

    expect(
      (await repository.deleteApp(
        'immich',
        removeImages: false,
        keepVolumes: true,
      )).jobId,
      90,
    );
    expect(client.method, 'app.delete');
    expect(client.params, [
      'immich',
      {
        'remove_images': false,
        'remove_ix_volumes': false,
        'force_remove_ix_volumes': false,
      },
    ]);
  });

  test('deletes an app removing images and named volumes', () async {
    final client = _RecordingClient(response: 91);
    final repository = ServerActionsRepository(client);

    expect(
      (await repository.deleteApp(
        'immich',
        removeImages: true,
        keepVolumes: false,
      )).jobId,
      91,
    );
    expect(client.params, [
      'immich',
      {
        'remove_images': true,
        'remove_ix_volumes': true,
        'force_remove_ix_volumes': true,
      },
    ]);
  });

  test('reconfigures an installed app with a full values object', () async {
    final client = _RecordingClient(response: 77);
    final repository = ServerActionsRepository(client);

    expect(
      (await repository.updateApp(
        'immich',
        values: const {'image_repository': 'immich-app/immich', 'port': 8080},
      )).jobId,
      77,
    );
    expect(client.method, 'app.update');
    expect(client.params, [
      'immich',
      {
        'values': const {'image_repository': 'immich-app/immich', 'port': 8080},
      },
    ]);
  });

  test('reconfigures a custom app with compose configuration', () async {
    final client = _RecordingClient(response: 78);
    final repository = ServerActionsRepository(client);

    await repository.updateApp(
      'custom',
      customComposeConfig: const {
        'services': {
          'web': {'image': 'nginx:2'},
        },
      },
    );

    expect(client.params, [
      'custom',
      {
        'custom_compose_config': {
          'services': {
            'web': {'image': 'nginx:2'},
          },
        },
      },
    ]);
  });

  test('combines bare app config values with installed app metadata', () async {
    final client = _RecordingClient(
      response: {'image_repository': 'immich-app/immich', 'port': 2283},
    );
    final repository = ServerActionsRepository(client);

    final config = await repository.getAppConfig(
      const InstalledApp(
        id: 'immich',
        name: 'Immich',
        state: 'RUNNING',
        version: '1.0.0',
        technicalVersion: '1.0.0',
        catalogUpgradeAvailable: false,
        imageUpdatesAvailable: false,
        catalogApp: 'immich',
        train: 'stable',
      ),
    );

    expect(config.values['port'], 2283);
    expect(config.catalogApp, 'immich');
    expect(config.train, 'stable');
    expect(config.canReconfigure, isTrue);
  });

  test('loads the live app config with catalog reference and values', () async {
    final client = _RecordingClient(
      response: {
        'app_id': 'immich',
        'name': 'immich',
        'catalog_app': 'immich',
        'train': 'stable',
        'app_version': '1.0.0',
        'values': {'image_repository': 'immich-app/immich', 'port': 8080},
      },
    );
    final repository = ServerActionsRepository(client);

    final config = await repository.getAppConfig('immich');
    expect(config.appId, 'immich');
    expect(config.name, 'immich');
    expect(config.catalogApp, 'immich');
    expect(config.train, 'stable');
    expect(config.version, '1.0.0');
    expect(config.values['port'], 8080);
    expect(config.canReconfigure, isTrue);
  });

  test(
    'marks a custom app without a catalog reference as non-reconfigurable',
    () async {
      final client = _RecordingClient(
        response: {
          'app_id': 'custom-app',
          'name': 'custom-app',
          'values': <String, Object?>{},
        },
      );
      final repository = ServerActionsRepository(client);

      final config = await repository.getAppConfig('custom-app');
      expect(config.catalogApp, isNull);
      expect(config.canReconfigure, isFalse);
    },
  );

  test('starts protection jobs with the documented payloads', () async {
    final client = _RecordingClient(response: 91);
    final repository = ServerActionsRepository(client);

    expect((await repository.runReplication(4)).jobId, 91);
    expect(client.method, 'replication.run');
    expect(client.params, [4]);

    await repository.runCloudSync(5, dryRun: true);
    expect(client.method, 'cloudsync.sync');
    expect(client.params, [
      5,
      {'dry_run': true},
    ]);

    await repository.runRsync(6);
    expect(client.method, 'rsynctask.run');
    expect(client.params, [6]);

    await repository.startPoolScrub('tank');
    expect(client.method, 'pool.scrub.scrub');
    expect(client.params, ['tank', 'START']);
  });

  test('aborts a running job by id', () async {
    final client = _RecordingClient(response: null);
    final repository = ServerActionsRepository(client);

    await repository.abortJob(11);

    expect(client.method, 'core.job_abort');
    expect(client.params, [11]);
  });

  test('updates a dataset with only the changed properties', () async {
    final client = _RecordingClient(response: {'id': 'tank/work'});
    final repository = ServerActionsRepository(client);

    await repository.updateDataset('tank/work', const {
      'readonly': 'ON',
      'quota': 'INHERIT',
    });

    expect(client.method, 'pool.dataset.update');
    expect(client.params, [
      'tank/work',
      {'readonly': 'ON', 'quota': 'INHERIT'},
    ]);
  });

  test('renames a dataset as a job', () async {
    final client = _RecordingClient(response: 42);
    final repository = ServerActionsRepository(client);

    final receipt = await repository.renameDataset(
      'tank/projects/work',
      const DatasetRenameRequest(
        newName: 'tank/projects/archive',
        recursive: true,
      ),
    );

    expect(client.method, 'pool.dataset.rename');
    expect(client.params, [
      'tank/projects/work',
      {'new_name': 'tank/projects/archive', 'recursive': true},
    ]);
    expect(receipt.jobId, 42);
  });

  test('maps virtual machine lifecycle verbs to 25.10 methods', () async {
    final client = _RecordingClient(response: 7);
    final repository = ServerActionsRepository(client);

    await repository.controlVirtualMachine(3, InstanceVerb.start);
    expect(client.method, 'vm.start');
    expect(client.params, [3]);

    await repository.controlVirtualMachine(3, InstanceVerb.stop);
    expect(client.method, 'vm.stop');
    expect(client.params, [
      3,
      {'force': false, 'force_after_timeout': false},
    ]);

    await repository.controlVirtualMachine(3, InstanceVerb.restart);
    expect(client.method, 'vm.restart');

    await repository.controlVirtualMachine(3, InstanceVerb.powerOff);
    expect(client.method, 'vm.poweroff');
    expect(client.params, [3]);
  });

  test('maps container lifecycle verbs, forcing only on power off', () async {
    final client = _RecordingClient(response: 8);
    final repository = ServerActionsRepository(client);

    await repository.controlContainer(5, InstanceVerb.start);
    expect(client.method, 'container.start');
    expect(client.params, [5]);

    await repository.controlContainer(5, InstanceVerb.stop);
    expect(client.method, 'container.stop');
    expect(client.params, [
      5,
      {'force': false},
    ]);

    await repository.controlContainer(5, InstanceVerb.powerOff);
    expect(client.method, 'container.stop');
    expect(client.params, [
      5,
      {'force': true},
    ]);
  });

  test('classifies which lifecycle verbs need confirmation', () {
    expect(InstanceVerb.start.isDisruptive, isFalse);
    expect(InstanceVerb.stop.isDisruptive, isTrue);
    expect(InstanceVerb.restart.isDisruptive, isTrue);
    expect(InstanceVerb.powerOff.isDisruptive, isTrue);
  });

  test('updates a user with only the changed fields', () async {
    final client = _RecordingClient(response: 3);
    final repository = ServerActionsRepository(client);

    await repository.updateUser(3, const {'locked': true, 'email': null});

    expect(client.method, 'user.update');
    expect(client.params, [
      3,
      {'locked': true, 'email': null},
    ]);
  });

  test('updates a group membership list', () async {
    final client = _RecordingClient(response: 42);
    final repository = ServerActionsRepository(client);

    await repository.updateGroup(42, const {
      'users': [5, 9],
    });

    expect(client.method, 'group.update');
    expect(client.params, [
      42,
      {
        'users': [5, 9],
      },
    ]);
  });

  test('deletes a dataset with explicit recursive and force flags', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteDataset(
      'tank/projects',
      recursive: true,
      force: true,
    );

    expect(client.method, 'pool.dataset.delete');
    expect(client.params, [
      'tank/projects',
      {'recursive': true, 'force': true},
    ]);
  });

  test('deletes a snapshot without deferring by default', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteSnapshot('tank/media@manual');

    expect(client.method, 'pool.snapshot.delete');
    expect(client.params, [
      'tank/media@manual',
      {'defer': false},
    ]);
  });

  test('maps rollback modes to recursion flags', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.rollbackSnapshot(
      'tank/media@daily',
      mode: SnapshotRollbackMode.newestOnly,
      force: false,
    );
    expect(client.method, 'pool.snapshot.rollback');
    expect(client.params, [
      'tank/media@daily',
      {'recursive': false, 'recursive_clones': false, 'force': false},
    ]);

    await repository.rollbackSnapshot(
      'tank/media@daily',
      mode: SnapshotRollbackMode.newerSnapshots,
      force: false,
    );
    expect(client.params, [
      'tank/media@daily',
      {'recursive': true, 'recursive_clones': false, 'force': false},
    ]);

    await repository.rollbackSnapshot(
      'tank/media@daily',
      mode: SnapshotRollbackMode.newerSnapshotsAndClones,
      force: true,
    );
    expect(client.params, [
      'tank/media@daily',
      {'recursive': true, 'recursive_clones': true, 'force': true},
    ]);
  });

  test('clones a snapshot into a new dataset', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.cloneSnapshot(
      'tank/media@daily',
      datasetDestination: 'tank/restored',
    );

    expect(client.method, 'pool.snapshot.clone');
    expect(client.params, [
      {'snapshot': 'tank/media@daily', 'dataset_dst': 'tank/restored'},
    ]);
  });

  test('deletes SMB and NFS shares by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteSmbShare(4);
    expect(client.method, 'sharing.smb.delete');
    expect(client.params, [4]);

    await repository.deleteNfsShare(6);
    expect(client.method, 'sharing.nfs.delete');
    expect(client.params, [6]);
  });

  test(
    'sends the reason as a positional argument, not an options key',
    () async {
      // 25.10 declares reason as a required positional string. The second
      // argument is the options object and accepts only `delay`, so wrapping the
      // reason in an object is rejected outright.
      final client = _RecordingClient(response: 12);
      final repository = ServerActionsRepository(client);

      await repository.rebootServer(reason: 'Requested from TrueDock');
      expect(client.method, 'system.reboot');
      expect(client.params, ['Requested from TrueDock']);

      await repository.shutdownServer(reason: 'Requested from TrueDock');
      expect(client.method, 'system.shutdown');
      expect(client.params, ['Requested from TrueDock']);
    },
  );

  test('runs an update with an explicit reboot choice', () async {
    final client = _RecordingClient(response: 13);
    final repository = ServerActionsRepository(client);

    await repository.runSystemUpdate(rebootAfter: true);

    expect(client.method, 'update.run');
    expect(client.params, [
      {'reboot': true},
    ]);
  });

  test('maps scrub control verbs to the scrub method', () async {
    final client = _RecordingClient(response: 14);
    final repository = ServerActionsRepository(client);

    await repository.controlPoolScrub('tank', ScrubControlAction.pause);
    expect(client.method, 'pool.scrub.scrub');
    expect(client.params, ['tank', 'PAUSE']);

    await repository.controlPoolScrub('tank', ScrubControlAction.stop);
    expect(client.params, ['tank', 'STOP']);

    await repository.controlPoolScrub('tank', ScrubControlAction.resume);
    expect(client.params, ['tank', 'RESUME']);
  });

  test('exports a pool without destroying data by default', () async {
    final client = _RecordingClient(response: 15);
    final repository = ServerActionsRepository(client);

    await repository.exportPool(
      1,
      destroyData: false,
      takeSnapshotsOffline: true,
    );

    expect(client.method, 'pool.export');
    expect(client.params, [
      1,
      {'cascade': true, 'restart_services': false, 'destroy': false},
    ]);
  });

  test('passes the destroy flag through when wiping a pool', () async {
    final client = _RecordingClient(response: 16);
    final repository = ServerActionsRepository(client);

    await repository.exportPool(
      1,
      destroyData: true,
      takeSnapshotsOffline: true,
    );

    expect((client.params![1]! as Map<String, Object?>)['destroy'], isTrue);
  });

  test('offlines and onlines a pool member by vdev label', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.offlinePoolDisk(1, '1234567890');
    expect(client.method, 'pool.offline');
    expect(client.params, [
      1,
      {'label': '1234567890'},
    ]);

    await repository.onlinePoolDisk(1, '1234567890');
    expect(client.method, 'pool.online');
    expect(client.params, [
      1,
      {'label': '1234567890'},
    ]);
  });

  test('locks a dataset and force-unmounts it', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.lockDataset('tank/secure', forceUmount: true);

    expect(client.method, 'pool.dataset.lock');
    expect(client.params, [
      'tank/secure',
      {'force_umount': true},
    ]);
  });

  test('unlocks a dataset with a passphrase', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.unlockDataset(
      'tank/secure',
      secret: 'correct horse',
      usePassphrase: true,
      unlockChildren: true,
    );

    expect(client.method, 'pool.dataset.unlock');
    expect(client.params, [
      'tank/secure',
      {
        'recursive': true,
        'datasets': [
          {'name': 'tank/secure', 'passphrase': 'correct horse'},
        ],
      },
    ]);
  });

  test('unlocks a dataset with a hex key', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.unlockDataset(
      'tank/secure',
      secret: 'abcdef0123',
      usePassphrase: false,
      unlockChildren: false,
    );

    final params = client.params![1]! as Map<String, Object?>;
    final datasets = params['datasets']! as List<Object?>;
    final entry = datasets.single! as Map<String, Object?>;

    expect(params['recursive'], isFalse);
    // A hex key must be sent as `key`, never as `passphrase`.
    expect(entry['key'], 'abcdef0123');
    expect(entry.containsKey('passphrase'), isFalse);
  });

  test('creates users and groups from validated payloads', () async {
    final client = _RecordingClient(response: 21);
    final repository = ServerActionsRepository(client);

    await repository.createUser(const {'username': 'ada'});
    expect(client.method, 'user.create');
    expect(client.params, [
      {'username': 'ada'},
    ]);

    await repository.createGroup(const {'name': 'engineering'});
    expect(client.method, 'group.create');
    expect(client.params, [
      {'name': 'engineering'},
    ]);
  });

  test('deletes a user and optionally its primary group', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteUser(3, deletePrimaryGroup: true);
    expect(client.method, 'user.delete');
    expect(client.params, [
      3,
      {'delete_group': true},
    ]);

    await repository.deleteUser(3, deletePrimaryGroup: false);
    expect(client.params, [
      3,
      {'delete_group': false},
    ]);
  });

  test('deletes a group without removing its members by default', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteGroup(42, deleteUsers: false);

    expect(client.method, 'group.delete');
    expect(client.params, [
      42,
      {'delete_users': false},
    ]);
  });

  test('changes a user password through user.update', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.changeUserPassword(5, password: 's3cret-passphrase');
    expect(client.method, 'user.update');
    expect(client.params, [
      5,
      {'password': 's3cret-passphrase'},
    ]);
  });

  test('deletes iSCSI portals, initiators, and associations', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteIscsiPortal(2);
    expect(client.method, 'iscsi.portal.delete');
    expect(client.params, [2]);

    await repository.deleteIscsiInitiator(3);
    expect(client.method, 'iscsi.initiator.delete');
    expect(client.params, [3]);

    await repository.deleteIscsiTargetExtent(4, force: true);
    expect(client.method, 'iscsi.targetextent.delete');
    expect(client.params, [4, true]);
  });

  test('deletes an iSCSI target with positional force', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteIscsiTarget(5, force: true);

    expect(client.method, 'iscsi.target.delete');
    expect(client.params, [5, true]);
  });

  test('keeps extent backing storage unless removal is requested', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteIscsiExtent(
      6,
      removeBackingFile: false,
      force: true,
    );
    expect(client.method, 'iscsi.extent.delete');
    expect(client.params, [6, false, true]);

    await repository.deleteIscsiExtent(6, removeBackingFile: true, force: true);
    expect(client.params, [6, true, true]);
  });

  test('holds and releases a snapshot', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.holdSnapshot('tank/media@daily');
    expect(client.method, 'pool.snapshot.hold');
    expect(client.params, ['tank/media@daily']);

    await repository.releaseSnapshot('tank/media@daily');
    expect(client.method, 'pool.snapshot.release');
    expect(client.params, ['tank/media@daily']);
  });

  test('deletes a periodic snapshot task by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteSnapshotTask(7);
    expect(client.method, 'pool.snapshottask.delete');
    expect(client.params, [7]);
  });

  test('deletes a replication task by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteReplicationTask(4);
    expect(client.method, 'replication.delete');
    expect(client.params, [4]);
  });

  test('deletes a cloud sync task by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteCloudSyncTask(5);
    expect(client.method, 'cloudsync.delete');
    expect(client.params, [5]);
  });

  test('deletes an rsync task by id', () async {
    final client = _RecordingClient(response: true);
    final repository = ServerActionsRepository(client);

    await repository.deleteRsyncTask(6);
    expect(client.method, 'rsynctask.delete');
    expect(client.params, [6]);
  });
  // Shapes below are pinned to a live 25.10 server (see
  // tool/live_mutation_probe.dart): the methods are `getacl`/`setacl`, they
  // are keyed by share name, the response wraps `share_acl`, and an entry
  // uses ae_type/ae_perm with ae_who_str or ae_who_sid.
  test('reads and parses the SMB share ACL', () async {
    final client = _RecordingClient(
      response: {
        'share_name': 'projects',
        'share_acl': [
          {
            'ae_who_str': 'alice',
            'ae_who_id': {'id_type': 'USER', 'xid': 1001},
            'ae_type': 'ALLOWED',
            'ae_perm': 'CHANGE',
            'ae_who_sid': 'S-1-5-21-1-2-3-1001',
          },
          {
            'ae_who_str': 'contractors',
            'ae_who_id': {'id_type': 'GROUP', 'xid': 2001},
            'ae_type': 'DENIED',
            'ae_perm': 'READ',
          },
        ],
      },
    );
    final acl = await ServerActionsRepository(
      client,
    ).getSmbShareAcl('projects');

    expect(client.method, 'sharing.smb.getacl');
    expect(client.params, [
      {'share_name': 'projects'},
    ]);
    expect(acl.length, 2);
    expect(acl[0].qualifiedName, 'user:alice');
    expect(acl[0].kind, SmbAclPrincipalKind.user);
    expect(acl[0].permission, SmbSharePermission.change);
    expect(acl[0].permType, SmbAclPermType.allowed);
    expect(acl[1].qualifiedName, 'group:contractors');
    expect(acl[1].kind, SmbAclPrincipalKind.group);
    expect(acl[1].permission, SmbSharePermission.read);
    expect(acl[1].permType, SmbAclPermType.denied);
  });

  test('rejects a non-object SMB share ACL response', () async {
    final client = _RecordingClient(response: ['not', 'an object']);

    expect(
      ServerActionsRepository(client).getSmbShareAcl('projects'),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('rejects an SMB share ACL response without share_acl', () async {
    final client = _RecordingClient(response: {'share_name': 'projects'});

    expect(
      ServerActionsRepository(client).getSmbShareAcl('projects'),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('no share_acl list'),
        ),
      ),
    );
  });

  test('replaces the SMB share ACL with the resolved entries', () async {
    final client = _RecordingClient(response: 64);
    const acl = [
      SmbAclEntry(
        qualifiedName: 'user:alice',
        kind: SmbAclPrincipalKind.user,
        permission: SmbSharePermission.full,
        permType: SmbAclPermType.allowed,
        sid: 'S-1-5-21-1-2-3-1001',
      ),
      SmbAclEntry(
        qualifiedName: 'group:contractors',
        kind: SmbAclPrincipalKind.group,
        permission: SmbSharePermission.read,
        permType: SmbAclPermType.denied,
      ),
    ];
    final receipt = await ServerActionsRepository(
      client,
    ).setSmbShareAcl('projects', acl);

    expect(client.method, 'sharing.smb.setacl');
    expect(client.params, [
      {
        'share_name': 'projects',
        'share_acl': [
          // A known SID identifies the principal; otherwise the bare name
          // does, with the display-only user:/group: prefix stripped.
          {
            'ae_type': 'ALLOWED',
            'ae_perm': 'FULL',
            'ae_who_sid': 'S-1-5-21-1-2-3-1001',
          },
          {'ae_type': 'DENIED', 'ae_perm': 'READ', 'ae_who_str': 'contractors'},
        ],
      },
    ]);
    expect(receipt.jobId, 64);
  });
  test('creates a one-way CHAP credential entry', () async {
    final client = _RecordingClient(response: {'id': 9});
    const configuration = IscsiAuthConfiguration(
      tag: 1,
      user: 'alice',
      secret: 's3cret',
      peerUser: '',
      peerSecret: null,
    );

    final receipt = await ServerActionsRepository(client).createIscsiAuth(
      tag: configuration.tag,
      user: configuration.user,
      secret: configuration.secret!,
    );

    expect(client.method, 'iscsi.auth.create');
    expect(client.params, [configuration.toCreateApiJson()]);
    expect(receipt.result, {'id': 9});
  });

  test('creates a mutual CHAP credential entry with peer fields', () async {
    final client = _RecordingClient(response: {'id': 10});
    const configuration = IscsiAuthConfiguration(
      tag: 2,
      user: 'bob',
      secret: 's3cret',
      peerUser: 'target-peer',
      peerSecret: 'peers3cret',
    );

    await ServerActionsRepository(client).createIscsiAuth(
      tag: configuration.tag,
      user: configuration.user,
      secret: configuration.secret!,
      peerUser: configuration.peerUser,
      peerSecret: configuration.peerSecret,
    );

    expect(client.params, [
      {
        'tag': 2,
        'user': 'bob',
        'secret': 's3cret',
        'peeruser': 'target-peer',
        'peersecret': 'peers3cret',
      },
    ]);
  });

  test('updates an entry without rotating secrets', () async {
    final client = _RecordingClient(response: null);
    const configuration = IscsiAuthConfiguration(
      tag: 1,
      user: 'alice',
      secret: null,
      peerUser: '',
      peerSecret: null,
    );

    await ServerActionsRepository(client).updateIscsiAuth(
      9,
      tag: configuration.tag,
      user: configuration.user,
      secret: configuration.secret,
      peerUser: configuration.peerUser,
      peerSecret: configuration.peerSecret,
    );

    expect(client.method, 'iscsi.auth.update');
    expect(client.params, [
      9,
      {'tag': 1, 'user': 'alice'},
    ]);
  });

  test('updates an entry and rotates both secrets', () async {
    final client = _RecordingClient(response: null);

    await ServerActionsRepository(client).updateIscsiAuth(
      9,
      tag: 1,
      user: 'alice',
      secret: 'newsecret',
      peerUser: 'peer',
      peerSecret: 'newpeersecret',
    );

    expect(client.params, [
      9,
      {
        'tag': 1,
        'user': 'alice',
        'secret': 'newsecret',
        'peeruser': 'peer',
        'peersecret': 'newpeersecret',
      },
    ]);
  });

  test('deletes a CHAP credential entry by id', () async {
    final client = _RecordingClient(response: null);

    await ServerActionsRepository(client).deleteIscsiAuth(9);

    expect(client.method, 'iscsi.auth.delete');
    expect(client.params, [9]);
  });
  test('updates a VM with only the changed fields', () async {
    final client = _RecordingClient(response: null);
    final baseline = VmConfiguration.fromVm(
      VirtualMachine.fromJson({
        'id': 1,
        'name': 'media',
        'status': {'state': 'STOPPED'},
        'vcpus': 2,
        'cores': 2,
        'threads': 1,
        'memory': 4096,
        'autostart': true,
      }),
    );
    final next = baseline.copyWith(vcpus: 4, memoryMiB: 8192, autostart: false);

    final receipt = await ServerActionsRepository(
      client,
    ).updateVirtualMachine(1, next: next, baseline: baseline);

    expect(client.method, 'vm.update');
    expect(client.params, [
      1,
      {'vcpus': 4, 'memory': 8192, 'autostart': false},
    ]);
    expect(receipt.result, isNull);
  });

  test('reads VM devices via vm.device.query', () async {
    final client = _RecordingClient(
      response: [
        {
          'id': 7,
          'vm': 1,
          'dtype': 'DISK',
          'attributes': {'path': '/dev/zvol/tank/vm', 'size': 10240},
        },
        {
          'id': 8,
          'vm': 1,
          'dtype': 'NIC',
          'attributes': {'mac': 'aa:bb'},
        },
      ],
    );

    final devices = await ServerActionsRepository(
      client,
    ).getVirtualMachineDevices(1);

    expect(client.method, 'vm.device.query');
    expect(client.params, [
      [1],
    ]);
    expect(devices.length, 2);
    expect(devices[0].type, VmDeviceType.disk);
    expect(devices[1].type, VmDeviceType.nic);
  });

  test('rejects a non-list vm.device.query response', () async {
    final client = _RecordingClient(response: {'not': 'a list'});

    expect(
      ServerActionsRepository(client).getVirtualMachineDevices(1),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('creates a VM device with the vm id', () async {
    final client = _RecordingClient(response: {'id': 9});
    const configuration = VmDeviceConfiguration(
      dtype: VmDeviceType.disk,
      attributes: {'path': '/dev/zvol/tank/vm', 'size': 10240},
    );

    await ServerActionsRepository(
      client,
    ).createVirtualMachineDevice(configuration, 1);

    expect(client.method, 'vm.device.create');
    expect(client.params, [
      {'vm': 1, 'dtype': 'DISK', 'path': '/dev/zvol/tank/vm', 'size': 10240},
    ]);
  });

  test('updates a VM device by id', () async {
    final client = _RecordingClient(response: null);
    const configuration = VmDeviceConfiguration(
      dtype: VmDeviceType.nic,
      attributes: {'mac': '52:54:00:aa:bb:cc'},
    );

    await ServerActionsRepository(
      client,
    ).updateVirtualMachineDevice(7, configuration);

    expect(client.method, 'vm.device.update');
    expect(client.params, [
      7,
      {'dtype': 'NIC', 'mac': '52:54:00:aa:bb:cc'},
    ]);
  });

  test('deletes a VM device by id', () async {
    final client = _RecordingClient(response: null);

    await ServerActionsRepository(client).deleteVirtualMachineDevice(9);

    expect(client.method, 'vm.device.delete');
    expect(client.params, [9]);
  });
  test('updates a container with the full configuration payload', () async {
    final client = _RecordingClient(response: null);
    final config = ContainerConfiguration.fromRawConfig({
      'name': 'plex',
      'description': '',
      'dataset': 'tank/apps/plex',
      'autostart': true,
      'vcpus': 2,
      'memory': 2048,
      'devices': [
        {'type': 'NIC', 'name': 'eth0'},
      ],
      'volumes': [],
      'environment': {'TZ': 'UTC'},
    });

    await ServerActionsRepository(client).updateContainer(7, config);

    expect(client.method, 'container.update');
    expect(client.params, [7, config.toApiJson()]);
  });

  test('reads container device choices as a label map', () async {
    final client = _RecordingClient(
      response: {'eth0': 'Host eth0', 'eth1': 'Host eth1'},
    );

    final choices = await ServerActionsRepository(
      client,
    ).getContainerDeviceChoices();

    expect(client.method, 'container.device_choices');
    expect(choices, {'eth0': 'Host eth0', 'eth1': 'Host eth1'});
  });

  test('rejects a non-map container.device_choices response', () async {
    final client = _RecordingClient(response: const ['eth0']);

    expect(
      ServerActionsRepository(client).getContainerDeviceChoices(),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('reads the full container config by id', () async {
    final client = _RecordingClient(
      response: [
        {'id': 7, 'name': 'plex', 'dataset': 'tank/apps/plex'},
      ],
    );

    final config = await ServerActionsRepository(client).getContainerConfig(7);

    expect(client.method, 'container.query');
    expect(client.params, [
      [],
      {
        'filters': [
          ['id', '=', 7],
        ],
      },
    ]);
    expect(config['name'], 'plex');
  });

  test('rejects an empty container.query response', () async {
    final client = _RecordingClient(response: const []);

    expect(
      ServerActionsRepository(client).getContainerConfig(7),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('reads a POSIX dataset ACL with resolved identities', () async {
    final client = _RecordingClient(
      response: const {
        'path': '/mnt/tank/media',
        'user': 'root',
        'group': 'wheel',
        'uid': 0,
        'gid': 0,
        'acltype': 'POSIX1E',
        'acl': [
          {
            'tag': 'USER_OBJ',
            'perms': {'READ': true, 'WRITE': true, 'EXECUTE': true},
            'default': false,
            'id': -1,
            'who': 'root',
          },
        ],
      },
    );

    final acl = await ServerActionsRepository(
      client,
    ).getDatasetAcl('tank/media');

    expect(client.method, 'filesystem.getacl');
    expect(client.params, ['/mnt/tank/media', true, true]);
    expect(acl.type, DatasetAclType.posix1e);
    expect(acl.entries.single.displayName, 'Owner');
    expect(acl.entries.single.access, DatasetAclAccess.fullControl);
  });

  test('sets a dataset ACL with recursive behavior explicit', () async {
    final client = _ScriptedClient({
      'filesystem.setacl': 44,
      'core.get_jobs': [
        {'id': 44, 'state': 'SUCCESS'},
      ],
    });
    final acl = DatasetAcl.fromJson(const {
      'path': '/mnt/tank/media',
      'uid': 0,
      'gid': 0,
      'acltype': 'NFS4',
      'nfs41_flags': {'protected': true},
      'acl': [
        {
          'tag': 'owner@',
          'type': 'ALLOW',
          'perms': {'BASIC': 'FULL_CONTROL'},
          'flags': {'BASIC': 'INHERIT'},
          'id': -1,
          'who': 'root',
        },
      ],
    });

    await ServerActionsRepository(client).setDatasetAcl(acl, recursive: true);

    expect(client.calls.map((call) => call.method), [
      'filesystem.setacl',
      'core.get_jobs',
    ]);
    final payload = client.calls.first.params.single as Map<String, dynamic>;
    expect(payload['path'], '/mnt/tank/media');
    expect(payload['acltype'], 'NFS4');
    expect(payload['nfs41_flags'], {'protected': true});
    expect((payload['options'] as Map)['recursive'], isTrue);
    expect((payload['options'] as Map)['traverse'], isFalse);
    expect((payload['dacl'] as List).single, {
      'tag': 'owner@',
      'type': 'ALLOW',
      'perms': {'BASIC': 'FULL_CONTROL'},
      'flags': {'BASIC': 'INHERIT'},
      'id': -1,
    });
  });

  test('surfaces the completed setacl job error for presentation', () {
    final client = _ScriptedClient({
      'filesystem.setacl': 45,
      'core.get_jobs': [
        {
          'id': 45,
          'state': 'FAILED',
          'error': 'The specified path is a ZFS pool mountpoint "(/mnt/tank)"',
        },
      ],
    });
    final acl = DatasetAcl.fromJson(const {
      'path': '/mnt/tank',
      'uid': 0,
      'gid': 0,
      'acltype': 'POSIX1E',
      'acl': <Object?>[],
    });

    expect(
      () =>
          ServerActionsRepository(client).setDatasetAcl(acl, recursive: false),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.displayMessage,
          'displayMessage',
          'The specified path is a ZFS pool mountpoint "(/mnt/tank)"',
        ),
      ),
    );
  });

  test('dataset ACL omits a resolved name when an id is present', () {
    final acl = DatasetAcl.fromJson(const {
      'path': '/mnt/tank/media',
      'acltype': 'POSIX1E',
      'acl': [
        {
          'tag': 'USER',
          'perms': {'READ': true, 'WRITE': false, 'EXECUTE': true},
          'default': false,
          'id': 950,
          'who': 'truenas_admin',
        },
      ],
    });

    final entry =
        (acl.toSetApiJson(recursive: false)['dacl'] as List).single as Map;

    expect(entry['id'], 950);
    expect(entry.containsKey('who'), isFalse);
  });

  test('changes the dataset ACL property before cross-type writes', () async {
    final client = _RecordingClient(response: 77);

    await ServerActionsRepository(
      client,
    ).setDatasetAclType('tank/media', DatasetAclType.nfs4);

    expect(client.method, 'pool.dataset.update');
    expect(client.params, [
      'tank/media',
      {'acltype': 'NFSV4', 'aclmode': 'PASSTHROUGH'},
    ]);
  });

  test('reads the general-system config', () async {
    final client = _ScriptedClient({
      'system.general.config': {'description': 'Lab', 'timezone': 'UTC'},
      'network.configuration.config': {'hostname': 'nas01'},
      'system.advanced.config': {'sysloglevel': 'INFO'},
    });

    final config = await ServerActionsRepository(
      client,
    ).getSystemGeneralConfig();

    expect(config['hostname'], 'nas01');
    expect(config['timezone'], 'UTC');
    expect(config['sysloglevel'], 'INFO');
    expect(client.calls.map((call) => call.method), [
      'system.general.config',
      'network.configuration.config',
      'system.advanced.config',
    ]);
  });

  test('rejects a non-map system configuration response', () async {
    final client = _ScriptedClient({
      'system.general.config': const ['not', 'a', 'map'],
      'network.configuration.config': {'hostname': 'nas01'},
      'system.advanced.config': {'sysloglevel': 'INFO'},
    });

    expect(
      ServerActionsRepository(client).getSystemGeneralConfig(),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });

  test('routes general settings to their documented 25.10 methods', () async {
    final client = _ScriptedClient({
      'network.configuration.update': null,
      'system.general.update': null,
      'system.advanced.update': null,
    });
    final baseline = SystemGeneralConfiguration.fromConfig({
      'hostname': 'nas01',
      'description': 'Lab',
      'timezone': 'UTC',
      'sysloglevel': 'INFO',
    });
    final next = baseline.copyWith(
      hostname: 'nas02',
      timezone: 'Asia/Seoul',
      syslogLevel: SystemSyslogLevel.warning,
    );

    await ServerActionsRepository(
      client,
    ).updateSystemGeneralConfig(next: next, baseline: baseline);

    expect(client.calls.map((call) => call.method), [
      'network.configuration.update',
      'system.general.update',
      'system.advanced.update',
    ]);
    expect(client.calls[0].params, [
      {'hostname': 'nas02'},
    ]);
    expect(client.calls[1].params, [
      {'timezone': 'Asia/Seoul'},
    ]);
    expect(client.calls[2].params, [
      {'sysloglevel': 'WARNING'},
    ]);
  });

  test('reads timezone choices as id/label records', () async {
    final client = _RecordingClient(
      response: [
        ['UTC', 'Coordinated Universal Time'],
        ['Asia/Seoul', 'Asia/Seoul'],
      ],
    );

    final choices = await ServerActionsRepository(
      client,
    ).getSystemTimezoneChoices();

    expect(client.method, 'system.general.timezone_choices');
    expect(choices.length, 2);
    expect(choices.first.id, 'UTC');
    expect(choices.first.label, 'Coordinated Universal Time');
    expect(choices.last.id, 'Asia/Seoul');
  });

  test('reads SCALE 25.10 timezone choices object', () async {
    final client = _RecordingClient(
      response: const {
        'Asia/Seoul': 'Asia/Seoul',
        'UTC': 'Coordinated Universal Time',
      },
    );

    final choices = await ServerActionsRepository(
      client,
    ).getSystemTimezoneChoices();

    expect(choices, [
      (id: 'Asia/Seoul', label: 'Asia/Seoul'),
      (id: 'UTC', label: 'Coordinated Universal Time'),
    ]);
  });

  test('reads timezone choices returned as records', () async {
    final client = _RecordingClient(
      response: const [
        {'id': 'Asia/Seoul', 'label': 'Asia/Seoul'},
      ],
    );

    final choices = await ServerActionsRepository(
      client,
    ).getSystemTimezoneChoices();

    expect(choices.single, (id: 'Asia/Seoul', label: 'Asia/Seoul'));
  });

  test('rejects an unsupported timezone choices response', () async {
    final client = _RecordingClient(response: 7);

    expect(
      ServerActionsRepository(client).getSystemTimezoneChoices(),
      throwsA(
        isA<TrueNasRpcException>().having(
          (error) => error.message,
          'message',
          contains('invalid data'),
        ),
      ),
    );
  });
  test('creates a pool with the topology payload', () async {
    final client = _RecordingClient(response: 42);
    final config = PoolConfiguration(
      name: 'tank',
      dataVdevs: const [
        VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
      ],
      cacheVdevs: const [
        VdevSpec(type: VdevType.stripe, disks: ['sdc']),
      ],
      encryption: true,
      dedup: true,
    );

    final receipt = await ServerActionsRepository(client).createPool(config);

    expect(client.method, 'pool.create');
    expect(client.params, [config.toApiJson()]);
    expect(receipt.jobId, 42);
  });

  // Auto-TRIM is not part of the pool.create schema in 25.10; it lives on
  // pool.update. Opting out therefore needs a follow-up call, which this
  // pins so the toggle cannot silently stop applying.
  test('turns auto-TRIM off through pool.update after creating', () async {
    final client = _ScriptedClient({
      'pool.create': 42,
      'pool.query': [
        {'id': 7, 'name': 'tank'},
      ],
      'pool.update': {'id': 7},
    });
    final config = PoolConfiguration(
      name: 'tank',
      dataVdevs: const [
        VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
      ],
      autoTrim: false,
    );

    final receipt = await ServerActionsRepository(client).createPool(config);

    expect(receipt.jobId, 42);
    expect(client.calls.map((c) => c.method), [
      'pool.create',
      'pool.query',
      'pool.update',
    ]);
    expect(client.calls.last.params, [
      7,
      {'autotrim': 'OFF'},
    ]);
  });

  test('leaves auto-TRIM alone when it stays enabled', () async {
    final client = _ScriptedClient({'pool.create': 42});
    final config = PoolConfiguration(
      name: 'tank',
      dataVdevs: const [
        VdevSpec(type: VdevType.mirror, disks: ['sda', 'sdb']),
      ],
    );

    await ServerActionsRepository(client).createPool(config);

    expect(client.calls.map((c) => c.method), ['pool.create']);
  });

  test('creates a static route with the staged payload', () async {
    final client = _RecordingClient(response: {'id': 7});
    const config = StaticRouteConfiguration(
      destination: '192.168.50.0/24',
      gateway: '10.0.0.1',
      description: 'Branch office',
    );

    final receipt = await ServerActionsRepository(
      client,
    ).createStaticRoute(config);

    expect(client.method, 'staticroute.create');
    expect(client.params, [config.toApiJson()]);
    expect(receipt.result, {'id': 7});
  });

  test('updates a static route by id', () async {
    final client = _RecordingClient(response: {'id': 7});
    const config = StaticRouteConfiguration(
      id: 7,
      destination: '192.168.51.0/24',
      gateway: '10.0.0.2',
    );

    final receipt = await ServerActionsRepository(
      client,
    ).updateStaticRoute(7, config);

    expect(client.method, 'staticroute.update');
    expect(client.params, [7, config.toApiJson()]);
    expect(receipt.result, {'id': 7});
  });

  test('deletes a static route by id', () async {
    final client = _RecordingClient(response: null);
    final receipt = await ServerActionsRepository(client).deleteStaticRoute(7);
    expect(client.method, 'staticroute.delete');
    expect(client.params, [7]);
    expect(receipt.jobId, isNull);
  });

  // 25.10 declares interface.commit/checkin/rollback as plain calls returning
  // null, not jobs. The receipt therefore carries no job id, and the commit
  // sheet must drive its own stages rather than watch a job.
  test('commits pending network changes without a job id', () async {
    final client = _RecordingClient(response: null);
    final receipt = await ServerActionsRepository(
      client,
    ).commitInterfaceChanges();
    expect(client.method, 'interface.commit');
    expect(client.params, [
      {'rollback': true, 'checkin_timeout': 60},
    ]);
    expect(receipt.jobId, isNull);
  });

  test('checks in pending network changes', () async {
    final client = _RecordingClient(response: null);
    final receipt = await ServerActionsRepository(
      client,
    ).checkInInterfaceChanges();
    expect(client.method, 'interface.checkin');
    expect(client.params, isEmpty);
    expect(receipt.jobId, isNull);
  });

  test('rolls back pending network changes', () async {
    final client = _RecordingClient(response: null);
    final receipt = await ServerActionsRepository(
      client,
    ).rollbackInterfaceChanges();
    expect(client.method, 'interface.rollback');
    expect(receipt.jobId, isNull);
  });

  test('reads staged network changes from the three 25.10 methods', () async {
    // 25.10 advertises no interface.commit_node; these three reads are what
    // actually exist, and the fields cleared on check-in are the part that can
    // sever the session TrueDock is connected over.
    final client = _ScriptedClient({
      'interface.has_pending_changes': true,
      'interface.checkin_waiting': 42,
      'interface.network_config_to_be_removed': ['ipv4gateway', 'nameserver1'],
    });
    final pending = await ServerActionsRepository(
      client,
    ).getPendingNetworkChanges();
    expect(client.calls.map((call) => call.method), [
      'interface.has_pending_changes',
      'interface.checkin_waiting',
      'interface.network_config_to_be_removed',
    ]);
    expect(pending.hasPendingChanges, isTrue);
    expect(pending.checkInSecondsRemaining, 42);
    expect(pending.isAwaitingCheckIn, isTrue);
    expect(pending.fieldsClearedOnCheckIn, ['ipv4gateway', 'nameserver1']);
    expect(pending.isEmpty, isFalse);
  });

  test('reports an idle network stack as nothing staged', () async {
    final client = _ScriptedClient({
      'interface.has_pending_changes': false,
      'interface.checkin_waiting': null,
      'interface.network_config_to_be_removed': <Object?>[],
    });
    final pending = await ServerActionsRepository(
      client,
    ).getPendingNetworkChanges();
    expect(pending.isEmpty, isTrue);
    expect(pending.isAwaitingCheckIn, isFalse);
    expect(pending.fieldsClearedOnCheckIn, isEmpty);
  });

  test('rejects a non-boolean pending-changes response', () async {
    final client = _ScriptedClient({'interface.has_pending_changes': 'nope'});
    await expectLater(
      ServerActionsRepository(client).getPendingNetworkChanges(),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('commits with an explicit rollback and check-in timeout', () async {
    final client = _RecordingClient(response: null);
    await ServerActionsRepository(
      client,
    ).commitInterfaceChanges(checkInTimeoutSeconds: 90);
    expect(client.method, 'interface.commit');
    expect(client.params, [
      {'rollback': true, 'checkin_timeout': 90},
    ]);
  });

  test('cancels the rollback countdown', () async {
    final client = _RecordingClient(response: null);
    await ServerActionsRepository(client).cancelInterfaceRollback();
    expect(client.method, 'interface.cancel_rollback');
  });

  test('reads SSH credentials filtered to SSH_CREDENTIALS', () async {
    final client = _RecordingClient(
      response: [
        {'id': 3, 'name': 'Offsite', 'type': 'SSH_CREDENTIALS'},
        {'id': 4, 'name': 'Lab', 'type': 'SSH_CREDENTIALS'},
      ],
    );

    final credentials = await ServerActionsRepository(
      client,
    ).getSshCredentials();

    expect(client.method, 'keychaincredential.query');
    expect(client.params, [
      [
        ['type', '=', 'SSH_CREDENTIALS'],
      ],
    ]);
    expect(credentials.map((c) => c.id), [3, 4]);
    expect(credentials.first.name, 'Offsite');
  });

  test('rejects a non-list keychaincredential.query response', () async {
    final client = _RecordingClient(response: const {'id': 1});
    await expectLater(
      ServerActionsRepository(client).getSshCredentials(),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('creates a replication task with the documented payload', () async {
    final client = _RecordingClient(response: {'id': 11});
    const config = ReplicationConfiguration(
      name: 'Nightly offsite',
      direction: ReplicationDirection.push,
      transport: ReplicationTransport.ssh,
      sshCredentialId: 3,
      sourceDatasets: ['tank/media'],
      targetDataset: 'backup/media',
    );

    final receipt = await ServerActionsRepository(
      client,
    ).createReplicationTask(config);

    expect(client.method, 'replication.create');
    expect(client.params, [config.toApiJson()]);
    expect(receipt.result, {'id': 11});
  });

  test('updates a replication task by id', () async {
    final client = _RecordingClient(response: {'id': 11});
    const config = ReplicationConfiguration(
      id: 11,
      name: 'Nightly offsite',
      direction: ReplicationDirection.pull,
      transport: ReplicationTransport.local,
      sourceDatasets: ['tank/media'],
      targetDataset: 'backup/media',
    );

    await ServerActionsRepository(client).updateReplicationTask(11, config);

    expect(client.method, 'replication.update');
    expect(client.params, [11, config.toApiJson()]);
  });

  test('creates an rsync task with the documented payload', () async {
    final client = _RecordingClient(response: {'id': 12});
    const config = RsyncConfiguration(
      path: '/mnt/tank/media',
      user: 'backup',
      direction: RsyncDirection.push,
      mode: RsyncMode.ssh,
      remoteHost: 'offsite.example',
      remotePath: '/srv/media',
      sshCredentialId: 4,
    );

    final receipt = await ServerActionsRepository(
      client,
    ).createRsyncTask(config);

    expect(client.method, 'rsynctask.create');
    expect(client.params, [config.toApiJson()]);
    expect(receipt.result, {'id': 12});
  });

  test('updates an rsync task by id', () async {
    final client = _RecordingClient(response: {'id': 12});
    const config = RsyncConfiguration(
      id: 12,
      path: '/mnt/tank/media',
      user: 'backup',
      direction: RsyncDirection.pull,
      mode: RsyncMode.module,
      remoteHost: 'offsite.example',
      remoteModule: 'media',
    );

    await ServerActionsRepository(client).updateRsyncTask(12, config);

    expect(client.method, 'rsynctask.update');
    expect(client.params, [12, config.toApiJson()]);
  });

  test('reads a single replication task config by id', () async {
    final client = _RecordingClient(
      response: [
        {'id': 11, 'name': 'Nightly offsite', 'direction': 'PUSH'},
      ],
    );

    final config = await ServerActionsRepository(
      client,
    ).getReplicationTaskConfig(11);

    expect(client.method, 'replication.query');
    expect(client.params, [
      [
        ['id', '=', 11],
      ],
    ]);
    expect(config['name'], 'Nightly offsite');
  });

  test('rejects an empty replication.query response', () async {
    final client = _RecordingClient(response: const []);
    await expectLater(
      ServerActionsRepository(client).getReplicationTaskConfig(11),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('reads a single rsync task config by id', () async {
    final client = _RecordingClient(
      response: [
        {'id': 12, 'path': '/mnt/tank/media', 'mode': 'SSH'},
      ],
    );

    final config = await ServerActionsRepository(client).getRsyncTaskConfig(12);

    expect(client.method, 'rsynctask.query');
    expect(config['path'], '/mnt/tank/media');
  });

  test('reads a single interface config by id', () async {
    final client = _RecordingClient(
      response: [
        {'id': 'eno1', 'name': 'eno1', 'ipv4_dhcp': true},
      ],
    );

    final config = await ServerActionsRepository(
      client,
    ).getInterfaceConfig('eno1');

    expect(client.method, 'interface.query');
    expect(client.params, [
      [
        ['id', '=', 'eno1'],
      ],
    ]);
    expect(config['name'], 'eno1');
  });

  test('rejects an empty interface.query response', () async {
    final client = _RecordingClient(response: const []);
    await expectLater(
      ServerActionsRepository(client).getInterfaceConfig('eno1'),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('stages an interface change with the documented payload', () async {
    final client = _RecordingClient(response: {'id': 'eno1'});
    const config = InterfaceConfiguration(
      id: 'eno1',
      name: 'eno1',
      description: 'LAN',
      ipv4Dhcp: false,
      aliases: [InterfaceAlias(address: '192.168.1.10', netmask: 24)],
      mtu: 9000,
    );

    await ServerActionsRepository(client).updateInterface(config);

    expect(client.method, 'interface.update');
    expect(client.params, ['eno1', config.toApiJson()]);
    // The id is the first positional argument, not part of the payload.
    expect((client.params!.last as Map).containsKey('id'), isFalse);
  });

  test('reads cloud credentials with the provider type', () async {
    final client = _RecordingClient(
      response: [
        {
          'id': 3,
          'name': 'Backblaze',
          'provider': {'type': 'S3'},
        },
        {'id': 4, 'name': 'Drive', 'provider': 'GOOGLE_DRIVE'},
      ],
    );

    final credentials = await ServerActionsRepository(
      client,
    ).getCloudCredentials();

    expect(client.method, 'cloudsync.credentials.query');
    expect(credentials.map((c) => c.id), [3, 4]);
    expect(credentials.first.usesBucket, isTrue);
    expect(credentials.last.usesBucket, isFalse);
  });

  test('rejects a non-list cloudsync.credentials.query response', () async {
    final client = _RecordingClient(response: const {'id': 1});
    await expectLater(
      ServerActionsRepository(client).getCloudCredentials(),
      throwsA(isA<TrueNasRpcException>()),
    );
  });

  test('creates a cloud sync task with the documented payload', () async {
    final client = _RecordingClient(response: {'id': 20});
    const credential = CloudCredential(
      id: 3,
      name: 'Backblaze',
      provider: 'S3',
    );
    const config = CloudSyncConfiguration(
      description: 'Nightly offsite',
      direction: CloudSyncDirection.push,
      transferMode: CloudSyncTransferMode.copy,
      path: '/mnt/tank/media',
      credentialId: 3,
      bucket: 'my-bucket',
      folder: 'media',
    );

    final receipt = await ServerActionsRepository(
      client,
    ).createCloudSyncTask(config, credential);

    expect(client.method, 'cloudsync.create');
    expect(client.params, [config.toApiJson(credential)]);
    // The remote location travels inside attributes, not at the top level.
    final payload = client.params!.single as Map<String, Object?>;
    final attributes = payload['attributes']! as Map<String, Object?>;
    expect(attributes['bucket'], 'my-bucket');
    expect(attributes['folder'], 'media');
    expect(receipt.result, {'id': 20});
  });

  test('omits the bucket for a bucket-less cloud provider', () async {
    final client = _RecordingClient(response: {'id': 21});
    const credential = CloudCredential(
      id: 4,
      name: 'Drive',
      provider: 'GOOGLE_DRIVE',
    );
    const config = CloudSyncConfiguration(
      description: 'Docs',
      direction: CloudSyncDirection.pull,
      transferMode: CloudSyncTransferMode.sync,
      path: '/mnt/tank/docs',
      credentialId: 4,
      folder: 'Documents',
    );

    await ServerActionsRepository(
      client,
    ).createCloudSyncTask(config, credential);

    final payload = client.params!.single as Map<String, Object?>;
    final attributes = payload['attributes']! as Map<String, Object?>;
    expect(attributes.containsKey('bucket'), isFalse);
    expect(attributes['folder'], 'Documents');
  });

  test('updates a cloud sync task by id', () async {
    final client = _RecordingClient(response: {'id': 20});
    const credential = CloudCredential(
      id: 3,
      name: 'Backblaze',
      provider: 'S3',
    );
    const config = CloudSyncConfiguration(
      id: 20,
      description: 'Nightly offsite',
      direction: CloudSyncDirection.push,
      transferMode: CloudSyncTransferMode.move,
      path: '/mnt/tank/media',
      credentialId: 3,
      bucket: 'my-bucket',
      folder: 'media',
    );

    await ServerActionsRepository(
      client,
    ).updateCloudSyncTask(20, config, credential);

    expect(client.method, 'cloudsync.update');
    expect(client.params, [20, config.toApiJson(credential)]);
  });

  test('reads a single cloud sync task config by id', () async {
    final client = _RecordingClient(
      response: [
        {'id': 20, 'description': 'Nightly offsite', 'transfer_mode': 'COPY'},
      ],
    );

    final config = await ServerActionsRepository(
      client,
    ).getCloudSyncTaskConfig(20);

    expect(client.method, 'cloudsync.query');
    expect(client.params, [
      [
        ['id', '=', 20],
      ],
    ]);
    expect(config['description'], 'Nightly offsite');
  });
}

const _smbConfiguration = SmbShareConfiguration(
  name: 'Projects',
  path: '/mnt/tank/projects',
  purpose: SmbSharePurpose.defaultShare,
  enabled: true,
  comment: '',
  readOnly: false,
  browsable: true,
  accessBasedEnumeration: false,
  auditEnabled: false,
  auditWatchList: [],
  auditIgnoreList: [],
  aaplNameMangling: false,
  hostsAllow: [],
  hostsDeny: [],
  timeMachineQuota: 0,
  autoSnapshot: false,
  autoDatasetCreation: false,
  datasetNamingSchema: null,
  volumeUuid: null,
  gracePeriod: 900,
  autoQuota: 0,
  remotePaths: [],
);

/// Records every call in order and answers each method from a script, so a
/// repository method that makes more than one call can be asserted as a
/// sequence rather than just its last call.
class _ScriptedClient extends TrueNasJsonRpcClient {
  _ScriptedClient(this.responses);

  final Map<String, Object?> responses;
  final calls = <({String method, List<Object?> params})>[];

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    calls.add((method: method, params: params));
    return responses[method];
  }
}

class _RecordingClient extends TrueNasJsonRpcClient {
  _RecordingClient({required this.response});

  final Object? response;
  String? method;
  List<Object?>? params;

  @override
  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 20),
  }) async {
    this.method = method;
    this.params = params;
    return response;
  }
}

class _UploadRecordingClient extends TrueNasJsonRpcClient {
  ServerProfile? profile;
  String? filePath;
  String? fileName;

  @override
  Future<int> uploadSystemUpdate({
    required ServerProfile profile,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    this.profile = profile;
    this.filePath = filePath;
    this.fileName = fileName;
    onProgress?.call(10, 10);
    return 73;
  }
}
