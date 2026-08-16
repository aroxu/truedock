import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../core/widgets/visible_auto_refresh.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../domain/privilege_configuration.dart';
import '../domain/system_resources.dart';
import 'privilege_sheet.dart';

/// Privileges (`privilege.*`): which groups can administer the server.
///
/// Loads its own data rather than joining the shared resource batch, which
/// already fans out enough concurrent reads to matter against the server's
/// per-connection call cap.
class PrivilegesSection extends ConsumerStatefulWidget {
  const PrivilegesSection({required this.groups, super.key});

  /// Local groups from the system resources, used as the grant targets.
  final List<NasGroup> groups;

  @override
  ConsumerState<PrivilegesSection> createState() => _PrivilegesSectionState();
}

class _PrivilegesSectionState extends ConsumerState<PrivilegesSection>
    with VisibleAutoRefreshState<PrivilegesSection> {
  List<Privilege>? _privileges;
  List<PrivilegeRole> _roles = const [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    startVisibleAutoRefresh(
      () => _load(showLoading: false, includeRoles: false),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({
    bool showLoading = true,
    bool includeRoles = true,
  }) async {
    if (_loading && !showLoading) return;
    if (!showLoading &&
        ref.read(serverActionControllerProvider).busyKeys.isNotEmpty) {
      return;
    }
    if (showLoading) setState(() => _loading = true);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final privileges = await controller.loadPrivileges();
    // The role catalog is needed to show effective grants, not just the roles
    // literally listed on a privilege.
    final roles = includeRoles ? await controller.loadPrivilegeRoles() : _roles;
    if (!mounted) return;
    setState(() {
      _privileges = privileges;
      _roles = roles ?? const [];
      _error = privileges == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canCreate = capabilities?.supports('privilege.create') == true;
    final canUpdate = capabilities?.supports('privilege.update') == true;
    final canDelete = capabilities?.supports('privilege.delete') == true;
    final privileges = _privileges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sysPrivilegesSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
        if (_loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!),
            ),
          )
        else if (privileges == null || privileges.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.sysPrivilegesEmpty),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, privilege) in privileges.indexed) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Icon(
                        // Unrestricted access is worth a distinct icon: it is
                        // the difference between an admin and a scoped operator.
                        privilege.grantsFullAdmin || privilege.webShell
                            ? Icons.admin_panel_settings_rounded
                            : Icons.badge_outlined,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(privilege.name)),
                        if (privilege.isBuiltin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.sysPrivilegeBuiltin,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${l10n.sysPrivilegeRoleCount(privilege.effectiveRoles(_roles).length)}'
                      ' · ${privilege.localGroupNames.isEmpty ? l10n.sysPrivilegeNoGroups : privilege.localGroupNames.join(', ')}',
                    ),
                    trailing: canUpdate || canDelete
                        ? PopupMenuButton<_PrivilegeAction>(
                            itemBuilder: (context) => [
                              if (canUpdate)
                                PopupMenuItem(
                                  value: _PrivilegeAction.edit,
                                  child: Text(l10n.sysEdit),
                                ),
                              // A built-in privilege cannot be deleted, so the
                              // action is absent rather than offered and failing.
                              if (canDelete && !privilege.isBuiltin)
                                PopupMenuItem(
                                  value: _PrivilegeAction.delete,
                                  child: Text(l10n.sysDelete),
                                ),
                            ],
                            onSelected: (action) => switch (action) {
                              _PrivilegeAction.edit => _edit(privilege),
                              _PrivilegeAction.delete => _delete(privilege),
                            },
                          )
                        : null,
                    onTap: canUpdate ? () => _edit(privilege) : null,
                  ),
                  if (index < privileges.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
        if (canCreate) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.sysPrivilegeCreate),
          ),
        ],
      ],
    );
  }

  String get _serverName =>
      ref.read(connectionControllerProvider).profile?.name ??
      AppLocalizations.of(context).systemServerFallback;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<PrivilegeConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PrivilegeSheet(
        baseline: const PrivilegeConfiguration(name: '', roles: []),
        roles: _roles,
        groups: widget.groups,
      ),
    );
    if (configuration == null || !mounted) return;
    if (!await _confirm(configuration, isBuiltin: false)) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createPrivilege(configuration);
    if (!mounted) return;
    _report(receipt != null, l10n.sysPrivilegeCreated);
    if (receipt != null) await _load();
  }

  Future<void> _edit(Privilege privilege) async {
    final l10n = AppLocalizations.of(context);
    final configuration = await showModalBottomSheet<PrivilegeConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PrivilegeSheet(
        baseline: PrivilegeConfiguration.from(privilege),
        roles: _roles,
        groups: widget.groups,
        isBuiltin: privilege.isBuiltin,
        isNew: false,
      ),
    );
    if (configuration == null || !mounted) return;
    if (!await _confirm(configuration, isBuiltin: privilege.isBuiltin)) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updatePrivilege(privilege.id, configuration);
    if (!mounted) return;
    _report(receipt != null, l10n.sysPrivilegeUpdated);
    if (receipt != null) await _load();
  }

  /// Confirms a grant.
  ///
  /// Escalates to a typed confirmation when the change grants unrestricted
  /// administration or narrows a built-in privilege, because both can end with
  /// nobody able to administer the server.
  Future<bool> _confirm(
    PrivilegeConfiguration configuration, {
    required bool isBuiltin,
  }) async {
    final l10n = AppLocalizations.of(context);
    final unrestricted = configuration.grantsUnrestrictedAccess;
    final critical = unrestricted || isBuiltin;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysPrivilegeApplyTitle(configuration.name),
      server: _serverName,
      target: configuration.name,
      actionLabel: l10n.sysPrivilegeApplyAction,
      impact: critical ? MutationImpact.critical : MutationImpact.high,
      confirmationText: critical ? configuration.name : null,
      consequences: [
        ImpactDetail(
          icon: Icons.group_rounded,
          text: l10n.sysPrivilegeApplyConsequence(_serverName),
        ),
        if (unrestricted)
          ImpactDetail(
            icon: Icons.admin_panel_settings_rounded,
            text: l10n.sysPrivilegeApplyConsequenceUnrestricted,
          ),
        if (isBuiltin)
          ImpactDetail(
            icon: Icons.lock_person_rounded,
            text: l10n.sysPrivilegeApplyConsequenceLockout,
          ),
      ],
    );
    return confirmed && mounted;
  }

  Future<void> _delete(Privilege privilege) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysPrivilegeDeleteTitle(privilege.name),
      server: _serverName,
      target: privilege.name,
      actionLabel: l10n.sysPrivilegeDeleteAction,
      impact: MutationImpact.critical,
      confirmationText: privilege.name,
      consequences: [
        ImpactDetail(
          icon: Icons.person_off_rounded,
          text: l10n.sysPrivilegeDeleteConsequence,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deletePrivilege(privilege.id);
    if (!mounted) return;
    _report(receipt != null, l10n.sysPrivilegeDeleted);
    if (receipt != null) await _load();
  }

  void _report(bool succeeded, String success) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? success
              : ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed,
        ),
        showCloseIcon: !succeeded,
      ),
    );
  }
}

enum _PrivilegeAction { edit, delete }
