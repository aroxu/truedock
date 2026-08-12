import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/rsync_configuration.dart';
import '../domain/task_schedule.dart';

extension _RsyncLocalizations on AppLocalizations {
  String rsyncDirectionLabel(RsyncDirection direction) => switch (direction) {
    RsyncDirection.push => rsyncDirectionPush,
    RsyncDirection.pull => rsyncDirectionPull,
  };

  String rsyncDirectionDescription(RsyncDirection direction) =>
      switch (direction) {
        RsyncDirection.push => rsyncDirectionPushDescription,
        RsyncDirection.pull => rsyncDirectionPullDescription,
      };

  String rsyncModeLabel(RsyncMode mode) => switch (mode) {
    RsyncMode.ssh => rsyncModeSsh,
    RsyncMode.module => rsyncModeModule,
  };

  String rsyncPresetLabel(TaskSchedulePreset preset) => switch (preset) {
    TaskSchedulePreset.hourly => taskPresetHourly,
    TaskSchedulePreset.daily => taskPresetDaily,
    TaskSchedulePreset.weekly => taskPresetWeekly,
    TaskSchedulePreset.monthly => taskPresetMonthly,
    TaskSchedulePreset.custom => taskPresetCustom,
  };

  String rsyncScheduleSummary(
    TaskSchedule schedule,
  ) => switch (schedule.summaryCode) {
    TaskScheduleSummaryCode.everyHour => taskScheduleEveryHour,
    TaskScheduleSummaryCode.everySundayMidnight => taskScheduleEverySunday,
    TaskScheduleSummaryCode.firstOfMonthMidnight => taskScheduleFirstOfMonth,
    TaskScheduleSummaryCode.everyDayMidnight => taskScheduleEveryDay,
    TaskScheduleSummaryCode.cron => taskScheduleCron(schedule.cronExpression),
  };

  String rsyncValidationMessage(RsyncValidationCode code) => switch (code) {
    RsyncValidationCode.pathRequired => rsyncValidationPathRequired,
    RsyncValidationCode.pathNotAbsolute => rsyncValidationPathAbsolute,
    RsyncValidationCode.userRequired => rsyncValidationUser,
    RsyncValidationCode.remoteHostRequired => rsyncValidationRemoteHost,
    RsyncValidationCode.remotePortRange => rsyncValidationRemotePort,
    RsyncValidationCode.remotePathRequired => rsyncValidationRemotePath,
    RsyncValidationCode.sshCredentialRequired => rsyncValidationSsh,
    RsyncValidationCode.remoteModuleRequired => rsyncValidationRemoteModule,
    RsyncValidationCode.cronInvalid => taskScheduleCronInvalid,
  };
}

/// Editor for an rsync task.
///
/// Returns the next [RsyncConfiguration] after a review step. The caller sends
/// it to `rsynctask.create` or `rsynctask.update` and routes the submission
/// through the shared high-impact confirmation.
///
/// SSH mode selects an existing `keychaincredential` entry; TrueDock does not
/// create SSH connections because that involves private-key material.
class RsyncTaskSheet extends StatefulWidget {
  const RsyncTaskSheet({
    required this.baseline,
    this.users = const [],
    this.sshCredentials = const [],
    this.sshCredentialsFailed = false,
    super.key,
  });

  final RsyncConfiguration baseline;

  /// Local usernames offered by the user picker.
  final List<String> users;

  /// Saved SSH connections from `keychaincredential.query`.
  final List<SshCredential> sshCredentials;

  /// True when the credential query failed, so the UI can distinguish
  /// "none configured" from "could not load".
  final bool sshCredentialsFailed;

  @override
  State<RsyncTaskSheet> createState() => _RsyncTaskSheetState();
}

class _RsyncTaskSheetState extends State<RsyncTaskSheet> {
  late final TextEditingController _pathController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _remoteHostController;
  late final TextEditingController _remotePortController;
  late final TextEditingController _remotePathController;
  late final TextEditingController _remoteModuleController;

  late RsyncConfiguration _configuration;
  late TaskSchedulePreset _preset;
  bool _reviewing = false;
  Map<String, RsyncValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _preset = TaskSchedulePreset.daily;
    _pathController = TextEditingController(text: widget.baseline.path);
    _descriptionController = TextEditingController(
      text: widget.baseline.description,
    );
    _remoteHostController = TextEditingController(
      text: widget.baseline.remoteHost,
    );
    _remotePortController = TextEditingController(
      text: widget.baseline.remotePort?.toString() ?? '',
    );
    _remotePathController = TextEditingController(
      text: widget.baseline.remotePath,
    );
    _remoteModuleController = TextEditingController(
      text: widget.baseline.remoteModule,
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    _descriptionController.dispose();
    _remoteHostController.dispose();
    _remotePortController.dispose();
    _remotePathController.dispose();
    _remoteModuleController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    final port = int.tryParse(_remotePortController.text.trim());
    _configuration = _configuration.copyWith(
      path: _pathController.text.trim(),
      description: _descriptionController.text.trim(),
      remoteHost: _remoteHostController.text.trim(),
      remotePort: port,
      clearRemotePort: _remotePortController.text.trim().isEmpty,
      remotePath: _remotePathController.text.trim(),
      remoteModule: _remoteModuleController.text.trim(),
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
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.sync_rounded,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.rsyncReviewTitle
                          : (creating
                                ? l10n.rsyncNewTitle
                                : l10n.rsyncEditTitle),
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
    return code == null ? null : l10n.rsyncValidationMessage(code);
  }

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    final sshMode = _configuration.mode == RsyncMode.ssh;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _pathController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.rsyncLocalPath,
            prefixIcon: const Icon(Icons.folder_outlined),
            helperText: l10n.rsyncLocalPathHelper,
          ),
        ),
        _FieldError(message: _errorText(l10n, 'path')),
        const SizedBox(height: 18),
        Text(l10n.rsyncRunAsUser, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          l10n.rsyncRunAsUserHelp,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (widget.users.isEmpty)
          Text(l10n.rsyncNoLocalUsers)
        else
          TrueDockDropdownButtonFormField<String>(
            initialValue: widget.users.contains(_configuration.user)
                ? _configuration.user
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.rsyncUser,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final user in widget.users)
                DropdownMenuItem(value: user, child: Text(user)),
            ],
            onChanged: (user) {
              if (user == null) return;
              setState(
                () => _configuration = _configuration.copyWith(user: user),
              );
            },
          ),
        _FieldError(message: _errorText(l10n, 'user')),
        const SizedBox(height: 18),
        Text(l10n.rsyncDirection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<RsyncDirection>(
          initialValue: _configuration.direction,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final direction in RsyncDirection.values)
              DropdownMenuItem(
                value: direction,
                child: Text(l10n.rsyncDirectionLabel(direction)),
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
        const SizedBox(height: 6),
        Text(
          l10n.rsyncDirectionDescription(_configuration.direction),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Text(l10n.rsyncRemote, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<RsyncMode>(
          initialValue: _configuration.mode,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.rsyncMode,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final mode in RsyncMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(l10n.rsyncModeLabel(mode)),
              ),
          ],
          onChanged: (mode) {
            if (mode == null) return;
            setState(() {
              _configuration = _configuration.copyWith(
                mode: mode,
                clearSshCredential: !mode.usesSshCredentials,
              );
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _remoteHostController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.rsyncRemoteHost,
            prefixIcon: const Icon(Icons.dns_outlined),
          ),
        ),
        _FieldError(message: _errorText(l10n, 'remoteHost')),
        const SizedBox(height: 12),
        TextField(
          controller: _remotePortController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.rsyncRemotePort,
            prefixIcon: const Icon(Icons.settings_ethernet_rounded),
            helperText: l10n.rsyncRemotePortHelper(
              _configuration.mode.defaultPort,
            ),
          ),
        ),
        _FieldError(message: _errorText(l10n, 'remotePort')),
        const SizedBox(height: 12),
        if (sshMode) ...[
          TextField(
            controller: _remotePathController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.rsyncRemotePath,
              prefixIcon: const Icon(Icons.drive_folder_upload_outlined),
            ),
          ),
          _FieldError(message: _errorText(l10n, 'remotePath')),
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
        ] else ...[
          TextField(
            controller: _remoteModuleController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.rsyncRemoteModule,
              prefixIcon: const Icon(Icons.view_module_outlined),
              helperText: l10n.rsyncRemoteModuleHelper,
            ),
          ),
          _FieldError(message: _errorText(l10n, 'remoteModule')),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.rsyncDescription,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
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
                label: Text(l10n.rsyncPresetLabel(preset)),
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
          l10n.rsyncScheduleSummary(_configuration.schedule),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (_preset == TaskSchedulePreset.custom) ...[
          const SizedBox(height: 12),
          _CronFields(
            schedule: _configuration.schedule,
            errors: _errors,
            onChanged: (schedule) => setState(
              () =>
                  _configuration = _configuration.copyWith(schedule: schedule),
            ),
          ),
        ],
        const SizedBox(height: 18),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.rsyncValidateRemotePath),
          subtitle: Text(l10n.rsyncValidateRemotePathSubtitle),
          value: _configuration.validateRemotePath,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(
              validateRemotePath: value,
            ),
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
    final sshMode = _configuration.mode == RsyncMode.ssh;
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
                label: l10n.rsyncLocalPath,
                value: _configuration.path,
              ),
              _ReviewRow(label: l10n.rsyncUser, value: _configuration.user),
              _ReviewRow(
                label: l10n.rsyncDirection,
                value: _configuration.direction.apiValue,
              ),
              _ReviewRow(
                label: l10n.rsyncMode,
                value: _configuration.mode.apiValue,
              ),
              _ReviewRow(
                label: l10n.rsyncReviewHost,
                value: _configuration.remoteHost,
              ),
              _ReviewRow(
                label: l10n.rsyncReviewPort,
                value: '${_configuration.effectivePort}',
              ),
              if (sshMode) ...[
                _ReviewRow(
                  label: l10n.rsyncRemotePath,
                  value: _configuration.remotePath,
                ),
                _ReviewRow(
                  label: l10n.replicationReviewSsh,
                  value: credential?.name ?? l10n.replicationNotSelected,
                ),
              ] else
                _ReviewRow(
                  label: l10n.rsyncReviewModule,
                  value: _configuration.remoteModule,
                ),
              _ReviewRow(
                label: l10n.replicationReviewSchedule,
                value: l10n.rsyncScheduleSummary(_configuration.schedule),
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
          message: _configuration.direction == RsyncDirection.push
              ? l10n.rsyncPushWarning
              : l10n.rsyncPullWarning(_configuration.path),
        ),
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = rsyncConfigurationIssues(_configuration);
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

class _CronFields extends StatelessWidget {
  const _CronFields({
    required this.schedule,
    required this.errors,
    required this.onChanged,
  });

  final TaskSchedule schedule;
  final Map<String, RsyncValidationCode> errors;
  final ValueChanged<TaskSchedule> onChanged;

  String? _error(AppLocalizations l10n, String field) {
    final code = errors[field];
    return code == null ? null : l10n.rsyncValidationMessage(code);
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
