import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import 'account_localizations.dart';

import '../domain/account_configuration.dart';
import '../domain/system_resources.dart';

/// Creates a local user account.
///
/// Returns the validated `user.create` payload. The password lives only in
/// this sheet's controller and is passed straight to the caller; TrueDock
/// never stores or logs it.
class UserCreateSheet extends StatefulWidget {
  const UserCreateSheet({required this.groups, super.key});

  final List<NasGroup> groups;

  @override
  State<UserCreateSheet> createState() => _UserCreateSheetState();
}

class _UserCreateSheetState extends State<UserCreateSheet> {
  var _configuration = UserCreateConfiguration.defaults;
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final assignable = [...widget.groups]
      ..sort((a, b) => a.name.compareTo(b.name));
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.sysUserCreateTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l10n.sysUserCreateUsernameLabel,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: l10n.sysUserFullNameLabel,
                helperText: l10n.sysUserCreateFullNameHelper,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.sysUserEmailLabel,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sysUserDisablePasswordTitle),
              subtitle: Text(l10n.sysUserCreateDisablePasswordSubtitle),
              value: _configuration.passwordDisabled,
              onChanged: (value) => setState(() {
                _configuration = _configuration.copyWith(
                  passwordDisabled: value,
                );
                _error = null;
              }),
            ),
            if (!_configuration.passwordDisabled) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: l10n.sysUserPasswordNewLabel,
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure
                        ? l10n.sysUserShowPassword
                        : l10n.sysUserHidePassword,
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sysUserCreateSmbAccessTitle),
              value: _configuration.smb,
              onChanged: (value) => setState(() {
                _configuration = _configuration.copyWith(smb: value);
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sysUserCreateMatchingGroupTitle),
              subtitle: Text(l10n.sysUserCreateMatchingGroupSubtitle),
              value: _configuration.createGroup,
              onChanged: (value) => setState(() {
                _configuration = _configuration.copyWith(createGroup: value);
                _error = null;
              }),
            ),
            if (!_configuration.createGroup) ...[
              const SizedBox(height: 10),
              TrueDockDropdownButtonFormField<int>(
                initialValue: _configuration.primaryGroupId,
                decoration: InputDecoration(
                  labelText: l10n.sysUserCreatePrimaryGroupLabel,
                  prefixIcon: const Icon(Icons.groups_outlined),
                ),
                items: [
                  for (final group in assignable)
                    DropdownMenuItem(value: group.id, child: Text(group.name)),
                ],
                onChanged: (value) => setState(() {
                  _configuration = _configuration.copyWith(
                    primaryGroupId: value,
                  );
                  _error = null;
                }),
              ),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(l10n.sysUserCreateAction),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    try {
      final payload = _configuration
          .copyWith(
            username: _usernameController.text,
            fullName: _fullNameController.text,
            password: _passwordController.text,
            email: _emailController.text,
          )
          .toApiJson();
      Navigator.of(context).pop(payload);
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.accountValidationMessage(error.code));
    }
  }
}

/// Creates a local group.
class GroupCreateSheet extends StatefulWidget {
  const GroupCreateSheet({required this.users, super.key});

  final List<NasUser> users;

  @override
  State<GroupCreateSheet> createState() => _GroupCreateSheetState();
}

class _GroupCreateSheetState extends State<GroupCreateSheet> {
  var _configuration = GroupCreateConfiguration.defaults;
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final selectable = [...widget.users]
      ..sort((a, b) => a.username.compareTo(b.username));
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sysGroupCreateTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l10n.sysGroupNameLabel,
                prefixIcon: const Icon(Icons.groups_outlined),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sysGroupExposeSmbTitle),
              value: _configuration.smb,
              onChanged: (value) => setState(() {
                _configuration = _configuration.copyWith(smb: value);
              }),
            ),
            const SizedBox(height: 12),
            Text(l10n.sysGroupMembersTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            if (selectable.isEmpty)
              Text(
                l10n.sysGroupMembersNone,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final user in selectable)
                    FilterChip(
                      label: Text(user.username),
                      selected: _configuration.userIds.contains(user.id),
                      onSelected: (selected) => setState(() {
                        final ids = [..._configuration.userIds];
                        if (selected) {
                          ids.add(user.id);
                        } else {
                          ids.remove(user.id);
                        }
                        _configuration = _configuration.copyWith(userIds: ids);
                      }),
                    ),
                ],
              ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.sysGroupCreateAction),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    try {
      final payload = _configuration
          .copyWith(name: _nameController.text)
          .toApiJson();
      Navigator.of(context).pop(payload);
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.accountValidationMessage(error.code));
    }
  }
}
