import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/domain/dataset_configuration.dart';

void main() {
  test('reads editable properties and their inheritance source', () {
    final dataset = Dataset.fromJson(_datasetJson);

    expect(dataset.comments, 'Project files');
    expect(dataset.quotaBytes, 10737418240);
    expect(dataset.readOnly, isFalse);
    expect(dataset.compression, 'LZ4');
    expect(dataset.sync, 'STANDARD');
    expect(dataset.inherits('compression'), isTrue);
    expect(dataset.inherits('quota'), isFalse);
  });

  test('sends only the properties that actually changed', () {
    final dataset = Dataset.fromJson(_datasetJson);
    final payload = DatasetUpdateConfiguration.fromDataset(
      dataset,
    ).copyWith(readOnly: true).toApiJson(dataset);

    expect(payload, {'readonly': 'ON'});
  });

  test('clears a quota by sending zero', () {
    final dataset = Dataset.fromJson(_datasetJson);
    final payload = DatasetUpdateConfiguration.fromDataset(
      dataset,
    ).copyWith(clearQuota: true).toApiJson(dataset);

    expect(payload, {'quota': 0});
  });

  test('switching an explicit property to inherit sends INHERIT', () {
    final dataset = Dataset.fromJson(_datasetJson);
    final payload = DatasetUpdateConfiguration.fromDataset(
      dataset,
    ).copyWith(quotaMode: DatasetPropertyMode.inherit).toApiJson(dataset);

    expect(payload, {'quota': 'INHERIT'});
  });

  test('an already inherited property is not re-sent', () {
    final dataset = Dataset.fromJson(_datasetJson);

    // compression is inherited on the fixture, so selecting inherit again
    // must not produce a payload entry.
    expect(
      () => DatasetUpdateConfiguration.fromDataset(dataset)
          .copyWith(compressionMode: DatasetPropertyMode.inherit)
          .toApiJson(dataset),
      throwsA(isA<DatasetConfigurationException>()),
    );
  });

  test('rejects an update that would change nothing', () {
    final dataset = Dataset.fromJson(_datasetJson);

    expect(
      () => DatasetUpdateConfiguration.fromDataset(dataset).toApiJson(dataset),
      throwsA(isA<DatasetConfigurationException>()),
    );
  });

  test('describes pending changes for the review step', () {
    final dataset = Dataset.fromJson(_datasetJson);
    final changes = DatasetUpdateConfiguration.fromDataset(
      dataset,
    ).copyWith(readOnly: true, clearQuota: true).describeChanges(dataset);

    expect(
      changes.map((change) => change.code),
      containsAll([
        DatasetChangeCode.readOnlyEnabled,
        DatasetChangeCode.quotaRemoved,
      ]),
    );
  });

  test('builds a rename request against the existing parent path', () {
    final dataset = Dataset.fromJson(_datasetJson);
    final request = DatasetRenameRequest.forDataset(
      dataset,
      newLeafName: 'archive',
      recursive: true,
    );

    expect(request.newName, 'tank/projects/archive');
    expect(request.toApiJson(), {
      'new_name': 'tank/projects/archive',
      'recursive': true,
    });
  });

  test('rejects invalid and no-op rename targets', () {
    final dataset = Dataset.fromJson(_datasetJson);

    for (final name in ['', '  ', 'a/b', 'work']) {
      expect(
        () => DatasetRenameRequest.forDataset(
          dataset,
          newLeafName: name,
          recursive: false,
        ),
        throwsA(isA<DatasetConfigurationException>()),
        reason: 'should reject "$name"',
      );
    }
  });

  test('refuses to rename a pool root dataset', () {
    final root = Dataset.fromJson(const {
      'id': 'tank',
      'name': 'tank',
      'type': 'FILESYSTEM',
    });

    expect(root.isPoolRoot, isTrue);
    expect(
      () => DatasetRenameRequest.forDataset(
        root,
        newLeafName: 'storage',
        recursive: false,
      ),
      throwsA(isA<DatasetConfigurationException>()),
    );
  });

  test('identifies an unlocked passphrase encryption root', () {
    final dataset = Dataset.fromJson(const {
      'id': 'tank/secure',
      'name': 'tank/secure',
      'type': 'FILESYSTEM',
      'encrypted': true,
      'locked': false,
      'key_loaded': true,
      'key_format': {'value': 'PASSPHRASE'},
      'encryption_root': 'tank/secure',
    });

    expect(dataset.isEncryptionRoot, isTrue);
    expect(dataset.usesPassphrase, isTrue);
    expect(dataset.canLock, isTrue);
    expect(dataset.canUnlock, isFalse);
  });

  test('a locked encryption root can only be unlocked', () {
    final dataset = Dataset.fromJson(const {
      'id': 'tank/secure',
      'name': 'tank/secure',
      'type': 'FILESYSTEM',
      'encrypted': true,
      'locked': true,
      'key_format': {'value': 'HEX'},
      'encryption_root': 'tank/secure',
    });

    expect(dataset.canUnlock, isTrue);
    expect(dataset.canLock, isFalse);
    expect(dataset.usesPassphrase, isFalse);
  });

  test('a child inheriting its parent key is not an encryption root', () {
    final child = Dataset.fromJson(const {
      'id': 'tank/secure/docs',
      'name': 'tank/secure/docs',
      'type': 'FILESYSTEM',
      'encrypted': true,
      'locked': true,
      'encryption_root': 'tank/secure',
    });

    // Locking or unlocking must happen on the encryption root instead.
    expect(child.isEncryptionRoot, isFalse);
    expect(child.canLock, isFalse);
    expect(child.canUnlock, isFalse);
  });

  test('an unencrypted dataset exposes no lock actions', () {
    final dataset = Dataset.fromJson(const {
      'id': 'tank/public',
      'name': 'tank/public',
      'type': 'FILESYSTEM',
    });

    expect(dataset.isEncryptionRoot, isFalse);
    expect(dataset.canLock, isFalse);
    expect(dataset.canUnlock, isFalse);
  });
}

const _datasetJson = {
  'id': 'tank/projects/work',
  'name': 'tank/projects/work',
  'type': 'FILESYSTEM',
  'used': {'parsed': 1024},
  'available': {'parsed': 4096},
  'comments': {'value': 'Project files', 'source': 'LOCAL'},
  'quota': {'parsed': 10737418240, 'source': 'LOCAL'},
  'refquota': {'parsed': 0, 'source': 'LOCAL'},
  'readonly': {'value': 'OFF', 'source': 'LOCAL'},
  'compression': {'value': 'LZ4', 'source': 'INHERITED'},
  'sync': {'value': 'STANDARD', 'source': 'LOCAL'},
};
