import '../../l10n/app_localizations.dart';
import '../domain/data_message.dart';

/// Renders a [DataMessage] recorded by a repository.
///
/// Repositories have no [BuildContext], so they record a stable code and the
/// values the message interpolates; this resolves that into localized text.
/// Messages the server supplied carry no code and fall back to the text the
/// server produced.
extension DataMessageLocalizations on AppLocalizations {
  String dataMessage(DataMessage message) {
    final code = message.code;
    if (code == null) return message.fallback ?? '';
    return switch (code) {
      DataMessageCode.decodeFailed => dataMsgDecodeFailed(message.method ?? ''),
      DataMessageCode.invalidData => dataMsgInvalidData(message.method ?? ''),
      DataMessageCode.methodUnavailable => dataMsgMethodUnavailable(
        message.method ?? '',
      ),
      DataMessageCode.decodeDiskTemperatures => dataMsgDecodeDiskTemperatures,
      DataMessageCode.decodeCatalogApps => dataMsgDecodeCatalogApps,
      DataMessageCode.decodeCatalogTrains => dataMsgDecodeCatalogTrains,
      DataMessageCode.decodeAppDetails => dataMsgDecodeAppDetails,
      DataMessageCode.noInstallableVersions => dataMsgNoInstallableVersions,
      DataMessageCode.reportingUnsupported => dataMsgReportingUnsupported,
      DataMessageCode.reportingUnreadable => dataMsgReportingUnreadable,
    };
  }
}
