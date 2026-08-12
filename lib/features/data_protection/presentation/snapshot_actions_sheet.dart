import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../resources/domain/server_resources.dart';

/// Localized label for a rollback mode.
///
/// The mode enum lives in the data layer and keeps an English label for
/// logging; the user-facing wording is resolved here so the picker and its
/// descriptions follow the active locale.
String rollbackModeLabel(AppLocalizations l10n, SnapshotRollbackMode mode) =>
    switch (mode) {
      SnapshotRollbackMode.newestOnly => l10n.snapshotRollbackModeNewestOnly,
      SnapshotRollbackMode.newerSnapshots => l10n.snapshotRollbackModeNewer,
      SnapshotRollbackMode.newerSnapshotsAndClones =>
        l10n.snapshotRollbackModeNewerAndClones,
    };

String rollbackModeDescription(
  AppLocalizations l10n,
  SnapshotRollbackMode mode,
) => switch (mode) {
  SnapshotRollbackMode.newestOnly =>
    l10n.snapshotRollbackModeNewestOnlyDescription,
  SnapshotRollbackMode.newerSnapshots =>
    l10n.snapshotRollbackModeNewerDescription,
  SnapshotRollbackMode.newerSnapshotsAndClones =>
    l10n.snapshotRollbackModeNewerAndClonesDescription,
};

/// The outcome chosen in [SnapshotActionsSheet].
sealed class SnapshotAction {
  const SnapshotAction();
}

class SnapshotDeleteAction extends SnapshotAction {
  const SnapshotDeleteAction();
}

class SnapshotRollbackAction extends SnapshotAction {
  const SnapshotRollbackAction({required this.mode, required this.force});

  final SnapshotRollbackMode mode;
  final bool force;
}

class SnapshotCloneAction extends SnapshotAction {
  const SnapshotCloneAction({required this.destination});

  final String destination;
}

class SnapshotHoldAction extends SnapshotAction {
  const SnapshotHoldAction({required this.held});

  final bool held;
}

/// Action chooser for a single snapshot.
///
/// Rollback and delete are destructive, so this sheet only collects the
/// parameters; the caller still runs the shared confirmation before calling
/// the server.
class SnapshotActionsSheet extends StatefulWidget {
  const SnapshotActionsSheet({
    required this.snapshot,
    required this.newerSnapshotCount,
    required this.canDelete,
    required this.canRollback,
    required this.canClone,
    required this.canHold,
    super.key,
  });

  final SnapshotEntry snapshot;

  /// Snapshots on the same dataset that are newer than this one. Rolling back
  /// destroys them, so the count drives the warnings shown here.
  final int newerSnapshotCount;
  final bool canDelete;
  final bool canRollback;
  final bool canClone;
  final bool canHold;

  @override
  State<SnapshotActionsSheet> createState() => _SnapshotActionsSheetState();
}

class _SnapshotActionsSheetState extends State<SnapshotActionsSheet> {
  final _cloneController = TextEditingController();
  SnapshotRollbackMode _mode = SnapshotRollbackMode.newestOnly;
  bool _force = false;
  _Section _section = _Section.menu;
  String? _error;

  @override
  void dispose() {
    _cloneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The clone destination seeds from the snapshot's dataset the first time
    // the sheet builds, once localized strings are available.
    if (_cloneController.text.isEmpty) {
      _cloneController.text = l10n.snapshotCloneSuffix(widget.snapshot.dataset);
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.snapshot.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(widget.snapshot.dataset, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            ...switch (_section) {
              _Section.menu => _menu(theme, l10n),
              _Section.rollback => _rollback(theme, l10n),
              _Section.clone => _clone(theme, l10n),
            },
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _menu(ThemeData theme, AppLocalizations l10n) => [
    if (widget.canHold)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          widget.snapshot.held
              ? Icons.lock_open_rounded
              : Icons.lock_outline_rounded,
        ),
        title: Text(
          widget.snapshot.held ? l10n.snapshotReleaseHold : l10n.snapshotHold,
        ),
        subtitle: Text(
          widget.snapshot.held
              ? l10n.snapshotReleaseHoldSubtitle
              : l10n.snapshotHoldSubtitle,
        ),
        onTap: () => Navigator.of(
          context,
        ).pop(SnapshotHoldAction(held: !widget.snapshot.held)),
      ),
    if (widget.canClone)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.copy_all_outlined),
        title: Text(l10n.snapshotCloneTitle),
        subtitle: Text(l10n.snapshotCloneSubtitle),
        onTap: () => setState(() => _section = _Section.clone),
      ),
    if (widget.canRollback)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.settings_backup_restore_rounded,
          color: theme.colorScheme.error,
        ),
        title: Text(l10n.snapshotRollbackTitle),
        subtitle: Text(
          widget.newerSnapshotCount == 0
              ? l10n.snapshotRollbackSubtitleClean
              : l10n.snapshotRollbackSubtitleNewer(widget.newerSnapshotCount),
        ),
        onTap: () => setState(() => _section = _Section.rollback),
      ),
    if (widget.canDelete)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.delete_forever_outlined,
          color: widget.snapshot.held ? null : theme.colorScheme.error,
        ),
        title: Text(l10n.snapshotDeleteTitle),
        subtitle: Text(
          widget.snapshot.held
              ? l10n.snapshotDeleteHeldSubtitle
              : l10n.snapshotDeleteSubtitle,
        ),
        // A held snapshot cannot be destroyed, so the server would reject it.
        enabled: !widget.snapshot.held,
        onTap: () => Navigator.of(context).pop(const SnapshotDeleteAction()),
      ),
    if (!widget.canClone &&
        !widget.canRollback &&
        !widget.canDelete &&
        !widget.canHold)
      Text(
        l10n.snapshotNoActions,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
  ];

  List<Widget> _rollback(ThemeData theme, AppLocalizations l10n) => [
    Text(l10n.snapshotRollbackHeading, style: theme.textTheme.titleMedium),
    const SizedBox(height: 12),
    RadioGroup<SnapshotRollbackMode>(
      groupValue: _mode,
      onChanged: (value) {
        if (value != null) setState(() => _mode = value);
      },
      child: Column(
        children: [
          for (final mode in SnapshotRollbackMode.values)
            RadioListTile<SnapshotRollbackMode>(
              contentPadding: EdgeInsets.zero,
              value: mode,
              title: Text(rollbackModeLabel(l10n, mode)),
              subtitle: Text(rollbackModeDescription(l10n, mode)),
            ),
        ],
      ),
    ),
    if (widget.newerSnapshotCount > 0 &&
        _mode == SnapshotRollbackMode.newestOnly)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.snapshotRollbackNewerWarning(widget.newerSnapshotCount),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    const SizedBox(height: 8),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.snapshotForceUnmount),
      subtitle: Text(l10n.snapshotForceUnmountSubtitle),
      value: _force,
      onChanged: (value) => setState(() => _force = value),
    ),
    const SizedBox(height: 18),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _section = _Section.menu),
            child: Text(l10n.actionBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(SnapshotRollbackAction(mode: _mode, force: _force)),
            child: Text(l10n.actionContinue),
          ),
        ),
      ],
    ),
  ];

  List<Widget> _clone(ThemeData theme, AppLocalizations l10n) => [
    Text(l10n.snapshotCloneHeading, style: theme.textTheme.titleMedium),
    const SizedBox(height: 6),
    Text(
      l10n.snapshotCloneDescription,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 14),
    TextField(
      controller: _cloneController,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: l10n.snapshotCloneDestinationLabel,
        prefixIcon: const Icon(Icons.dataset_outlined),
      ),
    ),
    const SizedBox(height: 18),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _section = _Section.menu),
            child: Text(l10n.actionBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _submitClone,
            child: Text(l10n.snapshotCreateClone),
          ),
        ),
      ],
    ),
  ];

  void _submitClone() {
    final l10n = AppLocalizations.of(context);
    final destination = _cloneController.text.trim();
    if (destination.isEmpty || !destination.contains('/')) {
      setState(() => _error = l10n.snapshotCloneValidationPath);
      return;
    }
    if (destination == widget.snapshot.dataset) {
      setState(() => _error = l10n.snapshotCloneValidationSameDataset);
      return;
    }
    Navigator.of(context).pop(SnapshotCloneAction(destination: destination));
  }
}

enum _Section { menu, rollback, clone }
