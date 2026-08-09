// Uses meta rather than flutter/foundation so this pure-domain type loads on
// the Dart VM, letting tool/live_mutation_probe.dart send the app's own payload.
import 'package:meta/meta.dart';

typedef SmbAclJson = Map<String, dynamic>;

/// SMB permission role applied to a share ACL entry.
///
/// TrueNAS exposes the standard Windows share-permission roles. The numeric
/// `value` ranks the role so the parser can pick the strongest role when the
/// server returns a list of permissions.
enum SmbSharePermission {
  none('NONE', 0),
  read('READ', 1),
  change('CHANGE', 2),
  full('FULL', 3);

  const SmbSharePermission(this.apiName, this.value);

  final String apiName;
  final int value;

  static SmbSharePermission fromApiName(String? name) {
    for (final p in SmbSharePermission.values) {
      if (p.apiName == name) return p;
    }
    return SmbSharePermission.none;
  }
}

/// Whether an ACL entry grants or denies its permission.
enum SmbAclPermType {
  allowed,
  denied;

  String get apiName => switch (this) {
    SmbAclPermType.allowed => 'ALLOWED',
    SmbAclPermType.denied => 'DENIED',
  };

  static SmbAclPermType fromApi(String? value) =>
      value == 'DENIED' ? SmbAclPermType.denied : SmbAclPermType.allowed;
}

/// The kind of principal an ACL entry names: a local user or a group.
enum SmbAclPrincipalKind {
  user,
  group,
  other;

  String get prefix => switch (this) {
    SmbAclPrincipalKind.user => 'user',
    SmbAclPrincipalKind.group => 'group',
    SmbAclPrincipalKind.other => 'other',
  };

  static SmbAclPrincipalKind fromQualified(String qualifiedName) {
    if (qualifiedName.startsWith('user:')) return SmbAclPrincipalKind.user;
    if (qualifiedName.startsWith('group:')) return SmbAclPrincipalKind.group;
    return SmbAclPrincipalKind.other;
  }
}

/// A single SMB share ACL entry.
///
/// TrueNAS identifies the principal by name (`ae_who_str`) or SID
/// (`ae_who_sid`), and splits the permission into `ae_type` (allow/deny) and
/// `ae_perm` (the role). TrueDock keeps a qualified `user:`/`group:` name for
/// display and sends the bare name, because the share-ACL UI presents one role
/// per principal. Verified against a live 25.10 server by
/// `tool/live_mutation_probe.dart`.
@immutable
class SmbAclEntry {
  const SmbAclEntry({
    required this.qualifiedName,
    required this.kind,
    required this.permission,
    required this.permType,
    this.sid,
    this.unixId,
  });

  factory SmbAclEntry.fromJson(SmbAclJson json) {
    // The server names the principal with ae_who_str (or a SID). Derive the
    // user:/group: prefix from ae_who_id.id_type when it is present, since the
    // bare name alone does not say which it is.
    final who = _nullableString(json['ae_who_str']);
    final whoId = json['ae_who_id'];
    final idType = whoId is Map ? whoId['id_type'] : null;
    final kind = switch (idType) {
      'USER' => SmbAclPrincipalKind.user,
      'GROUP' => SmbAclPrincipalKind.group,
      _ =>
        who == null
            ? SmbAclPrincipalKind.other
            : SmbAclPrincipalKind.fromQualified(who),
    };
    final qualified = who == null
        ? _string(json['ae_who_sid'], fallback: '')
        : (who.contains(':') ? who : '${kind.prefix}:$who');
    return SmbAclEntry(
      qualifiedName: qualified,
      kind: kind,
      permission: SmbSharePermission.fromApiName(json['ae_perm'] as String?),
      permType: SmbAclPermType.fromApi(json['ae_type'] as String?),
      sid: _nullableString(json['ae_who_sid']),
      unixId: whoId is Map && whoId['id'] is int ? whoId['id'] as int : null,
    );
  }

  final String qualifiedName;
  final SmbAclPrincipalKind kind;
  final SmbSharePermission permission;
  final SmbAclPermType permType;
  final String? sid;

  /// The principal's Unix UID/GID, when the server reported one.
  ///
  /// `sharing.smb.setacl` identifies a principal by SID or by Unix ID; a bare
  /// `ae_who_str` name makes the middleware raise a TypeError rather than a
  /// validation error, so one of these must be present.
  final int? unixId;

  /// The bare principal name without the `user:`/`group:` prefix, for display.
  String get principalName {
    final colon = qualifiedName.indexOf(':');
    return colon == -1 ? qualifiedName : qualifiedName.substring(colon + 1);
  }

  SmbAclEntry copyWith({
    String? qualifiedName,
    SmbAclPrincipalKind? kind,
    SmbSharePermission? permission,
    SmbAclPermType? permType,
    String? sid,
    int? unixId,
  }) => SmbAclEntry(
    qualifiedName: qualifiedName ?? this.qualifiedName,
    kind: kind ?? this.kind,
    permission: permission ?? this.permission,
    permType: permType ?? this.permType,
    sid: sid ?? this.sid,
    unixId: unixId ?? this.unixId,
  );

  /// Payload for `sharing.smb.setacl`.
  ///
  /// `ae_perm` is a scalar role, not a list. The principal must be identified
  /// by SID or Unix ID: passing only `ae_who_str` makes the middleware raise
  /// a TypeError. Verified against a live 25.10 server.
  SmbAclJson toApiJson() => {
    'ae_type': permType.apiName,
    'ae_perm': permission.apiName,
    if (sid != null && sid!.isNotEmpty)
      'ae_who_sid': sid
    else if (unixId != null)
      'ae_who_id': {
        'id_type': kind == SmbAclPrincipalKind.group ? 'GROUP' : 'USER',
        'id': unixId,
      }
    else
      'ae_who_str': principalName,
  };

  /// Whether this entry can be sent to `sharing.smb.setacl`.
  ///
  /// An entry the app built from a name alone cannot be, so the editor
  /// resolves the principal's SID or Unix ID before saving.
  bool get canSend => (sid != null && sid!.isNotEmpty) || unixId != null;

  @override
  bool operator ==(Object other) =>
      other is SmbAclEntry &&
      other.qualifiedName == qualifiedName &&
      other.permission == permission &&
      other.permType == permType;

  @override
  int get hashCode => Object.hash(qualifiedName, permission, permType);
}

/// Builds a qualified name for a local principal.
String smbQualifiedPrincipalName(SmbAclPrincipalKind kind, String name) {
  if (name.contains(':')) return name;
  return '${kind.prefix}:$name';
}

String _string(Object? value, {required String fallback}) =>
    value is String && value.isNotEmpty ? value : fallback;

String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
