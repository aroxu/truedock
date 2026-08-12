import 'package:flutter/material.dart';
import '../../../core/widgets/truedock_dropdown.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/alert_class_configuration.dart';
import '../domain/alert_service_configuration.dart';
import 'alert_class_localizations.dart';

/// Reviews and edits the per-class alert policies.
///
/// Shows every class from the catalog, not just the overridden ones: a stock
/// server has no overrides at all, so listing only those would render an empty
/// screen while hiding everything an administrator can change.
class AlertClassesSheet extends StatefulWidget {
  const AlertClassesSheet({required this.configuration, super.key});

  final AlertClassConfiguration configuration;

  @override
  State<AlertClassesSheet> createState() => _AlertClassesSheetState();
}

class _AlertClassesSheetState extends State<AlertClassesSheet> {
  late Map<String, AlertClassPolicy> _policies;

  @override
  void initState() {
    super.initState();
    _policies = {
      for (final policy in widget.configuration.policies) policy.id: policy,
    };
  }

  AlertClassConfiguration get _current =>
      AlertClassConfiguration(policies: _policies.values.toList());

  bool get _changed {
    for (final policy in widget.configuration.policies) {
      final next = _policies[policy.id]!;
      if (next.level != policy.level || next.policy != policy.policy) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final grouped = _current.byCategory;
    final silenced = _current.silenced.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sysAlertClassesTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sysAlertClassesSummary(
                _current.overriddenCount,
                _current.policies.length,
              ),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            // Silenced classes are called out because nothing else in the app
            // reveals that an alert will never be delivered.
            if (silenced > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.sysAlertClassesSilenced(silenced),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Text(entry.key, style: theme.textTheme.titleSmall),
                    ),
                    for (final policy in entry.value)
                      _ClassTile(
                        policy: policy,
                        onChanged: (next) =>
                            setState(() => _policies[policy.id] = next),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                    // Disabled until something actually differs, so the
                    // confirmation is never shown for a no-op save.
                    onPressed: _changed
                        ? () => Navigator.pop(context, _current)
                        : null,
                    child: Text(
                      l10n.sysAlertClassesApplyAction,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.policy, required this.onChanged});

  final AlertClassPolicy policy;
  final ValueChanged<AlertClassPolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(policy.title, style: theme.textTheme.titleSmall),
                ),
                if (policy.isSilenced)
                  _Badge(
                    label: l10n.sysAlertClassSilencedBadge,
                    color: theme.colorScheme.errorContainer,
                    onColor: theme.colorScheme.onErrorContainer,
                  )
                else if (policy.differsFromDefault)
                  _Badge(
                    label: l10n.sysAlertClassChanged,
                    color: theme.colorScheme.secondaryContainer,
                    onColor: theme.colorScheme.onSecondaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TrueDockDropdownButtonFormField<AlertLevel>(
                    initialValue: policy.level,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.sysAlertClassLevel,
                      isDense: true,
                    ),
                    items: [
                      for (final level in AlertLevel.values)
                        DropdownMenuItem(
                          value: level,
                          child: Text(level.apiValue),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(policy.copyWith(level: value));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TrueDockDropdownButtonFormField<AlertPolicy>(
                    initialValue: policy.policy,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.sysAlertClassPolicy,
                      isDense: true,
                    ),
                    items: [
                      for (final option in AlertPolicy.values)
                        DropdownMenuItem(
                          value: option,
                          child: Text(l10n.alertDeliveryLabel(option)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(policy.copyWith(policy: value));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor),
    ),
  );
}
