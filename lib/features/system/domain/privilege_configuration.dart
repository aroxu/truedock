import 'package:meta/meta.dart';

/// Stable codes for privilege validation failures.
enum PrivilegeValidationCode { nameRequired, rolesRequired, builtinImmutable }

@immutable
class PrivilegeValidationIssue {
  const PrivilegeValidationIssue(this.code);
  final PrivilegeValidationCode code;
}

/// One role a privilege can grant, from `privilege.roles`.
///
/// Roles compose: `ACCOUNT_WRITE` includes `ACCOUNT_READ`, so granting the
/// write role grants the read role implicitly. Surfacing [includes] is what lets
/// the UI explain why a privilege is broader than the roles literally listed on
/// it.
@immutable
class PrivilegeRole {
  const PrivilegeRole({
    required this.name,
    required this.title,
    this.includes = const [],
    this.builtin = true,
  });

  factory PrivilegeRole.fromJson(Map<String, dynamic> json) => PrivilegeRole(
    name: json['name'] is String ? json['name'] as String : '',
    title: json['title'] is String && (json['title'] as String).isNotEmpty
        ? json['title'] as String
        : '${json['name'] ?? ''}',
    includes: json['includes'] is List
        ? (json['includes'] as List).whereType<String>().toList(growable: false)
        : const [],
    builtin: json['builtin'] != false,
  );

  final String name;
  final String title;

  /// Roles this one implies.
  final List<String> includes;
  final bool builtin;

  /// `FULL_ADMIN` grants everything, so selecting it makes every other role
  /// redundant and is worth calling out rather than treating as one more row.
  bool get isFullAdmin => name == 'FULL_ADMIN';
}

/// A privilege: a set of roles granted to local or directory groups.
@immutable
class Privilege {
  const Privilege({
    required this.id,
    required this.name,
    required this.roles,
    required this.webShell,
    this.builtinName,
    this.localGroupIds = const [],
    this.localGroupNames = const [],
    this.directoryGroups = const [],
  });

  factory Privilege.fromJson(Map<String, dynamic> json) {
    final localGroups = json['local_groups'];
    final groupList = localGroups is List ? localGroups : const [];
    return Privilege(
      id: json['id'] is int ? json['id'] as int : -1,
      name: json['name'] is String ? json['name'] as String : '',
      roles: json['roles'] is List
          ? (json['roles'] as List).whereType<String>().toList(growable: false)
          : const [],
      webShell: json['web_shell'] == true,
      // Present only on the three privileges TrueNAS ships. Those cannot be
      // deleted, and editing them is how an administrator locks themselves out,
      // so the UI has to know which is which.
      builtinName: json['builtin_name'] is String
          ? json['builtin_name'] as String
          : null,
      // `local_groups` is expanded into full group objects on read but takes
      // plain gids on write, so both are kept: ids to send, names to show.
      localGroupIds: [
        for (final group in groupList)
          if (group is Map && group['id'] is int) group['id'] as int,
      ],
      localGroupNames: [
        for (final group in groupList)
          if (group is Map && group['name'] is String) group['name'] as String,
      ],
      directoryGroups: json['ds_groups'] is List
          ? (json['ds_groups'] as List)
                .map((value) => '$value')
                .toList(growable: false)
          : const [],
    );
  }

  final int id;
  final String name;
  final List<String> roles;

  /// Whether members may open the web shell, which is effectively root access
  /// regardless of the roles granted.
  final bool webShell;
  final String? builtinName;
  final List<int> localGroupIds;
  final List<String> localGroupNames;
  final List<String> directoryGroups;

  /// Built-in privileges cannot be deleted and should not be casually edited.
  bool get isBuiltin => builtinName != null;

  bool get grantsFullAdmin => roles.contains('FULL_ADMIN');

  /// Roles granted directly plus everything they imply, so the UI can show the
  /// effective set rather than only what was literally selected.
  Set<String> effectiveRoles(List<PrivilegeRole> catalog) {
    final byName = {for (final role in catalog) role.name: role};
    final effective = <String>{};
    void visit(String name) {
      if (!effective.add(name)) return;
      for (final included in byName[name]?.includes ?? const <String>[]) {
        visit(included);
      }
    }

    for (final role in roles) {
      visit(role);
    }
    return effective;
  }
}

/// A create or update payload for `privilege.*`.
@immutable
class PrivilegeConfiguration {
  const PrivilegeConfiguration({
    required this.name,
    required this.roles,
    this.webShell = false,
    this.localGroupIds = const [],
    this.directoryGroups = const [],
  });

  final String name;
  final List<String> roles;
  final bool webShell;

  /// Local group ids. The read response expands these into objects, but the
  /// write side takes bare integers.
  final List<int> localGroupIds;
  final List<String> directoryGroups;

  List<PrivilegeValidationIssue> validate() {
    final issues = <PrivilegeValidationIssue>[];
    if (name.trim().isEmpty) {
      issues.add(
        const PrivilegeValidationIssue(PrivilegeValidationCode.nameRequired),
      );
    }
    // A privilege with no roles and no shell grants nothing; the server accepts
    // it, which makes it look configured while doing nothing at all.
    if (roles.isEmpty && !webShell) {
      issues.add(
        const PrivilegeValidationIssue(PrivilegeValidationCode.rolesRequired),
      );
    }
    return issues;
  }

  Map<String, Object?> toApiJson() => <String, Object?>{
    'name': name.trim(),
    'roles': roles,
    'web_shell': webShell,
    'local_groups': localGroupIds,
    'ds_groups': directoryGroups,
  };

  /// True when this grants unrestricted administration, by role or by shell.
  ///
  /// Both paths are equivalent in practice: the web shell runs as root, so it
  /// bypasses whatever the role list restricts.
  bool get grantsUnrestrictedAccess => roles.contains('FULL_ADMIN') || webShell;

  PrivilegeConfiguration copyWith({
    String? name,
    List<String>? roles,
    bool? webShell,
    List<int>? localGroupIds,
    List<String>? directoryGroups,
  }) => PrivilegeConfiguration(
    name: name ?? this.name,
    roles: roles ?? this.roles,
    webShell: webShell ?? this.webShell,
    localGroupIds: localGroupIds ?? this.localGroupIds,
    directoryGroups: directoryGroups ?? this.directoryGroups,
  );

  /// Seeds an editor from an existing privilege.
  static PrivilegeConfiguration from(Privilege privilege) =>
      PrivilegeConfiguration(
        name: privilege.name,
        roles: privilege.roles,
        webShell: privilege.webShell,
        localGroupIds: privilege.localGroupIds,
        directoryGroups: privilege.directoryGroups,
      );
}
