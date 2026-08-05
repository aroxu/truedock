/// Stable codes for connection-layer messages surfaced to the user.
///
/// [ConnectionController] runs without a [BuildContext], so it cannot resolve
/// localized strings itself. It records a code (and any values the message
/// interpolates) and the presentation layer renders it through
/// `ConnectionMessageLocalizations`.
enum ConnectionMessageCode {
  signInAgainToReconnect,
  credentialRequired,
  authenticationRejected,
  credentialExpired,
  redirectUnsupported,
  insecureConnection,
  certificateInspectionFailed,
  credentialAccessFailed,
  appPinAccessFailed,
  unsupportedServer,
  invalidSavedData,
  savedSignInFailed,
  serverRegistrationFailed,
  addressTestSignInUnavailable,
  addressTestOtpRequired,
  addressTestAuthenticationRejected,
  addressTestInvalidAddress,
  certificateExpired,
  certificateExpiringSoon,
}

/// A connection message as a stable [code] plus the values it interpolates.
///
/// [fallback] holds the English text for logs and for the transport-supplied
/// messages that have no code of their own.
class ConnectionMessage {
  const ConnectionMessage(this.code, {this.name, this.detail, this.fallback});

  /// Wraps a message the server or transport produced, which has no code.
  const ConnectionMessage.raw(String text)
    : code = null,
      name = null,
      detail = null,
      fallback = text;

  final ConnectionMessageCode? code;

  /// The server or profile name a message names, when it has one.
  final String? name;

  /// A nested explanation retained for diagnostics. Client-authored details
  /// are not rendered directly because they are not localized.
  final String? detail;

  final String? fallback;

  @override
  String toString() => fallback ?? '$code';
}
