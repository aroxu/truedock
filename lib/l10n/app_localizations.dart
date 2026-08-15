import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// Application name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'TrueDock'**
  String get appTitle;

  /// Bottom navigation destination: server health at a glance.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Bottom navigation destination: pools, disks, datasets.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get navStorage;

  /// Bottom navigation destination: replication, snapshots, backups.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get navProtection;

  /// Bottom navigation destination: apps, VMs, containers.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navApps;

  /// Bottom navigation destination: accounts, network, updates.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get navSystem;

  /// Bottom navigation destination: TrueDock and registered server settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navAppSettings;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Advances an editor to its confirmation step.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get actionReview;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Retries a dropped server connection.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get actionReconnect;

  /// No description provided for @actionReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get actionReconnecting;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionAddServer.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get actionAddServer;

  /// No description provided for @actionConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Connect server'**
  String get actionConnectServer;

  /// No description provided for @authSucceededSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Authentication successful. Signing in to {serverName}…'**
  String authSucceededSigningIn(String serverName);

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Shown when the server connection dropped and no server name is known.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLostTitle;

  /// Shown when the server connection dropped.
  ///
  /// In en, this message translates to:
  /// **'Lost connection to {serverName}'**
  String connectionLostTitleNamed(String serverName);

  /// Warns that on-screen values predate the disconnection.
  ///
  /// In en, this message translates to:
  /// **'Showing the last data TrueDock received.'**
  String get connectionLostStaleData;

  /// No description provided for @connectionLostReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect to the server.'**
  String get connectionLostReconnectFailed;

  /// No description provided for @overviewAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get overviewAtAGlance;

  /// No description provided for @overviewLivePerformance.
  ///
  /// In en, this message translates to:
  /// **'Live performance'**
  String get overviewLivePerformance;

  /// No description provided for @overviewRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get overviewRecentActivity;

  /// No description provided for @activityAlertDetails.
  ///
  /// In en, this message translates to:
  /// **'Alert details'**
  String get activityAlertDetails;

  /// No description provided for @activityAlertSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get activityAlertSeverity;

  /// No description provided for @activityAlertOccurredAt.
  ///
  /// In en, this message translates to:
  /// **'Last occurred'**
  String get activityAlertOccurredAt;

  /// No description provided for @activityAlertCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get activityAlertCritical;

  /// No description provided for @activityAlertWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get activityAlertWarning;

  /// No description provided for @activityAlertInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get activityAlertInfo;

  /// No description provided for @overviewConnectedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Connected securely'**
  String get overviewConnectedSecurely;

  /// No description provided for @overviewNoServerConnected.
  ///
  /// In en, this message translates to:
  /// **'No server connected'**
  String get overviewNoServerConnected;

  /// No description provided for @overviewHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your TrueNAS, without the browser'**
  String get overviewHeroTitle;

  /// No description provided for @overviewHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a TrueNAS SCALE 25.10+ server to monitor and manage it here.'**
  String get overviewHeroDescription;

  /// No description provided for @metricUptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get metricUptime;

  /// No description provided for @metricUptimeDuration.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{{time}} =1{1 day, {time}} other{{days} days, {time}}}'**
  String metricUptimeDuration(int days, String time);

  /// No description provided for @metricMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get metricMemory;

  /// No description provided for @metricCpuCores.
  ///
  /// In en, this message translates to:
  /// **'CPU cores'**
  String get metricCpuCores;

  /// No description provided for @metricHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get metricHealth;

  /// No description provided for @healthPoolIssues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pool issue} other{{count} pool issues}}'**
  String healthPoolIssues(int count);

  /// No description provided for @healthAttention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get healthAttention;

  /// No description provided for @healthHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthHealthy;

  /// No description provided for @reportingNoSamples.
  ///
  /// In en, this message translates to:
  /// **'No reporting samples are available yet.'**
  String get reportingNoSamples;

  /// No description provided for @reportingCpuUtilisation.
  ///
  /// In en, this message translates to:
  /// **'CPU utilisation'**
  String get reportingCpuUtilisation;

  /// No description provided for @reportingMemoryInUse.
  ///
  /// In en, this message translates to:
  /// **'Memory in use'**
  String get reportingMemoryInUse;

  /// No description provided for @reportingLoadAverage.
  ///
  /// In en, this message translates to:
  /// **'Load average (1m)'**
  String get reportingLoadAverage;

  /// No description provided for @reportingNetworkTraffic.
  ///
  /// In en, this message translates to:
  /// **'Network traffic'**
  String get reportingNetworkTraffic;

  /// No description provided for @reportingNetworkReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get reportingNetworkReceived;

  /// No description provided for @reportingNetworkSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get reportingNetworkSent;

  /// No description provided for @reportingDiskIo.
  ///
  /// In en, this message translates to:
  /// **'Disk I/O'**
  String get reportingDiskIo;

  /// No description provided for @reportingDiskReads.
  ///
  /// In en, this message translates to:
  /// **'Reads'**
  String get reportingDiskReads;

  /// No description provided for @reportingDiskWrites.
  ///
  /// In en, this message translates to:
  /// **'Writes'**
  String get reportingDiskWrites;

  /// No description provided for @reportingCpuHistory.
  ///
  /// In en, this message translates to:
  /// **'CPU history'**
  String get reportingCpuHistory;

  /// No description provided for @reportingMemoryHistory.
  ///
  /// In en, this message translates to:
  /// **'RAM history'**
  String get reportingMemoryHistory;

  /// No description provided for @reportingNetworkHistory.
  ///
  /// In en, this message translates to:
  /// **'Network history'**
  String get reportingNetworkHistory;

  /// No description provided for @reportingDiskHistory.
  ///
  /// In en, this message translates to:
  /// **'Disk I/O history'**
  String get reportingDiskHistory;

  /// No description provided for @reportingRangeHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get reportingRangeHour;

  /// No description provided for @reportingRangeDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get reportingRangeDay;

  /// No description provided for @reportingRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get reportingRangeWeek;

  /// No description provided for @reportingCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get reportingCurrent;

  /// No description provided for @reportingChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. Current {current}. Range {minimum} to {maximum}.'**
  String reportingChartSemantics(
    String label,
    String current,
    String minimum,
    String maximum,
  );

  /// No description provided for @reportingAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get reportingAverage;

  /// No description provided for @reportingMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get reportingMinimum;

  /// No description provided for @reportingMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get reportingMaximum;

  /// No description provided for @activityNoAttention.
  ///
  /// In en, this message translates to:
  /// **'No active alerts or recent jobs need attention.'**
  String get activityNoAttention;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Jobs, alerts, and recent changes will appear here.'**
  String get activityEmpty;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Add TrueNAS server'**
  String get connectTitle;

  /// No description provided for @registrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Register TrueNAS server'**
  String get registrationTitle;

  /// No description provided for @serverEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a server'**
  String get serverEntryTitle;

  /// No description provided for @serverRegisterAnother.
  ///
  /// In en, this message translates to:
  /// **'Register another server'**
  String get serverRegisterAnother;

  /// No description provided for @connectServerName.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get connectServerName;

  /// No description provided for @connectServerNameHint.
  ///
  /// In en, this message translates to:
  /// **'Home NAS'**
  String get connectServerNameHint;

  /// No description provided for @connectSecureAddress.
  ///
  /// In en, this message translates to:
  /// **'Secure address'**
  String get connectSecureAddress;

  /// No description provided for @connectSecureAddressHint.
  ///
  /// In en, this message translates to:
  /// **'https://truenas.local'**
  String get connectSecureAddressHint;

  /// No description provided for @connectSecureAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'TrueDock connects to WSS /api/current.'**
  String get connectSecureAddressHelper;

  /// No description provided for @connectSignInWith.
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get connectSignInWith;

  /// No description provided for @authApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get authApiKey;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the account linked to this credential.'**
  String get authUsernameRequired;

  /// No description provided for @authCredentialRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your credential.'**
  String get authCredentialRequired;

  /// No description provided for @authShowCredential.
  ///
  /// In en, this message translates to:
  /// **'Show credential'**
  String get authShowCredential;

  /// No description provided for @authHideCredential.
  ///
  /// In en, this message translates to:
  /// **'Hide credential'**
  String get authHideCredential;

  /// No description provided for @authKeepSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Keep me signed in'**
  String get authKeepSignedIn;

  /// No description provided for @authUnlockWithBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock the saved credential with biometrics.'**
  String get authUnlockWithBiometrics;

  /// No description provided for @authBiometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock'**
  String get authBiometricUnlock;

  /// No description provided for @authBiometricUnlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, Touch ID, or fingerprint instead of entering the TrueDock PIN.'**
  String get authBiometricUnlockDescription;

  /// No description provided for @authCheckingBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Checking biometric protection…'**
  String get authCheckingBiometrics;

  /// No description provided for @authBiometricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric protection is currently unavailable.'**
  String get authBiometricsUnavailable;

  /// No description provided for @authBiometricsProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected by device biometrics'**
  String get authBiometricsProtected;

  /// No description provided for @authBiometricsNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Set up Face ID, Touch ID, or fingerprint first'**
  String get authBiometricsNotEnrolled;

  /// No description provided for @authBiometricsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support biometric sign-in'**
  String get authBiometricsUnsupported;

  /// No description provided for @authBiometricsTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric sign-in is currently unavailable'**
  String get authBiometricsTemporarilyUnavailable;

  /// No description provided for @authProtectWithAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Protect the saved credential with a separate TrueDock PIN.'**
  String get authProtectWithAppPassword;

  /// No description provided for @appPasswordCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create TrueDock PIN'**
  String get appPasswordCreateTitle;

  /// No description provided for @appPasswordCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'This 6-digit PIN encrypts saved credentials on this device. It is separate from your TrueNAS password and is never stored or synced.'**
  String get appPasswordCreateDescription;

  /// No description provided for @appPasswordExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter TrueDock PIN'**
  String get appPasswordExistingTitle;

  /// No description provided for @appPasswordExistingDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the same TrueDock PIN that protects your other saved server sign-ins.'**
  String get appPasswordExistingDescription;

  /// No description provided for @appPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'TrueDock PIN'**
  String get appPasswordLabel;

  /// No description provided for @appPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm TrueDock PIN'**
  String get appPasswordConfirmLabel;

  /// No description provided for @appPasswordMinimum.
  ///
  /// In en, this message translates to:
  /// **'Enter exactly 6 digits.'**
  String get appPasswordMinimum;

  /// No description provided for @appPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match.'**
  String get appPasswordMismatch;

  /// No description provided for @appPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'The TrueDock PIN is incorrect.'**
  String get appPasswordIncorrect;

  /// No description provided for @appPasswordUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock {serverName}'**
  String appPasswordUnlockTitle(String serverName);

  /// No description provided for @appPasswordUnlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your separate TrueDock PIN. This is not the TrueNAS account password.'**
  String get appPasswordUnlockDescription;

  /// No description provided for @appPasswordForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get appPasswordForgot;

  /// No description provided for @appPasswordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear saved sign-in?'**
  String get appPasswordResetTitle;

  /// No description provided for @appPasswordResetDescription.
  ///
  /// In en, this message translates to:
  /// **'TrueDock cannot recover this PIN. Every sign-in protected by the TrueDock PIN, including its Biometric Unlock copy, will be removed. Server profiles, TLS certificate trust, legacy biometric-only sign-ins, and TrueNAS data stay unchanged.'**
  String get appPasswordResetDescription;

  /// No description provided for @appPasswordResetAction.
  ///
  /// In en, this message translates to:
  /// **'Clear protected sign-ins'**
  String get appPasswordResetAction;

  /// No description provided for @authConnectingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Connecting securely…'**
  String get authConnectingSecurely;

  /// No description provided for @authTransportNotice.
  ///
  /// In en, this message translates to:
  /// **'Credentials are sent only through TLS. Saved credentials use platform protection or an encrypted TrueDock PIN vault.'**
  String get authTransportNotice;

  /// No description provided for @savedServersTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved servers'**
  String get savedServersTitle;

  /// No description provided for @savedServerOptions.
  ///
  /// In en, this message translates to:
  /// **'Saved server options'**
  String get savedServerOptions;

  /// No description provided for @savedServerForget.
  ///
  /// In en, this message translates to:
  /// **'Forget server'**
  String get savedServerForget;

  /// No description provided for @savedServerSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get savedServerSignInRequired;

  /// No description provided for @savedServerEnterCredential.
  ///
  /// In en, this message translates to:
  /// **'Enter the credential for {serverName} below.'**
  String savedServerEnterCredential(String serverName);

  /// No description provided for @savedServerSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {serverName}'**
  String savedServerSignInTitle(String serverName);

  /// No description provided for @savedServerAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in to the saved server.'**
  String get savedServerAuthenticationFailed;

  /// No description provided for @serverManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get serverManagementTitle;

  /// No description provided for @serverManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch between registered TrueNAS servers. Credentials and trusted certificates remain isolated per server.'**
  String get serverManagementDescription;

  /// No description provided for @serverManagementLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load registered servers.'**
  String get serverManagementLoadFailed;

  /// No description provided for @serverRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename server'**
  String get serverRenameTitle;

  /// No description provided for @serverRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Server name'**
  String get serverRenameLabel;

  /// No description provided for @serverRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get serverRenameAction;

  /// No description provided for @serverActive.
  ///
  /// In en, this message translates to:
  /// **'Active server'**
  String get serverActive;

  /// No description provided for @serverSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch server?'**
  String get serverSwitchTitle;

  /// No description provided for @serverSwitchDescription.
  ///
  /// In en, this message translates to:
  /// **'TrueDock will close the current session and connect to {serverName}. Server-side jobs already running will continue.'**
  String serverSwitchDescription(String serverName);

  /// No description provided for @serverSwitchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get serverSwitchAction;

  /// No description provided for @serverSwitching.
  ///
  /// In en, this message translates to:
  /// **'Switching…'**
  String get serverSwitching;

  /// No description provided for @serverSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get serverSigningIn;

  /// No description provided for @serverSwitchCredentialUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server has no saved sign-in.'**
  String get serverSwitchCredentialUnavailable;

  /// No description provided for @serverForgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget this server?'**
  String get serverForgetTitle;

  /// No description provided for @serverForgetDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove {serverName} and its saved credential from this device.'**
  String serverForgetDescription(String serverName);

  /// No description provided for @serverForgetActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from {serverName}, then remove it and its saved credential from this device.'**
  String serverForgetActiveDescription(String serverName);

  /// No description provided for @connectHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Dock your TrueNAS'**
  String get connectHeroTitle;

  /// No description provided for @connectHeroDescription.
  ///
  /// In en, this message translates to:
  /// **'Supports TrueNAS SCALE 25.10 or later.'**
  String get connectHeroDescription;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication'**
  String get otpTitle;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get otpCode;

  /// No description provided for @certificateChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Server certificate changed'**
  String get certificateChangedTitle;

  /// No description provided for @certificateExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Expired certificate'**
  String get certificateExpiredTitle;

  /// No description provided for @certificateTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust this server?'**
  String get certificateTrustTitle;

  /// No description provided for @certificateVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify server certificate'**
  String get certificateVerifyTitle;

  /// No description provided for @certificateChangedDescription.
  ///
  /// In en, this message translates to:
  /// **'The certificate no longer matches the one saved for {authority}. Continue only if you expected this change.'**
  String certificateChangedDescription(String authority);

  /// No description provided for @certificateExpiredDescription.
  ///
  /// In en, this message translates to:
  /// **'This is an expired certificate. Do you want to continue?'**
  String get certificateExpiredDescription;

  /// No description provided for @certificateTrustDescription.
  ///
  /// In en, this message translates to:
  /// **'{authority} uses a certificate that is not trusted by the operating system. Compare this fingerprint with your TrueNAS server.'**
  String certificateTrustDescription(String authority);

  /// No description provided for @certificateTrustedDescription.
  ///
  /// In en, this message translates to:
  /// **'The operating system trusts the certificate used by {authority}. Verify its identity before connecting.'**
  String certificateTrustedDescription(String authority);

  /// No description provided for @certificateUntrustedAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I verified this certificate fingerprint and understand that the operating system does not trust it.'**
  String get certificateUntrustedAcknowledge;

  /// No description provided for @certificateFingerprint.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get certificateFingerprint;

  /// No description provided for @certificateSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get certificateSubject;

  /// No description provided for @certificateIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get certificateIssuer;

  /// No description provided for @certificateValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get certificateValidUntil;

  /// No description provided for @certificatePreviousFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Previously trusted fingerprint'**
  String get certificatePreviousFingerprint;

  /// No description provided for @certificateTrustNew.
  ///
  /// In en, this message translates to:
  /// **'Trust new certificate'**
  String get certificateTrustNew;

  /// No description provided for @certificateExpiredContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get certificateExpiredContinue;

  /// No description provided for @certificateTrustAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Trust and connect'**
  String get certificateTrustAndConnect;

  /// No description provided for @certificateVerifyAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Verify and connect'**
  String get certificateVerifyAndConnect;

  /// No description provided for @systemAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get systemAppearance;

  /// No description provided for @systemAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Color, light and dark mode'**
  String get systemAppearanceSubtitle;

  /// No description provided for @systemReduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduced animations'**
  String get systemReduceAnimations;

  /// No description provided for @systemReduceAnimationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use immediate transitions and limit motion throughout TrueDock.'**
  String get systemReduceAnimationsSubtitle;

  /// No description provided for @diagnosticsPrivacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get diagnosticsPrivacySection;

  /// No description provided for @diagnosticsAnonymousTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous diagnostics'**
  String get diagnosticsAnonymousTitle;

  /// No description provided for @diagnosticsAnonymousDescription.
  ///
  /// In en, this message translates to:
  /// **'Share anonymized crash, error, and performance information to help improve TrueDock. Server addresses, accounts, resource names, API data, and credentials are never collected.'**
  String get diagnosticsAnonymousDescription;

  /// No description provided for @diagnosticsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic delivery is not configured for this build. This preference will be used when diagnostics are available.'**
  String get diagnosticsNotConfigured;

  /// No description provided for @diagnosticsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving diagnostic preference…'**
  String get diagnosticsSaving;

  /// No description provided for @diagnosticsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the diagnostic data setting.'**
  String get diagnosticsUpdateFailed;

  /// No description provided for @diagnosticsDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off anonymous diagnostics?'**
  String get diagnosticsDisclosureTitle;

  /// No description provided for @diagnosticsDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get diagnosticsDisableAction;

  /// No description provided for @systemProtectedSignIn.
  ///
  /// In en, this message translates to:
  /// **'TrueDock PIN'**
  String get systemProtectedSignIn;

  /// No description provided for @systemAppPasswordEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled on this device'**
  String get systemAppPasswordEnabled;

  /// No description provided for @systemAppPasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN to protect saved sign-ins.'**
  String get systemAppPasswordDisabled;

  /// No description provided for @systemChangeAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get systemChangeAppPassword;

  /// No description provided for @systemChangeAppPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-encrypt every saved sign-in with a new PIN.'**
  String get systemChangeAppPasswordSubtitle;

  /// No description provided for @systemChangeAppPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the current PIN, then choose a new 6-digit PIN. Saved server sign-ins remain available.'**
  String get systemChangeAppPasswordDescription;

  /// No description provided for @systemCurrentAppPassword.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get systemCurrentAppPassword;

  /// No description provided for @systemNewAppPassword.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get systemNewAppPassword;

  /// No description provided for @systemAppPasswordMustChange.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN different from the current PIN.'**
  String get systemAppPasswordMustChange;

  /// No description provided for @appDataDangerSection.
  ///
  /// In en, this message translates to:
  /// **'Device data'**
  String get appDataDangerSection;

  /// No description provided for @appDataResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all TrueDock data'**
  String get appDataResetTitle;

  /// No description provided for @appDataResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove server profiles, saved sign-ins, PIN data, biometric copies, trusted certificates, and app settings from this device.'**
  String get appDataResetSubtitle;

  /// No description provided for @appDataResetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase all data from this device?'**
  String get appDataResetDialogTitle;

  /// No description provided for @appDataResetDescription.
  ///
  /// In en, this message translates to:
  /// **'This signs out of TrueDock and permanently removes all local TrueDock data from the iOS Keychain or Android secure storage. Data and settings on your TrueNAS servers are not changed.'**
  String get appDataResetDescription;

  /// No description provided for @appDataResetIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get appDataResetIrreversible;

  /// No description provided for @appDataResetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get appDataResetConfirmation;

  /// No description provided for @appDataResetTypePrompt.
  ///
  /// In en, this message translates to:
  /// **'Type the code {confirmation} to continue.'**
  String appDataResetTypePrompt(String confirmation);

  /// No description provided for @appDataResetCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Data reset confirmation code'**
  String get appDataResetCodeLabel;

  /// No description provided for @appDataResetAction.
  ///
  /// In en, this message translates to:
  /// **'Erase all data'**
  String get appDataResetAction;

  /// No description provided for @appDataResetFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueDock could not erase all local data.'**
  String get appDataResetFailed;

  /// No description provided for @appDataResetCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset complete'**
  String get appDataResetCompleteTitle;

  /// No description provided for @appDataResetCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'All TrueDock data on this device has been erased. You can now set up the app again from the beginning.'**
  String get appDataResetCompleteDescription;

  /// No description provided for @appDataResetCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get appDataResetCompleteAction;

  /// No description provided for @systemSavedSignIns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved server sign-in} other{{count} saved server sign-ins}}'**
  String systemSavedSignIns(int count);

  /// No description provided for @systemCheckingDeviceSecurity.
  ///
  /// In en, this message translates to:
  /// **'Checking device security…'**
  String get systemCheckingDeviceSecurity;

  /// No description provided for @systemBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric protection is unavailable'**
  String get systemBiometricUnavailable;

  /// No description provided for @systemServerSection.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get systemServerSection;

  /// No description provided for @systemNoServer.
  ///
  /// In en, this message translates to:
  /// **'No server'**
  String get systemNoServer;

  /// No description provided for @systemCommunityVersion.
  ///
  /// In en, this message translates to:
  /// **'Community {version}'**
  String systemCommunityVersion(String version);

  /// No description provided for @systemConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Connect a TrueNAS server'**
  String get systemConnectServer;

  /// No description provided for @systemDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get systemDisconnect;

  /// No description provided for @systemPinnedCertificate.
  ///
  /// In en, this message translates to:
  /// **'Trusted Certificate'**
  String get systemPinnedCertificate;

  /// No description provided for @certificateDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'The certificate currently presented by {authority} is compared with the fingerprint saved for this server.'**
  String certificateDetailsDescription(String authority);

  /// No description provided for @certificateValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get certificateValidFrom;

  /// No description provided for @certificateTrustStatus.
  ///
  /// In en, this message translates to:
  /// **'Trust status'**
  String get certificateTrustStatus;

  /// No description provided for @certificateSystemTrust.
  ///
  /// In en, this message translates to:
  /// **'System trust'**
  String get certificateSystemTrust;

  /// No description provided for @certificatePinnedAndMatched.
  ///
  /// In en, this message translates to:
  /// **'Matches the certificate trusted by TrueDock'**
  String get certificatePinnedAndMatched;

  /// No description provided for @certificatePinnedMismatch.
  ///
  /// In en, this message translates to:
  /// **'Does not match the certificate trusted by TrueDock'**
  String get certificatePinnedMismatch;

  /// No description provided for @certificateSystemTrusted.
  ///
  /// In en, this message translates to:
  /// **'Also trusted by the operating system'**
  String get certificateSystemTrusted;

  /// No description provided for @certificateTrueDockTrustedOnly.
  ///
  /// In en, this message translates to:
  /// **'Trusted by TrueDock for this server'**
  String get certificateTrueDockTrustedOnly;

  /// No description provided for @certificateExpiredWarning.
  ///
  /// In en, this message translates to:
  /// **'This certificate has expired. Ask the TrueNAS administrator to renew it.'**
  String get certificateExpiredWarning;

  /// No description provided for @certificateExpiringSoonWarning.
  ///
  /// In en, this message translates to:
  /// **'This certificate expires soon. Ask the TrueNAS administrator to renew it.'**
  String get certificateExpiringSoonWarning;

  /// No description provided for @certificateDetailsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the server certificate.'**
  String get certificateDetailsLoadFailed;

  /// No description provided for @systemAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get systemAdministration;

  /// No description provided for @systemGeneralSettings.
  ///
  /// In en, this message translates to:
  /// **'General settings'**
  String get systemGeneralSettings;

  /// No description provided for @systemGeneralSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hostname, timezone, syslog, power'**
  String get systemGeneralSettingsSubtitle;

  /// No description provided for @systemAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get systemAdvanced;

  /// No description provided for @systemAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Boot environments and recovery'**
  String get systemAdvancedSubtitle;

  /// No description provided for @systemAlertsAndJobs.
  ///
  /// In en, this message translates to:
  /// **'Alerts and jobs'**
  String get systemAlertsAndJobs;

  /// No description provided for @systemUsersAndAccess.
  ///
  /// In en, this message translates to:
  /// **'Users and access'**
  String get systemUsersAndAccess;

  /// No description provided for @systemNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get systemNetwork;

  /// No description provided for @systemUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get systemUpdates;

  /// No description provided for @systemSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the server settings.'**
  String get systemSettingsLoadFailed;

  /// No description provided for @systemActivityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load system activity.'**
  String get systemActivityLoadFailed;

  /// No description provided for @systemNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get systemNoChanges;

  /// No description provided for @systemServerFallback.
  ///
  /// In en, this message translates to:
  /// **'this TrueNAS server'**
  String get systemServerFallback;

  /// No description provided for @systemSaveSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Save server settings?'**
  String get systemSaveSettingsTitle;

  /// No description provided for @systemGeneralSettingsTarget.
  ///
  /// In en, this message translates to:
  /// **'general settings'**
  String get systemGeneralSettingsTarget;

  /// No description provided for @actionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get actionSaveChanges;

  /// No description provided for @systemHostnameChangeImpact.
  ///
  /// In en, this message translates to:
  /// **'The hostname changes after the server reloads its network configuration. Active sessions are not affected.'**
  String get systemHostnameChangeImpact;

  /// No description provided for @systemSettingsChangeImpact.
  ///
  /// In en, this message translates to:
  /// **'The settings are updated on the server.'**
  String get systemSettingsChangeImpact;

  /// No description provided for @systemSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not save the settings.'**
  String get systemSettingsSaveFailed;

  /// No description provided for @systemSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Server settings saved.'**
  String get systemSettingsSaved;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get themeColor;

  /// No description provided for @themeSystemDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'System dynamic color'**
  String get themeSystemDynamicColor;

  /// No description provided for @themeSystemDynamicColorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match the Android wallpaper palette'**
  String get themeSystemDynamicColorSubtitle;

  /// No description provided for @themeColorSemantics.
  ///
  /// In en, this message translates to:
  /// **'Theme color {hex}'**
  String themeColorSemantics(String hex);

  /// No description provided for @themeCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get themeCustomColor;

  /// No description provided for @themeCustomSourceColor.
  ///
  /// In en, this message translates to:
  /// **'Custom source color'**
  String get themeCustomSourceColor;

  /// No description provided for @themeHexColor.
  ///
  /// In en, this message translates to:
  /// **'Hex color'**
  String get themeHexColor;

  /// No description provided for @themeColorPickerArea.
  ///
  /// In en, this message translates to:
  /// **'Color saturation and brightness'**
  String get themeColorPickerArea;

  /// No description provided for @themeColorHue.
  ///
  /// In en, this message translates to:
  /// **'Color hue'**
  String get themeColorHue;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @themeInvalidHex.
  ///
  /// In en, this message translates to:
  /// **'Enter six hexadecimal digits.'**
  String get themeInvalidHex;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// No description provided for @storageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load storage information.'**
  String get storageLoadFailed;

  /// No description provided for @storageLandingDescription.
  ///
  /// In en, this message translates to:
  /// **'Pools, disks, datasets, snapshots, and shares in one place.'**
  String get storageLandingDescription;

  /// No description provided for @storageFeaturePools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get storageFeaturePools;

  /// No description provided for @storageFeaturePoolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capacity, topology, health'**
  String get storageFeaturePoolsSubtitle;

  /// No description provided for @storageFeatureDatasets.
  ///
  /// In en, this message translates to:
  /// **'Datasets'**
  String get storageFeatureDatasets;

  /// No description provided for @storageFeatureDatasetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Properties, quotas, encryption'**
  String get storageFeatureDatasetsSubtitle;

  /// No description provided for @storageFeatureSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get storageFeatureSnapshots;

  /// No description provided for @storageFeatureSnapshotsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse, create, clone, restore'**
  String get storageFeatureSnapshotsSubtitle;

  /// No description provided for @storageFeatureDisks.
  ///
  /// In en, this message translates to:
  /// **'Disks'**
  String get storageFeatureDisks;

  /// No description provided for @storageFeatureDisksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory, capacity, temperatures'**
  String get storageFeatureDisksSubtitle;

  /// No description provided for @storageFeatureShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get storageFeatureShares;

  /// No description provided for @storageFeatureSharesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SMB, NFS, iSCSI, WebShare'**
  String get storageFeatureSharesSubtitle;

  /// No description provided for @storageRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh storage'**
  String get storageRefreshTooltip;

  /// No description provided for @storageDatasetCreated.
  ///
  /// In en, this message translates to:
  /// **'Dataset created.'**
  String get storageDatasetCreated;

  /// No description provided for @storageSmbShare.
  ///
  /// In en, this message translates to:
  /// **'SMB share'**
  String get storageSmbShare;

  /// No description provided for @storageNfsShare.
  ///
  /// In en, this message translates to:
  /// **'NFS share'**
  String get storageNfsShare;

  /// No description provided for @storageIscsiPortal.
  ///
  /// In en, this message translates to:
  /// **'iSCSI portal'**
  String get storageIscsiPortal;

  /// No description provided for @storageIscsiInitiatorGroup.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiator group'**
  String get storageIscsiInitiatorGroup;

  /// No description provided for @storageIscsiTarget.
  ///
  /// In en, this message translates to:
  /// **'iSCSI target'**
  String get storageIscsiTarget;

  /// No description provided for @storageIscsiExtent.
  ///
  /// In en, this message translates to:
  /// **'iSCSI extent'**
  String get storageIscsiExtent;

  /// No description provided for @storageIscsiLunAssociation.
  ///
  /// In en, this message translates to:
  /// **'iSCSI LUN association'**
  String get storageIscsiLunAssociation;

  /// No description provided for @storageIscsiPortalWithAddress.
  ///
  /// In en, this message translates to:
  /// **'iSCSI portal · {address}'**
  String storageIscsiPortalWithAddress(String address);

  /// No description provided for @storageDiskTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · {model}'**
  String storageDiskTitle(String name, String model);

  /// No description provided for @storageChapCredentials.
  ///
  /// In en, this message translates to:
  /// **'CHAP credentials'**
  String get storageChapCredentials;

  /// No description provided for @storageNoUnusedDisksForPool.
  ///
  /// In en, this message translates to:
  /// **'No unused disks are available to create a pool.'**
  String get storageNoUnusedDisksForPool;

  /// No description provided for @storageCreateTargetExtentFirst.
  ///
  /// In en, this message translates to:
  /// **'Create at least one target and one extent first.'**
  String get storageCreateTargetExtentFirst;

  /// No description provided for @storageCreateSnapshotRecursively.
  ///
  /// In en, this message translates to:
  /// **'Create the snapshot recursively'**
  String get storageCreateSnapshotRecursively;

  /// No description provided for @storageIncludeChildDatasets.
  ///
  /// In en, this message translates to:
  /// **'Include child datasets'**
  String get storageIncludeChildDatasets;

  /// No description provided for @storageDiskLabelModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get storageDiskLabelModel;

  /// No description provided for @storageDiskLabelSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get storageDiskLabelSerial;

  /// No description provided for @storageDiskUnknownModel.
  ///
  /// In en, this message translates to:
  /// **'Unknown model'**
  String get storageDiskUnknownModel;

  /// No description provided for @storageDiskNoSerial.
  ///
  /// In en, this message translates to:
  /// **'No serial'**
  String get storageDiskNoSerial;

  /// No description provided for @storageDiskLabelCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get storageDiskLabelCapacity;

  /// No description provided for @storageDiskLabelMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get storageDiskLabelMedia;

  /// No description provided for @storageDiskLabelPool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get storageDiskLabelPool;

  /// No description provided for @storageDiskLabelUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get storageDiskLabelUnassigned;

  /// No description provided for @storageDiskLabelRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get storageDiskLabelRotation;

  /// No description provided for @storageDiskLabelTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get storageDiskLabelTemperature;

  /// No description provided for @storageDiskLabelRatedMaximum.
  ///
  /// In en, this message translates to:
  /// **'Rated maximum'**
  String get storageDiskLabelRatedMaximum;

  /// No description provided for @storageDiskLabelCriticalAt.
  ///
  /// In en, this message translates to:
  /// **'Critical at'**
  String get storageDiskLabelCriticalAt;

  /// No description provided for @storageLabelUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get storageLabelUsed;

  /// No description provided for @storageLabelFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get storageLabelFree;

  /// No description provided for @storageLabelFragmentation.
  ///
  /// In en, this message translates to:
  /// **'Fragmentation'**
  String get storageLabelFragmentation;

  /// No description provided for @poolScrubStart.
  ///
  /// In en, this message translates to:
  /// **'Start scrub'**
  String get poolScrubStart;

  /// No description provided for @poolScrubStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verifies every block. Uses disk bandwidth.'**
  String get poolScrubStartSubtitle;

  /// No description provided for @poolScrubPause.
  ///
  /// In en, this message translates to:
  /// **'Pause scrub'**
  String get poolScrubPause;

  /// No description provided for @poolScrubPauseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress is kept and can be resumed.'**
  String get poolScrubPauseSubtitle;

  /// No description provided for @poolScrubStop.
  ///
  /// In en, this message translates to:
  /// **'Stop scrub'**
  String get poolScrubStop;

  /// No description provided for @poolScrubStopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress is discarded.'**
  String get poolScrubStopSubtitle;

  /// No description provided for @poolScrubResume.
  ///
  /// In en, this message translates to:
  /// **'Resume scrub'**
  String get poolScrubResume;

  /// No description provided for @poolScrubPaused.
  ///
  /// In en, this message translates to:
  /// **'Scrub paused'**
  String get poolScrubPaused;

  /// No description provided for @poolScrubRunning.
  ///
  /// In en, this message translates to:
  /// **'Scrub running'**
  String get poolScrubRunning;

  /// No description provided for @poolScrubProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String poolScrubProgress(double percent);

  /// No description provided for @poolMembers.
  ///
  /// In en, this message translates to:
  /// **'Pool members'**
  String get poolMembers;

  /// No description provided for @poolMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} device(s)'**
  String poolMembersCount(int count);

  /// No description provided for @poolAttachDisk.
  ///
  /// In en, this message translates to:
  /// **'Attach disk'**
  String get poolAttachDisk;

  /// No description provided for @poolAttachDiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a disk to a mirror or stripe. Starts a resilver.'**
  String get poolAttachDiskSubtitle;

  /// No description provided for @poolReplaceDisk.
  ///
  /// In en, this message translates to:
  /// **'Replace disk'**
  String get poolReplaceDisk;

  /// No description provided for @poolReplaceDiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swap a member for a new disk. Old disk is removed after resilver.'**
  String get poolReplaceDiskSubtitle;

  /// No description provided for @poolExportOrDestroy.
  ///
  /// In en, this message translates to:
  /// **'Export or destroy pool'**
  String get poolExportOrDestroy;

  /// No description provided for @poolExportOrDestroySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes the pool from this server.'**
  String get poolExportOrDestroySubtitle;

  /// No description provided for @poolMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'Taking a device offline leaves the pool degraded until it is brought back or replaced.'**
  String get poolMembersDescription;

  /// No description provided for @poolMemberCategoryStatus.
  ///
  /// In en, this message translates to:
  /// **'{category} · {status}'**
  String poolMemberCategoryStatus(String category, String status);

  /// No description provided for @poolTakeOffline.
  ///
  /// In en, this message translates to:
  /// **'Take offline'**
  String get poolTakeOffline;

  /// No description provided for @poolBringOnline.
  ///
  /// In en, this message translates to:
  /// **'Bring online'**
  String get poolBringOnline;

  /// No description provided for @poolOfflineUseOnly.
  ///
  /// In en, this message translates to:
  /// **'Offline use only'**
  String get poolOfflineUseOnly;

  /// No description provided for @poolAttachDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the vdev to add a disk to. Only mirror and stripe vdevs accept an attached disk; attaching to a mirror starts a resilver.'**
  String get poolAttachDescription;

  /// No description provided for @poolNoUnusedDisks.
  ///
  /// In en, this message translates to:
  /// **'No unused disks are available on this server.'**
  String get poolNoUnusedDisks;

  /// No description provided for @poolVdevTitle.
  ///
  /// In en, this message translates to:
  /// **'vdev {guid}'**
  String poolVdevTitle(String guid);

  /// No description provided for @poolContainsMember.
  ///
  /// In en, this message translates to:
  /// **'Contains {name} · {status}'**
  String poolContainsMember(String name, String status);

  /// No description provided for @poolReplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick the member to replace, then choose a new disk. The old disk is removed from the pool once the resilver finishes and is safe to remove.'**
  String get poolReplaceDescription;

  /// No description provided for @poolForceRemoveOldDisk.
  ///
  /// In en, this message translates to:
  /// **'Force remove old disk'**
  String get poolForceRemoveOldDisk;

  /// No description provided for @poolForceRemoveOldDiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes the old disk even if it is still being read. Use only if the disk has failed.'**
  String get poolForceRemoveOldDiskSubtitle;

  /// No description provided for @poolChooseReplacementDisk.
  ///
  /// In en, this message translates to:
  /// **'Choose replacement disk'**
  String get poolChooseReplacementDisk;

  /// No description provided for @poolAttachToVdev.
  ///
  /// In en, this message translates to:
  /// **'Attach to vdev {guid}'**
  String poolAttachToVdev(String guid);

  /// No description provided for @poolReplaceTarget.
  ///
  /// In en, this message translates to:
  /// **'Replace {name}'**
  String poolReplaceTarget(String name);

  /// No description provided for @poolExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export pool'**
  String get poolExportTitle;

  /// No description provided for @poolExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Exporting detaches the pool from this server. Without destroying data the disks can be imported again here or on another system.'**
  String get poolExportDescription;

  /// No description provided for @poolDeleteSharesAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Delete shares and tasks using this pool'**
  String get poolDeleteSharesAndTasks;

  /// No description provided for @poolDestroyAllData.
  ///
  /// In en, this message translates to:
  /// **'Destroy all data on the disks'**
  String get poolDestroyAllData;

  /// No description provided for @poolDestroyAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The pool can never be imported again.'**
  String get poolDestroyAllDataSubtitle;

  /// No description provided for @poolOperationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This TrueNAS version does not expose pool operations to TrueDock.'**
  String get poolOperationsUnavailable;

  /// No description provided for @poolStatusFree.
  ///
  /// In en, this message translates to:
  /// **'{status} · {free} free'**
  String poolStatusFree(String status, String free);

  /// No description provided for @datasetCreateFilesystem.
  ///
  /// In en, this message translates to:
  /// **'Create dataset'**
  String get datasetCreateFilesystem;

  /// No description provided for @datasetCreateVolume.
  ///
  /// In en, this message translates to:
  /// **'Create volume'**
  String get datasetCreateVolume;

  /// No description provided for @datasetVolumeDescription.
  ///
  /// In en, this message translates to:
  /// **'A volume is a block device, used by iSCSI extents and virtual machine disks. Encryption inherits from the selected parent.'**
  String get datasetVolumeDescription;

  /// No description provided for @datasetFilesystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Encryption settings inherit from the selected parent.'**
  String get datasetFilesystemDescription;

  /// No description provided for @datasetTypeFilesystem.
  ///
  /// In en, this message translates to:
  /// **'Filesystem'**
  String get datasetTypeFilesystem;

  /// No description provided for @datasetTypeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get datasetTypeVolume;

  /// No description provided for @datasetParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get datasetParent;

  /// No description provided for @datasetVolumeName.
  ///
  /// In en, this message translates to:
  /// **'Volume name'**
  String get datasetVolumeName;

  /// No description provided for @datasetName.
  ///
  /// In en, this message translates to:
  /// **'Dataset name'**
  String get datasetName;

  /// No description provided for @datasetEnterVolumeName.
  ///
  /// In en, this message translates to:
  /// **'Enter a volume name.'**
  String get datasetEnterVolumeName;

  /// No description provided for @datasetEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a dataset name.'**
  String get datasetEnterName;

  /// No description provided for @datasetUseParentForPaths.
  ///
  /// In en, this message translates to:
  /// **'Use the Parent field for paths.'**
  String get datasetUseParentForPaths;

  /// No description provided for @datasetSizeInGib.
  ///
  /// In en, this message translates to:
  /// **'Size in GiB'**
  String get datasetSizeInGib;

  /// No description provided for @datasetEnterSizeInGib.
  ///
  /// In en, this message translates to:
  /// **'Enter a size in GiB.'**
  String get datasetEnterSizeInGib;

  /// No description provided for @datasetEnterSizePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a size greater than zero.'**
  String get datasetEnterSizePositive;

  /// No description provided for @datasetSparseThin.
  ///
  /// In en, this message translates to:
  /// **'Sparse (thin provision)'**
  String get datasetSparseThin;

  /// No description provided for @datasetSparseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reserves no space up front. Writes can fail once the pool fills, even though the volume reports free space.'**
  String get datasetSparseSubtitle;

  /// No description provided for @datasetWorkloadOptimization.
  ///
  /// In en, this message translates to:
  /// **'Workload optimization'**
  String get datasetWorkloadOptimization;

  /// No description provided for @datasetShareGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get datasetShareGeneric;

  /// No description provided for @datasetShareSmb.
  ///
  /// In en, this message translates to:
  /// **'SMB'**
  String get datasetShareSmb;

  /// No description provided for @datasetShareNfs.
  ///
  /// In en, this message translates to:
  /// **'NFS'**
  String get datasetShareNfs;

  /// No description provided for @datasetShareMultiprotocol.
  ///
  /// In en, this message translates to:
  /// **'Multiprotocol'**
  String get datasetShareMultiprotocol;

  /// No description provided for @datasetShareApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get datasetShareApps;

  /// No description provided for @datasetCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get datasetCreating;

  /// No description provided for @datasetOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The TrueNAS operation failed.'**
  String get datasetOperationFailed;

  /// No description provided for @datasetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit dataset'**
  String get datasetEditTitle;

  /// No description provided for @datasetReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review dataset changes'**
  String get datasetReviewTitle;

  /// No description provided for @datasetApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get datasetApplyChanges;

  /// No description provided for @datasetReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get datasetReview;

  /// No description provided for @datasetComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get datasetComments;

  /// No description provided for @datasetCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get datasetCompression;

  /// No description provided for @datasetSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get datasetSync;

  /// No description provided for @datasetSyncInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetSyncInherit;

  /// No description provided for @datasetSyncStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get datasetSyncStandard;

  /// No description provided for @datasetSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get datasetSyncDisabled;

  /// No description provided for @datasetSyncAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get datasetSyncAlways;

  /// No description provided for @datasetAtimeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get datasetAtimeDisabled;

  /// No description provided for @datasetReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get datasetReadOnly;

  /// No description provided for @datasetReadOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Block writes to this dataset'**
  String get datasetReadOnlyDescription;

  /// No description provided for @datasetReadOnlyWarning.
  ///
  /// In en, this message translates to:
  /// **'Applications and shares writing to this dataset will start failing.'**
  String get datasetReadOnlyWarning;

  /// No description provided for @datasetQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get datasetQuota;

  /// No description provided for @datasetDataQuota.
  ///
  /// In en, this message translates to:
  /// **'Data quota'**
  String get datasetDataQuota;

  /// No description provided for @datasetDataQuotaDescription.
  ///
  /// In en, this message translates to:
  /// **'Limits only the data written directly to this dataset.'**
  String get datasetDataQuotaDescription;

  /// No description provided for @datasetDatasetQuota.
  ///
  /// In en, this message translates to:
  /// **'Dataset quota'**
  String get datasetDatasetQuota;

  /// No description provided for @datasetDatasetQuotaDescription.
  ///
  /// In en, this message translates to:
  /// **'Limits this dataset and its children, including snapshots.'**
  String get datasetDatasetQuotaDescription;

  /// No description provided for @datasetQuotaLeaveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no limit'**
  String get datasetQuotaLeaveEmpty;

  /// No description provided for @datasetQuotaEnterPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter quota sizes as a positive number.'**
  String get datasetQuotaEnterPositive;

  /// No description provided for @datasetNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed for this dataset.'**
  String get datasetNothingChanged;

  /// No description provided for @datasetReadOnlyReviewWarning.
  ///
  /// In en, this message translates to:
  /// **'Applications and shares writing to this dataset will start failing until read-only is turned off again.'**
  String get datasetReadOnlyReviewWarning;

  /// No description provided for @datasetSyncDisabledWarning.
  ///
  /// In en, this message translates to:
  /// **'Disabling sync risks losing recent writes if the server loses power.'**
  String get datasetSyncDisabledWarning;

  /// No description provided for @datasetChangeCommentsInherited.
  ///
  /// In en, this message translates to:
  /// **'Comments inherit from the parent.'**
  String get datasetChangeCommentsInherited;

  /// No description provided for @datasetChangeCommentsCleared.
  ///
  /// In en, this message translates to:
  /// **'Comments cleared.'**
  String get datasetChangeCommentsCleared;

  /// No description provided for @datasetChangeCommentsSet.
  ///
  /// In en, this message translates to:
  /// **'Comments set to “{value}”.'**
  String datasetChangeCommentsSet(String value);

  /// No description provided for @datasetChangeQuotaInherited.
  ///
  /// In en, this message translates to:
  /// **'Dataset quota inherits from the parent.'**
  String get datasetChangeQuotaInherited;

  /// No description provided for @datasetChangeQuotaRemoved.
  ///
  /// In en, this message translates to:
  /// **'Dataset quota removed.'**
  String get datasetChangeQuotaRemoved;

  /// No description provided for @datasetChangeQuotaSet.
  ///
  /// In en, this message translates to:
  /// **'Dataset quota set to {value}.'**
  String datasetChangeQuotaSet(String value);

  /// No description provided for @datasetChangeRefquotaInherited.
  ///
  /// In en, this message translates to:
  /// **'Data quota inherits from the parent.'**
  String get datasetChangeRefquotaInherited;

  /// No description provided for @datasetChangeRefquotaRemoved.
  ///
  /// In en, this message translates to:
  /// **'Data quota removed.'**
  String get datasetChangeRefquotaRemoved;

  /// No description provided for @datasetChangeRefquotaSet.
  ///
  /// In en, this message translates to:
  /// **'Data quota set to {value}.'**
  String datasetChangeRefquotaSet(String value);

  /// No description provided for @datasetChangeReadOnlyInherited.
  ///
  /// In en, this message translates to:
  /// **'Read-only inherits from the parent.'**
  String get datasetChangeReadOnlyInherited;

  /// No description provided for @datasetChangeReadOnlyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dataset becomes read-only.'**
  String get datasetChangeReadOnlyEnabled;

  /// No description provided for @datasetChangeReadOnlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Dataset becomes writable.'**
  String get datasetChangeReadOnlyDisabled;

  /// No description provided for @datasetChangeCompressionInherited.
  ///
  /// In en, this message translates to:
  /// **'Compression inherits from the parent.'**
  String get datasetChangeCompressionInherited;

  /// No description provided for @datasetChangeCompressionSet.
  ///
  /// In en, this message translates to:
  /// **'Compression set to {value}.'**
  String datasetChangeCompressionSet(String value);

  /// No description provided for @datasetChangeSyncInherited.
  ///
  /// In en, this message translates to:
  /// **'Sync inherits from the parent.'**
  String get datasetChangeSyncInherited;

  /// No description provided for @datasetChangeSyncSet.
  ///
  /// In en, this message translates to:
  /// **'Sync set to {value}.'**
  String datasetChangeSyncSet(String value);

  /// No description provided for @datasetChangePropertyUpdated.
  ///
  /// In en, this message translates to:
  /// **'{property} updated.'**
  String datasetChangePropertyUpdated(String property);

  /// No description provided for @datasetCompressionInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetCompressionInherit;

  /// No description provided for @datasetCompressionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get datasetCompressionOff;

  /// No description provided for @datasetCompressionLz4.
  ///
  /// In en, this message translates to:
  /// **'LZ4'**
  String get datasetCompressionLz4;

  /// No description provided for @datasetCompressionZstd.
  ///
  /// In en, this message translates to:
  /// **'ZSTD'**
  String get datasetCompressionZstd;

  /// No description provided for @datasetCompressionGzip.
  ///
  /// In en, this message translates to:
  /// **'GZIP'**
  String get datasetCompressionGzip;

  /// No description provided for @datasetCompressionZle.
  ///
  /// In en, this message translates to:
  /// **'ZLE'**
  String get datasetCompressionZle;

  /// No description provided for @datasetCompressionLzjb.
  ///
  /// In en, this message translates to:
  /// **'LZJB'**
  String get datasetCompressionLzjb;

  /// No description provided for @datasetAtimeInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetAtimeInherit;

  /// No description provided for @datasetAtimeOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get datasetAtimeOn;

  /// No description provided for @datasetExecInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetExecInherit;

  /// No description provided for @datasetExecOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get datasetExecOn;

  /// No description provided for @datasetExecOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get datasetExecOff;

  /// No description provided for @datasetBlockSizeInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetBlockSizeInherit;

  /// No description provided for @datasetStorageInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get datasetStorageInherit;

  /// No description provided for @poolCreateReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review new pool'**
  String get poolCreateReviewTitle;

  /// No description provided for @poolCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create pool'**
  String get poolCreateTitle;

  /// No description provided for @poolCreateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get poolCreateClose;

  /// No description provided for @poolCreateBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get poolCreateBack;

  /// No description provided for @poolCreateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get poolCreateCancel;

  /// No description provided for @poolCreateReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get poolCreateReview;

  /// No description provided for @poolCreateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Pool name'**
  String get poolCreateNameLabel;

  /// No description provided for @poolCreateNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Used as the dataset root. Start with a letter.'**
  String get poolCreateNameHelper;

  /// No description provided for @poolCreateDataVdevs.
  ///
  /// In en, this message translates to:
  /// **'Data vdevs'**
  String get poolCreateDataVdevs;

  /// No description provided for @poolCreateDataVdevsDescription.
  ///
  /// In en, this message translates to:
  /// **'The data tier is required. Each vdev groups disks with one layout. A pool stripes across multiple data vdevs.'**
  String get poolCreateDataVdevsDescription;

  /// No description provided for @poolCreateVdevLayout.
  ///
  /// In en, this message translates to:
  /// **'Vdev layout'**
  String get poolCreateVdevLayout;

  /// No description provided for @poolCreateAddDataVdev.
  ///
  /// In en, this message translates to:
  /// **'Add data vdev'**
  String get poolCreateAddDataVdev;

  /// No description provided for @poolCreateDataVdevLabel.
  ///
  /// In en, this message translates to:
  /// **'Data vdev {index}'**
  String poolCreateDataVdevLabel(int index);

  /// No description provided for @poolCreateCache.
  ///
  /// In en, this message translates to:
  /// **'Cache (L2ARC, optional)'**
  String get poolCreateCache;

  /// No description provided for @poolCreateCacheVdevLabel.
  ///
  /// In en, this message translates to:
  /// **'Cache vdev {index}'**
  String poolCreateCacheVdevLabel(int index);

  /// No description provided for @poolCreateAddCacheVdev.
  ///
  /// In en, this message translates to:
  /// **'Add cache vdev'**
  String get poolCreateAddCacheVdev;

  /// No description provided for @poolCreateOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get poolCreateOptions;

  /// No description provided for @poolCreateEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get poolCreateEncryption;

  /// No description provided for @poolCreateEncryptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypts the pool at rest. You must manage the keys.'**
  String get poolCreateEncryptionSubtitle;

  /// No description provided for @poolCreateDeduplication.
  ///
  /// In en, this message translates to:
  /// **'Deduplication'**
  String get poolCreateDeduplication;

  /// No description provided for @poolCreateDeduplicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Block-based dedup. Uses more memory; check your RAM before enabling.'**
  String get poolCreateDeduplicationSubtitle;

  /// No description provided for @poolCreateAutoTrim.
  ///
  /// In en, this message translates to:
  /// **'Auto TRIM'**
  String get poolCreateAutoTrim;

  /// No description provided for @poolCreateAutoTrimSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reclaims unused space automatically.'**
  String get poolCreateAutoTrimSubtitle;

  /// No description provided for @poolCreateReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get poolCreateReviewName;

  /// No description provided for @poolCreateReviewDataVdevsValue.
  ///
  /// In en, this message translates to:
  /// **'{vdevCount} · {diskCount, plural, =1{1 disk} other{{diskCount} disks}}'**
  String poolCreateReviewDataVdevsValue(int vdevCount, int diskCount);

  /// No description provided for @poolCreateReviewVdevLabel.
  ///
  /// In en, this message translates to:
  /// **'  vdev {index}'**
  String poolCreateReviewVdevLabel(int index);

  /// No description provided for @poolCreateReviewVdevValue.
  ///
  /// In en, this message translates to:
  /// **'{type} · {diskCount, plural, =1{1 disk} other{{diskCount} disks}}'**
  String poolCreateReviewVdevValue(String type, int diskCount);

  /// No description provided for @poolCreateReviewCacheVdevs.
  ///
  /// In en, this message translates to:
  /// **'Cache vdevs'**
  String get poolCreateReviewCacheVdevs;

  /// No description provided for @poolCreateReviewCacheVdevsValue.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String poolCreateReviewCacheVdevsValue(int count);

  /// No description provided for @poolCreateReviewTotalDisks.
  ///
  /// In en, this message translates to:
  /// **'Total disks'**
  String get poolCreateReviewTotalDisks;

  /// No description provided for @poolCreateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get poolCreateOn;

  /// No description provided for @poolCreateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get poolCreateOff;

  /// No description provided for @poolCreateNoticeEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Creating an encrypted pool formats every selected disk. You must keep the recovery key safe or the data is unrecoverable.'**
  String get poolCreateNoticeEncrypted;

  /// No description provided for @poolCreateNoticePlain.
  ///
  /// In en, this message translates to:
  /// **'Creating a pool formats every selected disk. Existing data on those disks is lost.'**
  String get poolCreateNoticePlain;

  /// No description provided for @poolCreateNoticeDedup.
  ///
  /// In en, this message translates to:
  /// **'Deduplication increases memory use. Disable it if the server runs out of memory under load.'**
  String get poolCreateNoticeDedup;

  /// No description provided for @poolCreateNoticeStripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe and single-disk pools have no redundancy. A disk failure loses the pool. Use a mirror or RAIDZ for safety.'**
  String get poolCreateNoticeStripe;

  /// No description provided for @poolCreateNoDisksSelected.
  ///
  /// In en, this message translates to:
  /// **'No disks selected'**
  String get poolCreateNoDisksSelected;

  /// No description provided for @poolCreateDisksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 disk: {names}} other{{count} disks: {names}}}'**
  String poolCreateDisksCount(int count, String names);

  /// No description provided for @poolCreateRemoveVdev.
  ///
  /// In en, this message translates to:
  /// **'Remove vdev'**
  String get poolCreateRemoveVdev;

  /// No description provided for @poolCreateSelectDisks.
  ///
  /// In en, this message translates to:
  /// **'Select disks'**
  String get poolCreateSelectDisks;

  /// No description provided for @poolCreateDiskPickerHint.
  ///
  /// In en, this message translates to:
  /// **'{type} needs at least {minimum} disk(s). Selected: {selected}'**
  String poolCreateDiskPickerHint(String type, int minimum, int selected);

  /// No description provided for @poolCreateAddDisks.
  ///
  /// In en, this message translates to:
  /// **'Add {count, plural, =1{1 disk} other{{count} disks}}'**
  String poolCreateAddDisks(int count);

  /// No description provided for @poolCreateSelectAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Select at least {minimum}'**
  String poolCreateSelectAtLeast(int minimum);

  /// No description provided for @poolVdevStripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get poolVdevStripe;

  /// No description provided for @poolVdevMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get poolVdevMirror;

  /// No description provided for @poolVdevRaidz1.
  ///
  /// In en, this message translates to:
  /// **'RAIDZ1'**
  String get poolVdevRaidz1;

  /// No description provided for @poolVdevRaidz2.
  ///
  /// In en, this message translates to:
  /// **'RAIDZ2'**
  String get poolVdevRaidz2;

  /// No description provided for @poolVdevRaidz3.
  ///
  /// In en, this message translates to:
  /// **'RAIDZ3'**
  String get poolVdevRaidz3;

  /// No description provided for @poolVdevStripeWarning.
  ///
  /// In en, this message translates to:
  /// **'No redundancy. A single disk failure loses the pool.'**
  String get poolVdevStripeWarning;

  /// No description provided for @poolVdevMirrorWarning.
  ///
  /// In en, this message translates to:
  /// **'Tolerates one disk failure per pair.'**
  String get poolVdevMirrorWarning;

  /// No description provided for @poolVdevRaidz1Warning.
  ///
  /// In en, this message translates to:
  /// **'Tolerates one disk failure.'**
  String get poolVdevRaidz1Warning;

  /// No description provided for @poolVdevRaidz2Warning.
  ///
  /// In en, this message translates to:
  /// **'Tolerates two disk failures.'**
  String get poolVdevRaidz2Warning;

  /// No description provided for @poolVdevRaidz3Warning.
  ///
  /// In en, this message translates to:
  /// **'Tolerates three disk failures.'**
  String get poolVdevRaidz3Warning;

  /// No description provided for @poolValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a pool name.'**
  String get poolValidationNameRequired;

  /// No description provided for @poolValidationNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Start with a letter and use letters, numbers, or . _ : -.'**
  String get poolValidationNameInvalid;

  /// No description provided for @poolValidationDataVdevRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one data vdev.'**
  String get poolValidationDataVdevRequired;

  /// No description provided for @poolValidationDataVdevNoDisks.
  ///
  /// In en, this message translates to:
  /// **'Data vdev {index} has no disks.'**
  String poolValidationDataVdevNoDisks(int index);

  /// No description provided for @poolValidationMinimumDisks.
  ///
  /// In en, this message translates to:
  /// **'{type} vdev {index} needs at least {minimum} disks.'**
  String poolValidationMinimumDisks(String type, int index, int minimum);

  /// No description provided for @iscsiTargetReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review iSCSI target'**
  String get iscsiTargetReviewTitle;

  /// No description provided for @iscsiTargetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iSCSI target'**
  String get iscsiTargetEditTitle;

  /// No description provided for @iscsiTargetNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New iSCSI target'**
  String get iscsiTargetNewTitle;

  /// No description provided for @iscsiTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Target identity, access, and portal groups'**
  String get iscsiTargetSubtitle;

  /// No description provided for @iscsiTargetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get iscsiTargetClose;

  /// No description provided for @iscsiTargetBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get iscsiTargetBack;

  /// No description provided for @iscsiTargetCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get iscsiTargetCancel;

  /// No description provided for @iscsiTargetSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get iscsiTargetSaveChanges;

  /// No description provided for @iscsiTargetCreate.
  ///
  /// In en, this message translates to:
  /// **'Create target'**
  String get iscsiTargetCreate;

  /// No description provided for @iscsiTargetReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get iscsiTargetReview;

  /// No description provided for @iscsiTargetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Target name'**
  String get iscsiTargetNameLabel;

  /// No description provided for @iscsiTargetNameHelper.
  ///
  /// In en, this message translates to:
  /// **'An IQN or another unique target name'**
  String get iscsiTargetNameHelper;

  /// No description provided for @iscsiTargetAliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get iscsiTargetAliasLabel;

  /// No description provided for @iscsiTargetAliasHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional human-readable target label'**
  String get iscsiTargetAliasHelper;

  /// No description provided for @iscsiTargetNetworksLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorized networks'**
  String get iscsiTargetNetworksLabel;

  /// No description provided for @iscsiTargetNetworksHelper.
  ///
  /// In en, this message translates to:
  /// **'One CIDR network per line · empty allows all networks'**
  String get iscsiTargetNetworksHelper;

  /// No description provided for @iscsiTargetQueuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Queued commands'**
  String get iscsiTargetQueuedLabel;

  /// No description provided for @iscsiTargetQueuedHelper.
  ///
  /// In en, this message translates to:
  /// **'Use the server default unless a workload requires tuning'**
  String get iscsiTargetQueuedHelper;

  /// No description provided for @iscsiTargetQueueServerDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get iscsiTargetQueueServerDefault;

  /// No description provided for @iscsiTargetQueue32.
  ///
  /// In en, this message translates to:
  /// **'32 commands'**
  String get iscsiTargetQueue32;

  /// No description provided for @iscsiTargetQueue128.
  ///
  /// In en, this message translates to:
  /// **'128 commands'**
  String get iscsiTargetQueue128;

  /// No description provided for @iscsiTargetGroups.
  ///
  /// In en, this message translates to:
  /// **'Target groups'**
  String get iscsiTargetGroups;

  /// No description provided for @iscsiTargetAddGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get iscsiTargetAddGroup;

  /// No description provided for @iscsiTargetGroupsDescription.
  ///
  /// In en, this message translates to:
  /// **'Each group binds a portal to all initiators or a selected initiator group.'**
  String get iscsiTargetGroupsDescription;

  /// No description provided for @iscsiTargetNoGroupsNotice.
  ///
  /// In en, this message translates to:
  /// **'This target has no portal groups and will be unreachable until a group is added.'**
  String get iscsiTargetNoGroupsNotice;

  /// No description provided for @iscsiTargetNoPortalsNotice.
  ///
  /// In en, this message translates to:
  /// **'No iSCSI portals are available. Create a portal before adding a target group.'**
  String get iscsiTargetNoPortalsNotice;

  /// No description provided for @iscsiTargetUnrestrictedNotice.
  ///
  /// In en, this message translates to:
  /// **'An unauthenticated group allows every initiator from every authorized network. With no authorized networks, it is open to every network.'**
  String get iscsiTargetUnrestrictedNotice;

  /// No description provided for @iscsiTargetMutualChapGroup.
  ///
  /// In en, this message translates to:
  /// **'Mutual CHAP group'**
  String get iscsiTargetMutualChapGroup;

  /// No description provided for @iscsiTargetChapGroup.
  ///
  /// In en, this message translates to:
  /// **'CHAP group'**
  String get iscsiTargetChapGroup;

  /// No description provided for @iscsiTargetPortalValue.
  ///
  /// In en, this message translates to:
  /// **'Portal: {value}'**
  String iscsiTargetPortalValue(String value);

  /// No description provided for @iscsiTargetInitiatorsValue.
  ///
  /// In en, this message translates to:
  /// **'Initiators: {value}'**
  String iscsiTargetInitiatorsValue(String value);

  /// No description provided for @iscsiTargetCredentialValue.
  ///
  /// In en, this message translates to:
  /// **'Credential ID: {value}'**
  String iscsiTargetCredentialValue(String value);

  /// No description provided for @iscsiTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get iscsiTargetUnavailable;

  /// No description provided for @iscsiTargetLockedAuthNotice.
  ///
  /// In en, this message translates to:
  /// **'Authentication credentials are preserved and cannot be changed or removed in this release.'**
  String get iscsiTargetLockedAuthNotice;

  /// No description provided for @iscsiTargetUnauthenticatedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unauthenticated group {index}'**
  String iscsiTargetUnauthenticatedGroup(int index);

  /// No description provided for @iscsiTargetRemoveGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove group {index}'**
  String iscsiTargetRemoveGroup(int index);

  /// No description provided for @iscsiTargetPortalLabel.
  ///
  /// In en, this message translates to:
  /// **'Portal'**
  String get iscsiTargetPortalLabel;

  /// No description provided for @iscsiTargetInitiatorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Initiators'**
  String get iscsiTargetInitiatorsLabel;

  /// No description provided for @iscsiTargetAllInitiators.
  ///
  /// In en, this message translates to:
  /// **'All initiators'**
  String get iscsiTargetAllInitiators;

  /// No description provided for @iscsiTargetAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get iscsiTargetAuthentication;

  /// No description provided for @iscsiTargetAuthNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get iscsiTargetAuthNone;

  /// No description provided for @iscsiTargetChapOneWay.
  ///
  /// In en, this message translates to:
  /// **'CHAP (one-way)'**
  String get iscsiTargetChapOneWay;

  /// No description provided for @iscsiTargetChapMutual.
  ///
  /// In en, this message translates to:
  /// **'CHAP (mutual)'**
  String get iscsiTargetChapMutual;

  /// No description provided for @iscsiTargetChapCredential.
  ///
  /// In en, this message translates to:
  /// **'CHAP credential'**
  String get iscsiTargetChapCredential;

  /// No description provided for @iscsiTargetNoChapCredentials.
  ///
  /// In en, this message translates to:
  /// **'No CHAP credentials are configured. Create one first.'**
  String get iscsiTargetNoChapCredentials;

  /// No description provided for @iscsiTargetChapRequiredNotice.
  ///
  /// In en, this message translates to:
  /// **'CHAP authentication requires at least one credential. Create one under CHAP credentials before adding an authenticated group.'**
  String get iscsiTargetChapRequiredNotice;

  /// No description provided for @iscsiTargetReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get iscsiTargetReviewName;

  /// No description provided for @iscsiTargetReviewNetworks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get iscsiTargetReviewNetworks;

  /// No description provided for @iscsiTargetAllNetworks.
  ///
  /// In en, this message translates to:
  /// **'All networks'**
  String get iscsiTargetAllNetworks;

  /// No description provided for @iscsiTargetQueueDepth.
  ///
  /// In en, this message translates to:
  /// **'Queue depth'**
  String get iscsiTargetQueueDepth;

  /// No description provided for @iscsiTargetReviewGroup.
  ///
  /// In en, this message translates to:
  /// **'Group {index} · {authMethod}'**
  String iscsiTargetReviewGroup(int index, String authMethod);

  /// No description provided for @iscsiTargetCredentialId.
  ///
  /// In en, this message translates to:
  /// **'Credential ID {id}'**
  String iscsiTargetCredentialId(String id);

  /// No description provided for @iscsiTargetReviewNoGroupNotice.
  ///
  /// In en, this message translates to:
  /// **'This target will be created without a portal group and will be unreachable until one is added.'**
  String get iscsiTargetReviewNoGroupNotice;

  /// No description provided for @iscsiTargetReviewUnrestrictedNotice.
  ///
  /// In en, this message translates to:
  /// **'This target includes an unauthenticated group open to every initiator. With no authorized networks, it is open to every network.'**
  String get iscsiTargetReviewUnrestrictedNotice;

  /// No description provided for @iscsiTargetReviewValidationNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will validate the target name, networks, portals, initiators, and preserved authentication groups.'**
  String get iscsiTargetReviewValidationNotice;

  /// No description provided for @iscsiTargetPortalTag.
  ///
  /// In en, this message translates to:
  /// **'Portal {tag}'**
  String iscsiTargetPortalTag(int tag);

  /// No description provided for @iscsiTargetPortalTagDetail.
  ///
  /// In en, this message translates to:
  /// **'Portal {tag} · {detail}'**
  String iscsiTargetPortalTagDetail(int tag, String detail);

  /// No description provided for @iscsiTargetPortalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Portal ID {id} · unavailable'**
  String iscsiTargetPortalUnavailable(int id);

  /// No description provided for @iscsiTargetInitiatorGroup.
  ///
  /// In en, this message translates to:
  /// **'Initiator group {id}'**
  String iscsiTargetInitiatorGroup(int id);

  /// No description provided for @iscsiTargetInitiatorGroupDetail.
  ///
  /// In en, this message translates to:
  /// **'Initiator group {id} · {detail}'**
  String iscsiTargetInitiatorGroupDetail(int id, String detail);

  /// No description provided for @iscsiTargetInitiatorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Initiator ID {id} · unavailable'**
  String iscsiTargetInitiatorUnavailable(int id);

  /// No description provided for @iscsiTargetValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a target name between 1 and 120 characters.'**
  String get iscsiTargetValidationName;

  /// No description provided for @iscsiTargetValidationGroups.
  ///
  /// In en, this message translates to:
  /// **'Use available portals and initiators with unique, valid authentication groups.'**
  String get iscsiTargetValidationGroups;

  /// No description provided for @iscsiTargetValidationNetworks.
  ///
  /// In en, this message translates to:
  /// **'Use unique IPv4 or IPv6 networks in CIDR notation.'**
  String get iscsiTargetValidationNetworks;

  /// No description provided for @iscsiTargetValidationQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued commands must be 32 or 128.'**
  String get iscsiTargetValidationQueued;

  /// No description provided for @smbReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review SMB share'**
  String get smbReviewTitle;

  /// No description provided for @smbEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit SMB share'**
  String get smbEditTitle;

  /// No description provided for @smbNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New SMB share'**
  String get smbNewTitle;

  /// No description provided for @smbClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get smbClose;

  /// No description provided for @smbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get smbBack;

  /// No description provided for @smbCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get smbCancel;

  /// No description provided for @smbSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get smbSaveChanges;

  /// No description provided for @smbCreateShare.
  ///
  /// In en, this message translates to:
  /// **'Create share'**
  String get smbCreateShare;

  /// No description provided for @smbReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get smbReview;

  /// No description provided for @smbPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get smbPurpose;

  /// No description provided for @smbShareName.
  ///
  /// In en, this message translates to:
  /// **'Share name'**
  String get smbShareName;

  /// No description provided for @smbSharePath.
  ///
  /// In en, this message translates to:
  /// **'Share path'**
  String get smbSharePath;

  /// No description provided for @smbSharePathHelper.
  ///
  /// In en, this message translates to:
  /// **'An existing path in a ZFS pool under /mnt/'**
  String get smbSharePathHelper;

  /// No description provided for @smbExternalDestinations.
  ///
  /// In en, this message translates to:
  /// **'External destinations'**
  String get smbExternalDestinations;

  /// No description provided for @smbExternalDestinationsHelper.
  ///
  /// In en, this message translates to:
  /// **'One SERVER\\SHARE destination per line'**
  String get smbExternalDestinationsHelper;

  /// No description provided for @smbComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get smbComment;

  /// No description provided for @smbEnableShare.
  ///
  /// In en, this message translates to:
  /// **'Enable share'**
  String get smbEnableShare;

  /// No description provided for @smbEnableShareDescription.
  ///
  /// In en, this message translates to:
  /// **'Make the share available over SMB.'**
  String get smbEnableShareDescription;

  /// No description provided for @smbReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get smbReadOnly;

  /// No description provided for @smbReadOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Prevent SMB clients from changing files.'**
  String get smbReadOnlyDescription;

  /// No description provided for @smbShowInBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Show in network browsing'**
  String get smbShowInBrowsing;

  /// No description provided for @smbAccessBasedEnumeration.
  ///
  /// In en, this message translates to:
  /// **'Access-based enumeration'**
  String get smbAccessBasedEnumeration;

  /// No description provided for @smbAccessBasedEnumerationDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the share only to users allowed by its share ACL.'**
  String get smbAccessBasedEnumerationDescription;

  /// No description provided for @smbNetworkRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Network restrictions'**
  String get smbNetworkRestrictions;

  /// No description provided for @smbNetworkRestrictionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional IP addresses, subnets, or ALL'**
  String get smbNetworkRestrictionsDescription;

  /// No description provided for @smbAllowedHosts.
  ///
  /// In en, this message translates to:
  /// **'Allowed hosts'**
  String get smbAllowedHosts;

  /// No description provided for @smbAllowedHostsHelper.
  ///
  /// In en, this message translates to:
  /// **'One entry per line · empty allows normal access'**
  String get smbAllowedHostsHelper;

  /// No description provided for @smbDeniedHosts.
  ///
  /// In en, this message translates to:
  /// **'Denied hosts'**
  String get smbDeniedHosts;

  /// No description provided for @smbOneEntryPerLine.
  ///
  /// In en, this message translates to:
  /// **'One entry per line'**
  String get smbOneEntryPerLine;

  /// No description provided for @smbAuditing.
  ///
  /// In en, this message translates to:
  /// **'Auditing'**
  String get smbAuditing;

  /// No description provided for @smbAuditingDescription.
  ///
  /// In en, this message translates to:
  /// **'Record SMB access for selected groups'**
  String get smbAuditingDescription;

  /// No description provided for @smbEnableAuditing.
  ///
  /// In en, this message translates to:
  /// **'Enable auditing'**
  String get smbEnableAuditing;

  /// No description provided for @smbGroupsToAudit.
  ///
  /// In en, this message translates to:
  /// **'Groups to audit'**
  String get smbGroupsToAudit;

  /// No description provided for @smbGroupsToAuditHelper.
  ///
  /// In en, this message translates to:
  /// **'One group per line · empty audits all groups'**
  String get smbGroupsToAuditHelper;

  /// No description provided for @smbGroupsToIgnore.
  ///
  /// In en, this message translates to:
  /// **'Groups to ignore'**
  String get smbGroupsToIgnore;

  /// No description provided for @smbOneGroupPerLine.
  ///
  /// In en, this message translates to:
  /// **'One group per line'**
  String get smbOneGroupPerLine;

  /// No description provided for @smbTimeMachineQuota.
  ///
  /// In en, this message translates to:
  /// **'Time Machine quota (bytes)'**
  String get smbTimeMachineQuota;

  /// No description provided for @smbZeroDisablesServerQuota.
  ///
  /// In en, this message translates to:
  /// **'0 disables the server-side quota'**
  String get smbZeroDisablesServerQuota;

  /// No description provided for @smbSnapshotAfterBackup.
  ///
  /// In en, this message translates to:
  /// **'Snapshot after a new backup'**
  String get smbSnapshotAfterBackup;

  /// No description provided for @smbDatasetPerUser.
  ///
  /// In en, this message translates to:
  /// **'Create a dataset per user'**
  String get smbDatasetPerUser;

  /// No description provided for @smbGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Write grace period (seconds)'**
  String get smbGracePeriod;

  /// No description provided for @smbPerUserQuota.
  ///
  /// In en, this message translates to:
  /// **'Per-user quota (GiB)'**
  String get smbPerUserQuota;

  /// No description provided for @smbZeroDisablesAutoQuota.
  ///
  /// In en, this message translates to:
  /// **'0 disables automatic quotas'**
  String get smbZeroDisablesAutoQuota;

  /// No description provided for @smbAppleFilenameMangling.
  ///
  /// In en, this message translates to:
  /// **'Apple filename mangling'**
  String get smbAppleFilenameMangling;

  /// No description provided for @smbAppleFilenameManglingDescription.
  ///
  /// In en, this message translates to:
  /// **'Preserve macOS filename characters that are illegal on Windows.'**
  String get smbAppleFilenameManglingDescription;

  /// No description provided for @smbDatasetNamingSchema.
  ///
  /// In en, this message translates to:
  /// **'Dataset naming schema'**
  String get smbDatasetNamingSchema;

  /// No description provided for @smbDatasetNamingSchemaHelper.
  ///
  /// In en, this message translates to:
  /// **'For example %U or %D/%U'**
  String get smbDatasetNamingSchemaHelper;

  /// No description provided for @smbFinalCutNotice.
  ///
  /// In en, this message translates to:
  /// **'Final Cut Pro forces Apple filename mangling and requires global Apple SMB extensions.'**
  String get smbFinalCutNotice;

  /// No description provided for @smbExternalNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS does not verify that external DFS destinations are reachable.'**
  String get smbExternalNotice;

  /// No description provided for @smbUnsupportedNotice.
  ///
  /// In en, this message translates to:
  /// **'This legacy or server-specific share can only be inspected.'**
  String get smbUnsupportedNotice;

  /// No description provided for @smbReviewShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get smbReviewShare;

  /// No description provided for @smbReviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get smbReviewLocation;

  /// No description provided for @smbReviewAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get smbReviewAccess;

  /// No description provided for @smbReadAndWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get smbReadAndWrite;

  /// No description provided for @smbVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get smbVisibility;

  /// No description provided for @smbBrowsableWhenAclPermits.
  ///
  /// In en, this message translates to:
  /// **'Browsable when ACL permits'**
  String get smbBrowsableWhenAclPermits;

  /// No description provided for @smbBrowsable.
  ///
  /// In en, this message translates to:
  /// **'Browsable'**
  String get smbBrowsable;

  /// No description provided for @smbHiddenFromBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Hidden from browsing'**
  String get smbHiddenFromBrowsing;

  /// No description provided for @smbState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get smbState;

  /// No description provided for @smbEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get smbEnabled;

  /// No description provided for @smbDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get smbDisabled;

  /// No description provided for @smbTimeLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'Time locking applies only through this SMB share and is not a regulatory write-once guarantee.'**
  String get smbTimeLockedNotice;

  /// No description provided for @smbMultiprotocolNotice.
  ///
  /// In en, this message translates to:
  /// **'Multiprotocol compatibility disables some SMB optimizations for safer external access.'**
  String get smbMultiprotocolNotice;

  /// No description provided for @smbValidationNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will validate the path, share name, purpose options, permissions, and SMB prerequisites.'**
  String get smbValidationNotice;

  /// No description provided for @smbPurposeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default share'**
  String get smbPurposeDefault;

  /// No description provided for @smbPurposeTimeMachine.
  ///
  /// In en, this message translates to:
  /// **'Time Machine'**
  String get smbPurposeTimeMachine;

  /// No description provided for @smbPurposeMultiprotocol.
  ///
  /// In en, this message translates to:
  /// **'Multiprotocol'**
  String get smbPurposeMultiprotocol;

  /// No description provided for @smbPurposeTimeLocked.
  ///
  /// In en, this message translates to:
  /// **'Time locked'**
  String get smbPurposeTimeLocked;

  /// No description provided for @smbPurposePrivateDatasets.
  ///
  /// In en, this message translates to:
  /// **'Private datasets'**
  String get smbPurposePrivateDatasets;

  /// No description provided for @smbPurposeExternal.
  ///
  /// In en, this message translates to:
  /// **'External DFS'**
  String get smbPurposeExternal;

  /// No description provided for @smbPurposeFinalCut.
  ///
  /// In en, this message translates to:
  /// **'Final Cut Pro'**
  String get smbPurposeFinalCut;

  /// No description provided for @smbPurposeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get smbPurposeUnsupported;

  /// No description provided for @smbPurposeDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Best compatibility for ordinary SMB clients.'**
  String get smbPurposeDefaultDescription;

  /// No description provided for @smbPurposeTimeMachineDescription.
  ///
  /// In en, this message translates to:
  /// **'Advertise storage as an Apple Time Machine destination.'**
  String get smbPurposeTimeMachineDescription;

  /// No description provided for @smbPurposeMultiprotocolDescription.
  ///
  /// In en, this message translates to:
  /// **'Safer interoperability when the same data is accessed outside SMB.'**
  String get smbPurposeMultiprotocolDescription;

  /// No description provided for @smbPurposeTimeLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'Make files read-only through SMB after a grace period.'**
  String get smbPurposeTimeLockedDescription;

  /// No description provided for @smbPurposePrivateDatasetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a separate ZFS dataset for each connecting user.'**
  String get smbPurposePrivateDatasetsDescription;

  /// No description provided for @smbPurposeExternalDescription.
  ///
  /// In en, this message translates to:
  /// **'Proxy clients to a share hosted on another SMB server.'**
  String get smbPurposeExternalDescription;

  /// No description provided for @smbPurposeFinalCutDescription.
  ///
  /// In en, this message translates to:
  /// **'Storage configured for Apple Final Cut Pro workflows.'**
  String get smbPurposeFinalCutDescription;

  /// No description provided for @smbPurposeUnsupportedDescription.
  ///
  /// In en, this message translates to:
  /// **'This server share purpose cannot be edited by TrueDock.'**
  String get smbPurposeUnsupportedDescription;

  /// No description provided for @smbValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a share name.'**
  String get smbValidationNameRequired;

  /// No description provided for @smbValidationNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid unique SMB share name.'**
  String get smbValidationNameInvalid;

  /// No description provided for @smbValidationPurpose.
  ///
  /// In en, this message translates to:
  /// **'This SMB share purpose cannot be edited.'**
  String get smbValidationPurpose;

  /// No description provided for @smbValidationPath.
  ///
  /// In en, this message translates to:
  /// **'Choose a dataset path under /mnt/.'**
  String get smbValidationPath;

  /// No description provided for @smbValidationRemotePaths.
  ///
  /// In en, this message translates to:
  /// **'Use one SERVER\\SHARE destination per line.'**
  String get smbValidationRemotePaths;

  /// No description provided for @smbValidationTimeMachineQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota cannot be negative.'**
  String get smbValidationTimeMachineQuota;

  /// No description provided for @smbValidationGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Grace period must be 60–15,552,000 seconds.'**
  String get smbValidationGracePeriod;

  /// No description provided for @smbValidationAutoQuota.
  ///
  /// In en, this message translates to:
  /// **'Automatic quota cannot be negative.'**
  String get smbValidationAutoQuota;

  /// No description provided for @smbValidationDatasetSchema.
  ///
  /// In en, this message translates to:
  /// **'Enter a dataset naming schema.'**
  String get smbValidationDatasetSchema;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @appsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load apps and services.'**
  String get appsLoadFailed;

  /// No description provided for @appsLandingDescription.
  ///
  /// In en, this message translates to:
  /// **'Control apps, containers, virtual machines, and services.'**
  String get appsLandingDescription;

  /// No description provided for @appsRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh apps'**
  String get appsRefreshTooltip;

  /// No description provided for @appsInstalledApps.
  ///
  /// In en, this message translates to:
  /// **'Installed apps'**
  String get appsInstalledApps;

  /// No description provided for @appsFeatureInstalledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start, stop, update, rollback'**
  String get appsFeatureInstalledSubtitle;

  /// No description provided for @appsDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get appsDiscover;

  /// No description provided for @appsFeatureDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse the configured catalog'**
  String get appsFeatureDiscoverSubtitle;

  /// No description provided for @appsContainers.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get appsContainers;

  /// No description provided for @appsFeatureContainersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instances, metrics, devices'**
  String get appsFeatureContainersSubtitle;

  /// No description provided for @appsVirtualMachines.
  ///
  /// In en, this message translates to:
  /// **'Virtual machines'**
  String get appsVirtualMachines;

  /// No description provided for @appsFeatureVirtualMachinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle, display, devices'**
  String get appsFeatureVirtualMachinesSubtitle;

  /// No description provided for @appsServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get appsServices;

  /// No description provided for @appsFeatureServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'State, startup, configuration'**
  String get appsFeatureServicesSubtitle;

  /// No description provided for @appsNoAppsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No apps are installed.'**
  String get appsNoAppsInstalled;

  /// No description provided for @appsNoVirtualMachines.
  ///
  /// In en, this message translates to:
  /// **'No virtual machines found.'**
  String get appsNoVirtualMachines;

  /// No description provided for @appsContainersUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Standalone containers are not exposed by this TrueNAS version. Installed Apps remain available above.'**
  String get appsContainersUnsupported;

  /// No description provided for @appsNoContainers.
  ///
  /// In en, this message translates to:
  /// **'No standalone containers found.'**
  String get appsNoContainers;

  /// No description provided for @appsInstances.
  ///
  /// In en, this message translates to:
  /// **'Instances'**
  String get appsInstances;

  /// No description provided for @appsInstancesUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This TrueNAS version does not expose the Instances API.'**
  String get appsInstancesUnsupported;

  /// No description provided for @appsInstancesNoPool.
  ///
  /// In en, this message translates to:
  /// **'Instances need a storage pool before any container or VM can be created. Choose one to initialize the platform.'**
  String get appsInstancesNoPool;

  /// No description provided for @appsInstancesChoosePool.
  ///
  /// In en, this message translates to:
  /// **'Choose storage pool'**
  String get appsInstancesChoosePool;

  /// No description provided for @appsInstancesPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage for instances'**
  String get appsInstancesPoolTitle;

  /// No description provided for @appsInstancesPoolConsequence.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS creates a hidden .ix-virt dataset on {pool} and every instance stores its disks there. Moving it later means recreating the instances.'**
  String appsInstancesPoolConsequence(String pool);

  /// No description provided for @appsInstancesPoolApplied.
  ///
  /// In en, this message translates to:
  /// **'Instance storage set to {pool}.'**
  String appsInstancesPoolApplied(String pool);

  /// No description provided for @appsNoInstances.
  ///
  /// In en, this message translates to:
  /// **'No instances yet.'**
  String get appsNoInstances;

  /// No description provided for @appsInstanceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create instance'**
  String get appsInstanceCreate;

  /// No description provided for @appsInstanceKindContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get appsInstanceKindContainer;

  /// No description provided for @appsInstanceKindVm.
  ///
  /// In en, this message translates to:
  /// **'VM'**
  String get appsInstanceKindVm;

  /// No description provided for @appsInstanceLabelImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get appsInstanceLabelImage;

  /// No description provided for @appsInstanceLabelCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get appsInstanceLabelCpu;

  /// No description provided for @appsInstanceLabelMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get appsInstanceLabelMemory;

  /// No description provided for @appsInstanceLabelPool.
  ///
  /// In en, this message translates to:
  /// **'Storage pool'**
  String get appsInstanceLabelPool;

  /// No description provided for @appsInstanceLabelRootDisk.
  ///
  /// In en, this message translates to:
  /// **'Root disk'**
  String get appsInstanceLabelRootDisk;

  /// No description provided for @appsInstanceLabelPrivileged.
  ///
  /// In en, this message translates to:
  /// **'Privileged mode'**
  String get appsInstanceLabelPrivileged;

  /// No description provided for @appsInstanceLabelDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get appsInstanceLabelDevices;

  /// No description provided for @appsInstanceServerDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get appsInstanceServerDefault;

  /// No description provided for @appsInstanceDevicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices attached.'**
  String get appsInstanceDevicesEmpty;

  /// No description provided for @appsInstanceDeviceManaged.
  ///
  /// In en, this message translates to:
  /// **'Managed by TrueNAS'**
  String get appsInstanceDeviceManaged;

  /// No description provided for @appsInstanceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String appsInstanceEditTitle(String name);

  /// No description provided for @appsInstanceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New instance'**
  String get appsInstanceCreateTitle;

  /// No description provided for @appsInstanceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get appsInstanceNameLabel;

  /// No description provided for @appsInstanceNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, and hyphens. Used as the guest hostname.'**
  String get appsInstanceNameHelper;

  /// No description provided for @appsInstanceImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Base image'**
  String get appsInstanceImageLabel;

  /// No description provided for @appsInstanceImagePickerHint.
  ///
  /// In en, this message translates to:
  /// **'Show base image options'**
  String get appsInstanceImagePickerHint;

  /// No description provided for @appsInstanceCpuHelper.
  ///
  /// In en, this message translates to:
  /// **'Core count, or a pinned set such as 0-3. Leave empty for the server default.'**
  String get appsInstanceCpuHelper;

  /// No description provided for @appsInstanceMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory (MiB)'**
  String get appsInstanceMemoryLabel;

  /// No description provided for @appsInstanceRootDiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Root disk (GiB)'**
  String get appsInstanceRootDiskLabel;

  /// No description provided for @appsInstanceAutostart.
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get appsInstanceAutostart;

  /// No description provided for @appsInstanceCreated.
  ///
  /// In en, this message translates to:
  /// **'Creating {name}.'**
  String appsInstanceCreated(String name);

  /// No description provided for @appsInstanceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updating {name}.'**
  String appsInstanceUpdated(String name);

  /// No description provided for @appsInstanceNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get appsInstanceNoChanges;

  /// No description provided for @appsInstanceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String appsInstanceDeleteTitle(String name);

  /// No description provided for @appsInstanceDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete instance'**
  String get appsInstanceDeleteAction;

  /// No description provided for @appsInstanceDeleteConsequenceDisk.
  ///
  /// In en, this message translates to:
  /// **'The instance root disk is destroyed with it. Data written inside the guest is lost.'**
  String get appsInstanceDeleteConsequenceDisk;

  /// No description provided for @appsInstanceDeleteConsequenceRunning.
  ///
  /// In en, this message translates to:
  /// **'The instance is running and will be stopped first.'**
  String get appsInstanceDeleteConsequenceRunning;

  /// No description provided for @appsInstanceDeleteRequested.
  ///
  /// In en, this message translates to:
  /// **'Deleting {name}.'**
  String appsInstanceDeleteRequested(String name);

  /// No description provided for @appsInstanceValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get appsInstanceValidationNameRequired;

  /// No description provided for @appsInstanceValidationNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use letters, digits, and hyphens only, starting with a letter.'**
  String get appsInstanceValidationNameInvalid;

  /// No description provided for @appsInstanceValidationImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a base image.'**
  String get appsInstanceValidationImageRequired;

  /// No description provided for @appsInstanceValidationCpu.
  ///
  /// In en, this message translates to:
  /// **'Enter a core count or a pinned set such as 0-3.'**
  String get appsInstanceValidationCpu;

  /// No description provided for @appsInstanceValidationMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory must be at least {bound} MiB.'**
  String appsInstanceValidationMemory(int bound);

  /// No description provided for @appsInstanceValidationRootDisk.
  ///
  /// In en, this message translates to:
  /// **'Root disk must be between 1 and {bound} GiB.'**
  String appsInstanceValidationRootDisk(int bound);

  /// No description provided for @appsInstanceValidationEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment names must start with a letter or underscore and contain only letters, digits, and underscores.'**
  String get appsInstanceValidationEnvironment;

  /// No description provided for @appsOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The TrueNAS operation failed.'**
  String get appsOperationFailed;

  /// No description provided for @appsJobSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Job {jobId}'**
  String appsJobSuffix(String jobId);

  /// No description provided for @appsSummaryInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get appsSummaryInstalled;

  /// No description provided for @appsSummaryRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get appsSummaryRunning;

  /// No description provided for @appsSummaryUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get appsSummaryUpdates;

  /// No description provided for @appsStopAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}?'**
  String appsStopAppTitle(String name);

  /// No description provided for @appsStopAppBody.
  ///
  /// In en, this message translates to:
  /// **'Users and dependent services may lose access until the app is started again.'**
  String get appsStopAppBody;

  /// No description provided for @appsStopApp.
  ///
  /// In en, this message translates to:
  /// **'Stop app'**
  String get appsStopApp;

  /// No description provided for @appsStartApp.
  ///
  /// In en, this message translates to:
  /// **'Start app'**
  String get appsStartApp;

  /// No description provided for @appsStopServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop {name}?'**
  String appsStopServiceTitle(String name);

  /// No description provided for @appsStopServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Active clients using this service may be disconnected.'**
  String get appsStopServiceBody;

  /// No description provided for @appsStopService.
  ///
  /// In en, this message translates to:
  /// **'Stop service'**
  String get appsStopService;

  /// No description provided for @appsStartRequested.
  ///
  /// In en, this message translates to:
  /// **'Start requested for {target}.'**
  String appsStartRequested(String target);

  /// No description provided for @appsStopRequested.
  ///
  /// In en, this message translates to:
  /// **'Stop requested for {target}.'**
  String appsStopRequested(String target);

  /// No description provided for @appsUpgradeRequested.
  ///
  /// In en, this message translates to:
  /// **'Upgrade requested for {target}.'**
  String appsUpgradeRequested(String target);

  /// No description provided for @appsRedeployRequested.
  ///
  /// In en, this message translates to:
  /// **'Redeploy requested for {target}.'**
  String appsRedeployRequested(String target);

  /// No description provided for @appsReconfigureRequested.
  ///
  /// In en, this message translates to:
  /// **'Reconfiguration requested for {target}.'**
  String appsReconfigureRequested(String target);

  /// No description provided for @appsRollbackRequested.
  ///
  /// In en, this message translates to:
  /// **'Rollback requested for {target}.'**
  String appsRollbackRequested(String target);

  /// No description provided for @appsRemovalRequested.
  ///
  /// In en, this message translates to:
  /// **'Removal requested for {target}.'**
  String appsRemovalRequested(String target);

  /// No description provided for @appsInstallRequested.
  ///
  /// In en, this message translates to:
  /// **'Installation requested for {target}.'**
  String appsInstallRequested(String target);

  /// No description provided for @appsStartOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start on boot'**
  String get appsStartOnBoot;

  /// No description provided for @appsDoNotStartOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Do not start on boot'**
  String get appsDoNotStartOnBoot;

  /// No description provided for @appsStartOnBootTitle.
  ///
  /// In en, this message translates to:
  /// **'Start {name} on boot?'**
  String appsStartOnBootTitle(String name);

  /// No description provided for @appsStopStartOnBootTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop starting {name} on boot?'**
  String appsStopStartOnBootTitle(String name);

  /// No description provided for @appsStartOnBootConsequence.
  ///
  /// In en, this message translates to:
  /// **'{name} will start automatically after every reboot of {server}.'**
  String appsStartOnBootConsequence(String name, String server);

  /// No description provided for @appsStopOnBootConsequence.
  ///
  /// In en, this message translates to:
  /// **'{name} will stay stopped after the next reboot of {server} until someone starts it manually.'**
  String appsStopOnBootConsequence(String name, String server);

  /// No description provided for @appsBootChangeRunningNote.
  ///
  /// In en, this message translates to:
  /// **'The service keeps running now. This changes only what happens at boot.'**
  String get appsBootChangeRunningNote;

  /// No description provided for @appsBootChangeStoppedNote.
  ///
  /// In en, this message translates to:
  /// **'The service stays stopped now. This changes only what happens at boot.'**
  String get appsBootChangeStoppedNote;

  /// No description provided for @appsStartOnBootSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} will start on boot.'**
  String appsStartOnBootSaved(String name);

  /// No description provided for @appsStopOnBootSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer start on boot.'**
  String appsStopOnBootSaved(String name);

  /// No description provided for @appsServiceStartsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Starts automatically'**
  String get appsServiceStartsAutomatically;

  /// No description provided for @appsServiceManualStart.
  ///
  /// In en, this message translates to:
  /// **'Manual start'**
  String get appsServiceManualStart;

  /// No description provided for @appsServiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Service options'**
  String get appsServiceOptions;

  /// No description provided for @appsMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More app actions'**
  String get appsMoreActions;

  /// No description provided for @appsRedeploy.
  ///
  /// In en, this message translates to:
  /// **'Redeploy'**
  String get appsRedeploy;

  /// No description provided for @appsReconfigure.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure'**
  String get appsReconfigure;

  /// No description provided for @appsRollbackMenu.
  ///
  /// In en, this message translates to:
  /// **'Roll back to previous version'**
  String get appsRollbackMenu;

  /// No description provided for @appsReviewUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Review app upgrade'**
  String get appsReviewUpgrade;

  /// No description provided for @appsUpgradeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Upgrade is not supported by this server'**
  String get appsUpgradeUnsupported;

  /// No description provided for @appsRedeployTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeploy {name}?'**
  String appsRedeployTitle(String name);

  /// No description provided for @appsRedeployAction.
  ///
  /// In en, this message translates to:
  /// **'Redeploy app'**
  String get appsRedeployAction;

  /// No description provided for @appsRedeployConsequenceRebuild.
  ///
  /// In en, this message translates to:
  /// **'The app is stopped, its containers are recreated, and it starts again. Users lose access until the TrueNAS job completes.'**
  String get appsRedeployConsequenceRebuild;

  /// No description provided for @appsRedeployConsequenceData.
  ///
  /// In en, this message translates to:
  /// **'Existing configuration and stored data are kept; only the running instance is rebuilt.'**
  String get appsRedeployConsequenceData;

  /// No description provided for @appsConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the configuration for {name}.'**
  String appsConfigLoadFailed(String name);

  /// No description provided for @appsNotReconfigurable.
  ///
  /// In en, this message translates to:
  /// **'{name} is a custom app or does not expose editable configuration through the catalog. Reinstall it from the catalog to change its settings.'**
  String appsNotReconfigurable(String name);

  /// No description provided for @appsReconfigureDescription.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure the installed app.'**
  String get appsReconfigureDescription;

  /// No description provided for @appsSchemaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the app configuration schema.'**
  String get appsSchemaLoadFailed;

  /// No description provided for @appsInstallSchemaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the app installation schema.'**
  String get appsInstallSchemaLoadFailed;

  /// No description provided for @appsRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Roll back {name}?'**
  String appsRollbackTitle(String name);

  /// No description provided for @appsRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'Roll back app'**
  String get appsRollbackAction;

  /// No description provided for @appsRollbackConsequenceRebuild.
  ///
  /// In en, this message translates to:
  /// **'The app is rebuilt from the selected image version and restarted. Changes that depend on the current version may not apply.'**
  String get appsRollbackConsequenceRebuild;

  /// No description provided for @appsRollbackConsequenceData.
  ///
  /// In en, this message translates to:
  /// **'Stored data and configuration are preserved, but the running version moves back to the prior release.'**
  String get appsRollbackConsequenceData;

  /// No description provided for @appsRollbackSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Roll back {name}'**
  String appsRollbackSheetTitle(String name);

  /// No description provided for @appsRollbackSheetNotice.
  ///
  /// In en, this message translates to:
  /// **'The app on {server} is rebuilt from the selected image and restarted. Stored data and configuration are kept; only the running version moves back.'**
  String appsRollbackSheetNotice(String server);

  /// No description provided for @appsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String appsRemoveTitle(String name);

  /// No description provided for @appsRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove app'**
  String get appsRemoveAction;

  /// No description provided for @appsRemoveConsequenceApp.
  ///
  /// In en, this message translates to:
  /// **'The app is permanently removed from {server}. Reinstalling requires the catalog entry and your configuration.'**
  String appsRemoveConsequenceApp(String server);

  /// No description provided for @appsRemoveConsequenceImages.
  ///
  /// In en, this message translates to:
  /// **'Pulled container images are also deleted and must be downloaded again to reinstall.'**
  String get appsRemoveConsequenceImages;

  /// No description provided for @appsRemoveConsequenceVolumesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Named volumes are removed with the app, destroying the data they hold.'**
  String get appsRemoveConsequenceVolumesDeleted;

  /// No description provided for @appsRemoveConsequenceVolumesKept.
  ///
  /// In en, this message translates to:
  /// **'Named volumes are kept so the data survives removal, but they must be reattached or removed manually later.'**
  String get appsRemoveConsequenceVolumesKept;

  /// No description provided for @appsRemovalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to remove with {name}'**
  String appsRemovalSheetTitle(String name);

  /// No description provided for @appsRemovalSheetBody.
  ///
  /// In en, this message translates to:
  /// **'The app itself is always removed. These options control whether images and stored volumes go with it.'**
  String get appsRemovalSheetBody;

  /// No description provided for @appsRemoveImages.
  ///
  /// In en, this message translates to:
  /// **'Remove pulled images'**
  String get appsRemoveImages;

  /// No description provided for @appsRemoveImagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the container images downloaded for this app. They are fetched again on the next install.'**
  String get appsRemoveImagesSubtitle;

  /// No description provided for @appsKeepVolumes.
  ///
  /// In en, this message translates to:
  /// **'Keep named volumes'**
  String get appsKeepVolumes;

  /// No description provided for @appsKeepVolumesOn.
  ///
  /// In en, this message translates to:
  /// **'Stored data survives removal and can be reattached later.'**
  String get appsKeepVolumesOn;

  /// No description provided for @appsKeepVolumesOff.
  ///
  /// In en, this message translates to:
  /// **'Named volumes are deleted with the app. Data is lost.'**
  String get appsKeepVolumesOff;

  /// No description provided for @appsReviewRemoval.
  ///
  /// In en, this message translates to:
  /// **'Review removal'**
  String get appsReviewRemoval;

  /// No description provided for @appsUpgradeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade {name}'**
  String appsUpgradeSheetTitle(String name);

  /// No description provided for @appsVersionTransition.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String appsVersionTransition(String from, String to);

  /// No description provided for @appsTargetVersion.
  ///
  /// In en, this message translates to:
  /// **'Target version'**
  String get appsTargetVersion;

  /// No description provided for @appsSnapshotHostPaths.
  ///
  /// In en, this message translates to:
  /// **'Snapshot host-path storage'**
  String get appsSnapshotHostPaths;

  /// No description provided for @appsSnapshotHostPathsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create ZFS snapshots of eligible host-path volumes before upgrading.'**
  String get appsSnapshotHostPathsSubtitle;

  /// No description provided for @appsUpgradeNotice.
  ///
  /// In en, this message translates to:
  /// **'The app may be stopped and redeployed. Users can lose access until the TrueNAS job completes.'**
  String get appsUpgradeNotice;

  /// No description provided for @appsReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get appsReleaseNotes;

  /// No description provided for @appsNoReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes were provided for this version.'**
  String get appsNoReleaseNotes;

  /// No description provided for @appsUpgradeAction.
  ///
  /// In en, this message translates to:
  /// **'Upgrade app'**
  String get appsUpgradeAction;

  /// No description provided for @appsCatalogUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The configured catalog is not exposed by this TrueNAS version.'**
  String get appsCatalogUnsupported;

  /// No description provided for @appsCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No catalog apps are available. The catalog may still be synchronizing.'**
  String get appsCatalogEmpty;

  /// No description provided for @appsBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all {count} apps'**
  String appsBrowseAll(int count);

  /// No description provided for @appsDockerService.
  ///
  /// In en, this message translates to:
  /// **'Docker service'**
  String get appsDockerService;

  /// No description provided for @appsStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get appsStatusUnknown;

  /// No description provided for @appsDockerConfigurationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Docker configuration available'**
  String get appsDockerConfigurationAvailable;

  /// No description provided for @appsNoAppsPool.
  ///
  /// In en, this message translates to:
  /// **'No apps pool configured'**
  String get appsNoAppsPool;

  /// No description provided for @appsImageUpdatesEnabled.
  ///
  /// In en, this message translates to:
  /// **'image updates enabled'**
  String get appsImageUpdatesEnabled;

  /// No description provided for @appsManualImageUpdates.
  ///
  /// In en, this message translates to:
  /// **'manual image updates'**
  String get appsManualImageUpdates;

  /// No description provided for @appsVersionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Version unavailable'**
  String get appsVersionUnavailable;

  /// No description provided for @appsImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get appsImageUnavailable;

  /// No description provided for @appsCatalogTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{train} · {version}\n{description}'**
  String appsCatalogTileSubtitle(
    String train,
    String version,
    String description,
  );

  /// No description provided for @appsDiscoverApps.
  ///
  /// In en, this message translates to:
  /// **'Discover apps'**
  String get appsDiscoverApps;

  /// No description provided for @appsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, category, or tag'**
  String get appsSearchHint;

  /// No description provided for @appsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get appsClearSearch;

  /// No description provided for @appsAllTrains.
  ///
  /// In en, this message translates to:
  /// **'All trains'**
  String get appsAllTrains;

  /// No description provided for @appsAppCount.
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String appsAppCount(int count);

  /// No description provided for @appsNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No apps match this search.'**
  String get appsNoSearchResults;

  /// No description provided for @appsLabelTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get appsLabelTrain;

  /// No description provided for @appsLabelVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appsLabelVersion;

  /// No description provided for @appsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get appsUnavailable;

  /// No description provided for @appsLabelHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get appsLabelHealth;

  /// No description provided for @appsCatalogHealthy.
  ///
  /// In en, this message translates to:
  /// **'Catalog entry healthy'**
  String get appsCatalogHealthy;

  /// No description provided for @appsNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get appsNeedsAttention;

  /// No description provided for @appsLabelCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get appsLabelCategories;

  /// No description provided for @appsLabelTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get appsLabelTags;

  /// No description provided for @appsConfigureInstall.
  ///
  /// In en, this message translates to:
  /// **'Configure install'**
  String get appsConfigureInstall;

  /// No description provided for @appsAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App unavailable'**
  String get appsAppUnavailable;

  /// No description provided for @appsInstallUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Install unsupported'**
  String get appsInstallUnsupported;

  /// No description provided for @appsVerbStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get appsVerbStart;

  /// No description provided for @appsVerbStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get appsVerbStop;

  /// No description provided for @appsVerbRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get appsVerbRestart;

  /// No description provided for @appsVerbPowerOff.
  ///
  /// In en, this message translates to:
  /// **'Force power off'**
  String get appsVerbPowerOff;

  /// No description provided for @appsVerbConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{verb} {name}?'**
  String appsVerbConfirmTitle(String verb, String name);

  /// No description provided for @appsVerbRequested.
  ///
  /// In en, this message translates to:
  /// **'{verb} requested for {name}.'**
  String appsVerbRequested(String verb, String name);

  /// No description provided for @appsControlFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not {verb} {name}.'**
  String appsControlFailed(String verb, String name);

  /// No description provided for @appsKindVirtualMachine.
  ///
  /// In en, this message translates to:
  /// **'virtual machine'**
  String get appsKindVirtualMachine;

  /// No description provided for @appsKindContainer.
  ///
  /// In en, this message translates to:
  /// **'container'**
  String get appsKindContainer;

  /// No description provided for @appsNoLifecycleControl.
  ///
  /// In en, this message translates to:
  /// **'This TrueNAS version does not expose lifecycle control for this {kind}.'**
  String appsNoLifecycleControl(String kind);

  /// No description provided for @appsStopConsequence.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will ask the {kind} to shut down. Workloads running inside it stop and any unsaved state depends on the guest.'**
  String appsStopConsequence(String kind);

  /// No description provided for @appsRestartConsequence.
  ///
  /// In en, this message translates to:
  /// **'The {kind} shuts down and starts again. Anything it serves is unavailable until it finishes booting.'**
  String appsRestartConsequence(String kind);

  /// No description provided for @appsPowerOffConsequence.
  ///
  /// In en, this message translates to:
  /// **'Power is cut immediately without a clean shutdown. Unwritten data inside the {kind} can be lost, like pulling the plug on a machine.'**
  String appsPowerOffConsequence(String kind);

  /// No description provided for @appsLabelState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get appsLabelState;

  /// No description provided for @appsLabelCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get appsLabelCpu;

  /// No description provided for @appsCpuSummary.
  ///
  /// In en, this message translates to:
  /// **'{sockets} sockets · {cores} cores · {threads} threads'**
  String appsCpuSummary(int sockets, int cores, int threads);

  /// No description provided for @appsLabelMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get appsLabelMemory;

  /// No description provided for @appsMemoryMiB.
  ///
  /// In en, this message translates to:
  /// **'{value} MiB'**
  String appsMemoryMiB(int value);

  /// No description provided for @appsLabelAutostart.
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get appsLabelAutostart;

  /// No description provided for @appsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get appsEnabled;

  /// No description provided for @appsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get appsDisabled;

  /// No description provided for @appsLabelDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get appsLabelDisplay;

  /// No description provided for @appsDisplayAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get appsDisplayAvailable;

  /// No description provided for @appsDisplayNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get appsDisplayNotConfigured;

  /// No description provided for @appsVmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{state} · {vcpu} vCPU · {memory} MiB'**
  String appsVmSubtitle(String state, int vcpu, int memory);

  /// No description provided for @appsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get appsEdit;

  /// No description provided for @appsStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get appsStateRunning;

  /// No description provided for @appsStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get appsStateStopped;

  /// No description provided for @appsStateDeploying.
  ///
  /// In en, this message translates to:
  /// **'Deploying'**
  String get appsStateDeploying;

  /// No description provided for @appsStateStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get appsStateStarting;

  /// No description provided for @appsStateStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping'**
  String get appsStateStopping;

  /// No description provided for @appsStateCrashed.
  ///
  /// In en, this message translates to:
  /// **'Crashed'**
  String get appsStateCrashed;

  /// No description provided for @appsStateHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get appsStateHealthy;

  /// No description provided for @appsStateUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get appsStateUnhealthy;

  /// No description provided for @appsStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get appsStateUnknown;

  /// No description provided for @appsDetailsLiveResources.
  ///
  /// In en, this message translates to:
  /// **'Live resources'**
  String get appsDetailsLiveResources;

  /// No description provided for @appsDetailsCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get appsDetailsCpu;

  /// No description provided for @appsDetailsMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get appsDetailsMemory;

  /// No description provided for @appsDetailsStatsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load live resource information.\n{detail}'**
  String appsDetailsStatsFailed(String detail);

  /// No description provided for @appsDetailsDiskRead.
  ///
  /// In en, this message translates to:
  /// **'Disk read'**
  String get appsDetailsDiskRead;

  /// No description provided for @appsDetailsDiskWrite.
  ///
  /// In en, this message translates to:
  /// **'Disk write'**
  String get appsDetailsDiskWrite;

  /// No description provided for @appsDetailsNetworkRate.
  ///
  /// In en, this message translates to:
  /// **'Received {received} · Sent {sent}'**
  String appsDetailsNetworkRate(String received, String sent);

  /// No description provided for @appsDetailsWorkloads.
  ///
  /// In en, this message translates to:
  /// **'Workloads'**
  String get appsDetailsWorkloads;

  /// No description provided for @appsDetailsContainerCount.
  ///
  /// In en, this message translates to:
  /// **'{count} containers'**
  String appsDetailsContainerCount(int count);

  /// No description provided for @appsDetailsNoContainerInfo.
  ///
  /// In en, this message translates to:
  /// **'No container details'**
  String get appsDetailsNoContainerInfo;

  /// No description provided for @appsDetailsImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get appsDetailsImages;

  /// No description provided for @appsDetailsPorts.
  ///
  /// In en, this message translates to:
  /// **'Ports'**
  String get appsDetailsPorts;

  /// No description provided for @appsDetailsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get appsDetailsStorage;

  /// No description provided for @appsDetailsNetworks.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get appsDetailsNetworks;

  /// No description provided for @appsCustomComposeDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit the custom app Docker Compose configuration as JSON. Applying it can recreate the app containers.'**
  String get appsCustomComposeDescription;

  /// No description provided for @appsCustomComposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Docker Compose configuration'**
  String get appsCustomComposeLabel;

  /// No description provided for @appsCustomComposeReview.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get appsCustomComposeReview;

  /// No description provided for @appsCustomComposeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid JSON object.'**
  String get appsCustomComposeInvalid;

  /// No description provided for @appsCustomComposeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Change the configuration for {name}?'**
  String appsCustomComposeConfirmTitle(String name);

  /// No description provided for @appsCustomComposeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get appsCustomComposeApply;

  /// No description provided for @appsCustomComposeRecreateWarning.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS can recreate the app containers with the changed configuration.'**
  String get appsCustomComposeRecreateWarning;

  /// No description provided for @appsCustomComposeDowntimeWarning.
  ///
  /// In en, this message translates to:
  /// **'The app can be briefly unavailable until the job completes.'**
  String get appsCustomComposeDowntimeWarning;

  /// No description provided for @appsDeviceTypeDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get appsDeviceTypeDisk;

  /// No description provided for @appsDeviceTypeNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get appsDeviceTypeNetwork;

  /// No description provided for @appsDeviceTypeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get appsDeviceTypeDisplay;

  /// No description provided for @appsDeviceTypeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get appsDeviceTypeUsb;

  /// No description provided for @appsDeviceTypePci.
  ///
  /// In en, this message translates to:
  /// **'PCI device'**
  String get appsDeviceTypePci;

  /// No description provided for @appsDeviceTypeTpm.
  ///
  /// In en, this message translates to:
  /// **'TPM'**
  String get appsDeviceTypeTpm;

  /// No description provided for @appsDeviceTypeCdrom.
  ///
  /// In en, this message translates to:
  /// **'CD-ROM'**
  String get appsDeviceTypeCdrom;

  /// No description provided for @appsDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get appsDevices;

  /// No description provided for @appsNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get appsNoChanges;

  /// No description provided for @appsSaveChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes to {name}?'**
  String appsSaveChangesTitle(String name);

  /// No description provided for @appsVmRuntimeChangeRunning.
  ///
  /// In en, this message translates to:
  /// **'CPU and memory changes apply on the next restart.'**
  String get appsVmRuntimeChangeRunning;

  /// No description provided for @appsVmRuntimeChangeStopped.
  ///
  /// In en, this message translates to:
  /// **'CPU and memory changes apply on next start.'**
  String get appsVmRuntimeChangeStopped;

  /// No description provided for @appsConfigUpdatedOnServer.
  ///
  /// In en, this message translates to:
  /// **'Configuration is updated on the server.'**
  String get appsConfigUpdatedOnServer;

  /// No description provided for @appsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update {name}.'**
  String appsUpdateFailed(String name);

  /// No description provided for @appsVmUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated. Restart it to apply runtime changes.'**
  String appsVmUpdated(String name);

  /// No description provided for @appsVmDevicesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the VM devices from the server.'**
  String get appsVmDevicesLoadFailed;

  /// No description provided for @appsAddDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {device} to {vm}?'**
  String appsAddDeviceTitle(String device, String vm);

  /// No description provided for @appsAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get appsAddDevice;

  /// No description provided for @appsAddDeviceConsequence.
  ///
  /// In en, this message translates to:
  /// **'The device is attached to {vm}. Disk devices require a restart to be visible inside the guest.'**
  String appsAddDeviceConsequence(String vm);

  /// No description provided for @appsAddDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not add the device.'**
  String get appsAddDeviceFailed;

  /// No description provided for @appsDeviceAdded.
  ///
  /// In en, this message translates to:
  /// **'Device added to {vm}.'**
  String appsDeviceAdded(String vm);

  /// No description provided for @appsSaveDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Save {device} on {vm}?'**
  String appsSaveDeviceTitle(String device, String vm);

  /// No description provided for @appsSaveDevice.
  ///
  /// In en, this message translates to:
  /// **'Save device'**
  String get appsSaveDevice;

  /// No description provided for @appsEditDeviceConsequence.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS replaces this device’s configuration on {vm}. Changes apply the next time the VM starts.'**
  String appsEditDeviceConsequence(String vm);

  /// No description provided for @appsEditDeviceDiskWarning.
  ///
  /// In en, this message translates to:
  /// **'Repointing a disk changes which storage the guest boots from. The underlying zvol or image is not modified.'**
  String get appsEditDeviceDiskWarning;

  /// No description provided for @appsUpdateDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update the device.'**
  String get appsUpdateDeviceFailed;

  /// No description provided for @appsDeviceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Device updated on {vm}.'**
  String appsDeviceUpdated(String vm);

  /// No description provided for @appsRemoveDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {device} from {vm}?'**
  String appsRemoveDeviceTitle(String device, String vm);

  /// No description provided for @appsRemoveDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get appsRemoveDevice;

  /// No description provided for @appsRemoveDeviceConsequence.
  ///
  /// In en, this message translates to:
  /// **'The device is detached from the VM. Disk removal does not delete the underlying zvol or image.'**
  String get appsRemoveDeviceConsequence;

  /// No description provided for @appsRemoveDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not remove the device.'**
  String get appsRemoveDeviceFailed;

  /// No description provided for @appsDeviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed from {vm}.'**
  String appsDeviceRemoved(String vm);

  /// No description provided for @appsDeviceTarget.
  ///
  /// In en, this message translates to:
  /// **'{vm} · {device}'**
  String appsDeviceTarget(String vm, String device);

  /// No description provided for @appsContainerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{state} · {dataset} · {count} devices'**
  String appsContainerSubtitle(String state, String dataset, int count);

  /// No description provided for @appsLabelDataset.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get appsLabelDataset;

  /// No description provided for @appsLabelUuid.
  ///
  /// In en, this message translates to:
  /// **'UUID'**
  String get appsLabelUuid;

  /// No description provided for @appsLabelDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get appsLabelDevices;

  /// No description provided for @appsLabelNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get appsLabelNetwork;

  /// No description provided for @appsNetworkByDevices.
  ///
  /// In en, this message translates to:
  /// **'Configured by devices'**
  String get appsNetworkByDevices;

  /// No description provided for @appsContainerConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the container configuration.'**
  String get appsContainerConfigLoadFailed;

  /// No description provided for @appsContainerUpdateConsequence.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS replaces the whole container configuration, including the device list. Volumes and environment are sent unchanged from the current container.'**
  String get appsContainerUpdateConsequence;

  /// No description provided for @appsContainerRestartToApply.
  ///
  /// In en, this message translates to:
  /// **'{name} is running; restart it to apply.'**
  String appsContainerRestartToApply(String name);

  /// No description provided for @appsContainerStartToApply.
  ///
  /// In en, this message translates to:
  /// **'Start the container to apply.'**
  String get appsContainerStartToApply;

  /// No description provided for @appsContainerUpdated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated. Restart it to apply.'**
  String appsContainerUpdated(String name);

  /// No description provided for @protectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get protectionTitle;

  /// No description provided for @protectionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load data protection information.'**
  String get protectionLoadFailed;

  /// No description provided for @overviewActivityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent activity.'**
  String get overviewActivityLoadFailed;

  /// No description provided for @protectionLandingDescription.
  ///
  /// In en, this message translates to:
  /// **'See every scheduled copy, snapshot, scrub, and backup task.'**
  String get protectionLandingDescription;

  /// No description provided for @protectionRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh protection tasks'**
  String get protectionRefreshTooltip;

  /// No description provided for @protectionReplication.
  ///
  /// In en, this message translates to:
  /// **'Replication'**
  String get protectionReplication;

  /// No description provided for @protectionReplicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local and remote ZFS replication'**
  String get protectionReplicationSubtitle;

  /// No description provided for @protectionSnapshotTasks.
  ///
  /// In en, this message translates to:
  /// **'Snapshot tasks'**
  String get protectionSnapshotTasks;

  /// No description provided for @protectionSnapshotTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Schedules and retention'**
  String get protectionSnapshotTasksSubtitle;

  /// No description provided for @protectionCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get protectionCloudSync;

  /// No description provided for @protectionCloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Providers, transfers, results'**
  String get protectionCloudSyncSubtitle;

  /// No description provided for @protectionScrubs.
  ///
  /// In en, this message translates to:
  /// **'Scrubs'**
  String get protectionScrubs;

  /// No description provided for @protectionScrubsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pool integrity schedules'**
  String get protectionScrubsSubtitle;

  /// No description provided for @protectionRsync.
  ///
  /// In en, this message translates to:
  /// **'Rsync'**
  String get protectionRsync;

  /// No description provided for @protectionRsyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Module and SSH tasks'**
  String get protectionRsyncSubtitle;

  /// No description provided for @protectionRecentSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Recent snapshots'**
  String get protectionRecentSnapshots;

  /// No description provided for @protectionScrubSchedules.
  ///
  /// In en, this message translates to:
  /// **'Scrub schedules'**
  String get protectionScrubSchedules;

  /// No description provided for @protectionSummary.
  ///
  /// In en, this message translates to:
  /// **'{replications} replication, {snapshots} snapshot, and {others} other tasks enabled'**
  String protectionSummary(int replications, int snapshots, int others);

  /// No description provided for @protectionNewReplication.
  ///
  /// In en, this message translates to:
  /// **'New replication task'**
  String get protectionNewReplication;

  /// No description provided for @protectionNewSnapshotTask.
  ///
  /// In en, this message translates to:
  /// **'Create periodic snapshot task'**
  String get protectionNewSnapshotTask;

  /// No description provided for @protectionSnapshotTaskCreateUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Snapshot task creation is not supported'**
  String get protectionSnapshotTaskCreateUnsupported;

  /// No description provided for @protectionNewCloudSync.
  ///
  /// In en, this message translates to:
  /// **'New cloud sync task'**
  String get protectionNewCloudSync;

  /// No description provided for @protectionCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'Cloud backups'**
  String get protectionCloudBackups;

  /// No description provided for @protectionNewCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'New cloud backup task'**
  String get protectionNewCloudBackup;

  /// No description provided for @protectionNoCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'No cloud backup tasks.'**
  String get protectionNoCloudBackups;

  /// No description provided for @protectionCloudBackupNeedsCredential.
  ///
  /// In en, this message translates to:
  /// **'Add a cloud credential in the TrueNAS web interface before creating a backup task.'**
  String get protectionCloudBackupNeedsCredential;

  /// No description provided for @protectionCloudBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{schedule} · keeps {keepLast} snapshots'**
  String protectionCloudBackupSubtitle(String schedule, int keepLast);

  /// No description provided for @protectionCloudBackupSheetCreate.
  ///
  /// In en, this message translates to:
  /// **'New cloud backup'**
  String get protectionCloudBackupSheetCreate;

  /// No description provided for @protectionCloudBackupSheetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit cloud backup'**
  String get protectionCloudBackupSheetEdit;

  /// No description provided for @protectionCloudBackupPath.
  ///
  /// In en, this message translates to:
  /// **'Dataset path'**
  String get protectionCloudBackupPath;

  /// No description provided for @protectionCloudBackupCredential.
  ///
  /// In en, this message translates to:
  /// **'Cloud credential'**
  String get protectionCloudBackupCredential;

  /// No description provided for @protectionCloudBackupBucket.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get protectionCloudBackupBucket;

  /// No description provided for @protectionCloudBackupFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get protectionCloudBackupFolder;

  /// No description provided for @protectionCloudBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Repository password'**
  String get protectionCloudBackupPassword;

  /// No description provided for @protectionCloudBackupPasswordHelperNew.
  ///
  /// In en, this message translates to:
  /// **'Required. Losing this password makes the backup unrecoverable; TrueDock never reads it back from the server.'**
  String get protectionCloudBackupPasswordHelperNew;

  /// No description provided for @protectionCloudBackupPasswordHelperEdit.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep the stored password.'**
  String get protectionCloudBackupPasswordHelperEdit;

  /// No description provided for @protectionCloudBackupKeepLast.
  ///
  /// In en, this message translates to:
  /// **'Snapshots to keep'**
  String get protectionCloudBackupKeepLast;

  /// No description provided for @protectionCloudBackupSnapshotFirst.
  ///
  /// In en, this message translates to:
  /// **'Snapshot the dataset first'**
  String get protectionCloudBackupSnapshotFirst;

  /// No description provided for @protectionCloudBackupSnapshotHelp.
  ///
  /// In en, this message translates to:
  /// **'Backs up a point-in-time snapshot instead of files that may change mid-transfer.'**
  String get protectionCloudBackupSnapshotHelp;

  /// No description provided for @protectionCloudBackupTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer profile'**
  String get protectionCloudBackupTransfer;

  /// No description provided for @protectionCloudBackupTransferDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get protectionCloudBackupTransferDefault;

  /// No description provided for @protectionCloudBackupTransferPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get protectionCloudBackupTransferPerformance;

  /// No description provided for @protectionCloudBackupTransferFast.
  ///
  /// In en, this message translates to:
  /// **'Fast storage'**
  String get protectionCloudBackupTransferFast;

  /// No description provided for @protectionCloudBackupEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get protectionCloudBackupEnabled;

  /// No description provided for @protectionCloudBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup task created.'**
  String get protectionCloudBackupCreated;

  /// No description provided for @protectionCloudBackupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup task updated.'**
  String get protectionCloudBackupUpdated;

  /// No description provided for @protectionCloudBackupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup task deleted.'**
  String get protectionCloudBackupDeleted;

  /// No description provided for @protectionCloudBackupRunning.
  ///
  /// In en, this message translates to:
  /// **'Backing up {path}.'**
  String protectionCloudBackupRunning(String path);

  /// No description provided for @protectionCloudBackupDryRun.
  ///
  /// In en, this message translates to:
  /// **'Dry run'**
  String get protectionCloudBackupDryRun;

  /// No description provided for @protectionCloudBackupDryRunStarted.
  ///
  /// In en, this message translates to:
  /// **'Simulating the backup of {path}.'**
  String protectionCloudBackupDryRunStarted(String path);

  /// No description provided for @protectionCloudBackupRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up {path} now?'**
  String protectionCloudBackupRunTitle(String path);

  /// No description provided for @protectionCloudBackupRunAction.
  ///
  /// In en, this message translates to:
  /// **'Start backup'**
  String get protectionCloudBackupRunAction;

  /// No description provided for @protectionCloudBackupRunConsequence.
  ///
  /// In en, this message translates to:
  /// **'The transfer runs now and counts against the provider\'s bandwidth and request charges.'**
  String get protectionCloudBackupRunConsequence;

  /// No description provided for @protectionCloudBackupDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this backup task?'**
  String get protectionCloudBackupDeleteTitle;

  /// No description provided for @protectionCloudBackupDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get protectionCloudBackupDeleteAction;

  /// No description provided for @protectionCloudBackupDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'The schedule is removed. Snapshots already in the cloud repository are left in place.'**
  String get protectionCloudBackupDeleteConsequence;

  /// No description provided for @protectionCloudBackupSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Repository snapshots'**
  String get protectionCloudBackupSnapshots;

  /// No description provided for @protectionCloudBackupSnapshotsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No snapshots in this repository yet.'**
  String get protectionCloudBackupSnapshotsEmpty;

  /// No description provided for @protectionCloudBackupAbort.
  ///
  /// In en, this message translates to:
  /// **'Abort running backup'**
  String get protectionCloudBackupAbort;

  /// No description provided for @protectionCloudBackupAborted.
  ///
  /// In en, this message translates to:
  /// **'Abort requested.'**
  String get protectionCloudBackupAborted;

  /// No description provided for @protectionCloudBackupAbortTitle.
  ///
  /// In en, this message translates to:
  /// **'Abort the backup of {path}?'**
  String protectionCloudBackupAbortTitle(String path);

  /// No description provided for @protectionCloudBackupAbortAction.
  ///
  /// In en, this message translates to:
  /// **'Abort backup'**
  String get protectionCloudBackupAbortAction;

  /// No description provided for @protectionCloudBackupAbortConsequence.
  ///
  /// In en, this message translates to:
  /// **'The transfer stops partway. Data already uploaded is kept, but this run produces no usable snapshot.'**
  String get protectionCloudBackupAbortConsequence;

  /// No description provided for @protectionCloudBackupAbortConsequenceRestart.
  ///
  /// In en, this message translates to:
  /// **'Backing up again starts a fresh transfer and counts against the provider\'s bandwidth and request charges.'**
  String get protectionCloudBackupAbortConsequenceRestart;

  /// No description provided for @protectionCloudBackupValidationPath.
  ///
  /// In en, this message translates to:
  /// **'Enter the dataset path to back up.'**
  String get protectionCloudBackupValidationPath;

  /// No description provided for @protectionCloudBackupValidationPathAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Use an absolute path, starting with /mnt.'**
  String get protectionCloudBackupValidationPathAbsolute;

  /// No description provided for @protectionCloudBackupValidationCredential.
  ///
  /// In en, this message translates to:
  /// **'Choose a cloud credential.'**
  String get protectionCloudBackupValidationCredential;

  /// No description provided for @protectionCloudBackupValidationPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a repository password.'**
  String get protectionCloudBackupValidationPassword;

  /// No description provided for @protectionCloudBackupValidationKeepLast.
  ///
  /// In en, this message translates to:
  /// **'Keep at least {bound} snapshot.'**
  String protectionCloudBackupValidationKeepLast(int bound);

  /// No description provided for @protectionNewRsync.
  ///
  /// In en, this message translates to:
  /// **'New rsync task'**
  String get protectionNewRsync;

  /// No description provided for @protectionEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get protectionEditTask;

  /// No description provided for @protectionDeleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get protectionDeleteTask;

  /// No description provided for @protectionRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get protectionRunNow;

  /// No description provided for @protectionTaskAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'Task already running'**
  String get protectionTaskAlreadyRunning;

  /// No description provided for @protectionActionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This action is not supported by the server'**
  String get protectionActionUnsupported;

  /// No description provided for @protectionSnapshotTaskActions.
  ///
  /// In en, this message translates to:
  /// **'Snapshot task actions'**
  String get protectionSnapshotTaskActions;

  /// No description provided for @protectionNoReplicationTasks.
  ///
  /// In en, this message translates to:
  /// **'No replication tasks found.'**
  String get protectionNoReplicationTasks;

  /// No description provided for @protectionNoSnapshotTasks.
  ///
  /// In en, this message translates to:
  /// **'No periodic snapshot tasks found.'**
  String get protectionNoSnapshotTasks;

  /// No description provided for @protectionNoSnapshots.
  ///
  /// In en, this message translates to:
  /// **'No snapshots found.'**
  String get protectionNoSnapshots;

  /// No description provided for @protectionNoScrubSchedules.
  ///
  /// In en, this message translates to:
  /// **'No scrub schedules found.'**
  String get protectionNoScrubSchedules;

  /// No description provided for @protectionNoCloudSyncTasks.
  ///
  /// In en, this message translates to:
  /// **'No cloud sync tasks found.'**
  String get protectionNoCloudSyncTasks;

  /// No description provided for @protectionNoRsyncTasks.
  ///
  /// In en, this message translates to:
  /// **'No rsync tasks found.'**
  String get protectionNoRsyncTasks;

  /// No description provided for @protectionRunTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Run {name}?'**
  String protectionRunTaskTitle(String name);

  /// No description provided for @protectionRunReplicationMessage.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will transfer snapshots to the configured {direction} destination. This can use storage, CPU, and network bandwidth.'**
  String protectionRunReplicationMessage(String direction);

  /// No description provided for @protectionRunReplication.
  ///
  /// In en, this message translates to:
  /// **'Run replication'**
  String get protectionRunReplication;

  /// No description provided for @protectionStartScrubTitle.
  ///
  /// In en, this message translates to:
  /// **'Start scrub on {pool}?'**
  String protectionStartScrubTitle(String pool);

  /// No description provided for @protectionStartScrubMessage.
  ///
  /// In en, this message translates to:
  /// **'A scrub verifies pool data and can increase disk activity until it completes.'**
  String get protectionStartScrubMessage;

  /// No description provided for @protectionStartScrub.
  ///
  /// In en, this message translates to:
  /// **'Start scrub'**
  String get protectionStartScrub;

  /// No description provided for @protectionRunRsyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Run Rsync task?'**
  String get protectionRunRsyncTitle;

  /// No description provided for @protectionRunRsyncMessage.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will {direction} data between {path} and {remote}. Existing destination files can be changed according to the task configuration.'**
  String protectionRunRsyncMessage(
    String direction,
    String path,
    String remote,
  );

  /// No description provided for @protectionRunRsync.
  ///
  /// In en, this message translates to:
  /// **'Run Rsync'**
  String get protectionRunRsync;

  /// No description provided for @protectionRunCloudSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will {direction} {path} using {provider}. Remote or local files can change according to {mode} rules.'**
  String protectionRunCloudSyncMessage(
    String direction,
    String path,
    String provider,
    String mode,
  );

  /// No description provided for @protectionDryRun.
  ///
  /// In en, this message translates to:
  /// **'Dry run'**
  String get protectionDryRun;

  /// No description provided for @protectionDryRunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preview changes without transferring data.'**
  String get protectionDryRunSubtitle;

  /// No description provided for @protectionRunPreview.
  ///
  /// In en, this message translates to:
  /// **'Run preview'**
  String get protectionRunPreview;

  /// No description provided for @protectionRunCloudSync.
  ///
  /// In en, this message translates to:
  /// **'Run cloud sync'**
  String get protectionRunCloudSync;

  /// No description provided for @protectionSnapshotTaskCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'The periodic snapshot task could not be created.'**
  String get protectionSnapshotTaskCreateFailed;

  /// No description provided for @protectionSnapshotTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Periodic snapshot task created for {dataset}.'**
  String protectionSnapshotTaskCreated(String dataset);

  /// No description provided for @protectionSnapshotTaskUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The periodic snapshot task could not be updated.'**
  String get protectionSnapshotTaskUpdateFailed;

  /// No description provided for @protectionSnapshotTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Periodic snapshot task updated for {dataset}.'**
  String protectionSnapshotTaskUpdated(String dataset);

  /// No description provided for @protectionSnapshotTaskUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Snapshot task update'**
  String get protectionSnapshotTaskUpdateLabel;

  /// No description provided for @protectionUpdateTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {dataset}?'**
  String protectionUpdateTaskTitle(String dataset);

  /// No description provided for @protectionUpdateTaskBody.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will apply the new snapshot schedule and retention policy.'**
  String get protectionUpdateTaskBody;

  /// No description provided for @protectionRetentionChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 existing snapshot retention assignment will change:} other{{count} existing snapshot retention assignments will change:}}'**
  String protectionRetentionChanges(int count);

  /// No description provided for @protectionRetentionConsequence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 snapshot that already exists gets a new retention deadline and may be pruned. Pruned snapshots cannot be recovered.} other{{count} snapshots that already exist get new retention deadlines and may be pruned. Pruned snapshots cannot be recovered.}}'**
  String protectionRetentionConsequence(int count);

  /// No description provided for @protectionRetentionEntry.
  ///
  /// In en, this message translates to:
  /// **'• {name}: {count}'**
  String protectionRetentionEntry(String name, String count);

  /// No description provided for @protectionNoRetentionChanges.
  ///
  /// In en, this message translates to:
  /// **'The server reports no existing snapshot retention changes.'**
  String get protectionNoRetentionChanges;

  /// No description provided for @protectionApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get protectionApplyChanges;

  /// No description provided for @protectionRunSnapshotTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Run snapshot task now?'**
  String get protectionRunSnapshotTaskTitle;

  /// No description provided for @protectionRunSnapshotTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will create {scope} snapshots for {dataset} immediately using {schema}.'**
  String protectionRunSnapshotTaskMessage(
    String scope,
    String dataset,
    String schema,
  );

  /// No description provided for @protectionScopeRecursive.
  ///
  /// In en, this message translates to:
  /// **'recursive'**
  String get protectionScopeRecursive;

  /// No description provided for @protectionRunSnapshotTask.
  ///
  /// In en, this message translates to:
  /// **'Run snapshot task'**
  String get protectionRunSnapshotTask;

  /// No description provided for @protectionDeleteSnapshotTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot task?'**
  String get protectionDeleteSnapshotTaskTitle;

  /// No description provided for @protectionDeleteSnapshotTaskConsequence.
  ///
  /// In en, this message translates to:
  /// **'The schedule is removed. Snapshots already created by this task are kept and expire on their own retention.'**
  String get protectionDeleteSnapshotTaskConsequence;

  /// No description provided for @protectionSnapshotHeld.
  ///
  /// In en, this message translates to:
  /// **'{name} is now protected from deletion.'**
  String protectionSnapshotHeld(String name);

  /// No description provided for @protectionSnapshotReleased.
  ///
  /// In en, this message translates to:
  /// **'Released the hold on {name}.'**
  String protectionSnapshotReleased(String name);

  /// No description provided for @protectionSnapshotHoldAction.
  ///
  /// In en, this message translates to:
  /// **'hold {name}'**
  String protectionSnapshotHoldAction(String name);

  /// No description provided for @protectionSnapshotReleaseAction.
  ///
  /// In en, this message translates to:
  /// **'release {name}'**
  String protectionSnapshotReleaseAction(String name);

  /// No description provided for @protectionSnapshotCloneAction.
  ///
  /// In en, this message translates to:
  /// **'clone {name}'**
  String protectionSnapshotCloneAction(String name);

  /// No description provided for @protectionSnapshotCloned.
  ///
  /// In en, this message translates to:
  /// **'Cloned to {destination}.'**
  String protectionSnapshotCloned(String destination);

  /// No description provided for @protectionSnapshotDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'delete {name}'**
  String protectionSnapshotDeleteAction(String name);

  /// No description provided for @protectionSnapshotDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}.'**
  String protectionSnapshotDeleted(String name);

  /// No description provided for @protectionSnapshotRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'roll back {dataset}'**
  String protectionSnapshotRollbackAction(String dataset);

  /// No description provided for @protectionSnapshotRolledBack.
  ///
  /// In en, this message translates to:
  /// **'Rolled {dataset} back to {name}.'**
  String protectionSnapshotRolledBack(String dataset, String name);

  /// No description provided for @protectionSnapshotActionFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not {action}.'**
  String protectionSnapshotActionFailed(String action);

  /// No description provided for @protectionSnapshotTarget.
  ///
  /// In en, this message translates to:
  /// **'{dataset}@{name}'**
  String protectionSnapshotTarget(String dataset, String name);

  /// No description provided for @protectionDeleteSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot?'**
  String get protectionDeleteSnapshotTitle;

  /// No description provided for @protectionDeleteSnapshotAction.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get protectionDeleteSnapshotAction;

  /// No description provided for @protectionDeleteSnapshotConsequenceRestore.
  ///
  /// In en, this message translates to:
  /// **'This restore point is destroyed and cannot be recovered.'**
  String get protectionDeleteSnapshotConsequenceRestore;

  /// No description provided for @protectionDeleteSnapshotConsequenceReplication.
  ///
  /// In en, this message translates to:
  /// **'Replication that depends on it may need a full resend.'**
  String get protectionDeleteSnapshotConsequenceReplication;

  /// No description provided for @protectionDeleteSnapshotNote.
  ///
  /// In en, this message translates to:
  /// **'Live data in the dataset is not affected.'**
  String get protectionDeleteSnapshotNote;

  /// No description provided for @protectionRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Roll back to this snapshot?'**
  String get protectionRollbackTitle;

  /// No description provided for @protectionRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'Roll back'**
  String get protectionRollbackAction;

  /// No description provided for @protectionRollbackConsequenceChanges.
  ///
  /// In en, this message translates to:
  /// **'Every change written to {dataset} after this snapshot is permanently lost.'**
  String protectionRollbackConsequenceChanges(String dataset);

  /// No description provided for @protectionRollbackConsequenceNewer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 newer snapshot is destroyed.} other{{count} newer snapshots are destroyed.}}'**
  String protectionRollbackConsequenceNewer(int count);

  /// No description provided for @protectionRollbackConsequenceClones.
  ///
  /// In en, this message translates to:
  /// **'Datasets cloned from those snapshots are destroyed too.'**
  String get protectionRollbackConsequenceClones;

  /// No description provided for @protectionRollbackConsequenceForce.
  ///
  /// In en, this message translates to:
  /// **'The dataset is unmounted even if applications are using it.'**
  String get protectionRollbackConsequenceForce;

  /// No description provided for @protectionRollbackNote.
  ///
  /// In en, this message translates to:
  /// **'Stop applications writing to this dataset before continuing.'**
  String get protectionRollbackNote;

  /// No description provided for @protectionCloudSyncConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cloud sync task configuration.'**
  String get protectionCloudSyncConfigLoadFailed;

  /// No description provided for @protectionReplicationConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the replication task configuration.'**
  String get protectionReplicationConfigLoadFailed;

  /// No description provided for @protectionRsyncConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the rsync task configuration.'**
  String get protectionRsyncConfigLoadFailed;

  /// No description provided for @protectionCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get protectionCreateTask;

  /// No description provided for @protectionSaveTask.
  ///
  /// In en, this message translates to:
  /// **'Save task'**
  String get protectionSaveTask;

  /// No description provided for @protectionCreateCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Create cloud sync {name}?'**
  String protectionCreateCloudSyncTitle(String name);

  /// No description provided for @protectionSaveCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Save cloud sync {name}?'**
  String protectionSaveCloudSyncTitle(String name);

  /// No description provided for @protectionCloudSyncPushConsequence.
  ///
  /// In en, this message translates to:
  /// **'Transfers {path} to {remote} on {provider}.'**
  String protectionCloudSyncPushConsequence(
    String path,
    String remote,
    String provider,
  );

  /// No description provided for @protectionCloudSyncPullConsequence.
  ///
  /// In en, this message translates to:
  /// **'Transfers {remote} into {path} on this server.'**
  String protectionCloudSyncPullConsequence(String remote, String path);

  /// No description provided for @protectionSelectedProvider.
  ///
  /// In en, this message translates to:
  /// **'the selected provider'**
  String get protectionSelectedProvider;

  /// No description provided for @protectionCloudSyncSyncPush.
  ///
  /// In en, this message translates to:
  /// **'Sync deletes files at {remote} that no longer exist in {path}.'**
  String protectionCloudSyncSyncPush(String remote, String path);

  /// No description provided for @protectionCloudSyncSyncPull.
  ///
  /// In en, this message translates to:
  /// **'Sync deletes files in {path} that no longer exist at {remote}.'**
  String protectionCloudSyncSyncPull(String path, String remote);

  /// No description provided for @protectionCloudSyncMovePush.
  ///
  /// In en, this message translates to:
  /// **'Move deletes the files from {path} on this server after a successful upload.'**
  String protectionCloudSyncMovePush(String path);

  /// No description provided for @protectionCloudSyncMovePull.
  ///
  /// In en, this message translates to:
  /// **'Move deletes the files from {remote} after a successful download.'**
  String protectionCloudSyncMovePull(String remote);

  /// No description provided for @protectionCloudSyncCopyNote.
  ///
  /// In en, this message translates to:
  /// **'Copy never deletes anything on either side.'**
  String get protectionCloudSyncCopyNote;

  /// No description provided for @protectionCloudSyncEncryptionNote.
  ///
  /// In en, this message translates to:
  /// **'Files are encrypted before upload. Losing the encryption password makes the data unrecoverable; TrueDock does not store it.'**
  String get protectionCloudSyncEncryptionNote;

  /// No description provided for @protectionCreateReplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create replication {name}?'**
  String protectionCreateReplicationTitle(String name);

  /// No description provided for @protectionSaveReplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Save replication {name}?'**
  String protectionSaveReplicationTitle(String name);

  /// No description provided for @protectionReplicationPushConsequence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Replicates 1 source dataset into {target} on the destination.} other{Replicates {count} source datasets into {target} on the destination.}}'**
  String protectionReplicationPushConsequence(int count, String target);

  /// No description provided for @protectionReplicationPullConsequence.
  ///
  /// In en, this message translates to:
  /// **'Pulls into {target} on this server, overwriting conflicting local snapshots.'**
  String protectionReplicationPullConsequence(String target);

  /// No description provided for @protectionReplicationOverwriteNote.
  ///
  /// In en, this message translates to:
  /// **'Snapshots on the target that conflict with the source are overwritten when the task runs.'**
  String get protectionReplicationOverwriteNote;

  /// No description provided for @protectionReplicationRetentionNote.
  ///
  /// In en, this message translates to:
  /// **'Destination snapshots older than {value} {unit} are destroyed automatically.'**
  String protectionReplicationRetentionNote(int value, String unit);

  /// No description provided for @protectionReplicationLocalNote.
  ///
  /// In en, this message translates to:
  /// **'This is a local task; both sides live on this server.'**
  String get protectionReplicationLocalNote;

  /// No description provided for @protectionCreateRsyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Create rsync task for {path}?'**
  String protectionCreateRsyncTitle(String path);

  /// No description provided for @protectionSaveRsyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Save rsync task for {path}?'**
  String protectionSaveRsyncTitle(String path);

  /// No description provided for @protectionRsyncPushConsequence.
  ///
  /// In en, this message translates to:
  /// **'Copies {path} to {remote} and can overwrite files on the remote system.'**
  String protectionRsyncPushConsequence(String path, String remote);

  /// No description provided for @protectionRsyncPullConsequence.
  ///
  /// In en, this message translates to:
  /// **'Copies {remote} into {path} and can overwrite local files on this server.'**
  String protectionRsyncPullConsequence(String remote, String path);

  /// No description provided for @protectionRsyncRunAsNote.
  ///
  /// In en, this message translates to:
  /// **'Runs as {user} on port {port}.'**
  String protectionRsyncRunAsNote(String user, String port);

  /// No description provided for @protectionRsyncScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'The task runs on its schedule until you disable it.'**
  String get protectionRsyncScheduleNote;

  /// No description provided for @protectionDeleteReplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete replication task?'**
  String get protectionDeleteReplicationTitle;

  /// No description provided for @protectionDeleteReplicationConsequence.
  ///
  /// In en, this message translates to:
  /// **'The task definition is removed. In-flight replications keep running to completion; abort the job first if it must stop now.'**
  String get protectionDeleteReplicationConsequence;

  /// No description provided for @protectionDeleteReplicationKeepNote.
  ///
  /// In en, this message translates to:
  /// **'Snapshots already replicated to the destination are kept.'**
  String get protectionDeleteReplicationKeepNote;

  /// No description provided for @protectionDeleteCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud sync task?'**
  String get protectionDeleteCloudSyncTitle;

  /// No description provided for @protectionDeleteCloudSyncConsequence.
  ///
  /// In en, this message translates to:
  /// **'The task definition is removed. Stored cloud credentials are kept and can be reused by other tasks.'**
  String get protectionDeleteCloudSyncConsequence;

  /// No description provided for @protectionDeleteCloudSyncKeepNote.
  ///
  /// In en, this message translates to:
  /// **'Files already transferred to or from the remote remain on both sides.'**
  String get protectionDeleteCloudSyncKeepNote;

  /// No description provided for @protectionDeleteRsyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete rsync task?'**
  String get protectionDeleteRsyncTitle;

  /// No description provided for @protectionDeleteRsyncConsequence.
  ///
  /// In en, this message translates to:
  /// **'The task definition is removed. Files already transferred remain on both sides.'**
  String get protectionDeleteRsyncConsequence;

  /// No description provided for @protectionTaskStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The TrueNAS task could not be started.'**
  String get protectionTaskStartFailed;

  /// No description provided for @protectionTaskStarted.
  ///
  /// In en, this message translates to:
  /// **'{label} started.'**
  String protectionTaskStarted(String label);

  /// No description provided for @protectionJobSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Job {jobId}'**
  String protectionJobSuffix(String jobId);

  /// No description provided for @protectionStateIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get protectionStateIdle;

  /// No description provided for @protectionReplicationSubtitleRow.
  ///
  /// In en, this message translates to:
  /// **'{direction} · {state}'**
  String protectionReplicationSubtitleRow(String direction, String state);

  /// No description provided for @protectionSnapshotTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cron {schedule} · Keep {retention}'**
  String protectionSnapshotTaskSubtitle(String schedule, String retention);

  /// No description provided for @protectionRecursiveSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Recursive'**
  String get protectionRecursiveSuffix;

  /// No description provided for @protectionScrubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{schedule} · Threshold {days} days'**
  String protectionScrubSubtitle(String schedule, int days);

  /// No description provided for @protectionCloudSyncSubtitleRow.
  ///
  /// In en, this message translates to:
  /// **'{direction} {mode} · {provider}\n{path}'**
  String protectionCloudSyncSubtitleRow(
    String direction,
    String mode,
    String provider,
    String path,
  );

  /// No description provided for @protectionRsyncSubtitleRow.
  ///
  /// In en, this message translates to:
  /// **'{direction} · {mode} · {path}\n{remote}'**
  String protectionRsyncSubtitleRow(
    String direction,
    String mode,
    String path,
    String remote,
  );

  /// No description provided for @protectionTransactionGroup.
  ///
  /// In en, this message translates to:
  /// **'TXG {txg}'**
  String protectionTransactionGroup(String txg);

  /// No description provided for @protectionLabelSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get protectionLabelSchedule;

  /// No description provided for @protectionLabelRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get protectionLabelRetention;

  /// No description provided for @protectionRetentionHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String protectionRetentionHours(int count);

  /// No description provided for @protectionRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String protectionRetentionDays(int count);

  /// No description provided for @protectionRetentionWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String protectionRetentionWeeks(int count);

  /// No description provided for @protectionRetentionMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String protectionRetentionMonths(int count);

  /// No description provided for @protectionRetentionYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String protectionRetentionYears(int count);

  /// No description provided for @protectionScheduleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Schedule unavailable'**
  String get protectionScheduleUnavailable;

  /// No description provided for @protectionScrubSchedule.
  ///
  /// In en, this message translates to:
  /// **'{hour}:{minute} · day {day}'**
  String protectionScrubSchedule(String hour, String minute, String day);

  /// No description provided for @protectionLabelNaming.
  ///
  /// In en, this message translates to:
  /// **'Naming'**
  String get protectionLabelNaming;

  /// No description provided for @protectionLabelScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get protectionLabelScope;

  /// No description provided for @protectionScopeRecursiveValue.
  ///
  /// In en, this message translates to:
  /// **'Recursive'**
  String get protectionScopeRecursiveValue;

  /// No description provided for @protectionScopeSelectedOnly.
  ///
  /// In en, this message translates to:
  /// **'Selected dataset only'**
  String get protectionScopeSelectedOnly;

  /// No description provided for @protectionLabelNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get protectionLabelNoChanges;

  /// No description provided for @protectionCreateSnapshotAnyway.
  ///
  /// In en, this message translates to:
  /// **'Create snapshot'**
  String get protectionCreateSnapshotAnyway;

  /// No description provided for @protectionSkipSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Skip snapshot'**
  String get protectionSkipSnapshot;

  /// No description provided for @protectionLabelState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get protectionLabelState;

  /// No description provided for @protectionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get protectionEnabled;

  /// No description provided for @protectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get protectionDisabled;

  /// No description provided for @protectionLabelExcludes.
  ///
  /// In en, this message translates to:
  /// **'Excludes'**
  String get protectionLabelExcludes;

  /// No description provided for @snapshotReleaseHold.
  ///
  /// In en, this message translates to:
  /// **'Release hold'**
  String get snapshotReleaseHold;

  /// No description provided for @snapshotHold.
  ///
  /// In en, this message translates to:
  /// **'Hold snapshot'**
  String get snapshotHold;

  /// No description provided for @snapshotReleaseHoldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allows this snapshot to be deleted again.'**
  String get snapshotReleaseHoldSubtitle;

  /// No description provided for @snapshotHoldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blocks deletion until the hold is released.'**
  String get snapshotHoldSubtitle;

  /// No description provided for @snapshotCloneTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone to new dataset'**
  String get snapshotCloneTitle;

  /// No description provided for @snapshotCloneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creates a writable copy without changing data.'**
  String get snapshotCloneSubtitle;

  /// No description provided for @snapshotRollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Roll back to this snapshot'**
  String get snapshotRollbackTitle;

  /// No description provided for @snapshotRollbackSubtitleClean.
  ///
  /// In en, this message translates to:
  /// **'Discards changes made after this snapshot.'**
  String get snapshotRollbackSubtitleClean;

  /// No description provided for @snapshotRollbackSubtitleNewer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Discards changes and 1 newer snapshot.} other{Discards changes and {count} newer snapshots.}}'**
  String snapshotRollbackSubtitleNewer(int count);

  /// No description provided for @snapshotDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete snapshot'**
  String get snapshotDeleteTitle;

  /// No description provided for @snapshotDeleteHeldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release the hold before deleting this snapshot.'**
  String get snapshotDeleteHeldSubtitle;

  /// No description provided for @snapshotDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes this restore point permanently.'**
  String get snapshotDeleteSubtitle;

  /// No description provided for @snapshotNoActions.
  ///
  /// In en, this message translates to:
  /// **'This TrueNAS version does not expose snapshot actions to TrueDock.'**
  String get snapshotNoActions;

  /// No description provided for @snapshotRollbackHeading.
  ///
  /// In en, this message translates to:
  /// **'Roll back'**
  String get snapshotRollbackHeading;

  /// No description provided for @snapshotRollbackModeNewestOnly.
  ///
  /// In en, this message translates to:
  /// **'Only if this is the newest snapshot'**
  String get snapshotRollbackModeNewestOnly;

  /// No description provided for @snapshotRollbackModeNewer.
  ///
  /// In en, this message translates to:
  /// **'Destroy newer snapshots'**
  String get snapshotRollbackModeNewer;

  /// No description provided for @snapshotRollbackModeNewerAndClones.
  ///
  /// In en, this message translates to:
  /// **'Destroy newer snapshots and their clones'**
  String get snapshotRollbackModeNewerAndClones;

  /// No description provided for @snapshotRollbackModeNewestOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'The rollback fails if any newer snapshot exists. Safest option.'**
  String get snapshotRollbackModeNewestOnlyDescription;

  /// No description provided for @snapshotRollbackModeNewerDescription.
  ///
  /// In en, this message translates to:
  /// **'Every snapshot taken after this one is permanently destroyed.'**
  String get snapshotRollbackModeNewerDescription;

  /// No description provided for @snapshotRollbackModeNewerAndClonesDescription.
  ///
  /// In en, this message translates to:
  /// **'Newer snapshots and any datasets cloned from them are destroyed.'**
  String get snapshotRollbackModeNewerAndClonesDescription;

  /// No description provided for @snapshotRollbackNewerWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 newer snapshot exists, so this option will fail until you choose to destroy it.} other{{count} newer snapshots exist, so this option will fail until you choose to destroy them.}}'**
  String snapshotRollbackNewerWarning(int count);

  /// No description provided for @snapshotForceUnmount.
  ///
  /// In en, this message translates to:
  /// **'Force unmount if busy'**
  String get snapshotForceUnmount;

  /// No description provided for @snapshotForceUnmountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Needed when applications still hold the dataset open.'**
  String get snapshotForceUnmountSubtitle;

  /// No description provided for @snapshotCloneHeading.
  ///
  /// In en, this message translates to:
  /// **'Clone snapshot'**
  String get snapshotCloneHeading;

  /// No description provided for @snapshotCloneDescription.
  ///
  /// In en, this message translates to:
  /// **'The clone starts as a read-write dataset sharing storage with this snapshot. The snapshot cannot be deleted while the clone exists.'**
  String get snapshotCloneDescription;

  /// No description provided for @snapshotCloneDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'New dataset path'**
  String get snapshotCloneDestinationLabel;

  /// No description provided for @snapshotCreateClone.
  ///
  /// In en, this message translates to:
  /// **'Create clone'**
  String get snapshotCreateClone;

  /// No description provided for @snapshotCloneValidationPath.
  ///
  /// In en, this message translates to:
  /// **'Enter a full dataset path such as tank/restored.'**
  String get snapshotCloneValidationPath;

  /// No description provided for @snapshotCloneValidationSameDataset.
  ///
  /// In en, this message translates to:
  /// **'Choose a path different from the source dataset.'**
  String get snapshotCloneValidationSameDataset;

  /// No description provided for @snapshotCloneSuffix.
  ///
  /// In en, this message translates to:
  /// **'{dataset}-clone'**
  String snapshotCloneSuffix(String dataset);

  /// No description provided for @snapshotTaskReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review snapshot task'**
  String get snapshotTaskReviewTitle;

  /// No description provided for @snapshotTaskNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New snapshot task'**
  String get snapshotTaskNewTitle;

  /// No description provided for @snapshotTaskEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit snapshot task'**
  String get snapshotTaskEditTitle;

  /// No description provided for @snapshotTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic ZFS snapshots and retention'**
  String get snapshotTaskSubtitle;

  /// No description provided for @snapshotTaskNoDatasets.
  ///
  /// In en, this message translates to:
  /// **'No unlocked filesystem datasets are available. Create or unlock a dataset first.'**
  String get snapshotTaskNoDatasets;

  /// No description provided for @snapshotTaskDataset.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get snapshotTaskDataset;

  /// No description provided for @snapshotTaskIncludeChildren.
  ///
  /// In en, this message translates to:
  /// **'Include child datasets'**
  String get snapshotTaskIncludeChildren;

  /// No description provided for @snapshotTaskIncludeChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create snapshots recursively below this dataset.'**
  String get snapshotTaskIncludeChildrenSubtitle;

  /// No description provided for @snapshotTaskExcludes.
  ///
  /// In en, this message translates to:
  /// **'Excluded child datasets'**
  String get snapshotTaskExcludes;

  /// No description provided for @snapshotTaskExcludesHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional · one full dataset name per line'**
  String get snapshotTaskExcludesHelper;

  /// No description provided for @snapshotTaskRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get snapshotTaskRetention;

  /// No description provided for @snapshotTaskKeepFor.
  ///
  /// In en, this message translates to:
  /// **'Keep for'**
  String get snapshotTaskKeepFor;

  /// No description provided for @snapshotTaskUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get snapshotTaskUnit;

  /// No description provided for @snapshotTaskNamingSchema.
  ///
  /// In en, this message translates to:
  /// **'Naming schema'**
  String get snapshotTaskNamingSchema;

  /// No description provided for @snapshotTaskNamingHelper.
  ///
  /// In en, this message translates to:
  /// **'strftime pattern used for each snapshot name'**
  String get snapshotTaskNamingHelper;

  /// No description provided for @snapshotTaskSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get snapshotTaskSchedule;

  /// No description provided for @snapshotTaskWindowBegins.
  ///
  /// In en, this message translates to:
  /// **'Window begins'**
  String get snapshotTaskWindowBegins;

  /// No description provided for @snapshotTaskWindowEnds.
  ///
  /// In en, this message translates to:
  /// **'Window ends'**
  String get snapshotTaskWindowEnds;

  /// No description provided for @snapshotTaskAllowEmpty.
  ///
  /// In en, this message translates to:
  /// **'Snapshot unchanged datasets'**
  String get snapshotTaskAllowEmpty;

  /// No description provided for @snapshotTaskAllowEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a snapshot even when data has not changed.'**
  String get snapshotTaskAllowEmptySubtitle;

  /// No description provided for @snapshotTaskEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable immediately'**
  String get snapshotTaskEnable;

  /// No description provided for @snapshotTaskEnableCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run this schedule after the task is created.'**
  String get snapshotTaskEnableCreateSubtitle;

  /// No description provided for @snapshotTaskEnableEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this schedule to continue running.'**
  String get snapshotTaskEnableEditSubtitle;

  /// No description provided for @snapshotTaskCreate.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get snapshotTaskCreate;

  /// No description provided for @snapshotTaskNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get snapshotTaskNone;

  /// No description provided for @snapshotTaskScope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get snapshotTaskScope;

  /// No description provided for @snapshotTaskNaming.
  ///
  /// In en, this message translates to:
  /// **'Naming'**
  String get snapshotTaskNaming;

  /// No description provided for @snapshotTaskState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get snapshotTaskState;

  /// No description provided for @snapshotTaskRetentionValue.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String snapshotTaskRetentionValue(String value, String unit);

  /// No description provided for @snapshotTaskExcludedList.
  ///
  /// In en, this message translates to:
  /// **'Excluded datasets: {datasets}'**
  String snapshotTaskExcludedList(String datasets);

  /// No description provided for @snapshotTaskRetentionNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS automatically removes snapshots created by this task after the configured retention period.'**
  String get snapshotTaskRetentionNotice;

  /// No description provided for @snapshotUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get snapshotUnitHours;

  /// No description provided for @snapshotUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get snapshotUnitDays;

  /// No description provided for @snapshotUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get snapshotUnitWeeks;

  /// No description provided for @snapshotUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get snapshotUnitMonths;

  /// No description provided for @snapshotUnitYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get snapshotUnitYears;

  /// No description provided for @snapshotPresetHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get snapshotPresetHourly;

  /// No description provided for @snapshotPresetDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get snapshotPresetDaily;

  /// No description provided for @snapshotPresetWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get snapshotPresetWeekly;

  /// No description provided for @snapshotPresetMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get snapshotPresetMonthly;

  /// No description provided for @snapshotPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get snapshotPresetCustom;

  /// No description provided for @snapshotScheduleEveryHour.
  ///
  /// In en, this message translates to:
  /// **'At the start of every hour'**
  String get snapshotScheduleEveryHour;

  /// No description provided for @snapshotScheduleEverySunday.
  ///
  /// In en, this message translates to:
  /// **'Every Sunday at 00:00'**
  String get snapshotScheduleEverySunday;

  /// No description provided for @snapshotScheduleFirstOfMonth.
  ///
  /// In en, this message translates to:
  /// **'On day 1 of every month at 00:00'**
  String get snapshotScheduleFirstOfMonth;

  /// No description provided for @snapshotScheduleEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day at 00:00'**
  String get snapshotScheduleEveryDay;

  /// No description provided for @snapshotScheduleCron.
  ///
  /// In en, this message translates to:
  /// **'Cron {expression}'**
  String snapshotScheduleCron(String expression);

  /// No description provided for @snapshotCronMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get snapshotCronMinute;

  /// No description provided for @snapshotCronHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get snapshotCronHour;

  /// No description provided for @snapshotCronDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get snapshotCronDayOfMonth;

  /// No description provided for @snapshotCronMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get snapshotCronMonth;

  /// No description provided for @snapshotCronDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of week (1 Monday–7 Sunday)'**
  String get snapshotCronDayOfWeek;

  /// No description provided for @snapshotValidationDataset.
  ///
  /// In en, this message translates to:
  /// **'Choose a dataset.'**
  String get snapshotValidationDataset;

  /// No description provided for @snapshotValidationRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention must be at least 1.'**
  String get snapshotValidationRetention;

  /// No description provided for @snapshotValidationNamingRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a snapshot naming schema.'**
  String get snapshotValidationNamingRequired;

  /// No description provided for @snapshotValidationNamingSlash.
  ///
  /// In en, this message translates to:
  /// **'Snapshot names cannot contain /.'**
  String get snapshotValidationNamingSlash;

  /// No description provided for @snapshotValidationExclude.
  ///
  /// In en, this message translates to:
  /// **'Each exclusion must be a child of the selected dataset.'**
  String get snapshotValidationExclude;

  /// No description provided for @snapshotValidationCron.
  ///
  /// In en, this message translates to:
  /// **'Use a numeric cron expression such as *, 00, or */2.'**
  String get snapshotValidationCron;

  /// No description provided for @snapshotValidationTime.
  ///
  /// In en, this message translates to:
  /// **'Use 24-hour time in HH:mm format.'**
  String get snapshotValidationTime;

  /// No description provided for @replicationReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review replication'**
  String get replicationReviewTitle;

  /// No description provided for @replicationNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New replication'**
  String get replicationNewTitle;

  /// No description provided for @replicationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit replication'**
  String get replicationEditTitle;

  /// No description provided for @replicationTaskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get replicationTaskName;

  /// No description provided for @replicationTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get replicationTransport;

  /// No description provided for @replicationTransportSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get replicationTransportSsh;

  /// No description provided for @replicationTransportSshNetcat.
  ///
  /// In en, this message translates to:
  /// **'SSH + netcat (faster, less secure)'**
  String get replicationTransportSshNetcat;

  /// No description provided for @replicationTransportLocal.
  ///
  /// In en, this message translates to:
  /// **'Local (same system)'**
  String get replicationTransportLocal;

  /// No description provided for @replicationSshLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved SSH connections. Check that the account has permission to read credentials.'**
  String get replicationSshLoadFailed;

  /// No description provided for @replicationNoSshCredentials.
  ///
  /// In en, this message translates to:
  /// **'No saved SSH connections. Create one in the TrueNAS web UI under Credentials, then reopen this editor. TrueDock does not create SSH keys.'**
  String get replicationNoSshCredentials;

  /// No description provided for @replicationSshConnection.
  ///
  /// In en, this message translates to:
  /// **'SSH connection'**
  String get replicationSshConnection;

  /// No description provided for @replicationDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get replicationDirection;

  /// No description provided for @replicationDirectionPush.
  ///
  /// In en, this message translates to:
  /// **'Push (this server to target)'**
  String get replicationDirectionPush;

  /// No description provided for @replicationDirectionPull.
  ///
  /// In en, this message translates to:
  /// **'Pull (target to this server)'**
  String get replicationDirectionPull;

  /// No description provided for @replicationSourceDatasets.
  ///
  /// In en, this message translates to:
  /// **'Source datasets'**
  String get replicationSourceDatasets;

  /// No description provided for @replicationSourceDatasetsHelp.
  ///
  /// In en, this message translates to:
  /// **'One task can replicate several datasets into one target.'**
  String get replicationSourceDatasetsHelp;

  /// No description provided for @replicationNoDatasets.
  ///
  /// In en, this message translates to:
  /// **'No datasets were reported by this server.'**
  String get replicationNoDatasets;

  /// No description provided for @replicationTargetDataset.
  ///
  /// In en, this message translates to:
  /// **'Target dataset'**
  String get replicationTargetDataset;

  /// No description provided for @replicationTargetHelper.
  ///
  /// In en, this message translates to:
  /// **'Add /name at the end to create a new dataset.'**
  String get replicationTargetHelper;

  /// No description provided for @replicationNamingSchema.
  ///
  /// In en, this message translates to:
  /// **'Snapshot naming schema'**
  String get replicationNamingSchema;

  /// No description provided for @replicationNamingHelper.
  ///
  /// In en, this message translates to:
  /// **'Which source snapshots this task replicates.'**
  String get replicationNamingHelper;

  /// No description provided for @replicationRetentionHeading.
  ///
  /// In en, this message translates to:
  /// **'Retention on the destination'**
  String get replicationRetentionHeading;

  /// No description provided for @replicationRetentionSource.
  ///
  /// In en, this message translates to:
  /// **'Same as source'**
  String get replicationRetentionSource;

  /// No description provided for @replicationRetentionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom retention'**
  String get replicationRetentionCustom;

  /// No description provided for @replicationRetentionNone.
  ///
  /// In en, this message translates to:
  /// **'Keep forever'**
  String get replicationRetentionNone;

  /// No description provided for @replicationRetentionSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Destination snapshots follow the source task retention.'**
  String get replicationRetentionSourceDescription;

  /// No description provided for @replicationRetentionCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'Destination snapshots are destroyed after the period you set.'**
  String get replicationRetentionCustomDescription;

  /// No description provided for @replicationRetentionNoneDescription.
  ///
  /// In en, this message translates to:
  /// **'Destination snapshots are never destroyed automatically.'**
  String get replicationRetentionNoneDescription;

  /// No description provided for @replicationKeepFor.
  ///
  /// In en, this message translates to:
  /// **'Keep for'**
  String get replicationKeepFor;

  /// No description provided for @replicationUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get replicationUnitHours;

  /// No description provided for @replicationUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get replicationUnitDays;

  /// No description provided for @replicationUnitWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get replicationUnitWeeks;

  /// No description provided for @replicationUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get replicationUnitMonths;

  /// No description provided for @replicationUnitYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get replicationUnitYears;

  /// No description provided for @replicationScheduleHeading.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get replicationScheduleHeading;

  /// No description provided for @replicationRunOnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Run on a schedule'**
  String get replicationRunOnSchedule;

  /// No description provided for @replicationRunOnScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to run this task only manually.'**
  String get replicationRunOnScheduleSubtitle;

  /// No description provided for @replicationRecursive.
  ///
  /// In en, this message translates to:
  /// **'Recursive'**
  String get replicationRecursive;

  /// No description provided for @replicationRecursiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include child datasets of each source.'**
  String get replicationRecursiveSubtitle;

  /// No description provided for @replicationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get replicationEnabled;

  /// No description provided for @replicationEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disabled tasks stay configured but never run.'**
  String get replicationEnabledSubtitle;

  /// No description provided for @replicationReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get replicationReviewName;

  /// No description provided for @replicationReviewDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get replicationReviewDirection;

  /// No description provided for @replicationReviewTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get replicationReviewTransport;

  /// No description provided for @replicationReviewSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get replicationReviewSsh;

  /// No description provided for @replicationNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get replicationNotSelected;

  /// No description provided for @replicationReviewSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get replicationReviewSources;

  /// No description provided for @replicationReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get replicationReviewNone;

  /// No description provided for @replicationReviewTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get replicationReviewTarget;

  /// No description provided for @replicationReviewSnapshots.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get replicationReviewSnapshots;

  /// No description provided for @replicationReviewRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get replicationReviewRetention;

  /// No description provided for @replicationRetentionValue.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String replicationRetentionValue(String value, String unit);

  /// No description provided for @replicationReviewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get replicationReviewSchedule;

  /// No description provided for @replicationManualOnly.
  ///
  /// In en, this message translates to:
  /// **'Manual only'**
  String get replicationManualOnly;

  /// No description provided for @replicationReviewRecursive.
  ///
  /// In en, this message translates to:
  /// **'Recursive'**
  String get replicationReviewRecursive;

  /// No description provided for @replicationReviewEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get replicationReviewEnabled;

  /// No description provided for @replicationYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get replicationYes;

  /// No description provided for @replicationNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get replicationNo;

  /// No description provided for @replicationOverwriteWarning.
  ///
  /// In en, this message translates to:
  /// **'Replication overwrites snapshots on the target dataset that conflict with the source. Verify the target path before saving, especially for a push task.'**
  String get replicationOverwriteWarning;

  /// No description provided for @replicationCustomRetentionWarning.
  ///
  /// In en, this message translates to:
  /// **'Custom retention destroys destination snapshots once they age past the period above.'**
  String get replicationCustomRetentionWarning;

  /// No description provided for @replicationCronMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get replicationCronMinute;

  /// No description provided for @replicationCronHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get replicationCronHour;

  /// No description provided for @replicationCronDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get replicationCronDay;

  /// No description provided for @replicationCronMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get replicationCronMonth;

  /// No description provided for @replicationCronWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get replicationCronWeekday;

  /// No description provided for @replicationValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a task name.'**
  String get replicationValidationName;

  /// No description provided for @replicationValidationSources.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one source dataset.'**
  String get replicationValidationSources;

  /// No description provided for @replicationValidationTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a target dataset path.'**
  String get replicationValidationTarget;

  /// No description provided for @replicationValidationSsh.
  ///
  /// In en, this message translates to:
  /// **'Choose the saved SSH connection for this transport.'**
  String get replicationValidationSsh;

  /// No description provided for @replicationValidationNamingRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a snapshot naming schema.'**
  String get replicationValidationNamingRequired;

  /// No description provided for @replicationValidationNamingSlash.
  ///
  /// In en, this message translates to:
  /// **'Snapshot names cannot contain /.'**
  String get replicationValidationNamingSlash;

  /// No description provided for @replicationValidationRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention must be at least 1.'**
  String get replicationValidationRetention;

  /// No description provided for @replicationValidationTargetSameAsSource.
  ///
  /// In en, this message translates to:
  /// **'The target cannot be the same as a source dataset.'**
  String get replicationValidationTargetSameAsSource;

  /// No description provided for @taskPresetHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get taskPresetHourly;

  /// No description provided for @taskPresetDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get taskPresetDaily;

  /// No description provided for @taskPresetWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get taskPresetWeekly;

  /// No description provided for @taskPresetMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get taskPresetMonthly;

  /// No description provided for @taskPresetCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get taskPresetCustom;

  /// No description provided for @taskScheduleEveryHour.
  ///
  /// In en, this message translates to:
  /// **'At the start of every hour'**
  String get taskScheduleEveryHour;

  /// No description provided for @taskScheduleEverySunday.
  ///
  /// In en, this message translates to:
  /// **'Every Sunday at 00:00'**
  String get taskScheduleEverySunday;

  /// No description provided for @taskScheduleFirstOfMonth.
  ///
  /// In en, this message translates to:
  /// **'On day 1 of every month at 00:00'**
  String get taskScheduleFirstOfMonth;

  /// No description provided for @taskScheduleEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day at 00:00'**
  String get taskScheduleEveryDay;

  /// No description provided for @taskScheduleCron.
  ///
  /// In en, this message translates to:
  /// **'Cron {expression}'**
  String taskScheduleCron(String expression);

  /// No description provided for @taskScheduleCronInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a numeric cron expression such as *, 00, or */2.'**
  String get taskScheduleCronInvalid;

  /// No description provided for @rsyncReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review rsync task'**
  String get rsyncReviewTitle;

  /// No description provided for @rsyncNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New rsync task'**
  String get rsyncNewTitle;

  /// No description provided for @rsyncEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit rsync task'**
  String get rsyncEditTitle;

  /// No description provided for @rsyncLocalPath.
  ///
  /// In en, this message translates to:
  /// **'Local path'**
  String get rsyncLocalPath;

  /// No description provided for @rsyncLocalPathHelper.
  ///
  /// In en, this message translates to:
  /// **'Absolute path on this server, e.g. /mnt/tank/media.'**
  String get rsyncLocalPathHelper;

  /// No description provided for @rsyncRunAsUser.
  ///
  /// In en, this message translates to:
  /// **'Run as user'**
  String get rsyncRunAsUser;

  /// No description provided for @rsyncRunAsUserHelp.
  ///
  /// In en, this message translates to:
  /// **'Must match the user of the SSH connection in SSH mode.'**
  String get rsyncRunAsUserHelp;

  /// No description provided for @rsyncNoLocalUsers.
  ///
  /// In en, this message translates to:
  /// **'No local users were reported by this server.'**
  String get rsyncNoLocalUsers;

  /// No description provided for @rsyncUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get rsyncUser;

  /// No description provided for @rsyncDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get rsyncDirection;

  /// No description provided for @rsyncDirectionPush.
  ///
  /// In en, this message translates to:
  /// **'Push (this server to remote)'**
  String get rsyncDirectionPush;

  /// No description provided for @rsyncDirectionPull.
  ///
  /// In en, this message translates to:
  /// **'Pull (remote to this server)'**
  String get rsyncDirectionPull;

  /// No description provided for @rsyncDirectionPushDescription.
  ///
  /// In en, this message translates to:
  /// **'Sends the local path to the remote host or module.'**
  String get rsyncDirectionPushDescription;

  /// No description provided for @rsyncDirectionPullDescription.
  ///
  /// In en, this message translates to:
  /// **'Copies the remote path into the local path on this server.'**
  String get rsyncDirectionPullDescription;

  /// No description provided for @rsyncRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get rsyncRemote;

  /// No description provided for @rsyncMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get rsyncMode;

  /// No description provided for @rsyncModeSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get rsyncModeSsh;

  /// No description provided for @rsyncModeModule.
  ///
  /// In en, this message translates to:
  /// **'rsync module'**
  String get rsyncModeModule;

  /// No description provided for @rsyncRemoteHost.
  ///
  /// In en, this message translates to:
  /// **'Remote host'**
  String get rsyncRemoteHost;

  /// No description provided for @rsyncRemotePort.
  ///
  /// In en, this message translates to:
  /// **'Remote port (optional)'**
  String get rsyncRemotePort;

  /// No description provided for @rsyncRemotePortHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for the default ({port}).'**
  String rsyncRemotePortHelper(int port);

  /// No description provided for @rsyncRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Remote path'**
  String get rsyncRemotePath;

  /// No description provided for @rsyncRemoteModule.
  ///
  /// In en, this message translates to:
  /// **'Remote module'**
  String get rsyncRemoteModule;

  /// No description provided for @rsyncRemoteModuleHelper.
  ///
  /// In en, this message translates to:
  /// **'Module name defined by the remote rsync daemon.'**
  String get rsyncRemoteModuleHelper;

  /// No description provided for @rsyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get rsyncDescription;

  /// No description provided for @rsyncValidateRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Validate remote path'**
  String get rsyncValidateRemotePath;

  /// No description provided for @rsyncValidateRemotePathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the server to check the remote path before running.'**
  String get rsyncValidateRemotePathSubtitle;

  /// No description provided for @rsyncReviewHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get rsyncReviewHost;

  /// No description provided for @rsyncReviewPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get rsyncReviewPort;

  /// No description provided for @rsyncReviewModule.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get rsyncReviewModule;

  /// No description provided for @rsyncPushWarning.
  ///
  /// In en, this message translates to:
  /// **'A push task writes into the remote destination and can overwrite files there.'**
  String get rsyncPushWarning;

  /// No description provided for @rsyncPullWarning.
  ///
  /// In en, this message translates to:
  /// **'A pull task writes into {path} on this server and can overwrite local files.'**
  String rsyncPullWarning(String path);

  /// No description provided for @rsyncValidationPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a local path.'**
  String get rsyncValidationPathRequired;

  /// No description provided for @rsyncValidationPathAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Use an absolute path starting with /.'**
  String get rsyncValidationPathAbsolute;

  /// No description provided for @rsyncValidationUser.
  ///
  /// In en, this message translates to:
  /// **'Choose the local user to run as.'**
  String get rsyncValidationUser;

  /// No description provided for @rsyncValidationRemoteHost.
  ///
  /// In en, this message translates to:
  /// **'Enter the remote host.'**
  String get rsyncValidationRemoteHost;

  /// No description provided for @rsyncValidationRemotePort.
  ///
  /// In en, this message translates to:
  /// **'Use a port between 1 and 65535.'**
  String get rsyncValidationRemotePort;

  /// No description provided for @rsyncValidationRemotePath.
  ///
  /// In en, this message translates to:
  /// **'Enter the remote path.'**
  String get rsyncValidationRemotePath;

  /// No description provided for @rsyncValidationSsh.
  ///
  /// In en, this message translates to:
  /// **'Choose the saved SSH connection.'**
  String get rsyncValidationSsh;

  /// No description provided for @rsyncValidationRemoteModule.
  ///
  /// In en, this message translates to:
  /// **'Enter the remote rsync module name.'**
  String get rsyncValidationRemoteModule;

  /// No description provided for @cloudSyncReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review cloud sync'**
  String get cloudSyncReviewTitle;

  /// No description provided for @cloudSyncNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New cloud sync'**
  String get cloudSyncNewTitle;

  /// No description provided for @cloudSyncEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit cloud sync'**
  String get cloudSyncEditTitle;

  /// No description provided for @cloudSyncTaskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get cloudSyncTaskName;

  /// No description provided for @cloudSyncCredentialHeading.
  ///
  /// In en, this message translates to:
  /// **'Cloud credential'**
  String get cloudSyncCredentialHeading;

  /// No description provided for @cloudSyncCredentialsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved cloud credentials. Check that the account has permission to read credentials.'**
  String get cloudSyncCredentialsLoadFailed;

  /// No description provided for @cloudSyncNoCredentials.
  ///
  /// In en, this message translates to:
  /// **'No saved cloud credentials. Create one in the TrueNAS web UI under Credentials, then reopen this editor. TrueDock does not create cloud credentials.'**
  String get cloudSyncNoCredentials;

  /// No description provided for @cloudSyncCredential.
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get cloudSyncCredential;

  /// No description provided for @cloudSyncDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get cloudSyncDirection;

  /// No description provided for @cloudSyncDirectionPush.
  ///
  /// In en, this message translates to:
  /// **'Push (this server to cloud)'**
  String get cloudSyncDirectionPush;

  /// No description provided for @cloudSyncDirectionPull.
  ///
  /// In en, this message translates to:
  /// **'Pull (cloud to this server)'**
  String get cloudSyncDirectionPull;

  /// No description provided for @cloudSyncDirectionPushDescription.
  ///
  /// In en, this message translates to:
  /// **'Sends the local path up to the cloud provider.'**
  String get cloudSyncDirectionPushDescription;

  /// No description provided for @cloudSyncDirectionPullDescription.
  ///
  /// In en, this message translates to:
  /// **'Downloads the remote location into the local path.'**
  String get cloudSyncDirectionPullDescription;

  /// No description provided for @cloudSyncTransferMode.
  ///
  /// In en, this message translates to:
  /// **'Transfer mode'**
  String get cloudSyncTransferMode;

  /// No description provided for @cloudSyncModeSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get cloudSyncModeSync;

  /// No description provided for @cloudSyncModeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get cloudSyncModeCopy;

  /// No description provided for @cloudSyncModeMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get cloudSyncModeMove;

  /// No description provided for @cloudSyncModeSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Makes the destination match the source. Files missing from the source are deleted at the destination.'**
  String get cloudSyncModeSyncDescription;

  /// No description provided for @cloudSyncModeCopyDescription.
  ///
  /// In en, this message translates to:
  /// **'Copies new and changed files. Nothing is ever deleted.'**
  String get cloudSyncModeCopyDescription;

  /// No description provided for @cloudSyncModeMoveDescription.
  ///
  /// In en, this message translates to:
  /// **'Copies files, then deletes them from the source once the transfer succeeds.'**
  String get cloudSyncModeMoveDescription;

  /// No description provided for @cloudSyncLocalPath.
  ///
  /// In en, this message translates to:
  /// **'Local path'**
  String get cloudSyncLocalPath;

  /// No description provided for @cloudSyncLocalPathHelper.
  ///
  /// In en, this message translates to:
  /// **'Absolute path, e.g. /mnt/tank/media.'**
  String get cloudSyncLocalPathHelper;

  /// No description provided for @cloudSyncRemoteLocation.
  ///
  /// In en, this message translates to:
  /// **'Remote location'**
  String get cloudSyncRemoteLocation;

  /// No description provided for @cloudSyncBucket.
  ///
  /// In en, this message translates to:
  /// **'Bucket'**
  String get cloudSyncBucket;

  /// No description provided for @cloudSyncFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get cloudSyncFolder;

  /// No description provided for @cloudSyncFolderBucketHelper.
  ///
  /// In en, this message translates to:
  /// **'Path inside the bucket. Leave blank for the root.'**
  String get cloudSyncFolderBucketHelper;

  /// No description provided for @cloudSyncFolderDriveHelper.
  ///
  /// In en, this message translates to:
  /// **'Path on the remote drive. Leave blank for the root.'**
  String get cloudSyncFolderDriveHelper;

  /// No description provided for @cloudSyncStorageClass.
  ///
  /// In en, this message translates to:
  /// **'Storage class (optional)'**
  String get cloudSyncStorageClass;

  /// No description provided for @cloudSyncStorageClassHelper.
  ///
  /// In en, this message translates to:
  /// **'S3 only, e.g. STANDARD or GLACIER.'**
  String get cloudSyncStorageClassHelper;

  /// No description provided for @cloudSyncAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cloudSyncAdvanced;

  /// No description provided for @cloudSyncTransfers.
  ///
  /// In en, this message translates to:
  /// **'Concurrent transfers (optional)'**
  String get cloudSyncTransfers;

  /// No description provided for @cloudSyncTransfersHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for the server default.'**
  String get cloudSyncTransfersHelper;

  /// No description provided for @cloudSyncEncryptFiles.
  ///
  /// In en, this message translates to:
  /// **'Encrypt files'**
  String get cloudSyncEncryptFiles;

  /// No description provided for @cloudSyncEncryptFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypts file contents before they leave this server.'**
  String get cloudSyncEncryptFilesSubtitle;

  /// No description provided for @cloudSyncEncryptNames.
  ///
  /// In en, this message translates to:
  /// **'Encrypt file names'**
  String get cloudSyncEncryptNames;

  /// No description provided for @cloudSyncEncryptNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides names as well as contents.'**
  String get cloudSyncEncryptNamesSubtitle;

  /// No description provided for @cloudSyncPassword.
  ///
  /// In en, this message translates to:
  /// **'Encryption password'**
  String get cloudSyncPassword;

  /// No description provided for @cloudSyncPasswordEdit.
  ///
  /// In en, this message translates to:
  /// **'New encryption password (optional)'**
  String get cloudSyncPasswordEdit;

  /// No description provided for @cloudSyncPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Required. Losing it makes the backup unreadable.'**
  String get cloudSyncPasswordHelper;

  /// No description provided for @cloudSyncPasswordEditHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the existing password.'**
  String get cloudSyncPasswordEditHelper;

  /// No description provided for @cloudSyncShowSecret.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get cloudSyncShowSecret;

  /// No description provided for @cloudSyncHideSecret.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get cloudSyncHideSecret;

  /// No description provided for @cloudSyncSalt.
  ///
  /// In en, this message translates to:
  /// **'Encryption salt (optional)'**
  String get cloudSyncSalt;

  /// No description provided for @cloudSyncSaltEdit.
  ///
  /// In en, this message translates to:
  /// **'New encryption salt (optional)'**
  String get cloudSyncSaltEdit;

  /// No description provided for @cloudSyncSaltHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional extra secret.'**
  String get cloudSyncSaltHelper;

  /// No description provided for @cloudSyncSaltEditHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the existing salt.'**
  String get cloudSyncSaltEditHelper;

  /// No description provided for @cloudSyncSecretsNotice.
  ///
  /// In en, this message translates to:
  /// **'Encryption secrets are sent only to the connected server. TrueDock never stores, logs, or autofills them, and cannot recover a lost password.'**
  String get cloudSyncSecretsNotice;

  /// No description provided for @cloudSyncPreservedFields.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings on this task ({fields}) are preserved and sent back unchanged. Pre/post scripts run commands on the server and are edited in the web UI.'**
  String cloudSyncPreservedFields(String fields);

  /// No description provided for @cloudSyncPreservedFieldsEllipsis.
  ///
  /// In en, this message translates to:
  /// **', …'**
  String get cloudSyncPreservedFieldsEllipsis;

  /// No description provided for @cloudSyncReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cloudSyncReviewName;

  /// No description provided for @cloudSyncReviewRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get cloudSyncReviewRemote;

  /// No description provided for @cloudSyncReviewTransfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get cloudSyncReviewTransfers;

  /// No description provided for @cloudSyncServerDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get cloudSyncServerDefault;

  /// No description provided for @cloudSyncReviewEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get cloudSyncReviewEncryption;

  /// No description provided for @cloudSyncEncryptionBoth.
  ///
  /// In en, this message translates to:
  /// **'Contents and file names'**
  String get cloudSyncEncryptionBoth;

  /// No description provided for @cloudSyncEncryptionContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get cloudSyncEncryptionContents;

  /// No description provided for @cloudSyncEncryptionOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get cloudSyncEncryptionOff;

  /// No description provided for @cloudSyncSyncPushWarning.
  ///
  /// In en, this message translates to:
  /// **'Sync makes the remote match the local path. Files that no longer exist locally are deleted from the cloud.'**
  String get cloudSyncSyncPushWarning;

  /// No description provided for @cloudSyncSyncPullWarning.
  ///
  /// In en, this message translates to:
  /// **'Sync makes {path} match the remote. Local files that no longer exist remotely are deleted.'**
  String cloudSyncSyncPullWarning(String path);

  /// No description provided for @cloudSyncMovePushWarning.
  ///
  /// In en, this message translates to:
  /// **'Move uploads the files, then deletes them from {path} on this server.'**
  String cloudSyncMovePushWarning(String path);

  /// No description provided for @cloudSyncMovePullWarning.
  ///
  /// In en, this message translates to:
  /// **'Move downloads the files, then deletes them from the cloud provider.'**
  String get cloudSyncMovePullWarning;

  /// No description provided for @cloudSyncCopyNotice.
  ///
  /// In en, this message translates to:
  /// **'Copy never deletes anything on either side.'**
  String get cloudSyncCopyNotice;

  /// No description provided for @cloudSyncEncryptionReminder.
  ///
  /// In en, this message translates to:
  /// **'Keep the encryption password somewhere safe. Without it the uploaded data cannot be restored.'**
  String get cloudSyncEncryptionReminder;

  /// No description provided for @cloudSyncValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a task name.'**
  String get cloudSyncValidationName;

  /// No description provided for @cloudSyncValidationPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a local path.'**
  String get cloudSyncValidationPathRequired;

  /// No description provided for @cloudSyncValidationPathAbsolute.
  ///
  /// In en, this message translates to:
  /// **'Use an absolute path starting with /.'**
  String get cloudSyncValidationPathAbsolute;

  /// No description provided for @cloudSyncValidationCredential.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved cloud credential.'**
  String get cloudSyncValidationCredential;

  /// No description provided for @cloudSyncValidationBucket.
  ///
  /// In en, this message translates to:
  /// **'Enter the bucket for this provider.'**
  String get cloudSyncValidationBucket;

  /// No description provided for @cloudSyncValidationTransfers.
  ///
  /// In en, this message translates to:
  /// **'Use between 1 and 64 concurrent transfers.'**
  String get cloudSyncValidationTransfers;

  /// No description provided for @cloudSyncValidationPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter an encryption password, or turn encryption off.'**
  String get cloudSyncValidationPassword;

  /// No description provided for @sysSectionAccounts.
  ///
  /// In en, this message translates to:
  /// **'Users and access'**
  String get sysSectionAccounts;

  /// No description provided for @sysPrivilegesTitle.
  ///
  /// In en, this message translates to:
  /// **'Privileges'**
  String get sysPrivilegesTitle;

  /// No description provided for @sysPrivilegesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which groups can administer this server'**
  String get sysPrivilegesSubtitle;

  /// No description provided for @sysPrivilegesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No privileges configured.'**
  String get sysPrivilegesEmpty;

  /// No description provided for @sysPrivilegeCreate.
  ///
  /// In en, this message translates to:
  /// **'Add privilege'**
  String get sysPrivilegeCreate;

  /// No description provided for @sysPrivilegeCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New privilege'**
  String get sysPrivilegeCreateTitle;

  /// No description provided for @sysPrivilegeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String sysPrivilegeEditTitle(String name);

  /// No description provided for @sysPrivilegeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysPrivilegeName;

  /// No description provided for @sysPrivilegeBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get sysPrivilegeBuiltin;

  /// No description provided for @sysPrivilegeBuiltinNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS ships this privilege. Narrowing it can remove your own administrative access, and it cannot be deleted.'**
  String get sysPrivilegeBuiltinNotice;

  /// No description provided for @sysPrivilegeGroups.
  ///
  /// In en, this message translates to:
  /// **'Local groups'**
  String get sysPrivilegeGroups;

  /// No description provided for @sysPrivilegeNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get sysPrivilegeNoGroups;

  /// No description provided for @sysPrivilegeRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get sysPrivilegeRoles;

  /// No description provided for @sysPrivilegeRoleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No roles} =1{1 role} other{{count} roles}}'**
  String sysPrivilegeRoleCount(int count);

  /// No description provided for @sysPrivilegeEffectiveRoles.
  ///
  /// In en, this message translates to:
  /// **'Grants {count} roles in total, including those implied by the ones selected.'**
  String sysPrivilegeEffectiveRoles(int count);

  /// No description provided for @sysPrivilegeFullAdminNotice.
  ///
  /// In en, this message translates to:
  /// **'FULL_ADMIN grants everything, so the other selections have no additional effect.'**
  String get sysPrivilegeFullAdminNotice;

  /// No description provided for @sysPrivilegeWebShell.
  ///
  /// In en, this message translates to:
  /// **'Allow web shell'**
  String get sysPrivilegeWebShell;

  /// No description provided for @sysPrivilegeWebShellNotice.
  ///
  /// In en, this message translates to:
  /// **'The web shell runs as root, so this grants full control regardless of the roles above.'**
  String get sysPrivilegeWebShellNotice;

  /// No description provided for @sysPrivilegeSearchRoles.
  ///
  /// In en, this message translates to:
  /// **'Search roles'**
  String get sysPrivilegeSearchRoles;

  /// No description provided for @sysPrivilegeApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change {name}?'**
  String sysPrivilegeApplyTitle(String name);

  /// No description provided for @sysPrivilegeApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Save privilege'**
  String get sysPrivilegeApplyAction;

  /// No description provided for @sysPrivilegeApplyConsequence.
  ///
  /// In en, this message translates to:
  /// **'Members of the selected groups gain these roles on {server} immediately.'**
  String sysPrivilegeApplyConsequence(String server);

  /// No description provided for @sysPrivilegeApplyConsequenceUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'This grants unrestricted administration. Anyone in these groups can change or destroy anything on the server.'**
  String get sysPrivilegeApplyConsequenceUnrestricted;

  /// No description provided for @sysPrivilegeApplyConsequenceLockout.
  ///
  /// In en, this message translates to:
  /// **'Narrowing a built-in privilege can remove your own access. Verify another account keeps full administration first.'**
  String get sysPrivilegeApplyConsequenceLockout;

  /// No description provided for @sysPrivilegeCreated.
  ///
  /// In en, this message translates to:
  /// **'Privilege created.'**
  String get sysPrivilegeCreated;

  /// No description provided for @sysPrivilegeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Privilege updated.'**
  String get sysPrivilegeUpdated;

  /// No description provided for @sysPrivilegeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Privilege deleted.'**
  String get sysPrivilegeDeleted;

  /// No description provided for @sysPrivilegeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String sysPrivilegeDeleteTitle(String name);

  /// No description provided for @sysPrivilegeDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete privilege'**
  String get sysPrivilegeDeleteAction;

  /// No description provided for @sysPrivilegeDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Members of its groups lose these roles immediately.'**
  String get sysPrivilegeDeleteConsequence;

  /// No description provided for @sysPrivilegeValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this privilege.'**
  String get sysPrivilegeValidationName;

  /// No description provided for @sysPrivilegeValidationRoles.
  ///
  /// In en, this message translates to:
  /// **'Select at least one role, or allow the web shell.'**
  String get sysPrivilegeValidationRoles;

  /// No description provided for @sysSectionNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get sysSectionNetwork;

  /// No description provided for @sysMailTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert email'**
  String get sysMailTitle;

  /// No description provided for @sysMailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Outgoing SMTP server for alerts and reports'**
  String get sysMailSubtitle;

  /// No description provided for @sysMailNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get sysMailNotConfigured;

  /// No description provided for @sysMailEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert email'**
  String get sysMailEditTitle;

  /// No description provided for @sysMailFromAddress.
  ///
  /// In en, this message translates to:
  /// **'From address'**
  String get sysMailFromAddress;

  /// No description provided for @sysMailFromName.
  ///
  /// In en, this message translates to:
  /// **'From name'**
  String get sysMailFromName;

  /// No description provided for @sysMailServer.
  ///
  /// In en, this message translates to:
  /// **'Outgoing server'**
  String get sysMailServer;

  /// No description provided for @sysMailPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get sysMailPort;

  /// No description provided for @sysMailSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sysMailSecurity;

  /// No description provided for @sysMailSecurityPlain.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysMailSecurityPlain;

  /// No description provided for @sysMailSecuritySsl.
  ///
  /// In en, this message translates to:
  /// **'SSL'**
  String get sysMailSecuritySsl;

  /// No description provided for @sysMailSecurityTls.
  ///
  /// In en, this message translates to:
  /// **'STARTTLS'**
  String get sysMailSecurityTls;

  /// No description provided for @sysMailAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to the server'**
  String get sysMailAuthentication;

  /// No description provided for @sysMailUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get sysMailUsername;

  /// No description provided for @sysMailPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get sysMailPassword;

  /// No description provided for @sysMailPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep the stored password. TrueDock never reads it back from the server.'**
  String get sysMailPasswordHelper;

  /// No description provided for @sysMailOauthNotice.
  ///
  /// In en, this message translates to:
  /// **'This server signs in with OAuth. TrueDock can change the addresses and test delivery, but the OAuth credential must be managed in the TrueNAS web interface.'**
  String get sysMailOauthNotice;

  /// No description provided for @sysMailSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test message'**
  String get sysMailSendTest;

  /// No description provided for @sysMailTestSubject.
  ///
  /// In en, this message translates to:
  /// **'TrueDock test message'**
  String get sysMailTestSubject;

  /// No description provided for @sysMailTestBody.
  ///
  /// In en, this message translates to:
  /// **'This is a test message sent from TrueDock to confirm the alert email settings work.'**
  String get sysMailTestBody;

  /// No description provided for @sysMailTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test message sent to {recipient}.'**
  String sysMailTestSent(String recipient);

  /// No description provided for @sysMailTestSentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Test message sent.'**
  String get sysMailTestSentUnknown;

  /// No description provided for @sysMailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alert email settings updated.'**
  String get sysMailUpdated;

  /// No description provided for @sysMailNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get sysMailNoChanges;

  /// No description provided for @sysMailApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change alert email settings?'**
  String get sysMailApplyTitle;

  /// No description provided for @sysMailApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Save mail settings'**
  String get sysMailApplyAction;

  /// No description provided for @sysMailApplyConsequence.
  ///
  /// In en, this message translates to:
  /// **'Alerts stop reaching you if the new server rejects them. Send a test message afterwards to confirm delivery.'**
  String get sysMailApplyConsequence;

  /// No description provided for @sysMailValidationFromRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the address alerts are sent from.'**
  String get sysMailValidationFromRequired;

  /// No description provided for @sysMailValidationFromInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get sysMailValidationFromInvalid;

  /// No description provided for @sysMailValidationServer.
  ///
  /// In en, this message translates to:
  /// **'Enter the outgoing mail server.'**
  String get sysMailValidationServer;

  /// No description provided for @sysMailValidationPort.
  ///
  /// In en, this message translates to:
  /// **'Port must be between 1 and {bound}.'**
  String sysMailValidationPort(int bound);

  /// No description provided for @sysMailValidationPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password for the username, or turn authentication off.'**
  String get sysMailValidationPassword;

  /// No description provided for @sysServiceConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Service settings'**
  String get sysServiceConfigTitle;

  /// No description provided for @sysServiceConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SSH, SMB, NFS, FTP, and SNMP configuration'**
  String get sysServiceConfigSubtitle;

  /// No description provided for @sysServiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'{service} settings'**
  String sysServiceEditTitle(String service);

  /// No description provided for @sysServiceNameSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get sysServiceNameSsh;

  /// No description provided for @sysServiceNameSmb.
  ///
  /// In en, this message translates to:
  /// **'SMB'**
  String get sysServiceNameSmb;

  /// No description provided for @sysServiceNameNfs.
  ///
  /// In en, this message translates to:
  /// **'NFS'**
  String get sysServiceNameNfs;

  /// No description provided for @sysServiceNameFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get sysServiceNameFtp;

  /// No description provided for @sysServiceNameSnmp.
  ///
  /// In en, this message translates to:
  /// **'SNMP'**
  String get sysServiceNameSnmp;

  /// No description provided for @sysServiceRestartNotice.
  ///
  /// In en, this message translates to:
  /// **'A running service applies these settings when it restarts.'**
  String get sysServiceRestartNotice;

  /// No description provided for @sysServiceSecretNotice.
  ///
  /// In en, this message translates to:
  /// **'Shared secrets are never read back from the server. Leave a secret field empty to keep the stored value.'**
  String get sysServiceSecretNotice;

  /// No description provided for @sysServiceApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change {service} settings?'**
  String sysServiceApplyTitle(String service);

  /// No description provided for @sysServiceApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get sysServiceApplyAction;

  /// No description provided for @sysServiceApplyConsequenceRunning.
  ///
  /// In en, this message translates to:
  /// **'{service} is running and restarts to apply the change, briefly interrupting clients.'**
  String sysServiceApplyConsequenceRunning(String service);

  /// No description provided for @sysServiceApplyConsequenceStopped.
  ///
  /// In en, this message translates to:
  /// **'{service} is stopped, so the change takes effect the next time it starts.'**
  String sysServiceApplyConsequenceStopped(String service);

  /// No description provided for @sysServiceUpdated.
  ///
  /// In en, this message translates to:
  /// **'{service} settings updated.'**
  String sysServiceUpdated(String service);

  /// No description provided for @sysServiceNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get sysServiceNoChanges;

  /// No description provided for @sysServiceValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String sysServiceValidationRequired(String field);

  /// No description provided for @sysServiceValidationRange.
  ///
  /// In en, this message translates to:
  /// **'{field} must be between {minimum} and {maximum}.'**
  String sysServiceValidationRange(String field, int minimum, int maximum);

  /// No description provided for @sysServiceValidationInvalid.
  ///
  /// In en, this message translates to:
  /// **'{field} is not a valid value.'**
  String sysServiceValidationInvalid(String field);

  /// No description provided for @sysServiceFieldTcpport.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get sysServiceFieldTcpport;

  /// No description provided for @sysServiceFieldPasswordauth.
  ///
  /// In en, this message translates to:
  /// **'Allow password sign-in'**
  String get sysServiceFieldPasswordauth;

  /// No description provided for @sysServiceFieldKerberosauth.
  ///
  /// In en, this message translates to:
  /// **'Allow Kerberos sign-in'**
  String get sysServiceFieldKerberosauth;

  /// No description provided for @sysServiceFieldTcpfwd.
  ///
  /// In en, this message translates to:
  /// **'Allow TCP port forwarding'**
  String get sysServiceFieldTcpfwd;

  /// No description provided for @sysServiceFieldCompression.
  ///
  /// In en, this message translates to:
  /// **'Compression'**
  String get sysServiceFieldCompression;

  /// No description provided for @sysServiceFieldNetbiosname.
  ///
  /// In en, this message translates to:
  /// **'NetBIOS name'**
  String get sysServiceFieldNetbiosname;

  /// No description provided for @sysServiceFieldWorkgroup.
  ///
  /// In en, this message translates to:
  /// **'Workgroup'**
  String get sysServiceFieldWorkgroup;

  /// No description provided for @sysServiceFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysServiceFieldDescription;

  /// No description provided for @sysServiceFieldEncryption.
  ///
  /// In en, this message translates to:
  /// **'Transport encryption'**
  String get sysServiceFieldEncryption;

  /// No description provided for @sysServiceFieldLocalmaster.
  ///
  /// In en, this message translates to:
  /// **'Local master browser'**
  String get sysServiceFieldLocalmaster;

  /// No description provided for @sysServiceFieldEnableSmb1.
  ///
  /// In en, this message translates to:
  /// **'Enable SMB1 (insecure)'**
  String get sysServiceFieldEnableSmb1;

  /// No description provided for @sysServiceFieldNtlmv1Auth.
  ///
  /// In en, this message translates to:
  /// **'Allow NTLMv1 (insecure)'**
  String get sysServiceFieldNtlmv1Auth;

  /// No description provided for @sysServiceFieldServers.
  ///
  /// In en, this message translates to:
  /// **'Server threads'**
  String get sysServiceFieldServers;

  /// No description provided for @sysServiceFieldAllowNonroot.
  ///
  /// In en, this message translates to:
  /// **'Allow non-root mounts'**
  String get sysServiceFieldAllowNonroot;

  /// No description provided for @sysServiceFieldV4Domain.
  ///
  /// In en, this message translates to:
  /// **'NFSv4 domain'**
  String get sysServiceFieldV4Domain;

  /// No description provided for @sysServiceFieldMountdPort.
  ///
  /// In en, this message translates to:
  /// **'mountd port'**
  String get sysServiceFieldMountdPort;

  /// No description provided for @sysServiceFieldRdma.
  ///
  /// In en, this message translates to:
  /// **'RDMA'**
  String get sysServiceFieldRdma;

  /// No description provided for @sysServiceFieldClients.
  ///
  /// In en, this message translates to:
  /// **'Maximum clients'**
  String get sysServiceFieldClients;

  /// No description provided for @sysServiceFieldLoginattempt.
  ///
  /// In en, this message translates to:
  /// **'Login attempts'**
  String get sysServiceFieldLoginattempt;

  /// No description provided for @sysServiceFieldTimeout.
  ///
  /// In en, this message translates to:
  /// **'Idle timeout (seconds)'**
  String get sysServiceFieldTimeout;

  /// No description provided for @sysServiceFieldTls.
  ///
  /// In en, this message translates to:
  /// **'Require TLS'**
  String get sysServiceFieldTls;

  /// No description provided for @sysServiceFieldOnlyanonymous.
  ///
  /// In en, this message translates to:
  /// **'Allow anonymous only'**
  String get sysServiceFieldOnlyanonymous;

  /// No description provided for @sysServiceFieldOnlylocal.
  ///
  /// In en, this message translates to:
  /// **'Allow local users only'**
  String get sysServiceFieldOnlylocal;

  /// No description provided for @sysServiceFieldDefaultroot.
  ///
  /// In en, this message translates to:
  /// **'Confine users to home'**
  String get sysServiceFieldDefaultroot;

  /// No description provided for @sysServiceFieldResume.
  ///
  /// In en, this message translates to:
  /// **'Allow resumed transfers'**
  String get sysServiceFieldResume;

  /// No description provided for @sysServiceFieldBanner.
  ///
  /// In en, this message translates to:
  /// **'Login banner'**
  String get sysServiceFieldBanner;

  /// No description provided for @sysServiceFieldCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community string'**
  String get sysServiceFieldCommunity;

  /// No description provided for @sysServiceFieldContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get sysServiceFieldContact;

  /// No description provided for @sysServiceFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sysServiceFieldLocation;

  /// No description provided for @sysServiceFieldLoglevel.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get sysServiceFieldLoglevel;

  /// No description provided for @sysServiceFieldTraps.
  ///
  /// In en, this message translates to:
  /// **'Send traps'**
  String get sysServiceFieldTraps;

  /// No description provided for @sysServiceFieldZilstat.
  ///
  /// In en, this message translates to:
  /// **'Report ZIL statistics'**
  String get sysServiceFieldZilstat;

  /// No description provided for @sysServiceFieldV3.
  ///
  /// In en, this message translates to:
  /// **'Enable SNMPv3'**
  String get sysServiceFieldV3;

  /// No description provided for @sysServiceFieldV3Username.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 username'**
  String get sysServiceFieldV3Username;

  /// No description provided for @sysServiceFieldV3Authtype.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 authentication'**
  String get sysServiceFieldV3Authtype;

  /// No description provided for @sysServiceFieldV3Password.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 password'**
  String get sysServiceFieldV3Password;

  /// No description provided for @sysServiceFieldV3Privproto.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 privacy protocol'**
  String get sysServiceFieldV3Privproto;

  /// No description provided for @sysServiceFieldV3Privpassphrase.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 privacy passphrase'**
  String get sysServiceFieldV3Privpassphrase;

  /// No description provided for @sysServiceChoiceDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get sysServiceChoiceDefault;

  /// No description provided for @sysServiceChoiceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysServiceChoiceNone;

  /// No description provided for @sysAlertClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert policies'**
  String get sysAlertClassesTitle;

  /// No description provided for @sysAlertClassesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which alerts are delivered, and how often'**
  String get sysAlertClassesSubtitle;

  /// No description provided for @sysAlertClassesOpen.
  ///
  /// In en, this message translates to:
  /// **'Review alert policies'**
  String get sysAlertClassesOpen;

  /// No description provided for @sysAlertClassesSummary.
  ///
  /// In en, this message translates to:
  /// **'{overridden} of {total} classes changed from their defaults'**
  String sysAlertClassesSummary(int overridden, int total);

  /// No description provided for @sysAlertClassesSilenced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No classes are silenced} =1{1 class is silenced} other{{count} classes are silenced}}'**
  String sysAlertClassesSilenced(int count);

  /// No description provided for @sysAlertClassLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get sysAlertClassLevel;

  /// No description provided for @sysAlertClassPolicy.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get sysAlertClassPolicy;

  /// No description provided for @sysAlertPolicyImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get sysAlertPolicyImmediately;

  /// No description provided for @sysAlertPolicyHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get sysAlertPolicyHourly;

  /// No description provided for @sysAlertPolicyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get sysAlertPolicyDaily;

  /// No description provided for @sysAlertPolicyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get sysAlertPolicyNever;

  /// No description provided for @sysAlertClassDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sysAlertClassDefault;

  /// No description provided for @sysAlertClassChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get sysAlertClassChanged;

  /// No description provided for @sysAlertClassSilencedBadge.
  ///
  /// In en, this message translates to:
  /// **'Silenced'**
  String get sysAlertClassSilencedBadge;

  /// No description provided for @sysAlertClassesApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change alert policies?'**
  String get sysAlertClassesApplyTitle;

  /// No description provided for @sysAlertClassesApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Save policies'**
  String get sysAlertClassesApplyAction;

  /// No description provided for @sysAlertClassesApplyConsequence.
  ///
  /// In en, this message translates to:
  /// **'Classes set to Never are not delivered to any destination, however severe they become.'**
  String get sysAlertClassesApplyConsequence;

  /// No description provided for @sysAlertClassesApplyReplace.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS replaces the whole override list, so every change shown here is saved together.'**
  String get sysAlertClassesApplyReplace;

  /// No description provided for @sysAlertClassesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alert policies updated.'**
  String get sysAlertClassesUpdated;

  /// No description provided for @sysAlertClassesNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get sysAlertClassesNoChanges;

  /// No description provided for @sysAlertClassesReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get sysAlertClassesReset;

  /// No description provided for @sysAlertServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert destinations'**
  String get sysAlertServicesTitle;

  /// No description provided for @sysAlertServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where TrueNAS sends alerts'**
  String get sysAlertServicesSubtitle;

  /// No description provided for @sysAlertServicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alert destinations. Alerts stay in the web interface and this app until one is added.'**
  String get sysAlertServicesEmpty;

  /// No description provided for @sysAlertServiceCreate.
  ///
  /// In en, this message translates to:
  /// **'Add destination'**
  String get sysAlertServiceCreate;

  /// No description provided for @sysAlertServiceCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New alert destination'**
  String get sysAlertServiceCreateTitle;

  /// No description provided for @sysAlertServiceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String sysAlertServiceEditTitle(String name);

  /// No description provided for @sysAlertServiceName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysAlertServiceName;

  /// No description provided for @sysAlertServiceKind.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get sysAlertServiceKind;

  /// No description provided for @sysAlertServiceLevel.
  ///
  /// In en, this message translates to:
  /// **'Minimum level'**
  String get sysAlertServiceLevel;

  /// No description provided for @sysAlertKindEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sysAlertKindEmail;

  /// No description provided for @sysAlertKindSnmpTrap.
  ///
  /// In en, this message translates to:
  /// **'SNMP trap'**
  String get sysAlertKindSnmpTrap;

  /// No description provided for @sysAlertLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get sysAlertLevelInfo;

  /// No description provided for @sysAlertLevelNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get sysAlertLevelNotice;

  /// No description provided for @sysAlertLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get sysAlertLevelWarning;

  /// No description provided for @sysAlertLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get sysAlertLevelError;

  /// No description provided for @sysAlertLevelCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get sysAlertLevelCritical;

  /// No description provided for @sysAlertLevelAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get sysAlertLevelAlert;

  /// No description provided for @sysAlertLevelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sysAlertLevelEmergency;

  /// No description provided for @sysAlertServiceEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sysAlertServiceEnabled;

  /// No description provided for @sysAlertServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sysAlertServiceDisabled;

  /// No description provided for @sysAlertServiceSecretNotice.
  ///
  /// In en, this message translates to:
  /// **'Credentials are never read back from the server. Leave one empty to keep the stored value.'**
  String get sysAlertServiceSecretNotice;

  /// No description provided for @sysAlertServiceUnknownKind.
  ///
  /// In en, this message translates to:
  /// **'This destination type is not supported by TrueDock. Edit it in the TrueNAS web interface.'**
  String get sysAlertServiceUnknownKind;

  /// No description provided for @sysAlertServiceTest.
  ///
  /// In en, this message translates to:
  /// **'Send test alert'**
  String get sysAlertServiceTest;

  /// No description provided for @sysAlertServiceTested.
  ///
  /// In en, this message translates to:
  /// **'Test alert sent through {name}.'**
  String sysAlertServiceTested(String name);

  /// No description provided for @sysAlertServiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Alert destination added.'**
  String get sysAlertServiceCreated;

  /// No description provided for @sysAlertServiceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Alert destination updated.'**
  String get sysAlertServiceUpdated;

  /// No description provided for @sysAlertServiceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert destination deleted.'**
  String get sysAlertServiceDeleted;

  /// No description provided for @sysAlertServiceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String sysAlertServiceDeleteTitle(String name);

  /// No description provided for @sysAlertServiceDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete destination'**
  String get sysAlertServiceDeleteAction;

  /// No description provided for @sysAlertServiceDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Alerts stop being delivered here. Any credential stored for it is removed.'**
  String get sysAlertServiceDeleteConsequence;

  /// No description provided for @sysAlertServiceValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this destination.'**
  String get sysAlertServiceValidationName;

  /// No description provided for @sysAlertServiceValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String sysAlertServiceValidationRequired(String field);

  /// No description provided for @sysAlertServiceValidationInteger.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a number.'**
  String sysAlertServiceValidationInteger(String field);

  /// No description provided for @sysAlertServiceValidationUrl.
  ///
  /// In en, this message translates to:
  /// **'{field} must be a full URL, including https://.'**
  String sysAlertServiceValidationUrl(String field);

  /// No description provided for @sysAlertFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get sysAlertFieldEmail;

  /// No description provided for @sysAlertFieldUrl.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL'**
  String get sysAlertFieldUrl;

  /// No description provided for @sysAlertFieldBotToken.
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get sysAlertFieldBotToken;

  /// No description provided for @sysAlertFieldChatIds.
  ///
  /// In en, this message translates to:
  /// **'Chat IDs'**
  String get sysAlertFieldChatIds;

  /// No description provided for @sysAlertFieldServiceKey.
  ///
  /// In en, this message translates to:
  /// **'Integration key'**
  String get sysAlertFieldServiceKey;

  /// No description provided for @sysAlertFieldClientName.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get sysAlertFieldClientName;

  /// No description provided for @sysAlertFieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get sysAlertFieldUsername;

  /// No description provided for @sysAlertFieldChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get sysAlertFieldChannel;

  /// No description provided for @sysAlertFieldIconUrl.
  ///
  /// In en, this message translates to:
  /// **'Icon URL'**
  String get sysAlertFieldIconUrl;

  /// No description provided for @sysAlertFieldApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get sysAlertFieldApiKey;

  /// No description provided for @sysAlertFieldApiUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get sysAlertFieldApiUrl;

  /// No description provided for @sysAlertFieldRoutingKey.
  ///
  /// In en, this message translates to:
  /// **'Routing key'**
  String get sysAlertFieldRoutingKey;

  /// No description provided for @sysAlertFieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get sysAlertFieldRegion;

  /// No description provided for @sysAlertFieldTopicArn.
  ///
  /// In en, this message translates to:
  /// **'Topic ARN'**
  String get sysAlertFieldTopicArn;

  /// No description provided for @sysAlertFieldAwsAccessKeyId.
  ///
  /// In en, this message translates to:
  /// **'Access key ID'**
  String get sysAlertFieldAwsAccessKeyId;

  /// No description provided for @sysAlertFieldAwsSecretAccessKey.
  ///
  /// In en, this message translates to:
  /// **'Secret access key'**
  String get sysAlertFieldAwsSecretAccessKey;

  /// No description provided for @sysAlertFieldHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get sysAlertFieldHost;

  /// No description provided for @sysAlertFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get sysAlertFieldPassword;

  /// No description provided for @sysAlertFieldDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get sysAlertFieldDatabase;

  /// No description provided for @sysAlertFieldSeriesName.
  ///
  /// In en, this message translates to:
  /// **'Series name'**
  String get sysAlertFieldSeriesName;

  /// No description provided for @sysAlertFieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get sysAlertFieldPort;

  /// No description provided for @sysAlertFieldCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community string'**
  String get sysAlertFieldCommunity;

  /// No description provided for @sysAlertFieldV3Username.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 username'**
  String get sysAlertFieldV3Username;

  /// No description provided for @sysAlertFieldV3Authkey.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 authentication key'**
  String get sysAlertFieldV3Authkey;

  /// No description provided for @sysAlertFieldV3Authprotocol.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 authentication protocol'**
  String get sysAlertFieldV3Authprotocol;

  /// No description provided for @sysAlertFieldV3Privkey.
  ///
  /// In en, this message translates to:
  /// **'SNMPv3 privacy key'**
  String get sysAlertFieldV3Privkey;

  /// No description provided for @sysSectionCron.
  ///
  /// In en, this message translates to:
  /// **'Scheduled commands'**
  String get sysSectionCron;

  /// No description provided for @sysCronTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled commands'**
  String get sysCronTitle;

  /// No description provided for @sysCronSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Commands TrueNAS runs on a schedule'**
  String get sysCronSubtitle;

  /// No description provided for @sysCronEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scheduled commands.'**
  String get sysCronEmpty;

  /// No description provided for @sysCronCreate.
  ///
  /// In en, this message translates to:
  /// **'Add scheduled command'**
  String get sysCronCreate;

  /// No description provided for @sysCronCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New scheduled command'**
  String get sysCronCreateTitle;

  /// No description provided for @sysCronEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit scheduled command'**
  String get sysCronEditTitle;

  /// No description provided for @sysCronCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get sysCronCommand;

  /// No description provided for @sysCronCommandHelper.
  ///
  /// In en, this message translates to:
  /// **'Runs through the shell as the account below.'**
  String get sysCronCommandHelper;

  /// No description provided for @sysCronUser.
  ///
  /// In en, this message translates to:
  /// **'Run as'**
  String get sysCronUser;

  /// No description provided for @sysCronDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysCronDescription;

  /// No description provided for @sysCronEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sysCronEnabled;

  /// No description provided for @sysCronCaptureStdout.
  ///
  /// In en, this message translates to:
  /// **'Keep standard output'**
  String get sysCronCaptureStdout;

  /// No description provided for @sysCronCaptureStderr.
  ///
  /// In en, this message translates to:
  /// **'Keep error output'**
  String get sysCronCaptureStderr;

  /// No description provided for @sysCronDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sysCronDisabled;

  /// No description provided for @sysCronRunNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get sysCronRunNow;

  /// No description provided for @sysCronRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Run this command now?'**
  String get sysCronRunTitle;

  /// No description provided for @sysCronRunAction.
  ///
  /// In en, this message translates to:
  /// **'Run command'**
  String get sysCronRunAction;

  /// No description provided for @sysCronRunConsequence.
  ///
  /// In en, this message translates to:
  /// **'The command runs immediately on {server} as {user}, with that account\'s privileges.'**
  String sysCronRunConsequence(String server, String user);

  /// No description provided for @sysCronRunRequested.
  ///
  /// In en, this message translates to:
  /// **'Running the command.'**
  String get sysCronRunRequested;

  /// No description provided for @sysCronDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this scheduled command?'**
  String get sysCronDeleteTitle;

  /// No description provided for @sysCronDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete command'**
  String get sysCronDeleteAction;

  /// No description provided for @sysCronDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'The schedule is removed. Anything the command already did is unaffected.'**
  String get sysCronDeleteConsequence;

  /// No description provided for @sysCronCreated.
  ///
  /// In en, this message translates to:
  /// **'Scheduled command added.'**
  String get sysCronCreated;

  /// No description provided for @sysCronUpdated.
  ///
  /// In en, this message translates to:
  /// **'Scheduled command updated.'**
  String get sysCronUpdated;

  /// No description provided for @sysCronDeleted.
  ///
  /// In en, this message translates to:
  /// **'Scheduled command deleted.'**
  String get sysCronDeleted;

  /// No description provided for @sysCronValidationCommand.
  ///
  /// In en, this message translates to:
  /// **'Enter a command to run.'**
  String get sysCronValidationCommand;

  /// No description provided for @sysCronValidationUser.
  ///
  /// In en, this message translates to:
  /// **'Choose an account to run as.'**
  String get sysCronValidationUser;

  /// No description provided for @sysSectionUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get sysSectionUpdates;

  /// No description provided for @sysAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get sysAuditTitle;

  /// No description provided for @sysAuditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who did what on this server'**
  String get sysAuditSubtitle;

  /// No description provided for @sysAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit records match this filter.'**
  String get sysAuditEmpty;

  /// No description provided for @sysAuditFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All events'**
  String get sysAuditFilterAll;

  /// No description provided for @sysAuditFilterFailures.
  ///
  /// In en, this message translates to:
  /// **'Failures only'**
  String get sysAuditFilterFailures;

  /// No description provided for @sysAuditFilterUser.
  ///
  /// In en, this message translates to:
  /// **'Filter by user'**
  String get sysAuditFilterUser;

  /// No description provided for @sysAuditEventAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sysAuditEventAuthentication;

  /// No description provided for @sysAuditEventLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get sysAuditEventLogout;

  /// No description provided for @sysAuditEventMethodCall.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get sysAuditEventMethodCall;

  /// No description provided for @sysAuditDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get sysAuditDenied;

  /// No description provided for @sysAuditFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sysAuditFailed;

  /// No description provided for @sysAuditFrom.
  ///
  /// In en, this message translates to:
  /// **'from {address}'**
  String sysAuditFrom(String address);

  /// No description provided for @sysAuditRetention.
  ///
  /// In en, this message translates to:
  /// **'Kept for {days, plural, =1{1 day} other{{days} days}}'**
  String sysAuditRetention(int days);

  /// No description provided for @sysAuditSpace.
  ///
  /// In en, this message translates to:
  /// **'Using {used} of {available}'**
  String sysAuditSpace(String used, String available);

  /// No description provided for @sysAuditQuotaUncapped.
  ///
  /// In en, this message translates to:
  /// **'No quota set'**
  String get sysAuditQuotaUncapped;

  /// No description provided for @sysAuditRetentionEdit.
  ///
  /// In en, this message translates to:
  /// **'Retention and quota'**
  String get sysAuditRetentionEdit;

  /// No description provided for @sysAuditRetentionDays.
  ///
  /// In en, this message translates to:
  /// **'Retention (days)'**
  String get sysAuditRetentionDays;

  /// No description provided for @sysAuditRetentionHelp.
  ///
  /// In en, this message translates to:
  /// **'Records older than this are discarded. Between 1 and 30 days.'**
  String get sysAuditRetentionHelp;

  /// No description provided for @sysAuditQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota (GiB)'**
  String get sysAuditQuota;

  /// No description provided for @sysAuditQuotaHelp.
  ///
  /// In en, this message translates to:
  /// **'Maximum space the audit databases may use. 0 means uncapped.'**
  String get sysAuditQuotaHelp;

  /// No description provided for @sysAuditWarnAt.
  ///
  /// In en, this message translates to:
  /// **'Warn at (%)'**
  String get sysAuditWarnAt;

  /// No description provided for @sysAuditCriticalAt.
  ///
  /// In en, this message translates to:
  /// **'Critical at (%)'**
  String get sysAuditCriticalAt;

  /// No description provided for @sysAuditApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change audit retention?'**
  String get sysAuditApplyTitle;

  /// No description provided for @sysAuditApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Save retention'**
  String get sysAuditApplyAction;

  /// No description provided for @sysAuditApplyConsequence.
  ///
  /// In en, this message translates to:
  /// **'Shortening retention discards audit history the server has already recorded. There is no undo.'**
  String get sysAuditApplyConsequence;

  /// No description provided for @sysAuditUpdated.
  ///
  /// In en, this message translates to:
  /// **'Audit retention updated.'**
  String get sysAuditUpdated;

  /// No description provided for @sysAuditNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get sysAuditNoChanges;

  /// No description provided for @sysAuditValidationRetention.
  ///
  /// In en, this message translates to:
  /// **'Retention must be between {minimum} and {maximum} days.'**
  String sysAuditValidationRetention(int minimum, int maximum);

  /// No description provided for @sysAuditValidationQuota.
  ///
  /// In en, this message translates to:
  /// **'Value must be between {minimum} and {maximum}.'**
  String sysAuditValidationQuota(int minimum, int maximum);

  /// No description provided for @sysAuditValidationFillOrder.
  ///
  /// In en, this message translates to:
  /// **'The critical threshold must be above the warning threshold.'**
  String get sysAuditValidationFillOrder;

  /// No description provided for @sysConfigBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration backup'**
  String get sysConfigBackupTitle;

  /// No description provided for @sysConfigBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download the settings database, or reset to defaults'**
  String get sysConfigBackupSubtitle;

  /// No description provided for @sysConfigBackupPrepare.
  ///
  /// In en, this message translates to:
  /// **'Prepare backup'**
  String get sysConfigBackupPrepare;

  /// No description provided for @sysConfigBackupSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Configuration backup'**
  String get sysConfigBackupSheetTitle;

  /// No description provided for @sysConfigBackupExplain.
  ///
  /// In en, this message translates to:
  /// **'The archive contains the settings database: shares, users, tasks, and network configuration. Pool data is not included.'**
  String get sysConfigBackupExplain;

  /// No description provided for @sysConfigBackupSecretSeed.
  ///
  /// In en, this message translates to:
  /// **'Include the secret seed'**
  String get sysConfigBackupSecretSeed;

  /// No description provided for @sysConfigBackupSecretSeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Needed to decrypt saved passwords and API keys after a restore. Anyone with this archive can read them.'**
  String get sysConfigBackupSecretSeedHelp;

  /// No description provided for @sysConfigBackupPoolKeys.
  ///
  /// In en, this message translates to:
  /// **'Include pool encryption keys'**
  String get sysConfigBackupPoolKeys;

  /// No description provided for @sysConfigBackupPoolKeysHelp.
  ///
  /// In en, this message translates to:
  /// **'Unlocks encrypted datasets. An archive with these keys is equivalent to the data itself.'**
  String get sysConfigBackupPoolKeysHelp;

  /// No description provided for @sysConfigBackupRootKeys.
  ///
  /// In en, this message translates to:
  /// **'Include root SSH keys'**
  String get sysConfigBackupRootKeys;

  /// No description provided for @sysConfigBackupSecretsWarning.
  ///
  /// In en, this message translates to:
  /// **'This archive will contain secrets. Store it where you would store the server password itself.'**
  String get sysConfigBackupSecretsWarning;

  /// No description provided for @sysConfigBackupReady.
  ///
  /// In en, this message translates to:
  /// **'Backup ready'**
  String get sysConfigBackupReady;

  /// No description provided for @sysConfigBackupReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Open this one-time link in a browser to download {filename}. The link expires shortly and works only for this download.'**
  String sysConfigBackupReadyBody(String filename);

  /// No description provided for @sysConfigBackupCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy download link'**
  String get sysConfigBackupCopyLink;

  /// No description provided for @sysConfigBackupDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get sysConfigBackupDownload;

  /// No description provided for @sysConfigBackupOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the download in your browser.'**
  String get sysConfigBackupOpenFailed;

  /// No description provided for @sysConfigBackupLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Download link copied.'**
  String get sysConfigBackupLinkCopied;

  /// No description provided for @sysConfigResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset configuration'**
  String get sysConfigResetTitle;

  /// No description provided for @sysConfigResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return every setting to its factory default'**
  String get sysConfigResetSubtitle;

  /// No description provided for @sysConfigResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset configuration'**
  String get sysConfigResetAction;

  /// No description provided for @sysConfigResetConsequenceTotal.
  ///
  /// In en, this message translates to:
  /// **'Every share, user, task, and network setting reverts to its default. Pool data is untouched, but nothing will be shared or scheduled until you configure it again.'**
  String get sysConfigResetConsequenceTotal;

  /// No description provided for @sysConfigResetConsequenceIrreversible.
  ///
  /// In en, this message translates to:
  /// **'There is no undo. Download a configuration backup first if you have not already.'**
  String get sysConfigResetConsequenceIrreversible;

  /// No description provided for @sysConfigResetConsequenceReboot.
  ///
  /// In en, this message translates to:
  /// **'The server reboots immediately and TrueDock loses this connection.'**
  String get sysConfigResetConsequenceReboot;

  /// No description provided for @sysConfigResetConsequenceNoReboot.
  ///
  /// In en, this message translates to:
  /// **'The reset applies now; restart the server yourself to complete it.'**
  String get sysConfigResetConsequenceNoReboot;

  /// No description provided for @sysConfigResetReboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot after resetting'**
  String get sysConfigResetReboot;

  /// No description provided for @sysConfigResetRequested.
  ///
  /// In en, this message translates to:
  /// **'Configuration reset requested.'**
  String get sysConfigResetRequested;

  /// No description provided for @sysSectionActivity.
  ///
  /// In en, this message translates to:
  /// **'Alerts and jobs'**
  String get sysSectionActivity;

  /// No description provided for @sysConnectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Connect a server to view this section.'**
  String get sysConnectPrompt;

  /// No description provided for @sysHeadingWithCount.
  ///
  /// In en, this message translates to:
  /// **'{title}  {count}'**
  String sysHeadingWithCount(String title, int count);

  /// No description provided for @sysMetricUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get sysMetricUsers;

  /// No description provided for @sysMetricGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get sysMetricGroups;

  /// No description provided for @sysMetricAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get sysMetricAdmins;

  /// No description provided for @sysUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get sysUsers;

  /// No description provided for @sysNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get sysNewUser;

  /// No description provided for @sysNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get sysNoUsers;

  /// No description provided for @sysGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get sysGroups;

  /// No description provided for @sysNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get sysNewGroup;

  /// No description provided for @sysNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups found.'**
  String get sysNoGroups;

  /// No description provided for @sysApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get sysApiKeys;

  /// No description provided for @sysRevokeApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}?'**
  String sysRevokeApiKeyTitle(String name);

  /// No description provided for @sysRevokeApiKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke API key'**
  String get sysRevokeApiKeyAction;

  /// No description provided for @sysRevokeApiKeyConsequence.
  ///
  /// In en, this message translates to:
  /// **'Every client still using this key stops being able to sign in immediately, including TrueDock if this is the key it uses.'**
  String get sysRevokeApiKeyConsequence;

  /// No description provided for @sysRevokeApiKeyUnowned.
  ///
  /// In en, this message translates to:
  /// **'The key cannot be recovered. A replacement has to be created on the server, which shows the new secret only once.'**
  String get sysRevokeApiKeyUnowned;

  /// No description provided for @sysRevokeApiKeyOwned.
  ///
  /// In en, this message translates to:
  /// **'The account {owner} keeps its password and other keys. This key cannot be recovered; a replacement shows its secret only once.'**
  String sysRevokeApiKeyOwned(String owner);

  /// No description provided for @sysRevokeApiKeyActionLabel.
  ///
  /// In en, this message translates to:
  /// **'revoke {name}'**
  String sysRevokeApiKeyActionLabel(String name);

  /// No description provided for @sysRevokedApiKey.
  ///
  /// In en, this message translates to:
  /// **'Revoked {name}.'**
  String sysRevokedApiKey(String name);

  /// No description provided for @sysUpdateActionLabel.
  ///
  /// In en, this message translates to:
  /// **'update {name}'**
  String sysUpdateActionLabel(String name);

  /// No description provided for @sysUpdatedEntity.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}.'**
  String sysUpdatedEntity(String name);

  /// No description provided for @sysCreateActionLabel.
  ///
  /// In en, this message translates to:
  /// **'create {name}'**
  String sysCreateActionLabel(String name);

  /// No description provided for @sysCreatedEntity.
  ///
  /// In en, this message translates to:
  /// **'Created {name}.'**
  String sysCreatedEntity(String name);

  /// No description provided for @sysDeleteActionLabel.
  ///
  /// In en, this message translates to:
  /// **'delete {name}'**
  String sysDeleteActionLabel(String name);

  /// No description provided for @sysDeletedEntity.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}.'**
  String sysDeletedEntity(String name);

  /// No description provided for @sysOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not {action}.'**
  String sysOperationFailed(String action);

  /// No description provided for @sysGenericOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The TrueNAS operation failed.'**
  String get sysGenericOperationFailed;

  /// No description provided for @sysChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password for {username}?'**
  String sysChangePasswordTitle(String username);

  /// No description provided for @sysChangePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get sysChangePasswordAction;

  /// No description provided for @sysChangePasswordImmediate.
  ///
  /// In en, this message translates to:
  /// **'The new password takes effect immediately. Anyone signed in as this account must use the new password afterwards.'**
  String get sysChangePasswordImmediate;

  /// No description provided for @sysChangePasswordSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions for this account may be ended by TrueNAS.'**
  String get sysChangePasswordSessions;

  /// No description provided for @sysChangePasswordPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The password is sent only to the connected server and is not stored, logged, or autofilled by TrueDock.'**
  String get sysChangePasswordPrivacy;

  /// No description provided for @sysChangePasswordActionLabel.
  ///
  /// In en, this message translates to:
  /// **'change the password for {username}'**
  String sysChangePasswordActionLabel(String username);

  /// No description provided for @sysPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed for {username}.'**
  String sysPasswordChanged(String username);

  /// No description provided for @sysDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user?'**
  String get sysDeleteUserTitle;

  /// No description provided for @sysDeleteUserAction.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get sysDeleteUserAction;

  /// No description provided for @sysDeleteUserConsequenceAccount.
  ///
  /// In en, this message translates to:
  /// **'The account is removed and can no longer sign in anywhere.'**
  String get sysDeleteUserConsequenceAccount;

  /// No description provided for @sysDeleteUserConsequenceGroups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The user is removed from 1 group.} other{The user is removed from {count} groups.}}'**
  String sysDeleteUserConsequenceGroups(int count);

  /// No description provided for @sysDeleteUserConsequencePrimaryGroup.
  ///
  /// In en, this message translates to:
  /// **'Their primary group {group} is deleted with them because it has no other members.'**
  String sysDeleteUserConsequencePrimaryGroup(String group);

  /// No description provided for @sysDeleteUserConsequenceFiles.
  ///
  /// In en, this message translates to:
  /// **'Files owned by this user keep its numeric UID and may become inaccessible.'**
  String get sysDeleteUserConsequenceFiles;

  /// No description provided for @sysDeleteUserNote.
  ///
  /// In en, this message translates to:
  /// **'Home directory contents are not removed by this action.'**
  String get sysDeleteUserNote;

  /// No description provided for @sysDeleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete group?'**
  String get sysDeleteGroupTitle;

  /// No description provided for @sysDeleteGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get sysDeleteGroupAction;

  /// No description provided for @sysDeleteGroupConsequenceMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The group is removed and its 1 member loses the access it granted.} other{The group is removed and its {count} members lose the access it granted.}}'**
  String sysDeleteGroupConsequenceMembers(int count);

  /// No description provided for @sysDeleteGroupConsequencePermissions.
  ///
  /// In en, this message translates to:
  /// **'Share and dataset permissions referencing this group stop matching anyone.'**
  String get sysDeleteGroupConsequencePermissions;

  /// No description provided for @sysDeleteGroupConsequencePrimary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{It is the primary group for 1 user, so TrueNAS may refuse to delete it.} other{It is the primary group for {count} users, so TrueNAS may refuse to delete it.}}'**
  String sysDeleteGroupConsequencePrimary(int count);

  /// No description provided for @sysDeleteGroupNote.
  ///
  /// In en, this message translates to:
  /// **'Member accounts themselves are not deleted.'**
  String get sysDeleteGroupNote;

  /// No description provided for @sysInstallUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Install {version}?'**
  String sysInstallUpdateTitle(String version);

  /// No description provided for @sysInstallUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Install and restart'**
  String get sysInstallUpdateAction;

  /// No description provided for @sysInstallUpdateConsequenceRestart.
  ///
  /// In en, this message translates to:
  /// **'The server downloads the update and restarts into it.'**
  String get sysInstallUpdateConsequenceRestart;

  /// No description provided for @sysInstallUpdateConsequenceServices.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shares, VMs, and 1 running app are unavailable until the restart finishes.} other{Shares, VMs, and {count} running apps are unavailable until the restart finishes.}}'**
  String sysInstallUpdateConsequenceServices(int count);

  /// No description provided for @sysInstallUpdateConsequenceJobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job is still running and will be cut off.} other{{count} jobs are still running and will be cut off.}}'**
  String sysInstallUpdateConsequenceJobs(int count);

  /// No description provided for @sysInstallUpdateConsequenceConnection.
  ///
  /// In en, this message translates to:
  /// **'TrueDock loses its connection while the server reboots.'**
  String get sysInstallUpdateConsequenceConnection;

  /// No description provided for @sysInstallUpdateNote.
  ///
  /// In en, this message translates to:
  /// **'Rolling back a TrueNAS update requires console access.'**
  String get sysInstallUpdateNote;

  /// No description provided for @sysInstallUpdateActionLabel.
  ///
  /// In en, this message translates to:
  /// **'install {version}'**
  String sysInstallUpdateActionLabel(String version);

  /// No description provided for @sysUpdateStarted.
  ///
  /// In en, this message translates to:
  /// **'Update started. The server will restart when it is staged.'**
  String get sysUpdateStarted;

  /// No description provided for @sysRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart server?'**
  String get sysRestartTitle;

  /// No description provided for @sysRestartAction.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get sysRestartAction;

  /// No description provided for @sysRestartVerb.
  ///
  /// In en, this message translates to:
  /// **'restart'**
  String get sysRestartVerb;

  /// No description provided for @sysRestartExtra.
  ///
  /// In en, this message translates to:
  /// **'The server comes back on its own once it finishes booting.'**
  String get sysRestartExtra;

  /// No description provided for @sysRestartSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restart requested. TrueDock will lose its connection.'**
  String get sysRestartSuccess;

  /// No description provided for @sysShutdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Shut down server?'**
  String get sysShutdownTitle;

  /// No description provided for @sysShutdownAction.
  ///
  /// In en, this message translates to:
  /// **'Shut down now'**
  String get sysShutdownAction;

  /// No description provided for @sysShutdownVerb.
  ///
  /// In en, this message translates to:
  /// **'shut down'**
  String get sysShutdownVerb;

  /// No description provided for @sysShutdownExtra.
  ///
  /// In en, this message translates to:
  /// **'The server stays off until someone powers it on physically or through out-of-band management.'**
  String get sysShutdownExtra;

  /// No description provided for @sysShutdownSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shutdown requested. TrueDock will lose its connection.'**
  String get sysShutdownSuccess;

  /// No description provided for @sysPowerConsequenceClients.
  ///
  /// In en, this message translates to:
  /// **'Every SMB, NFS, and iSCSI client loses access immediately.'**
  String get sysPowerConsequenceClients;

  /// No description provided for @sysPowerConsequenceWorkloads.
  ///
  /// In en, this message translates to:
  /// **'{apps} running app(s) and {vms} running VM(s) are stopped.'**
  String sysPowerConsequenceWorkloads(int apps, int vms);

  /// No description provided for @sysPowerConsequenceJobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job is still running. Replication and scrubs will need to run again.} other{{count} jobs are still running. Replication and scrubs will need to run again.}}'**
  String sysPowerConsequenceJobs(int count);

  /// No description provided for @sysPowerNote.
  ///
  /// In en, this message translates to:
  /// **'TrueDock cannot confirm the result because the connection drops.'**
  String get sysPowerNote;

  /// No description provided for @sysPowerActionLabel.
  ///
  /// In en, this message translates to:
  /// **'{verb} {server}'**
  String sysPowerActionLabel(String verb, String server);

  /// No description provided for @sysPowerReason.
  ///
  /// In en, this message translates to:
  /// **'Requested from TrueDock'**
  String get sysPowerReason;

  /// No description provided for @sysBootIntoTitle.
  ///
  /// In en, this message translates to:
  /// **'Boot into {environment}?'**
  String sysBootIntoTitle(String environment);

  /// No description provided for @sysBootIntoAction.
  ///
  /// In en, this message translates to:
  /// **'Use at next boot'**
  String get sysBootIntoAction;

  /// No description provided for @sysBootIntoConsequenceRestart.
  ///
  /// In en, this message translates to:
  /// **'{server} will start {environment} the next time it restarts. Nothing changes until then, and TrueDock does not restart the server for you.'**
  String sysBootIntoConsequenceRestart(String server, String environment);

  /// No description provided for @sysBootIntoConsequenceUnknownCurrent.
  ///
  /// In en, this message translates to:
  /// **'The system software, and any update applied to it, changes once the server restarts.'**
  String get sysBootIntoConsequenceUnknownCurrent;

  /// No description provided for @sysBootIntoConsequenceCurrent.
  ///
  /// In en, this message translates to:
  /// **'The server currently runs {current}. Its system software, including any update applied to it, is replaced after the restart.'**
  String sysBootIntoConsequenceCurrent(String current);

  /// No description provided for @sysBootEnvironmentDataNote.
  ///
  /// In en, this message translates to:
  /// **'Pools, datasets, and share data are not part of a boot environment and are left alone.'**
  String get sysBootEnvironmentDataNote;

  /// No description provided for @sysBootEnvironmentActivated.
  ///
  /// In en, this message translates to:
  /// **'{environment} will be used at the next restart.'**
  String sysBootEnvironmentActivated(String environment);

  /// No description provided for @sysBootEnvironmentKept.
  ///
  /// In en, this message translates to:
  /// **'{environment} is kept and will not be pruned automatically.'**
  String sysBootEnvironmentKept(String environment);

  /// No description provided for @sysBootEnvironmentUnkept.
  ///
  /// In en, this message translates to:
  /// **'{environment} can now be removed automatically.'**
  String sysBootEnvironmentUnkept(String environment);

  /// No description provided for @sysDeleteBootEnvironmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {environment}?'**
  String sysDeleteBootEnvironmentTitle(String environment);

  /// No description provided for @sysDeleteBootEnvironmentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete environment'**
  String get sysDeleteBootEnvironmentAction;

  /// No description provided for @sysDeleteBootEnvironmentConsequence.
  ///
  /// In en, this message translates to:
  /// **'{environment} is destroyed permanently. It cannot be recovered and can no longer be used to roll the system back.'**
  String sysDeleteBootEnvironmentConsequence(String environment);

  /// No description provided for @sysBootEnvironmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'{environment} was deleted.'**
  String sysBootEnvironmentDeleted(String environment);

  /// No description provided for @sysMetricInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Interfaces'**
  String get sysMetricInterfaces;

  /// No description provided for @sysMetricLinkUp.
  ///
  /// In en, this message translates to:
  /// **'Link up'**
  String get sysMetricLinkUp;

  /// No description provided for @sysMetricRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get sysMetricRoutes;

  /// No description provided for @sysInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Interfaces'**
  String get sysInterfaces;

  /// No description provided for @sysNoInterfaces.
  ///
  /// In en, this message translates to:
  /// **'No network interfaces found.'**
  String get sysNoInterfaces;

  /// No description provided for @sysStaticRoutes.
  ///
  /// In en, this message translates to:
  /// **'Static routes'**
  String get sysStaticRoutes;

  /// No description provided for @sysNewRoute.
  ///
  /// In en, this message translates to:
  /// **'New route'**
  String get sysNewRoute;

  /// No description provided for @sysNoStaticRoutes.
  ///
  /// In en, this message translates to:
  /// **'No static routes configured.'**
  String get sysNoStaticRoutes;

  /// No description provided for @sysRouteVia.
  ///
  /// In en, this message translates to:
  /// **'via {gateway}'**
  String sysRouteVia(String gateway);

  /// No description provided for @sysRouteViaWithDescription.
  ///
  /// In en, this message translates to:
  /// **'via {gateway} · {description}'**
  String sysRouteViaWithDescription(String gateway, String description);

  /// No description provided for @sysEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sysEdit;

  /// No description provided for @sysDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sysDelete;

  /// No description provided for @sysNetGlobalTitle.
  ///
  /// In en, this message translates to:
  /// **'DNS and gateway'**
  String get sysNetGlobalTitle;

  /// No description provided for @sysNetGlobalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hostname, domain, default gateway, nameservers'**
  String get sysNetGlobalSubtitle;

  /// No description provided for @sysNetGlobalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit DNS and gateway'**
  String get sysNetGlobalEdit;

  /// No description provided for @sysNetConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get sysNetConfigured;

  /// No description provided for @sysNetInEffect.
  ///
  /// In en, this message translates to:
  /// **'In effect'**
  String get sysNetInEffect;

  /// No description provided for @sysNetFromDhcp.
  ///
  /// In en, this message translates to:
  /// **'These values come from DHCP. Entering one here overrides the lease.'**
  String get sysNetFromDhcp;

  /// No description provided for @sysNetNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sysNetNotSet;

  /// No description provided for @sysNetHostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get sysNetHostname;

  /// No description provided for @sysNetDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get sysNetDomain;

  /// No description provided for @sysNetGateway.
  ///
  /// In en, this message translates to:
  /// **'IPv4 default gateway'**
  String get sysNetGateway;

  /// No description provided for @sysNetNameserver.
  ///
  /// In en, this message translates to:
  /// **'Nameserver {index}'**
  String sysNetNameserver(int index);

  /// No description provided for @sysNetHttpProxy.
  ///
  /// In en, this message translates to:
  /// **'HTTP proxy'**
  String get sysNetHttpProxy;

  /// No description provided for @sysNetDefaultRoutes.
  ///
  /// In en, this message translates to:
  /// **'Default routes'**
  String get sysNetDefaultRoutes;

  /// No description provided for @sysNetAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get sysNetAddresses;

  /// No description provided for @sysNetClearHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave a field empty to clear it and fall back to DHCP.'**
  String get sysNetClearHelp;

  /// No description provided for @sysNetGlobalApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Change DNS and gateway?'**
  String get sysNetGlobalApplyTitle;

  /// No description provided for @sysNetGlobalApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply network settings'**
  String get sysNetGlobalApplyAction;

  /// No description provided for @sysNetGlobalConsequenceImmediate.
  ///
  /// In en, this message translates to:
  /// **'The change applies immediately, without the commit and check-in window that interface edits use.'**
  String get sysNetGlobalConsequenceImmediate;

  /// No description provided for @sysNetGlobalConsequenceSever.
  ///
  /// In en, this message translates to:
  /// **'This clears a gateway or nameserver the server is currently using. If TrueDock reaches {server} through it, this connection will drop and you may need local access to recover.'**
  String sysNetGlobalConsequenceSever(String server);

  /// No description provided for @sysNetGlobalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Network settings updated.'**
  String get sysNetGlobalUpdated;

  /// No description provided for @sysNetGlobalNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed, so nothing was sent.'**
  String get sysNetGlobalNoChanges;

  /// No description provided for @sysNetValidationHostnameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a hostname.'**
  String get sysNetValidationHostnameRequired;

  /// No description provided for @sysNetValidationHostnameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use letters, digits, and hyphens only.'**
  String get sysNetValidationHostnameInvalid;

  /// No description provided for @sysNetValidationDomain.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid domain name.'**
  String get sysNetValidationDomain;

  /// No description provided for @sysNetValidationGateway.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IPv4 address, or leave empty to clear it.'**
  String get sysNetValidationGateway;

  /// No description provided for @sysNetValidationNameserver.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address, or leave empty to clear it.'**
  String get sysNetValidationNameserver;

  /// No description provided for @sysNetValidationProxy.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid proxy URL.'**
  String get sysNetValidationProxy;

  /// No description provided for @sysApplyNetworkChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply pending network changes'**
  String get sysApplyNetworkChanges;

  /// No description provided for @sysApplyNetworkChangesHelp.
  ///
  /// In en, this message translates to:
  /// **'Commit and check in staged interface and static-route changes.'**
  String get sysApplyNetworkChangesHelp;

  /// No description provided for @sysStageRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage route to {destination}?'**
  String sysStageRouteTitle(String destination);

  /// No description provided for @sysStageRouteAction.
  ///
  /// In en, this message translates to:
  /// **'Stage route'**
  String get sysStageRouteAction;

  /// No description provided for @sysRouteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Routes {destination} via {gateway}.'**
  String sysRouteConsequence(String destination, String gateway);

  /// No description provided for @sysRouteStagedConsequence.
  ///
  /// In en, this message translates to:
  /// **'The route is only staged. It takes effect after the pending network changes are committed and checked in.'**
  String get sysRouteStagedConsequence;

  /// No description provided for @sysRouteStagedNote.
  ///
  /// In en, this message translates to:
  /// **'TrueDock asks you to commit and check in afterwards.'**
  String get sysRouteStagedNote;

  /// No description provided for @sysStageRouteActionLabel.
  ///
  /// In en, this message translates to:
  /// **'stage the route to {destination}'**
  String sysStageRouteActionLabel(String destination);

  /// No description provided for @sysRouteStagedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Staged route to {destination}. Apply the pending network changes to take it live.'**
  String sysRouteStagedSuccess(String destination);

  /// No description provided for @sysUpdateRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Update route to {destination}?'**
  String sysUpdateRouteTitle(String destination);

  /// No description provided for @sysStageUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Stage update'**
  String get sysStageUpdateAction;

  /// No description provided for @sysRouteChangeStagedConsequence.
  ///
  /// In en, this message translates to:
  /// **'The change is only staged. It takes effect after the pending network changes are committed and checked in.'**
  String get sysRouteChangeStagedConsequence;

  /// No description provided for @sysUpdateRouteActionLabel.
  ///
  /// In en, this message translates to:
  /// **'update the route to {destination}'**
  String sysUpdateRouteActionLabel(String destination);

  /// No description provided for @sysRouteUpdateStagedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Staged update for {destination}. Apply the pending network changes to take it live.'**
  String sysRouteUpdateStagedSuccess(String destination);

  /// No description provided for @sysDeleteRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete route to {destination}?'**
  String sysDeleteRouteTitle(String destination);

  /// No description provided for @sysStageDeletionAction.
  ///
  /// In en, this message translates to:
  /// **'Stage deletion'**
  String get sysStageDeletionAction;

  /// No description provided for @sysRouteRemoveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Removes the route to {destination} via {gateway}.'**
  String sysRouteRemoveConsequence(String destination, String gateway);

  /// No description provided for @sysRouteDeletionStagedConsequence.
  ///
  /// In en, this message translates to:
  /// **'The deletion is only staged. The route stays in the table until the pending network changes are committed and checked in.'**
  String get sysRouteDeletionStagedConsequence;

  /// No description provided for @sysDeleteRouteActionLabel.
  ///
  /// In en, this message translates to:
  /// **'stage the deletion of the route to {destination}'**
  String sysDeleteRouteActionLabel(String destination);

  /// No description provided for @sysRouteDeletionStagedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Staged deletion of {destination}. Apply the pending network changes to take it live.'**
  String sysRouteDeletionStagedSuccess(String destination);

  /// No description provided for @sysInterfaceConfigLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the interface configuration.'**
  String get sysInterfaceConfigLoadFailed;

  /// No description provided for @sysInterfaceNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to stage for {name}.'**
  String sysInterfaceNoChanges(String name);

  /// No description provided for @sysStageInterfaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Stage changes to {name}?'**
  String sysStageInterfaceTitle(String name);

  /// No description provided for @sysStageChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Stage change'**
  String get sysStageChangeAction;

  /// No description provided for @sysInterfaceDhcpConsequence.
  ///
  /// In en, this message translates to:
  /// **'{name} switches to DHCP for IPv4.'**
  String sysInterfaceDhcpConsequence(String name);

  /// No description provided for @sysInterfaceStaticConsequence.
  ///
  /// In en, this message translates to:
  /// **'{name} uses {count} static address(es): {addresses}.'**
  String sysInterfaceStaticConsequence(
    String name,
    int count,
    String addresses,
  );

  /// No description provided for @sysInterfaceLosesStatic.
  ///
  /// In en, this message translates to:
  /// **'The existing static addresses are removed. Anything pointing at them loses its route.'**
  String get sysInterfaceLosesStatic;

  /// No description provided for @sysInterfaceStagedConsequence.
  ///
  /// In en, this message translates to:
  /// **'The change is only staged. Committing it can drop the TrueDock connection, and the server rolls it back unless the check-in arrives in time.'**
  String get sysInterfaceStagedConsequence;

  /// No description provided for @sysInterfaceStagedNote.
  ///
  /// In en, this message translates to:
  /// **'TrueDock offers the commit and check-in steps next.'**
  String get sysInterfaceStagedNote;

  /// No description provided for @sysStageInterfaceActionLabel.
  ///
  /// In en, this message translates to:
  /// **'stage changes to {name}'**
  String sysStageInterfaceActionLabel(String name);

  /// No description provided for @sysUpdateFallbackName.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS SCALE'**
  String get sysUpdateFallbackName;

  /// No description provided for @sysUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'{version} is available'**
  String sysUpdateAvailable(String version);

  /// No description provided for @sysUpdateStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'System update status'**
  String get sysUpdateStatusHeading;

  /// No description provided for @sysUpdateStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Update status is unavailable.'**
  String get sysUpdateStatusUnavailable;

  /// No description provided for @sysPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get sysPower;

  /// No description provided for @sysBootEnvironments.
  ///
  /// In en, this message translates to:
  /// **'Boot environments'**
  String get sysBootEnvironments;

  /// No description provided for @sysUpdateTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get sysUpdateTrain;

  /// No description provided for @sysUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get sysUpdateProfile;

  /// No description provided for @sysUpdateAvailableVersion.
  ///
  /// In en, this message translates to:
  /// **'Available version'**
  String get sysUpdateAvailableVersion;

  /// No description provided for @sysUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get sysUnknown;

  /// No description provided for @sysUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get sysUpToDate;

  /// No description provided for @sysUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get sysUpdateError;

  /// No description provided for @sysUpdateProfilesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load update channels.'**
  String get sysUpdateProfilesLoadFailed;

  /// No description provided for @sysInstallVersion.
  ///
  /// In en, this message translates to:
  /// **'Install {version}'**
  String sysInstallVersion(String version);

  /// No description provided for @sysUpdatesNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'Updates are not permitted for this account'**
  String get sysUpdatesNotPermitted;

  /// No description provided for @sysUpdateInProgress.
  ///
  /// In en, this message translates to:
  /// **'Update in progress'**
  String get sysUpdateInProgress;

  /// No description provided for @sysUpdatePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing the system update…'**
  String get sysUpdatePreparing;

  /// No description provided for @sysManualUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom firmware'**
  String get sysManualUpdateTitle;

  /// No description provided for @sysManualUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload an official TrueNAS .tar or .update file and install it directly.'**
  String get sysManualUpdateDescription;

  /// No description provided for @sysManualUpdateChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose update file'**
  String get sysManualUpdateChooseFile;

  /// No description provided for @sysManualUpdateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Install this custom firmware?'**
  String get sysManualUpdateConfirmTitle;

  /// No description provided for @sysManualUpdateUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload and install'**
  String get sysManualUpdateUploadAction;

  /// No description provided for @sysManualUpdateConsequenceValidation.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS uploads and validates the selected update archive before installing it.'**
  String get sysManualUpdateConsequenceValidation;

  /// No description provided for @sysManualUpdateConsequenceRestart.
  ///
  /// In en, this message translates to:
  /// **'The server restarts automatically after the update file is installed.'**
  String get sysManualUpdateConsequenceRestart;

  /// No description provided for @sysManualUpdateUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading: {percent}%'**
  String sysManualUpdateUploading(int percent);

  /// No description provided for @sysManualUpdateProcessing.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS is validating and installing the update…'**
  String get sysManualUpdateProcessing;

  /// No description provided for @sysManualUpdateRestartSoon.
  ///
  /// In en, this message translates to:
  /// **'The update is ready to install.'**
  String get sysManualUpdateRestartSoon;

  /// No description provided for @sysUpdateChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Firmware channel'**
  String get sysUpdateChannelTitle;

  /// No description provided for @sysUpdateChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which TrueNAS release channel supplies system updates.'**
  String get sysUpdateChannelDescription;

  /// No description provided for @sysUpdateChannelGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sysUpdateChannelGeneral;

  /// No description provided for @sysUpdateChannelEarlyAdopter.
  ///
  /// In en, this message translates to:
  /// **'Early Adopter'**
  String get sysUpdateChannelEarlyAdopter;

  /// No description provided for @sysUpdateChannelDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer Beta'**
  String get sysUpdateChannelDeveloper;

  /// No description provided for @sysManualUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The custom firmware update failed.'**
  String get sysManualUpdateFailed;

  /// No description provided for @sysManualUpdateNoPath.
  ///
  /// In en, this message translates to:
  /// **'The selected file cannot be read on this device.'**
  String get sysManualUpdateNoPath;

  /// No description provided for @sysManualUpdateUnsupportedExtension.
  ///
  /// In en, this message translates to:
  /// **'Select an official TrueNAS .tar or .update file.'**
  String get sysManualUpdateUnsupportedExtension;

  /// No description provided for @sysUpdateProgress.
  ///
  /// In en, this message translates to:
  /// **'Update progress: {percent}%'**
  String sysUpdateProgress(int percent);

  /// No description provided for @sysPowerNotPermitted.
  ///
  /// In en, this message translates to:
  /// **'This account cannot restart or shut down the server.'**
  String get sysPowerNotPermitted;

  /// No description provided for @sysPowerWarning.
  ///
  /// In en, this message translates to:
  /// **'Restarting or shutting down interrupts every share, app, and running job on this server.'**
  String get sysPowerWarning;

  /// No description provided for @sysRestartServer.
  ///
  /// In en, this message translates to:
  /// **'Restart server'**
  String get sysRestartServer;

  /// No description provided for @sysShutdownServer.
  ///
  /// In en, this message translates to:
  /// **'Shut down server'**
  String get sysShutdownServer;

  /// No description provided for @sysMetricAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get sysMetricAlerts;

  /// No description provided for @sysMetricActiveJobs.
  ///
  /// In en, this message translates to:
  /// **'Active jobs'**
  String get sysMetricActiveJobs;

  /// No description provided for @sysMetricFailures.
  ///
  /// In en, this message translates to:
  /// **'Failures'**
  String get sysMetricFailures;

  /// No description provided for @sysAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get sysAlerts;

  /// No description provided for @sysJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get sysJobs;

  /// No description provided for @sysNoAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts.'**
  String get sysNoAlerts;

  /// No description provided for @sysAlertFailed.
  ///
  /// In en, this message translates to:
  /// **'The alert operation failed.'**
  String get sysAlertFailed;

  /// No description provided for @sysAlertDismissed.
  ///
  /// In en, this message translates to:
  /// **'Alert dismissed.'**
  String get sysAlertDismissed;

  /// No description provided for @sysAlertRestored.
  ///
  /// In en, this message translates to:
  /// **'Alert restored.'**
  String get sysAlertRestored;

  /// No description provided for @sysAlertSubtitleDismissed.
  ///
  /// In en, this message translates to:
  /// **'{level} · Dismissed'**
  String sysAlertSubtitleDismissed(String level);

  /// No description provided for @sysRestoreAlert.
  ///
  /// In en, this message translates to:
  /// **'Restore alert'**
  String get sysRestoreAlert;

  /// No description provided for @sysDismissAlert.
  ///
  /// In en, this message translates to:
  /// **'Dismiss alert'**
  String get sysDismissAlert;

  /// No description provided for @sysUserLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sysUserLocal;

  /// No description provided for @sysUserDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get sysUserDirectory;

  /// No description provided for @sysUserSmb.
  ///
  /// In en, this message translates to:
  /// **'SMB'**
  String get sysUserSmb;

  /// No description provided for @sysUserPasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Password disabled'**
  String get sysUserPasswordDisabled;

  /// No description provided for @sysUserLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get sysUserLocked;

  /// No description provided for @sysBuiltInAccount.
  ///
  /// In en, this message translates to:
  /// **'Built-in account'**
  String get sysBuiltInAccount;

  /// No description provided for @sysDirectoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Directory account'**
  String get sysDirectoryAccount;

  /// No description provided for @sysEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get sysEditUser;

  /// No description provided for @sysDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get sysDeleteUser;

  /// No description provided for @sysGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GID {gid} · {count} users'**
  String sysGroupSubtitle(String gid, int count);

  /// No description provided for @sysGroupSubtitleWithRoles.
  ///
  /// In en, this message translates to:
  /// **'GID {gid} · {count} users · {roles}'**
  String sysGroupSubtitleWithRoles(String gid, int count, String roles);

  /// No description provided for @sysBuiltInGroup.
  ///
  /// In en, this message translates to:
  /// **'Built-in group'**
  String get sysBuiltInGroup;

  /// No description provided for @sysDirectoryGroup.
  ///
  /// In en, this message translates to:
  /// **'Directory group'**
  String get sysDirectoryGroup;

  /// No description provided for @sysEditGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get sysEditGroup;

  /// No description provided for @sysDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get sysDeleteGroup;

  /// No description provided for @sysInterfaceLinkUp.
  ///
  /// In en, this message translates to:
  /// **'Link up'**
  String get sysInterfaceLinkUp;

  /// No description provided for @sysInterfaceMtu.
  ///
  /// In en, this message translates to:
  /// **'MTU {mtu}'**
  String sysInterfaceMtu(String mtu);

  /// No description provided for @sysInterfaceDhcp.
  ///
  /// In en, this message translates to:
  /// **'DHCP'**
  String get sysInterfaceDhcp;

  /// No description provided for @sysUserEditReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review user changes'**
  String get sysUserEditReviewTitle;

  /// No description provided for @sysUserEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get sysUserEditTitle;

  /// No description provided for @sysUserApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get sysUserApplyChanges;

  /// No description provided for @sysUserFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get sysUserFullNameLabel;

  /// No description provided for @sysUserEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sysUserEmailLabel;

  /// No description provided for @sysUserEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to clear the address'**
  String get sysUserEmailHelper;

  /// No description provided for @sysUserShellLabel.
  ///
  /// In en, this message translates to:
  /// **'Login shell'**
  String get sysUserShellLabel;

  /// No description provided for @sysUserSmbAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'SMB access'**
  String get sysUserSmbAccessTitle;

  /// No description provided for @sysUserSmbAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow this account to authenticate to SMB.'**
  String get sysUserSmbAccessSubtitle;

  /// No description provided for @sysUserDisablePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Disable password sign-in'**
  String get sysUserDisablePasswordTitle;

  /// No description provided for @sysUserDisablePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeps key-based access working.'**
  String get sysUserDisablePasswordSubtitle;

  /// No description provided for @sysUserLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock account'**
  String get sysUserLockTitle;

  /// No description provided for @sysUserLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blocks all sign-in for this user.'**
  String get sysUserLockSubtitle;

  /// No description provided for @sysUserPrimaryGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary group'**
  String get sysUserPrimaryGroupTitle;

  /// No description provided for @sysUserPrimaryGroupManaged.
  ///
  /// In en, this message translates to:
  /// **'Managed by TrueNAS'**
  String get sysUserPrimaryGroupManaged;

  /// No description provided for @sysUserPrimaryGroupNamed.
  ///
  /// In en, this message translates to:
  /// **'{name} — change it in the TrueNAS web UI'**
  String sysUserPrimaryGroupNamed(String name);

  /// No description provided for @sysUserAuxGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary groups'**
  String get sysUserAuxGroupsTitle;

  /// No description provided for @sysUserAuxGroupsNone.
  ///
  /// In en, this message translates to:
  /// **'No other groups are available.'**
  String get sysUserAuxGroupsNone;

  /// No description provided for @sysUserLockWarning.
  ///
  /// In en, this message translates to:
  /// **'Locking {username} immediately blocks sign-in, including any session this account uses to reach TrueNAS.'**
  String sysUserLockWarning(String username);

  /// No description provided for @sysUserShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get sysUserShowPassword;

  /// No description provided for @sysUserHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get sysUserHidePassword;

  /// No description provided for @sysUserCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New user'**
  String get sysUserCreateTitle;

  /// No description provided for @sysUserCreateUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get sysUserCreateUsernameLabel;

  /// No description provided for @sysUserCreateFullNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Defaults to the username'**
  String get sysUserCreateFullNameHelper;

  /// No description provided for @sysUserCreateDisablePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the account without a password.'**
  String get sysUserCreateDisablePasswordSubtitle;

  /// No description provided for @sysUserCreateSmbAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'SMB access'**
  String get sysUserCreateSmbAccessTitle;

  /// No description provided for @sysUserCreateMatchingGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a matching primary group'**
  String get sysUserCreateMatchingGroupTitle;

  /// No description provided for @sysUserCreateMatchingGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for ordinary accounts.'**
  String get sysUserCreateMatchingGroupSubtitle;

  /// No description provided for @sysUserCreatePrimaryGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary group'**
  String get sysUserCreatePrimaryGroupLabel;

  /// No description provided for @sysUserCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get sysUserCreateAction;

  /// No description provided for @sysGroupEditReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review group changes'**
  String get sysGroupEditReviewTitle;

  /// No description provided for @sysGroupEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get sysGroupEditTitle;

  /// No description provided for @sysGroupEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GID {gid}'**
  String sysGroupEditSubtitle(String gid);

  /// No description provided for @sysGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get sysGroupNameLabel;

  /// No description provided for @sysGroupExposeSmbTitle.
  ///
  /// In en, this message translates to:
  /// **'Expose to SMB'**
  String get sysGroupExposeSmbTitle;

  /// No description provided for @sysGroupMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get sysGroupMembersTitle;

  /// No description provided for @sysGroupMembersNone.
  ///
  /// In en, this message translates to:
  /// **'No users are available.'**
  String get sysGroupMembersNone;

  /// No description provided for @sysGroupRenameWarning.
  ///
  /// In en, this message translates to:
  /// **'Permissions and shares that reference the old group name keep pointing at it and must be updated separately.'**
  String get sysGroupRenameWarning;

  /// No description provided for @sysGroupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get sysGroupCreateTitle;

  /// No description provided for @sysGroupCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get sysGroupCreateAction;

  /// No description provided for @sysUserValidationUserNotEditable.
  ///
  /// In en, this message translates to:
  /// **'Built-in and directory accounts cannot be edited from TrueDock.'**
  String get sysUserValidationUserNotEditable;

  /// No description provided for @sysUserValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or leave it empty.'**
  String get sysUserValidationEmailInvalid;

  /// No description provided for @sysUserValidationUserUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed for this user.'**
  String get sysUserValidationUserUnchanged;

  /// No description provided for @sysUserValidationGroupNotEditable.
  ///
  /// In en, this message translates to:
  /// **'Built-in and directory groups cannot be edited from TrueDock.'**
  String get sysUserValidationGroupNotEditable;

  /// No description provided for @sysUserValidationGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a group name.'**
  String get sysUserValidationGroupNameRequired;

  /// No description provided for @sysUserValidationGroupNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'A group name cannot contain spaces, colons, or commas.'**
  String get sysUserValidationGroupNameInvalid;

  /// No description provided for @sysUserValidationGroupUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed for this group.'**
  String get sysUserValidationGroupUnchanged;

  /// No description provided for @sysUserValidationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a username.'**
  String get sysUserValidationUsernameRequired;

  /// No description provided for @sysUserValidationUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'A username must start with a letter or underscore and use only lowercase letters, digits, hyphens, and underscores.'**
  String get sysUserValidationUsernameInvalid;

  /// No description provided for @sysUserValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Set a password or disable password sign-in.'**
  String get sysUserValidationPasswordRequired;

  /// No description provided for @sysUserValidationPrimaryGroupRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a primary group or let TrueNAS create one.'**
  String get sysUserValidationPrimaryGroupRequired;

  /// No description provided for @sysUserChangeFullNameCleared.
  ///
  /// In en, this message translates to:
  /// **'Full name cleared'**
  String get sysUserChangeFullNameCleared;

  /// No description provided for @sysUserChangeFullNameSet.
  ///
  /// In en, this message translates to:
  /// **'Full name set to \"{value}\"'**
  String sysUserChangeFullNameSet(String value);

  /// No description provided for @sysUserChangeEmailCleared.
  ///
  /// In en, this message translates to:
  /// **'Email address cleared'**
  String get sysUserChangeEmailCleared;

  /// No description provided for @sysUserChangeEmailSet.
  ///
  /// In en, this message translates to:
  /// **'Email set to {value}'**
  String sysUserChangeEmailSet(String value);

  /// No description provided for @sysUserChangeShellSet.
  ///
  /// In en, this message translates to:
  /// **'Login shell set to {value}'**
  String sysUserChangeShellSet(String value);

  /// No description provided for @sysUserChangeSmbEnabled.
  ///
  /// In en, this message translates to:
  /// **'SMB access enabled'**
  String get sysUserChangeSmbEnabled;

  /// No description provided for @sysUserChangeSmbDisabled.
  ///
  /// In en, this message translates to:
  /// **'SMB access disabled'**
  String get sysUserChangeSmbDisabled;

  /// No description provided for @sysUserChangeAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Account locked — the user can no longer sign in'**
  String get sysUserChangeAccountLocked;

  /// No description provided for @sysUserChangeAccountUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Account unlocked'**
  String get sysUserChangeAccountUnlocked;

  /// No description provided for @sysUserChangePasswordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Password sign-in disabled'**
  String get sysUserChangePasswordDisabled;

  /// No description provided for @sysUserChangePasswordEnabled.
  ///
  /// In en, this message translates to:
  /// **'Password sign-in enabled'**
  String get sysUserChangePasswordEnabled;

  /// No description provided for @sysUserChangeAuxGroupsSet.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary groups set to {count} group(s)'**
  String sysUserChangeAuxGroupsSet(int count);

  /// No description provided for @sysUserChangeGroupRenamed.
  ///
  /// In en, this message translates to:
  /// **'Group renamed to {value}'**
  String sysUserChangeGroupRenamed(String value);

  /// No description provided for @sysUserChangeGroupExposedSmb.
  ///
  /// In en, this message translates to:
  /// **'Group exposed to SMB'**
  String get sysUserChangeGroupExposedSmb;

  /// No description provided for @sysUserChangeGroupHiddenSmb.
  ///
  /// In en, this message translates to:
  /// **'Group hidden from SMB'**
  String get sysUserChangeGroupHiddenSmb;

  /// No description provided for @sysUserChangeMembershipSet.
  ///
  /// In en, this message translates to:
  /// **'Membership set to {count} user(s)'**
  String sysUserChangeMembershipSet(int count);

  /// No description provided for @sysUserChangeOtherField.
  ///
  /// In en, this message translates to:
  /// **'{value} updated'**
  String sysUserChangeOtherField(String value);

  /// No description provided for @sysUserPasswordReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review new password'**
  String get sysUserPasswordReviewTitle;

  /// No description provided for @sysUserPasswordSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set password for {username}'**
  String sysUserPasswordSetTitle(String username);

  /// No description provided for @sysUserPasswordLocalAccount.
  ///
  /// In en, this message translates to:
  /// **'Local account'**
  String get sysUserPasswordLocalAccount;

  /// No description provided for @sysUserPasswordDirectoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Directory account'**
  String get sysUserPasswordDirectoryAccount;

  /// No description provided for @sysUserPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get sysUserPasswordNewLabel;

  /// No description provided for @sysUserPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get sysUserPasswordConfirmLabel;

  /// No description provided for @sysUserPasswordNotice.
  ///
  /// In en, this message translates to:
  /// **'The new password is sent only to the connected TrueNAS server. TrueDock does not save it, log it, or autofill it.'**
  String get sysUserPasswordNotice;

  /// No description provided for @sysUserPasswordReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get sysUserPasswordReviewAction;

  /// No description provided for @sysUserPasswordReviewServerAction.
  ///
  /// In en, this message translates to:
  /// **'Server action'**
  String get sysUserPasswordReviewServerAction;

  /// No description provided for @sysUserPasswordReviewServerActionValue.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get sysUserPasswordReviewServerActionValue;

  /// No description provided for @sysUserPasswordReviewAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sysUserPasswordReviewAccount;

  /// No description provided for @sysUserPasswordReviewSetLabel.
  ///
  /// In en, this message translates to:
  /// **'Password set'**
  String get sysUserPasswordReviewSetLabel;

  /// No description provided for @sysUserPasswordReviewSetValue.
  ///
  /// In en, this message translates to:
  /// **'Yes · {count} characters'**
  String sysUserPasswordReviewSetValue(int count);

  /// No description provided for @sysUserPasswordReviewSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in as {username} must use the new password afterwards. Active sessions for this account may be ended by TrueNAS.'**
  String sysUserPasswordReviewSessionWarning(String username);

  /// No description provided for @sysUserPasswordErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password.'**
  String get sysUserPasswordErrorEmpty;

  /// No description provided for @sysUserPasswordErrorShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get sysUserPasswordErrorShort;

  /// No description provided for @sysUserPasswordErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get sysUserPasswordErrorMismatch;

  /// No description provided for @sysApiKeyNone.
  ///
  /// In en, this message translates to:
  /// **'No API keys are registered on this server.'**
  String get sysApiKeyNone;

  /// No description provided for @sysSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get sysSessions;

  /// No description provided for @sysSessionNone.
  ///
  /// In en, this message translates to:
  /// **'No user sessions are connected to this server.'**
  String get sysSessionNone;

  /// No description provided for @sysSessionThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sysSessionThisDevice;

  /// No description provided for @sysSessionPasswordLogin.
  ///
  /// In en, this message translates to:
  /// **'Password sign-in'**
  String get sysSessionPasswordLogin;

  /// No description provided for @sysSessionApiKeyLogin.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get sysSessionApiKeyLogin;

  /// No description provided for @sysSessionTokenLogin.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get sysSessionTokenLogin;

  /// No description provided for @sysSessionInsecure.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted'**
  String get sysSessionInsecure;

  /// No description provided for @sysSessionJustNow.
  ///
  /// In en, this message translates to:
  /// **'Started just now'**
  String get sysSessionJustNow;

  /// No description provided for @sysSessionMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Started 1 minute ago} other{Started {count} minutes ago}}'**
  String sysSessionMinutes(int count);

  /// No description provided for @sysSessionHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Started 1 hour ago} other{Started {count} hours ago}}'**
  String sysSessionHours(int count);

  /// No description provided for @sysSessionDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Started 1 day ago} other{Started {count} days ago}}'**
  String sysSessionDays(int count);

  /// No description provided for @sysSessionInternalNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 internal middleware connection is hidden.} other{{count} internal middleware connections are hidden.}}'**
  String sysSessionInternalNote(int count);

  /// No description provided for @sysSessionTerminateTooltip.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get sysSessionTerminateTooltip;

  /// No description provided for @sysSessionTerminateTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get sysSessionTerminateTitle;

  /// No description provided for @sysSessionTerminateAction.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get sysSessionTerminateAction;

  /// No description provided for @sysSessionTerminateConsequence.
  ///
  /// In en, this message translates to:
  /// **'The client at {origin} is signed out immediately and any request it is making fails.'**
  String sysSessionTerminateConsequence(String origin);

  /// No description provided for @sysSessionTerminateReconnect.
  ///
  /// In en, this message translates to:
  /// **'Whoever holds the credential can sign in again. Revoke the API key or change the password to stop that.'**
  String get sysSessionTerminateReconnect;

  /// No description provided for @sysSessionTerminateOthers.
  ///
  /// In en, this message translates to:
  /// **'End all other sessions'**
  String get sysSessionTerminateOthers;

  /// No description provided for @sysSessionTerminateOthersTitle.
  ///
  /// In en, this message translates to:
  /// **'End every other session?'**
  String get sysSessionTerminateOthersTitle;

  /// No description provided for @sysSessionTerminateOthersConsequence.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 other session is signed out immediately.} other{{count} other sessions are signed out immediately.}}'**
  String sysSessionTerminateOthersConsequence(int count);

  /// No description provided for @sysSessionTerminateOthersKeepsThis.
  ///
  /// In en, this message translates to:
  /// **'This device stays signed in.'**
  String get sysSessionTerminateOthersKeepsThis;

  /// No description provided for @sysSessionTerminated.
  ///
  /// In en, this message translates to:
  /// **'The session was ended.'**
  String get sysSessionTerminated;

  /// No description provided for @sysSessionTerminateFailed.
  ///
  /// In en, this message translates to:
  /// **'The session could not be ended.'**
  String get sysSessionTerminateFailed;

  /// No description provided for @sysApiKeyRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get sysApiKeyRevoked;

  /// No description provided for @sysApiKeyExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get sysApiKeyExpired;

  /// No description provided for @sysApiKeyExpiresDate.
  ///
  /// In en, this message translates to:
  /// **'expires {date}'**
  String sysApiKeyExpiresDate(String date);

  /// No description provided for @sysApiKeyNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'no expiry'**
  String get sysApiKeyNoExpiry;

  /// No description provided for @sysApiKeyCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'created {date}'**
  String sysApiKeyCreatedDate(String date);

  /// No description provided for @sysApiKeyRevokeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Revoke API key'**
  String get sysApiKeyRevokeTooltip;

  /// No description provided for @sysBootNone.
  ///
  /// In en, this message translates to:
  /// **'No boot environments were reported.'**
  String get sysBootNone;

  /// No description provided for @sysBootPendingNotice.
  ///
  /// In en, this message translates to:
  /// **'This server will boot into {id} the next time it restarts.'**
  String sysBootPendingNotice(String id);

  /// No description provided for @sysBootStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running now'**
  String get sysBootStatusRunning;

  /// No description provided for @sysBootStatusNext.
  ///
  /// In en, this message translates to:
  /// **'Next boot'**
  String get sysBootStatusNext;

  /// No description provided for @sysBootStatusReplaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced at next boot'**
  String get sysBootStatusReplaced;

  /// No description provided for @sysBootStatusKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get sysBootStatusKept;

  /// No description provided for @sysBootActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Use at next boot'**
  String get sysBootActivateAction;

  /// No description provided for @sysBootOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Boot environment options'**
  String get sysBootOptionsTooltip;

  /// No description provided for @sysBootAllowRemoval.
  ///
  /// In en, this message translates to:
  /// **'Allow automatic removal'**
  String get sysBootAllowRemoval;

  /// No description provided for @sysBootKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep this environment'**
  String get sysBootKeep;

  /// No description provided for @sysBootDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete environment'**
  String get sysBootDelete;

  /// No description provided for @sysGeneralReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get sysGeneralReviewTitle;

  /// No description provided for @sysGeneralFormTitle.
  ///
  /// In en, this message translates to:
  /// **'General settings'**
  String get sysGeneralFormTitle;

  /// No description provided for @sysGeneralHostnameLabel.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get sysGeneralHostnameLabel;

  /// No description provided for @sysGeneralDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysGeneralDescriptionLabel;

  /// No description provided for @sysGeneralDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown in the server list and overview.'**
  String get sysGeneralDescriptionHelper;

  /// No description provided for @sysGeneralTimezoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get sysGeneralTimezoneTitle;

  /// No description provided for @sysGeneralTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get sysGeneralTimezoneLabel;

  /// No description provided for @sysGeneralTimezoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Could not load choices. Enter an IANA timezone.'**
  String get sysGeneralTimezoneHelper;

  /// No description provided for @sysGeneralSyslogTitle.
  ///
  /// In en, this message translates to:
  /// **'Syslog'**
  String get sysGeneralSyslogTitle;

  /// No description provided for @sysGeneralSyslogLabel.
  ///
  /// In en, this message translates to:
  /// **'Syslog level'**
  String get sysGeneralSyslogLabel;

  /// No description provided for @sysGeneralReviewHostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get sysGeneralReviewHostname;

  /// No description provided for @sysGeneralReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysGeneralReviewDescription;

  /// No description provided for @sysGeneralReviewTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get sysGeneralReviewTimezone;

  /// No description provided for @sysGeneralReviewSyslog.
  ///
  /// In en, this message translates to:
  /// **'Syslog'**
  String get sysGeneralReviewSyslog;

  /// No description provided for @sysGeneralReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysGeneralReviewNone;

  /// No description provided for @sysGeneralNoFieldsChanged.
  ///
  /// In en, this message translates to:
  /// **'No fields changed. The server keeps its settings.'**
  String get sysGeneralNoFieldsChanged;

  /// No description provided for @sysGeneralHostnameNotice.
  ///
  /// In en, this message translates to:
  /// **'Hostname changes take effect after the server reloads its network configuration. Active sessions are not affected.'**
  String get sysGeneralHostnameNotice;

  /// No description provided for @sysGeneralChangedFields.
  ///
  /// In en, this message translates to:
  /// **'Changed fields'**
  String get sysGeneralChangedFields;

  /// No description provided for @sysGeneralValidationHostnameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a hostname.'**
  String get sysGeneralValidationHostnameRequired;

  /// No description provided for @sysGeneralValidationTimezoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a timezone.'**
  String get sysGeneralValidationTimezoneRequired;

  /// No description provided for @sysSyslogDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (local)'**
  String get sysSyslogDefault;

  /// No description provided for @sysSyslogDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get sysSyslogDebug;

  /// No description provided for @sysSyslogInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get sysSyslogInfo;

  /// No description provided for @sysSyslogNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get sysSyslogNotice;

  /// No description provided for @sysSyslogWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get sysSyslogWarning;

  /// No description provided for @sysSyslogError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get sysSyslogError;

  /// No description provided for @sysSyslogCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get sysSyslogCritical;

  /// No description provided for @sysSyslogAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get sysSyslogAlert;

  /// No description provided for @sysSyslogEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sysSyslogEmergency;

  /// No description provided for @sysRouteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review route'**
  String get sysRouteReviewTitle;

  /// No description provided for @sysRouteNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New static route'**
  String get sysRouteNewTitle;

  /// No description provided for @sysRouteEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get sysRouteEditTitle;

  /// No description provided for @sysRouteSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get sysRouteSaveAction;

  /// No description provided for @sysRouteDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination network'**
  String get sysRouteDestinationLabel;

  /// No description provided for @sysRouteGatewayLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get sysRouteGatewayLabel;

  /// No description provided for @sysRouteGatewayHelper.
  ///
  /// In en, this message translates to:
  /// **'Next-hop IP address, e.g. 10.0.0.1'**
  String get sysRouteGatewayHelper;

  /// No description provided for @sysRouteDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysRouteDescriptionLabel;

  /// No description provided for @sysRouteDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional note shown in the route list.'**
  String get sysRouteDescriptionHelper;

  /// No description provided for @sysRouteStagedNotice.
  ///
  /// In en, this message translates to:
  /// **'The route takes effect only after the staged network changes are committed. TrueDock walks you through commit and check-in once the route is saved.'**
  String get sysRouteStagedNotice;

  /// No description provided for @sysRouteReviewDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get sysRouteReviewDestination;

  /// No description provided for @sysRouteReviewGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get sysRouteReviewGateway;

  /// No description provided for @sysRouteReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysRouteReviewDescription;

  /// No description provided for @sysRouteReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysRouteReviewNone;

  /// No description provided for @sysRouteCommitNotice.
  ///
  /// In en, this message translates to:
  /// **'Committing the staged network change briefly disrupts network connectivity. If TrueDock loses its connection after commit, the server rolls the route back automatically.'**
  String get sysRouteCommitNotice;

  /// No description provided for @sysRouteValidationDestinationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a destination network.'**
  String get sysRouteValidationDestinationRequired;

  /// No description provided for @sysRouteValidationDestinationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a destination as A.B.C.D/E.'**
  String get sysRouteValidationDestinationInvalid;

  /// No description provided for @sysRouteValidationGatewayRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a gateway address.'**
  String get sysRouteValidationGatewayRequired;

  /// No description provided for @sysRouteValidationGatewayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid gateway IP address.'**
  String get sysRouteValidationGatewayInvalid;

  /// No description provided for @sysNetCommitApplyAction.
  ///
  /// In en, this message translates to:
  /// **'Apply network changes'**
  String get sysNetCommitApplyAction;

  /// No description provided for @sysNetCommitCommittingTitle.
  ///
  /// In en, this message translates to:
  /// **'Committing changes…'**
  String get sysNetCommitCommittingTitle;

  /// No description provided for @sysNetCommitCommittingBody.
  ///
  /// In en, this message translates to:
  /// **'The server is applying the staged network configuration. This may briefly drop the TrueDock connection.'**
  String get sysNetCommitCommittingBody;

  /// No description provided for @sysNetCommitCheckingInTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking in…'**
  String get sysNetCommitCheckingInTitle;

  /// No description provided for @sysNetCommitCheckingInBody.
  ///
  /// In en, this message translates to:
  /// **'Locking the staged changes so the server keeps them.'**
  String get sysNetCommitCheckingInBody;

  /// No description provided for @sysNetCommitAppliedTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes applied'**
  String get sysNetCommitAppliedTitle;

  /// No description provided for @sysNetCommitAppliedBody.
  ///
  /// In en, this message translates to:
  /// **'The network configuration was committed and checked in on {server}.'**
  String sysNetCommitAppliedBody(String server);

  /// No description provided for @sysNetCommitRolledBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes rolled back'**
  String get sysNetCommitRolledBackTitle;

  /// No description provided for @sysNetCommitRolledBackBody.
  ///
  /// In en, this message translates to:
  /// **'The staged network changes were reverted. No live configuration was changed on {server}.'**
  String sysNetCommitRolledBackBody(String server);

  /// No description provided for @sysNetCommitFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Network commit failed'**
  String get sysNetCommitFailedTitle;

  /// No description provided for @sysNetCommitFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the commit. No live configuration was changed.'**
  String get sysNetCommitFailedBody;

  /// No description provided for @sysNetCommitWarning.
  ///
  /// In en, this message translates to:
  /// **'Committing staged network changes briefly disrupts connectivity on {server}. If the new configuration breaks the route TrueDock uses, the server rolls everything back automatically at the end of its verification window.'**
  String sysNetCommitWarning(String server);

  /// No description provided for @sysNetCommitAfterNote.
  ///
  /// In en, this message translates to:
  /// **'After the commit succeeds, TrueDock verifies its own connection survived and asks you to check the changes in. Skip the check-in only if you want the server to revert.'**
  String get sysNetCommitAfterNote;

  /// No description provided for @sysNetCommitPendingChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for staged network changes…'**
  String get sysNetCommitPendingChecking;

  /// No description provided for @sysNetCommitPendingNone.
  ///
  /// In en, this message translates to:
  /// **'The server reports no staged network changes. Committing now would do nothing.'**
  String get sysNetCommitPendingNone;

  /// No description provided for @sysNetCommitPendingStaged.
  ///
  /// In en, this message translates to:
  /// **'The server has staged network changes waiting to be committed.'**
  String get sysNetCommitPendingStaged;

  /// No description provided for @sysNetCommitPendingAwaitingCheckIn.
  ///
  /// In en, this message translates to:
  /// **'A commit is already in flight. {seconds}s remain to check in before the server reverts it.'**
  String sysNetCommitPendingAwaitingCheckIn(int seconds);

  /// No description provided for @sysNetCommitPendingClears.
  ///
  /// In en, this message translates to:
  /// **'Checking in will clear these network settings: {fields}. If one of them is the route TrueDock uses, this connection will drop.'**
  String sysNetCommitPendingClears(String fields);

  /// No description provided for @sysNetCommitVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify the connection'**
  String get sysNetCommitVerifyTitle;

  /// No description provided for @sysNetCommitVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'The commit finished. TrueDock is checking that it can still reach {server}. If this hangs, the new configuration may have broken the route; the server will roll back shortly.'**
  String sysNetCommitVerifyBody(String server);

  /// No description provided for @sysNetCommitAddressChangedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did you change the network address?'**
  String get sysNetCommitAddressChangedQuestion;

  /// No description provided for @sysNetCommitAddressChangedHelp.
  ///
  /// In en, this message translates to:
  /// **'If this server moved, enter its new address and test an authenticated connection before checking in.'**
  String get sysNetCommitAddressChangedHelp;

  /// No description provided for @sysNetCommitNewAddress.
  ///
  /// In en, this message translates to:
  /// **'New server address'**
  String get sysNetCommitNewAddress;

  /// No description provided for @sysNetCommitTestAddress.
  ///
  /// In en, this message translates to:
  /// **'Test new address'**
  String get sysNetCommitTestAddress;

  /// No description provided for @sysNetCommitTestingAddress.
  ///
  /// In en, this message translates to:
  /// **'Testing new address…'**
  String get sysNetCommitTestingAddress;

  /// No description provided for @sysNetCommitAddressTestPassed.
  ///
  /// In en, this message translates to:
  /// **'The new address is reachable and authenticated. You can safely check in.'**
  String get sysNetCommitAddressTestPassed;

  /// No description provided for @sysNetCommitAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the new server address.'**
  String get sysNetCommitAddressRequired;

  /// No description provided for @sysNetCommitAddressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The network change was checked in, but TrueDock could not save the new server address.'**
  String get sysNetCommitAddressSaveFailed;

  /// No description provided for @sysNetCommitTestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Connection testing is unavailable.'**
  String get sysNetCommitTestUnavailable;

  /// No description provided for @sysNetCommitNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get sysNetCommitNotNow;

  /// No description provided for @sysNetCommitCommitAction.
  ///
  /// In en, this message translates to:
  /// **'Commit changes'**
  String get sysNetCommitCommitAction;

  /// No description provided for @sysNetCommitRollbackAction.
  ///
  /// In en, this message translates to:
  /// **'Roll back'**
  String get sysNetCommitRollbackAction;

  /// No description provided for @sysNetCommitCheckInAction.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get sysNetCommitCheckInAction;

  /// No description provided for @sysNetCommitDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sysNetCommitDone;

  /// No description provided for @sysInterfaceReviewName.
  ///
  /// In en, this message translates to:
  /// **'Review {name}'**
  String sysInterfaceReviewName(String name);

  /// No description provided for @sysInterfaceEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String sysInterfaceEditName(String name);

  /// No description provided for @sysInterfaceStageChange.
  ///
  /// In en, this message translates to:
  /// **'Stage change'**
  String get sysInterfaceStageChange;

  /// No description provided for @sysInterfaceStagedNotice.
  ///
  /// In en, this message translates to:
  /// **'Interface changes are staged. They take effect only after you commit and check in the pending network changes, and the server reverts them if the connection does not survive.'**
  String get sysInterfaceStagedNotice;

  /// No description provided for @sysInterfaceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysInterfaceDescriptionLabel;

  /// No description provided for @sysInterfaceAddressingTitle.
  ///
  /// In en, this message translates to:
  /// **'Addressing'**
  String get sysInterfaceAddressingTitle;

  /// No description provided for @sysInterfaceUseDhcpTitle.
  ///
  /// In en, this message translates to:
  /// **'Use DHCP for IPv4'**
  String get sysInterfaceUseDhcpTitle;

  /// No description provided for @sysInterfaceUseDhcpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Static addresses are ignored while DHCP is on.'**
  String get sysInterfaceUseDhcpSubtitle;

  /// No description provided for @sysInterfaceDhcpConflict.
  ///
  /// In en, this message translates to:
  /// **'{owner} already uses DHCP. TrueNAS allows DHCP on only one interface, so this change will be rejected unless you turn DHCP off there first.'**
  String sysInterfaceDhcpConflict(String owner);

  /// No description provided for @sysInterfaceStaticTitle.
  ///
  /// In en, this message translates to:
  /// **'Static addresses'**
  String get sysInterfaceStaticTitle;

  /// No description provided for @sysInterfaceNoStatic.
  ///
  /// In en, this message translates to:
  /// **'No static addresses configured.'**
  String get sysInterfaceNoStatic;

  /// No description provided for @sysInterfaceAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get sysInterfaceAddAddress;

  /// No description provided for @sysInterfaceMtuLabel.
  ///
  /// In en, this message translates to:
  /// **'MTU (optional)'**
  String get sysInterfaceMtuLabel;

  /// No description provided for @sysInterfaceMtuHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for the default (1500).'**
  String get sysInterfaceMtuHelper;

  /// No description provided for @sysInterfaceReviewInterface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get sysInterfaceReviewInterface;

  /// No description provided for @sysInterfaceReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysInterfaceReviewDescription;

  /// No description provided for @sysInterfaceReviewIpv4.
  ///
  /// In en, this message translates to:
  /// **'IPv4'**
  String get sysInterfaceReviewIpv4;

  /// No description provided for @sysInterfaceReviewAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get sysInterfaceReviewAddresses;

  /// No description provided for @sysInterfaceReviewMtu.
  ///
  /// In en, this message translates to:
  /// **'MTU'**
  String get sysInterfaceReviewMtu;

  /// No description provided for @sysInterfaceReviewDhcp.
  ///
  /// In en, this message translates to:
  /// **'DHCP'**
  String get sysInterfaceReviewDhcp;

  /// No description provided for @sysInterfaceReviewStatic.
  ///
  /// In en, this message translates to:
  /// **'Static'**
  String get sysInterfaceReviewStatic;

  /// No description provided for @sysInterfaceReviewAssignedByDhcp.
  ///
  /// In en, this message translates to:
  /// **'Assigned by DHCP'**
  String get sysInterfaceReviewAssignedByDhcp;

  /// No description provided for @sysInterfaceReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysInterfaceReviewNone;

  /// No description provided for @sysInterfaceReviewMtuDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (1500)'**
  String get sysInterfaceReviewMtuDefault;

  /// No description provided for @sysInterfaceNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed. Saving stages no work.'**
  String get sysInterfaceNothingChanged;

  /// No description provided for @sysInterfaceSessionDrop.
  ///
  /// In en, this message translates to:
  /// **'Changing the address of the interface TrueDock is connected through will drop this session when you commit. The server rolls the change back automatically if the check-in does not arrive.'**
  String get sysInterfaceSessionDrop;

  /// No description provided for @sysInterfaceDhcpLosesRoute.
  ///
  /// In en, this message translates to:
  /// **'Switching to DHCP removes the static addresses on this interface. Anything pointing at those addresses loses its route.'**
  String get sysInterfaceDhcpLosesRoute;

  /// No description provided for @sysInterfaceEditAddressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get sysInterfaceEditAddressTooltip;

  /// No description provided for @sysInterfaceRemoveAddressTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove address'**
  String get sysInterfaceRemoveAddressTooltip;

  /// No description provided for @sysInterfaceEditAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get sysInterfaceEditAddressTitle;

  /// No description provided for @sysInterfaceIpv4Label.
  ///
  /// In en, this message translates to:
  /// **'IPv4'**
  String get sysInterfaceIpv4Label;

  /// No description provided for @sysInterfaceIpv6Label.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get sysInterfaceIpv6Label;

  /// No description provided for @sysInterfaceAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sysInterfaceAddressLabel;

  /// No description provided for @sysInterfacePrefixLabel.
  ///
  /// In en, this message translates to:
  /// **'Prefix length'**
  String get sysInterfacePrefixLabel;

  /// No description provided for @sysInterfacePrefixHelperV6.
  ///
  /// In en, this message translates to:
  /// **'1-128, e.g. 64'**
  String get sysInterfacePrefixHelperV6;

  /// No description provided for @sysInterfacePrefixHelperV4.
  ///
  /// In en, this message translates to:
  /// **'1-32, e.g. 24'**
  String get sysInterfacePrefixHelperV4;

  /// No description provided for @sysInterfaceSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get sysInterfaceSaveAddress;

  /// No description provided for @sysInterfaceAliasErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {family} address.'**
  String sysInterfaceAliasErrorInvalid(String family);

  /// No description provided for @sysInterfaceAliasErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Use a prefix between 1 and {max}.'**
  String sysInterfaceAliasErrorPrefix(int max);

  /// No description provided for @sysInterfaceValidationMtuRange.
  ///
  /// In en, this message translates to:
  /// **'Use an MTU between 68 and 9216.'**
  String get sysInterfaceValidationMtuRange;

  /// No description provided for @sysInterfaceValidationAliasesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one static address, or turn DHCP back on.'**
  String get sysInterfaceValidationAliasesRequired;

  /// No description provided for @sysInterfaceValidationAliasAddressInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {family} address for each alias.'**
  String sysInterfaceValidationAliasAddressInvalid(String family);

  /// No description provided for @sysInterfaceValidationAliasPrefixRange.
  ///
  /// In en, this message translates to:
  /// **'Use a prefix between 1 and {max} for {address}.'**
  String sysInterfaceValidationAliasPrefixRange(int max, String address);

  /// No description provided for @sysInterfaceValidationAliasDuplicate.
  ///
  /// In en, this message translates to:
  /// **'{address} is listed more than once.'**
  String sysInterfaceValidationAliasDuplicate(String address);

  /// No description provided for @sysVmDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'VM devices'**
  String get sysVmDevicesTitle;

  /// No description provided for @sysVmDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disks, network interfaces, and other devices attached to this virtual machine. Removing a disk device does not delete the underlying zvol or image.'**
  String get sysVmDevicesSubtitle;

  /// No description provided for @sysVmDevicesNone.
  ///
  /// In en, this message translates to:
  /// **'No devices are attached to this VM.'**
  String get sysVmDevicesNone;

  /// No description provided for @sysVmDeviceEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit device'**
  String get sysVmDeviceEditTooltip;

  /// No description provided for @sysVmDeviceRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get sysVmDeviceRemoveTooltip;

  /// No description provided for @sysVmDeviceAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get sysVmDeviceAddAction;

  /// No description provided for @sysVmDeviceEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit VM device'**
  String get sysVmDeviceEditTitle;

  /// No description provided for @sysVmDeviceAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add VM device'**
  String get sysVmDeviceAddTitle;

  /// No description provided for @sysVmDeviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get sysVmDeviceTypeLabel;

  /// No description provided for @sysVmDevicePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get sysVmDevicePathLabel;

  /// No description provided for @sysVmDevicePathHelper.
  ///
  /// In en, this message translates to:
  /// **'zvol or image path, e.g. /dev/zvol/tank/vm'**
  String get sysVmDevicePathHelper;

  /// No description provided for @sysVmDeviceSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size (MiB)'**
  String get sysVmDeviceSizeLabel;

  /// No description provided for @sysVmDeviceSizeHelper.
  ///
  /// In en, this message translates to:
  /// **'Ignored for existing zvols.'**
  String get sysVmDeviceSizeHelper;

  /// No description provided for @sysVmDeviceMacLabel.
  ///
  /// In en, this message translates to:
  /// **'MAC address (optional)'**
  String get sysVmDeviceMacLabel;

  /// No description provided for @sysVmDeviceMacHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for an auto-generated MAC.'**
  String get sysVmDeviceMacHelper;

  /// No description provided for @sysVmDeviceDisplayNotice.
  ///
  /// In en, this message translates to:
  /// **'A VNC display device is created with default settings. Edit it on the server for advanced options.'**
  String get sysVmDeviceDisplayNotice;

  /// No description provided for @sysVmDeviceDefaultNotice.
  ///
  /// In en, this message translates to:
  /// **'{type} devices use default attributes. Edit on the server for advanced configuration.'**
  String sysVmDeviceDefaultNotice(String type);

  /// No description provided for @sysVmDeviceSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save device'**
  String get sysVmDeviceSaveAction;

  /// No description provided for @sysVmDeviceErrorPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a path for the disk.'**
  String get sysVmDeviceErrorPathRequired;

  /// No description provided for @sysVmDeviceTypeDisk.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get sysVmDeviceTypeDisk;

  /// No description provided for @sysVmDeviceTypeCdrom.
  ///
  /// In en, this message translates to:
  /// **'CD-ROM'**
  String get sysVmDeviceTypeCdrom;

  /// No description provided for @sysVmDeviceTypeNic.
  ///
  /// In en, this message translates to:
  /// **'Network interface'**
  String get sysVmDeviceTypeNic;

  /// No description provided for @sysVmDeviceTypeDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get sysVmDeviceTypeDisplay;

  /// No description provided for @sysVmDeviceTypeMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory balloon'**
  String get sysVmDeviceTypeMemory;

  /// No description provided for @sysVmDeviceTypeUsb.
  ///
  /// In en, this message translates to:
  /// **'USB redirect'**
  String get sysVmDeviceTypeUsb;

  /// No description provided for @sysVmDeviceTypePci.
  ///
  /// In en, this message translates to:
  /// **'PCI device'**
  String get sysVmDeviceTypePci;

  /// No description provided for @sysVmDeviceTypeSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial port'**
  String get sysVmDeviceTypeSerial;

  /// No description provided for @sysVmDeviceTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sysVmDeviceTypeOther;

  /// No description provided for @sysVmDeviceSummaryDiskWithSize.
  ///
  /// In en, this message translates to:
  /// **'{path} · {size}'**
  String sysVmDeviceSummaryDiskWithSize(String path, String size);

  /// No description provided for @sysVmDeviceSummaryDiskFallback.
  ///
  /// In en, this message translates to:
  /// **'Disk'**
  String get sysVmDeviceSummaryDiskFallback;

  /// No description provided for @sysVmDeviceSummaryNicWithMac.
  ///
  /// In en, this message translates to:
  /// **'NIC · {mac}'**
  String sysVmDeviceSummaryNicWithMac(String mac);

  /// No description provided for @sysVmDeviceSummaryDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display · {mode}'**
  String sysVmDeviceSummaryDisplay(String mode);

  /// No description provided for @sysVmDeviceSummaryCdromEmpty.
  ///
  /// In en, this message translates to:
  /// **'CD-ROM · empty'**
  String get sysVmDeviceSummaryCdromEmpty;

  /// No description provided for @sysVmDeviceSummaryCdromWithPath.
  ///
  /// In en, this message translates to:
  /// **'CD-ROM · {path}'**
  String sysVmDeviceSummaryCdromWithPath(String path);

  /// No description provided for @sysVmConfigReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get sysVmConfigReviewTitle;

  /// No description provided for @sysVmConfigEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit virtual machine'**
  String get sysVmConfigEditTitle;

  /// No description provided for @sysVmConfigNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysVmConfigNameLabel;

  /// No description provided for @sysVmConfigDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysVmConfigDescriptionLabel;

  /// No description provided for @sysVmConfigCpuTitle.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get sysVmConfigCpuTitle;

  /// No description provided for @sysVmConfigSocketsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sockets'**
  String get sysVmConfigSocketsLabel;

  /// No description provided for @sysVmConfigCoresLabel.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get sysVmConfigCoresLabel;

  /// No description provided for @sysVmConfigThreadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get sysVmConfigThreadsLabel;

  /// No description provided for @sysVmConfigMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get sysVmConfigMemoryTitle;

  /// No description provided for @sysVmConfigMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory (MiB)'**
  String get sysVmConfigMemoryLabel;

  /// No description provided for @sysVmConfigMinMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum memory (MiB, optional)'**
  String get sysVmConfigMinMemoryLabel;

  /// No description provided for @sysVmConfigMinMemoryHelper.
  ///
  /// In en, this message translates to:
  /// **'Used by memory ballooning. Leave blank to disable.'**
  String get sysVmConfigMinMemoryHelper;

  /// No description provided for @sysVmConfigBootCpuTitle.
  ///
  /// In en, this message translates to:
  /// **'Boot & CPU'**
  String get sysVmConfigBootCpuTitle;

  /// No description provided for @sysVmConfigBootloaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Bootloader'**
  String get sysVmConfigBootloaderLabel;

  /// No description provided for @sysVmConfigCpuModeLabel.
  ///
  /// In en, this message translates to:
  /// **'CPU mode'**
  String get sysVmConfigCpuModeLabel;

  /// No description provided for @sysVmConfigBehaviourTitle.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get sysVmConfigBehaviourTitle;

  /// No description provided for @sysVmConfigAutostartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get sysVmConfigAutostartTitle;

  /// No description provided for @sysVmConfigAutostartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Boots the VM when the server starts.'**
  String get sysVmConfigAutostartSubtitle;

  /// No description provided for @sysVmConfigEnsureDisplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Ensure display device'**
  String get sysVmConfigEnsureDisplayTitle;

  /// No description provided for @sysVmConfigEnsureDisplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creates a VNC display device if one is missing.'**
  String get sysVmConfigEnsureDisplaySubtitle;

  /// No description provided for @sysVmConfigShutdownTimeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Shutdown timeout (seconds)'**
  String get sysVmConfigShutdownTimeoutLabel;

  /// No description provided for @sysVmConfigShutdownTimeoutHelper.
  ///
  /// In en, this message translates to:
  /// **'How long to wait for a graceful shutdown.'**
  String get sysVmConfigShutdownTimeoutHelper;

  /// No description provided for @sysVmConfigReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysVmConfigReviewName;

  /// No description provided for @sysVmConfigReviewCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get sysVmConfigReviewCpu;

  /// No description provided for @sysVmConfigReviewCpuValue.
  ///
  /// In en, this message translates to:
  /// **'{sockets} sockets · {cores} cores · {threads} threads'**
  String sysVmConfigReviewCpuValue(int sockets, int cores, int threads);

  /// No description provided for @sysVmConfigReviewMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get sysVmConfigReviewMemory;

  /// No description provided for @sysVmConfigReviewMemoryValue.
  ///
  /// In en, this message translates to:
  /// **'{memory} MiB'**
  String sysVmConfigReviewMemoryValue(int memory);

  /// No description provided for @sysVmConfigReviewMemoryWithMinValue.
  ///
  /// In en, this message translates to:
  /// **'{memory} MiB (min {min})'**
  String sysVmConfigReviewMemoryWithMinValue(int memory, int min);

  /// No description provided for @sysVmConfigReviewBootloader.
  ///
  /// In en, this message translates to:
  /// **'Bootloader'**
  String get sysVmConfigReviewBootloader;

  /// No description provided for @sysVmConfigReviewCpuMode.
  ///
  /// In en, this message translates to:
  /// **'CPU mode'**
  String get sysVmConfigReviewCpuMode;

  /// No description provided for @sysVmConfigReviewAutostart.
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get sysVmConfigReviewAutostart;

  /// No description provided for @sysVmConfigEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sysVmConfigEnabled;

  /// No description provided for @sysVmConfigDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sysVmConfigDisabled;

  /// No description provided for @sysVmConfigReviewShutdown.
  ///
  /// In en, this message translates to:
  /// **'Shutdown'**
  String get sysVmConfigReviewShutdown;

  /// No description provided for @sysVmConfigReviewShutdownValue.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String sysVmConfigReviewShutdownValue(int seconds);

  /// No description provided for @sysVmConfigNoFieldsChanged.
  ///
  /// In en, this message translates to:
  /// **'No fields changed. The VM keeps its current configuration.'**
  String get sysVmConfigNoFieldsChanged;

  /// No description provided for @sysVmConfigApplyNotice.
  ///
  /// In en, this message translates to:
  /// **'Memory and CPU changes take effect on the next start. {apply}'**
  String sysVmConfigApplyNotice(String apply);

  /// No description provided for @sysVmConfigApplyRunning.
  ///
  /// In en, this message translates to:
  /// **'{name} is currently running; restart it to apply.'**
  String sysVmConfigApplyRunning(String name);

  /// No description provided for @sysVmConfigApplyStart.
  ///
  /// In en, this message translates to:
  /// **'Start the VM to apply.'**
  String get sysVmConfigApplyStart;

  /// No description provided for @sysVmConfigChangedFields.
  ///
  /// In en, this message translates to:
  /// **'Changed fields'**
  String get sysVmConfigChangedFields;

  /// No description provided for @sysVmConfigValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a VM name.'**
  String get sysVmConfigValidationNameRequired;

  /// No description provided for @sysVmConfigValidationVcpusMinimum.
  ///
  /// In en, this message translates to:
  /// **'Use at least 1 virtual CPU.'**
  String get sysVmConfigValidationVcpusMinimum;

  /// No description provided for @sysVmConfigValidationCoresMinimum.
  ///
  /// In en, this message translates to:
  /// **'Use at least 1 core per socket.'**
  String get sysVmConfigValidationCoresMinimum;

  /// No description provided for @sysVmConfigValidationThreadsMinimum.
  ///
  /// In en, this message translates to:
  /// **'Use at least 1 thread per core.'**
  String get sysVmConfigValidationThreadsMinimum;

  /// No description provided for @sysVmConfigValidationMemoryMinimum.
  ///
  /// In en, this message translates to:
  /// **'Allocate at least 128 MiB of memory.'**
  String get sysVmConfigValidationMemoryMinimum;

  /// No description provided for @sysVmConfigValidationMinMemoryExceeds.
  ///
  /// In en, this message translates to:
  /// **'Minimum memory cannot exceed memory.'**
  String get sysVmConfigValidationMinMemoryExceeds;

  /// No description provided for @sysVmConfigValidationShutdownTimeoutRange.
  ///
  /// In en, this message translates to:
  /// **'Shutdown timeout must be between 5 and 300 seconds.'**
  String get sysVmConfigValidationShutdownTimeoutRange;

  /// No description provided for @sysVmBootloaderUefi.
  ///
  /// In en, this message translates to:
  /// **'UEFI'**
  String get sysVmBootloaderUefi;

  /// No description provided for @sysVmBootloaderUefiCsm.
  ///
  /// In en, this message translates to:
  /// **'UEFI_CSM'**
  String get sysVmBootloaderUefiCsm;

  /// No description provided for @sysVmBootloaderGrub.
  ///
  /// In en, this message translates to:
  /// **'GRUB'**
  String get sysVmBootloaderGrub;

  /// No description provided for @sysVmCpuModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get sysVmCpuModeCustom;

  /// No description provided for @sysVmCpuModeHostModel.
  ///
  /// In en, this message translates to:
  /// **'Host model'**
  String get sysVmCpuModeHostModel;

  /// No description provided for @sysVmCpuModeHostPassthrough.
  ///
  /// In en, this message translates to:
  /// **'Host passthrough'**
  String get sysVmCpuModeHostPassthrough;

  /// No description provided for @sysContainerConfigReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get sysContainerConfigReviewTitle;

  /// No description provided for @sysContainerConfigEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit container'**
  String get sysContainerConfigEditTitle;

  /// No description provided for @sysContainerConfigClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sysContainerConfigClose;

  /// No description provided for @sysContainerConfigBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get sysContainerConfigBack;

  /// No description provided for @sysContainerConfigCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sysContainerConfigCancel;

  /// No description provided for @sysContainerConfigReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get sysContainerConfigReview;

  /// No description provided for @sysContainerConfigSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get sysContainerConfigSaveChanges;

  /// No description provided for @sysContainerConfigNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysContainerConfigNameLabel;

  /// No description provided for @sysContainerConfigDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysContainerConfigDescriptionLabel;

  /// No description provided for @sysContainerConfigDatasetLabel.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get sysContainerConfigDatasetLabel;

  /// No description provided for @sysContainerConfigDatasetHelper.
  ///
  /// In en, this message translates to:
  /// **'The dataset is fixed for an existing container.'**
  String get sysContainerConfigDatasetHelper;

  /// No description provided for @sysContainerConfigResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get sysContainerConfigResourcesTitle;

  /// No description provided for @sysContainerConfigVcpusLabel.
  ///
  /// In en, this message translates to:
  /// **'vCPUs (optional)'**
  String get sysContainerConfigVcpusLabel;

  /// No description provided for @sysContainerConfigVcpusHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for no CPU limit.'**
  String get sysContainerConfigVcpusHelper;

  /// No description provided for @sysContainerConfigMemoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory limit (MiB, optional)'**
  String get sysContainerConfigMemoryLabel;

  /// No description provided for @sysContainerConfigMemoryHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank for no memory limit.'**
  String get sysContainerConfigMemoryHelper;

  /// No description provided for @sysContainerConfigBehaviourTitle.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get sysContainerConfigBehaviourTitle;

  /// No description provided for @sysContainerConfigAutostartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get sysContainerConfigAutostartTitle;

  /// No description provided for @sysContainerConfigAutostartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts the container when the server starts.'**
  String get sysContainerConfigAutostartSubtitle;

  /// No description provided for @sysContainerConfigPreservedNotice.
  ///
  /// In en, this message translates to:
  /// **'Devices ({devices}), volumes ({volumes}), and environment ({env}) are preserved from the current container and sent unchanged. Editing them is not available in this release.'**
  String sysContainerConfigPreservedNotice(int devices, int volumes, int env);

  /// No description provided for @sysContainerConfigVolumesEnvNotice.
  ///
  /// In en, this message translates to:
  /// **'Volumes ({volumes}) and environment ({env}) are preserved from the current container and sent unchanged.'**
  String sysContainerConfigVolumesEnvNotice(int volumes, int env);

  /// No description provided for @sysContainerConfigDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get sysContainerConfigDevicesTitle;

  /// No description provided for @sysContainerConfigDevicesHelper.
  ///
  /// In en, this message translates to:
  /// **'Block devices passed through to the container. Added devices use the 25.10 passthrough shape; removal re-sends the remaining list.'**
  String get sysContainerConfigDevicesHelper;

  /// No description provided for @sysContainerConfigNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices attached.'**
  String get sysContainerConfigNoDevices;

  /// No description provided for @sysContainerConfigDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device {index}'**
  String sysContainerConfigDeviceLabel(int index);

  /// No description provided for @sysContainerConfigAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get sysContainerConfigAddDevice;

  /// No description provided for @sysContainerConfigRemoveDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove device'**
  String get sysContainerConfigRemoveDevice;

  /// No description provided for @sysContainerConfigAddDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get sysContainerConfigAddDeviceTitle;

  /// No description provided for @sysContainerConfigAddDeviceHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a host device to pass through to the container. TrueDock sends it using the 25.10 passthrough shape.'**
  String get sysContainerConfigAddDeviceHelper;

  /// No description provided for @sysContainerConfigReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sysContainerConfigReviewName;

  /// No description provided for @sysContainerConfigReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sysContainerConfigReviewDescription;

  /// No description provided for @sysContainerConfigReviewDescriptionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sysContainerConfigReviewDescriptionNone;

  /// No description provided for @sysContainerConfigReviewDataset.
  ///
  /// In en, this message translates to:
  /// **'Dataset'**
  String get sysContainerConfigReviewDataset;

  /// No description provided for @sysContainerConfigReviewVcpus.
  ///
  /// In en, this message translates to:
  /// **'vCPUs'**
  String get sysContainerConfigReviewVcpus;

  /// No description provided for @sysContainerConfigReviewVcpusNone.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get sysContainerConfigReviewVcpusNone;

  /// No description provided for @sysContainerConfigReviewMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get sysContainerConfigReviewMemory;

  /// No description provided for @sysContainerConfigReviewMemoryNone.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get sysContainerConfigReviewMemoryNone;

  /// No description provided for @sysContainerConfigReviewMemoryValue.
  ///
  /// In en, this message translates to:
  /// **'{memory} MiB'**
  String sysContainerConfigReviewMemoryValue(int memory);

  /// No description provided for @sysContainerConfigReviewAutostart.
  ///
  /// In en, this message translates to:
  /// **'Autostart'**
  String get sysContainerConfigReviewAutostart;

  /// No description provided for @sysContainerConfigReviewAutostartEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sysContainerConfigReviewAutostartEnabled;

  /// No description provided for @sysContainerConfigReviewAutostartDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sysContainerConfigReviewAutostartDisabled;

  /// No description provided for @sysContainerConfigReviewDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get sysContainerConfigReviewDevices;

  /// No description provided for @sysContainerConfigReviewDevicesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} preserved'**
  String sysContainerConfigReviewDevicesValue(int count);

  /// No description provided for @sysContainerConfigReviewVolumes.
  ///
  /// In en, this message translates to:
  /// **'Volumes'**
  String get sysContainerConfigReviewVolumes;

  /// No description provided for @sysContainerConfigReviewVolumesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} preserved'**
  String sysContainerConfigReviewVolumesValue(int count);

  /// No description provided for @sysContainerConfigReviewNoticeBase.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS replaces the whole container config. Devices, volumes, and environment are sent unchanged from the current container.'**
  String get sysContainerConfigReviewNoticeBase;

  /// No description provided for @sysContainerConfigReviewNoticeRunning.
  ///
  /// In en, this message translates to:
  /// **'{name} is running; restart it to apply.'**
  String sysContainerConfigReviewNoticeRunning(Object name);

  /// No description provided for @sysContainerConfigReviewNoticeStart.
  ///
  /// In en, this message translates to:
  /// **'Start the container to apply.'**
  String get sysContainerConfigReviewNoticeStart;

  /// No description provided for @sysContainerConfigValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a container name.'**
  String get sysContainerConfigValidationNameRequired;

  /// No description provided for @sysContainerConfigValidationDatasetRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a dataset path.'**
  String get sysContainerConfigValidationDatasetRequired;

  /// No description provided for @sysContainerConfigValidationVcpusMinimum.
  ///
  /// In en, this message translates to:
  /// **'Use at least 1 virtual CPU.'**
  String get sysContainerConfigValidationVcpusMinimum;

  /// No description provided for @sysContainerConfigValidationMemoryMinimum.
  ///
  /// In en, this message translates to:
  /// **'Allocate at least 16 MiB of memory.'**
  String get sysContainerConfigValidationMemoryMinimum;

  /// No description provided for @coreDestructiveServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get coreDestructiveServerLabel;

  /// No description provided for @coreDestructiveTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get coreDestructiveTargetLabel;

  /// No description provided for @coreDestructiveConsequencesTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get coreDestructiveConsequencesTitle;

  /// No description provided for @coreDestructiveCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Type {name} to continue.'**
  String coreDestructiveCannotBeUndone(Object name);

  /// No description provided for @coreDestructiveConfirmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm name'**
  String get coreDestructiveConfirmNameLabel;

  /// No description provided for @coreDestructiveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coreDestructiveCancel;

  /// No description provided for @storageRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename dataset'**
  String get storageRenameTitle;

  /// No description provided for @storageRenameNewNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get storageRenameNewNameLabel;

  /// No description provided for @storageRenameRecursiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename child datasets'**
  String get storageRenameRecursiveTitle;

  /// No description provided for @storageRenameRecursiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies the new path to every dataset underneath.'**
  String get storageRenameRecursiveSubtitle;

  /// No description provided for @storageRenameNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS unmounts the dataset while it renames it. Shares, apps, and tasks that reference the old path keep pointing at it and must be updated separately.'**
  String get storageRenameNotice;

  /// No description provided for @storageRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename dataset'**
  String get storageRenameAction;

  /// No description provided for @storageRenameCodeRenameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a new dataset name.'**
  String get storageRenameCodeRenameEmpty;

  /// No description provided for @storageRenameCodeRenameContainsSlash.
  ///
  /// In en, this message translates to:
  /// **'A dataset name cannot contain \"/\".'**
  String get storageRenameCodeRenameContainsSlash;

  /// No description provided for @storageRenameCodeRenamePoolRoot.
  ///
  /// In en, this message translates to:
  /// **'A pool root dataset cannot be renamed.'**
  String get storageRenameCodeRenamePoolRoot;

  /// No description provided for @storageRenameCodeRenameUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Enter a name different from the current one.'**
  String get storageRenameCodeRenameUnchanged;

  /// No description provided for @storageDatasetCodeEditNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing has changed for this dataset.'**
  String get storageDatasetCodeEditNothingChanged;

  /// No description provided for @storageDatasetTileActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dataset actions'**
  String get storageDatasetTileActionsTooltip;

  /// No description provided for @storageDatasetTileUsed.
  ///
  /// In en, this message translates to:
  /// **'{bytes} used'**
  String storageDatasetTileUsed(Object bytes);

  /// No description provided for @storageDatasetTileAvailable.
  ///
  /// In en, this message translates to:
  /// **'{bytes} available'**
  String storageDatasetTileAvailable(Object bytes);

  /// No description provided for @storageDatasetTileQuota.
  ///
  /// In en, this message translates to:
  /// **'quota {bytes}'**
  String storageDatasetTileQuota(Object bytes);

  /// No description provided for @storageDatasetTileReadOnly.
  ///
  /// In en, this message translates to:
  /// **'read-only'**
  String get storageDatasetTileReadOnly;

  /// No description provided for @storageDatasetTileClone.
  ///
  /// In en, this message translates to:
  /// **'clone'**
  String get storageDatasetTileClone;

  /// No description provided for @storageDatasetTileTakeSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Take snapshot'**
  String get storageDatasetTileTakeSnapshot;

  /// No description provided for @storageDatasetTileEditProperties.
  ///
  /// In en, this message translates to:
  /// **'Edit properties'**
  String get storageDatasetTileEditProperties;

  /// No description provided for @storageDatasetTileQuotas.
  ///
  /// In en, this message translates to:
  /// **'User and group quotas'**
  String get storageDatasetTileQuotas;

  /// No description provided for @storageDatasetTileManageAcl.
  ///
  /// In en, this message translates to:
  /// **'Manage ACL'**
  String get storageDatasetTileManageAcl;

  /// No description provided for @storageDatasetAclTitle.
  ///
  /// In en, this message translates to:
  /// **'Dataset ACL'**
  String get storageDatasetAclTitle;

  /// No description provided for @storageDatasetAclReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review ACL changes'**
  String get storageDatasetAclReviewTitle;

  /// No description provided for @storageDatasetAclType.
  ///
  /// In en, this message translates to:
  /// **'ACL type: {type}'**
  String storageDatasetAclType(Object type);

  /// No description provided for @storageDatasetAclOwnership.
  ///
  /// In en, this message translates to:
  /// **'Ownership'**
  String get storageDatasetAclOwnership;

  /// No description provided for @storageDatasetAclPermissionType.
  ///
  /// In en, this message translates to:
  /// **'Permission type'**
  String get storageDatasetAclPermissionType;

  /// No description provided for @storageDatasetAclPosix.
  ///
  /// In en, this message translates to:
  /// **'POSIX'**
  String get storageDatasetAclPosix;

  /// No description provided for @storageDatasetAclTrueNas.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS ACL'**
  String get storageDatasetAclTrueNas;

  /// No description provided for @storageDatasetAclTypeConversionWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing ACL type rebuilds the rules in the selected format. Named users and groups keep their basic access level, but deny and inheritance details that have no equivalent are replaced.'**
  String get storageDatasetAclTypeConversionWarning;

  /// No description provided for @storageDatasetAclTypeChangeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Change ACL type?'**
  String get storageDatasetAclTypeChangeWarningTitle;

  /// No description provided for @storageDatasetAclTypeChangeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Change from {from} to {to}? Existing rules will be rebuilt in the new format. Named users and groups keep their basic access level, but incompatible deny, default, and inheritance details can be replaced.'**
  String storageDatasetAclTypeChangeWarningBody(String from, String to);

  /// No description provided for @storageDatasetAclChangeTypeAction.
  ///
  /// In en, this message translates to:
  /// **'Change ACL type'**
  String get storageDatasetAclChangeTypeAction;

  /// No description provided for @storageDatasetAclConfirmOwnership.
  ///
  /// In en, this message translates to:
  /// **'Ownership changes to {user} : {group}.'**
  String storageDatasetAclConfirmOwnership(String user, String group);

  /// No description provided for @storageDatasetAclConfirmTypeChange.
  ///
  /// In en, this message translates to:
  /// **'ACL type changes from {from} to {to}; rules without an exact equivalent are rebuilt.'**
  String storageDatasetAclConfirmTypeChange(String from, String to);

  /// No description provided for @storageDatasetAclRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove rule'**
  String get storageDatasetAclRemove;

  /// No description provided for @storageDatasetAclAdd.
  ///
  /// In en, this message translates to:
  /// **'Add user or group'**
  String get storageDatasetAclAdd;

  /// No description provided for @storageDatasetAclChoosePrincipal.
  ///
  /// In en, this message translates to:
  /// **'Choose {type}'**
  String storageDatasetAclChoosePrincipal(String type);

  /// No description provided for @storageDatasetAclSearchPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Search {type}'**
  String storageDatasetAclSearchPrincipal(String type);

  /// No description provided for @storageDatasetAclPrincipalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No accounts} =1{1 account} other{{count} accounts}}'**
  String storageDatasetAclPrincipalCount(int count);

  /// No description provided for @storageDatasetAclNoPrincipals.
  ///
  /// In en, this message translates to:
  /// **'No {type} matches this search.'**
  String storageDatasetAclNoPrincipals(String type);

  /// No description provided for @storageDatasetAclRecursive.
  ///
  /// In en, this message translates to:
  /// **'Apply recursively'**
  String get storageDatasetAclRecursive;

  /// No description provided for @storageDatasetAclRecursiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace ACLs on child files and directories.'**
  String get storageDatasetAclRecursiveSubtitle;

  /// No description provided for @storageDatasetAclRecursiveWarning.
  ///
  /// In en, this message translates to:
  /// **'Existing permissions on child files and directories will be replaced.'**
  String get storageDatasetAclRecursiveWarning;

  /// No description provided for @storageDatasetAclTraverse.
  ///
  /// In en, this message translates to:
  /// **'Traverse'**
  String get storageDatasetAclTraverse;

  /// No description provided for @storageDatasetAclNone.
  ///
  /// In en, this message translates to:
  /// **'No permissions'**
  String get storageDatasetAclNone;

  /// No description provided for @storageDatasetAclRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get storageDatasetAclRead;

  /// No description provided for @storageDatasetAclWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get storageDatasetAclWrite;

  /// No description provided for @storageDatasetAclExecute.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get storageDatasetAclExecute;

  /// No description provided for @storageDatasetAclModify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get storageDatasetAclModify;

  /// No description provided for @storageDatasetAclFullControl.
  ///
  /// In en, this message translates to:
  /// **'Full control'**
  String get storageDatasetAclFullControl;

  /// No description provided for @storageDatasetAclRuleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ACL rules'**
  String storageDatasetAclRuleCount(int count);

  /// No description provided for @storageDatasetAclLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dataset ACL.'**
  String get storageDatasetAclLoadFailed;

  /// No description provided for @storageDatasetAclSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the dataset ACL.'**
  String get storageDatasetAclSaveFailed;

  /// No description provided for @storageDatasetAclSetAclError.
  ///
  /// In en, this message translates to:
  /// **'setacl error\n{detail}'**
  String storageDatasetAclSetAclError(String detail);

  /// No description provided for @storageDatasetAclPoolMountpointError.
  ///
  /// In en, this message translates to:
  /// **'The specified path is a ZFS pool mountpoint. ({path})'**
  String storageDatasetAclPoolMountpointError(String path);

  /// No description provided for @storageDatasetAclTypeChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the dataset ACL type. The new ACL rules were not applied.'**
  String get storageDatasetAclTypeChangeFailed;

  /// No description provided for @storageDatasetAclSaved.
  ///
  /// In en, this message translates to:
  /// **'Dataset ACL saved.'**
  String get storageDatasetAclSaved;

  /// No description provided for @storageDatasetAclConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply ACL changes?'**
  String get storageDatasetAclConfirmTitle;

  /// No description provided for @storageDatasetAclConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Apply ACL'**
  String get storageDatasetAclConfirmAction;

  /// No description provided for @storageDatasetAclConfirmRules.
  ///
  /// In en, this message translates to:
  /// **'The dataset ACL will be replaced with {count} rules.'**
  String storageDatasetAclConfirmRules(int count);

  /// No description provided for @storageDatasetAclConfirmRecursive.
  ///
  /// In en, this message translates to:
  /// **'The ACL will also replace permissions on child files and directories.'**
  String get storageDatasetAclConfirmRecursive;

  /// No description provided for @storageDatasetAclConfirmDatasetOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the dataset root ACL will change.'**
  String get storageDatasetAclConfirmDatasetOnly;

  /// No description provided for @quotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Quotas on {dataset}'**
  String quotaTitle(String dataset);

  /// No description provided for @quotaSubjectUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get quotaSubjectUsers;

  /// No description provided for @quotaSubjectGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get quotaSubjectGroups;

  /// No description provided for @quotaNoneUsers.
  ///
  /// In en, this message translates to:
  /// **'No user has written to this dataset yet.'**
  String get quotaNoneUsers;

  /// No description provided for @quotaNoneGroups.
  ///
  /// In en, this message translates to:
  /// **'No group has written to this dataset yet.'**
  String get quotaNoneGroups;

  /// No description provided for @quotaUsageOnly.
  ///
  /// In en, this message translates to:
  /// **'{used} used, no limit'**
  String quotaUsageOnly(String used);

  /// No description provided for @quotaSpaceOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit}'**
  String quotaSpaceOf(String used, String limit);

  /// No description provided for @quotaObjectsOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} files'**
  String quotaObjectsOf(String used, String limit);

  /// No description provided for @quotaObjectsOnly.
  ///
  /// In en, this message translates to:
  /// **'{used} files'**
  String quotaObjectsOnly(String used);

  /// No description provided for @quotaOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over limit'**
  String get quotaOverLimit;

  /// No description provided for @quotaAdd.
  ///
  /// In en, this message translates to:
  /// **'Set a quota'**
  String get quotaAdd;

  /// No description provided for @quotaEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Quota for {name}'**
  String quotaEditTitle(String name);

  /// No description provided for @quotaTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'User or group'**
  String get quotaTargetLabel;

  /// No description provided for @quotaTargetHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a name or a numeric id. The server rejects accounts it does not recognise.'**
  String get quotaTargetHelp;

  /// No description provided for @quotaSpaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Space limit'**
  String get quotaSpaceLabel;

  /// No description provided for @quotaObjectLabel.
  ///
  /// In en, this message translates to:
  /// **'File count limit (optional)'**
  String get quotaObjectLabel;

  /// No description provided for @quotaZeroRemoves.
  ///
  /// In en, this message translates to:
  /// **'Leave a field empty to keep it as it is. Enter 0 to remove that limit.'**
  String get quotaZeroRemoves;

  /// No description provided for @quotaApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get quotaApply;

  /// No description provided for @quotaRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the quota for {name}?'**
  String quotaRemoveTitle(String name);

  /// No description provided for @quotaRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove quota'**
  String get quotaRemoveAction;

  /// No description provided for @quotaRemoveConsequence.
  ///
  /// In en, this message translates to:
  /// **'{name} can write to this dataset without a limit again. Nothing already stored is deleted.'**
  String quotaRemoveConsequence(String name);

  /// No description provided for @quotaApplied.
  ///
  /// In en, this message translates to:
  /// **'Quota updated.'**
  String get quotaApplied;

  /// No description provided for @quotaFailed.
  ///
  /// In en, this message translates to:
  /// **'The quota could not be applied.'**
  String get quotaFailed;

  /// No description provided for @quotaValidationTarget.
  ///
  /// In en, this message translates to:
  /// **'Enter a user or group.'**
  String get quotaValidationTarget;

  /// No description provided for @quotaValidationReserved.
  ///
  /// In en, this message translates to:
  /// **'root cannot be given a quota; TrueNAS refuses it.'**
  String get quotaValidationReserved;

  /// No description provided for @quotaValidationNegative.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or a positive number.'**
  String get quotaValidationNegative;

  /// No description provided for @quotaValidationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set at least one limit.'**
  String get quotaValidationEmpty;

  /// No description provided for @quotaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The quotas could not be read.'**
  String get quotaLoadFailed;

  /// No description provided for @storageDatasetTileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get storageDatasetTileRename;

  /// No description provided for @storageDatasetTileUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get storageDatasetTileUnlock;

  /// No description provided for @storageDatasetTileLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get storageDatasetTileLock;

  /// No description provided for @storageDatasetTilePromoteClone.
  ///
  /// In en, this message translates to:
  /// **'Promote clone'**
  String get storageDatasetTilePromoteClone;

  /// No description provided for @storageDatasetTileDeleteDataset.
  ///
  /// In en, this message translates to:
  /// **'Delete dataset'**
  String get storageDatasetTileDeleteDataset;

  /// No description provided for @storageDiskPickerHelper.
  ///
  /// In en, this message translates to:
  /// **'Choose a disk that is not already part of a pool. Attaching or replacing starts a resilver; keep the pool online until it finishes.'**
  String get storageDiskPickerHelper;

  /// No description provided for @storageDiskPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No unused disks are available on this server.'**
  String get storageDiskPickerEmpty;

  /// No description provided for @storageDiskPickerSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search disks'**
  String get storageDiskPickerSearchLabel;

  /// No description provided for @storageDiskPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, serial, or model'**
  String get storageDiskPickerSearchHint;

  /// No description provided for @storageDiskPickerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageDiskPickerCancel;

  /// No description provided for @storageDiskPickerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get storageDiskPickerContinue;

  /// No description provided for @storageDiskPickerDiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{size} · {model} · {serial}'**
  String storageDiskPickerDiskSubtitle(
    Object size,
    Object model,
    Object serial,
  );

  /// No description provided for @storageDiskTempNormal.
  ///
  /// In en, this message translates to:
  /// **'{celsius} degrees Celsius'**
  String storageDiskTempNormal(int celsius);

  /// No description provided for @storageDiskTempOverLimit.
  ///
  /// In en, this message translates to:
  /// **'{celsius} degrees Celsius, over the drive limit'**
  String storageDiskTempOverLimit(int celsius);

  /// No description provided for @storageIscsiAuthMgmtTitle.
  ///
  /// In en, this message translates to:
  /// **'CHAP credentials'**
  String get storageIscsiAuthMgmtTitle;

  /// No description provided for @storageIscsiAuthMgmtSubtitle.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiator authentication entries. Target groups reference these by their tag. Secrets are write-only and never shown.'**
  String get storageIscsiAuthMgmtSubtitle;

  /// No description provided for @storageIscsiAuthMgmtEmpty.
  ///
  /// In en, this message translates to:
  /// **'No CHAP credentials are configured on this server.'**
  String get storageIscsiAuthMgmtEmpty;

  /// No description provided for @storageIscsiAuthMgmtEmptyUser.
  ///
  /// In en, this message translates to:
  /// **'(empty user)'**
  String get storageIscsiAuthMgmtEmptyUser;

  /// No description provided for @storageIscsiAuthMgmtTagSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tag {tag} · {mode}'**
  String storageIscsiAuthMgmtTagSubtitle(int tag, Object mode);

  /// No description provided for @storageIscsiAuthMgmtMutualChap.
  ///
  /// In en, this message translates to:
  /// **'Mutual CHAP'**
  String get storageIscsiAuthMgmtMutualChap;

  /// No description provided for @storageIscsiAuthMgmtOnewayChap.
  ///
  /// In en, this message translates to:
  /// **'One-way CHAP'**
  String get storageIscsiAuthMgmtOnewayChap;

  /// No description provided for @storageIscsiAuthMgmtEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get storageIscsiAuthMgmtEdit;

  /// No description provided for @storageIscsiAuthMgmtDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageIscsiAuthMgmtDelete;

  /// No description provided for @storageIscsiAuthMgmtNew.
  ///
  /// In en, this message translates to:
  /// **'New CHAP credential'**
  String get storageIscsiAuthMgmtNew;

  /// No description provided for @storageSmbAclReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review share permissions'**
  String get storageSmbAclReviewTitle;

  /// No description provided for @storageSmbAclFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions for {name}'**
  String storageSmbAclFormTitle(Object name);

  /// No description provided for @storageSmbAclClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageSmbAclClose;

  /// No description provided for @storageSmbAclBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageSmbAclBack;

  /// No description provided for @storageSmbAclCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageSmbAclCancel;

  /// No description provided for @storageSmbAclReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageSmbAclReview;

  /// No description provided for @storageSmbAclContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get storageSmbAclContinue;

  /// No description provided for @storageSmbAclCurrentPrincipals.
  ///
  /// In en, this message translates to:
  /// **'Current principals'**
  String get storageSmbAclCurrentPrincipals;

  /// No description provided for @storageSmbAclEmpty.
  ///
  /// In en, this message translates to:
  /// **'No permissions are set yet. Everyone with filesystem access can reach this share unless you add a rule.'**
  String get storageSmbAclEmpty;

  /// No description provided for @storageSmbAclAddPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Add a principal'**
  String get storageSmbAclAddPrincipal;

  /// No description provided for @storageSmbAclUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get storageSmbAclUser;

  /// No description provided for @storageSmbAclGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get storageSmbAclGroup;

  /// No description provided for @storageSmbAclAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get storageSmbAclAddToList;

  /// No description provided for @storageSmbAclDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'That principal is already in the list.'**
  String get storageSmbAclDuplicateError;

  /// No description provided for @storageSmbAclReviewServerAction.
  ///
  /// In en, this message translates to:
  /// **'Server action'**
  String get storageSmbAclReviewServerAction;

  /// No description provided for @storageSmbAclReviewServerActionValue.
  ///
  /// In en, this message translates to:
  /// **'Replace SMB share permissions'**
  String get storageSmbAclReviewServerActionValue;

  /// No description provided for @storageSmbAclReviewShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get storageSmbAclReviewShare;

  /// No description provided for @storageSmbAclReviewRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get storageSmbAclReviewRules;

  /// No description provided for @storageSmbAclReviewRulesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} principal(s)'**
  String storageSmbAclReviewRulesValue(int count);

  /// No description provided for @storageSmbAclReviewAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow {permission}'**
  String storageSmbAclReviewAllow(Object permission);

  /// No description provided for @storageSmbAclReviewDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny {permission}'**
  String storageSmbAclReviewDeny(Object permission);

  /// No description provided for @storageSmbAclPermRead.
  ///
  /// In en, this message translates to:
  /// **'read'**
  String get storageSmbAclPermRead;

  /// No description provided for @storageSmbAclPermChange.
  ///
  /// In en, this message translates to:
  /// **'change'**
  String get storageSmbAclPermChange;

  /// No description provided for @storageSmbAclPermFull.
  ///
  /// In en, this message translates to:
  /// **'full'**
  String get storageSmbAclPermFull;

  /// No description provided for @storageSmbAclReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Replacing the share permissions can revoke access for clients that currently use this share. The full list replaces the existing ACL.'**
  String get storageSmbAclReviewNotice;

  /// No description provided for @storageSmbAclRemoveFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get storageSmbAclRemoveFromList;

  /// No description provided for @storageSmbAclAllowRead.
  ///
  /// In en, this message translates to:
  /// **'Allow Read'**
  String get storageSmbAclAllowRead;

  /// No description provided for @storageSmbAclAllowChange.
  ///
  /// In en, this message translates to:
  /// **'Allow Change'**
  String get storageSmbAclAllowChange;

  /// No description provided for @storageSmbAclAllowFull.
  ///
  /// In en, this message translates to:
  /// **'Allow Full'**
  String get storageSmbAclAllowFull;

  /// No description provided for @storageSmbAclDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get storageSmbAclDeny;

  /// No description provided for @storageSmbAclPrincipalLabel.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get storageSmbAclPrincipalLabel;

  /// No description provided for @storageSmbAclNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No additional groups are available.'**
  String get storageSmbAclNoGroups;

  /// No description provided for @storageSmbAclNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No additional users are available.'**
  String get storageSmbAclNoUsers;

  /// No description provided for @storageNfsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review NFS share'**
  String get storageNfsReviewTitle;

  /// No description provided for @storageNfsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit NFS share'**
  String get storageNfsEditTitle;

  /// No description provided for @storageNfsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New NFS share'**
  String get storageNfsNewTitle;

  /// No description provided for @storageNfsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Network export and client identity mapping'**
  String get storageNfsSubtitle;

  /// No description provided for @storageNfsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageNfsClose;

  /// No description provided for @storageNfsBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageNfsBack;

  /// No description provided for @storageNfsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageNfsCancel;

  /// No description provided for @storageNfsReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageNfsReview;

  /// No description provided for @storageNfsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageNfsSaveChanges;

  /// No description provided for @storageNfsCreateShare.
  ///
  /// In en, this message translates to:
  /// **'Create share'**
  String get storageNfsCreateShare;

  /// No description provided for @storageNfsExportPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Export path'**
  String get storageNfsExportPathLabel;

  /// No description provided for @storageNfsExportPathHelper.
  ///
  /// In en, this message translates to:
  /// **'An existing path in a ZFS pool under /mnt/'**
  String get storageNfsExportPathHelper;

  /// No description provided for @storageNfsCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageNfsCommentLabel;

  /// No description provided for @storageNfsAuthorizedClients.
  ///
  /// In en, this message translates to:
  /// **'Authorized clients'**
  String get storageNfsAuthorizedClients;

  /// No description provided for @storageNfsNetworksLabel.
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get storageNfsNetworksLabel;

  /// No description provided for @storageNfsNetworksHelper.
  ///
  /// In en, this message translates to:
  /// **'One CIDR network per line · empty allows all networks'**
  String get storageNfsNetworksHelper;

  /// No description provided for @storageNfsHostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Individual hosts'**
  String get storageNfsHostsLabel;

  /// No description provided for @storageNfsHostsHelper.
  ///
  /// In en, this message translates to:
  /// **'One IP address or hostname per line'**
  String get storageNfsHostsHelper;

  /// No description provided for @storageNfsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get storageNfsSecurityTitle;

  /// No description provided for @storageNfsSecurityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No explicit schema; TrueNAS applies its default.'**
  String get storageNfsSecurityEmpty;

  /// No description provided for @storageNfsSecuritySelected.
  ///
  /// In en, this message translates to:
  /// **'Clients can negotiate any selected security schema.'**
  String get storageNfsSecuritySelected;

  /// No description provided for @storageNfsMappingTitle.
  ///
  /// In en, this message translates to:
  /// **'Client identity mapping'**
  String get storageNfsMappingTitle;

  /// No description provided for @storageNfsMappingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional root-user or all-user mapping'**
  String get storageNfsMappingSubtitle;

  /// No description provided for @storageNfsMapRoot.
  ///
  /// In en, this message translates to:
  /// **'Map root client identity'**
  String get storageNfsMapRoot;

  /// No description provided for @storageNfsMapAll.
  ///
  /// In en, this message translates to:
  /// **'Map every client identity'**
  String get storageNfsMapAll;

  /// No description provided for @storageNfsUserLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get storageNfsUserLabel;

  /// No description provided for @storageNfsGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get storageNfsGroupLabel;

  /// No description provided for @storageNfsReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get storageNfsReadOnlyTitle;

  /// No description provided for @storageNfsReadOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent NFS clients from changing files.'**
  String get storageNfsReadOnlySubtitle;

  /// No description provided for @storageNfsEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable share'**
  String get storageNfsEnableTitle;

  /// No description provided for @storageNfsEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publish the export through the NFS service.'**
  String get storageNfsEnableSubtitle;

  /// No description provided for @storageNfsEnterpriseNotice.
  ///
  /// In en, this message translates to:
  /// **'Snapshot directory exposure is an Enterprise-only value. TrueDock preserves the existing setting but cannot enable it on Community Edition.'**
  String get storageNfsEnterpriseNotice;

  /// No description provided for @storageNfsReviewPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get storageNfsReviewPath;

  /// No description provided for @storageNfsReviewClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get storageNfsReviewClients;

  /// No description provided for @storageNfsReviewClientsAll.
  ///
  /// In en, this message translates to:
  /// **'All networks and hosts'**
  String get storageNfsReviewClientsAll;

  /// No description provided for @storageNfsReviewAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get storageNfsReviewAccess;

  /// No description provided for @storageNfsReviewAccessReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get storageNfsReviewAccessReadOnly;

  /// No description provided for @storageNfsReviewAccessReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get storageNfsReviewAccessReadWrite;

  /// No description provided for @storageNfsReviewSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get storageNfsReviewSecurity;

  /// No description provided for @storageNfsReviewSecurityDefault.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get storageNfsReviewSecurityDefault;

  /// No description provided for @storageNfsReviewRootMapping.
  ///
  /// In en, this message translates to:
  /// **'Root mapping'**
  String get storageNfsReviewRootMapping;

  /// No description provided for @storageNfsReviewAllMapping.
  ///
  /// In en, this message translates to:
  /// **'All mapping'**
  String get storageNfsReviewAllMapping;

  /// No description provided for @storageNfsReviewState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get storageNfsReviewState;

  /// No description provided for @storageNfsReviewStateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get storageNfsReviewStateEnabled;

  /// No description provided for @storageNfsReviewStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get storageNfsReviewStateDisabled;

  /// No description provided for @storageNfsMappingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get storageNfsMappingNone;

  /// No description provided for @storageNfsMappingLabel.
  ///
  /// In en, this message translates to:
  /// **'{user} : {group}'**
  String storageNfsMappingLabel(Object user, Object group);

  /// No description provided for @storageNfsUnrestrictedNotice.
  ///
  /// In en, this message translates to:
  /// **'This writable export allows all networks unless filesystem permissions or another network control blocks access.'**
  String get storageNfsUnrestrictedNotice;

  /// No description provided for @storageNfsMapAllRootNotice.
  ///
  /// In en, this message translates to:
  /// **'All NFS client users will be mapped to root. Verify that this broad privilege is intentional.'**
  String get storageNfsMapAllRootNotice;

  /// No description provided for @storageNfsReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will validate the path, authorized clients, mappings, and NFS security configuration.'**
  String get storageNfsReviewNotice;

  /// No description provided for @storageNfsSecuritySys.
  ///
  /// In en, this message translates to:
  /// **'SYS'**
  String get storageNfsSecuritySys;

  /// No description provided for @storageNfsSecurityKrb5.
  ///
  /// In en, this message translates to:
  /// **'Kerberos'**
  String get storageNfsSecurityKrb5;

  /// No description provided for @storageNfsSecurityKrb5i.
  ///
  /// In en, this message translates to:
  /// **'Kerberos + integrity'**
  String get storageNfsSecurityKrb5i;

  /// No description provided for @storageNfsSecurityKrb5p.
  ///
  /// In en, this message translates to:
  /// **'Kerberos + privacy'**
  String get storageNfsSecurityKrb5p;

  /// No description provided for @storageNfsValidationPath.
  ///
  /// In en, this message translates to:
  /// **'Enter an existing path under /mnt/.'**
  String get storageNfsValidationPath;

  /// No description provided for @storageNfsValidationNetworksCount.
  ///
  /// In en, this message translates to:
  /// **'Use no more than 42 authorized networks.'**
  String get storageNfsValidationNetworksCount;

  /// No description provided for @storageNfsValidationNetworksFormat.
  ///
  /// In en, this message translates to:
  /// **'Use unique CIDR networks such as 10.0.0.0/24.'**
  String get storageNfsValidationNetworksFormat;

  /// No description provided for @storageNfsValidationHosts.
  ///
  /// In en, this message translates to:
  /// **'Use unique hostnames or IP addresses without spaces.'**
  String get storageNfsValidationHosts;

  /// No description provided for @storageNfsValidationMapping.
  ///
  /// In en, this message translates to:
  /// **'Choose either root mapping or all-user mapping.'**
  String get storageNfsValidationMapping;

  /// No description provided for @storageIscsiAuthReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review CHAP credential'**
  String get storageIscsiAuthReviewTitle;

  /// No description provided for @storageIscsiAuthEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit CHAP credential'**
  String get storageIscsiAuthEditTitle;

  /// No description provided for @storageIscsiAuthNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New CHAP credential'**
  String get storageIscsiAuthNewTitle;

  /// No description provided for @storageIscsiAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiator authentication'**
  String get storageIscsiAuthSubtitle;

  /// No description provided for @storageIscsiAuthListEmpty.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiator authentication · None configured'**
  String get storageIscsiAuthListEmpty;

  /// No description provided for @storageIscsiAuthListCount.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiator authentication · {count, plural, =1{1 credential} other{{count} credentials}}'**
  String storageIscsiAuthListCount(int count);

  /// No description provided for @storageIscsiAuthClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageIscsiAuthClose;

  /// No description provided for @storageIscsiAuthBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageIscsiAuthBack;

  /// No description provided for @storageIscsiAuthCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageIscsiAuthCancel;

  /// No description provided for @storageIscsiAuthReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageIscsiAuthReview;

  /// No description provided for @storageIscsiAuthSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageIscsiAuthSaveChanges;

  /// No description provided for @storageIscsiAuthCreateCredential.
  ///
  /// In en, this message translates to:
  /// **'Create credential'**
  String get storageIscsiAuthCreateCredential;

  /// No description provided for @storageIscsiAuthChapUserLabel.
  ///
  /// In en, this message translates to:
  /// **'CHAP user'**
  String get storageIscsiAuthChapUserLabel;

  /// No description provided for @storageIscsiAuthChapUserHelper.
  ///
  /// In en, this message translates to:
  /// **'The username initiators must present.'**
  String get storageIscsiAuthChapUserHelper;

  /// No description provided for @storageIscsiAuthSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get storageIscsiAuthSecretLabel;

  /// No description provided for @storageIscsiAuthNewSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'New secret (optional)'**
  String get storageIscsiAuthNewSecretLabel;

  /// No description provided for @storageIscsiAuthSecretHelper.
  ///
  /// In en, this message translates to:
  /// **'The shared secret initiators use to authenticate.'**
  String get storageIscsiAuthSecretHelper;

  /// No description provided for @storageIscsiAuthNewSecretHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the existing secret.'**
  String get storageIscsiAuthNewSecretHelper;

  /// No description provided for @storageIscsiAuthShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get storageIscsiAuthShow;

  /// No description provided for @storageIscsiAuthHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get storageIscsiAuthHide;

  /// No description provided for @storageIscsiAuthConfirmSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm secret'**
  String get storageIscsiAuthConfirmSecretLabel;

  /// No description provided for @storageIscsiAuthConfirmNewSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new secret'**
  String get storageIscsiAuthConfirmNewSecretLabel;

  /// No description provided for @storageIscsiAuthConfirmNewSecretHelper.
  ///
  /// In en, this message translates to:
  /// **'Retype the new secret only when rotating it.'**
  String get storageIscsiAuthConfirmNewSecretHelper;

  /// No description provided for @storageIscsiAuthMutualTitle.
  ///
  /// In en, this message translates to:
  /// **'Mutual CHAP'**
  String get storageIscsiAuthMutualTitle;

  /// No description provided for @storageIscsiAuthMutualSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The target also authenticates to the initiator with a peer user and peer secret.'**
  String get storageIscsiAuthMutualSubtitle;

  /// No description provided for @storageIscsiAuthPeerUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Peer user'**
  String get storageIscsiAuthPeerUserLabel;

  /// No description provided for @storageIscsiAuthPeerUserHelper.
  ///
  /// In en, this message translates to:
  /// **'The username the target presents to the initiator.'**
  String get storageIscsiAuthPeerUserHelper;

  /// No description provided for @storageIscsiAuthPeerSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Peer secret'**
  String get storageIscsiAuthPeerSecretLabel;

  /// No description provided for @storageIscsiAuthNewPeerSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'New peer secret (optional)'**
  String get storageIscsiAuthNewPeerSecretLabel;

  /// No description provided for @storageIscsiAuthNewPeerSecretHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the existing peer secret.'**
  String get storageIscsiAuthNewPeerSecretHelper;

  /// No description provided for @storageIscsiAuthConfirmPeerSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm peer secret'**
  String get storageIscsiAuthConfirmPeerSecretLabel;

  /// No description provided for @storageIscsiAuthConfirmNewPeerSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new peer secret'**
  String get storageIscsiAuthConfirmNewPeerSecretLabel;

  /// No description provided for @storageIscsiAuthConfirmNewPeerSecretHelper.
  ///
  /// In en, this message translates to:
  /// **'Retype the new peer secret only when rotating it.'**
  String get storageIscsiAuthConfirmNewPeerSecretHelper;

  /// No description provided for @storageIscsiAuthSecretsNotice.
  ///
  /// In en, this message translates to:
  /// **'Secrets are sent only to the connected TrueNAS server over this session. TrueDock does not save, log, or autofill them.'**
  String get storageIscsiAuthSecretsNotice;

  /// No description provided for @storageIscsiAuthReviewTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get storageIscsiAuthReviewTag;

  /// No description provided for @storageIscsiAuthReviewChapUser.
  ///
  /// In en, this message translates to:
  /// **'CHAP user'**
  String get storageIscsiAuthReviewChapUser;

  /// No description provided for @storageIscsiAuthReviewSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get storageIscsiAuthReviewSecret;

  /// No description provided for @storageIscsiAuthReviewSecretUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get storageIscsiAuthReviewSecretUnchanged;

  /// No description provided for @storageIscsiAuthReviewSecretSet.
  ///
  /// In en, this message translates to:
  /// **'Set · {count} characters'**
  String storageIscsiAuthReviewSecretSet(int count);

  /// No description provided for @storageIscsiAuthReviewMutual.
  ///
  /// In en, this message translates to:
  /// **'Mutual CHAP'**
  String get storageIscsiAuthReviewMutual;

  /// No description provided for @storageIscsiAuthReviewYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get storageIscsiAuthReviewYes;

  /// No description provided for @storageIscsiAuthReviewNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get storageIscsiAuthReviewNo;

  /// No description provided for @storageIscsiAuthReviewPeerUser.
  ///
  /// In en, this message translates to:
  /// **'Peer user'**
  String get storageIscsiAuthReviewPeerUser;

  /// No description provided for @storageIscsiAuthReviewPeerSecret.
  ///
  /// In en, this message translates to:
  /// **'Peer secret'**
  String get storageIscsiAuthReviewPeerSecret;

  /// No description provided for @storageIscsiAuthReviewNoticeEdit.
  ///
  /// In en, this message translates to:
  /// **'Targets and initiator groups that reference this credential start using the updated user and secret immediately. Initiators must be reconfigured to match.'**
  String get storageIscsiAuthReviewNoticeEdit;

  /// No description provided for @storageIscsiAuthReviewNoticeCreate.
  ///
  /// In en, this message translates to:
  /// **'Initiators presenting this user and secret can authenticate to target groups that reference this credential.'**
  String get storageIscsiAuthReviewNoticeCreate;

  /// No description provided for @storageIscsiAuthValidationUserRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a CHAP user.'**
  String get storageIscsiAuthValidationUserRequired;

  /// No description provided for @storageIscsiAuthValidationSecretRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a secret.'**
  String get storageIscsiAuthValidationSecretRequired;

  /// No description provided for @storageIscsiAuthValidationSecretMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two secrets do not match.'**
  String get storageIscsiAuthValidationSecretMismatch;

  /// No description provided for @storageIscsiAuthValidationPeerUserRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a peer user for mutual CHAP.'**
  String get storageIscsiAuthValidationPeerUserRequired;

  /// No description provided for @storageIscsiAuthValidationPeerSecretRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a peer secret for mutual CHAP.'**
  String get storageIscsiAuthValidationPeerSecretRequired;

  /// No description provided for @storageIscsiAuthValidationPeerSecretMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two peer secrets do not match.'**
  String get storageIscsiAuthValidationPeerSecretMismatch;

  /// No description provided for @storageIscsiExtentReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review iSCSI extent'**
  String get storageIscsiExtentReviewTitle;

  /// No description provided for @storageIscsiExtentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iSCSI extent'**
  String get storageIscsiExtentEditTitle;

  /// No description provided for @storageIscsiExtentNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New iSCSI extent'**
  String get storageIscsiExtentNewTitle;

  /// No description provided for @storageIscsiExtentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Storage presented through a target mapping'**
  String get storageIscsiExtentSubtitle;

  /// No description provided for @storageIscsiExtentClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageIscsiExtentClose;

  /// No description provided for @storageIscsiExtentBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageIscsiExtentBack;

  /// No description provided for @storageIscsiExtentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageIscsiExtentCancel;

  /// No description provided for @storageIscsiExtentReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageIscsiExtentReview;

  /// No description provided for @storageIscsiExtentSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageIscsiExtentSaveChanges;

  /// No description provided for @storageIscsiExtentCreateExtent.
  ///
  /// In en, this message translates to:
  /// **'Create extent'**
  String get storageIscsiExtentCreateExtent;

  /// No description provided for @storageIscsiExtentNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get storageIscsiExtentNameLabel;

  /// No description provided for @storageIscsiExtentNameHelper.
  ///
  /// In en, this message translates to:
  /// **'A unique name shown to iSCSI administrators'**
  String get storageIscsiExtentNameHelper;

  /// No description provided for @storageIscsiExtentCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiExtentCommentLabel;

  /// No description provided for @storageIscsiExtentCommentHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional description'**
  String get storageIscsiExtentCommentHelper;

  /// No description provided for @storageIscsiExtentBackingStore.
  ///
  /// In en, this message translates to:
  /// **'Backing store'**
  String get storageIscsiExtentBackingStore;

  /// No description provided for @storageIscsiExtentTypeDisk.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get storageIscsiExtentTypeDisk;

  /// No description provided for @storageIscsiExtentTypeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get storageIscsiExtentTypeFile;

  /// No description provided for @storageIscsiExtentDiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Disk or zvol'**
  String get storageIscsiExtentDiskLabel;

  /// No description provided for @storageIscsiExtentDiskHelper.
  ///
  /// In en, this message translates to:
  /// **'A current choice reported by this TrueNAS server'**
  String get storageIscsiExtentDiskHelper;

  /// No description provided for @storageIscsiExtentNoDiskChoices.
  ///
  /// In en, this message translates to:
  /// **'This server did not return an available disk or zvol for a new extent.'**
  String get storageIscsiExtentNoDiskChoices;

  /// No description provided for @storageIscsiExtentOldDiskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The previously selected disk or zvol is no longer offered by this server.'**
  String get storageIscsiExtentOldDiskUnavailable;

  /// No description provided for @storageIscsiExtentOldDiskUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'The previous backing store {disk} is no longer available. Select a current disk or zvol before saving.'**
  String storageIscsiExtentOldDiskUnavailableNotice(Object disk);

  /// No description provided for @storageIscsiExtentPathLabel.
  ///
  /// In en, this message translates to:
  /// **'File path'**
  String get storageIscsiExtentPathLabel;

  /// No description provided for @storageIscsiExtentPathHelper.
  ///
  /// In en, this message translates to:
  /// **'Absolute path under /mnt/'**
  String get storageIscsiExtentPathHelper;

  /// No description provided for @storageIscsiExtentFileAllocateNotice.
  ///
  /// In en, this message translates to:
  /// **'A file extent can allocate the requested space in its dataset when TrueNAS creates or grows the backing file.'**
  String get storageIscsiExtentFileAllocateNotice;

  /// No description provided for @storageIscsiExtentBackingChangeNotice.
  ///
  /// In en, this message translates to:
  /// **'Changing the extent type or backing store can disrupt target mappings and connected client I/O.'**
  String get storageIscsiExtentBackingChangeNotice;

  /// No description provided for @storageIscsiExtentFilesizeLabel.
  ///
  /// In en, this message translates to:
  /// **'File size (bytes)'**
  String get storageIscsiExtentFilesizeLabel;

  /// No description provided for @storageIscsiExtentFilesizeHelper.
  ///
  /// In en, this message translates to:
  /// **'0 uses the existing file size when supported'**
  String get storageIscsiExtentFilesizeHelper;

  /// No description provided for @storageIscsiExtentBlocksizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Logical block size'**
  String get storageIscsiExtentBlocksizeLabel;

  /// No description provided for @storageIscsiExtentRpmLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported drive speed'**
  String get storageIscsiExtentRpmLabel;

  /// No description provided for @storageIscsiExtentRpmUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get storageIscsiExtentRpmUnknown;

  /// No description provided for @storageIscsiExtentRpmSsd.
  ///
  /// In en, this message translates to:
  /// **'SSD'**
  String get storageIscsiExtentRpmSsd;

  /// No description provided for @storageIscsiExtentRpm5400.
  ///
  /// In en, this message translates to:
  /// **'5,400 RPM'**
  String get storageIscsiExtentRpm5400;

  /// No description provided for @storageIscsiExtentRpm7200.
  ///
  /// In en, this message translates to:
  /// **'7,200 RPM'**
  String get storageIscsiExtentRpm7200;

  /// No description provided for @storageIscsiExtentRpm10000.
  ///
  /// In en, this message translates to:
  /// **'10,000 RPM'**
  String get storageIscsiExtentRpm10000;

  /// No description provided for @storageIscsiExtentRpm15000.
  ///
  /// In en, this message translates to:
  /// **'15,000 RPM'**
  String get storageIscsiExtentRpm15000;

  /// No description provided for @storageIscsiExtentReadOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get storageIscsiExtentReadOnlyTitle;

  /// No description provided for @storageIscsiExtentReadOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent initiators from writing to this extent.'**
  String get storageIscsiExtentReadOnlySubtitle;

  /// No description provided for @storageIscsiExtentEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get storageIscsiExtentEnabledTitle;

  /// No description provided for @storageIscsiExtentEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow target mappings to present this extent.'**
  String get storageIscsiExtentEnabledSubtitle;

  /// No description provided for @storageIscsiExtentAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get storageIscsiExtentAdvancedTitle;

  /// No description provided for @storageIscsiExtentAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protocol compatibility and device identity'**
  String get storageIscsiExtentAdvancedSubtitle;

  /// No description provided for @storageIscsiExtentPhysicalBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Report physical block size'**
  String get storageIscsiExtentPhysicalBlockTitle;

  /// No description provided for @storageIscsiExtentPhysicalBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expose the logical block size as physical.'**
  String get storageIscsiExtentPhysicalBlockSubtitle;

  /// No description provided for @storageIscsiExtentThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Available capacity threshold (%)'**
  String get storageIscsiExtentThresholdLabel;

  /// No description provided for @storageIscsiExtentThresholdHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional percentage from 1 to 99'**
  String get storageIscsiExtentThresholdHelper;

  /// No description provided for @storageIscsiExtentInsecureTpcTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow insecure TPC'**
  String get storageIscsiExtentInsecureTpcTitle;

  /// No description provided for @storageIscsiExtentInsecureTpcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permit third-party copy without credentials.'**
  String get storageIscsiExtentInsecureTpcSubtitle;

  /// No description provided for @storageIscsiExtentXenTitle.
  ///
  /// In en, this message translates to:
  /// **'Xen compatibility'**
  String get storageIscsiExtentXenTitle;

  /// No description provided for @storageIscsiExtentXenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use legacy Xen initiator compatibility.'**
  String get storageIscsiExtentXenSubtitle;

  /// No description provided for @storageIscsiExtentSerialLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get storageIscsiExtentSerialLabel;

  /// No description provided for @storageIscsiExtentSerialHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional SCSI serial number'**
  String get storageIscsiExtentSerialHelper;

  /// No description provided for @storageIscsiExtentProductIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get storageIscsiExtentProductIdLabel;

  /// No description provided for @storageIscsiExtentProductIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional SCSI product identifier, up to 16 characters'**
  String get storageIscsiExtentProductIdHelper;

  /// No description provided for @storageIscsiExtentReviewName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get storageIscsiExtentReviewName;

  /// No description provided for @storageIscsiExtentReviewType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get storageIscsiExtentReviewType;

  /// No description provided for @storageIscsiExtentReviewBackingStore.
  ///
  /// In en, this message translates to:
  /// **'Backing store'**
  String get storageIscsiExtentReviewBackingStore;

  /// No description provided for @storageIscsiExtentReviewFilesize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get storageIscsiExtentReviewFilesize;

  /// No description provided for @storageIscsiExtentReviewFilesizeValue.
  ///
  /// In en, this message translates to:
  /// **'{count} bytes'**
  String storageIscsiExtentReviewFilesizeValue(int count);

  /// No description provided for @storageIscsiExtentReviewBlocksize.
  ///
  /// In en, this message translates to:
  /// **'Logical block size'**
  String get storageIscsiExtentReviewBlocksize;

  /// No description provided for @storageIscsiExtentReviewBlocksizeValue.
  ///
  /// In en, this message translates to:
  /// **'{count} bytes'**
  String storageIscsiExtentReviewBlocksizeValue(int count);

  /// No description provided for @storageIscsiExtentReviewSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reported speed'**
  String get storageIscsiExtentReviewSpeed;

  /// No description provided for @storageIscsiExtentReviewReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get storageIscsiExtentReviewReadOnly;

  /// No description provided for @storageIscsiExtentReviewEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get storageIscsiExtentReviewEnabled;

  /// No description provided for @storageIscsiExtentReviewPhysicalBlock.
  ///
  /// In en, this message translates to:
  /// **'Physical block size'**
  String get storageIscsiExtentReviewPhysicalBlock;

  /// No description provided for @storageIscsiExtentReviewThreshold.
  ///
  /// In en, this message translates to:
  /// **'Capacity threshold'**
  String get storageIscsiExtentReviewThreshold;

  /// No description provided for @storageIscsiExtentReviewThresholdNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get storageIscsiExtentReviewThresholdNone;

  /// No description provided for @storageIscsiExtentReviewThresholdValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String storageIscsiExtentReviewThresholdValue(int value);

  /// No description provided for @storageIscsiExtentReviewInsecureTpc.
  ///
  /// In en, this message translates to:
  /// **'Insecure TPC'**
  String get storageIscsiExtentReviewInsecureTpc;

  /// No description provided for @storageIscsiExtentReviewXen.
  ///
  /// In en, this message translates to:
  /// **'Xen compatibility'**
  String get storageIscsiExtentReviewXen;

  /// No description provided for @storageIscsiExtentReviewSerial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get storageIscsiExtentReviewSerial;

  /// No description provided for @storageIscsiExtentReviewSerialAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get storageIscsiExtentReviewSerialAutomatic;

  /// No description provided for @storageIscsiExtentReviewProductId.
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get storageIscsiExtentReviewProductId;

  /// No description provided for @storageIscsiExtentReviewProductIdDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get storageIscsiExtentReviewProductIdDefault;

  /// No description provided for @storageIscsiExtentReviewComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiExtentReviewComment;

  /// No description provided for @storageIscsiExtentReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get storageIscsiExtentReviewNone;

  /// No description provided for @storageIscsiExtentReviewYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get storageIscsiExtentReviewYes;

  /// No description provided for @storageIscsiExtentReviewNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get storageIscsiExtentReviewNo;

  /// No description provided for @storageIscsiExtentBackingChangedNotice.
  ///
  /// In en, this message translates to:
  /// **'This changes the extent type or backing store. Existing target mappings can be disrupted; verify mapped LUNs and client I/O after saving.'**
  String get storageIscsiExtentBackingChangedNotice;

  /// No description provided for @storageIscsiExtentFileAllocateReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will use {path} and may allocate {bytes} bytes in that dataset.'**
  String storageIscsiExtentFileAllocateReviewNotice(Object path, int bytes);

  /// No description provided for @storageIscsiExtentReviewNoticeEdit.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will apply these values to {name}. Target associations remain in place unless the server rejects the update.'**
  String storageIscsiExtentReviewNoticeEdit(Object name);

  /// No description provided for @storageIscsiExtentReviewNoticeCreate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will create this extent. It will not be available to initiators until it is assigned to a target and LUN.'**
  String get storageIscsiExtentReviewNoticeCreate;

  /// No description provided for @storageIscsiExtentValidationNameLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a name between 1 and 64 characters.'**
  String get storageIscsiExtentValidationNameLength;

  /// No description provided for @storageIscsiExtentValidationDiskRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a disk or zvol.'**
  String get storageIscsiExtentValidationDiskRequired;

  /// No description provided for @storageIscsiExtentValidationDiskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select a disk or zvol offered by this server.'**
  String get storageIscsiExtentValidationDiskUnavailable;

  /// No description provided for @storageIscsiExtentValidationDiskPathConflict.
  ///
  /// In en, this message translates to:
  /// **'A disk extent cannot also use a file path.'**
  String get storageIscsiExtentValidationDiskPathConflict;

  /// No description provided for @storageIscsiExtentValidationPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a file path under /mnt/.'**
  String get storageIscsiExtentValidationPathRequired;

  /// No description provided for @storageIscsiExtentValidationFileDiskConflict.
  ///
  /// In en, this message translates to:
  /// **'A file extent cannot also use a disk.'**
  String get storageIscsiExtentValidationFileDiskConflict;

  /// No description provided for @storageIscsiExtentValidationFileSizeNegative.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative file size.'**
  String get storageIscsiExtentValidationFileSizeNegative;

  /// No description provided for @storageIscsiExtentValidationFileSizeWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of bytes.'**
  String get storageIscsiExtentValidationFileSizeWholeNumber;

  /// No description provided for @storageIscsiExtentValidationBlockSize.
  ///
  /// In en, this message translates to:
  /// **'Choose a supported block size.'**
  String get storageIscsiExtentValidationBlockSize;

  /// No description provided for @storageIscsiExtentValidationThresholdRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a threshold from 1 to 99 percent.'**
  String get storageIscsiExtentValidationThresholdRange;

  /// No description provided for @storageIscsiExtentValidationThresholdWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole-number percentage.'**
  String get storageIscsiExtentValidationThresholdWholeNumber;

  /// No description provided for @storageIscsiExtentValidationProductIdLength.
  ///
  /// In en, this message translates to:
  /// **'Enter a product ID between 1 and 16 characters.'**
  String get storageIscsiExtentValidationProductIdLength;

  /// No description provided for @storageIscsiTeReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review iSCSI association'**
  String get storageIscsiTeReviewTitle;

  /// No description provided for @storageIscsiTeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iSCSI association'**
  String get storageIscsiTeEditTitle;

  /// No description provided for @storageIscsiTeNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New iSCSI association'**
  String get storageIscsiTeNewTitle;

  /// No description provided for @storageIscsiTeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expose an extent through a target and LUN'**
  String get storageIscsiTeSubtitle;

  /// No description provided for @storageIscsiTeClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageIscsiTeClose;

  /// No description provided for @storageIscsiTeBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageIscsiTeBack;

  /// No description provided for @storageIscsiTeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageIscsiTeCancel;

  /// No description provided for @storageIscsiTeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageIscsiTeReview;

  /// No description provided for @storageIscsiTeSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageIscsiTeSaveChanges;

  /// No description provided for @storageIscsiTeCreateAssociation.
  ///
  /// In en, this message translates to:
  /// **'Create association'**
  String get storageIscsiTeCreateAssociation;

  /// No description provided for @storageIscsiTeTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get storageIscsiTeTargetLabel;

  /// No description provided for @storageIscsiTeTargetHelper.
  ///
  /// In en, this message translates to:
  /// **'Clients connect through this iSCSI target'**
  String get storageIscsiTeTargetHelper;

  /// No description provided for @storageIscsiTeExtentLabel.
  ///
  /// In en, this message translates to:
  /// **'Extent'**
  String get storageIscsiTeExtentLabel;

  /// No description provided for @storageIscsiTeExtentHelper.
  ///
  /// In en, this message translates to:
  /// **'The storage made available to clients'**
  String get storageIscsiTeExtentHelper;

  /// No description provided for @storageIscsiTeAutoLunTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign LUN automatically'**
  String get storageIscsiTeAutoLunTitle;

  /// No description provided for @storageIscsiTeAutoLunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let TrueNAS choose the next available LUN ID'**
  String get storageIscsiTeAutoLunSubtitle;

  /// No description provided for @storageIscsiTeLunIdLabel.
  ///
  /// In en, this message translates to:
  /// **'LUN ID'**
  String get storageIscsiTeLunIdLabel;

  /// No description provided for @storageIscsiTeLunIdHelperEdit.
  ///
  /// In en, this message translates to:
  /// **'A concrete nonnegative LUN ID is required when editing'**
  String get storageIscsiTeLunIdHelperEdit;

  /// No description provided for @storageIscsiTeLunIdHelperCreate.
  ///
  /// In en, this message translates to:
  /// **'Use an available nonnegative integer'**
  String get storageIscsiTeLunIdHelperCreate;

  /// No description provided for @storageIscsiTeMissingResourcesNotice.
  ///
  /// In en, this message translates to:
  /// **'The saved target or extent is no longer offered by this server. Select available resources before saving.'**
  String get storageIscsiTeMissingResourcesNotice;

  /// No description provided for @storageIscsiTeReviewTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get storageIscsiTeReviewTarget;

  /// No description provided for @storageIscsiTeReviewExtent.
  ///
  /// In en, this message translates to:
  /// **'Extent'**
  String get storageIscsiTeReviewExtent;

  /// No description provided for @storageIscsiTeReviewLunId.
  ///
  /// In en, this message translates to:
  /// **'LUN ID'**
  String get storageIscsiTeReviewLunId;

  /// No description provided for @storageIscsiTeReviewLunIdAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get storageIscsiTeReviewLunIdAutomatic;

  /// No description provided for @storageIscsiTeReviewAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get storageIscsiTeReviewAccess;

  /// No description provided for @storageIscsiTeReviewAccessReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get storageIscsiTeReviewAccessReadOnly;

  /// No description provided for @storageIscsiTeReviewAccessReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get storageIscsiTeReviewAccessReadWrite;

  /// No description provided for @storageIscsiTeImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get storageIscsiTeImpactTitle;

  /// No description provided for @storageIscsiTeImpactNoticeEdit.
  ///
  /// In en, this message translates to:
  /// **'Saving reassigns this association. Clients using the target may lose access to the previous mapping and see the updated LUN.'**
  String get storageIscsiTeImpactNoticeEdit;

  /// No description provided for @storageIscsiTeImpactNoticeCreate.
  ///
  /// In en, this message translates to:
  /// **'Creating this association makes the extent visible to initiators that are allowed to connect to the target.'**
  String get storageIscsiTeImpactNoticeCreate;

  /// No description provided for @storageIscsiTeExposureReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This association exposes the extent as read-only storage to authorized clients.'**
  String get storageIscsiTeExposureReadOnly;

  /// No description provided for @storageIscsiTeExposureReadWrite.
  ///
  /// In en, this message translates to:
  /// **'This association exposes the extent for read and write access to authorized clients.'**
  String get storageIscsiTeExposureReadWrite;

  /// No description provided for @storageIscsiTeExtentDisabledNotice.
  ///
  /// In en, this message translates to:
  /// **'The selected extent is disabled and will not serve storage until it is enabled.'**
  String get storageIscsiTeExtentDisabledNotice;

  /// No description provided for @storageIscsiTeExtentLockedNotice.
  ///
  /// In en, this message translates to:
  /// **'The selected extent is locked and cannot serve data until its backing storage is unlocked.'**
  String get storageIscsiTeExtentLockedNotice;

  /// No description provided for @storageIscsiTeValidationTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a valid iSCSI target.'**
  String get storageIscsiTeValidationTargetInvalid;

  /// No description provided for @storageIscsiTeValidationTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select a target offered by this TrueNAS server.'**
  String get storageIscsiTeValidationTargetUnavailable;

  /// No description provided for @storageIscsiTeValidationExtentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a valid iSCSI extent.'**
  String get storageIscsiTeValidationExtentInvalid;

  /// No description provided for @storageIscsiTeValidationExtentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select an extent offered by this TrueNAS server.'**
  String get storageIscsiTeValidationExtentUnavailable;

  /// No description provided for @storageIscsiTeValidationLunidNegative.
  ///
  /// In en, this message translates to:
  /// **'Use a nonnegative LUN ID.'**
  String get storageIscsiTeValidationLunidNegative;

  /// No description provided for @storageIscsiTeValidationLunidEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a nonnegative LUN ID.'**
  String get storageIscsiTeValidationLunidEmpty;

  /// No description provided for @storageIscsiTeValidationLunidWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a whole, nonnegative LUN ID.'**
  String get storageIscsiTeValidationLunidWholeNumber;

  /// No description provided for @storageIscsiConfigClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get storageIscsiConfigClose;

  /// No description provided for @storageIscsiConfigBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get storageIscsiConfigBack;

  /// No description provided for @storageIscsiConfigCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get storageIscsiConfigCancel;

  /// No description provided for @storageIscsiConfigReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get storageIscsiConfigReview;

  /// No description provided for @storageIscsiPortalReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review iSCSI portal'**
  String get storageIscsiPortalReviewTitle;

  /// No description provided for @storageIscsiPortalNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New iSCSI portal'**
  String get storageIscsiPortalNewTitle;

  /// No description provided for @storageIscsiPortalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iSCSI portal'**
  String get storageIscsiPortalEditTitle;

  /// No description provided for @storageIscsiPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Static addresses that receive iSCSI connections'**
  String get storageIscsiPortalSubtitle;

  /// No description provided for @storageIscsiPortalCreate.
  ///
  /// In en, this message translates to:
  /// **'Create portal'**
  String get storageIscsiPortalCreate;

  /// No description provided for @storageIscsiPortalSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageIscsiPortalSaveChanges;

  /// No description provided for @storageIscsiPortalListenAddresses.
  ///
  /// In en, this message translates to:
  /// **'Listen addresses'**
  String get storageIscsiPortalListenAddresses;

  /// No description provided for @storageIscsiPortalListenHelper.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS only offers static addresses that can host a portal.'**
  String get storageIscsiPortalListenHelper;

  /// No description provided for @storageIscsiPortalNoAddress.
  ///
  /// In en, this message translates to:
  /// **'This server did not return a static listen address. Configure a static interface address before creating a portal.'**
  String get storageIscsiPortalNoAddress;

  /// No description provided for @storageIscsiPortalUnavailableNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS no longer offers {addresses} as a static listen address. Select a current address before saving.'**
  String storageIscsiPortalUnavailableNotice(Object addresses);

  /// No description provided for @storageIscsiPortalCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiPortalCommentLabel;

  /// No description provided for @storageIscsiPortalCommentHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional label for this portal'**
  String get storageIscsiPortalCommentHelper;

  /// No description provided for @storageIscsiPortalUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'Targets using this portal will receive connections on the updated address set after TrueNAS applies the change.'**
  String get storageIscsiPortalUpdateNotice;

  /// No description provided for @storageIscsiPortalReviewListen.
  ///
  /// In en, this message translates to:
  /// **'Listen addresses'**
  String get storageIscsiPortalReviewListen;

  /// No description provided for @storageIscsiPortalReviewPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get storageIscsiPortalReviewPort;

  /// No description provided for @storageIscsiPortalReviewPortValue.
  ///
  /// In en, this message translates to:
  /// **'3260 (managed by TrueNAS)'**
  String get storageIscsiPortalReviewPortValue;

  /// No description provided for @storageIscsiPortalReviewComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiPortalReviewComment;

  /// No description provided for @storageIscsiPortalReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get storageIscsiPortalReviewNone;

  /// No description provided for @storageIscsiPortalReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'The portal only exposes a network endpoint. A target, extent, and LUN association are still required before storage is available to clients.'**
  String get storageIscsiPortalReviewNotice;

  /// No description provided for @storageIscsiPortalValidationListenRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one listen address.'**
  String get storageIscsiPortalValidationListenRequired;

  /// No description provided for @storageIscsiPortalValidationListenFormat.
  ///
  /// In en, this message translates to:
  /// **'Use unique valid IPv4 or IPv6 addresses.'**
  String get storageIscsiPortalValidationListenFormat;

  /// No description provided for @storageIscsiPortalValidationListenUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Select only addresses offered by this TrueNAS server.'**
  String get storageIscsiPortalValidationListenUnavailable;

  /// No description provided for @storageIscsiInitiatorReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review initiator group'**
  String get storageIscsiInitiatorReviewTitle;

  /// No description provided for @storageIscsiInitiatorNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New initiator group'**
  String get storageIscsiInitiatorNewTitle;

  /// No description provided for @storageIscsiInitiatorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit initiator group'**
  String get storageIscsiInitiatorEditTitle;

  /// No description provided for @storageIscsiInitiatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clients authorized to connect to an iSCSI target'**
  String get storageIscsiInitiatorSubtitle;

  /// No description provided for @storageIscsiInitiatorCreate.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get storageIscsiInitiatorCreate;

  /// No description provided for @storageIscsiInitiatorSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageIscsiInitiatorSaveChanges;

  /// No description provided for @storageIscsiInitiatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Authorized initiators'**
  String get storageIscsiInitiatorLabel;

  /// No description provided for @storageIscsiInitiatorHelper.
  ///
  /// In en, this message translates to:
  /// **'One IQN or IP address per line · empty allows every initiator'**
  String get storageIscsiInitiatorHelper;

  /// No description provided for @storageIscsiInitiatorCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiInitiatorCommentLabel;

  /// No description provided for @storageIscsiInitiatorCommentHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional label for this client group'**
  String get storageIscsiInitiatorCommentHelper;

  /// No description provided for @storageIscsiInitiatorUpdateNotice.
  ///
  /// In en, this message translates to:
  /// **'Changing this group affects every target group that references it.'**
  String get storageIscsiInitiatorUpdateNotice;

  /// No description provided for @storageIscsiInitiatorReviewClients.
  ///
  /// In en, this message translates to:
  /// **'Authorized clients'**
  String get storageIscsiInitiatorReviewClients;

  /// No description provided for @storageIscsiInitiatorReviewAll.
  ///
  /// In en, this message translates to:
  /// **'All initiators'**
  String get storageIscsiInitiatorReviewAll;

  /// No description provided for @storageIscsiInitiatorReviewComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get storageIscsiInitiatorReviewComment;

  /// No description provided for @storageIscsiInitiatorReviewNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get storageIscsiInitiatorReviewNone;

  /// No description provided for @storageIscsiInitiatorAllNotice.
  ///
  /// In en, this message translates to:
  /// **'This group allows every initiator. Access can still be constrained by target authentication and network controls.'**
  String get storageIscsiInitiatorAllNotice;

  /// No description provided for @storageIscsiInitiatorListedNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will authorize only the listed IQNs or IP addresses when this group is assigned to a target.'**
  String get storageIscsiInitiatorListedNotice;

  /// No description provided for @storageIscsiInitiatorValidationFormat.
  ///
  /// In en, this message translates to:
  /// **'Use unique IQNs or IP addresses without whitespace.'**
  String get storageIscsiInitiatorValidationFormat;

  /// No description provided for @appsInstallReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review installation'**
  String get appsInstallReviewTitle;

  /// No description provided for @appsInstallReconfigureTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure {name}'**
  String appsInstallReconfigureTitle(Object name);

  /// No description provided for @appsInstallInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install {title}'**
  String appsInstallInstallTitle(Object title);

  /// No description provided for @appsInstallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{train} · {version}'**
  String appsInstallSubtitle(Object train, Object version);

  /// No description provided for @appsInstallClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appsInstallClose;

  /// No description provided for @appsInstallBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get appsInstallBack;

  /// No description provided for @appsInstallCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get appsInstallCancel;

  /// No description provided for @appsInstallReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get appsInstallReview;

  /// No description provided for @appsInstallReconfigureAction.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure app'**
  String get appsInstallReconfigureAction;

  /// No description provided for @appsInstallInstallAction.
  ///
  /// In en, this message translates to:
  /// **'Install app'**
  String get appsInstallInstallAction;

  /// No description provided for @appsInstallDefaultGroup.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get appsInstallDefaultGroup;

  /// No description provided for @appsValidationNameFormat.
  ///
  /// In en, this message translates to:
  /// **'Use 1–40 lowercase letters, numbers, or internal hyphens.'**
  String get appsValidationNameFormat;

  /// No description provided for @appsValidationUnsupportedField.
  ///
  /// In en, this message translates to:
  /// **'This catalog field type is not supported.'**
  String get appsValidationUnsupportedField;

  /// No description provided for @appsValidationFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get appsValidationFieldRequired;

  /// No description provided for @appsValidationWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get appsValidationWholeNumber;

  /// No description provided for @appsValidationMinimumValue.
  ///
  /// In en, this message translates to:
  /// **'Minimum value is {bound}.'**
  String appsValidationMinimumValue(int bound);

  /// No description provided for @appsValidationMaximumValue.
  ///
  /// In en, this message translates to:
  /// **'Maximum value is {bound}.'**
  String appsValidationMaximumValue(int bound);

  /// No description provided for @appsValidationMinimumLength.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {bound} characters.'**
  String appsValidationMinimumLength(int bound);

  /// No description provided for @appsValidationMaximumLength.
  ///
  /// In en, this message translates to:
  /// **'Enter no more than {bound} characters.'**
  String appsValidationMaximumLength(int bound);

  /// No description provided for @appsValidationAbsolutePath.
  ///
  /// In en, this message translates to:
  /// **'Enter an absolute path beginning with /.'**
  String get appsValidationAbsolutePath;

  /// No description provided for @appsValidationUriScheme.
  ///
  /// In en, this message translates to:
  /// **'Enter a URI with a scheme.'**
  String get appsValidationUriScheme;

  /// No description provided for @appsValidationIpAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IPv4 or IPv6 address.'**
  String get appsValidationIpAddress;

  /// No description provided for @appsValidationChooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the available values.'**
  String get appsValidationChooseOption;

  /// No description provided for @appsValidationMinimumItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least {bound} items.'**
  String appsValidationMinimumItems(int bound);

  /// No description provided for @appsValidationMaximumItems.
  ///
  /// In en, this message translates to:
  /// **'Use no more than {bound} items.'**
  String appsValidationMaximumItems(int bound);

  /// No description provided for @appsValidationListNoSchema.
  ///
  /// In en, this message translates to:
  /// **'This list has no editable item schema.'**
  String get appsValidationListNoSchema;

  /// No description provided for @appsValidationItemRequired.
  ///
  /// In en, this message translates to:
  /// **'This item is required.'**
  String get appsValidationItemRequired;

  /// No description provided for @appsValidationItemWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get appsValidationItemWholeNumber;

  /// No description provided for @appsInstallInstanceInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'App instance'**
  String get appsInstallInstanceInfoLabel;

  /// No description provided for @appsInstallInstanceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App instance name'**
  String get appsInstallInstanceNameLabel;

  /// No description provided for @appsInstallInstanceNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers, and internal hyphens'**
  String get appsInstallInstanceNameHelper;

  /// No description provided for @appsInstallCatalogVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Catalog version'**
  String get appsInstallCatalogVersionLabel;

  /// No description provided for @appsInstallVersionUnavailableSuffix.
  ///
  /// In en, this message translates to:
  /// **' · unavailable'**
  String get appsInstallVersionUnavailableSuffix;

  /// No description provided for @appsInstallVersionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This catalog version is not supported by the connected server.'**
  String get appsInstallVersionUnsupported;

  /// No description provided for @appsInstallNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This app uses its catalog defaults and needs no additional configuration.'**
  String get appsInstallNoQuestions;

  /// No description provided for @appsInstallReviewServerAction.
  ///
  /// In en, this message translates to:
  /// **'Server action'**
  String get appsInstallReviewServerAction;

  /// No description provided for @appsInstallReviewActionReconfigure.
  ///
  /// In en, this message translates to:
  /// **'Reconfigure app'**
  String get appsInstallReviewActionReconfigure;

  /// No description provided for @appsInstallReviewActionInstall.
  ///
  /// In en, this message translates to:
  /// **'Install catalog app'**
  String get appsInstallReviewActionInstall;

  /// No description provided for @appsInstallReviewApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appsInstallReviewApp;

  /// No description provided for @appsInstallReviewInstance.
  ///
  /// In en, this message translates to:
  /// **'Instance'**
  String get appsInstallReviewInstance;

  /// No description provided for @appsInstallReviewTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get appsInstallReviewTrain;

  /// No description provided for @appsInstallReviewVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appsInstallReviewVersion;

  /// No description provided for @appsInstallReviewNoticeUpdate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will revalidate the configuration and recreate the app containers with the new values. Users lose access until the TrueNAS job completes.'**
  String get appsInstallReviewNoticeUpdate;

  /// No description provided for @appsInstallReviewNoticeInstall.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS will validate the configuration, pull container images, create app storage, and start the workload as a background Job.'**
  String get appsInstallReviewNoticeInstall;

  /// No description provided for @appsInstallSecretsNotice.
  ///
  /// In en, this message translates to:
  /// **'Sensitive values are masked and are sent only to the connected TrueNAS server. TrueDock does not save this installation form.'**
  String get appsInstallSecretsNotice;

  /// No description provided for @appsInstallListNoItemType.
  ///
  /// In en, this message translates to:
  /// **'This catalog list does not describe its item type.'**
  String get appsInstallListNoItemType;

  /// No description provided for @appsInstallRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get appsInstallRemoveItem;

  /// No description provided for @appsInstallAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get appsInstallAddItem;

  /// No description provided for @appsInstallSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get appsInstallSelect;

  /// No description provided for @appsInstallOptionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String appsInstallOptionCount(int count);

  /// No description provided for @appsInstallOptionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get appsInstallOptionSearch;

  /// No description provided for @appsInstallNoMatchingOptions.
  ///
  /// In en, this message translates to:
  /// **'No matching options.'**
  String get appsInstallNoMatchingOptions;

  /// No description provided for @jobsFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get jobsFilterActive;

  /// No description provided for @jobsActiveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Running jobs'**
  String get jobsActiveDialogTitle;

  /// No description provided for @jobsActiveFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Running jobs ({count})'**
  String jobsActiveFabTooltip(int count);

  /// No description provided for @jobsFilterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get jobsFilterFailed;

  /// No description provided for @jobsFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get jobsFilterCompleted;

  /// No description provided for @jobsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get jobsFilterAll;

  /// No description provided for @jobsFilterChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String jobsFilterChipLabel(Object label, int count);

  /// No description provided for @jobsEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No jobs are running.'**
  String get jobsEmptyActive;

  /// No description provided for @jobsEmptyFailed.
  ///
  /// In en, this message translates to:
  /// **'No failed jobs reported.'**
  String get jobsEmptyFailed;

  /// No description provided for @jobsEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'No completed jobs reported.'**
  String get jobsEmptyCompleted;

  /// No description provided for @jobsEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No jobs found.'**
  String get jobsEmptyAll;

  /// No description provided for @jobsAbortDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Abort this job?'**
  String get jobsAbortDialogTitle;

  /// No description provided for @jobsAbortDialogBody.
  ///
  /// In en, this message translates to:
  /// **'TrueDock will ask the server to abort job {id} ({method}). Work already performed by the job is not rolled back, and the server may complete the job before the abort is processed.'**
  String jobsAbortDialogBody(int id, Object method);

  /// No description provided for @jobsAbortTarget.
  ///
  /// In en, this message translates to:
  /// **'Job {id} ({method})'**
  String jobsAbortTarget(int id, Object method);

  /// No description provided for @jobsAbortConsequenceNoRollback.
  ///
  /// In en, this message translates to:
  /// **'Work the job already performed is not rolled back.'**
  String get jobsAbortConsequenceNoRollback;

  /// No description provided for @jobsAbortConsequenceRace.
  ///
  /// In en, this message translates to:
  /// **'The server may finish the job before it processes the abort.'**
  String get jobsAbortConsequenceRace;

  /// No description provided for @jobsAbortKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running'**
  String get jobsAbortKeepRunning;

  /// No description provided for @jobsAbortConfirm.
  ///
  /// In en, this message translates to:
  /// **'Abort job'**
  String get jobsAbortConfirm;

  /// No description provided for @jobsAbortFailed.
  ///
  /// In en, this message translates to:
  /// **'The abort request failed.'**
  String get jobsAbortFailed;

  /// No description provided for @jobsAbortRequested.
  ///
  /// In en, this message translates to:
  /// **'Abort requested for job {id}.'**
  String jobsAbortRequested(int id);

  /// No description provided for @jobsAbortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Abort job'**
  String get jobsAbortTooltip;

  /// No description provided for @jobsDetailJobId.
  ///
  /// In en, this message translates to:
  /// **'Job ID'**
  String get jobsDetailJobId;

  /// No description provided for @jobsDetailMethod.
  ///
  /// In en, this message translates to:
  /// **'API method'**
  String get jobsDetailMethod;

  /// No description provided for @jobsMethodPoolScrub.
  ///
  /// In en, this message translates to:
  /// **'Scrub Pool'**
  String get jobsMethodPoolScrub;

  /// No description provided for @jobsMethodPoolCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Pool'**
  String get jobsMethodPoolCreate;

  /// No description provided for @jobsMethodPoolExport.
  ///
  /// In en, this message translates to:
  /// **'Export Pool'**
  String get jobsMethodPoolExport;

  /// No description provided for @jobsMethodDatasetCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Dataset'**
  String get jobsMethodDatasetCreate;

  /// No description provided for @jobsMethodDatasetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Dataset'**
  String get jobsMethodDatasetUpdate;

  /// No description provided for @jobsMethodDatasetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Dataset'**
  String get jobsMethodDatasetDelete;

  /// No description provided for @jobsMethodSnapshotCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Snapshot'**
  String get jobsMethodSnapshotCreate;

  /// No description provided for @jobsMethodSnapshotDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Snapshot'**
  String get jobsMethodSnapshotDelete;

  /// No description provided for @jobsMethodSnapshotRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback Snapshot'**
  String get jobsMethodSnapshotRollback;

  /// No description provided for @jobsMethodSnapshotClone.
  ///
  /// In en, this message translates to:
  /// **'Clone Snapshot'**
  String get jobsMethodSnapshotClone;

  /// No description provided for @jobsMethodSetAcl.
  ///
  /// In en, this message translates to:
  /// **'Set ACL'**
  String get jobsMethodSetAcl;

  /// No description provided for @jobsMethodAppInstall.
  ///
  /// In en, this message translates to:
  /// **'Install App'**
  String get jobsMethodAppInstall;

  /// No description provided for @jobsMethodAppUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade App'**
  String get jobsMethodAppUpgrade;

  /// No description provided for @jobsMethodAppRollback.
  ///
  /// In en, this message translates to:
  /// **'Rollback App'**
  String get jobsMethodAppRollback;

  /// No description provided for @jobsMethodAppDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete App'**
  String get jobsMethodAppDelete;

  /// No description provided for @jobsMethodReplicationRun.
  ///
  /// In en, this message translates to:
  /// **'Run Replication'**
  String get jobsMethodReplicationRun;

  /// No description provided for @jobsMethodCloudSyncRun.
  ///
  /// In en, this message translates to:
  /// **'Run Cloud Sync'**
  String get jobsMethodCloudSyncRun;

  /// No description provided for @jobsMethodRsyncRun.
  ///
  /// In en, this message translates to:
  /// **'Run Rsync'**
  String get jobsMethodRsyncRun;

  /// No description provided for @jobsMethodSystemUpdate.
  ///
  /// In en, this message translates to:
  /// **'System Update'**
  String get jobsMethodSystemUpdate;

  /// No description provided for @jobsMethodSystemReboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot System'**
  String get jobsMethodSystemReboot;

  /// No description provided for @jobsMethodSystemShutdown.
  ///
  /// In en, this message translates to:
  /// **'Shut Down System'**
  String get jobsMethodSystemShutdown;

  /// No description provided for @jobsMethodUnknown.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS operation'**
  String get jobsMethodUnknown;

  /// No description provided for @jobsDetailState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get jobsDetailState;

  /// No description provided for @jobsDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get jobsDetailProgress;

  /// No description provided for @jobsDetailStep.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get jobsDetailStep;

  /// No description provided for @jobsDetailStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get jobsDetailStarted;

  /// No description provided for @jobsDetailFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get jobsDetailFinished;

  /// No description provided for @jobsDetailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get jobsDetailDuration;

  /// No description provided for @jobsDetailLogExcerpt.
  ///
  /// In en, this message translates to:
  /// **'Log excerpt'**
  String get jobsDetailLogExcerpt;

  /// No description provided for @jobsNotAbortable.
  ///
  /// In en, this message translates to:
  /// **'This job cannot be aborted from TrueDock. The server did not report it as abortable.'**
  String get jobsNotAbortable;

  /// No description provided for @jobsStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get jobsStateRunning;

  /// No description provided for @jobsStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get jobsStateWaiting;

  /// No description provided for @jobsStateSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get jobsStateSucceeded;

  /// No description provided for @jobsStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get jobsStateFailed;

  /// No description provided for @jobsStateAborted.
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get jobsStateAborted;

  /// No description provided for @storageSectionPools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get storageSectionPools;

  /// No description provided for @storageSectionCreatePool.
  ///
  /// In en, this message translates to:
  /// **'Create pool'**
  String get storageSectionCreatePool;

  /// No description provided for @storageSectionNoPools.
  ///
  /// In en, this message translates to:
  /// **'No storage pools found.'**
  String get storageSectionNoPools;

  /// No description provided for @storageSectionDatasets.
  ///
  /// In en, this message translates to:
  /// **'Datasets'**
  String get storageSectionDatasets;

  /// No description provided for @storageSectionCreateDataset.
  ///
  /// In en, this message translates to:
  /// **'Create dataset'**
  String get storageSectionCreateDataset;

  /// No description provided for @storageSectionNoDatasets.
  ///
  /// In en, this message translates to:
  /// **'No datasets found.'**
  String get storageSectionNoDatasets;

  /// No description provided for @storageSnapshotCreated.
  ///
  /// In en, this message translates to:
  /// **'Snapshot created.'**
  String get storageSnapshotCreated;

  /// No description provided for @storageSectionDisks.
  ///
  /// In en, this message translates to:
  /// **'Disks'**
  String get storageSectionDisks;

  /// No description provided for @storageSectionNoDisks.
  ///
  /// In en, this message translates to:
  /// **'No disks found.'**
  String get storageSectionNoDisks;

  /// No description provided for @storageSectionShares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get storageSectionShares;

  /// No description provided for @storageSmbPurposeReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Legacy or server-specific SMB purposes are read-only in TrueDock.'**
  String get storageSmbPurposeReadOnly;

  /// No description provided for @storageNoSharesFound.
  ///
  /// In en, this message translates to:
  /// **'No supported shares or iSCSI resources found.'**
  String get storageNoSharesFound;

  /// No description provided for @storageScanScrubInProgress.
  ///
  /// In en, this message translates to:
  /// **'Scrub in progress'**
  String get storageScanScrubInProgress;

  /// No description provided for @storageScanResilverInProgress.
  ///
  /// In en, this message translates to:
  /// **'Resilver in progress'**
  String get storageScanResilverInProgress;

  /// No description provided for @storageCreateShort.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get storageCreateShort;

  /// No description provided for @storageDiskSolidState.
  ///
  /// In en, this message translates to:
  /// **'Solid state'**
  String get storageDiskSolidState;

  /// No description provided for @storageDiskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get storageDiskUnavailable;

  /// No description provided for @storageEditSmbPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit SMB permissions'**
  String get storageEditSmbPermissions;

  /// No description provided for @storageEditSharePermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit share permissions'**
  String get storageEditSharePermissions;

  /// No description provided for @storageDeleteShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete share'**
  String get storageDeleteShareTooltip;

  /// No description provided for @storageDeleteExtentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete extent'**
  String get storageDeleteExtentTooltip;

  /// No description provided for @storageDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get storageDeleteTooltip;

  /// No description provided for @storageIscsiLunSubtitle.
  ///
  /// In en, this message translates to:
  /// **'iSCSI LUN · {lun}'**
  String storageIscsiLunSubtitle(Object lun);

  /// No description provided for @storageLunAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get storageLunAutomatic;

  /// No description provided for @storageBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get storageBadgeLocked;

  /// No description provided for @storageBadgeEnabled.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get storageBadgeEnabled;

  /// No description provided for @storageBadgeDisabled.
  ///
  /// In en, this message translates to:
  /// **'DISABLED'**
  String get storageBadgeDisabled;

  /// No description provided for @storageDeleteExtentSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete extent'**
  String get storageDeleteExtentSheetTitle;

  /// No description provided for @storageDeleteExtentAlsoDestroy.
  ///
  /// In en, this message translates to:
  /// **'Also destroy the backing storage'**
  String get storageDeleteExtentAlsoDestroy;

  /// No description provided for @storageDetailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get storageDetailTarget;

  /// No description provided for @storageDetailMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get storageDetailMode;

  /// No description provided for @storageDetailGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get storageDetailGroups;

  /// No description provided for @storageDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get storageDetailType;

  /// No description provided for @storageDetailBacking.
  ///
  /// In en, this message translates to:
  /// **'Backing'**
  String get storageDetailBacking;

  /// No description provided for @storageDetailCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get storageDetailCapacity;

  /// No description provided for @storageDetailBlockSize.
  ///
  /// In en, this message translates to:
  /// **'Block size'**
  String get storageDetailBlockSize;

  /// No description provided for @storageDetailBlockSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{bytes} B'**
  String storageDetailBlockSizeValue(int bytes);

  /// No description provided for @storageDetailAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get storageDetailAccess;

  /// No description provided for @storageDetailAccessReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get storageDetailAccessReadOnly;

  /// No description provided for @storageDetailAccessReadWrite.
  ///
  /// In en, this message translates to:
  /// **'Read and write'**
  String get storageDetailAccessReadWrite;

  /// No description provided for @storageDetailState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get storageDetailState;

  /// No description provided for @storageDetailStateLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get storageDetailStateLocked;

  /// No description provided for @storageDetailStateEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get storageDetailStateEnabled;

  /// No description provided for @storageDetailStateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get storageDetailStateDisabled;

  /// No description provided for @storageCreateSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Create snapshot'**
  String get storageCreateSnapshotTitle;

  /// No description provided for @storageSnapshotNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Snapshot name'**
  String get storageSnapshotNameLabel;

  /// No description provided for @storageSnapshotCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get storageSnapshotCreating;

  /// No description provided for @storageActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The TrueNAS operation failed.'**
  String get storageActionFailed;

  /// No description provided for @storageServerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'this TrueNAS server'**
  String get storageServerFallbackName;

  /// No description provided for @storageAclConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace permissions for {name}?'**
  String storageAclConfirmTitle(Object name);

  /// No description provided for @storageAclConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Replace permissions'**
  String get storageAclConfirmAction;

  /// No description provided for @storageAclConfirmRules.
  ///
  /// In en, this message translates to:
  /// **'The full list replaces the existing ACL. {count} rule(s) take effect when the TrueNAS job completes.'**
  String storageAclConfirmRules(int count);

  /// No description provided for @storageAclConfirmUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Clients that currently access the share and are no longer listed lose access.'**
  String get storageAclConfirmUnlisted;

  /// No description provided for @storageDeleteDatasetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete dataset?'**
  String get storageDeleteDatasetTitle;

  /// No description provided for @storageDeleteDatasetAction.
  ///
  /// In en, this message translates to:
  /// **'Delete dataset'**
  String get storageDeleteDatasetAction;

  /// No description provided for @storageDeleteDatasetData.
  ///
  /// In en, this message translates to:
  /// **'All {size} of data in this dataset is destroyed and cannot be recovered.'**
  String storageDeleteDatasetData(Object size);

  /// No description provided for @storageDeleteDatasetChildren.
  ///
  /// In en, this message translates to:
  /// **'{count} child dataset(s) are destroyed with it.'**
  String storageDeleteDatasetChildren(int count);

  /// No description provided for @storageDeleteDatasetSnapshots.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshot(s) of this path are destroyed.'**
  String storageDeleteDatasetSnapshots(int count);

  /// No description provided for @storageDeleteDatasetShares.
  ///
  /// In en, this message translates to:
  /// **'{count} share(s) point at {path} and stop serving data.'**
  String storageDeleteDatasetShares(int count, Object path);

  /// No description provided for @storageDeleteDatasetNoteLeaf.
  ///
  /// In en, this message translates to:
  /// **'Applications writing to this path will start failing.'**
  String get storageDeleteDatasetNoteLeaf;

  /// No description provided for @storageDeleteDatasetNoteRecursive.
  ///
  /// In en, this message translates to:
  /// **'Child datasets are removed recursively, and busy datasets are unmounted so the delete can proceed.'**
  String get storageDeleteDatasetNoteRecursive;

  /// No description provided for @storageDeleteSmbTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete SMB share?'**
  String get storageDeleteSmbTitle;

  /// No description provided for @storageDeleteShareAction.
  ///
  /// In en, this message translates to:
  /// **'Delete share'**
  String get storageDeleteShareAction;

  /// No description provided for @storageDeleteSmbClients.
  ///
  /// In en, this message translates to:
  /// **'Connected SMB clients lose access immediately.'**
  String get storageDeleteSmbClients;

  /// No description provided for @storageDeleteSmbConfig.
  ///
  /// In en, this message translates to:
  /// **'The share configuration, including its ACL, is removed.'**
  String get storageDeleteSmbConfig;

  /// No description provided for @storageDeleteShareNote.
  ///
  /// In en, this message translates to:
  /// **'The dataset and its files are not deleted.'**
  String get storageDeleteShareNote;

  /// No description provided for @storageDeleteNfsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete NFS share?'**
  String get storageDeleteNfsTitle;

  /// No description provided for @storageDeleteNfsClients.
  ///
  /// In en, this message translates to:
  /// **'NFS clients with this export mounted lose access.'**
  String get storageDeleteNfsClients;

  /// No description provided for @storageDeleteNfsRules.
  ///
  /// In en, this message translates to:
  /// **'Host, network, and mapping rules for the export are removed.'**
  String get storageDeleteNfsRules;

  /// No description provided for @storageIscsiPortalFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Portal {tag}'**
  String storageIscsiPortalFallbackLabel(int tag);

  /// No description provided for @storageDeletePortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete iSCSI portal?'**
  String get storageDeletePortalTitle;

  /// No description provided for @storageDeletePortalAction.
  ///
  /// In en, this message translates to:
  /// **'Delete portal'**
  String get storageDeletePortalAction;

  /// No description provided for @storageDeletePortalInitiators.
  ///
  /// In en, this message translates to:
  /// **'Initiators reaching targets through these addresses disconnect.'**
  String get storageDeletePortalInitiators;

  /// No description provided for @storageDeleteIscsiInUse.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS refuses the delete while a target still uses it.'**
  String get storageDeleteIscsiInUse;

  /// No description provided for @storageDeletePortalNote.
  ///
  /// In en, this message translates to:
  /// **'Extents and their backing storage are not affected.'**
  String get storageDeletePortalNote;

  /// No description provided for @storageIscsiInitiatorFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Initiator group {id}'**
  String storageIscsiInitiatorFallbackLabel(int id);

  /// No description provided for @storageDeleteInitiatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete initiator group?'**
  String get storageDeleteInitiatorTitle;

  /// No description provided for @storageDeleteInitiatorAction.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get storageDeleteInitiatorAction;

  /// No description provided for @storageDeleteInitiatorAllowList.
  ///
  /// In en, this message translates to:
  /// **'Targets restricted to this group lose their allow list.'**
  String get storageDeleteInitiatorAllowList;

  /// No description provided for @storageDeleteTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete iSCSI target?'**
  String get storageDeleteTargetTitle;

  /// No description provided for @storageDeleteTargetAction.
  ///
  /// In en, this message translates to:
  /// **'Delete target'**
  String get storageDeleteTargetAction;

  /// No description provided for @storageDeleteTargetInitiators.
  ///
  /// In en, this message translates to:
  /// **'Connected initiators lose their block devices immediately, which can corrupt in-flight writes.'**
  String get storageDeleteTargetInitiators;

  /// No description provided for @storageDeleteTargetLuns.
  ///
  /// In en, this message translates to:
  /// **'{count} LUN association(s) are removed with the target.'**
  String storageDeleteTargetLuns(int count);

  /// No description provided for @storageDeleteTargetNote.
  ///
  /// In en, this message translates to:
  /// **'Extents keep their data and can be attached to another target.'**
  String get storageDeleteTargetNote;

  /// No description provided for @storageDestroyExtentTitle.
  ///
  /// In en, this message translates to:
  /// **'Destroy extent data?'**
  String get storageDestroyExtentTitle;

  /// No description provided for @storageDeleteExtentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete iSCSI extent?'**
  String get storageDeleteExtentTitle;

  /// No description provided for @storageDeleteExtentDestroyAction.
  ///
  /// In en, this message translates to:
  /// **'Delete and destroy'**
  String get storageDeleteExtentDestroyAction;

  /// No description provided for @storageDeleteExtentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete extent'**
  String get storageDeleteExtentAction;

  /// No description provided for @storageDeleteExtentBackingDestroyed.
  ///
  /// In en, this message translates to:
  /// **'The backing {type} {store} is destroyed and cannot be recovered.'**
  String storageDeleteExtentBackingDestroyed(Object type, Object store);

  /// No description provided for @storageDeleteExtentBackingKept.
  ///
  /// In en, this message translates to:
  /// **'The extent is removed but its backing storage is kept.'**
  String get storageDeleteExtentBackingKept;

  /// No description provided for @storageDeleteExtentLuns.
  ///
  /// In en, this message translates to:
  /// **'{count} LUN association(s) are removed with the extent.'**
  String storageDeleteExtentLuns(int count);

  /// No description provided for @storageDeleteExtentInitiators.
  ///
  /// In en, this message translates to:
  /// **'Initiators using this LUN lose their block device at once.'**
  String get storageDeleteExtentInitiators;

  /// No description provided for @storageIscsiAssociationLabel.
  ///
  /// In en, this message translates to:
  /// **'Target {targetId} → extent {extentId}'**
  String storageIscsiAssociationLabel(int targetId, int extentId);

  /// No description provided for @storageRemoveLunTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove LUN association?'**
  String get storageRemoveLunTitle;

  /// No description provided for @storageRemoveLunAction.
  ///
  /// In en, this message translates to:
  /// **'Remove association'**
  String get storageRemoveLunAction;

  /// No description provided for @storageRemoveLunDisappears.
  ///
  /// In en, this message translates to:
  /// **'The LUN disappears from the target and initiators lose that block device.'**
  String get storageRemoveLunDisappears;

  /// No description provided for @storageRemoveLunExtentKept.
  ///
  /// In en, this message translates to:
  /// **'The extent and its data are kept and can be reattached.'**
  String get storageRemoveLunExtentKept;

  /// No description provided for @storageLockDatasetTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock dataset?'**
  String get storageLockDatasetTitle;

  /// No description provided for @storageLockDatasetAction.
  ///
  /// In en, this message translates to:
  /// **'Lock dataset'**
  String get storageLockDatasetAction;

  /// No description provided for @storageLockDatasetKey.
  ///
  /// In en, this message translates to:
  /// **'The encryption key is evicted and the data becomes unreadable until it is unlocked again.'**
  String get storageLockDatasetKey;

  /// No description provided for @storageLockDatasetChildren.
  ///
  /// In en, this message translates to:
  /// **'{count} child dataset(s) sharing this key are locked too.'**
  String storageLockDatasetChildren(int count);

  /// No description provided for @storageLockDatasetShares.
  ///
  /// In en, this message translates to:
  /// **'{count} share(s) on this path stop serving data.'**
  String storageLockDatasetShares(int count);

  /// No description provided for @storageLockDatasetNotePassphrase.
  ///
  /// In en, this message translates to:
  /// **'You will need the passphrase to unlock it again.'**
  String get storageLockDatasetNotePassphrase;

  /// No description provided for @storageLockDatasetNoteKey.
  ///
  /// In en, this message translates to:
  /// **'You will need the hex key to unlock it again.'**
  String get storageLockDatasetNoteKey;

  /// No description provided for @storagePromoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote {name}?'**
  String storagePromoteTitle(Object name);

  /// No description provided for @storagePromoteAction.
  ///
  /// In en, this message translates to:
  /// **'Promote clone'**
  String get storagePromoteAction;

  /// No description provided for @storagePromoteOwnership.
  ///
  /// In en, this message translates to:
  /// **'{name} stops depending on {origin} and takes ownership of the data they share.'**
  String storagePromoteOwnership(Object name, Object origin);

  /// No description provided for @storagePromoteReverses.
  ///
  /// In en, this message translates to:
  /// **'The dependency reverses: {originDataset} becomes the dependent dataset, so {origin} and the snapshots before it can then be deleted.'**
  String storagePromoteReverses(Object originDataset, Object origin);

  /// No description provided for @storagePromoteSpace.
  ///
  /// In en, this message translates to:
  /// **'No data is copied or deleted, but space previously charged to the original is charged to this dataset afterwards.'**
  String get storagePromoteSpace;

  /// No description provided for @storageCreatePoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Create pool {name}?'**
  String storageCreatePoolTitle(Object name);

  /// No description provided for @storageCreatePoolAction.
  ///
  /// In en, this message translates to:
  /// **'Create pool'**
  String get storageCreatePoolAction;

  /// No description provided for @storageCreatePoolDisks.
  ///
  /// In en, this message translates to:
  /// **'{count} disk(s) are formatted. Existing data on them is unrecoverable.'**
  String storageCreatePoolDisks(int count);

  /// No description provided for @storageCreatePoolNoRedundancy.
  ///
  /// In en, this message translates to:
  /// **'The pool has no redundancy. A single disk failure loses the entire pool.'**
  String get storageCreatePoolNoRedundancy;

  /// No description provided for @storageCreatePoolEncrypted.
  ///
  /// In en, this message translates to:
  /// **'The pool is encrypted at rest. Keep the recovery key safe or the data is unrecoverable.'**
  String get storageCreatePoolEncrypted;

  /// No description provided for @storageCreatePoolNote.
  ///
  /// In en, this message translates to:
  /// **'This is a destructive operation with no undo.'**
  String get storageCreatePoolNote;

  /// No description provided for @storageStopScrubTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the scrub?'**
  String get storageStopScrubTitle;

  /// No description provided for @storageStopScrubAction.
  ///
  /// In en, this message translates to:
  /// **'Stop scrub'**
  String get storageStopScrubAction;

  /// No description provided for @storageStopScrubProgress.
  ///
  /// In en, this message translates to:
  /// **'Scrub progress is discarded and must start over.'**
  String get storageStopScrubProgress;

  /// No description provided for @storageStopScrubUnverified.
  ///
  /// In en, this message translates to:
  /// **'Blocks not yet verified stay unchecked until the next run.'**
  String get storageStopScrubUnverified;

  /// No description provided for @storageScrubActionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause scrub'**
  String get storageScrubActionPause;

  /// No description provided for @storageScrubActionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume scrub'**
  String get storageScrubActionResume;

  /// No description provided for @storageScrubActionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop scrub'**
  String get storageScrubActionStop;

  /// No description provided for @storageOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Take {name} offline?'**
  String storageOfflineTitle(Object name);

  /// No description provided for @storageOfflineAction.
  ///
  /// In en, this message translates to:
  /// **'Take offline'**
  String get storageOfflineAction;

  /// No description provided for @storageOfflineDegraded.
  ///
  /// In en, this message translates to:
  /// **'{pool} runs degraded and loses the redundancy this device provides.'**
  String storageOfflineDegraded(Object pool);

  /// No description provided for @storageOfflineSecondFailure.
  ///
  /// In en, this message translates to:
  /// **'A second device failure while degraded can lose the entire pool.'**
  String get storageOfflineSecondFailure;

  /// No description provided for @storageOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Bring the device back online or replace it as soon as possible.'**
  String get storageOfflineNote;

  /// No description provided for @storageAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach {disk} to a pool member?'**
  String storageAttachTitle(Object disk);

  /// No description provided for @storageAttachAction.
  ///
  /// In en, this message translates to:
  /// **'Attach disk'**
  String get storageAttachAction;

  /// No description provided for @storageAttachResilver.
  ///
  /// In en, this message translates to:
  /// **'Attaching to a mirror starts a resilver. The pool stays online but disk bandwidth is consumed until it finishes.'**
  String get storageAttachResilver;

  /// No description provided for @storageAttachJoins.
  ///
  /// In en, this message translates to:
  /// **'{disk} joins the selected vdev in {pool} and is no longer available as a spare or for another pool.'**
  String storageAttachJoins(Object disk, Object pool);

  /// No description provided for @storageAttachNote.
  ///
  /// In en, this message translates to:
  /// **'Keep the pool online until the resilver completes.'**
  String get storageAttachNote;

  /// No description provided for @storageReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace {member} with {disk}?'**
  String storageReplaceTitle(Object member, Object disk);

  /// No description provided for @storageReplaceAction.
  ///
  /// In en, this message translates to:
  /// **'Replace disk'**
  String get storageReplaceAction;

  /// No description provided for @storageReplaceResilver.
  ///
  /// In en, this message translates to:
  /// **'A resilver copies data onto the new disk. The pool stays online but runs degraded until the resilver finishes.'**
  String get storageReplaceResilver;

  /// No description provided for @storageReplaceRemoved.
  ///
  /// In en, this message translates to:
  /// **'{member} is removed from {pool} once the resilver completes and is safe to remove.'**
  String storageReplaceRemoved(Object member, Object pool);

  /// No description provided for @storageReplaceForce.
  ///
  /// In en, this message translates to:
  /// **'Forcing removes the old disk even if it is still being read. Use only when the disk has failed.'**
  String get storageReplaceForce;

  /// No description provided for @storageReplaceNote.
  ///
  /// In en, this message translates to:
  /// **'Do not remove the old disk until the resilver finishes.'**
  String get storageReplaceNote;

  /// No description provided for @storageDestroyPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Destroy pool?'**
  String get storageDestroyPoolTitle;

  /// No description provided for @storageExportPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Export pool?'**
  String get storageExportPoolTitle;

  /// No description provided for @storageDestroyPoolAction.
  ///
  /// In en, this message translates to:
  /// **'Destroy pool'**
  String get storageDestroyPoolAction;

  /// No description provided for @storageExportPoolAction.
  ///
  /// In en, this message translates to:
  /// **'Export pool'**
  String get storageExportPoolAction;

  /// No description provided for @storageDestroyPoolWiped.
  ///
  /// In en, this message translates to:
  /// **'Every disk in {pool} is wiped. {size} of data is unrecoverable.'**
  String storageDestroyPoolWiped(Object pool, Object size);

  /// No description provided for @storageExportPoolDetached.
  ///
  /// In en, this message translates to:
  /// **'The pool is detached from this server. The disks keep their data and can be imported again.'**
  String get storageExportPoolDetached;

  /// No description provided for @storageExportPoolDatasets.
  ///
  /// In en, this message translates to:
  /// **'{count} dataset(s) stop being served immediately.'**
  String storageExportPoolDatasets(int count);

  /// No description provided for @storageExportPoolSharesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Shares and tasks that reference this pool are deleted.'**
  String get storageExportPoolSharesDeleted;

  /// No description provided for @storageDestroyPoolNote.
  ///
  /// In en, this message translates to:
  /// **'There is no undo and no recovery path for this action.'**
  String get storageDestroyPoolNote;

  /// No description provided for @storageExportPoolNote.
  ///
  /// In en, this message translates to:
  /// **'Applications and shares using this pool will start failing.'**
  String get storageExportPoolNote;

  /// No description provided for @storagePoolFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create {name}.'**
  String storagePoolFailedCreate(Object name);

  /// No description provided for @storagePoolSuccessCreate.
  ///
  /// In en, this message translates to:
  /// **'{name} is being created.'**
  String storagePoolSuccessCreate(Object name);

  /// No description provided for @storagePoolFailedScrub.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not change the scrub for {pool}.'**
  String storagePoolFailedScrub(Object pool);

  /// No description provided for @storagePoolSuccessScrubStarted.
  ///
  /// In en, this message translates to:
  /// **'Scrub started for {pool}.'**
  String storagePoolSuccessScrubStarted(Object pool);

  /// No description provided for @storagePoolSuccessScrubAction.
  ///
  /// In en, this message translates to:
  /// **'{action} requested for {pool}.'**
  String storagePoolSuccessScrubAction(Object action, Object pool);

  /// No description provided for @storagePoolFailedOnline.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not bring {name} online.'**
  String storagePoolFailedOnline(Object name);

  /// No description provided for @storagePoolFailedOffline.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not take {name} offline.'**
  String storagePoolFailedOffline(Object name);

  /// No description provided for @storagePoolSuccessOnline.
  ///
  /// In en, this message translates to:
  /// **'{name} is coming back online.'**
  String storagePoolSuccessOnline(Object name);

  /// No description provided for @storagePoolSuccessOffline.
  ///
  /// In en, this message translates to:
  /// **'{name} was taken offline.'**
  String storagePoolSuccessOffline(Object name);

  /// No description provided for @storagePoolFailedAttach.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not attach {disk} to {pool}.'**
  String storagePoolFailedAttach(Object disk, Object pool);

  /// No description provided for @storagePoolSuccessAttach.
  ///
  /// In en, this message translates to:
  /// **'Resilver started for {disk} in {pool}.'**
  String storagePoolSuccessAttach(Object disk, Object pool);

  /// No description provided for @storagePoolFailedReplace.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not replace {member} in {pool}.'**
  String storagePoolFailedReplace(Object member, Object pool);

  /// No description provided for @storagePoolSuccessReplace.
  ///
  /// In en, this message translates to:
  /// **'Resilver started onto {disk} for {pool}.'**
  String storagePoolSuccessReplace(Object disk, Object pool);

  /// No description provided for @storagePoolFailedExport.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not export {pool}.'**
  String storagePoolFailedExport(Object pool);

  /// No description provided for @storagePoolSuccessDestroying.
  ///
  /// In en, this message translates to:
  /// **'{pool} is being destroyed.'**
  String storagePoolSuccessDestroying(Object pool);

  /// No description provided for @storagePoolSuccessExporting.
  ///
  /// In en, this message translates to:
  /// **'{pool} is being exported.'**
  String storagePoolSuccessExporting(Object pool);

  /// No description provided for @storageChapCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create CHAP credential?'**
  String get storageChapCreateTitle;

  /// No description provided for @storageChapCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create credential'**
  String get storageChapCreateAction;

  /// No description provided for @storageChapCreateStored.
  ///
  /// In en, this message translates to:
  /// **'A new CHAP user and secret are stored on the server. Initiators can authenticate with them once a target group references this credential.'**
  String get storageChapCreateStored;

  /// No description provided for @storageChapCreateMutual.
  ///
  /// In en, this message translates to:
  /// **'Mutual CHAP also stores a peer user and peer secret.'**
  String get storageChapCreateMutual;

  /// No description provided for @storageChapCreateNote.
  ///
  /// In en, this message translates to:
  /// **'The secret is sent only over this session and is not saved or logged by TrueDock.'**
  String get storageChapCreateNote;

  /// No description provided for @storageChapUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes to {user}?'**
  String storageChapUpdateTitle(Object user);

  /// No description provided for @storageChapUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get storageChapUpdateAction;

  /// No description provided for @storageChapUpdateImmediate.
  ///
  /// In en, this message translates to:
  /// **'Target groups that reference this credential start using the updated user and secret immediately. Initiators must be reconfigured to match or they fail to authenticate.'**
  String get storageChapUpdateImmediate;

  /// No description provided for @storageChapUpdateRotated.
  ///
  /// In en, this message translates to:
  /// **'The CHAP secret is rotated to the new value you entered.'**
  String get storageChapUpdateRotated;

  /// No description provided for @storageChapUpdateNoteRotating.
  ///
  /// In en, this message translates to:
  /// **'The new secret is sent only over this session and is not saved or logged by TrueDock.'**
  String get storageChapUpdateNoteRotating;

  /// No description provided for @storageChapUpdateNoteUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The existing secret is left unchanged on the server.'**
  String get storageChapUpdateNoteUnchanged;

  /// No description provided for @storageChapDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete CHAP credential {user}?'**
  String storageChapDeleteTitle(Object user);

  /// No description provided for @storageChapDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete credential'**
  String get storageChapDeleteAction;

  /// No description provided for @storageChapDeleteAuth.
  ///
  /// In en, this message translates to:
  /// **'Target groups that reference this credential by tag lose authentication. Initiators presenting this user are rejected.'**
  String get storageChapDeleteAuth;

  /// No description provided for @storageChapDeleteSecret.
  ///
  /// In en, this message translates to:
  /// **'The stored secret is removed from the server.'**
  String get storageChapDeleteSecret;

  /// No description provided for @storageChapDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Update or remove target groups that use this tag before deleting.'**
  String get storageChapDeleteNote;

  /// No description provided for @storageDatasetFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update {name}.'**
  String storageDatasetFailedUpdate(Object name);

  /// No description provided for @storageDatasetSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated {name}.'**
  String storageDatasetSuccessUpdate(Object name);

  /// No description provided for @storageDatasetFailedRename.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not rename {name}.'**
  String storageDatasetFailedRename(Object name);

  /// No description provided for @storageDatasetSuccessRename.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}.'**
  String storageDatasetSuccessRename(Object name);

  /// No description provided for @storageDatasetFailedDelete.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {name}.'**
  String storageDatasetFailedDelete(Object name);

  /// No description provided for @storageDatasetSuccessDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}.'**
  String storageDatasetSuccessDelete(Object name);

  /// No description provided for @storageDatasetFailedLock.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not lock {name}.'**
  String storageDatasetFailedLock(Object name);

  /// No description provided for @storageDatasetSuccessLock.
  ///
  /// In en, this message translates to:
  /// **'Locked {name}.'**
  String storageDatasetSuccessLock(Object name);

  /// No description provided for @storageDatasetFailedPromote.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not promote {name}.'**
  String storageDatasetFailedPromote(Object name);

  /// No description provided for @storageDatasetSuccessPromote.
  ///
  /// In en, this message translates to:
  /// **'Promoted {name}.'**
  String storageDatasetSuccessPromote(Object name);

  /// No description provided for @storageDatasetFailedUnlock.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not unlock {name}.'**
  String storageDatasetFailedUnlock(Object name);

  /// No description provided for @storageDatasetSuccessUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlocked {name}.'**
  String storageDatasetSuccessUnlock(Object name);

  /// No description provided for @storageSmbFailedLoadPresets.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not load SMB presets.'**
  String get storageSmbFailedLoadPresets;

  /// No description provided for @storageSmbFailedValidate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not validate the SMB share.'**
  String get storageSmbFailedValidate;

  /// No description provided for @storageSmbFailedLoadAcl.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not load the share permissions.'**
  String get storageSmbFailedLoadAcl;

  /// No description provided for @storageSmbFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create {name}.'**
  String storageSmbFailedCreate(Object name);

  /// No description provided for @storageSmbSuccessCreate.
  ///
  /// In en, this message translates to:
  /// **'Created SMB share {name}.'**
  String storageSmbSuccessCreate(Object name);

  /// No description provided for @storageSmbFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update {name}.'**
  String storageSmbFailedUpdate(Object name);

  /// No description provided for @storageSmbSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated SMB share {name}.'**
  String storageSmbSuccessUpdate(Object name);

  /// No description provided for @storageSmbFailedSetAcl.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not replace the SMB share permissions.'**
  String get storageSmbFailedSetAcl;

  /// No description provided for @storageSmbSuccessSetAcl.
  ///
  /// In en, this message translates to:
  /// **'Replaced the permissions for {name}.'**
  String storageSmbSuccessSetAcl(Object name);

  /// No description provided for @storageSmbFailedDelete.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {name}.'**
  String storageSmbFailedDelete(Object name);

  /// No description provided for @storageSmbSuccessDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted SMB share {name}.'**
  String storageSmbSuccessDelete(Object name);

  /// No description provided for @storageNfsFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create {path}.'**
  String storageNfsFailedCreate(Object path);

  /// No description provided for @storageNfsSuccessCreate.
  ///
  /// In en, this message translates to:
  /// **'Created NFS share {path}.'**
  String storageNfsSuccessCreate(Object path);

  /// No description provided for @storageNfsFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update {path}.'**
  String storageNfsFailedUpdate(Object path);

  /// No description provided for @storageNfsSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated NFS share {path}.'**
  String storageNfsSuccessUpdate(Object path);

  /// No description provided for @storageNfsFailedDelete.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {path}.'**
  String storageNfsFailedDelete(Object path);

  /// No description provided for @storageNfsSuccessDelete.
  ///
  /// In en, this message translates to:
  /// **'Deleted NFS share {path}.'**
  String storageNfsSuccessDelete(Object path);

  /// No description provided for @storageIscsiFailedLoadPortals.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not load portal addresses.'**
  String get storageIscsiFailedLoadPortals;

  /// No description provided for @storageIscsiFailedValidateTarget.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not validate the target name.'**
  String get storageIscsiFailedValidateTarget;

  /// No description provided for @storageIscsiFailedLoadExtents.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not load extent choices.'**
  String get storageIscsiFailedLoadExtents;

  /// No description provided for @storageIscsiFailedCreatePortal.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create the iSCSI portal.'**
  String get storageIscsiFailedCreatePortal;

  /// No description provided for @storageIscsiSuccessCreatePortal.
  ///
  /// In en, this message translates to:
  /// **'Created the iSCSI portal.'**
  String get storageIscsiSuccessCreatePortal;

  /// No description provided for @storageIscsiFailedUpdatePortal.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update portal {tag}.'**
  String storageIscsiFailedUpdatePortal(int tag);

  /// No description provided for @storageIscsiSuccessUpdatePortal.
  ///
  /// In en, this message translates to:
  /// **'Updated portal {tag}.'**
  String storageIscsiSuccessUpdatePortal(int tag);

  /// No description provided for @storageIscsiFailedDeletePortal.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {label}.'**
  String storageIscsiFailedDeletePortal(Object label);

  /// No description provided for @storageIscsiSuccessDeletePortal.
  ///
  /// In en, this message translates to:
  /// **'Deleted {label}.'**
  String storageIscsiSuccessDeletePortal(Object label);

  /// No description provided for @storageIscsiFailedCreateInitiator.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create the initiator group.'**
  String get storageIscsiFailedCreateInitiator;

  /// No description provided for @storageIscsiSuccessCreateInitiator.
  ///
  /// In en, this message translates to:
  /// **'Created the initiator group.'**
  String get storageIscsiSuccessCreateInitiator;

  /// No description provided for @storageIscsiFailedUpdateInitiator.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update initiator group {id}.'**
  String storageIscsiFailedUpdateInitiator(int id);

  /// No description provided for @storageIscsiSuccessUpdateInitiator.
  ///
  /// In en, this message translates to:
  /// **'Updated initiator group {id}.'**
  String storageIscsiSuccessUpdateInitiator(int id);

  /// No description provided for @storageIscsiFailedDeleteInitiator.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {label}.'**
  String storageIscsiFailedDeleteInitiator(Object label);

  /// No description provided for @storageIscsiSuccessDeleteInitiator.
  ///
  /// In en, this message translates to:
  /// **'Deleted {label}.'**
  String storageIscsiSuccessDeleteInitiator(Object label);

  /// No description provided for @storageIscsiFailedCreateTarget.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create target {name}.'**
  String storageIscsiFailedCreateTarget(Object name);

  /// No description provided for @storageIscsiSuccessCreateTarget.
  ///
  /// In en, this message translates to:
  /// **'Created target {name}.'**
  String storageIscsiSuccessCreateTarget(Object name);

  /// No description provided for @storageIscsiFailedUpdateTarget.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update target {name}.'**
  String storageIscsiFailedUpdateTarget(Object name);

  /// No description provided for @storageIscsiSuccessUpdateTarget.
  ///
  /// In en, this message translates to:
  /// **'Updated target {name}.'**
  String storageIscsiSuccessUpdateTarget(Object name);

  /// No description provided for @storageIscsiFailedDeleteTarget.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {name}.'**
  String storageIscsiFailedDeleteTarget(Object name);

  /// No description provided for @storageIscsiSuccessDeleteTarget.
  ///
  /// In en, this message translates to:
  /// **'Deleted target {name}.'**
  String storageIscsiSuccessDeleteTarget(Object name);

  /// No description provided for @storageIscsiFailedCreateExtent.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create extent {name}.'**
  String storageIscsiFailedCreateExtent(Object name);

  /// No description provided for @storageIscsiSuccessCreateExtent.
  ///
  /// In en, this message translates to:
  /// **'Created extent {name}.'**
  String storageIscsiSuccessCreateExtent(Object name);

  /// No description provided for @storageIscsiFailedUpdateExtent.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update extent {name}.'**
  String storageIscsiFailedUpdateExtent(Object name);

  /// No description provided for @storageIscsiSuccessUpdateExtent.
  ///
  /// In en, this message translates to:
  /// **'Updated extent {name}.'**
  String storageIscsiSuccessUpdateExtent(Object name);

  /// No description provided for @storageIscsiFailedDeleteExtent.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete {name}.'**
  String storageIscsiFailedDeleteExtent(Object name);

  /// No description provided for @storageIscsiSuccessDeleteExtent.
  ///
  /// In en, this message translates to:
  /// **'Deleted extent {name}.'**
  String storageIscsiSuccessDeleteExtent(Object name);

  /// No description provided for @storageIscsiFailedAssociate.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not associate the target and extent.'**
  String get storageIscsiFailedAssociate;

  /// No description provided for @storageIscsiSuccessAssociate.
  ///
  /// In en, this message translates to:
  /// **'Associated the target and extent.'**
  String get storageIscsiSuccessAssociate;

  /// No description provided for @storageIscsiFailedUpdateLun.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update LUN {lun}.'**
  String storageIscsiFailedUpdateLun(Object lun);

  /// No description provided for @storageIscsiSuccessUpdateLun.
  ///
  /// In en, this message translates to:
  /// **'Updated LUN {lun}.'**
  String storageIscsiSuccessUpdateLun(Object lun);

  /// No description provided for @storageIscsiFailedRemoveLun.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not remove {label}.'**
  String storageIscsiFailedRemoveLun(Object label);

  /// No description provided for @storageIscsiSuccessRemoveLun.
  ///
  /// In en, this message translates to:
  /// **'Removed {label}.'**
  String storageIscsiSuccessRemoveLun(Object label);

  /// No description provided for @storageIscsiFailedCreateChap.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not create the CHAP credential for {user}.'**
  String storageIscsiFailedCreateChap(Object user);

  /// No description provided for @storageIscsiSuccessCreateChap.
  ///
  /// In en, this message translates to:
  /// **'Created the CHAP credential for {user}.'**
  String storageIscsiSuccessCreateChap(Object user);

  /// No description provided for @storageIscsiFailedUpdateChap.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not update the CHAP credential for {user}.'**
  String storageIscsiFailedUpdateChap(Object user);

  /// No description provided for @storageIscsiSuccessUpdateChap.
  ///
  /// In en, this message translates to:
  /// **'Updated the CHAP credential for {user}.'**
  String storageIscsiSuccessUpdateChap(Object user);

  /// No description provided for @storageIscsiFailedDeleteChap.
  ///
  /// In en, this message translates to:
  /// **'TrueNAS could not delete the CHAP credential for {user}.'**
  String storageIscsiFailedDeleteChap(Object user);

  /// No description provided for @storageIscsiSuccessDeleteChap.
  ///
  /// In en, this message translates to:
  /// **'Deleted the CHAP credential for {user}.'**
  String storageIscsiSuccessDeleteChap(Object user);

  /// No description provided for @storageUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock dataset'**
  String get storageUnlockTitle;

  /// No description provided for @storageUnlockPassphraseLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get storageUnlockPassphraseLabel;

  /// No description provided for @storageUnlockHexKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Hex key'**
  String get storageUnlockHexKeyLabel;

  /// No description provided for @storageUnlockPassphraseHelper.
  ///
  /// In en, this message translates to:
  /// **'The passphrase set when this dataset was encrypted.'**
  String get storageUnlockPassphraseHelper;

  /// No description provided for @storageUnlockHexKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'The 64-character hex key for this dataset.'**
  String get storageUnlockHexKeyHelper;

  /// No description provided for @storageUnlockShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get storageUnlockShow;

  /// No description provided for @storageUnlockHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get storageUnlockHide;

  /// No description provided for @storageUnlockChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock child datasets'**
  String get storageUnlockChildrenTitle;

  /// No description provided for @storageUnlockChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Children that share this encryption key are unlocked too.'**
  String get storageUnlockChildrenSubtitle;

  /// No description provided for @storageUnlockSecretNotice.
  ///
  /// In en, this message translates to:
  /// **'TrueDock sends this secret to the server to unlock the dataset and does not store it.'**
  String get storageUnlockSecretNotice;

  /// No description provided for @storageUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get storageUnlockAction;

  /// No description provided for @storageUnlockErrorPassphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase for this dataset.'**
  String get storageUnlockErrorPassphraseRequired;

  /// No description provided for @storageUnlockErrorHexKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the hex key for this dataset.'**
  String get storageUnlockErrorHexKeyRequired;

  /// No description provided for @storageUnlockErrorHexKeyFormat.
  ///
  /// In en, this message translates to:
  /// **'A hex key contains only 0-9 and a-f.'**
  String get storageUnlockErrorHexKeyFormat;

  /// No description provided for @storageDatasetEditComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get storageDatasetEditComments;

  /// No description provided for @storageDatasetEditInherit.
  ///
  /// In en, this message translates to:
  /// **'Inherit'**
  String get storageDatasetEditInherit;

  /// No description provided for @storageDatasetEditSetHere.
  ///
  /// In en, this message translates to:
  /// **'Set here'**
  String get storageDatasetEditSetHere;

  /// No description provided for @coreLandingNoFakeData.
  ///
  /// In en, this message translates to:
  /// **'TrueDock never fills server screens with made-up data.'**
  String get coreLandingNoFakeData;

  /// No description provided for @coreLandingConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Connect server'**
  String get coreLandingConnectServer;

  /// No description provided for @coreLandingManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get coreLandingManage;

  /// No description provided for @coreLandingConnectToLoad.
  ///
  /// In en, this message translates to:
  /// **'Connect to load {title}'**
  String coreLandingConnectToLoad(String title);

  /// No description provided for @dropdownSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get dropdownSelect;

  /// No description provided for @dropdownOptionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String dropdownOptionCount(int count);

  /// No description provided for @dropdownSearch.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get dropdownSearch;

  /// No description provided for @dropdownNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching options.'**
  String get dropdownNoMatches;

  /// No description provided for @storagePoolMemberSummary.
  ///
  /// In en, this message translates to:
  /// **'{category} · {status}'**
  String storagePoolMemberSummary(String category, String status);

  /// No description provided for @storageValueOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get storageValueOnline;

  /// No description provided for @storageValueOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get storageValueOffline;

  /// No description provided for @storageValueDegraded.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get storageValueDegraded;

  /// No description provided for @storageValueFaulted.
  ///
  /// In en, this message translates to:
  /// **'Faulted'**
  String get storageValueFaulted;

  /// No description provided for @storageValueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get storageValueUnavailable;

  /// No description provided for @storageValueData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get storageValueData;

  /// No description provided for @storageValueCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get storageValueCache;

  /// No description provided for @storageValueLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get storageValueLog;

  /// No description provided for @storageValueSpare.
  ///
  /// In en, this message translates to:
  /// **'Spare'**
  String get storageValueSpare;

  /// No description provided for @storageValueSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get storageValueSpecial;

  /// No description provided for @storageIscsiTargetModeIscsi.
  ///
  /// In en, this message translates to:
  /// **'iSCSI'**
  String get storageIscsiTargetModeIscsi;

  /// No description provided for @storageSectionError.
  ///
  /// In en, this message translates to:
  /// **'{section}: {detail}'**
  String storageSectionError(String section, String detail);

  /// No description provided for @storageIscsiTargetsLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI targets'**
  String get storageIscsiTargetsLabel;

  /// No description provided for @storageIscsiExtentsLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI extents'**
  String get storageIscsiExtentsLabel;

  /// No description provided for @storageIscsiPortalsLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI portals'**
  String get storageIscsiPortalsLabel;

  /// No description provided for @storageIscsiInitiatorsLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiators'**
  String get storageIscsiInitiatorsLabel;

  /// No description provided for @storageIscsiAssociationsLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI associations'**
  String get storageIscsiAssociationsLabel;

  /// No description provided for @storageIscsiChapLabel.
  ///
  /// In en, this message translates to:
  /// **'iSCSI CHAP credentials'**
  String get storageIscsiChapLabel;

  /// No description provided for @storageShareProtocolPath.
  ///
  /// In en, this message translates to:
  /// **'{protocol} · {path}'**
  String storageShareProtocolPath(String protocol, String path);

  /// No description provided for @storageReadOnlySuffix.
  ///
  /// In en, this message translates to:
  /// **' · Read only'**
  String get storageReadOnlySuffix;

  /// No description provided for @storageNfsListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'NFS · {path} · {access}'**
  String storageNfsListSubtitle(String path, String access);

  /// No description provided for @storageIscsiTargetListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{mode} target · {name} · {count} portal groups'**
  String storageIscsiTargetListSubtitle(String mode, String name, int count);

  /// No description provided for @storageIscsiInitiatorListAll.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiators · All clients'**
  String get storageIscsiInitiatorListAll;

  /// No description provided for @storageIscsiInitiatorListAllowed.
  ///
  /// In en, this message translates to:
  /// **'iSCSI initiators · {count} allowed'**
  String storageIscsiInitiatorListAllowed(int count);

  /// No description provided for @storageIscsiExtentListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} extent · {store}'**
  String storageIscsiExtentListSubtitle(String type, String store);

  /// No description provided for @storageIscsiExtentListSubtitleReadOnly.
  ///
  /// In en, this message translates to:
  /// **'{type} extent · {store} · Read only'**
  String storageIscsiExtentListSubtitleReadOnly(String type, String store);

  /// No description provided for @storageDeleteExtentBackingWarning.
  ///
  /// In en, this message translates to:
  /// **'Removes {store} and everything on it.'**
  String storageDeleteExtentBackingWarning(String store);

  /// No description provided for @sysRouteDestinationHelper.
  ///
  /// In en, this message translates to:
  /// **'CIDR, e.g. 192.168.50.0/24'**
  String get sysRouteDestinationHelper;

  /// No description provided for @storageWebShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'WebShare · {path}'**
  String storageWebShareSubtitle(Object path);

  /// No description provided for @connMsgSignInAgainToReconnect.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to reconnect to {name}.'**
  String connMsgSignInAgainToReconnect(Object name);

  /// No description provided for @connMsgCredentialRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter or unlock a credential before connecting.'**
  String get connMsgCredentialRequired;

  /// No description provided for @connMsgAuthenticationRejected.
  ///
  /// In en, this message translates to:
  /// **'The username or credential was not accepted.'**
  String get connMsgAuthenticationRejected;

  /// No description provided for @connMsgCredentialExpired.
  ///
  /// In en, this message translates to:
  /// **'This credential has expired.'**
  String get connMsgCredentialExpired;

  /// No description provided for @connMsgCertificateExpired.
  ///
  /// In en, this message translates to:
  /// **'The server\'s TLS certificate has expired. Ask the TrueNAS administrator to renew it.'**
  String get connMsgCertificateExpired;

  /// No description provided for @connMsgCertificateExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'The TLS certificate for {authority} expires soon. Ask the TrueNAS administrator to renew it.'**
  String connMsgCertificateExpiringSoon(String authority);

  /// No description provided for @connMsgRedirectUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Redirected authentication is not supported yet.'**
  String get connMsgRedirectUnsupported;

  /// No description provided for @connMsgInsecureConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect securely. Check the address and certificate.'**
  String get connMsgInsecureConnection;

  /// No description provided for @connMsgCertificateInspectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not inspect the server certificate. Check the address and try again.'**
  String get connMsgCertificateInspectionFailed;

  /// No description provided for @connMsgCredentialAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access the saved sign-in. Unlock TrueDock and try again.'**
  String get connMsgCredentialAccessFailed;

  /// No description provided for @connMsgAppPinAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unlock the saved sign-in with the TrueDock PIN.'**
  String get connMsgAppPinAccessFailed;

  /// No description provided for @connMsgUnsupportedServer.
  ///
  /// In en, this message translates to:
  /// **'This server or TrueNAS version is not supported by TrueDock.'**
  String get connMsgUnsupportedServer;

  /// No description provided for @connMsgInvalidSavedData.
  ///
  /// In en, this message translates to:
  /// **'The saved server information is invalid. Register the server again.'**
  String get connMsgInvalidSavedData;

  /// No description provided for @connMsgAddressTestSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The active sign-in is unavailable. Let the server roll back and sign in again.'**
  String get connMsgAddressTestSignInUnavailable;

  /// No description provided for @connMsgAddressTestOtpRequired.
  ///
  /// In en, this message translates to:
  /// **'This sign-in requires a new verification code. Let the change roll back, then reconnect normally.'**
  String get connMsgAddressTestOtpRequired;

  /// No description provided for @connMsgAddressTestAuthenticationRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the active sign-in at the new address.'**
  String get connMsgAddressTestAuthenticationRejected;

  /// No description provided for @connMsgAddressTestInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid secure server address.'**
  String get connMsgAddressTestInvalidAddress;

  /// No description provided for @connMsgSavedSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Connected, but the sign-in could not be saved.'**
  String get connMsgSavedSignInFailed;

  /// No description provided for @connMsgServerRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Connected, but the server could not be registered.'**
  String get connMsgServerRegistrationFailed;

  /// No description provided for @securityBiometricPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock TrueDock'**
  String get securityBiometricPromptTitle;

  /// No description provided for @securityBiometricPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your saved server'**
  String get securityBiometricPromptSubtitle;

  /// No description provided for @securityBiometricPromptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get securityBiometricPromptCancel;

  /// No description provided for @dataMsgDecodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not decode {method}.'**
  String dataMsgDecodeFailed(Object method);

  /// No description provided for @dataMsgInvalidData.
  ///
  /// In en, this message translates to:
  /// **'{method} returned invalid data.'**
  String dataMsgInvalidData(Object method);

  /// No description provided for @dataMsgMethodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{method} is not available on this TrueNAS version.'**
  String dataMsgMethodUnavailable(Object method);

  /// No description provided for @dataMsgDecodeDiskTemperatures.
  ///
  /// In en, this message translates to:
  /// **'Could not decode disk.temperatures.'**
  String get dataMsgDecodeDiskTemperatures;

  /// No description provided for @dataMsgDecodeCatalogApps.
  ///
  /// In en, this message translates to:
  /// **'Could not decode catalog.apps.'**
  String get dataMsgDecodeCatalogApps;

  /// No description provided for @dataMsgDecodeCatalogTrains.
  ///
  /// In en, this message translates to:
  /// **'Could not decode catalog.trains.'**
  String get dataMsgDecodeCatalogTrains;

  /// No description provided for @dataMsgDecodeAppDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not decode catalog.get_app_details.'**
  String get dataMsgDecodeAppDetails;

  /// No description provided for @dataMsgNoInstallableVersions.
  ///
  /// In en, this message translates to:
  /// **'No installable app versions were returned.'**
  String get dataMsgNoInstallableVersions;

  /// No description provided for @dataMsgReportingUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Reporting is not available on this TrueNAS version.'**
  String get dataMsgReportingUnsupported;

  /// No description provided for @dataMsgReportingUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read reporting data.'**
  String get dataMsgReportingUnreadable;

  /// No description provided for @sysTunableTitle.
  ///
  /// In en, this message translates to:
  /// **'System tunables'**
  String get sysTunableTitle;

  /// No description provided for @sysTunableNavSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SYSCTL, UDEV, and ZFS parameters'**
  String get sysTunableNavSubtitle;

  /// No description provided for @sysTunableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Low-level settings applied by TrueNAS. Incorrect values can affect stability or access.'**
  String get sysTunableSubtitle;

  /// No description provided for @sysTunableEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom tunables.'**
  String get sysTunableEmpty;

  /// No description provided for @sysTunableCreate.
  ///
  /// In en, this message translates to:
  /// **'Add tunable'**
  String get sysTunableCreate;

  /// No description provided for @sysTunableCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New system tunable'**
  String get sysTunableCreateTitle;

  /// No description provided for @sysTunableEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit system tunable'**
  String get sysTunableEditTitle;

  /// No description provided for @sysTunableType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sysTunableType;

  /// No description provided for @sysTunableTypeSysctl.
  ///
  /// In en, this message translates to:
  /// **'SYSCTL · Runtime kernel'**
  String get sysTunableTypeSysctl;

  /// No description provided for @sysTunableTypeUdev.
  ///
  /// In en, this message translates to:
  /// **'UDEV · Device rule'**
  String get sysTunableTypeUdev;

  /// No description provided for @sysTunableTypeZfs.
  ///
  /// In en, this message translates to:
  /// **'ZFS · Module parameter'**
  String get sysTunableTypeZfs;

  /// No description provided for @sysTunableVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get sysTunableVariable;

  /// No description provided for @sysTunableVariableSysctlHelper.
  ///
  /// In en, this message translates to:
  /// **'Kernel parameter, for example kernel.watchdog'**
  String get sysTunableVariableSysctlHelper;

  /// No description provided for @sysTunableVariableUdevHelper.
  ///
  /// In en, this message translates to:
  /// **'Rules file name; TrueNAS appends .rules'**
  String get sysTunableVariableUdevHelper;

  /// No description provided for @sysTunableVariableZfsHelper.
  ///
  /// In en, this message translates to:
  /// **'OpenZFS module parameter name'**
  String get sysTunableVariableZfsHelper;

  /// No description provided for @sysTunableValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get sysTunableValue;

  /// No description provided for @sysTunableComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get sysTunableComment;

  /// No description provided for @sysTunableEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get sysTunableEnabled;

  /// No description provided for @sysTunableDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sysTunableDisabled;

  /// No description provided for @sysTunableUpdateInitramfs.
  ///
  /// In en, this message translates to:
  /// **'Update initramfs'**
  String get sysTunableUpdateInitramfs;

  /// No description provided for @sysTunableUpdateInitramfsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required for the ZFS parameter to survive boot unless rebuilt manually.'**
  String get sysTunableUpdateInitramfsSubtitle;

  /// No description provided for @sysTunableValidationVariable.
  ///
  /// In en, this message translates to:
  /// **'Enter a variable name.'**
  String get sysTunableValidationVariable;

  /// No description provided for @sysTunableValidationValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value.'**
  String get sysTunableValidationValue;

  /// No description provided for @sysTunableCreateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Add this system tunable?'**
  String get sysTunableCreateConfirmTitle;

  /// No description provided for @sysTunableUpdateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply these tunable changes?'**
  String get sysTunableUpdateConfirmTitle;

  /// No description provided for @sysTunableCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Add tunable'**
  String get sysTunableCreateAction;

  /// No description provided for @sysTunableUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get sysTunableUpdateAction;

  /// No description provided for @sysTunableSysctlConsequence.
  ///
  /// In en, this message translates to:
  /// **'SYSCTL settings generally take effect immediately across the server.'**
  String get sysTunableSysctlConsequence;

  /// No description provided for @sysTunableUdevConsequence.
  ///
  /// In en, this message translates to:
  /// **'UDEV rules apply when matching hardware events occur.'**
  String get sysTunableUdevConsequence;

  /// No description provided for @sysTunableZfsConsequence.
  ///
  /// In en, this message translates to:
  /// **'ZFS module settings can require an initramfs update and reboot.'**
  String get sysTunableZfsConsequence;

  /// No description provided for @sysTunableRiskConsequence.
  ///
  /// In en, this message translates to:
  /// **'A wrong low-level setting can destabilize TrueNAS or interrupt access.'**
  String get sysTunableRiskConsequence;

  /// No description provided for @sysTunableDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this system tunable?'**
  String get sysTunableDeleteTitle;

  /// No description provided for @sysTunableDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete tunable'**
  String get sysTunableDeleteAction;

  /// No description provided for @sysTunableDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'The stored override is removed. A reboot or device event may be required before the running value fully reverts.'**
  String get sysTunableDeleteConsequence;

  /// No description provided for @sysTunableCreated.
  ///
  /// In en, this message translates to:
  /// **'System tunable added.'**
  String get sysTunableCreated;

  /// No description provided for @sysTunableUpdated.
  ///
  /// In en, this message translates to:
  /// **'System tunable updated.'**
  String get sysTunableUpdated;

  /// No description provided for @sysTunableDeleted.
  ///
  /// In en, this message translates to:
  /// **'System tunable deleted.'**
  String get sysTunableDeleted;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About TrueDock'**
  String get aboutTitle;

  /// No description provided for @aboutSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, licenses, and project links'**
  String get aboutSettingsSubtitle;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Dock your TrueNAS'**
  String get aboutTagline;

  /// No description provided for @aboutMadeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ in 🇰🇷'**
  String get aboutMadeWith;

  /// No description provided for @aboutSectionApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get aboutSectionApp;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @aboutVersionValue.
  ///
  /// In en, this message translates to:
  /// **'{version} (build {build})'**
  String aboutVersionValue(String version, String build);

  /// No description provided for @aboutLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get aboutLicenseLabel;

  /// No description provided for @aboutSectionProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get aboutSectionProject;

  /// No description provided for @aboutRepositoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get aboutRepositoryLabel;

  /// No description provided for @aboutRepositorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse the sources, report an issue, or contribute on GitHub.'**
  String get aboutRepositorySubtitle;

  /// No description provided for @aboutSectionOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutSectionOpenSource;

  /// No description provided for @aboutOpenSourceIntro.
  ///
  /// In en, this message translates to:
  /// **'TrueDock is built on these open source packages. Thank you to their maintainers.'**
  String get aboutOpenSourceIntro;

  /// No description provided for @aboutOpenSourceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 package} other{{count} packages}}'**
  String aboutOpenSourceCount(int count);

  /// No description provided for @aboutLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link on this device.'**
  String get aboutLinkFailed;

  /// No description provided for @aboutOpenSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Packages bundled into TrueDock and their licenses'**
  String get aboutOpenSourceSubtitle;

  /// No description provided for @aboutPackageOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open package page'**
  String get aboutPackageOpenPage;

  /// No description provided for @aboutPackageLicenseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No bundled license text was found for this package. Use the package page to view its license.'**
  String get aboutPackageLicenseUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
