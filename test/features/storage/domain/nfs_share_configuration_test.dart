import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/nfs_share_configuration.dart';

void main() {
  test('serializes the complete NFS create and update payload', () {
    const configuration = NfsShareConfiguration(
      path: '/mnt/tank/projects',
      comment: 'Project files',
      networks: ['10.0.0.0/24'],
      hosts: ['buildbox.local'],
      readOnly: true,
      mapRootUser: 'nobody',
      mapRootGroup: 'nogroup',
      mapAllUser: null,
      mapAllGroup: null,
      security: {NfsSecurity.sys, NfsSecurity.krb5p},
      enabled: true,
      exposeSnapshots: false,
    );

    expect(configuration.toApiJson(), {
      'path': '/mnt/tank/projects',
      'aliases': <String>[],
      'comment': 'Project files',
      'networks': ['10.0.0.0/24'],
      'hosts': ['buildbox.local'],
      'ro': true,
      'maproot_user': 'nobody',
      'maproot_group': 'nogroup',
      'mapall_user': null,
      'mapall_group': null,
      'security': ['SYS', 'KRB5P'],
      'enabled': true,
      'expose_snapshots': false,
    });
    expect(configuration.validate(), isEmpty);
  });

  test('restores an existing share including Enterprise-only state', () {
    final share = NfsShare.fromJson({
      'id': 11,
      'path': '/mnt/tank/archive',
      'comment': 'Archive',
      'networks': ['2001:db8::/64'],
      'hosts': [],
      'ro': false,
      'maproot_user': null,
      'maproot_group': null,
      'mapall_user': 'backup',
      'mapall_group': 'backup',
      'security': ['KRB5I'],
      'enabled': false,
      'expose_snapshots': true,
    });

    final configuration = NfsShareConfiguration.fromShare(share);

    expect(configuration.path, '/mnt/tank/archive');
    expect(configuration.mapAllUser, 'backup');
    expect(configuration.security, {NfsSecurity.krb5i});
    expect(configuration.enabled, isFalse);
    expect(configuration.exposeSnapshots, isTrue);
  });

  test('rejects invalid clients and conflicting identity mappings', () {
    const configuration = NfsShareConfiguration(
      path: '/tmp/projects',
      comment: '',
      networks: ['10.0.0.0/24', '10.0.0.0/24'],
      hosts: ['host with spaces'],
      readOnly: false,
      mapRootUser: 'root',
      mapRootGroup: null,
      mapAllUser: 'nobody',
      mapAllGroup: null,
      security: {},
      enabled: true,
      exposeSnapshots: false,
    );

    expect(configuration.validate().keys, {
      'path',
      'networks',
      'hosts',
      'mapping',
    });
  });
}
