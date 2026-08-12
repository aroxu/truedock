import 'package:meta/meta.dart';

/// Destinations `alertservice.*` can deliver alerts to.
///
/// The API discriminates on an `attributes.type` string, so the enum carries the
/// exact wire value rather than a prettified name.
enum AlertServiceKind {
  mail('Mail'),
  slack('Slack'),
  telegram('Telegram'),
  pagerDuty('PagerDuty'),
  mattermost('Mattermost'),
  opsGenie('OpsGenie'),
  victorOps('VictorOps'),
  awsSns('AWSSNS'),
  influxDb('InfluxDB'),
  snmpTrap('SNMPTrap');

  const AlertServiceKind(this.apiValue);

  final String apiValue;

  static AlertServiceKind? fromApi(Object? value) {
    for (final kind in values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// Minimum severity an alert must reach before a service is notified.
enum AlertLevel {
  info('INFO'),
  notice('NOTICE'),
  warning('WARNING'),
  error('ERROR'),
  critical('CRITICAL'),
  alert('ALERT'),
  emergency('EMERGENCY');

  const AlertLevel(this.apiValue);

  final String apiValue;

  static AlertLevel fromApi(Object? value) {
    for (final level in values) {
      if (level.apiValue == value) return level;
    }
    return AlertLevel.warning;
  }
}

/// One attribute of an alert destination.
@immutable
class AlertServiceField {
  const AlertServiceField({
    required this.key,
    this.required = false,
    this.secret = false,
    this.integer = false,
    this.integerList = false,
    this.choices = const [],
  });

  /// API attribute name, sent verbatim inside `attributes`.
  final String key;
  final bool required;

  /// Whether the value is a credential: never prefilled from the server, and
  /// only sent when the user types one.
  final bool secret;
  final bool integer;

  /// Comma-separated integers, which is how Telegram takes its chat ids.
  final bool integerList;

  /// Allowed values, where the first entry is the server's null/default.
  final List<String> choices;
}

/// Attributes per destination, mirroring the discriminated schema.
///
/// Only the fields each variant declares are listed: `alertservice.create`
/// validates `attributes` against one exact variant, so an extra key from
/// another destination fails the whole call.
const alertServiceFields = <AlertServiceKind, List<AlertServiceField>>{
  AlertServiceKind.mail: [AlertServiceField(key: 'email')],
  AlertServiceKind.slack: [
    AlertServiceField(key: 'url', required: true, secret: true),
  ],
  AlertServiceKind.telegram: [
    AlertServiceField(key: 'bot_token', required: true, secret: true),
    AlertServiceField(key: 'chat_ids', required: true, integerList: true),
  ],
  AlertServiceKind.pagerDuty: [
    AlertServiceField(key: 'service_key', required: true, secret: true),
    AlertServiceField(key: 'client_name', required: true),
  ],
  AlertServiceKind.mattermost: [
    AlertServiceField(key: 'url', required: true, secret: true),
    AlertServiceField(key: 'username', required: true),
    AlertServiceField(key: 'channel'),
    AlertServiceField(key: 'icon_url'),
  ],
  AlertServiceKind.opsGenie: [
    AlertServiceField(key: 'api_key', required: true, secret: true),
    AlertServiceField(key: 'api_url'),
  ],
  AlertServiceKind.victorOps: [
    AlertServiceField(key: 'api_key', required: true, secret: true),
    AlertServiceField(key: 'routing_key', required: true),
  ],
  AlertServiceKind.awsSns: [
    AlertServiceField(key: 'region', required: true),
    AlertServiceField(key: 'topic_arn', required: true),
    // Both halves are credentials. `aws_access_key_id` is the one whose name
    // does not look like a secret, which is exactly why it needs marking.
    AlertServiceField(key: 'aws_access_key_id', required: true, secret: true),
    AlertServiceField(
      key: 'aws_secret_access_key',
      required: true,
      secret: true,
    ),
  ],
  AlertServiceKind.influxDb: [
    AlertServiceField(key: 'host', required: true),
    AlertServiceField(key: 'username', required: true),
    AlertServiceField(key: 'password', required: true, secret: true),
    AlertServiceField(key: 'database', required: true),
    AlertServiceField(key: 'series_name', required: true),
  ],
  AlertServiceKind.snmpTrap: [
    AlertServiceField(key: 'host', required: true),
    AlertServiceField(key: 'port', required: true, integer: true),
    AlertServiceField(key: 'community', secret: true),
    AlertServiceField(key: 'v3_username'),
    AlertServiceField(key: 'v3_authkey', secret: true),
    AlertServiceField(
      key: 'v3_authprotocol',
      choices: [
        '',
        'MD5',
        'SHA',
        '128SHA224',
        '192SHA256',
        '256SHA384',
        '384SHA512',
      ],
    ),
    AlertServiceField(key: 'v3_privkey', secret: true),
  ],
};

/// Stable codes for alert service validation failures.
enum AlertServiceValidationCode {
  nameRequired,
  attributeRequired,
  attributeInvalidInteger,
  attributeInvalidUrl,
}

@immutable
class AlertServiceValidationIssue {
  const AlertServiceValidationIssue(this.code, {this.field});
  final AlertServiceValidationCode code;

  /// Attribute key, when the failure is about one.
  final String? field;
}

/// An alert destination, from `alertservice.query`.
@immutable
class AlertServiceEntry {
  const AlertServiceEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.level,
    required this.enabled,
    this.attributes = const {},
  });

  factory AlertServiceEntry.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    final map = attributes is Map
        ? {for (final entry in attributes.entries) '${entry.key}': entry.value}
        : const <String, Object?>{};
    return AlertServiceEntry(
      id: json['id'] is int ? json['id'] as int : -1,
      name: json['name'] is String ? json['name'] as String : '',
      // `type` sits inside attributes on 25.10, not at the top level.
      kind: AlertServiceKind.fromApi(map['type'] ?? json['type']),
      level: AlertLevel.fromApi(json['level']),
      enabled: json['enabled'] != false,
      attributes: map,
    );
  }

  final int id;
  final String name;

  /// Null when the server reports a destination TrueDock does not model, which
  /// is shown read-only rather than offered for editing.
  final AlertServiceKind? kind;
  final AlertLevel level;
  final bool enabled;
  final Map<String, Object?> attributes;

  String attribute(String key) {
    final value = attributes[key];
    if (value == null) return '';
    if (value is List) return value.join(', ');
    return '$value';
  }
}

/// A create or update payload for `alertservice.*`.
@immutable
class AlertServiceConfiguration {
  const AlertServiceConfiguration({
    required this.name,
    required this.kind,
    required this.level,
    required this.attributes,
    this.enabled = true,
  });

  final String name;
  final AlertServiceKind kind;
  final AlertLevel level;

  /// Raw attribute values as typed by the user, keyed by API name.
  final Map<String, String> attributes;
  final bool enabled;

  List<AlertServiceField> get fields => alertServiceFields[kind] ?? const [];

  List<AlertServiceValidationIssue> validate() {
    final issues = <AlertServiceValidationIssue>[];
    if (name.trim().isEmpty) {
      issues.add(
        const AlertServiceValidationIssue(
          AlertServiceValidationCode.nameRequired,
        ),
      );
    }
    for (final field in fields) {
      final raw = attributes[field.key]?.trim() ?? '';
      if (field.required && raw.isEmpty) {
        issues.add(
          AlertServiceValidationIssue(
            AlertServiceValidationCode.attributeRequired,
            field: field.key,
          ),
        );
        continue;
      }
      if (raw.isEmpty) continue;
      if (field.integer && int.tryParse(raw) == null) {
        issues.add(
          AlertServiceValidationIssue(
            AlertServiceValidationCode.attributeInvalidInteger,
            field: field.key,
          ),
        );
      }
      if (field.integerList && _parseIntegerList(raw) == null) {
        issues.add(
          AlertServiceValidationIssue(
            AlertServiceValidationCode.attributeInvalidInteger,
            field: field.key,
          ),
        );
      }
      // Webhook destinations take a URI; the server enforces `format: uri`, and
      // a malformed one there returns an opaque validation dump.
      if (field.key == 'url' ||
          field.key == 'api_url' ||
          field.key == 'icon_url') {
        final uri = Uri.tryParse(raw);
        if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
          issues.add(
            AlertServiceValidationIssue(
              AlertServiceValidationCode.attributeInvalidUrl,
              field: field.key,
            ),
          );
        }
      }
    }
    return issues;
  }

  /// Payload for `alertservice.create` / `update` / `test`.
  ///
  /// [storedSecrets] supplies the values behind blank credential fields, which
  /// is how an edit keeps a secret the user did not retype. Omitting the field
  /// is not an option: `alertservice.update` rejects the call with "field
  /// required" for a variant's required secret, so the value has to be present.
  /// The editor still never prefills a secret on screen, so this is the only
  /// place a stored credential is read back.
  Map<String, Object?> toApiJson({
    Map<String, Object?> storedSecrets = const {},
  }) {
    final payload = <String, Object?>{'type': kind.apiValue};
    for (final field in fields) {
      var raw = attributes[field.key]?.trim() ?? '';
      if (raw.isEmpty && field.secret) {
        final stored = storedSecrets[field.key];
        if (stored != null && '$stored'.isNotEmpty) raw = '$stored';
      }
      if (raw.isEmpty) {
        if (field.required) continue;
        // A blank optional attribute is sent as null, which is the documented
        // "unset" for the nullable SNMP fields.
        payload[field.key] = field.choices.isNotEmpty ? null : '';
        continue;
      }
      if (field.integer) {
        payload[field.key] = int.tryParse(raw) ?? raw;
      } else if (field.integerList) {
        payload[field.key] = _parseIntegerList(raw) ?? const <int>[];
      } else {
        payload[field.key] = raw;
      }
    }
    return {
      'name': name.trim(),
      'level': level.apiValue,
      'enabled': enabled,
      'attributes': payload,
    };
  }

  /// True when the payload carries a credential, so callers avoid logging it.
  ///
  /// Always true for a variant with a required secret, because the payload
  /// carries one either from the user or from the stored value.
  bool get carriesSecret => fields.any(
    (field) =>
        field.secret &&
        (field.required || (attributes[field.key]?.trim().isNotEmpty ?? false)),
  );
}

/// Parses a comma or space separated integer list, or null when malformed.
List<int>? _parseIntegerList(String raw) {
  final parts = raw
      .split(RegExp(r'[,\s]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;
  final values = <int>[];
  for (final part in parts) {
    final parsed = int.tryParse(part);
    if (parsed == null) return null;
    values.add(parsed);
  }
  return values;
}
