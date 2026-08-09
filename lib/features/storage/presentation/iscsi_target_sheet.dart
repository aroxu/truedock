import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_target_configuration.dart';

extension _IscsiTargetLocalizations on AppLocalizations {
  String queueChoice(_QueuedCommandChoice choice) => switch (choice) {
    _QueuedCommandChoice.serverDefault => iscsiTargetQueueServerDefault,
    _QueuedCommandChoice.commands32 => iscsiTargetQueue32,
    _QueuedCommandChoice.commands128 => iscsiTargetQueue128,
  };

  String validationError(String field) => switch (field) {
    'name' => iscsiTargetValidationName,
    'groups' => iscsiTargetValidationGroups,
    'authNetworks' => iscsiTargetValidationNetworks,
    'queuedCommands' => iscsiTargetValidationQueued,
    _ => field,
  };
}

class IscsiTargetSheet extends StatefulWidget {
  const IscsiTargetSheet({
    required this.portals,
    required this.initiators,
    required this.auths,
    this.existingTarget,
    super.key,
  });

  final List<IscsiPortal> portals;
  final List<IscsiInitiator> initiators;

  /// CHAP credential entries available to assign to new target groups.
  final List<IscsiAuth> auths;
  final IscsiTarget? existingTarget;

  @override
  State<IscsiTargetSheet> createState() => _IscsiTargetSheetState();
}

class _IscsiTargetSheetState extends State<IscsiTargetSheet> {
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _authNetworksController = TextEditingController();
  final _groups = <_TargetGroupDraft>[];
  late AppLocalizations l10n;

  _QueuedCommandChoice _queuedCommands = _QueuedCommandChoice.serverDefault;
  bool _reviewing = false;
  Map<String, String> _errors = const {};
  int _nextGroupKey = 0;

  bool get _editing => widget.existingTarget != null;

  @override
  void initState() {
    super.initState();
    final configuration = widget.existingTarget == null
        ? IscsiTargetConfiguration.defaults()
        : IscsiTargetConfiguration.fromTarget(widget.existingTarget!);
    _nameController.text = configuration.name;
    _aliasController.text = configuration.alias ?? '';
    _authNetworksController.text = configuration.authNetworks.join('\n');
    _queuedCommands = _QueuedCommandChoice.fromValue(
      configuration.queuedCommands,
    );
    for (final group in configuration.groups) {
      _groups.add(
        _TargetGroupDraft(
          key: _nextGroupKey++,
          portalId: group.portalId,
          initiatorId: group.initiatorId,
          authMethod: group.authMethod,
          authId: group.authId,
          locked: group.authMethod != 'NONE',
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _authNetworksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .94,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.storage_outlined,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.iscsiTargetReviewTitle
                              : _editing
                              ? l10n.iscsiTargetEditTitle
                              : l10n.iscsiTargetNewTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.iscsiTargetSubtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.iscsiTargetClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: _reviewing ? _buildReview() : _buildForm()),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.iscsiTargetBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.iscsiTargetCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _review,
                    icon: Icon(
                      _reviewing
                          ? _editing
                                ? Icons.save_outlined
                                : Icons.add_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? _editing
                                ? l10n.iscsiTargetSaveChanges
                                : l10n.iscsiTargetCreate
                          : l10n.iscsiTargetReview,
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

  Widget _buildForm() => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    children: [
      TextField(
        controller: _nameController,
        autocorrect: false,
        textCapitalization: TextCapitalization.none,
        decoration: InputDecoration(
          labelText: l10n.iscsiTargetNameLabel,
          helperText: l10n.iscsiTargetNameHelper,
          errorText: _errors['name'],
          prefixIcon: const Icon(Icons.badge_outlined),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _clearError('name'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _aliasController,
        decoration: InputDecoration(
          labelText: l10n.iscsiTargetAliasLabel,
          helperText: l10n.iscsiTargetAliasHelper,
          prefixIcon: const Icon(Icons.label_outline_rounded),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _authNetworksController,
        minLines: 2,
        maxLines: 6,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.iscsiTargetNetworksLabel,
          helperText: l10n.iscsiTargetNetworksHelper,
          errorText: _errors['authNetworks'],
          prefixIcon: const Icon(Icons.hub_outlined),
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _clearError('authNetworks'),
      ),
      const SizedBox(height: 12),
      TrueDockDropdownButtonFormField<_QueuedCommandChoice>(
        initialValue: _queuedCommands,
        decoration: InputDecoration(
          labelText: l10n.iscsiTargetQueuedLabel,
          helperText: l10n.iscsiTargetQueuedHelper,
          errorText: _errors['queuedCommands'],
          prefixIcon: const Icon(Icons.queue_rounded),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final choice in _QueuedCommandChoice.values)
            DropdownMenuItem(
              value: choice,
              child: Text(l10n.queueChoice(choice)),
            ),
        ],
        onChanged: (choice) {
          if (choice == null) return;
          setState(() {
            _queuedCommands = choice;
            _errors = Map.of(_errors)..remove('queuedCommands');
          });
        },
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: Text(
              l10n.iscsiTargetGroups,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          OutlinedButton.icon(
            onPressed: widget.portals.isEmpty ? null : _addGroup,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.iscsiTargetAddGroup),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        l10n.iscsiTargetGroupsDescription,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      if (_errors['groups'] case final error?) ...[
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: 10),
      if (_groups.isEmpty)
        _TargetNotice(message: l10n.iscsiTargetNoGroupsNotice, warning: true)
      else
        for (var index = 0; index < _groups.length; index++) ...[
          _buildGroup(index, _groups[index]),
          if (index != _groups.length - 1) const SizedBox(height: 10),
        ],
      if (widget.portals.isEmpty) ...[
        const SizedBox(height: 10),
        _TargetNotice(message: l10n.iscsiTargetNoPortalsNotice, warning: true),
      ],
      if (_hasUnrestrictedUnauthenticatedGroup) ...[
        const SizedBox(height: 10),
        _TargetNotice(
          message: l10n.iscsiTargetUnrestrictedNotice,
          warning: true,
        ),
      ],
      const SizedBox(height: 8),
    ],
  );

  Widget _buildGroup(int index, _TargetGroupDraft group) {
    final colors = Theme.of(context).colorScheme;
    if (group.locked) {
      return Container(
        key: ValueKey('target-group-${group.key}'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.authMethod == 'CHAP_MUTUAL'
                        ? l10n.iscsiTargetMutualChapGroup
                        : l10n.iscsiTargetChapGroup,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(l10n.iscsiTargetPortalValue(_portalLabel(group.portalId))),
            const SizedBox(height: 4),
            Text(
              l10n.iscsiTargetInitiatorsValue(
                _initiatorLabel(group.initiatorId),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.iscsiTargetCredentialValue(
                group.authId?.toString() ?? l10n.iscsiTargetUnavailable,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.iscsiTargetLockedAuthNotice,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final portalAvailable = widget.portals.any(
      (portal) => portal.id == group.portalId,
    );
    final initiatorAvailable =
        group.initiatorId == null ||
        widget.initiators.any((initiator) => initiator.id == group.initiatorId);
    return Container(
      key: ValueKey('target-group-${group.key}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.iscsiTargetUnauthenticatedGroup(index + 1),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => _removeGroup(group),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l10n.iscsiTargetRemoveGroup(index + 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TrueDockDropdownButtonFormField<int>(
            key: ValueKey('portal-${group.key}-${group.portalId}'),
            initialValue: portalAvailable ? group.portalId : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.iscsiTargetPortalLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final portal in widget.portals)
                DropdownMenuItem(
                  value: portal.id,
                  child: Text(
                    _portalLabel(portal.id),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (portalId) {
              if (portalId == null) return;
              setState(() {
                group.portalId = portalId;
                _errors = Map.of(_errors)..remove('groups');
              });
            },
          ),
          const SizedBox(height: 10),
          TrueDockDropdownButtonFormField<int>(
            key: ValueKey('initiator-${group.key}-${group.initiatorId}'),
            initialValue: initiatorAvailable
                ? group.initiatorId ?? _allInitiatorsValue
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.iscsiTargetInitiatorsLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: _allInitiatorsValue,
                child: Text(l10n.iscsiTargetAllInitiators),
              ),
              for (final initiator in widget.initiators)
                DropdownMenuItem(
                  value: initiator.id,
                  child: Text(
                    _initiatorLabel(initiator.id),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (initiatorId) {
              if (initiatorId == null) return;
              setState(() {
                group.initiatorId = initiatorId == _allInitiatorsValue
                    ? null
                    : initiatorId;
                _errors = Map.of(_errors)..remove('groups');
              });
            },
          ),
          const SizedBox(height: 10),
          TrueDockDropdownButtonFormField<String>(
            key: ValueKey('auth-${group.key}-${group.authMethod}'),
            initialValue: group.authMethod,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.iscsiTargetAuthentication,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'NONE',
                child: Text(l10n.iscsiTargetAuthNone),
              ),
              DropdownMenuItem(
                value: 'CHAP',
                child: Text(l10n.iscsiTargetChapOneWay),
              ),
              DropdownMenuItem(
                value: 'CHAP_MUTUAL',
                child: Text(l10n.iscsiTargetChapMutual),
              ),
            ],
            onChanged: (method) {
              if (method == null) return;
              setState(() {
                group.authMethod = method;
                if (method == 'NONE') {
                  group.authId = null;
                } else {
                  final matching = widget.auths.where(
                    (auth) => method == 'CHAP_MUTUAL'
                        ? auth.isMutual
                        : !auth.isMutual,
                  );
                  group.authId = matching.isNotEmpty ? matching.first.id : null;
                }
                _errors = Map.of(_errors)..remove('groups');
              });
            },
          ),
          if (group.authMethod != 'NONE') ...[
            const SizedBox(height: 10),
            TrueDockDropdownButtonFormField<int>(
              key: ValueKey('authid-${group.key}-${group.authId}'),
              initialValue: widget.auths.any((auth) => auth.id == group.authId)
                  ? group.authId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.iscsiTargetChapCredential,
                border: const OutlineInputBorder(),
                helperText: widget.auths.isEmpty
                    ? l10n.iscsiTargetNoChapCredentials
                    : null,
              ),
              items: [
                for (final auth in widget.auths)
                  DropdownMenuItem(
                    value: auth.id,
                    child: Text(auth.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: widget.auths.isEmpty
                  ? null
                  : (authId) {
                      if (authId == null) return;
                      setState(() {
                        group.authId = authId;
                        _errors = Map.of(_errors)..remove('groups');
                      });
                    },
            ),
            if (widget.auths.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _TargetNotice(
                  message: l10n.iscsiTargetChapRequiredNotice,
                  warning: true,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildReview() {
    final configuration = _configuration;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: l10n.iscsiTargetReviewName,
                value: configuration.name.trim(),
              ),
              _ReviewRow(
                label: l10n.iscsiTargetAliasLabel,
                value: configuration.alias?.trim().isNotEmpty == true
                    ? configuration.alias!.trim()
                    : l10n.iscsiTargetAuthNone,
              ),
              _ReviewRow(
                label: l10n.iscsiTargetReviewNetworks,
                value: configuration.authNetworks.isEmpty
                    ? l10n.iscsiTargetAllNetworks
                    : configuration.authNetworks.join(', '),
              ),
              _ReviewRow(
                label: l10n.iscsiTargetQueueDepth,
                value:
                    configuration.queuedCommands?.toString() ??
                    l10n.iscsiTargetQueueServerDefault,
              ),
              _ReviewRow(
                label: l10n.iscsiTargetGroups,
                value: configuration.groups.length.toString(),
              ),
            ],
          ),
        ),
        if (configuration.groups.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.iscsiTargetGroups,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < configuration.groups.length; index++) ...[
            _ReviewGroup(
              index: index,
              group: configuration.groups[index],
              portalLabel: _portalLabel(configuration.groups[index].portalId),
              initiatorLabel: _initiatorLabel(
                configuration.groups[index].initiatorId,
              ),
            ),
            if (index != configuration.groups.length - 1)
              const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 12),
        if (configuration.groups.isEmpty)
          _TargetNotice(
            message: l10n.iscsiTargetReviewNoGroupNotice,
            warning: true,
          )
        else if (_hasUnrestrictedUnauthenticatedGroup)
          _TargetNotice(
            message: l10n.iscsiTargetReviewUnrestrictedNotice,
            warning: true,
          )
        else
          _TargetNotice(message: l10n.iscsiTargetReviewValidationNotice),
      ],
    );
  }

  IscsiTargetConfiguration get _configuration => IscsiTargetConfiguration(
    name: _nameController.text,
    alias: _nullIfEmpty(_aliasController.text),
    groups: _groups
        .map(
          (group) => IscsiTargetGroupConfiguration(
            portalId: group.portalId,
            initiatorId: group.initiatorId,
            authMethod: group.authMethod,
            authId: group.authId,
          ),
        )
        .toList(growable: false),
    authNetworks: _lines(_authNetworksController.text),
    queuedCommands: _queuedCommands.value,
  );

  bool get _hasUnrestrictedUnauthenticatedGroup {
    final configuration = _configuration;
    return configuration.groups.any((group) {
      if (group.authMethod != 'NONE') return false;
      if (group.initiatorId == null) return true;
      return widget.initiators
          .where((initiator) => initiator.id == group.initiatorId)
          .any((initiator) => initiator.allowsAll);
    });
  }

  void _addGroup() {
    if (widget.portals.isEmpty) return;
    setState(() {
      _groups.add(
        _TargetGroupDraft(
          key: _nextGroupKey++,
          portalId: widget.portals.first.id,
          authMethod: 'NONE',
        ),
      );
      _errors = Map.of(_errors)..remove('groups');
    });
  }

  void _removeGroup(_TargetGroupDraft group) {
    if (group.locked) return;
    setState(() {
      _groups.remove(group);
      _errors = Map.of(_errors)..remove('groups');
    });
  }

  void _clearError(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors = Map.of(_errors)..remove(key));
  }

  void _review() {
    final configuration = _configuration;
    final validationPortals = [...widget.portals];
    final validationInitiators = [...widget.initiators];
    for (final group in _groups.where((group) => group.locked)) {
      if (!validationPortals.any((portal) => portal.id == group.portalId)) {
        validationPortals.add(
          IscsiPortal(
            id: group.portalId,
            tag: 0,
            comment: '',
            listen: const [],
          ),
        );
      }
      final initiatorId = group.initiatorId;
      if (initiatorId != null &&
          !validationInitiators.any(
            (initiator) => initiator.id == initiatorId,
          )) {
        validationInitiators.add(
          IscsiInitiator(id: initiatorId, initiators: const [], comment: ''),
        );
      }
    }
    final errors = configuration.validate(
      availablePortals: validationPortals,
      availableInitiators: validationInitiators,
    );
    setState(() {
      _errors = {
        for (final field in errors.keys) field: l10n.validationError(field),
      };
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _configuration);

  String _portalLabel(int portalId) {
    for (final portal in widget.portals) {
      if (portal.id != portalId) continue;
      final detail = portal.comment.trim().isNotEmpty
          ? portal.comment.trim()
          : portal.addressSummary;
      return detail.isEmpty
          ? l10n.iscsiTargetPortalTag(portal.tag)
          : l10n.iscsiTargetPortalTagDetail(portal.tag, detail);
    }
    return l10n.iscsiTargetPortalUnavailable(portalId);
  }

  String _initiatorLabel(int? initiatorId) {
    if (initiatorId == null) return l10n.iscsiTargetAllInitiators;
    for (final initiator in widget.initiators) {
      if (initiator.id != initiatorId) continue;
      final detail = initiator.comment.trim().isNotEmpty
          ? initiator.comment.trim()
          : initiator.allowsAll
          ? l10n.iscsiTargetAllInitiators
          : initiator.initiators.join(', ');
      return detail.isEmpty
          ? l10n.iscsiTargetInitiatorGroup(initiator.id)
          : l10n.iscsiTargetInitiatorGroupDetail(initiator.id, detail);
    }
    return l10n.iscsiTargetInitiatorUnavailable(initiatorId);
  }
}

const int _allInitiatorsValue = -1;

class _TargetGroupDraft {
  _TargetGroupDraft({
    required this.key,
    required this.portalId,
    required this.authMethod,
    this.initiatorId,
    this.authId,
    this.locked = false,
  });

  final int key;
  int portalId;
  int? initiatorId;

  /// Mutable on new groups so the user can choose NONE, CHAP, or CHAP_MUTUAL
  /// and then pick a credential entry. Existing CHAP groups stay locked.
  String authMethod;
  int? authId;
  final bool locked;
}

enum _QueuedCommandChoice {
  serverDefault(null),
  commands32(32),
  commands128(128);

  const _QueuedCommandChoice(this.value);

  factory _QueuedCommandChoice.fromValue(int? value) => switch (value) {
    32 => commands32,
    128 => commands128,
    _ => serverDefault,
  };

  final int? value;
}

class _ReviewGroup extends StatelessWidget {
  const _ReviewGroup({
    required this.index,
    required this.group,
    required this.portalLabel,
    required this.initiatorLabel,
  });

  final int index;
  final IscsiTargetGroupConfiguration group;
  final String portalLabel;
  final String initiatorLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.iscsiTargetReviewGroup(index + 1, group.authMethod),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(portalLabel),
          Text(initiatorLabel),
          if (group.authMethod != 'NONE')
            Text(l10n.iscsiTargetCredentialId(group.authId?.toString() ?? '')),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _TargetNotice extends StatelessWidget {
  const _TargetNotice({required this.message, this.warning = false});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: warning
                ? colors.onErrorContainer
                : colors.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

List<String> _lines(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
