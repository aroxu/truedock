import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/security_providers.dart';
import '../../../core/security/app_password_vault.dart';
import '../../../core/security/tls_certificate_service.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/otp_code_field.dart';
import '../data/saved_server_repository.dart';
import '../domain/auth_credential.dart';
import '../domain/server_profile.dart';
import 'connection_controller.dart';
import 'connection_message_localizations.dart';
import '../../../l10n/app_localizations.dart';

/// Resolves a registered server from durable state before opening its
/// authentication form. Routes carry only the stable profile id so GoRouter
/// restoration never needs to serialize or cast a [SavedServer] object.
class SavedServerAuthenticationScreen extends ConsumerStatefulWidget {
  const SavedServerAuthenticationScreen({required this.serverId, super.key});

  final String serverId;

  @override
  ConsumerState<SavedServerAuthenticationScreen> createState() =>
      _SavedServerAuthenticationScreenState();
}

class _SavedServerAuthenticationScreenState
    extends ConsumerState<SavedServerAuthenticationScreen> {
  String? _startedServerId;
  bool? _isSwitching;
  bool _credentialVerified = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(savedServersProvider)
        .when(
          data: (servers) {
            final server = servers
                .where((entry) => entry.profile.id == widget.serverId)
                .firstOrNull;
            if (server != null) {
              if (_startedServerId != server.profile.id) {
                _startedServerId = server.profile.id;
                _isSwitching = ref
                    .read(connectionControllerProvider)
                    .isConnected;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _switchTo(server);
                });
              }
              return _buildSwitchingScreen(server);
            }
            return _SavedServerAuthenticationUnavailable(
              message: l10n.serverManagementLoadFailed,
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => _SavedServerAuthenticationUnavailable(
            message: l10n.serverManagementLoadFailed,
          ),
        );
  }

  Widget _buildSwitchingScreen(SavedServer server) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      // Signing in and switching servers cannot be interrupted midway: the
      // credential prompt/biometric flow already owns its own cancellation,
      // and leaving this screen while a connection attempt is in flight
      // would strand the controller mid-transition. Back only becomes
      // available once authentication has actually failed.
      canPop: _error != null,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Icon(
                          _isSwitching == true
                              ? Icons.swap_horiz_rounded
                              : Icons.login_rounded,
                          size: 42,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      server.profile.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: context.motionDuration(AppMotion.quick),
                      child: Text(
                        _error ??
                            (_credentialVerified
                                ? l10n.authSucceededSigningIn(
                                    server.profile.name,
                                  )
                                : _isSwitching == true
                                ? l10n.serverSwitching
                                : l10n.serverSigningIn),
                        key: _credentialVerified
                            ? const ValueKey('authenticated-signing-in')
                            : ValueKey((_error, _credentialVerified)),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _error == null
                              ? colors.onSurfaceVariant
                              : colors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error == null)
                      const CircularProgressIndicator()
                    else
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _credentialVerified = false;
                          });
                          _switchTo(server);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.actionReconnect),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switchTo(SavedServer server) async {
    if (!server.hasSavedCredential) {
      final credential = await showDialog<AuthCredential>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SavedServerCredentialDialog(server: server),
      );
      if (!mounted) return;
      if (credential == null) {
        if (context.canPop()) context.pop();
        return;
      }
      setState(() => _credentialVerified = true);
      final controller = ref.read(connectionControllerProvider.notifier);
      await controller.disconnect();
      await controller.connect(server.profile, credential);
      if (mounted) await _handleConnectionResult();
      return;
    }

    final controller = ref.read(connectionControllerProvider.notifier);
    try {
      if (server.credentialProtection ==
          CredentialProtection.appPasswordWithBiometric) {
        final unlocked = await controller.switchToSavedWithBiometrics(
          server,
          onCredentialUnlocked: () {
            if (mounted) setState(() => _credentialVerified = true);
          },
        );
        if (!mounted) return;
        if (!unlocked) {
          final pin = await _requestPin(server);
          if (!mounted) return;
          if (pin == null) {
            if (context.canPop()) context.pop();
            return;
          }
          setState(() => _credentialVerified = true);
          await controller.switchToSavedWithAppPassword(server, pin);
        }
      } else if (server.credentialProtection ==
          CredentialProtection.appPassword) {
        final pin = await _requestPin(server);
        if (!mounted) return;
        if (pin == null) {
          if (context.canPop()) context.pop();
          return;
        }
        setState(() => _credentialVerified = true);
        await controller.switchToSavedWithAppPassword(server, pin);
      } else {
        await controller.switchToSaved(server);
      }
      if (mounted) await _handleConnectionResult();
    } on Object {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(
          context,
        ).savedServerAuthenticationFailed,
      );
    }
  }

  Future<String?> _requestPin(SavedServer server) async {
    String? errorText;
    while (mounted) {
      if (!mounted) return null;
      final result = await showDialog<_AppPasswordUnlockResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _AppPasswordUnlockDialog(server: server, errorText: errorText),
      );
      if (result == null || !mounted) return null;
      if (result.reset) {
        await context.push('/app-data/reset');
        if (!mounted) return null;
        continue;
      }
      try {
        await ref
            .read(connectionControllerProvider.notifier)
            .verifyAppPassword(result.password!);
        return result.password;
      } on Object {
        if (!mounted) return null;
        errorText = AppLocalizations.of(context).appPasswordIncorrect;
      }
    }
    return null;
  }

  Future<void> _handleConnectionResult() async {
    while (mounted) {
      final connection = ref.read(connectionControllerProvider);
      switch (connection.stage) {
        case ConnectionStage.connected:
          if (!mounted) return;
          context.go('/');
          return;
        case ConnectionStage.awaitingCertificateTrust:
          final certificate = connection.certificate;
          final profile = connection.profile;
          if (certificate == null || profile == null) return;
          if (!mounted) return;
          final approved = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            isDismissible: false,
            enableDrag: false,
            builder: (context) => _CertificateTrustSheet(
              profile: profile,
              certificate: certificate,
              previousFingerprint: connection.previousCertificateSha256,
              isExpired: connection.isCertificateExpired,
            ),
          );
          if (approved != true || !mounted) return;
          await ref
              .read(connectionControllerProvider.notifier)
              .trustCertificate();
          continue;
        case ConnectionStage.awaitingOtp:
          if (!mounted) return;
          final otp = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const _OtpDialog(),
          );
          if (otp == null || !mounted) return;
          await ref.read(connectionControllerProvider.notifier).submitOtp(otp);
          continue;
        case ConnectionStage.failure:
          setState(
            () => _error = connection.error == null
                ? AppLocalizations.of(context).connectionLostReconnectFailed
                : AppLocalizations.of(
                    context,
                  ).connectionMessage(connection.error!),
          );
          return;
        case ConnectionStage.disconnected:
        case ConnectionStage.connecting:
        case ConnectionStage.connectionLost:
          return;
      }
    }
  }
}

class _SavedServerCredentialDialog extends StatefulWidget {
  const _SavedServerCredentialDialog({required this.server});

  final SavedServer server;

  @override
  State<_SavedServerCredentialDialog> createState() =>
      _SavedServerCredentialDialogState();
}

class _SavedServerCredentialDialogState
    extends State<_SavedServerCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final password = widget.server.authMethod == AuthMethod.password;
    return AlertDialog(
      icon: Icon(password ? Icons.password_rounded : Icons.key_rounded),
      title: Text(l10n.savedServerSignInTitle(widget.server.profile.name)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.authUsername}: ${widget.server.username}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: password ? l10n.authPassword : l10n.authApiKey,
                prefixIcon: Icon(
                  password ? Icons.lock_outline_rounded : Icons.key_rounded,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscure
                      ? l10n.authShowCredential
                      : l10n.authHideCredential,
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? l10n.authCredentialRequired
                  : null,
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final username = widget.server.username;
    Navigator.pop(
      context,
      widget.server.authMethod == AuthMethod.password
          ? PasswordCredential(username: username, password: _controller.text)
          : ApiKeyCredential(username: username, apiKey: _controller.text),
    );
  }
}

class _SavedServerAuthenticationUnavailable extends StatelessWidget {
  const _SavedServerAuthenticationUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        icon: const Icon(Icons.close_rounded),
        tooltip: AppLocalizations.of(context).actionClose,
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}

class ServerRegistrationScreen extends ConsumerStatefulWidget {
  const ServerRegistrationScreen({
    super.key,
    this.canClose = true,
    this.initialServer,
  });

  /// False when this is the application's entry screen and there is nowhere
  /// meaningful to navigate back to.
  final bool canClose;

  /// An already registered server selected for authentication. Protected
  /// entries reconnect automatically; metadata-only entries show only the
  /// credential form, never the new-server fields.
  final SavedServer? initialServer;

  @override
  ConsumerState<ServerRegistrationScreen> createState() =>
      _ServerRegistrationScreenState();
}

class _ServerRegistrationScreenState
    extends ConsumerState<ServerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _secretController = TextEditingController();
  final _credentialFormStartKey = GlobalKey();
  // Ordinary login is the default because it is the credential a new user
  // already has; an API key has to be created in the web UI first. The
  // API-key segment stays one tap away and is still the recommended choice
  // for a long-lived registration, since it can be revoked on its own.
  AuthMethod _method = AuthMethod.password;
  bool _obscureSecret = true;
  bool _keepSignedIn = false;
  bool _enableBiometricUnlock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(biometricVaultAvailabilityProvider);
    });
    ref.read(biometricUnlockEnabledProvider.future).then((enabled) {
      if (mounted) setState(() => _enableBiometricUnlock = enabled);
    });
    final server = widget.initialServer;
    if (server == null) return;
    _fillRegisteredServer(server);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (server.hasSavedCredential) {
        _connectSaved(server);
      } else {
        _focusCredentialFor(server);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(connectionControllerProvider);
    final isBusy = connection.stage == ConnectionStage.connecting;
    final biometricSupport = ref.watch(biometricVaultAvailabilityProvider);
    final registeredServer = widget.initialServer;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          registeredServer == null
              ? widget.canClose
                    ? l10n.connectTitle
                    : l10n.registrationTitle
              : l10n.savedServerSignInTitle(registeredServer.profile.name),
        ),
        leading: widget.canClose
            ? IconButton(
                onPressed: context.pop,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.actionClose,
              )
            : null,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (registeredServer == null) ...[
                      const _ConnectionHero(),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: _credentialFormStartKey,
                        enabled: !isBusy,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.connectServerName,
                          hintText: l10n.connectServerNameHint,
                          prefixIcon: const Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        enabled: !isBusy,
                        controller: _addressController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: l10n.connectSecureAddress,
                          hintText: l10n.connectSecureAddressHint,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          helperText: l10n.connectSecureAddressHelper,
                        ),
                        validator: (value) {
                          try {
                            ServerProfile.parse(
                              name: _nameController.text,
                              address: value ?? '',
                            );
                            return null;
                          } on FormatException catch (error) {
                            return error.message;
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text(
                        l10n.savedServerEnterCredential(
                          registeredServer.profile.name,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      l10n.connectSignInWith,
                      key: registeredServer == null
                          ? null
                          : _credentialFormStartKey,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<AuthMethod>(
                      segments: [
                        ButtonSegment(
                          value: AuthMethod.password,
                          icon: const Icon(Icons.person_outline_rounded),
                          label: Text(l10n.authLogin),
                        ),
                        ButtonSegment(
                          value: AuthMethod.apiKey,
                          icon: const Icon(Icons.key_rounded),
                          label: Text(l10n.authApiKey),
                        ),
                      ],
                      selected: {_method},
                      onSelectionChanged: isBusy
                          ? null
                          : (selection) {
                              setState(() {
                                _method = selection.first;
                                _secretController.clear();
                              });
                            },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      enabled: !isBusy,
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.authUsername,
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? l10n.authUsernameRequired
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      enabled: !isBusy,
                      controller: _secretController,
                      obscureText: _obscureSecret,
                      autocorrect: false,
                      enableSuggestions: false,
                      onFieldSubmitted: isBusy ? null : (_) => _connect(),
                      decoration: InputDecoration(
                        labelText: _method == AuthMethod.apiKey
                            ? l10n.authApiKey
                            : l10n.authPassword,
                        prefixIcon: Icon(
                          _method == AuthMethod.apiKey
                              ? Icons.vpn_key_outlined
                              : Icons.password_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: isBusy
                              ? null
                              : () => setState(
                                  () => _obscureSecret = !_obscureSecret,
                                ),
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscureSecret
                              ? l10n.authShowCredential
                              : l10n.authHideCredential,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? l10n.authCredentialRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _keepSignedIn,
                      onChanged: !isBusy
                          ? (value) => setState(() {
                              _keepSignedIn = value;
                              if (!_keepSignedIn) {
                                _enableBiometricUnlock = false;
                              }
                            })
                          : null,
                      title: Text(l10n.authKeepSignedIn),
                      subtitle: Text(l10n.authProtectWithAppPassword),
                    ),
                    biometricSupport.when(
                      data: (support) => support.canSave
                          ? SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _keepSignedIn && _enableBiometricUnlock,
                              onChanged: _keepSignedIn && !isBusy
                                  ? (value) => setState(
                                      () => _enableBiometricUnlock = value,
                                    )
                                  : null,
                              secondary: const Icon(Icons.fingerprint_rounded),
                              title: Text(l10n.authBiometricUnlock),
                              subtitle: Text(
                                l10n.authBiometricUnlockDescription,
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    if (connection.error case final error?) ...[
                      const SizedBox(height: 16),
                      _InlineError(message: l10n.connectionMessage(error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isBusy ? null : _connect,
                      icon: isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link_rounded),
                      label: Text(
                        isBusy
                            ? l10n.authConnectingSecurely
                            : l10n.actionConnectServer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.authTransportNotice,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    String? appPassword;
    if (_keepSignedIn) {
      // App Settings and onboarding must use one authoritative configured
      // state. Consulting the controller's repository separately could race a
      // provider refresh after a PIN was created and incorrectly reopen the
      // two-field "Create PIN" dialog while adding another server.
      final configured = await ref.read(appPasswordConfiguredProvider.future);
      if (!mounted) return;
      final password = await _requestAppPassword(configured: configured);
      if (password == null || !mounted) return;
      appPassword = password;
    }
    FocusScope.of(context).unfocus();
    final profile = ServerProfile.parse(
      name: _nameController.text,
      address: _addressController.text,
    );
    final credential = switch (_method) {
      AuthMethod.apiKey => ApiKeyCredential(
        username: _usernameController.text.trim(),
        apiKey: _secretController.text,
      ),
      AuthMethod.password => PasswordCredential(
        username: _usernameController.text.trim(),
        password: _secretController.text,
      ),
    };
    await ref
        .read(connectionControllerProvider.notifier)
        .connect(
          profile,
          credential,
          keepSignedIn: _keepSignedIn,
          appPassword: appPassword,
          enableBiometricUnlock: _enableBiometricUnlock,
        );
    appPassword = null;
    if (!mounted) return;
    await _handleConnectionResult();
  }

  Future<void> _handleConnectionResult() async {
    while (mounted) {
      if (!mounted) return;
      final connection = ref.read(connectionControllerProvider);
      switch (connection.stage) {
        case ConnectionStage.connected:
          final notice = connection.notice;
          if (notice != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).connectionMessage(notice),
                ),
              ),
            );
          }
          context.go('/');
          return;
        case ConnectionStage.awaitingCertificateTrust:
          final certificate = connection.certificate;
          final profile = connection.profile;
          if (certificate == null || profile == null) return;
          if (!mounted) return;
          final approved = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            isDismissible: false,
            enableDrag: false,
            builder: (context) => _CertificateTrustSheet(
              profile: profile,
              certificate: certificate,
              previousFingerprint: connection.previousCertificateSha256,
              isExpired: connection.isCertificateExpired,
            ),
          );
          if (approved != true || !mounted) return;
          await ref
              .read(connectionControllerProvider.notifier)
              .trustCertificate();
          continue;
        case ConnectionStage.awaitingOtp:
          if (!mounted) return;
          final otp = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const _OtpDialog(),
          );
          if (otp == null || !mounted) return;
          await ref.read(connectionControllerProvider.notifier).submitOtp(otp);
          continue;
        case ConnectionStage.disconnected:
        case ConnectionStage.connecting:
        case ConnectionStage.failure:
        // A live connection can only drop after this screen has navigated
        // away, so there is nothing to resolve here.
        case ConnectionStage.connectionLost:
          return;
      }
    }
  }

  Future<void> _connectSaved(SavedServer server) async {
    if (server.credentialProtection ==
        CredentialProtection.appPasswordWithBiometric) {
      final unlocked = await ref
          .read(connectionControllerProvider.notifier)
          .switchToSavedWithBiometrics(server);
      if (!mounted) return;
      if (unlocked) {
        await _handleConnectionResult();
        return;
      }
    }
    if (server.credentialProtection == CredentialProtection.appPassword ||
        server.credentialProtection ==
            CredentialProtection.appPasswordWithBiometric) {
      final result = await _requestAppPasswordUnlock(server);
      if (result == null || !mounted) return;
      if (result.reset) {
        final cleared = await _confirmClearAppPassword();
        if (!cleared || !mounted) return;
        await ref
            .read(connectionControllerProvider.notifier)
            .clearAllAppPasswordCredentials();
        _prepareRegisteredServer(server);
        return;
      }
      await ref
          .read(connectionControllerProvider.notifier)
          .switchToSavedWithAppPassword(server, result.password!);
    } else {
      await ref
          .read(connectionControllerProvider.notifier)
          .switchToSaved(server);
    }
    if (mounted) await _handleConnectionResult();
  }

  Future<String?> _requestAppPassword({required bool configured}) async {
    String? errorText;
    while (mounted) {
      if (!mounted) return null;
      final password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AppPasswordSetupDialog(
          passwordAlreadyConfigured: configured,
          errorText: errorText,
        ),
      );
      if (password == null || !mounted) return null;
      if (!configured) return password;
      try {
        await ref
            .read(connectionControllerProvider.notifier)
            .verifyAppPassword(password);
        return password;
      } on Object {
        if (!mounted) return null;
        errorText = AppLocalizations.of(context).appPasswordIncorrect;
      }
    }
    return null;
  }

  Future<_AppPasswordUnlockResult?> _requestAppPasswordUnlock(
    SavedServer server,
  ) async {
    String? errorText;
    while (mounted) {
      if (!mounted) return null;
      final result = await showDialog<_AppPasswordUnlockResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            _AppPasswordUnlockDialog(server: server, errorText: errorText),
      );
      if (result == null || result.reset || !mounted) return result;
      try {
        await ref
            .read(connectionControllerProvider.notifier)
            .verifyAppPassword(result.password!);
        return result;
      } on Object {
        if (!mounted) return null;
        errorText = AppLocalizations.of(context).appPasswordIncorrect;
      }
    }
    return null;
  }

  Future<bool> _confirmClearAppPassword() async {
    return await showDialog<bool>(
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
  }

  void _prepareRegisteredServer(SavedServer server) {
    setState(() {
      _fillRegisteredServer(server);
    });
    _focusCredentialFor(server);
  }

  void _fillRegisteredServer(SavedServer server) {
    _nameController.text = server.profile.name;
    _addressController.text = server.profile.baseUri.toString();
    _usernameController.text = server.username;
    _method = server.authMethod;
    _secretController.clear();
    _keepSignedIn = false;
    _enableBiometricUnlock = false;
  }

  void _focusCredentialFor(SavedServer server) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _credentialFormStartKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: context.motionDuration(AppMotion.standard),
        curve: AppMotion.standardCurve,
        alignment: 0.08,
      );
    });
  }
}

class _CertificateTrustSheet extends StatefulWidget {
  const _CertificateTrustSheet({
    required this.profile,
    required this.certificate,
    this.previousFingerprint,
    this.isExpired = false,
  });

  final ServerProfile profile;
  final TlsCertificateIdentity certificate;
  final String? previousFingerprint;
  final bool isExpired;

  @override
  State<_CertificateTrustSheet> createState() => _CertificateTrustSheetState();
}

class _CertificateTrustSheetState extends State<_CertificateTrustSheet> {
  bool _acknowledgedUntrusted = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final certificate = widget.certificate;
    final previousFingerprint = widget.previousFingerprint;
    final changed = previousFingerprint != null;
    final expired = widget.isExpired;
    final requiresAcknowledgement = !certificate.isTrustedBySystem;
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              changed || expired
                  ? Icons.gpp_bad_outlined
                  : Icons.verified_user_outlined,
              size: 44,
              color: changed || expired ? colors.error : colors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              expired
                  ? l10n.certificateExpiredTitle
                  : changed
                  ? l10n.certificateChangedTitle
                  : l10n.certificateVerifyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              expired
                  ? l10n.certificateExpiredDescription
                  : changed
                  ? l10n.certificateChangedDescription(
                      profile.baseUri.authority,
                    )
                  : certificate.isTrustedBySystem
                  ? l10n.certificateTrustedDescription(
                      profile.baseUri.authority,
                    )
                  : l10n.certificateTrustDescription(profile.baseUri.authority),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _CertificateField(
              label: l10n.certificateFingerprint,
              value: certificate.formattedSha256,
              monospace: true,
            ),
            _CertificateField(
              label: l10n.certificateSubject,
              value: certificate.subject,
            ),
            _CertificateField(
              label: l10n.certificateIssuer,
              value: certificate.issuer,
            ),
            _CertificateField(
              label: l10n.certificateValidUntil,
              value: certificate.validTo.toLocal().toString(),
            ),
            if (changed) ...[
              const SizedBox(height: 8),
              _CertificateField(
                label: l10n.certificatePreviousFingerprint,
                value: _formatFingerprint(previousFingerprint),
                monospace: true,
              ),
            ],
            if (requiresAcknowledgement) ...[
              const SizedBox(height: 16),
              CheckboxListTile(
                key: const ValueKey('untrusted-certificate-acknowledgement'),
                value: _acknowledgedUntrusted,
                onChanged: (value) =>
                    setState(() => _acknowledgedUntrusted = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.certificateUntrustedAcknowledge),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              style: changed || expired
                  ? FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    )
                  : null,
              onPressed: requiresAcknowledgement && !_acknowledgedUntrusted
                  ? null
                  : () => Navigator.pop(context, true),
              icon: const Icon(Icons.shield_outlined),
              label: Text(
                expired
                    ? l10n.certificateExpiredContinue
                    : changed
                    ? l10n.certificateTrustNew
                    : certificate.isTrustedBySystem
                    ? l10n.certificateVerifyAndConnect
                    : l10n.certificateTrustAndConnect,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.actionCancel),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFingerprint(String raw) {
    final compact = raw.replaceAll(':', '');
    return [
      for (var index = 0; index < compact.length; index += 2)
        compact.substring(index, index + 2).toUpperCase(),
    ].join(':');
  }
}

class _CertificateField extends StatelessWidget {
  const _CertificateField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: SvgPicture.asset(
              'assets/foreground.svg',
              key: const ValueKey('registration-foreground-logo'),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.connectHeroTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.connectHeroDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _OtpDialog extends StatefulWidget {
  const _OtpDialog();

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final complete = controller.text.length == OtpCodeField.length;
    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: Text(l10n.otpTitle),
      content: OtpCodeField(
        controller: controller,
        autofocus: true,
        semanticLabel: l10n.otpCode,
        onSubmitted: (value) => Navigator.pop(context, value),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: complete
              ? () => Navigator.pop(context, controller.text)
              : null,
          child: Text(l10n.actionContinue),
        ),
      ],
    );
  }
}

class _AppPasswordSetupDialog extends StatefulWidget {
  const _AppPasswordSetupDialog({
    required this.passwordAlreadyConfigured,
    this.errorText,
  });

  final bool passwordAlreadyConfigured;
  final String? errorText;

  @override
  State<_AppPasswordSetupDialog> createState() =>
      _AppPasswordSetupDialogState();
}

class _AppPasswordSetupDialogState extends State<_AppPasswordSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.password_rounded),
      title: Text(
        widget.passwordAlreadyConfigured
            ? l10n.appPasswordExistingTitle
            : l10n.appPasswordCreateTitle,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.passwordAlreadyConfigured
                    ? l10n.appPasswordExistingDescription
                    : l10n.appPasswordCreateDescription,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(trueDockPinLength),
                ],
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.appPasswordLabel,
                  helperText: l10n.appPasswordMinimum,
                  errorText: widget.errorText,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscure
                        ? l10n.authShowCredential
                        : l10n.authHideCredential,
                  ),
                ),
                validator: (value) => !isValidTrueDockPin(value ?? '')
                    ? l10n.appPasswordMinimum
                    : null,
              ),
              if (!widget.passwordAlreadyConfigured) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(trueDockPinLength),
                  ],
                  obscureText: _obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.appPasswordConfirmLabel,
                  ),
                  validator: (value) => value != _passwordController.text
                      ? l10n.appPasswordMismatch
                      : null,
                ),
              ],
            ],
          ),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _passwordController.text);
  }
}

class _AppPasswordUnlockResult {
  const _AppPasswordUnlockResult.password(this.password) : reset = false;
  const _AppPasswordUnlockResult.reset() : password = null, reset = true;

  final String? password;
  final bool reset;
}

class _AppPasswordUnlockDialog extends StatefulWidget {
  const _AppPasswordUnlockDialog({required this.server, this.errorText});

  final SavedServer server;
  final String? errorText;

  @override
  State<_AppPasswordUnlockDialog> createState() =>
      _AppPasswordUnlockDialogState();
}

class _AppPasswordUnlockDialogState extends State<_AppPasswordUnlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.lock_open_rounded),
      title: Text(l10n.appPasswordUnlockTitle(widget.server.profile.name)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appPasswordUnlockDescription),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('saved-server-app-password'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(trueDockPinLength),
              ],
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.appPasswordLabel,
                errorText: widget.errorText,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscure
                      ? l10n.authShowCredential
                      : l10n.authHideCredential,
                ),
              ),
              validator: (value) => !isValidTrueDockPin(value ?? '')
                  ? l10n.appPasswordMinimum
                  : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  const _AppPasswordUnlockResult.reset(),
                ),
                child: Text(l10n.appPasswordForgot),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _AppPasswordUnlockResult.password(_controller.text));
  }
}
