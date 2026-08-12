import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../actions/presentation/server_action_controller.dart';
import '../../connection/domain/connection_message.dart';
import '../../connection/presentation/connection_message_localizations.dart';
import '../domain/pending_network_changes.dart';

/// The stage of a network commit/checkin workflow.
enum NetworkCommitStage {
  /// About to commit. The user must confirm before proceeding.
  pending,

  /// The commit job is running.
  committing,

  /// The commit job finished. We verify the connection survived before
  /// checking in; if it didn't, the server is already rolling back.
  verifying,

  /// Checking in the staged changes so they become permanent.
  checkingIn,

  /// The workflow completed successfully.
  done,

  /// The workflow was rolled back (either by the user or by the server's
  /// verification timeout).
  rolledBack,

  /// Something went wrong. [NetworkCommitSheetState.errorMessage] carries the
  /// detail.
  error,
}

class NetworkCommitSheetState {
  const NetworkCommitSheetState({
    this.stage = NetworkCommitStage.pending,
    this.commitJobId,
    this.checkInJobId,
    this.errorMessage,
    this.pending,
    this.loadingPending = false,
  });

  final NetworkCommitStage stage;
  final int? commitJobId;
  final int? checkInJobId;
  final String? errorMessage;

  /// What the server says is staged. Null until the preview read finishes, or
  /// when that read failed; the sheet still allows a commit in that case
  /// because refusing to act on a failed *read* would be worse than showing
  /// the generic warning.
  final PendingNetworkChanges? pending;
  final bool loadingPending;

  NetworkCommitSheetState copyWith({
    NetworkCommitStage? stage,
    int? commitJobId,
    int? checkInJobId,
    String? errorMessage,
    PendingNetworkChanges? pending,
    bool? loadingPending,
  }) => NetworkCommitSheetState(
    stage: stage ?? this.stage,
    commitJobId: commitJobId ?? this.commitJobId,
    checkInJobId: checkInJobId ?? this.checkInJobId,
    errorMessage: errorMessage,
    pending: pending ?? this.pending,
    loadingPending: loadingPending ?? this.loadingPending,
  );
}

/// Walks the user through the network commit/checkin workflow after staged
/// interface or static-route changes have been queued.
///
/// TrueNAS applies staged network changes through `interface.commit`, which
/// starts a rollback countdown. The caller must verify the new network
/// configuration works (i.e. the TrueDock session survives) and then call
/// `interface.checkin` to lock the changes in; otherwise the server reverts
/// them at the end of the verification window. This sheet makes that dance
/// explicit instead of hiding it behind a single button.
class NetworkCommitSheet extends ConsumerStatefulWidget {
  const NetworkCommitSheet({
    required this.serverName,
    required this.serverAddress,
    this.testChangedAddress,
    this.confirmChangedAddress,
    super.key,
  });

  final String serverName;
  final String serverAddress;

  /// Returns null after a successful authenticated connection test, otherwise
  /// a user-facing failure detail. Injectable so the safety flow is testable.
  final Future<ConnectionMessage?> Function(String address)? testChangedAddress;
  final Future<void> Function()? confirmChangedAddress;

  @override
  ConsumerState<NetworkCommitSheet> createState() => _NetworkCommitSheetState();
}

class _NetworkCommitSheetState extends ConsumerState<NetworkCommitSheet> {
  NetworkCommitSheetState _state = const NetworkCommitSheetState(
    loadingPending: true,
  );
  late final TextEditingController _addressController;
  bool _addressChanged = false;
  bool _testingAddress = false;
  bool _addressTestPassed = false;
  String? _addressTestError;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.serverAddress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPending();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  /// Reads what the server actually has staged before offering to commit it.
  /// If a commit is already in flight the sheet opens straight into the
  /// verification stage, because the countdown is already running and the user
  /// needs the check-in button rather than another commit button.
  Future<void> _loadPending() async {
    final pending = await ref
        .read(serverActionControllerProvider.notifier)
        .getPendingNetworkChanges();
    if (!mounted) return;
    setState(() {
      _state = _state.copyWith(
        pending: pending,
        loadingPending: false,
        stage: pending != null && pending.isAwaitingCheckIn
            ? NetworkCommitStage.verifying
            : _state.stage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.bolt_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l10n.sysNetCommitApplyAction,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _canClose()
                        ? () => Navigator.pop(context)
                        : null,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.actionClose,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(child: _body(theme, l10n)),
              const SizedBox(height: 12),
              _actions(theme, l10n),
            ],
          ),
        ),
      ),
    );
  }

  bool _canClose() {
    final stage = _state.stage;
    return stage == NetworkCommitStage.done ||
        stage == NetworkCommitStage.rolledBack ||
        stage == NetworkCommitStage.error ||
        stage == NetworkCommitStage.pending;
  }

  Widget _body(ThemeData theme, AppLocalizations l10n) {
    switch (_state.stage) {
      case NetworkCommitStage.pending:
        return _pendingBody(theme, l10n);
      case NetworkCommitStage.committing:
        return _loadingBody(
          theme,
          icon: Icons.cloud_sync_rounded,
          title: l10n.sysNetCommitCommittingTitle,
          body: l10n.sysNetCommitCommittingBody,
        );
      case NetworkCommitStage.verifying:
        return _verifyBody(theme, l10n);
      case NetworkCommitStage.checkingIn:
        return _loadingBody(
          theme,
          icon: Icons.verified_rounded,
          title: l10n.sysNetCommitCheckingInTitle,
          body: l10n.sysNetCommitCheckingInBody,
        );
      case NetworkCommitStage.done:
        return _resultBody(
          theme,
          icon: Icons.check_circle_rounded,
          color: theme.colorScheme.primary,
          title: l10n.sysNetCommitAppliedTitle,
          body: l10n.sysNetCommitAppliedBody(widget.serverName),
        );
      case NetworkCommitStage.rolledBack:
        return _resultBody(
          theme,
          icon: Icons.undo_rounded,
          color: theme.colorScheme.tertiary,
          title: l10n.sysNetCommitRolledBackTitle,
          body: l10n.sysNetCommitRolledBackBody(widget.serverName),
        );
      case NetworkCommitStage.error:
        return _resultBody(
          theme,
          icon: Icons.error_outline_rounded,
          color: theme.colorScheme.error,
          title: l10n.sysNetCommitFailedTitle,
          body: _state.errorMessage ?? l10n.sysNetCommitFailedBody,
        );
    }
  }

  Widget _pendingBody(ThemeData theme, AppLocalizations l10n) {
    final pending = _state.pending;
    return ListView(
      children: [
        if (_state.loadingPending)
          _Notice(
            icon: Icons.hourglass_top_rounded,
            message: l10n.sysNetCommitPendingChecking,
          )
        else if (pending != null)
          _Notice(
            icon: pending.isEmpty
                ? Icons.check_circle_outline_rounded
                : Icons.pending_actions_rounded,
            message: pending.isEmpty
                ? l10n.sysNetCommitPendingNone
                : l10n.sysNetCommitPendingStaged,
          ),
        if (pending != null && pending.fieldsClearedOnCheckIn.isNotEmpty) ...[
          const SizedBox(height: 14),
          _Notice(
            icon: Icons.link_off_rounded,
            message: l10n.sysNetCommitPendingClears(
              pending.fieldsClearedOnCheckIn.join(', '),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _Notice(
          icon: Icons.warning_amber_rounded,
          message: l10n.sysNetCommitWarning(widget.serverName),
        ),
        const SizedBox(height: 14),
        _Notice(
          icon: Icons.timer_outlined,
          message: l10n.sysNetCommitAfterNote,
        ),
      ],
    );
  }

  Widget _verifyBody(ThemeData theme, AppLocalizations l10n) {
    final remaining = _state.pending?.checkInSecondsRemaining;
    return ListView(
      children: [
        Icon(
          Icons.network_check_rounded,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.sysNetCommitVerifyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          remaining == null
              ? l10n.sysNetCommitVerifyBody(widget.serverName)
              : '${l10n.sysNetCommitVerifyBody(widget.serverName)}\n\n'
                    '${l10n.sysNetCommitPendingAwaitingCheckIn(remaining)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        CheckboxListTile(
          key: const ValueKey('network-address-changed'),
          contentPadding: EdgeInsets.zero,
          value: _addressChanged,
          title: Text(l10n.sysNetCommitAddressChangedQuestion),
          subtitle: Text(l10n.sysNetCommitAddressChangedHelp),
          onChanged: _testingAddress
              ? null
              : (value) => setState(() {
                  _addressChanged = value ?? false;
                  _addressTestPassed = false;
                  _addressTestError = null;
                }),
        ),
        if (_addressChanged) ...[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('network-new-server-address'),
            controller: _addressController,
            enabled: !_testingAddress,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.sysNetCommitNewAddress,
              hintText: 'https://192.168.1.10',
              errorText: _addressTestError,
              suffixIcon: _addressTestPassed
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {
              _addressTestPassed = false;
              _addressTestError = null;
            }),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('test-network-address'),
            onPressed: _testingAddress ? null : _testAddress,
            icon: _testingAddress
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded),
            label: Text(
              _testingAddress
                  ? l10n.sysNetCommitTestingAddress
                  : l10n.sysNetCommitTestAddress,
            ),
          ),
          if (_addressTestPassed) ...[
            const SizedBox(height: 10),
            _Notice(
              icon: Icons.verified_rounded,
              message: l10n.sysNetCommitAddressTestPassed,
            ),
          ],
        ],
      ],
    );
  }

  Widget _loadingBody(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _resultBody(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(ThemeData theme, AppLocalizations l10n) {
    switch (_state.stage) {
      case NetworkCommitStage.pending:
        return Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.sysNetCommitNotNow),
            ),
            const Spacer(),
            FilledButton.icon(
              // Blocked only when the server positively reported nothing
              // staged. A failed preview read leaves `pending` null and must
              // not lock the user out of committing.
              onPressed:
                  _state.loadingPending || (_state.pending?.isEmpty ?? false)
                  ? null
                  : _commit,
              icon: const Icon(Icons.bolt_rounded),
              label: Text(l10n.sysNetCommitCommitAction),
            ),
          ],
        );
      case NetworkCommitStage.verifying:
        return Row(
          children: [
            TextButton.icon(
              onPressed: _rollback,
              icon: const Icon(Icons.undo_rounded),
              label: Text(l10n.sysNetCommitRollbackAction),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _addressChanged && !_addressTestPassed
                  ? null
                  : _checkIn,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.sysNetCommitCheckInAction),
            ),
          ],
        );
      case NetworkCommitStage.done:
      case NetworkCommitStage.rolledBack:
      case NetworkCommitStage.error:
        return Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.sysNetCommitDone),
          ),
        );
      case NetworkCommitStage.committing:
      case NetworkCommitStage.checkingIn:
        return const Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        );
    }
  }

  Future<void> _commit() async {
    setState(
      () => _state = _state.copyWith(stage: NetworkCommitStage.committing),
    );
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .commitInterfaceChanges();
    if (!mounted) return;
    if (receipt == null) {
      setState(
        () => _state = _state.copyWith(
          stage: NetworkCommitStage.error,
          errorMessage: ref.read(serverActionControllerProvider).errorMessage,
        ),
      );
      return;
    }
    setState(
      () => _state = _state.copyWith(
        stage: NetworkCommitStage.verifying,
        commitJobId: receipt.jobId,
      ),
    );
  }

  Future<void> _checkIn() async {
    setState(
      () => _state = _state.copyWith(stage: NetworkCommitStage.checkingIn),
    );
    final receipt = await ref
        .read(serverActionControllerProvider.notifier)
        .checkInInterfaceChanges();
    if (!mounted) return;
    if (receipt == null) {
      setState(
        () => _state = _state.copyWith(
          stage: NetworkCommitStage.error,
          errorMessage: ref.read(serverActionControllerProvider).errorMessage,
        ),
      );
      return;
    }
    if (_addressChanged && _addressTestPassed) {
      try {
        await widget.confirmChangedAddress?.call();
      } on Object {
        if (!mounted) return;
        setState(
          () => _state = _state.copyWith(
            stage: NetworkCommitStage.error,
            errorMessage: AppLocalizations.of(
              context,
            ).sysNetCommitAddressSaveFailed,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(
      () => _state = _state.copyWith(
        stage: NetworkCommitStage.done,
        checkInJobId: receipt.jobId,
      ),
    );
  }

  Future<void> _testAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(
        () => _addressTestError = AppLocalizations.of(
          context,
        ).sysNetCommitAddressRequired,
      );
      return;
    }
    setState(() {
      _testingAddress = true;
      _addressTestPassed = false;
      _addressTestError = null;
    });
    final error =
        await (widget.testChangedAddress?.call(address) ??
            Future<ConnectionMessage?>.value(
              const ConnectionMessage.raw('connection_test_unavailable'),
            ));
    if (!mounted) return;
    setState(() {
      _testingAddress = false;
      _addressTestPassed = error == null;
      _addressTestError = error == null
          ? null
          : error.fallback == 'connection_test_unavailable'
          ? AppLocalizations.of(context).sysNetCommitTestUnavailable
          : AppLocalizations.of(context).connectionMessage(error);
    });
  }

  Future<void> _rollback() async {
    setState(
      () => _state = _state.copyWith(stage: NetworkCommitStage.checkingIn),
    );
    await ref
        .read(serverActionControllerProvider.notifier)
        .rollbackInterfaceChanges();
    if (!mounted) return;
    setState(
      () => _state = _state.copyWith(stage: NetworkCommitStage.rolledBack),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
