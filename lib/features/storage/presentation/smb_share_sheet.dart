import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/smb_share_configuration.dart';

extension _SmbLocalizations on AppLocalizations {
  String purposeLabel(SmbSharePurpose purpose) => switch (purpose) {
    SmbSharePurpose.defaultShare => smbPurposeDefault,
    SmbSharePurpose.timeMachine => smbPurposeTimeMachine,
    SmbSharePurpose.multiprotocol => smbPurposeMultiprotocol,
    SmbSharePurpose.timeLocked => smbPurposeTimeLocked,
    SmbSharePurpose.privateDatasets => smbPurposePrivateDatasets,
    SmbSharePurpose.external => smbPurposeExternal,
    SmbSharePurpose.finalCutPro => smbPurposeFinalCut,
    SmbSharePurpose.unsupported => smbPurposeUnsupported,
  };

  String purposeDescription(SmbSharePurpose purpose) => switch (purpose) {
    SmbSharePurpose.defaultShare => smbPurposeDefaultDescription,
    SmbSharePurpose.timeMachine => smbPurposeTimeMachineDescription,
    SmbSharePurpose.multiprotocol => smbPurposeMultiprotocolDescription,
    SmbSharePurpose.timeLocked => smbPurposeTimeLockedDescription,
    SmbSharePurpose.privateDatasets => smbPurposePrivateDatasetsDescription,
    SmbSharePurpose.external => smbPurposeExternalDescription,
    SmbSharePurpose.finalCutPro => smbPurposeFinalCutDescription,
    SmbSharePurpose.unsupported => smbPurposeUnsupportedDescription,
  };

  String validationMessage(String message) => switch (message) {
    'Enter a share name.' => smbValidationNameRequired,
    'Enter a valid unique SMB share name.' => smbValidationNameInvalid,
    'This SMB share purpose cannot be edited.' => smbValidationPurpose,
    'Choose a dataset path under /mnt/.' => smbValidationPath,
    r'Use one SERVER\SHARE destination per line.' => smbValidationRemotePaths,
    'Quota cannot be negative.' => smbValidationTimeMachineQuota,
    'Grace period must be 60–15,552,000 seconds.' => smbValidationGracePeriod,
    'Automatic quota cannot be negative.' => smbValidationAutoQuota,
    'Enter a dataset naming schema.' => smbValidationDatasetSchema,
    _ => message,
  };
}

class SmbShareSheet extends StatefulWidget {
  const SmbShareSheet({
    required this.datasets,
    required this.presets,
    this.existingShare,
    super.key,
  });

  final List<Dataset> datasets;
  final List<SmbSharePreset> presets;
  final SmbShare? existingShare;

  @override
  State<SmbShareSheet> createState() => _SmbShareSheetState();
}

class _SmbShareSheetState extends State<SmbShareSheet> {
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _pathFocusNode = FocusNode();
  final _commentController = TextEditingController();
  final _hostsAllowController = TextEditingController();
  final _hostsDenyController = TextEditingController();
  final _auditWatchController = TextEditingController();
  final _auditIgnoreController = TextEditingController();
  final _timeMachineQuotaController = TextEditingController(text: '0');
  final _datasetSchemaController = TextEditingController(text: '%U');
  final _gracePeriodController = TextEditingController(text: '900');
  final _autoQuotaController = TextEditingController(text: '0');
  final _remotePathsController = TextEditingController();
  late AppLocalizations l10n;

  late SmbSharePurpose _purpose;
  String? _volumeUuid;
  bool _enabled = true;
  bool _readOnly = false;
  bool _browsable = true;
  bool _accessBasedEnumeration = false;
  bool _auditEnabled = false;
  bool _aaplNameMangling = false;
  bool _autoSnapshot = false;
  bool _autoDatasetCreation = false;
  bool _reviewing = false;
  Map<String, String> _errors = const {};
  var _pathHasFocus = false;
  var _pathQuery = '';

  List<String> get _paths =>
      widget.datasets
          .where((dataset) => dataset.type == 'FILESYSTEM' && !dataset.locked)
          .map((dataset) => '/mnt/${dataset.name}')
          .toSet()
          .toList(growable: false)
        ..sort();

  List<SmbSharePurpose> get _purposes {
    final values = widget.presets
        .map((preset) => preset.purpose)
        .where((purpose) => purpose != SmbSharePurpose.unsupported)
        .toSet();
    if (values.isEmpty) values.add(SmbSharePurpose.defaultShare);
    final existing = widget.existingShare;
    if (existing != null) {
      final purpose = SmbSharePurposeApi.fromApi(existing.purpose);
      if (purpose != SmbSharePurpose.unsupported) values.add(purpose);
    }
    return values.toList(growable: false)
      ..sort((a, b) => a.index.compareTo(b.index));
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingShare;
    final configuration = existing == null
        ? SmbShareConfiguration.defaults()
        : SmbShareConfiguration.fromShare(existing);
    _purpose = configuration.purpose;
    _nameController.text = configuration.name;
    _commentController.text = configuration.comment;
    _enabled = configuration.enabled;
    _readOnly = configuration.readOnly;
    _browsable = configuration.browsable;
    _accessBasedEnumeration = configuration.accessBasedEnumeration;
    _auditEnabled = configuration.auditEnabled;
    _aaplNameMangling = configuration.aaplNameMangling;
    _autoSnapshot = configuration.autoSnapshot;
    _autoDatasetCreation = configuration.autoDatasetCreation;
    _volumeUuid = configuration.volumeUuid;
    _hostsAllowController.text = configuration.hostsAllow.join('\n');
    _hostsDenyController.text = configuration.hostsDeny.join('\n');
    _auditWatchController.text = configuration.auditWatchList.join('\n');
    _auditIgnoreController.text = configuration.auditIgnoreList.join('\n');
    _timeMachineQuotaController.text = '${configuration.timeMachineQuota}';
    _datasetSchemaController.text = configuration.datasetNamingSchema ?? '%U';
    _gracePeriodController.text = '${configuration.gracePeriod}';
    _autoQuotaController.text = '${configuration.autoQuota}';
    _remotePathsController.text = configuration.remotePaths.join('\n');
    if (_purpose.usesLocalPath) {
      _pathController.text = configuration.path.startsWith('/mnt/')
          ? configuration.path
          : (_paths.isEmpty ? '' : _paths.first);
    }
    if (existing == null && _pathController.text.isNotEmpty) {
      _nameController.text = _pathController.text.split('/').last;
    }
    _pathQuery = _pathController.text;
    _pathController.addListener(_handlePathChanged);
    _pathFocusNode.addListener(_handlePathFocusChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.removeListener(_handlePathChanged);
    _pathController.dispose();
    _pathFocusNode.removeListener(_handlePathFocusChanged);
    _pathFocusNode.dispose();
    _commentController.dispose();
    _hostsAllowController.dispose();
    _hostsDenyController.dispose();
    _auditWatchController.dispose();
    _auditIgnoreController.dispose();
    _timeMachineQuotaController.dispose();
    _datasetSchemaController.dispose();
    _gracePeriodController.dispose();
    _autoQuotaController.dispose();
    _remotePathsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final editing = widget.existingShare != null;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .94,
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
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.folder_shared_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.smbReviewTitle
                              : editing
                              ? l10n.smbEditTitle
                              : l10n.smbNewTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.purposeDescription(_purpose),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.smbClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: _reviewing ? _buildReview() : _buildForm()),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.smbBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.smbCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _purpose == SmbSharePurpose.unsupported
                        ? null
                        : (_reviewing ? _submit : _review),
                    icon: Icon(
                      _reviewing
                          ? editing
                                ? Icons.save_outlined
                                : Icons.add_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing
                          ? editing
                                ? l10n.smbSaveChanges
                                : l10n.smbCreateShare
                          : l10n.smbReview,
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

  Widget _buildForm() => ListView(
    padding: const EdgeInsets.only(top: 8),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    children: [
      TrueDockDropdownButtonFormField<SmbSharePurpose>(
        initialValue: _purpose,
        decoration: InputDecoration(
          labelText: l10n.smbPurpose,
          errorText: _errors['purpose'],
          prefixIcon: const Icon(Icons.tune_rounded),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final purpose in _purposes)
            DropdownMenuItem(
              value: purpose,
              child: Text(l10n.purposeLabel(purpose)),
            ),
        ],
        onChanged: widget.existingShare?.purpose == 'LEGACY_SHARE'
            ? null
            : (purpose) {
                if (purpose == null) return;
                setState(() {
                  _purpose = purpose;
                  if (purpose.usesLocalPath &&
                      _pathController.text.isEmpty &&
                      _paths.isNotEmpty) {
                    _pathController.text = _paths.first;
                  }
                  _errors = const {};
                });
              },
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: l10n.smbShareName,
          errorText: _errors['name'],
          prefixIcon: const Icon(Icons.badge_outlined),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (_purpose.usesLocalPath)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('smb-share-path-field'),
              controller: _pathController,
              focusNode: _pathFocusNode,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.smbSharePath,
                helperText: l10n.smbSharePathHelper,
                errorText: _errors['path'],
                prefixIcon: const Icon(Icons.account_tree_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_pathSuggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Material(
                key: const ValueKey('smb-share-path-suggestions'),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 176),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _pathSuggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final path = _pathSuggestions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -2),
                        minTileHeight: 44,
                        leading: const Icon(Icons.folder_outlined, size: 20),
                        title: Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectPath(path),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (_paths.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final path in _paths) ...[
                      ActionChip(
                        label: Text(path),
                        onPressed: () => _selectPath(path),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ],
        )
      else
        TextField(
          controller: _remotePathsController,
          minLines: 2,
          maxLines: 5,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.smbExternalDestinations,
            helperText: l10n.smbExternalDestinationsHelper,
            errorText: _errors['remotePaths'],
            prefixIcon: const Icon(Icons.lan_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
      const SizedBox(height: 12),
      TextField(
        controller: _commentController,
        decoration: InputDecoration(
          labelText: l10n.smbComment,
          prefixIcon: const Icon(Icons.notes_outlined),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      _buildPurposeOptions(),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _enabled,
        onChanged: (value) => setState(() => _enabled = value),
        title: Text(l10n.smbEnableShare),
        subtitle: Text(l10n.smbEnableShareDescription),
      ),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _readOnly,
        onChanged: (value) => setState(() => _readOnly = value),
        title: Text(l10n.smbReadOnly),
        subtitle: Text(l10n.smbReadOnlyDescription),
      ),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _browsable,
        onChanged: (value) => setState(() => _browsable = value),
        title: Text(l10n.smbShowInBrowsing),
      ),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        value: _accessBasedEnumeration,
        onChanged: (value) => setState(() => _accessBasedEnumeration = value),
        title: Text(l10n.smbAccessBasedEnumeration),
        subtitle: Text(l10n.smbAccessBasedEnumerationDescription),
      ),
      const SizedBox(height: 6),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.smbNetworkRestrictions),
        subtitle: Text(l10n.smbNetworkRestrictionsDescription),
        children: [
          TextField(
            controller: _hostsAllowController,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.smbAllowedHosts,
              helperText: l10n.smbAllowedHostsHelper,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hostsDenyController,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.smbDeniedHosts,
              helperText: l10n.smbOneEntryPerLine,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(l10n.smbAuditing),
        subtitle: Text(l10n.smbAuditingDescription),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _auditEnabled,
            onChanged: (value) => setState(() => _auditEnabled = value),
            title: Text(l10n.smbEnableAuditing),
          ),
          if (_auditEnabled) ...[
            TextField(
              controller: _auditWatchController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.smbGroupsToAudit,
                helperText: l10n.smbGroupsToAuditHelper,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _auditIgnoreController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.smbGroupsToIgnore,
                helperText: l10n.smbOneGroupPerLine,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    ],
  );

  List<String> get _pathSuggestions {
    if (!_pathHasFocus) return const [];
    final query = _pathQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _paths
        .where(
          (path) =>
              path.toLowerCase().contains(query) && path.toLowerCase() != query,
        )
        .take(6)
        .toList(growable: false);
  }

  void _handlePathChanged() {
    if (!mounted) return;
    setState(() => _pathQuery = _pathController.text);
  }

  void _handlePathFocusChanged() {
    if (!mounted) return;
    setState(() => _pathHasFocus = _pathFocusNode.hasFocus);
  }

  void _selectPath(String path) {
    setState(() {
      _pathController.value = TextEditingValue(
        text: path,
        selection: TextSelection.collapsed(offset: path.length),
      );
      if (widget.existingShare == null) {
        _nameController.text = path.split('/').last;
      }
      _errors = Map.of(_errors)..remove('path');
    });
    _pathFocusNode.unfocus();
  }

  Widget _buildPurposeOptions() => switch (_purpose) {
    SmbSharePurpose.timeMachine => Column(
      children: [
        TextField(
          controller: _timeMachineQuotaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.smbTimeMachineQuota,
            helperText: l10n.smbZeroDisablesServerQuota,
            errorText: _errors['timeMachineQuota'],
            border: const OutlineInputBorder(),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _autoSnapshot,
          onChanged: (value) => setState(() => _autoSnapshot = value),
          title: Text(l10n.smbSnapshotAfterBackup),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _autoDatasetCreation,
          onChanged: (value) => setState(() => _autoDatasetCreation = value),
          title: Text(l10n.smbDatasetPerUser),
        ),
        if (_autoDatasetCreation) _datasetSchemaField(),
      ],
    ),
    SmbSharePurpose.timeLocked => Column(
      children: [
        TextField(
          controller: _gracePeriodController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.smbGracePeriod,
            errorText: _errors['gracePeriod'],
            border: const OutlineInputBorder(),
          ),
        ),
        _aaplSwitch(),
      ],
    ),
    SmbSharePurpose.privateDatasets => Column(
      children: [
        _datasetSchemaField(),
        const SizedBox(height: 12),
        TextField(
          controller: _autoQuotaController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.smbPerUserQuota,
            helperText: l10n.smbZeroDisablesAutoQuota,
            errorText: _errors['autoQuota'],
            border: const OutlineInputBorder(),
          ),
        ),
        _aaplSwitch(),
      ],
    ),
    SmbSharePurpose.defaultShare ||
    SmbSharePurpose.multiprotocol => _aaplSwitch(),
    SmbSharePurpose.finalCutPro => _SmbNotice(message: l10n.smbFinalCutNotice),
    SmbSharePurpose.external => _SmbNotice(message: l10n.smbExternalNotice),
    SmbSharePurpose.unsupported => _SmbNotice(
      message: l10n.smbUnsupportedNotice,
      error: true,
    ),
  };

  Widget _aaplSwitch() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: _aaplNameMangling,
    onChanged: (value) => setState(() => _aaplNameMangling = value),
    title: Text(l10n.smbAppleFilenameMangling),
    subtitle: Text(l10n.smbAppleFilenameManglingDescription),
  );

  Widget _datasetSchemaField() => TextField(
    controller: _datasetSchemaController,
    autocorrect: false,
    decoration: InputDecoration(
      labelText: l10n.smbDatasetNamingSchema,
      helperText: l10n.smbDatasetNamingSchemaHelper,
      errorText: _errors['datasetNamingSchema'],
      border: const OutlineInputBorder(),
    ),
  );

  Widget _buildReview() => ListView(
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _ReviewRow(
              label: l10n.smbReviewShare,
              value: _nameController.text.trim(),
            ),
            _ReviewRow(
              label: l10n.smbPurpose,
              value: l10n.purposeLabel(_purpose),
            ),
            _ReviewRow(
              label: l10n.smbReviewLocation,
              value: _purpose.usesLocalPath
                  ? _pathController.text.trim()
                  : _remotePaths.join(', '),
            ),
            _ReviewRow(
              label: l10n.smbReviewAccess,
              value: _readOnly ? l10n.smbReadOnly : l10n.smbReadAndWrite,
            ),
            _ReviewRow(
              label: l10n.smbVisibility,
              value: _browsable
                  ? (_accessBasedEnumeration
                        ? l10n.smbBrowsableWhenAclPermits
                        : l10n.smbBrowsable)
                  : l10n.smbHiddenFromBrowsing,
            ),
            _ReviewRow(
              label: l10n.smbState,
              value: _enabled ? l10n.smbEnabled : l10n.smbDisabled,
            ),
            _ReviewRow(
              label: l10n.smbAuditing,
              value: _auditEnabled ? l10n.smbEnabled : l10n.smbDisabled,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_purpose == SmbSharePurpose.timeLocked)
        _SmbNotice(message: l10n.smbTimeLockedNotice, error: true)
      else if (_purpose == SmbSharePurpose.multiprotocol)
        _SmbNotice(message: l10n.smbMultiprotocolNotice)
      else
        _SmbNotice(message: l10n.smbValidationNotice),
    ],
  );

  List<String> get _remotePaths => _lines(_remotePathsController.text);

  SmbShareConfiguration get _configuration => SmbShareConfiguration(
    name: _nameController.text.trim(),
    path: _pathController.text.trim(),
    purpose: _purpose,
    enabled: _enabled,
    comment: _commentController.text.trim(),
    readOnly: _readOnly,
    browsable: _browsable,
    accessBasedEnumeration: _accessBasedEnumeration,
    auditEnabled: _auditEnabled,
    auditWatchList: _lines(_auditWatchController.text),
    auditIgnoreList: _lines(_auditIgnoreController.text),
    aaplNameMangling: _aaplNameMangling,
    hostsAllow: _lines(_hostsAllowController.text),
    hostsDeny: _lines(_hostsDenyController.text),
    timeMachineQuota:
        int.tryParse(_timeMachineQuotaController.text.trim()) ?? -1,
    autoSnapshot: _autoSnapshot,
    autoDatasetCreation: _autoDatasetCreation,
    datasetNamingSchema: _datasetSchemaController.text.trim(),
    volumeUuid: _volumeUuid,
    gracePeriod: int.tryParse(_gracePeriodController.text.trim()) ?? 0,
    autoQuota: int.tryParse(_autoQuotaController.text.trim()) ?? -1,
    remotePaths: _remotePaths,
  );

  void _review() {
    final errors = _configuration.validate();
    setState(() {
      _errors = {
        for (final entry in errors.entries)
          entry.key: l10n.validationMessage(entry.value),
      };
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _configuration);
}

List<String> _lines(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _SmbNotice extends StatelessWidget {
  const _SmbNotice({required this.message, this.error = false});

  final String message;
  final bool error;

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
            error ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
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
