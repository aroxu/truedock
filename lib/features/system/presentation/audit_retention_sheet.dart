import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/audit_entry.dart';
import 'audit_section.dart';

/// Edits audit retention and the quota on the audit dataset.
///
/// Only changed fields are emitted, so an untouched threshold is never resent.
/// The sheet exists as its own editor rather than inline in the list because
/// shortening retention destroys recorded history, and that deserves a
/// deliberate step rather than a stepper next to the log.
class AuditRetentionSheet extends StatefulWidget {
  const AuditRetentionSheet({required this.baseline, super.key});

  final AuditConfiguration baseline;

  @override
  State<AuditRetentionSheet> createState() => _AuditRetentionSheetState();
}

class _AuditRetentionSheetState extends State<AuditRetentionSheet> {
  late final TextEditingController _retention;
  late final TextEditingController _quota;
  late final TextEditingController _warning;
  late final TextEditingController _critical;
  List<AuditValidationIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    final baseline = widget.baseline;
    _retention = TextEditingController(text: '${baseline.retentionDays}');
    _quota = TextEditingController(text: '${baseline.quotaGiB}');
    _warning = TextEditingController(text: '${baseline.quotaFillWarning}');
    _critical = TextEditingController(text: '${baseline.quotaFillCritical}');
  }

  @override
  void dispose() {
    _retention.dispose();
    _quota.dispose();
    _warning.dispose();
    _critical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sysAuditRetentionEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _retention,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.sysAuditRetentionDays,
                  helperText: l10n.sysAuditRetentionHelp,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _quota,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.sysAuditQuota,
                  helperText: l10n.sysAuditQuotaHelp,
                  helperMaxLines: 10,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _warning,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.sysAuditWarnAt,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _critical,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.sysAuditCriticalAt,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              for (final issue in _issues)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.auditValidationMessage(issue),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.actionCancel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(
                        l10n.sysAuditApplyAction,
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

  void _submit() {
    final baseline = widget.baseline;
    final retention = int.tryParse(_retention.text.trim());
    final quota = int.tryParse(_quota.text.trim());
    final warning = int.tryParse(_warning.text.trim());
    final critical = int.tryParse(_critical.text.trim());
    final edit = AuditConfigurationEdit(
      retentionDays: retention == baseline.retentionDays ? null : retention,
      quotaGiB: quota == baseline.quotaGiB ? null : quota,
      quotaFillWarning: warning == baseline.quotaFillWarning ? null : warning,
      quotaFillCritical: critical == baseline.quotaFillCritical
          ? null
          : critical,
    );
    // Validate against the effective values, not just the changed ones: raising
    // the warning alone can invert its relationship with the critical threshold.
    final effective = AuditConfigurationEdit(
      retentionDays: retention ?? baseline.retentionDays,
      quotaGiB: quota ?? baseline.quotaGiB,
      quotaFillWarning: warning ?? baseline.quotaFillWarning,
      quotaFillCritical: critical ?? baseline.quotaFillCritical,
    );
    final issues = effective.validate();
    if (issues.isNotEmpty) {
      setState(() => _issues = issues);
      return;
    }
    Navigator.pop(context, edit);
  }
}
