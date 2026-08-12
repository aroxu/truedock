import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/system_resources.dart';
import '../domain/privilege_configuration.dart';

extension _PrivilegeLocalizations on AppLocalizations {
  String privilegeValidationMessage(PrivilegeValidationIssue issue) =>
      switch (issue.code) {
        PrivilegeValidationCode.nameRequired => sysPrivilegeValidationName,
        PrivilegeValidationCode.rolesRequired => sysPrivilegeValidationRoles,
        PrivilegeValidationCode.builtinImmutable => sysPrivilegeBuiltinNotice,
      };
}

/// Creates or edits a privilege.
///
/// The role list is searchable because the server advertises 141 of them; a
/// plain list would be unusable on a phone. Roles that are already implied by a
/// selected role are shown as such rather than as independent choices, since
/// selecting `ACCOUNT_READ` alongside `ACCOUNT_WRITE` changes nothing.
class PrivilegeSheet extends StatefulWidget {
  const PrivilegeSheet({
    required this.baseline,
    required this.roles,
    required this.groups,
    this.isBuiltin = false,
    this.isNew = true,
    super.key,
  });

  final PrivilegeConfiguration baseline;

  /// Role catalog from `privilege.roles`.
  final List<PrivilegeRole> roles;

  /// Local groups available to grant to.
  final List<NasGroup> groups;
  final bool isBuiltin;
  final bool isNew;

  @override
  State<PrivilegeSheet> createState() => _PrivilegeSheetState();
}

class _PrivilegeSheetState extends State<PrivilegeSheet> {
  late final TextEditingController _name;
  final _search = TextEditingController();
  late Set<String> _selectedRoles;
  late Set<int> _selectedGroups;
  late bool _webShell;
  List<PrivilegeValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.baseline.name);
    _selectedRoles = widget.baseline.roles.toSet();
    _selectedGroups = widget.baseline.localGroupIds.toSet();
    _webShell = widget.baseline.webShell;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Roles granted directly plus everything they imply.
  Set<String> get _effectiveRoles {
    final byName = {for (final role in widget.roles) role.name: role};
    final effective = <String>{};
    void visit(String name) {
      if (!effective.add(name)) return;
      for (final included in byName[name]?.includes ?? const <String>[]) {
        visit(included);
      }
    }

    for (final role in _selectedRoles) {
      visit(role);
    }
    return effective;
  }

  List<PrivilegeRole> get _visibleRoles {
    final query = _search.text.trim().toUpperCase();
    // Selected roles stay visible while filtering, so a search cannot hide what
    // is about to be granted.
    return widget.roles
        .where(
          (role) =>
              query.isEmpty ||
              role.name.toUpperCase().contains(query) ||
              _selectedRoles.contains(role.name),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final effective = _effectiveRoles;
    final grantsFullAdmin = _selectedRoles.contains('FULL_ADMIN');
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isNew
                  ? l10n.sysPrivilegeCreateTitle
                  : l10n.sysPrivilegeEditTitle(widget.baseline.name),
              style: theme.textTheme.headlineSmall,
            ),
            if (widget.isBuiltin) ...[
              const SizedBox(height: 10),
              _Notice(
                message: l10n.sysPrivilegeBuiltinNotice,
                color: theme.colorScheme.errorContainer,
                onColor: theme.colorScheme.onErrorContainer,
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              // The built-in privileges are identified by name in TrueNAS docs
              // and the web UI, so renaming one only creates confusion.
              enabled: !widget.isBuiltin,
              decoration: InputDecoration(labelText: l10n.sysPrivilegeName),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    l10n.sysPrivilegeGroups,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  if (widget.groups.isEmpty)
                    Text(
                      l10n.sysPrivilegeNoGroups,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final group in widget.groups)
                          FilterChip(
                            selected: _selectedGroups.contains(group.id),
                            label: Text(group.name),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _selectedGroups.add(group.id);
                              } else {
                                _selectedGroups.remove(group.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.sysPrivilegeRoles,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sysPrivilegeEffectiveRoles(effective.length),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (grantsFullAdmin) ...[
                    const SizedBox(height: 8),
                    _Notice(
                      message: l10n.sysPrivilegeFullAdminNotice,
                      color: theme.colorScheme.secondaryContainer,
                      onColor: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _search,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l10n.sysPrivilegeSearchRoles,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final role in _visibleRoles)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _selectedRoles.contains(role.name),
                      onChanged: (selected) => setState(() {
                        if (selected == true) {
                          _selectedRoles.add(role.name);
                        } else {
                          _selectedRoles.remove(role.name);
                        }
                      }),
                      title: Text(role.name),
                      // An implied role is still granted, so saying so is more
                      // useful than leaving the row looking unselected.
                      subtitle:
                          !_selectedRoles.contains(role.name) &&
                              effective.contains(role.name)
                          ? Text(
                              l10n.sysPrivilegeRoleCount(role.includes.length),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _webShell,
                    onChanged: (value) => setState(() => _webShell = value),
                    title: Text(l10n.sysPrivilegeWebShell),
                    subtitle: Text(l10n.sysPrivilegeWebShellNotice),
                  ),
                  for (final issue in _issues)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.privilegeValidationMessage(issue),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.actionCancel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(
                      l10n.sysPrivilegeApplyAction,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final configuration = PrivilegeConfiguration(
      name: _name.text,
      roles: _selectedRoles.toList()..sort(),
      webShell: _webShell,
      localGroupIds: _selectedGroups.toList()..sort(),
      directoryGroups: widget.baseline.directoryGroups,
    );
    final issues = configuration.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, configuration);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.color,
    required this.onColor,
  });

  final String message;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message, style: TextStyle(color: onColor)),
  );
}
