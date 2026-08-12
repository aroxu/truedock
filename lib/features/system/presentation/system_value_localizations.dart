import '../../../l10n/app_localizations.dart';

/// Localizes client-owned fallback values while preserving values returned by
/// TrueNAS. API identifiers and real network addresses remain unchanged.
extension SystemValueLocalizations on AppLocalizations {
  String systemOriginLabel(String value) =>
      value.trim().isEmpty || value == 'Unknown origin' ? sysUnknown : value;

  String systemNetworkLabel(String value) =>
      value.trim().isEmpty ||
          value == 'Unknown network' ||
          value == 'Unknown gateway'
      ? sysUnknown
      : value;
}
