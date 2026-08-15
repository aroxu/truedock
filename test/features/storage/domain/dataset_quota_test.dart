import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/storage/domain/dataset_quota.dart';

void main() {
  group('DatasetQuota.fromJson', () {
    test('parses the shape get_quota actually returns', () {
      // Taken from a live 25.10.5 response. Note `quota`/`obj_quota` rather
      // than the `quota_value` name used when writing.
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'USER',
        'id': 950,
        'name': 'truenas_admin',
        'used_bytes': 1024,
        'obj_used': 2,
        'quota': 2147483648,
        'obj_quota': 5000,
      });

      expect(quota.subject, QuotaSubject.user);
      expect(quota.name, 'truenas_admin');
      expect(quota.quotaBytes, 2147483648);
      expect(quota.objectQuota, 5000);
      expect(quota.hasAnyQuota, isTrue);
    });

    test('a usage-only row is not treated as having a quota', () {
      // The server returns every account that has ever written, limit or not.
      // Most rows look like this, so the list would be noise without the
      // distinction.
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'USER',
        'id': 0,
        'name': 'root',
        'used_bytes': 1024,
        'obj_used': 2,
      });

      expect(quota.hasAnyQuota, isFalse);
      expect(quota.spaceUsedFraction, isNull);
      expect(quota.isOverQuota, isFalse);
    });

    test('an account with no matching name stays identifiable by id', () {
      // A quota can outlive the account it was set for. Falling back to a
      // blank name would make it impossible to find and clear.
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'GROUP',
        'id': 1234,
        'used_bytes': 0,
        'quota': 1024,
      });

      expect(quota.name, '1234');
      expect(quota.subject, QuotaSubject.group);
    });

    test('reaching the limit counts as over quota', () {
      // ZFS refuses writes at the limit, not past it.
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'USER',
        'id': 1,
        'name': 'alice',
        'used_bytes': 1024,
        'quota': 1024,
      });

      expect(quota.isOverQuota, isTrue);
      expect(quota.spaceUsedFraction, 1.0);
    });

    test('usage past the limit does not report more than a full bar', () {
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'USER',
        'id': 1,
        'name': 'alice',
        'used_bytes': 4096,
        'quota': 1024,
      });

      expect(quota.spaceUsedFraction, 1.0);
    });

    test('an object limit alone is still a quota', () {
      final quota = DatasetQuota.fromJson(const {
        'quota_type': 'USER',
        'id': 1,
        'name': 'alice',
        'obj_used': 10,
        'obj_quota': 100,
      });

      expect(quota.hasSpaceQuota, isFalse);
      expect(quota.hasAnyQuota, isTrue);
      expect(quota.objectUsedFraction, closeTo(0.1, 0.0001));
    });
  });

  group('DatasetQuotaEdit.toApiJson', () {
    test('splits one edit into the two quota_type values the API needs', () {
      // set_quota has no combined entry: the space and object limits are
      // separate types, even though they read back on one row.
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
        spaceBytes: 2147483648,
        objectCount: 5000,
      );

      expect(edit.toApiJson(), [
        {'quota_type': 'USER', 'id': 'alice', 'quota_value': 2147483648},
        {'quota_type': 'USEROBJ', 'id': 'alice', 'quota_value': 5000},
      ]);
    });

    test('groups use their own pair of types', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.group,
        target: 'staff',
        spaceBytes: 1024,
        objectCount: 10,
      );

      expect(edit.toApiJson().map((entry) => entry['quota_type']).toList(), [
        'GROUP',
        'GROUPOBJ',
      ]);
    });

    test('an untouched limit is omitted rather than sent as zero', () {
      // Zero means "remove" to the server, so sending it for a field the user
      // did not touch would silently clear an existing limit.
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
        spaceBytes: 1024,
      );

      expect(edit.toApiJson(), hasLength(1));
      expect(edit.toApiJson().single['quota_type'], 'USER');
    });

    test('zero is sent through, because that is how a limit is removed', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
        spaceBytes: 0,
        objectCount: 0,
      );

      expect(edit.toApiJson().map((entry) => entry['quota_value']).toList(), [
        0,
        0,
      ]);
    });

    test('the target is trimmed so a stray space cannot fail server-side', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: '  alice  ',
        spaceBytes: 1024,
      );

      expect(edit.toApiJson().single['id'], 'alice');
    });
  });

  group('DatasetQuotaEdit.validate', () {
    test('accepts an ordinary edit', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
        spaceBytes: 1024,
      );

      expect(edit.validate(), isEmpty);
    });

    test('rejects root, which the server refuses anyway', () {
      // Caught locally so the user gets an explanation instead of a raw EINVAL
      // after a round trip. The live probe proves the server really refuses it.
      const byName = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'root',
        spaceBytes: 1024,
      );
      const byId = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: '0',
        spaceBytes: 1024,
      );

      expect(byName.validate().single.code, QuotaValidationCode.reservedTarget);
      expect(byId.validate().single.code, QuotaValidationCode.reservedTarget);
    });

    test('gid 0 is allowed; only user quotas are restricted', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.group,
        target: 'root',
        spaceBytes: 1024,
      );

      expect(edit.validate(), isEmpty);
    });

    test('requires a target', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: '   ',
        spaceBytes: 1024,
      );

      expect(
        edit.validate().map((issue) => issue.code),
        contains(QuotaValidationCode.targetRequired),
      );
    });

    test('rejects a negative limit', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
        spaceBytes: -1,
      );

      expect(
        edit.validate().map((issue) => issue.code),
        contains(QuotaValidationCode.negativeValue),
      );
    });

    test('refuses an edit that would change nothing', () {
      const edit = DatasetQuotaEdit(
        subject: QuotaSubject.user,
        target: 'alice',
      );

      expect(
        edit.validate().map((issue) => issue.code),
        contains(QuotaValidationCode.nothingToApply),
      );
    });
  });

  group('QuotaSubject', () {
    test('maps both the space and object type names back to one subject', () {
      // get_quota rejects the *OBJ names, but they still arrive on the way in
      // when echoing a payload, so both must resolve.
      expect(QuotaSubject.fromApi('USER'), QuotaSubject.user);
      expect(QuotaSubject.fromApi('USEROBJ'), QuotaSubject.user);
      expect(QuotaSubject.fromApi('GROUP'), QuotaSubject.group);
      expect(QuotaSubject.fromApi('GROUPOBJ'), QuotaSubject.group);
      expect(QuotaSubject.fromApi('DATASET'), isNull);
    });
  });
}
