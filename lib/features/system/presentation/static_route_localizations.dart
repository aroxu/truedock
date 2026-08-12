import '../../../l10n/app_localizations.dart';
import '../domain/static_route_configuration.dart';

/// Maps static-route validation codes onto ARB-localized strings.
extension StaticRouteLocalizations on AppLocalizations {
  String staticRouteValidationMessage(StaticRouteValidationCode code) =>
      switch (code) {
        StaticRouteValidationCode.destinationRequired =>
          sysRouteValidationDestinationRequired,
        StaticRouteValidationCode.destinationInvalid =>
          sysRouteValidationDestinationInvalid,
        StaticRouteValidationCode.gatewayRequired =>
          sysRouteValidationGatewayRequired,
        StaticRouteValidationCode.gatewayInvalid =>
          sysRouteValidationGatewayInvalid,
      };
}
