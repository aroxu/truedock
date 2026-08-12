import 'package:meta/meta.dart';

/// Audit services TrueNAS records events for.
///
/// `MIDDLEWARE` is the one that matters for TrueDock: every administrative API
/// call lands there, including the ones this app makes. `SMB` and `SUDO` are
/// recorded separately and are included so the filter matches what the server
/// reports as enabled.
enum AuditService {
  middleware('MIDDLEWARE'),
  smb('SMB'),
  sudo('SUDO');

  const AuditService(this.apiValue);

  final String apiValue;

  static AuditService? fromApi(Object? value) {
    for (final service in values) {
      if (service.apiValue == value) return service;
    }
    return null;
  }
}

/// The kinds of event the middleware audit records.
enum AuditEventKind {
  authentication('AUTHENTICATION'),
  logout('LOGOUT'),
  methodCall('METHOD_CALL'),
  other('');

  const AuditEventKind(this.apiValue);

  final String apiValue;

  static AuditEventKind fromApi(Object? value) {
    for (final kind in values) {
      if (kind != AuditEventKind.other && kind.apiValue == value) return kind;
    }
    return AuditEventKind.other;
  }
}

/// One audit record from `audit.query`.
///
/// Parsed from the live 25.10.5 response rather than the docs, because two
/// details are not obvious: `timestamp` is wrapped as `{"$date": millis}` while
/// `message_timestamp` is bare epoch seconds, and the interesting content of a
/// `METHOD_CALL` — which method ran, and whether it was authorized — lives inside
/// `event_data` rather than at the top level.
@immutable
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.event,
    required this.rawEvent,
    required this.succeeded,
    this.timestamp,
    this.username,
    this.address,
    this.service,
    this.method,
    this.description,
    this.authenticated = true,
    this.authorized = true,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    final eventData = json['event_data'];
    final data = eventData is Map ? eventData : const {};
    return AuditEntry(
      id: '${json['audit_id'] ?? ''}',
      event: AuditEventKind.fromApi(json['event']),
      // Kept so an event kind TrueDock does not model still displays as itself
      // rather than as a blank row.
      rawEvent: '${json['event'] ?? ''}',
      succeeded: json['success'] != false,
      timestamp: _parseTimestamp(json),
      username: json['username'] is String ? json['username'] as String : null,
      address: json['address'] is String ? json['address'] as String : null,
      service: AuditService.fromApi(json['service']),
      method: data['method'] is String ? data['method'] as String : null,
      // The server supplies a human description for many calls, which is far
      // more useful in a list than the raw method name.
      description: data['description'] is String
          ? data['description'] as String
          : null,
      authenticated: data['authenticated'] != false,
      authorized: data['authorized'] != false,
    );
  }

  final String id;
  final AuditEventKind event;
  final String rawEvent;

  /// Whether the audited operation succeeded. A failed privileged call is the
  /// most interesting row in the log, so this drives the list's emphasis.
  final bool succeeded;
  final DateTime? timestamp;
  final String? username;
  final String? address;
  final AuditService? service;

  /// API method for a `METHOD_CALL`, absent for authentication events.
  final String? method;
  final String? description;
  final bool authenticated;
  final bool authorized;

  /// True when the record shows an operation that was refused rather than
  /// carried out. Worth separating from a plain failure: this is an access
  /// control event, not an error.
  bool get wasDenied => !authenticated || !authorized;

  /// The best single label for a list row.
  String get label {
    final text = description ?? method;
    if (text != null && text.isNotEmpty) return text;
    return rawEvent.isEmpty ? id : rawEvent;
  }

  /// Timestamps arrive in two shapes; prefer the wrapped one because it carries
  /// milliseconds, and fall back to the bare epoch seconds.
  static DateTime? _parseTimestamp(Map<String, dynamic> json) {
    final wrapped = json['timestamp'];
    if (wrapped is Map) {
      final millis = wrapped[r'$date'];
      if (millis is int) {
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
      }
    }
    final seconds = json['message_timestamp'];
    if (seconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    return null;
  }
}

/// A query against the audit log.
///
/// `audit.query` nests its filters and options under hyphenated keys
/// (`query-filters`, `query-options`) rather than the usual positional
/// `[filters, options]` pair every other query method uses, so the payload is
/// built explicitly instead of reusing the shared query helper.
@immutable
class AuditQuery {
  const AuditQuery({
    this.services = const [AuditService.middleware],
    this.limit = 100,
    this.username,
    this.onlyFailures = false,
  });

  final List<AuditService> services;
  final int limit;

  /// Restricts the log to one account, which is the usual question: what did
  /// this user do.
  final String? username;

  /// Restricts the log to failed or denied operations.
  final bool onlyFailures;

  Map<String, Object?> toApiJson() {
    final filters = <Object?>[
      if (username != null && username!.trim().isNotEmpty)
        ['username', '=', username!.trim()],
      if (onlyFailures) ['success', '=', false],
    ];
    return <String, Object?>{
      'services': [for (final service in services) service.apiValue],
      'query-filters': filters,
      'query-options': {
        'limit': limit,
        // Newest first: an audit log is read from the most recent event
        // backwards, and the server's default order is the opposite.
        'order_by': ['-message_timestamp'],
      },
    };
  }

  AuditQuery copyWith({
    List<AuditService>? services,
    int? limit,
    String? username,
    bool? onlyFailures,
  }) => AuditQuery(
    services: services ?? this.services,
    limit: limit ?? this.limit,
    username: username ?? this.username,
    onlyFailures: onlyFailures ?? this.onlyFailures,
  );
}

/// `audit.config`: retention and the space the audit databases consume.
@immutable
class AuditConfiguration {
  const AuditConfiguration({
    required this.retentionDays,
    required this.quotaGiB,
    required this.quotaFillWarning,
    required this.quotaFillCritical,
    this.usedBytes = 0,
    this.availableBytes = 0,
    this.remoteLoggingEnabled = false,
    this.enabledServices = const [],
  });

  factory AuditConfiguration.fromJson(Map<String, dynamic> json) {
    final space = json['space'];
    final spaceMap = space is Map ? space : const {};
    final services = json['enabled_services'];
    return AuditConfiguration(
      retentionDays: json['retention'] is int ? json['retention'] as int : 0,
      quotaGiB: json['quota'] is int ? json['quota'] as int : 0,
      quotaFillWarning: json['quota_fill_warning'] is int
          ? json['quota_fill_warning'] as int
          : 0,
      quotaFillCritical: json['quota_fill_critical'] is int
          ? json['quota_fill_critical'] as int
          : 0,
      usedBytes: spaceMap['used'] is int ? spaceMap['used'] as int : 0,
      availableBytes: spaceMap['available'] is int
          ? spaceMap['available'] as int
          : 0,
      remoteLoggingEnabled: json['remote_logging_enabled'] == true,
      enabledServices: services is Map
          ? [
              for (final key in services.keys)
                if (AuditService.fromApi(key) != null)
                  AuditService.fromApi(key)!,
            ]
          : const [],
    );
  }

  /// Days of audit history kept before records are pruned.
  final int retentionDays;

  /// Quota in GiB, where 0 means the dataset is uncapped.
  final int quotaGiB;
  final int quotaFillWarning;
  final int quotaFillCritical;
  final int usedBytes;
  final int availableBytes;
  final bool remoteLoggingEnabled;
  final List<AuditService> enabledServices;

  bool get isUncapped => quotaGiB == 0;
}

/// Stable codes for audit configuration validation failures.
enum AuditValidationCode { retentionRange, quotaRange, fillOrder }

@immutable
class AuditValidationIssue {
  const AuditValidationIssue(this.code, {this.minimum, this.maximum});
  final AuditValidationCode code;
  final int? minimum;
  final int? maximum;
}

/// An audit retention edit, for `audit.update`.
@immutable
class AuditConfigurationEdit {
  const AuditConfigurationEdit({
    this.retentionDays,
    this.quotaGiB,
    this.quotaFillWarning,
    this.quotaFillCritical,
  });

  final int? retentionDays;
  final int? quotaGiB;
  final int? quotaFillWarning;
  final int? quotaFillCritical;

  List<AuditValidationIssue> validate() {
    final issues = <AuditValidationIssue>[];
    final retention = retentionDays;
    if (retention != null && (retention < 1 || retention > 30)) {
      issues.add(
        const AuditValidationIssue(
          AuditValidationCode.retentionRange,
          minimum: 1,
          maximum: 30,
        ),
      );
    }
    final quota = quotaGiB;
    if (quota != null && (quota < 0 || quota > 100)) {
      issues.add(
        const AuditValidationIssue(
          AuditValidationCode.quotaRange,
          minimum: 0,
          maximum: 100,
        ),
      );
    }
    final warning = quotaFillWarning;
    final critical = quotaFillCritical;
    if (warning != null && (warning < 5 || warning > 80)) {
      issues.add(
        const AuditValidationIssue(
          AuditValidationCode.quotaRange,
          minimum: 5,
          maximum: 80,
        ),
      );
    }
    if (critical != null && (critical < 50 || critical > 95)) {
      issues.add(
        const AuditValidationIssue(
          AuditValidationCode.quotaRange,
          minimum: 50,
          maximum: 95,
        ),
      );
    }
    // A critical threshold at or below the warning would fire both alerts at
    // once, which makes the warning useless.
    if (warning != null && critical != null && critical <= warning) {
      issues.add(const AuditValidationIssue(AuditValidationCode.fillOrder));
    }
    return issues;
  }

  Map<String, Object?> toApiJson() => <String, Object?>{
    if (retentionDays != null) 'retention': retentionDays,
    if (quotaGiB != null) 'quota': quotaGiB,
    if (quotaFillWarning != null) 'quota_fill_warning': quotaFillWarning,
    if (quotaFillCritical != null) 'quota_fill_critical': quotaFillCritical,
  };

  bool get isEmpty => toApiJson().isEmpty;
}
