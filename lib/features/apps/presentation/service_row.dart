import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';

/// One row in the Services list.
///
/// Run state and start-on-boot are deliberately separate controls because they
/// are separate TrueNAS mutations: `service.control` changes the service now and
/// is forgotten on reboot, while `service.update` persists the boot setting. The
/// run state is the common action and keeps the switch; the boot setting is a
/// configuration change and lives in the overflow menu.
class ServiceRow extends StatelessWidget {
  const ServiceRow({
    required this.service,
    required this.busy,
    required this.onToggle,
    required this.canEditStartOnBoot,
    required this.bootBusy,
    required this.onToggleStartOnBoot,
    this.onConfigure,
    super.key,
  });

  final SystemService service;
  final bool busy;
  final ValueChanged<bool> onToggle;

  /// False when the server does not expose `service.update`. The boot state is
  /// still shown, because it is useful information, but it cannot be changed.
  final bool canEditStartOnBoot;
  final bool bootBusy;
  final ValueChanged<bool> onToggleStartOnBoot;

  /// Opens the service's configuration editor. Null when the server does not
  /// expose a `<service>.config`/`update` pair for it, which is most services.
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final running = service.state == 'RUNNING';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      leading: Icon(
        running
            ? Icons.check_circle_outline_rounded
            : Icons.pause_circle_outline_rounded,
        color: running ? const Color(0xFF2E9D64) : null,
      ),
      title: Text(service.name.toUpperCase()),
      subtitle: Text(
        service.enabled
            ? l10n.appsServiceStartsAutomatically
            : l10n.appsServiceManualStart,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Switch(value: running, onChanged: onToggle),
          if (canEditStartOnBoot && bootBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (canEditStartOnBoot || onConfigure != null)
            PopupMenuButton<_ServiceRowAction>(
              tooltip: l10n.appsServiceOptions,
              onSelected: (action) => switch (action) {
                _ServiceRowAction.toggleBoot => onToggleStartOnBoot(
                  !service.enabled,
                ),
                _ServiceRowAction.configure => onConfigure?.call(),
              },
              itemBuilder: (context) => [
                if (canEditStartOnBoot)
                  PopupMenuItem(
                    value: _ServiceRowAction.toggleBoot,
                    child: ListTile(
                      leading: Icon(
                        service.enabled
                            ? Icons.play_disabled_rounded
                            : Icons.play_circle_outline_rounded,
                      ),
                      title: Text(
                        service.enabled
                            ? l10n.appsDoNotStartOnBoot
                            : l10n.appsStartOnBoot,
                      ),
                    ),
                  ),
                if (onConfigure != null)
                  PopupMenuItem(
                    value: _ServiceRowAction.configure,
                    child: ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: Text(l10n.sysServiceConfigTitle),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _ServiceRowAction { toggleBoot, configure }
