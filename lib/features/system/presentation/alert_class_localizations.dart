import '../../../l10n/app_localizations.dart';
import '../domain/alert_class_configuration.dart';

/// Localized names for alert delivery policies.
///
/// Kept beside the alert sheets rather than inside one of them, so the list and
/// the editor label a policy identically.
extension AlertClassLocalizations on AppLocalizations {
  String alertDeliveryLabel(AlertPolicy policy) => switch (policy) {
    AlertPolicy.immediately => sysAlertPolicyImmediately,
    AlertPolicy.hourly => sysAlertPolicyHourly,
    AlertPolicy.daily => sysAlertPolicyDaily,
    AlertPolicy.never => sysAlertPolicyNever,
  };
}
