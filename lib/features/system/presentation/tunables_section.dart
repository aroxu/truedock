import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../domain/tunable_configuration.dart';
import 'tunable_sheet.dart';

class TunablesSection extends ConsumerStatefulWidget {
  const TunablesSection({super.key});

  @override
  ConsumerState<TunablesSection> createState() => _TunablesSectionState();
}

class _TunablesSectionState extends ConsumerState<TunablesSection> {
  List<Tunable>? _tunables;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    // The action controller publishes busy/error state. Calling it directly
    // from initState mutates a watched provider while the route is still
    // building, which Riverpod correctly rejects.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tunables = await ref
        .read(serverActionControllerProvider.notifier)
        .loadTunables();
    if (!mounted) return;
    setState(() {
      _tunables = tunables;
      _error = tunables == null
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
    final canCreate = capabilities?.supports('tunable.create') == true;
    final canUpdate = capabilities?.supports('tunable.update') == true;
    final canDelete = capabilities?.supports('tunable.delete') == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sysTunableSubtitle, style: theme.textTheme.bodyMedium),
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
        else if (_tunables == null || _tunables!.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.sysTunableEmpty),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, tunable) in _tunables!.indexed) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Text(_typeCode(tunable.configuration.type)),
                    ),
                    title: Text(tunable.configuration.variable),
                    subtitle: Text(
                      '${tunable.configuration.value}'
                      '${tunable.configuration.enabled ? '' : ' · ${l10n.sysTunableDisabled}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: canUpdate || canDelete
                        ? PopupMenuButton<_TunableAction>(
                            itemBuilder: (_) => [
                              if (canUpdate)
                                PopupMenuItem(
                                  value: _TunableAction.edit,
                                  child: Text(l10n.sysEdit),
                                ),
                              if (canDelete)
                                PopupMenuItem(
                                  value: _TunableAction.delete,
                                  child: Text(l10n.sysDelete),
                                ),
                            ],
                            onSelected: (action) => switch (action) {
                              _TunableAction.edit => _edit(tunable),
                              _TunableAction.delete => _delete(tunable),
                            },
                          )
                        : null,
                    onTap: canUpdate ? () => _edit(tunable) : null,
                  ),
                  if (index < _tunables!.length - 1)
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
            label: Text(l10n.sysTunableCreate),
          ),
        ],
      ],
    );
  }

  String get _serverName =>
      ref.read(connectionControllerProvider).profile?.name ??
      AppLocalizations.of(context).systemServerFallback;

  String _typeCode(TunableType type) => switch (type) {
    TunableType.sysctl => 'S',
    TunableType.udev => 'U',
    TunableType.zfs => 'Z',
  };

  Future<void> _create() async {
    final next = await _showSheet(
      const TunableConfiguration(variable: '', value: ''),
    );
    if (next == null || !mounted) return;
    if (!await _confirm(next, editing: false) || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .createTunable(next);
    if (!mounted) return;
    _report(receipt, AppLocalizations.of(context).sysTunableCreated);
    if (receipt != null) await _load();
  }

  Future<void> _edit(Tunable tunable) async {
    final next = await _showSheet(tunable.configuration, editing: true);
    if (next == null || !mounted) return;
    if (!await _confirm(next, editing: true) || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateTunable(tunable.id, next);
    if (!mounted) return;
    _report(receipt, AppLocalizations.of(context).sysTunableUpdated);
    if (receipt != null) await _load();
  }

  Future<TunableConfiguration?> _showSheet(
    TunableConfiguration baseline, {
    bool editing = false,
  }) => showModalBottomSheet<TunableConfiguration>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TunableSheet(baseline: baseline, editing: editing),
  );

  Future<bool> _confirm(
    TunableConfiguration configuration, {
    required bool editing,
  }) {
    final l10n = AppLocalizations.of(context);
    return confirmDestructiveAction(
      context,
      title: editing
          ? l10n.sysTunableUpdateConfirmTitle
          : l10n.sysTunableCreateConfirmTitle,
      server: _serverName,
      target: configuration.variable,
      actionLabel: editing
          ? l10n.sysTunableUpdateAction
          : l10n.sysTunableCreateAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.memory_rounded,
          text: _typeImpact(l10n, configuration.type),
        ),
        ImpactDetail(
          icon: Icons.warning_amber_rounded,
          text: l10n.sysTunableRiskConsequence,
        ),
      ],
    );
  }

  String _typeImpact(AppLocalizations l10n, TunableType type) => switch (type) {
    TunableType.sysctl => l10n.sysTunableSysctlConsequence,
    TunableType.udev => l10n.sysTunableUdevConsequence,
    TunableType.zfs => l10n.sysTunableZfsConsequence,
  };

  Future<void> _delete(Tunable tunable) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysTunableDeleteTitle,
      server: _serverName,
      target: tunable.configuration.variable,
      actionLabel: l10n.sysTunableDeleteAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.restart_alt_rounded,
          text: l10n.sysTunableDeleteConsequence,
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteTunable(tunable.id);
    if (!mounted) return;
    _report(receipt, l10n.sysTunableDeleted);
    if (receipt != null) await _load();
  }

  void _report(OperationReceipt? receipt, String success) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt != null
              ? success
              : ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed,
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }
}

enum _TunableAction { edit, delete }
