import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';

const _s3 = CloudCredential(id: 3, name: 'Backblaze', provider: 'S3');
const _drive = CloudCredential(
  id: 4,
  name: 'My Drive',
  provider: 'GOOGLE_DRIVE',
);

const _base = CloudSyncConfiguration(
  description: 'Nightly offsite',
  direction: CloudSyncDirection.push,
  transferMode: CloudSyncTransferMode.copy,
  path: '/mnt/tank/media',
  credentialId: 3,
  bucket: 'my-bucket',
  folder: 'media',
);

void main() {
  group('CloudCredential', () {
    test('reads a provider returned as an object', () {
      final credential = CloudCredential.fromJson(const {
        'id': 7,
        'name': 'Backblaze',
        'provider': {'type': 'S3'},
      });
      expect(credential.id, 7);
      expect(credential.provider, 'S3');
    });

    test('reads a provider returned as a bare string', () {
      final credential = CloudCredential.fromJson(const {
        'id': 8,
        'name': 'Drive',
        'provider': 'GOOGLE_DRIVE',
      });
      expect(credential.provider, 'GOOGLE_DRIVE');
    });

    test('knows which providers address a bucket', () {
      expect(_s3.usesBucket, isTrue);
      expect(_drive.usesBucket, isFalse);
      expect(
        const CloudCredential(id: 1, name: 'B2', provider: 'B2').usesBucket,
        isTrue,
      );
    });

    test('storage class is S3 only', () {
      expect(_s3.supportsStorageClass, isTrue);
      expect(_drive.supportsStorageClass, isFalse);
    });
  });

  group('attributesFor', () {
    test('includes the bucket for a bucket provider', () {
      final attributes = _base.attributesFor(_s3);
      expect(attributes['bucket'], 'my-bucket');
      expect(attributes['folder'], 'media');
    });

    test('omits the bucket for a bucket-less provider', () {
      final attributes = _base.copyWith(credentialId: 4).attributesFor(_drive);
      expect(attributes.containsKey('bucket'), isFalse);
      expect(attributes['folder'], 'media');
    });

    test('includes storage_class only for S3 when set', () {
      final withClass = _base.copyWith(storageClass: 'GLACIER');
      expect(withClass.attributesFor(_s3)['storage_class'], 'GLACIER');
      // Non-S3 provider drops it even when the field carries a value.
      expect(
        withClass.attributesFor(_drive).containsKey('storage_class'),
        isFalse,
      );
      // S3 with an empty value omits it rather than sending a blank.
      expect(_base.attributesFor(_s3).containsKey('storage_class'), isFalse);
    });

    test('preserves provider-specific attributes it does not surface', () {
      final config = _base.copyWith(
        preservedAttributes: const {'region': 'eu-central-1'},
      );
      final attributes = config.attributesFor(_s3);
      expect(attributes['region'], 'eu-central-1');
      expect(attributes['bucket'], 'my-bucket');
    });
  });

  group('toApiJson', () {
    test('emits the documented cloudsync.create fields', () {
      final json = _base.toApiJson(_s3);
      expect(json['description'], 'Nightly offsite');
      expect(json['direction'], 'PUSH');
      expect(json['transfer_mode'], 'COPY');
      expect(json['path'], '/mnt/tank/media');
      expect(json['credentials'], 3);
      expect(json['attributes'], isA<Map<String, Object?>>());
      expect(json['schedule'], isA<Map<String, Object?>>());
      expect(json['encryption'], false);
      expect(json['enabled'], true);
    });

    test('omits transfers unless set', () {
      expect(_base.toApiJson(_s3).containsKey('transfers'), isFalse);
      expect(_base.copyWith(transfers: 8).toApiJson(_s3)['transfers'], 8);
    });

    test('omits every encryption field while encryption is off', () {
      final json = _base.toApiJson(_s3);
      expect(json['encryption'], false);
      expect(json.containsKey('filename_encryption'), isFalse);
      expect(json.containsKey('encryption_password'), isFalse);
      expect(json.containsKey('encryption_salt'), isFalse);
    });

    test('sends encryption secrets only when they are supplied', () {
      final withoutSecret = _base.copyWith(encryption: true).toApiJson(_s3);
      expect(withoutSecret['encryption'], true);
      expect(withoutSecret['filename_encryption'], false);
      // An edit that did not touch the password must not clear it.
      expect(withoutSecret.containsKey('encryption_password'), isFalse);

      final withSecret = _base
          .copyWith(
            encryption: true,
            filenameEncryption: true,
            encryptionPassword: 'hunter2',
            encryptionSalt: 'pepper',
          )
          .toApiJson(_s3);
      expect(withSecret['filename_encryption'], true);
      expect(withSecret['encryption_password'], 'hunter2');
      expect(withSecret['encryption_salt'], 'pepper');
    });

    test('round-trips preserved top-level fields such as scripts', () {
      final config = _base.copyWith(
        preservedFields: const {
          'pre_script': 'echo before',
          'post_script': 'echo after',
          'bwlimit': <Object?>[],
        },
      );
      final json = config.toApiJson(_s3);
      expect(json['pre_script'], 'echo before');
      expect(json['post_script'], 'echo after');
      expect(json['bwlimit'], isEmpty);
      // Surfaced fields still win over anything preserved.
      expect(json['description'], 'Nightly offsite');
    });
  });

  group('fromJson', () {
    test('seeds surfaced fields and splits out the remote location', () {
      final config = CloudSyncConfiguration.fromJson(const {
        'id': 12,
        'description': 'Nightly offsite',
        'direction': 'PULL',
        'transfer_mode': 'SYNC',
        'path': '/mnt/tank/media',
        'credentials': {'id': 3, 'name': 'Backblaze'},
        'attributes': {
          'bucket': 'my-bucket',
          'folder': 'media',
          'storage_class': 'STANDARD',
          'region': 'eu-central-1',
        },
        'transfers': 8,
        'encryption': true,
        'filename_encryption': true,
        'enabled': false,
        'schedule': {'minute': '30', 'hour': '2'},
      });
      expect(config.id, 12);
      expect(config.direction, CloudSyncDirection.pull);
      expect(config.transferMode, CloudSyncTransferMode.sync);
      expect(config.credentialId, 3);
      expect(config.bucket, 'my-bucket');
      expect(config.folder, 'media');
      expect(config.storageClass, 'STANDARD');
      expect(config.transfers, 8);
      expect(config.encryption, isTrue);
      expect(config.filenameEncryption, isTrue);
      expect(config.enabled, isFalse);
      expect(config.schedule.minute, '30');
      // Non-surfaced attribute keys are preserved for the round-trip.
      expect(config.preservedAttributes['region'], 'eu-central-1');
      expect(config.preservedAttributes.containsKey('bucket'), isFalse);
    });

    test('preserves unsurfaced top-level fields but drops runtime state', () {
      final config = CloudSyncConfiguration.fromJson(const {
        'id': 12,
        'description': 'Nightly',
        'path': '/mnt/tank',
        'pre_script': 'echo before',
        'post_script': 'echo after',
        'job': {'state': 'RUNNING'},
        'locked': false,
      });
      expect(config.preservedFields['pre_script'], 'echo before');
      expect(config.preservedFields['post_script'], 'echo after');
      // Runtime-only fields must never be echoed back on update.
      expect(config.preservedFields.containsKey('job'), isFalse);
      expect(config.preservedFields.containsKey('locked'), isFalse);
    });

    test('reads a bare integer credential id', () {
      final config = CloudSyncConfiguration.fromJson(const {
        'id': 1,
        'credentials': 5,
      });
      expect(config.credentialId, 5);
    });
  });

  group('transfer mode', () {
    test('only COPY is non-destructive', () {
      expect(CloudSyncTransferMode.copy.deletesData, isFalse);
      expect(CloudSyncTransferMode.sync.deletesData, isTrue);
      expect(CloudSyncTransferMode.move.deletesData, isTrue);
    });

    test('maps to the documented API values', () {
      expect(CloudSyncTransferMode.sync.apiValue, 'SYNC');
      expect(CloudSyncTransferMode.copy.apiValue, 'COPY');
      expect(CloudSyncTransferMode.move.apiValue, 'MOVE');
      expect(
        CloudSyncTransferModeApi.fromApi('MOVE'),
        CloudSyncTransferMode.move,
      );
    });
  });

  group('validate', () {
    test('accepts a complete bucket-provider task', () {
      expect(validateCloudSyncConfiguration(_base, credential: _s3), isEmpty);
    });

    test('requires a task name', () {
      final errors = validateCloudSyncConfiguration(
        _base.copyWith(description: '  '),
        credential: _s3,
      );
      expect(errors['description'], isNotNull);
    });

    test('requires an absolute local path', () {
      expect(
        validateCloudSyncConfiguration(
          _base.copyWith(path: 'tank/media'),
          credential: _s3,
        )['path'],
        contains('absolute'),
      );
      expect(
        validateCloudSyncConfiguration(
          _base.copyWith(path: ''),
          credential: _s3,
        )['path'],
        isNotNull,
      );
    });

    test('requires a credential', () {
      final errors = validateCloudSyncConfiguration(
        _base.copyWith(clearCredential: true),
        credential: null,
      );
      expect(errors['credentials'], isNotNull);
    });

    test('requires a bucket only for bucket providers', () {
      final missing = _base.copyWith(bucket: '');
      expect(
        validateCloudSyncConfiguration(missing, credential: _s3)['bucket'],
        isNotNull,
      );
      expect(
        validateCloudSyncConfiguration(missing, credential: _drive)['bucket'],
        isNull,
      );
    });

    test('rejects an out-of-range transfer count', () {
      expect(
        validateCloudSyncConfiguration(
          _base.copyWith(transfers: 0),
          credential: _s3,
        )['transfers'],
        isNotNull,
      );
      expect(
        validateCloudSyncConfiguration(
          _base.copyWith(transfers: 100),
          credential: _s3,
        )['transfers'],
        isNotNull,
      );
    });

    test('a new encrypted task needs a password', () {
      final errors = validateCloudSyncConfiguration(
        _base.copyWith(encryption: true),
        credential: _s3,
      );
      expect(errors['encryptionPassword'], isNotNull);
    });

    test('an existing encrypted task may keep its stored password', () {
      final errors = validateCloudSyncConfiguration(
        _base.copyWith(id: 12, encryption: true),
        credential: _s3,
      );
      expect(errors['encryptionPassword'], isNull);
    });

    test('validates the schedule', () {
      final errors = validateCloudSyncConfiguration(
        _base.copyWith(schedule: const TaskSchedule(hour: 'nope')),
        credential: _s3,
      );
      expect(errors['hour'], isNotNull);
    });
  });
}
