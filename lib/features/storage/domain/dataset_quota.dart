// Uses meta rather than flutter/foundation so this pure-domain type loads on
// the Dart VM, letting tool/live_quota_probe.dart send the app's own payload.
import 'package:meta/meta.dart';

/// Who a quota applies to.
///
/// The API's `quota_type` enum is asymmetric and the asymmetry is load-bearing:
/// `pool.dataset.set_quota` accepts `USER`, `USEROBJ`, `GROUP`, `GROUPOBJ` and
/// `DATASET`, but `pool.dataset.get_quota` rejects the `*OBJ` variants outright
/// ("Input should be 'USER', 'GROUP', 'DATASET' or 'PROJECT'"). Object quotas
/// are *written* under their own type and *read back* as an `obj_quota` field on
/// the plain USER/GROUP row. Modelling the subject separately from the two
/// limits it carries is what keeps that from leaking into every call site.
enum QuotaSubject {
  user('USER', 'USEROBJ'),
  group('GROUP', 'GROUPOBJ');

  const QuotaSubject(this.spaceType, this.objectType);

  /// `quota_type` for the space limit, and the only value `get_quota` accepts.
  final String spaceType;

  /// `quota_type` for the file-count limit. Write-only; see the class comment.
  final String objectType;

  static QuotaSubject? fromApi(String? value) => switch (value?.toUpperCase()) {
    'USER' || 'USEROBJ' => QuotaSubject.user,
    'GROUP' || 'GROUPOBJ' => QuotaSubject.group,
    _ => null,
  };
}

/// One account's usage and limits on a dataset, from `pool.dataset.get_quota`.
@immutable
class DatasetQuota {
  const DatasetQuota({
    required this.subject,
    required this.id,
    required this.name,
    this.usedBytes = 0,
    this.objectsUsed = 0,
    this.quotaBytes = 0,
    this.objectQuota = 0,
  });

  factory DatasetQuota.fromJson(Map<String, dynamic> json) => DatasetQuota(
    subject:
        QuotaSubject.fromApi(json['quota_type'] as String?) ??
        QuotaSubject.user,
    id: json['id'] is int ? json['id'] as int : -1,
    name: json['name'] is String && (json['name'] as String).isNotEmpty
        ? json['name'] as String
        // A uid with no matching account still has to be identifiable, or an
        // orphaned quota becomes impossible to find and clear.
        : '${json['id']}',
    usedBytes: _int(json['used_bytes']),
    objectsUsed: _int(json['obj_used']),
    quotaBytes: _int(json['quota']),
    objectQuota: _int(json['obj_quota']),
  );

  final QuotaSubject subject;

  /// Numeric uid or gid. The server returns a number here but *accepts* either
  /// a name or a number as a string when setting.
  final int id;
  final String name;
  final int usedBytes;
  final int objectsUsed;

  /// Space limit in bytes. Zero means no limit, which is also how one is
  /// removed - the API has no separate "clear" call.
  final int quotaBytes;

  /// File-count limit. Zero means no limit.
  final int objectQuota;

  bool get hasSpaceQuota => quotaBytes > 0;
  bool get hasObjectQuota => objectQuota > 0;

  /// True when this row only records usage, with nothing limiting it. Every
  /// account that has ever written to the dataset appears, so most rows are
  /// this and the list would be noise without the distinction.
  bool get hasAnyQuota => hasSpaceQuota || hasObjectQuota;

  /// Fraction of the space limit consumed, or null when unlimited.
  double? get spaceUsedFraction =>
      hasSpaceQuota ? (usedBytes / quotaBytes).clamp(0.0, 1.0) : null;

  /// Fraction of the object limit consumed, or null when unlimited.
  double? get objectUsedFraction =>
      hasObjectQuota ? (objectsUsed / objectQuota).clamp(0.0, 1.0) : null;

  /// True when the account is already over a limit it has been given. ZFS
  /// enforces this by refusing writes, so it is a failure state rather than a
  /// warning.
  bool get isOverQuota =>
      (hasSpaceQuota && usedBytes >= quotaBytes) ||
      (hasObjectQuota && objectsUsed >= objectQuota);
}

/// Stable codes for quota validation failures, localized by the presentation
/// layer.
enum QuotaValidationCode {
  targetRequired,
  reservedTarget,
  negativeValue,
  nothingToApply,
}

@immutable
class QuotaValidationIssue {
  const QuotaValidationIssue(this.code, {this.field});

  final QuotaValidationCode code;
  final String? field;
}

/// A quota change to apply to one account.
///
/// Space and object limits are separate `quota_type` values on the wire, so a
/// single edit can expand into two entries. Null means "leave alone"; zero means
/// "remove", which is the API's own convention rather than an invention here.
@immutable
class DatasetQuotaEdit {
  const DatasetQuotaEdit({
    required this.subject,
    required this.target,
    this.spaceBytes,
    this.objectCount,
  });

  final QuotaSubject subject;

  /// A username/group name or a numeric id. Sent as a string either way; the
  /// server resolves it and rejects unknown accounts, so no local account list
  /// is required for correctness.
  final String target;

  /// New space limit in bytes. Zero removes it. Null leaves it unchanged.
  final int? spaceBytes;

  /// New file-count limit. Zero removes it. Null leaves it unchanged.
  final int? objectCount;

  bool get isEmpty => spaceBytes == null && objectCount == null;

  List<QuotaValidationIssue> validate() {
    final issues = <QuotaValidationIssue>[];
    final trimmed = target.trim();
    if (trimmed.isEmpty) {
      issues.add(
        const QuotaValidationIssue(
          QuotaValidationCode.targetRequired,
          field: 'target',
        ),
      );
    } else if (subject == QuotaSubject.user && trimmed == '0' ||
        subject == QuotaSubject.user && trimmed.toLowerCase() == 'root') {
      // The server refuses this with "Setting user quota on uid [0] is not
      // permitted". Catching it locally explains why instead of surfacing a
      // raw EINVAL after a round trip.
      issues.add(
        const QuotaValidationIssue(
          QuotaValidationCode.reservedTarget,
          field: 'target',
        ),
      );
    }
    if ((spaceBytes ?? 0) < 0) {
      issues.add(
        const QuotaValidationIssue(
          QuotaValidationCode.negativeValue,
          field: 'space',
        ),
      );
    }
    if ((objectCount ?? 0) < 0) {
      issues.add(
        const QuotaValidationIssue(
          QuotaValidationCode.negativeValue,
          field: 'objects',
        ),
      );
    }
    if (isEmpty) {
      issues.add(
        const QuotaValidationIssue(QuotaValidationCode.nothingToApply),
      );
    }
    return issues;
  }

  /// Payload entries for `pool.dataset.set_quota`.
  ///
  /// One edit becomes up to two entries because the space and object limits are
  /// distinct `quota_type` values. Unchanged limits are omitted rather than sent
  /// as zero, which would silently remove them.
  List<Map<String, Object?>> toApiJson() {
    final trimmed = target.trim();
    return [
      if (spaceBytes case final bytes?)
        {'quota_type': subject.spaceType, 'id': trimmed, 'quota_value': bytes},
      if (objectCount case final count?)
        {'quota_type': subject.objectType, 'id': trimmed, 'quota_value': count},
    ];
  }
}

int _int(Object? value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : 0;
