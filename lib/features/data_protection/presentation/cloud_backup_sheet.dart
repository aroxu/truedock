import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/cloud_backup_configuration.dart';
import '../domain/cloud_sync_configuration.dart';
import '../domain/task_schedule.dart';
import 'task_schedule_localizations.dart';

extension _CloudBackupLocalizations on AppLocalizations {
  String backupTransferLabel(
    CloudBackupTransferSetting setting,
  ) => switch (setting) {
    CloudBackupTransferSetting.standard => protectionCloudBackupTransferDefault,
    CloudBackupTransferSetting.performance =>
      protectionCloudBackupTransferPerformance,
    CloudBackupTransferSetting.fastStorage => protectionCloudBackupTransferFast,
  };

  String backupValidationMessage(CloudBackupValidationIssue issue) =>
      switch (issue.code) {
        CloudBackupValidationCode.pathRequired =>
          protectionCloudBackupValidationPath,
        CloudBackupValidationCode.pathNotAbsolute =>
          protectionCloudBackupValidationPathAbsolute,
        CloudBackupValidationCode.credentialRequired =>
          protectionCloudBackupValidationCredential,
        CloudBackupValidationCode.passwordRequired =>
          protectionCloudBackupValidationPassword,
        CloudBackupValidationCode.bucketRequired => protectionCloudBackupBucket,
        CloudBackupValidationCode.keepLastRange =>
          protectionCloudBackupValidationKeepLast(issue.bound ?? 1),
      };
}

/// Creates or edits a cloud backup task.
///
/// The repository password is the one field that behaves differently from every
/// other editor in the app: it is required on create, and on an edit it starts
/// empty and means "unchanged". `cloud_backup.query` does return it, but seeding
/// the field would put a credential on screen and risk sending a placeholder as
/// the real password — which would leave the repository unreadable.
class CloudBackupSheet extends StatefulWidget {
  const CloudBackupSheet({
    required this.baseline,
    required this.credentials,
    this.isNew = true,
    super.key,
  });

  final CloudBackupConfiguration baseline;
  final List<CloudCredential> credentials;
  final bool isNew;

  @override
  State<CloudBackupSheet> createState() => _CloudBackupSheetState();
}

class _CloudBackupSheetState extends State<CloudBackupSheet> {
  late final TextEditingController _path;
  late final TextEditingController _description;
  late final TextEditingController _bucket;
  late final TextEditingController _folder;
  late final TextEditingController _keepLast;
  final _password = TextEditingController();
  late CloudBackupConfiguration _configuration;
  late TaskSchedulePreset _preset;
  var _obscurePassword = true;
  List<CloudBackupValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _path = TextEditingController(text: _configuration.path);
    _description = TextEditingController(text: _configuration.description);
    _bucket = TextEditingController(text: _configuration.bucket);
    _folder = TextEditingController(text: _configuration.folder);
    _keepLast = TextEditingController(
      text: _configuration.keepLast > 0 ? '${_configuration.keepLast}' : '7',
    );
    _preset = _presetFor(_configuration.schedule);
  }

  /// Opens on the preset that matches, so editing an existing task does not
  /// always claim to be a custom schedule.
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
    _path.dispose();
    _description.dispose();
    _bucket.dispose();
    _folder.dispose();
    _keepLast.dispose();
    _password.dispose();
    super.dispose();
  }

  CloudCredential? get _selectedCredential {
    for (final credential in widget.credentials) {
      if (credential.id == _configuration.credentialId) return credential;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final credential = _selectedCredential;
    // Bucket-less providers address a folder alone, so offering a bucket field
    // would invite a value the payload then drops.
    final usesBucket = credential?.usesBucket ?? false;
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
                widget.isNew
                    ? l10n.protectionCloudBackupSheetCreate
                    : l10n.protectionCloudBackupSheetEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _path,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.protectionCloudBackupPath,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _description,
                decoration: InputDecoration(labelText: l10n.sysCronDescription),
              ),
              const SizedBox(height: 14),
              TrueDockDropdownMenu<int>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _configuration.credentialId,
                label: Text(l10n.protectionCloudBackupCredential),
                dropdownMenuEntries: [
                  for (final credential in widget.credentials)
                    DropdownMenuEntry(
                      value: credential.id,
                      label: '${credential.name} · ${credential.provider}',
                    ),
                ],
                onSelected: (value) => setState(
                  () => _configuration = _configuration.copyWith(
                    credentialId: value,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (usesBucket) ...[
                TextField(
                  controller: _bucket,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.protectionCloudBackupBucket,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _folder,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.protectionCloudBackupFolder,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.protectionCloudBackupPassword,
                  helperText: widget.isNew
                      ? l10n.protectionCloudBackupPasswordHelperNew
                      : l10n.protectionCloudBackupPasswordHelperEdit,
                  helperMaxLines: 10,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword
                        ? l10n.authShowCredential
                        : l10n.authHideCredential,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _keepLast,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.protectionCloudBackupKeepLast,
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
              const SizedBox(height: 14),
              TrueDockDropdownMenu<CloudBackupTransferSetting>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _configuration.transferSetting,
                label: Text(l10n.protectionCloudBackupTransfer),
                dropdownMenuEntries: [
                  for (final setting in CloudBackupTransferSetting.values)
                    DropdownMenuEntry(
                      value: setting,
                      label: l10n.backupTransferLabel(setting),
                    ),
                ],
                onSelected: (value) {
                  if (value != null) {
                    setState(
                      () => _configuration = _configuration.copyWith(
                        transferSetting: value,
                      ),
                    );
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.snapshot,
                onChanged: (value) => setState(
                  () =>
                      _configuration = _configuration.copyWith(snapshot: value),
                ),
                title: Text(l10n.protectionCloudBackupSnapshotFirst),
                subtitle: Text(l10n.protectionCloudBackupSnapshotHelp),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _configuration.enabled,
                onChanged: (value) => setState(
                  () =>
                      _configuration = _configuration.copyWith(enabled: value),
                ),
                title: Text(l10n.protectionCloudBackupEnabled),
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.backupValidationMessage(issue),
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
      path: _path.text,
      description: _description.text,
      bucket: _bucket.text,
      folder: _folder.text,
      password: _password.text,
      keepLast: int.tryParse(_keepLast.text.trim()) ?? 0,
    );
    // Only a create must carry a password; an edit leaves it blank to keep the
    // stored one, and the repository substitutes it.
    final issues = configuration.validate(requirePassword: widget.isNew);
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, configuration);
  }
}
