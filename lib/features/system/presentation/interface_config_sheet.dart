import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'interface_config_localizations.dart';
import '../domain/interface_configuration.dart';

/// Editor for a network interface's addressing.
///
/// Returns the next [InterfaceConfiguration] after a review step. The caller
/// sends it to `interface.update` and then drives the network commit/checkin
/// workflow, because TrueNAS stages interface changes and reverts them unless
/// they are checked in inside the verification window.
class InterfaceConfigSheet extends StatefulWidget {
  const InterfaceConfigSheet({
    required this.baseline,
    this.dhcpOwnedByOtherInterface,
    super.key,
  });

  final InterfaceConfiguration baseline;

  /// Name of another interface that already uses DHCP, when one exists.
  /// Only one interface on the system may use DHCP, so the editor warns
  /// instead of letting the server reject the change later.
  final String? dhcpOwnedByOtherInterface;

  @override
  State<InterfaceConfigSheet> createState() => _InterfaceConfigSheetState();
}

class _InterfaceConfigSheetState extends State<InterfaceConfigSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _mtuController;

  late InterfaceConfiguration _configuration;
  bool _reviewing = false;
  Map<String, InterfaceValidationIssue> _errors = const {};

  @override
  void initState() {
    super.initState();
    _configuration = widget.baseline;
    _descriptionController = TextEditingController(
      text: widget.baseline.description,
    );
    _mtuController = TextEditingController(
      text: widget.baseline.mtu?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mtuController.dispose();
    super.dispose();
  }

  void _syncConfiguration() {
    final mtuText = _mtuController.text.trim();
    final parsedMtu = int.tryParse(mtuText);
    _configuration = _configuration.copyWith(
      description: _descriptionController.text.trim(),
      mtu: mtuText.isEmpty ? widget.baseline.mtu : (parsedMtu ?? 0),
    );
  }

  Future<void> _addAlias({required bool ipv6}) async {
    final alias = await showModalBottomSheet<InterfaceAlias>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _AliasEditorSheet(
        initialIpv6: ipv6,
        allowIpv4: !_configuration.ipv4Dhcp,
        allowIpv6: !_configuration.ipv6Auto,
      ),
    );
    if (alias == null) return;
    setState(() {
      _configuration = _configuration.copyWith(
        aliases: [..._configuration.aliases, alias],
      );
    });
  }

  Future<void> _editAlias(int index) async {
    final alias = await showModalBottomSheet<InterfaceAlias>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _AliasEditorSheet(
        existing: _configuration.aliases[index],
        allowIpv4:
            !_configuration.ipv4Dhcp || !_configuration.aliases[index].isIpv6,
        allowIpv6:
            !_configuration.ipv6Auto || _configuration.aliases[index].isIpv6,
      ),
    );
    if (alias == null) return;
    final aliases = [..._configuration.aliases];
    aliases[index] = alias;
    setState(() => _configuration = _configuration.copyWith(aliases: aliases));
  }

  void _removeAlias(int index) {
    final aliases = [..._configuration.aliases];
    if (index < 0 || index >= aliases.length) return;
    aliases.removeAt(index);
    setState(() => _configuration = _configuration.copyWith(aliases: aliases));
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
                      Icons.lan_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _reviewing
                          ? l10n.sysInterfaceReviewName(widget.baseline.name)
                          : l10n.sysInterfaceEditName(widget.baseline.name),
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
                      _reviewing
                          ? l10n.sysInterfaceStageChange
                          : l10n.actionReview,
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
    final dhcpOwner = widget.dhcpOwnedByOtherInterface;
    final visibleAliases = _configuration.aliases.indexed
        .where(
          (entry) => entry.$2.isIpv6
              ? !_configuration.ipv6Auto
              : !_configuration.ipv4Dhcp,
        )
        .toList(growable: false);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Notice(
          icon: Icons.bolt_rounded,
          message: l10n.sysInterfaceStagedNotice,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.sysInterfaceDescriptionLabel,
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.sysInterfaceAddressingTitle,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sysInterfaceUseDhcpTitle),
          subtitle: Text(l10n.sysInterfaceUseDhcpSubtitle),
          value: _configuration.ipv4Dhcp,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(ipv4Dhcp: value),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sysInterfaceUseIpv6AutoTitle),
          subtitle: Text(l10n.sysInterfaceUseIpv6AutoSubtitle),
          value: _configuration.ipv6Auto,
          onChanged: (value) => setState(
            () => _configuration = _configuration.copyWith(ipv6Auto: value),
          ),
        ),
        if (_configuration.ipv4Dhcp && dhcpOwner != null) ...[
          const SizedBox(height: 8),
          _Notice(
            icon: Icons.warning_amber_rounded,
            message: l10n.sysInterfaceDhcpConflict(dhcpOwner),
          ),
        ],
        const SizedBox(height: 12),
        Text(l10n.sysInterfaceStaticTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (visibleAliases.isEmpty)
          Text(l10n.sysInterfaceNoStatic)
        else
          for (final (visibleIndex, entry) in visibleAliases.indexed) ...[
            if (visibleIndex > 0) const SizedBox(height: 6),
            _AliasRow(
              alias: entry.$2,
              onEdit: () => _editAlias(entry.$1),
              onRemove: () => _removeAlias(entry.$1),
            ),
          ],
        if (_errors['aliases'] != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.interfaceValidationMessage(_errors['aliases']!),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _configuration.ipv4Dhcp
                  ? null
                  : () => _addAlias(ipv6: false),
              icon: const Icon(Icons.looks_4_outlined),
              label: Text(l10n.sysInterfaceAddIpv4Address),
            ),
            TextButton.icon(
              onPressed: _configuration.ipv6Auto
                  ? null
                  : () => _addAlias(ipv6: true),
              icon: const Icon(Icons.looks_6_outlined),
              label: Text(l10n.sysInterfaceAddIpv6Address),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _mtuController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.sysInterfaceMtuLabel,
            prefixIcon: const Icon(Icons.straighten_rounded),
            helperText: l10n.sysInterfaceMtuHelper,
            errorText: _errors['mtu'] == null
                ? null
                : l10n.interfaceValidationMessage(_errors['mtu']!),
          ),
        ),
      ],
    );
  }

  Widget _review(ThemeData theme, AppLocalizations l10n) {
    _syncConfiguration();
    final changed = _configuration.differsFrom(widget.baseline);
    final losesStatic =
        widget.baseline.aliases.any((alias) => !alias.isIpv6) &&
        _configuration.ipv4Dhcp &&
        !widget.baseline.ipv4Dhcp;
    final losesStaticIpv6 =
        widget.baseline.aliases.any((alias) => alias.isIpv6) &&
        _configuration.ipv6Auto &&
        !widget.baseline.ipv6Auto;
    final visibleAddresses = <String>[
      if (_configuration.ipv4Dhcp) l10n.sysInterfaceReviewAssignedByDhcp,
      for (final alias in _configuration.activeAliases) alias.label,
    ];
    final hasStaticIpv6 = _configuration.aliases.any((alias) => alias.isIpv6);
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
                label: l10n.sysInterfaceReviewInterface,
                value: _configuration.name,
              ),
              _ReviewRow(
                label: l10n.sysInterfaceReviewDescription,
                value: _configuration.description.isEmpty
                    ? l10n.sysInterfaceReviewNone
                    : _configuration.description,
              ),
              _ReviewRow(
                label: l10n.sysInterfaceReviewIpv4,
                value: _configuration.ipv4Dhcp
                    ? l10n.sysInterfaceReviewDhcp
                    : l10n.sysInterfaceReviewStatic,
              ),
              _ReviewRow(
                label: l10n.sysInterfaceReviewIpv6,
                value: _configuration.ipv6Auto
                    ? l10n.sysInterfaceReviewAutomatic
                    : hasStaticIpv6
                    ? l10n.sysInterfaceReviewStatic
                    : l10n.sysInterfaceReviewDisabled,
              ),
              _ReviewRow(
                label: l10n.sysInterfaceReviewAddresses,
                value: visibleAddresses.isEmpty
                    ? l10n.sysInterfaceReviewNone
                    : visibleAddresses.join('\n'),
              ),
              _ReviewRow(
                label: l10n.sysInterfaceReviewMtu,
                value:
                    _configuration.mtu?.toString() ??
                    l10n.sysInterfaceReviewMtuDefault,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!changed)
          _Notice(
            icon: Icons.info_outline_rounded,
            message: l10n.sysInterfaceNothingChanged,
          )
        else ...[
          _Notice(
            icon: Icons.warning_amber_rounded,
            message: l10n.sysInterfaceSessionDrop,
          ),
          if (losesStatic) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.link_off_rounded,
              message: l10n.sysInterfaceDhcpLosesRoute,
            ),
          ],
          if (losesStaticIpv6) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.link_off_rounded,
              message: l10n.sysInterfaceIpv6AutoLosesStatic,
            ),
          ],
        ],
      ],
    );
  }

  void _validate() {
    _syncConfiguration();
    final errors = validateInterfaceConfiguration(_configuration);
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

/// A single static address with edit and remove actions.
class _AliasRow extends StatelessWidget {
  const _AliasRow({
    required this.alias,
    required this.onEdit,
    required this.onRemove,
  });

  final InterfaceAlias alias;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(
            alias.isIpv6 ? Icons.looks_6_outlined : Icons.looks_4_outlined,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(alias.label)),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppLocalizations.of(
              context,
            ).sysInterfaceEditAddressTooltip,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            tooltip: AppLocalizations.of(
              context,
            ).sysInterfaceRemoveAddressTooltip,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Collects a single address/prefix pair.
class _AliasEditorSheet extends StatefulWidget {
  const _AliasEditorSheet({
    this.existing,
    this.initialIpv6 = false,
    this.allowIpv4 = true,
    this.allowIpv6 = true,
  });

  final InterfaceAlias? existing;
  final bool initialIpv6;
  final bool allowIpv4;
  final bool allowIpv6;

  @override
  State<_AliasEditorSheet> createState() => _AliasEditorSheetState();
}

class _AliasEditorSheetState extends State<_AliasEditorSheet> {
  late final TextEditingController _addressController;
  late final TextEditingController _netmaskController;
  late bool _ipv6;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ipv6 = widget.existing?.isIpv6 ?? widget.initialIpv6;
    _addressController = TextEditingController(
      text: widget.existing?.address ?? '',
    );
    _netmaskController = TextEditingController(
      text: widget.existing?.netmask.toString() ?? (_ipv6 ? '64' : '24'),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _netmaskController.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _addressController.text.trim();
    final netmask = int.tryParse(_netmaskController.text.trim());
    final maxPrefix = _ipv6 ? 128 : 32;
    if (!isValidIpAddress(address, ipv6: _ipv6)) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        ).sysInterfaceAliasErrorInvalid(_ipv6 ? 'IPv6' : 'IPv4'),
      );
      return;
    }
    if (netmask == null || netmask < 1 || netmask > maxPrefix) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        ).sysInterfaceAliasErrorPrefix(maxPrefix),
      );
      return;
    }
    Navigator.of(context).pop(
      InterfaceAlias(
        address: address,
        netmask: netmask,
        type: _ipv6 ? 'INET6' : 'INET',
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? l10n.sysInterfaceAddAddress
                        : l10n.sysInterfaceEditAddressTitle,
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
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                if (widget.allowIpv4 || widget.existing?.isIpv6 == false)
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.sysInterfaceIpv4Label),
                  ),
                if (widget.allowIpv6 || widget.existing?.isIpv6 == true)
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.sysInterfaceIpv6Label),
                  ),
              ],
              selected: {_ipv6},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => setState(() {
                _ipv6 = selection.first;
                _netmaskController.text = _ipv6 ? '64' : '24';
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _addressController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.sysInterfaceAddressLabel,
                prefixIcon: const Icon(Icons.numbers_rounded),
                hintText: _ipv6 ? 'fd00::10' : '192.168.1.10',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _netmaskController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.sysInterfacePrefixLabel,
                prefixIcon: const Icon(Icons.alt_route_rounded),
                helperText: _ipv6
                    ? l10n.sysInterfacePrefixHelperV6
                    : l10n.sysInterfacePrefixHelperV4,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.actionCancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.sysInterfaceSaveAddress),
                ),
              ],
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
