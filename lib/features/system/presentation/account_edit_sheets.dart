import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'account_localizations.dart';

import '../domain/account_configuration.dart';
import '../domain/system_resources.dart';

/// Editing sheet for a local user account.
///
/// Returns the validated `user.update` payload after an explicit review step;
/// the caller performs the mutation. Password and privilege changes are
/// intentionally out of scope here.
class UserEditSheet extends StatefulWidget {
  const UserEditSheet({required this.user, required this.groups, super.key});

  final NasUser user;
  final List<NasGroup> groups;

  @override
  State<UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends State<UserEditSheet> {
  late UserUpdateConfiguration _configuration;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _shellController = TextEditingController();
  bool _reviewing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _configuration = UserUpdateConfiguration.fromUser(widget.user);
    _fullNameController.text = _configuration.fullName;
    _emailController.text = _configuration.email;
    _shellController.text = _configuration.shell;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _shellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return _SheetScaffold(
      title: _reviewing ? l10n.sysUserEditReviewTitle : l10n.sysUserEditTitle,
      subtitle: widget.user.username,
      error: _error,
      reviewing: _reviewing,
      onBack: () => setState(() => _reviewing = false),
      onReview: _review,
      onApply: _apply,
      applyLabel: l10n.sysUserApplyChanges,
      children: _reviewing ? _reviewContent(theme, l10n) : _form(theme, l10n),
    );
  }

  List<Widget> _form(ThemeData theme, AppLocalizations l10n) {
    final assignable =
        widget.groups
            .where((group) => group.id != widget.user.primaryGroupId)
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));
    final primary = widget.groups
        .where((group) => group.id == widget.user.primaryGroupId)
        .map((group) => group.name)
        .firstOrNull;

    return [
      TextField(
        controller: _fullNameController,
        decoration: InputDecoration(
          labelText: l10n.sysUserFullNameLabel,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: l10n.sysUserEmailLabel,
          helperText: l10n.sysUserEmailHelper,
          prefixIcon: const Icon(Icons.alternate_email_rounded),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _shellController,
        decoration: InputDecoration(
          labelText: l10n.sysUserShellLabel,
          prefixIcon: const Icon(Icons.terminal_rounded),
        ),
      ),
      const SizedBox(height: 18),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.sysUserSmbAccessTitle),
        subtitle: Text(l10n.sysUserSmbAccessSubtitle),
        value: _configuration.smb,
        onChanged: (value) => setState(() {
          _configuration = _configuration.copyWith(smb: value);
        }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.sysUserDisablePasswordTitle),
        subtitle: Text(l10n.sysUserDisablePasswordSubtitle),
        value: _configuration.passwordDisabled,
        onChanged: (value) => setState(() {
          _configuration = _configuration.copyWith(passwordDisabled: value);
        }),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.sysUserLockTitle),
        subtitle: Text(l10n.sysUserLockSubtitle),
        value: _configuration.locked,
        onChanged: (value) => setState(() {
          _configuration = _configuration.copyWith(locked: value);
        }),
      ),
      const SizedBox(height: 18),
      Text(l10n.sysUserPrimaryGroupTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: 6),
      Text(
        primary == null
            ? l10n.sysUserPrimaryGroupManaged
            : l10n.sysUserPrimaryGroupNamed(primary),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 18),
      Text(l10n.sysUserAuxGroupsTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: 10),
      if (assignable.isEmpty)
        Text(
          l10n.sysUserAuxGroupsNone,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in assignable)
              FilterChip(
                label: Text(group.name),
                selected: _configuration.auxiliaryGroupIds.contains(group.id),
                onSelected: (selected) => setState(() {
                  final ids = [..._configuration.auxiliaryGroupIds];
                  if (selected) {
                    ids.add(group.id);
                  } else {
                    ids.remove(group.id);
                  }
                  _configuration = _configuration.copyWith(
                    auxiliaryGroupIds: ids,
                  );
                }),
              ),
          ],
        ),
    ];
  }

  List<Widget> _reviewContent(ThemeData theme, AppLocalizations l10n) {
    final changes = _pending().describeChanges(widget.user);
    return [
      _ChangeList(changes: changes, l10n: l10n),
      if (_pending().locked && !widget.user.locked) ...[
        const SizedBox(height: 14),
        _WarningCard(message: l10n.sysUserLockWarning(widget.user.username)),
      ],
    ];
  }

  UserUpdateConfiguration _pending() => _configuration.copyWith(
    fullName: _fullNameController.text,
    email: _emailController.text,
    shell: _shellController.text,
  );

  void _review() {
    try {
      _pending().describeChanges(widget.user);
      setState(() {
        _error = null;
        _reviewing = true;
      });
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.accountValidationMessage(error.code));
    }
  }

  void _apply() {
    try {
      Navigator.of(context).pop(_pending().toApiJson(widget.user));
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _reviewing = false;
        _error = l10n.accountValidationMessage(error.code);
      });
    }
  }
}

/// Editing sheet for a local group, including its membership list.
class GroupEditSheet extends StatefulWidget {
  const GroupEditSheet({required this.group, required this.users, super.key});

  final NasGroup group;
  final List<NasUser> users;

  @override
  State<GroupEditSheet> createState() => _GroupEditSheetState();
}

class _GroupEditSheetState extends State<GroupEditSheet> {
  late GroupUpdateConfiguration _configuration;
  final _nameController = TextEditingController();
  bool _reviewing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _configuration = GroupUpdateConfiguration.fromGroup(widget.group);
    _nameController.text = _configuration.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return _SheetScaffold(
      title: _reviewing ? l10n.sysGroupEditReviewTitle : l10n.sysGroupEditTitle,
      subtitle: l10n.sysGroupEditSubtitle('${widget.group.gid}'),
      error: _error,
      reviewing: _reviewing,
      onBack: () => setState(() => _reviewing = false),
      onReview: _review,
      onApply: _apply,
      applyLabel: l10n.sysUserApplyChanges,
      children: _reviewing ? _reviewContent(l10n) : _form(theme, l10n),
    );
  }

  List<Widget> _form(ThemeData theme, AppLocalizations l10n) {
    final selectable = [...widget.users]
      ..sort((a, b) => a.username.compareTo(b.username));
    return [
      TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: l10n.sysGroupNameLabel,
          prefixIcon: const Icon(Icons.groups_outlined),
        ),
      ),
      const SizedBox(height: 18),
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
    ];
  }

  List<Widget> _reviewContent(AppLocalizations l10n) {
    final changes = _pending().describeChanges(widget.group);
    return [
      _ChangeList(changes: changes, l10n: l10n),
      if (_pending().name.trim() != widget.group.name) ...[
        const SizedBox(height: 14),
        _WarningCard(message: l10n.sysGroupRenameWarning),
      ],
    ];
  }

  GroupUpdateConfiguration _pending() =>
      _configuration.copyWith(name: _nameController.text);

  void _review() {
    try {
      _pending().describeChanges(widget.group);
      setState(() {
        _error = null;
        _reviewing = true;
      });
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() => _error = l10n.accountValidationMessage(error.code));
    }
  }

  void _apply() {
    try {
      Navigator.of(context).pop(_pending().toApiJson(widget.group));
    } on AccountConfigurationException catch (error) {
      final l10n = AppLocalizations.of(context);
      setState(() {
        _reviewing = false;
        _error = l10n.accountValidationMessage(error.code);
      });
    }
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.error,
    required this.reviewing,
    required this.onBack,
    required this.onReview,
    required this.onApply,
    required this.applyLabel,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String? error;
  final bool reviewing;
  final VoidCallback onBack;
  final VoidCallback onReview;
  final VoidCallback onApply;
  final String applyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            ...children,
            if (error case final message?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (reviewing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: Text(AppLocalizations.of(context).actionBack),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      child: Text(applyLabel),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(AppLocalizations.of(context).actionReview),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeList extends StatelessWidget {
  const _ChangeList({required this.changes, required this.l10n});

  final List<AccountChange> changes;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.accountChangeText(change))),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
        ),
      ),
    );
  }
}
