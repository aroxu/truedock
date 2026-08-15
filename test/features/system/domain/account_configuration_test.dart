import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/account_configuration.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';

void main() {
  test('parses editable user fields and group membership', () {
    final user = NasUser.fromJson(_userJson);

    expect(user.email, 'ada@example.invalid');
    expect(user.shell, '/usr/bin/zsh');
    expect(user.locked, isFalse);
    expect(user.primaryGroupId, 41);
    expect(user.auxiliaryGroupIds, [42, 43]);
    expect(user.isEditable, isTrue);
  });

  test('treats built-in and directory accounts as non-editable', () {
    final builtin = NasUser.fromJson({..._userJson, 'builtin': true});
    final directory = NasUser.fromJson({..._userJson, 'local': false});

    expect(builtin.isEditable, isFalse);
    expect(directory.isEditable, isFalse);
    expect(
      () => UserUpdateConfiguration.fromUser(
        builtin,
      ).copyWith(locked: true).toApiJson(builtin),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('sends only the user fields that changed', () {
    final user = NasUser.fromJson(_userJson);
    final payload = UserUpdateConfiguration.fromUser(
      user,
    ).copyWith(locked: true).toApiJson(user);

    expect(payload, {'locked': true});
  });

  test('clears an email address by sending null', () {
    final user = NasUser.fromJson(_userJson);
    final payload = UserUpdateConfiguration.fromUser(
      user,
    ).copyWith(email: '').toApiJson(user);

    expect(payload, {'email': null});
  });

  test('rejects a malformed email address', () {
    final user = NasUser.fromJson(_userJson);

    expect(
      () => UserUpdateConfiguration.fromUser(
        user,
      ).copyWith(email: 'not-an-address').toApiJson(user),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('sends auxiliary groups as a sorted id list', () {
    final user = NasUser.fromJson(_userJson);
    final payload = UserUpdateConfiguration.fromUser(
      user,
    ).copyWith(auxiliaryGroupIds: [44, 42]).toApiJson(user);

    expect(payload, {
      'groups': [42, 44],
    });
  });

  test('reordering the same groups is not a change', () {
    final user = NasUser.fromJson(_userJson);

    expect(
      () => UserUpdateConfiguration.fromUser(
        user,
      ).copyWith(auxiliaryGroupIds: [43, 42]).toApiJson(user),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('rejects a user update that would change nothing', () {
    final user = NasUser.fromJson(_userJson);

    expect(
      () => UserUpdateConfiguration.fromUser(user).toApiJson(user),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('describes user changes for the review step', () {
    final user = NasUser.fromJson(_userJson);
    final changes = UserUpdateConfiguration.fromUser(
      user,
    ).copyWith(locked: true, smb: false).describeChanges(user);

    expect(
      changes.map((change) => change.code),
      containsAll([
        AccountChangeCode.accountLocked,
        AccountChangeCode.smbDisabled,
      ]),
    );
  });

  test('sends only the group fields that changed', () {
    final group = NasGroup.fromJson(_groupJson);
    final payload = GroupUpdateConfiguration.fromGroup(
      group,
    ).copyWith(userIds: [9, 5]).toApiJson(group);

    expect(payload, {
      'users': [5, 9],
    });
  });

  test('reordering the same members is not a group change', () {
    final group = NasGroup.fromJson(_groupJson);

    expect(
      () => GroupUpdateConfiguration.fromGroup(
        group,
      ).copyWith(userIds: [7, 5]).toApiJson(group),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('rejects group names with separators', () {
    final group = NasGroup.fromJson(_groupJson);

    for (final name in ['', 'has space', 'has:colon', 'has,comma']) {
      expect(
        () => GroupUpdateConfiguration.fromGroup(
          group,
        ).copyWith(name: name).toApiJson(group),
        throwsA(isA<AccountConfigurationException>()),
        reason: 'should reject "$name"',
      );
    }
  });

  test('refuses to edit a built-in group', () {
    final builtin = NasGroup.fromJson({..._groupJson, 'builtin': true});

    expect(builtin.isEditable, isFalse);
    expect(
      () => GroupUpdateConfiguration.fromGroup(
        builtin,
      ).copyWith(smb: true).toApiJson(builtin),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('creates a user with a matching primary group', () {
    final payload = UserCreateConfiguration.defaults
        .copyWith(username: 'ada', password: 'secret')
        .toApiJson();

    expect(payload['username'], 'ada');
    // Full name defaults to the username rather than being sent empty.
    expect(payload['full_name'], 'ada');
    expect(payload['group_create'], isTrue);
    expect(payload.containsKey('group'), isFalse);
    expect(payload['password'], 'secret');
    expect(payload['password_disabled'], isFalse);
  });

  test('a passwordless account omits the password field', () {
    final payload = UserCreateConfiguration.defaults
        .copyWith(username: 'svc', passwordDisabled: true)
        .toApiJson();

    expect(payload['password_disabled'], isTrue);
    expect(payload.containsKey('password'), isFalse);
  });

  test('requires a password unless sign-in is disabled', () {
    expect(
      () => UserCreateConfiguration.defaults
          .copyWith(username: 'ada')
          .toApiJson(),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('rejects usernames that ZFS and Unix would not accept', () {
    for (final name in ['', '1ada', 'Ada', 'has space', 'has:colon']) {
      expect(
        () => UserCreateConfiguration.defaults
            .copyWith(username: name, passwordDisabled: true)
            .toApiJson(),
        throwsA(isA<AccountConfigurationException>()),
        reason: 'should reject "$name"',
      );
    }
  });

  test('an explicit primary group must be chosen when not creating one', () {
    expect(
      () => UserCreateConfiguration.defaults
          .copyWith(username: 'ada', passwordDisabled: true, createGroup: false)
          .toApiJson(),
      throwsA(isA<AccountConfigurationException>()),
    );

    final payload = UserCreateConfiguration.defaults
        .copyWith(
          username: 'ada',
          passwordDisabled: true,
          createGroup: false,
          primaryGroupId: 42,
        )
        .toApiJson();

    expect(payload['group_create'], isFalse);
    expect(payload['group'], 42);
  });

  test('validates the email address on creation too', () {
    expect(
      () => UserCreateConfiguration.defaults
          .copyWith(
            username: 'ada',
            passwordDisabled: true,
            email: 'not-an-address',
          )
          .toApiJson(),
      throwsA(isA<AccountConfigurationException>()),
    );
  });

  test('creates a group with a sorted member list', () {
    final payload = GroupCreateConfiguration.defaults
        .copyWith(name: 'engineering', userIds: [9, 3, 5])
        .toApiJson();

    expect(payload['name'], 'engineering');
    expect(payload['users'], [3, 5, 9]);
    expect(payload['smb'], isTrue);
  });

  test('rejects group names with separators on creation', () {
    for (final name in ['', 'has space', 'has:colon', 'has,comma']) {
      expect(
        () =>
            GroupCreateConfiguration.defaults.copyWith(name: name).toApiJson(),
        throwsA(isA<AccountConfigurationException>()),
        reason: 'should reject "$name"',
      );
    }
  });
}

const _userJson = {
  'id': 3,
  'username': 'ada',
  'full_name': 'Ada Lovelace',
  'uid': 3000,
  'local': true,
  'builtin': false,
  'smb': true,
  'password_disabled': false,
  'locked': false,
  'email': 'ada@example.invalid',
  'shell': '/usr/bin/zsh',
  'roles': <String>[],
  'group': {'id': 41, 'bsdgrp_gid': 3000},
  'groups': [42, 43],
};

const _groupJson = {
  'id': 42,
  'name': 'engineering',
  'gid': 3100,
  'local': true,
  'builtin': false,
  'smb': true,
  'roles': <String>[],
  'users': [5, 7],
};
