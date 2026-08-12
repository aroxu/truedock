import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart' show ResourceSection;
import '../domain/system_resources.dart';
import '../../../core/l10n/data_message_localizations.dart';

/// The API keys registered on the server.
///
/// TrueDock recommends API-key authentication because a key can be withdrawn
/// independently of the account password, so being able to see and revoke keys
/// is part of keeping that recommendation honest. No key material is ever shown:
/// TrueNAS returns the secret only once, at creation.
class ApiKeyList extends StatelessWidget {
  const ApiKeyList({
    required this.section,
    required this.canRevoke,
    required this.busyIds,
    required this.onRevoke,
    required this.now,
    super.key,
  });

  final ResourceSection<NasApiKey> section;
  final bool canRevoke;

  /// Key ids with a revoke in flight.
  final Set<int> busyIds;
  final ValueChanged<NasApiKey> onRevoke;

  /// Injected so expiry rendering is deterministic in tests.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (section.hasError) {
      return _Message(
        icon: Icons.lock_outline_rounded,
        message: AppLocalizations.of(context).dataMessage(section.error!),
      );
    }
    if (section.items.isEmpty) {
      return _Message(
        icon: Icons.key_outlined,
        message: AppLocalizations.of(context).sysApiKeyNone,
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, key) in section.items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 68),
            _ApiKeyTile(
              apiKey: key,
              canRevoke: canRevoke,
              busy: busyIds.contains(key.id),
              onRevoke: () => onRevoke(key),
              now: now,
            ),
          ],
        ],
      ),
    );
  }
}

class _ApiKeyTile extends StatelessWidget {
  const _ApiKeyTile({
    required this.apiKey,
    required this.canRevoke,
    required this.busy,
    required this.onRevoke,
    required this.now,
  });

  final NasApiKey apiKey;
  final bool canRevoke;
  final bool busy;
  final VoidCallback onRevoke;
  final DateTime now;

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final expired = apiKey.isExpiredAt(now);
    // Revoked and expired are different facts: one was withdrawn deliberately,
    // the other simply ran out. Both mean the key cannot authenticate.
    final unusable = apiKey.revoked || expired;
    final status = <String>[
      if (apiKey.revoked) l10n.sysApiKeyRevoked,
      if (expired && !apiKey.revoked) l10n.sysApiKeyExpired,
      if (apiKey.username case final owner? when owner.isNotEmpty) owner,
      if (apiKey.expiresAt case final expiry? when !expired)
        l10n.sysApiKeyExpiresDate(_date(expiry))
      else if (!apiKey.expires)
        l10n.sysApiKeyNoExpiry,
      if (apiKey.createdAt case final created?)
        l10n.sysApiKeyCreatedDate(_date(created)),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 18, right: 8),
      leading: Icon(
        unusable ? Icons.key_off_outlined : Icons.key_rounded,
        color: unusable ? colors.onSurfaceVariant : colors.primary,
      ),
      title: Text(
        apiKey.name,
        style: unusable ? TextStyle(color: colors.onSurfaceVariant) : null,
      ),
      subtitle: Text(status.join(' · ')),
      trailing: busy
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          // A revoked key cannot be revoked again, so the action is withheld
          // rather than shown as a no-op. An expired key can still be deleted.
          : canRevoke && !apiKey.revoked
          ? IconButton(
              onPressed: onRevoke,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.sysApiKeyRevokeTooltip,
              color: colors.error,
            )
          : null,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
