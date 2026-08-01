// Live TrueNAS mutation verification probe.
//
// The read-path probe (tool/live_server_probe.dart) confirms the shapes
// TrueDock *reads*. This one confirms the shapes it *writes*: pool, dataset,
// zvol, and snapshot create/update/delete, plus scrub control. Those were the
// last fixture-only call shapes, and they are the "live-server verification"
// gap in docs/architecture/0002-phase5-hardening.md.
//
// Usage:
//   dart run tool/live_mutation_probe.dart <host> <username> <password>
//
// DESTRUCTIVE. This probe creates a scratch pool from disks the server
// reports as unused, exercises the mutating calls inside it, and exports the
// pool with destroy_data at the end. It refuses to run unless every disk it
// would consume is currently unused, and it never touches an existing pool.
//
// Each payload below is copied from ServerActionsRepository so a shape that
// drifts from the app is a probe failure rather than a silent difference.
//
// Credentials are read from argv and never persisted. This is a tool, not
// part of the shipped app.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:true_dock/features/system/domain/account_configuration.dart';
import 'package:true_dock/features/system/domain/static_route_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_extent_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_configuration.dart';
import 'package:true_dock/features/storage/domain/iscsi_target_extent_configuration.dart';
import 'package:true_dock/features/storage/domain/nfs_share_configuration.dart';
import 'package:true_dock/features/storage/domain/pool_configuration.dart';
import 'package:true_dock/features/storage/domain/smb_acl_configuration.dart';
import 'package:true_dock/features/storage/domain/smb_share_configuration.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Name of the scratch pool. Deliberately distinctive so it is obvious in the
/// web UI that this came from the probe and is safe to remove.
const _poolName = 'truedock_probe';

void main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/live_mutation_probe.dart <host> <username> '
      '<password>',
    );
    exit(64);
  }
  final host = args[0];
  final username = args[1];
  final password = args[2];

  final results = <_ProbeResult>[];
  Future<void> check(String name, Future<void> Function() body) async {
    try {
      await body();
      results.add(_ProbeResult(name, true));
      print('PASS  $name');
    } catch (error) {
      results.add(_ProbeResult(name, false, '$error'));
      print('FAIL  $name\n      $error');
    }
  }

  WebSocketChannel? channel;
  var nextId = 1;
  final pending = <int, Completer<Object?>>{};

  Future<Object?> call(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(seconds: 30),
  }) async {
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
    return completer.future.timeout(timeout);
  }

  /// Runs a job-returning call and waits for the job to reach a terminal
  /// state. The mutating methods return a job id rather than a result, which
  /// is exactly why they could not be verified from fixtures alone.
  Future<void> runJob(
    String method, {
    List<Object?> params = const [],
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final jobId = await call(method, params: params);
    if (jobId is! int) {
      throw StateError('$method did not return a job id (got $jobId)');
    }
    final deadline = DateTime.now().add(timeout);
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
      final state = job['state'];
      if (state == 'SUCCESS') return;
      if (state == 'FAILED' || state == 'ABORTED') {
        throw StateError('$method job $jobId $state: ${job['error']}');
      }
    }
    throw StateError('$method job $jobId did not finish within $timeout');
  }

  var poolCreated = false;

  try {
    await check('connect to /api/current over WSS', () async {
      final httpClient = HttpClient()
        ..badCertificateCallback = (cert, h, p) {
          final fingerprint = sha256.convert(cert.der).toString();
          stderr.writeln('      (trusting cert fingerprint $fingerprint)');
          return h == host;
        };
      channel = IOWebSocketChannel.connect(
        'wss://$host/api/current',
        customClient: httpClient,
      );
      channel!.stream.listen(
        (message) {
          final decoded = jsonDecode(message.toString());
          if (decoded is Map && decoded['id'] is int) {
            final completer = pending.remove(decoded['id'] as int);
            if (completer == null || completer.isCompleted) return;
            final error = decoded['error'];
            if (error != null) {
              completer.completeError(StateError(jsonEncode(error)));
            } else {
              completer.complete(decoded['result']);
            }
          }
        },
        onError: (Object error) {
          for (final completer in pending.values) {
            if (!completer.isCompleted) completer.completeError(error);
          }
          pending.clear();
        },
      );
      await channel!.ready;
    });

    await check('auth.login_ex authenticates', () async {
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
      final response = result as Map;
      if (response['response_type'] != 'SUCCESS') {
        throw StateError('login returned ${response['response_type']}');
      }
    });

    // Clear anything a previous run stranded. The teardown below only runs if
    // the process survives to reach it, so a killed run leaves the scratch
    // pool and its shares behind; without this, the next run would refuse to
    // start. Only probe-created resources are matched, by name.
    await check('previous probe leftovers are cleared', () async {
      var removed = 0;

      for (final share in await call('sharing.smb.query') as List) {
        final row = share as Map;
        if ('${row['name']}' == 'probeshare') {
          await call('sharing.smb.delete', params: [row['id']]);
          removed++;
        }
      }
      for (final share in await call('sharing.nfs.query') as List) {
        final row = share as Map;
        if ('${row['path']}'.contains(_poolName)) {
          await call('sharing.nfs.delete', params: [row['id']]);
          removed++;
        }
      }
      // Dependency order: an association pins its target and extent.
      for (final entry in const [
        ('iscsi.targetextent', 'probe'),
        ('iscsi.target', 'probetarget'),
        ('iscsi.extent', 'probeextent'),
        ('iscsi.initiator', 'probed by truedock'),
        ('iscsi.portal', 'probed by truedock'),
      ]) {
        final (service, needle) = entry;
        for (final row in await call('$service.query') as List) {
          final map = row as Map;
          final label = '${map['name'] ?? map['comment'] ?? ''}';
          if (!label.contains(needle)) continue;
          try {
            await call('$service.delete', params: [map['id'], true]);
          } on Object {
            await call('$service.delete', params: [map['id']]);
          }
          removed++;
        }
      }
      for (final row in await call('staticroute.query') as List) {
        final map = row as Map;
        if ('${map['description']}'.contains('probed by truedock')) {
          await call('staticroute.delete', params: [map['id']]);
          removed++;
        }
      }
      for (final row
          in await call(
                'user.query',
                params: [
                  [
                    ['username', '=', 'truedockprobe'],
                  ],
                ],
              )
              as List) {
        await call(
          'user.delete',
          params: [
            (row as Map)['id'],
            {'delete_group': true},
          ],
        );
        removed++;
      }
      for (final row
          in await call(
                'group.query',
                params: [
                  [
                    ['group', '=', 'truedockprobe'],
                  ],
                ],
              )
              as List) {
        await call(
          'group.delete',
          params: [
            (row as Map)['id'],
            {'delete_users': false},
          ],
        );
        removed++;
      }
      for (final row in await call('pool.query') as List) {
        final map = row as Map;
        if (map['name'] != _poolName) continue;
        await runJob(
          'pool.export',
          params: [
            map['id'],
            {'destroy': true, 'cascade': true, 'restart_services': false},
          ],
        );
        removed++;
      }

      if (removed > 0) {
        print('      (cleared $removed leftover resource(s))');
      }
    });

    // Refuse to run unless the disks are genuinely unused. Formatting a disk
    // that belongs to a pool would be unrecoverable.
    late List<String> disks;
    await check('scratch disks are unused before we format them', () async {
      final existing = await call('pool.query');
      for (final pool in existing as List) {
        if ((pool as Map)['name'] == _poolName) {
          throw StateError(
            'a pool named $_poolName already exists; refusing to reuse it',
          );
        }
      }
      final unused = await call('disk.get_unused');
      disks = [
        for (final disk in unused as List)
          if ((disk as Map)['pool'] == null) disk['devname'] as String,
      ];
      if (disks.length < 2) {
        throw StateError(
          'need 2 unused disks to build a mirror, found ${disks.length}',
        );
      }
      disks = disks.take(2).toList();
      print('      (using ${disks.join(', ')} for a mirror)');
    });

    // Built by the app's own PoolConfiguration rather than a copy of it, so
    // this fails if the shipped payload drifts from what the server accepts.
    await check('pool.create accepts the topology payload', () async {
      final configuration = PoolConfiguration(
        name: _poolName,
        dataVdevs: [VdevSpec(type: VdevType.mirror, disks: disks)],
      );
      await runJob('pool.create', params: [configuration.toApiJson()]);
      poolCreated = true;
    });

    // createDataset()
    await check('pool.dataset.create accepts the filesystem payload', () async {
      await call(
        'pool.dataset.create',
        params: [
          {
            'name': '$_poolName/probe_fs',
            'type': 'FILESYSTEM',
            'share_type': 'GENERIC',
            'inherit_encryption': true,
          },
        ],
      );
    });

    // createVolume()
    await check('pool.dataset.create accepts the zvol payload', () async {
      await call(
        'pool.dataset.create',
        params: [
          {
            'name': '$_poolName/probe_zvol',
            'type': 'VOLUME',
            'volsize': 1073741824,
            'sparse': true,
            'inherit_encryption': true,
          },
        ],
      );
    });

    // updateDataset()
    await check('pool.dataset.update accepts a property payload', () async {
      await call(
        'pool.dataset.update',
        params: [
          '$_poolName/probe_fs',
          {'comments': 'probed by truedock'},
        ],
      );
    });

    // createSnapshot()
    await check('pool.snapshot.create accepts the snapshot payload', () async {
      await call(
        'pool.snapshot.create',
        params: [
          {
            'dataset': '$_poolName/probe_fs',
            'name': 'probe-snap',
            'recursive': false,
          },
        ],
      );
    });

    // rollbackSnapshot(), SnapshotRollbackMode.newestOnly.
    //
    // Ordered before the clone/promote pair on purpose: promotion moves the
    // snapshot to the clone, so rolling back afterwards would be asking for a
    // snapshot that legitimately no longer lives on this dataset.
    await check('pool.snapshot.rollback accepts the recursion flags', () async {
      await call(
        'pool.snapshot.rollback',
        params: [
          '$_poolName/probe_fs@probe-snap',
          {'recursive': false, 'recursive_clones': false, 'force': false},
        ],
      );
    });

    // deleteSnapshot()
    await check('pool.snapshot.delete accepts the defer flag', () async {
      await call(
        'pool.snapshot.delete',
        params: [
          '$_poolName/probe_fs@probe-snap',
          {'defer': false},
        ],
      );
    });

    // The clone/promote pair needs its own snapshot, since the one above is
    // gone by now.
    await check('pool.snapshot.create accepts a second snapshot', () async {
      await call(
        'pool.snapshot.create',
        params: [
          {
            'dataset': '$_poolName/probe_fs',
            'name': 'probe-clone-src',
            'recursive': false,
          },
        ],
      );
    });

    // cloneSnapshot()
    await check('pool.snapshot.clone accepts the clone payload', () async {
      await call(
        'pool.snapshot.clone',
        params: [
          {
            'snapshot': '$_poolName/probe_fs@probe-clone-src',
            'dataset_dst': '$_poolName/probe_clone',
          },
        ],
      );
    });

    // promoteDataset(). After this the dependency is reversed: probe_clone
    // owns the shared data and probe_fs becomes the dependent dataset, which
    // is why the teardown below deletes probe_fs first.
    await check('pool.dataset.promote accepts a clone id', () async {
      await call('pool.dataset.promote', params: ['$_poolName/probe_clone']);
    });

    // startPoolScrub() / controlPoolScrub()
    await check('pool.scrub.scrub accepts START and STOP', () async {
      await runJob('pool.scrub.scrub', params: [_poolName, 'START']);
    });

    // ---- Share and iSCSI shapes -------------------------------------------
    //
    // These run before the dataset teardown because they need a real path to
    // share and a real zvol to back an extent. Every payload is built by the
    // app's own configuration type, so a shape that drifts fails here.

    var smbShareId = 0;
    // createSmbShare()
    await check('sharing.smb.create accepts the share payload', () async {
      const configuration = SmbShareConfiguration(
        name: 'probeshare',
        path: '/mnt/$_poolName/probe_fs',
        purpose: SmbSharePurpose.defaultShare,
        enabled: true,
        comment: 'probed by truedock',
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
      final created = await call(
        'sharing.smb.create',
        params: [configuration.toApiJson()],
      );
      smbShareId = (created as Map)['id'] as int;
    });

    // updateSmbShare()
    await check('sharing.smb.update accepts an id and payload', () async {
      const configuration = SmbShareConfiguration(
        name: 'probeshare',
        path: '/mnt/$_poolName/probe_fs',
        purpose: SmbSharePurpose.defaultShare,
        enabled: false,
        comment: 'probed by truedock (updated)',
        readOnly: true,
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
      await call(
        'sharing.smb.update',
        params: [smbShareId, configuration.toApiJson()],
      );
    });

    // getSmbShareAcl(). Keyed by share name, and the response wraps the list
    // in `share_acl`; the underscored sharing.smb.get_acl spelling that the
    // app used to call does not exist on the middleware.
    await check('sharing.smb.getacl returns the share ACL', () async {
      final result = await call(
        'sharing.smb.getacl',
        params: [
          {'share_name': 'probeshare'},
        ],
      );
      if (result is! Map || result['share_acl'] is! List) {
        throw StateError('expected an object carrying share_acl');
      }
    });

    // setSmbShareAcl(), with the entry built by the app's own SmbAclEntry so
    // a drift in the entry shape fails here.
    await check('sharing.smb.setacl accepts the ACL payload', () async {
      // builtin_users (gid 545) is an SMB-enabled group on every TrueNAS box.
      // The principal must be an SMB account, and must be identified by Unix
      // id or SID: a bare ae_who_str name makes the middleware raise a
      // TypeError instead of a validation error.
      const entry = SmbAclEntry(
        qualifiedName: 'group:builtin_users',
        kind: SmbAclPrincipalKind.group,
        permission: SmbSharePermission.read,
        permType: SmbAclPermType.allowed,
        unixId: 545,
      );
      await call(
        'sharing.smb.setacl',
        params: [
          {
            'share_name': 'probeshare',
            'share_acl': [entry.toApiJson()],
          },
        ],
      );
    });

    await check('sharing.smb.delete accepts an id', () async {
      await call('sharing.smb.delete', params: [smbShareId]);
    });

    var nfsShareId = 0;
    // createNfsShare()
    await check('sharing.nfs.create accepts the export payload', () async {
      const configuration = NfsShareConfiguration(
        path: '/mnt/$_poolName/probe_fs',
        comment: 'probed by truedock',
        networks: [],
        hosts: [],
        readOnly: false,
        mapRootUser: null,
        mapRootGroup: null,
        mapAllUser: null,
        mapAllGroup: null,
        security: {},
        enabled: true,
        exposeSnapshots: false,
      );
      final created = await call(
        'sharing.nfs.create',
        params: [configuration.toApiJson()],
      );
      nfsShareId = (created as Map)['id'] as int;
    });

    // updateNfsShare()
    await check('sharing.nfs.update accepts an id and payload', () async {
      const configuration = NfsShareConfiguration(
        path: '/mnt/$_poolName/probe_fs',
        comment: 'probed by truedock (updated)',
        networks: ['10.0.0.0/24'],
        hosts: [],
        readOnly: true,
        mapRootUser: null,
        mapRootGroup: null,
        mapAllUser: null,
        mapAllGroup: null,
        security: {NfsSecurity.sys},
        enabled: true,
        exposeSnapshots: false,
      );
      await call(
        'sharing.nfs.update',
        params: [nfsShareId, configuration.toApiJson()],
      );
    });

    await check('sharing.nfs.delete accepts an id', () async {
      await call('sharing.nfs.delete', params: [nfsShareId]);
    });

    var portalId = 0;
    // createIscsiPortal()
    await check('iscsi.portal.create accepts the listen payload', () async {
      final choices = await call('iscsi.portal.listen_ip_choices');
      final addresses = (choices as Map).keys.cast<String>().toList();
      if (addresses.isEmpty) {
        throw StateError('server offered no listen addresses');
      }
      final configuration = IscsiPortalConfiguration(
        listenAddresses: [addresses.first],
        comment: 'probed by truedock',
      );
      final created = await call(
        'iscsi.portal.create',
        params: [configuration.toApiJson()],
      );
      portalId = (created as Map)['id'] as int;
    });

    var initiatorId = 0;
    // createIscsiInitiator()
    await check('iscsi.initiator.create accepts the group payload', () async {
      const configuration = IscsiInitiatorConfiguration(
        initiators: [],
        comment: 'probed by truedock',
      );
      final created = await call(
        'iscsi.initiator.create',
        params: [configuration.toApiJson()],
      );
      initiatorId = (created as Map)['id'] as int;
    });

    var extentId = 0;
    // createIscsiExtent(), disk-backed by the scratch zvol
    await check('iscsi.extent.create accepts the extent payload', () async {
      final configuration = IscsiExtentConfiguration(
        name: 'probeextent',
        type: IscsiExtentType.disk,
        disk: 'zvol/$_poolName/probe_zvol',
        serial: null,
        path: null,
        fileSize: 0,
        blockSize: 512,
        physicalBlockSize: false,
        availableThreshold: null,
        comment: 'probed by truedock',
        insecureTpc: true,
        xen: false,
        rpm: IscsiExtentRpm.ssd,
        readOnly: false,
        enabled: true,
        productId: null,
      );
      final created = await call(
        'iscsi.extent.create',
        params: [configuration.toApiJson()],
      );
      extentId = (created as Map)['id'] as int;
    });

    var targetId = 0;
    // createIscsiTarget()
    await check('iscsi.target.create accepts the target payload', () async {
      final configuration = IscsiTargetConfiguration(
        name: 'probetarget',
        alias: null,
        groups: [
          IscsiTargetGroupConfiguration(portalId: portalId, authMethod: 'NONE'),
        ],
        authNetworks: const [],
        queuedCommands: null,
      );
      final created = await call(
        'iscsi.target.create',
        params: [configuration.toApiJson()],
      );
      targetId = (created as Map)['id'] as int;
    });

    var associationId = 0;
    // createIscsiTargetExtent()
    await check('iscsi.targetextent.create accepts the LUN payload', () async {
      final configuration = IscsiTargetExtentConfiguration(
        targetId: targetId,
        extentId: extentId,
        lunId: null,
      );
      final created = await call(
        'iscsi.targetextent.create',
        params: [configuration.toCreateApiJson()],
      );
      associationId = (created as Map)['id'] as int;
    });

    // updateIscsiTargetExtent()
    await check('iscsi.targetextent.update accepts a concrete LUN', () async {
      final configuration = IscsiTargetExtentConfiguration(
        targetId: targetId,
        extentId: extentId,
        lunId: 1,
      );
      await call(
        'iscsi.targetextent.update',
        params: [associationId, configuration.toUpdateApiJson()],
      );
    });

    // Teardown, in dependency order: the association pins both the target and
    // the extent, and the extent pins the zvol the dataset teardown removes.
    await check('iscsi resources delete in dependency order', () async {
      await call('iscsi.targetextent.delete', params: [associationId, true]);
      await call('iscsi.target.delete', params: [targetId, true]);
      await call('iscsi.extent.delete', params: [extentId, true, true]);
      await call('iscsi.initiator.delete', params: [initiatorId]);
      await call('iscsi.portal.delete', params: [portalId]);
    });

    // ---- Account and network shapes ---------------------------------------
    //
    // These need no pool, but they run here so a failure still tears the
    // scratch pool down through the finally block below.

    var groupId = 0;
    // createGroup()
    await check('group.create accepts the group payload', () async {
      const configuration = GroupCreateConfiguration(
        name: 'truedockprobe',
        smb: false,
        userIds: [],
      );
      final created = await call(
        'group.create',
        params: [configuration.toApiJson()],
      );
      groupId = created is int ? created : (created as Map)['id'] as int;
    });

    // updateGroup(), through GroupUpdateConfiguration's diff payload
    await check('group.update accepts an id and payload', () async {
      await call(
        'group.update',
        params: [
          groupId,
          {'smb': false},
        ],
      );
    });

    var userId = 0;
    // createUser()
    await check('user.create accepts the account payload', () async {
      const configuration = UserCreateConfiguration(
        username: 'truedockprobe',
        fullName: 'TrueDock Probe',
        password: 'Pr0be-Passw0rd!',
        passwordDisabled: false,
        smb: false,
        createGroup: true,
        primaryGroupId: null,
        email: '',
        shell: '',
      );
      final created = await call(
        'user.create',
        params: [configuration.toApiJson()],
      );
      userId = created is int ? created : (created as Map)['id'] as int;
    });

    // updateUser()
    await check('user.update accepts an id and payload', () async {
      await call(
        'user.update',
        params: [
          userId,
          {'full_name': 'TrueDock Probe (updated)'},
        ],
      );
    });

    // deleteGroup(), with the delete_users flag. Ordered before the user so
    // the group still exists: the user was created with group_create, and
    // deleting it with delete_group also removes its own primary group.
    await check('group.delete accepts the delete_users flag', () async {
      await call(
        'group.delete',
        params: [
          groupId,
          {'delete_users': false},
        ],
      );
    });

    // deleteUser(), with the delete_group flag the UI surfaces
    await check('user.delete accepts the delete_group flag', () async {
      await call(
        'user.delete',
        params: [
          userId,
          {'delete_group': true},
        ],
      );
    });

    var routeId = 0;
    // createStaticRoute()
    await check('staticroute.create accepts the route payload', () async {
      const configuration = StaticRouteConfiguration(
        destination: '192.0.2.0/24',
        gateway: '10.24.30.1',
        description: 'probed by truedock',
      );
      final created = await call(
        'staticroute.create',
        params: [configuration.toApiJson()],
      );
      routeId = (created as Map)['id'] as int;
    });

    // updateStaticRoute()
    await check('staticroute.update accepts an id and payload', () async {
      const configuration = StaticRouteConfiguration(
        destination: '192.0.2.0/24',
        gateway: '10.24.30.1',
        description: 'probed by truedock (updated)',
      );
      await call(
        'staticroute.update',
        params: [routeId, configuration.toApiJson()],
      );
    });

    await check('staticroute.delete accepts an id', () async {
      await call('staticroute.delete', params: [routeId]);
    });

    // deleteDataset()
    await check('pool.dataset.delete accepts recursive and force', () async {
      // Dependency order: promotion made probe_fs depend on probe_clone, so
      // the clone cannot be destroyed until its dependent is gone.
      for (final dataset in [
        '$_poolName/probe_fs',
        '$_poolName/probe_clone',
        '$_poolName/probe_zvol',
      ]) {
        await call(
          'pool.dataset.delete',
          params: [
            dataset,
            {'recursive': true, 'force': true},
          ],
        );
      }
    });
  } finally {
    // Always tear the scratch pool down, even if a check above threw, so a
    // failed run does not leave the server holding formatted disks.
    if (poolCreated) {
      await check('pool.export removes the scratch pool', () async {
        final pools = await call('pool.query');
        final pool = (pools as List).cast<Map>().firstWhere(
          (candidate) => candidate['name'] == _poolName,
          orElse: () => throw StateError('scratch pool disappeared'),
        );
        await runJob(
          'pool.export',
          params: [
            pool['id'],
            {'destroy': true, 'cascade': true, 'restart_services': false},
          ],
        );
      });
    }
    try {
      await call('auth.logout');
    } on Object {
      // Logout is best-effort; the socket closes either way.
    }
    await channel?.sink.close();
  }

  final failed = results.where((r) => !r.passed).toList();
  print('\nResult: ${results.length - failed.length}/${results.length} passed');
  if (failed.isNotEmpty) {
    print('\nFailures:');
    for (final failure in failed) {
      print('  ${failure.name}: ${failure.detail}');
    }
    exit(1);
  }
  exit(0);
}

class _ProbeResult {
  _ProbeResult(this.name, this.passed, [this.detail]);

  final String name;
  final bool passed;
  final String? detail;
}
