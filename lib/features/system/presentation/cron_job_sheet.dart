import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../data_protection/domain/task_schedule.dart';
import '../../data_protection/presentation/task_schedule_localizations.dart';
import '../domain/cron_job_configuration.dart';

/// Renders a cron job validation issue.
String cronValidationMessage(
  AppLocalizations l10n,
  CronJobValidationIssue issue,
) => switch (issue.code) {
  CronJobValidationCode.commandRequired => l10n.sysCronValidationCommand,
  CronJobValidationCode.userRequired => l10n.sysCronValidationUser,
};

/// Creates or edits a scheduled command.
///
/// Reuses [TaskSchedule] and the same preset control the data-protection task
/// sheets use, because `cronjob` takes the identical schedule object; a separate
/// picker here would let the two drift apart.
class CronJobSheet extends StatefulWidget {
  const CronJobSheet({
    required this.baseline,
    this.users = const [],
    super.key,
  });

  /// Existing configuration when editing, or a seed when creating.
  final CronJobConfiguration baseline;

  /// Accounts offered in the "run as" picker. Empty falls back to a text field,
  /// so the sheet still works when the account list could not be read.
  final List<String> users;

  @override
  State<CronJobSheet> createState() => _CronJobSheetState();
}

class _CronJobSheetState extends State<CronJobSheet> {
  late final TextEditingController _command;
  late final TextEditingController _description;
  late final TextEditingController _user;
  late CronJobConfiguration _configuration;
  late TaskSchedulePreset _preset;
  List<CronJobValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _command = TextEditingController(text: _configuration.command);
    _description = TextEditingController(text: _configuration.description);
    _user = TextEditingController(text: _configuration.user);
    _preset = _presetFor(_configuration.schedule);
  }

  /// Picks the preset whose schedule matches, so editing an existing job opens
  /// on the right segment instead of always claiming to be custom.
  TaskSchedulePreset _presetFor(TaskSchedule schedule) {
    for (final preset in TaskSchedulePreset.values) {
      if (preset == TaskSchedulePreset.custom) continue;
      final candidate = TaskSchedule.forPreset(preset);
      if (candidate.minute == schedule.minute &&
          candidate.hour == schedule.hour &&
          candidate.dayOfMonth == schedule.dayOfMonth &&
          candidate.month == schedule.month &&
          candidate.dayOfWeek == schedule.dayOfWeek) {
        return preset;
      }
    }
    return TaskSchedulePreset.custom;
  }

  @override
  void dispose() {
    _command.dispose();
    _description.dispose();
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                _configuration.command.isEmpty
                    ? l10n.sysCronCreateTitle
                    : l10n.sysCronEditTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _command,
                autocorrect: false,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.sysCronCommand,
                  helperText: l10n.sysCronCommandHelper,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              if (widget.users.isEmpty)
                TextField(
                  controller: _user,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.sysCronUser),
                )
              else
                TrueDockDropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: widget.users.contains(_user.text)
                      ? _user.text
                      : widget.users.first,
                  label: Text(l10n.sysCronUser),
                  dropdownMenuEntries: [
                    for (final user in widget.users)
                      DropdownMenuEntry(value: user, label: user),
                  ],
                  onSelected: (value) {
                    if (value != null) _user.text = value;
                  },
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _description,
                decoration: InputDecoration(labelText: l10n.sysCronDescription),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.replicationScheduleHeading,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskSchedulePreset>(
                segments: [
                  for (final preset in TaskSchedulePreset.values)
                    ButtonSegment(
                      value: preset,
                      label: Text(l10n.schedulePresetLabel(preset)),
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
                l10n.scheduleSummary(_configuration.schedule),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (_preset == TaskSchedulePreset.custom) ...[
                const SizedBox(height: 12),
                _ScheduleFields(
                  schedule: _configuration.schedule,
                  onChanged: (schedule) => setState(
                    () => _configuration = _configuration.copyWith(
                      schedule: schedule,
                    ),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.enabled,
                onChanged: (value) => setState(
                  () =>
                      _configuration = _configuration.copyWith(enabled: value),
                ),
                title: Text(l10n.sysCronEnabled),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.captureStdout,
                onChanged: (value) => setState(
                  () => _configuration = _configuration.copyWith(
                    captureStdout: value,
                  ),
                ),
                title: Text(l10n.sysCronCaptureStdout),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.captureStderr,
                onChanged: (value) => setState(
                  () => _configuration = _configuration.copyWith(
                    captureStderr: value,
                  ),
                ),
                title: Text(l10n.sysCronCaptureStderr),
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    cronValidationMessage(l10n, issue),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.actionCancel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(
                        l10n.actionSaveChanges,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  void _submit() {
    final configuration = _configuration.copyWith(
      command: _command.text,
      user: _user.text,
      description: _description.text,
    );
    final issues = configuration.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, configuration);
  }
}

/// The five cron fields, shown only for a custom schedule.
class _ScheduleFields extends StatelessWidget {
  const _ScheduleFields({required this.schedule, required this.onChanged});

  final TaskSchedule schedule;
  final ValueChanged<TaskSchedule> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(l10n.replicationCronMinute, schedule.minute, (v) {
          onChanged(_copy(minute: v));
        }),
        _field(l10n.replicationCronHour, schedule.hour, (v) {
          onChanged(_copy(hour: v));
        }),
        _field(l10n.replicationCronDay, schedule.dayOfMonth, (v) {
          onChanged(_copy(dayOfMonth: v));
        }),
        _field(l10n.replicationCronMonth, schedule.month, (v) {
          onChanged(_copy(month: v));
        }),
        _field(l10n.replicationCronWeekday, schedule.dayOfWeek, (v) {
          onChanged(_copy(dayOfWeek: v));
        }),
      ],
    );
  }

  TaskSchedule _copy({
    String? minute,
    String? hour,
    String? dayOfMonth,
    String? month,
    String? dayOfWeek,
  }) => TaskSchedule(
    minute: minute ?? schedule.minute,
    hour: hour ?? schedule.hour,
    dayOfMonth: dayOfMonth ?? schedule.dayOfMonth,
    month: month ?? schedule.month,
    dayOfWeek: dayOfWeek ?? schedule.dayOfWeek,
  );

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onFieldChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: value,
        autocorrect: false,
        decoration: InputDecoration(labelText: label),
        onChanged: onFieldChanged,
      ),
    );
  }
}
