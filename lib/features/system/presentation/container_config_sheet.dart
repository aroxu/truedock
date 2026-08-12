import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/container_configuration.dart';
import 'container_config_localizations.dart';
import '../../resources/domain/server_resources.dart';

/// Editor for a standalone container's configuration.
///
/// Returns the next [ContainerConfiguration] after a review step. The caller
/// sends the whole config to `container.update`; the editor preserves the raw
/// device/volume/env lists it does not surface so the round-trip keeps them.
class ContainerConfigSheet extends StatefulWidget {
  const ContainerConfigSheet({
    required this.container,
    required this.baseline,
    this.deviceChoices = const {},
    super.key,
  });

  final ManagedContainer container;

  /// The seeded configuration, including the raw device/volume/env lists
  /// captured from the server so they round-trip unchanged.
  final ContainerConfiguration baseline;

  /// Host devices available to attach, as returned by
  /// `container.device_choices`. Keyed by the device value the server expects
  /// and labelled with a human-readable description. Empty when the caller
  /// could not load choices (the picker is then hidden).
  final Map<String, String> deviceChoices;

  @override
  State<ContainerConfigSheet> createState() => _ContainerConfigSheetState();
}

class _ContainerConfigSheetState extends State<ContainerConfigSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vcpusController;
  late final TextEditingController _memoryController;

  late ContainerConfiguration _configuration;
  bool _reviewing = false;
  Map<String, ContainerValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _nameController = TextEditingController(text: widget.baseline.name);
    _descriptionController = TextEditingController(
      text: widget.baseline.description,
    );
    _vcpusController = TextEditingController(
      text: widget.baseline.vcpus?.toString() ?? '',
    );
    _memoryController = TextEditingController(
      text: widget.baseline.memoryLimitMiB?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _vcpusController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    _configuration = _configuration.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      vcpus: int.tryParse(_vcpusController.text),
      memoryLimitMiB: int.tryParse(_memoryController.text),
    );
  }

  /// Best-effort label for a preserved device entry. The container `devices`
  /// list shape is not fully documented in 25.10, so fall back through the
  /// most common fields and finally to the raw entry index as a sanity check.
  String _deviceLabel(Map<String, Object?> device) {
    for (final key in const ['path', 'source', 'name', 'dev', 'destination']) {
      final value = device[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return AppLocalizations.of(context).sysContainerConfigDeviceLabel(
      widget.baseline.devices.indexOf(device) + 1,
    );
  }

  /// Builds a new device entry from a `container.device_choices` value. The
  /// 25.10 container surface expects a passthrough block-device entry shaped
  /// like `{'path': <value>}`; the editor only adds block devices from the
  /// server-provided choice list to avoid guessing unsupported shapes.
  Map<String, Object?> _deviceEntryFromChoice(String value) => {'path': value};

  void _removeDevice(int index) {
    final devices = List<Map<String, Object?>>.from(_configuration.devices);
    if (index < 0 || index >= devices.length) return;
    devices.removeAt(index);
    setState(() => _configuration = _configuration.copyWith(devices: devices));
  }

  Future<void> _addDevice() async {
    final available = widget.deviceChoices.entries
        .where(
          (entry) => !_configuration.devices.any(
            (device) => _deviceLabel(device) == entry.key,
          ),
        )
        .toList();
    if (available.isEmpty) return;
    final choice = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _DeviceChoiceSheet(choices: available),
    );
    if (choice == null) return;
    final devices = List<Map<String, Object?>>.from(_configuration.devices)
      ..add(_deviceEntryFromChoice(choice.key));
    setState(() => _configuration = _configuration.copyWith(devices: devices));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.sysContainerConfigReviewTitle
                          : l10n.sysContainerConfigEditTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.sysContainerConfigClose,
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
                      label: Text(l10n.sysContainerConfigBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.sysContainerConfigCancel),
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
                      _reviewing
                          ? l10n.sysContainerConfigSaveChanges
                          : l10n.sysContainerConfigReview,
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _nameController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysContainerConfigNameLabel,
            prefixIcon: Icon(Icons.label_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysContainerConfigDescriptionLabel,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          enabled: false,
          controller: TextEditingController(text: _configuration.dataset),
          decoration: InputDecoration(
            labelText: l10n.sysContainerConfigDatasetLabel,
            prefixIcon: Icon(Icons.dataset_outlined),
            helperText: l10n.sysContainerConfigDatasetHelper,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.sysContainerConfigResourcesTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _vcpusController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysContainerConfigVcpusLabel,
            prefixIcon: Icon(Icons.memory_outlined),
            helperText: l10n.sysContainerConfigVcpusHelper,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memoryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysContainerConfigMemoryLabel,
            prefixIcon: Icon(Icons.trending_down_rounded),
            helperText: l10n.sysContainerConfigMemoryHelper,
          ),
        ),
        if (_errors['vcpus'] != null || _errors['memory'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.containerValidationMessage(
              _errors['vcpus'] ?? _errors['memory']!,
            ),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          l10n.sysContainerConfigBehaviourTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sysContainerConfigAutostartTitle),
          subtitle: Text(l10n.sysContainerConfigAutostartSubtitle),
          value: _configuration.autostart,
          onChanged: (v) => setState(
            () => _configuration = _configuration.copyWith(autostart: v),
          ),
        ),
        const SizedBox(height: 8),
        _InfoNotice(
          message: l10n.sysContainerConfigPreservedNotice(
            _configuration.devices.length,
            _configuration.volumes.length,
            _configuration.environment.length,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.sysContainerConfigDevicesTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.sysContainerConfigDevicesHelper,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (_configuration.devices.isEmpty)
          Text(l10n.sysContainerConfigNoDevices),
        for (final (index, device) in _configuration.devices.indexed) ...[
          if (index > 0) const SizedBox(height: 6),
          _DeviceRow(
            label: _deviceLabel(device),
            onRemove: () => _removeDevice(index),
          ),
        ],
        if (widget.deviceChoices.isNotEmpty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addDevice,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.sysContainerConfigAddDevice),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _InfoNotice(
          message: l10n.sysContainerConfigVolumesEnvNotice(
            _configuration.volumes.length,
            _configuration.environment.length,
          ),
        ),
        if (_errors['name'] != null || _errors['dataset'] != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.containerValidationMessage(
              _errors['name'] ?? _errors['dataset']!,
            ),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _review(ThemeData theme) {
    _syncConfiguration();
    final l10n = AppLocalizations.of(context);
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
                label: l10n.sysContainerConfigReviewName,
                value: _configuration.name,
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewDescription,
                value: _configuration.description.isEmpty
                    ? l10n.sysContainerConfigReviewDescriptionNone
                    : _configuration.description,
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewDataset,
                value: _configuration.dataset,
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewVcpus,
                value:
                    _configuration.vcpus?.toString() ??
                    l10n.sysContainerConfigReviewVcpusNone,
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewMemory,
                value: _configuration.memoryLimitMiB == null
                    ? l10n.sysContainerConfigReviewMemoryNone
                    : l10n.sysContainerConfigReviewMemoryValue(
                        _configuration.memoryLimitMiB!,
                      ),
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewAutostart,
                value: _configuration.autostart
                    ? l10n.sysContainerConfigReviewAutostartEnabled
                    : l10n.sysContainerConfigReviewAutostartDisabled,
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewDevices,
                value: l10n.sysContainerConfigReviewDevicesValue(
                  _configuration.devices.length,
                ),
              ),
              _ReviewRow(
                label: l10n.sysContainerConfigReviewVolumes,
                value: l10n.sysContainerConfigReviewVolumesValue(
                  _configuration.volumes.length,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoNotice(
          message:
              '${l10n.sysContainerConfigReviewNoticeBase} '
              '${widget.container.isRunning ? l10n.sysContainerConfigReviewNoticeRunning(widget.container.name) : l10n.sysContainerConfigReviewNoticeStart}',
        ),
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = validateContainerConfiguration(_configuration);
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

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.message});

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
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

/// A single attached device with a remove button.
class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.memory_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            tooltip: l10n.sysContainerConfigRemoveDevice,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing available host devices the user can attach.
class _DeviceChoiceSheet extends StatelessWidget {
  const _DeviceChoiceSheet({required this.choices});

  final List<MapEntry<String, String>> choices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.memory_outlined,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.sysContainerConfigAddDeviceTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.sysContainerConfigClose,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.sysContainerConfigAddDeviceHelper,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: choices.length,
                itemBuilder: (context, index) {
                  final entry = choices[index];
                  return ListTile(
                    leading: const Icon(Icons.memory_outlined),
                    title: Text(entry.value),
                    subtitle: Text(entry.key),
                    onTap: () => Navigator.pop(context, entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
