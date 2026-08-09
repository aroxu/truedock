import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import '../../../l10n/app_localizations.dart';

import '../../resources/domain/server_resources.dart';
import '../domain/dataset_configuration.dart';
import 'storage_localizations.dart';

/// Units offered for quota entry. TrueNAS stores quotas in bytes.
enum SizeUnit { mib, gib, tib }

extension SizeUnitApi on SizeUnit {
  int get multiplier => switch (this) {
    SizeUnit.mib => 1024 * 1024,
    SizeUnit.gib => 1024 * 1024 * 1024,
    SizeUnit.tib => 1024 * 1024 * 1024 * 1024,
  };

  String get label => switch (this) {
    SizeUnit.mib => 'MiB',
    SizeUnit.gib => 'GiB',
    SizeUnit.tib => 'TiB',
  };
}

/// Editing sheet for an existing dataset's ZFS properties.
///
/// Returns the validated `pool.dataset.update` payload after an explicit
/// review step, so the caller performs the mutation.
class DatasetEditSheet extends StatefulWidget {
  const DatasetEditSheet({required this.dataset, super.key});

  final Dataset dataset;

  @override
  State<DatasetEditSheet> createState() => _DatasetEditSheetState();
}

class _DatasetEditSheetState extends State<DatasetEditSheet> {
  late DatasetUpdateConfiguration _configuration;
  final _commentsController = TextEditingController();
  final _quotaController = TextEditingController();
  final _refquotaController = TextEditingController();
  SizeUnit _quotaUnit = SizeUnit.gib;
  SizeUnit _refquotaUnit = SizeUnit.gib;
  bool _reviewing = false;
  String? _error;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    _configuration = DatasetUpdateConfiguration.fromDataset(widget.dataset);
    _commentsController.text = _configuration.comments;
    if (_configuration.quotaBytes case final quota?) {
      _quotaUnit = _bestUnit(quota);
      _quotaController.text = _formatAmount(quota, _quotaUnit);
    }
    if (_configuration.refquotaBytes case final refquota?) {
      _refquotaUnit = _bestUnit(refquota);
      _refquotaController.text = _formatAmount(refquota, _refquotaUnit);
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _quotaController.dispose();
    _refquotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
            Text(
              _reviewing ? l10n.datasetReviewTitle : l10n.datasetEditTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(widget.dataset.name, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            if (_reviewing) ..._reviewContent(theme) else ..._form(),
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
            const SizedBox(height: 20),
            if (_reviewing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _reviewing = false),
                      child: Text(l10n.actionBack),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: Text(l10n.datasetApplyChanges),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _review,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(l10n.datasetReview),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _form() => [
    _PropertySection(
      title: l10n.storageDatasetEditComments,
      mode: _configuration.commentsMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(commentsMode: mode);
      }),
      child: TextField(
        controller: _commentsController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: l10n.datasetComments,
          prefixIcon: const Icon(Icons.notes_rounded),
        ),
      ),
    ),
    const SizedBox(height: 18),
    _PropertySection(
      title: l10n.datasetDatasetQuota,
      description: l10n.datasetDatasetQuotaDescription,
      mode: _configuration.quotaMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(quotaMode: mode);
      }),
      child: _SizeField(
        controller: _quotaController,
        unit: _quotaUnit,
        label: l10n.datasetQuota,
        onUnitChanged: (unit) => setState(() => _quotaUnit = unit),
      ),
    ),
    const SizedBox(height: 18),
    _PropertySection(
      title: l10n.datasetDataQuota,
      description: l10n.datasetDataQuotaDescription,
      mode: _configuration.refquotaMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(refquotaMode: mode);
      }),
      child: _SizeField(
        controller: _refquotaController,
        unit: _refquotaUnit,
        label: l10n.datasetDataQuota,
        onUnitChanged: (unit) => setState(() => _refquotaUnit = unit),
      ),
    ),
    const SizedBox(height: 18),
    _PropertySection(
      title: l10n.datasetReadOnly,
      mode: _configuration.readOnlyMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(readOnlyMode: mode);
      }),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.datasetReadOnlyDescription),
        value: _configuration.readOnly,
        onChanged: (value) => setState(() {
          _configuration = _configuration.copyWith(readOnly: value);
        }),
      ),
    ),
    const SizedBox(height: 18),
    _PropertySection(
      title: l10n.datasetCompression,
      mode: _configuration.compressionMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(compressionMode: mode);
      }),
      child: TrueDockDropdownButtonFormField<DatasetCompression>(
        initialValue: _configuration.compression,
        decoration: InputDecoration(
          labelText: l10n.datasetCompression,
          prefixIcon: const Icon(Icons.compress_rounded),
        ),
        items: [
          for (final value in DatasetCompression.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.datasetCompressionLabel(value)),
            ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _configuration = _configuration.copyWith(compression: value);
          });
        },
      ),
    ),
    const SizedBox(height: 18),
    _PropertySection(
      title: l10n.datasetSync,
      mode: _configuration.syncMode,
      onModeChanged: (mode) => setState(() {
        _configuration = _configuration.copyWith(syncMode: mode);
      }),
      child: TrueDockDropdownButtonFormField<DatasetSync>(
        initialValue: _configuration.sync,
        decoration: InputDecoration(
          labelText: l10n.datasetSync,
          prefixIcon: const Icon(Icons.sync_alt_rounded),
          helperMaxLines: 10,
          helperText: _configuration.sync == DatasetSync.disabled
              ? l10n.datasetSyncDisabledWarning
              : null,
        ),
        items: [
          for (final value in DatasetSync.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.datasetSyncLabel(value)),
            ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _configuration = _configuration.copyWith(sync: value);
          });
        },
      ),
    ),
  ];

  List<Widget> _reviewContent(ThemeData theme) {
    final changes = _pendingConfiguration().describeChanges(widget.dataset);
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final change in changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.datasetChange(change))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_configuration.readOnlyMode == DatasetPropertyMode.explicit &&
          _configuration.readOnly &&
          !widget.dataset.readOnly) ...[
        const SizedBox(height: 14),
        Card(
          color: theme.colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.datasetReadOnlyReviewWarning,
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ),
      ],
    ];
  }

  DatasetUpdateConfiguration _pendingConfiguration() {
    final quota = _parseSize(_quotaController.text, _quotaUnit);
    final refquota = _parseSize(_refquotaController.text, _refquotaUnit);
    return _configuration.copyWith(
      comments: _commentsController.text,
      quotaBytes: quota,
      clearQuota: quota == null,
      refquotaBytes: refquota,
      clearRefquota: refquota == null,
    );
  }

  void _review() {
    setState(() => _error = null);
    for (final (text, mode) in [
      (_quotaController.text, _configuration.quotaMode),
      (_refquotaController.text, _configuration.refquotaMode),
    ]) {
      if (mode == DatasetPropertyMode.explicit &&
          text.trim().isNotEmpty &&
          _parseSize(text, SizeUnit.gib) == null) {
        setState(() => _error = l10n.datasetQuotaEnterPositive);
        return;
      }
    }
    try {
      _pendingConfiguration().describeChanges(widget.dataset);
      setState(() => _reviewing = true);
    } on DatasetConfigurationException catch (error) {
      setState(() => _error = _configurationError(error));
    }
  }

  void _apply() {
    try {
      final payload = _pendingConfiguration().toApiJson(widget.dataset);
      Navigator.of(context).pop(payload);
    } on DatasetConfigurationException catch (error) {
      setState(() {
        _reviewing = false;
        _error = _configurationError(error);
      });
    }
  }

  String _configurationError(DatasetConfigurationException error) =>
      switch (error.code) {
        DatasetConfigurationCode.editNothingChanged =>
          l10n.datasetNothingChanged,
        _ => l10n.datasetOperationFailed,
      };

  static int? _parseSize(String text, SizeUnit unit) {
    final amount = double.tryParse(text.trim());
    if (amount == null || amount <= 0) return null;
    return (amount * unit.multiplier).round();
  }

  static SizeUnit _bestUnit(int bytes) {
    if (bytes >= SizeUnit.tib.multiplier) return SizeUnit.tib;
    if (bytes >= SizeUnit.gib.multiplier) return SizeUnit.gib;
    return SizeUnit.mib;
  }

  static String _formatAmount(int bytes, SizeUnit unit) {
    final value = bytes / unit.multiplier;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class _PropertySection extends StatelessWidget {
  const _PropertySection({
    required this.title,
    required this.mode,
    required this.onModeChanged,
    required this.child,
    this.description,
  });

  final String title;
  final String? description;
  final DatasetPropertyMode mode;
  final ValueChanged<DatasetPropertyMode> onModeChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        if (description case final text?) ...[
          const SizedBox(height: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SegmentedButton<DatasetPropertyMode>(
          segments: [
            ButtonSegment(
              value: DatasetPropertyMode.inherit,
              label: Text(l10n.storageDatasetEditInherit),
            ),
            ButtonSegment(
              value: DatasetPropertyMode.explicit,
              label: Text(l10n.storageDatasetEditSetHere),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        if (mode == DatasetPropertyMode.explicit) ...[
          const SizedBox(height: 12),
          child,
        ],
      ],
    );
  }
}

class _SizeField extends StatelessWidget {
  const _SizeField({
    required this.controller,
    required this.unit,
    required this.label,
    required this.onUnitChanged,
  });

  final TextEditingController controller;
  final SizeUnit unit;
  final String label;
  final ValueChanged<SizeUnit> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            helperText: l10n.datasetQuotaLeaveEmpty,
            prefixIcon: const Icon(Icons.straighten_rounded),
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<SizeUnit>(
          segments: [
            for (final value in SizeUnit.values)
              ButtonSegment(value: value, label: Text(value.label)),
          ],
          selected: {unit},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onUnitChanged(selection.first),
        ),
      ],
    );
  }
}
