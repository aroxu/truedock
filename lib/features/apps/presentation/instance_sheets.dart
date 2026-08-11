import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../resources/domain/server_resources.dart';
import '../../system/domain/virt_instance_configuration.dart';
import 'instance_lifecycle_controls.dart';
import 'instances_section.dart';
import 'apps_localizations.dart';

/// Renders a validation issue raised by the instance domain types.
String instanceValidationMessage(
  AppLocalizations l10n,
  VirtInstanceValidationIssue issue,
) => switch (issue.code) {
  VirtInstanceValidationCode.nameRequired =>
    l10n.appsInstanceValidationNameRequired,
  VirtInstanceValidationCode.nameInvalid =>
    l10n.appsInstanceValidationNameInvalid,
  VirtInstanceValidationCode.imageRequired =>
    l10n.appsInstanceValidationImageRequired,
  VirtInstanceValidationCode.cpuInvalid => l10n.appsInstanceValidationCpu,
  VirtInstanceValidationCode.memoryRange => l10n.appsInstanceValidationMemory(
    issue.bound ?? virtMinimumMemoryMiB,
  ),
  VirtInstanceValidationCode.rootDiskRange =>
    l10n.appsInstanceValidationRootDisk(issue.bound ?? virtMaximumRootDiskGiB),
  VirtInstanceValidationCode.environmentKeyInvalid =>
    l10n.appsInstanceValidationEnvironment,
};

/// Status, metrics, devices, and lifecycle actions for one instance.
class InstanceDetailsSheet extends ConsumerStatefulWidget {
  const InstanceDetailsSheet({required this.instance, super.key});

  final VirtInstance instance;

  @override
  ConsumerState<InstanceDetailsSheet> createState() =>
      _InstanceDetailsSheetState();
}

class _InstanceDetailsSheetState extends ConsumerState<InstanceDetailsSheet> {
  List<VirtInstanceDevice>? _devices;
  var _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDevices();
    });
  }

  Future<void> _loadDevices() async {
    final devices = await ref
        .read(serverActionControllerProvider.notifier)
        .loadVirtInstanceDevices(widget.instance.id);
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _loadingDevices = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final instance = widget.instance;
    final verbs = instanceVerbsFor(
      instance,
      supports: (method) => capabilities?.supports(method) == true,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(instance.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              _Detail(label: l10n.appsLabelState, value: instance.status),
              _Detail(
                label: l10n.appsInstanceLabelImage,
                value:
                    instance.imageDescription ?? l10n.appsInstanceServerDefault,
              ),
              _Detail(
                label: l10n.appsInstanceLabelCpu,
                value: instance.cpu ?? l10n.appsInstanceServerDefault,
              ),
              _Detail(
                label: l10n.appsInstanceLabelMemory,
                value: instance.memoryBytes == null
                    ? l10n.appsInstanceServerDefault
                    : l10n.appsMemoryMiB(
                        instance.memoryBytes! ~/ (1024 * 1024),
                      ),
              ),
              _Detail(
                label: l10n.appsInstanceLabelPool,
                value: instance.storagePool ?? l10n.appsInstanceServerDefault,
              ),
              _Detail(
                label: l10n.appsInstanceLabelRootDisk,
                value: instance.rootDiskSizeGiB == null
                    ? l10n.appsInstanceServerDefault
                    : '${instance.rootDiskSizeGiB} GiB',
              ),
              _Detail(
                label: l10n.appsLabelAutostart,
                value: instance.autostart
                    ? l10n.appsEnabled
                    : l10n.appsDisabled,
              ),
              _Detail(
                label: l10n.appsInstanceLabelPrivileged,
                value: instance.privileged
                    ? l10n.appsEnabled
                    : l10n.appsDisabled,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.appsInstanceLabelDevices,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              if (_loadingDevices)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (_devices == null || _devices!.isEmpty)
                Text(
                  l10n.appsInstanceDevicesEmpty,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                for (final device in _devices!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(_deviceIcon(device.deviceType)),
                    title: Text(
                      '${device.name} · ${l10n.appDeviceType(device.deviceType)}',
                    ),
                    subtitle: Text(
                      device.readOnly
                          ? l10n.appsInstanceDeviceManaged
                          : device.description ?? '',
                    ),
                  ),
              const SizedBox(height: 18),
              if (verbs.isNotEmpty)
                InstanceLifecycleControls(
                  name: instance.name,
                  kind: instance.isVirtualMachine
                      ? l10n.appsInstanceKindVm
                      : l10n.appsInstanceKindContainer,
                  running: instance.isRunning,
                  busyKey: 'virt:${instance.id}',
                  supportedVerbs: verbs,
                  onInvoke: _control,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (capabilities?.supports('virt.instance.update') == true)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _edit,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.appsEdit),
                      ),
                    ),
                  if (capabilities?.supports('virt.instance.delete') ==
                      true) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.appsInstanceDeleteAction),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _deviceIcon(String type) => switch (type) {
    'NIC' => Icons.lan_outlined,
    'DISK' => Icons.storage_rounded,
    'GPU' => Icons.memory_rounded,
    'USB' => Icons.usb_rounded,
    'PCI' => Icons.developer_board_rounded,
    'CDROM' => Icons.album_outlined,
    'PROXY' => Icons.swap_horiz_rounded,
    _ => Icons.settings_input_component_rounded,
  };

  Future<void> _control(InstanceVerb verb) async {
    final l10n = AppLocalizations.of(context);
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .controlVirtInstance(widget.instance.id, verb);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.appsOperationFailed
              : l10n.appsInstanceUpdated(widget.instance.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _edit() async {
    final l10n = AppLocalizations.of(context);
    final next = await showModalBottomSheet<VirtInstanceConfiguration>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => EditInstanceSheet(instance: widget.instance),
    );
    if (next == null || !mounted) return;
    if (next.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.appsInstanceNoChanges)));
      return;
    }
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateVirtInstance(widget.instance.id, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.appsOperationFailed
              : l10n.appsInstanceUpdated(widget.instance.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    // Deleting an instance destroys its root disk, so this is critical rather
    // than high impact: the user types the name before it can proceed.
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.appsInstanceDeleteTitle(widget.instance.name),
      server: serverName,
      target: widget.instance.name,
      actionLabel: l10n.appsInstanceDeleteAction,
      impact: MutationImpact.critical,
      confirmationText: widget.instance.name,
      consequences: [
        ImpactDetail(
          icon: Icons.delete_forever_rounded,
          text: l10n.appsInstanceDeleteConsequenceDisk,
        ),
        if (widget.instance.isRunning)
          ImpactDetail(
            icon: Icons.stop_circle_outlined,
            text: l10n.appsInstanceDeleteConsequenceRunning,
          ),
      ],
    );
    if (!confirmed || !mounted) return;
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .deleteVirtInstance(widget.instance.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.appsOperationFailed
              : l10n.appsInstanceDeleteRequested(widget.instance.name),
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null && mounted) Navigator.pop(context);
  }
}

/// Edits the mutable fields of an existing instance.
///
/// Returns a configuration carrying only the fields the user changed, because
/// `virt.instance.update` merges a partial object and sending everything would
/// overwrite values TrueDock does not surface.
class EditInstanceSheet extends StatefulWidget {
  const EditInstanceSheet({required this.instance, super.key});

  final VirtInstance instance;

  @override
  State<EditInstanceSheet> createState() => _EditInstanceSheetState();
}

class _EditInstanceSheetState extends State<EditInstanceSheet> {
  late final TextEditingController _cpu;
  late final TextEditingController _memory;
  late final TextEditingController _rootDisk;
  late bool _autostart;
  late bool _privileged;
  List<VirtInstanceValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _cpu = TextEditingController(text: widget.instance.cpu ?? '');
    _memory = TextEditingController(
      text: widget.instance.memoryBytes == null
          ? ''
          : '${widget.instance.memoryBytes! ~/ (1024 * 1024)}',
    );
    _rootDisk = TextEditingController(
      text: widget.instance.rootDiskSizeGiB?.toString() ?? '',
    );
    _autostart = widget.instance.autostart;
    _privileged = widget.instance.privileged;
  }

  @override
  void dispose() {
    _cpu.dispose();
    _memory.dispose();
    _rootDisk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.appsInstanceEditTitle(widget.instance.name),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _cpu,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceLabelCpu,
                  helperText: l10n.appsInstanceCpuHelper,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _memory,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceMemoryLabel,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _rootDisk,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceRootDiskLabel,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autostart,
                onChanged: (value) => setState(() => _autostart = value),
                title: Text(l10n.appsInstanceAutostart),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _privileged,
                onChanged: (value) => setState(() => _privileged = value),
                title: Text(l10n.appsInstanceLabelPrivileged),
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    instanceValidationMessage(l10n, issue),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              // Flexible children rather than natural widths: "Save changes"
              // plus Cancel overflows a narrow phone at a 2x text scale.
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
    final instance = widget.instance;
    final cpu = _cpu.text.trim();
    final memory = int.tryParse(_memory.text.trim());
    final rootDisk = int.tryParse(_rootDisk.text.trim());
    final currentMemoryMiB = instance.memoryBytes == null
        ? null
        : instance.memoryBytes! ~/ (1024 * 1024);

    // Emit only what actually changed, so an untouched field is never resent.
    final configuration = VirtInstanceConfiguration(
      cpu: cpu == (instance.cpu ?? '') ? null : cpu,
      memoryMiB: memory == currentMemoryMiB ? null : memory,
      autostart: _autostart == instance.autostart ? null : _autostart,
      privileged: _privileged == instance.privileged ? null : _privileged,
      rootDiskSizeGiB: rootDisk == instance.rootDiskSizeGiB ? null : rootDisk,
    );
    final issues = configuration.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, configuration);
  }
}

/// Collects a new container instance.
class CreateInstanceSheet extends StatefulWidget {
  const CreateInstanceSheet({
    required this.images,
    this.storagePool,
    super.key,
  });

  final List<VirtImageChoice> images;
  final String? storagePool;

  @override
  State<CreateInstanceSheet> createState() => _CreateInstanceSheetState();
}

class _CreateInstanceSheetState extends State<CreateInstanceSheet> {
  final _name = TextEditingController();
  final _cpu = TextEditingController();
  final _memory = TextEditingController();
  final _rootDisk = TextEditingController();
  String? _image;
  var _autostart = true;
  List<VirtInstanceValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _image = widget.images.isEmpty ? null : widget.images.first.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _cpu.dispose();
    _memory.dispose();
    _rootDisk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.appsInstanceCreateTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceNameLabel,
                  helperText: l10n.appsInstanceNameHelper,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              TrueDockDropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                initialSelection: _image,
                label: Text(l10n.appsInstanceImageLabel),
                enableFilter: true,
                requestFocusOnTap: true,
                // The default trailing button ships without a semantic label,
                // so a screen reader announces an unnamed tappable control.
                trailingIcon: Semantics(
                  label: l10n.appsInstanceImagePickerHint,
                  button: true,
                  child: const Icon(Icons.arrow_drop_down),
                ),
                selectedTrailingIcon: Semantics(
                  label: l10n.appsInstanceImagePickerHint,
                  button: true,
                  child: const Icon(Icons.arrow_drop_up),
                ),
                dropdownMenuEntries: [
                  for (final image in widget.images)
                    DropdownMenuEntry(value: image.id, label: image.label),
                ],
                onSelected: (value) => setState(() => _image = value),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cpu,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceLabelCpu,
                  helperText: l10n.appsInstanceCpuHelper,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _memory,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceMemoryLabel,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _rootDisk,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.appsInstanceRootDiskLabel,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autostart,
                onChanged: (value) => setState(() => _autostart = value),
                title: Text(l10n.appsInstanceAutostart),
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    instanceValidationMessage(l10n, issue),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              // The action label is long in some locales, and an icon button
              // plus Cancel overflows a narrow phone at large text sizes.
              // Flexible children absorb that instead of clipping.
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionCancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        l10n.appsInstanceCreate,
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
    final cpu = _cpu.text.trim();
    final configuration = VirtInstanceCreateConfiguration(
      name: _name.text,
      image: _image ?? '',
      cpu: cpu.isEmpty ? null : cpu,
      memoryMiB: int.tryParse(_memory.text.trim()),
      autostart: _autostart,
      storagePool: widget.storagePool,
      rootDiskSizeGiB: int.tryParse(_rootDisk.text.trim()),
    );
    final issues = configuration.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, configuration);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
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
