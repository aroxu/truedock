typedef AclJson = Map<String, dynamic>;

enum DatasetAclType { nfs4, posix1e }

enum DatasetAclAccess { none, traverse, read, write, modify, fullControl }

enum DatasetAclPrincipalKind { user, group }

class DatasetAclPrincipal {
  const DatasetAclPrincipal({
    required this.name,
    required this.id,
    required this.kind,
  });

  final String name;
  final int id;
  final DatasetAclPrincipalKind kind;
}

class DatasetAcl {
  const DatasetAcl({
    required this.path,
    required this.type,
    required this.entries,
    required this.uid,
    required this.gid,
    this.user,
    this.group,
    this.nfs41Flags = const {},
  });

  factory DatasetAcl.fromJson(AclJson json) {
    final rawType = json['acltype']?.toString().toUpperCase();
    return DatasetAcl(
      path: json['path']?.toString() ?? '',
      type: rawType == 'NFS4' ? DatasetAclType.nfs4 : DatasetAclType.posix1e,
      entries: [
        for (final entry
            in json['acl'] is List ? json['acl'] as List : const [])
          if (entry is Map)
            DatasetAclEntry.fromJson(Map<String, dynamic>.from(entry)),
      ],
      uid: (json['uid'] as num?)?.toInt(),
      gid: (json['gid'] as num?)?.toInt(),
      user: json['user']?.toString(),
      group: json['group']?.toString(),
      nfs41Flags: _copyMap(json['nfs41_flags']),
    );
  }

  final String path;
  final DatasetAclType type;
  final List<DatasetAclEntry> entries;
  final int? uid;
  final int? gid;
  final String? user;
  final String? group;
  final AclJson nfs41Flags;

  DatasetAcl copyWith({
    DatasetAclType? type,
    List<DatasetAclEntry>? entries,
    int? uid,
    int? gid,
    String? user,
    String? group,
    AclJson? nfs41Flags,
  }) => DatasetAcl(
    path: path,
    type: type ?? this.type,
    entries: entries ?? this.entries,
    uid: uid ?? this.uid,
    gid: gid ?? this.gid,
    user: user ?? this.user,
    group: group ?? this.group,
    nfs41Flags: nfs41Flags ?? this.nfs41Flags,
  );

  /// Converts the ACL entries between the two structures TrueNAS accepts.
  /// Named user/group grants retain their coarse access level. Inheritance,
  /// deny rules, and POSIX default entries have no lossless counterpart and
  /// are intentionally rebuilt as ordinary allow/inherit entries.
  DatasetAcl convertedTo(DatasetAclType target) {
    if (target == type) return this;
    final converted = <DatasetAclEntry>[];
    for (final entry in entries) {
      if (type == DatasetAclType.posix1e && entry.isDefault == true) continue;
      final tag = switch ((target, entry.tag)) {
        (DatasetAclType.nfs4, 'USER_OBJ') => 'owner@',
        (DatasetAclType.nfs4, 'GROUP_OBJ') => 'group@',
        (DatasetAclType.nfs4, 'OTHER') => 'everyone@',
        (DatasetAclType.nfs4, 'MASK') => null,
        (DatasetAclType.posix1e, 'owner@') => 'USER_OBJ',
        (DatasetAclType.posix1e, 'group@') => 'GROUP_OBJ',
        (DatasetAclType.posix1e, 'everyone@') => 'OTHER',
        (_, 'USER') => 'USER',
        (_, 'GROUP') => 'GROUP',
        _ => null,
      };
      if (tag == null) continue;
      converted.add(
        DatasetAclEntry(
          tag: tag,
          type: target == DatasetAclType.nfs4 ? 'ALLOW' : null,
          permissions: const {},
          flags: target == DatasetAclType.nfs4
              ? const {'BASIC': 'INHERIT'}
              : const {},
          id: tag == 'USER' || tag == 'GROUP' ? entry.id : -1,
          who: tag == 'USER' || tag == 'GROUP' ? entry.who : null,
          isDefault: target == DatasetAclType.posix1e ? false : null,
        ).withAccess(entry.access, target),
      );
    }

    if (target == DatasetAclType.posix1e &&
        converted.any((entry) => entry.isNamed) &&
        !converted.any((entry) => entry.tag == 'MASK')) {
      converted.add(
        const DatasetAclEntry(
          tag: 'MASK',
          permissions: {'READ': true, 'WRITE': true, 'EXECUTE': true},
          id: -1,
          isDefault: false,
        ),
      );
    }
    return DatasetAcl(
      path: path,
      type: target,
      entries: converted,
      uid: uid,
      gid: gid,
      user: user,
      group: group,
      nfs41Flags: target == DatasetAclType.nfs4
          ? const {'autoinherit': false, 'protected': false, 'defaulted': false}
          : const {},
    );
  }

  AclJson toSetApiJson({required bool recursive}) => {
    'path': path,
    'dacl': [for (final entry in entries) entry.toApiJson(type)],
    'acltype': type == DatasetAclType.nfs4 ? 'NFS4' : 'POSIX1E',
    if (uid != null) 'uid': uid,
    if (gid != null) 'gid': gid,
    if (type == DatasetAclType.nfs4 && nfs41Flags.isNotEmpty)
      'nfs41_flags': nfs41Flags,
    'options': {
      'recursive': recursive,
      'traverse': false,
      'stripacl': false,
      'canonicalize': true,
      'validate_effective_acl': true,
    },
  };
}

class DatasetAclEntry {
  const DatasetAclEntry({
    required this.tag,
    required this.permissions,
    this.type,
    this.flags = const {},
    this.id,
    this.who,
    this.isDefault,
  });

  factory DatasetAclEntry.fromJson(AclJson json) => DatasetAclEntry(
    tag: json['tag']?.toString() ?? 'OTHER',
    type: json['type']?.toString(),
    permissions: _copyMap(json['perms']),
    flags: _copyMap(json['flags']),
    id: (json['id'] as num?)?.toInt(),
    who: json['who']?.toString(),
    isDefault: json['default'] as bool?,
  );

  final String tag;
  final String? type;
  final AclJson permissions;
  final AclJson flags;
  final int? id;
  final String? who;
  final bool? isDefault;

  bool get isNamed => tag == 'USER' || tag == 'GROUP';
  bool get canRemove => isNamed && flags['INHERITED'] != true;

  String get displayName => switch (tag) {
    'owner@' || 'USER_OBJ' => 'Owner',
    'group@' || 'GROUP_OBJ' => 'Owner group',
    'everyone@' || 'OTHER' => 'Everyone',
    'MASK' => 'Mask',
    _ => who?.isNotEmpty == true ? who! : '${tag.toLowerCase()} ${id ?? ''}',
  };

  DatasetAclAccess get access {
    final basic = permissions['BASIC']?.toString();
    if (basic == 'FULL_CONTROL') return DatasetAclAccess.fullControl;
    if (basic == 'MODIFY') return DatasetAclAccess.modify;
    if (basic == 'READ') return DatasetAclAccess.read;
    if (basic == 'TRAVERSE') return DatasetAclAccess.traverse;
    final read =
        permissions['READ'] == true || permissions['READ_DATA'] == true;
    final write =
        permissions['WRITE'] == true || permissions['WRITE_DATA'] == true;
    final execute = permissions['EXECUTE'] == true;
    if (!read && !write && !execute) return DatasetAclAccess.none;
    if (read && write && execute) return DatasetAclAccess.fullControl;
    if (read && write) return DatasetAclAccess.modify;
    if (write) return DatasetAclAccess.write;
    if (read) return DatasetAclAccess.read;
    return DatasetAclAccess.traverse;
  }

  DatasetAclEntry withAccess(DatasetAclAccess access, DatasetAclType aclType) {
    final next = aclType == DatasetAclType.nfs4
        ? <String, dynamic>{'BASIC': _nfs4AccessName(access)}
        : <String, dynamic>{
            'READ':
                access == DatasetAclAccess.read ||
                access == DatasetAclAccess.fullControl,
            'WRITE':
                access == DatasetAclAccess.write ||
                access == DatasetAclAccess.fullControl,
            'EXECUTE':
                access == DatasetAclAccess.traverse ||
                access == DatasetAclAccess.fullControl,
          };
    return DatasetAclEntry(
      tag: tag,
      type: type,
      permissions: next,
      flags: flags,
      id: id,
      who: who,
      isDefault: isDefault,
    );
  }

  DatasetAclEntry withPosixPermissions({
    bool? read,
    bool? write,
    bool? execute,
  }) => DatasetAclEntry(
    tag: tag,
    type: type,
    permissions: {
      'READ': read ?? permissions['READ'] == true,
      'WRITE': write ?? permissions['WRITE'] == true,
      'EXECUTE': execute ?? permissions['EXECUTE'] == true,
    },
    flags: flags,
    id: id,
    who: who,
    isDefault: isDefault,
  );

  AclJson toApiJson(DatasetAclType aclType) => {
    'tag': tag,
    if (aclType == DatasetAclType.nfs4) 'type': type ?? 'ALLOW',
    'perms': permissions,
    if (aclType == DatasetAclType.nfs4)
      'flags': flags.isEmpty ? const {'BASIC': 'INHERIT'} : flags,
    if (aclType == DatasetAclType.posix1e) 'default': isDefault ?? false,
    if (id != null) 'id': id,
    // getacl(resolve_ids: true) returns both fields, while setacl accepts only
    // one principal identifier. Prefer the stable numeric id when available.
    if (id == null && who != null) 'who': who,
  };

  static DatasetAclEntry named(
    DatasetAclPrincipal principal,
    DatasetAclType type,
  ) => DatasetAclEntry(
    tag: principal.kind == DatasetAclPrincipalKind.user ? 'USER' : 'GROUP',
    type: type == DatasetAclType.nfs4 ? 'ALLOW' : null,
    permissions: type == DatasetAclType.nfs4
        ? const {'BASIC': 'READ'}
        : const {'READ': true, 'WRITE': false, 'EXECUTE': true},
    flags: type == DatasetAclType.nfs4 ? const {'BASIC': 'INHERIT'} : const {},
    id: principal.id,
    who: principal.name,
    isDefault: type == DatasetAclType.posix1e ? false : null,
  );
}

String _nfs4AccessName(DatasetAclAccess access) => switch (access) {
  // POSIX has exact none/write-only modes while the NFS4 BASIC vocabulary
  // does not. ACL type conversion is already explicitly lossy and warned in
  // the UI, so choose the closest BASIC permission during that conversion.
  DatasetAclAccess.none => 'TRAVERSE',
  DatasetAclAccess.traverse => 'TRAVERSE',
  DatasetAclAccess.read => 'READ',
  DatasetAclAccess.write => 'MODIFY',
  DatasetAclAccess.modify => 'MODIFY',
  DatasetAclAccess.fullControl => 'FULL_CONTROL',
};

AclJson _copyMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
