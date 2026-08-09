import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_target_extent_configuration.dart';
import 'storage_localizations.dart';

class IscsiTargetExtentSheet extends StatefulWidget {
  const IscsiTargetExtentSheet({
    required this.targets,
    required this.extents,
    this.existingAssociation,
    super.key,
  });

  final List<IscsiTarget> targets;
  final List<IscsiExtent> extents;
  final IscsiTargetExtent? existingAssociation;

  @override
  State<IscsiTargetExtentSheet> createState() => _IscsiTargetExtentSheetState();
}

class _IscsiTargetExtentSheetState extends State<IscsiTargetExtentSheet> {
  final _lunController = TextEditingController(text: '0');

  int? _targetId;
  int? _extentId;
  bool _automaticLun = true;
  bool _reviewing = false;
  Map<String, IscsiTargetExtentValidationCode> _errors = const {};

  bool get _editing => widget.existingAssociation != null;

  IscsiTarget? get _selectedTarget =>
      _firstWhereOrNull(widget.targets, (target) => target.id == _targetId);

  IscsiExtent? get _selectedExtent =>
      _firstWhereOrNull(widget.extents, (extent) => extent.id == _extentId);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAssociation;
    if (existing == null) {
      _targetId = widget.targets.firstOrNull?.id;
      _extentId = widget.extents.firstOrNull?.id;
      return;
    }

    _targetId = widget.targets.any((target) => target.id == existing.targetId)
        ? existing.targetId
        : null;
    _extentId = widget.extents.any((extent) => extent.id == existing.extentId)
        ? existing.extentId
        : null;
    _automaticLun = false;
    _lunController.text = existing.lunId?.toString() ?? '';
  }

  @override
  void dispose() {
    _lunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
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
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.device_hub_outlined,
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reviewing
                              ? l10n.storageIscsiTeReviewTitle
                              : _editing
                              ? l10n.storageIscsiTeEditTitle
                              : l10n.storageIscsiTeNewTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.storageIscsiTeSubtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageIscsiTeClose,
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
                      label: Text(l10n.storageIscsiTeBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageIscsiTeCancel),
                    ),
                  const Spacer(),
                  Flexible(
                    child: FilledButton.icon(
                      onPressed: _reviewing ? _submit : _review,
                      icon: Icon(
                        _reviewing
                            ? _editing
                                  ? Icons.save_outlined
                                  : Icons.add_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _reviewing
                            ? _editing
                                  ? l10n.storageIscsiTeSaveChanges
                                  : l10n.storageIscsiTeCreateAssociation
                            : l10n.storageIscsiTeReview,
                        maxLines: 1,
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

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        TrueDockDropdownButtonFormField<int>(
          initialValue: _targetId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiTeTargetLabel,
            helperText: l10n.storageIscsiTeTargetHelper,
            errorText: _errors['target'] != null
                ? l10n.iscsiTargetExtentValidationMessage(_errors['target']!)
                : null,
            prefixIcon: const Icon(Icons.hub_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final target in widget.targets)
              DropdownMenuItem(
                value: target.id,
                child: Text(
                  _targetLabel(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() {
            _targetId = value;
            _errors = const {};
          }),
        ),
        const SizedBox(height: 14),
        TrueDockDropdownButtonFormField<int>(
          initialValue: _extentId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiTeExtentLabel,
            helperText: l10n.storageIscsiTeExtentHelper,
            errorText: _errors['extent'] != null
                ? l10n.iscsiTargetExtentValidationMessage(_errors['extent']!)
                : null,
            prefixIcon: const Icon(Icons.storage_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final extent in widget.extents)
              DropdownMenuItem(
                value: extent.id,
                child: Text(
                  _extentLabel(extent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() {
            _extentId = value;
            _errors = const {};
          }),
        ),
        const SizedBox(height: 14),
        if (!_editing)
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(l10n.storageIscsiTeAutoLunTitle),
            subtitle: Text(l10n.storageIscsiTeAutoLunSubtitle),
            value: _automaticLun,
            onChanged: (value) => setState(() {
              _automaticLun = value;
              _errors = const {};
            }),
          ),
        if (!_automaticLun) ...[
          if (!_editing) const SizedBox(height: 6),
          TextField(
            controller: _lunController,
            keyboardType: TextInputType.number,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.storageIscsiTeLunIdLabel,
              helperText: _editing
                  ? l10n.storageIscsiTeLunIdHelperEdit
                  : l10n.storageIscsiTeLunIdHelperCreate,
              errorText: _errors['lunid'] != null
                  ? l10n.iscsiTargetExtentValidationMessage(_errors['lunid']!)
                  : null,
              prefixIcon: const Icon(Icons.numbers_rounded),
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errors.isNotEmpty) setState(() => _errors = const {});
            },
          ),
        ],
        if (_selectedExtent case final extent?) ...[
          const SizedBox(height: 14),
          _ExtentExposureNotices(extent: extent),
        ],
        if (_editing &&
            (_selectedTarget == null || _selectedExtent == null)) ...[
          const SizedBox(height: 14),
          _AssociationNotice(
            message: l10n.storageIscsiTeMissingResourcesNotice,
            warning: true,
          ),
        ],
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context);
    final target = _selectedTarget!;
    final extent = _selectedExtent!;
    return ListView(
      children: [
        _AssociationReviewCard(
          rows: [
            (l10n.storageIscsiTeReviewTarget, _targetLabel(target)),
            (l10n.storageIscsiTeReviewExtent, _extentLabel(extent)),
            (
              l10n.storageIscsiTeReviewLunId,
              _configuration.lunId?.toString() ??
                  l10n.storageIscsiTeReviewLunIdAutomatic,
            ),
            (
              l10n.storageIscsiTeReviewAccess,
              extent.readOnly
                  ? l10n.storageIscsiTeReviewAccessReadOnly
                  : l10n.storageIscsiTeReviewAccessReadWrite,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          l10n.storageIscsiTeImpactTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _AssociationNotice(
          message: _editing
              ? l10n.storageIscsiTeImpactNoticeEdit
              : l10n.storageIscsiTeImpactNoticeCreate,
          warning: true,
        ),
        const SizedBox(height: 10),
        _ExtentExposureNotices(extent: extent),
      ],
    );
  }

  IscsiTargetExtentConfiguration get _configuration =>
      IscsiTargetExtentConfiguration(
        targetId: _targetId ?? -1,
        extentId: _extentId ?? -1,
        lunId: _automaticLun ? null : int.tryParse(_lunController.text.trim()),
      );

  void _review() {
    final configuration = _configuration;
    final errors = configuration.validate(
      availableTargetIds: widget.targets.map((target) => target.id).toList(),
      availableExtentIds: widget.extents.map((extent) => extent.id).toList(),
    );
    if (!_automaticLun) {
      final lunText = _lunController.text.trim();
      final lunId = int.tryParse(lunText);
      if (lunText.isEmpty) {
        errors['lunid'] = IscsiTargetExtentValidationCode.lunidEmpty;
      } else if (lunId == null) {
        errors['lunid'] = IscsiTargetExtentValidationCode.lunidWholeNumber;
      } else if (lunId < 0) {
        errors['lunid'] = IscsiTargetExtentValidationCode.lunidNegative;
      }
    }

    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _configuration);
}

class _ExtentExposureNotices extends StatelessWidget {
  const _ExtentExposureNotices({required this.extent});

  final IscsiExtent extent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _AssociationNotice(
          message: extent.readOnly
              ? l10n.storageIscsiTeExposureReadOnly
              : l10n.storageIscsiTeExposureReadWrite,
          warning: !extent.readOnly,
        ),
        if (!extent.enabled) ...[
          const SizedBox(height: 10),
          _AssociationNotice(
            message: l10n.storageIscsiTeExtentDisabledNotice,
            warning: true,
          ),
        ],
        if (extent.locked) ...[
          const SizedBox(height: 10),
          _AssociationNotice(
            message: l10n.storageIscsiTeExtentLockedNotice,
            warning: true,
          ),
        ],
      ],
    );
  }
}

class _AssociationReviewCard extends StatelessWidget {
  const _AssociationReviewCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
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
          ),
      ],
    ),
  );
}

class _AssociationNotice extends StatelessWidget {
  const _AssociationNotice({required this.message, this.warning = false});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: warning
                ? colors.onErrorContainer
                : colors.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _targetLabel(IscsiTarget target) {
  final alias = target.alias?.trim();
  return alias == null || alias.isEmpty
      ? target.name
      : '$alias — ${target.name}';
}

String _extentLabel(IscsiExtent extent) =>
    '${extent.name} — ${extent.backingStore}';

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}
