// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TrueDock';

  @override
  String get navOverview => 'Overview';

  @override
  String get navStorage => 'Storage';

  @override
  String get navProtection => 'Protection';

  @override
  String get navApps => 'Apps';

  @override
  String get navSystem => 'System';

  @override
  String get navAppSettings => 'Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionReview => 'Review';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionDone => 'Done';

  @override
  String get actionReconnect => 'Reconnect';

  @override
  String get actionReconnecting => 'Reconnecting…';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionAddServer => 'Add server';

  @override
  String get actionConnectServer => 'Connect server';

  @override
  String get actionNext => 'Next';

  @override
  String authSucceededSigningIn(String serverName) {
    return 'Signing in to $serverName…';
  }

  @override
  String get actionContinue => 'Continue';

  @override
  String get connectionLostTitle => 'Connection lost';

  @override
  String connectionLostTitleNamed(String serverName) {
    return 'Lost connection to $serverName';
  }

  @override
  String get connectionLostStaleData =>
      'Showing the last data TrueDock received.';

  @override
  String get connectionLostReconnectFailed =>
      'Could not reconnect to the server.';

  @override
  String get overviewAtAGlance => 'At a glance';

  @override
  String get overviewLivePerformance => 'Live performance';

  @override
  String get overviewRecentActivity => 'Recent activity';

  @override
  String get activityAlertDetails => 'Alert details';

  @override
  String get activityAlertSeverity => 'Severity';

  @override
  String get activityAlertOccurredAt => 'Last occurred';

  @override
  String get activityAlertCritical => 'Critical';

  @override
  String get activityAlertWarning => 'Warning';

  @override
  String get activityAlertInfo => 'Information';

  @override
  String get overviewConnectedSecurely => 'Connected securely';

  @override
  String get overviewNoServerConnected => 'No server connected';

  @override
  String get overviewHeroTitle => 'Your TrueNAS, without the browser';

  @override
  String get overviewHeroDescription =>
      'Add a TrueNAS SCALE 25.10+ server to monitor and manage it here.';

  @override
  String get metricUptime => 'Uptime';

  @override
  String metricUptimeDuration(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days, $time',
      one: '1 day, $time',
      zero: '$time',
    );
    return '$_temp0';
  }

  @override
  String get metricMemory => 'Memory';

  @override
  String get metricCpuCores => 'CPU cores';

  @override
  String get metricHealth => 'Health';

  @override
  String healthPoolIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pool issues',
      one: '1 pool issue',
    );
    return '$_temp0';
  }

  @override
  String get healthAttention => 'Attention';

  @override
  String get healthHealthy => 'Healthy';

  @override
  String get reportingNoSamples => 'No reporting samples are available yet.';

  @override
  String get reportingCpuUtilisation => 'CPU utilisation';

  @override
  String get reportingMemoryInUse => 'Memory in use';

  @override
  String get reportingLoadAverage => 'Load average (1m)';

  @override
  String get reportingNetworkTraffic => 'Network traffic';

  @override
  String get reportingNetworkReceived => 'Received';

  @override
  String get reportingNetworkSent => 'Sent';

  @override
  String get reportingDiskIo => 'Disk I/O';

  @override
  String get reportingDiskReads => 'Reads';

  @override
  String get reportingDiskWrites => 'Writes';

  @override
  String get reportingCpuHistory => 'CPU history';

  @override
  String get reportingMemoryHistory => 'RAM history';

  @override
  String get reportingNetworkHistory => 'Network history';

  @override
  String get reportingDiskHistory => 'Disk I/O history';

  @override
  String get reportingRangeHour => '1 hour';

  @override
  String get reportingRangeDay => '24 hours';

  @override
  String get reportingRangeWeek => '7 days';

  @override
  String get reportingCurrent => 'Current';

  @override
  String reportingChartSemantics(
    String label,
    String current,
    String minimum,
    String maximum,
  ) {
    return '$label. Current $current. Range $minimum to $maximum.';
  }

  @override
  String get reportingAverage => 'Average';

  @override
  String get reportingMinimum => 'Minimum';

  @override
  String get reportingMaximum => 'Maximum';

  @override
  String get activityNoAttention =>
      'No active alerts or recent jobs need attention.';

  @override
  String get activityEmpty =>
      'Jobs, alerts, and recent changes will appear here.';

  @override
  String get connectTitle => 'Add TrueNAS server';

  @override
  String get registrationTitle => 'Register TrueNAS server';

  @override
  String get serverEntryTitle => 'Choose a server';

  @override
  String get serverRegisterAnother => 'Register another server';

  @override
  String get connectServerName => 'Server name';

  @override
  String get connectServerNameHint => 'Home NAS';

  @override
  String get connectSecureAddress => 'TrueNAS Server Address';

  @override
  String get connectSecureAddressHint => 'https://truenas.local';

  @override
  String get connectSignInWith => 'Sign in with';

  @override
  String get authApiKey => 'API key';

  @override
  String get authLogin => 'Login';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsername => 'Username';

  @override
  String get authUsernameRequired =>
      'Enter the account linked to this credential.';

  @override
  String get authCredentialRequired => 'Enter your credential.';

  @override
  String get authShowCredential => 'Show credential';

  @override
  String get authHideCredential => 'Hide credential';

  @override
  String get authKeepSignedIn => 'Keep me signed in';

  @override
  String get authUnlockWithBiometrics =>
      'Unlock the saved credential with biometrics.';

  @override
  String get authBiometricUnlock => 'Biometric Unlock';

  @override
  String get authBiometricUnlockDescription =>
      'Use Face ID, Touch ID, or fingerprint instead of entering the TrueDock PIN.';

  @override
  String get authCheckingBiometrics => 'Checking biometric protection…';

  @override
  String get authBiometricsUnavailable =>
      'Biometric protection is currently unavailable.';

  @override
  String get authBiometricsProtected => 'Protected by device biometrics';

  @override
  String get authBiometricsNotEnrolled =>
      'Set up Face ID, Touch ID, or fingerprint first';

  @override
  String get authBiometricsUnsupported =>
      'This device does not support biometric sign-in';

  @override
  String get authBiometricsTemporarilyUnavailable =>
      'Biometric sign-in is currently unavailable';

  @override
  String get authProtectWithAppPassword =>
      'Protect the saved credential with a separate TrueDock PIN.';

  @override
  String get appPasswordCreateTitle => 'Create TrueDock PIN';

  @override
  String get appPasswordCreateDescription =>
      'This 6-digit PIN encrypts saved credentials on this device. It is separate from your TrueNAS password and is never stored or synced.';

  @override
  String get appPasswordExistingTitle => 'Enter TrueDock PIN';

  @override
  String get appPasswordExistingDescription =>
      'Use the same TrueDock PIN that protects your other saved server sign-ins.';

  @override
  String get appPasswordLabel => 'TrueDock PIN';

  @override
  String get appPasswordConfirmLabel => 'Confirm TrueDock PIN';

  @override
  String get appPasswordMinimum => 'Enter exactly 6 digits.';

  @override
  String get appPasswordMismatch => 'The PINs do not match.';

  @override
  String get appPasswordIncorrect => 'The TrueDock PIN is incorrect.';

  @override
  String appPasswordUnlockTitle(String serverName) {
    return 'Unlock $serverName';
  }

  @override
  String get appPasswordUnlockDescription =>
      'Enter your separate TrueDock PIN. This is not the TrueNAS account password.';

  @override
  String get appPasswordForgot => 'Forgot your password?';

  @override
  String get appPasswordResetTitle => 'Clear saved sign-in?';

  @override
  String get appPasswordResetDescription =>
      'TrueDock cannot recover this PIN. Every sign-in protected by the TrueDock PIN, including its Biometric Unlock copy, will be removed. Server profiles, TLS certificate trust, legacy biometric-only sign-ins, and TrueNAS data stay unchanged.';

  @override
  String get appPasswordResetAction => 'Clear protected sign-ins';

  @override
  String get authConnectingSecurely => 'Connecting securely…';

  @override
  String get authTransportNotice =>
      'Credentials are sent only through TLS. Saved credentials use platform protection or an encrypted TrueDock PIN vault.';

  @override
  String get savedServersTitle => 'Saved servers';

  @override
  String get savedServerOptions => 'Saved server options';

  @override
  String get savedServerForget => 'Forget server';

  @override
  String get savedServerSignInRequired => 'Sign in required';

  @override
  String savedServerEnterCredential(String serverName) {
    return 'Enter the credential for $serverName below.';
  }

  @override
  String savedServerSignInTitle(String serverName) {
    return 'Sign in to $serverName';
  }

  @override
  String get savedServerAuthenticationFailed =>
      'Could not sign in to the saved server.';

  @override
  String get serverManagementTitle => 'Servers';

  @override
  String get serverManagementDescription =>
      'Switch between registered TrueNAS servers. Credentials and trusted certificates remain isolated per server.';

  @override
  String get serverManagementLoadFailed => 'Could not load registered servers.';

  @override
  String get serverRenameTitle => 'Rename server';

  @override
  String get serverRenameLabel => 'Server name';

  @override
  String get serverRenameAction => 'Rename';

  @override
  String get serverActive => 'Active server';

  @override
  String get serverSwitchTitle => 'Switch server?';

  @override
  String serverSwitchDescription(String serverName) {
    return 'TrueDock will close the current session and connect to $serverName. Server-side jobs already running will continue.';
  }

  @override
  String get serverSwitchAction => 'Switch server';

  @override
  String get serverSwitching => 'Switching…';

  @override
  String get serverSigningIn => 'Signing in…';

  @override
  String get serverSwitchCredentialUnavailable =>
      'This server has no saved sign-in.';

  @override
  String get serverForgetTitle => 'Forget this server?';

  @override
  String serverForgetDescription(String serverName) {
    return 'Remove $serverName and its saved credential from this device.';
  }

  @override
  String serverForgetActiveDescription(String serverName) {
    return 'Disconnect from $serverName, then remove it and its saved credential from this device.';
  }

  @override
  String get connectHeroTitle => 'Dock your TrueNAS';

  @override
  String get connectHeroDescription => 'Supports TrueNAS SCALE 25.10 or later.';

  @override
  String get otpTitle => 'Two-factor authentication';

  @override
  String get otpCode => 'One-time code';

  @override
  String get certificateChangedTitle => 'Server certificate changed';

  @override
  String get certificateExpiredTitle => 'Expired certificate';

  @override
  String get certificateTrustTitle => 'Trust this server?';

  @override
  String get certificateVerifyTitle => 'Verify server certificate';

  @override
  String certificateChangedDescription(String authority) {
    return 'The certificate no longer matches the one saved for $authority. Continue only if you expected this change.';
  }

  @override
  String get certificateExpiredDescription =>
      'This is an expired certificate. Do you want to continue?';

  @override
  String certificateTrustDescription(String authority) {
    return '$authority uses a certificate that is not trusted by the operating system. Compare this fingerprint with your TrueNAS server.';
  }

  @override
  String certificateTrustedDescription(String authority) {
    return 'The operating system trusts the certificate used by $authority. Verify its identity before connecting.';
  }

  @override
  String get certificateUntrustedAcknowledge =>
      'I verified this certificate fingerprint and understand that the operating system does not trust it.';

  @override
  String get certificateFingerprint => 'SHA-256 fingerprint';

  @override
  String get certificateSubject => 'Subject';

  @override
  String get certificateIssuer => 'Issuer';

  @override
  String get certificateValidUntil => 'Valid until';

  @override
  String get certificatePreviousFingerprint => 'Previously trusted fingerprint';

  @override
  String get certificateTrustNew => 'Trust new certificate';

  @override
  String get certificateExpiredContinue => 'Continue anyway';

  @override
  String get certificateTrustAndConnect => 'Trust and connect';

  @override
  String get certificateVerifyAndConnect => 'Verify and connect';

  @override
  String get systemAppearance => 'Appearance';

  @override
  String get systemAppearanceSubtitle => 'Color, light and dark mode';

  @override
  String get systemReduceAnimations => 'Reduced animations';

  @override
  String get systemReduceAnimationsSubtitle =>
      'Use immediate transitions and limit motion throughout TrueDock.';

  @override
  String get diagnosticsPrivacySection => 'Privacy';

  @override
  String get diagnosticsAnonymousTitle => 'Anonymous diagnostics';

  @override
  String get diagnosticsAnonymousDescription =>
      'Share anonymized crash, error, and performance information to help improve TrueDock. Server addresses, accounts, resource names, API data, and credentials are never collected.';

  @override
  String get diagnosticsPrivacyPolicy => 'Privacy Policy';

  @override
  String get diagnosticsNotConfigured =>
      'Diagnostic delivery is not configured for this build. This preference will be used when diagnostics are available.';

  @override
  String get diagnosticsSaving => 'Saving diagnostic preference…';

  @override
  String get diagnosticsUpdateFailed =>
      'Could not change the diagnostic data setting.';

  @override
  String get diagnosticsDisclosureTitle => 'Turn off anonymous diagnostics?';

  @override
  String get diagnosticsDisableAction => 'Turn off';

  @override
  String get systemProtectedSignIn => 'TrueDock PIN';

  @override
  String get systemAppPasswordEnabled => 'Enabled on this device';

  @override
  String get systemAppPasswordDisabled =>
      'Create a PIN to protect saved sign-ins.';

  @override
  String get systemChangeAppPassword => 'Change PIN';

  @override
  String get systemChangeAppPasswordSubtitle =>
      'Re-encrypt every saved sign-in with a new PIN.';

  @override
  String get systemChangeAppPasswordDescription =>
      'Enter the current PIN, then choose a new 6-digit PIN. Saved server sign-ins remain available.';

  @override
  String get systemCurrentAppPassword => 'Current PIN';

  @override
  String get systemNewAppPassword => 'New PIN';

  @override
  String get systemAppPasswordMustChange =>
      'Choose a PIN different from the current PIN.';

  @override
  String get appDataDangerSection => 'Device data';

  @override
  String get appDataResetTitle => 'Erase all TrueDock data';

  @override
  String get appDataResetSubtitle =>
      'Remove server profiles, saved sign-ins, PIN data, biometric copies, trusted certificates, and app settings from this device.';

  @override
  String get appDataResetDialogTitle => 'Erase all data from this device?';

  @override
  String get appDataResetDescription =>
      'This signs out of TrueDock and permanently removes all local TrueDock data from the iOS Keychain or Android secure storage. Data and settings on your TrueNAS servers are not changed.';

  @override
  String get appDataResetIrreversible => 'This action cannot be undone.';

  @override
  String get appDataResetConfirmation => 'RESET';

  @override
  String appDataResetTypePrompt(String confirmation) {
    return 'Type the code $confirmation to continue.';
  }

  @override
  String get appDataResetCodeLabel => 'Data reset confirmation code';

  @override
  String get appDataResetAction => 'Erase all data';

  @override
  String get appDataResetFailed => 'TrueDock could not erase all local data.';

  @override
  String get appDataResetCompleteTitle => 'Reset complete';

  @override
  String get appDataResetCompleteDescription =>
      'All TrueDock data on this device has been erased. You can now set up the app again from the beginning.';

  @override
  String get appDataResetCompleteAction => 'Confirm';

  @override
  String systemSavedSignIns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved server sign-ins',
      one: '1 saved server sign-in',
    );
    return '$_temp0';
  }

  @override
  String get systemCheckingDeviceSecurity => 'Checking device security…';

  @override
  String get systemBiometricUnavailable =>
      'Biometric protection is unavailable';

  @override
  String get systemServerSection => 'Server';

  @override
  String get systemNoServer => 'No server';

  @override
  String systemCommunityVersion(String version) {
    return 'Community $version';
  }

  @override
  String get systemConnectServer => 'Connect a TrueNAS server';

  @override
  String get systemDisconnect => 'Disconnect';

  @override
  String get systemPinnedCertificate => 'Trusted Certificate';

  @override
  String certificateDetailsDescription(String authority) {
    return 'The certificate currently presented by $authority is compared with the fingerprint saved for this server.';
  }

  @override
  String get certificateValidFrom => 'Valid from';

  @override
  String get certificateTrustStatus => 'Trust status';

  @override
  String get certificateSystemTrust => 'System trust';

  @override
  String get certificatePinnedAndMatched =>
      'Matches the certificate trusted by TrueDock';

  @override
  String get certificatePinnedMismatch =>
      'Does not match the certificate trusted by TrueDock';

  @override
  String get certificateSystemTrusted => 'Also trusted by the operating system';

  @override
  String get certificateTrueDockTrustedOnly =>
      'Trusted by TrueDock for this server';

  @override
  String get certificateExpiredWarning =>
      'This certificate has expired. Ask the TrueNAS administrator to renew it.';

  @override
  String get certificateExpiringSoonWarning =>
      'This certificate expires soon. Ask the TrueNAS administrator to renew it.';

  @override
  String get certificateDetailsLoadFailed =>
      'Could not read the server certificate.';

  @override
  String get systemAdministration => 'Administration';

  @override
  String get systemGeneralSettings => 'General settings';

  @override
  String get systemGeneralSettingsSubtitle =>
      'Hostname, timezone, syslog, power';

  @override
  String get systemAdvanced => 'Advanced';

  @override
  String get systemAdvancedSubtitle => 'Boot environments and recovery';

  @override
  String get systemAlertsAndJobs => 'Alerts and jobs';

  @override
  String get systemUsersAndAccess => 'Users and access';

  @override
  String get systemNetwork => 'Network';

  @override
  String get systemUpdates => 'Updates';

  @override
  String get systemSettingsLoadFailed => 'Could not load the server settings.';

  @override
  String get systemActivityLoadFailed => 'Could not load system activity.';

  @override
  String get systemNoChanges => 'No changes to save.';

  @override
  String get systemServerFallback => 'this TrueNAS server';

  @override
  String get systemSaveSettingsTitle => 'Save server settings?';

  @override
  String get systemGeneralSettingsTarget => 'general settings';

  @override
  String get actionSaveChanges => 'Save changes';

  @override
  String get systemHostnameChangeImpact =>
      'The hostname changes after the server reloads its network configuration. Active sessions are not affected.';

  @override
  String get systemSettingsChangeImpact =>
      'The settings are updated on the server.';

  @override
  String get systemSettingsSaveFailed => 'TrueNAS could not save the settings.';

  @override
  String get systemSettingsSaved => 'Server settings saved.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeColor => 'Color';

  @override
  String get themeSystemDynamicColor => 'System dynamic color';

  @override
  String get themeSystemDynamicColorSubtitle =>
      'Match the Android wallpaper palette';

  @override
  String themeColorSemantics(String hex) {
    return 'Theme color $hex';
  }

  @override
  String get themeCustomColor => 'Custom color';

  @override
  String get themeCustomSourceColor => 'Custom source color';

  @override
  String get themeHexColor => 'Hex color';

  @override
  String get themeColorPickerArea => 'Color saturation and brightness';

  @override
  String get themeColorHue => 'Color hue';

  @override
  String get actionApply => 'Apply';

  @override
  String get themeInvalidHex => 'Enter six hexadecimal digits.';

  @override
  String get storageTitle => 'Storage';

  @override
  String get storageLoadFailed => 'Could not load storage information.';

  @override
  String get storageLandingDescription =>
      'Pools, disks, datasets, snapshots, and shares in one place.';

  @override
  String get storageFeaturePools => 'Pools';

  @override
  String get storageFeaturePoolsSubtitle => 'Capacity, topology, health';

  @override
  String get storageFeatureDatasets => 'Datasets';

  @override
  String get storageFeatureDatasetsSubtitle => 'Properties, quotas, encryption';

  @override
  String get storageFeatureSnapshots => 'Snapshots';

  @override
  String get storageFeatureSnapshotsSubtitle =>
      'Browse, create, clone, restore';

  @override
  String get storageFeatureDisks => 'Disks';

  @override
  String get storageFeatureDisksSubtitle => 'Inventory, capacity, temperatures';

  @override
  String get storageFeatureShares => 'Shares';

  @override
  String get storageFeatureSharesSubtitle => 'SMB, NFS, iSCSI, WebShare';

  @override
  String get storageRefreshTooltip => 'Refresh storage';

  @override
  String get storageDatasetCreated => 'Dataset created.';

  @override
  String get storageSmbShare => 'SMB share';

  @override
  String get storageNfsShare => 'NFS share';

  @override
  String get storageIscsiPortal => 'iSCSI portal';

  @override
  String get storageIscsiInitiatorGroup => 'iSCSI initiator group';

  @override
  String get storageIscsiTarget => 'iSCSI target';

  @override
  String get storageIscsiExtent => 'iSCSI extent';

  @override
  String get storageIscsiLunAssociation => 'iSCSI LUN association';

  @override
  String storageIscsiPortalWithAddress(String address) {
    return 'iSCSI portal · $address';
  }

  @override
  String storageDiskTitle(String name, String model) {
    return '$name · $model';
  }

  @override
  String get storageChapCredentials => 'CHAP credentials';

  @override
  String get storageNoUnusedDisksForPool =>
      'No unused disks are available to create a pool.';

  @override
  String get storageCreateTargetExtentFirst =>
      'Create at least one target and one extent first.';

  @override
  String get storageCreateSnapshotRecursively =>
      'Create the snapshot recursively';

  @override
  String get storageIncludeChildDatasets => 'Include child datasets';

  @override
  String get storageDiskLabelModel => 'Model';

  @override
  String get storageDiskLabelSerial => 'Serial';

  @override
  String get storageDiskUnknownModel => 'Unknown model';

  @override
  String get storageDiskNoSerial => 'No serial';

  @override
  String get storageDiskLabelCapacity => 'Capacity';

  @override
  String get storageDiskLabelMedia => 'Media';

  @override
  String get storageDiskLabelPool => 'Pool';

  @override
  String get storageDiskLabelUnassigned => 'Unassigned';

  @override
  String get storageDiskLabelRotation => 'Rotation';

  @override
  String get storageDiskLabelTemperature => 'Temperature';

  @override
  String get storageDiskLabelRatedMaximum => 'Rated maximum';

  @override
  String get storageDiskLabelCriticalAt => 'Critical at';

  @override
  String get storageLabelUsed => 'Used';

  @override
  String get storageLabelFree => 'Free';

  @override
  String get storageLabelFragmentation => 'Fragmentation';

  @override
  String get poolScrubStart => 'Start scrub';

  @override
  String get poolScrubStartSubtitle =>
      'Verifies every block. Uses disk bandwidth.';

  @override
  String get poolScrubPause => 'Pause scrub';

  @override
  String get poolScrubPauseSubtitle => 'Progress is kept and can be resumed.';

  @override
  String get poolScrubStop => 'Stop scrub';

  @override
  String get poolScrubStopSubtitle => 'Progress is discarded.';

  @override
  String get poolScrubResume => 'Resume scrub';

  @override
  String get poolScrubPaused => 'Scrub paused';

  @override
  String get poolScrubRunning => 'Scrub running';

  @override
  String poolScrubProgress(double percent) {
    return '$percent% complete';
  }

  @override
  String get poolMembers => 'Pool members';

  @override
  String poolMembersCount(int count) {
    return '$count device(s)';
  }

  @override
  String get poolAttachDisk => 'Attach disk';

  @override
  String get poolAttachDiskSubtitle =>
      'Add a disk to a mirror or stripe. Starts a resilver.';

  @override
  String get poolReplaceDisk => 'Replace disk';

  @override
  String get poolReplaceDiskSubtitle =>
      'Swap a member for a new disk. Old disk is removed after resilver.';

  @override
  String get poolExportOrDestroy => 'Export or destroy pool';

  @override
  String get poolExportOrDestroySubtitle =>
      'Removes the pool from this server.';

  @override
  String get poolMembersDescription =>
      'Taking a device offline leaves the pool degraded until it is brought back or replaced.';

  @override
  String poolMemberCategoryStatus(String category, String status) {
    return '$category · $status';
  }

  @override
  String get poolTakeOffline => 'Take offline';

  @override
  String get poolBringOnline => 'Bring online';

  @override
  String get poolOfflineUseOnly => 'Offline use only';

  @override
  String get poolAttachDescription =>
      'Choose the vdev to add a disk to. Only mirror and stripe vdevs accept an attached disk; attaching to a mirror starts a resilver.';

  @override
  String get poolNoUnusedDisks =>
      'No unused disks are available on this server.';

  @override
  String poolVdevTitle(String guid) {
    return 'vdev $guid';
  }

  @override
  String poolContainsMember(String name, String status) {
    return 'Contains $name · $status';
  }

  @override
  String get poolReplaceDescription =>
      'Pick the member to replace, then choose a new disk. The old disk is removed from the pool once the resilver finishes and is safe to remove.';

  @override
  String get poolForceRemoveOldDisk => 'Force remove old disk';

  @override
  String get poolForceRemoveOldDiskSubtitle =>
      'Removes the old disk even if it is still being read. Use only if the disk has failed.';

  @override
  String get poolChooseReplacementDisk => 'Choose replacement disk';

  @override
  String poolAttachToVdev(String guid) {
    return 'Attach to vdev $guid';
  }

  @override
  String poolReplaceTarget(String name) {
    return 'Replace $name';
  }

  @override
  String get poolExportTitle => 'Export pool';

  @override
  String get poolExportDescription =>
      'Exporting detaches the pool from this server. Without destroying data the disks can be imported again here or on another system.';

  @override
  String get poolDeleteSharesAndTasks =>
      'Delete shares and tasks using this pool';

  @override
  String get poolDestroyAllData => 'Destroy all data on the disks';

  @override
  String get poolDestroyAllDataSubtitle =>
      'The pool can never be imported again.';

  @override
  String get poolOperationsUnavailable =>
      'This TrueNAS version does not expose pool operations to TrueDock.';

  @override
  String poolStatusFree(String status, String free) {
    return '$status · $free free';
  }

  @override
  String get datasetCreateFilesystem => 'Create dataset';

  @override
  String get datasetCreateVolume => 'Create volume';

  @override
  String get datasetVolumeDescription =>
      'A volume is a block device, used by iSCSI extents and virtual machine disks. Encryption inherits from the selected parent.';

  @override
  String get datasetFilesystemDescription =>
      'Encryption settings inherit from the selected parent.';

  @override
  String get datasetTypeFilesystem => 'Filesystem';

  @override
  String get datasetTypeVolume => 'Volume';

  @override
  String get datasetParent => 'Parent';

  @override
  String get datasetVolumeName => 'Volume name';

  @override
  String get datasetName => 'Dataset name';

  @override
  String get datasetEnterVolumeName => 'Enter a volume name.';

  @override
  String get datasetEnterName => 'Enter a dataset name.';

  @override
  String get datasetUseParentForPaths => 'Use the Parent field for paths.';

  @override
  String get datasetSizeInGib => 'Size in GiB';

  @override
  String get datasetEnterSizeInGib => 'Enter a size in GiB.';

  @override
  String get datasetEnterSizePositive => 'Enter a size greater than zero.';

  @override
  String get datasetSparseThin => 'Sparse (thin provision)';

  @override
  String get datasetSparseSubtitle =>
      'Reserves no space up front. Writes can fail once the pool fills, even though the volume reports free space.';

  @override
  String get datasetWorkloadOptimization => 'Workload optimization';

  @override
  String get datasetShareGeneric => 'Generic';

  @override
  String get datasetShareSmb => 'SMB';

  @override
  String get datasetShareNfs => 'NFS';

  @override
  String get datasetShareMultiprotocol => 'Multiprotocol';

  @override
  String get datasetShareApps => 'Apps';

  @override
  String get datasetCreating => 'Creating…';

  @override
  String get datasetOperationFailed => 'The TrueNAS operation failed.';

  @override
  String get datasetEditTitle => 'Edit dataset';

  @override
  String get datasetReviewTitle => 'Review dataset changes';

  @override
  String get datasetApplyChanges => 'Apply changes';

  @override
  String get datasetReview => 'Review';

  @override
  String get datasetComments => 'Comments';

  @override
  String get datasetCompression => 'Compression';

  @override
  String get datasetSync => 'Sync';

  @override
  String get datasetSyncInherit => 'Inherit';

  @override
  String get datasetSyncStandard => 'Standard';

  @override
  String get datasetSyncDisabled => 'Disabled';

  @override
  String get datasetSyncAlways => 'Always';

  @override
  String get datasetAtimeDisabled => 'Disabled';

  @override
  String get datasetReadOnly => 'Read-only';

  @override
  String get datasetReadOnlyDescription => 'Block writes to this dataset';

  @override
  String get datasetReadOnlyWarning =>
      'Applications and shares writing to this dataset will start failing.';

  @override
  String get datasetQuota => 'Quota';

  @override
  String get datasetDataQuota => 'Data quota';

  @override
  String get datasetDataQuotaDescription =>
      'Limits only the data written directly to this dataset.';

  @override
  String get datasetDatasetQuota => 'Dataset quota';

  @override
  String get datasetDatasetQuotaDescription =>
      'Limits this dataset and its children, including snapshots.';

  @override
  String get datasetQuotaLeaveEmpty => 'Leave empty for no limit';

  @override
  String get datasetQuotaEnterPositive =>
      'Enter quota sizes as a positive number.';

  @override
  String get datasetNothingChanged => 'Nothing has changed for this dataset.';

  @override
  String get datasetReadOnlyReviewWarning =>
      'Applications and shares writing to this dataset will start failing until read-only is turned off again.';

  @override
  String get datasetSyncDisabledWarning =>
      'Disabling sync risks losing recent writes if the server loses power.';

  @override
  String get datasetChangeCommentsInherited =>
      'Comments inherit from the parent.';

  @override
  String get datasetChangeCommentsCleared => 'Comments cleared.';

  @override
  String datasetChangeCommentsSet(String value) {
    return 'Comments set to “$value”.';
  }

  @override
  String get datasetChangeQuotaInherited =>
      'Dataset quota inherits from the parent.';

  @override
  String get datasetChangeQuotaRemoved => 'Dataset quota removed.';

  @override
  String datasetChangeQuotaSet(String value) {
    return 'Dataset quota set to $value.';
  }

  @override
  String get datasetChangeRefquotaInherited =>
      'Data quota inherits from the parent.';

  @override
  String get datasetChangeRefquotaRemoved => 'Data quota removed.';

  @override
  String datasetChangeRefquotaSet(String value) {
    return 'Data quota set to $value.';
  }

  @override
  String get datasetChangeReadOnlyInherited =>
      'Read-only inherits from the parent.';

  @override
  String get datasetChangeReadOnlyEnabled => 'Dataset becomes read-only.';

  @override
  String get datasetChangeReadOnlyDisabled => 'Dataset becomes writable.';

  @override
  String get datasetChangeCompressionInherited =>
      'Compression inherits from the parent.';

  @override
  String datasetChangeCompressionSet(String value) {
    return 'Compression set to $value.';
  }

  @override
  String get datasetChangeSyncInherited => 'Sync inherits from the parent.';

  @override
  String datasetChangeSyncSet(String value) {
    return 'Sync set to $value.';
  }

  @override
  String datasetChangePropertyUpdated(String property) {
    return '$property updated.';
  }

  @override
  String get datasetCompressionInherit => 'Inherit';

  @override
  String get datasetCompressionOff => 'Off';

  @override
  String get datasetCompressionLz4 => 'LZ4';

  @override
  String get datasetCompressionZstd => 'ZSTD';

  @override
  String get datasetCompressionGzip => 'GZIP';

  @override
  String get datasetCompressionZle => 'ZLE';

  @override
  String get datasetCompressionLzjb => 'LZJB';

  @override
  String get datasetAtimeInherit => 'Inherit';

  @override
  String get datasetAtimeOn => 'On';

  @override
  String get datasetExecInherit => 'Inherit';

  @override
  String get datasetExecOn => 'On';

  @override
  String get datasetExecOff => 'Off';

  @override
  String get datasetBlockSizeInherit => 'Inherit';

  @override
  String get datasetStorageInherit => 'Inherit';

  @override
  String get poolCreateReviewTitle => 'Review new pool';

  @override
  String get poolCreateTitle => 'Create pool';

  @override
  String get poolCreateClose => 'Close';

  @override
  String get poolCreateBack => 'Back';

  @override
  String get poolCreateCancel => 'Cancel';

  @override
  String get poolCreateReview => 'Review';

  @override
  String get poolCreateNameLabel => 'Pool name';

  @override
  String get poolCreateNameHelper =>
      'Used as the dataset root. Start with a letter.';

  @override
  String get poolCreateDataVdevs => 'Data vdevs';

  @override
  String get poolCreateDataVdevsDescription =>
      'The data tier is required. Each vdev groups disks with one layout. A pool stripes across multiple data vdevs.';

  @override
  String get poolCreateVdevLayout => 'Vdev layout';

  @override
  String get poolCreateAddDataVdev => 'Add data vdev';

  @override
  String poolCreateDataVdevLabel(int index) {
    return 'Data vdev $index';
  }

  @override
  String get poolCreateCache => 'Cache (L2ARC, optional)';

  @override
  String poolCreateCacheVdevLabel(int index) {
    return 'Cache vdev $index';
  }

  @override
  String get poolCreateAddCacheVdev => 'Add cache vdev';

  @override
  String get poolCreateOptions => 'Options';

  @override
  String get poolCreateEncryption => 'Encryption';

  @override
  String get poolCreateEncryptionSubtitle =>
      'Encrypts the pool at rest. You must manage the keys.';

  @override
  String get poolCreateDeduplication => 'Deduplication';

  @override
  String get poolCreateDeduplicationSubtitle =>
      'Block-based dedup. Uses more memory; check your RAM before enabling.';

  @override
  String get poolCreateAutoTrim => 'Auto TRIM';

  @override
  String get poolCreateAutoTrimSubtitle =>
      'Reclaims unused space automatically.';

  @override
  String get poolCreateReviewName => 'Name';

  @override
  String poolCreateReviewDataVdevsValue(int vdevCount, int diskCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diskCount,
      locale: localeName,
      other: '$diskCount disks',
      one: '1 disk',
    );
    return '$vdevCount · $_temp0';
  }

  @override
  String poolCreateReviewVdevLabel(int index) {
    return '  vdev $index';
  }

  @override
  String poolCreateReviewVdevValue(String type, int diskCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diskCount,
      locale: localeName,
      other: '$diskCount disks',
      one: '1 disk',
    );
    return '$type · $_temp0';
  }

  @override
  String get poolCreateReviewCacheVdevs => 'Cache vdevs';

  @override
  String poolCreateReviewCacheVdevsValue(int count) {
    return '$count';
  }

  @override
  String get poolCreateReviewTotalDisks => 'Total disks';

  @override
  String get poolCreateOn => 'On';

  @override
  String get poolCreateOff => 'Off';

  @override
  String get poolCreateNoticeEncrypted =>
      'Creating an encrypted pool formats every selected disk. You must keep the recovery key safe or the data is unrecoverable.';

  @override
  String get poolCreateNoticePlain =>
      'Creating a pool formats every selected disk. Existing data on those disks is lost.';

  @override
  String get poolCreateNoticeDedup =>
      'Deduplication increases memory use. Disable it if the server runs out of memory under load.';

  @override
  String get poolCreateNoticeStripe =>
      'Stripe and single-disk pools have no redundancy. A disk failure loses the pool. Use a mirror or RAIDZ for safety.';

  @override
  String get poolCreateNoDisksSelected => 'No disks selected';

  @override
  String poolCreateDisksCount(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disks: $names',
      one: '1 disk: $names',
    );
    return '$_temp0';
  }

  @override
  String get poolCreateRemoveVdev => 'Remove vdev';

  @override
  String get poolCreateSelectDisks => 'Select disks';

  @override
  String poolCreateDiskPickerHint(String type, int minimum, int selected) {
    return '$type needs at least $minimum disk(s). Selected: $selected';
  }

  @override
  String poolCreateAddDisks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count disks',
      one: '1 disk',
    );
    return 'Add $_temp0';
  }

  @override
  String poolCreateSelectAtLeast(int minimum) {
    return 'Select at least $minimum';
  }

  @override
  String get poolVdevStripe => 'Stripe';

  @override
  String get poolVdevMirror => 'Mirror';

  @override
  String get poolVdevRaidz1 => 'RAIDZ1';

  @override
  String get poolVdevRaidz2 => 'RAIDZ2';

  @override
  String get poolVdevRaidz3 => 'RAIDZ3';

  @override
  String get poolVdevStripeWarning =>
      'No redundancy. A single disk failure loses the pool.';

  @override
  String get poolVdevMirrorWarning => 'Tolerates one disk failure per pair.';

  @override
  String get poolVdevRaidz1Warning => 'Tolerates one disk failure.';

  @override
  String get poolVdevRaidz2Warning => 'Tolerates two disk failures.';

  @override
  String get poolVdevRaidz3Warning => 'Tolerates three disk failures.';

  @override
  String get poolValidationNameRequired => 'Enter a pool name.';

  @override
  String get poolValidationNameInvalid =>
      'Start with a letter and use letters, numbers, or . _ : -.';

  @override
  String get poolValidationDataVdevRequired => 'Add at least one data vdev.';

  @override
  String poolValidationDataVdevNoDisks(int index) {
    return 'Data vdev $index has no disks.';
  }

  @override
  String poolValidationMinimumDisks(String type, int index, int minimum) {
    return '$type vdev $index needs at least $minimum disks.';
  }

  @override
  String get iscsiTargetReviewTitle => 'Review iSCSI target';

  @override
  String get iscsiTargetEditTitle => 'Edit iSCSI target';

  @override
  String get iscsiTargetNewTitle => 'New iSCSI target';

  @override
  String get iscsiTargetSubtitle =>
      'Target identity, access, and portal groups';

  @override
  String get iscsiTargetClose => 'Close';

  @override
  String get iscsiTargetBack => 'Back';

  @override
  String get iscsiTargetCancel => 'Cancel';

  @override
  String get iscsiTargetSaveChanges => 'Save changes';

  @override
  String get iscsiTargetCreate => 'Create target';

  @override
  String get iscsiTargetReview => 'Review';

  @override
  String get iscsiTargetNameLabel => 'Target name';

  @override
  String get iscsiTargetNameHelper => 'An IQN or another unique target name';

  @override
  String get iscsiTargetAliasLabel => 'Alias';

  @override
  String get iscsiTargetAliasHelper => 'Optional human-readable target label';

  @override
  String get iscsiTargetNetworksLabel => 'Authorized networks';

  @override
  String get iscsiTargetNetworksHelper =>
      'One CIDR network per line · empty allows all networks';

  @override
  String get iscsiTargetQueuedLabel => 'Queued commands';

  @override
  String get iscsiTargetQueuedHelper =>
      'Use the server default unless a workload requires tuning';

  @override
  String get iscsiTargetQueueServerDefault => 'Server default';

  @override
  String get iscsiTargetQueue32 => '32 commands';

  @override
  String get iscsiTargetQueue128 => '128 commands';

  @override
  String get iscsiTargetGroups => 'Target groups';

  @override
  String get iscsiTargetAddGroup => 'Add group';

  @override
  String get iscsiTargetGroupsDescription =>
      'Each group binds a portal to all initiators or a selected initiator group.';

  @override
  String get iscsiTargetNoGroupsNotice =>
      'This target has no portal groups and will be unreachable until a group is added.';

  @override
  String get iscsiTargetNoPortalsNotice =>
      'No iSCSI portals are available. Create a portal before adding a target group.';

  @override
  String get iscsiTargetUnrestrictedNotice =>
      'An unauthenticated group allows every initiator from every authorized network. With no authorized networks, it is open to every network.';

  @override
  String get iscsiTargetMutualChapGroup => 'Mutual CHAP group';

  @override
  String get iscsiTargetChapGroup => 'CHAP group';

  @override
  String iscsiTargetPortalValue(String value) {
    return 'Portal: $value';
  }

  @override
  String iscsiTargetInitiatorsValue(String value) {
    return 'Initiators: $value';
  }

  @override
  String iscsiTargetCredentialValue(String value) {
    return 'Credential ID: $value';
  }

  @override
  String get iscsiTargetUnavailable => 'Unavailable';

  @override
  String get iscsiTargetLockedAuthNotice =>
      'Authentication credentials are preserved and cannot be changed or removed in this release.';

  @override
  String iscsiTargetUnauthenticatedGroup(int index) {
    return 'Unauthenticated group $index';
  }

  @override
  String iscsiTargetRemoveGroup(int index) {
    return 'Remove group $index';
  }

  @override
  String get iscsiTargetPortalLabel => 'Portal';

  @override
  String get iscsiTargetInitiatorsLabel => 'Initiators';

  @override
  String get iscsiTargetAllInitiators => 'All initiators';

  @override
  String get iscsiTargetAuthentication => 'Authentication';

  @override
  String get iscsiTargetAuthNone => 'None';

  @override
  String get iscsiTargetChapOneWay => 'CHAP (one-way)';

  @override
  String get iscsiTargetChapMutual => 'CHAP (mutual)';

  @override
  String get iscsiTargetChapCredential => 'CHAP credential';

  @override
  String get iscsiTargetNoChapCredentials =>
      'No CHAP credentials are configured. Create one first.';

  @override
  String get iscsiTargetChapRequiredNotice =>
      'CHAP authentication requires at least one credential. Create one under CHAP credentials before adding an authenticated group.';

  @override
  String get iscsiTargetReviewName => 'Name';

  @override
  String get iscsiTargetReviewNetworks => 'Networks';

  @override
  String get iscsiTargetAllNetworks => 'All networks';

  @override
  String get iscsiTargetQueueDepth => 'Queue depth';

  @override
  String iscsiTargetReviewGroup(int index, String authMethod) {
    return 'Group $index · $authMethod';
  }

  @override
  String iscsiTargetCredentialId(String id) {
    return 'Credential ID $id';
  }

  @override
  String get iscsiTargetReviewNoGroupNotice =>
      'This target will be created without a portal group and will be unreachable until one is added.';

  @override
  String get iscsiTargetReviewUnrestrictedNotice =>
      'This target includes an unauthenticated group open to every initiator. With no authorized networks, it is open to every network.';

  @override
  String get iscsiTargetReviewValidationNotice =>
      'TrueNAS will validate the target name, networks, portals, initiators, and preserved authentication groups.';

  @override
  String iscsiTargetPortalTag(int tag) {
    return 'Portal $tag';
  }

  @override
  String iscsiTargetPortalTagDetail(int tag, String detail) {
    return 'Portal $tag · $detail';
  }

  @override
  String iscsiTargetPortalUnavailable(int id) {
    return 'Portal ID $id · unavailable';
  }

  @override
  String iscsiTargetInitiatorGroup(int id) {
    return 'Initiator group $id';
  }

  @override
  String iscsiTargetInitiatorGroupDetail(int id, String detail) {
    return 'Initiator group $id · $detail';
  }

  @override
  String iscsiTargetInitiatorUnavailable(int id) {
    return 'Initiator ID $id · unavailable';
  }

  @override
  String get iscsiTargetValidationName =>
      'Enter a target name between 1 and 120 characters.';

  @override
  String get iscsiTargetValidationGroups =>
      'Use available portals and initiators with unique, valid authentication groups.';

  @override
  String get iscsiTargetValidationNetworks =>
      'Use unique IPv4 or IPv6 networks in CIDR notation.';

  @override
  String get iscsiTargetValidationQueued =>
      'Queued commands must be 32 or 128.';

  @override
  String get smbReviewTitle => 'Review SMB share';

  @override
  String get smbEditTitle => 'Edit SMB share';

  @override
  String get smbNewTitle => 'New SMB share';

  @override
  String get smbClose => 'Close';

  @override
  String get smbBack => 'Back';

  @override
  String get smbCancel => 'Cancel';

  @override
  String get smbSaveChanges => 'Save changes';

  @override
  String get smbCreateShare => 'Create share';

  @override
  String get smbReview => 'Review';

  @override
  String get smbPurpose => 'Purpose';

  @override
  String get smbShareName => 'Share name';

  @override
  String get smbSharePath => 'Share path';

  @override
  String get smbSharePathHelper => 'An existing path in a ZFS pool under /mnt/';

  @override
  String get smbExternalDestinations => 'External destinations';

  @override
  String get smbExternalDestinationsHelper =>
      'One SERVER\\SHARE destination per line';

  @override
  String get smbComment => 'Comment';

  @override
  String get smbEnableShare => 'Enable share';

  @override
  String get smbEnableShareDescription => 'Make the share available over SMB.';

  @override
  String get smbReadOnly => 'Read only';

  @override
  String get smbReadOnlyDescription =>
      'Prevent SMB clients from changing files.';

  @override
  String get smbShowInBrowsing => 'Show in network browsing';

  @override
  String get smbAccessBasedEnumeration => 'Access-based enumeration';

  @override
  String get smbAccessBasedEnumerationDescription =>
      'Show the share only to users allowed by its share ACL.';

  @override
  String get smbNetworkRestrictions => 'Network restrictions';

  @override
  String get smbNetworkRestrictionsDescription =>
      'Optional IP addresses, subnets, or ALL';

  @override
  String get smbAllowedHosts => 'Allowed hosts';

  @override
  String get smbAllowedHostsHelper =>
      'One entry per line · empty allows normal access';

  @override
  String get smbDeniedHosts => 'Denied hosts';

  @override
  String get smbOneEntryPerLine => 'One entry per line';

  @override
  String get smbAuditing => 'Auditing';

  @override
  String get smbAuditingDescription => 'Record SMB access for selected groups';

  @override
  String get smbEnableAuditing => 'Enable auditing';

  @override
  String get smbGroupsToAudit => 'Groups to audit';

  @override
  String get smbGroupsToAuditHelper =>
      'One group per line · empty audits all groups';

  @override
  String get smbGroupsToIgnore => 'Groups to ignore';

  @override
  String get smbOneGroupPerLine => 'One group per line';

  @override
  String get smbTimeMachineQuota => 'Time Machine quota (bytes)';

  @override
  String get smbZeroDisablesServerQuota => '0 disables the server-side quota';

  @override
  String get smbSnapshotAfterBackup => 'Snapshot after a new backup';

  @override
  String get smbDatasetPerUser => 'Create a dataset per user';

  @override
  String get smbGracePeriod => 'Write grace period (seconds)';

  @override
  String get smbPerUserQuota => 'Per-user quota (GiB)';

  @override
  String get smbZeroDisablesAutoQuota => '0 disables automatic quotas';

  @override
  String get smbAppleFilenameMangling => 'Apple filename mangling';

  @override
  String get smbAppleFilenameManglingDescription =>
      'Preserve macOS filename characters that are illegal on Windows.';

  @override
  String get smbDatasetNamingSchema => 'Dataset naming schema';

  @override
  String get smbDatasetNamingSchemaHelper => 'For example %U or %D/%U';

  @override
  String get smbFinalCutNotice =>
      'Final Cut Pro forces Apple filename mangling and requires global Apple SMB extensions.';

  @override
  String get smbExternalNotice =>
      'TrueNAS does not verify that external DFS destinations are reachable.';

  @override
  String get smbUnsupportedNotice =>
      'This legacy or server-specific share can only be inspected.';

  @override
  String get smbReviewShare => 'Share';

  @override
  String get smbReviewLocation => 'Location';

  @override
  String get smbReviewAccess => 'Access';

  @override
  String get smbReadAndWrite => 'Read and write';

  @override
  String get smbVisibility => 'Visibility';

  @override
  String get smbBrowsableWhenAclPermits => 'Browsable when ACL permits';

  @override
  String get smbBrowsable => 'Browsable';

  @override
  String get smbHiddenFromBrowsing => 'Hidden from browsing';

  @override
  String get smbState => 'State';

  @override
  String get smbEnabled => 'Enabled';

  @override
  String get smbDisabled => 'Disabled';

  @override
  String get smbTimeLockedNotice =>
      'Time locking applies only through this SMB share and is not a regulatory write-once guarantee.';

  @override
  String get smbMultiprotocolNotice =>
      'Multiprotocol compatibility disables some SMB optimizations for safer external access.';

  @override
  String get smbValidationNotice =>
      'TrueNAS will validate the path, share name, purpose options, permissions, and SMB prerequisites.';

  @override
  String get smbPurposeDefault => 'Default share';

  @override
  String get smbPurposeTimeMachine => 'Time Machine';

  @override
  String get smbPurposeMultiprotocol => 'Multiprotocol';

  @override
  String get smbPurposeTimeLocked => 'Time locked';

  @override
  String get smbPurposePrivateDatasets => 'Private datasets';

  @override
  String get smbPurposeExternal => 'External DFS';

  @override
  String get smbPurposeFinalCut => 'Final Cut Pro';

  @override
  String get smbPurposeUnsupported => 'Unsupported';

  @override
  String get smbPurposeDefaultDescription =>
      'Best compatibility for ordinary SMB clients.';

  @override
  String get smbPurposeTimeMachineDescription =>
      'Advertise storage as an Apple Time Machine destination.';

  @override
  String get smbPurposeMultiprotocolDescription =>
      'Safer interoperability when the same data is accessed outside SMB.';

  @override
  String get smbPurposeTimeLockedDescription =>
      'Make files read-only through SMB after a grace period.';

  @override
  String get smbPurposePrivateDatasetsDescription =>
      'Create a separate ZFS dataset for each connecting user.';

  @override
  String get smbPurposeExternalDescription =>
      'Proxy clients to a share hosted on another SMB server.';

  @override
  String get smbPurposeFinalCutDescription =>
      'Storage configured for Apple Final Cut Pro workflows.';

  @override
  String get smbPurposeUnsupportedDescription =>
      'This server share purpose cannot be edited by TrueDock.';

  @override
  String get smbValidationNameRequired => 'Enter a share name.';

  @override
  String get smbValidationNameInvalid => 'Enter a valid unique SMB share name.';

  @override
  String get smbValidationPurpose => 'This SMB share purpose cannot be edited.';

  @override
  String get smbValidationPath => 'Choose a dataset path under /mnt/.';

  @override
  String get smbValidationRemotePaths =>
      'Use one SERVER\\SHARE destination per line.';

  @override
  String get smbValidationTimeMachineQuota => 'Quota cannot be negative.';

  @override
  String get smbValidationGracePeriod =>
      'Grace period must be 60–15,552,000 seconds.';

  @override
  String get smbValidationAutoQuota => 'Automatic quota cannot be negative.';

  @override
  String get smbValidationDatasetSchema => 'Enter a dataset naming schema.';

  @override
  String get appsTitle => 'Apps';

  @override
  String get appsLoadFailed => 'Could not load apps and services.';

  @override
  String get appsLandingDescription =>
      'Control apps, containers, virtual machines, and services.';

  @override
  String get appsRefreshTooltip => 'Refresh apps';

  @override
  String get appsInstalledApps => 'Installed apps';

  @override
  String get appsFeatureInstalledSubtitle => 'Start, stop, update, rollback';

  @override
  String get appsDiscover => 'Discover';

  @override
  String get appsFeatureDiscoverSubtitle => 'Browse the configured catalog';

  @override
  String get appsContainers => 'Containers';

  @override
  String get appsFeatureContainersSubtitle => 'Instances, metrics, devices';

  @override
  String get appsVirtualMachines => 'Virtual machines';

  @override
  String get appsFeatureVirtualMachinesSubtitle =>
      'Lifecycle, display, devices';

  @override
  String get appsServices => 'Services';

  @override
  String get appsFeatureServicesSubtitle => 'State, startup, configuration';

  @override
  String get appsNoAppsInstalled => 'No apps are installed.';

  @override
  String get appsNoVirtualMachines => 'No virtual machines found.';

  @override
  String get appsContainersUnsupported =>
      'Standalone containers are not exposed by this TrueNAS version. Installed Apps remain available above.';

  @override
  String get appsNoContainers => 'No standalone containers found.';

  @override
  String get appsInstances => 'Instances';

  @override
  String get appsInstancesUnsupported =>
      'This TrueNAS version does not expose the Instances API.';

  @override
  String get appsInstancesNoPool =>
      'Instances need a storage pool before any container or VM can be created. Choose one to initialize the platform.';

  @override
  String get appsInstancesChoosePool => 'Choose storage pool';

  @override
  String get appsInstancesPoolTitle => 'Storage for instances';

  @override
  String appsInstancesPoolConsequence(String pool) {
    return 'TrueNAS creates a hidden .ix-virt dataset on $pool and every instance stores its disks there. Moving it later means recreating the instances.';
  }

  @override
  String appsInstancesPoolApplied(String pool) {
    return 'Instance storage set to $pool.';
  }

  @override
  String get appsNoInstances => 'No instances yet.';

  @override
  String get appsInstanceCreate => 'Create instance';

  @override
  String get appsInstanceKindContainer => 'Container';

  @override
  String get appsInstanceKindVm => 'VM';

  @override
  String get appsInstanceLabelImage => 'Image';

  @override
  String get appsInstanceLabelCpu => 'CPU';

  @override
  String get appsInstanceLabelMemory => 'Memory';

  @override
  String get appsInstanceLabelPool => 'Storage pool';

  @override
  String get appsInstanceLabelRootDisk => 'Root disk';

  @override
  String get appsInstanceLabelPrivileged => 'Privileged mode';

  @override
  String get appsInstanceLabelDevices => 'Devices';

  @override
  String get appsInstanceServerDefault => 'Server default';

  @override
  String get appsInstanceDevicesEmpty => 'No devices attached.';

  @override
  String get appsInstanceDeviceManaged => 'Managed by TrueNAS';

  @override
  String appsInstanceEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get appsInstanceCreateTitle => 'New instance';

  @override
  String get appsInstanceNameLabel => 'Name';

  @override
  String get appsInstanceNameHelper =>
      'Letters, digits, and hyphens. Used as the guest hostname.';

  @override
  String get appsInstanceImageLabel => 'Base image';

  @override
  String get appsInstanceImagePickerHint => 'Show base image options';

  @override
  String get appsInstanceCpuHelper =>
      'Core count, or a pinned set such as 0-3. Leave empty for the server default.';

  @override
  String get appsInstanceMemoryLabel => 'Memory (MiB)';

  @override
  String get appsInstanceRootDiskLabel => 'Root disk (GiB)';

  @override
  String get appsInstanceAutostart => 'Start automatically';

  @override
  String appsInstanceCreated(String name) {
    return 'Creating $name.';
  }

  @override
  String appsInstanceUpdated(String name) {
    return 'Updating $name.';
  }

  @override
  String get appsInstanceNoChanges => 'Nothing changed, so nothing was sent.';

  @override
  String appsInstanceDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get appsInstanceDeleteAction => 'Delete instance';

  @override
  String get appsInstanceDeleteConsequenceDisk =>
      'The instance root disk is destroyed with it. Data written inside the guest is lost.';

  @override
  String get appsInstanceDeleteConsequenceRunning =>
      'The instance is running and will be stopped first.';

  @override
  String appsInstanceDeleteRequested(String name) {
    return 'Deleting $name.';
  }

  @override
  String get appsInstanceValidationNameRequired => 'Enter a name.';

  @override
  String get appsInstanceValidationNameInvalid =>
      'Use letters, digits, and hyphens only, starting with a letter.';

  @override
  String get appsInstanceValidationImageRequired => 'Choose a base image.';

  @override
  String get appsInstanceValidationCpu =>
      'Enter a core count or a pinned set such as 0-3.';

  @override
  String appsInstanceValidationMemory(int bound) {
    return 'Memory must be at least $bound MiB.';
  }

  @override
  String appsInstanceValidationRootDisk(int bound) {
    return 'Root disk must be between 1 and $bound GiB.';
  }

  @override
  String get appsInstanceValidationEnvironment =>
      'Environment names must start with a letter or underscore and contain only letters, digits, and underscores.';

  @override
  String get appsOperationFailed => 'The TrueNAS operation failed.';

  @override
  String appsJobSuffix(String jobId) {
    return ' · Job $jobId';
  }

  @override
  String get appsSummaryInstalled => 'Installed';

  @override
  String get appsSummaryRunning => 'Running';

  @override
  String get appsSummaryUpdates => 'Updates';

  @override
  String appsStopAppTitle(String name) {
    return 'Stop $name?';
  }

  @override
  String get appsStopAppBody =>
      'Users and dependent services may lose access until the app is started again.';

  @override
  String get appsStopApp => 'Stop app';

  @override
  String get appsStartApp => 'Start app';

  @override
  String appsStopServiceTitle(String name) {
    return 'Stop $name?';
  }

  @override
  String get appsStopServiceBody =>
      'Active clients using this service may be disconnected.';

  @override
  String get appsStopService => 'Stop service';

  @override
  String appsStartRequested(String target) {
    return 'Start requested for $target.';
  }

  @override
  String appsStopRequested(String target) {
    return 'Stop requested for $target.';
  }

  @override
  String appsUpgradeRequested(String target) {
    return 'Upgrade requested for $target.';
  }

  @override
  String appsRedeployRequested(String target) {
    return 'Redeploy requested for $target.';
  }

  @override
  String appsReconfigureRequested(String target) {
    return 'Reconfiguration requested for $target.';
  }

  @override
  String appsRollbackRequested(String target) {
    return 'Rollback requested for $target.';
  }

  @override
  String appsRemovalRequested(String target) {
    return 'Removal requested for $target.';
  }

  @override
  String appsInstallRequested(String target) {
    return 'Installation requested for $target.';
  }

  @override
  String get appsStartOnBoot => 'Start on boot';

  @override
  String get appsDoNotStartOnBoot => 'Do not start on boot';

  @override
  String appsStartOnBootTitle(String name) {
    return 'Start $name on boot?';
  }

  @override
  String appsStopStartOnBootTitle(String name) {
    return 'Stop starting $name on boot?';
  }

  @override
  String appsStartOnBootConsequence(String name, String server) {
    return '$name will start automatically after every reboot of $server.';
  }

  @override
  String appsStopOnBootConsequence(String name, String server) {
    return '$name will stay stopped after the next reboot of $server until someone starts it manually.';
  }

  @override
  String get appsBootChangeRunningNote =>
      'The service keeps running now. This changes only what happens at boot.';

  @override
  String get appsBootChangeStoppedNote =>
      'The service stays stopped now. This changes only what happens at boot.';

  @override
  String appsStartOnBootSaved(String name) {
    return '$name will start on boot.';
  }

  @override
  String appsStopOnBootSaved(String name) {
    return '$name will no longer start on boot.';
  }

  @override
  String get appsServiceStartsAutomatically => 'Starts automatically';

  @override
  String get appsServiceManualStart => 'Manual start';

  @override
  String get appsServiceOptions => 'Service options';

  @override
  String get appsMoreActions => 'More app actions';

  @override
  String get appsRedeploy => 'Redeploy';

  @override
  String get appsReconfigure => 'Reconfigure';

  @override
  String get appsRollbackMenu => 'Roll back to previous version';

  @override
  String get appsReviewUpgrade => 'Review app upgrade';

  @override
  String get appsUpgradeUnsupported =>
      'Upgrade is not supported by this server';

  @override
  String appsRedeployTitle(String name) {
    return 'Redeploy $name?';
  }

  @override
  String get appsRedeployAction => 'Redeploy app';

  @override
  String get appsRedeployConsequenceRebuild =>
      'The app is stopped, its containers are recreated, and it starts again. Users lose access until the TrueNAS job completes.';

  @override
  String get appsRedeployConsequenceData =>
      'Existing configuration and stored data are kept; only the running instance is rebuilt.';

  @override
  String appsConfigLoadFailed(String name) {
    return 'Could not load the configuration for $name.';
  }

  @override
  String appsNotReconfigurable(String name) {
    return '$name is a custom app or does not expose editable configuration through the catalog. Reinstall it from the catalog to change its settings.';
  }

  @override
  String get appsReconfigureDescription => 'Reconfigure the installed app.';

  @override
  String get appsSchemaLoadFailed =>
      'Could not load the app configuration schema.';

  @override
  String get appsInstallSchemaLoadFailed =>
      'Could not load the app installation schema.';

  @override
  String appsRollbackTitle(String name) {
    return 'Roll back $name?';
  }

  @override
  String get appsRollbackAction => 'Roll back app';

  @override
  String get appsRollbackConsequenceRebuild =>
      'The app is rebuilt from the selected image version and restarted. Changes that depend on the current version may not apply.';

  @override
  String get appsRollbackConsequenceData =>
      'Stored data and configuration are preserved, but the running version moves back to the prior release.';

  @override
  String appsRollbackSheetTitle(String name) {
    return 'Roll back $name';
  }

  @override
  String appsRollbackSheetNotice(String server) {
    return 'The app on $server is rebuilt from the selected image and restarted. Stored data and configuration are kept; only the running version moves back.';
  }

  @override
  String appsRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get appsRemoveAction => 'Remove app';

  @override
  String appsRemoveConsequenceApp(String server) {
    return 'The app is permanently removed from $server. Reinstalling requires the catalog entry and your configuration.';
  }

  @override
  String get appsRemoveConsequenceImages =>
      'Pulled container images are also deleted and must be downloaded again to reinstall.';

  @override
  String get appsRemoveConsequenceVolumesDeleted =>
      'Named volumes are removed with the app, destroying the data they hold.';

  @override
  String get appsRemoveConsequenceVolumesKept =>
      'Named volumes are kept so the data survives removal, but they must be reattached or removed manually later.';

  @override
  String appsRemovalSheetTitle(String name) {
    return 'Choose what to remove with $name';
  }

  @override
  String get appsRemovalSheetBody =>
      'The app itself is always removed. These options control whether images and stored volumes go with it.';

  @override
  String get appsRemoveImages => 'Remove pulled images';

  @override
  String get appsRemoveImagesSubtitle =>
      'Delete the container images downloaded for this app. They are fetched again on the next install.';

  @override
  String get appsKeepVolumes => 'Keep named volumes';

  @override
  String get appsKeepVolumesOn =>
      'Stored data survives removal and can be reattached later.';

  @override
  String get appsKeepVolumesOff =>
      'Named volumes are deleted with the app. Data is lost.';

  @override
  String get appsReviewRemoval => 'Review removal';

  @override
  String appsUpgradeSheetTitle(String name) {
    return 'Upgrade $name';
  }

  @override
  String appsVersionTransition(String from, String to) {
    return '$from → $to';
  }

  @override
  String get appsTargetVersion => 'Target version';

  @override
  String get appsSnapshotHostPaths => 'Snapshot host-path storage';

  @override
  String get appsSnapshotHostPathsSubtitle =>
      'Create ZFS snapshots of eligible host-path volumes before upgrading.';

  @override
  String get appsUpgradeNotice =>
      'The app may be stopped and redeployed. Users can lose access until the TrueNAS job completes.';

  @override
  String get appsReleaseNotes => 'Release notes';

  @override
  String get appsNoReleaseNotes =>
      'No release notes were provided for this version.';

  @override
  String get appsUpgradeAction => 'Upgrade app';

  @override
  String get appsCatalogUnsupported =>
      'The configured catalog is not exposed by this TrueNAS version.';

  @override
  String get appsCatalogEmpty =>
      'No catalog apps are available. The catalog may still be synchronizing.';

  @override
  String appsBrowseAll(int count) {
    return 'Browse all $count apps';
  }

  @override
  String get appsDockerService => 'Docker service';

  @override
  String get appsStatusUnknown => 'UNKNOWN';

  @override
  String get appsDockerConfigurationAvailable =>
      'Docker configuration available';

  @override
  String get appsNoAppsPool => 'No apps pool configured';

  @override
  String get appsImageUpdatesEnabled => 'image updates enabled';

  @override
  String get appsManualImageUpdates => 'manual image updates';

  @override
  String get appsVersionUnavailable => 'Version unavailable';

  @override
  String get appsImageUnavailable => 'Image unavailable';

  @override
  String appsCatalogTileSubtitle(
    String train,
    String version,
    String description,
  ) {
    return '$train · $version\n$description';
  }

  @override
  String get appsDiscoverApps => 'Discover apps';

  @override
  String get appsSearchHint => 'Search name, category, or tag';

  @override
  String get appsClearSearch => 'Clear search';

  @override
  String get appsAllTrains => 'All trains';

  @override
  String appsAppCount(int count) {
    return '$count apps';
  }

  @override
  String get appsNoSearchResults => 'No apps match this search.';

  @override
  String get appsLabelTrain => 'Train';

  @override
  String get appsLabelVersion => 'Version';

  @override
  String get appsUnavailable => 'Unavailable';

  @override
  String get appsLabelHealth => 'Health';

  @override
  String get appsCatalogHealthy => 'Catalog entry healthy';

  @override
  String get appsNeedsAttention => 'Needs attention';

  @override
  String get appsLabelCategories => 'Categories';

  @override
  String get appsLabelTags => 'Tags';

  @override
  String get appsConfigureInstall => 'Configure install';

  @override
  String get appsAppUnavailable => 'App unavailable';

  @override
  String get appsInstallUnsupported => 'Install unsupported';

  @override
  String get appsVerbStart => 'Start';

  @override
  String get appsVerbStop => 'Stop';

  @override
  String get appsVerbRestart => 'Restart';

  @override
  String get appsVerbPowerOff => 'Force power off';

  @override
  String appsVerbConfirmTitle(String verb, String name) {
    return '$verb $name?';
  }

  @override
  String appsVerbRequested(String verb, String name) {
    return '$verb requested for $name.';
  }

  @override
  String appsControlFailed(String verb, String name) {
    return 'TrueNAS could not $verb $name.';
  }

  @override
  String get appsKindVirtualMachine => 'virtual machine';

  @override
  String get appsKindContainer => 'container';

  @override
  String appsNoLifecycleControl(String kind) {
    return 'This TrueNAS version does not expose lifecycle control for this $kind.';
  }

  @override
  String appsStopConsequence(String kind) {
    return 'TrueNAS will ask the $kind to shut down. Workloads running inside it stop and any unsaved state depends on the guest.';
  }

  @override
  String appsRestartConsequence(String kind) {
    return 'The $kind shuts down and starts again. Anything it serves is unavailable until it finishes booting.';
  }

  @override
  String appsPowerOffConsequence(String kind) {
    return 'Power is cut immediately without a clean shutdown. Unwritten data inside the $kind can be lost, like pulling the plug on a machine.';
  }

  @override
  String get appsLabelState => 'State';

  @override
  String get appsLabelCpu => 'CPU';

  @override
  String appsCpuSummary(int sockets, int cores, int threads) {
    return '$sockets sockets · $cores cores · $threads threads';
  }

  @override
  String get appsLabelMemory => 'Memory';

  @override
  String appsMemoryMiB(int value) {
    return '$value MiB';
  }

  @override
  String get appsLabelAutostart => 'Autostart';

  @override
  String get appsEnabled => 'Enabled';

  @override
  String get appsDisabled => 'Disabled';

  @override
  String get appsLabelDisplay => 'Display';

  @override
  String get appsDisplayAvailable => 'Available';

  @override
  String get appsDisplayNotConfigured => 'Not configured';

  @override
  String appsVmSubtitle(String state, int vcpu, int memory) {
    return '$state · $vcpu vCPU · $memory MiB';
  }

  @override
  String get appsEdit => 'Edit';

  @override
  String get appsStateRunning => 'Running';

  @override
  String get appsStateStopped => 'Stopped';

  @override
  String get appsStateDeploying => 'Deploying';

  @override
  String get appsStateStarting => 'Starting';

  @override
  String get appsStateStopping => 'Stopping';

  @override
  String get appsStateCrashed => 'Crashed';

  @override
  String get appsStateHealthy => 'Healthy';

  @override
  String get appsStateUnhealthy => 'Unhealthy';

  @override
  String get appsStateUnknown => 'Unknown';

  @override
  String get appsDetailsLiveResources => 'Live resources';

  @override
  String get appsDetailsCpu => 'CPU';

  @override
  String get appsDetailsMemory => 'Memory';

  @override
  String appsDetailsStatsFailed(String detail) {
    return 'Could not load live resource information.\n$detail';
  }

  @override
  String get appsDetailsDiskRead => 'Disk read';

  @override
  String get appsDetailsDiskWrite => 'Disk write';

  @override
  String appsDetailsNetworkRate(String received, String sent) {
    return 'Received $received · Sent $sent';
  }

  @override
  String get appsDetailsWorkloads => 'Workloads';

  @override
  String appsDetailsContainerCount(int count) {
    return '$count containers';
  }

  @override
  String get appsDetailsNoContainerInfo => 'No container details';

  @override
  String get appsDetailsImages => 'Images';

  @override
  String get appsDetailsPorts => 'Ports';

  @override
  String get appsDetailsStorage => 'Storage';

  @override
  String get appsDetailsNetworks => 'Networks';

  @override
  String get appsCustomComposeDescription =>
      'Edit the custom app Docker Compose configuration as JSON. Applying it can recreate the app containers.';

  @override
  String get appsCustomComposeLabel => 'Docker Compose configuration';

  @override
  String get appsCustomComposeReview => 'Review changes';

  @override
  String get appsCustomComposeInvalid => 'Enter a valid JSON object.';

  @override
  String appsCustomComposeConfirmTitle(String name) {
    return 'Change the configuration for $name?';
  }

  @override
  String get appsCustomComposeApply => 'Apply changes';

  @override
  String get appsCustomComposeRecreateWarning =>
      'TrueNAS can recreate the app containers with the changed configuration.';

  @override
  String get appsCustomComposeDowntimeWarning =>
      'The app can be briefly unavailable until the job completes.';

  @override
  String get appsDeviceTypeDisk => 'Disk';

  @override
  String get appsDeviceTypeNetwork => 'Network';

  @override
  String get appsDeviceTypeDisplay => 'Display';

  @override
  String get appsDeviceTypeUsb => 'USB';

  @override
  String get appsDeviceTypePci => 'PCI device';

  @override
  String get appsDeviceTypeTpm => 'TPM';

  @override
  String get appsDeviceTypeCdrom => 'CD-ROM';

  @override
  String get appsDevices => 'Devices';

  @override
  String get appsNoChanges => 'No changes to save.';

  @override
  String appsSaveChangesTitle(String name) {
    return 'Save changes to $name?';
  }

  @override
  String get appsVmRuntimeChangeRunning =>
      'CPU and memory changes apply on the next restart.';

  @override
  String get appsVmRuntimeChangeStopped =>
      'CPU and memory changes apply on next start.';

  @override
  String get appsConfigUpdatedOnServer =>
      'Configuration is updated on the server.';

  @override
  String appsUpdateFailed(String name) {
    return 'TrueNAS could not update $name.';
  }

  @override
  String appsVmUpdated(String name) {
    return '$name updated. Restart it to apply runtime changes.';
  }

  @override
  String get appsVmDevicesLoadFailed =>
      'Could not load the VM devices from the server.';

  @override
  String appsAddDeviceTitle(String device, String vm) {
    return 'Add $device to $vm?';
  }

  @override
  String get appsAddDevice => 'Add device';

  @override
  String appsAddDeviceConsequence(String vm) {
    return 'The device is attached to $vm. Disk devices require a restart to be visible inside the guest.';
  }

  @override
  String get appsAddDeviceFailed => 'TrueNAS could not add the device.';

  @override
  String appsDeviceAdded(String vm) {
    return 'Device added to $vm.';
  }

  @override
  String appsSaveDeviceTitle(String device, String vm) {
    return 'Save $device on $vm?';
  }

  @override
  String get appsSaveDevice => 'Save device';

  @override
  String appsEditDeviceConsequence(String vm) {
    return 'TrueNAS replaces this device’s configuration on $vm. Changes apply the next time the VM starts.';
  }

  @override
  String get appsEditDeviceDiskWarning =>
      'Repointing a disk changes which storage the guest boots from. The underlying zvol or image is not modified.';

  @override
  String get appsUpdateDeviceFailed => 'TrueNAS could not update the device.';

  @override
  String appsDeviceUpdated(String vm) {
    return 'Device updated on $vm.';
  }

  @override
  String appsRemoveDeviceTitle(String device, String vm) {
    return 'Remove $device from $vm?';
  }

  @override
  String get appsRemoveDevice => 'Remove device';

  @override
  String get appsRemoveDeviceConsequence =>
      'The device is detached from the VM. Disk removal does not delete the underlying zvol or image.';

  @override
  String get appsRemoveDeviceFailed => 'TrueNAS could not remove the device.';

  @override
  String appsDeviceRemoved(String vm) {
    return 'Device removed from $vm.';
  }

  @override
  String appsDeviceTarget(String vm, String device) {
    return '$vm · $device';
  }

  @override
  String appsContainerSubtitle(String state, String dataset, int count) {
    return '$state · $dataset · $count devices';
  }

  @override
  String get appsLabelDataset => 'Dataset';

  @override
  String get appsLabelUuid => 'UUID';

  @override
  String get appsLabelDevices => 'Devices';

  @override
  String get appsLabelNetwork => 'Network';

  @override
  String get appsNetworkByDevices => 'Configured by devices';

  @override
  String get appsContainerConfigLoadFailed =>
      'Could not load the container configuration.';

  @override
  String get appsContainerUpdateConsequence =>
      'TrueNAS replaces the whole container configuration, including the device list. Volumes and environment are sent unchanged from the current container.';

  @override
  String appsContainerRestartToApply(String name) {
    return '$name is running; restart it to apply.';
  }

  @override
  String get appsContainerStartToApply => 'Start the container to apply.';

  @override
  String appsContainerUpdated(String name) {
    return '$name updated. Restart it to apply.';
  }

  @override
  String get protectionTitle => 'Protection';

  @override
  String get protectionLoadFailed =>
      'Could not load data protection information.';

  @override
  String get overviewActivityLoadFailed => 'Could not load recent activity.';

  @override
  String get protectionLandingDescription =>
      'See every scheduled copy, snapshot, scrub, and backup task.';

  @override
  String get protectionRefreshTooltip => 'Refresh protection tasks';

  @override
  String get protectionReplication => 'Replication';

  @override
  String get protectionReplicationSubtitle =>
      'Local and remote ZFS replication';

  @override
  String get protectionSnapshotTasks => 'Snapshot tasks';

  @override
  String get protectionSnapshotTasksSubtitle => 'Schedules and retention';

  @override
  String get protectionCloudSync => 'Cloud sync';

  @override
  String get protectionCloudSyncSubtitle => 'Providers, transfers, results';

  @override
  String get protectionScrubs => 'Scrubs';

  @override
  String get protectionScrubsSubtitle => 'Pool integrity schedules';

  @override
  String get protectionRsync => 'Rsync';

  @override
  String get protectionRsyncSubtitle => 'Module and SSH tasks';

  @override
  String get protectionRecentSnapshots => 'Recent snapshots';

  @override
  String get protectionScrubSchedules => 'Scrub schedules';

  @override
  String protectionSummary(int replications, int snapshots, int others) {
    return '$replications replication, $snapshots snapshot, and $others other tasks enabled';
  }

  @override
  String get protectionNewReplication => 'New replication task';

  @override
  String get protectionNewSnapshotTask => 'Create periodic snapshot task';

  @override
  String get protectionSnapshotTaskCreateUnsupported =>
      'Snapshot task creation is not supported';

  @override
  String get protectionNewCloudSync => 'New cloud sync task';

  @override
  String get protectionCloudBackups => 'Cloud backups';

  @override
  String get protectionNewCloudBackup => 'New cloud backup task';

  @override
  String get protectionNoCloudBackups => 'No cloud backup tasks.';

  @override
  String get protectionCloudBackupNeedsCredential =>
      'Add a cloud credential in the TrueNAS web interface before creating a backup task.';

  @override
  String protectionCloudBackupSubtitle(String schedule, int keepLast) {
    return '$schedule · keeps $keepLast snapshots';
  }

  @override
  String get protectionCloudBackupSheetCreate => 'New cloud backup';

  @override
  String get protectionCloudBackupSheetEdit => 'Edit cloud backup';

  @override
  String get protectionCloudBackupPath => 'Dataset path';

  @override
  String get protectionCloudBackupCredential => 'Cloud credential';

  @override
  String get protectionCloudBackupBucket => 'Bucket';

  @override
  String get protectionCloudBackupFolder => 'Folder';

  @override
  String get protectionCloudBackupPassword => 'Repository password';

  @override
  String get protectionCloudBackupPasswordHelperNew =>
      'Required. Losing this password makes the backup unrecoverable; TrueDock never reads it back from the server.';

  @override
  String get protectionCloudBackupPasswordHelperEdit =>
      'Leave empty to keep the stored password.';

  @override
  String get protectionCloudBackupKeepLast => 'Snapshots to keep';

  @override
  String get protectionCloudBackupSnapshotFirst => 'Snapshot the dataset first';

  @override
  String get protectionCloudBackupSnapshotHelp =>
      'Backs up a point-in-time snapshot instead of files that may change mid-transfer.';

  @override
  String get protectionCloudBackupTransfer => 'Transfer profile';

  @override
  String get protectionCloudBackupTransferDefault => 'Default';

  @override
  String get protectionCloudBackupTransferPerformance => 'Performance';

  @override
  String get protectionCloudBackupTransferFast => 'Fast storage';

  @override
  String get protectionCloudBackupEnabled => 'Enabled';

  @override
  String get protectionCloudBackupCreated => 'Cloud backup task created.';

  @override
  String get protectionCloudBackupUpdated => 'Cloud backup task updated.';

  @override
  String get protectionCloudBackupDeleted => 'Cloud backup task deleted.';

  @override
  String protectionCloudBackupRunning(String path) {
    return 'Backing up $path.';
  }

  @override
  String get protectionCloudBackupDryRun => 'Dry run';

  @override
  String protectionCloudBackupDryRunStarted(String path) {
    return 'Simulating the backup of $path.';
  }

  @override
  String protectionCloudBackupRunTitle(String path) {
    return 'Back up $path now?';
  }

  @override
  String get protectionCloudBackupRunAction => 'Start backup';

  @override
  String get protectionCloudBackupRunConsequence =>
      'The transfer runs now and counts against the provider\'s bandwidth and request charges.';

  @override
  String get protectionCloudBackupDeleteTitle => 'Delete this backup task?';

  @override
  String get protectionCloudBackupDeleteAction => 'Delete task';

  @override
  String get protectionCloudBackupDeleteConsequence =>
      'The schedule is removed. Snapshots already in the cloud repository are left in place.';

  @override
  String get protectionCloudBackupSnapshots => 'Repository snapshots';

  @override
  String get protectionCloudBackupSnapshotsEmpty =>
      'No snapshots in this repository yet.';

  @override
  String get protectionCloudBackupAbort => 'Abort running backup';

  @override
  String get protectionCloudBackupAborted => 'Abort requested.';

  @override
  String protectionCloudBackupAbortTitle(String path) {
    return 'Abort the backup of $path?';
  }

  @override
  String get protectionCloudBackupAbortAction => 'Abort backup';

  @override
  String get protectionCloudBackupAbortConsequence =>
      'The transfer stops partway. Data already uploaded is kept, but this run produces no usable snapshot.';

  @override
  String get protectionCloudBackupAbortConsequenceRestart =>
      'Backing up again starts a fresh transfer and counts against the provider\'s bandwidth and request charges.';

  @override
  String get protectionCloudBackupValidationPath =>
      'Enter the dataset path to back up.';

  @override
  String get protectionCloudBackupValidationPathAbsolute =>
      'Use an absolute path, starting with /mnt.';

  @override
  String get protectionCloudBackupValidationCredential =>
      'Choose a cloud credential.';

  @override
  String get protectionCloudBackupValidationPassword =>
      'Enter a repository password.';

  @override
  String protectionCloudBackupValidationKeepLast(int bound) {
    return 'Keep at least $bound snapshot.';
  }

  @override
  String get protectionNewRsync => 'New rsync task';

  @override
  String get protectionEditTask => 'Edit task';

  @override
  String get protectionDeleteTask => 'Delete task';

  @override
  String get protectionRunNow => 'Run now';

  @override
  String get protectionTaskAlreadyRunning => 'Task already running';

  @override
  String get protectionActionUnsupported =>
      'This action is not supported by the server';

  @override
  String get protectionSnapshotTaskActions => 'Snapshot task actions';

  @override
  String get protectionNoReplicationTasks => 'No replication tasks found.';

  @override
  String get protectionNoSnapshotTasks => 'No periodic snapshot tasks found.';

  @override
  String get protectionNoSnapshots => 'No snapshots found.';

  @override
  String get protectionNoScrubSchedules => 'No scrub schedules found.';

  @override
  String get protectionNoCloudSyncTasks => 'No cloud sync tasks found.';

  @override
  String get protectionNoRsyncTasks => 'No rsync tasks found.';

  @override
  String protectionRunTaskTitle(String name) {
    return 'Run $name?';
  }

  @override
  String protectionRunReplicationMessage(String direction) {
    return 'TrueNAS will transfer snapshots to the configured $direction destination. This can use storage, CPU, and network bandwidth.';
  }

  @override
  String get protectionRunReplication => 'Run replication';

  @override
  String protectionStartScrubTitle(String pool) {
    return 'Start scrub on $pool?';
  }

  @override
  String get protectionStartScrubMessage =>
      'A scrub verifies pool data and can increase disk activity until it completes.';

  @override
  String get protectionStartScrub => 'Start scrub';

  @override
  String get protectionRunRsyncTitle => 'Run Rsync task?';

  @override
  String protectionRunRsyncMessage(
    String direction,
    String path,
    String remote,
  ) {
    return 'TrueNAS will $direction data between $path and $remote. Existing destination files can be changed according to the task configuration.';
  }

  @override
  String get protectionRunRsync => 'Run Rsync';

  @override
  String protectionRunCloudSyncMessage(
    String direction,
    String path,
    String provider,
    String mode,
  ) {
    return 'TrueNAS will $direction $path using $provider. Remote or local files can change according to $mode rules.';
  }

  @override
  String get protectionDryRun => 'Dry run';

  @override
  String get protectionDryRunSubtitle =>
      'Preview changes without transferring data.';

  @override
  String get protectionRunPreview => 'Run preview';

  @override
  String get protectionRunCloudSync => 'Run cloud sync';

  @override
  String get protectionSnapshotTaskCreateFailed =>
      'The periodic snapshot task could not be created.';

  @override
  String protectionSnapshotTaskCreated(String dataset) {
    return 'Periodic snapshot task created for $dataset.';
  }

  @override
  String get protectionSnapshotTaskUpdateFailed =>
      'The periodic snapshot task could not be updated.';

  @override
  String protectionSnapshotTaskUpdated(String dataset) {
    return 'Periodic snapshot task updated for $dataset.';
  }

  @override
  String get protectionSnapshotTaskUpdateLabel => 'Snapshot task update';

  @override
  String protectionUpdateTaskTitle(String dataset) {
    return 'Update $dataset?';
  }

  @override
  String get protectionUpdateTaskBody =>
      'TrueNAS will apply the new snapshot schedule and retention policy.';

  @override
  String protectionRetentionChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count existing snapshot retention assignments will change:',
      one: '1 existing snapshot retention assignment will change:',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionConsequence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count snapshots that already exist get new retention deadlines and may be pruned. Pruned snapshots cannot be recovered.',
      one:
          '1 snapshot that already exists gets a new retention deadline and may be pruned. Pruned snapshots cannot be recovered.',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionEntry(String name, String count) {
    return '• $name: $count';
  }

  @override
  String get protectionNoRetentionChanges =>
      'The server reports no existing snapshot retention changes.';

  @override
  String get protectionApplyChanges => 'Apply changes';

  @override
  String get protectionRunSnapshotTaskTitle => 'Run snapshot task now?';

  @override
  String protectionRunSnapshotTaskMessage(
    String scope,
    String dataset,
    String schema,
  ) {
    return 'TrueNAS will create $scope snapshots for $dataset immediately using $schema.';
  }

  @override
  String get protectionScopeRecursive => 'recursive';

  @override
  String get protectionRunSnapshotTask => 'Run snapshot task';

  @override
  String get protectionDeleteSnapshotTaskTitle => 'Delete snapshot task?';

  @override
  String get protectionDeleteSnapshotTaskConsequence =>
      'The schedule is removed. Snapshots already created by this task are kept and expire on their own retention.';

  @override
  String protectionSnapshotHeld(String name) {
    return '$name is now protected from deletion.';
  }

  @override
  String protectionSnapshotReleased(String name) {
    return 'Released the hold on $name.';
  }

  @override
  String protectionSnapshotHoldAction(String name) {
    return 'hold $name';
  }

  @override
  String protectionSnapshotReleaseAction(String name) {
    return 'release $name';
  }

  @override
  String protectionSnapshotCloneAction(String name) {
    return 'clone $name';
  }

  @override
  String protectionSnapshotCloned(String destination) {
    return 'Cloned to $destination.';
  }

  @override
  String protectionSnapshotDeleteAction(String name) {
    return 'delete $name';
  }

  @override
  String protectionSnapshotDeleted(String name) {
    return 'Deleted $name.';
  }

  @override
  String protectionSnapshotRollbackAction(String dataset) {
    return 'roll back $dataset';
  }

  @override
  String protectionSnapshotRolledBack(String dataset, String name) {
    return 'Rolled $dataset back to $name.';
  }

  @override
  String protectionSnapshotActionFailed(String action) {
    return 'TrueNAS could not $action.';
  }

  @override
  String protectionSnapshotTarget(String dataset, String name) {
    return '$dataset@$name';
  }

  @override
  String get protectionDeleteSnapshotTitle => 'Delete snapshot?';

  @override
  String get protectionDeleteSnapshotAction => 'Delete snapshot';

  @override
  String get protectionDeleteSnapshotConsequenceRestore =>
      'This restore point is destroyed and cannot be recovered.';

  @override
  String get protectionDeleteSnapshotConsequenceReplication =>
      'Replication that depends on it may need a full resend.';

  @override
  String get protectionDeleteSnapshotNote =>
      'Live data in the dataset is not affected.';

  @override
  String get protectionRollbackTitle => 'Roll back to this snapshot?';

  @override
  String get protectionRollbackAction => 'Roll back';

  @override
  String protectionRollbackConsequenceChanges(String dataset) {
    return 'Every change written to $dataset after this snapshot is permanently lost.';
  }

  @override
  String protectionRollbackConsequenceNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count newer snapshots are destroyed.',
      one: '1 newer snapshot is destroyed.',
    );
    return '$_temp0';
  }

  @override
  String get protectionRollbackConsequenceClones =>
      'Datasets cloned from those snapshots are destroyed too.';

  @override
  String get protectionRollbackConsequenceForce =>
      'The dataset is unmounted even if applications are using it.';

  @override
  String get protectionRollbackNote =>
      'Stop applications writing to this dataset before continuing.';

  @override
  String get protectionCloudSyncConfigLoadFailed =>
      'Could not load the cloud sync task configuration.';

  @override
  String get protectionReplicationConfigLoadFailed =>
      'Could not load the replication task configuration.';

  @override
  String get protectionRsyncConfigLoadFailed =>
      'Could not load the rsync task configuration.';

  @override
  String get protectionCreateTask => 'Create task';

  @override
  String get protectionSaveTask => 'Save task';

  @override
  String protectionCreateCloudSyncTitle(String name) {
    return 'Create cloud sync $name?';
  }

  @override
  String protectionSaveCloudSyncTitle(String name) {
    return 'Save cloud sync $name?';
  }

  @override
  String protectionCloudSyncPushConsequence(
    String path,
    String remote,
    String provider,
  ) {
    return 'Transfers $path to $remote on $provider.';
  }

  @override
  String protectionCloudSyncPullConsequence(String remote, String path) {
    return 'Transfers $remote into $path on this server.';
  }

  @override
  String get protectionSelectedProvider => 'the selected provider';

  @override
  String protectionCloudSyncSyncPush(String remote, String path) {
    return 'Sync deletes files at $remote that no longer exist in $path.';
  }

  @override
  String protectionCloudSyncSyncPull(String path, String remote) {
    return 'Sync deletes files in $path that no longer exist at $remote.';
  }

  @override
  String protectionCloudSyncMovePush(String path) {
    return 'Move deletes the files from $path on this server after a successful upload.';
  }

  @override
  String protectionCloudSyncMovePull(String remote) {
    return 'Move deletes the files from $remote after a successful download.';
  }

  @override
  String get protectionCloudSyncCopyNote =>
      'Copy never deletes anything on either side.';

  @override
  String get protectionCloudSyncEncryptionNote =>
      'Files are encrypted before upload. Losing the encryption password makes the data unrecoverable; TrueDock does not store it.';

  @override
  String protectionCreateReplicationTitle(String name) {
    return 'Create replication $name?';
  }

  @override
  String protectionSaveReplicationTitle(String name) {
    return 'Save replication $name?';
  }

  @override
  String protectionReplicationPushConsequence(int count, String target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Replicates $count source datasets into $target on the destination.',
      one: 'Replicates 1 source dataset into $target on the destination.',
    );
    return '$_temp0';
  }

  @override
  String protectionReplicationPullConsequence(String target) {
    return 'Pulls into $target on this server, overwriting conflicting local snapshots.';
  }

  @override
  String get protectionReplicationOverwriteNote =>
      'Snapshots on the target that conflict with the source are overwritten when the task runs.';

  @override
  String protectionReplicationRetentionNote(int value, String unit) {
    return 'Destination snapshots older than $value $unit are destroyed automatically.';
  }

  @override
  String get protectionReplicationLocalNote =>
      'This is a local task; both sides live on this server.';

  @override
  String protectionCreateRsyncTitle(String path) {
    return 'Create rsync task for $path?';
  }

  @override
  String protectionSaveRsyncTitle(String path) {
    return 'Save rsync task for $path?';
  }

  @override
  String protectionRsyncPushConsequence(String path, String remote) {
    return 'Copies $path to $remote and can overwrite files on the remote system.';
  }

  @override
  String protectionRsyncPullConsequence(String remote, String path) {
    return 'Copies $remote into $path and can overwrite local files on this server.';
  }

  @override
  String protectionRsyncRunAsNote(String user, String port) {
    return 'Runs as $user on port $port.';
  }

  @override
  String get protectionRsyncScheduleNote =>
      'The task runs on its schedule until you disable it.';

  @override
  String get protectionDeleteReplicationTitle => 'Delete replication task?';

  @override
  String get protectionDeleteReplicationConsequence =>
      'The task definition is removed. In-flight replications keep running to completion; abort the job first if it must stop now.';

  @override
  String get protectionDeleteReplicationKeepNote =>
      'Snapshots already replicated to the destination are kept.';

  @override
  String get protectionDeleteCloudSyncTitle => 'Delete cloud sync task?';

  @override
  String get protectionDeleteCloudSyncConsequence =>
      'The task definition is removed. Stored cloud credentials are kept and can be reused by other tasks.';

  @override
  String get protectionDeleteCloudSyncKeepNote =>
      'Files already transferred to or from the remote remain on both sides.';

  @override
  String get protectionDeleteRsyncTitle => 'Delete rsync task?';

  @override
  String get protectionDeleteRsyncConsequence =>
      'The task definition is removed. Files already transferred remain on both sides.';

  @override
  String get protectionTaskStartFailed =>
      'The TrueNAS task could not be started.';

  @override
  String protectionTaskStarted(String label) {
    return '$label started.';
  }

  @override
  String protectionJobSuffix(String jobId) {
    return ' · Job $jobId';
  }

  @override
  String get protectionStateIdle => 'Idle';

  @override
  String protectionReplicationSubtitleRow(String direction, String state) {
    return '$direction · $state';
  }

  @override
  String protectionSnapshotTaskSubtitle(String schedule, String retention) {
    return 'Cron $schedule · Keep $retention';
  }

  @override
  String get protectionRecursiveSuffix => ' · Recursive';

  @override
  String protectionScrubSubtitle(String schedule, int days) {
    return '$schedule · Threshold $days days';
  }

  @override
  String protectionCloudSyncSubtitleRow(
    String direction,
    String mode,
    String provider,
    String path,
  ) {
    return '$direction $mode · $provider\n$path';
  }

  @override
  String protectionRsyncSubtitleRow(
    String direction,
    String mode,
    String path,
    String remote,
  ) {
    return '$direction · $mode · $path\n$remote';
  }

  @override
  String protectionTransactionGroup(String txg) {
    return 'TXG $txg';
  }

  @override
  String get protectionLabelSchedule => 'Schedule';

  @override
  String get protectionLabelRetention => 'Retention';

  @override
  String protectionRetentionHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get protectionScheduleUnavailable => 'Schedule unavailable';

  @override
  String protectionScrubSchedule(String hour, String minute, String day) {
    return '$hour:$minute · day $day';
  }

  @override
  String get protectionLabelNaming => 'Naming';

  @override
  String get protectionLabelScope => 'Scope';

  @override
  String get protectionScopeRecursiveValue => 'Recursive';

  @override
  String get protectionScopeSelectedOnly => 'Selected dataset only';

  @override
  String get protectionLabelNoChanges => 'No changes';

  @override
  String get protectionCreateSnapshotAnyway => 'Create snapshot';

  @override
  String get protectionSkipSnapshot => 'Skip snapshot';

  @override
  String get protectionLabelState => 'State';

  @override
  String get protectionEnabled => 'Enabled';

  @override
  String get protectionDisabled => 'Disabled';

  @override
  String get protectionLabelExcludes => 'Excludes';

  @override
  String get snapshotReleaseHold => 'Release hold';

  @override
  String get snapshotHold => 'Hold snapshot';

  @override
  String get snapshotReleaseHoldSubtitle =>
      'Allows this snapshot to be deleted again.';

  @override
  String get snapshotHoldSubtitle =>
      'Blocks deletion until the hold is released.';

  @override
  String get snapshotCloneTitle => 'Clone to new dataset';

  @override
  String get snapshotCloneSubtitle =>
      'Creates a writable copy without changing data.';

  @override
  String get snapshotRollbackTitle => 'Roll back to this snapshot';

  @override
  String get snapshotRollbackSubtitleClean =>
      'Discards changes made after this snapshot.';

  @override
  String snapshotRollbackSubtitleNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Discards changes and $count newer snapshots.',
      one: 'Discards changes and 1 newer snapshot.',
    );
    return '$_temp0';
  }

  @override
  String get snapshotDeleteTitle => 'Delete snapshot';

  @override
  String get snapshotDeleteHeldSubtitle =>
      'Release the hold before deleting this snapshot.';

  @override
  String get snapshotDeleteSubtitle =>
      'Removes this restore point permanently.';

  @override
  String get snapshotNoActions =>
      'This TrueNAS version does not expose snapshot actions to TrueDock.';

  @override
  String get snapshotRollbackHeading => 'Roll back';

  @override
  String get snapshotRollbackModeNewestOnly =>
      'Only if this is the newest snapshot';

  @override
  String get snapshotRollbackModeNewer => 'Destroy newer snapshots';

  @override
  String get snapshotRollbackModeNewerAndClones =>
      'Destroy newer snapshots and their clones';

  @override
  String get snapshotRollbackModeNewestOnlyDescription =>
      'The rollback fails if any newer snapshot exists. Safest option.';

  @override
  String get snapshotRollbackModeNewerDescription =>
      'Every snapshot taken after this one is permanently destroyed.';

  @override
  String get snapshotRollbackModeNewerAndClonesDescription =>
      'Newer snapshots and any datasets cloned from them are destroyed.';

  @override
  String snapshotRollbackNewerWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count newer snapshots exist, so this option will fail until you choose to destroy them.',
      one:
          '1 newer snapshot exists, so this option will fail until you choose to destroy it.',
    );
    return '$_temp0';
  }

  @override
  String get snapshotForceUnmount => 'Force unmount if busy';

  @override
  String get snapshotForceUnmountSubtitle =>
      'Needed when applications still hold the dataset open.';

  @override
  String get snapshotCloneHeading => 'Clone snapshot';

  @override
  String get snapshotCloneDescription =>
      'The clone starts as a read-write dataset sharing storage with this snapshot. The snapshot cannot be deleted while the clone exists.';

  @override
  String get snapshotCloneDestinationLabel => 'New dataset path';

  @override
  String get snapshotCreateClone => 'Create clone';

  @override
  String get snapshotCloneValidationPath =>
      'Enter a full dataset path such as tank/restored.';

  @override
  String get snapshotCloneValidationSameDataset =>
      'Choose a path different from the source dataset.';

  @override
  String snapshotCloneSuffix(String dataset) {
    return '$dataset-clone';
  }

  @override
  String get snapshotTaskReviewTitle => 'Review snapshot task';

  @override
  String get snapshotTaskNewTitle => 'New snapshot task';

  @override
  String get snapshotTaskEditTitle => 'Edit snapshot task';

  @override
  String get snapshotTaskSubtitle => 'Automatic ZFS snapshots and retention';

  @override
  String get snapshotTaskNoDatasets =>
      'No unlocked filesystem datasets are available. Create or unlock a dataset first.';

  @override
  String get snapshotTaskDataset => 'Dataset';

  @override
  String get snapshotTaskIncludeChildren => 'Include child datasets';

  @override
  String get snapshotTaskIncludeChildrenSubtitle =>
      'Create snapshots recursively below this dataset.';

  @override
  String get snapshotTaskExcludes => 'Excluded child datasets';

  @override
  String get snapshotTaskExcludesHelper =>
      'Optional · one full dataset name per line';

  @override
  String get snapshotTaskRetention => 'Retention';

  @override
  String get snapshotTaskKeepFor => 'Keep for';

  @override
  String get snapshotTaskUnit => 'Unit';

  @override
  String get snapshotTaskNamingSchema => 'Naming schema';

  @override
  String get snapshotTaskNamingHelper =>
      'strftime pattern used for each snapshot name';

  @override
  String get snapshotTaskSchedule => 'Schedule';

  @override
  String get snapshotTaskWindowBegins => 'Window begins';

  @override
  String get snapshotTaskWindowEnds => 'Window ends';

  @override
  String get snapshotTaskAllowEmpty => 'Snapshot unchanged datasets';

  @override
  String get snapshotTaskAllowEmptySubtitle =>
      'Create a snapshot even when data has not changed.';

  @override
  String get snapshotTaskEnable => 'Enable immediately';

  @override
  String get snapshotTaskEnableCreateSubtitle =>
      'Run this schedule after the task is created.';

  @override
  String get snapshotTaskEnableEditSubtitle =>
      'Allow this schedule to continue running.';

  @override
  String get snapshotTaskCreate => 'Create task';

  @override
  String get snapshotTaskNone => 'None';

  @override
  String get snapshotTaskScope => 'Scope';

  @override
  String get snapshotTaskNaming => 'Naming';

  @override
  String get snapshotTaskState => 'State';

  @override
  String snapshotTaskRetentionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String snapshotTaskExcludedList(String datasets) {
    return 'Excluded datasets: $datasets';
  }

  @override
  String get snapshotTaskRetentionNotice =>
      'TrueNAS automatically removes snapshots created by this task after the configured retention period.';

  @override
  String get snapshotUnitHours => 'Hours';

  @override
  String get snapshotUnitDays => 'Days';

  @override
  String get snapshotUnitWeeks => 'Weeks';

  @override
  String get snapshotUnitMonths => 'Months';

  @override
  String get snapshotUnitYears => 'Years';

  @override
  String get snapshotPresetHourly => 'Hourly';

  @override
  String get snapshotPresetDaily => 'Daily';

  @override
  String get snapshotPresetWeekly => 'Weekly';

  @override
  String get snapshotPresetMonthly => 'Monthly';

  @override
  String get snapshotPresetCustom => 'Custom';

  @override
  String get snapshotScheduleEveryHour => 'At the start of every hour';

  @override
  String get snapshotScheduleEverySunday => 'Every Sunday at 00:00';

  @override
  String get snapshotScheduleFirstOfMonth => 'On day 1 of every month at 00:00';

  @override
  String get snapshotScheduleEveryDay => 'Every day at 00:00';

  @override
  String snapshotScheduleCron(String expression) {
    return 'Cron $expression';
  }

  @override
  String get snapshotCronMinute => 'Minute';

  @override
  String get snapshotCronHour => 'Hour';

  @override
  String get snapshotCronDayOfMonth => 'Day of month';

  @override
  String get snapshotCronMonth => 'Month';

  @override
  String get snapshotCronDayOfWeek => 'Day of week (1 Monday–7 Sunday)';

  @override
  String get snapshotValidationDataset => 'Choose a dataset.';

  @override
  String get snapshotValidationRetention => 'Retention must be at least 1.';

  @override
  String get snapshotValidationNamingRequired =>
      'Enter a snapshot naming schema.';

  @override
  String get snapshotValidationNamingSlash =>
      'Snapshot names cannot contain /.';

  @override
  String get snapshotValidationExclude =>
      'Each exclusion must be a child of the selected dataset.';

  @override
  String get snapshotValidationCron =>
      'Use a numeric cron expression such as *, 00, or */2.';

  @override
  String get snapshotValidationTime => 'Use 24-hour time in HH:mm format.';

  @override
  String get replicationReviewTitle => 'Review replication';

  @override
  String get replicationNewTitle => 'New replication';

  @override
  String get replicationEditTitle => 'Edit replication';

  @override
  String get replicationTaskName => 'Task name';

  @override
  String get replicationTransport => 'Transport';

  @override
  String get replicationTransportSsh => 'SSH';

  @override
  String get replicationTransportSshNetcat =>
      'SSH + netcat (faster, less secure)';

  @override
  String get replicationTransportLocal => 'Local (same system)';

  @override
  String get replicationSshLoadFailed =>
      'Could not load saved SSH connections. Check that the account has permission to read credentials.';

  @override
  String get replicationNoSshCredentials =>
      'No saved SSH connections. Create one in the TrueNAS web UI under Credentials, then reopen this editor. TrueDock does not create SSH keys.';

  @override
  String get replicationSshConnection => 'SSH connection';

  @override
  String get replicationDirection => 'Direction';

  @override
  String get replicationDirectionPush => 'Push (this server to target)';

  @override
  String get replicationDirectionPull => 'Pull (target to this server)';

  @override
  String get replicationSourceDatasets => 'Source datasets';

  @override
  String get replicationSourceDatasetsHelp =>
      'One task can replicate several datasets into one target.';

  @override
  String get replicationNoDatasets =>
      'No datasets were reported by this server.';

  @override
  String get replicationTargetDataset => 'Target dataset';

  @override
  String get replicationTargetHelper =>
      'Add /name at the end to create a new dataset.';

  @override
  String get replicationNamingSchema => 'Snapshot naming schema';

  @override
  String get replicationNamingHelper =>
      'Which source snapshots this task replicates.';

  @override
  String get replicationRetentionHeading => 'Retention on the destination';

  @override
  String get replicationRetentionSource => 'Same as source';

  @override
  String get replicationRetentionCustom => 'Custom retention';

  @override
  String get replicationRetentionNone => 'Keep forever';

  @override
  String get replicationRetentionSourceDescription =>
      'Destination snapshots follow the source task retention.';

  @override
  String get replicationRetentionCustomDescription =>
      'Destination snapshots are destroyed after the period you set.';

  @override
  String get replicationRetentionNoneDescription =>
      'Destination snapshots are never destroyed automatically.';

  @override
  String get replicationKeepFor => 'Keep for';

  @override
  String get replicationUnitHours => 'Hours';

  @override
  String get replicationUnitDays => 'Days';

  @override
  String get replicationUnitWeeks => 'Weeks';

  @override
  String get replicationUnitMonths => 'Months';

  @override
  String get replicationUnitYears => 'Years';

  @override
  String get replicationScheduleHeading => 'Schedule';

  @override
  String get replicationRunOnSchedule => 'Run on a schedule';

  @override
  String get replicationRunOnScheduleSubtitle =>
      'Turn off to run this task only manually.';

  @override
  String get replicationRecursive => 'Recursive';

  @override
  String get replicationRecursiveSubtitle =>
      'Include child datasets of each source.';

  @override
  String get replicationEnabled => 'Enabled';

  @override
  String get replicationEnabledSubtitle =>
      'Disabled tasks stay configured but never run.';

  @override
  String get replicationReviewName => 'Name';

  @override
  String get replicationReviewDirection => 'Direction';

  @override
  String get replicationReviewTransport => 'Transport';

  @override
  String get replicationReviewSsh => 'SSH';

  @override
  String get replicationNotSelected => 'Not selected';

  @override
  String get replicationReviewSources => 'Sources';

  @override
  String get replicationReviewNone => 'None';

  @override
  String get replicationReviewTarget => 'Target';

  @override
  String get replicationReviewSnapshots => 'Snapshots';

  @override
  String get replicationReviewRetention => 'Retention';

  @override
  String replicationRetentionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get replicationReviewSchedule => 'Schedule';

  @override
  String get replicationManualOnly => 'Manual only';

  @override
  String get replicationReviewRecursive => 'Recursive';

  @override
  String get replicationReviewEnabled => 'Enabled';

  @override
  String get replicationYes => 'Yes';

  @override
  String get replicationNo => 'No';

  @override
  String get replicationOverwriteWarning =>
      'Replication overwrites snapshots on the target dataset that conflict with the source. Verify the target path before saving, especially for a push task.';

  @override
  String get replicationCustomRetentionWarning =>
      'Custom retention destroys destination snapshots once they age past the period above.';

  @override
  String get replicationCronMinute => 'Minute';

  @override
  String get replicationCronHour => 'Hour';

  @override
  String get replicationCronDay => 'Day';

  @override
  String get replicationCronMonth => 'Month';

  @override
  String get replicationCronWeekday => 'Weekday';

  @override
  String get replicationValidationName => 'Enter a task name.';

  @override
  String get replicationValidationSources =>
      'Choose at least one source dataset.';

  @override
  String get replicationValidationTarget => 'Enter a target dataset path.';

  @override
  String get replicationValidationSsh =>
      'Choose the saved SSH connection for this transport.';

  @override
  String get replicationValidationNamingRequired =>
      'Enter a snapshot naming schema.';

  @override
  String get replicationValidationNamingSlash =>
      'Snapshot names cannot contain /.';

  @override
  String get replicationValidationRetention => 'Retention must be at least 1.';

  @override
  String get replicationValidationTargetSameAsSource =>
      'The target cannot be the same as a source dataset.';

  @override
  String get taskPresetHourly => 'Hourly';

  @override
  String get taskPresetDaily => 'Daily';

  @override
  String get taskPresetWeekly => 'Weekly';

  @override
  String get taskPresetMonthly => 'Monthly';

  @override
  String get taskPresetCustom => 'Custom';

  @override
  String get taskScheduleEveryHour => 'At the start of every hour';

  @override
  String get taskScheduleEverySunday => 'Every Sunday at 00:00';

  @override
  String get taskScheduleFirstOfMonth => 'On day 1 of every month at 00:00';

  @override
  String get taskScheduleEveryDay => 'Every day at 00:00';

  @override
  String taskScheduleCron(String expression) {
    return 'Cron $expression';
  }

  @override
  String get taskScheduleCronInvalid =>
      'Use a numeric cron expression such as *, 00, or */2.';

  @override
  String get rsyncReviewTitle => 'Review rsync task';

  @override
  String get rsyncNewTitle => 'New rsync task';

  @override
  String get rsyncEditTitle => 'Edit rsync task';

  @override
  String get rsyncLocalPath => 'Local path';

  @override
  String get rsyncLocalPathHelper =>
      'Absolute path on this server, e.g. /mnt/tank/media.';

  @override
  String get rsyncRunAsUser => 'Run as user';

  @override
  String get rsyncRunAsUserHelp =>
      'Must match the user of the SSH connection in SSH mode.';

  @override
  String get rsyncNoLocalUsers =>
      'No local users were reported by this server.';

  @override
  String get rsyncUser => 'User';

  @override
  String get rsyncDirection => 'Direction';

  @override
  String get rsyncDirectionPush => 'Push (this server to remote)';

  @override
  String get rsyncDirectionPull => 'Pull (remote to this server)';

  @override
  String get rsyncDirectionPushDescription =>
      'Sends the local path to the remote host or module.';

  @override
  String get rsyncDirectionPullDescription =>
      'Copies the remote path into the local path on this server.';

  @override
  String get rsyncRemote => 'Remote';

  @override
  String get rsyncMode => 'Mode';

  @override
  String get rsyncModeSsh => 'SSH';

  @override
  String get rsyncModeModule => 'rsync module';

  @override
  String get rsyncRemoteHost => 'Remote host';

  @override
  String get rsyncRemotePort => 'Remote port (optional)';

  @override
  String rsyncRemotePortHelper(int port) {
    return 'Leave blank for the default ($port).';
  }

  @override
  String get rsyncRemotePath => 'Remote path';

  @override
  String get rsyncRemoteModule => 'Remote module';

  @override
  String get rsyncRemoteModuleHelper =>
      'Module name defined by the remote rsync daemon.';

  @override
  String get rsyncDescription => 'Description (optional)';

  @override
  String get rsyncValidateRemotePath => 'Validate remote path';

  @override
  String get rsyncValidateRemotePathSubtitle =>
      'Ask the server to check the remote path before running.';

  @override
  String get rsyncReviewHost => 'Host';

  @override
  String get rsyncReviewPort => 'Port';

  @override
  String get rsyncReviewModule => 'Module';

  @override
  String get rsyncPushWarning =>
      'A push task writes into the remote destination and can overwrite files there.';

  @override
  String rsyncPullWarning(String path) {
    return 'A pull task writes into $path on this server and can overwrite local files.';
  }

  @override
  String get rsyncValidationPathRequired => 'Enter a local path.';

  @override
  String get rsyncValidationPathAbsolute =>
      'Use an absolute path starting with /.';

  @override
  String get rsyncValidationUser => 'Choose the local user to run as.';

  @override
  String get rsyncValidationRemoteHost => 'Enter the remote host.';

  @override
  String get rsyncValidationRemotePort => 'Use a port between 1 and 65535.';

  @override
  String get rsyncValidationRemotePath => 'Enter the remote path.';

  @override
  String get rsyncValidationSsh => 'Choose the saved SSH connection.';

  @override
  String get rsyncValidationRemoteModule =>
      'Enter the remote rsync module name.';

  @override
  String get cloudSyncReviewTitle => 'Review cloud sync';

  @override
  String get cloudSyncNewTitle => 'New cloud sync';

  @override
  String get cloudSyncEditTitle => 'Edit cloud sync';

  @override
  String get cloudSyncTaskName => 'Task name';

  @override
  String get cloudSyncCredentialHeading => 'Cloud credential';

  @override
  String get cloudSyncCredentialsLoadFailed =>
      'Could not load saved cloud credentials. Check that the account has permission to read credentials.';

  @override
  String get cloudSyncNoCredentials =>
      'No saved cloud credentials. Create one in the TrueNAS web UI under Credentials, then reopen this editor. TrueDock does not create cloud credentials.';

  @override
  String get cloudSyncCredential => 'Credential';

  @override
  String get cloudSyncDirection => 'Direction';

  @override
  String get cloudSyncDirectionPush => 'Push (this server to cloud)';

  @override
  String get cloudSyncDirectionPull => 'Pull (cloud to this server)';

  @override
  String get cloudSyncDirectionPushDescription =>
      'Sends the local path up to the cloud provider.';

  @override
  String get cloudSyncDirectionPullDescription =>
      'Downloads the remote location into the local path.';

  @override
  String get cloudSyncTransferMode => 'Transfer mode';

  @override
  String get cloudSyncModeSync => 'Sync';

  @override
  String get cloudSyncModeCopy => 'Copy';

  @override
  String get cloudSyncModeMove => 'Move';

  @override
  String get cloudSyncModeSyncDescription =>
      'Makes the destination match the source. Files missing from the source are deleted at the destination.';

  @override
  String get cloudSyncModeCopyDescription =>
      'Copies new and changed files. Nothing is ever deleted.';

  @override
  String get cloudSyncModeMoveDescription =>
      'Copies files, then deletes them from the source once the transfer succeeds.';

  @override
  String get cloudSyncLocalPath => 'Local path';

  @override
  String get cloudSyncLocalPathHelper => 'Absolute path, e.g. /mnt/tank/media.';

  @override
  String get cloudSyncRemoteLocation => 'Remote location';

  @override
  String get cloudSyncBucket => 'Bucket';

  @override
  String get cloudSyncFolder => 'Folder';

  @override
  String get cloudSyncFolderBucketHelper =>
      'Path inside the bucket. Leave blank for the root.';

  @override
  String get cloudSyncFolderDriveHelper =>
      'Path on the remote drive. Leave blank for the root.';

  @override
  String get cloudSyncStorageClass => 'Storage class (optional)';

  @override
  String get cloudSyncStorageClassHelper =>
      'S3 only, e.g. STANDARD or GLACIER.';

  @override
  String get cloudSyncAdvanced => 'Advanced';

  @override
  String get cloudSyncTransfers => 'Concurrent transfers (optional)';

  @override
  String get cloudSyncTransfersHelper => 'Leave blank for the server default.';

  @override
  String get cloudSyncEncryptFiles => 'Encrypt files';

  @override
  String get cloudSyncEncryptFilesSubtitle =>
      'Encrypts file contents before they leave this server.';

  @override
  String get cloudSyncEncryptNames => 'Encrypt file names';

  @override
  String get cloudSyncEncryptNamesSubtitle =>
      'Hides names as well as contents.';

  @override
  String get cloudSyncPassword => 'Encryption password';

  @override
  String get cloudSyncPasswordEdit => 'New encryption password (optional)';

  @override
  String get cloudSyncPasswordHelper =>
      'Required. Losing it makes the backup unreadable.';

  @override
  String get cloudSyncPasswordEditHelper =>
      'Leave blank to keep the existing password.';

  @override
  String get cloudSyncShowSecret => 'Show';

  @override
  String get cloudSyncHideSecret => 'Hide';

  @override
  String get cloudSyncSalt => 'Encryption salt (optional)';

  @override
  String get cloudSyncSaltEdit => 'New encryption salt (optional)';

  @override
  String get cloudSyncSaltHelper => 'Optional extra secret.';

  @override
  String get cloudSyncSaltEditHelper =>
      'Leave blank to keep the existing salt.';

  @override
  String get cloudSyncSecretsNotice =>
      'Encryption secrets are sent only to the connected server. TrueDock never stores, logs, or autofills them, and cannot recover a lost password.';

  @override
  String cloudSyncPreservedFields(String fields) {
    return 'Advanced settings on this task ($fields) are preserved and sent back unchanged. Pre/post scripts run commands on the server and are edited in the web UI.';
  }

  @override
  String get cloudSyncPreservedFieldsEllipsis => ', …';

  @override
  String get cloudSyncReviewName => 'Name';

  @override
  String get cloudSyncReviewRemote => 'Remote';

  @override
  String get cloudSyncReviewTransfers => 'Transfers';

  @override
  String get cloudSyncServerDefault => 'Server default';

  @override
  String get cloudSyncReviewEncryption => 'Encryption';

  @override
  String get cloudSyncEncryptionBoth => 'Contents and file names';

  @override
  String get cloudSyncEncryptionContents => 'Contents';

  @override
  String get cloudSyncEncryptionOff => 'Off';

  @override
  String get cloudSyncSyncPushWarning =>
      'Sync makes the remote match the local path. Files that no longer exist locally are deleted from the cloud.';

  @override
  String cloudSyncSyncPullWarning(String path) {
    return 'Sync makes $path match the remote. Local files that no longer exist remotely are deleted.';
  }

  @override
  String cloudSyncMovePushWarning(String path) {
    return 'Move uploads the files, then deletes them from $path on this server.';
  }

  @override
  String get cloudSyncMovePullWarning =>
      'Move downloads the files, then deletes them from the cloud provider.';

  @override
  String get cloudSyncCopyNotice =>
      'Copy never deletes anything on either side.';

  @override
  String get cloudSyncEncryptionReminder =>
      'Keep the encryption password somewhere safe. Without it the uploaded data cannot be restored.';

  @override
  String get cloudSyncValidationName => 'Enter a task name.';

  @override
  String get cloudSyncValidationPathRequired => 'Enter a local path.';

  @override
  String get cloudSyncValidationPathAbsolute =>
      'Use an absolute path starting with /.';

  @override
  String get cloudSyncValidationCredential =>
      'Choose a saved cloud credential.';

  @override
  String get cloudSyncValidationBucket => 'Enter the bucket for this provider.';

  @override
  String get cloudSyncValidationTransfers =>
      'Use between 1 and 64 concurrent transfers.';

  @override
  String get cloudSyncValidationPassword =>
      'Enter an encryption password, or turn encryption off.';

  @override
  String get sysSectionAccounts => 'Users and access';

  @override
  String get sysPrivilegesTitle => 'Privileges';

  @override
  String get sysPrivilegesSubtitle => 'Which groups can administer this server';

  @override
  String get sysPrivilegesEmpty => 'No privileges configured.';

  @override
  String get sysPrivilegeCreate => 'Add privilege';

  @override
  String get sysPrivilegeCreateTitle => 'New privilege';

  @override
  String sysPrivilegeEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get sysPrivilegeName => 'Name';

  @override
  String get sysPrivilegeBuiltin => 'Built in';

  @override
  String get sysPrivilegeBuiltinNotice =>
      'TrueNAS ships this privilege. Narrowing it can remove your own administrative access, and it cannot be deleted.';

  @override
  String get sysPrivilegeGroups => 'Local groups';

  @override
  String get sysPrivilegeNoGroups => 'No groups';

  @override
  String get sysPrivilegeRoles => 'Roles';

  @override
  String sysPrivilegeRoleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count roles',
      one: '1 role',
      zero: 'No roles',
    );
    return '$_temp0';
  }

  @override
  String sysPrivilegeEffectiveRoles(int count) {
    return 'Grants $count roles in total, including those implied by the ones selected.';
  }

  @override
  String get sysPrivilegeFullAdminNotice =>
      'FULL_ADMIN grants everything, so the other selections have no additional effect.';

  @override
  String get sysPrivilegeWebShell => 'Allow web shell';

  @override
  String get sysPrivilegeWebShellNotice =>
      'The web shell runs as root, so this grants full control regardless of the roles above.';

  @override
  String get sysPrivilegeSearchRoles => 'Search roles';

  @override
  String sysPrivilegeApplyTitle(String name) {
    return 'Change $name?';
  }

  @override
  String get sysPrivilegeApplyAction => 'Save privilege';

  @override
  String sysPrivilegeApplyConsequence(String server) {
    return 'Members of the selected groups gain these roles on $server immediately.';
  }

  @override
  String get sysPrivilegeApplyConsequenceUnrestricted =>
      'This grants unrestricted administration. Anyone in these groups can change or destroy anything on the server.';

  @override
  String get sysPrivilegeApplyConsequenceLockout =>
      'Narrowing a built-in privilege can remove your own access. Verify another account keeps full administration first.';

  @override
  String get sysPrivilegeCreated => 'Privilege created.';

  @override
  String get sysPrivilegeUpdated => 'Privilege updated.';

  @override
  String get sysPrivilegeDeleted => 'Privilege deleted.';

  @override
  String sysPrivilegeDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get sysPrivilegeDeleteAction => 'Delete privilege';

  @override
  String get sysPrivilegeDeleteConsequence =>
      'Members of its groups lose these roles immediately.';

  @override
  String get sysPrivilegeValidationName => 'Enter a name for this privilege.';

  @override
  String get sysPrivilegeValidationRoles =>
      'Select at least one role, or allow the web shell.';

  @override
  String get sysSectionNetwork => 'Network';

  @override
  String get sysMailTitle => 'Alert email';

  @override
  String get sysMailSubtitle => 'Outgoing SMTP server for alerts and reports';

  @override
  String get sysMailNotConfigured => 'Not configured';

  @override
  String get sysMailEditTitle => 'Alert email';

  @override
  String get sysMailFromAddress => 'From address';

  @override
  String get sysMailFromName => 'From name';

  @override
  String get sysMailServer => 'Outgoing server';

  @override
  String get sysMailPort => 'Port';

  @override
  String get sysMailSecurity => 'Security';

  @override
  String get sysMailSecurityPlain => 'None';

  @override
  String get sysMailSecuritySsl => 'SSL';

  @override
  String get sysMailSecurityTls => 'STARTTLS';

  @override
  String get sysMailAuthentication => 'Authenticate to the server';

  @override
  String get sysMailUsername => 'Username';

  @override
  String get sysMailPassword => 'Password';

  @override
  String get sysMailPasswordHelper =>
      'Leave empty to keep the stored password. TrueDock never reads it back from the server.';

  @override
  String get sysMailOauthNotice =>
      'This server signs in with OAuth. TrueDock can change the addresses and test delivery, but the OAuth credential must be managed in the TrueNAS web interface.';

  @override
  String get sysMailSendTest => 'Send test message';

  @override
  String get sysMailTestSubject => 'TrueDock test message';

  @override
  String get sysMailTestBody =>
      'This is a test message sent from TrueDock to confirm the alert email settings work.';

  @override
  String sysMailTestSent(String recipient) {
    return 'Test message sent to $recipient.';
  }

  @override
  String get sysMailTestSentUnknown => 'Test message sent.';

  @override
  String get sysMailUpdated => 'Alert email settings updated.';

  @override
  String get sysMailNoChanges => 'Nothing changed, so nothing was sent.';

  @override
  String get sysMailApplyTitle => 'Change alert email settings?';

  @override
  String get sysMailApplyAction => 'Save mail settings';

  @override
  String get sysMailApplyConsequence =>
      'Alerts stop reaching you if the new server rejects them. Send a test message afterwards to confirm delivery.';

  @override
  String get sysMailValidationFromRequired =>
      'Enter the address alerts are sent from.';

  @override
  String get sysMailValidationFromInvalid => 'Enter a valid email address.';

  @override
  String get sysMailValidationServer => 'Enter the outgoing mail server.';

  @override
  String sysMailValidationPort(int bound) {
    return 'Port must be between 1 and $bound.';
  }

  @override
  String get sysMailValidationPassword =>
      'Enter a password for the username, or turn authentication off.';

  @override
  String get sysServiceConfigTitle => 'Service settings';

  @override
  String get sysServiceConfigSubtitle =>
      'SSH, SMB, NFS, FTP, and SNMP configuration';

  @override
  String sysServiceEditTitle(String service) {
    return '$service settings';
  }

  @override
  String get sysServiceNameSsh => 'SSH';

  @override
  String get sysServiceNameSmb => 'SMB';

  @override
  String get sysServiceNameNfs => 'NFS';

  @override
  String get sysServiceNameFtp => 'FTP';

  @override
  String get sysServiceNameSnmp => 'SNMP';

  @override
  String get sysServiceRestartNotice =>
      'A running service applies these settings when it restarts.';

  @override
  String get sysServiceSecretNotice =>
      'Shared secrets are never read back from the server. Leave a secret field empty to keep the stored value.';

  @override
  String sysServiceApplyTitle(String service) {
    return 'Change $service settings?';
  }

  @override
  String get sysServiceApplyAction => 'Save settings';

  @override
  String sysServiceApplyConsequenceRunning(String service) {
    return '$service is running and restarts to apply the change, briefly interrupting clients.';
  }

  @override
  String sysServiceApplyConsequenceStopped(String service) {
    return '$service is stopped, so the change takes effect the next time it starts.';
  }

  @override
  String sysServiceUpdated(String service) {
    return '$service settings updated.';
  }

  @override
  String get sysServiceNoChanges => 'Nothing changed, so nothing was sent.';

  @override
  String sysServiceValidationRequired(String field) {
    return '$field is required.';
  }

  @override
  String sysServiceValidationRange(String field, int minimum, int maximum) {
    return '$field must be between $minimum and $maximum.';
  }

  @override
  String sysServiceValidationInvalid(String field) {
    return '$field is not a valid value.';
  }

  @override
  String get sysServiceFieldTcpport => 'Port';

  @override
  String get sysServiceFieldPasswordauth => 'Allow password sign-in';

  @override
  String get sysServiceFieldKerberosauth => 'Allow Kerberos sign-in';

  @override
  String get sysServiceFieldTcpfwd => 'Allow TCP port forwarding';

  @override
  String get sysServiceFieldCompression => 'Compression';

  @override
  String get sysServiceFieldNetbiosname => 'NetBIOS name';

  @override
  String get sysServiceFieldWorkgroup => 'Workgroup';

  @override
  String get sysServiceFieldDescription => 'Description';

  @override
  String get sysServiceFieldEncryption => 'Transport encryption';

  @override
  String get sysServiceFieldLocalmaster => 'Local master browser';

  @override
  String get sysServiceFieldEnableSmb1 => 'Enable SMB1 (insecure)';

  @override
  String get sysServiceFieldNtlmv1Auth => 'Allow NTLMv1 (insecure)';

  @override
  String get sysServiceFieldServers => 'Server threads';

  @override
  String get sysServiceFieldAllowNonroot => 'Allow non-root mounts';

  @override
  String get sysServiceFieldV4Domain => 'NFSv4 domain';

  @override
  String get sysServiceFieldMountdPort => 'mountd port';

  @override
  String get sysServiceFieldRdma => 'RDMA';

  @override
  String get sysServiceFieldClients => 'Maximum clients';

  @override
  String get sysServiceFieldLoginattempt => 'Login attempts';

  @override
  String get sysServiceFieldTimeout => 'Idle timeout (seconds)';

  @override
  String get sysServiceFieldTls => 'Require TLS';

  @override
  String get sysServiceFieldOnlyanonymous => 'Allow anonymous only';

  @override
  String get sysServiceFieldOnlylocal => 'Allow local users only';

  @override
  String get sysServiceFieldDefaultroot => 'Confine users to home';

  @override
  String get sysServiceFieldResume => 'Allow resumed transfers';

  @override
  String get sysServiceFieldBanner => 'Login banner';

  @override
  String get sysServiceFieldCommunity => 'Community string';

  @override
  String get sysServiceFieldContact => 'Contact';

  @override
  String get sysServiceFieldLocation => 'Location';

  @override
  String get sysServiceFieldLoglevel => 'Log level';

  @override
  String get sysServiceFieldTraps => 'Send traps';

  @override
  String get sysServiceFieldZilstat => 'Report ZIL statistics';

  @override
  String get sysServiceFieldV3 => 'Enable SNMPv3';

  @override
  String get sysServiceFieldV3Username => 'SNMPv3 username';

  @override
  String get sysServiceFieldV3Authtype => 'SNMPv3 authentication';

  @override
  String get sysServiceFieldV3Password => 'SNMPv3 password';

  @override
  String get sysServiceFieldV3Privproto => 'SNMPv3 privacy protocol';

  @override
  String get sysServiceFieldV3Privpassphrase => 'SNMPv3 privacy passphrase';

  @override
  String get sysServiceChoiceDefault => 'Server default';

  @override
  String get sysServiceChoiceNone => 'None';

  @override
  String get sysAlertClassesTitle => 'Alert policies';

  @override
  String get sysAlertClassesSubtitle =>
      'Which alerts are delivered, and how often';

  @override
  String get sysAlertClassesOpen => 'Review alert policies';

  @override
  String sysAlertClassesSummary(int overridden, int total) {
    return '$overridden of $total classes changed from their defaults';
  }

  @override
  String sysAlertClassesSilenced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes are silenced',
      one: '1 class is silenced',
      zero: 'No classes are silenced',
    );
    return '$_temp0';
  }

  @override
  String get sysAlertClassLevel => 'Level';

  @override
  String get sysAlertClassPolicy => 'Delivery';

  @override
  String get sysAlertPolicyImmediately => 'Immediately';

  @override
  String get sysAlertPolicyHourly => 'Hourly';

  @override
  String get sysAlertPolicyDaily => 'Daily';

  @override
  String get sysAlertPolicyNever => 'Never';

  @override
  String get sysAlertClassDefault => 'Default';

  @override
  String get sysAlertClassChanged => 'Changed';

  @override
  String get sysAlertClassSilencedBadge => 'Silenced';

  @override
  String get sysAlertClassesApplyTitle => 'Change alert policies?';

  @override
  String get sysAlertClassesApplyAction => 'Save policies';

  @override
  String get sysAlertClassesApplyConsequence =>
      'Classes set to Never are not delivered to any destination, however severe they become.';

  @override
  String get sysAlertClassesApplyReplace =>
      'TrueNAS replaces the whole override list, so every change shown here is saved together.';

  @override
  String get sysAlertClassesUpdated => 'Alert policies updated.';

  @override
  String get sysAlertClassesNoChanges =>
      'Nothing changed, so nothing was sent.';

  @override
  String get sysAlertClassesReset => 'Reset to default';

  @override
  String get sysAlertServicesTitle => 'Alert destinations';

  @override
  String get sysAlertServicesSubtitle => 'Where TrueNAS sends alerts';

  @override
  String get sysAlertServicesEmpty =>
      'No alert destinations. Alerts stay in the web interface and this app until one is added.';

  @override
  String get sysAlertServiceCreate => 'Add destination';

  @override
  String get sysAlertServiceCreateTitle => 'New alert destination';

  @override
  String sysAlertServiceEditTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get sysAlertServiceName => 'Name';

  @override
  String get sysAlertServiceKind => 'Destination';

  @override
  String get sysAlertServiceLevel => 'Minimum level';

  @override
  String get sysAlertKindEmail => 'Email';

  @override
  String get sysAlertKindSnmpTrap => 'SNMP trap';

  @override
  String get sysAlertLevelInfo => 'Information';

  @override
  String get sysAlertLevelNotice => 'Notice';

  @override
  String get sysAlertLevelWarning => 'Warning';

  @override
  String get sysAlertLevelError => 'Error';

  @override
  String get sysAlertLevelCritical => 'Critical';

  @override
  String get sysAlertLevelAlert => 'Alert';

  @override
  String get sysAlertLevelEmergency => 'Emergency';

  @override
  String get sysAlertServiceEnabled => 'Enabled';

  @override
  String get sysAlertServiceDisabled => 'Disabled';

  @override
  String get sysAlertServiceSecretNotice =>
      'Credentials are never read back from the server. Leave one empty to keep the stored value.';

  @override
  String get sysAlertServiceUnknownKind =>
      'This destination type is not supported by TrueDock. Edit it in the TrueNAS web interface.';

  @override
  String get sysAlertServiceTest => 'Send test alert';

  @override
  String sysAlertServiceTested(String name) {
    return 'Test alert sent through $name.';
  }

  @override
  String get sysAlertServiceCreated => 'Alert destination added.';

  @override
  String get sysAlertServiceUpdated => 'Alert destination updated.';

  @override
  String get sysAlertServiceDeleted => 'Alert destination deleted.';

  @override
  String sysAlertServiceDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get sysAlertServiceDeleteAction => 'Delete destination';

  @override
  String get sysAlertServiceDeleteConsequence =>
      'Alerts stop being delivered here. Any credential stored for it is removed.';

  @override
  String get sysAlertServiceValidationName =>
      'Enter a name for this destination.';

  @override
  String sysAlertServiceValidationRequired(String field) {
    return '$field is required.';
  }

  @override
  String sysAlertServiceValidationInteger(String field) {
    return '$field must be a number.';
  }

  @override
  String sysAlertServiceValidationUrl(String field) {
    return '$field must be a full URL, including https://.';
  }

  @override
  String get sysAlertFieldEmail => 'Email address';

  @override
  String get sysAlertFieldUrl => 'Webhook URL';

  @override
  String get sysAlertFieldBotToken => 'Bot token';

  @override
  String get sysAlertFieldChatIds => 'Chat IDs';

  @override
  String get sysAlertFieldServiceKey => 'Integration key';

  @override
  String get sysAlertFieldClientName => 'Client name';

  @override
  String get sysAlertFieldUsername => 'Username';

  @override
  String get sysAlertFieldChannel => 'Channel';

  @override
  String get sysAlertFieldIconUrl => 'Icon URL';

  @override
  String get sysAlertFieldApiKey => 'API key';

  @override
  String get sysAlertFieldApiUrl => 'API URL';

  @override
  String get sysAlertFieldRoutingKey => 'Routing key';

  @override
  String get sysAlertFieldRegion => 'Region';

  @override
  String get sysAlertFieldTopicArn => 'Topic ARN';

  @override
  String get sysAlertFieldAwsAccessKeyId => 'Access key ID';

  @override
  String get sysAlertFieldAwsSecretAccessKey => 'Secret access key';

  @override
  String get sysAlertFieldHost => 'Host';

  @override
  String get sysAlertFieldPassword => 'Password';

  @override
  String get sysAlertFieldDatabase => 'Database';

  @override
  String get sysAlertFieldSeriesName => 'Series name';

  @override
  String get sysAlertFieldPort => 'Port';

  @override
  String get sysAlertFieldCommunity => 'Community string';

  @override
  String get sysAlertFieldV3Username => 'SNMPv3 username';

  @override
  String get sysAlertFieldV3Authkey => 'SNMPv3 authentication key';

  @override
  String get sysAlertFieldV3Authprotocol => 'SNMPv3 authentication protocol';

  @override
  String get sysAlertFieldV3Privkey => 'SNMPv3 privacy key';

  @override
  String get sysSectionCron => 'Scheduled commands';

  @override
  String get sysCronTitle => 'Scheduled commands';

  @override
  String get sysCronSubtitle => 'Commands TrueNAS runs on a schedule';

  @override
  String get sysCronEmpty => 'No scheduled commands.';

  @override
  String get sysCronCreate => 'Add scheduled command';

  @override
  String get sysCronCreateTitle => 'New scheduled command';

  @override
  String get sysCronEditTitle => 'Edit scheduled command';

  @override
  String get sysCronCommand => 'Command';

  @override
  String get sysCronCommandHelper =>
      'Runs through the shell as the account below.';

  @override
  String get sysCronUser => 'Run as';

  @override
  String get sysCronDescription => 'Description';

  @override
  String get sysCronEnabled => 'Enabled';

  @override
  String get sysCronCaptureStdout => 'Keep standard output';

  @override
  String get sysCronCaptureStderr => 'Keep error output';

  @override
  String get sysCronDisabled => 'Disabled';

  @override
  String get sysCronRunNow => 'Run now';

  @override
  String get sysCronRunTitle => 'Run this command now?';

  @override
  String get sysCronRunAction => 'Run command';

  @override
  String sysCronRunConsequence(String server, String user) {
    return 'The command runs immediately on $server as $user, with that account\'s privileges.';
  }

  @override
  String get sysCronRunRequested => 'Running the command.';

  @override
  String get sysCronDeleteTitle => 'Delete this scheduled command?';

  @override
  String get sysCronDeleteAction => 'Delete command';

  @override
  String get sysCronDeleteConsequence =>
      'The schedule is removed. Anything the command already did is unaffected.';

  @override
  String get sysCronCreated => 'Scheduled command added.';

  @override
  String get sysCronUpdated => 'Scheduled command updated.';

  @override
  String get sysCronDeleted => 'Scheduled command deleted.';

  @override
  String get sysCronValidationCommand => 'Enter a command to run.';

  @override
  String get sysCronValidationUser => 'Choose an account to run as.';

  @override
  String get sysSectionUpdates => 'Updates';

  @override
  String get sysAuditTitle => 'Audit log';

  @override
  String get sysAuditSubtitle => 'Who did what on this server';

  @override
  String get sysAuditEmpty => 'No audit records match this filter.';

  @override
  String get sysAuditFilterAll => 'All events';

  @override
  String get sysAuditFilterFailures => 'Failures only';

  @override
  String get sysAuditFilterUser => 'Filter by user';

  @override
  String get sysAuditEventAuthentication => 'Sign in';

  @override
  String get sysAuditEventLogout => 'Sign out';

  @override
  String get sysAuditEventMethodCall => 'Action';

  @override
  String get sysAuditDenied => 'Denied';

  @override
  String get sysAuditFailed => 'Failed';

  @override
  String sysAuditFrom(String address) {
    return 'from $address';
  }

  @override
  String sysAuditRetention(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Kept for $_temp0';
  }

  @override
  String sysAuditSpace(String used, String available) {
    return 'Using $used of $available';
  }

  @override
  String get sysAuditQuotaUncapped => 'No quota set';

  @override
  String get sysAuditRetentionEdit => 'Retention and quota';

  @override
  String get sysAuditRetentionDays => 'Retention (days)';

  @override
  String get sysAuditRetentionHelp =>
      'Records older than this are discarded. Between 1 and 30 days.';

  @override
  String get sysAuditQuota => 'Quota (GiB)';

  @override
  String get sysAuditQuotaHelp =>
      'Maximum space the audit databases may use. 0 means uncapped.';

  @override
  String get sysAuditWarnAt => 'Warn at (%)';

  @override
  String get sysAuditCriticalAt => 'Critical at (%)';

  @override
  String get sysAuditApplyTitle => 'Change audit retention?';

  @override
  String get sysAuditApplyAction => 'Save retention';

  @override
  String get sysAuditApplyConsequence =>
      'Shortening retention discards audit history the server has already recorded. There is no undo.';

  @override
  String get sysAuditUpdated => 'Audit retention updated.';

  @override
  String get sysAuditNoChanges => 'Nothing changed, so nothing was sent.';

  @override
  String sysAuditValidationRetention(int minimum, int maximum) {
    return 'Retention must be between $minimum and $maximum days.';
  }

  @override
  String sysAuditValidationQuota(int minimum, int maximum) {
    return 'Value must be between $minimum and $maximum.';
  }

  @override
  String get sysAuditValidationFillOrder =>
      'The critical threshold must be above the warning threshold.';

  @override
  String get sysConfigBackupTitle => 'Configuration backup';

  @override
  String get sysConfigBackupSubtitle =>
      'Download the settings database, or reset to defaults';

  @override
  String get sysConfigBackupPrepare => 'Prepare backup';

  @override
  String get sysConfigBackupSheetTitle => 'Configuration backup';

  @override
  String get sysConfigBackupExplain =>
      'The archive contains the settings database: shares, users, tasks, and network configuration. Pool data is not included.';

  @override
  String get sysConfigBackupSecretSeed => 'Include the secret seed';

  @override
  String get sysConfigBackupSecretSeedHelp =>
      'Needed to decrypt saved passwords and API keys after a restore. Anyone with this archive can read them.';

  @override
  String get sysConfigBackupPoolKeys => 'Include pool encryption keys';

  @override
  String get sysConfigBackupPoolKeysHelp =>
      'Unlocks encrypted datasets. An archive with these keys is equivalent to the data itself.';

  @override
  String get sysConfigBackupRootKeys => 'Include root SSH keys';

  @override
  String get sysConfigBackupSecretsWarning =>
      'This archive will contain secrets. Store it where you would store the server password itself.';

  @override
  String get sysConfigBackupReady => 'Backup ready';

  @override
  String sysConfigBackupReadyBody(String filename) {
    return 'Open this one-time link in a browser to download $filename. The link expires shortly and works only for this download.';
  }

  @override
  String get sysConfigBackupCopyLink => 'Copy download link';

  @override
  String get sysConfigBackupDownload => 'Download';

  @override
  String get sysConfigBackupOpenFailed =>
      'Could not open the download in your browser.';

  @override
  String get sysConfigBackupLinkCopied => 'Download link copied.';

  @override
  String get sysConfigResetTitle => 'Reset configuration';

  @override
  String get sysConfigResetSubtitle =>
      'Return every setting to its factory default';

  @override
  String get sysConfigResetAction => 'Reset configuration';

  @override
  String get sysConfigResetConsequenceTotal =>
      'Every share, user, task, and network setting reverts to its default. Pool data is untouched, but nothing will be shared or scheduled until you configure it again.';

  @override
  String get sysConfigResetConsequenceIrreversible =>
      'There is no undo. Download a configuration backup first if you have not already.';

  @override
  String get sysConfigResetConsequenceReboot =>
      'The server reboots immediately and TrueDock loses this connection.';

  @override
  String get sysConfigResetConsequenceNoReboot =>
      'The reset applies now; restart the server yourself to complete it.';

  @override
  String get sysConfigResetReboot => 'Reboot after resetting';

  @override
  String get sysConfigResetRequested => 'Configuration reset requested.';

  @override
  String get sysSectionActivity => 'Alerts and jobs';

  @override
  String get sysConnectPrompt => 'Connect a server to view this section.';

  @override
  String sysHeadingWithCount(String title, int count) {
    return '$title  $count';
  }

  @override
  String get sysMetricUsers => 'Users';

  @override
  String get sysMetricGroups => 'Groups';

  @override
  String get sysMetricAdmins => 'Admins';

  @override
  String get sysUsers => 'Users';

  @override
  String get sysNewUser => 'New user';

  @override
  String get sysNoUsers => 'No users found.';

  @override
  String get sysGroups => 'Groups';

  @override
  String get sysNewGroup => 'New group';

  @override
  String get sysNoGroups => 'No groups found.';

  @override
  String get sysApiKeys => 'API keys';

  @override
  String sysRevokeApiKeyTitle(String name) {
    return 'Revoke $name?';
  }

  @override
  String get sysRevokeApiKeyAction => 'Revoke API key';

  @override
  String get sysRevokeApiKeyConsequence =>
      'Every client still using this key stops being able to sign in immediately, including TrueDock if this is the key it uses.';

  @override
  String get sysRevokeApiKeyUnowned =>
      'The key cannot be recovered. A replacement has to be created on the server, which shows the new secret only once.';

  @override
  String sysRevokeApiKeyOwned(String owner) {
    return 'The account $owner keeps its password and other keys. This key cannot be recovered; a replacement shows its secret only once.';
  }

  @override
  String sysRevokeApiKeyActionLabel(String name) {
    return 'revoke $name';
  }

  @override
  String sysRevokedApiKey(String name) {
    return 'Revoked $name.';
  }

  @override
  String sysUpdateActionLabel(String name) {
    return 'update $name';
  }

  @override
  String sysUpdatedEntity(String name) {
    return 'Updated $name.';
  }

  @override
  String sysCreateActionLabel(String name) {
    return 'create $name';
  }

  @override
  String sysCreatedEntity(String name) {
    return 'Created $name.';
  }

  @override
  String sysDeleteActionLabel(String name) {
    return 'delete $name';
  }

  @override
  String sysDeletedEntity(String name) {
    return 'Deleted $name.';
  }

  @override
  String sysOperationFailed(String action) {
    return 'TrueNAS could not $action.';
  }

  @override
  String get sysGenericOperationFailed => 'The TrueNAS operation failed.';

  @override
  String sysChangePasswordTitle(String username) {
    return 'Change password for $username?';
  }

  @override
  String get sysChangePasswordAction => 'Change password';

  @override
  String get sysChangePasswordImmediate =>
      'The new password takes effect immediately. Anyone signed in as this account must use the new password afterwards.';

  @override
  String get sysChangePasswordSessions =>
      'Active sessions for this account may be ended by TrueNAS.';

  @override
  String get sysChangePasswordPrivacy =>
      'The password is sent only to the connected server and is not stored, logged, or autofilled by TrueDock.';

  @override
  String sysChangePasswordActionLabel(String username) {
    return 'change the password for $username';
  }

  @override
  String sysPasswordChanged(String username) {
    return 'Password changed for $username.';
  }

  @override
  String get sysDeleteUserTitle => 'Delete user?';

  @override
  String get sysDeleteUserAction => 'Delete user';

  @override
  String get sysDeleteUserConsequenceAccount =>
      'The account is removed and can no longer sign in anywhere.';

  @override
  String sysDeleteUserConsequenceGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The user is removed from $count groups.',
      one: 'The user is removed from 1 group.',
    );
    return '$_temp0';
  }

  @override
  String sysDeleteUserConsequencePrimaryGroup(String group) {
    return 'Their primary group $group is deleted with them because it has no other members.';
  }

  @override
  String get sysDeleteUserConsequenceFiles =>
      'Files owned by this user keep its numeric UID and may become inaccessible.';

  @override
  String get sysDeleteUserNote =>
      'Home directory contents are not removed by this action.';

  @override
  String get sysDeleteGroupTitle => 'Delete group?';

  @override
  String get sysDeleteGroupAction => 'Delete group';

  @override
  String sysDeleteGroupConsequenceMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The group is removed and its $count members lose the access it granted.',
      one: 'The group is removed and its 1 member loses the access it granted.',
    );
    return '$_temp0';
  }

  @override
  String get sysDeleteGroupConsequencePermissions =>
      'Share and dataset permissions referencing this group stop matching anyone.';

  @override
  String sysDeleteGroupConsequencePrimary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'It is the primary group for $count users, so TrueNAS may refuse to delete it.',
      one:
          'It is the primary group for 1 user, so TrueNAS may refuse to delete it.',
    );
    return '$_temp0';
  }

  @override
  String get sysDeleteGroupNote =>
      'Member accounts themselves are not deleted.';

  @override
  String sysInstallUpdateTitle(String version) {
    return 'Install $version?';
  }

  @override
  String get sysInstallUpdateAction => 'Install and restart';

  @override
  String get sysInstallUpdateConsequenceRestart =>
      'The server downloads the update and restarts into it.';

  @override
  String sysInstallUpdateConsequenceServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Shares, VMs, and $count running apps are unavailable until the restart finishes.',
      one:
          'Shares, VMs, and 1 running app are unavailable until the restart finishes.',
    );
    return '$_temp0';
  }

  @override
  String sysInstallUpdateConsequenceJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs are still running and will be cut off.',
      one: '1 job is still running and will be cut off.',
    );
    return '$_temp0';
  }

  @override
  String get sysInstallUpdateConsequenceConnection =>
      'TrueDock loses its connection while the server reboots.';

  @override
  String get sysInstallUpdateNote =>
      'Rolling back a TrueNAS update requires console access.';

  @override
  String sysInstallUpdateActionLabel(String version) {
    return 'install $version';
  }

  @override
  String get sysUpdateStarted =>
      'Update started. The server will restart when it is staged.';

  @override
  String get sysRestartTitle => 'Restart server?';

  @override
  String get sysRestartAction => 'Restart now';

  @override
  String get sysRestartVerb => 'restart';

  @override
  String get sysRestartExtra =>
      'The server comes back on its own once it finishes booting.';

  @override
  String get sysRestartSuccess =>
      'Restart requested. TrueDock will lose its connection.';

  @override
  String get sysShutdownTitle => 'Shut down server?';

  @override
  String get sysShutdownAction => 'Shut down now';

  @override
  String get sysShutdownVerb => 'shut down';

  @override
  String get sysShutdownExtra =>
      'The server stays off until someone powers it on physically or through out-of-band management.';

  @override
  String get sysShutdownSuccess =>
      'Shutdown requested. TrueDock will lose its connection.';

  @override
  String get sysPowerConsequenceClients =>
      'Every SMB, NFS, and iSCSI client loses access immediately.';

  @override
  String sysPowerConsequenceWorkloads(int apps, int vms) {
    return '$apps running app(s) and $vms running VM(s) are stopped.';
  }

  @override
  String sysPowerConsequenceJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count jobs are still running. Replication and scrubs will need to run again.',
      one:
          '1 job is still running. Replication and scrubs will need to run again.',
    );
    return '$_temp0';
  }

  @override
  String get sysPowerNote =>
      'TrueDock cannot confirm the result because the connection drops.';

  @override
  String sysPowerActionLabel(String verb, String server) {
    return '$verb $server';
  }

  @override
  String get sysPowerReason => 'Requested from TrueDock';

  @override
  String sysBootIntoTitle(String environment) {
    return 'Boot into $environment?';
  }

  @override
  String get sysBootIntoAction => 'Use at next boot';

  @override
  String sysBootIntoConsequenceRestart(String server, String environment) {
    return '$server will start $environment the next time it restarts. Nothing changes until then, and TrueDock does not restart the server for you.';
  }

  @override
  String get sysBootIntoConsequenceUnknownCurrent =>
      'The system software, and any update applied to it, changes once the server restarts.';

  @override
  String sysBootIntoConsequenceCurrent(String current) {
    return 'The server currently runs $current. Its system software, including any update applied to it, is replaced after the restart.';
  }

  @override
  String get sysBootEnvironmentDataNote =>
      'Pools, datasets, and share data are not part of a boot environment and are left alone.';

  @override
  String sysBootEnvironmentActivated(String environment) {
    return '$environment will be used at the next restart.';
  }

  @override
  String sysBootEnvironmentKept(String environment) {
    return '$environment is kept and will not be pruned automatically.';
  }

  @override
  String sysBootEnvironmentUnkept(String environment) {
    return '$environment can now be removed automatically.';
  }

  @override
  String sysDeleteBootEnvironmentTitle(String environment) {
    return 'Delete $environment?';
  }

  @override
  String get sysDeleteBootEnvironmentAction => 'Delete environment';

  @override
  String sysDeleteBootEnvironmentConsequence(String environment) {
    return '$environment is destroyed permanently. It cannot be recovered and can no longer be used to roll the system back.';
  }

  @override
  String sysBootEnvironmentDeleted(String environment) {
    return '$environment was deleted.';
  }

  @override
  String get sysMetricInterfaces => 'Interfaces';

  @override
  String get sysMetricLinkUp => 'Link up';

  @override
  String get sysMetricRoutes => 'Routes';

  @override
  String get sysInterfaces => 'Interfaces';

  @override
  String get sysNoInterfaces => 'No network interfaces found.';

  @override
  String get sysStaticRoutes => 'Static routes';

  @override
  String get sysNewRoute => 'New route';

  @override
  String get sysNoStaticRoutes => 'No static routes configured.';

  @override
  String sysRouteVia(String gateway) {
    return 'via $gateway';
  }

  @override
  String sysRouteViaWithDescription(String gateway, String description) {
    return 'via $gateway · $description';
  }

  @override
  String get sysEdit => 'Edit';

  @override
  String get sysDelete => 'Delete';

  @override
  String get sysNetGlobalTitle => 'DNS and gateway';

  @override
  String get sysNetGlobalSubtitle =>
      'Hostname, domain, IPv4/IPv6 gateways, nameservers';

  @override
  String get sysNetGlobalEdit => 'Edit DNS and gateway';

  @override
  String get sysNetConfigured => 'Configured';

  @override
  String get sysNetInEffect => 'In effect';

  @override
  String get sysNetFromDhcp =>
      'These values come from DHCP. Entering one here overrides the lease.';

  @override
  String get sysNetNotSet => 'Not set';

  @override
  String get sysNetHostname => 'Hostname';

  @override
  String get sysNetDomain => 'Domain';

  @override
  String get sysNetGateway => 'IPv4 default gateway';

  @override
  String get sysNetIpv6Gateway => 'IPv6 default gateway';

  @override
  String sysNetNameserver(int index) {
    return 'Nameserver $index';
  }

  @override
  String get sysNetHttpProxy => 'HTTP proxy';

  @override
  String get sysNetDefaultRoutes => 'Default routes';

  @override
  String get sysNetAddresses => 'Addresses';

  @override
  String get sysNetClearHelp =>
      'Leave a field empty to clear it and fall back to DHCP.';

  @override
  String get sysNetGlobalApplyTitle => 'Change DNS and gateway?';

  @override
  String get sysNetGlobalApplyAction => 'Apply network settings';

  @override
  String get sysNetGlobalConsequenceImmediate =>
      'The change applies immediately, without the commit and check-in window that interface edits use.';

  @override
  String sysNetGlobalConsequenceSever(String server) {
    return 'This clears a gateway or nameserver the server is currently using. If TrueDock reaches $server through it, this connection will drop and you may need local access to recover.';
  }

  @override
  String get sysNetGlobalUpdated => 'Network settings updated.';

  @override
  String get sysNetGlobalNoChanges => 'Nothing changed, so nothing was sent.';

  @override
  String get sysNetValidationHostnameRequired => 'Enter a hostname.';

  @override
  String get sysNetValidationHostnameInvalid =>
      'Use letters, digits, and hyphens only.';

  @override
  String get sysNetValidationDomain => 'Enter a valid domain name.';

  @override
  String get sysNetValidationGateway =>
      'Enter a valid IPv4 address, or leave empty to clear it.';

  @override
  String get sysNetValidationIpv6Gateway =>
      'Enter a valid IPv6 address, or leave empty to clear it.';

  @override
  String get sysNetValidationNameserver =>
      'Enter a valid IP address, or leave empty to clear it.';

  @override
  String get sysNetValidationProxy => 'Enter a valid proxy URL.';

  @override
  String get sysApplyNetworkChanges => 'Apply pending network changes';

  @override
  String get sysApplyNetworkChangesHelp =>
      'Commit and check in staged interface and static-route changes.';

  @override
  String sysStageRouteTitle(String destination) {
    return 'Stage route to $destination?';
  }

  @override
  String get sysStageRouteAction => 'Stage route';

  @override
  String sysRouteConsequence(String destination, String gateway) {
    return 'Routes $destination via $gateway.';
  }

  @override
  String get sysRouteStagedConsequence =>
      'The route is only staged. It takes effect after the pending network changes are committed and checked in.';

  @override
  String get sysRouteStagedNote =>
      'TrueDock asks you to commit and check in afterwards.';

  @override
  String sysStageRouteActionLabel(String destination) {
    return 'stage the route to $destination';
  }

  @override
  String sysRouteStagedSuccess(String destination) {
    return 'Staged route to $destination. Apply the pending network changes to take it live.';
  }

  @override
  String sysUpdateRouteTitle(String destination) {
    return 'Update route to $destination?';
  }

  @override
  String get sysStageUpdateAction => 'Stage update';

  @override
  String get sysRouteChangeStagedConsequence =>
      'The change is only staged. It takes effect after the pending network changes are committed and checked in.';

  @override
  String sysUpdateRouteActionLabel(String destination) {
    return 'update the route to $destination';
  }

  @override
  String sysRouteUpdateStagedSuccess(String destination) {
    return 'Staged update for $destination. Apply the pending network changes to take it live.';
  }

  @override
  String sysDeleteRouteTitle(String destination) {
    return 'Delete route to $destination?';
  }

  @override
  String get sysStageDeletionAction => 'Stage deletion';

  @override
  String sysRouteRemoveConsequence(String destination, String gateway) {
    return 'Removes the route to $destination via $gateway.';
  }

  @override
  String get sysRouteDeletionStagedConsequence =>
      'The deletion is only staged. The route stays in the table until the pending network changes are committed and checked in.';

  @override
  String sysDeleteRouteActionLabel(String destination) {
    return 'stage the deletion of the route to $destination';
  }

  @override
  String sysRouteDeletionStagedSuccess(String destination) {
    return 'Staged deletion of $destination. Apply the pending network changes to take it live.';
  }

  @override
  String get sysInterfaceConfigLoadFailed =>
      'Could not load the interface configuration.';

  @override
  String sysInterfaceNoChanges(String name) {
    return 'No changes to stage for $name.';
  }

  @override
  String sysStageInterfaceTitle(String name) {
    return 'Stage changes to $name?';
  }

  @override
  String get sysStageChangeAction => 'Stage change';

  @override
  String sysInterfaceDhcpConsequence(String name) {
    return '$name switches to DHCP for IPv4.';
  }

  @override
  String sysInterfaceStaticConsequence(
    String name,
    int count,
    String addresses,
  ) {
    return '$name uses $count static address(es): $addresses.';
  }

  @override
  String get sysInterfaceLosesStatic =>
      'The existing static addresses are removed. Anything pointing at them loses its route.';

  @override
  String get sysInterfaceStagedConsequence =>
      'The change is only staged. Committing it can drop the TrueDock connection, and the server rolls it back unless the check-in arrives in time.';

  @override
  String get sysInterfaceStagedNote =>
      'TrueDock offers the commit and check-in steps next.';

  @override
  String sysStageInterfaceActionLabel(String name) {
    return 'stage changes to $name';
  }

  @override
  String get sysUpdateFallbackName => 'TrueNAS SCALE';

  @override
  String sysUpdateAvailable(String version) {
    return '$version is available';
  }

  @override
  String get sysUpdateStatusHeading => 'System update status';

  @override
  String get sysUpdateStatusUnavailable => 'Update status is unavailable.';

  @override
  String get sysPower => 'Power';

  @override
  String get sysBootEnvironments => 'Boot environments';

  @override
  String get sysUpdateTrain => 'Train';

  @override
  String get sysUpdateProfile => 'Profile';

  @override
  String get sysUpdateAvailableVersion => 'Available version';

  @override
  String get sysUnknown => 'Unknown';

  @override
  String get sysUpToDate => 'Up to date';

  @override
  String get sysUpdateError => 'Error';

  @override
  String get sysUpdateProfilesLoadFailed => 'Could not load update channels.';

  @override
  String sysInstallVersion(String version) {
    return 'Install $version';
  }

  @override
  String get sysUpdatesNotPermitted =>
      'Updates are not permitted for this account';

  @override
  String get sysUpdateInProgress => 'Update in progress';

  @override
  String get sysUpdatePreparing => 'Preparing the system update…';

  @override
  String get sysManualUpdateTitle => 'Custom firmware';

  @override
  String get sysManualUpdateDescription =>
      'Upload an official TrueNAS .tar or .update file and install it directly.';

  @override
  String get sysManualUpdateChooseFile => 'Choose update file';

  @override
  String get sysManualUpdateConfirmTitle => 'Install this custom firmware?';

  @override
  String get sysManualUpdateUploadAction => 'Upload and install';

  @override
  String get sysManualUpdateConsequenceValidation =>
      'TrueNAS uploads and validates the selected update archive before installing it.';

  @override
  String get sysManualUpdateConsequenceRestart =>
      'The server restarts automatically after the update file is installed.';

  @override
  String sysManualUpdateUploading(int percent) {
    return 'Uploading: $percent%';
  }

  @override
  String get sysManualUpdateProcessing =>
      'TrueNAS is validating and installing the update…';

  @override
  String get sysManualUpdateRestartSoon => 'The update is ready to install.';

  @override
  String get sysUpdateChannelTitle => 'Firmware channel';

  @override
  String get sysUpdateChannelDescription =>
      'Choose which TrueNAS release channel supplies system updates.';

  @override
  String get sysUpdateChannelGeneral => 'General';

  @override
  String get sysUpdateChannelEarlyAdopter => 'Early Adopter';

  @override
  String get sysUpdateChannelDeveloper => 'Developer Beta';

  @override
  String get sysManualUpdateFailed => 'The custom firmware update failed.';

  @override
  String get sysManualUpdateNoPath =>
      'The selected file cannot be read on this device.';

  @override
  String get sysManualUpdateUnsupportedExtension =>
      'Select an official TrueNAS .tar or .update file.';

  @override
  String sysUpdateProgress(int percent) {
    return 'Update progress: $percent%';
  }

  @override
  String get sysPowerNotPermitted =>
      'This account cannot restart or shut down the server.';

  @override
  String get sysPowerWarning =>
      'Restarting or shutting down interrupts every share, app, and running job on this server.';

  @override
  String get sysRestartServer => 'Restart server';

  @override
  String get sysShutdownServer => 'Shut down server';

  @override
  String get sysMetricAlerts => 'Alerts';

  @override
  String get sysMetricActiveJobs => 'Active jobs';

  @override
  String get sysMetricFailures => 'Failures';

  @override
  String get sysAlerts => 'Alerts';

  @override
  String get sysJobs => 'Jobs';

  @override
  String get sysNoAlerts => 'No alerts.';

  @override
  String get sysAlertFailed => 'The alert operation failed.';

  @override
  String get sysAlertDismissed => 'Alert dismissed.';

  @override
  String get sysAlertRestored => 'Alert restored.';

  @override
  String sysAlertSubtitleDismissed(String level) {
    return '$level · Dismissed';
  }

  @override
  String get sysRestoreAlert => 'Restore alert';

  @override
  String get sysDismissAlert => 'Dismiss alert';

  @override
  String get sysUserLocal => 'Local';

  @override
  String get sysUserDirectory => 'Directory';

  @override
  String get sysUserSmb => 'SMB';

  @override
  String get sysUserPasswordDisabled => 'Password disabled';

  @override
  String get sysUserLocked => 'Locked';

  @override
  String get sysBuiltInAccount => 'Built-in account';

  @override
  String get sysDirectoryAccount => 'Directory account';

  @override
  String get sysEditUser => 'Edit user';

  @override
  String get sysDeleteUser => 'Delete user';

  @override
  String sysGroupSubtitle(String gid, int count) {
    return 'GID $gid · $count users';
  }

  @override
  String sysGroupSubtitleWithRoles(String gid, int count, String roles) {
    return 'GID $gid · $count users · $roles';
  }

  @override
  String get sysBuiltInGroup => 'Built-in group';

  @override
  String get sysDirectoryGroup => 'Directory group';

  @override
  String get sysEditGroup => 'Edit group';

  @override
  String get sysDeleteGroup => 'Delete group';

  @override
  String get sysInterfaceLinkUp => 'Link up';

  @override
  String sysInterfaceMtu(String mtu) {
    return 'MTU $mtu';
  }

  @override
  String get sysInterfaceDhcp => 'DHCP';

  @override
  String get sysUserEditReviewTitle => 'Review user changes';

  @override
  String get sysUserEditTitle => 'Edit user';

  @override
  String get sysUserApplyChanges => 'Apply changes';

  @override
  String get sysUserFullNameLabel => 'Full name';

  @override
  String get sysUserEmailLabel => 'Email';

  @override
  String get sysUserEmailHelper => 'Leave empty to clear the address';

  @override
  String get sysUserShellLabel => 'Login shell';

  @override
  String get sysUserSmbAccessTitle => 'SMB access';

  @override
  String get sysUserSmbAccessSubtitle =>
      'Allow this account to authenticate to SMB.';

  @override
  String get sysUserDisablePasswordTitle => 'Disable password sign-in';

  @override
  String get sysUserDisablePasswordSubtitle =>
      'Keeps key-based access working.';

  @override
  String get sysUserLockTitle => 'Lock account';

  @override
  String get sysUserLockSubtitle => 'Blocks all sign-in for this user.';

  @override
  String get sysUserPrimaryGroupTitle => 'Primary group';

  @override
  String get sysUserPrimaryGroupManaged => 'Managed by TrueNAS';

  @override
  String sysUserPrimaryGroupNamed(String name) {
    return '$name — change it in the TrueNAS web UI';
  }

  @override
  String get sysUserAuxGroupsTitle => 'Auxiliary groups';

  @override
  String get sysUserAuxGroupsNone => 'No other groups are available.';

  @override
  String sysUserLockWarning(String username) {
    return 'Locking $username immediately blocks sign-in, including any session this account uses to reach TrueNAS.';
  }

  @override
  String get sysUserShowPassword => 'Show';

  @override
  String get sysUserHidePassword => 'Hide';

  @override
  String get sysUserCreateTitle => 'New user';

  @override
  String get sysUserCreateUsernameLabel => 'Username';

  @override
  String get sysUserCreateFullNameHelper => 'Defaults to the username';

  @override
  String get sysUserCreateDisablePasswordSubtitle =>
      'Create the account without a password.';

  @override
  String get sysUserCreateSmbAccessTitle => 'SMB access';

  @override
  String get sysUserCreateMatchingGroupTitle =>
      'Create a matching primary group';

  @override
  String get sysUserCreateMatchingGroupSubtitle =>
      'Recommended for ordinary accounts.';

  @override
  String get sysUserCreatePrimaryGroupLabel => 'Primary group';

  @override
  String get sysUserCreateAction => 'Create user';

  @override
  String get sysGroupEditReviewTitle => 'Review group changes';

  @override
  String get sysGroupEditTitle => 'Edit group';

  @override
  String sysGroupEditSubtitle(String gid) {
    return 'GID $gid';
  }

  @override
  String get sysGroupNameLabel => 'Group name';

  @override
  String get sysGroupExposeSmbTitle => 'Expose to SMB';

  @override
  String get sysGroupMembersTitle => 'Members';

  @override
  String get sysGroupMembersNone => 'No users are available.';

  @override
  String get sysGroupRenameWarning =>
      'Permissions and shares that reference the old group name keep pointing at it and must be updated separately.';

  @override
  String get sysGroupCreateTitle => 'New group';

  @override
  String get sysGroupCreateAction => 'Create group';

  @override
  String get sysUserValidationUserNotEditable =>
      'Built-in and directory accounts cannot be edited from TrueDock.';

  @override
  String get sysUserValidationEmailInvalid =>
      'Enter a valid email address or leave it empty.';

  @override
  String get sysUserValidationUserUnchanged =>
      'Nothing has changed for this user.';

  @override
  String get sysUserValidationGroupNotEditable =>
      'Built-in and directory groups cannot be edited from TrueDock.';

  @override
  String get sysUserValidationGroupNameRequired => 'Enter a group name.';

  @override
  String get sysUserValidationGroupNameInvalid =>
      'A group name cannot contain spaces, colons, or commas.';

  @override
  String get sysUserValidationGroupUnchanged =>
      'Nothing has changed for this group.';

  @override
  String get sysUserValidationUsernameRequired => 'Enter a username.';

  @override
  String get sysUserValidationUsernameInvalid =>
      'A username must start with a letter or underscore and use only lowercase letters, digits, hyphens, and underscores.';

  @override
  String get sysUserValidationPasswordRequired =>
      'Set a password or disable password sign-in.';

  @override
  String get sysUserValidationPrimaryGroupRequired =>
      'Choose a primary group or let TrueNAS create one.';

  @override
  String get sysUserChangeFullNameCleared => 'Full name cleared';

  @override
  String sysUserChangeFullNameSet(String value) {
    return 'Full name set to \"$value\"';
  }

  @override
  String get sysUserChangeEmailCleared => 'Email address cleared';

  @override
  String sysUserChangeEmailSet(String value) {
    return 'Email set to $value';
  }

  @override
  String sysUserChangeShellSet(String value) {
    return 'Login shell set to $value';
  }

  @override
  String get sysUserChangeSmbEnabled => 'SMB access enabled';

  @override
  String get sysUserChangeSmbDisabled => 'SMB access disabled';

  @override
  String get sysUserChangeAccountLocked =>
      'Account locked — the user can no longer sign in';

  @override
  String get sysUserChangeAccountUnlocked => 'Account unlocked';

  @override
  String get sysUserChangePasswordDisabled => 'Password sign-in disabled';

  @override
  String get sysUserChangePasswordEnabled => 'Password sign-in enabled';

  @override
  String sysUserChangeAuxGroupsSet(int count) {
    return 'Auxiliary groups set to $count group(s)';
  }

  @override
  String sysUserChangeGroupRenamed(String value) {
    return 'Group renamed to $value';
  }

  @override
  String get sysUserChangeGroupExposedSmb => 'Group exposed to SMB';

  @override
  String get sysUserChangeGroupHiddenSmb => 'Group hidden from SMB';

  @override
  String sysUserChangeMembershipSet(int count) {
    return 'Membership set to $count user(s)';
  }

  @override
  String sysUserChangeOtherField(String value) {
    return '$value updated';
  }

  @override
  String get sysUserPasswordReviewTitle => 'Review new password';

  @override
  String sysUserPasswordSetTitle(String username) {
    return 'Set password for $username';
  }

  @override
  String get sysUserPasswordLocalAccount => 'Local account';

  @override
  String get sysUserPasswordDirectoryAccount => 'Directory account';

  @override
  String get sysUserPasswordNewLabel => 'New password';

  @override
  String get sysUserPasswordConfirmLabel => 'Confirm new password';

  @override
  String get sysUserPasswordNotice =>
      'The new password is sent only to the connected TrueNAS server. TrueDock does not save it, log it, or autofill it.';

  @override
  String get sysUserPasswordReviewAction => 'Set password';

  @override
  String get sysUserPasswordReviewServerAction => 'Server action';

  @override
  String get sysUserPasswordReviewServerActionValue => 'Change password';

  @override
  String get sysUserPasswordReviewAccount => 'Account';

  @override
  String get sysUserPasswordReviewSetLabel => 'Password set';

  @override
  String sysUserPasswordReviewSetValue(int count) {
    return 'Yes · $count characters';
  }

  @override
  String sysUserPasswordReviewSessionWarning(String username) {
    return 'Anyone signed in as $username must use the new password afterwards. Active sessions for this account may be ended by TrueNAS.';
  }

  @override
  String get sysUserPasswordErrorEmpty => 'Enter a new password.';

  @override
  String get sysUserPasswordErrorShort => 'Use at least 8 characters.';

  @override
  String get sysUserPasswordErrorMismatch => 'The two passwords do not match.';

  @override
  String get sysApiKeyNone => 'No API keys are registered on this server.';

  @override
  String get sysSessions => 'Active sessions';

  @override
  String get sysSessionNone => 'No user sessions are connected to this server.';

  @override
  String get sysSessionThisDevice => 'This device';

  @override
  String get sysSessionPasswordLogin => 'Password sign-in';

  @override
  String get sysSessionApiKeyLogin => 'API key';

  @override
  String get sysSessionTokenLogin => 'Token';

  @override
  String get sysSessionInsecure => 'Not encrypted';

  @override
  String get sysSessionJustNow => 'Started just now';

  @override
  String sysSessionMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Started $count minutes ago',
      one: 'Started 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String sysSessionHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Started $count hours ago',
      one: 'Started 1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String sysSessionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Started $count days ago',
      one: 'Started 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String sysSessionInternalNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count internal middleware connections are hidden.',
      one: '1 internal middleware connection is hidden.',
    );
    return '$_temp0';
  }

  @override
  String get sysSessionTerminateTooltip => 'End session';

  @override
  String get sysSessionTerminateTitle => 'End this session?';

  @override
  String get sysSessionTerminateAction => 'End session';

  @override
  String sysSessionTerminateConsequence(String origin) {
    return 'The client at $origin is signed out immediately and any request it is making fails.';
  }

  @override
  String get sysSessionTerminateReconnect =>
      'Whoever holds the credential can sign in again. Revoke the API key or change the password to stop that.';

  @override
  String get sysSessionTerminateOthers => 'End all other sessions';

  @override
  String get sysSessionTerminateOthersTitle => 'End every other session?';

  @override
  String sysSessionTerminateOthersConsequence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other sessions are signed out immediately.',
      one: '1 other session is signed out immediately.',
    );
    return '$_temp0';
  }

  @override
  String get sysSessionTerminateOthersKeepsThis =>
      'This device stays signed in.';

  @override
  String get sysSessionTerminated => 'The session was ended.';

  @override
  String get sysSessionTerminateFailed => 'The session could not be ended.';

  @override
  String get sysApiKeyRevoked => 'Revoked';

  @override
  String get sysApiKeyExpired => 'Expired';

  @override
  String sysApiKeyExpiresDate(String date) {
    return 'expires $date';
  }

  @override
  String get sysApiKeyNoExpiry => 'no expiry';

  @override
  String sysApiKeyCreatedDate(String date) {
    return 'created $date';
  }

  @override
  String get sysApiKeyRevokeTooltip => 'Revoke API key';

  @override
  String get sysBootNone => 'No boot environments were reported.';

  @override
  String sysBootPendingNotice(String id) {
    return 'This server will boot into $id the next time it restarts.';
  }

  @override
  String get sysBootStatusRunning => 'Running now';

  @override
  String get sysBootStatusNext => 'Next boot';

  @override
  String get sysBootStatusReplaced => 'Replaced at next boot';

  @override
  String get sysBootStatusKept => 'Kept';

  @override
  String get sysBootActivateAction => 'Use at next boot';

  @override
  String get sysBootOptionsTooltip => 'Boot environment options';

  @override
  String get sysBootAllowRemoval => 'Allow automatic removal';

  @override
  String get sysBootKeep => 'Keep this environment';

  @override
  String get sysBootDelete => 'Delete environment';

  @override
  String get sysGeneralReviewTitle => 'Review changes';

  @override
  String get sysGeneralFormTitle => 'General settings';

  @override
  String get sysGeneralHostnameLabel => 'Hostname';

  @override
  String get sysGeneralDescriptionLabel => 'Description';

  @override
  String get sysGeneralDescriptionHelper =>
      'Shown in the server list and overview.';

  @override
  String get sysGeneralTimezoneTitle => 'Timezone';

  @override
  String get sysGeneralTimezoneLabel => 'Timezone';

  @override
  String get sysGeneralTimezoneHelper =>
      'Could not load choices. Enter an IANA timezone.';

  @override
  String get sysGeneralSyslogTitle => 'Syslog';

  @override
  String get sysGeneralSyslogLabel => 'Syslog level';

  @override
  String get sysGeneralReviewHostname => 'Hostname';

  @override
  String get sysGeneralReviewDescription => 'Description';

  @override
  String get sysGeneralReviewTimezone => 'Timezone';

  @override
  String get sysGeneralReviewSyslog => 'Syslog';

  @override
  String get sysGeneralReviewNone => 'None';

  @override
  String get sysGeneralNoFieldsChanged =>
      'No fields changed. The server keeps its settings.';

  @override
  String get sysGeneralHostnameNotice =>
      'Hostname changes take effect after the server reloads its network configuration. Active sessions are not affected.';

  @override
  String get sysGeneralChangedFields => 'Changed fields';

  @override
  String get sysGeneralValidationHostnameRequired => 'Enter a hostname.';

  @override
  String get sysGeneralValidationTimezoneRequired => 'Enter a timezone.';

  @override
  String get sysSyslogDefault => 'Default (local)';

  @override
  String get sysSyslogDebug => 'Debug';

  @override
  String get sysSyslogInfo => 'Info';

  @override
  String get sysSyslogNotice => 'Notice';

  @override
  String get sysSyslogWarning => 'Warning';

  @override
  String get sysSyslogError => 'Error';

  @override
  String get sysSyslogCritical => 'Critical';

  @override
  String get sysSyslogAlert => 'Alert';

  @override
  String get sysSyslogEmergency => 'Emergency';

  @override
  String get sysRouteReviewTitle => 'Review route';

  @override
  String get sysRouteNewTitle => 'New static route';

  @override
  String get sysRouteEditTitle => 'Edit route';

  @override
  String get sysRouteSaveAction => 'Save route';

  @override
  String get sysRouteDestinationLabel => 'Destination network';

  @override
  String get sysRouteGatewayLabel => 'Gateway';

  @override
  String get sysRouteGatewayHelper => 'Next-hop IP address, e.g. 10.0.0.1';

  @override
  String get sysRouteDescriptionLabel => 'Description';

  @override
  String get sysRouteDescriptionHelper =>
      'Optional note shown in the route list.';

  @override
  String get sysRouteStagedNotice =>
      'The route takes effect only after the staged network changes are committed. TrueDock walks you through commit and check-in once the route is saved.';

  @override
  String get sysRouteReviewDestination => 'Destination';

  @override
  String get sysRouteReviewGateway => 'Gateway';

  @override
  String get sysRouteReviewDescription => 'Description';

  @override
  String get sysRouteReviewNone => 'None';

  @override
  String get sysRouteCommitNotice =>
      'Committing the staged network change briefly disrupts network connectivity. If TrueDock loses its connection after commit, the server rolls the route back automatically.';

  @override
  String get sysRouteValidationDestinationRequired =>
      'Enter a destination network.';

  @override
  String get sysRouteValidationDestinationInvalid =>
      'Enter a destination as A.B.C.D/E.';

  @override
  String get sysRouteValidationGatewayRequired => 'Enter a gateway address.';

  @override
  String get sysRouteValidationGatewayInvalid =>
      'Enter a valid gateway IP address.';

  @override
  String get sysNetCommitApplyAction => 'Apply network changes';

  @override
  String get sysNetCommitCommittingTitle => 'Committing changes…';

  @override
  String get sysNetCommitCommittingBody =>
      'The server is applying the staged network configuration. This may briefly drop the TrueDock connection.';

  @override
  String get sysNetCommitCheckingInTitle => 'Checking in…';

  @override
  String get sysNetCommitCheckingInBody =>
      'Locking the staged changes so the server keeps them.';

  @override
  String get sysNetCommitAppliedTitle => 'Changes applied';

  @override
  String sysNetCommitAppliedBody(String server) {
    return 'The network configuration was committed and checked in on $server.';
  }

  @override
  String get sysNetCommitRolledBackTitle => 'Changes rolled back';

  @override
  String sysNetCommitRolledBackBody(String server) {
    return 'The staged network changes were reverted. No live configuration was changed on $server.';
  }

  @override
  String get sysNetCommitFailedTitle => 'Network commit failed';

  @override
  String get sysNetCommitFailedBody =>
      'The server rejected the commit. No live configuration was changed.';

  @override
  String sysNetCommitWarning(String server) {
    return 'Committing staged network changes briefly disrupts connectivity on $server. If the new configuration breaks the route TrueDock uses, the server rolls everything back automatically at the end of its verification window.';
  }

  @override
  String get sysNetCommitAfterNote =>
      'After the commit succeeds, TrueDock verifies its own connection survived and asks you to check the changes in. Skip the check-in only if you want the server to revert.';

  @override
  String get sysNetCommitPendingChecking =>
      'Checking for staged network changes…';

  @override
  String get sysNetCommitPendingNone =>
      'The server reports no staged network changes. Committing now would do nothing.';

  @override
  String get sysNetCommitPendingStaged =>
      'The server has staged network changes waiting to be committed.';

  @override
  String sysNetCommitPendingAwaitingCheckIn(int seconds) {
    return 'A commit is already in flight. ${seconds}s remain to check in before the server reverts it.';
  }

  @override
  String sysNetCommitPendingClears(String fields) {
    return 'Checking in will clear these network settings: $fields. If one of them is the route TrueDock uses, this connection will drop.';
  }

  @override
  String get sysNetCommitVerifyTitle => 'Verify the connection';

  @override
  String sysNetCommitVerifyBody(String server) {
    return 'The commit finished. TrueDock is checking that it can still reach $server. If this hangs, the new configuration may have broken the route; the server will roll back shortly.';
  }

  @override
  String get sysNetCommitAddressChangedQuestion =>
      'Did you change the network address?';

  @override
  String get sysNetCommitAddressChangedHelp =>
      'If this server moved, enter its new address and test an authenticated connection before checking in.';

  @override
  String get sysNetCommitNewAddress => 'New server address';

  @override
  String get sysNetCommitTestAddress => 'Test new address';

  @override
  String get sysNetCommitTestingAddress => 'Testing new address…';

  @override
  String get sysNetCommitAddressTestPassed =>
      'The new address is reachable and authenticated. You can safely check in.';

  @override
  String get sysNetCommitAddressRequired => 'Enter the new server address.';

  @override
  String get sysNetCommitAddressSaveFailed =>
      'The network change was checked in, but TrueDock could not save the new server address.';

  @override
  String get sysNetCommitTestUnavailable =>
      'Connection testing is unavailable.';

  @override
  String get sysNetCommitNotNow => 'Not now';

  @override
  String get sysNetCommitCommitAction => 'Commit changes';

  @override
  String get sysNetCommitRollbackAction => 'Roll back';

  @override
  String get sysNetCommitCheckInAction => 'Check in';

  @override
  String get sysNetCommitDone => 'Done';

  @override
  String sysInterfaceReviewName(String name) {
    return 'Review $name';
  }

  @override
  String sysInterfaceEditName(String name) {
    return 'Edit $name';
  }

  @override
  String get sysInterfaceStageChange => 'Stage change';

  @override
  String get sysInterfaceStagedNotice =>
      'Interface changes are staged. They take effect only after you commit and check in the pending network changes, and the server reverts them if the connection does not survive.';

  @override
  String get sysInterfaceDescriptionLabel => 'Description';

  @override
  String get sysInterfaceAddressingTitle => 'Addressing';

  @override
  String get sysInterfaceUseDhcpTitle => 'Use DHCP for IPv4';

  @override
  String get sysInterfaceUseDhcpSubtitle =>
      'Static IPv4 addresses are ignored while DHCP is on.';

  @override
  String get sysInterfaceUseIpv6AutoTitle => 'Configure IPv6 automatically';

  @override
  String get sysInterfaceUseIpv6AutoSubtitle =>
      'Accept IPv6 router advertisements for automatic addressing.';

  @override
  String get sysInterfaceIpv6AutoShort => 'IPv6 automatic';

  @override
  String sysInterfaceDhcpConflict(String owner) {
    return '$owner already uses DHCP. TrueNAS allows DHCP on only one interface, so this change will be rejected unless you turn DHCP off there first.';
  }

  @override
  String get sysInterfaceStaticTitle => 'Static addresses';

  @override
  String get sysInterfaceNoStatic => 'No static addresses configured.';

  @override
  String get sysInterfaceAddAddress => 'Add address';

  @override
  String get sysInterfaceAddIpv4Address => 'Add IPv4 address';

  @override
  String get sysInterfaceAddIpv6Address => 'Add IPv6 address';

  @override
  String get sysInterfaceMtuLabel => 'MTU (optional)';

  @override
  String get sysInterfaceMtuHelper => 'Leave blank to keep the current value.';

  @override
  String get sysInterfaceReviewInterface => 'Interface';

  @override
  String get sysInterfaceReviewDescription => 'Description';

  @override
  String get sysInterfaceReviewIpv4 => 'IPv4';

  @override
  String get sysInterfaceReviewIpv6 => 'IPv6';

  @override
  String get sysInterfaceReviewAutomatic => 'Automatic';

  @override
  String get sysInterfaceReviewDisabled => 'Disabled';

  @override
  String get sysInterfaceReviewAddresses => 'Addresses';

  @override
  String get sysInterfaceReviewMtu => 'MTU';

  @override
  String get sysInterfaceReviewDhcp => 'DHCP';

  @override
  String get sysInterfaceReviewStatic => 'Static';

  @override
  String get sysInterfaceReviewAssignedByDhcp => 'Assigned by DHCP';

  @override
  String get sysInterfaceReviewNone => 'None';

  @override
  String get sysInterfaceReviewMtuDefault => 'Unchanged';

  @override
  String get sysInterfaceNothingChanged =>
      'Nothing changed. Saving stages no work.';

  @override
  String get sysInterfaceSessionDrop =>
      'Changing the address of the interface TrueDock is connected through will drop this session when you commit. The server rolls the change back automatically if the check-in does not arrive.';

  @override
  String sysInterfaceIpv6AutoEnabledConsequence(String name) {
    return '$name will configure IPv6 automatically from router advertisements.';
  }

  @override
  String sysInterfaceIpv6AutoDisabledConsequence(String name) {
    return '$name will stop automatic IPv6 configuration. Add a static IPv6 address if this interface still needs IPv6 connectivity.';
  }

  @override
  String get sysInterfaceIpv6AutoLosesStatic =>
      'Turning on automatic IPv6 removes the static IPv6 addresses on this interface.';

  @override
  String get sysInterfaceDhcpLosesRoute =>
      'Switching to DHCP removes the static addresses on this interface. Anything pointing at those addresses loses its route.';

  @override
  String get sysInterfaceEditAddressTooltip => 'Edit address';

  @override
  String get sysInterfaceRemoveAddressTooltip => 'Remove address';

  @override
  String get sysInterfaceEditAddressTitle => 'Edit address';

  @override
  String get sysInterfaceIpv4Label => 'IPv4';

  @override
  String get sysInterfaceIpv6Label => 'IPv6';

  @override
  String get sysInterfaceAddressLabel => 'Address';

  @override
  String get sysInterfacePrefixLabel => 'Prefix length';

  @override
  String get sysInterfacePrefixHelperV6 => '1-128, e.g. 64';

  @override
  String get sysInterfacePrefixHelperV4 => '1-32, e.g. 24';

  @override
  String get sysInterfaceSaveAddress => 'Save address';

  @override
  String sysInterfaceAliasErrorInvalid(String family) {
    return 'Enter a valid $family address.';
  }

  @override
  String sysInterfaceAliasErrorPrefix(int max) {
    return 'Use a prefix between 1 and $max.';
  }

  @override
  String get sysInterfaceValidationMtuRange =>
      'Use an MTU between 68 and 9216.';

  @override
  String get sysInterfaceValidationAliasesRequired =>
      'Add at least one static address, or turn DHCP back on.';

  @override
  String sysInterfaceValidationAliasAddressInvalid(String family) {
    return 'Enter a valid $family address for each alias.';
  }

  @override
  String sysInterfaceValidationAliasPrefixRange(int max, String address) {
    return 'Use a prefix between 1 and $max for $address.';
  }

  @override
  String sysInterfaceValidationAliasDuplicate(String address) {
    return '$address is listed more than once.';
  }

  @override
  String get sysVmDevicesTitle => 'VM devices';

  @override
  String get sysVmDevicesSubtitle =>
      'Disks, network interfaces, and other devices attached to this virtual machine. Removing a disk device does not delete the underlying zvol or image.';

  @override
  String get sysVmDevicesNone => 'No devices are attached to this VM.';

  @override
  String get sysVmDeviceEditTooltip => 'Edit device';

  @override
  String get sysVmDeviceRemoveTooltip => 'Remove device';

  @override
  String get sysVmDeviceAddAction => 'Add device';

  @override
  String get sysVmDeviceEditTitle => 'Edit VM device';

  @override
  String get sysVmDeviceAddTitle => 'Add VM device';

  @override
  String get sysVmDeviceTypeLabel => 'Device type';

  @override
  String get sysVmDevicePathLabel => 'Path';

  @override
  String get sysVmDevicePathHelper =>
      'zvol or image path, e.g. /dev/zvol/tank/vm';

  @override
  String get sysVmDeviceSizeLabel => 'Size (MiB)';

  @override
  String get sysVmDeviceSizeHelper => 'Ignored for existing zvols.';

  @override
  String get sysVmDeviceMacLabel => 'MAC address (optional)';

  @override
  String get sysVmDeviceMacHelper => 'Leave blank for an auto-generated MAC.';

  @override
  String get sysVmDeviceDisplayNotice =>
      'A VNC display device is created with default settings. Edit it on the server for advanced options.';

  @override
  String sysVmDeviceDefaultNotice(String type) {
    return '$type devices use default attributes. Edit on the server for advanced configuration.';
  }

  @override
  String get sysVmDeviceSaveAction => 'Save device';

  @override
  String get sysVmDeviceErrorPathRequired => 'Enter a path for the disk.';

  @override
  String get sysVmDeviceTypeDisk => 'Disk';

  @override
  String get sysVmDeviceTypeCdrom => 'CD-ROM';

  @override
  String get sysVmDeviceTypeNic => 'Network interface';

  @override
  String get sysVmDeviceTypeDisplay => 'Display';

  @override
  String get sysVmDeviceTypeMemory => 'Memory balloon';

  @override
  String get sysVmDeviceTypeUsb => 'USB redirect';

  @override
  String get sysVmDeviceTypePci => 'PCI device';

  @override
  String get sysVmDeviceTypeSerial => 'Serial port';

  @override
  String get sysVmDeviceTypeOther => 'Other';

  @override
  String sysVmDeviceSummaryDiskWithSize(String path, String size) {
    return '$path · $size';
  }

  @override
  String get sysVmDeviceSummaryDiskFallback => 'Disk';

  @override
  String sysVmDeviceSummaryNicWithMac(String mac) {
    return 'NIC · $mac';
  }

  @override
  String sysVmDeviceSummaryDisplay(String mode) {
    return 'Display · $mode';
  }

  @override
  String get sysVmDeviceSummaryCdromEmpty => 'CD-ROM · empty';

  @override
  String sysVmDeviceSummaryCdromWithPath(String path) {
    return 'CD-ROM · $path';
  }

  @override
  String get sysVmConfigReviewTitle => 'Review changes';

  @override
  String get sysVmConfigEditTitle => 'Edit virtual machine';

  @override
  String get sysVmConfigNameLabel => 'Name';

  @override
  String get sysVmConfigDescriptionLabel => 'Description';

  @override
  String get sysVmConfigCpuTitle => 'CPU';

  @override
  String get sysVmConfigSocketsLabel => 'Sockets';

  @override
  String get sysVmConfigCoresLabel => 'Cores';

  @override
  String get sysVmConfigThreadsLabel => 'Threads';

  @override
  String get sysVmConfigMemoryTitle => 'Memory';

  @override
  String get sysVmConfigMemoryLabel => 'Memory (MiB)';

  @override
  String get sysVmConfigMinMemoryLabel => 'Minimum memory (MiB, optional)';

  @override
  String get sysVmConfigMinMemoryHelper =>
      'Used by memory ballooning. Leave blank to disable.';

  @override
  String get sysVmConfigBootCpuTitle => 'Boot & CPU';

  @override
  String get sysVmConfigBootloaderLabel => 'Bootloader';

  @override
  String get sysVmConfigCpuModeLabel => 'CPU mode';

  @override
  String get sysVmConfigBehaviourTitle => 'Behaviour';

  @override
  String get sysVmConfigAutostartTitle => 'Start automatically';

  @override
  String get sysVmConfigAutostartSubtitle =>
      'Boots the VM when the server starts.';

  @override
  String get sysVmConfigEnsureDisplayTitle => 'Ensure display device';

  @override
  String get sysVmConfigEnsureDisplaySubtitle =>
      'Creates a VNC display device if one is missing.';

  @override
  String get sysVmConfigShutdownTimeoutLabel => 'Shutdown timeout (seconds)';

  @override
  String get sysVmConfigShutdownTimeoutHelper =>
      'How long to wait for a graceful shutdown.';

  @override
  String get sysVmConfigReviewName => 'Name';

  @override
  String get sysVmConfigReviewCpu => 'CPU';

  @override
  String sysVmConfigReviewCpuValue(int sockets, int cores, int threads) {
    return '$sockets sockets · $cores cores · $threads threads';
  }

  @override
  String get sysVmConfigReviewMemory => 'Memory';

  @override
  String sysVmConfigReviewMemoryValue(int memory) {
    return '$memory MiB';
  }

  @override
  String sysVmConfigReviewMemoryWithMinValue(int memory, int min) {
    return '$memory MiB (min $min)';
  }

  @override
  String get sysVmConfigReviewBootloader => 'Bootloader';

  @override
  String get sysVmConfigReviewCpuMode => 'CPU mode';

  @override
  String get sysVmConfigReviewAutostart => 'Autostart';

  @override
  String get sysVmConfigEnabled => 'Enabled';

  @override
  String get sysVmConfigDisabled => 'Disabled';

  @override
  String get sysVmConfigReviewShutdown => 'Shutdown';

  @override
  String sysVmConfigReviewShutdownValue(int seconds) {
    return '${seconds}s';
  }

  @override
  String get sysVmConfigNoFieldsChanged =>
      'No fields changed. The VM keeps its current configuration.';

  @override
  String sysVmConfigApplyNotice(String apply) {
    return 'Memory and CPU changes take effect on the next start. $apply';
  }

  @override
  String sysVmConfigApplyRunning(String name) {
    return '$name is currently running; restart it to apply.';
  }

  @override
  String get sysVmConfigApplyStart => 'Start the VM to apply.';

  @override
  String get sysVmConfigChangedFields => 'Changed fields';

  @override
  String get sysVmConfigValidationNameRequired => 'Enter a VM name.';

  @override
  String get sysVmConfigValidationVcpusMinimum => 'Use at least 1 virtual CPU.';

  @override
  String get sysVmConfigValidationCoresMinimum =>
      'Use at least 1 core per socket.';

  @override
  String get sysVmConfigValidationThreadsMinimum =>
      'Use at least 1 thread per core.';

  @override
  String get sysVmConfigValidationMemoryMinimum =>
      'Allocate at least 128 MiB of memory.';

  @override
  String get sysVmConfigValidationMinMemoryExceeds =>
      'Minimum memory cannot exceed memory.';

  @override
  String get sysVmConfigValidationShutdownTimeoutRange =>
      'Shutdown timeout must be between 5 and 300 seconds.';

  @override
  String get sysVmBootloaderUefi => 'UEFI';

  @override
  String get sysVmBootloaderUefiCsm => 'UEFI_CSM';

  @override
  String get sysVmBootloaderGrub => 'GRUB';

  @override
  String get sysVmCpuModeCustom => 'Custom';

  @override
  String get sysVmCpuModeHostModel => 'Host model';

  @override
  String get sysVmCpuModeHostPassthrough => 'Host passthrough';

  @override
  String get sysContainerConfigReviewTitle => 'Review changes';

  @override
  String get sysContainerConfigEditTitle => 'Edit container';

  @override
  String get sysContainerConfigClose => 'Close';

  @override
  String get sysContainerConfigBack => 'Back';

  @override
  String get sysContainerConfigCancel => 'Cancel';

  @override
  String get sysContainerConfigReview => 'Review';

  @override
  String get sysContainerConfigSaveChanges => 'Save changes';

  @override
  String get sysContainerConfigNameLabel => 'Name';

  @override
  String get sysContainerConfigDescriptionLabel => 'Description';

  @override
  String get sysContainerConfigDatasetLabel => 'Dataset';

  @override
  String get sysContainerConfigDatasetHelper =>
      'The dataset is fixed for an existing container.';

  @override
  String get sysContainerConfigResourcesTitle => 'Resources';

  @override
  String get sysContainerConfigVcpusLabel => 'vCPUs (optional)';

  @override
  String get sysContainerConfigVcpusHelper => 'Leave blank for no CPU limit.';

  @override
  String get sysContainerConfigMemoryLabel => 'Memory limit (MiB, optional)';

  @override
  String get sysContainerConfigMemoryHelper =>
      'Leave blank for no memory limit.';

  @override
  String get sysContainerConfigBehaviourTitle => 'Behaviour';

  @override
  String get sysContainerConfigAutostartTitle => 'Start automatically';

  @override
  String get sysContainerConfigAutostartSubtitle =>
      'Starts the container when the server starts.';

  @override
  String sysContainerConfigPreservedNotice(int devices, int volumes, int env) {
    return 'Devices ($devices), volumes ($volumes), and environment ($env) are preserved from the current container and sent unchanged. Editing them is not available in this release.';
  }

  @override
  String sysContainerConfigVolumesEnvNotice(int volumes, int env) {
    return 'Volumes ($volumes) and environment ($env) are preserved from the current container and sent unchanged.';
  }

  @override
  String get sysContainerConfigDevicesTitle => 'Devices';

  @override
  String get sysContainerConfigDevicesHelper =>
      'Block devices passed through to the container. Added devices use the 25.10 passthrough shape; removal re-sends the remaining list.';

  @override
  String get sysContainerConfigNoDevices => 'No devices attached.';

  @override
  String sysContainerConfigDeviceLabel(int index) {
    return 'Device $index';
  }

  @override
  String get sysContainerConfigAddDevice => 'Add device';

  @override
  String get sysContainerConfigRemoveDevice => 'Remove device';

  @override
  String get sysContainerConfigAddDeviceTitle => 'Add device';

  @override
  String get sysContainerConfigAddDeviceHelper =>
      'Choose a host device to pass through to the container. TrueDock sends it using the 25.10 passthrough shape.';

  @override
  String get sysContainerConfigReviewName => 'Name';

  @override
  String get sysContainerConfigReviewDescription => 'Description';

  @override
  String get sysContainerConfigReviewDescriptionNone => 'None';

  @override
  String get sysContainerConfigReviewDataset => 'Dataset';

  @override
  String get sysContainerConfigReviewVcpus => 'vCPUs';

  @override
  String get sysContainerConfigReviewVcpusNone => 'No limit';

  @override
  String get sysContainerConfigReviewMemory => 'Memory';

  @override
  String get sysContainerConfigReviewMemoryNone => 'No limit';

  @override
  String sysContainerConfigReviewMemoryValue(int memory) {
    return '$memory MiB';
  }

  @override
  String get sysContainerConfigReviewAutostart => 'Autostart';

  @override
  String get sysContainerConfigReviewAutostartEnabled => 'Enabled';

  @override
  String get sysContainerConfigReviewAutostartDisabled => 'Disabled';

  @override
  String get sysContainerConfigReviewDevices => 'Devices';

  @override
  String sysContainerConfigReviewDevicesValue(int count) {
    return '$count preserved';
  }

  @override
  String get sysContainerConfigReviewVolumes => 'Volumes';

  @override
  String sysContainerConfigReviewVolumesValue(int count) {
    return '$count preserved';
  }

  @override
  String get sysContainerConfigReviewNoticeBase =>
      'TrueNAS replaces the whole container config. Devices, volumes, and environment are sent unchanged from the current container.';

  @override
  String sysContainerConfigReviewNoticeRunning(Object name) {
    return '$name is running; restart it to apply.';
  }

  @override
  String get sysContainerConfigReviewNoticeStart =>
      'Start the container to apply.';

  @override
  String get sysContainerConfigValidationNameRequired =>
      'Enter a container name.';

  @override
  String get sysContainerConfigValidationDatasetRequired =>
      'Enter a dataset path.';

  @override
  String get sysContainerConfigValidationVcpusMinimum =>
      'Use at least 1 virtual CPU.';

  @override
  String get sysContainerConfigValidationMemoryMinimum =>
      'Allocate at least 16 MiB of memory.';

  @override
  String get coreDestructiveServerLabel => 'Server';

  @override
  String get coreDestructiveTargetLabel => 'Target';

  @override
  String get coreDestructiveConsequencesTitle => 'What happens';

  @override
  String coreDestructiveCannotBeUndone(Object name) {
    return 'This cannot be undone. Type $name to continue.';
  }

  @override
  String get coreDestructiveConfirmNameLabel => 'Confirm name';

  @override
  String get coreDestructiveCancel => 'Cancel';

  @override
  String get storageRenameTitle => 'Rename dataset';

  @override
  String get storageRenameNewNameLabel => 'New name';

  @override
  String get storageRenameRecursiveTitle => 'Rename child datasets';

  @override
  String get storageRenameRecursiveSubtitle =>
      'Applies the new path to every dataset underneath.';

  @override
  String get storageRenameNotice =>
      'TrueNAS unmounts the dataset while it renames it. Shares, apps, and tasks that reference the old path keep pointing at it and must be updated separately.';

  @override
  String get storageRenameAction => 'Rename dataset';

  @override
  String get storageRenameCodeRenameEmpty => 'Enter a new dataset name.';

  @override
  String get storageRenameCodeRenameContainsSlash =>
      'A dataset name cannot contain \"/\".';

  @override
  String get storageRenameCodeRenamePoolRoot =>
      'A pool root dataset cannot be renamed.';

  @override
  String get storageRenameCodeRenameUnchanged =>
      'Enter a name different from the current one.';

  @override
  String get storageDatasetCodeEditNothingChanged =>
      'Nothing has changed for this dataset.';

  @override
  String get storageDatasetTileActionsTooltip => 'Dataset actions';

  @override
  String storageDatasetTileUsed(Object bytes) {
    return '$bytes used';
  }

  @override
  String storageDatasetTileAvailable(Object bytes) {
    return '$bytes available';
  }

  @override
  String storageDatasetTileQuota(Object bytes) {
    return 'quota $bytes';
  }

  @override
  String get storageDatasetTileReadOnly => 'read-only';

  @override
  String get storageDatasetTileClone => 'clone';

  @override
  String get storageDatasetTileTakeSnapshot => 'Take snapshot';

  @override
  String get storageDatasetTileEditProperties => 'Edit properties';

  @override
  String get storageDatasetTileQuotas => 'User and group quotas';

  @override
  String get storageDatasetTileManageAcl => 'Manage ACL';

  @override
  String get storageDatasetAclTitle => 'Dataset ACL';

  @override
  String get storageDatasetAclReviewTitle => 'Review ACL changes';

  @override
  String storageDatasetAclType(Object type) {
    return 'ACL type: $type';
  }

  @override
  String get storageDatasetAclOwnership => 'Ownership';

  @override
  String get storageDatasetAclPermissionType => 'Permission type';

  @override
  String get storageDatasetAclPosix => 'POSIX';

  @override
  String get storageDatasetAclTrueNas => 'TrueNAS ACL';

  @override
  String get storageDatasetAclTypeConversionWarning =>
      'Changing ACL type rebuilds the rules in the selected format. Named users and groups keep their basic access level, but deny and inheritance details that have no equivalent are replaced.';

  @override
  String get storageDatasetAclTypeChangeWarningTitle => 'Change ACL type?';

  @override
  String storageDatasetAclTypeChangeWarningBody(String from, String to) {
    return 'Change from $from to $to? Existing rules will be rebuilt in the new format. Named users and groups keep their basic access level, but incompatible deny, default, and inheritance details can be replaced.';
  }

  @override
  String get storageDatasetAclChangeTypeAction => 'Change ACL type';

  @override
  String storageDatasetAclConfirmOwnership(String user, String group) {
    return 'Ownership changes to $user : $group.';
  }

  @override
  String storageDatasetAclConfirmTypeChange(String from, String to) {
    return 'ACL type changes from $from to $to; rules without an exact equivalent are rebuilt.';
  }

  @override
  String get storageDatasetAclRemove => 'Remove rule';

  @override
  String get storageDatasetAclAdd => 'Add user or group';

  @override
  String storageDatasetAclChoosePrincipal(String type) {
    return 'Choose $type';
  }

  @override
  String storageDatasetAclSearchPrincipal(String type) {
    return 'Search $type';
  }

  @override
  String storageDatasetAclPrincipalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
      zero: 'No accounts',
    );
    return '$_temp0';
  }

  @override
  String storageDatasetAclNoPrincipals(String type) {
    return 'No $type matches this search.';
  }

  @override
  String get storageDatasetAclRecursive => 'Apply recursively';

  @override
  String get storageDatasetAclRecursiveSubtitle =>
      'Replace ACLs on child files and directories.';

  @override
  String get storageDatasetAclRecursiveWarning =>
      'Existing permissions on child files and directories will be replaced.';

  @override
  String get storageDatasetAclTraverse => 'Traverse';

  @override
  String get storageDatasetAclNone => 'No permissions';

  @override
  String get storageDatasetAclRead => 'Read';

  @override
  String get storageDatasetAclWrite => 'Write';

  @override
  String get storageDatasetAclExecute => 'Execute';

  @override
  String get storageDatasetAclModify => 'Modify';

  @override
  String get storageDatasetAclFullControl => 'Full control';

  @override
  String storageDatasetAclRuleCount(int count) {
    return '$count ACL rules';
  }

  @override
  String get storageDatasetAclLoadFailed => 'Could not load the dataset ACL.';

  @override
  String get storageDatasetAclSaveFailed => 'Could not save the dataset ACL.';

  @override
  String storageDatasetAclSetAclError(String detail) {
    return 'setacl error\n$detail';
  }

  @override
  String storageDatasetAclPoolMountpointError(String path) {
    return 'The specified path is a ZFS pool mountpoint. ($path)';
  }

  @override
  String get storageDatasetAclTypeChangeFailed =>
      'Could not change the dataset ACL type. The new ACL rules were not applied.';

  @override
  String get storageDatasetAclSaved => 'Dataset ACL saved.';

  @override
  String get storageDatasetAclConfirmTitle => 'Apply ACL changes?';

  @override
  String get storageDatasetAclConfirmAction => 'Apply ACL';

  @override
  String storageDatasetAclConfirmRules(int count) {
    return 'The dataset ACL will be replaced with $count rules.';
  }

  @override
  String get storageDatasetAclConfirmRecursive =>
      'The ACL will also replace permissions on child files and directories.';

  @override
  String get storageDatasetAclConfirmDatasetOnly =>
      'Only the dataset root ACL will change.';

  @override
  String quotaTitle(String dataset) {
    return 'Quotas on $dataset';
  }

  @override
  String get quotaSubjectUsers => 'Users';

  @override
  String get quotaSubjectGroups => 'Groups';

  @override
  String get quotaNoneUsers => 'No user has written to this dataset yet.';

  @override
  String get quotaNoneGroups => 'No group has written to this dataset yet.';

  @override
  String quotaUsageOnly(String used) {
    return '$used used, no limit';
  }

  @override
  String quotaSpaceOf(String used, String limit) {
    return '$used of $limit';
  }

  @override
  String quotaObjectsOf(String used, String limit) {
    return '$used of $limit files';
  }

  @override
  String quotaObjectsOnly(String used) {
    return '$used files';
  }

  @override
  String get quotaOverLimit => 'Over limit';

  @override
  String get quotaAdd => 'Set a quota';

  @override
  String quotaEditTitle(String name) {
    return 'Quota for $name';
  }

  @override
  String get quotaTargetLabel => 'User or group';

  @override
  String get quotaTargetHelp =>
      'Enter a name or a numeric id. The server rejects accounts it does not recognise.';

  @override
  String get quotaSpaceLabel => 'Space limit';

  @override
  String get quotaObjectLabel => 'File count limit (optional)';

  @override
  String get quotaZeroRemoves =>
      'Leave a field empty to keep it as it is. Enter 0 to remove that limit.';

  @override
  String get quotaApply => 'Apply';

  @override
  String quotaRemoveTitle(String name) {
    return 'Remove the quota for $name?';
  }

  @override
  String get quotaRemoveAction => 'Remove quota';

  @override
  String quotaRemoveConsequence(String name) {
    return '$name can write to this dataset without a limit again. Nothing already stored is deleted.';
  }

  @override
  String get quotaApplied => 'Quota updated.';

  @override
  String get quotaFailed => 'The quota could not be applied.';

  @override
  String get quotaValidationTarget => 'Enter a user or group.';

  @override
  String get quotaValidationReserved =>
      'root cannot be given a quota; TrueNAS refuses it.';

  @override
  String get quotaValidationNegative => 'Enter zero or a positive number.';

  @override
  String get quotaValidationEmpty => 'Set at least one limit.';

  @override
  String get quotaLoadFailed => 'The quotas could not be read.';

  @override
  String get storageDatasetTileRename => 'Rename';

  @override
  String get storageDatasetTileUnlock => 'Unlock';

  @override
  String get storageDatasetTileLock => 'Lock';

  @override
  String get storageDatasetTilePromoteClone => 'Promote clone';

  @override
  String get storageDatasetTileDeleteDataset => 'Delete dataset';

  @override
  String get storageDiskPickerHelper =>
      'Choose a disk that is not already part of a pool. Attaching or replacing starts a resilver; keep the pool online until it finishes.';

  @override
  String get storageDiskPickerEmpty =>
      'No unused disks are available on this server.';

  @override
  String get storageDiskPickerSearchLabel => 'Search disks';

  @override
  String get storageDiskPickerSearchHint => 'Name, serial, or model';

  @override
  String get storageDiskPickerCancel => 'Cancel';

  @override
  String get storageDiskPickerContinue => 'Continue';

  @override
  String storageDiskPickerDiskSubtitle(
    Object size,
    Object model,
    Object serial,
  ) {
    return '$size · $model · $serial';
  }

  @override
  String storageDiskTempNormal(int celsius) {
    return '$celsius degrees Celsius';
  }

  @override
  String storageDiskTempOverLimit(int celsius) {
    return '$celsius degrees Celsius, over the drive limit';
  }

  @override
  String get storageIscsiAuthMgmtTitle => 'CHAP credentials';

  @override
  String get storageIscsiAuthMgmtSubtitle =>
      'iSCSI initiator authentication entries. Target groups reference these by their tag. Secrets are write-only and never shown.';

  @override
  String get storageIscsiAuthMgmtEmpty =>
      'No CHAP credentials are configured on this server.';

  @override
  String get storageIscsiAuthMgmtEmptyUser => '(empty user)';

  @override
  String storageIscsiAuthMgmtTagSubtitle(int tag, Object mode) {
    return 'Tag $tag · $mode';
  }

  @override
  String get storageIscsiAuthMgmtMutualChap => 'Mutual CHAP';

  @override
  String get storageIscsiAuthMgmtOnewayChap => 'One-way CHAP';

  @override
  String get storageIscsiAuthMgmtEdit => 'Edit';

  @override
  String get storageIscsiAuthMgmtDelete => 'Delete';

  @override
  String get storageIscsiAuthMgmtNew => 'New CHAP credential';

  @override
  String get storageSmbAclReviewTitle => 'Review share permissions';

  @override
  String storageSmbAclFormTitle(Object name) {
    return 'Permissions for $name';
  }

  @override
  String get storageSmbAclClose => 'Close';

  @override
  String get storageSmbAclBack => 'Back';

  @override
  String get storageSmbAclCancel => 'Cancel';

  @override
  String get storageSmbAclReview => 'Review';

  @override
  String get storageSmbAclContinue => 'Continue';

  @override
  String get storageSmbAclCurrentPrincipals => 'Current principals';

  @override
  String get storageSmbAclEmpty =>
      'No permissions are set yet. Everyone with filesystem access can reach this share unless you add a rule.';

  @override
  String get storageSmbAclAddPrincipal => 'Add a principal';

  @override
  String get storageSmbAclUser => 'User';

  @override
  String get storageSmbAclGroup => 'Group';

  @override
  String get storageSmbAclAddToList => 'Add to list';

  @override
  String get storageSmbAclDuplicateError =>
      'That principal is already in the list.';

  @override
  String get storageSmbAclReviewServerAction => 'Server action';

  @override
  String get storageSmbAclReviewServerActionValue =>
      'Replace SMB share permissions';

  @override
  String get storageSmbAclReviewShare => 'Share';

  @override
  String get storageSmbAclReviewRules => 'Rules';

  @override
  String storageSmbAclReviewRulesValue(int count) {
    return '$count principal(s)';
  }

  @override
  String storageSmbAclReviewAllow(Object permission) {
    return 'Allow $permission';
  }

  @override
  String storageSmbAclReviewDeny(Object permission) {
    return 'Deny $permission';
  }

  @override
  String get storageSmbAclPermRead => 'read';

  @override
  String get storageSmbAclPermChange => 'change';

  @override
  String get storageSmbAclPermFull => 'full';

  @override
  String get storageSmbAclReviewNotice =>
      'Replacing the share permissions can revoke access for clients that currently use this share. The full list replaces the existing ACL.';

  @override
  String get storageSmbAclRemoveFromList => 'Remove from list';

  @override
  String get storageSmbAclAllowRead => 'Allow Read';

  @override
  String get storageSmbAclAllowChange => 'Allow Change';

  @override
  String get storageSmbAclAllowFull => 'Allow Full';

  @override
  String get storageSmbAclDeny => 'Deny';

  @override
  String get storageSmbAclPrincipalLabel => 'Principal';

  @override
  String get storageSmbAclNoGroups => 'No additional groups are available.';

  @override
  String get storageSmbAclNoUsers => 'No additional users are available.';

  @override
  String get storageNfsReviewTitle => 'Review NFS share';

  @override
  String get storageNfsEditTitle => 'Edit NFS share';

  @override
  String get storageNfsNewTitle => 'New NFS share';

  @override
  String get storageNfsSubtitle => 'Network export and client identity mapping';

  @override
  String get storageNfsClose => 'Close';

  @override
  String get storageNfsBack => 'Back';

  @override
  String get storageNfsCancel => 'Cancel';

  @override
  String get storageNfsReview => 'Review';

  @override
  String get storageNfsSaveChanges => 'Save changes';

  @override
  String get storageNfsCreateShare => 'Create share';

  @override
  String get storageNfsExportPathLabel => 'Export path';

  @override
  String get storageNfsExportPathHelper =>
      'An existing path in a ZFS pool under /mnt/';

  @override
  String get storageNfsCommentLabel => 'Comment';

  @override
  String get storageNfsAuthorizedClients => 'Authorized clients';

  @override
  String get storageNfsNetworksLabel => 'Networks';

  @override
  String get storageNfsNetworksHelper =>
      'One CIDR network per line · empty allows all networks';

  @override
  String get storageNfsHostsLabel => 'Individual hosts';

  @override
  String get storageNfsHostsHelper => 'One IP address or hostname per line';

  @override
  String get storageNfsSecurityTitle => 'Security';

  @override
  String get storageNfsSecurityEmpty =>
      'No explicit schema; TrueNAS applies its default.';

  @override
  String get storageNfsSecuritySelected =>
      'Clients can negotiate any selected security schema.';

  @override
  String get storageNfsMappingTitle => 'Client identity mapping';

  @override
  String get storageNfsMappingSubtitle =>
      'Optional root-user or all-user mapping';

  @override
  String get storageNfsMapRoot => 'Map root client identity';

  @override
  String get storageNfsMapAll => 'Map every client identity';

  @override
  String get storageNfsUserLabel => 'User';

  @override
  String get storageNfsGroupLabel => 'Group';

  @override
  String get storageNfsReadOnlyTitle => 'Read only';

  @override
  String get storageNfsReadOnlySubtitle =>
      'Prevent NFS clients from changing files.';

  @override
  String get storageNfsEnableTitle => 'Enable share';

  @override
  String get storageNfsEnableSubtitle =>
      'Publish the export through the NFS service.';

  @override
  String get storageNfsEnterpriseNotice =>
      'Snapshot directory exposure is an Enterprise-only value. TrueDock preserves the existing setting but cannot enable it on Community Edition.';

  @override
  String get storageNfsReviewPath => 'Path';

  @override
  String get storageNfsReviewClients => 'Clients';

  @override
  String get storageNfsReviewClientsAll => 'All networks and hosts';

  @override
  String get storageNfsReviewAccess => 'Access';

  @override
  String get storageNfsReviewAccessReadOnly => 'Read only';

  @override
  String get storageNfsReviewAccessReadWrite => 'Read and write';

  @override
  String get storageNfsReviewSecurity => 'Security';

  @override
  String get storageNfsReviewSecurityDefault => 'Server default';

  @override
  String get storageNfsReviewRootMapping => 'Root mapping';

  @override
  String get storageNfsReviewAllMapping => 'All mapping';

  @override
  String get storageNfsReviewState => 'State';

  @override
  String get storageNfsReviewStateEnabled => 'Enabled';

  @override
  String get storageNfsReviewStateDisabled => 'Disabled';

  @override
  String get storageNfsMappingNone => 'None';

  @override
  String storageNfsMappingLabel(Object user, Object group) {
    return '$user : $group';
  }

  @override
  String get storageNfsUnrestrictedNotice =>
      'This writable export allows all networks unless filesystem permissions or another network control blocks access.';

  @override
  String get storageNfsMapAllRootNotice =>
      'All NFS client users will be mapped to root. Verify that this broad privilege is intentional.';

  @override
  String get storageNfsReviewNotice =>
      'TrueNAS will validate the path, authorized clients, mappings, and NFS security configuration.';

  @override
  String get storageNfsSecuritySys => 'SYS';

  @override
  String get storageNfsSecurityKrb5 => 'Kerberos';

  @override
  String get storageNfsSecurityKrb5i => 'Kerberos + integrity';

  @override
  String get storageNfsSecurityKrb5p => 'Kerberos + privacy';

  @override
  String get storageNfsValidationPath => 'Enter an existing path under /mnt/.';

  @override
  String get storageNfsValidationNetworksCount =>
      'Use no more than 42 authorized networks.';

  @override
  String get storageNfsValidationNetworksFormat =>
      'Use unique CIDR networks such as 10.0.0.0/24.';

  @override
  String get storageNfsValidationHosts =>
      'Use unique hostnames or IP addresses without spaces.';

  @override
  String get storageNfsValidationMapping =>
      'Choose either root mapping or all-user mapping.';

  @override
  String get storageIscsiAuthReviewTitle => 'Review CHAP credential';

  @override
  String get storageIscsiAuthEditTitle => 'Edit CHAP credential';

  @override
  String get storageIscsiAuthNewTitle => 'New CHAP credential';

  @override
  String get storageIscsiAuthSubtitle => 'iSCSI initiator authentication';

  @override
  String get storageIscsiAuthListEmpty =>
      'iSCSI initiator authentication · None configured';

  @override
  String storageIscsiAuthListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count credentials',
      one: '1 credential',
    );
    return 'iSCSI initiator authentication · $_temp0';
  }

  @override
  String get storageIscsiAuthClose => 'Close';

  @override
  String get storageIscsiAuthBack => 'Back';

  @override
  String get storageIscsiAuthCancel => 'Cancel';

  @override
  String get storageIscsiAuthReview => 'Review';

  @override
  String get storageIscsiAuthSaveChanges => 'Save changes';

  @override
  String get storageIscsiAuthCreateCredential => 'Create credential';

  @override
  String get storageIscsiAuthChapUserLabel => 'CHAP user';

  @override
  String get storageIscsiAuthChapUserHelper =>
      'The username initiators must present.';

  @override
  String get storageIscsiAuthSecretLabel => 'Secret';

  @override
  String get storageIscsiAuthNewSecretLabel => 'New secret (optional)';

  @override
  String get storageIscsiAuthSecretHelper =>
      'The shared secret initiators use to authenticate.';

  @override
  String get storageIscsiAuthNewSecretHelper =>
      'Leave blank to keep the existing secret.';

  @override
  String get storageIscsiAuthShow => 'Show';

  @override
  String get storageIscsiAuthHide => 'Hide';

  @override
  String get storageIscsiAuthConfirmSecretLabel => 'Confirm secret';

  @override
  String get storageIscsiAuthConfirmNewSecretLabel => 'Confirm new secret';

  @override
  String get storageIscsiAuthConfirmNewSecretHelper =>
      'Retype the new secret only when rotating it.';

  @override
  String get storageIscsiAuthMutualTitle => 'Mutual CHAP';

  @override
  String get storageIscsiAuthMutualSubtitle =>
      'The target also authenticates to the initiator with a peer user and peer secret.';

  @override
  String get storageIscsiAuthPeerUserLabel => 'Peer user';

  @override
  String get storageIscsiAuthPeerUserHelper =>
      'The username the target presents to the initiator.';

  @override
  String get storageIscsiAuthPeerSecretLabel => 'Peer secret';

  @override
  String get storageIscsiAuthNewPeerSecretLabel => 'New peer secret (optional)';

  @override
  String get storageIscsiAuthNewPeerSecretHelper =>
      'Leave blank to keep the existing peer secret.';

  @override
  String get storageIscsiAuthConfirmPeerSecretLabel => 'Confirm peer secret';

  @override
  String get storageIscsiAuthConfirmNewPeerSecretLabel =>
      'Confirm new peer secret';

  @override
  String get storageIscsiAuthConfirmNewPeerSecretHelper =>
      'Retype the new peer secret only when rotating it.';

  @override
  String get storageIscsiAuthSecretsNotice =>
      'Secrets are sent only to the connected TrueNAS server over this session. TrueDock does not save, log, or autofill them.';

  @override
  String get storageIscsiAuthReviewTag => 'Tag';

  @override
  String get storageIscsiAuthReviewChapUser => 'CHAP user';

  @override
  String get storageIscsiAuthReviewSecret => 'Secret';

  @override
  String get storageIscsiAuthReviewSecretUnchanged => 'Unchanged';

  @override
  String storageIscsiAuthReviewSecretSet(int count) {
    return 'Set · $count characters';
  }

  @override
  String get storageIscsiAuthReviewMutual => 'Mutual CHAP';

  @override
  String get storageIscsiAuthReviewYes => 'Yes';

  @override
  String get storageIscsiAuthReviewNo => 'No';

  @override
  String get storageIscsiAuthReviewPeerUser => 'Peer user';

  @override
  String get storageIscsiAuthReviewPeerSecret => 'Peer secret';

  @override
  String get storageIscsiAuthReviewNoticeEdit =>
      'Targets and initiator groups that reference this credential start using the updated user and secret immediately. Initiators must be reconfigured to match.';

  @override
  String get storageIscsiAuthReviewNoticeCreate =>
      'Initiators presenting this user and secret can authenticate to target groups that reference this credential.';

  @override
  String get storageIscsiAuthValidationUserRequired => 'Enter a CHAP user.';

  @override
  String get storageIscsiAuthValidationSecretRequired => 'Enter a secret.';

  @override
  String get storageIscsiAuthValidationSecretMismatch =>
      'The two secrets do not match.';

  @override
  String get storageIscsiAuthValidationPeerUserRequired =>
      'Enter a peer user for mutual CHAP.';

  @override
  String get storageIscsiAuthValidationPeerSecretRequired =>
      'Enter a peer secret for mutual CHAP.';

  @override
  String get storageIscsiAuthValidationPeerSecretMismatch =>
      'The two peer secrets do not match.';

  @override
  String get storageIscsiExtentReviewTitle => 'Review iSCSI extent';

  @override
  String get storageIscsiExtentEditTitle => 'Edit iSCSI extent';

  @override
  String get storageIscsiExtentNewTitle => 'New iSCSI extent';

  @override
  String get storageIscsiExtentSubtitle =>
      'Storage presented through a target mapping';

  @override
  String get storageIscsiExtentClose => 'Close';

  @override
  String get storageIscsiExtentBack => 'Back';

  @override
  String get storageIscsiExtentCancel => 'Cancel';

  @override
  String get storageIscsiExtentReview => 'Review';

  @override
  String get storageIscsiExtentSaveChanges => 'Save changes';

  @override
  String get storageIscsiExtentCreateExtent => 'Create extent';

  @override
  String get storageIscsiExtentNameLabel => 'Name';

  @override
  String get storageIscsiExtentNameHelper =>
      'A unique name shown to iSCSI administrators';

  @override
  String get storageIscsiExtentCommentLabel => 'Comment';

  @override
  String get storageIscsiExtentCommentHelper => 'Optional description';

  @override
  String get storageIscsiExtentBackingStore => 'Backing store';

  @override
  String get storageIscsiExtentTypeDisk => 'Device';

  @override
  String get storageIscsiExtentTypeFile => 'File';

  @override
  String get storageIscsiExtentDiskLabel => 'Disk or zvol';

  @override
  String get storageIscsiExtentDiskHelper =>
      'A current choice reported by this TrueNAS server';

  @override
  String get storageIscsiExtentNoDiskChoices =>
      'This server did not return an available disk or zvol for a new extent.';

  @override
  String get storageIscsiExtentOldDiskUnavailable =>
      'The previously selected disk or zvol is no longer offered by this server.';

  @override
  String storageIscsiExtentOldDiskUnavailableNotice(Object disk) {
    return 'The previous backing store $disk is no longer available. Select a current disk or zvol before saving.';
  }

  @override
  String get storageIscsiExtentPathLabel => 'File path';

  @override
  String get storageIscsiExtentPathHelper => 'Absolute path under /mnt/';

  @override
  String get storageIscsiExtentFileAllocateNotice =>
      'A file extent can allocate the requested space in its dataset when TrueNAS creates or grows the backing file.';

  @override
  String get storageIscsiExtentBackingChangeNotice =>
      'Changing the extent type or backing store can disrupt target mappings and connected client I/O.';

  @override
  String get storageIscsiExtentFilesizeLabel => 'File size (bytes)';

  @override
  String get storageIscsiExtentFilesizeHelper =>
      '0 uses the existing file size when supported';

  @override
  String get storageIscsiExtentBlocksizeLabel => 'Logical block size';

  @override
  String get storageIscsiExtentRpmLabel => 'Reported drive speed';

  @override
  String get storageIscsiExtentRpmUnknown => 'Unknown';

  @override
  String get storageIscsiExtentRpmSsd => 'SSD';

  @override
  String get storageIscsiExtentRpm5400 => '5,400 RPM';

  @override
  String get storageIscsiExtentRpm7200 => '7,200 RPM';

  @override
  String get storageIscsiExtentRpm10000 => '10,000 RPM';

  @override
  String get storageIscsiExtentRpm15000 => '15,000 RPM';

  @override
  String get storageIscsiExtentReadOnlyTitle => 'Read only';

  @override
  String get storageIscsiExtentReadOnlySubtitle =>
      'Prevent initiators from writing to this extent.';

  @override
  String get storageIscsiExtentEnabledTitle => 'Enabled';

  @override
  String get storageIscsiExtentEnabledSubtitle =>
      'Allow target mappings to present this extent.';

  @override
  String get storageIscsiExtentAdvancedTitle => 'Advanced';

  @override
  String get storageIscsiExtentAdvancedSubtitle =>
      'Protocol compatibility and device identity';

  @override
  String get storageIscsiExtentPhysicalBlockTitle =>
      'Report physical block size';

  @override
  String get storageIscsiExtentPhysicalBlockSubtitle =>
      'Expose the logical block size as physical.';

  @override
  String get storageIscsiExtentThresholdLabel =>
      'Available capacity threshold (%)';

  @override
  String get storageIscsiExtentThresholdHelper =>
      'Optional percentage from 1 to 99';

  @override
  String get storageIscsiExtentInsecureTpcTitle => 'Allow insecure TPC';

  @override
  String get storageIscsiExtentInsecureTpcSubtitle =>
      'Permit third-party copy without credentials.';

  @override
  String get storageIscsiExtentXenTitle => 'Xen compatibility';

  @override
  String get storageIscsiExtentXenSubtitle =>
      'Use legacy Xen initiator compatibility.';

  @override
  String get storageIscsiExtentSerialLabel => 'Serial';

  @override
  String get storageIscsiExtentSerialHelper => 'Optional SCSI serial number';

  @override
  String get storageIscsiExtentProductIdLabel => 'Product ID';

  @override
  String get storageIscsiExtentProductIdHelper =>
      'Optional SCSI product identifier, up to 16 characters';

  @override
  String get storageIscsiExtentReviewName => 'Name';

  @override
  String get storageIscsiExtentReviewType => 'Type';

  @override
  String get storageIscsiExtentReviewBackingStore => 'Backing store';

  @override
  String get storageIscsiExtentReviewFilesize => 'File size';

  @override
  String storageIscsiExtentReviewFilesizeValue(int count) {
    return '$count bytes';
  }

  @override
  String get storageIscsiExtentReviewBlocksize => 'Logical block size';

  @override
  String storageIscsiExtentReviewBlocksizeValue(int count) {
    return '$count bytes';
  }

  @override
  String get storageIscsiExtentReviewSpeed => 'Reported speed';

  @override
  String get storageIscsiExtentReviewReadOnly => 'Read only';

  @override
  String get storageIscsiExtentReviewEnabled => 'Enabled';

  @override
  String get storageIscsiExtentReviewPhysicalBlock => 'Physical block size';

  @override
  String get storageIscsiExtentReviewThreshold => 'Capacity threshold';

  @override
  String get storageIscsiExtentReviewThresholdNone => 'None';

  @override
  String storageIscsiExtentReviewThresholdValue(int value) {
    return '$value%';
  }

  @override
  String get storageIscsiExtentReviewInsecureTpc => 'Insecure TPC';

  @override
  String get storageIscsiExtentReviewXen => 'Xen compatibility';

  @override
  String get storageIscsiExtentReviewSerial => 'Serial';

  @override
  String get storageIscsiExtentReviewSerialAutomatic => 'Automatic';

  @override
  String get storageIscsiExtentReviewProductId => 'Product ID';

  @override
  String get storageIscsiExtentReviewProductIdDefault => 'Default';

  @override
  String get storageIscsiExtentReviewComment => 'Comment';

  @override
  String get storageIscsiExtentReviewNone => 'None';

  @override
  String get storageIscsiExtentReviewYes => 'Yes';

  @override
  String get storageIscsiExtentReviewNo => 'No';

  @override
  String get storageIscsiExtentBackingChangedNotice =>
      'This changes the extent type or backing store. Existing target mappings can be disrupted; verify mapped LUNs and client I/O after saving.';

  @override
  String storageIscsiExtentFileAllocateReviewNotice(Object path, int bytes) {
    return 'TrueNAS will use $path and may allocate $bytes bytes in that dataset.';
  }

  @override
  String storageIscsiExtentReviewNoticeEdit(Object name) {
    return 'TrueNAS will apply these values to $name. Target associations remain in place unless the server rejects the update.';
  }

  @override
  String get storageIscsiExtentReviewNoticeCreate =>
      'TrueNAS will create this extent. It will not be available to initiators until it is assigned to a target and LUN.';

  @override
  String get storageIscsiExtentValidationNameLength =>
      'Enter a name between 1 and 64 characters.';

  @override
  String get storageIscsiExtentValidationDiskRequired =>
      'Select a disk or zvol.';

  @override
  String get storageIscsiExtentValidationDiskUnavailable =>
      'Select a disk or zvol offered by this server.';

  @override
  String get storageIscsiExtentValidationDiskPathConflict =>
      'A disk extent cannot also use a file path.';

  @override
  String get storageIscsiExtentValidationPathRequired =>
      'Enter a file path under /mnt/.';

  @override
  String get storageIscsiExtentValidationFileDiskConflict =>
      'A file extent cannot also use a disk.';

  @override
  String get storageIscsiExtentValidationFileSizeNegative =>
      'Enter a non-negative file size.';

  @override
  String get storageIscsiExtentValidationFileSizeWholeNumber =>
      'Enter a whole number of bytes.';

  @override
  String get storageIscsiExtentValidationBlockSize =>
      'Choose a supported block size.';

  @override
  String get storageIscsiExtentValidationThresholdRange =>
      'Enter a threshold from 1 to 99 percent.';

  @override
  String get storageIscsiExtentValidationThresholdWholeNumber =>
      'Enter a whole-number percentage.';

  @override
  String get storageIscsiExtentValidationProductIdLength =>
      'Enter a product ID between 1 and 16 characters.';

  @override
  String get storageIscsiTeReviewTitle => 'Review iSCSI association';

  @override
  String get storageIscsiTeEditTitle => 'Edit iSCSI association';

  @override
  String get storageIscsiTeNewTitle => 'New iSCSI association';

  @override
  String get storageIscsiTeSubtitle =>
      'Expose an extent through a target and LUN';

  @override
  String get storageIscsiTeClose => 'Close';

  @override
  String get storageIscsiTeBack => 'Back';

  @override
  String get storageIscsiTeCancel => 'Cancel';

  @override
  String get storageIscsiTeReview => 'Review';

  @override
  String get storageIscsiTeSaveChanges => 'Save changes';

  @override
  String get storageIscsiTeCreateAssociation => 'Create association';

  @override
  String get storageIscsiTeTargetLabel => 'Target';

  @override
  String get storageIscsiTeTargetHelper =>
      'Clients connect through this iSCSI target';

  @override
  String get storageIscsiTeExtentLabel => 'Extent';

  @override
  String get storageIscsiTeExtentHelper =>
      'The storage made available to clients';

  @override
  String get storageIscsiTeAutoLunTitle => 'Assign LUN automatically';

  @override
  String get storageIscsiTeAutoLunSubtitle =>
      'Let TrueNAS choose the next available LUN ID';

  @override
  String get storageIscsiTeLunIdLabel => 'LUN ID';

  @override
  String get storageIscsiTeLunIdHelperEdit =>
      'A concrete nonnegative LUN ID is required when editing';

  @override
  String get storageIscsiTeLunIdHelperCreate =>
      'Use an available nonnegative integer';

  @override
  String get storageIscsiTeMissingResourcesNotice =>
      'The saved target or extent is no longer offered by this server. Select available resources before saving.';

  @override
  String get storageIscsiTeReviewTarget => 'Target';

  @override
  String get storageIscsiTeReviewExtent => 'Extent';

  @override
  String get storageIscsiTeReviewLunId => 'LUN ID';

  @override
  String get storageIscsiTeReviewLunIdAutomatic => 'Automatic';

  @override
  String get storageIscsiTeReviewAccess => 'Access';

  @override
  String get storageIscsiTeReviewAccessReadOnly => 'Read-only';

  @override
  String get storageIscsiTeReviewAccessReadWrite => 'Read and write';

  @override
  String get storageIscsiTeImpactTitle => 'Impact';

  @override
  String get storageIscsiTeImpactNoticeEdit =>
      'Saving reassigns this association. Clients using the target may lose access to the previous mapping and see the updated LUN.';

  @override
  String get storageIscsiTeImpactNoticeCreate =>
      'Creating this association makes the extent visible to initiators that are allowed to connect to the target.';

  @override
  String get storageIscsiTeExposureReadOnly =>
      'This association exposes the extent as read-only storage to authorized clients.';

  @override
  String get storageIscsiTeExposureReadWrite =>
      'This association exposes the extent for read and write access to authorized clients.';

  @override
  String get storageIscsiTeExtentDisabledNotice =>
      'The selected extent is disabled and will not serve storage until it is enabled.';

  @override
  String get storageIscsiTeExtentLockedNotice =>
      'The selected extent is locked and cannot serve data until its backing storage is unlocked.';

  @override
  String get storageIscsiTeValidationTargetInvalid =>
      'Select a valid iSCSI target.';

  @override
  String get storageIscsiTeValidationTargetUnavailable =>
      'Select a target offered by this TrueNAS server.';

  @override
  String get storageIscsiTeValidationExtentInvalid =>
      'Select a valid iSCSI extent.';

  @override
  String get storageIscsiTeValidationExtentUnavailable =>
      'Select an extent offered by this TrueNAS server.';

  @override
  String get storageIscsiTeValidationLunidNegative =>
      'Use a nonnegative LUN ID.';

  @override
  String get storageIscsiTeValidationLunidEmpty =>
      'Enter a nonnegative LUN ID.';

  @override
  String get storageIscsiTeValidationLunidWholeNumber =>
      'Use a whole, nonnegative LUN ID.';

  @override
  String get storageIscsiConfigClose => 'Close';

  @override
  String get storageIscsiConfigBack => 'Back';

  @override
  String get storageIscsiConfigCancel => 'Cancel';

  @override
  String get storageIscsiConfigReview => 'Review';

  @override
  String get storageIscsiPortalReviewTitle => 'Review iSCSI portal';

  @override
  String get storageIscsiPortalNewTitle => 'New iSCSI portal';

  @override
  String get storageIscsiPortalEditTitle => 'Edit iSCSI portal';

  @override
  String get storageIscsiPortalSubtitle =>
      'Static addresses that receive iSCSI connections';

  @override
  String get storageIscsiPortalCreate => 'Create portal';

  @override
  String get storageIscsiPortalSaveChanges => 'Save changes';

  @override
  String get storageIscsiPortalListenAddresses => 'Listen addresses';

  @override
  String get storageIscsiPortalListenHelper =>
      'TrueNAS only offers static addresses that can host a portal.';

  @override
  String get storageIscsiPortalNoAddress =>
      'This server did not return a static listen address. Configure a static interface address before creating a portal.';

  @override
  String storageIscsiPortalUnavailableNotice(Object addresses) {
    return 'TrueNAS no longer offers $addresses as a static listen address. Select a current address before saving.';
  }

  @override
  String get storageIscsiPortalCommentLabel => 'Comment';

  @override
  String get storageIscsiPortalCommentHelper =>
      'Optional label for this portal';

  @override
  String get storageIscsiPortalUpdateNotice =>
      'Targets using this portal will receive connections on the updated address set after TrueNAS applies the change.';

  @override
  String get storageIscsiPortalReviewListen => 'Listen addresses';

  @override
  String get storageIscsiPortalReviewPort => 'Port';

  @override
  String get storageIscsiPortalReviewPortValue => '3260 (managed by TrueNAS)';

  @override
  String get storageIscsiPortalReviewComment => 'Comment';

  @override
  String get storageIscsiPortalReviewNone => 'None';

  @override
  String get storageIscsiPortalReviewNotice =>
      'The portal only exposes a network endpoint. A target, extent, and LUN association are still required before storage is available to clients.';

  @override
  String get storageIscsiPortalValidationListenRequired =>
      'Select at least one listen address.';

  @override
  String get storageIscsiPortalValidationListenFormat =>
      'Use unique valid IPv4 or IPv6 addresses.';

  @override
  String get storageIscsiPortalValidationListenUnavailable =>
      'Select only addresses offered by this TrueNAS server.';

  @override
  String get storageIscsiInitiatorReviewTitle => 'Review initiator group';

  @override
  String get storageIscsiInitiatorNewTitle => 'New initiator group';

  @override
  String get storageIscsiInitiatorEditTitle => 'Edit initiator group';

  @override
  String get storageIscsiInitiatorSubtitle =>
      'Clients authorized to connect to an iSCSI target';

  @override
  String get storageIscsiInitiatorCreate => 'Create group';

  @override
  String get storageIscsiInitiatorSaveChanges => 'Save changes';

  @override
  String get storageIscsiInitiatorLabel => 'Authorized initiators';

  @override
  String get storageIscsiInitiatorHelper =>
      'One IQN or IP address per line · empty allows every initiator';

  @override
  String get storageIscsiInitiatorCommentLabel => 'Comment';

  @override
  String get storageIscsiInitiatorCommentHelper =>
      'Optional label for this client group';

  @override
  String get storageIscsiInitiatorUpdateNotice =>
      'Changing this group affects every target group that references it.';

  @override
  String get storageIscsiInitiatorReviewClients => 'Authorized clients';

  @override
  String get storageIscsiInitiatorReviewAll => 'All initiators';

  @override
  String get storageIscsiInitiatorReviewComment => 'Comment';

  @override
  String get storageIscsiInitiatorReviewNone => 'None';

  @override
  String get storageIscsiInitiatorAllNotice =>
      'This group allows every initiator. Access can still be constrained by target authentication and network controls.';

  @override
  String get storageIscsiInitiatorListedNotice =>
      'TrueNAS will authorize only the listed IQNs or IP addresses when this group is assigned to a target.';

  @override
  String get storageIscsiInitiatorValidationFormat =>
      'Use unique IQNs or IP addresses without whitespace.';

  @override
  String get appsInstallReviewTitle => 'Review installation';

  @override
  String appsInstallReconfigureTitle(Object name) {
    return 'Reconfigure $name';
  }

  @override
  String appsInstallInstallTitle(Object title) {
    return 'Install $title';
  }

  @override
  String appsInstallSubtitle(Object train, Object version) {
    return '$train · $version';
  }

  @override
  String get appsInstallClose => 'Close';

  @override
  String get appsInstallBack => 'Back';

  @override
  String get appsInstallCancel => 'Cancel';

  @override
  String get appsInstallReview => 'Review';

  @override
  String get appsInstallReconfigureAction => 'Reconfigure app';

  @override
  String get appsInstallInstallAction => 'Install app';

  @override
  String get appsInstallDefaultGroup => 'Configuration';

  @override
  String get appsValidationNameFormat =>
      'Use 1–40 lowercase letters, numbers, or internal hyphens.';

  @override
  String get appsValidationUnsupportedField =>
      'This catalog field type is not supported.';

  @override
  String get appsValidationFieldRequired => 'This field is required.';

  @override
  String get appsValidationWholeNumber => 'Enter a whole number.';

  @override
  String appsValidationMinimumValue(int bound) {
    return 'Minimum value is $bound.';
  }

  @override
  String appsValidationMaximumValue(int bound) {
    return 'Maximum value is $bound.';
  }

  @override
  String appsValidationMinimumLength(int bound) {
    return 'Enter at least $bound characters.';
  }

  @override
  String appsValidationMaximumLength(int bound) {
    return 'Enter no more than $bound characters.';
  }

  @override
  String get appsValidationAbsolutePath =>
      'Enter an absolute path beginning with /.';

  @override
  String get appsValidationUriScheme => 'Enter a URI with a scheme.';

  @override
  String get appsValidationIpAddress => 'Enter a valid IPv4 or IPv6 address.';

  @override
  String get appsValidationChooseOption =>
      'Choose one of the available values.';

  @override
  String appsValidationMinimumItems(int bound) {
    return 'Add at least $bound items.';
  }

  @override
  String appsValidationMaximumItems(int bound) {
    return 'Use no more than $bound items.';
  }

  @override
  String get appsValidationListNoSchema =>
      'This list has no editable item schema.';

  @override
  String get appsValidationItemRequired => 'This item is required.';

  @override
  String get appsValidationItemWholeNumber => 'Enter a whole number.';

  @override
  String get appsInstallInstanceInfoLabel => 'App instance';

  @override
  String get appsInstallInstanceNameLabel => 'App instance name';

  @override
  String get appsInstallInstanceNameHelper =>
      'Lowercase letters, numbers, and internal hyphens';

  @override
  String get appsInstallCatalogVersionLabel => 'Catalog version';

  @override
  String get appsInstallVersionUnavailableSuffix => ' · unavailable';

  @override
  String get appsInstallVersionUnsupported =>
      'This catalog version is not supported by the connected server.';

  @override
  String get appsInstallNoQuestions =>
      'This app uses its catalog defaults and needs no additional configuration.';

  @override
  String get appsInstallReviewServerAction => 'Server action';

  @override
  String get appsInstallReviewActionReconfigure => 'Reconfigure app';

  @override
  String get appsInstallReviewActionInstall => 'Install catalog app';

  @override
  String get appsInstallReviewApp => 'App';

  @override
  String get appsInstallReviewInstance => 'Instance';

  @override
  String get appsInstallReviewTrain => 'Train';

  @override
  String get appsInstallReviewVersion => 'Version';

  @override
  String get appsInstallReviewNoticeUpdate =>
      'TrueNAS will revalidate the configuration and recreate the app containers with the new values. Users lose access until the TrueNAS job completes.';

  @override
  String get appsInstallReviewNoticeInstall =>
      'TrueNAS will validate the configuration, pull container images, create app storage, and start the workload as a background Job.';

  @override
  String get appsInstallSecretsNotice =>
      'Sensitive values are masked and are sent only to the connected TrueNAS server. TrueDock does not save this installation form.';

  @override
  String get appsInstallListNoItemType =>
      'This catalog list does not describe its item type.';

  @override
  String get appsInstallRemoveItem => 'Remove item';

  @override
  String get appsInstallAddItem => 'Add item';

  @override
  String get appsInstallSelect => 'Select';

  @override
  String appsInstallOptionCount(int count) {
    return '$count options';
  }

  @override
  String get appsInstallOptionSearch => 'Search options';

  @override
  String get appsInstallNoMatchingOptions => 'No matching options.';

  @override
  String get jobsFilterActive => 'Active';

  @override
  String get jobsActiveDialogTitle => 'Running jobs';

  @override
  String jobsActiveFabTooltip(int count) {
    return 'Running jobs ($count)';
  }

  @override
  String get jobsFilterFailed => 'Failed';

  @override
  String get jobsFilterCompleted => 'Completed';

  @override
  String get jobsFilterAll => 'All';

  @override
  String jobsFilterChipLabel(Object label, int count) {
    return '$label ($count)';
  }

  @override
  String get jobsEmptyActive => 'No jobs are running.';

  @override
  String get jobsEmptyFailed => 'No failed jobs reported.';

  @override
  String get jobsEmptyCompleted => 'No completed jobs reported.';

  @override
  String get jobsEmptyAll => 'No jobs found.';

  @override
  String get jobsAbortDialogTitle => 'Abort this job?';

  @override
  String jobsAbortDialogBody(int id, Object method) {
    return 'TrueDock will ask the server to abort job $id ($method). Work already performed by the job is not rolled back, and the server may complete the job before the abort is processed.';
  }

  @override
  String jobsAbortTarget(int id, Object method) {
    return 'Job $id ($method)';
  }

  @override
  String get jobsAbortConsequenceNoRollback =>
      'Work the job already performed is not rolled back.';

  @override
  String get jobsAbortConsequenceRace =>
      'The server may finish the job before it processes the abort.';

  @override
  String get jobsAbortKeepRunning => 'Keep running';

  @override
  String get jobsAbortConfirm => 'Abort job';

  @override
  String get jobsAbortFailed => 'The abort request failed.';

  @override
  String jobsAbortRequested(int id) {
    return 'Abort requested for job $id.';
  }

  @override
  String get jobsAbortTooltip => 'Abort job';

  @override
  String get jobsDetailJobId => 'Job ID';

  @override
  String get jobsDetailMethod => 'API method';

  @override
  String get jobsMethodPoolScrub => 'Scrub Pool';

  @override
  String get jobsMethodPoolCreate => 'Create Pool';

  @override
  String get jobsMethodPoolExport => 'Export Pool';

  @override
  String get jobsMethodDatasetCreate => 'Create Dataset';

  @override
  String get jobsMethodDatasetUpdate => 'Update Dataset';

  @override
  String get jobsMethodDatasetDelete => 'Delete Dataset';

  @override
  String get jobsMethodSnapshotCreate => 'Create Snapshot';

  @override
  String get jobsMethodSnapshotDelete => 'Delete Snapshot';

  @override
  String get jobsMethodSnapshotRollback => 'Rollback Snapshot';

  @override
  String get jobsMethodSnapshotClone => 'Clone Snapshot';

  @override
  String get jobsMethodSetAcl => 'Set ACL';

  @override
  String get jobsMethodAppInstall => 'Install App';

  @override
  String get jobsMethodAppUpgrade => 'Upgrade App';

  @override
  String get jobsMethodAppRollback => 'Rollback App';

  @override
  String get jobsMethodAppDelete => 'Delete App';

  @override
  String get jobsMethodReplicationRun => 'Run Replication';

  @override
  String get jobsMethodCloudSyncRun => 'Run Cloud Sync';

  @override
  String get jobsMethodRsyncRun => 'Run Rsync';

  @override
  String get jobsMethodSystemUpdate => 'System Update';

  @override
  String get jobsMethodSystemReboot => 'Reboot System';

  @override
  String get jobsMethodSystemShutdown => 'Shut Down System';

  @override
  String get jobsMethodUnknown => 'TrueNAS operation';

  @override
  String get jobsDetailState => 'State';

  @override
  String get jobsDetailProgress => 'Progress';

  @override
  String get jobsDetailStep => 'Step';

  @override
  String get jobsDetailStarted => 'Started';

  @override
  String get jobsDetailFinished => 'Finished';

  @override
  String get jobsDetailDuration => 'Duration';

  @override
  String get jobsDetailLogExcerpt => 'Log excerpt';

  @override
  String get jobsNotAbortable =>
      'This job cannot be aborted from TrueDock. The server did not report it as abortable.';

  @override
  String get jobsStateRunning => 'Running';

  @override
  String get jobsStateWaiting => 'Waiting';

  @override
  String get jobsStateSucceeded => 'Succeeded';

  @override
  String get jobsStateFailed => 'Failed';

  @override
  String get jobsStateAborted => 'Aborted';

  @override
  String get storageSectionPools => 'Pools';

  @override
  String get storageSectionCreatePool => 'Create pool';

  @override
  String get storageSectionNoPools => 'No storage pools found.';

  @override
  String get storageSectionDatasets => 'Datasets';

  @override
  String get storageSectionCreateDataset => 'Create dataset';

  @override
  String get storageSectionNoDatasets => 'No datasets found.';

  @override
  String get storageSnapshotCreated => 'Snapshot created.';

  @override
  String get storageSectionDisks => 'Disks';

  @override
  String get storageSectionNoDisks => 'No disks found.';

  @override
  String get storageSectionShares => 'Shares';

  @override
  String get storageSmbPurposeReadOnly =>
      'Legacy or server-specific SMB purposes are read-only in TrueDock.';

  @override
  String get storageNoSharesFound =>
      'No supported shares or iSCSI resources found.';

  @override
  String get storageScanScrubInProgress => 'Scrub in progress';

  @override
  String get storageScanResilverInProgress => 'Resilver in progress';

  @override
  String get storageCreateShort => 'Create';

  @override
  String get storageDiskSolidState => 'Solid state';

  @override
  String get storageDiskUnavailable => 'Unavailable';

  @override
  String get storageEditSmbPermissions => 'Edit SMB permissions';

  @override
  String get storageEditSharePermissions => 'Edit share permissions';

  @override
  String get storageDeleteShareTooltip => 'Delete share';

  @override
  String get storageDeleteExtentTooltip => 'Delete extent';

  @override
  String get storageDeleteTooltip => 'Delete';

  @override
  String storageIscsiLunSubtitle(Object lun) {
    return 'iSCSI LUN · $lun';
  }

  @override
  String get storageLunAutomatic => 'Automatic';

  @override
  String get storageBadgeLocked => 'LOCKED';

  @override
  String get storageBadgeEnabled => 'ENABLED';

  @override
  String get storageBadgeDisabled => 'DISABLED';

  @override
  String get storageDeleteExtentSheetTitle => 'Delete extent';

  @override
  String get storageDeleteExtentAlsoDestroy =>
      'Also destroy the backing storage';

  @override
  String get storageDetailTarget => 'Target';

  @override
  String get storageDetailMode => 'Mode';

  @override
  String get storageDetailGroups => 'Groups';

  @override
  String get storageDetailType => 'Type';

  @override
  String get storageDetailBacking => 'Backing';

  @override
  String get storageDetailCapacity => 'Capacity';

  @override
  String get storageDetailBlockSize => 'Block size';

  @override
  String storageDetailBlockSizeValue(int bytes) {
    return '$bytes B';
  }

  @override
  String get storageDetailAccess => 'Access';

  @override
  String get storageDetailAccessReadOnly => 'Read only';

  @override
  String get storageDetailAccessReadWrite => 'Read and write';

  @override
  String get storageDetailState => 'State';

  @override
  String get storageDetailStateLocked => 'Locked';

  @override
  String get storageDetailStateEnabled => 'Enabled';

  @override
  String get storageDetailStateDisabled => 'Disabled';

  @override
  String get storageCreateSnapshotTitle => 'Create snapshot';

  @override
  String get storageSnapshotNameLabel => 'Snapshot name';

  @override
  String get storageSnapshotCreating => 'Creating…';

  @override
  String get storageActionFailed => 'The TrueNAS operation failed.';

  @override
  String get storageServerFallbackName => 'this TrueNAS server';

  @override
  String storageAclConfirmTitle(Object name) {
    return 'Replace permissions for $name?';
  }

  @override
  String get storageAclConfirmAction => 'Replace permissions';

  @override
  String storageAclConfirmRules(int count) {
    return 'The full list replaces the existing ACL. $count rule(s) take effect when the TrueNAS job completes.';
  }

  @override
  String get storageAclConfirmUnlisted =>
      'Clients that currently access the share and are no longer listed lose access.';

  @override
  String get storageDeleteDatasetTitle => 'Delete dataset?';

  @override
  String get storageDeleteDatasetAction => 'Delete dataset';

  @override
  String storageDeleteDatasetData(Object size) {
    return 'All $size of data in this dataset is destroyed and cannot be recovered.';
  }

  @override
  String storageDeleteDatasetChildren(int count) {
    return '$count child dataset(s) are destroyed with it.';
  }

  @override
  String storageDeleteDatasetSnapshots(int count) {
    return '$count snapshot(s) of this path are destroyed.';
  }

  @override
  String storageDeleteDatasetShares(int count, Object path) {
    return '$count share(s) point at $path and stop serving data.';
  }

  @override
  String get storageDeleteDatasetNoteLeaf =>
      'Applications writing to this path will start failing.';

  @override
  String get storageDeleteDatasetNoteRecursive =>
      'Child datasets are removed recursively, and busy datasets are unmounted so the delete can proceed.';

  @override
  String get storageDeleteSmbTitle => 'Delete SMB share?';

  @override
  String get storageDeleteShareAction => 'Delete share';

  @override
  String get storageDeleteSmbClients =>
      'Connected SMB clients lose access immediately.';

  @override
  String get storageDeleteSmbConfig =>
      'The share configuration, including its ACL, is removed.';

  @override
  String get storageDeleteShareNote =>
      'The dataset and its files are not deleted.';

  @override
  String get storageDeleteNfsTitle => 'Delete NFS share?';

  @override
  String get storageDeleteNfsClients =>
      'NFS clients with this export mounted lose access.';

  @override
  String get storageDeleteNfsRules =>
      'Host, network, and mapping rules for the export are removed.';

  @override
  String storageIscsiPortalFallbackLabel(int tag) {
    return 'Portal $tag';
  }

  @override
  String get storageDeletePortalTitle => 'Delete iSCSI portal?';

  @override
  String get storageDeletePortalAction => 'Delete portal';

  @override
  String get storageDeletePortalInitiators =>
      'Initiators reaching targets through these addresses disconnect.';

  @override
  String get storageDeleteIscsiInUse =>
      'TrueNAS refuses the delete while a target still uses it.';

  @override
  String get storageDeletePortalNote =>
      'Extents and their backing storage are not affected.';

  @override
  String storageIscsiInitiatorFallbackLabel(int id) {
    return 'Initiator group $id';
  }

  @override
  String get storageDeleteInitiatorTitle => 'Delete initiator group?';

  @override
  String get storageDeleteInitiatorAction => 'Delete group';

  @override
  String get storageDeleteInitiatorAllowList =>
      'Targets restricted to this group lose their allow list.';

  @override
  String get storageDeleteTargetTitle => 'Delete iSCSI target?';

  @override
  String get storageDeleteTargetAction => 'Delete target';

  @override
  String get storageDeleteTargetInitiators =>
      'Connected initiators lose their block devices immediately, which can corrupt in-flight writes.';

  @override
  String storageDeleteTargetLuns(int count) {
    return '$count LUN association(s) are removed with the target.';
  }

  @override
  String get storageDeleteTargetNote =>
      'Extents keep their data and can be attached to another target.';

  @override
  String get storageDestroyExtentTitle => 'Destroy extent data?';

  @override
  String get storageDeleteExtentTitle => 'Delete iSCSI extent?';

  @override
  String get storageDeleteExtentDestroyAction => 'Delete and destroy';

  @override
  String get storageDeleteExtentAction => 'Delete extent';

  @override
  String storageDeleteExtentBackingDestroyed(Object type, Object store) {
    return 'The backing $type $store is destroyed and cannot be recovered.';
  }

  @override
  String get storageDeleteExtentBackingKept =>
      'The extent is removed but its backing storage is kept.';

  @override
  String storageDeleteExtentLuns(int count) {
    return '$count LUN association(s) are removed with the extent.';
  }

  @override
  String get storageDeleteExtentInitiators =>
      'Initiators using this LUN lose their block device at once.';

  @override
  String storageIscsiAssociationLabel(int targetId, int extentId) {
    return 'Target $targetId → extent $extentId';
  }

  @override
  String get storageRemoveLunTitle => 'Remove LUN association?';

  @override
  String get storageRemoveLunAction => 'Remove association';

  @override
  String get storageRemoveLunDisappears =>
      'The LUN disappears from the target and initiators lose that block device.';

  @override
  String get storageRemoveLunExtentKept =>
      'The extent and its data are kept and can be reattached.';

  @override
  String get storageLockDatasetTitle => 'Lock dataset?';

  @override
  String get storageLockDatasetAction => 'Lock dataset';

  @override
  String get storageLockDatasetKey =>
      'The encryption key is evicted and the data becomes unreadable until it is unlocked again.';

  @override
  String storageLockDatasetChildren(int count) {
    return '$count child dataset(s) sharing this key are locked too.';
  }

  @override
  String storageLockDatasetShares(int count) {
    return '$count share(s) on this path stop serving data.';
  }

  @override
  String get storageLockDatasetNotePassphrase =>
      'You will need the passphrase to unlock it again.';

  @override
  String get storageLockDatasetNoteKey =>
      'You will need the hex key to unlock it again.';

  @override
  String storagePromoteTitle(Object name) {
    return 'Promote $name?';
  }

  @override
  String get storagePromoteAction => 'Promote clone';

  @override
  String storagePromoteOwnership(Object name, Object origin) {
    return '$name stops depending on $origin and takes ownership of the data they share.';
  }

  @override
  String storagePromoteReverses(Object originDataset, Object origin) {
    return 'The dependency reverses: $originDataset becomes the dependent dataset, so $origin and the snapshots before it can then be deleted.';
  }

  @override
  String get storagePromoteSpace =>
      'No data is copied or deleted, but space previously charged to the original is charged to this dataset afterwards.';

  @override
  String storageCreatePoolTitle(Object name) {
    return 'Create pool $name?';
  }

  @override
  String get storageCreatePoolAction => 'Create pool';

  @override
  String storageCreatePoolDisks(int count) {
    return '$count disk(s) are formatted. Existing data on them is unrecoverable.';
  }

  @override
  String get storageCreatePoolNoRedundancy =>
      'The pool has no redundancy. A single disk failure loses the entire pool.';

  @override
  String get storageCreatePoolEncrypted =>
      'The pool is encrypted at rest. Keep the recovery key safe or the data is unrecoverable.';

  @override
  String get storageCreatePoolNote =>
      'This is a destructive operation with no undo.';

  @override
  String get storageStopScrubTitle => 'Stop the scrub?';

  @override
  String get storageStopScrubAction => 'Stop scrub';

  @override
  String get storageStopScrubProgress =>
      'Scrub progress is discarded and must start over.';

  @override
  String get storageStopScrubUnverified =>
      'Blocks not yet verified stay unchecked until the next run.';

  @override
  String get storageScrubActionPause => 'Pause scrub';

  @override
  String get storageScrubActionResume => 'Resume scrub';

  @override
  String get storageScrubActionStop => 'Stop scrub';

  @override
  String storageOfflineTitle(Object name) {
    return 'Take $name offline?';
  }

  @override
  String get storageOfflineAction => 'Take offline';

  @override
  String storageOfflineDegraded(Object pool) {
    return '$pool runs degraded and loses the redundancy this device provides.';
  }

  @override
  String get storageOfflineSecondFailure =>
      'A second device failure while degraded can lose the entire pool.';

  @override
  String get storageOfflineNote =>
      'Bring the device back online or replace it as soon as possible.';

  @override
  String storageAttachTitle(Object disk) {
    return 'Attach $disk to a pool member?';
  }

  @override
  String get storageAttachAction => 'Attach disk';

  @override
  String get storageAttachResilver =>
      'Attaching to a mirror starts a resilver. The pool stays online but disk bandwidth is consumed until it finishes.';

  @override
  String storageAttachJoins(Object disk, Object pool) {
    return '$disk joins the selected vdev in $pool and is no longer available as a spare or for another pool.';
  }

  @override
  String get storageAttachNote =>
      'Keep the pool online until the resilver completes.';

  @override
  String storageReplaceTitle(Object member, Object disk) {
    return 'Replace $member with $disk?';
  }

  @override
  String get storageReplaceAction => 'Replace disk';

  @override
  String get storageReplaceResilver =>
      'A resilver copies data onto the new disk. The pool stays online but runs degraded until the resilver finishes.';

  @override
  String storageReplaceRemoved(Object member, Object pool) {
    return '$member is removed from $pool once the resilver completes and is safe to remove.';
  }

  @override
  String get storageReplaceForce =>
      'Forcing removes the old disk even if it is still being read. Use only when the disk has failed.';

  @override
  String get storageReplaceNote =>
      'Do not remove the old disk until the resilver finishes.';

  @override
  String get storageDestroyPoolTitle => 'Destroy pool?';

  @override
  String get storageExportPoolTitle => 'Export pool?';

  @override
  String get storageDestroyPoolAction => 'Destroy pool';

  @override
  String get storageExportPoolAction => 'Export pool';

  @override
  String storageDestroyPoolWiped(Object pool, Object size) {
    return 'Every disk in $pool is wiped. $size of data is unrecoverable.';
  }

  @override
  String get storageExportPoolDetached =>
      'The pool is detached from this server. The disks keep their data and can be imported again.';

  @override
  String storageExportPoolDatasets(int count) {
    return '$count dataset(s) stop being served immediately.';
  }

  @override
  String get storageExportPoolSharesDeleted =>
      'Shares and tasks that reference this pool are deleted.';

  @override
  String get storageDestroyPoolNote =>
      'There is no undo and no recovery path for this action.';

  @override
  String get storageExportPoolNote =>
      'Applications and shares using this pool will start failing.';

  @override
  String storagePoolFailedCreate(Object name) {
    return 'TrueNAS could not create $name.';
  }

  @override
  String storagePoolSuccessCreate(Object name) {
    return '$name is being created.';
  }

  @override
  String storagePoolFailedScrub(Object pool) {
    return 'TrueNAS could not change the scrub for $pool.';
  }

  @override
  String storagePoolSuccessScrubStarted(Object pool) {
    return 'Scrub started for $pool.';
  }

  @override
  String storagePoolSuccessScrubAction(Object action, Object pool) {
    return '$action requested for $pool.';
  }

  @override
  String storagePoolFailedOnline(Object name) {
    return 'TrueNAS could not bring $name online.';
  }

  @override
  String storagePoolFailedOffline(Object name) {
    return 'TrueNAS could not take $name offline.';
  }

  @override
  String storagePoolSuccessOnline(Object name) {
    return '$name is coming back online.';
  }

  @override
  String storagePoolSuccessOffline(Object name) {
    return '$name was taken offline.';
  }

  @override
  String storagePoolFailedAttach(Object disk, Object pool) {
    return 'TrueNAS could not attach $disk to $pool.';
  }

  @override
  String storagePoolSuccessAttach(Object disk, Object pool) {
    return 'Resilver started for $disk in $pool.';
  }

  @override
  String storagePoolFailedReplace(Object member, Object pool) {
    return 'TrueNAS could not replace $member in $pool.';
  }

  @override
  String storagePoolSuccessReplace(Object disk, Object pool) {
    return 'Resilver started onto $disk for $pool.';
  }

  @override
  String storagePoolFailedExport(Object pool) {
    return 'TrueNAS could not export $pool.';
  }

  @override
  String storagePoolSuccessDestroying(Object pool) {
    return '$pool is being destroyed.';
  }

  @override
  String storagePoolSuccessExporting(Object pool) {
    return '$pool is being exported.';
  }

  @override
  String get storageChapCreateTitle => 'Create CHAP credential?';

  @override
  String get storageChapCreateAction => 'Create credential';

  @override
  String get storageChapCreateStored =>
      'A new CHAP user and secret are stored on the server. Initiators can authenticate with them once a target group references this credential.';

  @override
  String get storageChapCreateMutual =>
      'Mutual CHAP also stores a peer user and peer secret.';

  @override
  String get storageChapCreateNote =>
      'The secret is sent only over this session and is not saved or logged by TrueDock.';

  @override
  String storageChapUpdateTitle(Object user) {
    return 'Save changes to $user?';
  }

  @override
  String get storageChapUpdateAction => 'Save changes';

  @override
  String get storageChapUpdateImmediate =>
      'Target groups that reference this credential start using the updated user and secret immediately. Initiators must be reconfigured to match or they fail to authenticate.';

  @override
  String get storageChapUpdateRotated =>
      'The CHAP secret is rotated to the new value you entered.';

  @override
  String get storageChapUpdateNoteRotating =>
      'The new secret is sent only over this session and is not saved or logged by TrueDock.';

  @override
  String get storageChapUpdateNoteUnchanged =>
      'The existing secret is left unchanged on the server.';

  @override
  String storageChapDeleteTitle(Object user) {
    return 'Delete CHAP credential $user?';
  }

  @override
  String get storageChapDeleteAction => 'Delete credential';

  @override
  String get storageChapDeleteAuth =>
      'Target groups that reference this credential by tag lose authentication. Initiators presenting this user are rejected.';

  @override
  String get storageChapDeleteSecret =>
      'The stored secret is removed from the server.';

  @override
  String get storageChapDeleteNote =>
      'Update or remove target groups that use this tag before deleting.';

  @override
  String storageDatasetFailedUpdate(Object name) {
    return 'TrueNAS could not update $name.';
  }

  @override
  String storageDatasetSuccessUpdate(Object name) {
    return 'Updated $name.';
  }

  @override
  String storageDatasetFailedRename(Object name) {
    return 'TrueNAS could not rename $name.';
  }

  @override
  String storageDatasetSuccessRename(Object name) {
    return 'Renamed to $name.';
  }

  @override
  String storageDatasetFailedDelete(Object name) {
    return 'TrueNAS could not delete $name.';
  }

  @override
  String storageDatasetSuccessDelete(Object name) {
    return 'Deleted $name.';
  }

  @override
  String storageDatasetFailedLock(Object name) {
    return 'TrueNAS could not lock $name.';
  }

  @override
  String storageDatasetSuccessLock(Object name) {
    return 'Locked $name.';
  }

  @override
  String storageDatasetFailedPromote(Object name) {
    return 'TrueNAS could not promote $name.';
  }

  @override
  String storageDatasetSuccessPromote(Object name) {
    return 'Promoted $name.';
  }

  @override
  String storageDatasetFailedUnlock(Object name) {
    return 'TrueNAS could not unlock $name.';
  }

  @override
  String storageDatasetSuccessUnlock(Object name) {
    return 'Unlocked $name.';
  }

  @override
  String get storageSmbFailedLoadPresets =>
      'TrueNAS could not load SMB presets.';

  @override
  String get storageSmbFailedValidate =>
      'TrueNAS could not validate the SMB share.';

  @override
  String get storageSmbFailedLoadAcl =>
      'TrueNAS could not load the share permissions.';

  @override
  String storageSmbFailedCreate(Object name) {
    return 'TrueNAS could not create $name.';
  }

  @override
  String storageSmbSuccessCreate(Object name) {
    return 'Created SMB share $name.';
  }

  @override
  String storageSmbFailedUpdate(Object name) {
    return 'TrueNAS could not update $name.';
  }

  @override
  String storageSmbSuccessUpdate(Object name) {
    return 'Updated SMB share $name.';
  }

  @override
  String get storageSmbFailedSetAcl =>
      'TrueNAS could not replace the SMB share permissions.';

  @override
  String storageSmbSuccessSetAcl(Object name) {
    return 'Replaced the permissions for $name.';
  }

  @override
  String storageSmbFailedDelete(Object name) {
    return 'TrueNAS could not delete $name.';
  }

  @override
  String storageSmbSuccessDelete(Object name) {
    return 'Deleted SMB share $name.';
  }

  @override
  String storageNfsFailedCreate(Object path) {
    return 'TrueNAS could not create $path.';
  }

  @override
  String storageNfsSuccessCreate(Object path) {
    return 'Created NFS share $path.';
  }

  @override
  String storageNfsFailedUpdate(Object path) {
    return 'TrueNAS could not update $path.';
  }

  @override
  String storageNfsSuccessUpdate(Object path) {
    return 'Updated NFS share $path.';
  }

  @override
  String storageNfsFailedDelete(Object path) {
    return 'TrueNAS could not delete $path.';
  }

  @override
  String storageNfsSuccessDelete(Object path) {
    return 'Deleted NFS share $path.';
  }

  @override
  String get storageIscsiFailedLoadPortals =>
      'TrueNAS could not load portal addresses.';

  @override
  String get storageIscsiFailedValidateTarget =>
      'TrueNAS could not validate the target name.';

  @override
  String get storageIscsiFailedLoadExtents =>
      'TrueNAS could not load extent choices.';

  @override
  String get storageIscsiFailedCreatePortal =>
      'TrueNAS could not create the iSCSI portal.';

  @override
  String get storageIscsiSuccessCreatePortal => 'Created the iSCSI portal.';

  @override
  String storageIscsiFailedUpdatePortal(int tag) {
    return 'TrueNAS could not update portal $tag.';
  }

  @override
  String storageIscsiSuccessUpdatePortal(int tag) {
    return 'Updated portal $tag.';
  }

  @override
  String storageIscsiFailedDeletePortal(Object label) {
    return 'TrueNAS could not delete $label.';
  }

  @override
  String storageIscsiSuccessDeletePortal(Object label) {
    return 'Deleted $label.';
  }

  @override
  String get storageIscsiFailedCreateInitiator =>
      'TrueNAS could not create the initiator group.';

  @override
  String get storageIscsiSuccessCreateInitiator =>
      'Created the initiator group.';

  @override
  String storageIscsiFailedUpdateInitiator(int id) {
    return 'TrueNAS could not update initiator group $id.';
  }

  @override
  String storageIscsiSuccessUpdateInitiator(int id) {
    return 'Updated initiator group $id.';
  }

  @override
  String storageIscsiFailedDeleteInitiator(Object label) {
    return 'TrueNAS could not delete $label.';
  }

  @override
  String storageIscsiSuccessDeleteInitiator(Object label) {
    return 'Deleted $label.';
  }

  @override
  String storageIscsiFailedCreateTarget(Object name) {
    return 'TrueNAS could not create target $name.';
  }

  @override
  String storageIscsiSuccessCreateTarget(Object name) {
    return 'Created target $name.';
  }

  @override
  String storageIscsiFailedUpdateTarget(Object name) {
    return 'TrueNAS could not update target $name.';
  }

  @override
  String storageIscsiSuccessUpdateTarget(Object name) {
    return 'Updated target $name.';
  }

  @override
  String storageIscsiFailedDeleteTarget(Object name) {
    return 'TrueNAS could not delete $name.';
  }

  @override
  String storageIscsiSuccessDeleteTarget(Object name) {
    return 'Deleted target $name.';
  }

  @override
  String storageIscsiFailedCreateExtent(Object name) {
    return 'TrueNAS could not create extent $name.';
  }

  @override
  String storageIscsiSuccessCreateExtent(Object name) {
    return 'Created extent $name.';
  }

  @override
  String storageIscsiFailedUpdateExtent(Object name) {
    return 'TrueNAS could not update extent $name.';
  }

  @override
  String storageIscsiSuccessUpdateExtent(Object name) {
    return 'Updated extent $name.';
  }

  @override
  String storageIscsiFailedDeleteExtent(Object name) {
    return 'TrueNAS could not delete $name.';
  }

  @override
  String storageIscsiSuccessDeleteExtent(Object name) {
    return 'Deleted extent $name.';
  }

  @override
  String get storageIscsiFailedAssociate =>
      'TrueNAS could not associate the target and extent.';

  @override
  String get storageIscsiSuccessAssociate =>
      'Associated the target and extent.';

  @override
  String storageIscsiFailedUpdateLun(Object lun) {
    return 'TrueNAS could not update LUN $lun.';
  }

  @override
  String storageIscsiSuccessUpdateLun(Object lun) {
    return 'Updated LUN $lun.';
  }

  @override
  String storageIscsiFailedRemoveLun(Object label) {
    return 'TrueNAS could not remove $label.';
  }

  @override
  String storageIscsiSuccessRemoveLun(Object label) {
    return 'Removed $label.';
  }

  @override
  String storageIscsiFailedCreateChap(Object user) {
    return 'TrueNAS could not create the CHAP credential for $user.';
  }

  @override
  String storageIscsiSuccessCreateChap(Object user) {
    return 'Created the CHAP credential for $user.';
  }

  @override
  String storageIscsiFailedUpdateChap(Object user) {
    return 'TrueNAS could not update the CHAP credential for $user.';
  }

  @override
  String storageIscsiSuccessUpdateChap(Object user) {
    return 'Updated the CHAP credential for $user.';
  }

  @override
  String storageIscsiFailedDeleteChap(Object user) {
    return 'TrueNAS could not delete the CHAP credential for $user.';
  }

  @override
  String storageIscsiSuccessDeleteChap(Object user) {
    return 'Deleted the CHAP credential for $user.';
  }

  @override
  String get storageUnlockTitle => 'Unlock dataset';

  @override
  String get storageUnlockPassphraseLabel => 'Passphrase';

  @override
  String get storageUnlockHexKeyLabel => 'Hex key';

  @override
  String get storageUnlockPassphraseHelper =>
      'The passphrase set when this dataset was encrypted.';

  @override
  String get storageUnlockHexKeyHelper =>
      'The 64-character hex key for this dataset.';

  @override
  String get storageUnlockShow => 'Show';

  @override
  String get storageUnlockHide => 'Hide';

  @override
  String get storageUnlockChildrenTitle => 'Unlock child datasets';

  @override
  String get storageUnlockChildrenSubtitle =>
      'Children that share this encryption key are unlocked too.';

  @override
  String get storageUnlockSecretNotice =>
      'TrueDock sends this secret to the server to unlock the dataset and does not store it.';

  @override
  String get storageUnlockAction => 'Unlock';

  @override
  String get storageUnlockErrorPassphraseRequired =>
      'Enter the passphrase for this dataset.';

  @override
  String get storageUnlockErrorHexKeyRequired =>
      'Enter the hex key for this dataset.';

  @override
  String get storageUnlockErrorHexKeyFormat =>
      'A hex key contains only 0-9 and a-f.';

  @override
  String get storageDatasetEditComments => 'Comments';

  @override
  String get storageDatasetEditInherit => 'Inherit';

  @override
  String get storageDatasetEditSetHere => 'Set here';

  @override
  String get coreLandingNoFakeData =>
      'TrueDock never fills server screens with made-up data.';

  @override
  String get coreLandingConnectServer => 'Connect server';

  @override
  String get coreLandingManage => 'Manage';

  @override
  String coreLandingConnectToLoad(String title) {
    return 'Connect to load $title';
  }

  @override
  String get dropdownSelect => 'Select';

  @override
  String dropdownOptionCount(int count) {
    return '$count options';
  }

  @override
  String get dropdownSearch => 'Search options';

  @override
  String get dropdownNoMatches => 'No matching options.';

  @override
  String storagePoolMemberSummary(String category, String status) {
    return '$category · $status';
  }

  @override
  String get storageValueOnline => 'Online';

  @override
  String get storageValueOffline => 'Offline';

  @override
  String get storageValueDegraded => 'Degraded';

  @override
  String get storageValueFaulted => 'Faulted';

  @override
  String get storageValueUnavailable => 'Unavailable';

  @override
  String get storageValueData => 'Data';

  @override
  String get storageValueCache => 'Cache';

  @override
  String get storageValueLog => 'Log';

  @override
  String get storageValueSpare => 'Spare';

  @override
  String get storageValueSpecial => 'Special';

  @override
  String get storageIscsiTargetModeIscsi => 'iSCSI';

  @override
  String storageSectionError(String section, String detail) {
    return '$section: $detail';
  }

  @override
  String get storageIscsiTargetsLabel => 'iSCSI targets';

  @override
  String get storageIscsiExtentsLabel => 'iSCSI extents';

  @override
  String get storageIscsiPortalsLabel => 'iSCSI portals';

  @override
  String get storageIscsiInitiatorsLabel => 'iSCSI initiators';

  @override
  String get storageIscsiAssociationsLabel => 'iSCSI associations';

  @override
  String get storageIscsiChapLabel => 'iSCSI CHAP credentials';

  @override
  String storageShareProtocolPath(String protocol, String path) {
    return '$protocol · $path';
  }

  @override
  String get storageReadOnlySuffix => ' · Read only';

  @override
  String storageNfsListSubtitle(String path, String access) {
    return 'NFS · $path · $access';
  }

  @override
  String storageIscsiTargetListSubtitle(String mode, String name, int count) {
    return '$mode target · $name · $count portal groups';
  }

  @override
  String get storageIscsiInitiatorListAll => 'iSCSI initiators · All clients';

  @override
  String storageIscsiInitiatorListAllowed(int count) {
    return 'iSCSI initiators · $count allowed';
  }

  @override
  String storageIscsiExtentListSubtitle(String type, String store) {
    return '$type extent · $store';
  }

  @override
  String storageIscsiExtentListSubtitleReadOnly(String type, String store) {
    return '$type extent · $store · Read only';
  }

  @override
  String storageDeleteExtentBackingWarning(String store) {
    return 'Removes $store and everything on it.';
  }

  @override
  String get sysRouteDestinationHelper => 'CIDR, e.g. 192.168.50.0/24';

  @override
  String storageWebShareSubtitle(Object path) {
    return 'WebShare · $path';
  }

  @override
  String connMsgSignInAgainToReconnect(Object name) {
    return 'Sign in again to reconnect to $name.';
  }

  @override
  String get connMsgCredentialRequired =>
      'Enter or unlock a credential before connecting.';

  @override
  String get connMsgAuthenticationRejected =>
      'The username or credential was not accepted.';

  @override
  String get connMsgCredentialExpired => 'This credential has expired.';

  @override
  String get connMsgCertificateExpired =>
      'The server\'s TLS certificate has expired. Ask the TrueNAS administrator to renew it.';

  @override
  String connMsgCertificateExpiringSoon(String authority) {
    return 'The TLS certificate for $authority expires soon. Ask the TrueNAS administrator to renew it.';
  }

  @override
  String get connMsgRedirectUnsupported =>
      'Redirected authentication is not supported yet.';

  @override
  String get connMsgInsecureConnection =>
      'Could not connect securely. Check the address and certificate.';

  @override
  String get connMsgCertificateInspectionFailed =>
      'Could not inspect the server certificate. Check the address and try again.';

  @override
  String get connMsgCredentialAccessFailed =>
      'Could not access the saved sign-in. Unlock TrueDock and try again.';

  @override
  String get connMsgAppPinAccessFailed =>
      'Could not unlock the saved sign-in with the TrueDock PIN.';

  @override
  String get connMsgUnsupportedServer =>
      'This server or TrueNAS version is not supported by TrueDock.';

  @override
  String get connMsgInvalidSavedData =>
      'The saved server information is invalid. Register the server again.';

  @override
  String get connMsgAddressTestSignInUnavailable =>
      'The active sign-in is unavailable. Let the server roll back and sign in again.';

  @override
  String get connMsgAddressTestOtpRequired =>
      'This sign-in requires a new verification code. Let the change roll back, then reconnect normally.';

  @override
  String get connMsgAddressTestAuthenticationRejected =>
      'The server rejected the active sign-in at the new address.';

  @override
  String get connMsgAddressTestInvalidAddress =>
      'Enter a valid secure server address.';

  @override
  String get connMsgSavedSignInFailed =>
      'Connected, but the sign-in could not be saved.';

  @override
  String get connMsgServerRegistrationFailed =>
      'Connected, but the server could not be registered.';

  @override
  String get securityBiometricPromptTitle => 'Unlock TrueDock';

  @override
  String get securityBiometricPromptSubtitle =>
      'Authenticate to access your saved server';

  @override
  String get securityBiometricPromptCancel => 'Cancel';

  @override
  String dataMsgDecodeFailed(Object method) {
    return 'Could not decode $method.';
  }

  @override
  String dataMsgInvalidData(Object method) {
    return '$method returned invalid data.';
  }

  @override
  String dataMsgMethodUnavailable(Object method) {
    return '$method is not available on this TrueNAS version.';
  }

  @override
  String get dataMsgDecodeDiskTemperatures =>
      'Could not decode disk.temperatures.';

  @override
  String get dataMsgDecodeCatalogApps => 'Could not decode catalog.apps.';

  @override
  String get dataMsgDecodeCatalogTrains => 'Could not decode catalog.trains.';

  @override
  String get dataMsgDecodeAppDetails =>
      'Could not decode catalog.get_app_details.';

  @override
  String get dataMsgNoInstallableVersions =>
      'No installable app versions were returned.';

  @override
  String get dataMsgReportingUnsupported =>
      'Reporting is not available on this TrueNAS version.';

  @override
  String get dataMsgReportingUnreadable => 'Could not read reporting data.';

  @override
  String get sysTunableTitle => 'System tunables';

  @override
  String get sysTunableNavSubtitle => 'SYSCTL, UDEV, and ZFS parameters';

  @override
  String get sysTunableSubtitle =>
      'Low-level settings applied by TrueNAS. Incorrect values can affect stability or access.';

  @override
  String get sysTunableEmpty => 'No custom tunables.';

  @override
  String get sysTunableCreate => 'Add tunable';

  @override
  String get sysTunableCreateTitle => 'New system tunable';

  @override
  String get sysTunableEditTitle => 'Edit system tunable';

  @override
  String get sysTunableType => 'Type';

  @override
  String get sysTunableTypeSysctl => 'SYSCTL · Runtime kernel';

  @override
  String get sysTunableTypeUdev => 'UDEV · Device rule';

  @override
  String get sysTunableTypeZfs => 'ZFS · Module parameter';

  @override
  String get sysTunableVariable => 'Variable';

  @override
  String get sysTunableVariableSysctlHelper =>
      'Kernel parameter, for example kernel.watchdog';

  @override
  String get sysTunableVariableUdevHelper =>
      'Rules file name; TrueNAS appends .rules';

  @override
  String get sysTunableVariableZfsHelper => 'OpenZFS module parameter name';

  @override
  String get sysTunableValue => 'Value';

  @override
  String get sysTunableComment => 'Comment';

  @override
  String get sysTunableEnabled => 'Enabled';

  @override
  String get sysTunableDisabled => 'Disabled';

  @override
  String get sysTunableUpdateInitramfs => 'Update initramfs';

  @override
  String get sysTunableUpdateInitramfsSubtitle =>
      'Required for the ZFS parameter to survive boot unless rebuilt manually.';

  @override
  String get sysTunableValidationVariable => 'Enter a variable name.';

  @override
  String get sysTunableValidationValue => 'Enter a value.';

  @override
  String get sysTunableCreateConfirmTitle => 'Add this system tunable?';

  @override
  String get sysTunableUpdateConfirmTitle => 'Apply these tunable changes?';

  @override
  String get sysTunableCreateAction => 'Add tunable';

  @override
  String get sysTunableUpdateAction => 'Apply changes';

  @override
  String get sysTunableSysctlConsequence =>
      'SYSCTL settings generally take effect immediately across the server.';

  @override
  String get sysTunableUdevConsequence =>
      'UDEV rules apply when matching hardware events occur.';

  @override
  String get sysTunableZfsConsequence =>
      'ZFS module settings can require an initramfs update and reboot.';

  @override
  String get sysTunableRiskConsequence =>
      'A wrong low-level setting can destabilize TrueNAS or interrupt access.';

  @override
  String get sysTunableDeleteTitle => 'Delete this system tunable?';

  @override
  String get sysTunableDeleteAction => 'Delete tunable';

  @override
  String get sysTunableDeleteConsequence =>
      'The stored override is removed. A reboot or device event may be required before the running value fully reverts.';

  @override
  String get sysTunableCreated => 'System tunable added.';

  @override
  String get sysTunableUpdated => 'System tunable updated.';

  @override
  String get sysTunableDeleted => 'System tunable deleted.';

  @override
  String get navAbout => 'About';

  @override
  String get aboutTitle => 'About TrueDock';

  @override
  String get aboutSettingsSubtitle => 'Version, licenses, and project links';

  @override
  String get aboutTagline => 'Dock your TrueNAS';

  @override
  String get aboutMadeWith => 'Made with ❤️ in 🇰🇷';

  @override
  String get aboutSectionApp => 'Application';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (build $build)';
  }

  @override
  String get aboutLicenseLabel => 'License';

  @override
  String get aboutSectionProject => 'Project';

  @override
  String get aboutRepositoryLabel => 'Source code';

  @override
  String get aboutRepositorySubtitle =>
      'Browse the sources, report an issue, or contribute on GitHub.';

  @override
  String get aboutSectionOpenSource => 'Open source licenses';

  @override
  String get aboutOpenSourceIntro =>
      'TrueDock is built on these open source packages. Thank you to their maintainers.';

  @override
  String aboutOpenSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packages',
      one: '1 package',
    );
    return '$_temp0';
  }

  @override
  String get aboutLinkFailed => 'Could not open the link on this device.';

  @override
  String get aboutOpenSourceSubtitle =>
      'Packages bundled into TrueDock and their licenses';

  @override
  String get aboutPackageOpenPage => 'Open package page';

  @override
  String get aboutPackageLicenseUnavailable =>
      'No bundled license text was found for this package. Use the package page to view its license.';
}
