import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';

/// Localized label for a lifecycle verb.
///
/// The verb enum lives in the data layer and carries an English label for
/// logging and API mapping; user-facing text is resolved here so both the VM
/// and container surfaces show the same translated wording.
String localizedVerbLabel(AppLocalizations l10n, InstanceVerb verb) =>
    switch (verb) {
      InstanceVerb.start => l10n.appsVerbStart,
      InstanceVerb.stop => l10n.appsVerbStop,
      InstanceVerb.restart => l10n.appsVerbRestart,
      InstanceVerb.powerOff => l10n.appsVerbPowerOff,
    };

/// Lifecycle buttons shared by virtual machines and standalone containers.
///
/// Every disruptive verb goes through a confirmation dialog that names the
/// instance and the consequence, and each verb is hidden unless the connected
/// server actually exposes the backing method.
class InstanceLifecycleControls extends ConsumerWidget {
  const InstanceLifecycleControls({
    required this.name,
    required this.kind,
    required this.running,
    required this.busyKey,
    required this.supportedVerbs,
    required this.onInvoke,
    super.key,
  });

  final String name;

  /// User-facing noun, such as "virtual machine" or "container".
  final String kind;
  final bool running;
  final String busyKey;
  final Set<InstanceVerb> supportedVerbs;
  final Future<void> Function(InstanceVerb verb) onInvoke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(serverActionControllerProvider).isBusy(busyKey);
    final verbs = [
      if (!running) InstanceVerb.start,
      if (running) InstanceVerb.stop,
      if (running) InstanceVerb.restart,
      if (running) InstanceVerb.powerOff,
    ].where(supportedVerbs.contains).toList(growable: false);

    if (verbs.isEmpty) {
      return Text(
        l10n.appsNoLifecycleControl(kind),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final verb in verbs)
              if (verb == InstanceVerb.powerOff)
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _invoke(context, verb),
                  icon: const Icon(Icons.power_off_rounded),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(localizedVerbLabel(l10n, verb)),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: busy ? null : () => _invoke(context, verb),
                  icon: Icon(switch (verb) {
                    InstanceVerb.start => Icons.play_arrow_rounded,
                    InstanceVerb.stop => Icons.stop_rounded,
                    InstanceVerb.restart => Icons.restart_alt_rounded,
                    InstanceVerb.powerOff => Icons.power_off_rounded,
                  }),
                  label: Text(localizedVerbLabel(l10n, verb)),
                ),
          ],
        ),
      ],
    );
  }

  Future<void> _invoke(BuildContext context, InstanceVerb verb) async {
    final l10n = AppLocalizations.of(context);
    if (verb.isDisruptive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: Text(
            l10n.appsVerbConfirmTitle(localizedVerbLabel(l10n, verb), name),
          ),
          content: Text(_consequence(l10n, verb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(localizedVerbLabel(l10n, verb)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await onInvoke(verb);
  }

  String _consequence(AppLocalizations l10n, InstanceVerb verb) =>
      switch (verb) {
        InstanceVerb.stop => l10n.appsStopConsequence(kind),
        InstanceVerb.restart => l10n.appsRestartConsequence(kind),
        InstanceVerb.powerOff => l10n.appsPowerOffConsequence(kind),
        InstanceVerb.start => '',
      };
}
