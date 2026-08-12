import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../resources/domain/server_resources.dart' show ResourceSection;
import '../domain/system_resources.dart';
import '../../../core/l10n/data_message_localizations.dart';
import 'system_value_localizations.dart';

/// Sessions currently authenticated against the server.
///
/// The API key list answers "what could connect"; this answers "what is
/// connected right now", which is the question that matters when an account may
/// have been compromised. Terminating one evicts a single client rather than
/// signing the account out everywhere.
class SessionList extends StatelessWidget {
  const SessionList({
    required this.section,
    required this.canTerminate,
    required this.busyIds,
    required this.onTerminate,
    required this.now,
    super.key,
  });

  final ResourceSection<NasSession> section;
  final bool canTerminate;

  /// Session ids with a terminate in flight.
  final Set<String> busyIds;
  final ValueChanged<NasSession> onTerminate;

  /// Injected so relative ages render deterministically in tests.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (section.hasError) {
      return _Message(
        icon: Icons.lock_outline_rounded,
        message: l10n.dataMessage(section.error!),
      );
    }

    // The middleware's own UNIX-socket connections are listed by the server but
    // are not user logins: showing them as unexplained root sessions would be
    // alarming and wrong, and they cannot be terminated meaningfully.
    final user = section.items.where((s) => s.isUserSession).toList();
    final internal = section.items.length - user.length;

    if (user.isEmpty) {
      return _Message(
        icon: Icons.devices_outlined,
        message: l10n.sysSessionNone,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, session) in user.indexed) ...[
                if (index > 0) const Divider(height: 1, indent: 68),
                _SessionTile(
                  session: session,
                  canTerminate: canTerminate,
                  busy: busyIds.contains(session.id),
                  onTerminate: () => onTerminate(session),
                  now: now,
                ),
              ],
            ],
          ),
        ),
        if (internal > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.sysSessionInternalNote(internal),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.canTerminate,
    required this.busy,
    required this.onTerminate,
    required this.now,
  });

  final NasSession session;
  final bool canTerminate;
  final bool busy;
  final VoidCallback onTerminate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final details = <String>[
      if (session.username case final name? when name.isNotEmpty) name,
      l10n.systemOriginLabel(session.origin),
      if (session.createdAt case final started?) _age(l10n, started),
      // An unencrypted session is worth surfacing rather than leaving to be
      // inferred from the origin.
      if (!session.secureTransport) l10n.sysSessionInsecure,
    ];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 18, right: 8),
      leading: Icon(
        session.current
            ? Icons.smartphone_rounded
            : session.usedApiKey
            ? Icons.key_rounded
            : Icons.computer_rounded,
        color: session.secureTransport ? colors.primary : colors.error,
      ),
      title: Row(
        children: [
          Flexible(child: Text(_label(l10n))),
          if (session.current) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(l10n.sysSessionThisDevice),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      subtitle: Text(details.join(' · ')),
      trailing: busy
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          // TrueDock's own session is deliberately not terminable here. Ending
          // it just signs the app out, which "Sign out" already does more
          // clearly, and offering it beside other sessions invites a mis-tap
          // that disconnects the user instead of the intruder.
          : canTerminate && !session.current
          ? IconButton(
              onPressed: onTerminate,
              icon: const Icon(Icons.logout_rounded),
              tooltip: l10n.sysSessionTerminateTooltip,
            )
          : null,
    );
  }

  String _label(AppLocalizations l10n) => switch (session.credentials) {
    'LOGIN_PASSWORD' => l10n.sysSessionPasswordLogin,
    'API_KEY' => l10n.sysSessionApiKeyLogin,
    'TOKEN' => l10n.sysSessionTokenLogin,
    _ => session.credentials,
  };

  /// Coarse ages only. A precise timestamp invites reading it as authoritative
  /// when clocks differ between the phone and the server.
  String _age(AppLocalizations l10n, DateTime started) {
    final elapsed = now.difference(started);
    if (elapsed.inMinutes < 1) return l10n.sysSessionJustNow;
    if (elapsed.inHours < 1) return l10n.sysSessionMinutes(elapsed.inMinutes);
    if (elapsed.inDays < 1) return l10n.sysSessionHours(elapsed.inHours);
    return l10n.sysSessionDays(elapsed.inDays);
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
