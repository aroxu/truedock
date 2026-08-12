import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import 'vm_config_localizations.dart';
import '../domain/vm_configuration.dart';
import '../../resources/domain/server_resources.dart';

/// Editor for a virtual machine's configuration.
///
/// Returns the next [VmConfiguration] after an explicit review step. The
/// caller computes the diff against the baseline and sends only the changed
/// fields through `vm.update`. Memory and CPU changes take effect on the
/// next start, which the review surfaces explicitly.
class VmConfigSheet extends StatefulWidget {
  const VmConfigSheet({required this.vm, super.key});

  final VirtualMachine vm;

  @override
  State<VmConfigSheet> createState() => _VmConfigSheetState();
}

class _VmConfigSheetState extends State<VmConfigSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _memoryController;
  late final TextEditingController _minMemoryController;
  late final TextEditingController _shutdownTimeoutController;

  late VmConfiguration _configuration;
  late final VmConfiguration _baseline;
  bool _reviewing = false;
  Map<String, VmValidationCode> _errors = const {};

  @override
  void initState() {
    super.initState();
    _baseline = VmConfiguration.fromVm(widget.vm);
    _configuration = _baseline;
    _nameController = TextEditingController(text: _baseline.name);
    _descriptionController = TextEditingController(text: _baseline.description);
    _memoryController = TextEditingController(
      text: _baseline.memoryMiB.toString(),
    );
    _minMemoryController = TextEditingController(
      text: _baseline.minMemoryMiB?.toString() ?? '',
    );
    _shutdownTimeoutController = TextEditingController(
      text: _baseline.shutdownTimeoutSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memoryController.dispose();
    _minMemoryController.dispose();
    _shutdownTimeoutController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    _configuration = _configuration.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      memoryMiB: int.tryParse(_memoryController.text) ?? _baseline.memoryMiB,
      minMemoryMiB: int.tryParse(_minMemoryController.text),
      shutdownTimeoutSeconds:
          int.tryParse(_shutdownTimeoutController.text) ??
          _baseline.shutdownTimeoutSeconds,
    );
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
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.memory_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.sysVmConfigReviewTitle
                          : l10n.sysVmConfigEditTitle,
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
                      _reviewing ? l10n.actionSaveChanges : l10n.actionReview,
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

  Widget _form(ThemeData theme, AppLocalizations l10n) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TextField(
          controller: _nameController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigNameLabel,
            prefixIcon: const Icon(Icons.label_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigDescriptionLabel,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 18),
        Text(l10n.sysVmConfigCpuTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IntegerField(
                label: l10n.sysVmConfigSocketsLabel,
                value: _configuration.vcpus,
                onChanged: (v) => setState(
                  () => _configuration = _configuration.copyWith(vcpus: v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IntegerField(
                label: l10n.sysVmConfigCoresLabel,
                value: _configuration.cores,
                onChanged: (v) => setState(
                  () => _configuration = _configuration.copyWith(cores: v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IntegerField(
                label: l10n.sysVmConfigThreadsLabel,
                value: _configuration.threads,
                onChanged: (v) => setState(
                  () => _configuration = _configuration.copyWith(threads: v),
                ),
              ),
            ),
          ],
        ),
        if (_errors['vcpus'] != null ||
            _errors['cores'] != null ||
            _errors['threads'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.vmValidationMessage(
              _errors['vcpus'] ?? _errors['cores'] ?? _errors['threads']!,
            ),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.sysVmConfigMemoryTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: _memoryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigMemoryLabel,
            prefixIcon: const Icon(Icons.memory_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _minMemoryController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigMinMemoryLabel,
            prefixIcon: const Icon(Icons.trending_down_rounded),
            helperText: l10n.sysVmConfigMinMemoryHelper,
          ),
        ),
        if (_errors['memory'] != null || _errors['min_memory'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.vmValidationMessage(
              _errors['memory'] ?? _errors['min_memory']!,
            ),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Text(l10n.sysVmConfigBootCpuTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TrueDockDropdownButtonFormField<VmBootloader>(
          initialValue: _configuration.bootloader,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigBootloaderLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final b in VmBootloader.values)
              DropdownMenuItem(
                value: b,
                child: Text(l10n.vmBootloaderLabel(b)),
              ),
          ],
          onChanged: (b) {
            if (b == null) return;
            setState(
              () => _configuration = _configuration.copyWith(bootloader: b),
            );
          },
        ),
        const SizedBox(height: 10),
        TrueDockDropdownButtonFormField<VmCpuMode>(
          initialValue: _configuration.cpuMode,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigCpuModeLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final m in VmCpuMode.values)
              DropdownMenuItem(value: m, child: Text(l10n.vmCpuModeLabel(m))),
          ],
          onChanged: (m) {
            if (m == null) return;
            setState(
              () => _configuration = _configuration.copyWith(cpuMode: m),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(l10n.sysVmConfigBehaviourTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sysVmConfigAutostartTitle),
          subtitle: Text(l10n.sysVmConfigAutostartSubtitle),
          value: _configuration.autostart,
          onChanged: (v) => setState(
            () => _configuration = _configuration.copyWith(autostart: v),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sysVmConfigEnsureDisplayTitle),
          subtitle: Text(l10n.sysVmConfigEnsureDisplaySubtitle),
          value: _configuration.ensureDisplayDevice,
          onChanged: (v) => setState(
            () => _configuration = _configuration.copyWith(
              ensureDisplayDevice: v,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _shutdownTimeoutController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysVmConfigShutdownTimeoutLabel,
            prefixIcon: const Icon(Icons.timer_outlined),
            helperText: l10n.sysVmConfigShutdownTimeoutHelper,
          ),
        ),
        if (_errors['shutdown_timeout'] != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.vmValidationMessage(_errors['shutdown_timeout']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        if (_errors['name'] != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.vmValidationMessage(_errors['name']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
    final diff = _configuration.changedFields(_baseline);
    final keys = diff.keys.toList()..sort();
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
                label: l10n.sysVmConfigReviewName,
                value: _configuration.name,
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewCpu,
                value: l10n.sysVmConfigReviewCpuValue(
                  _configuration.vcpus,
                  _configuration.cores,
                  _configuration.threads,
                ),
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewMemory,
                value: _configuration.minMemoryMiB == null
                    ? l10n.sysVmConfigReviewMemoryValue(
                        _configuration.memoryMiB,
                      )
                    : l10n.sysVmConfigReviewMemoryWithMinValue(
                        _configuration.memoryMiB,
                        _configuration.minMemoryMiB!,
                      ),
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewBootloader,
                value: l10n.vmBootloaderLabel(_configuration.bootloader),
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewCpuMode,
                value: l10n.vmCpuModeLabel(_configuration.cpuMode),
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewAutostart,
                value: _configuration.autostart
                    ? l10n.sysVmConfigEnabled
                    : l10n.sysVmConfigDisabled,
              ),
              _ReviewRow(
                label: l10n.sysVmConfigReviewShutdown,
                value: l10n.sysVmConfigReviewShutdownValue(
                  _configuration.shutdownTimeoutSeconds,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (keys.isEmpty)
          _Notice(message: l10n.sysVmConfigNoFieldsChanged)
        else ...[
          _Notice(
            message: l10n.sysVmConfigApplyNotice(
              widget.vm.isRunning
                  ? l10n.sysVmConfigApplyRunning(widget.vm.name)
                  : l10n.sysVmConfigApplyStart,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sysVmConfigChangedFields,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          for (final key in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(key),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = validateVmConfiguration(_configuration);
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

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

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

class _IntegerField extends StatefulWidget {
  const _IntegerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_IntegerField> createState() => _IntegerFieldState();
}

class _IntegerFieldState extends State<_IntegerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _IntegerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) {
        final value = int.tryParse(text);
        if (value != null) widget.onChanged(value);
      },
    );
  }
}
