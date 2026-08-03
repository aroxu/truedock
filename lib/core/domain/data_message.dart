/// Stable codes for data-layer messages surfaced to the user.
///
/// Repositories run without a [BuildContext], so they cannot resolve localized
/// strings. They record a code and the presentation layer renders it through
/// `DataMessageLocalizations`.
enum DataMessageCode {
  decodeFailed,
  invalidData,
  methodUnavailable,
  decodeDiskTemperatures,
  decodeCatalogApps,
  decodeCatalogTrains,
  decodeAppDetails,
  noInstallableVersions,
  reportingUnsupported,
  reportingUnreadable,
}

/// A data-layer message as a stable [code] plus the values it interpolates.
///
/// Text the server produced has no code of its own and is wrapped verbatim
/// with [DataMessage.raw], so a server's own explanation still reaches the
/// user unchanged. [fallback] holds English text for logs and tests.
class DataMessage {
  const DataMessage(this.code, {this.method, this.fallback});

  /// Wraps a message the server or transport produced, which has no code.
  const DataMessage.raw(String text)
    : code = null,
      method = null,
      fallback = text;

  final DataMessageCode? code;

  /// The API method a decode failure refers to, when the message names one.
  final String? method;

  final String? fallback;

  @override
  String toString() => fallback ?? '$code';
}
