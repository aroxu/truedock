import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/config_backup.dart';

enum ConfigBackupReadyAction { download, copyLink }

/// Chooses what a configuration backup includes.
///
/// The three options are not equivalent checkboxes: the secret seed decrypts
/// stored credentials and the pool keys unlock encrypted datasets, so an archive
/// carrying either is as sensitive as the server's own secrets. The sheet says
/// that per option and again as a warning once any is selected, rather than
/// leaving the consequence to the user's inference.
class ConfigBackupSheet extends StatefulWidget {
  const ConfigBackupSheet({super.key});

  @override
  State<ConfigBackupSheet> createState() => _ConfigBackupSheetState();
}

class _ConfigBackupSheetState extends State<ConfigBackupSheet> {
  var _options = const ConfigBackupOptions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sysConfigBackupSheetTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sysConfigBackupExplain,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _options.secretSeed,
                onChanged: (value) => setState(
                  () => _options = _options.copyWith(secretSeed: value),
                ),
                title: Text(l10n.sysConfigBackupSecretSeed),
                subtitle: Text(l10n.sysConfigBackupSecretSeedHelp),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _options.poolKeys,
                onChanged: (value) => setState(
                  () => _options = _options.copyWith(poolKeys: value),
                ),
                title: Text(l10n.sysConfigBackupPoolKeys),
                subtitle: Text(l10n.sysConfigBackupPoolKeysHelp),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _options.rootAuthorizedKeys,
                onChanged: (value) => setState(
                  () => _options = _options.copyWith(rootAuthorizedKeys: value),
                ),
                title: Text(l10n.sysConfigBackupRootKeys),
              ),
              if (_options.carriesSecrets) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.sysConfigBackupSecretsWarning,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _options),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        l10n.sysConfigBackupPrepare,
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
}

/// Shows the prepared download link.
///
/// The primary action opens the single-use URL in the platform browser, which
/// owns the actual download destination. Link copy remains available as a
/// fallback for browsers or document workflows that need manual handling.
class ConfigBackupReadySheet extends StatelessWidget {
  const ConfigBackupReadySheet({
    required this.download,
    required this.url,
    super.key,
  });

  final ConfigBackupDownload download;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sysConfigBackupReady,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sysConfigBackupReadyBody(download.filename),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SelectableText(
                  url.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, ConfigBackupReadyAction.download),
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  l10n.sysConfigBackupDownload,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, ConfigBackupReadyAction.copyLink),
                icon: const Icon(Icons.copy_rounded),
                label: Text(
                  l10n.sysConfigBackupCopyLink,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
