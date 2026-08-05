import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/security/security_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/saved_server_repository.dart';
import 'connection_controller.dart';

class ServerManagementScreen extends ConsumerWidget {
  const ServerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final servers = ref.watch(savedServersProvider);

    return Scaffold(
      body: SafeRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedServersProvider);
          await ref.read(savedServersProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: Text(l10n.serverManagementTitle),
              actions: [
                IconButton(
                  onPressed: connection.stage == ConnectionStage.connecting
                      ? null
                      : () => context.push('/servers/new'),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: l10n.actionAddServer,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: servers.when(
                data: (items) => SliverList.list(
                  children: [
                    Text(
                      l10n.serverManagementDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            if (index > 0) const Divider(height: 1, indent: 68),
                            _ServerTile(
                              server: items[index],
                              active:
                                  connection.isConnected &&
                                  connection.profile?.id ==
                                      items[index].profile.id,
                              busy:
                                  connection.stage ==
                                  ConnectionStage.connecting,
                              onSelect: () => _selectServer(
                                context,
                                items[index],
                                connection,
                              ),
                              onForget: () => _forgetServer(
                                context,
                                ref,
                                items[index],
                                connection,
                              ),
                              onRename: () =>
                                  _renameServer(context, ref, items[index]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: connection.stage == ConnectionStage.connecting
                          ? null
                          : () => context.push('/servers/new'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.actionAddServer),
                    ),
                  ],
                ),
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(l10n.serverManagementLoadFailed)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectServer(
    BuildContext context,
    SavedServer server,
    NasConnectionState connection,
  ) async {
    if (connection.isConnected && connection.profile?.id == server.profile.id) {
      return;
    }
    if (connection.isConnected) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.swap_horiz_rounded),
          title: Text(AppLocalizations.of(context).serverSwitchTitle),
          content: Text(
            AppLocalizations.of(
              context,
            ).serverSwitchDescription(server.profile.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).serverSwitchAction),
            ),
          ],
        ),
      );
      if (approved != true || !context.mounted) return;
    }
    await context.push('/servers/auth/${server.profile.id}');
  }

  Future<void> _forgetServer(
    BuildContext context,
    WidgetRef ref,
    SavedServer server,
    NasConnectionState connection,
  ) async {
    final active = connection.profile?.id == server.profile.id;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: Text(AppLocalizations.of(context).serverForgetTitle),
        content: Text(
          active
              ? AppLocalizations.of(
                  context,
                ).serverForgetActiveDescription(server.profile.name)
              : AppLocalizations.of(
                  context,
                ).serverForgetDescription(server.profile.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).savedServerForget),
          ),
        ],
      ),
    );
    if (approved != true) return;
    final controller = ref.read(connectionControllerProvider.notifier);
    if (active) await controller.disconnect();
    await controller.forgetSavedServer(server.profile);
  }

  Future<void> _renameServer(
    BuildContext context,
    WidgetRef ref,
    SavedServer server,
  ) async {
    var editedName = server.profile.name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_outlined),
        title: Text(AppLocalizations.of(context).serverRenameTitle),
        content: TextFormField(
          initialValue: server.profile.name,
          keyboardType: TextInputType.text,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (value) => editedName = value,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).serverRenameLabel,
          ),
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).actionCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = editedName.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(AppLocalizations.of(context).serverRenameAction),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    await ref
        .read(connectionControllerProvider.notifier)
        .renameSavedServer(server.profile, name);
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.active,
    required this.busy,
    required this.onSelect,
    required this.onForget,
    required this.onRename,
  });

  final SavedServer server;
  final bool active;
  final bool busy;
  final VoidCallback onSelect;
  final VoidCallback onForget;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      enabled: !busy,
      contentPadding: const EdgeInsets.only(left: 18, right: 8),
      leading: Icon(
        active
            ? Icons.check_circle_rounded
            : server.hasSavedCredential
            ? server.credentialProtection == CredentialProtection.biometric ||
                      server.credentialProtection ==
                          CredentialProtection.appPasswordWithBiometric
                  ? Icons.fingerprint_rounded
                  : Icons.password_rounded
            : Icons.login_rounded,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(server.profile.name),
      subtitle: Text(
        active
            ? '${l10n.serverActive} · ${server.profile.baseUri.authority}'
            : server.hasSavedCredential
            ? '${server.username} · ${server.profile.baseUri.authority}'
            : '${l10n.savedServerSignInRequired} · '
                  '${server.profile.baseUri.authority}',
      ),
      onTap: active ? null : onSelect,
      trailing: PopupMenuButton<String>(
        enabled: !busy,
        tooltip: l10n.savedServerOptions,
        onSelected: (value) {
          if (value == 'rename') onRename();
          if (value == 'forget') onForget();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.serverRenameAction),
            ),
          ),
          PopupMenuItem(
            value: 'forget',
            child: ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.savedServerForget),
            ),
          ),
        ],
      ),
    );
  }
}
