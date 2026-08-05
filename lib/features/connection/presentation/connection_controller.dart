import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../core/api/truenas_client_provider.dart';
import '../../../core/api/truenas_json_rpc_client.dart';
import '../../../core/security/credential_vault.dart';
import '../../../core/security/app_password_vault.dart';
import '../../../core/security/security_providers.dart';
import '../../../core/security/tls_certificate_service.dart';
import '../data/saved_server_repository.dart';
import '../domain/auth_credential.dart';
import '../domain/connection_message.dart';
import '../domain/server_capabilities.dart';
import '../domain/server_profile.dart';
import '../domain/system_info.dart';

enum ConnectionStage {
  disconnected,
  connecting,
  awaitingCertificateTrust,
  awaitingOtp,
  connected,
  failure,

  /// The transport went away after a successful connection. The profile is
  /// retained so the user can reconnect without re-entering the server.
  connectionLost,
}

class NasConnectionState {
  const NasConnectionState({
    this.stage = ConnectionStage.disconnected,
    this.profile,
    this.systemInfo,
    this.username,
    this.error,
    this.notice,
    this.certificate,
    this.previousCertificateSha256,
    this.isCertificateExpired = false,
    this.capabilities,
    this.isReconnecting = false,
  });

  final ConnectionStage stage;
  final ServerProfile? profile;
  final SystemInfo? systemInfo;
  final String? username;

  /// The failure to show, as a code the presentation layer localizes.
  final ConnectionMessage? error;

  /// A partial-success notice: the connection succeeded but a follow-up step
  /// did not.
  final ConnectionMessage? notice;

  /// English text for logs and for tests that only assert presence. The UI
  /// renders [error] through `ConnectionMessageLocalizations` instead.
  String? get errorMessage => error?.fallback;

  /// English text for logs. See [errorMessage].
  String? get noticeMessage => notice?.fallback;
  final TlsCertificateIdentity? certificate;
  final String? previousCertificateSha256;

  /// True when [certificate] triggered [ConnectionStage.awaitingCertificateTrust]
  /// because it has expired, rather than because its fingerprint changed.
  final bool isCertificateExpired;
  final ServerCapabilities? capabilities;
  final bool isReconnecting;

  bool get isConnected => stage == ConnectionStage.connected;

  /// A previously authenticated session whose last successful server
  /// snapshot can still be rendered while its transport is being restored.
  ///
  /// This deliberately remains true through `connectionLost` and a reconnect
  /// attempt. It is not permission to send mutations; `isConnected` remains
  /// the authoritative live-transport check.
  bool get hasRetainedSession =>
      isConnected || (profile != null && systemInfo != null);

  /// True once a live connection dropped on its own. Distinct from
  /// [ConnectionStage.failure], which covers a connection that never
  /// succeeded.
  bool get isConnectionLost => stage == ConnectionStage.connectionLost;
}

final connectionControllerProvider =
    StateNotifierProvider<ConnectionController, NasConnectionState>((ref) {
      return ConnectionController(
        ref.watch(trueNasClientProvider),
        ref.watch(savedServerRepositoryProvider),
        onSavedServersChanged: () {
          ref.invalidate(savedServersProvider);
          ref.invalidate(appPasswordConfiguredProvider);
        },
      );
    });

class ConnectionController extends StateNotifier<NasConnectionState> {
  ConnectionController(
    this._client,
    this._savedServers, {
    this.onSavedServersChanged,
    this.automaticReconnectDelays = const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
      Duration(seconds: 16),
      Duration(seconds: 30),
    ],
  }) : super(const NasConnectionState()) {
    // The client detects a dropped socket but cannot decide what it means for
    // the user. Without this subscription every screen keeps rendering as
    // though the server were still reachable.
    _lossSubscription = _client.connectionLost.listen(_handleConnectionLoss);
  }

  final TrueNasJsonRpcClient _client;
  final SavedServerRepository _savedServers;
  final void Function()? onSavedServersChanged;
  final List<Duration> automaticReconnectDelays;
  StreamSubscription<ConnectionLoss>? _lossSubscription;
  Timer? _automaticReconnectTimer;
  Future<void>? _reconnectInFlight;
  int _automaticReconnectAttempt = 0;
  AuthCredential? _pendingCredential;
  // Retained only in process memory while the session is active. This is what
  // makes a dropped socket recoverable without reading secure storage or
  // asking the user to sign in again. It is cleared on explicit sign-out.
  AuthCredential? _sessionCredential;
  bool _savePendingCredential = false;
  String? _pendingAppPassword;
  bool _pendingBiometricUnlock = false;
  bool _credentialAlreadySaved = false;

  /// Moves the app out of its connected state when the transport goes away.
  ///
  /// The last confirmed system snapshot and capability layout are retained
  /// for display while reconnection runs. Mutation dispatch independently
  /// requires a live transport, so retaining layout does not authorize calls.
  void _handleConnectionLoss(ConnectionLoss loss) {
    if (!state.isConnected) return;
    state = NasConnectionState(
      stage: ConnectionStage.connectionLost,
      profile: state.profile,
      systemInfo: state.systemInfo,
      username: state.username,
      error: ConnectionMessage.raw(loss.message),
      capabilities: state.capabilities,
    );
    _scheduleAutomaticReconnect();
  }

  @override
  void dispose() {
    _automaticReconnectTimer?.cancel();
    _lossSubscription?.cancel();
    _pendingCredential = null;
    _sessionCredential = null;
    _pendingAppPassword = null;
    super.dispose();
  }

  Future<void> connect(
    ServerProfile profile,
    AuthCredential credential, {
    bool keepSignedIn = false,
    String? appPassword,
    bool enableBiometricUnlock = false,
  }) async {
    _cancelAutomaticReconnect();
    _sessionCredential = null;
    _pendingCredential = credential;
    _savePendingCredential = keepSignedIn;
    _pendingAppPassword = appPassword;
    _pendingBiometricUnlock = enableBiometricUnlock;
    _credentialAlreadySaved = false;
    await _attemptConnection(profile);
  }

  Future<void> connectSaved(SavedServer server, {String? appPassword}) async {
    _cancelAutomaticReconnect();
    try {
      _sessionCredential = null;
      state = NasConnectionState(
        stage: ConnectionStage.connecting,
        profile: server.profile,
      );
      final credential = await _savedServers.unlock(
        server,
        appPassword: appPassword,
      );
      if (credential == null) {
        throw const CredentialVaultException(
          'No saved credential was found for this server.',
        );
      }
      _pendingCredential = credential;
      _savePendingCredential = false;
      _credentialAlreadySaved = true;
      await _attemptConnection(server.profile);
    } on Object catch (error) {
      state = NasConnectionState(
        stage: ConnectionStage.failure,
        profile: server.profile,
        error: _messageFor(error),
      );
    }
  }

  Future<void> trustCertificate() async {
    final profile = state.profile;
    final certificate = state.certificate;
    if (profile == null || certificate == null) return;
    try {
      state = NasConnectionState(
        stage: ConnectionStage.connecting,
        profile: profile,
      );
      final trustedProfile = await _client.trustCertificate(
        profile,
        certificate,
      );
      await _attemptConnection(trustedProfile);
    } on Object catch (error) {
      state = NasConnectionState(
        stage: ConnectionStage.failure,
        profile: profile,
        error: _messageFor(error),
      );
    }
  }

  Future<void> submitOtp(String otp) async {
    final profile = state.profile;
    if (profile == null) return;
    state = NasConnectionState(
      stage: ConnectionStage.connecting,
      profile: profile,
    );
    try {
      final auth = await _client.continueWithOtp(otp.trim());
      await _finishAuthentication(profile, auth);
    } on Object catch (error) {
      state = NasConnectionState(
        stage: ConnectionStage.failure,
        profile: profile,
        error: _messageFor(error),
      );
    }
  }

  Future<void> refreshSystemInfo() async {
    if (!state.isConnected) return;
    final current = state;
    try {
      final info = await _client.getSystemInfo();
      state = NasConnectionState(
        stage: ConnectionStage.connected,
        profile: current.profile,
        systemInfo: info,
        username: current.username,
        capabilities: current.capabilities,
      );
    } on Object catch (error) {
      state = NasConnectionState(
        // This was a health check for an established session. A failure means
        // values on screen are no longer known to be live, so use the same
        // recoverable state as a socket close rather than a first-connect
        // failure.
        stage: ConnectionStage.connectionLost,
        profile: current.profile,
        systemInfo: current.systemInfo,
        username: current.username,
        error: _messageFor(error),
        capabilities: current.capabilities,
      );
      _scheduleAutomaticReconnect();
    }
  }

  Future<void> disconnect() async {
    await _endCurrentSession();
  }

  /// Clears only the in-memory session after a local device-data reset.
  /// Persistent storage is owned by [DeviceDataResetService].
  Future<void> clearSessionForDeviceReset() async {
    _cancelAutomaticReconnect();
    _clearPendingCredential();
    _sessionCredential = null;
    state = const NasConnectionState();

    // The local reset is authoritative and navigation must never wait for a
    // server that is offline, rebooting, or no longer answering auth.logout.
    // Transport cleanup remains best-effort after the UI has returned to
    // first use.
    unawaited(_closeTransportAfterDeviceReset());
  }

  Future<void> _closeTransportAfterDeviceReset() async {
    try {
      await _client.logout().timeout(const Duration(seconds: 2));
    } on Object {
      // The server may already be unreachable.
    }
    try {
      await _client.close().timeout(const Duration(seconds: 2));
    } on Object {
      // Local state is already clear, so transport failure is non-blocking.
    }
  }

  /// Ends the active session before authenticating to another saved server.
  ///
  /// Saved profiles keep their own certificate pin and credential entry, so a
  /// switch must use the complete profile rather than mutating the current
  /// connection in place.
  Future<void> switchToSaved(SavedServer server) async {
    if (state.isConnected && state.profile?.id == server.profile.id) return;
    await _endCurrentSession();
    await connectSaved(server);
  }

  Future<void> switchToSavedWithAppPassword(
    SavedServer server,
    String appPassword,
  ) async {
    if (state.isConnected && state.profile?.id == server.profile.id) return;
    await _endCurrentSession();
    await connectSaved(server, appPassword: appPassword);
  }

  /// Attempts the optional biometric unlock copy. A cancelled or unavailable
  /// biometric prompt returns false so the UI can ask for the TrueDock app
  /// password instead of presenting it as a server connection failure.
  Future<bool> switchToSavedWithBiometrics(
    SavedServer server, {
    void Function()? onCredentialUnlocked,
  }) async {
    if (state.isConnected && state.profile?.id == server.profile.id) {
      return true;
    }
    await _endCurrentSession();
    AuthCredential? credential;
    try {
      state = NasConnectionState(
        stage: ConnectionStage.connecting,
        profile: server.profile,
      );
      credential = await _savedServers.unlock(server);
    } on Object {
      state = const NasConnectionState();
      return false;
    }
    if (credential == null) {
      state = const NasConnectionState();
      return false;
    }
    // Biometric authentication and TrueNAS authentication are distinct
    // stages. Let the presentation acknowledge the completed device check
    // before the network sign-in begins, which may take several seconds.
    onCredentialUnlocked?.call();
    _pendingCredential = credential;
    _savePendingCredential = false;
    _credentialAlreadySaved = true;
    await _attemptConnection(server.profile);
    return true;
  }

  Future<void> _endCurrentSession() async {
    _cancelAutomaticReconnect();
    // End the session on the server first. Closing the socket alone leaves the
    // authenticated session alive until it times out. A transport failure must
    // not prevent TrueDock from clearing its local authenticated state.
    try {
      await _client.logout();
    } on Object {
      // The socket may already be gone. Closing it below is still required.
    }
    try {
      await _client.close();
    } on Object {
      // Local sign-out is authoritative even if transport cleanup fails.
    }
    _clearPendingCredential();
    _sessionCredential = null;
    state = const NasConnectionState();
  }

  /// Re-establishes a session after the transport dropped on its own.
  ///
  /// The credential from the original sign-in is still held in memory, so a
  /// lost connection can be recovered without asking for it again. If it is
  /// gone (for example after a failed attempt cleared it), the user is sent
  /// back to the connect flow rather than being left on a dead screen.
  Future<void> reconnect() async {
    _cancelAutomaticReconnect(resetAttempt: false);
    await _reconnectOnce();
    if (state.isConnectionLost) _scheduleAutomaticReconnect();
  }

  /// Reconnects without surfacing secure-storage UI.
  ///
  /// Only the credential retained by the current in-memory session is used.
  /// iOS can suspend an app and tear down its WebSocket, but it must not show a
  /// biometric prompt merely because the app returned to the foreground.
  /// Repeated callers share one attempt, which prevents a resume probe, socket
  /// close event, and retry timer from opening competing sessions.
  Future<void> reconnectAutomatically({bool resetBackoff = false}) async {
    if (resetBackoff) {
      _automaticReconnectAttempt = 0;
      _automaticReconnectTimer?.cancel();
      _automaticReconnectTimer = null;
    }
    if (state.isConnected) return;
    await _reconnectOnce();
    if (state.isConnectionLost) _scheduleAutomaticReconnect();
  }

  Future<void> _reconnectOnce() {
    final running = _reconnectInFlight;
    if (running != null) return running;

    final attempt = _performReconnect();
    _reconnectInFlight = attempt;
    return attempt.whenComplete(() {
      if (identical(_reconnectInFlight, attempt)) {
        _reconnectInFlight = null;
      }
    });
  }

  Future<void> _performReconnect() async {
    final profile = state.profile;
    if (profile == null) {
      state = const NasConnectionState();
      return;
    }
    final credential = _sessionCredential;
    if (credential == null) {
      state = NasConnectionState(
        stage: ConnectionStage.failure,
        profile: profile,
        error: ConnectionMessage(
          ConnectionMessageCode.signInAgainToReconnect,
          name: profile.name,
          fallback: 'Sign in again to reconnect to ${profile.name}.',
        ),
      );
      return;
    }
    _pendingCredential = credential;
    _savePendingCredential = false;
    _credentialAlreadySaved = true;
    await _attemptConnection(profile, isReconnect: true);
    if (state.isConnected) _automaticReconnectAttempt = 0;
  }

  void _scheduleAutomaticReconnect() {
    if (!state.isConnectionLost || automaticReconnectDelays.isEmpty) return;
    if (_reconnectInFlight != null ||
        _automaticReconnectTimer?.isActive == true) {
      return;
    }
    final index = _automaticReconnectAttempt.clamp(
      0,
      automaticReconnectDelays.length - 1,
    );
    final delay = automaticReconnectDelays[index];
    if (_automaticReconnectAttempt < automaticReconnectDelays.length - 1) {
      _automaticReconnectAttempt++;
    }
    _automaticReconnectTimer = Timer(delay, () {
      _automaticReconnectTimer = null;
      unawaited(reconnectAutomatically());
    });
  }

  void _cancelAutomaticReconnect({bool resetAttempt = true}) {
    _automaticReconnectTimer?.cancel();
    _automaticReconnectTimer = null;
    if (resetAttempt) _automaticReconnectAttempt = 0;
  }

  /// Tests and adopts a server address changed by an in-flight network commit.
  ///
  /// The existing socket may point at an address that no longer exists. This
  /// reconnects with the active in-memory credential without changing visible
  /// connection state until the replacement connection is fully authenticated.
  /// A successful call leaves the shared API client connected to [address], so
  /// `interface.checkin` can be sent through the new route immediately.
  Future<ConnectionMessage?> testChangedServerAddress(String address) async {
    final current = state;
    final profile = current.profile;
    final credential = _sessionCredential;
    if (profile == null || credential == null) {
      return const ConnectionMessage(
        ConnectionMessageCode.addressTestSignInUnavailable,
      );
    }

    final ServerProfile candidate;
    try {
      final parsed = ServerProfile.parse(name: profile.name, address: address);
      candidate = profile.copyWith(baseUri: parsed.baseUri);
    } on FormatException {
      return const ConnectionMessage(
        ConnectionMessageCode.addressTestInvalidAddress,
      );
    }

    try {
      await _client.connect(candidate);
      final auth = await _client.authenticate(credential);
      if (auth.outcome != AuthOutcome.success) {
        await _client.close();
        return ConnectionMessage(
          auth.outcome == AuthOutcome.otpRequired
              ? ConnectionMessageCode.addressTestOtpRequired
              : ConnectionMessageCode.addressTestAuthenticationRejected,
        );
      }
      final info = await _client.getSystemInfo();
      final capabilities = await _client.discoverCapabilities(info);
      final username = auth.username ?? current.username;
      state = NasConnectionState(
        stage: ConnectionStage.connected,
        profile: candidate,
        systemInfo: info,
        username: username,
        capabilities: capabilities,
      );
      return null;
    } on Object catch (error) {
      try {
        await _client.close();
      } on Object {
        // The failed candidate transport may already be closed.
      }
      return _messageFor(error);
    }
  }

  /// Persists the tested address only after TrueNAS confirms check-in.
  Future<void> confirmChangedServerAddress() async {
    final profile = state.profile;
    if (profile == null) return;
    await _savedServers.updateProfile(profile);
    onSavedServersChanged?.call();
  }

  Future<void> forgetSavedServer(ServerProfile profile) async {
    await _savedServers.delete(profile);
    onSavedServersChanged?.call();
  }

  /// Changes only TrueDock's local label for a server. The stable profile id
  /// keeps its credential and certificate pin attached to the same server.
  Future<void> renameSavedServer(ServerProfile profile, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == profile.name) return;
    final renamed = profile.copyWith(name: trimmed);
    await _savedServers.updateProfile(renamed);
    if (state.profile?.id == profile.id) {
      state = NasConnectionState(
        stage: state.stage,
        profile: renamed,
        systemInfo: state.systemInfo,
        username: state.username,
        error: state.error,
        notice: state.notice,
        certificate: state.certificate,
        previousCertificateSha256: state.previousCertificateSha256,
        capabilities: state.capabilities,
        isReconnecting: state.isReconnecting,
      );
    }
    onSavedServersChanged?.call();
  }

  Future<bool> isAppPasswordConfigured() =>
      _savedServers.isAppPasswordConfigured();

  Future<void> verifyAppPassword(String password) =>
      _savedServers.verifyAppPassword(password);

  Future<void> configureAppPassword(String password) async {
    await _savedServers.configureAppPassword(password);
    onSavedServersChanged?.call();
  }

  Future<void> changeAppPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _savedServers.changeAppPassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    onSavedServersChanged?.call();
  }

  Future<void> setBiometricUnlockEnabled({
    required String appPassword,
    required bool enabled,
  }) async {
    await _savedServers.setBiometricUnlockEnabled(
      appPassword: appPassword,
      enabled: enabled,
    );
    onSavedServersChanged?.call();
  }

  Future<void> clearAllAppPasswordCredentials() async {
    await _savedServers.clearAllAppPasswordCredentials();
    onSavedServersChanged?.call();
  }

  Future<void> _attemptConnection(
    ServerProfile profile, {
    bool isReconnect = false,
  }) async {
    final credential = _pendingCredential;
    if (credential == null) {
      state = NasConnectionState(
        stage: ConnectionStage.failure,
        profile: profile,
        error: const ConnectionMessage(
          ConnectionMessageCode.credentialRequired,
          fallback: 'Enter or unlock a credential before connecting.',
        ),
      );
      return;
    }
    final previousUsername = state.username;
    final previousSystemInfo = state.systemInfo;
    final previousCapabilities = state.capabilities;
    state = NasConnectionState(
      stage: ConnectionStage.connecting,
      profile: profile,
      systemInfo: isReconnect ? previousSystemInfo : null,
      username: isReconnect ? previousUsername : null,
      capabilities: isReconnect ? previousCapabilities : null,
      isReconnecting: isReconnect,
    );
    try {
      await _client.connect(profile);
      final auth = await _client.authenticate(credential);
      await _finishAuthentication(profile, auth);
    } on TlsCertificateTrustRequired catch (request) {
      state = NasConnectionState(
        stage: ConnectionStage.awaitingCertificateTrust,
        profile: profile,
        certificate: request.certificate,
        previousCertificateSha256: request.previousFingerprint,
        isCertificateExpired: request.isExpired,
      );
    } on Object catch (error) {
      _clearPendingCredential();
      state = NasConnectionState(
        // A failed retry is still a lost established session. Keep the banner
        // and its retry affordance visible instead of silently replacing it
        // with a generic first-connection failure state.
        stage: isReconnect
            ? ConnectionStage.connectionLost
            : ConnectionStage.failure,
        profile: profile,
        systemInfo: isReconnect ? previousSystemInfo : null,
        username: isReconnect ? previousUsername : null,
        error: _messageFor(error),
        capabilities: isReconnect ? previousCapabilities : null,
      );
    }
  }

  Future<void> _finishAuthentication(
    ServerProfile profile,
    AuthResult result,
  ) async {
    switch (result.outcome) {
      case AuthOutcome.success:
        final info = await _client.getSystemInfo();
        final capabilities = await _client.discoverCapabilities(info);
        // `login_ex` normally carries the account in `user_info`, but an
        // API-key login can succeed without it, which would leave the saved
        // server row unlabelled. Ask the server only when it is missing.
        final username = result.username ?? await _client.currentUserName();
        ConnectionMessage? notice;
        final credential = _pendingCredential;
        if (!_credentialAlreadySaved && credential != null) {
          try {
            await _savedServers.register(
              profile,
              credential,
              saveCredential: _savePendingCredential,
              appPassword: _pendingAppPassword,
              enableBiometricUnlock: _pendingBiometricUnlock,
            );
            onSavedServersChanged?.call();
          } on Object catch (error) {
            final detail = _messageFor(error);
            notice = ConnectionMessage(
              _savePendingCredential
                  ? ConnectionMessageCode.savedSignInFailed
                  : ConnectionMessageCode.serverRegistrationFailed,
              detail: detail.fallback,
              fallback:
                  'Connected, but '
                  '${_savePendingCredential ? 'the sign-in could not be saved' : 'the server could not be registered'}'
                  ': ${detail.fallback}',
            );
          }
        }
        notice ??= _certificateExpiryNotice(profile);
        // Keep the reusable secret only in memory for recovery from an
        // unexpected transport loss. `_clearPendingCredential` below clears
        // onboarding/save-flow state, not this active-session copy.
        _sessionCredential = credential;
        _clearPendingCredential();
        state = NasConnectionState(
          stage: ConnectionStage.connected,
          profile: profile,
          systemInfo: info,
          username: username,
          notice: notice,
          capabilities: capabilities,
        );
        return;
      case AuthOutcome.otpRequired:
        state = NasConnectionState(
          stage: ConnectionStage.awaitingOtp,
          profile: profile,
          username: result.username,
        );
        return;
      case AuthOutcome.authenticationError:
        throw const AuthFailure(
          ConnectionMessageCode.authenticationRejected,
          'The username or credential was not accepted.',
        );
      case AuthOutcome.expired:
        throw const AuthFailure(
          ConnectionMessageCode.credentialExpired,
          'This credential has expired.',
        );
      case AuthOutcome.redirect:
        throw const AuthFailure(
          ConnectionMessageCode.redirectUnsupported,
          'Redirected authentication is not supported yet.',
        );
    }
  }

  /// Maps a thrown error onto a [ConnectionMessage].
  ///
  /// Server- and transport-supplied text has no stable code, so it is wrapped
  /// verbatim; only our own fallback carries a code the UI can localize.
  ConnectionMessage _messageFor(Object error) {
    if (error is AuthFailure) {
      return ConnectionMessage(error.code, fallback: error.fallback);
    }
    if (error is TrueNasRpcException) {
      return ConnectionMessage.raw(error.displayMessage);
    }
    if (error is TlsCertificateException) {
      return ConnectionMessage(
        ConnectionMessageCode.certificateInspectionFailed,
        detail: error.message,
        fallback: error.message,
      );
    }
    if (error is CredentialVaultException) {
      return ConnectionMessage(
        ConnectionMessageCode.credentialAccessFailed,
        detail: error.message,
        fallback: error.message,
      );
    }
    if (error is AppPasswordVaultException) {
      return ConnectionMessage(
        ConnectionMessageCode.appPinAccessFailed,
        detail: error.message,
        fallback: error.message,
      );
    }
    if (error is UnsupportedServerException) {
      return ConnectionMessage(
        ConnectionMessageCode.unsupportedServer,
        detail: error.message,
        fallback: error.message,
      );
    }
    if (error is FormatException) {
      return ConnectionMessage(
        ConnectionMessageCode.invalidSavedData,
        detail: error.message,
        fallback: error.message,
      );
    }
    return const ConnectionMessage(
      ConnectionMessageCode.insecureConnection,
      fallback:
          'Could not connect securely. Check the address and certificate.',
    );
  }

  /// Warns about the certificate the transport just verified, when it is
  /// already expired or close to expiring.
  ///
  /// This never blocks the connection: an already-verified and pinned or
  /// system-trusted certificate is still safe to use for the current
  /// session, but the administrator needs to renew it before it lapses.
  ConnectionMessage? _certificateExpiryNotice(ServerProfile profile) {
    final certificate = _client.lastVerifiedCertificate;
    if (certificate == null) return null;
    final now = DateTime.now();
    if (certificate.isExpiredAt(now)) {
      return const ConnectionMessage(
        ConnectionMessageCode.certificateExpired,
        fallback: "The server's TLS certificate has expired.",
      );
    }
    if (certificate.isExpiringSoonAt(now)) {
      return ConnectionMessage(
        ConnectionMessageCode.certificateExpiringSoon,
        name: profile.baseUri.authority,
        fallback:
            'The TLS certificate for ${profile.baseUri.authority} expires soon.',
      );
    }
    return null;
  }

  void _clearPendingCredential() {
    _pendingCredential = null;
    _savePendingCredential = false;
    _pendingAppPassword = null;
    _pendingBiometricUnlock = false;
    _credentialAlreadySaved = false;
  }
}

/// An authentication outcome that failed for a reason TrueDock names itself,
/// rather than one the server explained. Carries the code so the UI can
/// localize it.
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.fallback);

  final ConnectionMessageCode code;
  final String fallback;

  @override
  String toString() => fallback;
}
