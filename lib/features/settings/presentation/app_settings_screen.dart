import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/safe_refresh_indicator.dart';

import '../../../core/security/security_providers.dart';
import '../../../core/security/app_password_vault.dart';
import '../../../core/security/tls_certificate_service.dart';
import '../../../core/diagnostics/diagnostics_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../connection/presentation/connection_controller.dart';
import '../../connection/domain/server_profile.dart';
import 'device_data_reset_screen.dart';
import '../../system/presentation/system_screen.dart' show AppearanceSheet;

/// Settings for TrueDock itself and its registered server profiles.
///
/// TrueNAS administration remains in [SystemScreen]; local app preferences and
/// connection profiles live here so users do not confuse them with server
/// configuration.
class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _securityBusy = false;

  @override
  void initState() {
    super.initState();
    // Device security may have changed since onboarding. In particular, the
    // iOS Simulator can enroll Face ID without sending an app lifecycle event.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(biometricVaultAvailabilityProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final savedServers = ref.watch(savedServersProvider);
    final appPasswordConfigured = ref.watch(appPasswordConfiguredProvider);
    final biometricSupport = ref.watch(biometricVaultAvailabilityProvider);
    final biometricEnabled = ref.watch(biometricUnlockEnabledProvider);
    final themeSettings = ref.watch(themeControllerProvider);
    final diagnostics = ref.watch(diagnosticsSettingsProvider);
    final diagnosticsConfigured = ref
        .watch(diagnosticsBackendProvider)
        .isConfigured;

    ref.listen(diagnosticsSettingsProvider, (previous, next) {
      if (previous?.updateFailed == true || !next.updateFailed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.diagnosticsUpdateFailed)));
        ref.read(diagnosticsSettingsProvider.notifier).clearUpdateFailure();
      });
    });

    return SafeRefreshIndicator(
      onRefresh: () async {
        ref.invalidate(savedServersProvider);
        ref.invalidate(biometricVaultAvailabilityProvider);
        await Future.wait([
          ref.read(savedServersProvider.future),
          ref.read(biometricVaultAvailabilityProvider.future),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(title: Text(l10n.navAppSettings)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        leading: const Icon(Icons.palette_outlined),
                        title: Text(l10n.systemAppearance),
                        subtitle: Text(l10n.systemAppearanceSubtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => const AppearanceSheet(),
                        ),
                      ),
                      const Divider(indent: 68, height: 1),
                      SwitchListTile(
                        key: const ValueKey('reduce-animations-setting'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        secondary: const Icon(Icons.motion_photos_off_outlined),
                        title: Text(l10n.systemReduceAnimations),
                        subtitle: Text(l10n.systemReduceAnimationsSubtitle),
                        value: themeSettings.reduceAnimations,
                        onChanged: (value) => ref
                            .read(themeControllerProvider.notifier)
                            .setReduceAnimations(value),
                      ),
                      const Divider(indent: 68, height: 1),
                      SwitchListTile(
                        key: const ValueKey('app-password-setting'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        secondary: const Icon(Icons.password_rounded),
                        title: Text(l10n.systemProtectedSignIn),
                        subtitle: Text(
                          appPasswordConfigured.when(
                            data: (configured) => configured
                                ? savedServers.when(
                                    data: (servers) => l10n.systemSavedSignIns(
                                      servers
                                          .where(
                                            (server) =>
                                                server.hasSavedCredential,
                                          )
                                          .length,
                                    ),
                                    loading: () =>
                                        l10n.systemCheckingDeviceSecurity,
                                    error: (_, _) =>
                                        l10n.systemAppPasswordEnabled,
                                  )
                                : l10n.systemAppPasswordDisabled,
                            loading: () => l10n.systemCheckingDeviceSecurity,
                            error: (_, _) => l10n.systemAppPasswordDisabled,
                          ),
                        ),
                        value: appPasswordConfigured.value ?? false,
                        onChanged:
                            _securityBusy || appPasswordConfigured.isLoading
                            ? null
                            : _toggleAppPassword,
                      ),
                      if (appPasswordConfigured.value == true) ...[
                        const Divider(indent: 68, height: 1),
                        ListTile(
                          key: const ValueKey('change-app-password'),
                          enabled: !_securityBusy,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          leading: const Icon(Icons.password_rounded),
                          title: Text(l10n.systemChangeAppPassword),
                          subtitle: Text(l10n.systemChangeAppPasswordSubtitle),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _securityBusy ? null : _changeAppPassword,
                        ),
                      ],
                      const Divider(indent: 68, height: 1),
                      SwitchListTile(
                        key: const ValueKey('biometric-unlock-setting'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        secondary: const Icon(Icons.fingerprint_rounded),
                        title: Text(l10n.authBiometricUnlock),
                        subtitle: Text(
                          biometricSupport.when(
                            data: (support) => support.canSave
                                ? l10n.authBiometricUnlockDescription
                                : l10n.systemBiometricUnavailable,
                            loading: () => l10n.systemCheckingDeviceSecurity,
                            error: (_, _) => l10n.systemBiometricUnavailable,
                          ),
                        ),
                        value:
                            (biometricEnabled.value ?? false) &&
                            (appPasswordConfigured.value ?? false),
                        onChanged:
                            _securityBusy ||
                                biometricEnabled.isLoading ||
                                biometricSupport.value?.canSave != true ||
                                appPasswordConfigured.value != true
                            ? null
                            : _toggleBiometricUnlock,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.systemServerSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        leading: const Icon(Icons.dns_outlined),
                        title: Text(
                          connection.profile?.name ?? l10n.systemNoServer,
                        ),
                        subtitle: Text(
                          connection.profile?.baseUri.host ??
                              l10n.systemConnectServer,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings/servers'),
                      ),
                      if (connection.isConnected) ...[
                        const Divider(indent: 68, height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          leading: const Icon(Icons.logout_rounded),
                          title: Text(l10n.systemDisconnect),
                          onTap: () => ref
                              .read(connectionControllerProvider.notifier)
                              .disconnect(),
                        ),
                      ],
                      if (connection.profile?.pinnedCertificateSha256 !=
                          null) ...[
                        const Divider(indent: 68, height: 1),
                        ListTile(
                          key: const ValueKey('trusted-certificate-details'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(l10n.systemPinnedCertificate),
                          subtitle: Text(
                            _shortFingerprint(
                              connection.profile!.pinnedCertificateSha256!,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              _showTrustedCertificate(connection.profile!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.diagnosticsPrivacySection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    key: const ValueKey('anonymous-diagnostics-setting'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    secondary: const Icon(Icons.monitor_heart_outlined),
                    title: Text(l10n.diagnosticsAnonymousTitle),
                    subtitle: Text(
                      !diagnosticsConfigured
                          ? l10n.diagnosticsNotConfigured
                          : diagnostics.isUpdating
                          ? l10n.diagnosticsSaving
                          : l10n.diagnosticsAnonymousDescription,
                    ),
                    value: diagnostics.enabled,
                    onChanged: !diagnostics.isLoaded || diagnostics.isUpdating
                        ? null
                        : (value) => _handleDiagnosticsToggle(value),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appDataDangerSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    key: const ValueKey('reset-all-device-data'),
                    enabled: !_securityBusy,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.appDataResetTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: Text(l10n.appDataResetSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _securityBusy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DeviceDataResetScreen(),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortFingerprint(String fingerprint) {
    final compact = fingerprint.replaceAll(':', '').toUpperCase();
    if (compact.length <= 24) return compact;
    return '${compact.substring(0, 12)}…${compact.substring(compact.length - 12)}';
  }

  Future<void> _showTrustedCertificate(ServerProfile profile) {
    final certificate = ref
        .read(tlsCertificateInspectorProvider)
        .inspect(profile.baseUri);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => TrustedCertificateDetailsSheet(
        profile: profile,
        certificate: certificate,
      ),
    );
  }

  Future<void> _toggleAppPassword(bool enabled) async {
    if (enabled) {
      final password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _SecurityPasswordDialog(create: true),
      );
      if (password == null || !mounted) return;
      await _runSecurityAction(() async {
        await ref
            .read(connectionControllerProvider.notifier)
            .configureAppPassword(password);
        ref.invalidate(appPasswordConfiguredProvider);
      });
      return;
    }
    final confirmed = await _confirmDisableAppPassword();
    if (!confirmed || !mounted) return;
    await _runSecurityAction(() async {
      await ref
          .read(connectionControllerProvider.notifier)
          .clearAllAppPasswordCredentials();
      ref.invalidate(appPasswordConfiguredProvider);
      ref.invalidate(biometricUnlockEnabledProvider);
    });
  }

  Future<void> _toggleBiometricUnlock(bool enabled) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SecurityPasswordDialog(create: false),
    );
    if (password == null || !mounted) return;
    await _runSecurityAction(() async {
      await ref
          .read(connectionControllerProvider.notifier)
          .setBiometricUnlockEnabled(appPassword: password, enabled: enabled);
      ref.invalidate(biometricUnlockEnabledProvider);
    });
  }

  Future<void> _changeAppPassword() async {
    final result = await showDialog<({String current, String next})>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ChangeAppPasswordDialog(),
    );
    if (result == null || !mounted) return;
    await _runSecurityAction(() async {
      await ref
          .read(connectionControllerProvider.notifier)
          .changeAppPassword(
            currentPassword: result.current,
            newPassword: result.next,
          );
      ref.invalidate(appPasswordConfiguredProvider);
    });
  }

  Future<void> _runSecurityAction(Future<void> Function() action) async {
    setState(() => _securityBusy = true);
    try {
      await action();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).appPasswordIncorrect),
        ),
      );
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  Future<bool> _confirmDisableAppPassword() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            icon: const Icon(Icons.lock_reset_rounded),
            title: Text(l10n.appPasswordResetTitle),
            content: Text(l10n.appPasswordResetDescription),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.appPasswordResetAction),
              ),
            ],
          );
        },
      ) ??
      false;

  Future<void> _handleDiagnosticsToggle(bool value) async {
    final notifier = ref.read(diagnosticsSettingsProvider.notifier);
    if (value) {
      await notifier.setEnabled(true);
      return;
    }
    final confirmed = await _confirmDisableDiagnostics();
    if (!confirmed) return;
    await notifier.setEnabled(false);
  }

  Future<bool> _confirmDisableDiagnostics() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            icon: const Icon(Icons.monitor_heart_outlined),
            title: Text(l10n.diagnosticsDisclosureTitle),
            content: Text(l10n.diagnosticsAnonymousDescription),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.diagnosticsDisableAction),
              ),
            ],
          );
        },
      ) ??
      false;
}

class TrustedCertificateDetailsSheet extends StatelessWidget {
  const TrustedCertificateDetailsSheet({
    required this.profile,
    required this.certificate,
    super.key,
  });

  final ServerProfile profile;
  final Future<TlsCertificateIdentity> certificate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: FutureBuilder<TlsCertificateIdentity>(
        future: certificate,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final identity = snapshot.data;
          if (identity == null) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.gpp_bad_outlined,
                    size: 44,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.certificateDetailsLoadFailed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.actionClose),
                  ),
                ],
              ),
            );
          }

          final pinned = profile.pinnedCertificateSha256!
              .replaceAll(':', '')
              .toLowerCase();
          final matches = pinned == identity.sha256.toLowerCase();
          final colors = Theme.of(context).colorScheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  matches
                      ? Icons.verified_user_outlined
                      : Icons.gpp_bad_outlined,
                  size: 44,
                  color: matches ? colors.primary : colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.systemPinnedCertificate,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.certificateDetailsDescription(profile.baseUri.authority),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                _CertificateDetailsField(
                  label: l10n.certificateTrustStatus,
                  value: matches
                      ? l10n.certificatePinnedAndMatched
                      : l10n.certificatePinnedMismatch,
                  valueColor: matches ? colors.primary : colors.error,
                ),
                _CertificateDetailsField(
                  label: l10n.certificateFingerprint,
                  value: identity.formattedSha256,
                  monospace: true,
                ),
                _CertificateDetailsField(
                  label: l10n.certificateSubject,
                  value: identity.subject,
                ),
                _CertificateDetailsField(
                  label: l10n.certificateIssuer,
                  value: identity.issuer,
                ),
                _CertificateDetailsField(
                  label: l10n.certificateValidFrom,
                  value: _certificateDate(context, identity.validFrom),
                ),
                _CertificateDetailsField(
                  label: l10n.certificateValidUntil,
                  value: _certificateDate(context, identity.validTo),
                  valueColor: identity.isExpiredAt(DateTime.now())
                      ? colors.error
                      : identity.isExpiringSoonAt(DateTime.now())
                      ? colors.error
                      : null,
                ),
                if (identity.isExpiredAt(DateTime.now()))
                  _CertificateStatusBanner(
                    icon: Icons.gpp_bad_outlined,
                    text: l10n.certificateExpiredWarning,
                    color: colors.error,
                  )
                else if (identity.isExpiringSoonAt(DateTime.now()))
                  _CertificateStatusBanner(
                    icon: Icons.warning_amber_rounded,
                    text: l10n.certificateExpiringSoonWarning,
                    color: colors.error,
                  ),
                _CertificateDetailsField(
                  label: l10n.certificateSystemTrust,
                  value: identity.isTrustedBySystem
                      ? l10n.certificateSystemTrusted
                      : l10n.certificateTrueDockTrustedOnly,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _certificateDate(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatFullDate(local);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date $time';
  }
}

class _CertificateStatusBanner extends StatelessWidget {
  const _CertificateStatusBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CertificateDetailsField extends StatelessWidget {
  const _CertificateDetailsField({
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: monospace ? 'monospace' : null,
            color: valueColor,
          ),
        ),
      ],
    ),
  );
}

class _SecurityPasswordDialog extends StatefulWidget {
  const _SecurityPasswordDialog({required this.create});

  final bool create;

  @override
  State<_SecurityPasswordDialog> createState() =>
      _SecurityPasswordDialogState();
}

class _SecurityPasswordDialogState extends State<_SecurityPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: Icon(
        widget.create ? Icons.password_rounded : Icons.fingerprint_rounded,
      ),
      title: Text(
        widget.create
            ? l10n.appPasswordCreateTitle
            : l10n.appPasswordExistingTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.create
                ? l10n.appPasswordCreateDescription
                : l10n.appPasswordExistingDescription,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('settings-app-password'),
            controller: _password,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(trueDockPinLength),
            ],
            decoration: InputDecoration(
              labelText: l10n.appPasswordLabel,
              errorText: _error,
            ),
          ),
          if (widget.create) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('settings-app-password-confirm'),
              controller: _confirmation,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(trueDockPinLength),
              ],
              decoration: InputDecoration(
                labelText: l10n.appPasswordConfirmLabel,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionContinue)),
      ],
    );
  }

  void _submit() {
    final value = _password.text;
    if (!isValidTrueDockPin(value)) {
      setState(() => _error = AppLocalizations.of(context).appPasswordMinimum);
      return;
    }
    if (widget.create && value != _confirmation.text) {
      setState(() => _error = AppLocalizations.of(context).appPasswordMismatch);
      return;
    }
    Navigator.pop(context, value);
  }
}

class _ChangeAppPasswordDialog extends StatefulWidget {
  const _ChangeAppPasswordDialog();

  @override
  State<_ChangeAppPasswordDialog> createState() =>
      _ChangeAppPasswordDialogState();
}

class _ChangeAppPasswordDialogState extends State<_ChangeAppPasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.password_rounded),
      title: Text(l10n.systemChangeAppPassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.systemChangeAppPasswordDescription),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('current-app-password'),
              controller: _current,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(trueDockPinLength),
              ],
              decoration: InputDecoration(
                labelText: l10n.systemCurrentAppPassword,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('new-app-password'),
              controller: _next,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(trueDockPinLength),
              ],
              decoration: InputDecoration(labelText: l10n.systemNewAppPassword),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('new-app-password-confirm'),
              controller: _confirmation,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(trueDockPinLength),
              ],
              decoration: InputDecoration(
                labelText: l10n.appPasswordConfirmLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionContinue)),
      ],
    );
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (!isValidTrueDockPin(_current.text) || !isValidTrueDockPin(_next.text)) {
      setState(() => _error = l10n.appPasswordMinimum);
      return;
    }
    if (_next.text != _confirmation.text) {
      setState(() => _error = l10n.appPasswordMismatch);
      return;
    }
    if (_current.text == _next.text) {
      setState(() => _error = l10n.systemAppPasswordMustChange);
      return;
    }
    Navigator.pop(context, (current: _current.text, next: _next.text));
  }
}
