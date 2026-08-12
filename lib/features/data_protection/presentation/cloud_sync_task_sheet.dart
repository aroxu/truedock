import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/cloud_sync_configuration.dart';
import '../domain/task_schedule.dart';

extension _CloudSyncLocalizations on AppLocalizations {
  String cloudDirectionLabel(CloudSyncDirection direction) =>
      switch (direction) {
        CloudSyncDirection.push => cloudSyncDirectionPush,
        CloudSyncDirection.pull => cloudSyncDirectionPull,
      };

  String cloudDirectionDescription(CloudSyncDirection direction) =>
      switch (direction) {
        CloudSyncDirection.push => cloudSyncDirectionPushDescription,
        CloudSyncDirection.pull => cloudSyncDirectionPullDescription,
      };

  String cloudModeLabel(CloudSyncTransferMode mode) => switch (mode) {
    CloudSyncTransferMode.sync => cloudSyncModeSync,
    CloudSyncTransferMode.copy => cloudSyncModeCopy,
    CloudSyncTransferMode.move => cloudSyncModeMove,
  };

  String cloudModeDescription(CloudSyncTransferMode mode) => switch (mode) {
    CloudSyncTransferMode.sync => cloudSyncModeSyncDescription,
    CloudSyncTransferMode.copy => cloudSyncModeCopyDescription,
    CloudSyncTransferMode.move => cloudSyncModeMoveDescription,
  };

  String cloudPresetLabel(TaskSchedulePreset preset) => switch (preset) {
    TaskSchedulePreset.hourly => taskPresetHourly,
    TaskSchedulePreset.daily => taskPresetDaily,
    TaskSchedulePreset.weekly => taskPresetWeekly,
    TaskSchedulePreset.monthly => taskPresetMonthly,
    TaskSchedulePreset.custom => taskPresetCustom,
  };

  String cloudScheduleSummary(
    TaskSchedule schedule,
  ) => switch (schedule.summaryCode) {
    TaskScheduleSummaryCode.everyHour => taskScheduleEveryHour,
    TaskScheduleSummaryCode.everySundayMidnight => taskScheduleEverySunday,
    TaskScheduleSummaryCode.firstOfMonthMidnight => taskScheduleFirstOfMonth,
    TaskScheduleSummaryCode.everyDayMidnight => taskScheduleEveryDay,
    TaskScheduleSummaryCode.cron => taskScheduleCron(schedule.cronExpression),
  };

  String cloudValidationMessage(CloudSyncValidationCode code) => switch (code) {
    CloudSyncValidationCode.descriptionRequired => cloudSyncValidationName,
    CloudSyncValidationCode.pathRequired => cloudSyncValidationPathRequired,
    CloudSyncValidationCode.pathNotAbsolute => cloudSyncValidationPathAbsolute,
    CloudSyncValidationCode.credentialRequired => cloudSyncValidationCredential,
    CloudSyncValidationCode.bucketRequired => cloudSyncValidationBucket,
    CloudSyncValidationCode.transfersRange => cloudSyncValidationTransfers,
    CloudSyncValidationCode.encryptionPasswordRequired =>
      cloudSyncValidationPassword,
    CloudSyncValidationCode.cronInvalid => taskScheduleCronInvalid,
  };
}

/// Editor for a cloud sync task.
///
/// Returns the next [CloudSyncConfiguration] after a review step. The caller
/// sends it to `cloudsync.create` or `cloudsync.update` and routes the
/// submission through the shared high-impact confirmation.
///
/// Cloud credentials are selected from existing
/// `cloudsync.credentials.query` entries; TrueDock does not create them
/// because that involves provider secrets and OAuth flows.
class CloudSyncTaskSheet extends StatefulWidget {
  const CloudSyncTaskSheet({
    required this.baseline,
    this.credentials = const [],
    this.credentialsFailed = false,
    super.key,
  });

  final CloudSyncConfiguration baseline;

  /// Saved cloud credentials from `cloudsync.credentials.query`.
  final List<CloudCredential> credentials;

  /// True when the credential query failed, so the UI can distinguish
  /// "none configured" from "could not load".
  final bool credentialsFailed;

  @override
  State<CloudSyncTaskSheet> createState() => _CloudSyncTaskSheetState();
}

class _CloudSyncTaskSheetState extends State<CloudSyncTaskSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _pathController;
  late final TextEditingController _bucketController;
  late final TextEditingController _folderController;
  late final TextEditingController _storageClassController;
  late final TextEditingController _transfersController;
  late final TextEditingController _passwordController;
  late final TextEditingController _saltController;

  late CloudSyncConfiguration _configuration;
  late TaskSchedulePreset _preset;
  bool _reviewing = false;
  bool _obscureSecrets = true;
  Map<String, CloudSyncValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _preset = TaskSchedulePreset.daily;
    _descriptionController = TextEditingController(
      text: widget.baseline.description,
    );
    _pathController = TextEditingController(text: widget.baseline.path);
    _bucketController = TextEditingController(text: widget.baseline.bucket);
    _folderController = TextEditingController(text: widget.baseline.folder);
    _storageClassController = TextEditingController(
      text: widget.baseline.storageClass,
    );
    _transfersController = TextEditingController(
      text: widget.baseline.transfers?.toString() ?? '',
    );
    _passwordController = TextEditingController();
    _saltController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _pathController.dispose();
    _bucketController.dispose();
    _folderController.dispose();
    _storageClassController.dispose();
    _transfersController.dispose();
    _passwordController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  /// The credential backing the current selection, which decides whether the
  /// provider addresses a bucket and supports a storage class.
  CloudCredential? get _selectedCredential => widget.credentials
      .where((c) => c.id == _configuration.credentialId)
      .firstOrNull;

  void _syncConfiguration() {
    final transfersText = _transfersController.text.trim();
    _configuration = _configuration.copyWith(
      description: _descriptionController.text.trim(),
      path: _pathController.text.trim(),
      bucket: _bucketController.text.trim(),
      folder: _folderController.text.trim(),
      storageClass: _storageClassController.text.trim(),
      transfers: int.tryParse(transfersText),
      clearTransfers: transfersText.isEmpty,
      encryptionPassword: _passwordController.text,
      encryptionSalt: _saltController.text,
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
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.cloud_sync_outlined,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.cloudSyncReviewTitle
                          : (creating
                                ? l10n.cloudSyncNewTitle
                                : l10n.cloudSyncEditTitle),
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
    return code == null ? null : l10n.cloudValidationMessage(code);
  }

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    final credential = _selectedCredential;
    final usesBucket = _configuration.usesBucketFor(credential);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.cloudSyncTaskName,
            prefixIcon: const Icon(Icons.label_outline_rounded),
          ),
        ),
        _FieldError(message: _errorText(l10n, 'description')),
        const SizedBox(height: 18),
        Text(
          l10n.cloudSyncCredentialHeading,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (widget.credentialsFailed)
          _Notice(
            icon: Icons.error_outline_rounded,
            message: l10n.cloudSyncCredentialsLoadFailed,
          )
        else if (widget.credentials.isEmpty)
          _Notice(
            icon: Icons.cloud_off_outlined,
            message: l10n.cloudSyncNoCredentials,
          )
        else
          TrueDockDropdownButtonFormField<int>(
            initialValue:
                widget.credentials.any(
                  (c) => c.id == _configuration.credentialId,
                )
                ? _configuration.credentialId
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.cloudSyncCredential,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final item in widget.credentials)
                DropdownMenuItem(value: item.id, child: Text(item.label)),
            ],
            onChanged: (id) {
              if (id == null) return;
              setState(
                () =>
                    _configuration = _configuration.copyWith(credentialId: id),
              );
            },
          ),
        _FieldError(message: _errorText(l10n, 'credentials')),
        const SizedBox(height: 18),
        Text(l10n.cloudSyncDirection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<CloudSyncDirection>(
          initialValue: _configuration.direction,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final direction in CloudSyncDirection.values)
              DropdownMenuItem(
                value: direction,
                child: Text(l10n.cloudDirectionLabel(direction)),
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
          l10n.cloudDirectionDescription(_configuration.direction),
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Text(l10n.cloudSyncTransferMode, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<CloudSyncTransferMode>(
          initialValue: _configuration.transferMode,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final mode in CloudSyncTransferMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(l10n.cloudModeLabel(mode)),
              ),
          ],
          onChanged: (mode) {
            if (mode == null) return;
            setState(
              () =>
                  _configuration = _configuration.copyWith(transferMode: mode),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          l10n.cloudModeDescription(_configuration.transferMode),
          style: TextStyle(
            color: _configuration.transferMode.deletesData
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _pathController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.cloudSyncLocalPath,
            prefixIcon: const Icon(Icons.folder_outlined),
            helperText: l10n.cloudSyncLocalPathHelper,
          ),
        ),
        _FieldError(message: _errorText(l10n, 'path')),
        const SizedBox(height: 18),
        Text(l10n.cloudSyncRemoteLocation, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (usesBucket) ...[
          TextField(
            controller: _bucketController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.cloudSyncBucket,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
            ),
          ),
          _FieldError(message: _errorText(l10n, 'bucket')),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _folderController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.cloudSyncFolder,
            prefixIcon: const Icon(Icons.drive_folder_upload_outlined),
            helperText: usesBucket
                ? l10n.cloudSyncFolderBucketHelper
                : l10n.cloudSyncFolderDriveHelper,
          ),
        ),
        if (credential?.supportsStorageClass == true) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _storageClassController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.cloudSyncStorageClass,
              prefixIcon: const Icon(Icons.inventory_outlined),
              helperText: l10n.cloudSyncStorageClassHelper,
            ),
          ),
        ],
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
                label: Text(l10n.cloudPresetLabel(preset)),
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
          l10n.cloudScheduleSummary(_configuration.schedule),
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
        Text(l10n.cloudSyncAdvanced, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _transfersController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.cloudSyncTransfers,
            prefixIcon: const Icon(Icons.swap_horiz_rounded),
            helperText: l10n.cloudSyncTransfersHelper,
          ),
        ),
        _FieldError(message: _errorText(l10n, 'transfers')),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.cloudSyncEncryptFiles),
          subtitle: Text(l10n.cloudSyncEncryptFilesSubtitle),
          value: _configuration.encryption,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(encryption: value),
          ),
        ),
        if (_configuration.encryption) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.cloudSyncEncryptNames),
            subtitle: Text(l10n.cloudSyncEncryptNamesSubtitle),
            value: _configuration.filenameEncryption,
            onChanged: (value) => setState(
              () => _configuration = _configuration.copyWith(
                filenameEncryption: value,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscureSecrets,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: widget.baseline.isCreate
                  ? l10n.cloudSyncPassword
                  : l10n.cloudSyncPasswordEdit,
              prefixIcon: const Icon(Icons.password_rounded),
              helperText: widget.baseline.isCreate
                  ? l10n.cloudSyncPasswordHelper
                  : l10n.cloudSyncPasswordEditHelper,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecrets
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: _obscureSecrets
                    ? l10n.cloudSyncShowSecret
                    : l10n.cloudSyncHideSecret,
                onPressed: () =>
                    setState(() => _obscureSecrets = !_obscureSecrets),
              ),
            ),
          ),
          _FieldError(message: _errorText(l10n, 'encryptionPassword')),
          const SizedBox(height: 12),
          TextField(
            controller: _saltController,
            obscureText: _obscureSecrets,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: widget.baseline.isCreate
                  ? l10n.cloudSyncSalt
                  : l10n.cloudSyncSaltEdit,
              prefixIcon: const Icon(Icons.grain_rounded),
              helperText: widget.baseline.isCreate
                  ? l10n.cloudSyncSaltHelper
                  : l10n.cloudSyncSaltEditHelper,
            ),
          ),
          const SizedBox(height: 10),
          _Notice(
            icon: Icons.shield_outlined,
            message: l10n.cloudSyncSecretsNotice,
          ),
        ],
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.replicationEnabled),
          subtitle: Text(l10n.replicationEnabledSubtitle),
          value: _configuration.enabled,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(enabled: value),
          ),
        ),
        if (_configuration.preservedFields.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.lock_outline_rounded,
            message: l10n.cloudSyncPreservedFields(
              _configuration.preservedFields.keys.take(4).join(', ') +
                  (_configuration.preservedFields.length > 4
                      ? l10n.cloudSyncPreservedFieldsEllipsis
                      : ''),
            ),
          ),
        ],
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
    final credential = _selectedCredential;
    final usesBucket = _configuration.usesBucketFor(credential);
    final remote = usesBucket
        ? '${_configuration.bucket}/${_configuration.folder}'
        : (_configuration.folder.isEmpty ? '/' : _configuration.folder);
    final pushing = _configuration.direction == CloudSyncDirection.push;
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
                label: l10n.cloudSyncReviewName,
                value: _configuration.description,
              ),
              _ReviewRow(
                label: l10n.cloudSyncCredential,
                value: credential?.label ?? l10n.replicationNotSelected,
              ),
              _ReviewRow(
                label: l10n.cloudSyncDirection,
                value: _configuration.direction.apiValue,
              ),
              _ReviewRow(
                label: l10n.cloudSyncTransferMode,
                value: _configuration.transferMode.apiValue,
              ),
              _ReviewRow(
                label: l10n.cloudSyncLocalPath,
                value: _configuration.path,
              ),
              _ReviewRow(label: l10n.cloudSyncReviewRemote, value: remote),
              _ReviewRow(
                label: l10n.replicationReviewSchedule,
                value: l10n.cloudScheduleSummary(_configuration.schedule),
              ),
              _ReviewRow(
                label: l10n.cloudSyncReviewTransfers,
                value:
                    _configuration.transfers?.toString() ??
                    l10n.cloudSyncServerDefault,
              ),
              _ReviewRow(
                label: l10n.cloudSyncReviewEncryption,
                value: _configuration.encryption
                    ? (_configuration.filenameEncryption
                          ? l10n.cloudSyncEncryptionBoth
                          : l10n.cloudSyncEncryptionContents)
                    : l10n.cloudSyncEncryptionOff,
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
        // Spell out exactly which side loses data for the selected mode.
        if (_configuration.transferMode == CloudSyncTransferMode.sync)
          _Notice(
            icon: Icons.warning_amber_rounded,
            message: pushing
                ? l10n.cloudSyncSyncPushWarning
                : l10n.cloudSyncSyncPullWarning(_configuration.path),
          )
        else if (_configuration.transferMode == CloudSyncTransferMode.move)
          _Notice(
            icon: Icons.warning_amber_rounded,
            message: pushing
                ? l10n.cloudSyncMovePushWarning(_configuration.path)
                : l10n.cloudSyncMovePullWarning,
          )
        else
          _Notice(
            icon: Icons.check_circle_outline_rounded,
            message: l10n.cloudSyncCopyNotice,
          ),
        if (_configuration.encryption) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.key_rounded,
            message: l10n.cloudSyncEncryptionReminder,
          ),
        ],
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = cloudSyncConfigurationIssues(
      _configuration,
      credential: _selectedCredential,
    );
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
  final Map<String, CloudSyncValidationCode> errors;
  final ValueChanged<TaskSchedule> onChanged;

  String? _error(AppLocalizations l10n, String field) {
    final code = errors[field];
    return code == null ? null : l10n.cloudValidationMessage(code);
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
