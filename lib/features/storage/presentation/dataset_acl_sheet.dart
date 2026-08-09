import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/dataset_acl.dart';

class DatasetAclEditResult {
  const DatasetAclEditResult({
    required this.acl,
    required this.recursive,
    required this.typeChanged,
    required this.ownerChanged,
  });

  final DatasetAcl acl;
  final bool recursive;
  final bool typeChanged;
  final bool ownerChanged;
}

class DatasetAclSheet extends StatefulWidget {
  const DatasetAclSheet({
    required this.datasetName,
    required this.initialAcl,
    required this.users,
    required this.groups,
    super.key,
  });

  final String datasetName;
  final DatasetAcl initialAcl;
  final List<DatasetAclPrincipal> users;
  final List<DatasetAclPrincipal> groups;

  @override
  State<DatasetAclSheet> createState() => _DatasetAclSheetState();
}

class _DatasetAclSheetState extends State<DatasetAclSheet> {
  late List<DatasetAclEntry> _entries;
  late DatasetAclType _aclType;
  late List<DatasetAclPrincipal> _userChoices;
  late List<DatasetAclPrincipal> _groupChoices;
  DatasetAclPrincipal? _owner;
  DatasetAclPrincipal? _ownerGroup;
  var _kind = DatasetAclPrincipalKind.user;
  DatasetAclPrincipal? _principal;
  var _recursive = false;
  var _reviewing = false;

  @override
  void initState() {
    super.initState();
    _entries = List.of(widget.initialAcl.entries);
    _aclType = widget.initialAcl.type;
    _userChoices = _withCurrentPrincipal(
      widget.users,
      id: widget.initialAcl.uid,
      name: widget.initialAcl.user,
      kind: DatasetAclPrincipalKind.user,
    );
    _groupChoices = _withCurrentPrincipal(
      widget.groups,
      id: widget.initialAcl.gid,
      name: widget.initialAcl.group,
      kind: DatasetAclPrincipalKind.group,
    );
    _owner = _findPrincipal(_userChoices, widget.initialAcl.uid);
    _ownerGroup = _findPrincipal(_groupChoices, widget.initialAcl.gid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.storageDatasetAclReviewTitle
                              : l10n.storageDatasetAclTitle,
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          widget.datasetName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _reviewing ? _review() : _form()),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.actionBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing ? l10n.actionSaveChanges : l10n.actionReview,
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

  Widget _form() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final choices = _kind == DatasetAclPrincipalKind.user
        ? _userChoices
        : _groupChoices;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            l10n.storageDatasetAclType(
              _aclTypeLabel(l10n, widget.initialAcl.type),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.storageDatasetAclOwnership,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PrincipalSelector(
                key: const ValueKey('dataset-acl-owner-selector'),
                kind: DatasetAclPrincipalKind.user,
                value: _owner,
                choices: _userChoices,
                onChanged: (value) => setState(() => _owner = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrincipalSelector(
                key: const ValueKey('dataset-acl-owner-group-selector'),
                kind: DatasetAclPrincipalKind.group,
                value: _ownerGroup,
                choices: _groupChoices,
                onChanged: (value) => setState(() => _ownerGroup = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          l10n.storageDatasetAclPermissionType,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<DatasetAclType>(
          key: const ValueKey('dataset-acl-type-selector'),
          segments: [
            ButtonSegment(
              value: DatasetAclType.posix1e,
              label: Text(l10n.storageDatasetAclPosix),
            ),
            ButtonSegment(
              value: DatasetAclType.nfs4,
              label: Text(l10n.storageDatasetAclTrueNas),
            ),
          ],
          selected: {_aclType},
          onSelectionChanged: (selection) =>
              _confirmAclTypeChange(selection.first),
        ),
        if (_aclType != widget.initialAcl.type) ...[
          const SizedBox(height: 10),
          _AclNotice(
            icon: Icons.warning_amber_rounded,
            message: l10n.storageDatasetAclTypeConversionWarning,
          ),
        ],
        const SizedBox(height: 14),
        for (final entry in _entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.displayName),
                            Text(
                              entry.tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_aclType == DatasetAclType.nfs4)
                        TrueDockDropdownButton<DatasetAclAccess>(
                          value: entry.access,
                          items: [
                            for (final access in _nfs4AccessChoices)
                              DropdownMenuItem(
                                value: access,
                                child: Text(_accessLabel(l10n, access)),
                              ),
                          ],
                          onChanged: (access) {
                            if (access == null) return;
                            _replaceEntry(
                              entry,
                              entry.withAccess(access, _aclType),
                            );
                          },
                        ),
                      IconButton(
                        onPressed: entry.canRemove
                            ? () => setState(() => _entries.remove(entry))
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        tooltip: l10n.storageDatasetAclRemove,
                      ),
                    ],
                  ),
                  if (_aclType == DatasetAclType.posix1e) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _PosixPermissionCheckbox(
                            key: ValueKey(
                              'posix-read-${entry.tag}-${entry.id}',
                            ),
                            label: l10n.storageDatasetAclRead,
                            value: entry.permissions['READ'] == true,
                            onChanged: (value) => _replaceEntry(
                              entry,
                              entry.withPosixPermissions(read: value),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _PosixPermissionCheckbox(
                            key: ValueKey(
                              'posix-write-${entry.tag}-${entry.id}',
                            ),
                            label: l10n.storageDatasetAclWrite,
                            value: entry.permissions['WRITE'] == true,
                            onChanged: (value) => _replaceEntry(
                              entry,
                              entry.withPosixPermissions(write: value),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _PosixPermissionCheckbox(
                            key: ValueKey(
                              'posix-execute-${entry.tag}-${entry.id}',
                            ),
                            label: l10n.storageDatasetAclExecute,
                            value: entry.permissions['EXECUTE'] == true,
                            onChanged: (value) => _replaceEntry(
                              entry,
                              entry.withPosixPermissions(execute: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(l10n.storageDatasetAclAdd, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<DatasetAclPrincipalKind>(
          segments: [
            ButtonSegment(
              value: DatasetAclPrincipalKind.user,
              label: Text(l10n.storageSmbAclUser),
            ),
            ButtonSegment(
              value: DatasetAclPrincipalKind.group,
              label: Text(l10n.storageSmbAclGroup),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() {
            _kind = value.first;
            _principal = null;
          }),
        ),
        const SizedBox(height: 10),
        _PrincipalSelector(
          key: const ValueKey('dataset-acl-principal-selector'),
          kind: _kind,
          value: choices.contains(_principal) ? _principal : null,
          choices: [
            for (final principal in choices)
              if (!_entries.any(
                (entry) =>
                    entry.tag ==
                        (principal.kind == DatasetAclPrincipalKind.user
                            ? 'USER'
                            : 'GROUP') &&
                    entry.id == principal.id,
              ))
                principal,
          ],
          onChanged: (value) => setState(() => _principal = value),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _principal == null ? null : _addPrincipal,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.storageDatasetAclAdd),
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _recursive,
          onChanged: (value) => setState(() => _recursive = value),
          title: Text(l10n.storageDatasetAclRecursive),
          subtitle: Text(l10n.storageDatasetAclRecursiveSubtitle),
        ),
      ],
    );
  }

  Widget _review() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
              Text(widget.initialAcl.path, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(l10n.storageDatasetAclRuleCount(_entries.length)),
              const SizedBox(height: 8),
              for (final entry in _entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.displayName)),
                      Text(_accessLabel(l10n, entry.access)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_recursive) ...[
          const SizedBox(height: 12),
          Text(l10n.storageDatasetAclRecursiveWarning),
        ],
      ],
    );
  }

  void _addPrincipal() {
    final principal = _principal;
    if (principal == null) return;
    setState(() {
      _entries.add(DatasetAclEntry.named(principal, _aclType));
      if (_aclType == DatasetAclType.posix1e &&
          !_entries.any(
            (entry) => entry.tag == 'MASK' && entry.isDefault != true,
          )) {
        _entries.add(
          const DatasetAclEntry(
            tag: 'MASK',
            permissions: {'READ': true, 'WRITE': true, 'EXECUTE': true},
            id: -1,
            isDefault: false,
          ),
        );
      }
      _principal = null;
    });
  }

  void _replaceEntry(DatasetAclEntry current, DatasetAclEntry replacement) {
    setState(() {
      final index = _entries.indexOf(current);
      if (index >= 0) _entries[index] = replacement;
    });
  }

  void _validate() => setState(() => _reviewing = true);

  void _submit() {
    final owner = _owner;
    final group = _ownerGroup;
    final acl = DatasetAcl(
      path: widget.initialAcl.path,
      type: _aclType,
      entries: List.of(_entries),
      uid: owner?.id ?? widget.initialAcl.uid,
      user: owner?.name ?? widget.initialAcl.user,
      gid: group?.id ?? widget.initialAcl.gid,
      group: group?.name ?? widget.initialAcl.group,
      nfs41Flags: _aclType == DatasetAclType.nfs4
          ? (_aclType == widget.initialAcl.type
                ? widget.initialAcl.nfs41Flags
                : const {
                    'autoinherit': false,
                    'protected': false,
                    'defaulted': false,
                  })
          : const {},
    );
    Navigator.pop(
      context,
      DatasetAclEditResult(
        acl: acl,
        recursive: _recursive,
        typeChanged: _aclType != widget.initialAcl.type,
        ownerChanged:
            owner?.id != widget.initialAcl.uid ||
            group?.id != widget.initialAcl.gid,
      ),
    );
  }

  void _changeAclType(DatasetAclType type) {
    if (type == _aclType) return;
    final converted = widget.initialAcl
        .copyWith(type: _aclType, entries: _entries)
        .convertedTo(type);
    setState(() {
      _aclType = type;
      _entries = List.of(converted.entries);
      _principal = null;
    });
  }

  Future<void> _confirmAclTypeChange(DatasetAclType type) async {
    if (type == _aclType) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(l10n.storageDatasetAclTypeChangeWarningTitle),
        content: Text(
          l10n.storageDatasetAclTypeChangeWarningBody(
            _aclTypeLabel(l10n, _aclType),
            _aclTypeLabel(l10n, type),
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cancel-dataset-acl-type-change'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-dataset-acl-type-change'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.storageDatasetAclChangeTypeAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _changeAclType(type);
  }

  static DatasetAclPrincipal? _findPrincipal(
    List<DatasetAclPrincipal> principals,
    int? id,
  ) {
    for (final principal in principals) {
      if (principal.id == id) return principal;
    }
    return null;
  }

  static List<DatasetAclPrincipal> _withCurrentPrincipal(
    List<DatasetAclPrincipal> principals, {
    required int? id,
    required String? name,
    required DatasetAclPrincipalKind kind,
  }) {
    if (id == null || principals.any((principal) => principal.id == id)) {
      return List.of(principals);
    }
    return [
      DatasetAclPrincipal(
        name: name?.trim().isNotEmpty == true ? name!.trim() : '$id',
        id: id,
        kind: kind,
      ),
      ...principals,
    ];
  }

  String _aclTypeLabel(AppLocalizations l10n, DatasetAclType type) =>
      type == DatasetAclType.nfs4
      ? l10n.storageDatasetAclTrueNas
      : l10n.storageDatasetAclPosix;

  static const _nfs4AccessChoices = [
    DatasetAclAccess.fullControl,
    DatasetAclAccess.modify,
    DatasetAclAccess.read,
    DatasetAclAccess.traverse,
  ];

  String _accessLabel(AppLocalizations l10n, DatasetAclAccess access) =>
      switch (access) {
        DatasetAclAccess.none => l10n.storageDatasetAclNone,
        DatasetAclAccess.traverse => l10n.storageDatasetAclTraverse,
        DatasetAclAccess.read => l10n.storageDatasetAclRead,
        DatasetAclAccess.write => l10n.storageDatasetAclWrite,
        DatasetAclAccess.modify => l10n.storageDatasetAclModify,
        DatasetAclAccess.fullControl => l10n.storageDatasetAclFullControl,
      };
}

class _PosixPermissionCheckbox extends StatelessWidget {
  const _PosixPermissionCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: value,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            onChanged: (next) => onChanged(next ?? false),
            visualDensity: VisualDensity.compact,
          ),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ),
  );
}

class _AclNotice extends StatelessWidget {
  const _AclNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipalSelector extends StatelessWidget {
  const _PrincipalSelector({
    required this.kind,
    required this.value,
    required this.choices,
    required this.onChanged,
    super.key,
  });

  final DatasetAclPrincipalKind kind;
  final DatasetAclPrincipal? value;
  final List<DatasetAclPrincipal> choices;
  final ValueChanged<DatasetAclPrincipal?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = kind == DatasetAclPrincipalKind.user
        ? l10n.storageSmbAclUser
        : l10n.storageSmbAclGroup;
    return Semantics(
      label: label,
      button: true,
      enabled: choices.isNotEmpty,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: choices.isEmpty ? null : () => _openPicker(context),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded),
          ),
          child: Text(
            value?.name ?? l10n.storageDatasetAclChoosePrincipal(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: value == null
                ? TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<DatasetAclPrincipal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) =>
          _PrincipalPickerSheet(kind: kind, choices: choices, selected: value),
    );
    if (selected != null) onChanged(selected);
  }
}

class _PrincipalPickerSheet extends StatefulWidget {
  const _PrincipalPickerSheet({
    required this.kind,
    required this.choices,
    required this.selected,
  });

  final DatasetAclPrincipalKind kind;
  final List<DatasetAclPrincipal> choices;
  final DatasetAclPrincipal? selected;

  @override
  State<_PrincipalPickerSheet> createState() => _PrincipalPickerSheetState();
}

class _PrincipalPickerSheetState extends State<_PrincipalPickerSheet> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = widget.kind == DatasetAclPrincipalKind.user
        ? l10n.storageSmbAclUser
        : l10n.storageSmbAclGroup;
    final filtered =
        widget.choices
            .where(
              (principal) => principal.name.toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return FractionallySizedBox(
      heightFactor: .62,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    widget.kind == DatasetAclPrincipalKind.user
                        ? Icons.person_outline_rounded
                        : Icons.group_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.storageDatasetAclChoosePrincipal(label),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        l10n.storageDatasetAclPrincipalCount(filtered.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.actionClose,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('dataset-acl-principal-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.storageDatasetAclSearchPrincipal(label),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: l10n.appsClearSearch,
                      ),
                filled: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(l10n.storageDatasetAclNoPrincipals(label)),
                    )
                  : ListView.separated(
                      key: const ValueKey('dataset-acl-principal-list'),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final principal = filtered[index];
                        final selected = widget.selected?.id == principal.id;
                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -2),
                          minTileHeight: 48,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: Icon(
                            widget.kind == DatasetAclPrincipalKind.user
                                ? Icons.person_outline_rounded
                                : Icons.group_outlined,
                            size: 21,
                          ),
                          title: Text(principal.name),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, principal),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
