import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/domain/dataset_acl.dart';

void main() {
  test('POSIX access presets emit exact rwx bits', () {
    const entry = DatasetAclEntry(
      tag: 'USER',
      permissions: {},
      id: 1000,
      isDefault: false,
    );

    expect(
      entry
          .withAccess(DatasetAclAccess.none, DatasetAclType.posix1e)
          .permissions,
      {'READ': false, 'WRITE': false, 'EXECUTE': false},
    );
    expect(
      entry
          .withAccess(DatasetAclAccess.fullControl, DatasetAclType.posix1e)
          .permissions,
      {'READ': true, 'WRITE': true, 'EXECUTE': true},
    );
    expect(
      entry
          .withAccess(DatasetAclAccess.read, DatasetAclType.posix1e)
          .permissions,
      {'READ': true, 'WRITE': false, 'EXECUTE': false},
    );
    expect(
      entry
          .withAccess(DatasetAclAccess.write, DatasetAclType.posix1e)
          .permissions,
      {'READ': false, 'WRITE': true, 'EXECUTE': false},
    );
    expect(
      entry
          .withAccess(DatasetAclAccess.traverse, DatasetAclType.posix1e)
          .permissions,
      {'READ': false, 'WRITE': false, 'EXECUTE': true},
    );
  });

  test(
    'POSIX permission checks update one bit without changing the others',
    () {
      const entry = DatasetAclEntry(
        tag: 'USER',
        permissions: {'READ': true, 'WRITE': false, 'EXECUTE': true},
        id: 1000,
        isDefault: false,
      );

      expect(entry.withPosixPermissions(write: true).permissions, {
        'READ': true,
        'WRITE': true,
        'EXECUTE': true,
      });
      expect(entry.withPosixPermissions(read: false).permissions, {
        'READ': false,
        'WRITE': false,
        'EXECUTE': true,
      });
    },
  );

  test('converts POSIX ACL to NFS4 while retaining named access', () {
    final source = DatasetAcl.fromJson(const {
      'path': '/mnt/tank/media',
      'acltype': 'POSIX1E',
      'acl': [
        {
          'tag': 'USER_OBJ',
          'perms': {'READ': true, 'WRITE': true, 'EXECUTE': true},
          'default': false,
          'id': -1,
        },
        {
          'tag': 'USER',
          'perms': {'READ': true, 'WRITE': false, 'EXECUTE': true},
          'default': false,
          'id': 1000,
        },
        {
          'tag': 'MASK',
          'perms': {'READ': true, 'WRITE': true, 'EXECUTE': true},
          'default': false,
          'id': -1,
        },
      ],
    });

    final converted = source.convertedTo(DatasetAclType.nfs4);

    expect(converted.type, DatasetAclType.nfs4);
    expect(converted.entries.map((entry) => entry.tag), ['owner@', 'USER']);
    expect(converted.entries.last.id, 1000);
    expect(converted.entries.last.access, DatasetAclAccess.read);
    expect(converted.entries.every((entry) => entry.type == 'ALLOW'), isTrue);
  });

  test('converts NFS4 ACL to complete POSIX entries and adds mask', () {
    final source = DatasetAcl.fromJson(const {
      'path': '/mnt/tank/media',
      'acltype': 'NFS4',
      'acl': [
        {
          'tag': 'owner@',
          'type': 'ALLOW',
          'perms': {'BASIC': 'FULL_CONTROL'},
          'flags': {'BASIC': 'INHERIT'},
          'id': -1,
        },
        {
          'tag': 'GROUP',
          'type': 'DENY',
          'perms': {'BASIC': 'MODIFY'},
          'flags': {'BASIC': 'NOINHERIT'},
          'id': 1000,
        },
      ],
    });

    final converted = source.convertedTo(DatasetAclType.posix1e);

    expect(converted.type, DatasetAclType.posix1e);
    expect(converted.entries.map((entry) => entry.tag), [
      'USER_OBJ',
      'GROUP',
      'MASK',
    ]);
    expect(converted.entries.every((entry) => entry.type == null), isTrue);
    expect(converted.nfs41Flags, isEmpty);
  });
}
