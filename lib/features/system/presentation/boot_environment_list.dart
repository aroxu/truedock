import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart'
    show ResourceSection, formatBytes;
import '../domain/system_resources.dart';
import '../../../core/l10n/data_message_localizations.dart';

/// The boot environments available to start, shown beside the update controls.
///
/// This is the only real way back after a bad update, so the list makes the
/// distinction between the running environment and the one selected for the next
/// boot explicit: a pending activation means the server is not currently running
/// what it will run after a reboot.
class BootEnvironmentList extends StatelessWidget {
  const BootEnvironmentList({
    required this.section,
    required this.canActivate,
    required this.canKeep,
    required this.canDestroy,
    required this.busyIds,
    required this.onActivate,
    required this.onSetKept,
    required this.onDestroy,
    super.key,
  });

  final ResourceSection<BootEnvironment> section;
  final bool canActivate;
  final bool canKeep;
  final bool canDestroy;

  /// Environment ids with a mutation in flight.
  final Set<String> busyIds;
  final ValueChanged<BootEnvironment> onActivate;
  final void Function(BootEnvironment environment, bool keep) onSetKept;
  final ValueChanged<BootEnvironment> onDestroy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.dataMessage(section.error!))),
            ],
          ),
        ),
      );
    }
    if (section.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.sysBootNone)),
            ],
          ),
        ),
      );
    }

    final pending = section.items.where((e) => e.activationPending).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: colors.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.restart_alt_rounded,
                      color: colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.sysBootPendingNotice(pending.first.id),
                        style: TextStyle(color: colors.onTertiaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, environment) in section.items.indexed) ...[
                if (index > 0) const Divider(height: 1, indent: 68),
                _BootEnvironmentTile(
                  environment: environment,
                  busy: busyIds.contains(environment.id),
                  canActivate: canActivate,
                  canKeep: canKeep,
                  canDestroy: canDestroy,
                  onActivate: () => onActivate(environment),
                  onSetKept: (keep) => onSetKept(environment, keep),
                  onDestroy: () => onDestroy(environment),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BootEnvironmentTile extends StatelessWidget {
  const _BootEnvironmentTile({
    required this.environment,
    required this.busy,
    required this.canActivate,
    required this.canKeep,
    required this.canDestroy,
    required this.onActivate,
    required this.onSetKept,
    required this.onDestroy,
  });

  final BootEnvironment environment;
  final bool busy;
  final bool canActivate;
  final bool canKeep;
  final bool canDestroy;
  final VoidCallback onActivate;
  final ValueChanged<bool> onSetKept;
  final VoidCallback onDestroy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    // The running environment and the next-boot environment are different
    // facts. Collapsing them would hide a pending activation entirely.
    final status = <String>[
      if (environment.active) l10n.sysBootStatusRunning,
      if (environment.activationPending) l10n.sysBootStatusNext,
      if (environment.supersededByPendingActivation) l10n.sysBootStatusReplaced,
      if (environment.keep) l10n.sysBootStatusKept,
    ];
    final created = environment.created;
    final details = <String>[
      if (environment.sizeBytes != null) formatBytes(environment.sizeBytes),
      if (created != null)
        '${created.year}-${created.month.toString().padLeft(2, '0')}-'
            '${created.day.toString().padLeft(2, '0')}',
    ];

    // Destroying the running or next-boot environment would break the server's
    // ability to boot, so it is never offered for those.
    final destroyable =
        canDestroy && !environment.active && !environment.activated;
    final activatable = canActivate && !environment.activated;
    final hasMenu = destroyable || canKeep;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 18, right: 8),
      leading: Icon(
        environment.active
            ? Icons.play_circle_outline_rounded
            : environment.activationPending
            ? Icons.restart_alt_rounded
            : Icons.history_rounded,
        color: environment.active
            ? colors.primary
            : environment.activationPending
            ? colors.tertiary
            : null,
      ),
      title: Text(environment.id),
      subtitle: Text(
        [
          if (status.isNotEmpty) status.join(' · '),
          if (details.isNotEmpty) details.join(' · '),
        ].join(' · '),
      ),
      trailing: busy
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activatable)
                  TextButton(
                    onPressed: onActivate,
                    child: Text(l10n.sysBootActivateAction),
                  ),
                if (hasMenu)
                  PopupMenuButton<String>(
                    tooltip: l10n.sysBootOptionsTooltip,
                    onSelected: (value) {
                      if (value == 'destroy') onDestroy();
                      if (value == 'keep') onSetKept(!environment.keep);
                    },
                    itemBuilder: (context) => [
                      if (canKeep)
                        PopupMenuItem(
                          value: 'keep',
                          child: ListTile(
                            leading: Icon(
                              environment.keep
                                  ? Icons.bookmark_remove_outlined
                                  : Icons.bookmark_add_outlined,
                            ),
                            title: Text(
                              environment.keep
                                  ? l10n.sysBootAllowRemoval
                                  : l10n.sysBootKeep,
                            ),
                          ),
                        ),
                      if (destroyable)
                        PopupMenuItem(
                          value: 'destroy',
                          child: ListTile(
                            leading: const Icon(Icons.delete_outline_rounded),
                            title: Text(l10n.sysBootDelete),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
