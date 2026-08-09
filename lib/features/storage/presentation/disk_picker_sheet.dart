import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import 'storage_localizations.dart';

/// Lets the user pick an available disk for a pool attach or replace.
///
/// Only disks that are not already part of a pool are selectable by default.
/// The caller passes the candidate list so the sheet stays free of repository
/// concerns; the picker is read-only and returns the chosen [StorageDisk.name]
/// (the devname TrueNAS expects for `pool.attach`/`pool.replace`).
class DiskPickerSheet extends StatefulWidget {
  const DiskPickerSheet({
    required this.candidates,
    required this.title,
    this.emptyMessage,
    super.key,
  });

  final List<StorageDisk> candidates;
  final String title;
  final String? emptyMessage;

  @override
  State<DiskPickerSheet> createState() => _DiskPickerSheetState();
}

class _DiskPickerSheetState extends State<DiskPickerSheet> {
  String? _query;
  StorageDisk? _selected;

  List<StorageDisk> get _filtered {
    final query = _query;
    if (query == null || query.isEmpty) return widget.candidates;
    final lower = query.toLowerCase();
    return widget.candidates
        .where(
          (disk) =>
              disk.name.toLowerCase().contains(lower) ||
              disk.serial.toLowerCase().contains(lower) ||
              disk.model.toLowerCase().contains(lower),
        )
        .toList(growable: false);
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
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.storageDiskPickerHelper,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  widget.emptyMessage ?? l10n.storageDiskPickerEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  labelText: l10n.storageDiskPickerSearchLabel,
                  hintText: l10n.storageDiskPickerSearchHint,
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (value) =>
                    setState(() => _query = value.isEmpty ? null : value),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final disk = _filtered[index];
                    final selected = _selected?.id == disk.id;
                    return ListTile(
                      selected: selected,
                      leading: Icon(
                        disk.isSolidState
                            ? Icons.memory_rounded
                            : Icons.storage_rounded,
                      ),
                      title: Text(disk.name),
                      subtitle: Text(
                        l10n.storageDiskPickerDiskSubtitle(
                          formatBytes(disk.sizeBytes),
                          l10n.diskModelLabel(disk.model),
                          l10n.diskSerialLabel(disk.serial),
                        ),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => setState(() => _selected = disk),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.storageDiskPickerCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selected == null
                          ? null
                          : () => Navigator.pop(context, _selected!.name),
                      child: Text(l10n.storageDiskPickerContinue),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
