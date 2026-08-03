import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Impact classes from the safety policy in AGENTS.md.
///
/// [high] interrupts workloads or changes important configuration and needs an
/// explicit confirmation naming the server and target. [critical] is
/// irreversible and additionally requires the user to type the target name.
enum MutationImpact { high, critical }

/// A single consequence line shown in the confirmation sheet.
class ImpactDetail {
  const ImpactDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

/// Shared confirmation surface for high-risk and irreversible operations.
///
/// Returns true only when the user explicitly confirms. For [MutationImpact
/// .critical] the action button stays disabled until the typed name matches
/// [confirmationText] exactly, so a single mis-tap can never trigger it.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String server,
  required String target,
  required String actionLabel,
  required MutationImpact impact,
  required List<ImpactDetail> consequences,
  String? confirmationText,
  String? note,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _DestructiveConfirmationSheet(
      title: title,
      server: server,
      target: target,
      actionLabel: actionLabel,
      impact: impact,
      consequences: consequences,
      confirmationText: impact == MutationImpact.critical
          ? (confirmationText ?? target)
          : null,
      note: note,
    ),
  );
  return confirmed == true;
}

class _DestructiveConfirmationSheet extends StatefulWidget {
  const _DestructiveConfirmationSheet({
    required this.title,
    required this.server,
    required this.target,
    required this.actionLabel,
    required this.impact,
    required this.consequences,
    required this.confirmationText,
    required this.note,
  });

  final String title;
  final String server;
  final String target;
  final String actionLabel;
  final MutationImpact impact;
  final List<ImpactDetail> consequences;
  final String? confirmationText;
  final String? note;

  @override
  State<_DestructiveConfirmationSheet> createState() =>
      _DestructiveConfirmationSheetState();
}

class _DestructiveConfirmationSheetState
    extends State<_DestructiveConfirmationSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    final required = widget.confirmationText;
    if (required == null) return true;
    return _controller.text.trim() == required;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                widget.impact == MutationImpact.critical
                    ? Icons.dangerous_outlined
                    : Icons.warning_amber_rounded,
                color: colors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.title, style: theme.textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            color: colors.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TargetRow(
                    label: l10n.coreDestructiveServerLabel,
                    value: widget.server,
                  ),
                  const SizedBox(height: 8),
                  _TargetRow(
                    label: l10n.coreDestructiveTargetLabel,
                    value: widget.target,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.coreDestructiveConsequencesTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          for (final consequence in widget.consequences)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(consequence.icon, size: 19, color: colors.error),
                  const SizedBox(width: 12),
                  Expanded(child: Text(consequence.text)),
                ],
              ),
            ),
          if (widget.note case final note?) ...[
            const SizedBox(height: 12),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (widget.confirmationText case final required?) ...[
            const SizedBox(height: 20),
            Text(
              l10n.coreDestructiveCannotBeUndone(required),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.coreDestructiveConfirmNameLabel,
                hintText: required,
                prefixIcon: const Icon(Icons.keyboard_outlined),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.coreDestructiveCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _canConfirm
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  child: Text(widget.actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.titleSmall)),
      ],
    );
  }
}
