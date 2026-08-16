import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../actions/presentation/server_action_controller.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../jobs/presentation/job_center.dart';
import '../../resources/domain/server_resources.dart';
import '../../resources/presentation/server_resources_provider.dart';
import '../domain/system_resources.dart';
import 'account_create_sheets.dart';
import 'account_edit_sheets.dart';
import 'user_password_sheet.dart';
import 'static_route_sheet.dart';
import 'network_commit_sheet.dart';
import 'network_global_sheet.dart';
import 'cron_section.dart';
import 'alert_services_section.dart';
import 'privileges_section.dart';
import 'config_backup_sheet.dart';
import 'audit_section.dart';
import '../domain/config_backup.dart';
import 'mail_sheet.dart';
import '../domain/mail_configuration.dart';
import '../domain/network_configuration.dart';
import 'interface_config_sheet.dart';
import '../domain/static_route_configuration.dart';
import '../domain/interface_configuration.dart';
import '../domain/system_general_configuration.dart';
import 'system_resources_provider.dart';
import 'system_general_sheet.dart';
import 'boot_environment_list.dart';
import 'api_key_list.dart';
import 'session_list.dart';
import 'system_value_localizations.dart';
import '../../../core/l10n/data_message_localizations.dart';

class SystemAdministrationScreen extends ConsumerStatefulWidget {
  const SystemAdministrationScreen({
    required this.section,
    this.onBack,
    super.key,
  });

  final String section;
  final VoidCallback? onBack;

  @override
  ConsumerState<SystemAdministrationScreen> createState() =>
      _SystemAdministrationScreenState();
}

class _SystemAdministrationScreenState
    extends ConsumerState<SystemAdministrationScreen> {
  static const refreshInterval = Duration(seconds: 1);
  late final AppLifecycleListener _lifecycleListener;
  Timer? _refreshTimer;
  var _appActive = true;
  var _visible = true;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _appActive = true,
      onPause: () => _appActive = false,
      onHide: () => _appActive = false,
      onInactive: () => _appActive = false,
      onDetach: () => _appActive = false,
    );
    _refreshTimer = Timer.periodic(
      refreshInterval,
      (_) => _refreshVisibleSection(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.onBack != null) return;
      ref.read(activeServerResourceScopeProvider.notifier).state =
          ServerResourceScope.system;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refreshVisibleSection() {
    if (!mounted || !_visible || !_appActive) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    if (!ref.read(connectionControllerProvider).isConnected) return;
    if (ref.read(serverActionControllerProvider).busyKeys.isNotEmpty) return;

    // Inline tablet/landscape sections are refreshed by AppShell's one global
    // timer. A pushed phone route is no longer covered by that shell route, so
    // it refreshes the two snapshots it renders here instead.
    if (widget.onBack == null) {
      if (!ref.read(systemResourcesProvider).isLoading) {
        ref.invalidate(systemResourcesProvider);
      }
      if (!ref.read(serverResourcesProvider).isLoading) {
        ref.invalidate(serverResourcesProvider);
      }
    }
    if (widget.section == 'updates' &&
        !ref.read(systemUpdateStatusProvider).isLoading) {
      ref.invalidate(systemUpdateStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = _SectionDefinition.fromPath(widget.section, l10n);
    final connected = ref.watch(connectionControllerProvider).isConnected;
    final resources = ref.watch(systemResourcesProvider);
    final serverResources = ref.watch(serverResourcesProvider);
    final liveUpdateStatus = widget.section == 'updates'
        ? ref.watch(systemUpdateStatusProvider)
        : null;

    return Scaffold(
      body: SafeRefreshIndicator(
        onRefresh: () async {
          refreshSystemResources(ref);
          refreshServerResources(ref);
          if (widget.section == 'updates') {
            ref.invalidate(systemUpdateStatusProvider);
          }
          await Future.wait([
            ref.read(systemResourcesProvider.future),
            ref.read(serverResourcesProvider.future),
            if (widget.section == 'updates')
              ref.read(systemUpdateStatusProvider.future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: widget.onBack == null,
              leading: widget.onBack == null
                  ? null
                  : IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: l10n.actionBack,
                    ),
              title: Text(definition.title),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: !connected
                  ? SliverToBoxAdapter(
                      child: _MessageCard(
                        icon: Icons.link_off_rounded,
                        message: l10n.sysConnectPrompt,
                      ),
                    )
                  : resources.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, _) => SliverToBoxAdapter(
                        child: _MessageCard(
                          icon: Icons.error_outline_rounded,
                          message: l10n.systemSettingsLoadFailed,
                        ),
                      ),
                      data: (data) => SliverList.list(
                        children: switch (definition.path) {
                          'general' => [
                            _GeneralSettingsSection(
                              key: ValueKey(data),
                              onReboot: () => _rebootServer(context, ref),
                              onShutdown: () => _shutdownServer(context, ref),
                            ),
                          ],
                          'accounts' => _accounts(context, ref, data),
                          'network' => _network(context, ref, data),
                          'cron' => _cron(context, ref),
                          'updates' => _updates(
                            context,
                            ref,
                            data,
                            liveUpdateStatus,
                          ),
                          'advanced' => _advanced(context, ref, data),
                          _ => _activity(context, ref, serverResources),
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _accounts(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
  ) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final actions = ref.watch(serverActionControllerProvider);
    final canEditUsers = capabilities?.supports('user.update') == true;
    final canEditGroups = capabilities?.supports('group.update') == true;
    final canCreateUsers = capabilities?.supports('user.create') == true;
    final canDeleteUsers = capabilities?.supports('user.delete') == true;
    final canCreateGroups = capabilities?.supports('group.create') == true;
    final canDeleteGroups = capabilities?.supports('group.delete') == true;
    final visibleUsers = [...data.users.items]
      ..sort((a, b) {
        final builtin = a.builtin == b.builtin ? 0 : (a.builtin ? 1 : -1);
        return builtin != 0 ? builtin : a.username.compareTo(b.username);
      });
    final visibleGroups = [...data.groups.items]
      ..sort((a, b) {
        final builtin = a.builtin == b.builtin ? 0 : (a.builtin ? 1 : -1);
        return builtin != 0 ? builtin : a.name.compareTo(b.name);
      });
    return [
      _MetricStrip(
        metrics: [
          (
            l10n.sysMetricUsers,
            '${data.users.items.length}',
            Icons.person_outline_rounded,
          ),
          (
            l10n.sysMetricGroups,
            '${data.groups.items.length}',
            Icons.groups_outlined,
          ),
          (
            l10n.sysMetricAdmins,
            '${data.users.items.where((user) => user.isAdministrator).length}',
            Icons.admin_panel_settings_outlined,
          ),
        ],
      ),
      const SizedBox(height: 28),
      _ActionHeading(
        title: l10n.sysUsers,
        count: data.users.items.length,
        actionLabel: l10n.sysNewUser,
        onAction: canCreateUsers
            ? () => _createUser(context, ref, data.groups.items)
            : null,
      ),
      const SizedBox(height: 12),
      if (data.users.hasError)
        _MessageCard(
          icon: Icons.lock_outline_rounded,
          message: l10n.dataMessage(data.users.error!),
        )
      else if (visibleUsers.isEmpty)
        _MessageCard(icon: Icons.person_off_outlined, message: l10n.sysNoUsers)
      else
        _UserList(
          users: visibleUsers.take(100).toList(),
          canEdit: canEditUsers,
          canDelete: canDeleteUsers,
          canChangePassword: canEditUsers,
          onEdit: (user) => _editUser(context, ref, user, data.groups.items),
          onDelete: (user) => _deleteUser(context, ref, user, data),
          onChangePassword: (user) => _changeUserPassword(context, ref, user),
        ),
      const SizedBox(height: 28),
      _ActionHeading(
        title: l10n.sysGroups,
        count: data.groups.items.length,
        actionLabel: l10n.sysNewGroup,
        onAction: canCreateGroups
            ? () => _createGroup(context, ref, data.users.items)
            : null,
      ),
      const SizedBox(height: 12),
      if (data.groups.hasError)
        _MessageCard(
          icon: Icons.lock_outline_rounded,
          message: l10n.dataMessage(data.groups.error!),
        )
      else if (visibleGroups.isEmpty)
        _MessageCard(icon: Icons.group_off_outlined, message: l10n.sysNoGroups)
      else
        _GroupList(
          groups: visibleGroups.take(100).toList(),
          canEdit: canEditGroups,
          canDelete: canDeleteGroups,
          onEdit: (group) => _editGroup(context, ref, group, data.users.items),
          onDelete: (group) => _deleteGroup(context, ref, group, data),
        ),
      const SizedBox(height: 28),
      // API keys live with accounts because they are credentials for an
      // account, and revoking one is the independent withdrawal that makes
      // API-key authentication preferable in the first place.
      _Heading(title: l10n.sysApiKeys, count: data.apiKeys.items.length),
      const SizedBox(height: 12),
      ApiKeyList(
        section: data.apiKeys,
        canRevoke: capabilities?.supports('api_key.delete') == true,
        busyIds: {
          for (final key in data.apiKeys.items)
            if (actions.isBusy('api-key-delete:${key.id}')) key.id,
        },
        onRevoke: (key) => _revokeApiKey(context, ref, key),
        now: DateTime.now(),
      ),
      // Sessions sit with API keys because both answer a credential question,
      // but a different one: keys say what could connect, sessions say what is
      // connected now. That is what you look at when an account may be
      // compromised.
      if (capabilities?.supports('auth.sessions') == true) ...[
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _Heading(
                title: l10n.sysSessions,
                count: data.sessions.items
                    .where((session) => session.isUserSession)
                    .length,
              ),
            ),
            if (capabilities?.supports('auth.terminate_other_sessions') ==
                    true &&
                data.sessions.items
                        .where((s) => s.isUserSession && !s.current)
                        .length >
                    1)
              TextButton(
                onPressed: actions.isBusy('session-terminate-others')
                    ? null
                    : () => _terminateOtherSessions(context, ref, data),
                child: Text(l10n.sysSessionTerminateOthers),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SessionList(
          section: data.sessions,
          canTerminate:
              capabilities?.supports('auth.terminate_session') == true,
          busyIds: {
            for (final session in data.sessions.items)
              if (actions.isBusy('session-terminate:${session.id}')) session.id,
          },
          onTerminate: (session) => _terminateSession(context, ref, session),
          now: DateTime.now(),
        ),
      ],
      // Privileges belong with accounts: users and groups say who exists,
      // privileges say what any of them may administer.
      if (capabilities?.supports('privilege.query') == true) ...[
        const SizedBox(height: 28),
        Text(
          l10n.sysPrivilegesTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        PrivilegesSection(groups: data.groups.items),
      ],
    ];
  }

  /// Ends one authenticated session.
  ///
  /// Confirmed rather than a bare tap: the target is somebody's live
  /// connection, and the consequence names where it is coming from so the user
  /// can tell an intruder from their own laptop. It is `high` rather than
  /// `critical` because nothing stored is destroyed - the client can sign in
  /// again, which the confirmation says plainly so ending a session is not
  /// mistaken for locking an attacker out.
  Future<void> _terminateSession(
    BuildContext context,
    WidgetRef ref,
    NasSession session,
  ) async {
    final l10n = AppLocalizations.of(context);
    final origin = l10n.systemOriginLabel(session.origin);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysSessionTerminateTitle,
      server: _serverName(ref, l10n),
      target: session.username?.isNotEmpty == true
          ? '${session.username} · $origin'
          : origin,
      actionLabel: l10n.sysSessionTerminateAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.logout_rounded,
          text: l10n.sysSessionTerminateConsequence(origin),
        ),
        ImpactDetail(
          icon: Icons.login_rounded,
          text: l10n.sysSessionTerminateReconnect,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .terminateSession(session.id);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysSessionTerminateAction,
      success: l10n.sysSessionTerminated,
    );
  }

  /// Ends every session except this one.
  ///
  /// Uses `auth.terminate_other_sessions` rather than looping: the server
  /// excludes the caller, so a client-side loop would race its own connection
  /// and could sign TrueDock out halfway through.
  Future<void> _terminateOtherSessions(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final others = data.sessions.items
        .where((session) => session.isUserSession && !session.current)
        .length;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysSessionTerminateOthersTitle,
      server: _serverName(ref, l10n),
      target: _serverName(ref, l10n),
      actionLabel: l10n.sysSessionTerminateOthers,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.logout_rounded,
          text: l10n.sysSessionTerminateOthersConsequence(others),
        ),
        ImpactDetail(
          icon: Icons.smartphone_rounded,
          text: l10n.sysSessionTerminateOthersKeepsThis,
        ),
        ImpactDetail(
          icon: Icons.login_rounded,
          text: l10n.sysSessionTerminateReconnect,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .terminateOtherSessions();
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysSessionTerminateOthers,
      success: l10n.sysSessionTerminated,
    );
  }

  /// Revokes an API key.
  ///
  /// This is the independent withdrawal that makes API-key authentication
  /// preferable to a password, so the confirmation names what stops working
  /// rather than treating it as a routine delete. The key cannot be recovered:
  /// TrueNAS returns the secret only once, at creation.
  Future<void> _revokeApiKey(
    BuildContext context,
    WidgetRef ref,
    NasApiKey apiKey,
  ) async {
    final l10n = AppLocalizations.of(context);
    final owner = apiKey.username;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysRevokeApiKeyTitle(apiKey.name),
      server: _serverName(ref, l10n),
      target: apiKey.name,
      actionLabel: l10n.sysRevokeApiKeyAction,
      impact: MutationImpact.critical,
      consequences: [
        ImpactDetail(
          icon: Icons.key_off_outlined,
          text: l10n.sysRevokeApiKeyConsequence,
        ),
        ImpactDetail(
          icon: Icons.lock_reset_rounded,
          text: owner == null || owner.isEmpty
              ? l10n.sysRevokeApiKeyUnowned
              : l10n.sysRevokeApiKeyOwned(owner),
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteApiKey(apiKey.id);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysRevokeApiKeyActionLabel(apiKey.name),
      success: l10n.sysRevokedApiKey(apiKey.name),
    );
  }

  Future<void> _editUser(
    BuildContext context,
    WidgetRef ref,
    NasUser user,
    List<NasGroup> groups,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => UserEditSheet(user: user, groups: groups),
    );
    if (payload == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateUser(user.id, payload);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysUpdateActionLabel(user.username),
      success: l10n.sysUpdatedEntity(user.username),
    );
  }

  Future<void> _changeUserPassword(
    BuildContext context,
    WidgetRef ref,
    NasUser user,
  ) async {
    final l10n = AppLocalizations.of(context);
    final password = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => UserPasswordSheet(user: user),
    );
    if (password == null || password.isEmpty || !context.mounted) return;

    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysChangePasswordTitle(user.username),
      server: _serverName(ref, l10n),
      target: user.username,
      actionLabel: l10n.sysChangePasswordAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.key_rounded,
          text: l10n.sysChangePasswordImmediate,
        ),
        ImpactDetail(
          icon: Icons.logout_rounded,
          text: l10n.sysChangePasswordSessions,
        ),
        ImpactDetail(
          icon: Icons.shield_outlined,
          text: l10n.sysChangePasswordPrivacy,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .changeUserPassword(user.id, password: password);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysChangePasswordActionLabel(user.username),
      success: l10n.sysPasswordChanged(user.username),
    );
  }

  Future<void> _editGroup(
    BuildContext context,
    WidgetRef ref,
    NasGroup group,
    List<NasUser> users,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => GroupEditSheet(group: group, users: users),
    );
    if (payload == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateGroup(group.id, payload);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysUpdateActionLabel(group.name),
      success: l10n.sysUpdatedEntity(group.name),
    );
  }

  void _showAccountResult(
    BuildContext context,
    WidgetRef ref, {
    required bool succeeded,
    required String action,
    required String success,
  }) {
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? success
              : error ??
                    AppLocalizations.of(context).sysOperationFailed(action),
        ),
        showCloseIcon: !succeeded,
      ),
    );
  }

  Future<void> _createUser(
    BuildContext context,
    WidgetRef ref,
    List<NasGroup> groups,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => UserCreateSheet(groups: groups),
    );
    if (payload == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createUser(payload);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysCreateActionLabel('${payload['username']}'),
      success: l10n.sysCreatedEntity('${payload['username']}'),
    );
  }

  Future<void> _createGroup(
    BuildContext context,
    WidgetRef ref,
    List<NasUser> users,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => GroupCreateSheet(users: users),
    );
    if (payload == null || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createGroup(payload);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysCreateActionLabel('${payload['name']}'),
      success: l10n.sysCreatedEntity('${payload['name']}'),
    );
  }

  /// Deleting an account is irreversible, so it requires the username to be
  /// typed and states what the account still owns.
  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    NasUser user,
    SystemResources data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ownedGroups = data.groups.items
        .where((group) => group.userIds.contains(user.id))
        .length;
    final primaryGroup = data.groups.items
        .where((group) => group.id == user.primaryGroupId)
        .firstOrNull;
    // Only offer to remove the primary group when nobody else is in it.
    final canRemovePrimaryGroup =
        primaryGroup != null &&
        !primaryGroup.builtin &&
        primaryGroup.userIds.where((id) => id != user.id).isEmpty;

    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysDeleteUserTitle,
      server: _serverName(ref, l10n),
      target: user.username,
      actionLabel: l10n.sysDeleteUserAction,
      impact: MutationImpact.critical,
      confirmationText: user.username,
      consequences: [
        ImpactDetail(
          icon: Icons.person_remove_outlined,
          text: l10n.sysDeleteUserConsequenceAccount,
        ),
        if (ownedGroups > 0)
          ImpactDetail(
            icon: Icons.groups_outlined,
            text: l10n.sysDeleteUserConsequenceGroups(ownedGroups),
          ),
        if (canRemovePrimaryGroup)
          ImpactDetail(
            icon: Icons.group_remove_outlined,
            text: l10n.sysDeleteUserConsequencePrimaryGroup(primaryGroup.name),
          ),
        ImpactDetail(
          icon: Icons.folder_outlined,
          text: l10n.sysDeleteUserConsequenceFiles,
        ),
      ],
      note: l10n.sysDeleteUserNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteUser(user.id, deletePrimaryGroup: canRemovePrimaryGroup);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysDeleteActionLabel(user.username),
      success: l10n.sysDeletedEntity(user.username),
    );
  }

  Future<void> _deleteGroup(
    BuildContext context,
    WidgetRef ref,
    NasGroup group,
    SystemResources data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final primaryFor = data.users.items
        .where((user) => user.primaryGroupId == group.id)
        .length;

    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysDeleteGroupTitle,
      server: _serverName(ref, l10n),
      target: group.name,
      actionLabel: l10n.sysDeleteGroupAction,
      impact: MutationImpact.critical,
      confirmationText: group.name,
      consequences: [
        ImpactDetail(
          icon: Icons.group_remove_outlined,
          text: l10n.sysDeleteGroupConsequenceMembers(group.userIds.length),
        ),
        ImpactDetail(
          icon: Icons.folder_shared_outlined,
          text: l10n.sysDeleteGroupConsequencePermissions,
        ),
        if (primaryFor > 0)
          ImpactDetail(
            icon: Icons.warning_amber_rounded,
            text: l10n.sysDeleteGroupConsequencePrimary(primaryFor),
          ),
      ],
      note: l10n.sysDeleteGroupNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteGroup(group.id, deleteUsers: false);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysDeleteActionLabel(group.name),
      success: l10n.sysDeletedEntity(group.name),
    );
  }

  /// Applying an update reboots into new system software, so the confirmation
  /// names the exact version and requires it to be typed.
  Future<OperationReceipt?> _runUpdate(
    BuildContext context,
    WidgetRef ref,
    SystemUpdateStatus status,
  ) async {
    final l10n = AppLocalizations.of(context);
    final version = status.newVersion;
    if (version == null) return null;
    final resources = ref.read(serverResourcesProvider).value;
    final activeJobs =
        resources?.jobs.items.where((job) => job.isActive).length ?? 0;
    final runningApps =
        resources?.apps.items.where((app) => app.state == 'RUNNING').length ??
        0;

    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysInstallUpdateTitle(version),
      server: _serverName(ref, l10n),
      target: version,
      actionLabel: l10n.sysInstallUpdateAction,
      impact: MutationImpact.critical,
      confirmationText: version,
      consequences: [
        ImpactDetail(
          icon: Icons.system_update_alt_rounded,
          text: l10n.sysInstallUpdateConsequenceRestart,
        ),
        ImpactDetail(
          icon: Icons.dns_outlined,
          text: l10n.sysInstallUpdateConsequenceServices(runningApps),
        ),
        if (activeJobs > 0)
          ImpactDetail(
            icon: Icons.pending_actions_outlined,
            text: l10n.sysInstallUpdateConsequenceJobs(activeJobs),
          ),
        ImpactDetail(
          icon: Icons.link_off_rounded,
          text: l10n.sysInstallUpdateConsequenceConnection,
        ),
      ],
      note: l10n.sysInstallUpdateNote,
    );
    if (!confirmed || !context.mounted) return null;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .runSystemUpdate(rebootAfter: true);
    if (!context.mounted) return receipt;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysInstallUpdateActionLabel(version),
      success: l10n.sysUpdateStarted,
    );
    return receipt;
  }

  Future<void> _rebootServer(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _powerAction(
      context,
      ref,
      title: l10n.sysRestartTitle,
      actionLabel: l10n.sysRestartAction,
      verb: l10n.sysRestartVerb,
      extra: ImpactDetail(
        icon: Icons.restart_alt_rounded,
        text: l10n.sysRestartExtra,
      ),
      operation: (controller, reason) =>
          controller.rebootServer(reason: reason),
      success: l10n.sysRestartSuccess,
    );
  }

  Future<void> _shutdownServer(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _powerAction(
      context,
      ref,
      title: l10n.sysShutdownTitle,
      actionLabel: l10n.sysShutdownAction,
      verb: l10n.sysShutdownVerb,
      extra: ImpactDetail(
        icon: Icons.power_off_rounded,
        text: l10n.sysShutdownExtra,
      ),
      operation: (controller, reason) =>
          controller.shutdownServer(reason: reason),
      success: l10n.sysShutdownSuccess,
    );
  }

  /// Selects a boot environment for the next boot.
  ///
  /// This does not reboot and does not change the running system, so the
  /// confirmation says so plainly: the risk is a user believing they have just
  /// rolled back when nothing has happened yet.
  Future<void> _activateBootEnvironment(
    BuildContext context,
    WidgetRef ref,
    BootEnvironment environment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final serverName = _serverName(ref, l10n);
    final current = ref
        .read(systemResourcesProvider)
        .value
        ?.bootEnvironments
        .items
        .where((candidate) => candidate.active)
        .firstOrNull;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysBootIntoTitle(environment.id),
      server: serverName,
      target: environment.id,
      actionLabel: l10n.sysBootIntoAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: l10n.sysBootIntoConsequenceRestart(serverName, environment.id),
        ),
        ImpactDetail(
          icon: Icons.swap_vert_rounded,
          text: current == null
              ? l10n.sysBootIntoConsequenceUnknownCurrent
              : l10n.sysBootIntoConsequenceCurrent(current.id),
        ),
        ImpactDetail(
          icon: Icons.storage_rounded,
          text: l10n.sysBootEnvironmentDataNote,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .activateBootEnvironment(environment.id);
    if (!context.mounted) return;
    _showSystemResult(
      context,
      ref,
      receipt,
      l10n.sysBootEnvironmentActivated(environment.id),
    );
  }

  Future<void> _setBootEnvironmentKept(
    BuildContext context,
    WidgetRef ref,
    BootEnvironment environment,
    bool keep,
  ) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setBootEnvironmentKept(environment.id, keep: keep);
    if (!context.mounted) return;
    _showSystemResult(
      context,
      ref,
      receipt,
      keep
          ? l10n.sysBootEnvironmentKept(environment.id)
          : l10n.sysBootEnvironmentUnkept(environment.id),
    );
  }

  /// Permanently removes a boot environment. Irreversible, so it requires the
  /// name to be typed.
  Future<void> _destroyBootEnvironment(
    BuildContext context,
    WidgetRef ref,
    BootEnvironment environment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysDeleteBootEnvironmentTitle(environment.id),
      server: _serverName(ref, l10n),
      target: environment.id,
      actionLabel: l10n.sysDeleteBootEnvironmentAction,
      impact: MutationImpact.critical,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.sysDeleteBootEnvironmentConsequence(environment.id),
        ),
        ImpactDetail(
          icon: Icons.storage_rounded,
          text: l10n.sysBootEnvironmentDataNote,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .destroyBootEnvironment(environment.id);
    if (!context.mounted) return;
    _showSystemResult(
      context,
      ref,
      receipt,
      l10n.sysBootEnvironmentDeleted(environment.id),
    );
  }

  void _showSystemResult(
    BuildContext context,
    WidgetRef ref,
    OperationReceipt? receipt,
    String success,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    AppLocalizations.of(context).sysGenericOperationFailed
              : success,
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _powerAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String actionLabel,
    required String verb,
    required ImpactDetail extra,
    required Future<OperationReceipt?> Function(
      ServerActionController controller,
      String reason,
    )
    operation,
    required String success,
  }) async {
    final l10n = AppLocalizations.of(context);
    final serverName = _serverName(ref, l10n);
    final resources = ref.read(serverResourcesProvider).value;
    final activeJobs =
        resources?.jobs.items.where((job) => job.isActive).length ?? 0;
    final runningApps =
        resources?.apps.items.where((app) => app.state == 'RUNNING').length ??
        0;
    final runningVms =
        resources?.virtualMachines.items.where((vm) => vm.isRunning).length ??
        0;

    final confirmed = await confirmDestructiveAction(
      context,
      title: title,
      server: serverName,
      target: serverName,
      actionLabel: actionLabel,
      impact: MutationImpact.critical,
      confirmationText: serverName,
      consequences: [
        ImpactDetail(
          icon: Icons.folder_shared_outlined,
          text: l10n.sysPowerConsequenceClients,
        ),
        if (runningApps > 0 || runningVms > 0)
          ImpactDetail(
            icon: Icons.widgets_outlined,
            text: l10n.sysPowerConsequenceWorkloads(runningApps, runningVms),
          ),
        if (activeJobs > 0)
          ImpactDetail(
            icon: Icons.pending_actions_outlined,
            text: l10n.sysPowerConsequenceJobs(activeJobs),
          ),
        extra,
      ],
      note: l10n.sysPowerNote,
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await operation(
      ref.read(serverActionControllerProvider.notifier),
      l10n.sysPowerReason,
    );
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysPowerActionLabel(verb, serverName),
      success: success,
    );
  }

  String _serverName(WidgetRef ref, AppLocalizations l10n) =>
      ref.read(connectionControllerProvider).profile?.name ??
      l10n.systemServerFallback;

  List<Widget> _network(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
  ) {
    final l10n = AppLocalizations.of(context);
    // Sort again at the rendering boundary so a retained provider snapshot
    // created before a refresh cannot leak the server's arbitrary query order
    // into the visible list.
    final interfaces = data.interfaces.items.toList(growable: false)
      ..sort((left, right) => naturalDeviceNameCompare(left.name, right.name));
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canCreateRoute = capabilities?.supports('staticroute.create') == true;
    final canUpdateRoute = capabilities?.supports('staticroute.update') == true;
    final canDeleteRoute = capabilities?.supports('staticroute.delete') == true;
    final canCommit =
        capabilities?.supports('interface.commit') == true &&
        capabilities?.supports('interface.checkin') == true;
    final canEditInterface = capabilities?.supports('interface.update') == true;
    final canEditGlobalNetwork =
        capabilities?.supports('network.configuration.config') == true &&
        capabilities?.supports('network.configuration.update') == true;
    final dhcpInterface = interfaces
        .where((item) => item.dhcp)
        .map((item) => item.name)
        .firstOrNull;
    return [
      _MetricStrip(
        metrics: [
          (
            l10n.sysMetricInterfaces,
            '${interfaces.length}',
            Icons.lan_outlined,
          ),
          (
            l10n.sysMetricLinkUp,
            '${interfaces.where((item) => item.isUp).length}',
            Icons.link_rounded,
          ),
          (
            l10n.sysMetricRoutes,
            '${data.routes.items.length}',
            Icons.route_outlined,
          ),
        ],
      ),
      const SizedBox(height: 28),
      _Heading(title: l10n.sysInterfaces, count: interfaces.length),
      const SizedBox(height: 12),
      if (data.interfaces.hasError)
        _MessageCard(
          icon: Icons.lock_outline_rounded,
          message: l10n.dataMessage(data.interfaces.error!),
        )
      else if (interfaces.isEmpty)
        _MessageCard(
          icon: Icons.portable_wifi_off_outlined,
          message: l10n.sysNoInterfaces,
        )
      else
        ...interfaces.map(
          (item) => _InterfaceCard(
            item,
            onEdit: canEditInterface
                ? () => _editInterface(context, ref, item, dhcpInterface)
                : null,
          ),
        ),
      const SizedBox(height: 24),
      _ActionHeading(
        title: l10n.sysStaticRoutes,
        count: data.routes.items.length,
        actionLabel: l10n.sysNewRoute,
        onAction: canCreateRoute
            ? () => _createStaticRoute(context, ref)
            : null,
      ),
      const SizedBox(height: 12),
      if (data.routes.hasError)
        _MessageCard(
          icon: Icons.lock_outline_rounded,
          message: l10n.dataMessage(data.routes.error!),
        )
      else if (data.routes.items.isEmpty)
        _MessageCard(
          icon: Icons.route_outlined,
          message: l10n.sysNoStaticRoutes,
        )
      else
        Card(
          child: Column(
            children: [
              for (final (index, route) in data.routes.items.indexed) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.alt_route_rounded),
                  title: Text(l10n.systemNetworkLabel(route.destination)),
                  subtitle: Text(
                    route.description == null || route.description!.isEmpty
                        ? l10n.sysRouteVia(
                            l10n.systemNetworkLabel(route.gateway),
                          )
                        : l10n.sysRouteViaWithDescription(
                            l10n.systemNetworkLabel(route.gateway),
                            route.description!,
                          ),
                  ),
                  trailing: canUpdateRoute || canDeleteRoute
                      ? PopupMenuButton<_RouteAction>(
                          itemBuilder: (context) => [
                            if (canUpdateRoute)
                              PopupMenuItem(
                                value: _RouteAction.edit,
                                child: Text(l10n.sysEdit),
                              ),
                            if (canDeleteRoute)
                              PopupMenuItem(
                                value: _RouteAction.delete,
                                child: Text(l10n.sysDelete),
                              ),
                          ],
                          onSelected: (action) {
                            if (action == _RouteAction.edit) {
                              _editStaticRoute(context, ref, route);
                            } else if (action == _RouteAction.delete) {
                              _deleteStaticRoute(context, ref, route);
                            }
                          },
                        )
                      : null,
                  onTap: canUpdateRoute
                      ? () => _editStaticRoute(context, ref, route)
                      : null,
                ),
                if (index < data.routes.items.length - 1)
                  const Divider(indent: 68, height: 1),
              ],
            ],
          ),
        ),
      if (canEditGlobalNetwork) ...[
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.sysNetGlobalTitle),
            subtitle: Text(l10n.sysNetGlobalSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _editGlobalNetwork(context, ref),
          ),
        ),
      ],
      if (canCommit) ...[
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () => _applyNetworkChanges(context, ref),
          icon: const Icon(Icons.bolt_rounded),
          label: Text(l10n.sysApplyNetworkChanges),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.sysApplyNetworkChangesHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ];
  }

  Future<void> _createStaticRoute(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final created = await showModalBottomSheet<StaticRouteConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => const StaticRouteSheet(
        baseline: StaticRouteConfiguration(destination: '', gateway: ''),
      ),
    );
    if (created == null || !context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysStageRouteTitle(created.destination),
      server: _serverName(ref, l10n),
      target: created.destination,
      actionLabel: l10n.sysStageRouteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.alt_route_rounded,
          text: l10n.sysRouteConsequence(created.destination, created.gateway),
        ),
        ImpactDetail(
          icon: Icons.bolt_rounded,
          text: l10n.sysRouteStagedConsequence,
        ),
      ],
      note: l10n.sysRouteStagedNote,
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createStaticRoute(created);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysStageRouteActionLabel(created.destination),
      success: l10n.sysRouteStagedSuccess(created.destination),
    );
  }

  Future<void> _editStaticRoute(
    BuildContext context,
    WidgetRef ref,
    StaticRoute route,
  ) async {
    final l10n = AppLocalizations.of(context);
    final baseline = StaticRouteConfiguration(
      id: route.id,
      destination: route.destination,
      gateway: route.gateway,
      description: route.description ?? '',
    );
    final updated = await showModalBottomSheet<StaticRouteConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StaticRouteSheet(baseline: baseline),
    );
    if (updated == null || !context.mounted) return;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysUpdateRouteTitle(updated.destination),
      server: _serverName(ref, l10n),
      target: updated.destination,
      actionLabel: l10n.sysStageUpdateAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.alt_route_rounded,
          text: l10n.sysRouteConsequence(updated.destination, updated.gateway),
        ),
        ImpactDetail(
          icon: Icons.bolt_rounded,
          text: l10n.sysRouteChangeStagedConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateStaticRoute(route.id, updated);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysUpdateRouteActionLabel(updated.destination),
      success: l10n.sysRouteUpdateStagedSuccess(updated.destination),
    );
  }

  Future<void> _deleteStaticRoute(
    BuildContext context,
    WidgetRef ref,
    StaticRoute route,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysDeleteRouteTitle(route.destination),
      server: _serverName(ref, l10n),
      target: route.destination,
      actionLabel: l10n.sysStageDeletionAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.alt_route_rounded,
          text: l10n.sysRouteRemoveConsequence(
            route.destination,
            route.gateway,
          ),
        ),
        ImpactDetail(
          icon: Icons.bolt_rounded,
          text: l10n.sysRouteDeletionStagedConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteStaticRoute(route.id);
    if (!context.mounted) return;
    _showAccountResult(
      context,
      ref,
      succeeded: receipt != null,
      action: l10n.sysDeleteRouteActionLabel(route.destination),
      success: l10n.sysRouteDeletionStagedSuccess(route.destination),
    );
  }

  /// Edits the global network settings: hostname, domain, default gateway,
  /// nameservers, and HTTP proxy.
  ///
  /// Unlike an interface edit, `network.configuration.update` applies
  /// immediately — there is no commit/check-in window to fall back on — so
  /// clearing a gateway or nameserver the server is actually using can sever
  /// this session with no automatic rollback. That case gets a distinct
  /// consequence rather than the generic warning.
  Future<void> _editGlobalNetwork(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final baseline = await controller.loadNetworkConfiguration();
    if (!context.mounted) return;
    if (baseline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.sysGenericOperationFailed,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }
    // Best-effort: the summary is context, so a failure here must not block the
    // editor.
    final summary = await controller.loadNetworkSummary();
    if (!context.mounted) return;

    final edit = await showModalBottomSheet<NetworkConfigurationEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => NetworkGlobalSheet(baseline: baseline, summary: summary),
    );
    if (edit == null || !context.mounted) return;
    if (edit.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sysNetGlobalNoChanges)));
      return;
    }

    final serverName = _serverName(ref, l10n);
    final severs = edit.clearsEffectiveRouting(baseline);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysNetGlobalApplyTitle,
      server: serverName,
      target: baseline.hostname,
      actionLabel: l10n.sysNetGlobalApplyAction,
      impact: severs ? MutationImpact.critical : MutationImpact.high,
      confirmationText: severs ? baseline.hostname : null,
      consequences: [
        ImpactDetail(
          icon: Icons.bolt_rounded,
          text: l10n.sysNetGlobalConsequenceImmediate,
        ),
        if (severs)
          ImpactDetail(
            icon: Icons.link_off_rounded,
            text: l10n.sysNetGlobalConsequenceSever(serverName),
          ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await controller.updateNetworkConfiguration(edit);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed
              : l10n.sysNetGlobalUpdated,
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null) refreshSystemResources(ref);
  }

  Future<void> _applyNetworkChanges(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final connection = ref.read(connectionControllerProvider);
        return NetworkCommitSheet(
          serverName: _serverName(ref, l10n),
          serverAddress: connection.profile?.baseUri.toString() ?? '',
          testChangedAddress: ref
              .read(connectionControllerProvider.notifier)
              .testChangedServerAddress,
          confirmChangedAddress: ref
              .read(connectionControllerProvider.notifier)
              .confirmChangedServerAddress,
        );
      },
    );
    if (!context.mounted) return;
    refreshSystemResources(ref);
  }

  /// Edits an interface's addressing through `interface.update`.
  ///
  /// The change is staged, so a successful save offers the commit/checkin
  /// workflow immediately: without it the server reverts the change at the
  /// end of its verification window.
  Future<void> _editInterface(
    BuildContext context,
    WidgetRef ref,
    NetworkInterface item,
    String? dhcpInterfaceName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final raw = await controller.getInterfaceConfig(item.id);
    if (!context.mounted) return;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.sysInterfaceConfigLoadFailed),
          showCloseIcon: true,
        ),
      );
      return;
    }
    final baseline = InterfaceConfiguration.fromJson(raw);
    final next = await showModalBottomSheet<InterfaceConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => InterfaceConfigSheet(
        baseline: baseline,
        dhcpOwnedByOtherInterface:
            dhcpInterfaceName != null && dhcpInterfaceName != item.name
            ? dhcpInterfaceName
            : null,
      ),
    );
    if (next == null || !context.mounted) return;
    if (!next.differsFrom(baseline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sysInterfaceNoChanges(item.name))),
      );
      return;
    }
    final losesStatic =
        baseline.aliases.any((alias) => !alias.isIpv6) && next.ipv4Dhcp;
    final losesStaticIpv6 =
        baseline.aliases.any((alias) => alias.isIpv6) &&
        next.ipv6Auto &&
        !baseline.ipv6Auto;
    final staticIpv4Aliases = next.activeAliases
        .where((alias) => !alias.isIpv6)
        .toList(growable: false);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysStageInterfaceTitle(item.name),
      server: _serverName(ref, l10n),
      target: item.name,
      actionLabel: l10n.sysStageChangeAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.lan_rounded,
          text: next.ipv4Dhcp
              ? l10n.sysInterfaceDhcpConsequence(item.name)
              : l10n.sysInterfaceStaticConsequence(
                  item.name,
                  staticIpv4Aliases.length,
                  staticIpv4Aliases.map((a) => a.label).join(', '),
                ),
        ),
        ImpactDetail(
          icon: Icons.looks_6_outlined,
          text: next.ipv6Auto
              ? l10n.sysInterfaceIpv6AutoEnabledConsequence(item.name)
              : l10n.sysInterfaceIpv6AutoDisabledConsequence(item.name),
        ),
        if (losesStatic)
          ImpactDetail(
            icon: Icons.link_off_rounded,
            text: l10n.sysInterfaceLosesStatic,
          ),
        if (losesStaticIpv6)
          ImpactDetail(
            icon: Icons.link_off_rounded,
            text: l10n.sysInterfaceIpv6AutoLosesStatic,
          ),
        ImpactDetail(
          icon: Icons.bolt_rounded,
          text: l10n.sysInterfaceStagedConsequence,
        ),
      ],
      note: l10n.sysInterfaceStagedNote,
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await controller.updateInterface(next);
    if (!context.mounted) return;
    if (receipt == null) {
      _showAccountResult(
        context,
        ref,
        succeeded: false,
        action: l10n.sysStageInterfaceActionLabel(item.name),
        success: '',
      );
      return;
    }
    // The change is staged; take the user straight into commit/checkin so a
    // pending change is never left to expire silently.
    await _applyNetworkChanges(context, ref);
  }

  /// Edits the outgoing mail settings and offers a delivery test.
  ///
  /// The password is only sent when the user typed one: `mail.config` never
  /// returns it, so resending the whole object would overwrite the stored
  /// password with a blank. Validation cannot prove the settings work — a wrong
  /// password or a blocked port only surfaces on a real send — so a test message
  /// is offered right after saving.
  Future<void> _editMailSettings(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final baseline = await controller.loadMailConfiguration();
    if (!context.mounted) return;
    if (baseline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.sysGenericOperationFailed,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }

    final edit = await showModalBottomSheet<MailConfigurationEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => MailSheet(baseline: baseline),
    );
    if (edit == null || !context.mounted) return;
    if (edit.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sysMailNoChanges)));
      return;
    }

    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysMailApplyTitle,
      server: _serverName(ref, l10n),
      target: edit.fromEmail ?? baseline.fromEmail,
      actionLabel: l10n.sysMailApplyAction,
      // The shared sheet only models high and critical. Mail settings are the
      // lower of the two: wrong settings silence alerts, which is why this is
      // confirmed at all, but nothing is destroyed.
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.mark_email_unread_outlined,
          text: l10n.sysMailApplyConsequence,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;

    final receipt = await controller.updateMailConfiguration(
      edit,
      current: baseline,
    );
    if (!context.mounted) return;
    if (receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.sysGenericOperationFailed,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.sysMailUpdated),
        action: SnackBarAction(
          label: l10n.sysMailSendTest,
          onPressed: () => _sendTestMail(context, ref),
        ),
      ),
    );
  }

  /// Sends a test message. This is the only proof the settings work.
  Future<void> _sendTestMail(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final recipient = await controller.loadLocalAdministratorEmail();
    final receipt = await controller.sendTestMail(
      subject: l10n.sysMailTestSubject,
      body: l10n.sysMailTestBody,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed
              : recipient == null
              ? l10n.sysMailTestSentUnknown
              : l10n.sysMailTestSent(recipient),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  /// Scheduled commands, plus the alert-email settings that make notifications
  /// from those jobs (and from alerts generally) actually arrive.
  List<Widget> _cron(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canEditMail =
        capabilities?.supports('mail.config') == true &&
        capabilities?.supports('mail.update') == true;
    final canReadAlertServices =
        capabilities?.supports('alertservice.query') == true;
    return [
      const CronSection(),
      if (canReadAlertServices) ...[
        const SizedBox(height: 28),
        Text(
          l10n.sysAlertServicesTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const AlertServicesSection(),
      ],
      if (canEditMail) ...[
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(l10n.sysMailTitle),
                subtitle: Text(l10n.sysMailSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editMailSettings(context, ref),
              ),
              if (capabilities?.supports('mail.send') == true) ...[
                const Divider(indent: 68, height: 1),
                ListTile(
                  leading: const Icon(Icons.send_outlined),
                  title: Text(l10n.sysMailSendTest),
                  onTap: () => _sendTestMail(context, ref),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _updates(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
    AsyncValue<ResourceValue<SystemUpdateStatus>>? liveUpdateStatus,
  ) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final currentStatus = liveUpdateStatus?.value ?? data.updateStatus;
    final status = currentStatus.value;
    final capabilities = connection.capabilities;
    final canUpdate = capabilities?.supports('update.run') == true;
    final canChangeProfile =
        capabilities?.supports('update.profile_choices') == true &&
        capabilities?.supports('update.config') == true &&
        capabilities?.supports('update.update') == true;
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, size: 42),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.systemInfo?.version ??
                        l10n.sysUpdateFallbackName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status?.updateAvailable == true
                        ? l10n.sysUpdateAvailable('${status!.newVersion}')
                        : l10n.sysUpdateStatusHeading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (currentStatus.hasError)
        _MessageCard(
          icon: Icons.lock_outline_rounded,
          message: l10n.dataMessage(currentStatus.error!),
        )
      else if (status == null)
        _MessageCard(
          icon: Icons.info_outline_rounded,
          message: l10n.sysUpdateStatusUnavailable,
        )
      else
        SystemUpdateDetails(
          status: status,
          canUpdate: canUpdate,
          onInstall: () => _runUpdate(context, ref, status),
        ),
      const SizedBox(height: 16),
      SystemUpdateChannelCard(canChange: canChangeProfile),
    ];
  }

  List<Widget> _advanced(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
  ) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final actions = ref.watch(serverActionControllerProvider);
    return [
      _Heading(
        key: const ValueKey('advanced-boot-environments-section'),
        title: l10n.sysBootEnvironments,
        count: null,
      ),
      const SizedBox(height: 12),
      BootEnvironmentList(
        section: data.bootEnvironments,
        canActivate:
            capabilities?.supports('boot.environment.activate') == true,
        canKeep: capabilities?.supports('boot.environment.keep') == true,
        canDestroy: capabilities?.supports('boot.environment.destroy') == true,
        busyIds: {
          for (final environment in data.bootEnvironments.items)
            if (actions.isBusy('boot-env-activate:${environment.id}') ||
                actions.isBusy('boot-env-keep:${environment.id}') ||
                actions.isBusy('boot-env-destroy:${environment.id}'))
              environment.id,
        },
        onActivate: (environment) =>
            _activateBootEnvironment(context, ref, environment),
        onSetKept: (environment, keep) =>
            _setBootEnvironmentKept(context, ref, environment, keep),
        onDestroy: (environment) =>
            _destroyBootEnvironment(context, ref, environment),
      ),
      if (capabilities?.supports('core.download') == true) ...[
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            leading: const Icon(Icons.save_alt_rounded),
            title: Text(l10n.sysConfigBackupTitle),
            subtitle: Text(l10n.sysConfigBackupSubtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _downloadConfigBackup(context, ref, data),
          ),
        ),
      ],
      if (capabilities?.supports('config.reset') == true) ...[
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(
              Icons.restart_alt_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            title: Text(l10n.sysConfigResetTitle),
            subtitle: Text(l10n.sysConfigResetSubtitle),
            onTap: () => _resetConfiguration(context, ref),
          ),
        ),
      ],
    ];
  }

  /// Prepares a configuration backup and hands the download link to the user.
  ///
  /// `config.save` writes to a job pipe that a JSON-RPC client cannot read, so
  /// `core.download` wraps it and returns a tokenized HTTPS path. TrueDock opens
  /// that single-use URL in the platform browser through `url_launcher`; the
  /// browser owns the download destination, while link copy remains a fallback.
  Future<void> _downloadConfigBackup(
    BuildContext context,
    WidgetRef ref,
    SystemResources data,
  ) async {
    final l10n = AppLocalizations.of(context);
    final options = await showModalBottomSheet<ConfigBackupOptions>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ConfigBackupSheet(),
    );
    if (options == null || !context.mounted) return;

    final connection = ref.read(connectionControllerProvider);
    final hostname = connection.systemInfo?.hostname ?? 'truenas';
    final download = await ref
        .read(serverActionControllerProvider.notifier)
        .prepareConfigBackup(
          options: options,
          filename: options.suggestedFilename(hostname, DateTime.now()),
        );
    if (!context.mounted) return;
    if (download == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.sysGenericOperationFailed,
          ),
          showCloseIcon: true,
        ),
      );
      return;
    }

    final profile = connection.profile;
    if (profile == null) return;
    final url = download.resolve(profile.baseUri);
    final action = await showModalBottomSheet<ConfigBackupReadyAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ConfigBackupReadySheet(download: download, url: url),
    );
    if (action == null || !context.mounted) return;
    if (action == ConfigBackupReadyAction.download) {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.sysConfigBackupOpenFailed)));
      }
      return;
    }
    await Clipboard.setData(ClipboardData(text: url.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.sysConfigBackupLinkCopied)));
  }

  /// Resets the configuration to factory defaults.
  ///
  /// The most destructive non-storage action in the app: every share, user,
  /// task, and network setting reverts with no undo. It takes a typed
  /// confirmation, and the reboot choice is explicit because the server's own
  /// default is to restart immediately.
  Future<void> _resetConfiguration(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final serverName = _serverName(ref, l10n);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysConfigResetTitle,
      server: serverName,
      target: serverName,
      actionLabel: l10n.sysConfigResetAction,
      impact: MutationImpact.critical,
      confirmationText: serverName,
      consequences: [
        ImpactDetail(
          icon: Icons.settings_backup_restore_rounded,
          text: l10n.sysConfigResetConsequenceTotal,
        ),
        ImpactDetail(
          icon: Icons.block_rounded,
          text: l10n.sysConfigResetConsequenceIrreversible,
        ),
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: l10n.sysConfigResetConsequenceReboot,
        ),
      ],
    );
    if (!confirmed || !context.mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .resetConfiguration(reboot: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed
              : l10n.sysConfigResetRequested,
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  List<Widget> _activity(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ServerResources> resources,
  ) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final actions = ref.watch(serverActionControllerProvider);
    return resources.when(
      loading: () => const [Center(child: CircularProgressIndicator())],
      error: (_, _) => [
        _MessageCard(
          icon: Icons.error_outline_rounded,
          message: l10n.systemActivityLoadFailed,
        ),
      ],
      data: (data) => [
        _MetricStrip(
          metrics: [
            (
              l10n.sysMetricAlerts,
              '${data.alerts.items.where((alert) => !alert.dismissed).length}',
              Icons.notifications_outlined,
            ),
            (
              l10n.sysMetricActiveJobs,
              '${data.jobs.items.where((job) => job.isActive).length}',
              Icons.pending_actions_outlined,
            ),
            (
              l10n.sysMetricFailures,
              '${data.jobs.items.where((job) => job.error != null).length}',
              Icons.error_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 28),
        _Heading(title: l10n.sysAlerts, count: data.alerts.items.length),
        const SizedBox(height: 12),
        _AlertList(
          section: data.alerts,
          actions: actions,
          canDismiss: capabilities?.supports('alert.dismiss') == true,
          canRestore: capabilities?.supports('alert.restore') == true,
          onToggle: (alert) => _toggleAlert(context, ref, alert),
        ),
        const SizedBox(height: 28),
        _Heading(title: l10n.sysJobs, count: data.jobs.items.length),
        const SizedBox(height: 12),
        JobCenter(section: data.jobs),
        // The audit log is the record of every action the rest of the app can
        // take, so it belongs with alerts and jobs rather than in its own screen.
        if (capabilities?.supports('audit.query') == true) ...[
          const SizedBox(height: 28),
          _Heading(title: l10n.sysAuditTitle, count: null),
          const SizedBox(height: 12),
          const AuditSection(),
        ],
      ],
    );
  }

  Future<void> _toggleAlert(
    BuildContext context,
    WidgetRef ref,
    SystemAlert alert,
  ) async {
    final l10n = AppLocalizations.of(context);
    final dismiss = !alert.dismissed;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setAlertDismissed(alert.uuid, dismissed: dismiss);
    if (!context.mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? error ?? l10n.sysAlertFailed
              : dismiss
              ? l10n.sysAlertDismissed
              : l10n.sysAlertRestored,
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

class _SectionDefinition {
  const _SectionDefinition(this.path, this.title);

  factory _SectionDefinition.fromPath(String path, AppLocalizations l10n) =>
      switch (path) {
        'accounts' => _SectionDefinition('accounts', l10n.sysSectionAccounts),
        'general' => _SectionDefinition('general', l10n.systemGeneralSettings),
        'network' => _SectionDefinition('network', l10n.sysSectionNetwork),
        'cron' => _SectionDefinition('cron', l10n.sysSectionCron),
        'updates' => _SectionDefinition('updates', l10n.sysSectionUpdates),
        'advanced' => _SectionDefinition('advanced', l10n.systemAdvanced),
        _ => _SectionDefinition('activity', l10n.sysSectionActivity),
      };

  final String path;
  final String title;
}

class _GeneralSettingsSection extends ConsumerStatefulWidget {
  const _GeneralSettingsSection({
    required this.onReboot,
    required this.onShutdown,
    super.key,
  });

  final VoidCallback onReboot;
  final VoidCallback onShutdown;

  @override
  ConsumerState<_GeneralSettingsSection> createState() =>
      _GeneralSettingsSectionState();
}

class _GeneralSettingsSectionState
    extends ConsumerState<_GeneralSettingsSection> {
  SystemGeneralConfiguration? _baseline;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final raw = await ref
        .read(serverActionControllerProvider.notifier)
        .getSystemGeneralConfig();
    if (!mounted) return;
    setState(() {
      _baseline = raw == null
          ? null
          : SystemGeneralConfiguration.fromConfig(raw);
      _error = raw == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final baseline = _baseline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null || baseline == null)
          _MessageCard(
            icon: Icons.error_outline_rounded,
            message: _error ?? l10n.systemSettingsLoadFailed,
          )
        else
          SystemGeneralSheet(
            key: ValueKey(baseline.hashCode),
            baseline: baseline,
            embedded: true,
            onSubmitted: _save,
          ),
        const SizedBox(height: 28),
        _Heading(
          key: const ValueKey('general-power-section'),
          title: l10n.sysPower,
          count: null,
        ),
        const SizedBox(height: 12),
        _PowerControls(
          canReboot: capabilities?.supports('system.reboot') == true,
          canShutdown: capabilities?.supports('system.shutdown') == true,
          onReboot: widget.onReboot,
          onShutdown: widget.onShutdown,
        ),
      ],
    );
  }

  Future<void> _save(SystemGeneralConfiguration next) async {
    final baseline = _baseline;
    if (baseline == null) return;
    final l10n = AppLocalizations.of(context);
    final diff = next.changedFields(baseline);
    if (diff.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.systemNoChanges)));
      return;
    }
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.systemSaveSettingsTitle,
      server: serverName,
      target: l10n.systemGeneralSettingsTarget,
      actionLabel: l10n.actionSaveChanges,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.dns_outlined,
          text: diff.containsKey('hostname')
              ? l10n.systemHostnameChangeImpact
              : l10n.systemSettingsChangeImpact,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateSystemGeneralConfig(next: next, baseline: baseline);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.systemSettingsSaveFailed
              : l10n.systemSettingsSaved,
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null) {
      setState(() => _baseline = next);
    }
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.metrics});

  final List<(String, String, IconData)> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final metric in metrics)
            Expanded(
              child: Column(
                children: [
                  Icon(metric.$3, color: colors.primary),
                  const SizedBox(height: 7),
                  Text(
                    metric.$2,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    metric.$1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.count, super.key});

  final String title;

  /// Null for sections that are actions rather than collections.
  final int? count;

  @override
  Widget build(BuildContext context) => Text(
    count == null ? title : '$title  $count',
    style: Theme.of(context).textTheme.titleLarge,
  );
}

/// Per-row actions for a static route entry.
enum _RouteAction { edit, delete }

/// A section heading with a trailing create action.
class _ActionHeading extends StatelessWidget {
  const _ActionHeading({
    required this.title,
    required this.count,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final int count;
  final String actionLabel;

  /// Null when the connected account cannot perform the action.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$title  $count',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      FilledButton.tonalIcon(
        onPressed: onAction,
        icon: const Icon(Icons.add_rounded),
        label: Text(actionLabel),
      ),
    ],
  );
}

class _UserList extends StatelessWidget {
  const _UserList({
    required this.users,
    required this.canEdit,
    required this.onEdit,
    required this.canDelete,
    required this.onDelete,
    required this.canChangePassword,
    required this.onChangePassword,
  });

  final List<NasUser> users;
  final bool canEdit;
  final ValueChanged<NasUser> onEdit;
  final bool canDelete;
  final ValueChanged<NasUser> onDelete;
  final bool canChangePassword;
  final ValueChanged<NasUser> onChangePassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          for (final (index, user) in users.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: CircleAvatar(
                child: Icon(
                  user.isAdministrator
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
                ),
              ),
              title: Text(user.username),
              subtitle: Text(
                [
                  if (user.fullName.isNotEmpty) user.fullName,
                  user.local ? l10n.sysUserLocal : l10n.sysUserDirectory,
                  if (user.smb) l10n.sysUserSmb,
                  if (user.passwordDisabled) l10n.sysUserPasswordDisabled,
                  if (user.locked) l10n.sysUserLocked,
                ].join(' · '),
              ),
              trailing: !user.isEditable
                  ? Tooltip(
                      message: user.builtin
                          ? l10n.sysBuiltInAccount
                          : l10n.sysDirectoryAccount,
                      child: const Icon(Icons.lock_outline_rounded, size: 19),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canChangePassword && !user.passwordDisabled)
                          IconButton(
                            onPressed: () => onChangePassword(user),
                            tooltip: l10n.sysChangePasswordAction,
                            icon: const Icon(Icons.password_outlined),
                          ),
                        if (canEdit)
                          IconButton(
                            onPressed: () => onEdit(user),
                            tooltip: l10n.sysEditUser,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        if (canDelete)
                          IconButton(
                            onPressed: () => onDelete(user),
                            tooltip: l10n.sysDeleteUser,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
              onTap: user.isEditable && canEdit ? () => onEdit(user) : null,
            ),
            if (index < users.length - 1) const Divider(indent: 74, height: 1),
          ],
        ],
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groups,
    required this.canEdit,
    required this.onEdit,
    required this.canDelete,
    required this.onDelete,
  });

  final List<NasGroup> groups;
  final bool canEdit;
  final ValueChanged<NasGroup> onEdit;
  final bool canDelete;
  final ValueChanged<NasGroup> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          for (final (index, group) in groups.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const Icon(Icons.groups_outlined),
              title: Text(group.name),
              subtitle: Text(
                group.roles.isEmpty
                    ? l10n.sysGroupSubtitle(
                        '${group.gid}',
                        group.userIds.length,
                      )
                    : l10n.sysGroupSubtitleWithRoles(
                        '${group.gid}',
                        group.userIds.length,
                        group.roles.join(', '),
                      ),
              ),
              trailing: !group.isEditable
                  ? Tooltip(
                      message: group.builtin
                          ? l10n.sysBuiltInGroup
                          : l10n.sysDirectoryGroup,
                      child: const Icon(Icons.lock_outline_rounded, size: 19),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canEdit)
                          IconButton(
                            onPressed: () => onEdit(group),
                            tooltip: l10n.sysEditGroup,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        if (canDelete)
                          IconButton(
                            onPressed: () => onDelete(group),
                            tooltip: l10n.sysDeleteGroup,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
              onTap: group.isEditable && canEdit ? () => onEdit(group) : null,
            ),
            if (index < groups.length - 1) const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

class _InterfaceCard extends StatelessWidget {
  const _InterfaceCard(this.item, {this.onEdit});

  final NetworkInterface item;

  /// Null when the connected account cannot run `interface.update`.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      item.isUp ? Icons.lan_rounded : Icons.link_off_rounded,
                      color: item.isUp ? colors.primary : colors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(item.type.replaceAll('_', ' ')),
                    if (onEdit != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  [
                    item.isUp ? l10n.sysInterfaceLinkUp : item.linkState,
                    if (item.activeMediaSubtype != null)
                      item.activeMediaSubtype!,
                    if (item.mtu != null) l10n.sysInterfaceMtu('${item.mtu}'),
                    if (item.dhcp) l10n.sysInterfaceDhcp,
                    if (item.ipv6Auto) l10n.sysInterfaceIpv6AutoShort,
                  ].join(' · '),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                if (item.addresses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final address in item.addresses)
                        Chip(
                          avatar: Icon(
                            address.type == 'INET6'
                                ? Icons.looks_6_outlined
                                : Icons.looks_4_outlined,
                            size: 17,
                          ),
                          label: Text(address.label),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SystemUpdateDetails extends ConsumerStatefulWidget {
  const SystemUpdateDetails({
    required this.status,
    required this.canUpdate,
    required this.onInstall,
    super.key,
  });

  final SystemUpdateStatus status;
  final bool canUpdate;
  final Future<OperationReceipt?> Function() onInstall;

  @override
  ConsumerState<SystemUpdateDetails> createState() =>
      _SystemUpdateDetailsState();
}

class _SystemUpdateDetailsState extends ConsumerState<SystemUpdateDetails> {
  Timer? _pollTimer;
  int? _jobId;
  SystemJob? _job;
  SystemUpdateStatus? _liveStatus;
  var _starting = false;

  bool get _inProgress =>
      _starting || _job?.isActive == true || (_jobId != null && _job == null);

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_inProgress) return;
    setState(() => _starting = true);
    final receipt = await widget.onInstall();
    if (!mounted) return;
    final jobId = receipt?.jobId;
    setState(() {
      _jobId = jobId;
      _starting = jobId != null;
    });
    if (jobId == null) return;
    await _poll();
    if (!mounted || _jobId == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    final jobId = _jobId;
    if (jobId == null || !mounted) return;
    ref.invalidate(serverResourcesProvider);
    ref.invalidate(systemResourcesProvider);
    try {
      final results = await Future.wait<Object>([
        ref.read(serverResourcesProvider.future),
        ref.read(systemResourcesProvider.future),
      ]);
      if (!mounted || jobId != _jobId) return;
      final server = results[0] as ServerResources;
      final system = results[1] as SystemResources;
      SystemJob? job;
      for (final candidate in server.jobs.items) {
        if (candidate.id == jobId) {
          job = candidate;
          break;
        }
      }
      setState(() {
        _job = job;
        _liveStatus = system.updateStatus.value;
        _starting = job == null;
      });
      if (job != null && !job.isActive) {
        _pollTimer?.cancel();
        setState(() {
          _jobId = null;
          _starting = false;
        });
      }
    } catch (_) {
      // The update-triggered reboot can disconnect before a terminal job
      // event. Keep the accepted action disabled until this screen is rebuilt
      // after reconnection.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _liveStatus ?? widget.status;
    final percent = _job?.percent ?? status.downloadPercent;
    final description = _job?.description ?? status.downloadDescription;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(
              label: l10n.sysUpdateTrain,
              value: status.train ?? l10n.sysUnknown,
            ),
            _DetailRow(
              label: l10n.sysUpdateProfile,
              value: status.profile ?? l10n.sysUnknown,
            ),
            _DetailRow(
              label: l10n.sysUpdateAvailableVersion,
              value: status.newVersion ?? l10n.sysUpToDate,
            ),
            if (status.error != null)
              _DetailRow(label: l10n.sysUpdateError, value: status.error!),
            if (_inProgress) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                key: const ValueKey('system-update-progress'),
                value: percent == null ? null : (percent / 100).clamp(0, 1),
              ),
              const SizedBox(height: 8),
              Text(
                description ??
                    (percent == null
                        ? l10n.sysUpdatePreparing
                        : l10n.sysUpdateProgress(percent.toInt())),
              ),
            ] else if (status.downloadPercent case final progress?) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (progress / 100).clamp(0, 1)),
              const SizedBox(height: 8),
              Text(
                progress >= 100
                    ? l10n.sysManualUpdateRestartSoon
                    : status.downloadDescription ?? '${progress.toInt()}%',
              ),
            ],
            if (status.updateAvailable || _inProgress) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.canUpdate && !_inProgress ? _start : null,
                icon: _inProgress
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _inProgress
                      ? l10n.sysUpdateInProgress
                      : widget.canUpdate
                      ? l10n.sysInstallVersion('${status.newVersion}')
                      : l10n.sysUpdatesNotPermitted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SystemUpdateChannelCard extends ConsumerStatefulWidget {
  const SystemUpdateChannelCard({required this.canChange, super.key});

  final bool canChange;

  @override
  ConsumerState<SystemUpdateChannelCard> createState() =>
      _SystemUpdateChannelCardState();
}

class _SystemUpdateChannelCardState
    extends ConsumerState<SystemUpdateChannelCard> {
  String? _selectedId;

  Future<void> _apply(String currentId) async {
    final selected = _selectedId;
    if (selected == null || selected == currentId) return;
    await ref
        .read(serverActionControllerProvider.notifier)
        .changeSystemUpdateProfile(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profiles = ref.watch(systemUpdateProfilesProvider);
    final action = ref.watch(serverActionControllerProvider);
    final busy = action.isBusy('system-update-profile');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: profiles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(
            l10n.sysUpdateProfilesLoadFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          data: (data) {
            final currentId = data.currentId;
            final selectedId = _selectedId ?? currentId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.sysUpdateChannelTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sysUpdateChannelDescription,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TrueDockDropdownButtonFormField<String>(
                  key: ValueKey(currentId),
                  initialValue: selectedId,
                  decoration: InputDecoration(
                    labelText: l10n.sysUpdateChannelTitle,
                    prefixIcon: const Icon(Icons.route_rounded),
                  ),
                  items: [
                    for (final profile in data.items)
                      DropdownMenuItem(
                        value: profile.id,
                        child: Text(switch (profile.channel) {
                          SystemUpdateChannel.general =>
                            l10n.sysUpdateChannelGeneral,
                          SystemUpdateChannel.earlyAdopter =>
                            l10n.sysUpdateChannelEarlyAdopter,
                          SystemUpdateChannel.developer =>
                            l10n.sysUpdateChannelDeveloper,
                        }),
                      ),
                  ],
                  onChanged: widget.canChange && !busy
                      ? (value) => setState(() => _selectedId = value)
                      : null,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed:
                      widget.canChange &&
                          !busy &&
                          selectedId != null &&
                          selectedId != currentId
                      ? () => _apply(currentId ?? '')
                      : null,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(l10n.actionApply),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PowerControls extends StatelessWidget {
  const _PowerControls({
    required this.canReboot,
    required this.canShutdown,
    required this.onReboot,
    required this.onShutdown,
  });

  final bool canReboot;
  final bool canShutdown;
  final VoidCallback onReboot;
  final VoidCallback onShutdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!canReboot && !canShutdown) {
      return _MessageCard(
        icon: Icons.lock_outline_rounded,
        message: l10n.sysPowerNotPermitted,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sysPowerWarning,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            if (canReboot)
              OutlinedButton.icon(
                onPressed: onReboot,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.sysRestartServer),
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              ),
            if (canReboot && canShutdown) const SizedBox(height: 10),
            if (canShutdown)
              OutlinedButton.icon(
                onPressed: onShutdown,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: Text(l10n.sysShutdownServer),
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
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

class _AlertList extends StatelessWidget {
  const _AlertList({
    required this.section,
    required this.actions,
    required this.canDismiss,
    required this.canRestore,
    required this.onToggle,
  });

  final ResourceSection<SystemAlert> section;
  final ServerActionState actions;
  final bool canDismiss;
  final bool canRestore;
  final ValueChanged<SystemAlert> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _MessageCard(
        icon: Icons.lock_outline_rounded,
        message: l10n.dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _MessageCard(
        icon: Icons.notifications_none_rounded,
        message: l10n.sysNoAlerts,
      );
    }
    return Card(
      child: Column(
        children: [
          for (final (index, alert) in section.items.indexed) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: Icon(
                alert.isCritical
                    ? Icons.error_outline_rounded
                    : alert.isWarning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
              ),
              title: Text(alert.text),
              subtitle: Text(
                alert.dismissed
                    ? l10n.sysAlertSubtitleDismissed(alert.level)
                    : alert.level,
              ),
              trailing: actions.isBusy('alert:${alert.uuid}')
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : IconButton.filledTonal(
                      onPressed: (alert.dismissed ? canRestore : canDismiss)
                          ? () => onToggle(alert)
                          : null,
                      icon: Icon(
                        alert.dismissed
                            ? Icons.restore_rounded
                            : Icons.notifications_off_outlined,
                      ),
                      tooltip: alert.dismissed
                          ? l10n.sysRestoreAlert
                          : l10n.sysDismissAlert,
                    ),
            ),
            if (index < section.items.length - 1)
              const Divider(indent: 68, height: 1),
          ],
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
