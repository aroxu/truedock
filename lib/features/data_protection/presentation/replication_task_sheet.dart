import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/replication_configuration.dart';
import '../domain/task_schedule.dart';

extension _ReplicationLocalizations on AppLocalizations {
  String transportLabel(ReplicationTransport transport) => switch (transport) {
    ReplicationTransport.ssh => replicationTransportSsh,
    ReplicationTransport.sshNetcat => replicationTransportSshNetcat,
    ReplicationTransport.local => replicationTransportLocal,
  };

  String directionLabel(ReplicationDirection direction) => switch (direction) {
    ReplicationDirection.push => replicationDirectionPush,
    ReplicationDirection.pull => replicationDirectionPull,
  };

  String retentionPolicyLabel(ReplicationRetentionPolicy policy) =>
      switch (policy) {
        ReplicationRetentionPolicy.source => replicationRetentionSource,
        ReplicationRetentionPolicy.custom => replicationRetentionCustom,
        ReplicationRetentionPolicy.none => replicationRetentionNone,
      };

  String retentionPolicyDescription(
    ReplicationRetentionPolicy policy,
  ) => switch (policy) {
    ReplicationRetentionPolicy.source => replicationRetentionSourceDescription,
    ReplicationRetentionPolicy.custom => replicationRetentionCustomDescription,
    ReplicationRetentionPolicy.none => replicationRetentionNoneDescription,
  };

  String replicationUnitLabel(ReplicationLifetimeUnit unit) => switch (unit) {
    ReplicationLifetimeUnit.hour => replicationUnitHours,
    ReplicationLifetimeUnit.day => replicationUnitDays,
    ReplicationLifetimeUnit.week => replicationUnitWeeks,
    ReplicationLifetimeUnit.month => replicationUnitMonths,
    ReplicationLifetimeUnit.year => replicationUnitYears,
  };

  String taskPresetLabel(TaskSchedulePreset preset) => switch (preset) {
    TaskSchedulePreset.hourly => taskPresetHourly,
    TaskSchedulePreset.daily => taskPresetDaily,
    TaskSchedulePreset.weekly => taskPresetWeekly,
    TaskSchedulePreset.monthly => taskPresetMonthly,
    TaskSchedulePreset.custom => taskPresetCustom,
  };

  String taskScheduleSummary(
    TaskSchedule schedule,
  ) => switch (schedule.summaryCode) {
    TaskScheduleSummaryCode.everyHour => taskScheduleEveryHour,
    TaskScheduleSummaryCode.everySundayMidnight => taskScheduleEverySunday,
    TaskScheduleSummaryCode.firstOfMonthMidnight => taskScheduleFirstOfMonth,
    TaskScheduleSummaryCode.everyDayMidnight => taskScheduleEveryDay,
    TaskScheduleSummaryCode.cron => taskScheduleCron(schedule.cronExpression),
  };

  String replicationValidationMessage(ReplicationValidationCode code) =>
      switch (code) {
        ReplicationValidationCode.nameRequired => replicationValidationName,
        ReplicationValidationCode.sourceDatasetsRequired =>
          replicationValidationSources,
        ReplicationValidationCode.targetRequired => replicationValidationTarget,
        ReplicationValidationCode.sshCredentialRequired =>
          replicationValidationSsh,
        ReplicationValidationCode.namingSchemaRequired =>
          replicationValidationNamingRequired,
        ReplicationValidationCode.namingSchemaSlash =>
          replicationValidationNamingSlash,
        ReplicationValidationCode.retentionTooSmall =>
          replicationValidationRetention,
        ReplicationValidationCode.targetSameAsSource =>
          replicationValidationTargetSameAsSource,
        ReplicationValidationCode.cronInvalid => taskScheduleCronInvalid,
      };
}

/// Editor for a replication task.
///
/// Returns the next [ReplicationConfiguration] after a review step. The caller
/// sends it to `replication.create` or `replication.update` and routes the
/// submission through the shared high-impact confirmation.
///
/// SSH connections are selected from existing `keychaincredential` entries;
/// TrueDock does not create them because that involves private-key material.
class ReplicationTaskSheet extends StatefulWidget {
  const ReplicationTaskSheet({
    required this.baseline,
    this.datasets = const [],
    this.sshCredentials = const [],
    this.sshCredentialsFailed = false,
    super.key,
  });

  final ReplicationConfiguration baseline;

  /// Dataset paths offered by the source picker.
  final List<String> datasets;

  /// Saved SSH connections from `keychaincredential.query`.
  final List<SshCredential> sshCredentials;

  /// True when the credential query failed, so the UI can distinguish
  /// "none configured" from "could not load".
  final bool sshCredentialsFailed;

  @override
  State<ReplicationTaskSheet> createState() => _ReplicationTaskSheetState();
}

class _ReplicationTaskSheetState extends State<ReplicationTaskSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _namingSchemaController;
  late final TextEditingController _lifetimeController;

  late ReplicationConfiguration _configuration;
  late TaskSchedulePreset _preset;
  bool _reviewing = false;
  Map<String, ReplicationValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _preset = TaskSchedulePreset.daily;
    _nameController = TextEditingController(text: widget.baseline.name);
    _targetController = TextEditingController(
      text: widget.baseline.targetDataset,
    );
    _namingSchemaController = TextEditingController(
      text: widget.baseline.namingSchema,
    );
    _lifetimeController = TextEditingController(
      text: widget.baseline.lifetimeValue.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _namingSchemaController.dispose();
    _lifetimeController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    _configuration = _configuration.copyWith(
      name: _nameController.text.trim(),
      targetDataset: _targetController.text.trim(),
      namingSchema: _namingSchemaController.text.trim(),
      lifetimeValue:
          int.tryParse(_lifetimeController.text) ??
          _configuration.lifetimeValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final creating = widget.baseline.isCreate;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.replicationReviewTitle
                          : (creating
                                ? l10n.replicationNewTitle
                                : l10n.replicationEditTitle),
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _reviewing ? _review(theme, l10n) : _form(theme, l10n),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.actionBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.save_outlined
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing ? l10n.protectionSaveTask : l10n.actionReview,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Translated message for a field's validation issue, or null when the
  /// field currently has no issue.
  String? _errorText(AppLocalizations l10n, String field) {
    final code = _errors[field];
    return code == null ? null : l10n.replicationValidationMessage(code);
  }

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _nameController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.replicationTaskName,
            prefixIcon: const Icon(Icons.label_outline_rounded),
          ),
        ),
        _FieldError(message: _errorText(l10n, 'name')),
        const SizedBox(height: 18),
        Text(l10n.replicationTransport, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<ReplicationTransport>(
          initialValue: _configuration.transport,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final transport in ReplicationTransport.values)
              DropdownMenuItem(
                value: transport,
                child: Text(l10n.transportLabel(transport)),
              ),
          ],
          onChanged: (transport) {
            if (transport == null) return;
            setState(() {
              _configuration = _configuration.copyWith(
                transport: transport,
                clearSshCredential: !transport.requiresSshCredentials,
              );
            });
          },
        ),
        if (_configuration.transport.requiresSshCredentials) ...[
          const SizedBox(height: 12),
          if (widget.sshCredentialsFailed)
            _Notice(
              icon: Icons.error_outline_rounded,
              message: l10n.replicationSshLoadFailed,
            )
          else if (widget.sshCredentials.isEmpty)
            _Notice(
              icon: Icons.key_off_outlined,
              message: l10n.replicationNoSshCredentials,
            )
          else
            TrueDockDropdownButtonFormField<int>(
              initialValue:
                  widget.sshCredentials.any(
                    (c) => c.id == _configuration.sshCredentialId,
                  )
                  ? _configuration.sshCredentialId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.replicationSshConnection,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final credential in widget.sshCredentials)
                  DropdownMenuItem(
                    value: credential.id,
                    child: Text(credential.name),
                  ),
              ],
              onChanged: (id) {
                if (id == null) return;
                setState(
                  () => _configuration = _configuration.copyWith(
                    sshCredentialId: id,
                  ),
                );
              },
            ),
          _FieldError(message: _errorText(l10n, 'sshCredentials')),
        ],
        const SizedBox(height: 18),
        Text(l10n.replicationDirection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<ReplicationDirection>(
          initialValue: _configuration.direction,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final direction in ReplicationDirection.values)
              DropdownMenuItem(
                value: direction,
                child: Text(l10n.directionLabel(direction)),
              ),
          ],
          onChanged: (direction) {
            if (direction == null) return;
            setState(
              () => _configuration = _configuration.copyWith(
                direction: direction,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(l10n.replicationSourceDatasets, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          l10n.replicationSourceDatasetsHelp,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (widget.datasets.isEmpty)
          Text(l10n.replicationNoDatasets)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dataset in widget.datasets)
                FilterChip(
                  label: Text(dataset),
                  selected: _configuration.sourceDatasets.contains(dataset),
                  onSelected: (selected) {
                    final next = [..._configuration.sourceDatasets];
                    if (selected) {
                      next.add(dataset);
                    } else {
                      next.remove(dataset);
                    }
                    setState(
                      () => _configuration = _configuration.copyWith(
                        sourceDatasets: next,
                      ),
                    );
                  },
                ),
            ],
          ),
        _FieldError(message: _errorText(l10n, 'sourceDatasets')),
        const SizedBox(height: 18),
        TextField(
          controller: _targetController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.replicationTargetDataset,
            prefixIcon: const Icon(Icons.output_rounded),
            helperText: l10n.replicationTargetHelper,
          ),
        ),
        _FieldError(message: _errorText(l10n, 'targetDataset')),
        const SizedBox(height: 18),
        TextField(
          controller: _namingSchemaController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.replicationNamingSchema,
            prefixIcon: const Icon(Icons.tag_rounded),
            helperText: l10n.replicationNamingHelper,
          ),
        ),
        _FieldError(message: _errorText(l10n, 'namingSchema')),
        const SizedBox(height: 18),
        Text(
          l10n.replicationRetentionHeading,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<ReplicationRetentionPolicy>(
          initialValue: _configuration.retentionPolicy,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final policy in ReplicationRetentionPolicy.values)
              DropdownMenuItem(
                value: policy,
                child: Text(l10n.retentionPolicyLabel(policy)),
              ),
          ],
          onChanged: (policy) {
            if (policy == null) return;
            setState(
              () => _configuration = _configuration.copyWith(
                retentionPolicy: policy,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          l10n.retentionPolicyDescription(_configuration.retentionPolicy),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (_configuration.retentionPolicy ==
            ReplicationRetentionPolicy.custom) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _lifetimeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.replicationKeepFor,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TrueDockDropdownButtonFormField<ReplicationLifetimeUnit>(
                  initialValue: _configuration.lifetimeUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final unit in ReplicationLifetimeUnit.values)
                      DropdownMenuItem(
                        value: unit,
                        child: Text(l10n.replicationUnitLabel(unit)),
                      ),
                  ],
                  onChanged: (unit) {
                    if (unit == null) return;
                    setState(
                      () => _configuration = _configuration.copyWith(
                        lifetimeUnit: unit,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          _FieldError(message: _errorText(l10n, 'lifetimeValue')),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.replicationScheduleHeading,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.replicationRunOnSchedule),
          subtitle: Text(l10n.replicationRunOnScheduleSubtitle),
          value: _configuration.auto,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(auto: value),
          ),
        ),
        if (_configuration.auto) ...[
          const SizedBox(height: 8),
          SegmentedButton<TaskSchedulePreset>(
            segments: [
              for (final preset in TaskSchedulePreset.values)
                ButtonSegment(
                  value: preset,
                  label: Text(l10n.taskPresetLabel(preset)),
                ),
            ],
            selected: {_preset},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              final preset = selection.first;
              setState(() {
                _preset = preset;
                if (preset != TaskSchedulePreset.custom) {
                  _configuration = _configuration.copyWith(
                    schedule: TaskSchedule.forPreset(preset),
                  );
                }
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            l10n.taskScheduleSummary(_configuration.schedule),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (_preset == TaskSchedulePreset.custom) ...[
            const SizedBox(height: 12),
            _CronFields(
              schedule: _configuration.schedule,
              errors: _errors,
              onChanged: (schedule) => setState(
                () => _configuration = _configuration.copyWith(
                  schedule: schedule,
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.replicationRecursive),
          subtitle: Text(l10n.replicationRecursiveSubtitle),
          value: _configuration.recursive,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(recursive: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.replicationEnabled),
          subtitle: Text(l10n.replicationEnabledSubtitle),
          value: _configuration.enabled,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(enabled: value),
          ),
        ),
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
    final credential = widget.sshCredentials
        .where((c) => c.id == _configuration.sshCredentialId)
        .firstOrNull;
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(
                label: l10n.replicationReviewName,
                value: _configuration.name,
              ),
              _ReviewRow(
                label: l10n.replicationReviewDirection,
                value: _configuration.direction.apiValue,
              ),
              _ReviewRow(
                label: l10n.replicationReviewTransport,
                value: _configuration.transport.apiValue,
              ),
              if (_configuration.transport.requiresSshCredentials)
                _ReviewRow(
                  label: l10n.replicationReviewSsh,
                  value: credential?.name ?? l10n.replicationNotSelected,
                ),
              _ReviewRow(
                label: l10n.replicationReviewSources,
                value: _configuration.sourceDatasets.isEmpty
                    ? l10n.replicationReviewNone
                    : _configuration.sourceDatasets.join('\n'),
              ),
              _ReviewRow(
                label: l10n.replicationReviewTarget,
                value: _configuration.targetDataset,
              ),
              _ReviewRow(
                label: l10n.replicationReviewSnapshots,
                value: _configuration.namingSchema,
              ),
              _ReviewRow(
                label: l10n.replicationReviewRetention,
                value:
                    _configuration.retentionPolicy ==
                        ReplicationRetentionPolicy.custom
                    ? l10n.replicationRetentionValue(
                        '${_configuration.lifetimeValue}',
                        l10n
                            .replicationUnitLabel(_configuration.lifetimeUnit)
                            .toLowerCase(),
                      )
                    : l10n.retentionPolicyLabel(_configuration.retentionPolicy),
              ),
              _ReviewRow(
                label: l10n.replicationReviewSchedule,
                value: _configuration.auto
                    ? l10n.taskScheduleSummary(_configuration.schedule)
                    : l10n.replicationManualOnly,
              ),
              _ReviewRow(
                label: l10n.replicationReviewRecursive,
                value: _configuration.recursive
                    ? l10n.replicationYes
                    : l10n.replicationNo,
              ),
              _ReviewRow(
                label: l10n.replicationReviewEnabled,
                value: _configuration.enabled
                    ? l10n.replicationYes
                    : l10n.replicationNo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          icon: Icons.warning_amber_rounded,
          message: l10n.replicationOverwriteWarning,
        ),
        if (_configuration.retentionPolicy ==
            ReplicationRetentionPolicy.custom) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.auto_delete_outlined,
            message: l10n.replicationCustomRetentionWarning,
          ),
        ],
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = replicationConfigurationIssues(_configuration);
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() {
    _syncConfiguration();
    Navigator.of(context).pop(_configuration);
  }
}

/// Cron entry fields shared by the custom schedule option.
class _CronFields extends StatelessWidget {
  const _CronFields({
    required this.schedule,
    required this.errors,
    required this.onChanged,
  });

  final TaskSchedule schedule;
  final Map<String, ReplicationValidationCode> errors;
  final ValueChanged<TaskSchedule> onChanged;

  String? _error(AppLocalizations l10n, String field) {
    final code = errors[field];
    return code == null ? null : l10n.replicationValidationMessage(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _CronField(
                label: l10n.replicationCronMinute,
                value: schedule.minute,
                error: _error(l10n, 'minute'),
                onChanged: (v) => onChanged(schedule.copyWith(minute: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CronField(
                label: l10n.replicationCronHour,
                value: schedule.hour,
                error: _error(l10n, 'hour'),
                onChanged: (v) => onChanged(schedule.copyWith(hour: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CronField(
                label: l10n.replicationCronDay,
                value: schedule.dayOfMonth,
                error: _error(l10n, 'dayOfMonth'),
                onChanged: (v) => onChanged(schedule.copyWith(dayOfMonth: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CronField(
                label: l10n.replicationCronMonth,
                value: schedule.month,
                error: _error(l10n, 'month'),
                onChanged: (v) => onChanged(schedule.copyWith(month: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CronField(
                label: l10n.replicationCronWeekday,
                value: schedule.dayOfWeek,
                error: _error(l10n, 'dayOfWeek'),
                onChanged: (v) => onChanged(schedule.copyWith(dayOfWeek: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CronField extends StatelessWidget {
  const _CronField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String label;
  final String value;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: error,
      ),
      onChanged: onChanged,
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
