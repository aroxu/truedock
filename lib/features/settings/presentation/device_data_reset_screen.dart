import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/device_data_reset_service.dart';
import '../../../core/security/security_providers.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/device_data_reset_confirmation.dart';
import '../../../l10n/app_localizations.dart';
import '../../connection/presentation/connection_controller.dart';

/// Recovery page for a forgotten TrueDock PIN.
///
/// Only local TrueDock state is erased. Nothing on a TrueNAS server is
/// modified by this flow.
class DeviceDataResetScreen extends ConsumerStatefulWidget {
  const DeviceDataResetScreen({super.key});

  @override
  ConsumerState<DeviceDataResetScreen> createState() =>
      _DeviceDataResetScreenState();
}

class _DeviceDataResetScreenState extends ConsumerState<DeviceDataResetScreen> {
  final _controller = TextEditingController();
  late final String _expected = generateDeviceDataResetCode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final confirmed = matchesDeviceDataResetCode(_controller.text, _expected);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appDataResetTitle),
        leading: IconButton(
          onPressed: _busy
              ? null
              : () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.actionClose,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 52,
                    color: colors.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.appDataResetDialogTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: colors.error),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appDataResetDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appDataResetIrreversible,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appDataResetTypePrompt(_expected),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  DeviceDataResetCodeField(
                    key: const ValueKey('reset-all-device-data-confirmation'),
                    controller: _controller,
                    enabled: !_busy,
                    autofocus: true,
                    semanticLabel: l10n.appDataResetCodeLabel,
                    errorText: _error,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) {
                      if (confirmed && !_busy) _reset();
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    onPressed: confirmed && !_busy ? _reset : null,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(l10n.appDataResetAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deviceDataResetterProvider).reset();
      ref.invalidate(savedServersProvider);
      await ref.read(savedServersProvider.future);
      ref.invalidate(appPasswordConfiguredProvider);
      ref.invalidate(biometricUnlockEnabledProvider);
      ref.invalidate(themeControllerProvider);
      if (!mounted) return;
      await _showResetCompleteDialog();
      if (!mounted) return;
      await ref
          .read(connectionControllerProvider.notifier)
          .clearSessionForDeviceReset();
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.go('/');
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context).appDataResetFailed;
      });
    }
  }

  Future<void> _showResetCompleteDialog() {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.appDataResetCompleteTitle),
        content: Text(l10n.appDataResetCompleteDescription),
        actions: [
          FilledButton(
            key: const ValueKey('device-data-reset-complete'),
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.appDataResetCompleteAction),
          ),
        ],
      ),
    );
  }
}
