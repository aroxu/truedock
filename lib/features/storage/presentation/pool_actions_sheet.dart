import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/data/server_actions_repository.dart';
import '../../resources/domain/server_resources.dart';
import 'disk_picker_sheet.dart';
import 'storage_localizations.dart';

/// The outcome chosen in [PoolActionsSheet].
sealed class PoolAction {
  const PoolAction();
}

class PoolScrubAction extends PoolAction {
  const PoolScrubAction(this.action);

  /// Null means "start a new scrub".
  final ScrubControlAction? action;
}

class PoolMemberAction extends PoolAction {
  const PoolMemberAction({required this.member, required this.online});

  final PoolMember member;
  final bool online;
}

class PoolExportAction extends PoolAction {
  const PoolExportAction({
    required this.destroyData,
    required this.takeSnapshotsOffline,
  });

  final bool destroyData;
  final bool takeSnapshotsOffline;
}

class PoolAttachAction extends PoolAction {
  const PoolAttachAction({required this.targetVdev, required this.disk});

  /// GUID of the vdev to attach to (`pool.attach.target_vdev`).
  final String targetVdev;

  /// devname of the disk to attach (`pool.attach.new_disk`).
  final String disk;
}

class PoolReplaceAction extends PoolAction {
  const PoolReplaceAction({
    required this.member,
    required this.disk,
    this.force = false,
  });

  /// The member being replaced (`pool.replace.label`).
  final PoolMember member;

  /// devname of the replacement disk (`pool.replace.disk`).
  final String disk;

  /// When true the old disk is removed even if it is still being read.
  final bool force;
}

/// Pool operations chooser. Destructive choices are only collected here; the
/// caller runs the shared confirmation before calling the server.
class PoolActionsSheet extends StatefulWidget {
  const PoolActionsSheet({
    required this.pool,
    required this.candidateDisks,
    required this.canScrub,
    required this.canControlScrub,
    required this.canToggleMembers,
    required this.canExport,
    required this.canAttach,
    required this.canReplace,
    super.key,
  });

  final StoragePool pool;

  /// Disks not currently in a pool, offered as attach/replace candidates.
  final List<StorageDisk> candidateDisks;

  final bool canScrub;
  final bool canControlScrub;
  final bool canToggleMembers;
  final bool canExport;
  final bool canAttach;
  final bool canReplace;

  @override
  State<PoolActionsSheet> createState() => _PoolActionsSheetState();
}

class _PoolActionsSheetState extends State<PoolActionsSheet> {
  bool _destroyData = false;
  bool _cascade = true;
  bool _force = false;
  _Section _section = _Section.menu;

  PoolMember? _replaceTarget;
  late AppLocalizations l10n;

  /// Data-category members that carry a vdev GUID. `pool.attach` only accepts
  /// a `target_vdev` for mirror and stripe vdevs, so attach is offered per
  /// unique attachable vdev rather than per leaf disk.
  List<PoolMember> get _attachableMembers => widget.pool.members
      .where((m) => m.category == 'data' && m.vdevGuid != null)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.pool.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              l10n.poolStatusFree(
                widget.pool.status,
                formatBytes(widget.pool.freeBytes),
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ...switch (_section) {
              _Section.menu => _menu(theme),
              _Section.members => _members(theme),
              _Section.attach => _attach(theme),
              _Section.replace => _replace(theme),
              _Section.export => _export(theme),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _menu(ThemeData theme) {
    final scan = widget.pool.scan;
    final scrubRunning = scan?.isScrub == true && scan!.isRunning;
    final scrubPaused = scan?.isScrub == true && scan!.isPaused;
    final attachable =
        _attachableMembers.isNotEmpty && widget.candidateDisks.isNotEmpty;
    final replaceable =
        widget.pool.members.isNotEmpty && widget.candidateDisks.isNotEmpty;
    return [
      if (scrubRunning || scrubPaused) ...[
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scrubPaused ? l10n.poolScrubPaused : l10n.poolScrubRunning,
                  style: theme.textTheme.titleSmall,
                ),
                if (scan.percentage case final percent?) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: (percent / 100).clamp(0, 1)),
                  const SizedBox(height: 6),
                  Text(l10n.poolScrubProgress(percent)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (widget.canScrub && !scrubRunning && !scrubPaused)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cleaning_services_outlined),
          title: Text(l10n.poolScrubStart),
          subtitle: Text(l10n.poolScrubStartSubtitle),
          onTap: () => Navigator.of(context).pop(const PoolScrubAction(null)),
        ),
      if (widget.canControlScrub && scrubRunning) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.pause_rounded),
          title: Text(l10n.poolScrubPause),
          subtitle: Text(l10n.poolScrubPauseSubtitle),
          onTap: () => Navigator.of(
            context,
          ).pop(const PoolScrubAction(ScrubControlAction.pause)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.stop_rounded, color: theme.colorScheme.error),
          title: Text(l10n.poolScrubStop),
          subtitle: Text(l10n.poolScrubStopSubtitle),
          onTap: () => Navigator.of(
            context,
          ).pop(const PoolScrubAction(ScrubControlAction.stop)),
        ),
      ],
      if (widget.canControlScrub && scrubPaused)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.play_arrow_rounded),
          title: Text(l10n.poolScrubResume),
          onTap: () => Navigator.of(
            context,
          ).pop(const PoolScrubAction(ScrubControlAction.resume)),
        ),
      if (widget.canToggleMembers && widget.pool.members.isNotEmpty)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storage_outlined),
          title: Text(l10n.poolMembers),
          subtitle: Text(l10n.poolMembersCount(widget.pool.members.length)),
          onTap: () => setState(() => _section = _Section.members),
        ),
      if (widget.canAttach && attachable)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.add_circle_outline_rounded),
          title: Text(l10n.poolAttachDisk),
          subtitle: Text(l10n.poolAttachDiskSubtitle),
          onTap: () => setState(() => _section = _Section.attach),
        ),
      if (widget.canReplace && replaceable)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.swap_horiz_rounded),
          title: Text(l10n.poolReplaceDisk),
          subtitle: Text(l10n.poolReplaceDiskSubtitle),
          onTap: () => setState(() => _section = _Section.replace),
        ),
      if (widget.canExport)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.eject_outlined, color: theme.colorScheme.error),
          title: Text(l10n.poolExportOrDestroy),
          subtitle: Text(l10n.poolExportOrDestroySubtitle),
          onTap: () => setState(() => _section = _Section.export),
        ),
      if (!widget.canScrub &&
          !widget.canToggleMembers &&
          !widget.canExport &&
          !widget.canAttach &&
          !widget.canReplace)
        Text(
          l10n.poolOperationsUnavailable,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
    ];
  }

  List<Widget> _members(ThemeData theme) => [
    Text(l10n.poolMembers, style: theme.textTheme.titleMedium),
    const SizedBox(height: 6),
    Text(
      l10n.poolMembersDescription,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 12),
    for (final member in widget.pool.members)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          member.isOnline
              ? Icons.check_circle_outline_rounded
              : Icons.remove_circle_outline_rounded,
          color: member.isOnline
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
        title: Text(member.name),
        subtitle: Text(
          l10n.poolMemberCategoryStatus(member.category, member.status),
        ),
        trailing: TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(PoolMemberAction(member: member, online: !member.isOnline)),
          child: Text(
            member.isOnline ? l10n.poolTakeOffline : l10n.poolBringOnline,
          ),
        ),
      ),
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: () => setState(() => _section = _Section.menu),
      child: Text(l10n.actionBack),
    ),
  ];

  List<Widget> _attach(ThemeData theme) => [
    Text(l10n.poolAttachDisk, style: theme.textTheme.titleMedium),
    const SizedBox(height: 6),
    Text(
      l10n.poolAttachDescription,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 12),
    if (widget.candidateDisks.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.poolNoUnusedDisks,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      )
    else ...[
      for (final member in _attachableMembers)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.hub_outlined),
          title: Text(l10n.poolVdevTitle(member.vdevGuid ?? '')),
          subtitle: Text(l10n.poolContainsMember(member.name, member.status)),
          onTap: () => _pickAttachDisk(member),
        ),
      const SizedBox(height: 12),
    ],
    OutlinedButton(
      onPressed: () => setState(() => _section = _Section.menu),
      child: Text(l10n.actionBack),
    ),
  ];

  List<Widget> _replace(ThemeData theme) => [
    Text(l10n.poolReplaceDisk, style: theme.textTheme.titleMedium),
    const SizedBox(height: 6),
    Text(
      l10n.poolReplaceDescription,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 12),
    if (widget.candidateDisks.isEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.storageNoUnusedDisksForPool,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      )
    else ...[
      for (final member in widget.pool.members)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            member.isOnline
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            color: member.isOnline
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
          title: Text(member.name),
          subtitle: Text(
            l10n.storagePoolMemberSummary(
              l10n.storageServerValue(member.category),
              l10n.storageServerValue(member.status),
            ),
          ),
          trailing: member.isOnline
              ? TextButton(
                  onPressed: null,
                  child: Text(l10n.poolOfflineUseOnly),
                )
              : null,
          enabled: !member.isOnline,
          onTap: () => setState(() => _replaceTarget = member),
          selected: _replaceTarget?.label == member.label,
        ),
      if (_replaceTarget != null) ...[
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.poolForceRemoveOldDisk,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: Text(l10n.poolForceRemoveOldDiskSubtitle),
          value: _force,
          onChanged: (value) => setState(() => _force = value),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _pickReplaceDisk,
          icon: const Icon(Icons.swap_horiz_rounded),
          label: Text(l10n.poolChooseReplacementDisk),
        ),
      ],
      const SizedBox(height: 12),
    ],
    OutlinedButton(
      onPressed: () => setState(() => _section = _Section.menu),
      child: Text(l10n.actionBack),
    ),
  ];

  Future<void> _pickAttachDisk(PoolMember target) async {
    final disk = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DiskPickerSheet(
        title: l10n.poolAttachToVdev(target.vdevGuid ?? ''),
        candidates: widget.candidateDisks,
      ),
    );
    if (disk == null) return;
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(PoolAttachAction(targetVdev: target.vdevGuid!, disk: disk));
  }

  Future<void> _pickReplaceDisk() async {
    final target = _replaceTarget;
    if (target == null) return;
    final disk = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DiskPickerSheet(
        title: l10n.poolReplaceTarget(target.name),
        candidates: widget.candidateDisks,
      ),
    );
    if (disk == null) return;
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(PoolReplaceAction(member: target, disk: disk, force: _force));
  }

  List<Widget> _export(ThemeData theme) => [
    Text(l10n.poolExportTitle, style: theme.textTheme.titleMedium),
    const SizedBox(height: 6),
    Text(
      l10n.poolExportDescription,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 14),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.poolDeleteSharesAndTasks),
      value: _cascade,
      onChanged: (value) => setState(() => _cascade = value),
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.poolDestroyAllData,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      subtitle: Text(l10n.poolDestroyAllDataSubtitle),
      value: _destroyData,
      onChanged: (value) => setState(() => _destroyData = value),
    ),
    const SizedBox(height: 18),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _section = _Section.menu),
            child: Text(l10n.actionBack),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(
              PoolExportAction(
                destroyData: _destroyData,
                takeSnapshotsOffline: _cascade,
              ),
            ),
            child: Text(l10n.actionContinue),
          ),
        ),
      ],
    ),
  ];
}

enum _Section { menu, members, attach, replace, export }
