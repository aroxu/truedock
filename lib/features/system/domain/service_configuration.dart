import 'package:meta/meta.dart';

/// The services whose configuration TrueDock can edit.
///
/// Each maps to a `<service>.config` / `<service>.update` pair. Grouped into one
/// type because the surfaces are structurally identical — read a flat object,
/// send back only what changed — and a separate model per service would be five
/// copies of the same partial-update logic.
enum ConfigurableService { ssh, smb, nfs, ftp, snmp }

extension ConfigurableServiceApi on ConfigurableService {
  /// Namespace used by both the read and the update method.
  String get namespace => switch (this) {
    ConfigurableService.ssh => 'ssh',
    ConfigurableService.smb => 'smb',
    ConfigurableService.nfs => 'nfs',
    ConfigurableService.ftp => 'ftp',
    ConfigurableService.snmp => 'snmp',
  };

  String get configMethod => '$namespace.config';
  String get updateMethod => '$namespace.update';

  /// The `service.query` name, which does not always match the namespace: SMB
  /// is `cifs` and SSH is `ssh`, so the mapping is explicit.
  String get serviceName => switch (this) {
    ConfigurableService.ssh => 'ssh',
    ConfigurableService.smb => 'cifs',
    ConfigurableService.nfs => 'nfs',
    ConfigurableService.ftp => 'ftp',
    ConfigurableService.snmp => 'snmp',
  };
}

/// Stable codes for service configuration validation failures.
enum ServiceValidationCode { required, integerRange, invalidText }

@immutable
class ServiceValidationIssue {
  const ServiceValidationIssue(
    this.code,
    this.field, {
    this.minimum,
    this.maximum,
  });

  final ServiceValidationCode code;

  /// The field key, so the presentation layer can label the error.
  final String field;
  final int? minimum;
  final int? maximum;
}

/// How a single editable field behaves, so the editor can be generated from a
/// description rather than hand-built five times.
enum ServiceFieldKind { text, integer, toggle, choice }

@immutable
class ServiceField {
  const ServiceField({
    required this.key,
    required this.kind,
    this.minimum,
    this.maximum,
    this.choices = const [],
    this.nullable = false,
    this.secret = false,
  });

  /// API field name, sent verbatim.
  final String key;
  final ServiceFieldKind kind;
  final int? minimum;
  final int? maximum;

  /// Allowed values for [ServiceFieldKind.choice], in server order.
  final List<String> choices;

  /// Whether the server accepts null, which is how an optional port is cleared.
  final bool nullable;

  /// Whether the value is a shared secret. Secret fields are never prefilled
  /// from the server response and are only sent when the user types one.
  final bool secret;
}

/// The fields TrueDock exposes per service.
///
/// A deliberate subset of what each `update` accepts: these are the settings an
/// administrator changes from a phone. Everything omitted keeps its server value
/// because updates are partial, so a narrow editor cannot damage the rest of the
/// configuration.
const serviceFields = <ConfigurableService, List<ServiceField>>{
  ConfigurableService.ssh: [
    ServiceField(
      key: 'tcpport',
      kind: ServiceFieldKind.integer,
      minimum: 1,
      maximum: 65535,
    ),
    ServiceField(key: 'passwordauth', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'kerberosauth', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'tcpfwd', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'compression', kind: ServiceFieldKind.toggle),
  ],
  ConfigurableService.smb: [
    ServiceField(key: 'netbiosname', kind: ServiceFieldKind.text),
    ServiceField(key: 'workgroup', kind: ServiceFieldKind.text),
    ServiceField(key: 'description', kind: ServiceFieldKind.text),
    ServiceField(
      key: 'encryption',
      kind: ServiceFieldKind.choice,
      choices: ['DEFAULT', 'NEGOTIATE', 'DESIRED', 'REQUIRED'],
    ),
    ServiceField(key: 'localmaster', kind: ServiceFieldKind.toggle),
    // Both of these weaken authentication, so they are surfaced rather than
    // hidden: a server with them on should be visible from the app.
    ServiceField(key: 'enable_smb1', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'ntlmv1_auth', kind: ServiceFieldKind.toggle),
  ],
  ConfigurableService.nfs: [
    ServiceField(
      key: 'servers',
      kind: ServiceFieldKind.integer,
      minimum: 1,
      maximum: 256,
      nullable: true,
    ),
    ServiceField(key: 'allow_nonroot', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'v4_domain', kind: ServiceFieldKind.text),
    ServiceField(
      key: 'mountd_port',
      kind: ServiceFieldKind.integer,
      minimum: 1,
      maximum: 65535,
      nullable: true,
    ),
    ServiceField(key: 'rdma', kind: ServiceFieldKind.toggle),
  ],
  ConfigurableService.ftp: [
    ServiceField(
      key: 'port',
      kind: ServiceFieldKind.integer,
      minimum: 1,
      maximum: 65535,
    ),
    ServiceField(
      key: 'clients',
      kind: ServiceFieldKind.integer,
      minimum: 1,
      maximum: 10000,
    ),
    ServiceField(
      key: 'loginattempt',
      kind: ServiceFieldKind.integer,
      minimum: 0,
      maximum: 1000,
    ),
    ServiceField(
      key: 'timeout',
      kind: ServiceFieldKind.integer,
      minimum: 0,
      maximum: 10000,
    ),
    ServiceField(key: 'tls', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'onlyanonymous', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'onlylocal', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'defaultroot', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'resume', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'banner', kind: ServiceFieldKind.text),
  ],
  ConfigurableService.snmp: [
    // SNMP v1/v2c authenticates with the community string, so it is treated as
    // a secret: never prefilled, never logged, only sent when typed.
    ServiceField(key: 'community', kind: ServiceFieldKind.text, secret: true),
    ServiceField(key: 'contact', kind: ServiceFieldKind.text),
    ServiceField(key: 'location', kind: ServiceFieldKind.text),
    ServiceField(
      key: 'loglevel',
      kind: ServiceFieldKind.integer,
      minimum: 0,
      maximum: 7,
    ),
    ServiceField(key: 'traps', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'zilstat', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'v3', kind: ServiceFieldKind.toggle),
    ServiceField(key: 'v3_username', kind: ServiceFieldKind.text),
    ServiceField(
      key: 'v3_authtype',
      kind: ServiceFieldKind.choice,
      choices: ['', 'MD5', 'SHA'],
    ),
    ServiceField(key: 'v3_password', kind: ServiceFieldKind.text, secret: true),
    ServiceField(
      key: 'v3_privproto',
      kind: ServiceFieldKind.choice,
      choices: ['', 'AES', 'DES'],
      nullable: true,
    ),
    ServiceField(
      key: 'v3_privpassphrase',
      kind: ServiceFieldKind.text,
      secret: true,
    ),
  ],
};

/// A service's current configuration, as the raw object the server returned.
///
/// Kept as a map rather than a typed model per service: TrueDock edits a subset
/// and must not reshape the rest, and a typed model would have to enumerate
/// every field of five different services to avoid dropping them.
@immutable
class ServiceConfiguration {
  const ServiceConfiguration({required this.service, required this.values});

  final ConfigurableService service;
  final Map<String, Object?> values;

  /// The fields TrueDock exposes for this service.
  List<ServiceField> get fields => serviceFields[service] ?? const [];

  Object? operator [](String key) => values[key];

  String text(String key) {
    final value = values[key];
    return value == null ? '' : '$value';
  }

  bool flag(String key) => values[key] == true;

  int? integer(String key) {
    final value = values[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// A partial service configuration edit.
@immutable
class ServiceConfigurationEdit {
  const ServiceConfigurationEdit({
    required this.service,
    required this.changes,
  });

  final ConfigurableService service;
  final Map<String, Object?> changes;

  List<ServiceValidationIssue> validate() {
    final issues = <ServiceValidationIssue>[];
    final fields = {
      for (final field in serviceFields[service] ?? const <ServiceField>[])
        field.key: field,
    };
    for (final entry in changes.entries) {
      final field = fields[entry.key];
      if (field == null) continue;
      final value = entry.value;
      switch (field.kind) {
        case ServiceFieldKind.integer:
          if (value == null) {
            // Clearing an optional port is how it is unset, so null is only a
            // problem on a field the server requires.
            if (!field.nullable) {
              issues.add(
                ServiceValidationIssue(
                  ServiceValidationCode.required,
                  field.key,
                ),
              );
            }
            break;
          }
          final number = value is int ? value : int.tryParse('$value');
          if (number == null ||
              (field.minimum != null && number < field.minimum!) ||
              (field.maximum != null && number > field.maximum!)) {
            issues.add(
              ServiceValidationIssue(
                ServiceValidationCode.integerRange,
                field.key,
                minimum: field.minimum,
                maximum: field.maximum,
              ),
            );
          }
        case ServiceFieldKind.choice:
          if (value != null &&
              !field.choices.contains('$value') &&
              !(field.nullable && '$value'.isEmpty)) {
            issues.add(
              ServiceValidationIssue(
                ServiceValidationCode.invalidText,
                field.key,
              ),
            );
          }
        case ServiceFieldKind.text:
        case ServiceFieldKind.toggle:
          break;
      }
    }
    return issues;
  }

  Map<String, Object?> toApiJson() => Map<String, Object?>.from(changes);

  bool get isEmpty => changes.isEmpty;

  /// True when the payload carries a shared secret, so callers avoid logging it.
  bool get carriesSecret {
    final secrets = {
      for (final field in serviceFields[service] ?? const <ServiceField>[])
        if (field.secret) field.key,
    };
    return changes.keys.any(secrets.contains);
  }
}
