import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_motion.dart';
import '../../resources/domain/server_resources.dart';

/// One row in the dataset tree.
///
/// Every action is gated twice: on the method the server exposes, and on what
/// the dataset itself allows. A locked dataset cannot take property changes, a
/// pool root is not an ordinary dataset, and promotion only means something for
/// a clone that still depends on its origin snapshot.

class DatasetTile extends StatelessWidget {
  const DatasetTile({
    required this.dataset,
    required this.onCreateSnapshot,
    required this.canEdit,
    required this.canRename,
    required this.onEdit,
    required this.onRename,
    required this.canDelete,
    required this.onDelete,
    required this.canLock,
    required this.onLock,
    required this.onUnlock,
    required this.canPromote,
    required this.onPromote,
    required this.canManageQuotas,
    required this.onManageQuotas,
    required this.canManageAcl,
    required this.onManageAcl,
    this.hasChildren = false,
    this.isExpanded = false,
    this.onToggle,
    super.key,
  });
  final Dataset dataset;
  final VoidCallback onCreateSnapshot;
  final bool canEdit;
  final bool canRename;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final bool canDelete;
  final VoidCallback onDelete;
  final bool canLock;
  final VoidCallback onLock;
  final VoidCallback onUnlock;
  final bool canPromote;
  final VoidCallback onPromote;

  /// Per-account quotas need both halves of the API, and the read half is the
  /// one a restricted role is likely to be missing.
  final bool canManageQuotas;
  final VoidCallback onManageQuotas;
  final bool canManageAcl;
  final VoidCallback onManageAcl;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A locked dataset cannot accept property or path changes, and a pool
    // root dataset cannot be renamed at all.
    final editable = canEdit && !dataset.locked;
    final renameable = canRename && !dataset.locked && !dataset.isPoolRoot;
    // Destroying a pool root dataset is a pool operation, not a dataset one.
    final deletable = canDelete && !dataset.isPoolRoot;
    // Only an encryption root exposes its own lock state.
    final lockable = canLock && dataset.canLock;
    final unlockable = canLock && dataset.canUnlock;
    // Promotion only means anything for a clone that still depends on its
    // origin snapshot.
    final promotable = canPromote && dataset.isClone;
    // A locked dataset cannot report usage, so quotas would read as all zero.
    final quotaManageable = canManageQuotas && !dataset.locked;
    final aclManageable =
        canManageAcl && !dataset.locked && dataset.type == 'FILESYSTEM';
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(18 + dataset.depth * 8, 6, 12, 6),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: hasChildren
                ? AnimatedRotation(
                    key: ValueKey('dataset-expansion-${dataset.id}'),
                    turns: isExpanded ? 0.25 : 0,
                    duration: context.motionDuration(AppMotion.standard),
                    curve: AppMotion.standardCurve,
                    child: const Icon(Icons.chevron_right_rounded),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Icon(
            dataset.type == 'VOLUME'
                ? Icons.view_in_ar_outlined
                : Icons.folder_outlined,
          ),
        ],
      ),
      title: Text(dataset.leafName),
      subtitle: Text(
        [
          l10n.storageDatasetTileUsed(formatBytes(dataset.usedBytes)),
          l10n.storageDatasetTileAvailable(formatBytes(dataset.availableBytes)),
          if (dataset.quotaBytes case final quota? when quota > 0)
            l10n.storageDatasetTileQuota(formatBytes(quota)),
          if (dataset.readOnly) l10n.storageDatasetTileReadOnly,
          if (dataset.isClone) l10n.storageDatasetTileClone,
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dataset.locked) const Icon(Icons.lock_rounded, size: 18),
          if (dataset.encrypted && !dataset.locked)
            const Icon(Icons.lock_open_rounded, size: 18),
          PopupMenuButton<_DatasetAction>(
            key: ValueKey('dataset-actions-${dataset.id}'),
            tooltip: l10n.storageDatasetTileActionsTooltip,
            onSelected: (action) => switch (action) {
              _DatasetAction.snapshot => onCreateSnapshot(),
              _DatasetAction.edit => onEdit(),
              _DatasetAction.rename => onRename(),
              _DatasetAction.delete => onDelete(),
              _DatasetAction.lock => onLock(),
              _DatasetAction.unlock => onUnlock(),
              _DatasetAction.promote => onPromote(),
              _DatasetAction.quotas => onManageQuotas(),
              _DatasetAction.acl => onManageAcl(),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _DatasetAction.snapshot,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_a_photo_outlined),
                  title: Text(l10n.storageDatasetTileTakeSnapshot),
                ),
              ),
              PopupMenuItem(
                value: _DatasetAction.edit,
                enabled: editable,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune_rounded),
                  title: Text(l10n.storageDatasetTileEditProperties),
                ),
              ),
              PopupMenuItem(
                value: _DatasetAction.quotas,
                enabled: quotaManageable,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pie_chart_outline_rounded),
                  title: Text(l10n.storageDatasetTileQuotas),
                ),
              ),
              PopupMenuItem(
                key: const ValueKey('dataset-manage-acl-action'),
                value: _DatasetAction.acl,
                enabled: aclManageable,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(l10n.storageDatasetTileManageAcl),
                ),
              ),
              PopupMenuItem(
                value: _DatasetAction.rename,
                enabled: renameable,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.drive_file_rename_outline_rounded),
                  title: Text(l10n.storageDatasetTileRename),
                ),
              ),
              if (lockable || unlockable)
                PopupMenuItem(
                  value: unlockable
                      ? _DatasetAction.unlock
                      : _DatasetAction.lock,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      unlockable
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                    ),
                    title: Text(
                      unlockable
                          ? l10n.storageDatasetTileUnlock
                          : l10n.storageDatasetTileLock,
                    ),
                  ),
                ),
              if (promotable)
                PopupMenuItem(
                  value: _DatasetAction.promote,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.upgrade_rounded),
                    title: Text(l10n.storageDatasetTilePromoteClone),
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _DatasetAction.delete,
                enabled: deletable,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: deletable
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: Text(
                    l10n.storageDatasetTileDeleteDataset,
                    style: TextStyle(
                      color: deletable
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: hasChildren ? onToggle : null,
    );
  }
}

enum _DatasetAction {
  snapshot,
  edit,
  rename,
  delete,
  lock,
  unlock,
  promote,
  quotas,
  acl,
}
