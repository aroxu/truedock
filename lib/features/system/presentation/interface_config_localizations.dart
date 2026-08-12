import '../../../l10n/app_localizations.dart';
import '../domain/interface_configuration.dart';

/// Maps interface configuration validation issues onto ARB-localized strings.
extension InterfaceConfigLocalizations on AppLocalizations {
  String interfaceValidationMessage(InterfaceValidationIssue issue) {
    final ctx = issue.context;
    switch (issue.code) {
      case InterfaceValidationCode.mtuRange:
        return sysInterfaceValidationMtuRange;
      case InterfaceValidationCode.aliasesRequired:
        return sysInterfaceValidationAliasesRequired;
      case InterfaceValidationCode.aliasAddressInvalid:
        return sysInterfaceValidationAliasAddressInvalid(
          (ctx.ipv6 ?? false) ? 'IPv6' : 'IPv4',
        );
      case InterfaceValidationCode.aliasPrefixRange:
        return sysInterfaceValidationAliasPrefixRange(
          ctx.maxPrefix ?? 32,
          ctx.address ?? '',
        );
      case InterfaceValidationCode.aliasDuplicate:
        return sysInterfaceValidationAliasDuplicate(ctx.address ?? '');
    }
  }
}
