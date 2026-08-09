import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_extent_configuration.dart';
import 'storage_localizations.dart';

class IscsiExtentSheet extends StatefulWidget {
  const IscsiExtentSheet({
    required this.diskChoices,
    this.existingExtent,
    super.key,
  });

  final Map<String, String> diskChoices;
  final IscsiExtent? existingExtent;

  @override
  State<IscsiExtentSheet> createState() => _IscsiExtentSheetState();
}

class _IscsiExtentSheetState extends State<IscsiExtentSheet> {
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final _pathController = TextEditingController();
  final _fileSizeController = TextEditingController();
  final _availableThresholdController = TextEditingController();
  final _serialController = TextEditingController();
  final _productIdController = TextEditingController();

  late IscsiExtentType _type;
  String? _disk;
  late int _blockSize;
  late IscsiExtentRpm _rpm;
  late bool _physicalBlockSize;
  late bool _insecureTpc;
  late bool _xen;
  late bool _readOnly;
  late bool _enabled;
  bool _reviewing = false;
  Map<String, IscsiExtentValidationCode> _errors = const {};

  bool get _editing => widget.existingExtent != null;

  bool get _oldDiskIsUnavailable {
    final extent = widget.existingExtent;
    return extent != null &&
        IscsiExtentTypeApi.fromApi(extent.type) == IscsiExtentType.disk &&
        extent.disk != null &&
        !widget.diskChoices.containsKey(extent.disk);
  }

  bool get _backingChanged {
    final extent = widget.existingExtent;
    if (extent == null) return false;
    final oldType = IscsiExtentTypeApi.fromApi(extent.type);
    return oldType != _type ||
        (_type == IscsiExtentType.disk
            ? extent.disk != _disk
            : extent.path != _trimmedOrNull(_pathController.text));
  }

  @override
  void initState() {
    super.initState();
    final configuration = widget.existingExtent == null
        ? IscsiExtentConfiguration.defaults()
        : IscsiExtentConfiguration.fromExtent(widget.existingExtent!);
    _nameController.text = configuration.name;
    _commentController.text = configuration.comment;
    _pathController.text = configuration.path ?? '';
    _fileSizeController.text = configuration.fileSize.toString();
    _availableThresholdController.text =
        configuration.availableThreshold?.toString() ?? '';
    _serialController.text = configuration.serial ?? '';
    _productIdController.text = configuration.productId ?? '';
    _type = configuration.type;
    _disk = widget.diskChoices.containsKey(configuration.disk)
        ? configuration.disk
        : null;
    _blockSize = configuration.blockSize;
    _rpm = configuration.rpm;
    _physicalBlockSize = configuration.physicalBlockSize;
    _insecureTpc = configuration.insecureTpc;
    _xen = configuration.xen;
    _readOnly = configuration.readOnly;
    _enabled = configuration.enabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    _pathController.dispose();
    _fileSizeController.dispose();
    _availableThresholdController.dispose();
    _serialController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
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
                    backgroundColor: colors.tertiaryContainer,
                    child: Icon(
                      _reviewing
                          ? Icons.fact_check_outlined
                          : Icons.storage_outlined,
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
                              ? l10n.storageIscsiExtentReviewTitle
                              : _editing
                              ? l10n.storageIscsiExtentEditTitle
                              : l10n.storageIscsiExtentNewTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          l10n.storageIscsiExtentSubtitle,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.storageIscsiExtentClose,
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
                      label: Text(l10n.storageIscsiExtentBack),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageIscsiExtentCancel),
                    ),
                  const Spacer(),
                  FilledButton.icon(
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
                                ? l10n.storageIscsiExtentSaveChanges
                                : l10n.storageIscsiExtentCreateExtent
                          : l10n.storageIscsiExtentReview,
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
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiExtentNameLabel,
            helperText: l10n.storageIscsiExtentNameHelper,
            errorText: _errors['name'] != null
                ? l10n.iscsiExtentValidationMessage(_errors['name']!)
                : null,
            prefixIcon: const Icon(Icons.badge_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiExtentCommentLabel,
            helperText: l10n.storageIscsiExtentCommentHelper,
            prefixIcon: const Icon(Icons.notes_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.storageIscsiExtentBackingStore,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        SegmentedButton<IscsiExtentType>(
          segments: [
            ButtonSegment(
              value: IscsiExtentType.disk,
              icon: const Icon(Icons.disc_full_outlined),
              label: Text(l10n.storageIscsiExtentTypeDisk),
            ),
            ButtonSegment(
              value: IscsiExtentType.file,
              icon: const Icon(Icons.insert_drive_file_outlined),
              label: Text(l10n.storageIscsiExtentTypeFile),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (selection) => setState(() {
            _type = selection.single;
            _errors = const {};
          }),
        ),
        const SizedBox(height: 12),
        if (_type == IscsiExtentType.disk) ...[
          TrueDockDropdownButtonFormField<String>(
            key: const Key('extent-disk-field'),
            initialValue: _disk,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.storageIscsiExtentDiskLabel,
              helperText: l10n.storageIscsiExtentDiskHelper,
              errorText: _errors['disk'] != null
                  ? l10n.iscsiExtentValidationMessage(_errors['disk']!)
                  : null,
              prefixIcon: const Icon(Icons.dns_outlined),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final choice in widget.diskChoices.entries)
                DropdownMenuItem(value: choice.key, child: Text(choice.value)),
            ],
            onChanged: (value) => setState(() => _disk = value),
          ),
          if (widget.diskChoices.isEmpty) ...[
            const SizedBox(height: 10),
            _ExtentNotice(
              message: l10n.storageIscsiExtentNoDiskChoices,
              error: true,
            ),
          ],
          if (_oldDiskIsUnavailable && _disk == null) ...[
            const SizedBox(height: 10),
            _ExtentNotice(
              message: l10n.storageIscsiExtentOldDiskUnavailableNotice(
                widget.existingExtent!.disk ?? '',
              ),
              error: true,
            ),
          ],
        ] else ...[
          TextField(
            key: const Key('extent-path-field'),
            controller: _pathController,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.storageIscsiExtentPathLabel,
              helperText: l10n.storageIscsiExtentPathHelper,
              errorText: _errors['path'] != null
                  ? l10n.iscsiExtentValidationMessage(_errors['path']!)
                  : null,
              prefixIcon: const Icon(Icons.route_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('extent-file-size-field'),
            controller: _fileSizeController,
            autocorrect: false,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.storageIscsiExtentFilesizeLabel,
              helperText: l10n.storageIscsiExtentFilesizeHelper,
              errorText: _errors['filesize'] != null
                  ? l10n.iscsiExtentValidationMessage(_errors['filesize']!)
                  : null,
              prefixIcon: const Icon(Icons.data_usage_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          _ExtentNotice(message: l10n.storageIscsiExtentFileAllocateNotice),
        ],
        if (_editing) ...[
          const SizedBox(height: 10),
          _ExtentNotice(
            message: l10n.storageIscsiExtentBackingChangeNotice,
            error: true,
          ),
        ],
        const SizedBox(height: 16),
        TrueDockDropdownButtonFormField<int>(
          key: const Key('extent-block-size-field'),
          initialValue: _blockSize,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiExtentBlocksizeLabel,
            errorText: _errors['blocksize'] != null
                ? l10n.iscsiExtentValidationMessage(_errors['blocksize']!)
                : null,
            prefixIcon: const Icon(Icons.grid_4x4_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final size in IscsiExtentConfiguration.supportedBlockSizes)
              DropdownMenuItem(
                value: size,
                child: Text(l10n.storageIscsiExtentReviewBlocksizeValue(size)),
              ),
          ],
          onChanged: (value) =>
              setState(() => _blockSize = value ?? _blockSize),
        ),
        const SizedBox(height: 12),
        TrueDockDropdownButtonFormField<IscsiExtentRpm>(
          key: const Key('extent-rpm-field'),
          initialValue: _rpm,
          decoration: InputDecoration(
            labelText: l10n.storageIscsiExtentRpmLabel,
            prefixIcon: const Icon(Icons.speed_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final rpm in IscsiExtentRpm.values)
              DropdownMenuItem(
                value: rpm,
                child: Text(l10n.iscsiExtentRpmLabel(rpm)),
              ),
          ],
          onChanged: (value) => setState(() => _rpm = value ?? _rpm),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: _readOnly,
          onChanged: (value) => setState(() => _readOnly = value),
          title: Text(l10n.storageIscsiExtentReadOnlyTitle),
          subtitle: Text(l10n.storageIscsiExtentReadOnlySubtitle),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          title: Text(l10n.storageIscsiExtentEnabledTitle),
          subtitle: Text(l10n.storageIscsiExtentEnabledSubtitle),
        ),
        ExpansionTile(
          key: const Key('extent-advanced-tile'),
          tilePadding: EdgeInsets.zero,
          title: Text(l10n.storageIscsiExtentAdvancedTitle),
          subtitle: Text(l10n.storageIscsiExtentAdvancedSubtitle),
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _physicalBlockSize,
              onChanged: (value) => setState(() => _physicalBlockSize = value),
              title: Text(l10n.storageIscsiExtentPhysicalBlockTitle),
              subtitle: Text(l10n.storageIscsiExtentPhysicalBlockSubtitle),
            ),
            TextField(
              key: const Key('extent-threshold-field'),
              controller: _availableThresholdController,
              autocorrect: false,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.storageIscsiExtentThresholdLabel,
                helperText: l10n.storageIscsiExtentThresholdHelper,
                errorText: _errors['avail_threshold'] != null
                    ? l10n.iscsiExtentValidationMessage(
                        _errors['avail_threshold']!,
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _insecureTpc,
              onChanged: (value) => setState(() => _insecureTpc = value),
              title: Text(l10n.storageIscsiExtentInsecureTpcTitle),
              subtitle: Text(l10n.storageIscsiExtentInsecureTpcSubtitle),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _xen,
              onChanged: (value) => setState(() => _xen = value),
              title: Text(l10n.storageIscsiExtentXenTitle),
              subtitle: Text(l10n.storageIscsiExtentXenSubtitle),
            ),
            TextField(
              key: const Key('extent-serial-field'),
              controller: _serialController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.storageIscsiExtentSerialLabel,
                helperText: l10n.storageIscsiExtentSerialHelper,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('extent-product-id-field'),
              controller: _productIdController,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.storageIscsiExtentProductIdLabel,
                helperText: l10n.storageIscsiExtentProductIdHelper,
                errorText: _errors['product_id'] != null
                    ? l10n.iscsiExtentValidationMessage(_errors['product_id']!)
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    final l10n = AppLocalizations.of(context);
    final configuration = _configuration;
    final backing = configuration.type == IscsiExtentType.disk
        ? widget.diskChoices[configuration.disk] ??
              configuration.disk ??
              l10n.storageIscsiExtentReviewNone
        : configuration.path ?? l10n.storageIscsiExtentReviewNone;
    return ListView(
      children: [
        _ExtentReviewCard(
          rows: [
            (l10n.storageIscsiExtentReviewName, configuration.name),
            (
              l10n.storageIscsiExtentReviewType,
              l10n.iscsiExtentTypeLabel(configuration.type),
            ),
            (l10n.storageIscsiExtentReviewBackingStore, backing),
            if (configuration.type == IscsiExtentType.file)
              (
                l10n.storageIscsiExtentReviewFilesize,
                l10n.storageIscsiExtentReviewFilesizeValue(
                  configuration.fileSize,
                ),
              ),
            (
              l10n.storageIscsiExtentReviewBlocksize,
              l10n.storageIscsiExtentReviewBlocksizeValue(
                configuration.blockSize,
              ),
            ),
            (
              l10n.storageIscsiExtentReviewSpeed,
              l10n.iscsiExtentRpmLabel(configuration.rpm),
            ),
            (
              l10n.storageIscsiExtentReviewReadOnly,
              l10n.storageIscsiExtentReviewYesNo(configuration.readOnly),
            ),
            (
              l10n.storageIscsiExtentReviewEnabled,
              l10n.storageIscsiExtentReviewYesNo(configuration.enabled),
            ),
            (
              l10n.storageIscsiExtentReviewPhysicalBlock,
              l10n.storageIscsiExtentReviewYesNo(
                configuration.physicalBlockSize,
              ),
            ),
            (
              l10n.storageIscsiExtentReviewThreshold,
              configuration.availableThreshold == null
                  ? l10n.storageIscsiExtentReviewThresholdNone
                  : l10n.storageIscsiExtentReviewThresholdValue(
                      configuration.availableThreshold!,
                    ),
            ),
            (
              l10n.storageIscsiExtentReviewInsecureTpc,
              l10n.storageIscsiExtentReviewYesNo(configuration.insecureTpc),
            ),
            (
              l10n.storageIscsiExtentReviewXen,
              l10n.storageIscsiExtentReviewYesNo(configuration.xen),
            ),
            (
              l10n.storageIscsiExtentReviewSerial,
              configuration.serial ??
                  l10n.storageIscsiExtentReviewSerialAutomatic,
            ),
            (
              l10n.storageIscsiExtentReviewProductId,
              configuration.productId ??
                  l10n.storageIscsiExtentReviewProductIdDefault,
            ),
            (
              l10n.storageIscsiExtentReviewComment,
              configuration.comment.isEmpty
                  ? l10n.storageIscsiExtentReviewNone
                  : configuration.comment,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_backingChanged) ...[
          _ExtentNotice(
            message: l10n.storageIscsiExtentBackingChangedNotice,
            error: true,
          ),
          const SizedBox(height: 12),
        ],
        if (configuration.type == IscsiExtentType.file) ...[
          _ExtentNotice(
            message: l10n.storageIscsiExtentFileAllocateReviewNotice(
              configuration.path ?? '',
              configuration.fileSize,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ExtentNotice(
          message: _editing
              ? l10n.storageIscsiExtentReviewNoticeEdit(
                  widget.existingExtent!.name,
                )
              : l10n.storageIscsiExtentReviewNoticeCreate,
        ),
      ],
    );
  }

  IscsiExtentConfiguration get _configuration => IscsiExtentConfiguration(
    name: _nameController.text.trim(),
    type: _type,
    disk: _type == IscsiExtentType.disk ? _disk : null,
    serial: _trimmedOrNull(_serialController.text),
    path: _type == IscsiExtentType.file
        ? _trimmedOrNull(_pathController.text)
        : null,
    fileSize: int.tryParse(_fileSizeController.text.trim()) ?? 0,
    blockSize: _blockSize,
    physicalBlockSize: _physicalBlockSize,
    availableThreshold: _availableThresholdController.text.trim().isEmpty
        ? null
        : int.tryParse(_availableThresholdController.text.trim()),
    comment: _commentController.text.trim(),
    insecureTpc: _insecureTpc,
    xen: _xen,
    rpm: _rpm,
    readOnly: _readOnly,
    enabled: _enabled,
    productId: _trimmedOrNull(_productIdController.text),
  );

  void _review() {
    final errors = <String, IscsiExtentValidationCode>{
      ..._configuration.validate(availableDiskChoices: widget.diskChoices),
    };
    if (_type == IscsiExtentType.file &&
        int.tryParse(_fileSizeController.text.trim()) == null) {
      errors['filesize'] = IscsiExtentValidationCode.fileSizeWholeNumber;
    }
    if (_availableThresholdController.text.trim().isNotEmpty &&
        int.tryParse(_availableThresholdController.text.trim()) == null) {
      errors['avail_threshold'] =
          IscsiExtentValidationCode.thresholdWholeNumber;
    }
    setState(() {
      _errors = errors;
      _reviewing = errors.isEmpty;
    });
  }

  void _submit() => Navigator.pop(context, _configuration);
}

class _ExtentReviewCard extends StatelessWidget {
  const _ExtentReviewCard({required this.rows});

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
                  width: 136,
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

class _ExtentNotice extends StatelessWidget {
  const _ExtentNotice({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: error ? colors.onErrorContainer : colors.onTertiaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
