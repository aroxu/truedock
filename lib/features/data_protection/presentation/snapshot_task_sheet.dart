import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/snapshot_task_configuration.dart';

extension _SnapshotTaskLocalizations on AppLocalizations {
  String lifetimeUnitLabel(SnapshotLifetimeUnit unit) => switch (unit) {
    SnapshotLifetimeUnit.hour => snapshotUnitHours,
    SnapshotLifetimeUnit.day => snapshotUnitDays,
    SnapshotLifetimeUnit.week => snapshotUnitWeeks,
    SnapshotLifetimeUnit.month => snapshotUnitMonths,
    SnapshotLifetimeUnit.year => snapshotUnitYears,
  };

  String presetLabel(SnapshotSchedulePreset preset) => switch (preset) {
    SnapshotSchedulePreset.hourly => snapshotPresetHourly,
    SnapshotSchedulePreset.daily => snapshotPresetDaily,
    SnapshotSchedulePreset.weekly => snapshotPresetWeekly,
    SnapshotSchedulePreset.monthly => snapshotPresetMonthly,
    SnapshotSchedulePreset.custom => snapshotPresetCustom,
  };

  String scheduleSummary(SnapshotTaskSchedule schedule) =>
      switch (schedule.summaryCode) {
        SnapshotScheduleSummaryCode.everyHour => snapshotScheduleEveryHour,
        SnapshotScheduleSummaryCode.everySundayMidnight =>
          snapshotScheduleEverySunday,
        SnapshotScheduleSummaryCode.firstOfMonthMidnight =>
          snapshotScheduleFirstOfMonth,
        SnapshotScheduleSummaryCode.everyDayMidnight =>
          snapshotScheduleEveryDay,
        SnapshotScheduleSummaryCode.cron => snapshotScheduleCron(
          schedule.cronExpression,
        ),
      };

  String snapshotValidationMessage(SnapshotValidationIssue issue) =>
      switch (issue.code) {
        SnapshotValidationCode.datasetRequired => snapshotValidationDataset,
        SnapshotValidationCode.retentionTooSmall => snapshotValidationRetention,
        SnapshotValidationCode.namingSchemaRequired =>
          snapshotValidationNamingRequired,
        SnapshotValidationCode.namingSchemaSlash =>
          snapshotValidationNamingSlash,
        SnapshotValidationCode.excludeNotChild => snapshotValidationExclude,
        SnapshotValidationCode.cronInvalid => snapshotValidationCron,
        SnapshotValidationCode.timeInvalid => snapshotValidationTime,
      };
}

class SnapshotTaskSheet extends StatefulWidget {
  const SnapshotTaskSheet({
    required this.datasets,
    this.existingTask,
    super.key,
  });

  final List<Dataset> datasets;
  final SnapshotTask? existingTask;

  @override
  State<SnapshotTaskSheet> createState() => _SnapshotTaskSheetState();
}

class _SnapshotTaskSheetState extends State<SnapshotTaskSheet> {
  final _lifetimeController = TextEditingController(text: '2');
  final _namingController = TextEditingController(text: 'auto-%Y-%m-%d_%H-%M');
  final _excludesController = TextEditingController();
  final _minuteController = TextEditingController(text: '00');
  final _hourController = TextEditingController(text: '*');
  final _dayOfMonthController = TextEditingController(text: '*');
  final _monthController = TextEditingController(text: '*');
  final _dayOfWeekController = TextEditingController(text: '*');
  final _beginController = TextEditingController(text: '00:00');
  final _endController = TextEditingController(text: '23:59');

  String? _dataset;
  SnapshotLifetimeUnit _lifetimeUnit = SnapshotLifetimeUnit.week;
  SnapshotSchedulePreset _preset = SnapshotSchedulePreset.hourly;
  bool _recursive = false;
  bool _allowEmpty = true;
  bool _enabled = true;
  bool _reviewing = false;
  Map<String, SnapshotValidationIssue> _errors = const {};

  @override
  void initState() {
    super.initState();
    final eligible = _eligibleDatasets;
    final existing = widget.existingTask;
    if (existing != null) {
      _dataset = eligible.any((dataset) => dataset.name == existing.dataset)
          ? existing.dataset
          : null;
      _lifetimeController.text = '${existing.lifetimeValue}';
      _lifetimeUnit = SnapshotLifetimeUnit.values.firstWhere(
        (unit) => unit.apiValue == existing.lifetimeUnit,
        orElse: () => SnapshotLifetimeUnit.week,
      );
      _namingController.text = existing.namingSchema;
      _excludesController.text = existing.excludes.join('\n');
      _recursive = existing.recursive;
      _allowEmpty = existing.allowEmpty;
      _enabled = existing.enabled;
      _applySchedule(
        SnapshotTaskSchedule(
          minute: existing.minute,
          hour: existing.hour,
          dayOfMonth: existing.dayOfMonth,
          month: existing.month,
          dayOfWeek: existing.dayOfWeek,
          begin: existing.begin,
          end: existing.end,
        ),
      );
      _preset = _detectPreset(_schedule);
    } else if (eligible.isNotEmpty) {
      _dataset = eligible.first.name;
    }
  }

  List<Dataset> get _eligibleDatasets => widget.datasets
      .where((dataset) => dataset.type == 'FILESYSTEM' && !dataset.locked)
      .toList(growable: false);

  @override
  void dispose() {
    _lifetimeController.dispose();
    _namingController.dispose();
    _excludesController.dispose();
    _minuteController.dispose();
    _hourController.dispose();
    _dayOfMonthController.dispose();
    _monthController.dispose();
    _dayOfWeekController.dispose();
    _beginController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .92,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.schedule_rounded,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.snapshotTaskReviewTitle
                              : widget.existingTask == null
                              ? l10n.snapshotTaskNewTitle
                              : l10n.snapshotTaskEditTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.snapshotTaskSubtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _reviewing ? _buildReview(l10n) : _buildForm(l10n),
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
                    onPressed: _eligibleDatasets.isEmpty
                        ? null
                        : (_reviewing ? _submit : _review),
                    icon: Icon(
                      _reviewing
                          ? Icons.add_task_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? widget.existingTask == null
                                ? l10n.snapshotTaskCreate
                                : l10n.actionContinue
                          : l10n.actionReview,
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
    final issue = _errors[field];
    return issue == null ? null : l10n.snapshotValidationMessage(issue);
  }

  Widget _buildForm(AppLocalizations l10n) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    children: [
      if (_eligibleDatasets.isEmpty)
        _TaskNotice(message: l10n.snapshotTaskNoDatasets, error: true)
      else
        TrueDockDropdownButtonFormField<String>(
          initialValue: _dataset,
          decoration: InputDecoration(
            labelText: l10n.snapshotTaskDataset,
            errorText: _errorText(l10n, 'dataset'),
            prefixIcon: const Icon(Icons.account_tree_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final dataset in _eligibleDatasets)
              DropdownMenuItem(value: dataset.name, child: Text(dataset.name)),
          ],
          onChanged: (dataset) => setState(() {
            _dataset = dataset;
            _errors = {..._errors}..remove('dataset');
          }),
        ),
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _recursive,
        onChanged: (value) => setState(() => _recursive = value),
        title: Text(l10n.snapshotTaskIncludeChildren),
        subtitle: Text(l10n.snapshotTaskIncludeChildrenSubtitle),
      ),
      if (_recursive) ...[
        const SizedBox(height: 8),
        TextField(
          controller: _excludesController,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: l10n.snapshotTaskExcludes,
            helperText: l10n.snapshotTaskExcludesHelper,
            errorText: _errorText(l10n, 'excludes'),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text(
        l10n.snapshotTaskRetention,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _lifetimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.snapshotTaskKeepFor,
                errorText: _errorText(l10n, 'lifetimeValue'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TrueDockDropdownButtonFormField<SnapshotLifetimeUnit>(
              initialValue: _lifetimeUnit,
              decoration: InputDecoration(
                labelText: l10n.snapshotTaskUnit,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final unit in SnapshotLifetimeUnit.values)
                  DropdownMenuItem(
                    value: unit,
                    child: Text(l10n.lifetimeUnitLabel(unit)),
                  ),
              ],
              onChanged: (unit) => setState(() {
                if (unit != null) _lifetimeUnit = unit;
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _namingController,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.snapshotTaskNamingSchema,
          helperText: l10n.snapshotTaskNamingHelper,
          errorText: _errorText(l10n, 'namingSchema'),
          prefixIcon: const Icon(Icons.label_outline_rounded),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        l10n.snapshotTaskSchedule,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      SegmentedButton<SnapshotSchedulePreset>(
        segments: [
          for (final preset in SnapshotSchedulePreset.values)
            ButtonSegment(value: preset, label: Text(l10n.presetLabel(preset))),
        ],
        selected: {_preset},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          final preset = selection.first;
          setState(() {
            _preset = preset;
            if (preset != SnapshotSchedulePreset.custom) {
              _applySchedule(SnapshotTaskSchedule.forPreset(preset));
            }
          });
        },
      ),
      const SizedBox(height: 12),
      if (_preset != SnapshotSchedulePreset.custom)
        _TaskNotice(message: l10n.scheduleSummary(_schedule))
      else ...[
        _CronGrid(
          minute: _minuteController,
          hour: _hourController,
          dayOfMonth: _dayOfMonthController,
          month: _monthController,
          dayOfWeek: _dayOfWeekController,
          errors: _errors,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _beginController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: l10n.snapshotTaskWindowBegins,
                  errorText: _errorText(l10n, 'begin'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _endController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: l10n.snapshotTaskWindowEnds,
                  errorText: _errorText(l10n, 'end'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 14),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _allowEmpty,
        onChanged: (value) => setState(() => _allowEmpty = value),
        title: Text(l10n.snapshotTaskAllowEmpty),
        subtitle: Text(l10n.snapshotTaskAllowEmptySubtitle),
      ),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _enabled,
        onChanged: (value) => setState(() => _enabled = value),
        title: Text(l10n.snapshotTaskEnable),
        subtitle: Text(
          widget.existingTask == null
              ? l10n.snapshotTaskEnableCreateSubtitle
              : l10n.snapshotTaskEnableEditSubtitle,
        ),
      ),
    ],
  );

  Widget _buildReview(AppLocalizations l10n) => ListView(
    children: [
      _ReviewCard(
        rows: [
          (l10n.snapshotTaskDataset, _dataset ?? l10n.snapshotTaskNone),
          (
            l10n.snapshotTaskScope,
            _recursive
                ? l10n.protectionScopeRecursiveValue
                : l10n.protectionScopeSelectedOnly,
          ),
          (l10n.snapshotTaskSchedule, l10n.scheduleSummary(_schedule)),
          (
            l10n.snapshotTaskRetention,
            l10n.snapshotTaskRetentionValue(
              _lifetimeController.text,
              l10n.lifetimeUnitLabel(_lifetimeUnit).toLowerCase(),
            ),
          ),
          (l10n.snapshotTaskNaming, _namingController.text),
          (
            l10n.snapshotTaskState,
            _enabled ? l10n.protectionEnabled : l10n.protectionDisabled,
          ),
        ],
      ),
      if (_recursive && _excludes.isNotEmpty) ...[
        const SizedBox(height: 12),
        _TaskNotice(
          message: l10n.snapshotTaskExcludedList(_excludes.join(', ')),
        ),
      ],
      const SizedBox(height: 12),
      _TaskNotice(
        icon: Icons.delete_sweep_outlined,
        message: l10n.snapshotTaskRetentionNotice,
      ),
    ],
  );

  SnapshotTaskSchedule get _schedule => SnapshotTaskSchedule(
    minute: _minuteController.text.trim(),
    hour: _hourController.text.trim(),
    dayOfMonth: _dayOfMonthController.text.trim(),
    month: _monthController.text.trim(),
    dayOfWeek: _dayOfWeekController.text.trim(),
    begin: _beginController.text.trim(),
    end: _endController.text.trim(),
  );

  List<String> get _excludes => _excludesController.text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  CreateSnapshotTaskRequest get _request => CreateSnapshotTaskRequest(
    dataset: _dataset ?? '',
    recursive: _recursive,
    lifetimeValue: int.tryParse(_lifetimeController.text.trim()) ?? 0,
    lifetimeUnit: _lifetimeUnit,
    enabled: _enabled,
    excludes: _excludes,
    namingSchema: _namingController.text.trim(),
    allowEmpty: _allowEmpty,
    schedule: _schedule,
  );

  void _applySchedule(SnapshotTaskSchedule schedule) {
    _minuteController.text = schedule.minute;
    _hourController.text = schedule.hour;
    _dayOfMonthController.text = schedule.dayOfMonth;
    _monthController.text = schedule.month;
    _dayOfWeekController.text = schedule.dayOfWeek;
    _beginController.text = schedule.begin;
    _endController.text = schedule.end;
  }

  void _review() {
    final errors = _request.issues();
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _request);

  SnapshotSchedulePreset _detectPreset(SnapshotTaskSchedule schedule) {
    for (final preset in SnapshotSchedulePreset.values) {
      if (preset == SnapshotSchedulePreset.custom) continue;
      final candidate = SnapshotTaskSchedule.forPreset(preset);
      if (candidate.minute == schedule.minute &&
          candidate.hour == schedule.hour &&
          candidate.dayOfMonth == schedule.dayOfMonth &&
          candidate.month == schedule.month &&
          candidate.dayOfWeek == schedule.dayOfWeek &&
          candidate.begin == schedule.begin &&
          candidate.end == schedule.end) {
        return preset;
      }
    }
    return SnapshotSchedulePreset.custom;
  }
}

class _CronGrid extends StatelessWidget {
  const _CronGrid({
    required this.minute,
    required this.hour,
    required this.dayOfMonth,
    required this.month,
    required this.dayOfWeek,
    required this.errors,
  });

  final TextEditingController minute;
  final TextEditingController hour;
  final TextEditingController dayOfMonth;
  final TextEditingController month;
  final TextEditingController dayOfWeek;
  final Map<String, SnapshotValidationIssue> errors;

  String? _error(AppLocalizations l10n, String field) {
    final issue = errors[field];
    return issue == null ? null : l10n.snapshotValidationMessage(issue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CronField(
                l10n.snapshotCronMinute,
                minute,
                _error(l10n, 'minute'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CronField(
                l10n.snapshotCronHour,
                hour,
                _error(l10n, 'hour'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CronField(
                l10n.snapshotCronDayOfMonth,
                dayOfMonth,
                _error(l10n, 'dayOfMonth'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CronField(
                l10n.snapshotCronMonth,
                month,
                _error(l10n, 'month'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CronField(
          l10n.snapshotCronDayOfWeek,
          dayOfWeek,
          _error(l10n, 'dayOfWeek'),
        ),
      ],
    );
  }
}

class _CronField extends StatelessWidget {
  const _CronField(this.label, this.controller, this.error);

  final String label;
  final TextEditingController controller;
  final String? error;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autocorrect: false,
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      border: const OutlineInputBorder(),
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    row.$1,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Text(row.$2)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _TaskNotice extends StatelessWidget {
  const _TaskNotice({
    required this.message,
    this.error = false,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final bool error;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: error
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
