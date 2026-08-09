import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/pool_configuration.dart';
import 'storage_localizations.dart';

extension _PoolCreateLocalizations on AppLocalizations {
  String vdevLabel(VdevType type) => switch (type) {
    VdevType.stripe => poolVdevStripe,
    VdevType.mirror => poolVdevMirror,
    VdevType.raidz1 => poolVdevRaidz1,
    VdevType.raidz2 => poolVdevRaidz2,
    VdevType.raidz3 => poolVdevRaidz3,
  };

  String vdevWarning(VdevType type) => switch (type) {
    VdevType.stripe => poolVdevStripeWarning,
    VdevType.mirror => poolVdevMirrorWarning,
    VdevType.raidz1 => poolVdevRaidz1Warning,
    VdevType.raidz2 => poolVdevRaidz2Warning,
    VdevType.raidz3 => poolVdevRaidz3Warning,
  };

  String validationMessage(PoolValidationIssue issue) => switch (issue.code) {
    PoolValidationCode.nameRequired => poolValidationNameRequired,
    PoolValidationCode.nameInvalid => poolValidationNameInvalid,
    PoolValidationCode.dataVdevRequired => poolValidationDataVdevRequired,
    PoolValidationCode.dataVdevNoDisks => poolValidationDataVdevNoDisks(
      issue.vdevIndex! + 1,
    ),
    PoolValidationCode.dataVdevMinimumDisks => poolValidationMinimumDisks(
      vdevLabel(issue.vdevType!),
      issue.vdevIndex! + 1,
      issue.minimumDisks!,
    ),
  };
}

/// Editor for creating a new storage pool via `pool.create`.
///
/// Returns the chosen [PoolConfiguration] after a review step. The caller
/// routes it through the shared confirmation and the server action
/// controller. Disks already used by another pool are excluded from the
/// candidate list the caller passes in.
class PoolCreateSheet extends StatefulWidget {
  const PoolCreateSheet({required this.candidateDisks, super.key});

  final List<StorageDisk> candidateDisks;

  @override
  State<PoolCreateSheet> createState() => _PoolCreateSheetState();
}

class _PoolCreateSheetState extends State<PoolCreateSheet> {
  final _nameController = TextEditingController();
  late AppLocalizations l10n;
  VdevType _dataVdevType = VdevType.stripe;
  final List<VdevSpec> _dataVdevs = [];
  final List<VdevSpec> _cacheVdevs = [];
  bool _encryption = false;
  bool _dedup = false;
  bool _autoTrim = true;
  bool _reviewing = false;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Set<String> get _usedDisks => {
    for (final v in _dataVdevs) ...v.disks,
    for (final v in _cacheVdevs) ...v.disks,
  };

  List<StorageDisk> get _availableForData {
    final used = _usedDisks;
    return widget.candidateDisks
        .where((disk) => !used.contains(disk.name))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.poolCreateReviewTitle
                          : l10n.poolCreateTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.poolCreateClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: _reviewing ? _review(theme) : _form(theme)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_reviewing)
                    TextButton.icon(
                      onPressed: () => setState(() => _reviewing = false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.poolCreateBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.poolCreateCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _reviewing ? _submit : _validate,
                    icon: Icon(
                      _reviewing
                          ? Icons.add_circle_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _reviewing ? l10n.poolCreateTitle : l10n.poolCreateReview,
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

  Widget _form(ThemeData theme) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _nameController,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: l10n.poolCreateNameLabel,
            prefixIcon: const Icon(Icons.label_outline_rounded),
            helperText: l10n.poolCreateNameHelper,
            errorText: _errors['name'],
          ),
        ),
        const SizedBox(height: 18),
        Text(l10n.poolCreateDataVdevs, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          l10n.poolCreateDataVdevsDescription,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        TrueDockDropdownButtonFormField<VdevType>(
          initialValue: _dataVdevType,
          decoration: InputDecoration(
            labelText: l10n.poolCreateVdevLayout,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final t in VdevType.values)
              DropdownMenuItem(value: t, child: Text(l10n.vdevLabel(t))),
          ],
          onChanged: (t) {
            if (t != null) setState(() => _dataVdevType = t);
          },
        ),
        const SizedBox(height: 6),
        _VdevWarning(type: _dataVdevType),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _availableForData.isEmpty ? null : _addDataVdev,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.poolCreateAddDataVdev),
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < _dataVdevs.length; index++)
          _VdevCard(
            vdev: _dataVdevs[index],
            index: index,
            label: l10n.poolCreateDataVdevLabel(index + 1),
            available: _availableForData,
            onChanged: (vdev) => setState(() {
              if (vdev.disks.isEmpty) {
                _dataVdevs.removeAt(index);
              } else {
                _dataVdevs[index] = vdev;
              }
            }),
          ),
        if (_errors['data'] != null) ...[
          const SizedBox(height: 8),
          Text(
            _errors['data']!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.poolCreateCache, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (var index = 0; index < _cacheVdevs.length; index++)
          _VdevCard(
            vdev: _cacheVdevs[index],
            index: index,
            label: l10n.poolCreateCacheVdevLabel(index + 1),
            available: _availableForData,
            forceStripe: true,
            onChanged: (vdev) => setState(() {
              if (vdev.disks.isEmpty) {
                _cacheVdevs.removeAt(index);
              } else {
                _cacheVdevs[index] = vdev;
              }
            }),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _availableForData.isEmpty
              ? null
              : () {
                  setState(
                    () => _cacheVdevs.add(
                      VdevSpec(type: VdevType.stripe, disks: const []),
                    ),
                  );
                },
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.poolCreateAddCacheVdev),
        ),
        const SizedBox(height: 18),
        Text(l10n.poolCreateOptions, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.poolCreateEncryption),
          subtitle: Text(l10n.poolCreateEncryptionSubtitle),
          value: _encryption,
          onChanged: (v) => setState(() => _encryption = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.poolCreateDeduplication),
          subtitle: Text(l10n.poolCreateDeduplicationSubtitle),
          value: _dedup,
          onChanged: (v) => setState(() => _dedup = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.poolCreateAutoTrim),
          subtitle: Text(l10n.poolCreateAutoTrimSubtitle),
          value: _autoTrim,
          onChanged: (v) => setState(() => _autoTrim = v),
        ),
      ],
    );
  }

  Future<void> _addDataVdev() async {
    final available = _availableForData;
    if (available.isEmpty) return;
    final chosen = await _pickDisks(available, _dataVdevType);
    if (chosen == null || chosen.isEmpty) return;
    setState(() {
      _dataVdevs.add(VdevSpec(type: _dataVdevType, disks: chosen));
      _errors = Map.of(_errors)..remove('data');
    });
  }

  Future<List<String>?> _pickDisks(
    List<StorageDisk> available,
    VdevType type,
  ) async {
    final selected = <String>{};
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _DiskPicker(
        available: available,
        type: type,
        selected: selected,
        onConfirm: () => Navigator.of(sheetContext).pop(selected.toList()),
      ),
    );
  }

  Widget _review(ThemeData theme) {
    final config = _configuration;
    final totalDisks = config.usedDisks.length;
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
              _ReviewRow(label: l10n.poolCreateReviewName, value: config.name),
              _ReviewRow(
                label: l10n.poolCreateDataVdevs,
                value: l10n.poolCreateReviewDataVdevsValue(
                  config.dataVdevs.length,
                  config.dataVdevs.fold<int>(
                    0,
                    (sum, vdev) => sum + vdev.disks.length,
                  ),
                ),
              ),
              for (var index = 0; index < config.dataVdevs.length; index++)
                _ReviewRow(
                  label: l10n.poolCreateReviewVdevLabel(index + 1),
                  value: l10n.poolCreateReviewVdevValue(
                    l10n.vdevLabel(config.dataVdevs[index].type),
                    config.dataVdevs[index].disks.length,
                  ),
                ),
              if (config.cacheVdevs.isNotEmpty)
                _ReviewRow(
                  label: l10n.poolCreateReviewCacheVdevs,
                  value: l10n.poolCreateReviewCacheVdevsValue(
                    config.cacheVdevs.length,
                  ),
                ),
              _ReviewRow(
                label: l10n.poolCreateReviewTotalDisks,
                value: '$totalDisks',
              ),
              _ReviewRow(
                label: l10n.poolCreateEncryption,
                value: config.encryption
                    ? l10n.poolCreateOn
                    : l10n.poolCreateOff,
              ),
              _ReviewRow(
                label: l10n.poolCreateDeduplication,
                value: config.dedup ? l10n.poolCreateOn : l10n.poolCreateOff,
              ),
              _ReviewRow(
                label: l10n.poolCreateAutoTrim,
                value: config.autoTrim ? l10n.poolCreateOn : l10n.poolCreateOff,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          message: config.encryption
              ? l10n.poolCreateNoticeEncrypted
              : l10n.poolCreateNoticePlain,
        ),
        const SizedBox(height: 12),
        _Notice(
          message: config.dedup
              ? l10n.poolCreateNoticeDedup
              : l10n.poolCreateNoticeStripe,
        ),
      ],
    );
  }

  PoolConfiguration get _configuration => PoolConfiguration(
    name: _nameController.text.trim(),
    dataVdevs: List<VdevSpec>.from(_dataVdevs),
    cacheVdevs: List<VdevSpec>.from(_cacheVdevs),
    encryption: _encryption,
    dedup: _dedup,
    autoTrim: _autoTrim,
  );

  void _validate() {
    final errors = {
      for (final issue in poolConfigurationIssues(_configuration))
        issue.field: l10n.validationMessage(issue),
    };
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() {
    Navigator.of(context).pop(_configuration);
  }
}

class _VdevWarning extends StatelessWidget {
  const _VdevWarning({required this.type});

  final VdevType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warn = type == VdevType.stripe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warn ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
          size: 18,
          color: warn
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.vdevWarning(type),
            style: TextStyle(
              color: warn
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _VdevCard extends StatelessWidget {
  const _VdevCard({
    required this.vdev,
    required this.index,
    required this.label,
    required this.available,
    required this.onChanged,
    this.forceStripe = false,
  });

  final VdevSpec vdev;
  final int index;
  final String label;
  final List<StorageDisk> available;
  final ValueChanged<VdevSpec> onChanged;
  final bool forceStripe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.hub_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label · ${l10n.vdevLabel(vdev.type)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    vdev.disks.isEmpty
                        ? l10n.poolCreateNoDisksSelected
                        : l10n.poolCreateDisksCount(
                            vdev.disks.length,
                            vdev.disks.join(', '),
                          ),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.poolCreateRemoveVdev,
              onPressed: () => onChanged(vdev.copyWith(disks: const [])),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiskPicker extends StatefulWidget {
  const _DiskPicker({
    required this.available,
    required this.type,
    required this.selected,
    required this.onConfirm,
  });

  final List<StorageDisk> available;
  final VdevType type;
  final Set<String> selected;
  final VoidCallback onConfirm;

  @override
  State<_DiskPicker> createState() => _DiskPickerState();
}

class _DiskPickerState extends State<_DiskPicker> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minDisks = switch (widget.type) {
      VdevType.mirror => 2,
      VdevType.raidz1 => 2,
      VdevType.raidz2 => 3,
      VdevType.raidz3 => 4,
      VdevType.stripe => 1,
    };
    final canConfirm = widget.selected.length >= minDisks;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.poolCreateSelectDisks, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.poolCreateDiskPickerHint(
                l10n.vdevLabel(widget.type),
                minDisks,
                widget.selected.length,
              ),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.available.length,
                itemBuilder: (context, index) {
                  final disk = widget.available[index];
                  final checked = widget.selected.contains(disk.name);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        widget.selected.add(disk.name);
                      } else {
                        widget.selected.remove(disk.name);
                      }
                    }),
                    title: Text(disk.name),
                    subtitle: Text(
                      l10n.storageDiskPickerDiskSubtitle(
                        formatBytes(disk.sizeBytes),
                        l10n.diskModelLabel(disk.model),
                        l10n.diskSerialLabel(disk.serial),
                      ),
                    ),
                    secondary: Icon(
                      disk.isSolidState
                          ? Icons.memory_rounded
                          : Icons.storage_rounded,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canConfirm ? widget.onConfirm : null,
              child: Text(
                canConfirm
                    ? l10n.poolCreateAddDisks(widget.selected.length)
                    : l10n.poolCreateSelectAtLeast(minDisks),
              ),
            ),
          ],
        ),
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
            width: 120,
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
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
