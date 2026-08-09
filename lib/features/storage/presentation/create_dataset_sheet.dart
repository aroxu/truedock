import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';

import '../../actions/data/server_actions_repository.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../resources/domain/server_resources.dart';

/// Creates a filesystem dataset or a zvol.
///
/// The two are one sheet because they are the same TrueNAS call on the same
/// parent, but their payloads barely overlap: a filesystem takes a workload
/// optimization, while a volume takes a size and provisioning mode. Only the
/// fields belonging to the selected kind are ever shown or sent.

class CreateDatasetSheet extends ConsumerStatefulWidget {
  const CreateDatasetSheet({
    required this.pools,
    required this.datasets,
    super.key,
  });

  final List<StoragePool> pools;
  final List<Dataset> datasets;

  @override
  ConsumerState<CreateDatasetSheet> createState() => CreateDatasetSheetState();
}

class CreateDatasetSheetState extends ConsumerState<CreateDatasetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  late String _parent;
  DatasetShareType _shareType = DatasetShareType.generic;

  /// A zvol is a block device rather than a directory tree, so it takes a size
  /// instead of a workload optimization.
  bool _isVolume = false;
  bool _sparse = false;
  late AppLocalizations l10n;

  @override
  void initState() {
    super.initState();
    _parent = widget.pools.first.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final fullName = _nameController.text.trim().isEmpty
        ? '$_parent/…'
        : '$_parent/${_nameController.text.trim()}';
    final busy = ref
        .watch(serverActionControllerProvider)
        .isBusy('dataset:$fullName');
    final parents = {
      ...widget.pools.map((pool) => pool.name),
      ...widget.datasets
          .where((dataset) => dataset.type == 'FILESYSTEM' && !dataset.locked)
          .map((dataset) => dataset.name),
    }.toList(growable: false)..sort();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isVolume
                    ? l10n.datasetCreateVolume
                    : l10n.datasetCreateFilesystem,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isVolume
                    ? l10n.datasetVolumeDescription
                    : l10n.datasetFilesystemDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.folder_outlined),
                    label: Text(l10n.datasetTypeFilesystem),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: Text(l10n.datasetTypeVolume),
                  ),
                ],
                selected: {_isVolume},
                onSelectionChanged: busy
                    ? null
                    : (selection) =>
                          setState(() => _isVolume = selection.first),
              ),
              const SizedBox(height: 14),
              TrueDockDropdownButtonFormField<String>(
                initialValue: _parent,
                decoration: InputDecoration(
                  labelText: l10n.datasetParent,
                  prefixIcon: const Icon(Icons.account_tree_outlined),
                ),
                items: [
                  for (final parent in parents)
                    DropdownMenuItem(value: parent, child: Text(parent)),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _parent = value);
                      },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                enabled: !busy,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _isVolume
                      ? l10n.datasetVolumeName
                      : l10n.datasetName,
                  prefixIcon: const Icon(Icons.dataset_outlined),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) {
                    return _isVolume
                        ? l10n.datasetEnterVolumeName
                        : l10n.datasetEnterName;
                  }
                  if (name.contains('/')) {
                    return l10n.datasetUseParentForPaths;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Workload optimization is a filesystem concept; a zvol takes a
              // size instead, so the two are never shown together.
              if (_isVolume) ...[
                TextFormField(
                  controller: _sizeController,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.datasetSizeInGib,
                    prefixIcon: const Icon(Icons.straighten_rounded),
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    if (raw.isEmpty) return l10n.datasetEnterSizeInGib;
                    final size = num.tryParse(raw);
                    if (size == null || size <= 0) {
                      return l10n.datasetEnterSizePositive;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _sparse,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _sparse = value),
                  title: Text(l10n.datasetSparseThin),
                  subtitle: Text(l10n.datasetSparseSubtitle),
                ),
              ] else
                TrueDockDropdownButtonFormField<DatasetShareType>(
                  initialValue: _shareType,
                  decoration: InputDecoration(
                    labelText: l10n.datasetWorkloadOptimization,
                    prefixIcon: const Icon(Icons.tune_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: DatasetShareType.generic,
                      child: Text(l10n.datasetShareGeneric),
                    ),
                    DropdownMenuItem(
                      value: DatasetShareType.smb,
                      child: Text(l10n.datasetShareSmb),
                    ),
                    DropdownMenuItem(
                      value: DatasetShareType.nfs,
                      child: Text(l10n.datasetShareNfs),
                    ),
                    DropdownMenuItem(
                      value: DatasetShareType.multiprotocol,
                      child: Text(l10n.datasetShareMultiprotocol),
                    ),
                    DropdownMenuItem(
                      value: DatasetShareType.apps,
                      child: Text(l10n.datasetShareApps),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _shareType = value);
                        },
                ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy ? null : _create,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  busy
                      ? l10n.datasetCreating
                      : _isVolume
                      ? l10n.datasetCreateVolume
                      : l10n.datasetCreateFilesystem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fullName = '$_parent/${_nameController.text.trim()}';
    final controller = ref.read(serverActionControllerProvider.notifier);
    final receipt = _isVolume
        ? await controller.createVolume(
            fullName: fullName,
            // The field is in GiB because a byte count is unusable on a phone
            // keyboard; the API takes bytes.
            sizeBytes:
                (num.parse(_sizeController.text.trim()) * 1024 * 1024 * 1024)
                    .round(),
            sparse: _sparse,
          )
        : await controller.createDataset(
            fullName: fullName,
            shareType: _shareType,
          );
    if (!mounted) return;
    if (receipt != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(serverActionControllerProvider).errorMessage ??
                l10n.datasetOperationFailed,
          ),
        ),
      );
    }
  }
}
