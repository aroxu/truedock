import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import 'vm_device_localizations.dart';
import '../domain/vm_device.dart';

/// Lists the devices attached to a virtual machine and lets the user add or
/// remove them. Device edits are intentionally limited to the common disk
/// size, NIC, and display cases; the raw attribute editor is not exposed in
/// this release. Deletions are returned to the caller for confirmation.
class VmDeviceSheet extends StatefulWidget {
  const VmDeviceSheet({
    required this.devices,
    required this.canCreate,
    required this.canDelete,
    required this.onAddDevice,
    required this.onDeleteDevice,
    required this.canEdit,
    required this.onEditDevice,
    super.key,
  });

  final List<VmDevice> devices;
  final bool canCreate;
  final bool canDelete;
  final bool canEdit;

  /// Opens the add-device form and returns the chosen configuration.
  final Future<VmDeviceConfiguration?> Function() onAddDevice;

  /// Confirms and deletes the device. Returns true when the caller carried
  /// out the deletion.
  final Future<bool> Function(VmDevice device) onDeleteDevice;

  /// Opens the edit form for [device] and applies the result. Returns true
  /// when the caller carried out the update.
  final Future<bool> Function(VmDevice device) onEditDevice;

  @override
  State<VmDeviceSheet> createState() => _VmDeviceSheetState();
}

class _VmDeviceSheetState extends State<VmDeviceSheet> {
  List<VmDevice> _devices = const [];

  @override
  void initState() {
    super.initState();
    _devices = widget.devices;
  }

  @override
  void didUpdateWidget(covariant VmDeviceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devices != widget.devices) {
      _devices = widget.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.sysVmDevicesTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.sysVmDevicesSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.sysVmDevicesNone,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _deviceIcon(device.type, theme),
                      title: Text(l10n.vmDeviceTypeLabel(device.type)),
                      subtitle: Text(l10n.vmDeviceSummary(device)),
                      trailing: (widget.canEdit || widget.canDelete)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.canEdit)
                                  IconButton(
                                    tooltip: l10n.sysVmDeviceEditTooltip,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      // The caller reloads the device list, so
                                      // the sheet closes rather than showing a
                                      // guess at the server's new state.
                                      await widget.onEditDevice(device);
                                    },
                                  ),
                                if (widget.canDelete)
                                  IconButton(
                                    tooltip: l10n.sysVmDeviceRemoveTooltip,
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      final did = await widget.onDeleteDevice(
                                        device,
                                      );
                                      if (did) {
                                        setState(() {
                                          _devices = _devices
                                              .where((d) => d.id != device.id)
                                              .toList(growable: false);
                                        });
                                      }
                                    },
                                  ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (widget.canCreate)
              FilledButton.icon(
                onPressed: () async {
                  final configuration = await widget.onAddDevice();
                  if (configuration == null) return;
                  // The caller refreshes the device list; we just close the
                  // add form. The parent will reload devices and reopen.
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.sysVmDeviceAddAction),
              ),
          ],
        ),
      ),
    );
  }

  Icon _deviceIcon(VmDeviceType type, ThemeData theme) {
    switch (type) {
      case VmDeviceType.disk:
        return Icon(Icons.storage_rounded, color: theme.colorScheme.primary);
      case VmDeviceType.cdrom:
        return Icon(Icons.album_outlined, color: theme.colorScheme.primary);
      case VmDeviceType.nic:
        return Icon(Icons.lan_outlined, color: theme.colorScheme.tertiary);
      case VmDeviceType.display:
        return Icon(Icons.monitor_outlined, color: theme.colorScheme.tertiary);
      case VmDeviceType.memory:
        return Icon(Icons.memory_outlined, color: theme.colorScheme.secondary);
      default:
        return Icon(Icons.memory_rounded, color: theme.colorScheme.primary);
    }
  }
}

/// A form for adding a new VM device, or editing an existing one when
/// [existing] is supplied. Only the common disk, CD-ROM, and NIC fields are
/// surfaced; every other attribute on an edited device is preserved so an edit
/// cannot silently drop configuration the form does not understand.
class VmDeviceAddSheet extends StatefulWidget {
  const VmDeviceAddSheet({this.existing, super.key});

  /// The device being edited, or null when adding a new one.
  final VmDevice? existing;

  @override
  State<VmDeviceAddSheet> createState() => _VmDeviceAddSheetState();
}

class _VmDeviceAddSheetState extends State<VmDeviceAddSheet> {
  VmDeviceType _type = VmDeviceType.disk;
  final _pathController = TextEditingController();
  final _sizeController = TextEditingController();
  final _macController = TextEditingController();
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;
    _type = existing.type;
    final attributes = existing.attributes;
    final path = attributes['path'];
    if (path is String) _pathController.text = path;
    final size = attributes['size'];
    if (size is num) _sizeController.text = size.toInt().toString();
    final mac = attributes['mac'];
    if (mac is String) _macController.text = mac;
  }

  @override
  void dispose() {
    _pathController.dispose();
    _sizeController.dispose();
    _macController.dispose();
    super.dispose();
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
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing
                    ? l10n.sysVmDeviceEditTitle
                    : l10n.sysVmDeviceAddTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    TrueDockDropdownButtonFormField<VmDeviceType>(
                      initialValue: _type,
                      decoration: InputDecoration(
                        labelText: l10n.sysVmDeviceTypeLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final t in VmDeviceType.values)
                          if (t != VmDeviceType.other)
                            DropdownMenuItem(
                              value: t,
                              child: Text(l10n.vmDeviceTypeLabel(t)),
                            ),
                      ],
                      onChanged: (t) {
                        if (t != null) setState(() => _type = t);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (_type == VmDeviceType.disk ||
                        _type == VmDeviceType.cdrom) ...[
                      TextField(
                        controller: _pathController,
                        decoration: InputDecoration(
                          labelText: l10n.sysVmDevicePathLabel,
                          prefixIcon: const Icon(Icons.folder_outlined),
                          helperText: l10n.sysVmDevicePathHelper,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_type == VmDeviceType.disk)
                        TextField(
                          controller: _sizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.sysVmDeviceSizeLabel,
                            prefixIcon: const Icon(Icons.storage_outlined),
                            helperText: l10n.sysVmDeviceSizeHelper,
                          ),
                        ),
                    ] else if (_type == VmDeviceType.nic) ...[
                      TextField(
                        controller: _macController,
                        decoration: InputDecoration(
                          labelText: l10n.sysVmDeviceMacLabel,
                          prefixIcon: const Icon(Icons.lan_outlined),
                          helperText: l10n.sysVmDeviceMacHelper,
                        ),
                      ),
                    ] else if (_type == VmDeviceType.display) ...[
                      _InfoNotice(message: l10n.sysVmDeviceDisplayNotice),
                    ] else ...[
                      _InfoNotice(
                        message: l10n.sysVmDeviceDefaultNotice(
                          l10n.vmDeviceTypeLabel(_type),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionCancel),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(
                      _isEditing ? Icons.save_outlined : Icons.add_rounded,
                    ),
                    label: Text(
                      _isEditing
                          ? l10n.sysVmDeviceSaveAction
                          : l10n.sysVmDeviceAddAction,
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
    // Start from the existing attributes when editing so keys the form does
    // not surface (display ports, PCI slots, boot order) survive the update.
    // TrueNAS replaces the attribute set, so dropping them here would silently
    // reset configuration the user never touched.
    final attributes = <String, Object?>{...?widget.existing?.attributes};
    switch (_type) {
      case VmDeviceType.disk:
        final path = _pathController.text.trim();
        if (path.isEmpty) {
          setState(
            () => _error = AppLocalizations.of(
              context,
            ).sysVmDeviceErrorPathRequired,
          );
          return;
        }
        attributes['path'] = path;
        final size = int.tryParse(_sizeController.text);
        if (size != null && size > 0) attributes['size'] = size;
      case VmDeviceType.cdrom:
        attributes['path'] = _pathController.text.trim().isEmpty
            ? null
            : _pathController.text.trim();
      case VmDeviceType.nic:
        final mac = _macController.text.trim();
        if (mac.isNotEmpty) {
          attributes['mac'] = mac;
        } else {
          // Clearing the field asks TrueNAS to auto-generate a MAC again.
          attributes.remove('mac');
        }
      default:
        break;
    }
    Navigator.of(
      context,
    ).pop(VmDeviceConfiguration(dtype: _type, attributes: attributes));
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
