import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart';
import '../domain/iscsi_auth_configuration.dart';
import 'iscsi_auth_sheet.dart';

/// Lists iSCSI CHAP credential entries and lets the user create, edit, or
/// delete them. Secrets are never shown: the sheet only renders the user,
/// tag, and whether mutual CHAP is configured. Mutations are returned to the
/// caller, which routes them through the shared confirmation and the server
/// action controller.
class IscsiAuthManagementSheet extends StatelessWidget {
  const IscsiAuthManagementSheet({
    required this.auths,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.onNextTag,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<IscsiAuth> auths;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  /// Computes the next free tag for a new entry.
  final int Function() onNextTag;

  /// Opens [IscsiAuthSheet] for create and returns the chosen configuration.
  final Future<IscsiAuthConfiguration?> Function(int nextTag) onCreate;

  /// Opens [IscsiAuthSheet] for edit and returns the chosen configuration.
  final Future<IscsiAuthConfiguration?> Function(IscsiAuth existing) onEdit;

  /// Confirms and deletes the entry. Returns true when the caller carried out
  /// the deletion.
  final Future<bool> Function(IscsiAuth auth) onDelete;

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
            Text(
              l10n.storageIscsiAuthMgmtTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.storageIscsiAuthMgmtSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (auths.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.storageIscsiAuthMgmtEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: auths.length,
                  itemBuilder: (context, index) {
                    final auth = auths[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        auth.isMutual
                            ? Icons.shield_moon_outlined
                            : Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        auth.user.isEmpty
                            ? l10n.storageIscsiAuthMgmtEmptyUser
                            : auth.user,
                      ),
                      subtitle: Text(
                        l10n.storageIscsiAuthMgmtTagSubtitle(
                          auth.tag,
                          auth.isMutual
                              ? l10n.storageIscsiAuthMgmtMutualChap
                              : l10n.storageIscsiAuthMgmtOnewayChap,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canEdit)
                            IconButton(
                              tooltip: l10n.storageIscsiAuthMgmtEdit,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => onEdit(auth),
                            ),
                          if (canDelete)
                            IconButton(
                              tooltip: l10n.storageIscsiAuthMgmtDelete,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () => onDelete(auth),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (canCreate)
              FilledButton.icon(
                onPressed: () => onCreate(onNextTag()),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.storageIscsiAuthMgmtNew),
              ),
          ],
        ),
      ),
    );
  }
}
