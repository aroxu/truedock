import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/dataset_quota.dart';
import 'dataset_edit_sheet.dart' show SizeUnit, SizeUnitApi;

/// Per-account quotas for one dataset.
///
/// Dataset-wide `quota`/`refquota` already live in the properties editor; this
/// answers the different question of who may consume how much of it, which is
/// what matters once a dataset is shared between people.
///
/// Reads are per subject because `pool.dataset.get_quota` takes one
/// `quota_type` at a time, so the tab switch is a real fetch rather than a
/// filter over one list.
class DatasetQuotaSheet extends ConsumerStatefulWidget {
  const DatasetQuotaSheet({required this.dataset, super.key});

  final Dataset dataset;

  @override
  ConsumerState<DatasetQuotaSheet> createState() => _DatasetQuotaSheetState();
}

class _DatasetQuotaSheetState extends ConsumerState<DatasetQuotaSheet> {
  QuotaSubject _subject = QuotaSubject.user;
  List<DatasetQuota>? _quotas;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame. `_load` goes through the action
    // controller, which flips a busy flag - modifying a provider while the tree
    // is still building, which Riverpod rejects outright. Calling it directly
    // from initState threw before the sheet ever rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final quotas = await ref
        .read(serverActionControllerProvider.notifier)
        .loadDatasetQuotas(widget.dataset.name, _subject);
    if (!mounted) return;
    setState(() {
      _quotas = quotas;
      _loading = false;
      _failed = quotas == null;
    });
  }

  Future<void> _apply(DatasetQuotaEdit edit) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .setDatasetQuotas(widget.dataset.name, [edit]);
    if (!mounted) return;
    final error = ref.read(serverActionControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null ? error ?? l10n.quotaFailed : l10n.quotaApplied,
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null) await _load();
  }

  Future<void> _edit(DatasetQuota? existing) async {
    final l10n = AppLocalizations.of(context);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _QuotaEditSheet(
        subject: _subject,
        existing: existing,
        onApply: (edit) async {
          final receipt = await ref
              .read(serverActionControllerProvider.notifier)
              .setDatasetQuotas(widget.dataset.name, [edit]);
          if (receipt != null) return null;
          return ref.read(serverActionControllerProvider).errorMessage ??
              l10n.quotaFailed;
        },
      ),
    );
    if (applied != true || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.quotaApplied)));
    await _load();
  }

  /// Removes both limits for an account.
  ///
  /// Confirmed rather than a bare tap because removing a limit is what lets one
  /// account fill a shared dataset, but only `high`: nothing stored is lost and
  /// the limit can be set again, which the consequence says so the user is not
  /// left thinking data was deleted.
  Future<void> _remove(DatasetQuota quota) async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.quotaRemoveTitle(quota.name),
      server: serverName,
      target: '${widget.dataset.name} · ${quota.name}',
      actionLabel: l10n.quotaRemoveAction,
      impact: MutationImpact.high,
      consequences: [
        ImpactDetail(
          icon: Icons.all_inclusive_rounded,
          text: l10n.quotaRemoveConsequence(quota.name),
        ),
      ],
    );
    if (!confirmed || !mounted) return;
    await _apply(
      DatasetQuotaEdit(
        subject: quota.subject,
        // The name may be a bare uid when no account matches; either form is
        // accepted, which is what keeps an orphaned quota clearable.
        target: quota.name,
        spaceBytes: 0,
        objectCount: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = ref
        .watch(serverActionControllerProvider)
        .isBusy('dataset-quota-set:${widget.dataset.name}');

    // Accounts with no limit are usage rows the server always returns; showing
    // them first would bury the handful that are actually configured.
    final all = _quotas ?? const <DatasetQuota>[];
    final limited = all.where((q) => q.hasAnyQuota).toList();
    final unlimited = all.where((q) => !q.hasAnyQuota).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.quotaTitle(widget.dataset.name),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<QuotaSubject>(
              segments: [
                ButtonSegment(
                  value: QuotaSubject.user,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: Text(l10n.quotaSubjectUsers),
                ),
                ButtonSegment(
                  value: QuotaSubject.group,
                  icon: const Icon(Icons.groups_outlined),
                  label: Text(l10n.quotaSubjectGroups),
                ),
              ],
              selected: {_subject},
              onSelectionChanged: _loading
                  ? null
                  : (selection) {
                      setState(() => _subject = selection.first);
                      _load();
                    },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              _Message(
                icon: Icons.error_outline_rounded,
                text: l10n.quotaLoadFailed,
              )
            else if (all.isEmpty)
              _Message(
                icon: Icons.inbox_outlined,
                text: _subject == QuotaSubject.user
                    ? l10n.quotaNoneUsers
                    : l10n.quotaNoneGroups,
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final quota in limited)
                      _QuotaTile(
                        quota: quota,
                        onEdit: busy ? null : () => _edit(quota),
                        onRemove: busy ? null : () => _remove(quota),
                      ),
                    if (limited.isNotEmpty && unlimited.isNotEmpty)
                      const Divider(height: 24),
                    for (final quota in unlimited)
                      _QuotaTile(
                        quota: quota,
                        onEdit: busy ? null : () => _edit(quota),
                        onRemove: null,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy ? null : () => _edit(null),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.quotaAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaTile extends StatelessWidget {
  const _QuotaTile({
    required this.quota,
    required this.onEdit,
    required this.onRemove,
  });

  final DatasetQuota quota;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final details = <String>[
      if (quota.hasSpaceQuota)
        l10n.quotaSpaceOf(
          formatBytes(quota.usedBytes),
          formatBytes(quota.quotaBytes),
        )
      else
        l10n.quotaUsageOnly(formatBytes(quota.usedBytes)),
      if (quota.hasObjectQuota)
        l10n.quotaObjectsOf('${quota.objectsUsed}', '${quota.objectQuota}')
      else if (quota.objectsUsed > 0)
        l10n.quotaObjectsOnly('${quota.objectsUsed}'),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 4, right: 0),
      leading: Icon(
        quota.subject == QuotaSubject.user
            ? Icons.person_outline_rounded
            : Icons.groups_outlined,
        color: quota.isOverQuota ? colors.error : colors.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Flexible(child: Text(quota.name)),
          if (quota.isOverQuota) ...[
            const SizedBox(width: 8),
            // ZFS refuses writes past the limit, so this is a failure state
            // rather than a warning.
            Chip(
              label: Text(l10n.quotaOverLimit),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              backgroundColor: colors.errorContainer,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(details.join(' · ')),
          if (quota.spaceUsedFraction case final fraction?) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: fraction,
              color: quota.isOverQuota ? colors.error : null,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.quotaEditTitle(quota.name),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              tooltip: l10n.quotaRemoveAction,
            ),
        ],
      ),
    );
  }
}

/// Editor for one account's limits.
class _QuotaEditSheet extends StatefulWidget {
  const _QuotaEditSheet({
    required this.subject,
    required this.onApply,
    this.existing,
  });

  final QuotaSubject subject;
  final DatasetQuota? existing;
  final Future<String?> Function(DatasetQuotaEdit edit) onApply;

  @override
  State<_QuotaEditSheet> createState() => _QuotaEditSheetState();
}

class _QuotaEditSheetState extends State<_QuotaEditSheet> {
  late final TextEditingController _target;
  late final TextEditingController _space;
  late final TextEditingController _objects;
  SizeUnit _unit = SizeUnit.gib;
  List<QuotaValidationIssue> _issues = const [];
  bool _submitting = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _target = TextEditingController(text: existing?.name ?? '');
    _space = TextEditingController(
      text: existing != null && existing.hasSpaceQuota
          ? _amount(existing.quotaBytes)
          : '',
    );
    _objects = TextEditingController(
      text: existing != null && existing.hasObjectQuota
          ? '${existing.objectQuota}'
          : '',
    );
  }

  /// Picks the largest unit that still renders a whole-ish number, so a 2 GiB
  /// limit does not read as 2048 MiB.
  String _amount(int bytes) {
    for (final unit in [SizeUnit.tib, SizeUnit.gib, SizeUnit.mib]) {
      if (bytes >= unit.multiplier) {
        _unit = unit;
        final value = bytes / unit.multiplier;
        return value == value.roundToDouble()
            ? '${value.round()}'
            : value.toStringAsFixed(2);
      }
    }
    return '$bytes';
  }

  @override
  void dispose() {
    _target.dispose();
    _space.dispose();
    _objects.dispose();
    super.dispose();
  }

  DatasetQuotaEdit _build() {
    // An empty field means "leave alone"; the API has no separate clear, so a
    // typed 0 is how a limit is removed.
    final space = _space.text.trim();
    final objects = _objects.text.trim();
    return DatasetQuotaEdit(
      subject: widget.subject,
      target: _target.text,
      spaceBytes: space.isEmpty
          ? null
          : ((double.tryParse(space) ?? -1) * _unit.multiplier).round(),
      objectCount: objects.isEmpty ? null : int.tryParse(objects) ?? -1,
    );
  }

  Future<void> _submit() async {
    final edit = _build();
    final issues = edit.validate();
    if (issues.isNotEmpty) {
      setState(() {
        _issues = issues;
        _serverError = null;
      });
      return;
    }
    setState(() {
      _issues = const [];
      _serverError = null;
      _submitting = true;
    });
    final error = await widget.onApply(edit);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _submitting = false;
      _serverError = error;
    });
  }

  String? _errorFor(String field, AppLocalizations l10n) {
    for (final issue in _issues) {
      if (issue.field != field) continue;
      return switch (issue.code) {
        QuotaValidationCode.targetRequired => l10n.quotaValidationTarget,
        QuotaValidationCode.reservedTarget => l10n.quotaValidationReserved,
        QuotaValidationCode.negativeValue => l10n.quotaValidationNegative,
        QuotaValidationCode.nothingToApply => null,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final empty = _issues.any(
      (issue) => issue.code == QuotaValidationCode.nothingToApply,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? l10n.quotaAdd
                    : l10n.quotaEditTitle(widget.existing!.name),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _target,
                // An existing row's identity is not editable: changing it would
                // silently create a second quota instead of moving one.
                enabled: widget.existing == null,
                decoration: InputDecoration(
                  labelText: l10n.quotaTargetLabel,
                  helperText: l10n.quotaTargetHelp,
                  helperMaxLines: 10,
                  errorText: _errorFor('target', l10n),
                  errorMaxLines: 20,
                  prefixIcon: Icon(
                    widget.subject == QuotaSubject.user
                        ? Icons.person_outline_rounded
                        : Icons.groups_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _space,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.quotaSpaceLabel,
                        errorText: _errorFor('space', l10n),
                        errorMaxLines: 20,
                        prefixIcon: const Icon(Icons.data_usage_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TrueDockDropdownButton<SizeUnit>(
                    value: _unit,
                    onChanged: (unit) {
                      if (unit != null) setState(() => _unit = unit);
                    },
                    items: [
                      for (final unit in SizeUnit.values)
                        DropdownMenuItem(value: unit, child: Text(unit.label)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _objects,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.quotaObjectLabel,
                  errorText: _errorFor('objects', l10n),
                  errorMaxLines: 20,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.quotaZeroRemoves,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (empty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.quotaValidationEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_serverError case final error?) ...[
                const SizedBox(height: 12),
                _QuotaApplyError(message: error),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.quotaApply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotaApplyError extends StatelessWidget {
  const _QuotaApplyError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('quota-apply-error'),
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
