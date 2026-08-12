import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/destructive_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/presentation/connection_controller.dart';
import '../domain/audit_entry.dart';
import 'audit_retention_sheet.dart';

extension AuditLocalizations on AppLocalizations {
  String auditEventLabel(AuditEntry entry) => switch (entry.event) {
    AuditEventKind.authentication => sysAuditEventAuthentication,
    AuditEventKind.logout => sysAuditEventLogout,
    AuditEventKind.methodCall => sysAuditEventMethodCall,
    // An event kind TrueDock does not model still shows as itself rather than
    // as a blank row.
    AuditEventKind.other => entry.rawEvent,
  };

  String auditValidationMessage(AuditValidationIssue issue) =>
      switch (issue.code) {
        AuditValidationCode.retentionRange => sysAuditValidationRetention(
          issue.minimum ?? 1,
          issue.maximum ?? 30,
        ),
        AuditValidationCode.quotaRange => sysAuditValidationQuota(
          issue.minimum ?? 0,
          issue.maximum ?? 100,
        ),
        AuditValidationCode.fillOrder => sysAuditValidationFillOrder,
      };
}

/// The audit log (`audit.*`): who did what on the server.
///
/// This is the counterpart to every destructive action the app offers — the
/// record of them. Failures and denials are emphasised rather than blended in,
/// because a refused privileged call is the row worth finding.
class AuditSection extends ConsumerStatefulWidget {
  const AuditSection({super.key});

  @override
  ConsumerState<AuditSection> createState() => _AuditSectionState();
}

class _AuditSectionState extends ConsumerState<AuditSection> {
  var _query = const AuditQuery(limit: 50);
  List<AuditEntry>? _entries;
  AuditConfiguration? _configuration;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = ref.read(serverActionControllerProvider.notifier);
    final entries = await controller.loadAuditEntries(_query);
    final configuration = await controller.loadAuditConfiguration();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _configuration = configuration;
      _error = entries == null
          ? ref.read(serverActionControllerProvider).errorMessage
          : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final capabilities = ref.watch(connectionControllerProvider).capabilities;
    final canEditRetention = capabilities?.supports('audit.update') == true;
    final entries = _entries;
    final configuration = _configuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.sysAuditSubtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (configuration != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(l10n.sysAuditRetention(configuration.retentionDays)),
              subtitle: Text(
                configuration.isUncapped
                    ? l10n.sysAuditQuotaUncapped
                    : l10n.sysAuditSpace(
                        _formatBytes(configuration.usedBytes),
                        _formatBytes(
                          configuration.usedBytes +
                              configuration.availableBytes,
                        ),
                      ),
              ),
              trailing: canEditRetention
                  ? const Icon(Icons.chevron_right_rounded)
                  : null,
              onTap: canEditRetention
                  ? () => _editRetention(configuration)
                  : null,
            ),
          ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.sysAuditFilterAll)),
            ButtonSegment(
              value: true,
              label: Text(l10n.sysAuditFilterFailures),
            ),
          ],
          selected: {_query.onlyFailures},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(
              () => _query = _query.copyWith(onlyFailures: selection.first),
            );
            _load();
          },
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_error != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_error!),
            ),
          )
        else if (entries == null || entries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.sysAuditEmpty),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (index, entry) in entries.indexed) ...[
                  _AuditRow(entry: entry),
                  if (index < entries.length - 1)
                    const Divider(indent: 68, height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editRetention(AuditConfiguration configuration) async {
    final l10n = AppLocalizations.of(context);
    final edit = await showModalBottomSheet<AuditConfigurationEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AuditRetentionSheet(baseline: configuration),
    );
    if (edit == null || !mounted) return;
    if (edit.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sysAuditNoChanges)));
      return;
    }

    final serverName =
        ref.read(connectionControllerProvider).profile?.name ??
        l10n.systemServerFallback;
    // Shortening retention destroys recorded history, so this is confirmed even
    // though it looks like an ordinary settings change.
    final shortens =
        edit.retentionDays != null &&
        edit.retentionDays! < configuration.retentionDays;
    final confirmed = await confirmDestructiveAction(
      context,
      title: l10n.sysAuditApplyTitle,
      server: serverName,
      target: l10n.sysAuditTitle,
      actionLabel: l10n.sysAuditApplyAction,
      impact: shortens ? MutationImpact.critical : MutationImpact.high,
      confirmationText: shortens ? l10n.sysAuditTitle : null,
      consequences: [
        if (shortens)
          ImpactDetail(
            icon: Icons.delete_sweep_rounded,
            text: l10n.sysAuditApplyConsequence,
          ),
      ],
    );
    if (!confirmed || !mounted) return;

    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .updateAuditConfiguration(edit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          receipt == null
              ? ref.read(serverActionControllerProvider).errorMessage ??
                    l10n.sysGenericOperationFailed
              : l10n.sysAuditUpdated,
        ),
        showCloseIcon: receipt == null,
      ),
    );
    if (receipt != null) await _load();
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KiB', 'MiB', 'GiB', 'TiB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // A denial is an access-control event, not an error, so it reads differently
    // from a call that simply failed.
    final flag = entry.wasDenied
        ? l10n.sysAuditDenied
        : entry.succeeded
        ? null
        : l10n.sysAuditFailed;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: flag == null ? null : theme.colorScheme.errorContainer,
        child: Icon(switch (entry.event) {
          AuditEventKind.authentication => Icons.login_rounded,
          AuditEventKind.logout => Icons.logout_rounded,
          AuditEventKind.methodCall => Icons.bolt_rounded,
          AuditEventKind.other => Icons.article_outlined,
        }, color: flag == null ? null : theme.colorScheme.onErrorContainer),
      ),
      title: Text(entry.label, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          l10n.auditEventLabel(entry),
          ?entry.username,
          if (entry.address != null) l10n.sysAuditFrom(entry.address!),
          if (entry.timestamp != null)
            entry.timestamp!.toLocal().toString().split('.').first,
          ?flag,
        ].join(' · '),
      ),
      isThreeLine: false,
    );
  }
}
