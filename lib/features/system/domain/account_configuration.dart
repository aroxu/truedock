import 'system_resources.dart';

/// A stable code for an account validation failure, so presentation layers can
/// translate the message instead of surfacing the English fallback carried by
/// [AccountConfigurationException.message].
enum AccountValidationCode {
  userNotEditable,
  emailInvalid,
  userUnchanged,
  groupNotEditable,
  groupNameRequired,
  groupNameInvalid,
  groupUnchanged,
  usernameRequired,
  usernameInvalid,
  passwordRequired,
  primaryGroupRequired,
}

/// A stable code for one line of the review step's change summary.
///
/// The review step lists what the payload will change. Presentation layers map
/// the code plus [AccountChange.value] to translated text rather than parsing
/// the English sentence in [AccountChange.description].
enum AccountChangeCode {
  fullNameCleared,
  fullNameSet,
  emailCleared,
  emailSet,
  shellSet,
  smbEnabled,
  smbDisabled,
  accountLocked,
  accountUnlocked,
  passwordSignInDisabled,
  passwordSignInEnabled,
  auxiliaryGroupsSet,
  groupRenamed,
  groupExposedToSmb,
  groupHiddenFromSmb,
  membershipSet,
  otherFieldUpdated,
}

/// One entry in the review step's change summary.
class AccountChange {
  const AccountChange(this.code, this.description, {this.value});

  final AccountChangeCode code;

  /// English fallback for callers without localizations.
  final String description;

  /// The interpolated value, when the code carries one: a name, an address, a
  /// shell path, or a count rendered as a string.
  final String? value;

  @override
  String toString() => description;
}

class AccountConfigurationException implements Exception {
  const AccountConfigurationException(this.code, this.message);

  /// Stable identity of the failure. The UI maps this to translated text.
  final AccountValidationCode code;

  /// English fallback, used by logs and by any caller without localizations.
  final String message;

  @override
  String toString() => message;
}

/// The canonical exception for each validation code, so the domain raises one
/// message per condition and the UI translates from the code.
const _userNotEditable = AccountConfigurationException(
  AccountValidationCode.userNotEditable,
  'Built-in and directory accounts cannot be edited from TrueDock.',
);
const _emailInvalid = AccountConfigurationException(
  AccountValidationCode.emailInvalid,
  'Enter a valid email address or leave it empty.',
);
const _userUnchanged = AccountConfigurationException(
  AccountValidationCode.userUnchanged,
  'Nothing has changed for this user.',
);
const _groupNotEditable = AccountConfigurationException(
  AccountValidationCode.groupNotEditable,
  'Built-in and directory groups cannot be edited from TrueDock.',
);
const _groupNameRequired = AccountConfigurationException(
  AccountValidationCode.groupNameRequired,
  'Enter a group name.',
);
const _groupNameInvalid = AccountConfigurationException(
  AccountValidationCode.groupNameInvalid,
  'A group name cannot contain spaces, colons, or commas.',
);
const _groupUnchanged = AccountConfigurationException(
  AccountValidationCode.groupUnchanged,
  'Nothing has changed for this group.',
);
const _usernameRequired = AccountConfigurationException(
  AccountValidationCode.usernameRequired,
  'Enter a username.',
);
const _usernameInvalid = AccountConfigurationException(
  AccountValidationCode.usernameInvalid,
  'A username must start with a letter or underscore and use only '
  'lowercase letters, digits, hyphens, and underscores.',
);
const _passwordRequired = AccountConfigurationException(
  AccountValidationCode.passwordRequired,
  'Set a password or disable password sign-in.',
);
const _primaryGroupRequired = AccountConfigurationException(
  AccountValidationCode.primaryGroupRequired,
  'Choose a primary group or let TrueNAS create one.',
);

/// A validated `user.update` payload.
///
/// Only changed fields are sent. TrueDock deliberately excludes password and
/// privilege fields here; credential changes are a separate high-risk flow.
class UserUpdateConfiguration {
  const UserUpdateConfiguration({
    required this.fullName,
    required this.email,
    required this.shell,
    required this.smb,
    required this.locked,
    required this.passwordDisabled,
    required this.auxiliaryGroupIds,
  });

  factory UserUpdateConfiguration.fromUser(NasUser user) =>
      UserUpdateConfiguration(
        fullName: user.fullName,
        email: user.email ?? '',
        shell: user.shell ?? '',
        smb: user.smb,
        locked: user.locked,
        passwordDisabled: user.passwordDisabled,
        auxiliaryGroupIds: List.unmodifiable(user.auxiliaryGroupIds),
      );

  final String fullName;
  final String email;
  final String shell;
  final bool smb;
  final bool locked;
  final bool passwordDisabled;
  final List<int> auxiliaryGroupIds;

  UserUpdateConfiguration copyWith({
    String? fullName,
    String? email,
    String? shell,
    bool? smb,
    bool? locked,
    bool? passwordDisabled,
    List<int>? auxiliaryGroupIds,
  }) => UserUpdateConfiguration(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    shell: shell ?? this.shell,
    smb: smb ?? this.smb,
    locked: locked ?? this.locked,
    passwordDisabled: passwordDisabled ?? this.passwordDisabled,
    auxiliaryGroupIds: auxiliaryGroupIds ?? this.auxiliaryGroupIds,
  );

  Map<String, Object?> toApiJson(NasUser original) {
    if (!original.isEditable) {
      throw _userNotEditable;
    }
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty && !_looksLikeEmail(trimmedEmail)) {
      throw _emailInvalid;
    }

    final baseline = UserUpdateConfiguration.fromUser(original);
    final payload = <String, Object?>{};
    if (fullName.trim() != baseline.fullName.trim()) {
      payload['full_name'] = fullName.trim();
    }
    if (trimmedEmail != baseline.email.trim()) {
      // TrueNAS clears the address when null is sent.
      payload['email'] = trimmedEmail.isEmpty ? null : trimmedEmail;
    }
    if (shell.trim() != baseline.shell.trim() && shell.trim().isNotEmpty) {
      payload['shell'] = shell.trim();
    }
    if (smb != baseline.smb) payload['smb'] = smb;
    if (locked != baseline.locked) payload['locked'] = locked;
    if (passwordDisabled != baseline.passwordDisabled) {
      payload['password_disabled'] = passwordDisabled;
    }
    final groups = [...auxiliaryGroupIds]..sort();
    final baseGroups = [...baseline.auxiliaryGroupIds]..sort();
    if (!_sameIds(groups, baseGroups)) payload['groups'] = groups;

    if (payload.isEmpty) {
      throw _userUnchanged;
    }
    return payload;
  }

  /// Human-readable summary used by the review step.
  List<AccountChange> describeChanges(NasUser original) {
    final payload = toApiJson(original);
    return [
      for (final entry in payload.entries)
        switch (entry.key) {
          'full_name' =>
            (entry.value as String).isEmpty
                ? const AccountChange(
                    AccountChangeCode.fullNameCleared,
                    'Full name cleared',
                  )
                : AccountChange(
                    AccountChangeCode.fullNameSet,
                    'Full name set to "${entry.value}"',
                    value: entry.value as String,
                  ),
          'email' =>
            entry.value == null
                ? const AccountChange(
                    AccountChangeCode.emailCleared,
                    'Email address cleared',
                  )
                : AccountChange(
                    AccountChangeCode.emailSet,
                    'Email set to ${entry.value}',
                    value: entry.value.toString(),
                  ),
          'shell' => AccountChange(
            AccountChangeCode.shellSet,
            'Login shell set to ${entry.value}',
            value: entry.value.toString(),
          ),
          'smb' => AccountChange(
            entry.value == true
                ? AccountChangeCode.smbEnabled
                : AccountChangeCode.smbDisabled,
            entry.value == true ? 'SMB access enabled' : 'SMB access disabled',
          ),
          'locked' =>
            entry.value == true
                ? AccountChange(
                    AccountChangeCode.accountLocked,
                    'Account locked — the user can no longer sign in',
                  )
                : AccountChange(
                    AccountChangeCode.accountUnlocked,
                    'Account unlocked',
                  ),
          'password_disabled' =>
            entry.value == true
                ? AccountChange(
                    AccountChangeCode.passwordSignInDisabled,
                    'Password sign-in disabled',
                  )
                : AccountChange(
                    AccountChangeCode.passwordSignInEnabled,
                    'Password sign-in enabled',
                  ),
          'groups' => AccountChange(
            AccountChangeCode.auxiliaryGroupsSet,
            'Auxiliary groups set to '
            '${(entry.value as List<int>).length} group(s)',
            value: '${(entry.value as List<int>).length}',
          ),
          final other => AccountChange(
            AccountChangeCode.otherFieldUpdated,
            '$other updated',
            value: other,
          ),
        },
    ];
  }

  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// A validated `group.update` payload.
class GroupUpdateConfiguration {
  const GroupUpdateConfiguration({
    required this.name,
    required this.smb,
    required this.userIds,
  });

  factory GroupUpdateConfiguration.fromGroup(NasGroup group) =>
      GroupUpdateConfiguration(
        name: group.name,
        smb: group.smb,
        userIds: List.unmodifiable(group.userIds),
      );

  final String name;
  final bool smb;
  final List<int> userIds;

  GroupUpdateConfiguration copyWith({
    String? name,
    bool? smb,
    List<int>? userIds,
  }) => GroupUpdateConfiguration(
    name: name ?? this.name,
    smb: smb ?? this.smb,
    userIds: userIds ?? this.userIds,
  );

  Map<String, Object?> toApiJson(NasGroup original) {
    if (!original.isEditable) {
      throw _groupNotEditable;
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw _groupNameRequired;
    }
    if (RegExp(r'[\s:,]').hasMatch(trimmed)) {
      throw _groupNameInvalid;
    }

    final payload = <String, Object?>{};
    if (trimmed != original.name) payload['name'] = trimmed;
    if (smb != original.smb) payload['smb'] = smb;
    final members = [...userIds]..sort();
    final baseMembers = [...original.userIds]..sort();
    if (!UserUpdateConfiguration._sameIds(members, baseMembers)) {
      payload['users'] = members;
    }

    if (payload.isEmpty) {
      throw _groupUnchanged;
    }
    return payload;
  }

  List<AccountChange> describeChanges(NasGroup original) {
    final payload = toApiJson(original);
    return [
      for (final entry in payload.entries)
        switch (entry.key) {
          'name' => AccountChange(
            AccountChangeCode.groupRenamed,
            'Group renamed to ${entry.value}',
            value: entry.value.toString(),
          ),
          'smb' => AccountChange(
            entry.value == true
                ? AccountChangeCode.groupExposedToSmb
                : AccountChangeCode.groupHiddenFromSmb,
            entry.value == true
                ? 'Group exposed to SMB'
                : 'Group hidden from SMB',
          ),
          'users' => AccountChange(
            AccountChangeCode.membershipSet,
            'Membership set to ${(entry.value as List<int>).length} user(s)',
            value: '${(entry.value as List<int>).length}',
          ),
          final other => AccountChange(
            AccountChangeCode.otherFieldUpdated,
            '$other updated',
            value: other,
          ),
        },
    ];
  }
}

/// A validated `user.create` payload.
///
/// TrueNAS requires either a password or an explicit "no password" account, so
/// the two are modelled as a single deliberate choice rather than an optional
/// field that can be silently left empty.
class UserCreateConfiguration {
  const UserCreateConfiguration({
    required this.username,
    required this.fullName,
    required this.password,
    required this.passwordDisabled,
    required this.smb,
    required this.createGroup,
    required this.primaryGroupId,
    required this.email,
    required this.shell,
  });

  static const defaults = UserCreateConfiguration(
    username: '',
    fullName: '',
    password: '',
    passwordDisabled: false,
    smb: true,
    createGroup: true,
    primaryGroupId: null,
    email: '',
    shell: '/usr/bin/bash',
  );

  final String username;
  final String fullName;
  final String password;
  final bool passwordDisabled;
  final bool smb;

  /// When true TrueNAS creates a matching primary group for the user.
  final bool createGroup;
  final int? primaryGroupId;
  final String email;
  final String shell;

  UserCreateConfiguration copyWith({
    String? username,
    String? fullName,
    String? password,
    bool? passwordDisabled,
    bool? smb,
    bool? createGroup,
    int? primaryGroupId,
    String? email,
    String? shell,
  }) => UserCreateConfiguration(
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    password: password ?? this.password,
    passwordDisabled: passwordDisabled ?? this.passwordDisabled,
    smb: smb ?? this.smb,
    createGroup: createGroup ?? this.createGroup,
    primaryGroupId: primaryGroupId ?? this.primaryGroupId,
    email: email ?? this.email,
    shell: shell ?? this.shell,
  );

  Map<String, Object?> toApiJson() {
    final name = username.trim();
    if (name.isEmpty) {
      throw _usernameRequired;
    }
    if (!RegExp(r'^[a-z_][a-z0-9_-]*\$?$').hasMatch(name)) {
      throw _usernameInvalid;
    }
    if (!passwordDisabled && password.isEmpty) {
      throw _passwordRequired;
    }
    if (!createGroup && primaryGroupId == null) {
      throw _primaryGroupRequired;
    }
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty &&
        !UserUpdateConfiguration._looksLikeEmail(trimmedEmail)) {
      throw _emailInvalid;
    }

    return {
      'username': name,
      'full_name': fullName.trim().isEmpty ? name : fullName.trim(),
      'group_create': createGroup,
      if (!createGroup) 'group': primaryGroupId,
      'smb': smb,
      'password_disabled': passwordDisabled,
      if (!passwordDisabled) 'password': password,
      if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
      if (shell.trim().isNotEmpty) 'shell': shell.trim(),
    };
  }
}

/// A validated `group.create` payload.
class GroupCreateConfiguration {
  const GroupCreateConfiguration({
    required this.name,
    required this.smb,
    required this.userIds,
  });

  static const defaults = GroupCreateConfiguration(
    name: '',
    smb: true,
    userIds: [],
  );

  final String name;
  final bool smb;
  final List<int> userIds;

  GroupCreateConfiguration copyWith({
    String? name,
    bool? smb,
    List<int>? userIds,
  }) => GroupCreateConfiguration(
    name: name ?? this.name,
    smb: smb ?? this.smb,
    userIds: userIds ?? this.userIds,
  );

  Map<String, Object?> toApiJson() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw _groupNameRequired;
    }
    if (RegExp(r'[\s:,]').hasMatch(trimmed)) {
      throw _groupNameInvalid;
    }
    return {
      'name': trimmed,
      'smb': smb,
      'users': [...userIds]..sort(),
    };
  }
}
