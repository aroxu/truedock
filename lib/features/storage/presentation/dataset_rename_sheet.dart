import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/dataset_configuration.dart';
import 'storage_localizations.dart';

/// Renames a dataset within its existing parent path.
///
/// Returns a validated [DatasetRenameRequest]; the caller runs the job. A
/// rename unmounts the dataset, so the sheet states that consequence before
/// the user confirms.
class DatasetRenameSheet extends StatefulWidget {
  const DatasetRenameSheet({required this.dataset, super.key});

  final Dataset dataset;

  @override
  State<DatasetRenameSheet> createState() => _DatasetRenameSheetState();
}

class _DatasetRenameSheetState extends State<DatasetRenameSheet> {
  final _controller = TextEditingController();
  bool _recursive = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.dataset.leafName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final parent = (widget.dataset.name.split('/')..removeLast()).join('/');
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.storageRenameTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(widget.dataset.name, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l10n.storageRenameNewNameLabel,
                prefixText: parent.isEmpty ? null : '$parent/',
                prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.storageRenameRecursiveTitle),
              subtitle: Text(l10n.storageRenameRecursiveSubtitle),
              value: _recursive,
              onChanged: (value) => setState(() => _recursive = value),
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.storageRenameNotice,
                  style: TextStyle(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.drive_file_rename_outline_rounded),
              label: Text(l10n.storageRenameAction),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    try {
      final request = DatasetRenameRequest.forDataset(
        widget.dataset,
        newLeafName: _controller.text,
        recursive: _recursive,
      );
      Navigator.of(context).pop(request);
    } on DatasetConfigurationException catch (error) {
      setState(
        () => _error = error.code != null
            ? AppLocalizations.of(
                context,
              ).datasetConfigurationMessage(error.code!)
            : error.message,
      );
    }
  }
}
