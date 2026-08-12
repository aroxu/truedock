import '../../../l10n/app_localizations.dart';
import '../domain/account_configuration.dart';

/// Maps the account-domain stable codes onto the ARB-localized strings used by
/// the user/group sheets. Keeping the mapping next to the sheets lets the
/// domain layer stay free of Flutter and localization imports.
extension AccountLocalizations on AppLocalizations {
  String accountValidationMessage(AccountValidationCode code) => switch (code) {
    AccountValidationCode.userNotEditable => sysUserValidationUserNotEditable,
    AccountValidationCode.emailInvalid => sysUserValidationEmailInvalid,
    AccountValidationCode.userUnchanged => sysUserValidationUserUnchanged,
    AccountValidationCode.groupNotEditable => sysUserValidationGroupNotEditable,
    AccountValidationCode.groupNameRequired =>
      sysUserValidationGroupNameRequired,
    AccountValidationCode.groupNameInvalid => sysUserValidationGroupNameInvalid,
    AccountValidationCode.groupUnchanged => sysUserValidationGroupUnchanged,
    AccountValidationCode.usernameRequired => sysUserValidationUsernameRequired,
    AccountValidationCode.usernameInvalid => sysUserValidationUsernameInvalid,
    AccountValidationCode.passwordRequired => sysUserValidationPasswordRequired,
    AccountValidationCode.primaryGroupRequired =>
      sysUserValidationPrimaryGroupRequired,
  };

  String accountChangeText(AccountChange change) {
    final value = change.value ?? '';
    return switch (change.code) {
      AccountChangeCode.fullNameCleared => sysUserChangeFullNameCleared,
      AccountChangeCode.fullNameSet => sysUserChangeFullNameSet(value),
      AccountChangeCode.emailCleared => sysUserChangeEmailCleared,
      AccountChangeCode.emailSet => sysUserChangeEmailSet(value),
      AccountChangeCode.shellSet => sysUserChangeShellSet(value),
      AccountChangeCode.smbEnabled => sysUserChangeSmbEnabled,
      AccountChangeCode.smbDisabled => sysUserChangeSmbDisabled,
      AccountChangeCode.accountLocked => sysUserChangeAccountLocked,
      AccountChangeCode.accountUnlocked => sysUserChangeAccountUnlocked,
      AccountChangeCode.passwordSignInDisabled => sysUserChangePasswordDisabled,
      AccountChangeCode.passwordSignInEnabled => sysUserChangePasswordEnabled,
      AccountChangeCode.auxiliaryGroupsSet => sysUserChangeAuxGroupsSet(
        int.parse(value.isEmpty ? '0' : value),
      ),
      AccountChangeCode.groupRenamed => sysUserChangeGroupRenamed(value),
      AccountChangeCode.groupExposedToSmb => sysUserChangeGroupExposedSmb,
      AccountChangeCode.groupHiddenFromSmb => sysUserChangeGroupHiddenSmb,
      AccountChangeCode.membershipSet => sysUserChangeMembershipSet(
        int.parse(value.isEmpty ? '0' : value),
      ),
      AccountChangeCode.otherFieldUpdated => sysUserChangeOtherField(value),
    };
  }
}
