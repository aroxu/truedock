import '../../../l10n/app_localizations.dart';
import '../domain/system_general_configuration.dart';

/// Maps the general-system configuration codes onto ARB-localized strings.
extension SystemGeneralLocalizations on AppLocalizations {
  String systemGeneralValidationMessage(SystemGeneralValidationCode code) =>
      switch (code) {
        SystemGeneralValidationCode.hostnameRequired =>
          sysGeneralValidationHostnameRequired,
        SystemGeneralValidationCode.timezoneRequired =>
          sysGeneralValidationTimezoneRequired,
      };

  String syslogLabel(SystemSyslogLevel level) => switch (level) {
    SystemSyslogLevel.defaultLevel => sysSyslogDefault,
    SystemSyslogLevel.debug => sysSyslogDebug,
    SystemSyslogLevel.info => sysSyslogInfo,
    SystemSyslogLevel.notice => sysSyslogNotice,
    SystemSyslogLevel.warning => sysSyslogWarning,
    SystemSyslogLevel.error => sysSyslogError,
    SystemSyslogLevel.critical => sysSyslogCritical,
    SystemSyslogLevel.alert => sysSyslogAlert,
    SystemSyslogLevel.emergency => sysSyslogEmergency,
  };
}
