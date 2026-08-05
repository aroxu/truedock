import '../../../l10n/app_localizations.dart';
import '../domain/connection_message.dart';

/// Renders a [ConnectionMessage] recorded by [ConnectionController].
///
/// The controller has no [BuildContext], so it records a stable code and the
/// values the message interpolates; this resolves that into localized text.
/// Messages that came from the server or transport carry no code and fall
/// back to the text the server supplied.
extension ConnectionMessageLocalizations on AppLocalizations {
  String connectionMessage(ConnectionMessage message) {
    final code = message.code;
    if (code == null) return message.fallback ?? '';
    return switch (code) {
      ConnectionMessageCode.signInAgainToReconnect =>
        connMsgSignInAgainToReconnect(message.name ?? ''),
      ConnectionMessageCode.credentialRequired => connMsgCredentialRequired,
      ConnectionMessageCode.authenticationRejected =>
        connMsgAuthenticationRejected,
      ConnectionMessageCode.credentialExpired => connMsgCredentialExpired,
      ConnectionMessageCode.redirectUnsupported => connMsgRedirectUnsupported,
      ConnectionMessageCode.insecureConnection => connMsgInsecureConnection,
      ConnectionMessageCode.certificateInspectionFailed =>
        connMsgCertificateInspectionFailed,
      ConnectionMessageCode.credentialAccessFailed =>
        connMsgCredentialAccessFailed,
      ConnectionMessageCode.appPinAccessFailed => connMsgAppPinAccessFailed,
      ConnectionMessageCode.unsupportedServer => connMsgUnsupportedServer,
      ConnectionMessageCode.invalidSavedData => connMsgInvalidSavedData,
      ConnectionMessageCode.savedSignInFailed => connMsgSavedSignInFailed,
      ConnectionMessageCode.serverRegistrationFailed =>
        connMsgServerRegistrationFailed,
      ConnectionMessageCode.addressTestSignInUnavailable =>
        connMsgAddressTestSignInUnavailable,
      ConnectionMessageCode.addressTestOtpRequired =>
        connMsgAddressTestOtpRequired,
      ConnectionMessageCode.addressTestAuthenticationRejected =>
        connMsgAddressTestAuthenticationRejected,
      ConnectionMessageCode.addressTestInvalidAddress =>
        connMsgAddressTestInvalidAddress,
      ConnectionMessageCode.certificateExpired => connMsgCertificateExpired,
      ConnectionMessageCode.certificateExpiringSoon =>
        connMsgCertificateExpiringSoon(message.name ?? ''),
    };
  }
}
