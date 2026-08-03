import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/connection/presentation/connection_controller.dart';
import '../../features/connection/presentation/connection_message_localizations.dart';
import '../../l10n/app_localizations.dart';

/// Hosts the connection-lost banner above the whole application.
///
/// This lives at the app level rather than inside the shell because a dropped
/// socket is not a property of one screen. It used to sit in `AppShell`, which
/// meant the banner - the stale-data warning and the only retry affordance -
/// simply did not exist on the routes pushed outside the shell. A real server
/// restart while the user sat on a `/system/*` detail screen left them looking
/// at "connect to a server to see this section" with no way back.
///
/// Mounted from `MaterialApp.router`'s `builder`, so it wraps every route
/// including ones pushed on top of the shell.
class ConnectionLostHost extends ConsumerStatefulWidget {
  const ConnectionLostHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectionLostHost> createState() => _ConnectionLostHostState();
}

class _ConnectionLostHostState extends ConsumerState<ConnectionLostHost>
    with WidgetsBindingObserver {
  static const resumeGracePeriod = Duration(seconds: 7);
  Timer? _graceTimer;
  bool _wasBackgrounded = false;
  bool _hideBannerDuringResumeGrace = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _graceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _wasBackgrounded = true;
        break;
      case AppLifecycleState.resumed:
        if (!_wasBackgrounded) return;
        _wasBackgrounded = false;
        _graceTimer?.cancel();
        setState(() => _hideBannerDuringResumeGrace = true);
        _graceTimer = Timer(resumeGracePeriod, () {
          if (mounted) setState(() => _hideBannerDuringResumeGrace = false);
        });
        break;
    }
  }

  Future<void> _reconnect(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await ref.read(connectionControllerProvider.notifier).reconnect();
    final state = ref.read(connectionControllerProvider);
    if (state.isConnected) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          // Prefer the server's own explanation; fall back to our wording.
          switch (state.error) {
            final error? => l10n.connectionMessage(error),
            _ => l10n.connectionLostReconnectFailed,
          },
        ),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionControllerProvider);
    if (!connection.isConnectionLost && !connection.isReconnecting) {
      return widget.child;
    }
    if (_hideBannerDuringResumeGrace) {
      return widget.child;
    }

    return Material(
      // Transparent so the routes below keep painting their own surfaces; this
      // Material exists only to give the banner a canvas to sit on.
      color: Colors.transparent,
      child: Column(
        children: [
          ConnectionLostBanner(
            message: switch (connection.error) {
              final error? => AppLocalizations.of(
                context,
              ).connectionMessage(error),
              _ => null,
            },
            serverName: connection.profile?.name,
            reconnecting: connection.isReconnecting,
            onReconnect: connection.isReconnecting
                ? null
                : () => _reconnect(context),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// Persistent notice shown while the transport is down.
///
/// Says three things, all of which matter during a restart: which server went
/// away, that everything on screen predates the drop, and how to retry.
class ConnectionLostBanner extends StatelessWidget {
  const ConnectionLostBanner({
    required this.onReconnect,
    this.reconnecting = false,
    this.message,
    this.serverName,
    super.key,
  });

  final VoidCallback? onReconnect;
  final bool reconnecting;
  final String? message;
  final String? serverName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serverName == null
                          ? l10n.connectionLostTitle
                          : l10n.connectionLostTitleNamed(serverName!),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Anything on screen predates the drop, so say so
                      // rather than letting it read as live.
                      // The server's own reason, when present, leads; the
                      // stale-data warning always follows it.
                      message == null
                          ? l10n.connectionLostStaleData
                          : '$message ${l10n.connectionLostStaleData}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (reconnecting)
                Semantics(
                  liveRegion: true,
                  label: l10n.actionReconnecting,
                  child: Padding(
                    key: const ValueKey('connection-reconnecting'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: colors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.actionReconnecting,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.onErrorContainer),
                        ),
                      ],
                    ),
                  ),
                )
              else
                TextButton(
                  key: const ValueKey('connection-reconnect-button'),
                  onPressed: onReconnect,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onErrorContainer,
                  ),
                  child: Text(l10n.actionReconnect),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
