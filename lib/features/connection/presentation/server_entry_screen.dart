import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/security_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/presentation/app_shell.dart';
import '../data/saved_server_repository.dart';
import 'connect_server_screen.dart';
import 'connection_controller.dart';

/// Keeps the administrative shell out of view until a live server session
/// exists. First use goes straight to registration. Once at least one profile
/// exists, this becomes a server picker with registration as a separate page.
class ServerEntryScreen extends ConsumerWidget {
  const ServerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionControllerProvider);
    // A dropped session is not the same as having no session. The shell owns
    // the connection-lost banner - the stale-data warning and the retry - so
    // swapping it for the registration screen the moment the socket died threw
    // that away and made a restart look like being signed out. Keep the shell
    // up while a lost connection can still be retried; a real reboot recovers
    // in place instead of dumping the user back at server registration.
    if (connection.isConnected || connection.hasRetainedSession) {
      return const AppShell();
    }
    return ref
        .watch(savedServersProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => const ServerRegistrationScreen(canClose: false),
          data: (servers) => servers.isEmpty
              ? const ServerRegistrationScreen(canClose: false)
              : ServerSelectionScreen(servers: servers),
        );
  }
}

class ServerSelectionScreen extends ConsumerStatefulWidget {
  const ServerSelectionScreen({required this.servers, super.key});

  final List<SavedServer> servers;

  @override
  ConsumerState<ServerSelectionScreen> createState() =>
      _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends ConsumerState<ServerSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverEntryTitle)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  l10n.savedServersTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (index, server) in widget.servers.indexed) ...[
                        if (index > 0) const Divider(height: 1, indent: 68),
                        ListTile(
                          key: ValueKey('server-${server.profile.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          leading: Icon(
                            server.hasSavedCredential
                                ? server.credentialProtection ==
                                              CredentialProtection.biometric ||
                                          server.credentialProtection ==
                                              CredentialProtection
                                                  .appPasswordWithBiometric
                                      ? Icons.fingerprint_rounded
                                      : server.credentialProtection ==
                                            CredentialProtection.appPassword
                                      ? Icons.password_rounded
                                      : Icons.login_rounded
                                : Icons.login_rounded,
                          ),
                          title: Text(server.profile.name),
                          subtitle: Text(
                            server.hasSavedCredential
                                ? '${server.username} · ${server.profile.baseUri.authority}'
                                : '${l10n.savedServerSignInRequired} · ${server.profile.baseUri.authority}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openServer(server),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  key: const ValueKey('register-server-button'),
                  onPressed: () => context.push('/servers/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.serverRegisterAnother),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openServer(SavedServer server) =>
      context.push('/servers/auth/${server.profile.id}');
}
