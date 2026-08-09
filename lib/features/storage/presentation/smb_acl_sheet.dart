import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/smb_acl_configuration.dart';
import '../../resources/domain/server_resources.dart' show SmbShare;
import 'storage_localizations.dart';

/// A principal the editor can add, carrying the Unix id the server needs.
///
/// `sharing.smb.setacl` identifies a principal by SID or Unix id; a bare name
/// makes the middleware fail, so the picker never offers a name alone.
class SmbAclPrincipal {
  const SmbAclPrincipal({required this.name, required this.unixId});

  final String name;
  final int unixId;
}

/// Editor for an SMB share's access-control list.
///
/// Loads the current ACL through `sharing.smb.getacl`, lets the user add
/// local users/groups and change each principal's role (allow read/change/full
/// or deny), and returns the resolved list for `sharing.smb.setacl`. The
/// caller routes the result through the shared confirmation.
class SmbAclSheet extends StatefulWidget {
  const SmbAclSheet({
    required this.share,
    required this.users,
    required this.groups,
    required this.initialAcl,
    super.key,
  });

  final SmbShare share;
  final List<SmbAclPrincipal> users;
  final List<SmbAclPrincipal> groups;
  final List<SmbAclEntry> initialAcl;

  @override
  State<SmbAclSheet> createState() => _SmbAclSheetState();
}

class _SmbAclSheetState extends State<SmbAclSheet> {
  late List<SmbAclEntry> _acl;
  SmbAclPrincipalKind _addKind = SmbAclPrincipalKind.user;
  SmbAclPrincipal? _addPrincipalChoice;
  bool _reviewing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _acl = List.of(widget.initialAcl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.security_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.storageSmbAclReviewTitle
                              : l10n.storageSmbAclFormTitle(widget.share.name),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          widget.share.path,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageSmbAclClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _reviewing ? _review(theme) : _form(theme)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.storageSmbAclBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageSmbAclCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.save_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? l10n.storageSmbAclReview
                          : l10n.storageSmbAclContinue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(
          l10n.storageSmbAclCurrentPrincipals,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_acl.isEmpty)
          Text(
            l10n.storageSmbAclEmpty,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          for (final entry in _acl)
            _AclEntryTile(
              entry: entry,
              onChanged: (permission, permType) => setState(() {
                final index = _acl.indexOf(entry);
                _acl[index] = entry.copyWith(
                  permission: permission,
                  permType: permType,
                );
              }),
              onRemove: () => setState(() => _acl.remove(entry)),
            ),
        const SizedBox(height: 20),
        Text(l10n.storageSmbAclAddPrincipal, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<SmbAclPrincipalKind>(
          segments: [
            ButtonSegment(
              value: SmbAclPrincipalKind.user,
              label: Text(l10n.storageSmbAclUser),
            ),
            ButtonSegment(
              value: SmbAclPrincipalKind.group,
              label: Text(l10n.storageSmbAclGroup),
            ),
          ],
          selected: {_addKind},
          onSelectionChanged: (selection) =>
              setState(() => _addKind = selection.first),
        ),
        const SizedBox(height: 10),
        _PrincipalPicker(
          kind: _addKind,
          users: widget.users,
          groups: widget.groups,
          existing: _acl.map((e) => e.qualifiedName).toSet(),
          onChanged: (principal) => setState(() {
            _addPrincipalChoice = principal;
            _error = null;
          }),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _addPrincipalChoice == null
              ? null
              : () => _addPrincipal(_addPrincipalChoice!),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.storageSmbAclAddToList),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _Notice(message: _error!, error: true),
        ],
      ],
    );
  }

  void _addPrincipal(SmbAclPrincipal principal) {
    final qualified = smbQualifiedPrincipalName(
      _addKind,
      principal.name.trim(),
    );
    if (_acl.any((e) => e.qualifiedName == qualified)) {
      setState(
        () => _error = AppLocalizations.of(context).storageSmbAclDuplicateError,
      );
      return;
    }
    setState(() {
      _acl = List.of(_acl)
        ..add(
          SmbAclEntry(
            qualifiedName: qualified,
            kind: _addKind,
            permission: SmbSharePermission.read,
            permType: SmbAclPermType.allowed,
            // Carried so the entry can be sent; a name alone cannot be.
            unixId: principal.unixId,
          ),
        );
      _addPrincipalChoice = null;
      _error = null;
    });
  }

  Widget _review(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(
                label: l10n.storageSmbAclReviewServerAction,
                value: l10n.storageSmbAclReviewServerActionValue,
              ),
              _ReviewRow(
                label: l10n.storageSmbAclReviewShare,
                value: widget.share.name,
              ),
              _ReviewRow(
                label: l10n.storageSmbAclReviewRules,
                value: l10n.storageSmbAclReviewRulesValue(_acl.length),
              ),
              for (final entry in _acl)
                _ReviewRow(
                  label: entry.principalName,
                  value: entry.permType == SmbAclPermType.denied
                      ? l10n.storageSmbAclReviewDeny(
                          l10n.smbSharePermissionLabel(entry.permission),
                        )
                      : l10n.storageSmbAclReviewAllow(
                          l10n.smbSharePermissionLabel(entry.permission),
                        ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(message: l10n.storageSmbAclReviewNotice),
      ],
    );
  }

  void _validate() {
    setState(() {
      _error = null;
      _reviewing = true;
    });
  }

  void _submit() {
    Navigator.of(context).pop(List.of(_acl));
  }
}

class _AclEntryTile extends StatelessWidget {
  const _AclEntryTile({
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final SmbAclEntry entry;
  final void Function(SmbSharePermission, SmbAclPermType) onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  entry.kind == SmbAclPrincipalKind.group
                      ? Icons.group_outlined
                      : Icons.person_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.principalName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: l10n.storageSmbAclRemoveFromList,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.storageSmbAclAllowRead),
                  selected:
                      entry.permType == SmbAclPermType.allowed &&
                      entry.permission == SmbSharePermission.read,
                  onSelected: (_) => onChanged(
                    SmbSharePermission.read,
                    SmbAclPermType.allowed,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.storageSmbAclAllowChange),
                  selected:
                      entry.permType == SmbAclPermType.allowed &&
                      entry.permission == SmbSharePermission.change,
                  onSelected: (_) => onChanged(
                    SmbSharePermission.change,
                    SmbAclPermType.allowed,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.storageSmbAclAllowFull),
                  selected:
                      entry.permType == SmbAclPermType.allowed &&
                      entry.permission == SmbSharePermission.full,
                  onSelected: (_) => onChanged(
                    SmbSharePermission.full,
                    SmbAclPermType.allowed,
                  ),
                ),
                ChoiceChip(
                  label: Text(l10n.storageSmbAclDeny),
                  selected: entry.permType == SmbAclPermType.denied,
                  onSelected: (_) =>
                      onChanged(entry.permission, SmbAclPermType.denied),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrincipalPicker extends StatelessWidget {
  const _PrincipalPicker({
    required this.kind,
    required this.users,
    required this.groups,
    required this.existing,
    required this.onChanged,
  });

  final SmbAclPrincipalKind kind;
  final List<SmbAclPrincipal> users;
  final List<SmbAclPrincipal> groups;
  final Set<String> existing;
  final ValueChanged<SmbAclPrincipal?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates =
        (kind == SmbAclPrincipalKind.group ? groups : users)
            .where(
              (principal) => !existing.contains(
                smbQualifiedPrincipalName(kind, principal.name),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));
    if (candidates.isEmpty) {
      return Text(
        kind == SmbAclPrincipalKind.group
            ? l10n.storageSmbAclNoGroups
            : l10n.storageSmbAclNoUsers,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return TrueDockDropdownButtonFormField<SmbAclPrincipal>(
      decoration: InputDecoration(
        labelText: l10n.storageSmbAclPrincipalLabel,
        prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
      ),
      items: [
        for (final principal in candidates)
          DropdownMenuItem(value: principal, child: Text(principal.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: error
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: error
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
