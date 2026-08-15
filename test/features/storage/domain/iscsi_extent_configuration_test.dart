import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/iscsi_extent_configuration.dart';

void main() {
  test('serializes the complete iSCSI extent payload exactly', () {
    const configuration = IscsiExtentConfiguration(
      name: 'archive-zvol',
      type: IscsiExtentType.disk,
      disk: 'zvol/tank/archive',
      serial: 'TRUEDOCK001',
      path: null,
      fileSize: 0,
      blockSize: 4096,
      physicalBlockSize: true,
      availableThreshold: 20,
      comment: 'Archive storage',
      insecureTpc: false,
      xen: true,
      rpm: IscsiExtentRpm.rpm7200,
      readOnly: true,
      enabled: false,
      productId: 'TrueDock Disk',
    );

    expect(configuration.toApiJson(), {
      'name': 'archive-zvol',
      'type': 'DISK',
      'disk': 'zvol/tank/archive',
      'serial': 'TRUEDOCK001',
      'path': null,
      'filesize': 0,
      'blocksize': 4096,
      'pblocksize': true,
      'avail_threshold': 20,
      'comment': 'Archive storage',
      'insecure_tpc': false,
      'xen': true,
      'rpm': '7200',
      'ro': true,
      'enabled': false,
      'product_id': 'TrueDock Disk',
    });
    expect(
      configuration.validate(
        availableDiskChoices: const {
          'zvol/tank/archive': 'tank/archive (10 GiB)',
        },
      ),
      isEmpty,
    );
  });

  test('uses the documented create defaults', () {
    final configuration = IscsiExtentConfiguration.defaults();

    expect(configuration.toApiJson(), {
      'name': '',
      'type': 'DISK',
      'disk': null,
      'serial': null,
      'path': null,
      'filesize': 0,
      'blocksize': 512,
      'pblocksize': false,
      'avail_threshold': null,
      'comment': '',
      'insecure_tpc': true,
      'xen': false,
      'rpm': 'SSD',
      'ro': false,
      'enabled': true,
      'product_id': null,
    });
  });

  test('restores every editable field from an existing extent', () {
    final extent = IscsiExtent.fromJson({
      'id': 12,
      'name': 'backup-file',
      'type': 'FILE',
      'disk': null,
      'serial': 'FILE0001',
      'path': '/mnt/tank/iscsi/backup.img',
      'filesize': '1073741824',
      'blocksize': 2048,
      'pblocksize': true,
      'avail_threshold': 15,
      'comment': 'Backup target',
      'insecure_tpc': false,
      'xen': true,
      'rpm': '10000',
      'ro': true,
      'enabled': false,
      'product_id': 'Backup Disk',
      'locked': false,
    });

    final configuration = IscsiExtentConfiguration.fromExtent(extent);

    expect(configuration.type, IscsiExtentType.file);
    expect(configuration.disk, isNull);
    expect(configuration.serial, 'FILE0001');
    expect(configuration.path, '/mnt/tank/iscsi/backup.img');
    expect(configuration.fileSize, 1073741824);
    expect(configuration.blockSize, 2048);
    expect(configuration.physicalBlockSize, isTrue);
    expect(configuration.availableThreshold, 15);
    expect(configuration.comment, 'Backup target');
    expect(configuration.insecureTpc, isFalse);
    expect(configuration.xen, isTrue);
    expect(configuration.rpm, IscsiExtentRpm.rpm10000);
    expect(configuration.readOnly, isTrue);
    expect(configuration.enabled, isFalse);
    expect(configuration.productId, 'Backup Disk');
    expect(configuration.validate(), isEmpty);
  });

  test('requires a server-provided disk and rejects a file path for disks', () {
    const configuration = IscsiExtentConfiguration(
      name: 'disk-extent',
      type: IscsiExtentType.disk,
      disk: 'zvol/tank/missing',
      serial: null,
      path: '/mnt/tank/extent.img',
      fileSize: 0,
      blockSize: 512,
      physicalBlockSize: false,
      availableThreshold: null,
      comment: '',
      insecureTpc: true,
      xen: false,
      rpm: IscsiExtentRpm.ssd,
      readOnly: false,
      enabled: true,
      productId: null,
    );

    expect(configuration.validate().keys, {'disk', 'path'});
  });

  test('requires /mnt file paths, no disk, and a non-negative file size', () {
    const configuration = IscsiExtentConfiguration(
      name: 'file-extent',
      type: IscsiExtentType.file,
      disk: 'zvol/tank/data',
      serial: null,
      path: '/tmp/extent.img',
      fileSize: -1,
      blockSize: 512,
      physicalBlockSize: false,
      availableThreshold: null,
      comment: '',
      insecureTpc: true,
      xen: false,
      rpm: IscsiExtentRpm.ssd,
      readOnly: false,
      enabled: true,
      productId: null,
    );

    expect(configuration.validate().keys, {'path', 'disk', 'filesize'});
    expect(configuration.toApiJson()['disk'], isNull);
  });

  test('validates names, block sizes, thresholds, and product IDs', () {
    final configuration = IscsiExtentConfiguration(
      name: ' ' * 65,
      type: IscsiExtentType.file,
      disk: null,
      serial: null,
      path: '/mnt/tank/extent.img',
      fileSize: 1024,
      blockSize: 8192,
      physicalBlockSize: false,
      availableThreshold: 100,
      comment: '',
      insecureTpc: true,
      xen: false,
      rpm: IscsiExtentRpm.unknown,
      readOnly: false,
      enabled: true,
      productId: '12345678901234567',
    );

    expect(configuration.validate().keys, {
      'name',
      'blocksize',
      'avail_threshold',
      'product_id',
    });
  });
}
