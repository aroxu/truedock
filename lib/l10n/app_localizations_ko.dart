// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'TrueDock';

  @override
  String get navOverview => '개요';

  @override
  String get navStorage => '스토리지';

  @override
  String get navProtection => '보호';

  @override
  String get navApps => '앱';

  @override
  String get navSystem => '시스템';

  @override
  String get navAppSettings => '앱 설정';

  @override
  String get actionCancel => '취소';

  @override
  String get actionReview => '검토';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionClose => '닫기';

  @override
  String get actionDone => '완료';

  @override
  String get actionReconnect => '다시 연결';

  @override
  String get actionReconnecting => '재연결 중…';

  @override
  String get actionRefresh => '새로고침';

  @override
  String get actionAddServer => '서버 추가';

  @override
  String get actionConnectServer => '서버 연결';

  @override
  String authSucceededSigningIn(String serverName) {
    return '인증 성공. $serverName에 로그인 중…';
  }

  @override
  String get actionContinue => '계속';

  @override
  String get connectionLostTitle => '연결 끊김';

  @override
  String connectionLostTitleNamed(String serverName) {
    return '$serverName 연결 끊김';
  }

  @override
  String get connectionLostStaleData => 'TrueDock이 마지막으로 받은 데이터를 표시 중입니다.';

  @override
  String get connectionLostReconnectFailed => '서버에 다시 연결하지 못했습니다.';

  @override
  String get overviewAtAGlance => '한눈에 보기';

  @override
  String get overviewLivePerformance => '실시간 성능';

  @override
  String get overviewRecentActivity => '최근 활동';

  @override
  String get activityAlertDetails => '알림 상세 정보';

  @override
  String get activityAlertSeverity => '심각도';

  @override
  String get activityAlertOccurredAt => '최근 발생';

  @override
  String get activityAlertCritical => '심각';

  @override
  String get activityAlertWarning => '경고';

  @override
  String get activityAlertInfo => '정보';

  @override
  String get overviewConnectedSecurely => '안전하게 연결됨';

  @override
  String get overviewNoServerConnected => '연결된 서버 없음';

  @override
  String get overviewHeroTitle => '브라우저 없이 만나는 TrueNAS';

  @override
  String get overviewHeroDescription =>
      '여기서 모니터링하고 관리할 TrueNAS SCALE 25.10+ 서버를 추가하세요.';

  @override
  String get metricUptime => '가동 시간';

  @override
  String metricUptimeDuration(int days, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 $time',
      zero: '$time',
    );
    return '$_temp0';
  }

  @override
  String get metricMemory => '메모리';

  @override
  String get metricCpuCores => 'CPU 코어';

  @override
  String get metricHealth => '상태';

  @override
  String healthPoolIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '풀 문제 $count건',
      one: '풀 문제 1건',
    );
    return '$_temp0';
  }

  @override
  String get healthAttention => '주의';

  @override
  String get healthHealthy => '정상';

  @override
  String get reportingNoSamples => '아직 보고 샘플이 없습니다.';

  @override
  String get reportingCpuUtilisation => 'CPU 사용률';

  @override
  String get reportingMemoryInUse => '사용 중인 메모리';

  @override
  String get reportingLoadAverage => '평균 부하 (1분)';

  @override
  String get reportingNetworkTraffic => '네트워크 트래픽';

  @override
  String get reportingNetworkReceived => '수신';

  @override
  String get reportingNetworkSent => '송신';

  @override
  String get reportingDiskIo => '디스크 I/O';

  @override
  String get reportingDiskReads => '읽기';

  @override
  String get reportingDiskWrites => '쓰기';

  @override
  String get reportingCpuHistory => 'CPU 기록';

  @override
  String get reportingMemoryHistory => 'RAM 기록';

  @override
  String get reportingNetworkHistory => '네트워크 기록';

  @override
  String get reportingDiskHistory => '디스크 I/O 기록';

  @override
  String get reportingRangeHour => '1시간';

  @override
  String get reportingRangeDay => '24시간';

  @override
  String get reportingRangeWeek => '7일';

  @override
  String get reportingCurrent => '현재';

  @override
  String reportingChartSemantics(
    String label,
    String current,
    String minimum,
    String maximum,
  ) {
    return '$label. 현재 $current. 범위 $minimum에서 $maximum.';
  }

  @override
  String get reportingAverage => '평균';

  @override
  String get reportingMinimum => '최저';

  @override
  String get reportingMaximum => '최고';

  @override
  String get activityNoAttention => '주의가 필요한 활성 알림이나 최근 작업이 없습니다.';

  @override
  String get activityEmpty => '작업, 알림, 최근 변경 사항이 여기에 표시됩니다.';

  @override
  String get connectTitle => 'TrueNAS 서버 추가';

  @override
  String get registrationTitle => 'TrueNAS 서버 등록';

  @override
  String get serverEntryTitle => '서버 선택';

  @override
  String get serverRegisterAnother => '서버 등록하기';

  @override
  String get connectServerName => '서버 이름';

  @override
  String get connectServerNameHint => '홈 NAS';

  @override
  String get connectSecureAddress => '보안 주소';

  @override
  String get connectSecureAddressHint => 'https://truenas.local';

  @override
  String get connectSecureAddressHelper => 'TrueDock은 WSS /api/current에 연결합니다.';

  @override
  String get connectSignInWith => '로그인 방법';

  @override
  String get authApiKey => 'API 키';

  @override
  String get authLogin => '로그인';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authUsername => '사용자 이름';

  @override
  String get authUsernameRequired => '이 자격 증명에 연결된 계정을 입력하세요.';

  @override
  String get authCredentialRequired => '자격 증명을 입력하세요.';

  @override
  String get authShowCredential => '자격 증명 표시';

  @override
  String get authHideCredential => '자격 증명 숨기기';

  @override
  String get authKeepSignedIn => '로그인 유지';

  @override
  String get authUnlockWithBiometrics => '생체 인증으로 저장된 자격 증명을 잠금 해제하세요.';

  @override
  String get authBiometricUnlock => '생체 인증 잠금 해제';

  @override
  String get authBiometricUnlockDescription =>
      'TrueDock PIN 대신 Face ID, Touch ID 또는 지문을 사용합니다.';

  @override
  String get authCheckingBiometrics => '생체 인증 보호 확인 중…';

  @override
  String get authBiometricsUnavailable => '생체 인증 보호를 현재 사용할 수 없습니다.';

  @override
  String get authBiometricsProtected => '기기 생체 인증으로 보호됨';

  @override
  String get authBiometricsNotEnrolled => '먼저 Face ID, Touch ID 또는 지문을 설정하세요';

  @override
  String get authBiometricsUnsupported => '이 기기는 생체 인증 로그인을 지원하지 않습니다';

  @override
  String get authBiometricsTemporarilyUnavailable => '생체 인증 로그인을 현재 사용할 수 없습니다';

  @override
  String get authProtectWithAppPassword =>
      '별도의 TrueDock PIN으로 저장된 자격 증명을 보호합니다.';

  @override
  String get appPasswordCreateTitle => 'TrueDock PIN 생성';

  @override
  String get appPasswordCreateDescription =>
      '이 6자리 PIN은 이 기기의 저장된 자격 증명을 암호화합니다. TrueNAS 비밀번호와 별개이며 저장되거나 동기화되지 않습니다.';

  @override
  String get appPasswordExistingTitle => 'TrueDock PIN 입력';

  @override
  String get appPasswordExistingDescription =>
      '다른 서버의 저장된 로그인을 보호할 때 만든 동일한 TrueDock PIN을 입력하세요.';

  @override
  String get appPasswordLabel => 'TrueDock PIN';

  @override
  String get appPasswordConfirmLabel => 'TrueDock PIN 확인';

  @override
  String get appPasswordMinimum => '숫자 6자리를 입력하세요.';

  @override
  String get appPasswordMismatch => 'PIN이 일치하지 않습니다.';

  @override
  String get appPasswordIncorrect => 'TrueDock PIN이 올바르지 않습니다.';

  @override
  String appPasswordUnlockTitle(String serverName) {
    return '$serverName 잠금 해제';
  }

  @override
  String get appPasswordUnlockDescription =>
      '별도로 만든 TrueDock PIN을 입력하세요. TrueNAS 계정 비밀번호가 아닙니다.';

  @override
  String get appPasswordForgot => '비밀번호를 잊으셨나요?';

  @override
  String get appPasswordResetTitle => '저장된 로그인을 지울까요?';

  @override
  String get appPasswordResetDescription =>
      'TrueDock은 이 PIN을 복구할 수 없습니다. 생체 인증 잠금 해제 사본을 포함해 TrueDock PIN으로 보호된 모든 저장 로그인이 제거됩니다. 서버 프로필, TLS 인증서 신뢰, 기존 생체 인증 전용 로그인, TrueNAS 데이터는 그대로 유지됩니다.';

  @override
  String get appPasswordResetAction => '보호된 로그인 모두 지우기';

  @override
  String get authConnectingSecurely => '안전하게 연결 중…';

  @override
  String get authTransportNotice =>
      '자격 증명은 TLS를 통해서만 전송됩니다. 저장된 자격 증명은 플랫폼 보호 또는 암호화된 TrueDock PIN 금고를 사용합니다.';

  @override
  String get savedServersTitle => '저장된 서버';

  @override
  String get savedServerOptions => '저장된 서버 옵션';

  @override
  String get savedServerForget => '서버 삭제';

  @override
  String get savedServerSignInRequired => '로그인 필요';

  @override
  String savedServerEnterCredential(String serverName) {
    return '아래에 $serverName의 자격 증명을 입력하세요.';
  }

  @override
  String savedServerSignInTitle(String serverName) {
    return '$serverName 로그인';
  }

  @override
  String get savedServerAuthenticationFailed => '저장된 서버에 로그인하지 못했습니다.';

  @override
  String get serverManagementTitle => '서버';

  @override
  String get serverManagementDescription =>
      '등록된 TrueNAS 서버 간에 전환합니다. 자격 증명과 신뢰할 수 있는 인증서는 서버별로 격리됩니다.';

  @override
  String get serverManagementLoadFailed => '등록된 서버를 불러오지 못했습니다.';

  @override
  String get serverRenameTitle => '서버 이름 변경';

  @override
  String get serverRenameLabel => '서버 이름';

  @override
  String get serverRenameAction => '이름 변경';

  @override
  String get serverActive => '활성 서버';

  @override
  String get serverSwitchTitle => '서버를 전환하시겠습니까?';

  @override
  String serverSwitchDescription(String serverName) {
    return '현재 세션을 닫고 $serverName에 연결합니다. 서버에서 이미 실행 중인 작업은 계속됩니다.';
  }

  @override
  String get serverSwitchAction => '서버 전환';

  @override
  String get serverSwitching => '전환 중…';

  @override
  String get serverSigningIn => '로그인 중…';

  @override
  String get serverSwitchCredentialUnavailable => '이 서버에 저장된 로그인이 없습니다.';

  @override
  String get serverForgetTitle => '이 서버를 삭제하시겠습니까?';

  @override
  String serverForgetDescription(String serverName) {
    return '$serverName과 저장된 자격 증명을 이 기기에서 제거합니다.';
  }

  @override
  String serverForgetActiveDescription(String serverName) {
    return '$serverName에서 연결을 끊은 뒤, 이 기기에서 서버와 저장된 자격 증명을 제거합니다.';
  }

  @override
  String get connectHeroTitle => 'TrueNAS 관리의 새로운 정박지';

  @override
  String get connectHeroDescription => 'TrueNAS SCALE 25.10 이상을 지원합니다.';

  @override
  String get otpTitle => '이중 인증';

  @override
  String get otpCode => '일회용 코드';

  @override
  String get certificateChangedTitle => '서버 인증서가 변경됨';

  @override
  String get certificateExpiredTitle => '만료된 인증서';

  @override
  String get certificateTrustTitle => '이 서버를 신뢰하시겠습니까?';

  @override
  String get certificateVerifyTitle => '서버 인증서 검증';

  @override
  String certificateChangedDescription(String authority) {
    return '인증서가 $authority에 저장된 것과 더 이상 일치하지 않습니다. 이 변경을 예상한 경우에만 계속하세요.';
  }

  @override
  String get certificateExpiredDescription => '만료된 인증서 입니다. 계속 하시겠습니까?';

  @override
  String certificateTrustDescription(String authority) {
    return '$authority가 운영 체제에서 신뢰하지 않는 인증서를 사용합니다. 이 지문을 TrueNAS 서버와 비교하세요.';
  }

  @override
  String certificateTrustedDescription(String authority) {
    return '운영 체제가 $authority의 인증서를 신뢰합니다. 연결하기 전에 인증서 정보를 확인하세요.';
  }

  @override
  String get certificateUntrustedAcknowledge =>
      '인증서 지문을 확인했으며 운영 체제가 이 인증서를 신뢰하지 않는다는 점을 이해했습니다.';

  @override
  String get certificateFingerprint => 'SHA-256 지문';

  @override
  String get certificateSubject => '제목';

  @override
  String get certificateIssuer => '발급자';

  @override
  String get certificateValidUntil => '유효 기간';

  @override
  String get certificatePreviousFingerprint => '이전에 신뢰한 지문';

  @override
  String get certificateTrustNew => '새 인증서 신뢰';

  @override
  String get certificateExpiredContinue => '그래도 계속하기';

  @override
  String get certificateTrustAndConnect => '신뢰하고 연결';

  @override
  String get certificateVerifyAndConnect => '검증 후 연결';

  @override
  String get systemAppearance => '모양';

  @override
  String get systemAppearanceSubtitle => '색상, 라이트 및 다크 모드';

  @override
  String get systemReduceAnimations => '감소된 애니메이션';

  @override
  String get systemReduceAnimationsSubtitle =>
      'TrueDock 전체의 화면 전환과 움직임을 줄이고 즉시 표시합니다.';

  @override
  String get diagnosticsPrivacySection => '개인정보 보호';

  @override
  String get diagnosticsAnonymousTitle => '익명 진단 정보 수집';

  @override
  String get diagnosticsAnonymousDescription =>
      'TrueDock 개선을 위해 익명화된 충돌, 오류 및 성능 정보를 공유합니다. 서버 주소, 계정, 리소스 이름, API 데이터 및 인증 정보는 수집하지 않습니다.';

  @override
  String get diagnosticsNotConfigured =>
      '이 빌드에는 진단 정보 전송이 구성되어 있지 않습니다. 진단 기능을 사용할 수 있게 되면 이 설정을 적용합니다.';

  @override
  String get diagnosticsSaving => '진단 정보 설정을 저장하는 중…';

  @override
  String get diagnosticsUpdateFailed => '진단 정보 설정을 변경하지 못했습니다.';

  @override
  String get diagnosticsDisclosureTitle => '익명 진단 정보 수집을 끄시겠습니까?';

  @override
  String get diagnosticsDisableAction => '끄기';

  @override
  String get systemProtectedSignIn => 'TrueDock PIN';

  @override
  String get systemAppPasswordEnabled => '이 기기에서 사용 중';

  @override
  String get systemAppPasswordDisabled => '저장된 로그인을 보호할 PIN을 생성합니다.';

  @override
  String get systemChangeAppPassword => 'PIN 변경';

  @override
  String get systemChangeAppPasswordSubtitle => '모든 저장 로그인을 새 PIN으로 다시 암호화합니다.';

  @override
  String get systemChangeAppPasswordDescription =>
      '현재 PIN을 입력한 다음 새 6자리 PIN을 설정하세요. 저장된 서버 로그인은 유지됩니다.';

  @override
  String get systemCurrentAppPassword => '현재 PIN';

  @override
  String get systemNewAppPassword => '새 PIN';

  @override
  String get systemAppPasswordMustChange => '현재 PIN과 다른 PIN을 입력하세요.';

  @override
  String get appDataDangerSection => '기기 데이터';

  @override
  String get appDataResetTitle => '모든 TrueDock 데이터 초기화';

  @override
  String get appDataResetSubtitle =>
      '이 기기의 서버 프로필, 저장 로그인, PIN 데이터, 생체 인증 사본, 신뢰된 인증서 및 앱 설정을 모두 삭제합니다.';

  @override
  String get appDataResetDialogTitle => '이 기기의 모든 데이터를 초기화할까요?';

  @override
  String get appDataResetDescription =>
      'TrueDock에서 로그아웃하고 iOS Keychain 또는 Android 보안 저장소를 포함한 모든 로컬 TrueDock 데이터를 영구적으로 삭제합니다. TrueNAS 서버의 데이터와 설정은 변경하지 않습니다.';

  @override
  String get appDataResetIrreversible => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get appDataResetConfirmation => '초기화';

  @override
  String appDataResetTypePrompt(String confirmation) {
    return '계속하려면 코드 $confirmation를 입력하세요.';
  }

  @override
  String get appDataResetCodeLabel => '데이터 초기화 확인 코드';

  @override
  String get appDataResetAction => '모든 데이터 초기화';

  @override
  String get appDataResetFailed => 'TrueDock 로컬 데이터를 모두 삭제하지 못했습니다.';

  @override
  String get appDataResetCompleteTitle => '초기화 완료';

  @override
  String get appDataResetCompleteDescription =>
      '이 기기의 모든 TrueDock 데이터를 초기화했습니다. 이제 앱을 처음부터 다시 설정할 수 있습니다.';

  @override
  String get appDataResetCompleteAction => '확인';

  @override
  String systemSavedSignIns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장된 서버 로그인 $count개',
      one: '저장된 서버 로그인 1개',
    );
    return '$_temp0';
  }

  @override
  String get systemCheckingDeviceSecurity => '기기 보안 확인 중…';

  @override
  String get systemBiometricUnavailable => '생체 인증 보호를 사용할 수 없습니다';

  @override
  String get systemServerSection => '서버';

  @override
  String get systemNoServer => '서버 없음';

  @override
  String systemCommunityVersion(String version) {
    return 'Community $version';
  }

  @override
  String get systemConnectServer => 'TrueNAS 서버 연결';

  @override
  String get systemDisconnect => '연결 끊기';

  @override
  String get systemPinnedCertificate => '신뢰된 인증서';

  @override
  String certificateDetailsDescription(String authority) {
    return '$authority가 현재 제공하는 인증서를 이 서버에 저장된 지문과 비교합니다.';
  }

  @override
  String get certificateValidFrom => '유효 시작';

  @override
  String get certificateTrustStatus => '신뢰 상태';

  @override
  String get certificateSystemTrust => '시스템 신뢰';

  @override
  String get certificatePinnedAndMatched => 'TrueDock이 신뢰한 인증서와 일치함';

  @override
  String get certificatePinnedMismatch => 'TrueDock이 신뢰한 인증서와 일치하지 않음';

  @override
  String get certificateSystemTrusted => '운영 체제에서도 신뢰함';

  @override
  String get certificateTrueDockTrustedOnly => 'TrueDock이 이 서버에 한해 신뢰함';

  @override
  String get certificateExpiredWarning =>
      '이 인증서는 만료되었습니다. TrueNAS 관리자에게 인증서 갱신을 요청하세요.';

  @override
  String get certificateExpiringSoonWarning =>
      '이 인증서는 곧 만료됩니다. TrueNAS 관리자에게 인증서 갱신을 요청하세요.';

  @override
  String get certificateDetailsLoadFailed => '서버 인증서 정보를 읽지 못했습니다.';

  @override
  String get systemAdministration => '관리';

  @override
  String get systemGeneralSettings => '일반 설정';

  @override
  String get systemGeneralSettingsSubtitle => '호스트 이름, 시간대, 시스템 로그, 전원';

  @override
  String get systemAdvanced => '고급';

  @override
  String get systemAdvancedSubtitle => '부트 환경 및 복구';

  @override
  String get systemAlertsAndJobs => '알림 및 작업';

  @override
  String get systemUsersAndAccess => '사용자 및 접근';

  @override
  String get systemNetwork => '네트워크';

  @override
  String get systemUpdates => '업데이트';

  @override
  String get systemSettingsLoadFailed => '서버 설정을 불러오지 못했습니다.';

  @override
  String get systemActivityLoadFailed => '시스템 활동을 불러오지 못했습니다.';

  @override
  String get systemNoChanges => '저장할 변경 사항이 없습니다.';

  @override
  String get systemServerFallback => '이 TrueNAS 서버';

  @override
  String get systemSaveSettingsTitle => '서버 설정을 저장하시겠습니까?';

  @override
  String get systemGeneralSettingsTarget => '일반 설정';

  @override
  String get actionSaveChanges => '변경 사항 저장';

  @override
  String get systemHostnameChangeImpact =>
      '서버가 네트워크 설정을 다시 불러온 뒤 호스트 이름이 변경됩니다. 활성 세션은 영향을 받지 않습니다.';

  @override
  String get systemSettingsChangeImpact => '설정이 서버에 반영됩니다.';

  @override
  String get systemSettingsSaveFailed => 'TrueNAS가 설정을 저장하지 못했습니다.';

  @override
  String get systemSettingsSaved => '서버 설정이 저장되었습니다.';

  @override
  String get themeModeSystem => '시스템';

  @override
  String get themeModeLight => '라이트';

  @override
  String get themeModeDark => '다크';

  @override
  String get themeColor => '색상';

  @override
  String get themeSystemDynamicColor => '시스템 동적 색상';

  @override
  String get themeSystemDynamicColorSubtitle => 'Android 배경화면 색상 팔레트와 일치';

  @override
  String themeColorSemantics(String hex) {
    return '테마 색상 $hex';
  }

  @override
  String get themeCustomColor => '사용자 지정 색상';

  @override
  String get themeCustomSourceColor => '사용자 지정 기준 색상';

  @override
  String get themeHexColor => '16진수 색상';

  @override
  String get themeColorPickerArea => '색상 채도 및 밝기';

  @override
  String get themeColorHue => '색조';

  @override
  String get actionApply => '적용';

  @override
  String get themeInvalidHex => '16진수 여섯 자리를 입력하세요.';

  @override
  String get storageTitle => '스토리지';

  @override
  String get storageLoadFailed => '스토리지 정보를 불러오지 못했습니다.';

  @override
  String get storageLandingDescription => '풀, 디스크, 데이터셋, 스냅샷, 공유를 한곳에서.';

  @override
  String get storageFeaturePools => '풀';

  @override
  String get storageFeaturePoolsSubtitle => '용량, 토폴로지, 상태';

  @override
  String get storageFeatureDatasets => '데이터셋';

  @override
  String get storageFeatureDatasetsSubtitle => '속성, 할당량, 암호화';

  @override
  String get storageFeatureSnapshots => '스냅샷';

  @override
  String get storageFeatureSnapshotsSubtitle => '탐색, 생성, 복제, 복원';

  @override
  String get storageFeatureDisks => '디스크';

  @override
  String get storageFeatureDisksSubtitle => '목록, 용량, 온도';

  @override
  String get storageFeatureShares => '공유';

  @override
  String get storageFeatureSharesSubtitle => 'SMB, NFS, iSCSI, WebShare';

  @override
  String get storageRefreshTooltip => '스토리지 새로고침';

  @override
  String get storageDatasetCreated => '데이터셋이 생성되었습니다.';

  @override
  String get storageSmbShare => 'SMB 공유';

  @override
  String get storageNfsShare => 'NFS 공유';

  @override
  String get storageIscsiPortal => 'iSCSI 포털';

  @override
  String get storageIscsiInitiatorGroup => 'iSCSI 개시자 그룹';

  @override
  String get storageIscsiTarget => 'iSCSI 타겟';

  @override
  String get storageIscsiExtent => 'iSCSI 익스텐트';

  @override
  String get storageIscsiLunAssociation => 'iSCSI LUN 연결';

  @override
  String storageIscsiPortalWithAddress(String address) {
    return 'iSCSI 포털 · $address';
  }

  @override
  String storageDiskTitle(String name, String model) {
    return '$name · $model';
  }

  @override
  String get storageChapCredentials => 'CHAP 자격 증명';

  @override
  String get storageNoUnusedDisksForPool => '풀을 만드는 데 사용할 수 있는 여유 디스크가 없습니다.';

  @override
  String get storageCreateTargetExtentFirst => '먼저 타겟과 익스텐트를 하나 이상 만드세요.';

  @override
  String get storageCreateSnapshotRecursively => '스냅샷을 재귀적으로 만들기';

  @override
  String get storageIncludeChildDatasets => '하위 데이터셋 포함';

  @override
  String get storageDiskLabelModel => '모델';

  @override
  String get storageDiskLabelSerial => '시리얼';

  @override
  String get storageDiskUnknownModel => '알 수 없는 모델';

  @override
  String get storageDiskNoSerial => '시리얼 정보 없음';

  @override
  String get storageDiskLabelCapacity => '용량';

  @override
  String get storageDiskLabelMedia => '매체';

  @override
  String get storageDiskLabelPool => '풀';

  @override
  String get storageDiskLabelUnassigned => '할당되지 않음';

  @override
  String get storageDiskLabelRotation => '회전수';

  @override
  String get storageDiskLabelTemperature => '온도';

  @override
  String get storageDiskLabelRatedMaximum => '최대 정격';

  @override
  String get storageDiskLabelCriticalAt => '임계 온도';

  @override
  String get storageLabelUsed => '사용됨';

  @override
  String get storageLabelFree => '여유';

  @override
  String get storageLabelFragmentation => '단편화';

  @override
  String get poolScrubStart => '스크럽 시작';

  @override
  String get poolScrubStartSubtitle => '모든 블록을 검증합니다. 디스크 대역폭을 사용합니다.';

  @override
  String get poolScrubPause => '스크럽 일시정지';

  @override
  String get poolScrubPauseSubtitle => '진행 상황이 유지되며 나중에 이어할 수 있습니다.';

  @override
  String get poolScrubStop => '스크럽 중지';

  @override
  String get poolScrubStopSubtitle => '진행 상황이 폐기됩니다.';

  @override
  String get poolScrubResume => '스크럽 다시 시작';

  @override
  String get poolScrubPaused => '스크럽 일시정지됨';

  @override
  String get poolScrubRunning => '스크럽 실행 중';

  @override
  String poolScrubProgress(double percent) {
    return '$percent% 완료';
  }

  @override
  String get poolMembers => '풀 멤버';

  @override
  String poolMembersCount(int count) {
    return '디바이스 $count개';
  }

  @override
  String get poolAttachDisk => '디스크 연결';

  @override
  String get poolAttachDiskSubtitle => '미러 또는 스트라이프에 디스크를 추가합니다. 리실버가 시작됩니다.';

  @override
  String get poolReplaceDisk => '디스크 교체';

  @override
  String get poolReplaceDiskSubtitle =>
      '멤버를 새 디스크로 교체합니다. 리실버 후 이전 디스크가 제거됩니다.';

  @override
  String get poolExportOrDestroy => '풀 내보내기 또는 파괴';

  @override
  String get poolExportOrDestroySubtitle => '이 서버에서 풀을 제거합니다.';

  @override
  String get poolMembersDescription =>
      '디바이스를 오프라인으로 전환하면 다시 온라인으로 돌리거나 교체할 때까지 풀이 성능 저하 상태가 됩니다.';

  @override
  String poolMemberCategoryStatus(String category, String status) {
    return '$category · $status';
  }

  @override
  String get poolTakeOffline => '오프라인으로 전환';

  @override
  String get poolBringOnline => '온라인으로 전환';

  @override
  String get poolOfflineUseOnly => '오프라인 전용';

  @override
  String get poolAttachDescription =>
      '디스크를 추가할 vdev를 선택하세요. 미러와 스트라이프 vdev만 디스크 연결을 허용하며, 미러에 연결하면 리실버가 시작됩니다.';

  @override
  String get poolNoUnusedDisks => '이 서버에 사용 가능한 여유 디스크가 없습니다.';

  @override
  String poolVdevTitle(String guid) {
    return 'vdev $guid';
  }

  @override
  String poolContainsMember(String name, String status) {
    return '$name 포함 · $status';
  }

  @override
  String get poolReplaceDescription =>
      '교체할 멤버를 선택한 뒤 새 디스크를 선택하세요. 리실버가 끝나면 이전 디스크가 풀에서 제거되며 안전하게 분리할 수 있습니다.';

  @override
  String get poolForceRemoveOldDisk => '이전 디스크 강제 제거';

  @override
  String get poolForceRemoveOldDiskSubtitle =>
      '여전히 읽고 있는 이전 디스크도 제거합니다. 디스크가 고장난 경우에만 사용하세요.';

  @override
  String get poolChooseReplacementDisk => '교체 디스크 선택';

  @override
  String poolAttachToVdev(String guid) {
    return 'vdev $guid에 연결';
  }

  @override
  String poolReplaceTarget(String name) {
    return '$name 교체';
  }

  @override
  String get poolExportTitle => '풀 내보내기';

  @override
  String get poolExportDescription =>
      '내보내면 이 서버에서 풀을 분리합니다. 데이터를 파괴하지 않으면 디스크를 여기나 다른 시스템에서 다시 가져올 수 있습니다.';

  @override
  String get poolDeleteSharesAndTasks => '이 풀을 사용하는 공유와 작업 삭제';

  @override
  String get poolDestroyAllData => '디스크의 모든 데이터 파괴';

  @override
  String get poolDestroyAllDataSubtitle => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get poolOperationsUnavailable =>
      '이 TrueNAS 버전은 TrueDock에 풀 작업을 노출하지 않습니다.';

  @override
  String poolStatusFree(String status, String free) {
    return '$status · $free 여유';
  }

  @override
  String get datasetCreateFilesystem => '데이터셋 생성';

  @override
  String get datasetCreateVolume => '볼륨 생성';

  @override
  String get datasetVolumeDescription =>
      '볼륨은 iSCSI 익스텐트와 가상 머신 디스크가 사용하는 블록 디바이스입니다. 암호화는 선택한 부모에서 상속됩니다.';

  @override
  String get datasetFilesystemDescription => '암호화 설정은 선택한 부모에서 상속됩니다.';

  @override
  String get datasetTypeFilesystem => '파일시스템';

  @override
  String get datasetTypeVolume => '볼륨';

  @override
  String get datasetParent => '부모';

  @override
  String get datasetVolumeName => '볼륨 이름';

  @override
  String get datasetName => '데이터셋 이름';

  @override
  String get datasetEnterVolumeName => '볼륨 이름을 입력하세요.';

  @override
  String get datasetEnterName => '데이터셋 이름을 입력하세요.';

  @override
  String get datasetUseParentForPaths => '경로에는 부모 필드를 사용하세요.';

  @override
  String get datasetSizeInGib => '크기(GiB)';

  @override
  String get datasetEnterSizeInGib => 'GiB 단위로 크기를 입력하세요.';

  @override
  String get datasetEnterSizePositive => '0보다 큰 크기를 입력하세요.';

  @override
  String get datasetSparseThin => '스파스(씬 프로비저닝)';

  @override
  String get datasetSparseSubtitle =>
      '미리 공간을 예약하지 않습니다. 풀이 가득 차면 볼륨이 여유 공간을 보고함에도 불구하고 쓰기가 실패할 수 있습니다.';

  @override
  String get datasetWorkloadOptimization => '워크로드 최적화';

  @override
  String get datasetShareGeneric => '일반';

  @override
  String get datasetShareSmb => 'SMB';

  @override
  String get datasetShareNfs => 'NFS';

  @override
  String get datasetShareMultiprotocol => '멀티프로토콜';

  @override
  String get datasetShareApps => '앱';

  @override
  String get datasetCreating => '생성 중…';

  @override
  String get datasetOperationFailed => 'TrueNAS 작업이 실패했습니다.';

  @override
  String get datasetEditTitle => '데이터셋 편집';

  @override
  String get datasetReviewTitle => '데이터셋 변경 검토';

  @override
  String get datasetApplyChanges => '변경 사항 적용';

  @override
  String get datasetReview => '검토';

  @override
  String get datasetComments => '주석';

  @override
  String get datasetCompression => '압축';

  @override
  String get datasetSync => '동기화';

  @override
  String get datasetSyncInherit => '상속';

  @override
  String get datasetSyncStandard => '표준';

  @override
  String get datasetSyncDisabled => '비활성';

  @override
  String get datasetSyncAlways => '항상';

  @override
  String get datasetAtimeDisabled => '끔';

  @override
  String get datasetReadOnly => '읽기 전용';

  @override
  String get datasetReadOnlyDescription => '이 데이터셋에 쓰기 금지';

  @override
  String get datasetReadOnlyWarning => '이 데이터셋에 쓰는 애플리케이션과 공유가 실패하기 시작합니다.';

  @override
  String get datasetQuota => '할당량';

  @override
  String get datasetDataQuota => '데이터 할당량';

  @override
  String get datasetDataQuotaDescription => '이 데이터셋에 직접 쓴 데이터만 제한합니다.';

  @override
  String get datasetDatasetQuota => '데이터셋 할당량';

  @override
  String get datasetDatasetQuotaDescription => '스냅샷을 포함해 이 데이터셋과 하위 항목을 제한합니다.';

  @override
  String get datasetQuotaLeaveEmpty => '제한 없음은 비워두세요';

  @override
  String get datasetQuotaEnterPositive => '할당량 크기를 양수로 입력하세요.';

  @override
  String get datasetNothingChanged => '이 데이터셋에서 변경된 항목이 없습니다.';

  @override
  String get datasetReadOnlyReviewWarning =>
      '읽기 전용을 다시 끌 때까지 이 데이터셋에 쓰는 앱과 공유에서 오류가 발생합니다.';

  @override
  String get datasetSyncDisabledWarning =>
      '동기화를 비활성화하면 서버 전원이 끊길 때 최근 쓰기 내용이 손실될 수 있습니다.';

  @override
  String get datasetChangeCommentsInherited => '설명을 상위 데이터셋에서 상속합니다.';

  @override
  String get datasetChangeCommentsCleared => '설명을 지웁니다.';

  @override
  String datasetChangeCommentsSet(String value) {
    return '설명을 ‘$value’(으)로 설정합니다.';
  }

  @override
  String get datasetChangeQuotaInherited => '데이터셋 할당량을 상위 데이터셋에서 상속합니다.';

  @override
  String get datasetChangeQuotaRemoved => '데이터셋 할당량을 제거합니다.';

  @override
  String datasetChangeQuotaSet(String value) {
    return '데이터셋 할당량을 $value(으)로 설정합니다.';
  }

  @override
  String get datasetChangeRefquotaInherited => '데이터 할당량을 상위 데이터셋에서 상속합니다.';

  @override
  String get datasetChangeRefquotaRemoved => '데이터 할당량을 제거합니다.';

  @override
  String datasetChangeRefquotaSet(String value) {
    return '데이터 할당량을 $value(으)로 설정합니다.';
  }

  @override
  String get datasetChangeReadOnlyInherited => '읽기 전용 설정을 상위 데이터셋에서 상속합니다.';

  @override
  String get datasetChangeReadOnlyEnabled => '데이터셋을 읽기 전용으로 변경합니다.';

  @override
  String get datasetChangeReadOnlyDisabled => '데이터셋을 쓰기 가능으로 변경합니다.';

  @override
  String get datasetChangeCompressionInherited => '압축 설정을 상위 데이터셋에서 상속합니다.';

  @override
  String datasetChangeCompressionSet(String value) {
    return '압축을 $value(으)로 설정합니다.';
  }

  @override
  String get datasetChangeSyncInherited => '동기화 설정을 상위 데이터셋에서 상속합니다.';

  @override
  String datasetChangeSyncSet(String value) {
    return '동기화를 $value(으)로 설정합니다.';
  }

  @override
  String datasetChangePropertyUpdated(String property) {
    return '$property 속성을 변경합니다.';
  }

  @override
  String get datasetCompressionInherit => '상속';

  @override
  String get datasetCompressionOff => '끔';

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
  String get datasetAtimeInherit => '상속';

  @override
  String get datasetAtimeOn => '켬';

  @override
  String get datasetExecInherit => '상속';

  @override
  String get datasetExecOn => '켬';

  @override
  String get datasetExecOff => '끔';

  @override
  String get datasetBlockSizeInherit => '상속';

  @override
  String get datasetStorageInherit => '상속';

  @override
  String get poolCreateReviewTitle => '새 풀 검토';

  @override
  String get poolCreateTitle => '풀 생성';

  @override
  String get poolCreateClose => '닫기';

  @override
  String get poolCreateBack => '뒤로';

  @override
  String get poolCreateCancel => '취소';

  @override
  String get poolCreateReview => '검토';

  @override
  String get poolCreateNameLabel => '풀 이름';

  @override
  String get poolCreateNameHelper => '데이터셋 루트 이름으로 사용됩니다. 문자로 시작하세요.';

  @override
  String get poolCreateDataVdevs => '데이터 vdev';

  @override
  String get poolCreateDataVdevsDescription =>
      '데이터 계층은 필수입니다. 각 vdev는 같은 레이아웃의 디스크를 묶으며, 풀은 여러 데이터 vdev에 걸쳐 데이터를 스트라이핑합니다.';

  @override
  String get poolCreateVdevLayout => 'vdev 레이아웃';

  @override
  String get poolCreateAddDataVdev => '데이터 vdev 추가';

  @override
  String poolCreateDataVdevLabel(int index) {
    return '데이터 vdev $index';
  }

  @override
  String get poolCreateCache => '캐시 (L2ARC, 선택 사항)';

  @override
  String poolCreateCacheVdevLabel(int index) {
    return '캐시 vdev $index';
  }

  @override
  String get poolCreateAddCacheVdev => '캐시 vdev 추가';

  @override
  String get poolCreateOptions => '옵션';

  @override
  String get poolCreateEncryption => '암호화';

  @override
  String get poolCreateEncryptionSubtitle =>
      '풀의 저장 데이터를 암호화합니다. 키를 직접 관리해야 합니다.';

  @override
  String get poolCreateDeduplication => '중복 제거';

  @override
  String get poolCreateDeduplicationSubtitle =>
      '블록 단위 중복 제거입니다. 메모리를 더 사용하므로 활성화 전에 RAM을 확인하세요.';

  @override
  String get poolCreateAutoTrim => '자동 TRIM';

  @override
  String get poolCreateAutoTrimSubtitle => '사용하지 않는 공간을 자동으로 회수합니다.';

  @override
  String get poolCreateReviewName => '이름';

  @override
  String poolCreateReviewDataVdevsValue(int vdevCount, int diskCount) {
    return '$vdevCount개 · 디스크 $diskCount개';
  }

  @override
  String poolCreateReviewVdevLabel(int index) {
    return '  vdev $index';
  }

  @override
  String poolCreateReviewVdevValue(String type, int diskCount) {
    return '$type · 디스크 $diskCount개';
  }

  @override
  String get poolCreateReviewCacheVdevs => '캐시 vdev';

  @override
  String poolCreateReviewCacheVdevsValue(int count) {
    return '$count';
  }

  @override
  String get poolCreateReviewTotalDisks => '전체 디스크';

  @override
  String get poolCreateOn => '켬';

  @override
  String get poolCreateOff => '끔';

  @override
  String get poolCreateNoticeEncrypted =>
      '암호화된 풀을 생성하면 선택한 모든 디스크가 포맷됩니다. 복구 키를 안전하게 보관하지 않으면 데이터를 복구할 수 없습니다.';

  @override
  String get poolCreateNoticePlain => '풀을 생성하면 선택한 모든 디스크가 포맷되며 기존 데이터가 삭제됩니다.';

  @override
  String get poolCreateNoticeDedup =>
      '중복 제거는 메모리 사용량을 늘립니다. 부하가 걸릴 때 서버 메모리가 부족해지면 비활성화하세요.';

  @override
  String get poolCreateNoticeStripe =>
      '스트라이프 및 단일 디스크 풀에는 중복성이 없습니다. 디스크 하나에 장애가 나면 풀을 잃습니다. 안전을 위해 미러 또는 RAIDZ를 사용하세요.';

  @override
  String get poolCreateNoDisksSelected => '선택한 디스크 없음';

  @override
  String poolCreateDisksCount(int count, String names) {
    return '디스크 $count개: $names';
  }

  @override
  String get poolCreateRemoveVdev => 'vdev 제거';

  @override
  String get poolCreateSelectDisks => '디스크 선택';

  @override
  String poolCreateDiskPickerHint(String type, int minimum, int selected) {
    return '$type에는 디스크가 최소 $minimum개 필요합니다. 선택됨: $selected개';
  }

  @override
  String poolCreateAddDisks(int count) {
    return '디스크 $count개 추가';
  }

  @override
  String poolCreateSelectAtLeast(int minimum) {
    return '최소 $minimum개 선택';
  }

  @override
  String get poolVdevStripe => '스트라이프';

  @override
  String get poolVdevMirror => '미러';

  @override
  String get poolVdevRaidz1 => 'RAIDZ1';

  @override
  String get poolVdevRaidz2 => 'RAIDZ2';

  @override
  String get poolVdevRaidz3 => 'RAIDZ3';

  @override
  String get poolVdevStripeWarning => '중복성이 없습니다. 디스크 하나에 장애가 나면 풀을 잃습니다.';

  @override
  String get poolVdevMirrorWarning => '각 미러 쌍마다 디스크 하나의 장애를 허용합니다.';

  @override
  String get poolVdevRaidz1Warning => '디스크 하나의 장애를 허용합니다.';

  @override
  String get poolVdevRaidz2Warning => '디스크 두 개의 장애를 허용합니다.';

  @override
  String get poolVdevRaidz3Warning => '디스크 세 개의 장애를 허용합니다.';

  @override
  String get poolValidationNameRequired => '풀 이름을 입력하세요.';

  @override
  String get poolValidationNameInvalid => '문자로 시작하고 문자, 숫자 또는 . _ : -만 사용하세요.';

  @override
  String get poolValidationDataVdevRequired => '데이터 vdev를 하나 이상 추가하세요.';

  @override
  String poolValidationDataVdevNoDisks(int index) {
    return '데이터 vdev $index에 디스크가 없습니다.';
  }

  @override
  String poolValidationMinimumDisks(String type, int index, int minimum) {
    return '$type vdev $index에는 디스크가 최소 $minimum개 필요합니다.';
  }

  @override
  String get iscsiTargetReviewTitle => 'iSCSI 타깃 검토';

  @override
  String get iscsiTargetEditTitle => 'iSCSI 타깃 편집';

  @override
  String get iscsiTargetNewTitle => '새 iSCSI 타깃';

  @override
  String get iscsiTargetSubtitle => '타깃 식별 정보, 접근 및 포털 그룹';

  @override
  String get iscsiTargetClose => '닫기';

  @override
  String get iscsiTargetBack => '뒤로';

  @override
  String get iscsiTargetCancel => '취소';

  @override
  String get iscsiTargetSaveChanges => '변경사항 저장';

  @override
  String get iscsiTargetCreate => '타깃 생성';

  @override
  String get iscsiTargetReview => '검토';

  @override
  String get iscsiTargetNameLabel => '타깃 이름';

  @override
  String get iscsiTargetNameHelper => 'IQN 또는 고유한 타깃 이름';

  @override
  String get iscsiTargetAliasLabel => '별칭';

  @override
  String get iscsiTargetAliasHelper => '선택 사항인 읽기 쉬운 타깃 이름';

  @override
  String get iscsiTargetNetworksLabel => '허용된 네트워크';

  @override
  String get iscsiTargetNetworksHelper => '한 줄에 CIDR 네트워크 하나 · 비워두면 모든 네트워크 허용';

  @override
  String get iscsiTargetQueuedLabel => '대기 명령 수';

  @override
  String get iscsiTargetQueuedHelper => '워크로드 튜닝이 필요하지 않으면 서버 기본값을 사용하세요';

  @override
  String get iscsiTargetQueueServerDefault => '서버 기본값';

  @override
  String get iscsiTargetQueue32 => '명령 32개';

  @override
  String get iscsiTargetQueue128 => '명령 128개';

  @override
  String get iscsiTargetGroups => '타깃 그룹';

  @override
  String get iscsiTargetAddGroup => '그룹 추가';

  @override
  String get iscsiTargetGroupsDescription =>
      '각 그룹은 포털을 모든 이니시에이터 또는 선택한 이니시에이터 그룹에 연결합니다.';

  @override
  String get iscsiTargetNoGroupsNotice =>
      '이 타깃에는 포털 그룹이 없어 그룹을 추가하기 전까지 접근할 수 없습니다.';

  @override
  String get iscsiTargetNoPortalsNotice =>
      '사용 가능한 iSCSI 포털이 없습니다. 타깃 그룹을 추가하기 전에 포털을 생성하세요.';

  @override
  String get iscsiTargetUnrestrictedNotice =>
      '인증되지 않은 그룹은 허용된 모든 네트워크의 모든 이니시에이터를 허용합니다. 허용된 네트워크가 없으면 모든 네트워크에 열립니다.';

  @override
  String get iscsiTargetMutualChapGroup => '상호 CHAP 그룹';

  @override
  String get iscsiTargetChapGroup => 'CHAP 그룹';

  @override
  String iscsiTargetPortalValue(String value) {
    return '포털: $value';
  }

  @override
  String iscsiTargetInitiatorsValue(String value) {
    return '이니시에이터: $value';
  }

  @override
  String iscsiTargetCredentialValue(String value) {
    return '자격 증명 ID: $value';
  }

  @override
  String get iscsiTargetUnavailable => '사용할 수 없음';

  @override
  String get iscsiTargetLockedAuthNotice =>
      '이 릴리스에서는 인증 자격 증명을 보존하며 변경하거나 제거할 수 없습니다.';

  @override
  String iscsiTargetUnauthenticatedGroup(int index) {
    return '인증되지 않은 그룹 $index';
  }

  @override
  String iscsiTargetRemoveGroup(int index) {
    return '그룹 $index 제거';
  }

  @override
  String get iscsiTargetPortalLabel => '포털';

  @override
  String get iscsiTargetInitiatorsLabel => '이니시에이터';

  @override
  String get iscsiTargetAllInitiators => '모든 이니시에이터';

  @override
  String get iscsiTargetAuthentication => '인증';

  @override
  String get iscsiTargetAuthNone => '없음';

  @override
  String get iscsiTargetChapOneWay => 'CHAP (단방향)';

  @override
  String get iscsiTargetChapMutual => 'CHAP (상호)';

  @override
  String get iscsiTargetChapCredential => 'CHAP 자격 증명';

  @override
  String get iscsiTargetNoChapCredentials => '구성된 CHAP 자격 증명이 없습니다. 먼저 생성하세요.';

  @override
  String get iscsiTargetChapRequiredNotice =>
      'CHAP 인증에는 자격 증명이 하나 이상 필요합니다. 인증 그룹을 추가하기 전에 CHAP 자격 증명에서 생성하세요.';

  @override
  String get iscsiTargetReviewName => '이름';

  @override
  String get iscsiTargetReviewNetworks => '네트워크';

  @override
  String get iscsiTargetAllNetworks => '모든 네트워크';

  @override
  String get iscsiTargetQueueDepth => '대기열 깊이';

  @override
  String iscsiTargetReviewGroup(int index, String authMethod) {
    return '그룹 $index · $authMethod';
  }

  @override
  String iscsiTargetCredentialId(String id) {
    return '자격 증명 ID $id';
  }

  @override
  String get iscsiTargetReviewNoGroupNotice =>
      '이 타깃은 포털 그룹 없이 생성되며 그룹을 추가하기 전까지 접근할 수 없습니다.';

  @override
  String get iscsiTargetReviewUnrestrictedNotice =>
      '이 타깃에는 모든 이니시에이터에 열린 인증되지 않은 그룹이 포함됩니다. 허용된 네트워크가 없으면 모든 네트워크에 열립니다.';

  @override
  String get iscsiTargetReviewValidationNotice =>
      'TrueNAS가 타깃 이름, 네트워크, 포털, 이니시에이터 및 보존된 인증 그룹을 검증합니다.';

  @override
  String iscsiTargetPortalTag(int tag) {
    return '포털 $tag';
  }

  @override
  String iscsiTargetPortalTagDetail(int tag, String detail) {
    return '포털 $tag · $detail';
  }

  @override
  String iscsiTargetPortalUnavailable(int id) {
    return '포털 ID $id · 사용할 수 없음';
  }

  @override
  String iscsiTargetInitiatorGroup(int id) {
    return '이니시에이터 그룹 $id';
  }

  @override
  String iscsiTargetInitiatorGroupDetail(int id, String detail) {
    return '이니시에이터 그룹 $id · $detail';
  }

  @override
  String iscsiTargetInitiatorUnavailable(int id) {
    return '이니시에이터 ID $id · 사용할 수 없음';
  }

  @override
  String get iscsiTargetValidationName => '타깃 이름을 1~120자로 입력하세요.';

  @override
  String get iscsiTargetValidationGroups =>
      '사용 가능한 포털과 이니시에이터로 고유하고 올바른 인증 그룹을 구성하세요.';

  @override
  String get iscsiTargetValidationNetworks =>
      '고유한 IPv4 또는 IPv6 네트워크를 CIDR 표기법으로 입력하세요.';

  @override
  String get iscsiTargetValidationQueued => '대기 명령 수는 32 또는 128이어야 합니다.';

  @override
  String get smbReviewTitle => 'SMB 공유 검토';

  @override
  String get smbEditTitle => 'SMB 공유 편집';

  @override
  String get smbNewTitle => '새 SMB 공유';

  @override
  String get smbClose => '닫기';

  @override
  String get smbBack => '뒤로';

  @override
  String get smbCancel => '취소';

  @override
  String get smbSaveChanges => '변경사항 저장';

  @override
  String get smbCreateShare => '공유 생성';

  @override
  String get smbReview => '검토';

  @override
  String get smbPurpose => '용도';

  @override
  String get smbShareName => '공유 이름';

  @override
  String get smbSharePath => '공유 경로';

  @override
  String get smbSharePathHelper => '/mnt/ 아래 ZFS 풀의 기존 경로';

  @override
  String get smbExternalDestinations => '외부 대상';

  @override
  String get smbExternalDestinationsHelper => '한 줄에 SERVER\\SHARE 대상 하나';

  @override
  String get smbComment => '설명';

  @override
  String get smbEnableShare => '공유 활성화';

  @override
  String get smbEnableShareDescription => 'SMB를 통해 공유를 사용할 수 있게 합니다.';

  @override
  String get smbReadOnly => '읽기 전용';

  @override
  String get smbReadOnlyDescription => 'SMB 클라이언트가 파일을 변경하지 못하게 합니다.';

  @override
  String get smbShowInBrowsing => '네트워크 탐색에 표시';

  @override
  String get smbAccessBasedEnumeration => '접근 기반 열거';

  @override
  String get smbAccessBasedEnumerationDescription =>
      '공유 ACL에서 허용된 사용자에게만 공유를 표시합니다.';

  @override
  String get smbNetworkRestrictions => '네트워크 제한';

  @override
  String get smbNetworkRestrictionsDescription => '선택 사항인 IP 주소, 서브넷 또는 ALL';

  @override
  String get smbAllowedHosts => '허용 호스트';

  @override
  String get smbAllowedHostsHelper => '한 줄에 하나 · 비워두면 일반 접근 허용';

  @override
  String get smbDeniedHosts => '차단 호스트';

  @override
  String get smbOneEntryPerLine => '한 줄에 하나';

  @override
  String get smbAuditing => '감사';

  @override
  String get smbAuditingDescription => '선택한 그룹의 SMB 접근 기록';

  @override
  String get smbEnableAuditing => '감사 활성화';

  @override
  String get smbGroupsToAudit => '감사할 그룹';

  @override
  String get smbGroupsToAuditHelper => '한 줄에 그룹 하나 · 비워두면 모든 그룹 감사';

  @override
  String get smbGroupsToIgnore => '제외할 그룹';

  @override
  String get smbOneGroupPerLine => '한 줄에 그룹 하나';

  @override
  String get smbTimeMachineQuota => 'Time Machine 할당량 (바이트)';

  @override
  String get smbZeroDisablesServerQuota => '0이면 서버 측 할당량 비활성화';

  @override
  String get smbSnapshotAfterBackup => '새 백업 후 스냅샷 생성';

  @override
  String get smbDatasetPerUser => '사용자별 데이터셋 생성';

  @override
  String get smbGracePeriod => '쓰기 유예 기간 (초)';

  @override
  String get smbPerUserQuota => '사용자별 할당량 (GiB)';

  @override
  String get smbZeroDisablesAutoQuota => '0이면 자동 할당량 비활성화';

  @override
  String get smbAppleFilenameMangling => 'Apple 파일 이름 변환';

  @override
  String get smbAppleFilenameManglingDescription =>
      'Windows에서 허용되지 않는 macOS 파일 이름 문자를 보존합니다.';

  @override
  String get smbDatasetNamingSchema => '데이터셋 이름 스키마';

  @override
  String get smbDatasetNamingSchemaHelper => '예: %U 또는 %D/%U';

  @override
  String get smbFinalCutNotice =>
      'Final Cut Pro는 Apple 파일 이름 변환을 강제하며 전역 Apple SMB 확장이 필요합니다.';

  @override
  String get smbExternalNotice => 'TrueNAS는 외부 DFS 대상에 연결할 수 있는지 확인하지 않습니다.';

  @override
  String get smbUnsupportedNotice => '이 레거시 또는 서버별 공유는 조회만 할 수 있습니다.';

  @override
  String get smbReviewShare => '공유';

  @override
  String get smbReviewLocation => '위치';

  @override
  String get smbReviewAccess => '접근';

  @override
  String get smbReadAndWrite => '읽기 및 쓰기';

  @override
  String get smbVisibility => '표시 여부';

  @override
  String get smbBrowsableWhenAclPermits => 'ACL 허용 시 탐색 가능';

  @override
  String get smbBrowsable => '탐색 가능';

  @override
  String get smbHiddenFromBrowsing => '탐색에서 숨김';

  @override
  String get smbState => '상태';

  @override
  String get smbEnabled => '활성화';

  @override
  String get smbDisabled => '비활성화';

  @override
  String get smbTimeLockedNotice =>
      '시간 잠금은 이 SMB 공유를 통해서만 적용되며 규정 준수용 일회 쓰기 보장은 아닙니다.';

  @override
  String get smbMultiprotocolNotice =>
      '멀티프로토콜 호환성은 더 안전한 외부 접근을 위해 일부 SMB 최적화를 비활성화합니다.';

  @override
  String get smbValidationNotice =>
      'TrueNAS가 경로, 공유 이름, 용도 옵션, 권한 및 SMB 필수 조건을 검증합니다.';

  @override
  String get smbPurposeDefault => '기본 공유';

  @override
  String get smbPurposeTimeMachine => 'Time Machine';

  @override
  String get smbPurposeMultiprotocol => '멀티프로토콜';

  @override
  String get smbPurposeTimeLocked => '시간 잠금';

  @override
  String get smbPurposePrivateDatasets => '개인 데이터셋';

  @override
  String get smbPurposeExternal => '외부 DFS';

  @override
  String get smbPurposeFinalCut => 'Final Cut Pro';

  @override
  String get smbPurposeUnsupported => '지원되지 않음';

  @override
  String get smbPurposeDefaultDescription => '일반 SMB 클라이언트에 가장 적합한 호환성을 제공합니다.';

  @override
  String get smbPurposeTimeMachineDescription =>
      '저장소를 Apple Time Machine 대상으로 알립니다.';

  @override
  String get smbPurposeMultiprotocolDescription =>
      '같은 데이터를 SMB 외부에서도 접근할 때 더 안전하게 상호 운용합니다.';

  @override
  String get smbPurposeTimeLockedDescription =>
      '유예 기간 후 SMB를 통해 파일을 읽기 전용으로 만듭니다.';

  @override
  String get smbPurposePrivateDatasetsDescription =>
      '접속하는 사용자마다 별도 ZFS 데이터셋을 생성합니다.';

  @override
  String get smbPurposeExternalDescription => '클라이언트를 다른 SMB 서버의 공유로 연결합니다.';

  @override
  String get smbPurposeFinalCutDescription =>
      'Apple Final Cut Pro 워크플로에 맞춘 저장소입니다.';

  @override
  String get smbPurposeUnsupportedDescription =>
      '이 서버의 공유 용도는 TrueDock에서 편집할 수 없습니다.';

  @override
  String get smbValidationNameRequired => '공유 이름을 입력하세요.';

  @override
  String get smbValidationNameInvalid => '올바르고 고유한 SMB 공유 이름을 입력하세요.';

  @override
  String get smbValidationPurpose => '이 SMB 공유 용도는 편집할 수 없습니다.';

  @override
  String get smbValidationPath => '/mnt/ 아래의 데이터셋 경로를 선택하세요.';

  @override
  String get smbValidationRemotePaths => '한 줄에 SERVER\\SHARE 대상 하나를 입력하세요.';

  @override
  String get smbValidationTimeMachineQuota => '할당량은 음수일 수 없습니다.';

  @override
  String get smbValidationGracePeriod => '유예 기간은 60~15,552,000초여야 합니다.';

  @override
  String get smbValidationAutoQuota => '자동 할당량은 음수일 수 없습니다.';

  @override
  String get smbValidationDatasetSchema => '데이터셋 이름 스키마를 입력하세요.';

  @override
  String get appsTitle => '앱';

  @override
  String get appsLoadFailed => '앱과 서비스를 불러오지 못했습니다.';

  @override
  String get appsLandingDescription => '앱, 컨테이너, 가상 머신, 서비스를 제어합니다.';

  @override
  String get appsRefreshTooltip => '앱 새로고침';

  @override
  String get appsInstalledApps => '설치된 앱';

  @override
  String get appsFeatureInstalledSubtitle => '시작, 중지, 업데이트, 롤백';

  @override
  String get appsDiscover => '둘러보기';

  @override
  String get appsFeatureDiscoverSubtitle => '구성된 카탈로그 탐색';

  @override
  String get appsContainers => '컨테이너';

  @override
  String get appsFeatureContainersSubtitle => '인스턴스, 지표, 장치';

  @override
  String get appsVirtualMachines => '가상 머신';

  @override
  String get appsFeatureVirtualMachinesSubtitle => '수명 주기, 디스플레이, 장치';

  @override
  String get appsServices => '서비스';

  @override
  String get appsFeatureServicesSubtitle => '상태, 시작 설정, 구성';

  @override
  String get appsNoAppsInstalled => '설치된 앱이 없습니다.';

  @override
  String get appsNoVirtualMachines => '가상 머신이 없습니다.';

  @override
  String get appsContainersUnsupported =>
      '이 TrueNAS 버전은 독립 컨테이너를 제공하지 않습니다. 위의 설치된 앱은 계속 사용할 수 있습니다.';

  @override
  String get appsNoContainers => '독립 컨테이너가 없습니다.';

  @override
  String get appsInstances => '인스턴스';

  @override
  String get appsInstancesUnsupported => '이 TrueNAS 버전은 인스턴스 API를 제공하지 않습니다.';

  @override
  String get appsInstancesNoPool =>
      '컨테이너나 VM을 만들기 전에 인스턴스용 스토리지 풀이 필요합니다. 풀을 선택해 플랫폼을 초기화하세요.';

  @override
  String get appsInstancesChoosePool => '스토리지 풀 선택';

  @override
  String get appsInstancesPoolTitle => '인스턴스 스토리지';

  @override
  String appsInstancesPoolConsequence(String pool) {
    return 'TrueNAS가 $pool에 숨겨진 .ix-virt 데이터셋을 만들고 모든 인스턴스가 여기에 디스크를 저장합니다. 나중에 옮기려면 인스턴스를 다시 만들어야 합니다.';
  }

  @override
  String appsInstancesPoolApplied(String pool) {
    return '인스턴스 스토리지를 $pool(으)로 설정했습니다.';
  }

  @override
  String get appsNoInstances => '아직 인스턴스가 없습니다.';

  @override
  String get appsInstanceCreate => '인스턴스 생성';

  @override
  String get appsInstanceKindContainer => '컨테이너';

  @override
  String get appsInstanceKindVm => 'VM';

  @override
  String get appsInstanceLabelImage => '이미지';

  @override
  String get appsInstanceLabelCpu => 'CPU';

  @override
  String get appsInstanceLabelMemory => '메모리';

  @override
  String get appsInstanceLabelPool => '스토리지 풀';

  @override
  String get appsInstanceLabelRootDisk => '루트 디스크';

  @override
  String get appsInstanceLabelPrivileged => '특권 모드';

  @override
  String get appsInstanceLabelDevices => '장치';

  @override
  String get appsInstanceServerDefault => '서버 기본값';

  @override
  String get appsInstanceDevicesEmpty => '연결된 장치가 없습니다.';

  @override
  String get appsInstanceDeviceManaged => 'TrueNAS가 관리함';

  @override
  String appsInstanceEditTitle(String name) {
    return '$name 편집';
  }

  @override
  String get appsInstanceCreateTitle => '새 인스턴스';

  @override
  String get appsInstanceNameLabel => '이름';

  @override
  String get appsInstanceNameHelper =>
      '영문자, 숫자, 하이픈만 사용합니다. 게스트 호스트 이름으로 쓰입니다.';

  @override
  String get appsInstanceImageLabel => '기본 이미지';

  @override
  String get appsInstanceImagePickerHint => '기본 이미지 목록 표시';

  @override
  String get appsInstanceCpuHelper =>
      '코어 수 또는 0-3 같은 고정 집합. 비워 두면 서버 기본값을 씁니다.';

  @override
  String get appsInstanceMemoryLabel => '메모리 (MiB)';

  @override
  String get appsInstanceRootDiskLabel => '루트 디스크 (GiB)';

  @override
  String get appsInstanceAutostart => '자동 시작';

  @override
  String appsInstanceCreated(String name) {
    return '$name을(를) 생성하는 중입니다.';
  }

  @override
  String appsInstanceUpdated(String name) {
    return '$name을(를) 수정하는 중입니다.';
  }

  @override
  String get appsInstanceNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String appsInstanceDeleteTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String get appsInstanceDeleteAction => '인스턴스 삭제';

  @override
  String get appsInstanceDeleteConsequenceDisk =>
      '인스턴스의 루트 디스크가 함께 삭제됩니다. 게스트 내부에 기록된 데이터는 사라집니다.';

  @override
  String get appsInstanceDeleteConsequenceRunning => '인스턴스가 실행 중이며 먼저 중지됩니다.';

  @override
  String appsInstanceDeleteRequested(String name) {
    return '$name을(를) 삭제하는 중입니다.';
  }

  @override
  String get appsInstanceValidationNameRequired => '이름을 입력하세요.';

  @override
  String get appsInstanceValidationNameInvalid =>
      '영문자로 시작하고 영문자, 숫자, 하이픈만 사용하세요.';

  @override
  String get appsInstanceValidationImageRequired => '기본 이미지를 선택하세요.';

  @override
  String get appsInstanceValidationCpu => '코어 수 또는 0-3 같은 고정 집합을 입력하세요.';

  @override
  String appsInstanceValidationMemory(int bound) {
    return '메모리는 최소 $bound MiB여야 합니다.';
  }

  @override
  String appsInstanceValidationRootDisk(int bound) {
    return '루트 디스크는 1에서 $bound GiB 사이여야 합니다.';
  }

  @override
  String get appsInstanceValidationEnvironment =>
      '환경 변수 이름은 영문자나 밑줄로 시작하고 영문자, 숫자, 밑줄만 포함해야 합니다.';

  @override
  String get appsOperationFailed => 'TrueNAS 작업이 실패했습니다.';

  @override
  String appsJobSuffix(String jobId) {
    return ' · 작업 $jobId';
  }

  @override
  String get appsSummaryInstalled => '설치됨';

  @override
  String get appsSummaryRunning => '실행 중';

  @override
  String get appsSummaryUpdates => '업데이트';

  @override
  String appsStopAppTitle(String name) {
    return '$name을(를) 중지할까요?';
  }

  @override
  String get appsStopAppBody => '앱을 다시 시작할 때까지 사용자와 종속 서비스가 접근하지 못할 수 있습니다.';

  @override
  String get appsStopApp => '앱 중지';

  @override
  String get appsStartApp => '앱 시작';

  @override
  String appsStopServiceTitle(String name) {
    return '$name을(를) 중지할까요?';
  }

  @override
  String get appsStopServiceBody => '이 서비스를 사용 중인 클라이언트의 연결이 끊길 수 있습니다.';

  @override
  String get appsStopService => '서비스 중지';

  @override
  String appsStartRequested(String target) {
    return '$target 시작을 요청했습니다.';
  }

  @override
  String appsStopRequested(String target) {
    return '$target 중지를 요청했습니다.';
  }

  @override
  String appsUpgradeRequested(String target) {
    return '$target 업그레이드를 요청했습니다.';
  }

  @override
  String appsRedeployRequested(String target) {
    return '$target 재배포를 요청했습니다.';
  }

  @override
  String appsReconfigureRequested(String target) {
    return '$target 재구성을 요청했습니다.';
  }

  @override
  String appsRollbackRequested(String target) {
    return '$target 롤백을 요청했습니다.';
  }

  @override
  String appsRemovalRequested(String target) {
    return '$target 제거를 요청했습니다.';
  }

  @override
  String appsInstallRequested(String target) {
    return '$target 설치를 요청했습니다.';
  }

  @override
  String get appsStartOnBoot => '부팅 시 시작';

  @override
  String get appsDoNotStartOnBoot => '부팅 시 시작 안 함';

  @override
  String appsStartOnBootTitle(String name) {
    return '부팅 시 $name을(를) 시작할까요?';
  }

  @override
  String appsStopStartOnBootTitle(String name) {
    return '부팅 시 $name 시작을 중단할까요?';
  }

  @override
  String appsStartOnBootConsequence(String name, String server) {
    return '$server을(를) 재부팅할 때마다 $name이(가) 자동으로 시작됩니다.';
  }

  @override
  String appsStopOnBootConsequence(String name, String server) {
    return '$server을(를) 다음에 재부팅한 뒤에는 누군가 직접 시작하기 전까지 $name이(가) 중지된 상태로 유지됩니다.';
  }

  @override
  String get appsBootChangeRunningNote => '서비스는 지금 그대로 실행됩니다. 부팅 시 동작만 변경됩니다.';

  @override
  String get appsBootChangeStoppedNote =>
      '서비스는 지금 그대로 중지 상태입니다. 부팅 시 동작만 변경됩니다.';

  @override
  String appsStartOnBootSaved(String name) {
    return '부팅 시 $name이(가) 시작됩니다.';
  }

  @override
  String appsStopOnBootSaved(String name) {
    return '부팅 시 $name이(가) 더 이상 시작되지 않습니다.';
  }

  @override
  String get appsServiceStartsAutomatically => '자동으로 시작됨';

  @override
  String get appsServiceManualStart => '수동 시작';

  @override
  String get appsServiceOptions => '서비스 옵션';

  @override
  String get appsMoreActions => '추가 앱 작업';

  @override
  String get appsRedeploy => '재배포';

  @override
  String get appsReconfigure => '재구성';

  @override
  String get appsRollbackMenu => '이전 버전으로 롤백';

  @override
  String get appsReviewUpgrade => '앱 업그레이드 검토';

  @override
  String get appsUpgradeUnsupported => '이 서버는 업그레이드를 지원하지 않습니다';

  @override
  String appsRedeployTitle(String name) {
    return '$name을(를) 재배포할까요?';
  }

  @override
  String get appsRedeployAction => '앱 재배포';

  @override
  String get appsRedeployConsequenceRebuild =>
      '앱이 중지되고 컨테이너가 다시 생성된 뒤 재시작됩니다. TrueNAS 작업이 끝날 때까지 사용자는 접근할 수 없습니다.';

  @override
  String get appsRedeployConsequenceData =>
      '기존 구성과 저장된 데이터는 유지되며 실행 인스턴스만 다시 만들어집니다.';

  @override
  String appsConfigLoadFailed(String name) {
    return '$name의 구성을 불러오지 못했습니다.';
  }

  @override
  String appsNotReconfigurable(String name) {
    return '$name은(는) 사용자 지정 앱이거나 카탈로그를 통해 편집 가능한 구성을 제공하지 않습니다. 설정을 바꾸려면 카탈로그에서 다시 설치하세요.';
  }

  @override
  String get appsReconfigureDescription => '설치된 앱을 재구성합니다.';

  @override
  String get appsSchemaLoadFailed => '앱 구성 스키마를 불러오지 못했습니다.';

  @override
  String get appsInstallSchemaLoadFailed => '앱 설치 스키마를 불러오지 못했습니다.';

  @override
  String appsRollbackTitle(String name) {
    return '$name을(를) 롤백할까요?';
  }

  @override
  String get appsRollbackAction => '앱 롤백';

  @override
  String get appsRollbackConsequenceRebuild =>
      '선택한 이미지 버전으로 앱이 다시 빌드되고 재시작됩니다. 현재 버전에 의존하는 변경 사항은 적용되지 않을 수 있습니다.';

  @override
  String get appsRollbackConsequenceData =>
      '저장된 데이터와 구성은 유지되지만 실행 버전은 이전 릴리스로 되돌아갑니다.';

  @override
  String appsRollbackSheetTitle(String name) {
    return '$name 롤백';
  }

  @override
  String appsRollbackSheetNotice(String server) {
    return '$server의 앱이 선택한 이미지로 다시 빌드되고 재시작됩니다. 저장된 데이터와 구성은 유지되며 실행 버전만 되돌아갑니다.';
  }

  @override
  String appsRemoveTitle(String name) {
    return '$name을(를) 제거할까요?';
  }

  @override
  String get appsRemoveAction => '앱 제거';

  @override
  String appsRemoveConsequenceApp(String server) {
    return '$server에서 앱이 영구적으로 제거됩니다. 다시 설치하려면 카탈로그 항목과 기존 구성이 필요합니다.';
  }

  @override
  String get appsRemoveConsequenceImages =>
      '내려받은 컨테이너 이미지도 삭제되며 재설치 시 다시 내려받아야 합니다.';

  @override
  String get appsRemoveConsequenceVolumesDeleted =>
      '명명된 볼륨이 앱과 함께 제거되어 그 안의 데이터가 삭제됩니다.';

  @override
  String get appsRemoveConsequenceVolumesKept =>
      '명명된 볼륨은 유지되어 데이터가 남지만, 나중에 직접 다시 연결하거나 제거해야 합니다.';

  @override
  String appsRemovalSheetTitle(String name) {
    return '$name과(와) 함께 제거할 항목 선택';
  }

  @override
  String get appsRemovalSheetBody =>
      '앱 자체는 항상 제거됩니다. 아래 옵션은 이미지와 저장된 볼륨을 함께 제거할지 결정합니다.';

  @override
  String get appsRemoveImages => '내려받은 이미지 제거';

  @override
  String get appsRemoveImagesSubtitle =>
      '이 앱을 위해 내려받은 컨테이너 이미지를 삭제합니다. 다음 설치 때 다시 내려받습니다.';

  @override
  String get appsKeepVolumes => '명명된 볼륨 유지';

  @override
  String get appsKeepVolumesOn => '저장된 데이터가 제거 후에도 남아 나중에 다시 연결할 수 있습니다.';

  @override
  String get appsKeepVolumesOff => '명명된 볼륨이 앱과 함께 삭제됩니다. 데이터가 사라집니다.';

  @override
  String get appsReviewRemoval => '제거 검토';

  @override
  String appsUpgradeSheetTitle(String name) {
    return '$name 업그레이드';
  }

  @override
  String appsVersionTransition(String from, String to) {
    return '$from → $to';
  }

  @override
  String get appsTargetVersion => '대상 버전';

  @override
  String get appsSnapshotHostPaths => '호스트 경로 저장소 스냅샷';

  @override
  String get appsSnapshotHostPathsSubtitle =>
      '업그레이드 전에 대상이 되는 호스트 경로 볼륨의 ZFS 스냅샷을 만듭니다.';

  @override
  String get appsUpgradeNotice =>
      '앱이 중지되고 다시 배포될 수 있습니다. TrueNAS 작업이 끝날 때까지 사용자는 접근하지 못할 수 있습니다.';

  @override
  String get appsReleaseNotes => '릴리스 노트';

  @override
  String get appsNoReleaseNotes => '이 버전에는 제공된 릴리스 노트가 없습니다.';

  @override
  String get appsUpgradeAction => '앱 업그레이드';

  @override
  String get appsCatalogUnsupported => '이 TrueNAS 버전은 구성된 카탈로그를 제공하지 않습니다.';

  @override
  String get appsCatalogEmpty => '사용 가능한 카탈로그 앱이 없습니다. 카탈로그가 아직 동기화 중일 수 있습니다.';

  @override
  String appsBrowseAll(int count) {
    return '앱 $count개 모두 보기';
  }

  @override
  String get appsDockerService => 'Docker 서비스';

  @override
  String get appsStatusUnknown => '알 수 없음';

  @override
  String get appsDockerConfigurationAvailable => 'Docker 구성 사용 가능';

  @override
  String get appsNoAppsPool => '앱 풀이 구성되지 않음';

  @override
  String get appsImageUpdatesEnabled => '이미지 업데이트 사용';

  @override
  String get appsManualImageUpdates => '수동 이미지 업데이트';

  @override
  String get appsVersionUnavailable => '버전 정보 없음';

  @override
  String get appsImageUnavailable => '이미지 정보 없음';

  @override
  String appsCatalogTileSubtitle(
    String train,
    String version,
    String description,
  ) {
    return '$train · $version\n$description';
  }

  @override
  String get appsDiscoverApps => '앱 둘러보기';

  @override
  String get appsSearchHint => '이름, 카테고리, 태그 검색';

  @override
  String get appsClearSearch => '검색어 지우기';

  @override
  String get appsAllTrains => '전체 트레인';

  @override
  String appsAppCount(int count) {
    return '앱 $count개';
  }

  @override
  String get appsNoSearchResults => '검색과 일치하는 앱이 없습니다.';

  @override
  String get appsLabelTrain => '트레인';

  @override
  String get appsLabelVersion => '버전';

  @override
  String get appsUnavailable => '사용할 수 없음';

  @override
  String get appsLabelHealth => '상태';

  @override
  String get appsCatalogHealthy => '카탈로그 항목 정상';

  @override
  String get appsNeedsAttention => '확인 필요';

  @override
  String get appsLabelCategories => '카테고리';

  @override
  String get appsLabelTags => '태그';

  @override
  String get appsConfigureInstall => '설치 구성';

  @override
  String get appsAppUnavailable => '앱 사용 불가';

  @override
  String get appsInstallUnsupported => '설치 미지원';

  @override
  String get appsVerbStart => '시작';

  @override
  String get appsVerbStop => '중지';

  @override
  String get appsVerbRestart => '재시작';

  @override
  String get appsVerbPowerOff => '강제 전원 차단';

  @override
  String appsVerbConfirmTitle(String verb, String name) {
    return '$name을(를) $verb할까요?';
  }

  @override
  String appsVerbRequested(String verb, String name) {
    return '$name $verb을(를) 요청했습니다.';
  }

  @override
  String appsControlFailed(String verb, String name) {
    return 'TrueNAS가 $name을(를) $verb하지 못했습니다.';
  }

  @override
  String get appsKindVirtualMachine => '가상 머신';

  @override
  String get appsKindContainer => '컨테이너';

  @override
  String appsNoLifecycleControl(String kind) {
    return '이 TrueNAS 버전은 이 $kind의 수명 주기 제어를 제공하지 않습니다.';
  }

  @override
  String appsStopConsequence(String kind) {
    return 'TrueNAS가 $kind에 종료를 요청합니다. 내부에서 실행 중인 작업이 중지되며 저장되지 않은 상태는 게스트에 따라 달라집니다.';
  }

  @override
  String appsRestartConsequence(String kind) {
    return '$kind이(가) 종료된 뒤 다시 시작됩니다. 부팅이 끝날 때까지 제공 중인 서비스를 사용할 수 없습니다.';
  }

  @override
  String appsPowerOffConsequence(String kind) {
    return '정상 종료 없이 전원이 즉시 차단됩니다. 플러그를 뽑는 것과 같아 $kind 내부에 기록되지 않은 데이터가 사라질 수 있습니다.';
  }

  @override
  String get appsLabelState => '상태';

  @override
  String get appsLabelCpu => 'CPU';

  @override
  String appsCpuSummary(int sockets, int cores, int threads) {
    return '소켓 $sockets개 · 코어 $cores개 · 스레드 $threads개';
  }

  @override
  String get appsLabelMemory => '메모리';

  @override
  String appsMemoryMiB(int value) {
    return '$value MiB';
  }

  @override
  String get appsLabelAutostart => '자동 시작';

  @override
  String get appsEnabled => '사용';

  @override
  String get appsDisabled => '사용 안 함';

  @override
  String get appsLabelDisplay => '디스플레이';

  @override
  String get appsDisplayAvailable => '사용 가능';

  @override
  String get appsDisplayNotConfigured => '구성되지 않음';

  @override
  String appsVmSubtitle(String state, int vcpu, int memory) {
    return '$state · vCPU $vcpu개 · $memory MiB';
  }

  @override
  String get appsEdit => '편집';

  @override
  String get appsStateRunning => '실행 중';

  @override
  String get appsStateStopped => '중지됨';

  @override
  String get appsStateDeploying => '배포 중';

  @override
  String get appsStateStarting => '시작 중';

  @override
  String get appsStateStopping => '중지 중';

  @override
  String get appsStateCrashed => '비정상 종료';

  @override
  String get appsStateHealthy => '정상';

  @override
  String get appsStateUnhealthy => '비정상';

  @override
  String get appsStateUnknown => '알 수 없음';

  @override
  String get appsDetailsLiveResources => '실시간 리소스';

  @override
  String get appsDetailsCpu => 'CPU';

  @override
  String get appsDetailsMemory => '메모리';

  @override
  String appsDetailsStatsFailed(String detail) {
    return '실시간 리소스 정보를 불러올 수 없습니다.\n$detail';
  }

  @override
  String get appsDetailsDiskRead => '디스크 읽기';

  @override
  String get appsDetailsDiskWrite => '디스크 쓰기';

  @override
  String appsDetailsNetworkRate(String received, String sent) {
    return '수신 $received · 송신 $sent';
  }

  @override
  String get appsDetailsWorkloads => '워크로드';

  @override
  String appsDetailsContainerCount(int count) {
    return '컨테이너 $count개';
  }

  @override
  String get appsDetailsNoContainerInfo => '컨테이너 상세 정보 없음';

  @override
  String get appsDetailsImages => '이미지';

  @override
  String get appsDetailsPorts => '포트';

  @override
  String get appsDetailsStorage => '스토리지';

  @override
  String get appsDetailsNetworks => '네트워크';

  @override
  String get appsCustomComposeDescription =>
      '커스텀 앱의 Docker Compose 구성을 JSON으로 편집합니다. 적용하면 앱 컨테이너가 다시 생성될 수 있습니다.';

  @override
  String get appsCustomComposeLabel => 'Docker Compose 구성';

  @override
  String get appsCustomComposeReview => '변경 검토';

  @override
  String get appsCustomComposeInvalid => '올바른 JSON 객체를 입력하세요.';

  @override
  String appsCustomComposeConfirmTitle(String name) {
    return '$name 구성을 변경할까요?';
  }

  @override
  String get appsCustomComposeApply => '변경 적용';

  @override
  String get appsCustomComposeRecreateWarning =>
      'TrueNAS가 변경된 구성으로 앱 컨테이너를 다시 생성할 수 있습니다.';

  @override
  String get appsCustomComposeDowntimeWarning =>
      '작업이 완료될 때까지 앱 연결이 잠시 중단될 수 있습니다.';

  @override
  String get appsDeviceTypeDisk => '디스크';

  @override
  String get appsDeviceTypeNetwork => '네트워크';

  @override
  String get appsDeviceTypeDisplay => '디스플레이';

  @override
  String get appsDeviceTypeUsb => 'USB';

  @override
  String get appsDeviceTypePci => 'PCI 장치';

  @override
  String get appsDeviceTypeTpm => 'TPM';

  @override
  String get appsDeviceTypeCdrom => 'CD-ROM';

  @override
  String get appsDevices => '장치';

  @override
  String get appsNoChanges => '저장할 변경 사항이 없습니다.';

  @override
  String appsSaveChangesTitle(String name) {
    return '$name의 변경 사항을 저장할까요?';
  }

  @override
  String get appsVmRuntimeChangeRunning => 'CPU와 메모리 변경은 다음 재시작 때 적용됩니다.';

  @override
  String get appsVmRuntimeChangeStopped => 'CPU와 메모리 변경은 다음 시작 때 적용됩니다.';

  @override
  String get appsConfigUpdatedOnServer => '구성이 서버에서 업데이트됩니다.';

  @override
  String appsUpdateFailed(String name) {
    return 'TrueNAS가 $name을(를) 업데이트하지 못했습니다.';
  }

  @override
  String appsVmUpdated(String name) {
    return '$name이(가) 업데이트되었습니다. 런타임 변경을 적용하려면 재시작하세요.';
  }

  @override
  String get appsVmDevicesLoadFailed => '서버에서 VM 장치를 불러오지 못했습니다.';

  @override
  String appsAddDeviceTitle(String device, String vm) {
    return '$vm에 $device을(를) 추가할까요?';
  }

  @override
  String get appsAddDevice => '장치 추가';

  @override
  String appsAddDeviceConsequence(String vm) {
    return '장치가 $vm에 연결됩니다. 디스크 장치는 게스트 내부에서 보이려면 재시작이 필요합니다.';
  }

  @override
  String get appsAddDeviceFailed => 'TrueNAS가 장치를 추가하지 못했습니다.';

  @override
  String appsDeviceAdded(String vm) {
    return '$vm에 장치를 추가했습니다.';
  }

  @override
  String appsSaveDeviceTitle(String device, String vm) {
    return '$vm의 $device을(를) 저장할까요?';
  }

  @override
  String get appsSaveDevice => '장치 저장';

  @override
  String appsEditDeviceConsequence(String vm) {
    return 'TrueNAS가 $vm에서 이 장치의 구성을 교체합니다. 변경 사항은 VM을 다음에 시작할 때 적용됩니다.';
  }

  @override
  String get appsEditDeviceDiskWarning =>
      '디스크를 다시 지정하면 게스트가 부팅하는 저장소가 바뀝니다. 기반 zvol이나 이미지 자체는 변경되지 않습니다.';

  @override
  String get appsUpdateDeviceFailed => 'TrueNAS가 장치를 업데이트하지 못했습니다.';

  @override
  String appsDeviceUpdated(String vm) {
    return '$vm의 장치를 업데이트했습니다.';
  }

  @override
  String appsRemoveDeviceTitle(String device, String vm) {
    return '$vm에서 $device을(를) 제거할까요?';
  }

  @override
  String get appsRemoveDevice => '장치 제거';

  @override
  String get appsRemoveDeviceConsequence =>
      '장치가 VM에서 분리됩니다. 디스크를 제거해도 기반 zvol이나 이미지는 삭제되지 않습니다.';

  @override
  String get appsRemoveDeviceFailed => 'TrueNAS가 장치를 제거하지 못했습니다.';

  @override
  String appsDeviceRemoved(String vm) {
    return '$vm에서 장치를 제거했습니다.';
  }

  @override
  String appsDeviceTarget(String vm, String device) {
    return '$vm · $device';
  }

  @override
  String appsContainerSubtitle(String state, String dataset, int count) {
    return '$state · $dataset · 장치 $count개';
  }

  @override
  String get appsLabelDataset => '데이터셋';

  @override
  String get appsLabelUuid => 'UUID';

  @override
  String get appsLabelDevices => '장치';

  @override
  String get appsLabelNetwork => '네트워크';

  @override
  String get appsNetworkByDevices => '장치에서 구성됨';

  @override
  String get appsContainerConfigLoadFailed => '컨테이너 구성을 불러오지 못했습니다.';

  @override
  String get appsContainerUpdateConsequence =>
      'TrueNAS가 장치 목록을 포함한 컨테이너 구성 전체를 교체합니다. 볼륨과 환경 변수는 현재 컨테이너 값 그대로 전송됩니다.';

  @override
  String appsContainerRestartToApply(String name) {
    return '$name이(가) 실행 중입니다. 적용하려면 재시작하세요.';
  }

  @override
  String get appsContainerStartToApply => '적용하려면 컨테이너를 시작하세요.';

  @override
  String appsContainerUpdated(String name) {
    return '$name이(가) 업데이트되었습니다. 적용하려면 재시작하세요.';
  }

  @override
  String get protectionTitle => '보호';

  @override
  String get protectionLoadFailed => '데이터 보호 정보를 불러오지 못했습니다.';

  @override
  String get overviewActivityLoadFailed => '최근 활동을 불러오지 못했습니다.';

  @override
  String get protectionLandingDescription =>
      '예약된 복사, 스냅샷, 스크럽, 백업 작업을 한눈에 확인합니다.';

  @override
  String get protectionRefreshTooltip => '보호 작업 새로고침';

  @override
  String get protectionReplication => '복제';

  @override
  String get protectionReplicationSubtitle => '로컬 및 원격 ZFS 복제';

  @override
  String get protectionSnapshotTasks => '스냅샷 작업';

  @override
  String get protectionSnapshotTasksSubtitle => '일정과 보존 정책';

  @override
  String get protectionCloudSync => '클라우드 동기화';

  @override
  String get protectionCloudSyncSubtitle => '공급자, 전송, 결과';

  @override
  String get protectionScrubs => '스크럽';

  @override
  String get protectionScrubsSubtitle => '풀 무결성 일정';

  @override
  String get protectionRsync => 'Rsync';

  @override
  String get protectionRsyncSubtitle => '모듈 및 SSH 작업';

  @override
  String get protectionRecentSnapshots => '최근 스냅샷';

  @override
  String get protectionScrubSchedules => '스크럽 일정';

  @override
  String protectionSummary(int replications, int snapshots, int others) {
    return '복제 $replications개, 스냅샷 $snapshots개, 기타 $others개 작업이 사용 중입니다';
  }

  @override
  String get protectionNewReplication => '새 복제 작업';

  @override
  String get protectionNewSnapshotTask => '주기적 스냅샷 작업 만들기';

  @override
  String get protectionSnapshotTaskCreateUnsupported => '스냅샷 작업 생성을 지원하지 않습니다';

  @override
  String get protectionNewCloudSync => '새 클라우드 동기화 작업';

  @override
  String get protectionCloudBackups => '클라우드 백업';

  @override
  String get protectionNewCloudBackup => '새 클라우드 백업 작업';

  @override
  String get protectionNoCloudBackups => '클라우드 백업 작업이 없습니다.';

  @override
  String get protectionCloudBackupNeedsCredential =>
      '백업 작업을 만들기 전에 TrueNAS 웹 인터페이스에서 클라우드 자격 증명을 추가하세요.';

  @override
  String protectionCloudBackupSubtitle(String schedule, int keepLast) {
    return '$schedule · 스냅샷 $keepLast개 유지';
  }

  @override
  String get protectionCloudBackupSheetCreate => '새 클라우드 백업';

  @override
  String get protectionCloudBackupSheetEdit => '클라우드 백업 편집';

  @override
  String get protectionCloudBackupPath => '데이터셋 경로';

  @override
  String get protectionCloudBackupCredential => '클라우드 자격 증명';

  @override
  String get protectionCloudBackupBucket => '버킷';

  @override
  String get protectionCloudBackupFolder => '폴더';

  @override
  String get protectionCloudBackupPassword => '저장소 비밀번호';

  @override
  String get protectionCloudBackupPasswordHelperNew =>
      '필수 항목입니다. 이 비밀번호를 잃으면 백업을 복구할 수 없습니다. TrueDock은 서버에서 비밀번호를 읽어오지 않습니다.';

  @override
  String get protectionCloudBackupPasswordHelperEdit =>
      '비워 두면 저장된 비밀번호를 유지합니다.';

  @override
  String get protectionCloudBackupKeepLast => '유지할 스냅샷 수';

  @override
  String get protectionCloudBackupSnapshotFirst => '먼저 데이터셋 스냅샷 생성';

  @override
  String get protectionCloudBackupSnapshotHelp =>
      '전송 중 변경될 수 있는 파일 대신 특정 시점의 스냅샷을 백업합니다.';

  @override
  String get protectionCloudBackupTransfer => '전송 프로필';

  @override
  String get protectionCloudBackupTransferDefault => '기본';

  @override
  String get protectionCloudBackupTransferPerformance => '성능';

  @override
  String get protectionCloudBackupTransferFast => '고속 스토리지';

  @override
  String get protectionCloudBackupEnabled => '사용';

  @override
  String get protectionCloudBackupCreated => '클라우드 백업 작업을 만들었습니다.';

  @override
  String get protectionCloudBackupUpdated => '클라우드 백업 작업을 수정했습니다.';

  @override
  String get protectionCloudBackupDeleted => '클라우드 백업 작업을 삭제했습니다.';

  @override
  String protectionCloudBackupRunning(String path) {
    return '$path을(를) 백업하는 중입니다.';
  }

  @override
  String get protectionCloudBackupDryRun => '시험 실행';

  @override
  String protectionCloudBackupDryRunStarted(String path) {
    return '$path 백업을 시뮬레이션합니다.';
  }

  @override
  String protectionCloudBackupRunTitle(String path) {
    return '$path을(를) 지금 백업할까요?';
  }

  @override
  String get protectionCloudBackupRunAction => '백업 시작';

  @override
  String get protectionCloudBackupRunConsequence =>
      '전송이 지금 실행되며 제공업체의 대역폭 및 요청 비용이 발생합니다.';

  @override
  String get protectionCloudBackupDeleteTitle => '이 백업 작업을 삭제할까요?';

  @override
  String get protectionCloudBackupDeleteAction => '작업 삭제';

  @override
  String get protectionCloudBackupDeleteConsequence =>
      '일정이 제거됩니다. 클라우드 저장소에 이미 있는 스냅샷은 그대로 남습니다.';

  @override
  String get protectionCloudBackupSnapshots => '저장소 스냅샷';

  @override
  String get protectionCloudBackupSnapshotsEmpty => '이 저장소에 아직 스냅샷이 없습니다.';

  @override
  String get protectionCloudBackupAbort => '실행 중인 백업 중단';

  @override
  String get protectionCloudBackupAborted => '중단을 요청했습니다.';

  @override
  String protectionCloudBackupAbortTitle(String path) {
    return '$path 백업을 중단할까요?';
  }

  @override
  String get protectionCloudBackupAbortAction => '백업 중단';

  @override
  String get protectionCloudBackupAbortConsequence =>
      '전송이 도중에 멈춥니다. 이미 업로드된 데이터는 남지만, 이번 실행으로는 사용할 수 있는 스냅샷이 만들어지지 않습니다.';

  @override
  String get protectionCloudBackupAbortConsequenceRestart =>
      '다시 백업하면 처음부터 전송하며, 제공업체의 대역폭 및 요청 요금이 부과됩니다.';

  @override
  String get protectionCloudBackupValidationPath => '백업할 데이터셋 경로를 입력하세요.';

  @override
  String get protectionCloudBackupValidationPathAbsolute =>
      '/mnt으로 시작하는 절대 경로를 사용하세요.';

  @override
  String get protectionCloudBackupValidationCredential => '클라우드 자격 증명을 선택하세요.';

  @override
  String get protectionCloudBackupValidationPassword => '저장소 비밀번호를 입력하세요.';

  @override
  String protectionCloudBackupValidationKeepLast(int bound) {
    return '스냅샷을 최소 $bound개 유지해야 합니다.';
  }

  @override
  String get protectionNewRsync => '새 rsync 작업';

  @override
  String get protectionEditTask => '작업 편집';

  @override
  String get protectionDeleteTask => '작업 삭제';

  @override
  String get protectionRunNow => '지금 실행';

  @override
  String get protectionTaskAlreadyRunning => '작업이 이미 실행 중입니다';

  @override
  String get protectionActionUnsupported => '서버가 이 작업을 지원하지 않습니다';

  @override
  String get protectionSnapshotTaskActions => '스냅샷 작업 메뉴';

  @override
  String get protectionNoReplicationTasks => '복제 작업이 없습니다.';

  @override
  String get protectionNoSnapshotTasks => '주기적 스냅샷 작업이 없습니다.';

  @override
  String get protectionNoSnapshots => '스냅샷이 없습니다.';

  @override
  String get protectionNoScrubSchedules => '스크럽 일정이 없습니다.';

  @override
  String get protectionNoCloudSyncTasks => '클라우드 동기화 작업이 없습니다.';

  @override
  String get protectionNoRsyncTasks => 'rsync 작업이 없습니다.';

  @override
  String protectionRunTaskTitle(String name) {
    return '$name을(를) 실행할까요?';
  }

  @override
  String protectionRunReplicationMessage(String direction) {
    return 'TrueNAS가 구성된 $direction 대상으로 스냅샷을 전송합니다. 스토리지, CPU, 네트워크 대역폭을 사용할 수 있습니다.';
  }

  @override
  String get protectionRunReplication => '복제 실행';

  @override
  String protectionStartScrubTitle(String pool) {
    return '$pool에서 스크럽을 시작할까요?';
  }

  @override
  String get protectionStartScrubMessage =>
      '스크럽은 풀 데이터를 검증하며, 완료될 때까지 디스크 사용량이 늘어날 수 있습니다.';

  @override
  String get protectionStartScrub => '스크럽 시작';

  @override
  String get protectionRunRsyncTitle => 'Rsync 작업을 실행할까요?';

  @override
  String protectionRunRsyncMessage(
    String direction,
    String path,
    String remote,
  ) {
    return 'TrueNAS가 $path와(과) $remote 사이에서 데이터를 $direction합니다. 작업 구성에 따라 대상의 기존 파일이 변경될 수 있습니다.';
  }

  @override
  String get protectionRunRsync => 'Rsync 실행';

  @override
  String protectionRunCloudSyncMessage(
    String direction,
    String path,
    String provider,
    String mode,
  ) {
    return 'TrueNAS가 $provider을(를) 사용해 $path을(를) $direction합니다. $mode 규칙에 따라 원격 또는 로컬 파일이 변경될 수 있습니다.';
  }

  @override
  String get protectionDryRun => '모의 실행';

  @override
  String get protectionDryRunSubtitle => '데이터를 전송하지 않고 변경 사항을 미리 봅니다.';

  @override
  String get protectionRunPreview => '미리 보기 실행';

  @override
  String get protectionRunCloudSync => '클라우드 동기화 실행';

  @override
  String get protectionSnapshotTaskCreateFailed => '주기적 스냅샷 작업을 만들지 못했습니다.';

  @override
  String protectionSnapshotTaskCreated(String dataset) {
    return '$dataset에 대한 주기적 스냅샷 작업을 만들었습니다.';
  }

  @override
  String get protectionSnapshotTaskUpdateFailed => '주기적 스냅샷 작업을 수정하지 못했습니다.';

  @override
  String protectionSnapshotTaskUpdated(String dataset) {
    return '$dataset에 대한 주기적 스냅샷 작업을 수정했습니다.';
  }

  @override
  String get protectionSnapshotTaskUpdateLabel => '스냅샷 작업 수정';

  @override
  String protectionUpdateTaskTitle(String dataset) {
    return '$dataset을(를) 수정할까요?';
  }

  @override
  String get protectionUpdateTaskBody => 'TrueNAS가 새 스냅샷 일정과 보존 정책을 적용합니다.';

  @override
  String protectionRetentionChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '기존 스냅샷 보존 설정 $count개가 변경됩니다:',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionConsequence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '이미 존재하는 스냅샷 $count개의 보존 기한이 새로 적용되어 삭제될 수 있습니다. 삭제된 스냅샷은 복구할 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String protectionRetentionEntry(String name, String count) {
    return '• $name: $count';
  }

  @override
  String get protectionNoRetentionChanges => '서버가 보고한 기존 스냅샷 보존 변경 사항이 없습니다.';

  @override
  String get protectionApplyChanges => '변경 사항 적용';

  @override
  String get protectionRunSnapshotTaskTitle => '지금 스냅샷 작업을 실행할까요?';

  @override
  String protectionRunSnapshotTaskMessage(
    String scope,
    String dataset,
    String schema,
  ) {
    return 'TrueNAS가 $schema을(를) 사용해 $dataset의 $scope 스냅샷을 즉시 생성합니다.';
  }

  @override
  String get protectionScopeRecursive => '재귀';

  @override
  String get protectionRunSnapshotTask => '스냅샷 작업 실행';

  @override
  String get protectionDeleteSnapshotTaskTitle => '스냅샷 작업을 삭제할까요?';

  @override
  String get protectionDeleteSnapshotTaskConsequence =>
      '일정이 제거됩니다. 이 작업으로 이미 만들어진 스냅샷은 유지되며 각자의 보존 기간에 따라 만료됩니다.';

  @override
  String protectionSnapshotHeld(String name) {
    return '$name이(가) 삭제로부터 보호됩니다.';
  }

  @override
  String protectionSnapshotReleased(String name) {
    return '$name의 보호를 해제했습니다.';
  }

  @override
  String protectionSnapshotHoldAction(String name) {
    return '$name 보호';
  }

  @override
  String protectionSnapshotReleaseAction(String name) {
    return '$name 보호 해제';
  }

  @override
  String protectionSnapshotCloneAction(String name) {
    return '$name 복제';
  }

  @override
  String protectionSnapshotCloned(String destination) {
    return '$destination(으)로 복제했습니다.';
  }

  @override
  String protectionSnapshotDeleteAction(String name) {
    return '$name 삭제';
  }

  @override
  String protectionSnapshotDeleted(String name) {
    return '$name을(를) 삭제했습니다.';
  }

  @override
  String protectionSnapshotRollbackAction(String dataset) {
    return '$dataset 롤백';
  }

  @override
  String protectionSnapshotRolledBack(String dataset, String name) {
    return '$dataset을(를) $name 시점으로 롤백했습니다.';
  }

  @override
  String protectionSnapshotActionFailed(String action) {
    return 'TrueNAS가 $action을(를) 수행하지 못했습니다.';
  }

  @override
  String protectionSnapshotTarget(String dataset, String name) {
    return '$dataset@$name';
  }

  @override
  String get protectionDeleteSnapshotTitle => '스냅샷을 삭제할까요?';

  @override
  String get protectionDeleteSnapshotAction => '스냅샷 삭제';

  @override
  String get protectionDeleteSnapshotConsequenceRestore =>
      '이 복원 지점이 삭제되며 복구할 수 없습니다.';

  @override
  String get protectionDeleteSnapshotConsequenceReplication =>
      '이 스냅샷에 의존하는 복제는 전체 재전송이 필요할 수 있습니다.';

  @override
  String get protectionDeleteSnapshotNote => '데이터셋의 실제 데이터는 영향을 받지 않습니다.';

  @override
  String get protectionRollbackTitle => '이 스냅샷으로 롤백할까요?';

  @override
  String get protectionRollbackAction => '롤백';

  @override
  String protectionRollbackConsequenceChanges(String dataset) {
    return '이 스냅샷 이후 $dataset에 기록된 모든 변경 사항이 영구적으로 사라집니다.';
  }

  @override
  String protectionRollbackConsequenceNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이후 스냅샷 $count개가 삭제됩니다.',
    );
    return '$_temp0';
  }

  @override
  String get protectionRollbackConsequenceClones =>
      '해당 스냅샷에서 복제된 데이터셋도 함께 삭제됩니다.';

  @override
  String get protectionRollbackConsequenceForce =>
      '애플리케이션이 사용 중이더라도 데이터셋이 마운트 해제됩니다.';

  @override
  String get protectionRollbackNote => '계속하기 전에 이 데이터셋에 쓰는 애플리케이션을 중지하세요.';

  @override
  String get protectionCloudSyncConfigLoadFailed =>
      '클라우드 동기화 작업 구성을 불러오지 못했습니다.';

  @override
  String get protectionReplicationConfigLoadFailed => '복제 작업 구성을 불러오지 못했습니다.';

  @override
  String get protectionRsyncConfigLoadFailed => 'rsync 작업 구성을 불러오지 못했습니다.';

  @override
  String get protectionCreateTask => '작업 만들기';

  @override
  String get protectionSaveTask => '작업 저장';

  @override
  String protectionCreateCloudSyncTitle(String name) {
    return '클라우드 동기화 $name을(를) 만들까요?';
  }

  @override
  String protectionSaveCloudSyncTitle(String name) {
    return '클라우드 동기화 $name을(를) 저장할까요?';
  }

  @override
  String protectionCloudSyncPushConsequence(
    String path,
    String remote,
    String provider,
  ) {
    return '$path을(를) $provider의 $remote(으)로 전송합니다.';
  }

  @override
  String protectionCloudSyncPullConsequence(String remote, String path) {
    return '$remote을(를) 이 서버의 $path(으)로 전송합니다.';
  }

  @override
  String get protectionSelectedProvider => '선택한 공급자';

  @override
  String protectionCloudSyncSyncPush(String remote, String path) {
    return '동기화는 $path에 더 이상 없는 파일을 $remote에서 삭제합니다.';
  }

  @override
  String protectionCloudSyncSyncPull(String path, String remote) {
    return '동기화는 $remote에 더 이상 없는 파일을 $path에서 삭제합니다.';
  }

  @override
  String protectionCloudSyncMovePush(String path) {
    return '이동은 업로드가 성공한 뒤 이 서버의 $path에서 파일을 삭제합니다.';
  }

  @override
  String protectionCloudSyncMovePull(String remote) {
    return '이동은 다운로드가 성공한 뒤 $remote에서 파일을 삭제합니다.';
  }

  @override
  String get protectionCloudSyncCopyNote => '복사는 어느 쪽에서도 파일을 삭제하지 않습니다.';

  @override
  String get protectionCloudSyncEncryptionNote =>
      '업로드 전에 파일이 암호화됩니다. 암호화 비밀번호를 잃어버리면 데이터를 복구할 수 없으며, TrueDock은 이를 저장하지 않습니다.';

  @override
  String protectionCreateReplicationTitle(String name) {
    return '복제 $name을(를) 만들까요?';
  }

  @override
  String protectionSaveReplicationTitle(String name) {
    return '복제 $name을(를) 저장할까요?';
  }

  @override
  String protectionReplicationPushConsequence(int count, String target) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '원본 데이터셋 $count개를 대상의 $target(으)로 복제합니다.',
    );
    return '$_temp0';
  }

  @override
  String protectionReplicationPullConsequence(String target) {
    return '이 서버의 $target(으)로 가져오며, 충돌하는 로컬 스냅샷을 덮어씁니다.';
  }

  @override
  String get protectionReplicationOverwriteNote =>
      '작업이 실행되면 원본과 충돌하는 대상 스냅샷을 덮어씁니다.';

  @override
  String protectionReplicationRetentionNote(int value, String unit) {
    return '$value $unit보다 오래된 대상 스냅샷은 자동으로 삭제됩니다.';
  }

  @override
  String get protectionReplicationLocalNote => '로컬 작업이므로 양쪽 모두 이 서버에 있습니다.';

  @override
  String protectionCreateRsyncTitle(String path) {
    return '$path에 대한 rsync 작업을 만들까요?';
  }

  @override
  String protectionSaveRsyncTitle(String path) {
    return '$path에 대한 rsync 작업을 저장할까요?';
  }

  @override
  String protectionRsyncPushConsequence(String path, String remote) {
    return '$path을(를) $remote(으)로 복사하며 원격 시스템의 파일을 덮어쓸 수 있습니다.';
  }

  @override
  String protectionRsyncPullConsequence(String remote, String path) {
    return '$remote을(를) $path(으)로 복사하며 이 서버의 로컬 파일을 덮어쓸 수 있습니다.';
  }

  @override
  String protectionRsyncRunAsNote(String user, String port) {
    return '$user 계정으로 $port 포트에서 실행됩니다.';
  }

  @override
  String get protectionRsyncScheduleNote => '작업을 비활성화하기 전까지 일정에 따라 계속 실행됩니다.';

  @override
  String get protectionDeleteReplicationTitle => '복제 작업을 삭제할까요?';

  @override
  String get protectionDeleteReplicationConsequence =>
      '작업 정의가 제거됩니다. 진행 중인 복제는 끝까지 실행되므로, 지금 중지하려면 작업을 먼저 중단하세요.';

  @override
  String get protectionDeleteReplicationKeepNote => '이미 대상으로 복제된 스냅샷은 유지됩니다.';

  @override
  String get protectionDeleteCloudSyncTitle => '클라우드 동기화 작업을 삭제할까요?';

  @override
  String get protectionDeleteCloudSyncConsequence =>
      '작업 정의가 제거됩니다. 저장된 클라우드 자격 증명은 유지되어 다른 작업에서 재사용할 수 있습니다.';

  @override
  String get protectionDeleteCloudSyncKeepNote =>
      '원격으로 이미 전송된 파일은 양쪽에 그대로 남습니다.';

  @override
  String get protectionDeleteRsyncTitle => 'rsync 작업을 삭제할까요?';

  @override
  String get protectionDeleteRsyncConsequence =>
      '작업 정의가 제거됩니다. 이미 전송된 파일은 양쪽에 그대로 남습니다.';

  @override
  String get protectionTaskStartFailed => 'TrueNAS 작업을 시작하지 못했습니다.';

  @override
  String protectionTaskStarted(String label) {
    return '$label을(를) 시작했습니다.';
  }

  @override
  String protectionJobSuffix(String jobId) {
    return ' · 작업 $jobId';
  }

  @override
  String get protectionStateIdle => '대기 중';

  @override
  String protectionReplicationSubtitleRow(String direction, String state) {
    return '$direction · $state';
  }

  @override
  String protectionSnapshotTaskSubtitle(String schedule, String retention) {
    return 'Cron $schedule · 보존 $retention';
  }

  @override
  String get protectionRecursiveSuffix => ' · 재귀';

  @override
  String protectionScrubSubtitle(String schedule, int days) {
    return '$schedule · 기준 $days일';
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
  String get protectionLabelSchedule => '일정';

  @override
  String get protectionLabelRetention => '보존';

  @override
  String protectionRetentionHours(int count) {
    return '$count시간';
  }

  @override
  String protectionRetentionDays(int count) {
    return '$count일';
  }

  @override
  String protectionRetentionWeeks(int count) {
    return '$count주';
  }

  @override
  String protectionRetentionMonths(int count) {
    return '$count개월';
  }

  @override
  String protectionRetentionYears(int count) {
    return '$count년';
  }

  @override
  String get protectionScheduleUnavailable => '일정 정보 없음';

  @override
  String protectionScrubSchedule(String hour, String minute, String day) {
    return '$hour:$minute · 요일 $day';
  }

  @override
  String get protectionLabelNaming => '이름 규칙';

  @override
  String get protectionLabelScope => '범위';

  @override
  String get protectionScopeRecursiveValue => '재귀';

  @override
  String get protectionScopeSelectedOnly => '선택한 데이터셋만';

  @override
  String get protectionLabelNoChanges => '변경 없음';

  @override
  String get protectionCreateSnapshotAnyway => '스냅샷 생성';

  @override
  String get protectionSkipSnapshot => '스냅샷 건너뛰기';

  @override
  String get protectionLabelState => '상태';

  @override
  String get protectionEnabled => '사용';

  @override
  String get protectionDisabled => '사용 안 함';

  @override
  String get protectionLabelExcludes => '제외';

  @override
  String get snapshotReleaseHold => '보호 해제';

  @override
  String get snapshotHold => '스냅샷 보호';

  @override
  String get snapshotReleaseHoldSubtitle => '이 스냅샷을 다시 삭제할 수 있게 합니다.';

  @override
  String get snapshotHoldSubtitle => '보호를 해제할 때까지 삭제를 차단합니다.';

  @override
  String get snapshotCloneTitle => '새 데이터셋으로 복제';

  @override
  String get snapshotCloneSubtitle => '데이터를 변경하지 않고 쓰기 가능한 사본을 만듭니다.';

  @override
  String get snapshotRollbackTitle => '이 스냅샷으로 롤백';

  @override
  String get snapshotRollbackSubtitleClean => '이 스냅샷 이후의 변경 사항을 버립니다.';

  @override
  String snapshotRollbackSubtitleNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '변경 사항과 이후 스냅샷 $count개를 버립니다.',
    );
    return '$_temp0';
  }

  @override
  String get snapshotDeleteTitle => '스냅샷 삭제';

  @override
  String get snapshotDeleteHeldSubtitle => '이 스냅샷을 삭제하려면 먼저 보호를 해제하세요.';

  @override
  String get snapshotDeleteSubtitle => '이 복원 지점을 영구적으로 제거합니다.';

  @override
  String get snapshotNoActions => '이 TrueNAS 버전은 TrueDock에 스냅샷 작업을 제공하지 않습니다.';

  @override
  String get snapshotRollbackHeading => '롤백';

  @override
  String get snapshotRollbackModeNewestOnly => '가장 최신 스냅샷일 때만';

  @override
  String get snapshotRollbackModeNewer => '이후 스냅샷 삭제';

  @override
  String get snapshotRollbackModeNewerAndClones => '이후 스냅샷과 그 복제본 삭제';

  @override
  String get snapshotRollbackModeNewestOnlyDescription =>
      '더 최신 스냅샷이 하나라도 있으면 롤백이 실패합니다. 가장 안전한 옵션입니다.';

  @override
  String get snapshotRollbackModeNewerDescription =>
      '이 스냅샷 이후에 만들어진 모든 스냅샷이 영구적으로 삭제됩니다.';

  @override
  String get snapshotRollbackModeNewerAndClonesDescription =>
      '이후 스냅샷과 그로부터 복제된 데이터셋이 모두 삭제됩니다.';

  @override
  String snapshotRollbackNewerWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이후 스냅샷 $count개가 있으므로, 삭제를 선택하기 전까지 이 옵션은 실패합니다.',
    );
    return '$_temp0';
  }

  @override
  String get snapshotForceUnmount => '사용 중이면 강제 마운트 해제';

  @override
  String get snapshotForceUnmountSubtitle =>
      '애플리케이션이 데이터셋을 계속 열어 두고 있을 때 필요합니다.';

  @override
  String get snapshotCloneHeading => '스냅샷 복제';

  @override
  String get snapshotCloneDescription =>
      '복제본은 이 스냅샷과 저장 공간을 공유하는 읽기·쓰기 데이터셋으로 시작합니다. 복제본이 있는 동안에는 스냅샷을 삭제할 수 없습니다.';

  @override
  String get snapshotCloneDestinationLabel => '새 데이터셋 경로';

  @override
  String get snapshotCreateClone => '복제본 만들기';

  @override
  String get snapshotCloneValidationPath =>
      'tank/restored처럼 전체 데이터셋 경로를 입력하세요.';

  @override
  String get snapshotCloneValidationSameDataset => '원본 데이터셋과 다른 경로를 선택하세요.';

  @override
  String snapshotCloneSuffix(String dataset) {
    return '$dataset-clone';
  }

  @override
  String get snapshotTaskReviewTitle => '스냅샷 작업 검토';

  @override
  String get snapshotTaskNewTitle => '새 스냅샷 작업';

  @override
  String get snapshotTaskEditTitle => '스냅샷 작업 편집';

  @override
  String get snapshotTaskSubtitle => '자동 ZFS 스냅샷 및 보존';

  @override
  String get snapshotTaskNoDatasets =>
      '잠금 해제된 파일시스템 데이터셋이 없습니다. 먼저 데이터셋을 만들거나 잠금을 해제하세요.';

  @override
  String get snapshotTaskDataset => '데이터셋';

  @override
  String get snapshotTaskIncludeChildren => '하위 데이터셋 포함';

  @override
  String get snapshotTaskIncludeChildrenSubtitle => '이 데이터셋 아래를 재귀적으로 스냅샷합니다.';

  @override
  String get snapshotTaskExcludes => '제외할 하위 데이터셋';

  @override
  String get snapshotTaskExcludesHelper => '선택 사항 · 한 줄에 전체 데이터셋 이름 하나';

  @override
  String get snapshotTaskRetention => '보존';

  @override
  String get snapshotTaskKeepFor => '보관 기간';

  @override
  String get snapshotTaskUnit => '단위';

  @override
  String get snapshotTaskNamingSchema => '이름 스키마';

  @override
  String get snapshotTaskNamingHelper => '각 스냅샷 이름에 사용하는 strftime 패턴';

  @override
  String get snapshotTaskSchedule => '일정';

  @override
  String get snapshotTaskWindowBegins => '시작 시각';

  @override
  String get snapshotTaskWindowEnds => '종료 시각';

  @override
  String get snapshotTaskAllowEmpty => '변경 없어도 스냅샷 생성';

  @override
  String get snapshotTaskAllowEmptySubtitle => '데이터가 변경되지 않았더라도 스냅샷을 만듭니다.';

  @override
  String get snapshotTaskEnable => '즉시 사용';

  @override
  String get snapshotTaskEnableCreateSubtitle => '작업을 만든 뒤 이 일정을 실행합니다.';

  @override
  String get snapshotTaskEnableEditSubtitle => '이 일정이 계속 실행되도록 허용합니다.';

  @override
  String get snapshotTaskCreate => '작업 만들기';

  @override
  String get snapshotTaskNone => '없음';

  @override
  String get snapshotTaskScope => '범위';

  @override
  String get snapshotTaskNaming => '이름 규칙';

  @override
  String get snapshotTaskState => '상태';

  @override
  String snapshotTaskRetentionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String snapshotTaskExcludedList(String datasets) {
    return '제외된 데이터셋: $datasets';
  }

  @override
  String get snapshotTaskRetentionNotice =>
      'TrueNAS는 설정한 보존 기간이 지나면 이 작업이 만든 스냅샷을 자동으로 삭제합니다.';

  @override
  String get snapshotUnitHours => '시간';

  @override
  String get snapshotUnitDays => '일';

  @override
  String get snapshotUnitWeeks => '주';

  @override
  String get snapshotUnitMonths => '개월';

  @override
  String get snapshotUnitYears => '년';

  @override
  String get snapshotPresetHourly => '매시간';

  @override
  String get snapshotPresetDaily => '매일';

  @override
  String get snapshotPresetWeekly => '매주';

  @override
  String get snapshotPresetMonthly => '매월';

  @override
  String get snapshotPresetCustom => '사용자 지정';

  @override
  String get snapshotScheduleEveryHour => '매시 정각';

  @override
  String get snapshotScheduleEverySunday => '매주 일요일 00:00';

  @override
  String get snapshotScheduleFirstOfMonth => '매월 1일 00:00';

  @override
  String get snapshotScheduleEveryDay => '매일 00:00';

  @override
  String snapshotScheduleCron(String expression) {
    return 'Cron $expression';
  }

  @override
  String get snapshotCronMinute => '분';

  @override
  String get snapshotCronHour => '시';

  @override
  String get snapshotCronDayOfMonth => '일(날짜)';

  @override
  String get snapshotCronMonth => '월';

  @override
  String get snapshotCronDayOfWeek => '요일 (1 월요일–7 일요일)';

  @override
  String get snapshotValidationDataset => '데이터셋을 선택하세요.';

  @override
  String get snapshotValidationRetention => '보존 기간은 1 이상이어야 합니다.';

  @override
  String get snapshotValidationNamingRequired => '스냅샷 이름 스키마를 입력하세요.';

  @override
  String get snapshotValidationNamingSlash => '스냅샷 이름에는 /를 사용할 수 없습니다.';

  @override
  String get snapshotValidationExclude => '제외 항목은 선택한 데이터셋의 하위여야 합니다.';

  @override
  String get snapshotValidationCron => '*, 00, */2처럼 숫자 cron 표현식을 사용하세요.';

  @override
  String get snapshotValidationTime => 'HH:mm 형식의 24시간제 시각을 사용하세요.';

  @override
  String get replicationReviewTitle => '복제 검토';

  @override
  String get replicationNewTitle => '새 복제';

  @override
  String get replicationEditTitle => '복제 편집';

  @override
  String get replicationTaskName => '작업 이름';

  @override
  String get replicationTransport => '전송 방식';

  @override
  String get replicationTransportSsh => 'SSH';

  @override
  String get replicationTransportSshNetcat => 'SSH + netcat (더 빠르지만 보안은 약함)';

  @override
  String get replicationTransportLocal => '로컬 (같은 시스템)';

  @override
  String get replicationSshLoadFailed =>
      '저장된 SSH 연결을 불러오지 못했습니다. 계정에 자격 증명 조회 권한이 있는지 확인하세요.';

  @override
  String get replicationNoSshCredentials =>
      '저장된 SSH 연결이 없습니다. TrueNAS 웹 UI의 자격 증명에서 만든 뒤 이 편집기를 다시 여세요. TrueDock은 SSH 키를 만들지 않습니다.';

  @override
  String get replicationSshConnection => 'SSH 연결';

  @override
  String get replicationDirection => '방향';

  @override
  String get replicationDirectionPush => '푸시 (이 서버 → 대상)';

  @override
  String get replicationDirectionPull => '풀 (대상 → 이 서버)';

  @override
  String get replicationSourceDatasets => '원본 데이터셋';

  @override
  String get replicationSourceDatasetsHelp =>
      '하나의 작업으로 여러 데이터셋을 한 대상에 복제할 수 있습니다.';

  @override
  String get replicationNoDatasets => '이 서버가 보고한 데이터셋이 없습니다.';

  @override
  String get replicationTargetDataset => '대상 데이터셋';

  @override
  String get replicationTargetHelper => '끝에 /이름을 붙이면 새 데이터셋을 만듭니다.';

  @override
  String get replicationNamingSchema => '스냅샷 이름 스키마';

  @override
  String get replicationNamingHelper => '이 작업이 복제할 원본 스냅샷을 결정합니다.';

  @override
  String get replicationRetentionHeading => '대상의 보존 정책';

  @override
  String get replicationRetentionSource => '원본과 동일';

  @override
  String get replicationRetentionCustom => '사용자 지정 보존';

  @override
  String get replicationRetentionNone => '영구 보관';

  @override
  String get replicationRetentionSourceDescription =>
      '대상 스냅샷은 원본 작업의 보존 정책을 따릅니다.';

  @override
  String get replicationRetentionCustomDescription =>
      '설정한 기간이 지나면 대상 스냅샷이 삭제됩니다.';

  @override
  String get replicationRetentionNoneDescription => '대상 스냅샷은 자동으로 삭제되지 않습니다.';

  @override
  String get replicationKeepFor => '보관 기간';

  @override
  String get replicationUnitHours => '시간';

  @override
  String get replicationUnitDays => '일';

  @override
  String get replicationUnitWeeks => '주';

  @override
  String get replicationUnitMonths => '개월';

  @override
  String get replicationUnitYears => '년';

  @override
  String get replicationScheduleHeading => '일정';

  @override
  String get replicationRunOnSchedule => '일정에 따라 실행';

  @override
  String get replicationRunOnScheduleSubtitle => '끄면 이 작업을 수동으로만 실행합니다.';

  @override
  String get replicationRecursive => '재귀';

  @override
  String get replicationRecursiveSubtitle => '각 원본의 하위 데이터셋을 포함합니다.';

  @override
  String get replicationEnabled => '사용';

  @override
  String get replicationEnabledSubtitle => '사용 안 함으로 두면 설정은 유지되지만 실행되지 않습니다.';

  @override
  String get replicationReviewName => '이름';

  @override
  String get replicationReviewDirection => '방향';

  @override
  String get replicationReviewTransport => '전송 방식';

  @override
  String get replicationReviewSsh => 'SSH';

  @override
  String get replicationNotSelected => '선택 안 함';

  @override
  String get replicationReviewSources => '원본';

  @override
  String get replicationReviewNone => '없음';

  @override
  String get replicationReviewTarget => '대상';

  @override
  String get replicationReviewSnapshots => '스냅샷';

  @override
  String get replicationReviewRetention => '보존';

  @override
  String replicationRetentionValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get replicationReviewSchedule => '일정';

  @override
  String get replicationManualOnly => '수동 실행만';

  @override
  String get replicationReviewRecursive => '재귀';

  @override
  String get replicationReviewEnabled => '사용';

  @override
  String get replicationYes => '예';

  @override
  String get replicationNo => '아니요';

  @override
  String get replicationOverwriteWarning =>
      '복제는 원본과 충돌하는 대상 데이터셋의 스냅샷을 덮어씁니다. 특히 푸시 작업이라면 저장하기 전에 대상 경로를 확인하세요.';

  @override
  String get replicationCustomRetentionWarning =>
      '사용자 지정 보존은 위에서 설정한 기간이 지난 대상 스냅샷을 삭제합니다.';

  @override
  String get replicationCronMinute => '분';

  @override
  String get replicationCronHour => '시';

  @override
  String get replicationCronDay => '일';

  @override
  String get replicationCronMonth => '월';

  @override
  String get replicationCronWeekday => '요일';

  @override
  String get replicationValidationName => '작업 이름을 입력하세요.';

  @override
  String get replicationValidationSources => '원본 데이터셋을 하나 이상 선택하세요.';

  @override
  String get replicationValidationTarget => '대상 데이터셋 경로를 입력하세요.';

  @override
  String get replicationValidationSsh => '이 전송 방식에 사용할 저장된 SSH 연결을 선택하세요.';

  @override
  String get replicationValidationNamingRequired => '스냅샷 이름 스키마를 입력하세요.';

  @override
  String get replicationValidationNamingSlash => '스냅샷 이름에는 /를 사용할 수 없습니다.';

  @override
  String get replicationValidationRetention => '보존 기간은 1 이상이어야 합니다.';

  @override
  String get replicationValidationTargetSameAsSource =>
      '대상은 원본 데이터셋과 같을 수 없습니다.';

  @override
  String get taskPresetHourly => '매시간';

  @override
  String get taskPresetDaily => '매일';

  @override
  String get taskPresetWeekly => '매주';

  @override
  String get taskPresetMonthly => '매월';

  @override
  String get taskPresetCustom => '사용자 지정';

  @override
  String get taskScheduleEveryHour => '매시 정각';

  @override
  String get taskScheduleEverySunday => '매주 일요일 00:00';

  @override
  String get taskScheduleFirstOfMonth => '매월 1일 00:00';

  @override
  String get taskScheduleEveryDay => '매일 00:00';

  @override
  String taskScheduleCron(String expression) {
    return 'Cron $expression';
  }

  @override
  String get taskScheduleCronInvalid => '*, 00, */2처럼 숫자 cron 표현식을 사용하세요.';

  @override
  String get rsyncReviewTitle => 'rsync 작업 검토';

  @override
  String get rsyncNewTitle => '새 rsync 작업';

  @override
  String get rsyncEditTitle => 'rsync 작업 편집';

  @override
  String get rsyncLocalPath => '로컬 경로';

  @override
  String get rsyncLocalPathHelper => '이 서버의 절대 경로입니다. 예: /mnt/tank/media';

  @override
  String get rsyncRunAsUser => '실행 계정';

  @override
  String get rsyncRunAsUserHelp => 'SSH 모드에서는 SSH 연결의 사용자와 일치해야 합니다.';

  @override
  String get rsyncNoLocalUsers => '이 서버가 보고한 로컬 사용자가 없습니다.';

  @override
  String get rsyncUser => '사용자';

  @override
  String get rsyncDirection => '방향';

  @override
  String get rsyncDirectionPush => '푸시 (이 서버 → 원격)';

  @override
  String get rsyncDirectionPull => '풀 (원격 → 이 서버)';

  @override
  String get rsyncDirectionPushDescription => '로컬 경로를 원격 호스트나 모듈로 보냅니다.';

  @override
  String get rsyncDirectionPullDescription => '원격 경로를 이 서버의 로컬 경로로 복사합니다.';

  @override
  String get rsyncRemote => '원격';

  @override
  String get rsyncMode => '모드';

  @override
  String get rsyncModeSsh => 'SSH';

  @override
  String get rsyncModeModule => 'rsync 모듈';

  @override
  String get rsyncRemoteHost => '원격 호스트';

  @override
  String get rsyncRemotePort => '원격 포트 (선택)';

  @override
  String rsyncRemotePortHelper(int port) {
    return '비워 두면 기본값($port)을 사용합니다.';
  }

  @override
  String get rsyncRemotePath => '원격 경로';

  @override
  String get rsyncRemoteModule => '원격 모듈';

  @override
  String get rsyncRemoteModuleHelper => '원격 rsync 데몬에 정의된 모듈 이름입니다.';

  @override
  String get rsyncDescription => '설명 (선택)';

  @override
  String get rsyncValidateRemotePath => '원격 경로 검증';

  @override
  String get rsyncValidateRemotePathSubtitle => '실행 전에 서버가 원격 경로를 확인하도록 합니다.';

  @override
  String get rsyncReviewHost => '호스트';

  @override
  String get rsyncReviewPort => '포트';

  @override
  String get rsyncReviewModule => '모듈';

  @override
  String get rsyncPushWarning => '푸시 작업은 원격 대상에 기록하며 그곳의 파일을 덮어쓸 수 있습니다.';

  @override
  String rsyncPullWarning(String path) {
    return '풀 작업은 이 서버의 $path에 기록하며 로컬 파일을 덮어쓸 수 있습니다.';
  }

  @override
  String get rsyncValidationPathRequired => '로컬 경로를 입력하세요.';

  @override
  String get rsyncValidationPathAbsolute => '/로 시작하는 절대 경로를 사용하세요.';

  @override
  String get rsyncValidationUser => '실행할 로컬 사용자를 선택하세요.';

  @override
  String get rsyncValidationRemoteHost => '원격 호스트를 입력하세요.';

  @override
  String get rsyncValidationRemotePort => '1에서 65535 사이의 포트를 사용하세요.';

  @override
  String get rsyncValidationRemotePath => '원격 경로를 입력하세요.';

  @override
  String get rsyncValidationSsh => '저장된 SSH 연결을 선택하세요.';

  @override
  String get rsyncValidationRemoteModule => '원격 rsync 모듈 이름을 입력하세요.';

  @override
  String get cloudSyncReviewTitle => '클라우드 동기화 검토';

  @override
  String get cloudSyncNewTitle => '새 클라우드 동기화';

  @override
  String get cloudSyncEditTitle => '클라우드 동기화 편집';

  @override
  String get cloudSyncTaskName => '작업 이름';

  @override
  String get cloudSyncCredentialHeading => '클라우드 자격 증명';

  @override
  String get cloudSyncCredentialsLoadFailed =>
      '저장된 클라우드 자격 증명을 불러오지 못했습니다. 계정에 자격 증명 조회 권한이 있는지 확인하세요.';

  @override
  String get cloudSyncNoCredentials =>
      '저장된 클라우드 자격 증명이 없습니다. TrueNAS 웹 UI의 자격 증명에서 만든 뒤 이 편집기를 다시 여세요. TrueDock은 클라우드 자격 증명을 만들지 않습니다.';

  @override
  String get cloudSyncCredential => '자격 증명';

  @override
  String get cloudSyncDirection => '방향';

  @override
  String get cloudSyncDirectionPush => '푸시 (이 서버 → 클라우드)';

  @override
  String get cloudSyncDirectionPull => '풀 (클라우드 → 이 서버)';

  @override
  String get cloudSyncDirectionPushDescription => '로컬 경로를 클라우드 공급자로 올려 보냅니다.';

  @override
  String get cloudSyncDirectionPullDescription => '원격 위치를 로컬 경로로 내려받습니다.';

  @override
  String get cloudSyncTransferMode => '전송 모드';

  @override
  String get cloudSyncModeSync => '동기화';

  @override
  String get cloudSyncModeCopy => '복사';

  @override
  String get cloudSyncModeMove => '이동';

  @override
  String get cloudSyncModeSyncDescription =>
      '대상을 원본과 동일하게 맞춥니다. 원본에 없는 파일은 대상에서 삭제됩니다.';

  @override
  String get cloudSyncModeCopyDescription =>
      '새 파일과 변경된 파일을 복사합니다. 아무것도 삭제하지 않습니다.';

  @override
  String get cloudSyncModeMoveDescription => '파일을 복사한 뒤 전송이 성공하면 원본에서 삭제합니다.';

  @override
  String get cloudSyncLocalPath => '로컬 경로';

  @override
  String get cloudSyncLocalPathHelper => '절대 경로입니다. 예: /mnt/tank/media';

  @override
  String get cloudSyncRemoteLocation => '원격 위치';

  @override
  String get cloudSyncBucket => '버킷';

  @override
  String get cloudSyncFolder => '폴더';

  @override
  String get cloudSyncFolderBucketHelper => '버킷 내부 경로입니다. 비워 두면 루트를 사용합니다.';

  @override
  String get cloudSyncFolderDriveHelper => '원격 드라이브의 경로입니다. 비워 두면 루트를 사용합니다.';

  @override
  String get cloudSyncStorageClass => '스토리지 클래스 (선택)';

  @override
  String get cloudSyncStorageClassHelper => 'S3 전용입니다. 예: STANDARD 또는 GLACIER';

  @override
  String get cloudSyncAdvanced => '고급';

  @override
  String get cloudSyncTransfers => '동시 전송 수 (선택)';

  @override
  String get cloudSyncTransfersHelper => '비워 두면 서버 기본값을 사용합니다.';

  @override
  String get cloudSyncEncryptFiles => '파일 암호화';

  @override
  String get cloudSyncEncryptFilesSubtitle => '파일 내용이 이 서버를 떠나기 전에 암호화합니다.';

  @override
  String get cloudSyncEncryptNames => '파일 이름 암호화';

  @override
  String get cloudSyncEncryptNamesSubtitle => '내용뿐 아니라 이름도 숨깁니다.';

  @override
  String get cloudSyncPassword => '암호화 비밀번호';

  @override
  String get cloudSyncPasswordEdit => '새 암호화 비밀번호 (선택)';

  @override
  String get cloudSyncPasswordHelper => '필수입니다. 잃어버리면 백업을 읽을 수 없습니다.';

  @override
  String get cloudSyncPasswordEditHelper => '비워 두면 기존 비밀번호를 유지합니다.';

  @override
  String get cloudSyncShowSecret => '표시';

  @override
  String get cloudSyncHideSecret => '숨기기';

  @override
  String get cloudSyncSalt => '암호화 솔트 (선택)';

  @override
  String get cloudSyncSaltEdit => '새 암호화 솔트 (선택)';

  @override
  String get cloudSyncSaltHelper => '선택적으로 추가하는 비밀 값입니다.';

  @override
  String get cloudSyncSaltEditHelper => '비워 두면 기존 솔트를 유지합니다.';

  @override
  String get cloudSyncSecretsNotice =>
      '암호화 비밀 값은 연결된 서버로만 전송됩니다. TrueDock은 이를 저장하거나 기록하거나 자동 입력하지 않으며, 잃어버린 비밀번호를 복구할 수 없습니다.';

  @override
  String cloudSyncPreservedFields(String fields) {
    return '이 작업의 고급 설정($fields)은 그대로 유지되어 변경 없이 다시 전송됩니다. 사전/사후 스크립트는 서버에서 명령을 실행하므로 웹 UI에서 편집합니다.';
  }

  @override
  String get cloudSyncPreservedFieldsEllipsis => ', …';

  @override
  String get cloudSyncReviewName => '이름';

  @override
  String get cloudSyncReviewRemote => '원격';

  @override
  String get cloudSyncReviewTransfers => '동시 전송';

  @override
  String get cloudSyncServerDefault => '서버 기본값';

  @override
  String get cloudSyncReviewEncryption => '암호화';

  @override
  String get cloudSyncEncryptionBoth => '내용 및 파일 이름';

  @override
  String get cloudSyncEncryptionContents => '내용';

  @override
  String get cloudSyncEncryptionOff => '사용 안 함';

  @override
  String get cloudSyncSyncPushWarning =>
      '동기화는 원격을 로컬 경로와 동일하게 맞춥니다. 로컬에 더 이상 없는 파일은 클라우드에서 삭제됩니다.';

  @override
  String cloudSyncSyncPullWarning(String path) {
    return '동기화는 $path을(를) 원격과 동일하게 맞춥니다. 원격에 더 이상 없는 로컬 파일은 삭제됩니다.';
  }

  @override
  String cloudSyncMovePushWarning(String path) {
    return '이동은 파일을 업로드한 뒤 이 서버의 $path에서 삭제합니다.';
  }

  @override
  String get cloudSyncMovePullWarning => '이동은 파일을 내려받은 뒤 클라우드 공급자에서 삭제합니다.';

  @override
  String get cloudSyncCopyNotice => '복사는 어느 쪽에서도 파일을 삭제하지 않습니다.';

  @override
  String get cloudSyncEncryptionReminder =>
      '암호화 비밀번호를 안전한 곳에 보관하세요. 비밀번호가 없으면 업로드한 데이터를 복원할 수 없습니다.';

  @override
  String get cloudSyncValidationName => '작업 이름을 입력하세요.';

  @override
  String get cloudSyncValidationPathRequired => '로컬 경로를 입력하세요.';

  @override
  String get cloudSyncValidationPathAbsolute => '/로 시작하는 절대 경로를 사용하세요.';

  @override
  String get cloudSyncValidationCredential => '저장된 클라우드 자격 증명을 선택하세요.';

  @override
  String get cloudSyncValidationBucket => '이 공급자의 버킷을 입력하세요.';

  @override
  String get cloudSyncValidationTransfers => '동시 전송 수는 1에서 64 사이여야 합니다.';

  @override
  String get cloudSyncValidationPassword => '암호화 비밀번호를 입력하거나 암호화를 끄세요.';

  @override
  String get sysSectionAccounts => '사용자 및 접근';

  @override
  String get sysPrivilegesTitle => '권한';

  @override
  String get sysPrivilegesSubtitle => '이 서버를 관리할 수 있는 그룹';

  @override
  String get sysPrivilegesEmpty => '설정된 권한이 없습니다.';

  @override
  String get sysPrivilegeCreate => '권한 추가';

  @override
  String get sysPrivilegeCreateTitle => '새 권한';

  @override
  String sysPrivilegeEditTitle(String name) {
    return '$name 편집';
  }

  @override
  String get sysPrivilegeName => '이름';

  @override
  String get sysPrivilegeBuiltin => '내장';

  @override
  String get sysPrivilegeBuiltinNotice =>
      'TrueNAS가 기본 제공하는 권한입니다. 범위를 좁히면 본인의 관리 접근 권한이 사라질 수 있고, 삭제할 수 없습니다.';

  @override
  String get sysPrivilegeGroups => '로컬 그룹';

  @override
  String get sysPrivilegeNoGroups => '그룹 없음';

  @override
  String get sysPrivilegeRoles => '역할';

  @override
  String sysPrivilegeRoleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '역할 $count개',
      zero: '역할 없음',
    );
    return '$_temp0';
  }

  @override
  String sysPrivilegeEffectiveRoles(int count) {
    return '선택한 역할이 함축하는 것까지 포함해 총 $count개 역할을 부여합니다.';
  }

  @override
  String get sysPrivilegeFullAdminNotice =>
      'FULL_ADMIN은 모든 권한을 부여하므로 다른 선택은 추가 효과가 없습니다.';

  @override
  String get sysPrivilegeWebShell => '웹 셸 허용';

  @override
  String get sysPrivilegeWebShellNotice =>
      '웹 셸은 root로 실행되므로 위의 역할과 무관하게 전체 제어 권한을 부여합니다.';

  @override
  String get sysPrivilegeSearchRoles => '역할 검색';

  @override
  String sysPrivilegeApplyTitle(String name) {
    return '$name을(를) 변경할까요?';
  }

  @override
  String get sysPrivilegeApplyAction => '권한 저장';

  @override
  String sysPrivilegeApplyConsequence(String server) {
    return '선택한 그룹의 구성원이 $server에서 이 역할을 즉시 갖게 됩니다.';
  }

  @override
  String get sysPrivilegeApplyConsequenceUnrestricted =>
      '제한 없는 관리 권한을 부여합니다. 해당 그룹의 누구든 서버의 모든 것을 변경하거나 삭제할 수 있습니다.';

  @override
  String get sysPrivilegeApplyConsequenceLockout =>
      '내장 권한의 범위를 좁히면 본인의 접근 권한이 사라질 수 있습니다. 다른 계정이 전체 관리 권한을 유지하는지 먼저 확인하세요.';

  @override
  String get sysPrivilegeCreated => '권한을 만들었습니다.';

  @override
  String get sysPrivilegeUpdated => '권한을 수정했습니다.';

  @override
  String get sysPrivilegeDeleted => '권한을 삭제했습니다.';

  @override
  String sysPrivilegeDeleteTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String get sysPrivilegeDeleteAction => '권한 삭제';

  @override
  String get sysPrivilegeDeleteConsequence => '해당 그룹의 구성원이 이 역할을 즉시 잃습니다.';

  @override
  String get sysPrivilegeValidationName => '이 권한의 이름을 입력하세요.';

  @override
  String get sysPrivilegeValidationRoles => '역할을 하나 이상 선택하거나 웹 셸을 허용하세요.';

  @override
  String get sysSectionNetwork => '네트워크';

  @override
  String get sysMailTitle => '알림 이메일';

  @override
  String get sysMailSubtitle => '알림과 보고서를 보낼 SMTP 서버';

  @override
  String get sysMailNotConfigured => '설정되지 않음';

  @override
  String get sysMailEditTitle => '알림 이메일';

  @override
  String get sysMailFromAddress => '보내는 주소';

  @override
  String get sysMailFromName => '보내는 이름';

  @override
  String get sysMailServer => '발신 서버';

  @override
  String get sysMailPort => '포트';

  @override
  String get sysMailSecurity => '보안';

  @override
  String get sysMailSecurityPlain => '없음';

  @override
  String get sysMailSecuritySsl => 'SSL';

  @override
  String get sysMailSecurityTls => 'STARTTLS';

  @override
  String get sysMailAuthentication => '서버에 인증';

  @override
  String get sysMailUsername => '사용자 이름';

  @override
  String get sysMailPassword => '비밀번호';

  @override
  String get sysMailPasswordHelper =>
      '비워 두면 저장된 비밀번호를 유지합니다. TrueDock은 서버에서 비밀번호를 읽어오지 않습니다.';

  @override
  String get sysMailOauthNotice =>
      '이 서버는 OAuth로 로그인합니다. TrueDock에서 주소 변경과 발송 테스트는 가능하지만 OAuth 자격 증명은 TrueNAS 웹 인터페이스에서 관리해야 합니다.';

  @override
  String get sysMailSendTest => '테스트 메시지 보내기';

  @override
  String get sysMailTestSubject => 'TrueDock 테스트 메시지';

  @override
  String get sysMailTestBody =>
      '알림 이메일 설정이 정상 동작하는지 확인하기 위해 TrueDock에서 보낸 테스트 메시지입니다.';

  @override
  String sysMailTestSent(String recipient) {
    return '$recipient(으)로 테스트 메시지를 보냈습니다.';
  }

  @override
  String get sysMailTestSentUnknown => '테스트 메시지를 보냈습니다.';

  @override
  String get sysMailUpdated => '알림 이메일 설정을 변경했습니다.';

  @override
  String get sysMailNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String get sysMailApplyTitle => '알림 이메일 설정을 변경할까요?';

  @override
  String get sysMailApplyAction => '메일 설정 저장';

  @override
  String get sysMailApplyConsequence =>
      '새 서버가 발송을 거부하면 알림이 도달하지 않습니다. 저장 후 테스트 메시지로 확인하세요.';

  @override
  String get sysMailValidationFromRequired => '알림을 보낼 주소를 입력하세요.';

  @override
  String get sysMailValidationFromInvalid => '올바른 이메일 주소를 입력하세요.';

  @override
  String get sysMailValidationServer => '발신 메일 서버를 입력하세요.';

  @override
  String sysMailValidationPort(int bound) {
    return '포트는 1에서 $bound 사이여야 합니다.';
  }

  @override
  String get sysMailValidationPassword => '사용자 이름에 해당하는 비밀번호를 입력하거나 인증을 끄세요.';

  @override
  String get sysServiceConfigTitle => '서비스 설정';

  @override
  String get sysServiceConfigSubtitle => 'SSH, SMB, NFS, FTP, SNMP 설정';

  @override
  String sysServiceEditTitle(String service) {
    return '$service 설정';
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
  String get sysServiceRestartNotice => '실행 중인 서비스는 재시작할 때 이 설정을 적용합니다.';

  @override
  String get sysServiceSecretNotice =>
      '공유 비밀 값은 서버에서 읽어오지 않습니다. 비워 두면 저장된 값을 유지합니다.';

  @override
  String sysServiceApplyTitle(String service) {
    return '$service 설정을 변경할까요?';
  }

  @override
  String get sysServiceApplyAction => '설정 저장';

  @override
  String sysServiceApplyConsequenceRunning(String service) {
    return '$service가 실행 중이며 변경을 적용하기 위해 재시작되어 클라이언트 연결이 잠시 끊깁니다.';
  }

  @override
  String sysServiceApplyConsequenceStopped(String service) {
    return '$service가 중지되어 있어 다음 시작 시 변경이 적용됩니다.';
  }

  @override
  String sysServiceUpdated(String service) {
    return '$service 설정을 변경했습니다.';
  }

  @override
  String get sysServiceNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String sysServiceValidationRequired(String field) {
    return '$field은(는) 필수입니다.';
  }

  @override
  String sysServiceValidationRange(String field, int minimum, int maximum) {
    return '$field은(는) $minimum에서 $maximum 사이여야 합니다.';
  }

  @override
  String sysServiceValidationInvalid(String field) {
    return '$field의 값이 올바르지 않습니다.';
  }

  @override
  String get sysServiceFieldTcpport => '포트';

  @override
  String get sysServiceFieldPasswordauth => '비밀번호 로그인 허용';

  @override
  String get sysServiceFieldKerberosauth => 'Kerberos 로그인 허용';

  @override
  String get sysServiceFieldTcpfwd => 'TCP 포트 포워딩 허용';

  @override
  String get sysServiceFieldCompression => '압축';

  @override
  String get sysServiceFieldNetbiosname => 'NetBIOS 이름';

  @override
  String get sysServiceFieldWorkgroup => '작업 그룹';

  @override
  String get sysServiceFieldDescription => '설명';

  @override
  String get sysServiceFieldEncryption => '전송 암호화';

  @override
  String get sysServiceFieldLocalmaster => '로컬 마스터 브라우저';

  @override
  String get sysServiceFieldEnableSmb1 => 'SMB1 사용 (취약)';

  @override
  String get sysServiceFieldNtlmv1Auth => 'NTLMv1 허용 (취약)';

  @override
  String get sysServiceFieldServers => '서버 스레드';

  @override
  String get sysServiceFieldAllowNonroot => '비루트 마운트 허용';

  @override
  String get sysServiceFieldV4Domain => 'NFSv4 도메인';

  @override
  String get sysServiceFieldMountdPort => 'mountd 포트';

  @override
  String get sysServiceFieldRdma => 'RDMA';

  @override
  String get sysServiceFieldClients => '최대 클라이언트 수';

  @override
  String get sysServiceFieldLoginattempt => '로그인 시도 횟수';

  @override
  String get sysServiceFieldTimeout => '유휴 시간 제한 (초)';

  @override
  String get sysServiceFieldTls => 'TLS 필수';

  @override
  String get sysServiceFieldOnlyanonymous => '익명 접속만 허용';

  @override
  String get sysServiceFieldOnlylocal => '로컬 사용자만 허용';

  @override
  String get sysServiceFieldDefaultroot => '사용자를 홈 디렉터리로 제한';

  @override
  String get sysServiceFieldResume => '이어받기 허용';

  @override
  String get sysServiceFieldBanner => '로그인 배너';

  @override
  String get sysServiceFieldCommunity => '커뮤니티 문자열';

  @override
  String get sysServiceFieldContact => '담당자';

  @override
  String get sysServiceFieldLocation => '위치';

  @override
  String get sysServiceFieldLoglevel => '로그 수준';

  @override
  String get sysServiceFieldTraps => '트랩 전송';

  @override
  String get sysServiceFieldZilstat => 'ZIL 통계 보고';

  @override
  String get sysServiceFieldV3 => 'SNMPv3 사용';

  @override
  String get sysServiceFieldV3Username => 'SNMPv3 사용자 이름';

  @override
  String get sysServiceFieldV3Authtype => 'SNMPv3 인증';

  @override
  String get sysServiceFieldV3Password => 'SNMPv3 비밀번호';

  @override
  String get sysServiceFieldV3Privproto => 'SNMPv3 프라이버시 프로토콜';

  @override
  String get sysServiceFieldV3Privpassphrase => 'SNMPv3 프라이버시 암호구';

  @override
  String get sysServiceChoiceDefault => '서버 기본값';

  @override
  String get sysServiceChoiceNone => '없음';

  @override
  String get sysAlertClassesTitle => '알림 정책';

  @override
  String get sysAlertClassesSubtitle => '어떤 알림을 얼마나 자주 보낼지';

  @override
  String get sysAlertClassesOpen => '알림 정책 검토';

  @override
  String sysAlertClassesSummary(int overridden, int total) {
    return '전체 $total개 중 $overridden개가 기본값과 다릅니다';
  }

  @override
  String sysAlertClassesSilenced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '음소거된 항목 $count개',
      zero: '음소거된 항목 없음',
    );
    return '$_temp0';
  }

  @override
  String get sysAlertClassLevel => '수준';

  @override
  String get sysAlertClassPolicy => '전송 주기';

  @override
  String get sysAlertPolicyImmediately => '즉시';

  @override
  String get sysAlertPolicyHourly => '매시간';

  @override
  String get sysAlertPolicyDaily => '매일';

  @override
  String get sysAlertPolicyNever => '보내지 않음';

  @override
  String get sysAlertClassDefault => '기본값';

  @override
  String get sysAlertClassChanged => '변경됨';

  @override
  String get sysAlertClassSilencedBadge => '음소거';

  @override
  String get sysAlertClassesApplyTitle => '알림 정책을 변경할까요?';

  @override
  String get sysAlertClassesApplyAction => '정책 저장';

  @override
  String get sysAlertClassesApplyConsequence =>
      '보내지 않음으로 설정한 항목은 아무리 심각해져도 어떤 대상에도 전달되지 않습니다.';

  @override
  String get sysAlertClassesApplyReplace =>
      'TrueNAS는 재정의 목록 전체를 교체하므로 여기 표시된 모든 변경이 함께 저장됩니다.';

  @override
  String get sysAlertClassesUpdated => '알림 정책을 변경했습니다.';

  @override
  String get sysAlertClassesNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String get sysAlertClassesReset => '기본값으로 되돌리기';

  @override
  String get sysAlertServicesTitle => '알림 대상';

  @override
  String get sysAlertServicesSubtitle => 'TrueNAS가 알림을 보낼 곳';

  @override
  String get sysAlertServicesEmpty =>
      '알림 대상이 없습니다. 추가하기 전까지 알림은 웹 인터페이스와 이 앱에만 표시됩니다.';

  @override
  String get sysAlertServiceCreate => '대상 추가';

  @override
  String get sysAlertServiceCreateTitle => '새 알림 대상';

  @override
  String sysAlertServiceEditTitle(String name) {
    return '$name 편집';
  }

  @override
  String get sysAlertServiceName => '이름';

  @override
  String get sysAlertServiceKind => '대상 종류';

  @override
  String get sysAlertServiceLevel => '최소 수준';

  @override
  String get sysAlertKindEmail => '이메일';

  @override
  String get sysAlertKindSnmpTrap => 'SNMP 트랩';

  @override
  String get sysAlertLevelInfo => '정보';

  @override
  String get sysAlertLevelNotice => '알림';

  @override
  String get sysAlertLevelWarning => '경고';

  @override
  String get sysAlertLevelError => '오류';

  @override
  String get sysAlertLevelCritical => '심각';

  @override
  String get sysAlertLevelAlert => '긴급 경고';

  @override
  String get sysAlertLevelEmergency => '비상';

  @override
  String get sysAlertServiceEnabled => '사용';

  @override
  String get sysAlertServiceDisabled => '사용 안 함';

  @override
  String get sysAlertServiceSecretNotice =>
      '자격 증명은 서버에서 읽어오지 않습니다. 비워 두면 저장된 값을 유지합니다.';

  @override
  String get sysAlertServiceUnknownKind =>
      'TrueDock이 지원하지 않는 대상 종류입니다. TrueNAS 웹 인터페이스에서 편집하세요.';

  @override
  String get sysAlertServiceTest => '테스트 알림 보내기';

  @override
  String sysAlertServiceTested(String name) {
    return '$name(으)로 테스트 알림을 보냈습니다.';
  }

  @override
  String get sysAlertServiceCreated => '알림 대상을 추가했습니다.';

  @override
  String get sysAlertServiceUpdated => '알림 대상을 수정했습니다.';

  @override
  String get sysAlertServiceDeleted => '알림 대상을 삭제했습니다.';

  @override
  String sysAlertServiceDeleteTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String get sysAlertServiceDeleteAction => '대상 삭제';

  @override
  String get sysAlertServiceDeleteConsequence =>
      '이곳으로 알림이 더 이상 전달되지 않습니다. 저장된 자격 증명도 함께 삭제됩니다.';

  @override
  String get sysAlertServiceValidationName => '이 대상의 이름을 입력하세요.';

  @override
  String sysAlertServiceValidationRequired(String field) {
    return '$field은(는) 필수입니다.';
  }

  @override
  String sysAlertServiceValidationInteger(String field) {
    return '$field은(는) 숫자여야 합니다.';
  }

  @override
  String sysAlertServiceValidationUrl(String field) {
    return '$field은(는) https:// 를 포함한 전체 URL이어야 합니다.';
  }

  @override
  String get sysAlertFieldEmail => '이메일 주소';

  @override
  String get sysAlertFieldUrl => '웹훅 URL';

  @override
  String get sysAlertFieldBotToken => '봇 토큰';

  @override
  String get sysAlertFieldChatIds => '채팅 ID';

  @override
  String get sysAlertFieldServiceKey => '연동 키';

  @override
  String get sysAlertFieldClientName => '클라이언트 이름';

  @override
  String get sysAlertFieldUsername => '사용자 이름';

  @override
  String get sysAlertFieldChannel => '채널';

  @override
  String get sysAlertFieldIconUrl => '아이콘 URL';

  @override
  String get sysAlertFieldApiKey => 'API 키';

  @override
  String get sysAlertFieldApiUrl => 'API URL';

  @override
  String get sysAlertFieldRoutingKey => '라우팅 키';

  @override
  String get sysAlertFieldRegion => '리전';

  @override
  String get sysAlertFieldTopicArn => '토픽 ARN';

  @override
  String get sysAlertFieldAwsAccessKeyId => '액세스 키 ID';

  @override
  String get sysAlertFieldAwsSecretAccessKey => '시크릿 액세스 키';

  @override
  String get sysAlertFieldHost => '호스트';

  @override
  String get sysAlertFieldPassword => '비밀번호';

  @override
  String get sysAlertFieldDatabase => '데이터베이스';

  @override
  String get sysAlertFieldSeriesName => '시리즈 이름';

  @override
  String get sysAlertFieldPort => '포트';

  @override
  String get sysAlertFieldCommunity => '커뮤니티 문자열';

  @override
  String get sysAlertFieldV3Username => 'SNMPv3 사용자 이름';

  @override
  String get sysAlertFieldV3Authkey => 'SNMPv3 인증 키';

  @override
  String get sysAlertFieldV3Authprotocol => 'SNMPv3 인증 프로토콜';

  @override
  String get sysAlertFieldV3Privkey => 'SNMPv3 프라이버시 키';

  @override
  String get sysSectionCron => 'Cronjob';

  @override
  String get sysCronTitle => 'Cronjob';

  @override
  String get sysCronSubtitle => 'TrueNAS가 일정에 따라 실행하는 명령';

  @override
  String get sysCronEmpty => '예약된 명령이 없습니다.';

  @override
  String get sysCronCreate => 'Cronjob 추가';

  @override
  String get sysCronCreateTitle => '새 Cronjob';

  @override
  String get sysCronEditTitle => 'Cronjob 편집';

  @override
  String get sysCronCommand => '명령';

  @override
  String get sysCronCommandHelper => '아래 계정 권한으로 셸에서 실행됩니다.';

  @override
  String get sysCronUser => '실행 계정';

  @override
  String get sysCronDescription => '설명';

  @override
  String get sysCronEnabled => '사용';

  @override
  String get sysCronCaptureStdout => '표준 출력 보관';

  @override
  String get sysCronCaptureStderr => '오류 출력 보관';

  @override
  String get sysCronDisabled => '사용 안 함';

  @override
  String get sysCronRunNow => '지금 실행';

  @override
  String get sysCronRunTitle => '이 명령을 지금 실행할까요?';

  @override
  String get sysCronRunAction => '명령 실행';

  @override
  String sysCronRunConsequence(String server, String user) {
    return '$server에서 $user 계정 권한으로 즉시 실행됩니다.';
  }

  @override
  String get sysCronRunRequested => '명령을 실행하는 중입니다.';

  @override
  String get sysCronDeleteTitle => '이 Cronjob을 삭제할까요?';

  @override
  String get sysCronDeleteAction => '명령 삭제';

  @override
  String get sysCronDeleteConsequence => '일정이 제거됩니다. 이미 실행된 작업에는 영향이 없습니다.';

  @override
  String get sysCronCreated => 'Cronjob을 추가했습니다.';

  @override
  String get sysCronUpdated => 'Cronjob을 수정했습니다.';

  @override
  String get sysCronDeleted => 'Cronjob을 삭제했습니다.';

  @override
  String get sysCronValidationCommand => '실행할 명령을 입력하세요.';

  @override
  String get sysCronValidationUser => '실행할 계정을 선택하세요.';

  @override
  String get sysSectionUpdates => '업데이트';

  @override
  String get sysAuditTitle => '감사 로그';

  @override
  String get sysAuditSubtitle => '이 서버에서 누가 무엇을 했는지';

  @override
  String get sysAuditEmpty => '이 필터에 해당하는 감사 기록이 없습니다.';

  @override
  String get sysAuditFilterAll => '전체 이벤트';

  @override
  String get sysAuditFilterFailures => '실패만';

  @override
  String get sysAuditFilterUser => '사용자로 필터';

  @override
  String get sysAuditEventAuthentication => '로그인';

  @override
  String get sysAuditEventLogout => '로그아웃';

  @override
  String get sysAuditEventMethodCall => '작업';

  @override
  String get sysAuditDenied => '거부됨';

  @override
  String get sysAuditFailed => '실패';

  @override
  String sysAuditFrom(String address) {
    return '$address에서';
  }

  @override
  String sysAuditRetention(int days) {
    return '$days일간 보관';
  }

  @override
  String sysAuditSpace(String used, String available) {
    return '$available 중 $used 사용';
  }

  @override
  String get sysAuditQuotaUncapped => '할당량 없음';

  @override
  String get sysAuditRetentionEdit => '보관 기간 및 할당량';

  @override
  String get sysAuditRetentionDays => '보관 기간 (일)';

  @override
  String get sysAuditRetentionHelp => '이 기간이 지난 기록은 삭제됩니다. 1일에서 30일 사이.';

  @override
  String get sysAuditQuota => '할당량 (GiB)';

  @override
  String get sysAuditQuotaHelp => '감사 데이터베이스가 사용할 수 있는 최대 용량입니다. 0은 무제한입니다.';

  @override
  String get sysAuditWarnAt => '경고 기준 (%)';

  @override
  String get sysAuditCriticalAt => '위험 기준 (%)';

  @override
  String get sysAuditApplyTitle => '감사 보관 기간을 변경할까요?';

  @override
  String get sysAuditApplyAction => '보관 설정 저장';

  @override
  String get sysAuditApplyConsequence =>
      '보관 기간을 줄이면 서버가 이미 기록한 감사 이력이 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get sysAuditUpdated => '감사 보관 설정을 변경했습니다.';

  @override
  String get sysAuditNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String sysAuditValidationRetention(int minimum, int maximum) {
    return '보관 기간은 $minimum일에서 $maximum일 사이여야 합니다.';
  }

  @override
  String sysAuditValidationQuota(int minimum, int maximum) {
    return '값은 $minimum에서 $maximum 사이여야 합니다.';
  }

  @override
  String get sysAuditValidationFillOrder => '위험 기준은 경고 기준보다 커야 합니다.';

  @override
  String get sysConfigBackupTitle => '설정 백업';

  @override
  String get sysConfigBackupSubtitle => '설정 데이터베이스 다운로드 또는 기본값으로 초기화';

  @override
  String get sysConfigBackupPrepare => '백업 준비';

  @override
  String get sysConfigBackupSheetTitle => '설정 백업';

  @override
  String get sysConfigBackupExplain =>
      '이 아카이브에는 공유, 사용자, 작업, 네트워크 설정 등 설정 데이터베이스가 담깁니다. 풀 데이터는 포함되지 않습니다.';

  @override
  String get sysConfigBackupSecretSeed => '시크릿 시드 포함';

  @override
  String get sysConfigBackupSecretSeedHelp =>
      '복원 후 저장된 비밀번호와 API 키를 복호화하는 데 필요합니다. 이 아카이브를 가진 사람은 그 값을 읽을 수 있습니다.';

  @override
  String get sysConfigBackupPoolKeys => '풀 암호화 키 포함';

  @override
  String get sysConfigBackupPoolKeysHelp =>
      '암호화된 데이터셋을 해제합니다. 이 키가 포함된 아카이브는 데이터 자체와 같습니다.';

  @override
  String get sysConfigBackupRootKeys => 'root SSH 키 포함';

  @override
  String get sysConfigBackupSecretsWarning =>
      '이 아카이브에는 비밀 정보가 포함됩니다. 서버 비밀번호와 같은 수준으로 보관하세요.';

  @override
  String get sysConfigBackupReady => '백업 준비 완료';

  @override
  String sysConfigBackupReadyBody(String filename) {
    return '브라우저에서 이 일회용 링크를 열어 $filename을(를) 다운로드하세요. 링크는 곧 만료되며 이 다운로드에만 사용됩니다.';
  }

  @override
  String get sysConfigBackupCopyLink => '다운로드 링크 복사';

  @override
  String get sysConfigBackupDownload => '다운로드';

  @override
  String get sysConfigBackupOpenFailed => '브라우저에서 다운로드를 열지 못했습니다.';

  @override
  String get sysConfigBackupLinkCopied => '다운로드 링크를 복사했습니다.';

  @override
  String get sysConfigResetTitle => '설정 초기화';

  @override
  String get sysConfigResetSubtitle => '모든 설정을 공장 기본값으로 되돌리기';

  @override
  String get sysConfigResetAction => '설정 초기화';

  @override
  String get sysConfigResetConsequenceTotal =>
      '모든 공유, 사용자, 작업, 네트워크 설정이 기본값으로 돌아갑니다. 풀 데이터는 그대로지만 다시 설정하기 전까지 아무것도 공유되거나 예약되지 않습니다.';

  @override
  String get sysConfigResetConsequenceIrreversible =>
      '되돌릴 수 없습니다. 아직 받지 않았다면 먼저 설정 백업을 다운로드하세요.';

  @override
  String get sysConfigResetConsequenceReboot =>
      '서버가 즉시 재시작되고 TrueDock의 연결이 끊어집니다.';

  @override
  String get sysConfigResetConsequenceNoReboot =>
      '초기화는 지금 적용됩니다. 완료하려면 직접 서버를 재시작하세요.';

  @override
  String get sysConfigResetReboot => '초기화 후 재시작';

  @override
  String get sysConfigResetRequested => '설정 초기화를 요청했습니다.';

  @override
  String get sysSectionActivity => '알림 및 작업';

  @override
  String get sysConnectPrompt => '이 섹션을 보려면 서버에 연결하세요.';

  @override
  String sysHeadingWithCount(String title, int count) {
    return '$title  $count';
  }

  @override
  String get sysMetricUsers => '사용자';

  @override
  String get sysMetricGroups => '그룹';

  @override
  String get sysMetricAdmins => '관리자';

  @override
  String get sysUsers => '사용자';

  @override
  String get sysNewUser => '새 사용자';

  @override
  String get sysNoUsers => '사용자가 없습니다.';

  @override
  String get sysGroups => '그룹';

  @override
  String get sysNewGroup => '새 그룹';

  @override
  String get sysNoGroups => '그룹이 없습니다.';

  @override
  String get sysApiKeys => 'API 키';

  @override
  String sysRevokeApiKeyTitle(String name) {
    return '$name을(를) 취소할까요?';
  }

  @override
  String get sysRevokeApiKeyAction => 'API 키 취소';

  @override
  String get sysRevokeApiKeyConsequence =>
      '이 키를 사용 중인 모든 클라이언트가 즉시 로그인할 수 없게 됩니다. TrueDock이 이 키를 사용 중이라면 TrueDock도 포함됩니다.';

  @override
  String get sysRevokeApiKeyUnowned =>
      '키는 복구할 수 없습니다. 서버에서 새로 만들어야 하며, 새 비밀 값은 한 번만 표시됩니다.';

  @override
  String sysRevokeApiKeyOwned(String owner) {
    return '$owner 계정의 비밀번호와 다른 키는 유지됩니다. 이 키는 복구할 수 없으며, 새로 만든 키의 비밀 값은 한 번만 표시됩니다.';
  }

  @override
  String sysRevokeApiKeyActionLabel(String name) {
    return '$name 취소';
  }

  @override
  String sysRevokedApiKey(String name) {
    return '$name을(를) 취소했습니다.';
  }

  @override
  String sysUpdateActionLabel(String name) {
    return '$name 수정';
  }

  @override
  String sysUpdatedEntity(String name) {
    return '$name을(를) 수정했습니다.';
  }

  @override
  String sysCreateActionLabel(String name) {
    return '$name 생성';
  }

  @override
  String sysCreatedEntity(String name) {
    return '$name을(를) 만들었습니다.';
  }

  @override
  String sysDeleteActionLabel(String name) {
    return '$name 삭제';
  }

  @override
  String sysDeletedEntity(String name) {
    return '$name을(를) 삭제했습니다.';
  }

  @override
  String sysOperationFailed(String action) {
    return 'TrueNAS가 $action을(를) 수행하지 못했습니다.';
  }

  @override
  String get sysGenericOperationFailed => 'TrueNAS 작업이 실패했습니다.';

  @override
  String sysChangePasswordTitle(String username) {
    return '$username의 비밀번호를 변경할까요?';
  }

  @override
  String get sysChangePasswordAction => '비밀번호 변경';

  @override
  String get sysChangePasswordImmediate =>
      '새 비밀번호는 즉시 적용됩니다. 이 계정으로 로그인한 사용자는 이후 새 비밀번호를 사용해야 합니다.';

  @override
  String get sysChangePasswordSessions =>
      '이 계정의 활성 세션이 TrueNAS에 의해 종료될 수 있습니다.';

  @override
  String get sysChangePasswordPrivacy =>
      '비밀번호는 연결된 서버로만 전송되며, TrueDock은 이를 저장하거나 기록하거나 자동 입력하지 않습니다.';

  @override
  String sysChangePasswordActionLabel(String username) {
    return '$username의 비밀번호 변경';
  }

  @override
  String sysPasswordChanged(String username) {
    return '$username의 비밀번호를 변경했습니다.';
  }

  @override
  String get sysDeleteUserTitle => '사용자를 삭제할까요?';

  @override
  String get sysDeleteUserAction => '사용자 삭제';

  @override
  String get sysDeleteUserConsequenceAccount => '계정이 제거되어 어디에서도 로그인할 수 없게 됩니다.';

  @override
  String sysDeleteUserConsequenceGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '그룹 $count개에서 이 사용자가 제거됩니다.',
    );
    return '$_temp0';
  }

  @override
  String sysDeleteUserConsequencePrimaryGroup(String group) {
    return '다른 구성원이 없으므로 기본 그룹 $group도 함께 삭제됩니다.';
  }

  @override
  String get sysDeleteUserConsequenceFiles =>
      '이 사용자가 소유한 파일은 숫자 UID를 그대로 유지하므로 접근하지 못하게 될 수 있습니다.';

  @override
  String get sysDeleteUserNote => '홈 디렉터리의 내용은 이 작업으로 제거되지 않습니다.';

  @override
  String get sysDeleteGroupTitle => '그룹을 삭제할까요?';

  @override
  String get sysDeleteGroupAction => '그룹 삭제';

  @override
  String sysDeleteGroupConsequenceMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '그룹이 제거되어 구성원 $count명이 이 그룹으로 얻던 접근 권한을 잃습니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysDeleteGroupConsequencePermissions =>
      '이 그룹을 참조하는 공유 및 데이터셋 권한이 더 이상 어떤 대상과도 일치하지 않게 됩니다.';

  @override
  String sysDeleteGroupConsequencePrimary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용자 $count명의 기본 그룹이므로 TrueNAS가 삭제를 거부할 수 있습니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysDeleteGroupNote => '구성원 계정 자체는 삭제되지 않습니다.';

  @override
  String sysInstallUpdateTitle(String version) {
    return '$version을(를) 설치할까요?';
  }

  @override
  String get sysInstallUpdateAction => '설치 후 재시작';

  @override
  String get sysInstallUpdateConsequenceRestart =>
      '서버가 업데이트를 내려받은 뒤 해당 버전으로 재시작합니다.';

  @override
  String sysInstallUpdateConsequenceServices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '재시작이 끝날 때까지 공유, VM, 실행 중인 앱 $count개를 사용할 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String sysInstallUpdateConsequenceJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '작업 $count개가 아직 실행 중이며 중단됩니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysInstallUpdateConsequenceConnection =>
      '서버가 재부팅되는 동안 TrueDock의 연결이 끊깁니다.';

  @override
  String get sysInstallUpdateNote => 'TrueNAS 업데이트를 되돌리려면 콘솔 접근이 필요합니다.';

  @override
  String sysInstallUpdateActionLabel(String version) {
    return '$version 설치';
  }

  @override
  String get sysUpdateStarted => '업데이트를 시작했습니다. 준비가 끝나면 서버가 재시작합니다.';

  @override
  String get sysRestartTitle => '서버를 재시작할까요?';

  @override
  String get sysRestartAction => '지금 재시작';

  @override
  String get sysRestartVerb => '재시작';

  @override
  String get sysRestartExtra => '부팅이 끝나면 서버가 스스로 다시 올라옵니다.';

  @override
  String get sysRestartSuccess => '재시작을 요청했습니다. TrueDock의 연결이 끊깁니다.';

  @override
  String get sysShutdownTitle => '서버를 종료할까요?';

  @override
  String get sysShutdownAction => '지금 종료';

  @override
  String get sysShutdownVerb => '종료';

  @override
  String get sysShutdownExtra =>
      '물리적으로 전원을 켜거나 대역 외 관리로 켜기 전까지 서버는 꺼진 상태로 유지됩니다.';

  @override
  String get sysShutdownSuccess => '종료를 요청했습니다. TrueDock의 연결이 끊깁니다.';

  @override
  String get sysPowerConsequenceClients =>
      '모든 SMB, NFS, iSCSI 클라이언트가 즉시 접근할 수 없게 됩니다.';

  @override
  String sysPowerConsequenceWorkloads(int apps, int vms) {
    return '실행 중인 앱 $apps개와 VM $vms개가 중지됩니다.';
  }

  @override
  String sysPowerConsequenceJobs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '작업 $count개가 아직 실행 중입니다. 복제와 스크럽은 다시 실행해야 합니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysPowerNote => '연결이 끊기므로 TrueDock은 결과를 확인할 수 없습니다.';

  @override
  String sysPowerActionLabel(String verb, String server) {
    return '$server $verb';
  }

  @override
  String get sysPowerReason => 'TrueDock에서 요청함';

  @override
  String sysBootIntoTitle(String environment) {
    return '$environment(으)로 부팅할까요?';
  }

  @override
  String get sysBootIntoAction => '다음 부팅에 사용';

  @override
  String sysBootIntoConsequenceRestart(String server, String environment) {
    return '$server이(가) 다음에 재시작할 때 $environment(으)로 시작합니다. 그전까지는 아무것도 바뀌지 않으며, TrueDock이 대신 재시작하지도 않습니다.';
  }

  @override
  String get sysBootIntoConsequenceUnknownCurrent =>
      '서버가 재시작하면 시스템 소프트웨어와 그에 적용된 업데이트가 바뀝니다.';

  @override
  String sysBootIntoConsequenceCurrent(String current) {
    return '서버는 현재 $current을(를) 실행 중입니다. 재시작 후에는 적용된 업데이트를 포함한 시스템 소프트웨어가 교체됩니다.';
  }

  @override
  String get sysBootEnvironmentDataNote =>
      '풀, 데이터셋, 공유 데이터는 부트 환경에 포함되지 않으며 그대로 유지됩니다.';

  @override
  String sysBootEnvironmentActivated(String environment) {
    return '다음 재시작 때 $environment이(가) 사용됩니다.';
  }

  @override
  String sysBootEnvironmentKept(String environment) {
    return '$environment이(가) 보존되며 자동으로 정리되지 않습니다.';
  }

  @override
  String sysBootEnvironmentUnkept(String environment) {
    return '이제 $environment이(가) 자동으로 제거될 수 있습니다.';
  }

  @override
  String sysDeleteBootEnvironmentTitle(String environment) {
    return '$environment을(를) 삭제할까요?';
  }

  @override
  String get sysDeleteBootEnvironmentAction => '환경 삭제';

  @override
  String sysDeleteBootEnvironmentConsequence(String environment) {
    return '$environment이(가) 영구적으로 삭제됩니다. 복구할 수 없으며 시스템을 되돌리는 데에도 더 이상 사용할 수 없습니다.';
  }

  @override
  String sysBootEnvironmentDeleted(String environment) {
    return '$environment을(를) 삭제했습니다.';
  }

  @override
  String get sysMetricInterfaces => '인터페이스';

  @override
  String get sysMetricLinkUp => '링크 연결됨';

  @override
  String get sysMetricRoutes => '경로';

  @override
  String get sysInterfaces => '인터페이스';

  @override
  String get sysNoInterfaces => '네트워크 인터페이스가 없습니다.';

  @override
  String get sysStaticRoutes => '정적 경로';

  @override
  String get sysNewRoute => '새 경로';

  @override
  String get sysNoStaticRoutes => '구성된 정적 경로가 없습니다.';

  @override
  String sysRouteVia(String gateway) {
    return '게이트웨이 $gateway';
  }

  @override
  String sysRouteViaWithDescription(String gateway, String description) {
    return '게이트웨이 $gateway · $description';
  }

  @override
  String get sysEdit => '편집';

  @override
  String get sysDelete => '삭제';

  @override
  String get sysNetGlobalTitle => 'DNS 및 게이트웨이';

  @override
  String get sysNetGlobalSubtitle => '호스트 이름, 도메인, 기본 게이트웨이, 네임서버';

  @override
  String get sysNetGlobalEdit => 'DNS 및 게이트웨이 편집';

  @override
  String get sysNetConfigured => '설정값';

  @override
  String get sysNetInEffect => '실제 적용값';

  @override
  String get sysNetFromDhcp => '이 값은 DHCP에서 받은 것입니다. 여기에 값을 입력하면 임대 값을 덮어씁니다.';

  @override
  String get sysNetNotSet => '설정되지 않음';

  @override
  String get sysNetHostname => '호스트 이름';

  @override
  String get sysNetDomain => '도메인';

  @override
  String get sysNetGateway => 'IPv4 기본 게이트웨이';

  @override
  String sysNetNameserver(int index) {
    return '네임서버 $index';
  }

  @override
  String get sysNetHttpProxy => 'HTTP 프록시';

  @override
  String get sysNetDefaultRoutes => '기본 경로';

  @override
  String get sysNetAddresses => '주소';

  @override
  String get sysNetClearHelp => '비워 두면 값이 지워지고 DHCP 값으로 돌아갑니다.';

  @override
  String get sysNetGlobalApplyTitle => 'DNS 및 게이트웨이를 변경할까요?';

  @override
  String get sysNetGlobalApplyAction => '네트워크 설정 적용';

  @override
  String get sysNetGlobalConsequenceImmediate =>
      '인터페이스 편집과 달리 커밋 및 체크인 과정 없이 즉시 적용됩니다.';

  @override
  String sysNetGlobalConsequenceSever(String server) {
    return '서버가 현재 사용 중인 게이트웨이 또는 네임서버를 지웁니다. TrueDock이 그 경로로 $server에 접속하고 있다면 연결이 끊어지고 복구에 로컬 접근이 필요할 수 있습니다.';
  }

  @override
  String get sysNetGlobalUpdated => '네트워크 설정을 변경했습니다.';

  @override
  String get sysNetGlobalNoChanges => '변경된 항목이 없어 아무것도 전송하지 않았습니다.';

  @override
  String get sysNetValidationHostnameRequired => '호스트 이름을 입력하세요.';

  @override
  String get sysNetValidationHostnameInvalid => '영문자, 숫자, 하이픈만 사용하세요.';

  @override
  String get sysNetValidationDomain => '올바른 도메인 이름을 입력하세요.';

  @override
  String get sysNetValidationGateway => '올바른 IPv4 주소를 입력하거나 비워서 지우세요.';

  @override
  String get sysNetValidationNameserver => '올바른 IP 주소를 입력하거나 비워서 지우세요.';

  @override
  String get sysNetValidationProxy => '올바른 프록시 URL을 입력하세요.';

  @override
  String get sysApplyNetworkChanges => '대기 중인 네트워크 변경 적용';

  @override
  String get sysApplyNetworkChangesHelp => '준비된 인터페이스 및 정적 경로 변경을 커밋하고 체크인합니다.';

  @override
  String sysStageRouteTitle(String destination) {
    return '$destination(으)로 가는 경로를 준비할까요?';
  }

  @override
  String get sysStageRouteAction => '경로 준비';

  @override
  String sysRouteConsequence(String destination, String gateway) {
    return '$destination(으)로 가는 트래픽을 $gateway을(를) 통해 라우팅합니다.';
  }

  @override
  String get sysRouteStagedConsequence =>
      '경로는 준비만 된 상태입니다. 대기 중인 네트워크 변경을 커밋하고 체크인해야 적용됩니다.';

  @override
  String get sysRouteStagedNote => '이후 TrueDock이 커밋과 체크인을 안내합니다.';

  @override
  String sysStageRouteActionLabel(String destination) {
    return '$destination(으)로 가는 경로 준비';
  }

  @override
  String sysRouteStagedSuccess(String destination) {
    return '$destination(으)로 가는 경로를 준비했습니다. 대기 중인 네트워크 변경을 적용하면 반영됩니다.';
  }

  @override
  String sysUpdateRouteTitle(String destination) {
    return '$destination(으)로 가는 경로를 수정할까요?';
  }

  @override
  String get sysStageUpdateAction => '수정 준비';

  @override
  String get sysRouteChangeStagedConsequence =>
      '변경은 준비만 된 상태입니다. 대기 중인 네트워크 변경을 커밋하고 체크인해야 적용됩니다.';

  @override
  String sysUpdateRouteActionLabel(String destination) {
    return '$destination(으)로 가는 경로 수정';
  }

  @override
  String sysRouteUpdateStagedSuccess(String destination) {
    return '$destination에 대한 수정을 준비했습니다. 대기 중인 네트워크 변경을 적용하면 반영됩니다.';
  }

  @override
  String sysDeleteRouteTitle(String destination) {
    return '$destination(으)로 가는 경로를 삭제할까요?';
  }

  @override
  String get sysStageDeletionAction => '삭제 준비';

  @override
  String sysRouteRemoveConsequence(String destination, String gateway) {
    return '$gateway을(를) 통해 $destination(으)로 가던 경로를 제거합니다.';
  }

  @override
  String get sysRouteDeletionStagedConsequence =>
      '삭제는 준비만 된 상태입니다. 대기 중인 네트워크 변경을 커밋하고 체크인하기 전까지 경로는 라우팅 테이블에 남아 있습니다.';

  @override
  String sysDeleteRouteActionLabel(String destination) {
    return '$destination(으)로 가는 경로 삭제 준비';
  }

  @override
  String sysRouteDeletionStagedSuccess(String destination) {
    return '$destination 삭제를 준비했습니다. 대기 중인 네트워크 변경을 적용하면 반영됩니다.';
  }

  @override
  String get sysInterfaceConfigLoadFailed => '인터페이스 구성을 불러오지 못했습니다.';

  @override
  String sysInterfaceNoChanges(String name) {
    return '$name에 준비할 변경 사항이 없습니다.';
  }

  @override
  String sysStageInterfaceTitle(String name) {
    return '$name의 변경 사항을 준비할까요?';
  }

  @override
  String get sysStageChangeAction => '변경 준비';

  @override
  String sysInterfaceDhcpConsequence(String name) {
    return '$name이(가) IPv4에 DHCP를 사용하도록 전환됩니다.';
  }

  @override
  String sysInterfaceStaticConsequence(
    String name,
    int count,
    String addresses,
  ) {
    return '$name이(가) 정적 주소 $count개를 사용합니다: $addresses';
  }

  @override
  String get sysInterfaceLosesStatic =>
      '기존 정적 주소가 제거됩니다. 이를 사용하던 대상은 경로를 잃습니다.';

  @override
  String get sysInterfaceStagedConsequence =>
      '변경은 준비만 된 상태입니다. 커밋하면 TrueDock 연결이 끊길 수 있으며, 체크인이 제때 도착하지 않으면 서버가 변경을 되돌립니다.';

  @override
  String get sysInterfaceStagedNote => '다음 단계에서 TrueDock이 커밋과 체크인을 안내합니다.';

  @override
  String sysStageInterfaceActionLabel(String name) {
    return '$name의 변경 준비';
  }

  @override
  String get sysUpdateFallbackName => 'TrueNAS SCALE';

  @override
  String sysUpdateAvailable(String version) {
    return '$version 사용 가능';
  }

  @override
  String get sysUpdateStatusHeading => '시스템 업데이트 상태';

  @override
  String get sysUpdateStatusUnavailable => '업데이트 상태를 확인할 수 없습니다.';

  @override
  String get sysPower => '전원';

  @override
  String get sysBootEnvironments => '부트 환경';

  @override
  String get sysUpdateTrain => '트레인';

  @override
  String get sysUpdateProfile => '프로필';

  @override
  String get sysUpdateAvailableVersion => '사용 가능한 버전';

  @override
  String get sysUnknown => '알 수 없음';

  @override
  String get sysUpToDate => '최신 상태';

  @override
  String get sysUpdateError => '오류';

  @override
  String get sysUpdateProfilesLoadFailed => '업데이트 채널을 불러오지 못했습니다.';

  @override
  String sysInstallVersion(String version) {
    return '$version 설치';
  }

  @override
  String get sysUpdatesNotPermitted => '이 계정은 업데이트를 수행할 수 없습니다';

  @override
  String get sysUpdateInProgress => '업데이트 진행 중';

  @override
  String get sysUpdatePreparing => '시스템 업데이트 준비 중…';

  @override
  String get sysManualUpdateTitle => '커스텀 펌웨어';

  @override
  String get sysManualUpdateDescription =>
      '공식 TrueNAS .tar 또는 .update 파일을 직접 올려 설치합니다.';

  @override
  String get sysManualUpdateChooseFile => '업데이트 파일 선택';

  @override
  String get sysManualUpdateConfirmTitle => '이 커스텀 펌웨어를 설치할까요?';

  @override
  String get sysManualUpdateUploadAction => '업로드 및 설치';

  @override
  String get sysManualUpdateConsequenceValidation =>
      '선택한 업데이트 파일을 TrueNAS에 업로드하고 검증한 뒤 설치합니다.';

  @override
  String get sysManualUpdateConsequenceRestart =>
      '업데이트 파일 설치가 완료되면 서버가 자동으로 재시작합니다.';

  @override
  String sysManualUpdateUploading(int percent) {
    return '업로드 중: $percent%';
  }

  @override
  String get sysManualUpdateProcessing => 'TrueNAS가 업데이트를 검증하고 설치하는 중…';

  @override
  String get sysManualUpdateRestartSoon => '업데이트를 설치할 준비가 되었습니다.';

  @override
  String get sysUpdateChannelTitle => '펌웨어 채널';

  @override
  String get sysUpdateChannelDescription =>
      '시스템 업데이트를 받을 TrueNAS 릴리스 채널을 선택합니다.';

  @override
  String get sysUpdateChannelGeneral => '일반';

  @override
  String get sysUpdateChannelEarlyAdopter => '얼리 어댑터';

  @override
  String get sysUpdateChannelDeveloper => '개발자 베타';

  @override
  String get sysManualUpdateFailed => '커스텀 펌웨어 업데이트에 실패했습니다.';

  @override
  String get sysManualUpdateNoPath => '이 기기에서 선택한 파일을 읽을 수 없습니다.';

  @override
  String get sysManualUpdateUnsupportedExtension =>
      '공식 TrueNAS .tar 또는 .update 파일을 선택하세요.';

  @override
  String sysUpdateProgress(int percent) {
    return '업데이트 진행률: $percent%';
  }

  @override
  String get sysPowerNotPermitted => '이 계정은 서버를 재시작하거나 종료할 수 없습니다.';

  @override
  String get sysPowerWarning => '재시작하거나 종료하면 이 서버의 모든 공유, 앱, 실행 중인 작업이 중단됩니다.';

  @override
  String get sysRestartServer => '서버 재시작';

  @override
  String get sysShutdownServer => '서버 종료';

  @override
  String get sysMetricAlerts => '알림';

  @override
  String get sysMetricActiveJobs => '실행 중 작업';

  @override
  String get sysMetricFailures => '실패';

  @override
  String get sysAlerts => '알림';

  @override
  String get sysJobs => '작업';

  @override
  String get sysNoAlerts => '알림이 없습니다.';

  @override
  String get sysAlertFailed => '알림 작업이 실패했습니다.';

  @override
  String get sysAlertDismissed => '알림을 무시했습니다.';

  @override
  String get sysAlertRestored => '알림을 복원했습니다.';

  @override
  String sysAlertSubtitleDismissed(String level) {
    return '$level · 무시함';
  }

  @override
  String get sysRestoreAlert => '알림 복원';

  @override
  String get sysDismissAlert => '알림 무시';

  @override
  String get sysUserLocal => '로컬';

  @override
  String get sysUserDirectory => '디렉터리';

  @override
  String get sysUserSmb => 'SMB';

  @override
  String get sysUserPasswordDisabled => '비밀번호 사용 안 함';

  @override
  String get sysUserLocked => '잠김';

  @override
  String get sysBuiltInAccount => '기본 제공 계정';

  @override
  String get sysDirectoryAccount => '디렉터리 계정';

  @override
  String get sysEditUser => '사용자 편집';

  @override
  String get sysDeleteUser => '사용자 삭제';

  @override
  String sysGroupSubtitle(String gid, int count) {
    return 'GID $gid · 사용자 $count명';
  }

  @override
  String sysGroupSubtitleWithRoles(String gid, int count, String roles) {
    return 'GID $gid · 사용자 $count명 · $roles';
  }

  @override
  String get sysBuiltInGroup => '기본 제공 그룹';

  @override
  String get sysDirectoryGroup => '디렉터리 그룹';

  @override
  String get sysEditGroup => '그룹 편집';

  @override
  String get sysDeleteGroup => '그룹 삭제';

  @override
  String get sysInterfaceLinkUp => '링크 연결됨';

  @override
  String sysInterfaceMtu(String mtu) {
    return 'MTU $mtu';
  }

  @override
  String get sysInterfaceDhcp => 'DHCP';

  @override
  String get sysUserEditReviewTitle => '사용자 변경 사항 검토';

  @override
  String get sysUserEditTitle => '사용자 편집';

  @override
  String get sysUserApplyChanges => '변경 사항 적용';

  @override
  String get sysUserFullNameLabel => '전체 이름';

  @override
  String get sysUserEmailLabel => '이메일';

  @override
  String get sysUserEmailHelper => '비우면 주소를 지웁니다';

  @override
  String get sysUserShellLabel => '로그인 셸';

  @override
  String get sysUserSmbAccessTitle => 'SMB 접근';

  @override
  String get sysUserSmbAccessSubtitle => '이 계정이 SMB에 인증하도록 허용합니다.';

  @override
  String get sysUserDisablePasswordTitle => '비밀번호 로그인 비활성화';

  @override
  String get sysUserDisablePasswordSubtitle => '키 기반 접근은 계속 작동합니다.';

  @override
  String get sysUserLockTitle => '계정 잠금';

  @override
  String get sysUserLockSubtitle => '이 사용자의 모든 로그인을 차단합니다.';

  @override
  String get sysUserPrimaryGroupTitle => '기본 그룹';

  @override
  String get sysUserPrimaryGroupManaged => 'TrueNAS가 관리';

  @override
  String sysUserPrimaryGroupNamed(String name) {
    return '$name — TrueNAS 웹 UI에서 변경하세요';
  }

  @override
  String get sysUserAuxGroupsTitle => '보조 그룹';

  @override
  String get sysUserAuxGroupsNone => '선택할 수 있는 다른 그룹이 없습니다.';

  @override
  String sysUserLockWarning(String username) {
    return '$username을(를) 잠그면 이 계정이 TrueNAS에 접근하는 데 사용하는 모든 세션을 포함해 로그인이 즉시 차단됩니다.';
  }

  @override
  String get sysUserShowPassword => '표시';

  @override
  String get sysUserHidePassword => '숨기기';

  @override
  String get sysUserCreateTitle => '새 사용자';

  @override
  String get sysUserCreateUsernameLabel => '사용자 이름';

  @override
  String get sysUserCreateFullNameHelper => '기본값은 사용자 이름';

  @override
  String get sysUserCreateDisablePasswordSubtitle => '비밀번호 없이 계정을 만듭니다.';

  @override
  String get sysUserCreateSmbAccessTitle => 'SMB 접근';

  @override
  String get sysUserCreateMatchingGroupTitle => '일치하는 기본 그룹 만들기';

  @override
  String get sysUserCreateMatchingGroupSubtitle => '일반 계정에 권장됩니다.';

  @override
  String get sysUserCreatePrimaryGroupLabel => '기본 그룹';

  @override
  String get sysUserCreateAction => '사용자 만들기';

  @override
  String get sysGroupEditReviewTitle => '그룹 변경 사항 검토';

  @override
  String get sysGroupEditTitle => '그룹 편집';

  @override
  String sysGroupEditSubtitle(String gid) {
    return 'GID $gid';
  }

  @override
  String get sysGroupNameLabel => '그룹 이름';

  @override
  String get sysGroupExposeSmbTitle => 'SMB에 노출';

  @override
  String get sysGroupMembersTitle => '구성원';

  @override
  String get sysGroupMembersNone => '사용할 수 있는 사용자가 없습니다.';

  @override
  String get sysGroupRenameWarning =>
      '이전 그룹 이름을 참조하는 권한과 공유는 계속 해당 이름을 가리키며 별도로 업데이트해야 합니다.';

  @override
  String get sysGroupCreateTitle => '새 그룹';

  @override
  String get sysGroupCreateAction => '그룹 만들기';

  @override
  String get sysUserValidationUserNotEditable =>
      '기본 제공 및 디렉터리 계정은 TrueDock에서 편집할 수 없습니다.';

  @override
  String get sysUserValidationEmailInvalid => '올바른 이메일 주소를 입력하거나 비워 두세요.';

  @override
  String get sysUserValidationUserUnchanged => '이 사용자의 변경 사항이 없습니다.';

  @override
  String get sysUserValidationGroupNotEditable =>
      '기본 제공 및 디렉터리 그룹은 TrueDock에서 편집할 수 없습니다.';

  @override
  String get sysUserValidationGroupNameRequired => '그룹 이름을 입력하세요.';

  @override
  String get sysUserValidationGroupNameInvalid =>
      '그룹 이름에는 공백, 콜론, 쉼표를 사용할 수 없습니다.';

  @override
  String get sysUserValidationGroupUnchanged => '이 그룹의 변경 사항이 없습니다.';

  @override
  String get sysUserValidationUsernameRequired => '사용자 이름을 입력하세요.';

  @override
  String get sysUserValidationUsernameInvalid =>
      '사용자 이름은 문자 또는 밑줄로 시작하고 소문자, 숫자, 하이픈, 밑줄만 사용할 수 있습니다.';

  @override
  String get sysUserValidationPasswordRequired =>
      '비밀번호를 설정하거나 비밀번호 로그인을 비활성화하세요.';

  @override
  String get sysUserValidationPrimaryGroupRequired =>
      '기본 그룹을 선택하거나 TrueNAS가 만들도록 두세요.';

  @override
  String get sysUserChangeFullNameCleared => '전체 이름을 지웠습니다';

  @override
  String sysUserChangeFullNameSet(String value) {
    return '전체 이름을 \"$value\"(으)로 설정';
  }

  @override
  String get sysUserChangeEmailCleared => '이메일 주소를 지웠습니다';

  @override
  String sysUserChangeEmailSet(String value) {
    return '이메일을 $value(으)로 설정';
  }

  @override
  String sysUserChangeShellSet(String value) {
    return '로그인 셸을 $value(으)로 설정';
  }

  @override
  String get sysUserChangeSmbEnabled => 'SMB 접근 활성화됨';

  @override
  String get sysUserChangeSmbDisabled => 'SMB 접근 비활성화됨';

  @override
  String get sysUserChangeAccountLocked => '계정 잠김 — 이 사용자는 더 이상 로그인할 수 없습니다';

  @override
  String get sysUserChangeAccountUnlocked => '계정 잠금 해제됨';

  @override
  String get sysUserChangePasswordDisabled => '비밀번호 로그인 비활성화됨';

  @override
  String get sysUserChangePasswordEnabled => '비밀번호 로그인 활성화됨';

  @override
  String sysUserChangeAuxGroupsSet(int count) {
    return '보조 그룹을 그룹 $count개로 설정';
  }

  @override
  String sysUserChangeGroupRenamed(String value) {
    return '그룹 이름을 $value(으)로 변경';
  }

  @override
  String get sysUserChangeGroupExposedSmb => '그룹이 SMB에 노출됨';

  @override
  String get sysUserChangeGroupHiddenSmb => '그룹이 SMB에서 숨겨짐';

  @override
  String sysUserChangeMembershipSet(int count) {
    return '구성원을 사용자 $count명으로 설정';
  }

  @override
  String sysUserChangeOtherField(String value) {
    return '$value 수정됨';
  }

  @override
  String get sysUserPasswordReviewTitle => '새 비밀번호 검토';

  @override
  String sysUserPasswordSetTitle(String username) {
    return '$username의 비밀번호 설정';
  }

  @override
  String get sysUserPasswordLocalAccount => '로컬 계정';

  @override
  String get sysUserPasswordDirectoryAccount => '디렉터리 계정';

  @override
  String get sysUserPasswordNewLabel => '새 비밀번호';

  @override
  String get sysUserPasswordConfirmLabel => '새 비밀번호 확인';

  @override
  String get sysUserPasswordNotice =>
      '새 비밀번호는 연결된 TrueNAS 서버에만 전송됩니다. TrueDock은 이를 저장하거나 기록하거나 자동 채우지 않습니다.';

  @override
  String get sysUserPasswordReviewAction => '비밀번호 설정';

  @override
  String get sysUserPasswordReviewServerAction => '서버 동작';

  @override
  String get sysUserPasswordReviewServerActionValue => '비밀번호 변경';

  @override
  String get sysUserPasswordReviewAccount => '계정';

  @override
  String get sysUserPasswordReviewSetLabel => '비밀번호 설정됨';

  @override
  String sysUserPasswordReviewSetValue(int count) {
    return '예 · 글자 $count개';
  }

  @override
  String sysUserPasswordReviewSessionWarning(String username) {
    return '$username(으)로 로그인한 모든 사용자는 이후 새 비밀번호를 사용해야 합니다. 이 계정의 활성 세션은 TrueNAS에 의해 종료될 수 있습니다.';
  }

  @override
  String get sysUserPasswordErrorEmpty => '새 비밀번호를 입력하세요.';

  @override
  String get sysUserPasswordErrorShort => '최소 8자를 사용하세요.';

  @override
  String get sysUserPasswordErrorMismatch => '두 비밀번호가 일치하지 않습니다.';

  @override
  String get sysApiKeyNone => '이 서버에 등록된 API 키가 없습니다.';

  @override
  String get sysSessions => '활성 세션';

  @override
  String get sysSessionNone => '이 서버에 연결된 사용자 세션이 없습니다.';

  @override
  String get sysSessionThisDevice => '이 기기';

  @override
  String get sysSessionPasswordLogin => '비밀번호 로그인';

  @override
  String get sysSessionApiKeyLogin => 'API 키';

  @override
  String get sysSessionTokenLogin => '토큰';

  @override
  String get sysSessionInsecure => '암호화되지 않음';

  @override
  String get sysSessionJustNow => '방금 시작됨';

  @override
  String sysSessionMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 전에 시작됨',
    );
    return '$_temp0';
  }

  @override
  String sysSessionHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간 전에 시작됨',
    );
    return '$_temp0';
  }

  @override
  String sysSessionDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 전에 시작됨',
    );
    return '$_temp0';
  }

  @override
  String sysSessionInternalNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '내부 미들웨어 연결 $count개는 표시하지 않았습니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysSessionTerminateTooltip => '세션 종료';

  @override
  String get sysSessionTerminateTitle => '이 세션을 종료할까요?';

  @override
  String get sysSessionTerminateAction => '세션 종료';

  @override
  String sysSessionTerminateConsequence(String origin) {
    return '$origin의 클라이언트가 즉시 로그아웃되며 진행 중인 요청은 실패합니다.';
  }

  @override
  String get sysSessionTerminateReconnect =>
      '자격 증명을 가진 사람은 다시 로그인할 수 있습니다. 이를 막으려면 API 키를 폐기하거나 비밀번호를 변경하세요.';

  @override
  String get sysSessionTerminateOthers => '다른 세션 모두 종료';

  @override
  String get sysSessionTerminateOthersTitle => '다른 세션을 모두 종료할까요?';

  @override
  String sysSessionTerminateOthersConsequence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '다른 세션 $count개가 즉시 로그아웃됩니다.',
    );
    return '$_temp0';
  }

  @override
  String get sysSessionTerminateOthersKeepsThis => '이 기기는 로그인 상태로 유지됩니다.';

  @override
  String get sysSessionTerminated => '세션을 종료했습니다.';

  @override
  String get sysSessionTerminateFailed => '세션을 종료하지 못했습니다.';

  @override
  String get sysApiKeyRevoked => '취소됨';

  @override
  String get sysApiKeyExpired => '만료됨';

  @override
  String sysApiKeyExpiresDate(String date) {
    return '만료 $date';
  }

  @override
  String get sysApiKeyNoExpiry => '만료 없음';

  @override
  String sysApiKeyCreatedDate(String date) {
    return '생성 $date';
  }

  @override
  String get sysApiKeyRevokeTooltip => 'API 키 취소';

  @override
  String get sysBootNone => '보고된 부트 환경이 없습니다.';

  @override
  String sysBootPendingNotice(String id) {
    return '이 서버는 다음 재시작 시 $id(으)로 부팅됩니다.';
  }

  @override
  String get sysBootStatusRunning => '현재 실행 중';

  @override
  String get sysBootStatusNext => '다음 부트';

  @override
  String get sysBootStatusReplaced => '다음 부트에서 교체됨';

  @override
  String get sysBootStatusKept => '유지됨';

  @override
  String get sysBootActivateAction => '다음 부트에 사용';

  @override
  String get sysBootOptionsTooltip => '부트 환경 옵션';

  @override
  String get sysBootAllowRemoval => '자동 제거 허용';

  @override
  String get sysBootKeep => '이 환경 유지';

  @override
  String get sysBootDelete => '환경 삭제';

  @override
  String get sysGeneralReviewTitle => '변경 사항 검토';

  @override
  String get sysGeneralFormTitle => '일반 설정';

  @override
  String get sysGeneralHostnameLabel => '호스트 이름';

  @override
  String get sysGeneralDescriptionLabel => '설명';

  @override
  String get sysGeneralDescriptionHelper => '서버 목록과 개요에 표시됩니다.';

  @override
  String get sysGeneralTimezoneTitle => '시간대';

  @override
  String get sysGeneralTimezoneLabel => '시간대';

  @override
  String get sysGeneralTimezoneHelper => '선택 항목을 불러올 수 없습니다. IANA 시간대를 입력하세요.';

  @override
  String get sysGeneralSyslogTitle => '시스로그';

  @override
  String get sysGeneralSyslogLabel => '시스로그 레벨';

  @override
  String get sysGeneralReviewHostname => '호스트 이름';

  @override
  String get sysGeneralReviewDescription => '설명';

  @override
  String get sysGeneralReviewTimezone => '시간대';

  @override
  String get sysGeneralReviewSyslog => '시스로그';

  @override
  String get sysGeneralReviewNone => '없음';

  @override
  String get sysGeneralNoFieldsChanged => '변경된 필드가 없습니다. 서버는 설정을 유지합니다.';

  @override
  String get sysGeneralHostnameNotice =>
      '호스트 이름 변경은 서버가 네트워크 설정을 다시 불러온 후 적용됩니다. 활성 세션에는 영향이 없습니다.';

  @override
  String get sysGeneralChangedFields => '변경된 필드';

  @override
  String get sysGeneralValidationHostnameRequired => '호스트 이름을 입력하세요.';

  @override
  String get sysGeneralValidationTimezoneRequired => '시간대를 입력하세요.';

  @override
  String get sysSyslogDefault => '기본 (로컬)';

  @override
  String get sysSyslogDebug => '디버그';

  @override
  String get sysSyslogInfo => '정보';

  @override
  String get sysSyslogNotice => '알림';

  @override
  String get sysSyslogWarning => '경고';

  @override
  String get sysSyslogError => '오류';

  @override
  String get sysSyslogCritical => '심각';

  @override
  String get sysSyslogAlert => '경계';

  @override
  String get sysSyslogEmergency => '긴급';

  @override
  String get sysRouteReviewTitle => '라우트 검토';

  @override
  String get sysRouteNewTitle => '새 정적 라우트';

  @override
  String get sysRouteEditTitle => '라우트 편집';

  @override
  String get sysRouteSaveAction => '라우트 저장';

  @override
  String get sysRouteDestinationLabel => '대상 네트워크';

  @override
  String get sysRouteGatewayLabel => '게이트웨이';

  @override
  String get sysRouteGatewayHelper => '다음 홉 IP 주소 (예: 10.0.0.1)';

  @override
  String get sysRouteDescriptionLabel => '설명';

  @override
  String get sysRouteDescriptionHelper => '라우트 목록에 표시되는 선택적 메모입니다.';

  @override
  String get sysRouteStagedNotice =>
      '라우트는 대기 중인 네트워크 변경 사항이 커밋된 후에만 적용됩니다. 라우트가 저장되면 TrueDock이 커밋과 체크인을 안내합니다.';

  @override
  String get sysRouteReviewDestination => '대상';

  @override
  String get sysRouteReviewGateway => '게이트웨이';

  @override
  String get sysRouteReviewDescription => '설명';

  @override
  String get sysRouteReviewNone => '없음';

  @override
  String get sysRouteCommitNotice =>
      '대기 중인 네트워크 변경 사항을 커밋하면 네트워크 연결이 잠시 중단됩니다. 커밋 후 TrueDock이 연결을 잃으면 서버가 라우트를 자동으로 롤백합니다.';

  @override
  String get sysRouteValidationDestinationRequired => '대상 네트워크를 입력하세요.';

  @override
  String get sysRouteValidationDestinationInvalid =>
      '대상을 A.B.C.D/E 형식으로 입력하세요.';

  @override
  String get sysRouteValidationGatewayRequired => '게이트웨이 주소를 입력하세요.';

  @override
  String get sysRouteValidationGatewayInvalid => '올바른 게이트웨이 IP 주소를 입력하세요.';

  @override
  String get sysNetCommitApplyAction => '네트워크 변경 사항 적용';

  @override
  String get sysNetCommitCommittingTitle => '변경 사항 커밋 중…';

  @override
  String get sysNetCommitCommittingBody =>
      '서버가 대기 중인 네트워크 설정을 적용하고 있습니다. TrueDock 연결이 잠시 끊길 수 있습니다.';

  @override
  String get sysNetCommitCheckingInTitle => '체크인 중…';

  @override
  String get sysNetCommitCheckingInBody => '대기 중인 변경 사항을 잠가 서버가 유지하도록 합니다.';

  @override
  String get sysNetCommitAppliedTitle => '변경 사항 적용됨';

  @override
  String sysNetCommitAppliedBody(String server) {
    return '네트워크 설정이 $server에 커밋되고 체크인되었습니다.';
  }

  @override
  String get sysNetCommitRolledBackTitle => '변경 사항 롤백됨';

  @override
  String sysNetCommitRolledBackBody(String server) {
    return '대기 중인 네트워크 변경 사항이 되돌려졌습니다. $server의 실제 설정은 변경되지 않았습니다.';
  }

  @override
  String get sysNetCommitFailedTitle => '네트워크 커밋 실패';

  @override
  String get sysNetCommitFailedBody => '서버가 커밋을 거부했습니다. 실제 설정은 변경되지 않았습니다.';

  @override
  String sysNetCommitWarning(String server) {
    return '대기 중인 네트워크 변경 사항을 커밋하면 $server의 연결이 잠시 중단됩니다. 새 설정이 TrueDock이 사용하는 라우트를 손상시키면 서버는 확인 기간이 끝나면 모두 자동으로 롤백합니다.';
  }

  @override
  String get sysNetCommitAfterNote =>
      '커밋이 성공하면 TrueDock은 자신의 연결이 유지되는지 확인하고 변경 사항을 체크인하라고 요청합니다. 서버가 되돌리기를 원할 때만 체크인을 건너뛰세요.';

  @override
  String get sysNetCommitPendingChecking => '대기 중인 네트워크 변경 사항을 확인하는 중…';

  @override
  String get sysNetCommitPendingNone =>
      '서버에 대기 중인 네트워크 변경 사항이 없습니다. 지금 커밋해도 아무 일도 일어나지 않습니다.';

  @override
  String get sysNetCommitPendingStaged => '서버에 커밋을 기다리는 네트워크 변경 사항이 있습니다.';

  @override
  String sysNetCommitPendingAwaitingCheckIn(int seconds) {
    return '커밋이 이미 진행 중입니다. 서버가 되돌리기 전에 체크인할 시간이 $seconds초 남았습니다.';
  }

  @override
  String sysNetCommitPendingClears(String fields) {
    return '체크인하면 다음 네트워크 설정이 지워집니다: $fields. 그중 하나가 TrueDock이 사용하는 경로라면 이 연결이 끊어집니다.';
  }

  @override
  String get sysNetCommitVerifyTitle => '연결 확인';

  @override
  String sysNetCommitVerifyBody(String server) {
    return '커밋이 완료되었습니다. TrueDock이 여전히 $server에 접근할 수 있는지 확인 중입니다. 이 단계가 멈추면 새 설정이 라우트를 손상시켰을 수 있습니다. 서버가 곧 롤백합니다.';
  }

  @override
  String get sysNetCommitAddressChangedQuestion => '네트워크 주소를 변경하였나요?';

  @override
  String get sysNetCommitAddressChangedHelp =>
      '서버 주소가 바뀌었다면 새 주소를 입력하고 인증 연결을 테스트한 뒤 체크인하세요.';

  @override
  String get sysNetCommitNewAddress => '새 서버 주소';

  @override
  String get sysNetCommitTestAddress => '새 주소 테스트';

  @override
  String get sysNetCommitTestingAddress => '새 주소 테스트 중…';

  @override
  String get sysNetCommitAddressTestPassed =>
      '새 주소 연결과 인증에 성공했습니다. 안전하게 체크인할 수 있습니다.';

  @override
  String get sysNetCommitAddressRequired => '새 서버 주소를 입력하세요.';

  @override
  String get sysNetCommitAddressSaveFailed =>
      '네트워크 변경 사항은 체크인되었지만 TrueDock이 새 서버 주소를 저장하지 못했습니다.';

  @override
  String get sysNetCommitTestUnavailable => '연결 테스트를 사용할 수 없습니다.';

  @override
  String get sysNetCommitNotNow => '나중에';

  @override
  String get sysNetCommitCommitAction => '변경 사항 커밋';

  @override
  String get sysNetCommitRollbackAction => '롤백';

  @override
  String get sysNetCommitCheckInAction => '체크인';

  @override
  String get sysNetCommitDone => '완료';

  @override
  String sysInterfaceReviewName(String name) {
    return '$name 검토';
  }

  @override
  String sysInterfaceEditName(String name) {
    return '$name 편집';
  }

  @override
  String get sysInterfaceStageChange => '변경 사항 스테이징';

  @override
  String get sysInterfaceStagedNotice =>
      '인터페이스 변경 사항은 스테이징됩니다. 대기 중인 네트워크 변경 사항을 커밋하고 체크인한 후에만 적용되며, 연결이 유지되지 않으면 서버가 되돌립니다.';

  @override
  String get sysInterfaceDescriptionLabel => '설명';

  @override
  String get sysInterfaceAddressingTitle => '주소 할당';

  @override
  String get sysInterfaceUseDhcpTitle => 'IPv4에 DHCP 사용';

  @override
  String get sysInterfaceUseDhcpSubtitle => 'DHCP가 켜져 있는 동안 정적 주소는 무시됩니다.';

  @override
  String sysInterfaceDhcpConflict(String owner) {
    return '$owner이(가) 이미 DHCP를 사용합니다. TrueNAS는 하나의 인터페이스에서만 DHCP를 허용하므로, 먼저 해당 인터페이스에서 DHCP를 끄지 않으면 이 변경이 거부됩니다.';
  }

  @override
  String get sysInterfaceStaticTitle => '정적 주소';

  @override
  String get sysInterfaceNoStatic => '구성된 정적 주소가 없습니다.';

  @override
  String get sysInterfaceAddAddress => '주소 추가';

  @override
  String get sysInterfaceMtuLabel => 'MTU (선택)';

  @override
  String get sysInterfaceMtuHelper => '기본값(1500)을 사용하려면 비워 두세요.';

  @override
  String get sysInterfaceReviewInterface => '인터페이스';

  @override
  String get sysInterfaceReviewDescription => '설명';

  @override
  String get sysInterfaceReviewIpv4 => 'IPv4';

  @override
  String get sysInterfaceReviewAddresses => '주소';

  @override
  String get sysInterfaceReviewMtu => 'MTU';

  @override
  String get sysInterfaceReviewDhcp => 'DHCP';

  @override
  String get sysInterfaceReviewStatic => '정적';

  @override
  String get sysInterfaceReviewAssignedByDhcp => 'DHCP가 할당함';

  @override
  String get sysInterfaceReviewNone => '없음';

  @override
  String get sysInterfaceReviewMtuDefault => '기본값 (1500)';

  @override
  String get sysInterfaceNothingChanged =>
      '변경된 사항이 없습니다. 저장해도 스테이징되는 작업이 없습니다.';

  @override
  String get sysInterfaceSessionDrop =>
      'TrueDock이 연결된 인터페이스의 주소를 변경하면 커밋할 때 이 세션이 끊깁니다. 체크인이 도착하지 않으면 서버가 변경 사항을 자동으로 롤백합니다.';

  @override
  String get sysInterfaceDhcpLosesRoute =>
      'DHCP로 전환하면 이 인터페이스의 정적 주소가 제거됩니다. 해당 주소를 가리키는 모든 항목이 라우트를 잃습니다.';

  @override
  String get sysInterfaceEditAddressTooltip => '주소 편집';

  @override
  String get sysInterfaceRemoveAddressTooltip => '주소 제거';

  @override
  String get sysInterfaceEditAddressTitle => '주소 편집';

  @override
  String get sysInterfaceIpv4Label => 'IPv4';

  @override
  String get sysInterfaceIpv6Label => 'IPv6';

  @override
  String get sysInterfaceAddressLabel => '주소';

  @override
  String get sysInterfacePrefixLabel => '프리픽스 길이';

  @override
  String get sysInterfacePrefixHelperV6 => '1-128, 예: 64';

  @override
  String get sysInterfacePrefixHelperV4 => '1-32, 예: 24';

  @override
  String get sysInterfaceSaveAddress => '주소 저장';

  @override
  String sysInterfaceAliasErrorInvalid(String family) {
    return '올바른 $family 주소를 입력하세요.';
  }

  @override
  String sysInterfaceAliasErrorPrefix(int max) {
    return '1에서 $max 사이의 프리픽스를 사용하세요.';
  }

  @override
  String get sysInterfaceValidationMtuRange => '68에서 9216 사이의 MTU를 사용하세요.';

  @override
  String get sysInterfaceValidationAliasesRequired =>
      '최소한 하나의 정적 주소를 추가하거나 DHCP를 다시 켜세요.';

  @override
  String sysInterfaceValidationAliasAddressInvalid(String family) {
    return '각 별칭에 올바른 $family 주소를 입력하세요.';
  }

  @override
  String sysInterfaceValidationAliasPrefixRange(int max, String address) {
    return '$address에 1에서 $max 사이의 프리픽스를 사용하세요.';
  }

  @override
  String sysInterfaceValidationAliasDuplicate(String address) {
    return '$address이(가) 두 번 이상 나열되어 있습니다.';
  }

  @override
  String get sysVmDevicesTitle => 'VM 장치';

  @override
  String get sysVmDevicesSubtitle =>
      '이 가상 머신에 연결된 디스크, 네트워크 인터페이스 및 기타 장치입니다. 디스크 장치를 제거해도 기본 zvol이나 이미지는 삭제되지 않습니다.';

  @override
  String get sysVmDevicesNone => '이 VM에 연결된 장치가 없습니다.';

  @override
  String get sysVmDeviceEditTooltip => '장치 편집';

  @override
  String get sysVmDeviceRemoveTooltip => '장치 제거';

  @override
  String get sysVmDeviceAddAction => '장치 추가';

  @override
  String get sysVmDeviceEditTitle => 'VM 장치 편집';

  @override
  String get sysVmDeviceAddTitle => 'VM 장치 추가';

  @override
  String get sysVmDeviceTypeLabel => '장치 유형';

  @override
  String get sysVmDevicePathLabel => '경로';

  @override
  String get sysVmDevicePathHelper => 'zvol 또는 이미지 경로 (예: /dev/zvol/tank/vm)';

  @override
  String get sysVmDeviceSizeLabel => '크기 (MiB)';

  @override
  String get sysVmDeviceSizeHelper => '기존 zvol에는 무시됩니다.';

  @override
  String get sysVmDeviceMacLabel => 'MAC 주소 (선택)';

  @override
  String get sysVmDeviceMacHelper => '자동 생성된 MAC를 사용하려면 비워 두세요.';

  @override
  String get sysVmDeviceDisplayNotice =>
      '기본 설정으로 VNC 디스플레이 장치가 생성됩니다. 고급 옵션은 서버에서 편집하세요.';

  @override
  String sysVmDeviceDefaultNotice(String type) {
    return '$type 장치는 기본 속성을 사용합니다. 고급 설정은 서버에서 편집하세요.';
  }

  @override
  String get sysVmDeviceSaveAction => '장치 저장';

  @override
  String get sysVmDeviceErrorPathRequired => '디스크 경로를 입력하세요.';

  @override
  String get sysVmDeviceTypeDisk => '디스크';

  @override
  String get sysVmDeviceTypeCdrom => 'CD-ROM';

  @override
  String get sysVmDeviceTypeNic => '네트워크 인터페이스';

  @override
  String get sysVmDeviceTypeDisplay => '디스플레이';

  @override
  String get sysVmDeviceTypeMemory => '메모리 벌룬';

  @override
  String get sysVmDeviceTypeUsb => 'USB 리다이렉트';

  @override
  String get sysVmDeviceTypePci => 'PCI 장치';

  @override
  String get sysVmDeviceTypeSerial => '직렬 포트';

  @override
  String get sysVmDeviceTypeOther => '기타';

  @override
  String sysVmDeviceSummaryDiskWithSize(String path, String size) {
    return '$path · $size';
  }

  @override
  String get sysVmDeviceSummaryDiskFallback => '디스크';

  @override
  String sysVmDeviceSummaryNicWithMac(String mac) {
    return 'NIC · $mac';
  }

  @override
  String sysVmDeviceSummaryDisplay(String mode) {
    return '디스플레이 · $mode';
  }

  @override
  String get sysVmDeviceSummaryCdromEmpty => 'CD-ROM · 비어 있음';

  @override
  String sysVmDeviceSummaryCdromWithPath(String path) {
    return 'CD-ROM · $path';
  }

  @override
  String get sysVmConfigReviewTitle => '변경 사항 검토';

  @override
  String get sysVmConfigEditTitle => '가상 머신 편집';

  @override
  String get sysVmConfigNameLabel => '이름';

  @override
  String get sysVmConfigDescriptionLabel => '설명';

  @override
  String get sysVmConfigCpuTitle => 'CPU';

  @override
  String get sysVmConfigSocketsLabel => '소켓';

  @override
  String get sysVmConfigCoresLabel => '코어';

  @override
  String get sysVmConfigThreadsLabel => '스레드';

  @override
  String get sysVmConfigMemoryTitle => '메모리';

  @override
  String get sysVmConfigMemoryLabel => '메모리 (MiB)';

  @override
  String get sysVmConfigMinMemoryLabel => '최소 메모리 (MiB, 선택)';

  @override
  String get sysVmConfigMinMemoryHelper => '메모리 벌루닝에 사용됩니다. 비활성화하려면 비워 두세요.';

  @override
  String get sysVmConfigBootCpuTitle => '부트 & CPU';

  @override
  String get sysVmConfigBootloaderLabel => '부트로더';

  @override
  String get sysVmConfigCpuModeLabel => 'CPU 모드';

  @override
  String get sysVmConfigBehaviourTitle => '동작';

  @override
  String get sysVmConfigAutostartTitle => '자동 시작';

  @override
  String get sysVmConfigAutostartSubtitle => '서버가 시작될 때 VM을 부팅합니다.';

  @override
  String get sysVmConfigEnsureDisplayTitle => '디스플레이 장치 보장';

  @override
  String get sysVmConfigEnsureDisplaySubtitle =>
      '디스플레이 장치가 없으면 VNC 디스플레이 장치를 만듭니다.';

  @override
  String get sysVmConfigShutdownTimeoutLabel => '종료 타임아웃 (초)';

  @override
  String get sysVmConfigShutdownTimeoutHelper => '정상 종료를 기다릴 시간입니다.';

  @override
  String get sysVmConfigReviewName => '이름';

  @override
  String get sysVmConfigReviewCpu => 'CPU';

  @override
  String sysVmConfigReviewCpuValue(int sockets, int cores, int threads) {
    return '소켓 $sockets · 코어 $cores · 스레드 $threads';
  }

  @override
  String get sysVmConfigReviewMemory => '메모리';

  @override
  String sysVmConfigReviewMemoryValue(int memory) {
    return '$memory MiB';
  }

  @override
  String sysVmConfigReviewMemoryWithMinValue(int memory, int min) {
    return '$memory MiB (최소 $min)';
  }

  @override
  String get sysVmConfigReviewBootloader => '부트로더';

  @override
  String get sysVmConfigReviewCpuMode => 'CPU 모드';

  @override
  String get sysVmConfigReviewAutostart => '자동 시작';

  @override
  String get sysVmConfigEnabled => '활성화됨';

  @override
  String get sysVmConfigDisabled => '비활성화됨';

  @override
  String get sysVmConfigReviewShutdown => '종료';

  @override
  String sysVmConfigReviewShutdownValue(int seconds) {
    return '$seconds초';
  }

  @override
  String get sysVmConfigNoFieldsChanged => '변경된 필드가 없습니다. VM은 현재 설정을 유지합니다.';

  @override
  String sysVmConfigApplyNotice(String apply) {
    return '메모리와 CPU 변경 사항은 다음 시작 시 적용됩니다. $apply';
  }

  @override
  String sysVmConfigApplyRunning(String name) {
    return '$name이(가) 현재 실행 중입니다. 적용하려면 재시작하세요.';
  }

  @override
  String get sysVmConfigApplyStart => '적용하려면 VM을 시작하세요.';

  @override
  String get sysVmConfigChangedFields => '변경된 필드';

  @override
  String get sysVmConfigValidationNameRequired => 'VM 이름을 입력하세요.';

  @override
  String get sysVmConfigValidationVcpusMinimum => '최소 1개의 가상 CPU를 사용하세요.';

  @override
  String get sysVmConfigValidationCoresMinimum => '소켓당 최소 1개의 코어를 사용하세요.';

  @override
  String get sysVmConfigValidationThreadsMinimum => '코어당 최소 1개의 스레드를 사용하세요.';

  @override
  String get sysVmConfigValidationMemoryMinimum => '최소 128 MiB의 메모리를 할당하세요.';

  @override
  String get sysVmConfigValidationMinMemoryExceeds =>
      '최소 메모리는 메모리를 초과할 수 없습니다.';

  @override
  String get sysVmConfigValidationShutdownTimeoutRange =>
      '종료 타임아웃은 5에서 300초 사이여야 합니다.';

  @override
  String get sysVmBootloaderUefi => 'UEFI';

  @override
  String get sysVmBootloaderUefiCsm => 'UEFI_CSM';

  @override
  String get sysVmBootloaderGrub => 'GRUB';

  @override
  String get sysVmCpuModeCustom => '사용자 지정';

  @override
  String get sysVmCpuModeHostModel => '호스트 모델';

  @override
  String get sysVmCpuModeHostPassthrough => '호스트 패스스루';

  @override
  String get sysContainerConfigReviewTitle => '변경 사항 검토';

  @override
  String get sysContainerConfigEditTitle => '컨테이너 편집';

  @override
  String get sysContainerConfigClose => '닫기';

  @override
  String get sysContainerConfigBack => '뒤로';

  @override
  String get sysContainerConfigCancel => '취소';

  @override
  String get sysContainerConfigReview => '검토';

  @override
  String get sysContainerConfigSaveChanges => '변경 사항 저장';

  @override
  String get sysContainerConfigNameLabel => '이름';

  @override
  String get sysContainerConfigDescriptionLabel => '설명';

  @override
  String get sysContainerConfigDatasetLabel => '데이터셋';

  @override
  String get sysContainerConfigDatasetHelper => '기존 컨테이너의 데이터셋은 고정됩니다.';

  @override
  String get sysContainerConfigResourcesTitle => '리소스';

  @override
  String get sysContainerConfigVcpusLabel => 'vCPU(선택)';

  @override
  String get sysContainerConfigVcpusHelper => 'CPU 제한을 두지 않으려면 비워 두세요.';

  @override
  String get sysContainerConfigMemoryLabel => '메모리 제한(MiB, 선택)';

  @override
  String get sysContainerConfigMemoryHelper => '메모리 제한을 두지 않으려면 비워 두세요.';

  @override
  String get sysContainerConfigBehaviourTitle => '동작';

  @override
  String get sysContainerConfigAutostartTitle => '자동으로 시작';

  @override
  String get sysContainerConfigAutostartSubtitle => '서버가 시작될 때 컨테이너를 시작합니다.';

  @override
  String sysContainerConfigPreservedNotice(int devices, int volumes, int env) {
    return '디바이스 $devices개, 볼륨 $volumes개, 환경 변수 $env개는 현재 컨테이너에서 보존되어 변경 없이 전송됩니다. 이번 릴리스에서는 편집할 수 없습니다.';
  }

  @override
  String sysContainerConfigVolumesEnvNotice(int volumes, int env) {
    return '볼륨 $volumes개와 환경 변수 $env개는 현재 컨테이너에서 보존되어 변경 없이 전송됩니다.';
  }

  @override
  String get sysContainerConfigDevicesTitle => '디바이스';

  @override
  String get sysContainerConfigDevicesHelper =>
      '컨테이너로 패스스루할 블록 디바이스입니다. 추가된 디바이스는 25.10 패스스루 형식을 사용하고, 제거 시 남은 목록을 다시 전송합니다.';

  @override
  String get sysContainerConfigNoDevices => '연결된 디바이스가 없습니다.';

  @override
  String sysContainerConfigDeviceLabel(int index) {
    return '디바이스 $index';
  }

  @override
  String get sysContainerConfigAddDevice => '디바이스 추가';

  @override
  String get sysContainerConfigRemoveDevice => '디바이스 제거';

  @override
  String get sysContainerConfigAddDeviceTitle => '디바이스 추가';

  @override
  String get sysContainerConfigAddDeviceHelper =>
      '컨테이너로 패스스루할 호스트 디바이스를 선택하세요. TrueDock이 25.10 패스스루 형식으로 전송합니다.';

  @override
  String get sysContainerConfigReviewName => '이름';

  @override
  String get sysContainerConfigReviewDescription => '설명';

  @override
  String get sysContainerConfigReviewDescriptionNone => '없음';

  @override
  String get sysContainerConfigReviewDataset => '데이터셋';

  @override
  String get sysContainerConfigReviewVcpus => 'vCPU';

  @override
  String get sysContainerConfigReviewVcpusNone => '제한 없음';

  @override
  String get sysContainerConfigReviewMemory => '메모리';

  @override
  String get sysContainerConfigReviewMemoryNone => '제한 없음';

  @override
  String sysContainerConfigReviewMemoryValue(int memory) {
    return '$memory MiB';
  }

  @override
  String get sysContainerConfigReviewAutostart => '자동 시작';

  @override
  String get sysContainerConfigReviewAutostartEnabled => '활성화됨';

  @override
  String get sysContainerConfigReviewAutostartDisabled => '비활성화됨';

  @override
  String get sysContainerConfigReviewDevices => '디바이스';

  @override
  String sysContainerConfigReviewDevicesValue(int count) {
    return '$count개 보존됨';
  }

  @override
  String get sysContainerConfigReviewVolumes => '볼륨';

  @override
  String sysContainerConfigReviewVolumesValue(int count) {
    return '$count개 보존됨';
  }

  @override
  String get sysContainerConfigReviewNoticeBase =>
      'TrueNAS는 컨테이너 설정 전체를 교체합니다. 디바이스, 볼륨, 환경 변수는 현재 컨테이너에서 변경 없이 전송됩니다.';

  @override
  String sysContainerConfigReviewNoticeRunning(Object name) {
    return '$name이(가) 실행 중입니다. 적용하려면 다시 시작하세요.';
  }

  @override
  String get sysContainerConfigReviewNoticeStart => '적용하려면 컨테이너를 시작하세요.';

  @override
  String get sysContainerConfigValidationNameRequired => '컨테이너 이름을 입력하세요.';

  @override
  String get sysContainerConfigValidationDatasetRequired => '데이터셋 경로를 입력하세요.';

  @override
  String get sysContainerConfigValidationVcpusMinimum =>
      '최소 1개의 가상 CPU를 사용하세요.';

  @override
  String get sysContainerConfigValidationMemoryMinimum =>
      '최소 16 MiB의 메모리를 할당하세요.';

  @override
  String get coreDestructiveServerLabel => '서버';

  @override
  String get coreDestructiveTargetLabel => '대상';

  @override
  String get coreDestructiveConsequencesTitle => '발생하는 일';

  @override
  String coreDestructiveCannotBeUndone(Object name) {
    return '이 작업은 되돌릴 수 없습니다. 계속하려면 $name을(를) 입력하세요.';
  }

  @override
  String get coreDestructiveConfirmNameLabel => '이름 확인';

  @override
  String get coreDestructiveCancel => '취소';

  @override
  String get storageRenameTitle => '데이터셋 이름 변경';

  @override
  String get storageRenameNewNameLabel => '새 이름';

  @override
  String get storageRenameRecursiveTitle => '하위 데이터셋 이름 변경';

  @override
  String get storageRenameRecursiveSubtitle => '아래의 모든 데이터셋에 새 경로를 적용합니다.';

  @override
  String get storageRenameNotice =>
      'TrueNAS는 이름을 변경하는 동안 데이터셋을 마운트 해제합니다. 이전 경로를 참조하는 공유, 앱, 작업은 계속 해당 경로를 가리키며 별도로 업데이트해야 합니다.';

  @override
  String get storageRenameAction => '데이터셋 이름 변경';

  @override
  String get storageRenameCodeRenameEmpty => '새 데이터셋 이름을 입력하세요.';

  @override
  String get storageRenameCodeRenameContainsSlash =>
      '데이터셋 이름에는 \"/\"를 포함할 수 없습니다.';

  @override
  String get storageRenameCodeRenamePoolRoot => '풀 루트 데이터셋은 이름을 변경할 수 없습니다.';

  @override
  String get storageRenameCodeRenameUnchanged => '현재 이름과 다른 이름을 입력하세요.';

  @override
  String get storageDatasetCodeEditNothingChanged => '이 데이터셋에는 변경된 사항이 없습니다.';

  @override
  String get storageDatasetTileActionsTooltip => '데이터셋 작업';

  @override
  String storageDatasetTileUsed(Object bytes) {
    return '$bytes 사용';
  }

  @override
  String storageDatasetTileAvailable(Object bytes) {
    return '$bytes 사용 가능';
  }

  @override
  String storageDatasetTileQuota(Object bytes) {
    return '할당량 $bytes';
  }

  @override
  String get storageDatasetTileReadOnly => '읽기 전용';

  @override
  String get storageDatasetTileClone => '복제본';

  @override
  String get storageDatasetTileTakeSnapshot => '스냅샷 생성';

  @override
  String get storageDatasetTileEditProperties => '속성 편집';

  @override
  String get storageDatasetTileQuotas => '사용자 및 그룹 할당량';

  @override
  String get storageDatasetTileManageAcl => 'ACL 관리';

  @override
  String get storageDatasetAclTitle => '데이터셋 ACL';

  @override
  String get storageDatasetAclReviewTitle => 'ACL 변경사항 검토';

  @override
  String storageDatasetAclType(Object type) {
    return 'ACL 유형: $type';
  }

  @override
  String get storageDatasetAclOwnership => '소유권';

  @override
  String get storageDatasetAclPermissionType => '권한 유형';

  @override
  String get storageDatasetAclPosix => 'POSIX';

  @override
  String get storageDatasetAclTrueNas => 'TrueNAS ACL';

  @override
  String get storageDatasetAclTypeConversionWarning =>
      'ACL 유형을 변경하면 선택한 형식으로 규칙을 재구성합니다. 지정 사용자와 그룹의 기본 접근 수준은 유지하지만, 대응 항목이 없는 거부 및 상속 세부 설정은 교체됩니다.';

  @override
  String get storageDatasetAclTypeChangeWarningTitle => 'ACL 유형을 변경할까요?';

  @override
  String storageDatasetAclTypeChangeWarningBody(String from, String to) {
    return '$from에서 $to(으)로 변경할까요? 기존 규칙은 새 형식으로 재구성됩니다. 지정 사용자와 그룹의 기본 접근 수준은 유지하지만 호환되지 않는 거부, 기본값 및 상속 세부 설정은 교체될 수 있습니다.';
  }

  @override
  String get storageDatasetAclChangeTypeAction => 'ACL 유형 변경';

  @override
  String storageDatasetAclConfirmOwnership(String user, String group) {
    return '소유권을 $user : $group(으)로 변경합니다.';
  }

  @override
  String storageDatasetAclConfirmTypeChange(String from, String to) {
    return 'ACL 유형을 $from에서 $to(으)로 변경하며, 정확히 대응하지 않는 규칙은 재구성합니다.';
  }

  @override
  String get storageDatasetAclRemove => '규칙 제거';

  @override
  String get storageDatasetAclAdd => '사용자 또는 그룹 추가';

  @override
  String storageDatasetAclChoosePrincipal(String type) {
    return '$type 선택';
  }

  @override
  String storageDatasetAclSearchPrincipal(String type) {
    return '$type 검색';
  }

  @override
  String storageDatasetAclPrincipalCount(int count) {
    return '계정 $count개';
  }

  @override
  String storageDatasetAclNoPrincipals(String type) {
    return '검색과 일치하는 $type이(가) 없습니다.';
  }

  @override
  String get storageDatasetAclRecursive => '재귀적으로 적용';

  @override
  String get storageDatasetAclRecursiveSubtitle => '하위 파일과 디렉터리의 ACL을 교체합니다.';

  @override
  String get storageDatasetAclRecursiveWarning => '하위 파일과 디렉터리의 기존 권한이 교체됩니다.';

  @override
  String get storageDatasetAclTraverse => '탐색';

  @override
  String get storageDatasetAclNone => '권한 없음';

  @override
  String get storageDatasetAclRead => '읽기';

  @override
  String get storageDatasetAclWrite => '쓰기';

  @override
  String get storageDatasetAclExecute => '실행';

  @override
  String get storageDatasetAclModify => '수정';

  @override
  String get storageDatasetAclFullControl => '모든 권한';

  @override
  String storageDatasetAclRuleCount(int count) {
    return 'ACL 규칙 $count개';
  }

  @override
  String get storageDatasetAclLoadFailed => '데이터셋 ACL을 불러오지 못했습니다.';

  @override
  String get storageDatasetAclSaveFailed => '데이터셋 ACL을 저장하지 못했습니다.';

  @override
  String storageDatasetAclSetAclError(String detail) {
    return 'setacl 오류\n$detail';
  }

  @override
  String storageDatasetAclPoolMountpointError(String path) {
    return '지정한 경로는 ZFS 풀 탑재 지점입니다. ($path)';
  }

  @override
  String get storageDatasetAclTypeChangeFailed =>
      '데이터셋 ACL 유형을 변경하지 못했습니다. 새 ACL 규칙은 적용하지 않았습니다.';

  @override
  String get storageDatasetAclSaved => '데이터셋 ACL을 저장했습니다.';

  @override
  String get storageDatasetAclConfirmTitle => 'ACL 변경사항을 적용할까요?';

  @override
  String get storageDatasetAclConfirmAction => 'ACL 적용';

  @override
  String storageDatasetAclConfirmRules(int count) {
    return '데이터셋 ACL을 규칙 $count개로 교체합니다.';
  }

  @override
  String get storageDatasetAclConfirmRecursive =>
      '하위 파일과 디렉터리의 권한도 이 ACL로 교체합니다.';

  @override
  String get storageDatasetAclConfirmDatasetOnly => '데이터셋 루트 ACL만 변경합니다.';

  @override
  String quotaTitle(String dataset) {
    return '$dataset의 할당량';
  }

  @override
  String get quotaSubjectUsers => '사용자';

  @override
  String get quotaSubjectGroups => '그룹';

  @override
  String get quotaNoneUsers => '아직 이 데이터셋에 쓴 사용자가 없습니다.';

  @override
  String get quotaNoneGroups => '아직 이 데이터셋에 쓴 그룹이 없습니다.';

  @override
  String quotaUsageOnly(String used) {
    return '$used 사용, 제한 없음';
  }

  @override
  String quotaSpaceOf(String used, String limit) {
    return '$limit 중 $used';
  }

  @override
  String quotaObjectsOf(String used, String limit) {
    return '파일 $limit개 중 $used개';
  }

  @override
  String quotaObjectsOnly(String used) {
    return '파일 $used개';
  }

  @override
  String get quotaOverLimit => '한도 초과';

  @override
  String get quotaAdd => '할당량 설정';

  @override
  String quotaEditTitle(String name) {
    return '$name의 할당량';
  }

  @override
  String get quotaTargetLabel => '사용자 또는 그룹';

  @override
  String get quotaTargetHelp => '이름 또는 숫자 ID를 입력하세요. 서버가 인식하지 못하는 계정은 거부됩니다.';

  @override
  String get quotaSpaceLabel => '용량 제한';

  @override
  String get quotaObjectLabel => '파일 개수 제한 (선택)';

  @override
  String get quotaZeroRemoves => '비워 두면 현재 값을 유지합니다. 0을 입력하면 해당 제한을 해제합니다.';

  @override
  String get quotaApply => '적용';

  @override
  String quotaRemoveTitle(String name) {
    return '$name의 할당량을 해제할까요?';
  }

  @override
  String get quotaRemoveAction => '할당량 해제';

  @override
  String quotaRemoveConsequence(String name) {
    return '$name이(가) 다시 제한 없이 이 데이터셋에 쓸 수 있게 됩니다. 이미 저장된 데이터는 삭제되지 않습니다.';
  }

  @override
  String get quotaApplied => '할당량을 변경했습니다.';

  @override
  String get quotaFailed => '할당량을 적용하지 못했습니다.';

  @override
  String get quotaValidationTarget => '사용자 또는 그룹을 입력하세요.';

  @override
  String get quotaValidationReserved =>
      'root에는 할당량을 설정할 수 없습니다. TrueNAS가 거부합니다.';

  @override
  String get quotaValidationNegative => '0 이상의 숫자를 입력하세요.';

  @override
  String get quotaValidationEmpty => '제한을 하나 이상 설정하세요.';

  @override
  String get quotaLoadFailed => '할당량을 읽지 못했습니다.';

  @override
  String get storageDatasetTileRename => '이름 변경';

  @override
  String get storageDatasetTileUnlock => '잠금 해제';

  @override
  String get storageDatasetTileLock => '잠금';

  @override
  String get storageDatasetTilePromoteClone => '복제본 승격';

  @override
  String get storageDatasetTileDeleteDataset => '데이터셋 삭제';

  @override
  String get storageDiskPickerHelper =>
      '이미 풀에 속하지 않은 디스크를 선택하세요. 연결 또는 교체는 리실버를 시작하므로 완료될 때까지 풀을 온라인 상태로 유지하세요.';

  @override
  String get storageDiskPickerEmpty => '이 서버에서 사용 가능한 미사용 디스크가 없습니다.';

  @override
  String get storageDiskPickerSearchLabel => '디스크 검색';

  @override
  String get storageDiskPickerSearchHint => '이름, 시리얼 또는 모델';

  @override
  String get storageDiskPickerCancel => '취소';

  @override
  String get storageDiskPickerContinue => '계속';

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
    return '$celsius도(섭씨)';
  }

  @override
  String storageDiskTempOverLimit(int celsius) {
    return '$celsius도(섭씨), 드라이브 한도 초과';
  }

  @override
  String get storageIscsiAuthMgmtTitle => 'CHAP 자격 증명';

  @override
  String get storageIscsiAuthMgmtSubtitle =>
      'iSCSI 개시자 인증 항목입니다. 타깃 그룹은 태그로 이 항목을 참조합니다. 비밀값은 쓰기 전용이며 표시되지 않습니다.';

  @override
  String get storageIscsiAuthMgmtEmpty => '이 서버에 구성된 CHAP 자격 증명이 없습니다.';

  @override
  String get storageIscsiAuthMgmtEmptyUser => '(빈 사용자)';

  @override
  String storageIscsiAuthMgmtTagSubtitle(int tag, Object mode) {
    return '태그 $tag · $mode';
  }

  @override
  String get storageIscsiAuthMgmtMutualChap => '상호 CHAP';

  @override
  String get storageIscsiAuthMgmtOnewayChap => '단방향 CHAP';

  @override
  String get storageIscsiAuthMgmtEdit => '편집';

  @override
  String get storageIscsiAuthMgmtDelete => '삭제';

  @override
  String get storageIscsiAuthMgmtNew => '새 CHAP 자격 증명';

  @override
  String get storageSmbAclReviewTitle => '공유 권한 검토';

  @override
  String storageSmbAclFormTitle(Object name) {
    return '$name의 권한';
  }

  @override
  String get storageSmbAclClose => '닫기';

  @override
  String get storageSmbAclBack => '뒤로';

  @override
  String get storageSmbAclCancel => '취소';

  @override
  String get storageSmbAclReview => '검토';

  @override
  String get storageSmbAclContinue => '계속';

  @override
  String get storageSmbAclCurrentPrincipals => '현재 보안 주체';

  @override
  String get storageSmbAclEmpty =>
      '아직 권한이 설정되지 않았습니다. 규칙을 추가하지 않으면 파일 시스템 접근 권한이 있는 모든 사용자가 이 공유에 접근할 수 있습니다.';

  @override
  String get storageSmbAclAddPrincipal => '보안 주체 추가';

  @override
  String get storageSmbAclUser => '사용자';

  @override
  String get storageSmbAclGroup => '그룹';

  @override
  String get storageSmbAclAddToList => '목록에 추가';

  @override
  String get storageSmbAclDuplicateError => '해당 보안 주체는 이미 목록에 있습니다.';

  @override
  String get storageSmbAclReviewServerAction => '서버 작업';

  @override
  String get storageSmbAclReviewServerActionValue => 'SMB 공유 권한 교체';

  @override
  String get storageSmbAclReviewShare => '공유';

  @override
  String get storageSmbAclReviewRules => '규칙';

  @override
  String storageSmbAclReviewRulesValue(int count) {
    return '보안 주체 $count개';
  }

  @override
  String storageSmbAclReviewAllow(Object permission) {
    return '허용 $permission';
  }

  @override
  String storageSmbAclReviewDeny(Object permission) {
    return '거부 $permission';
  }

  @override
  String get storageSmbAclPermRead => '읽기';

  @override
  String get storageSmbAclPermChange => '변경';

  @override
  String get storageSmbAclPermFull => '전체';

  @override
  String get storageSmbAclReviewNotice =>
      '공유 권한을 교체하면 현재 이 공유를 사용하는 클라이언트의 접근이 취소될 수 있습니다. 전체 목록이 기존 ACL을 교체합니다.';

  @override
  String get storageSmbAclRemoveFromList => '목록에서 제거';

  @override
  String get storageSmbAclAllowRead => '읽기 허용';

  @override
  String get storageSmbAclAllowChange => '변경 허용';

  @override
  String get storageSmbAclAllowFull => '전체 허용';

  @override
  String get storageSmbAclDeny => '거부';

  @override
  String get storageSmbAclPrincipalLabel => '보안 주체';

  @override
  String get storageSmbAclNoGroups => '추가로 사용 가능한 그룹이 없습니다.';

  @override
  String get storageSmbAclNoUsers => '추가로 사용 가능한 사용자가 없습니다.';

  @override
  String get storageNfsReviewTitle => 'NFS 공유 검토';

  @override
  String get storageNfsEditTitle => 'NFS 공유 편집';

  @override
  String get storageNfsNewTitle => '새 NFS 공유';

  @override
  String get storageNfsSubtitle => '네트워크 내보내기 및 클라이언트 ID 매핑';

  @override
  String get storageNfsClose => '닫기';

  @override
  String get storageNfsBack => '뒤로';

  @override
  String get storageNfsCancel => '취소';

  @override
  String get storageNfsReview => '검토';

  @override
  String get storageNfsSaveChanges => '변경 사항 저장';

  @override
  String get storageNfsCreateShare => '공유 생성';

  @override
  String get storageNfsExportPathLabel => '내보내기 경로';

  @override
  String get storageNfsExportPathHelper => '/mnt/ 아래 ZFS 풀의 기존 경로';

  @override
  String get storageNfsCommentLabel => '설명';

  @override
  String get storageNfsAuthorizedClients => '인증된 클라이언트';

  @override
  String get storageNfsNetworksLabel => '네트워크';

  @override
  String get storageNfsNetworksHelper =>
      '한 줄에 하나의 CIDR 네트워크 · 비워 두면 모든 네트워크 허용';

  @override
  String get storageNfsHostsLabel => '개별 호스트';

  @override
  String get storageNfsHostsHelper => '한 줄에 하나의 IP 주소 또는 호스트 이름';

  @override
  String get storageNfsSecurityTitle => '보안';

  @override
  String get storageNfsSecurityEmpty => '명시적 스키마 없음; TrueNAS가 기본값 적용.';

  @override
  String get storageNfsSecuritySelected =>
      '클라이언트는 선택된 보안 스키마 중 하나를 협상할 수 있습니다.';

  @override
  String get storageNfsMappingTitle => '클라이언트 ID 매핑';

  @override
  String get storageNfsMappingSubtitle => '선택적 root 사용자 또는 전체 사용자 매핑';

  @override
  String get storageNfsMapRoot => 'root 클라이언트 ID 매핑';

  @override
  String get storageNfsMapAll => '모든 클라이언트 ID 매핑';

  @override
  String get storageNfsUserLabel => '사용자';

  @override
  String get storageNfsGroupLabel => '그룹';

  @override
  String get storageNfsReadOnlyTitle => '읽기 전용';

  @override
  String get storageNfsReadOnlySubtitle => 'NFS 클라이언트가 파일을 변경하지 못하게 합니다.';

  @override
  String get storageNfsEnableTitle => '공유 활성화';

  @override
  String get storageNfsEnableSubtitle => 'NFS 서비스를 통해 내보내기를 게시합니다.';

  @override
  String get storageNfsEnterpriseNotice =>
      '스냅샷 디렉터리 노출은 Enterprise 전용 값입니다. TrueDock은 기존 설정을 보존하지만 Community Edition에서는 활성화할 수 없습니다.';

  @override
  String get storageNfsReviewPath => '경로';

  @override
  String get storageNfsReviewClients => '클라이언트';

  @override
  String get storageNfsReviewClientsAll => '모든 네트워크 및 호스트';

  @override
  String get storageNfsReviewAccess => '접근';

  @override
  String get storageNfsReviewAccessReadOnly => '읽기 전용';

  @override
  String get storageNfsReviewAccessReadWrite => '읽기 및 쓰기';

  @override
  String get storageNfsReviewSecurity => '보안';

  @override
  String get storageNfsReviewSecurityDefault => '서버 기본값';

  @override
  String get storageNfsReviewRootMapping => 'root 매핑';

  @override
  String get storageNfsReviewAllMapping => '전체 매핑';

  @override
  String get storageNfsReviewState => '상태';

  @override
  String get storageNfsReviewStateEnabled => '활성화됨';

  @override
  String get storageNfsReviewStateDisabled => '비활성화됨';

  @override
  String get storageNfsMappingNone => '없음';

  @override
  String storageNfsMappingLabel(Object user, Object group) {
    return '$user : $group';
  }

  @override
  String get storageNfsUnrestrictedNotice =>
      '이 쓰기 가능한 내보내기는 파일 시스템 권한이나 다른 네트워크 제어가 접근을 차단하지 않는 한 모든 네트워크를 허용합니다.';

  @override
  String get storageNfsMapAllRootNotice =>
      '모든 NFS 클라이언트 사용자가 root로 매핑됩니다. 이 광범위한 권한이 의도적인 것인지 확인하세요.';

  @override
  String get storageNfsReviewNotice =>
      'TrueNAS가 경로, 인증된 클라이언트, 매핑 및 NFS 보안 구성을 검증합니다.';

  @override
  String get storageNfsSecuritySys => 'SYS';

  @override
  String get storageNfsSecurityKrb5 => 'Kerberos';

  @override
  String get storageNfsSecurityKrb5i => 'Kerberos + 무결성';

  @override
  String get storageNfsSecurityKrb5p => 'Kerberos + 프라이버시';

  @override
  String get storageNfsValidationPath => '/mnt/ 아래의 기존 경로를 입력하세요.';

  @override
  String get storageNfsValidationNetworksCount => '인증된 네트워크는 최대 42개까지 사용하세요.';

  @override
  String get storageNfsValidationNetworksFormat =>
      '10.0.0.0/24와 같은 고유한 CIDR 네트워크를 사용하세요.';

  @override
  String get storageNfsValidationHosts => '공백 없이 고유한 호스트 이름 또는 IP 주소를 사용하세요.';

  @override
  String get storageNfsValidationMapping => 'root 매핑 또는 전체 사용자 매핑 중 하나를 선택하세요.';

  @override
  String get storageIscsiAuthReviewTitle => 'CHAP 자격 증명 검토';

  @override
  String get storageIscsiAuthEditTitle => 'CHAP 자격 증명 편집';

  @override
  String get storageIscsiAuthNewTitle => '새 CHAP 자격 증명';

  @override
  String get storageIscsiAuthSubtitle => 'iSCSI 개시자 인증';

  @override
  String get storageIscsiAuthListEmpty => 'iSCSI 개시자 인증 · 설정 없음';

  @override
  String storageIscsiAuthListCount(int count) {
    return 'iSCSI 개시자 인증 · 자격 증명 $count개';
  }

  @override
  String get storageIscsiAuthClose => '닫기';

  @override
  String get storageIscsiAuthBack => '뒤로';

  @override
  String get storageIscsiAuthCancel => '취소';

  @override
  String get storageIscsiAuthReview => '검토';

  @override
  String get storageIscsiAuthSaveChanges => '변경 사항 저장';

  @override
  String get storageIscsiAuthCreateCredential => '자격 증명 생성';

  @override
  String get storageIscsiAuthChapUserLabel => 'CHAP 사용자';

  @override
  String get storageIscsiAuthChapUserHelper => '개시자가 제시해야 하는 사용자 이름입니다.';

  @override
  String get storageIscsiAuthSecretLabel => '비밀값';

  @override
  String get storageIscsiAuthNewSecretLabel => '새 비밀값(선택)';

  @override
  String get storageIscsiAuthSecretHelper => '개시자가 인증에 사용하는 공유 비밀값입니다.';

  @override
  String get storageIscsiAuthNewSecretHelper => '기존 비밀값을 유지하려면 비워 두세요.';

  @override
  String get storageIscsiAuthShow => '표시';

  @override
  String get storageIscsiAuthHide => '숨기기';

  @override
  String get storageIscsiAuthConfirmSecretLabel => '비밀값 확인';

  @override
  String get storageIscsiAuthConfirmNewSecretLabel => '새 비밀값 확인';

  @override
  String get storageIscsiAuthConfirmNewSecretHelper =>
      '비밀값을 회전할 때만 새 비밀값을 다시 입력하세요.';

  @override
  String get storageIscsiAuthMutualTitle => '상호 CHAP';

  @override
  String get storageIscsiAuthMutualSubtitle =>
      '타깃도 피어 사용자와 피어 비밀값으로 개시자에게 인증합니다.';

  @override
  String get storageIscsiAuthPeerUserLabel => '피어 사용자';

  @override
  String get storageIscsiAuthPeerUserHelper => '타깃이 개시자에게 제시하는 사용자 이름입니다.';

  @override
  String get storageIscsiAuthPeerSecretLabel => '피어 비밀값';

  @override
  String get storageIscsiAuthNewPeerSecretLabel => '새 피어 비밀값(선택)';

  @override
  String get storageIscsiAuthNewPeerSecretHelper => '기존 피어 비밀값을 유지하려면 비워 두세요.';

  @override
  String get storageIscsiAuthConfirmPeerSecretLabel => '피어 비밀값 확인';

  @override
  String get storageIscsiAuthConfirmNewPeerSecretLabel => '새 피어 비밀값 확인';

  @override
  String get storageIscsiAuthConfirmNewPeerSecretHelper =>
      '피어 비밀값을 회전할 때만 새 피어 비밀값을 다시 입력하세요.';

  @override
  String get storageIscsiAuthSecretsNotice =>
      '비밀값은 이 세션을 통해 연결된 TrueNAS 서버로만 전송됩니다. TrueDock은 이를 저장, 로깅 또는 자동 완성하지 않습니다.';

  @override
  String get storageIscsiAuthReviewTag => '태그';

  @override
  String get storageIscsiAuthReviewChapUser => 'CHAP 사용자';

  @override
  String get storageIscsiAuthReviewSecret => '비밀값';

  @override
  String get storageIscsiAuthReviewSecretUnchanged => '변경 없음';

  @override
  String storageIscsiAuthReviewSecretSet(int count) {
    return '설정 · $count자';
  }

  @override
  String get storageIscsiAuthReviewMutual => '상호 CHAP';

  @override
  String get storageIscsiAuthReviewYes => '예';

  @override
  String get storageIscsiAuthReviewNo => '아니오';

  @override
  String get storageIscsiAuthReviewPeerUser => '피어 사용자';

  @override
  String get storageIscsiAuthReviewPeerSecret => '피어 비밀값';

  @override
  String get storageIscsiAuthReviewNoticeEdit =>
      '이 자격 증명을 참조하는 타깃과 개시자 그룹은 업데이트된 사용자와 비밀값을 즉시 사용하기 시작합니다. 개시자도 일치하도록 재구성해야 합니다.';

  @override
  String get storageIscsiAuthReviewNoticeCreate =>
      '이 사용자와 비밀값을 제시하는 개시자는 이 자격 증명을 참조하는 타깃 그룹에 인증할 수 있습니다.';

  @override
  String get storageIscsiAuthValidationUserRequired => 'CHAP 사용자를 입력하세요.';

  @override
  String get storageIscsiAuthValidationSecretRequired => '비밀값을 입력하세요.';

  @override
  String get storageIscsiAuthValidationSecretMismatch => '두 비밀값이 일치하지 않습니다.';

  @override
  String get storageIscsiAuthValidationPeerUserRequired =>
      '상호 CHAP의 피어 사용자를 입력하세요.';

  @override
  String get storageIscsiAuthValidationPeerSecretRequired =>
      '상호 CHAP의 피어 비밀값을 입력하세요.';

  @override
  String get storageIscsiAuthValidationPeerSecretMismatch =>
      '두 피어 비밀값이 일치하지 않습니다.';

  @override
  String get storageIscsiExtentReviewTitle => 'iSCSI 익스텐트 검토';

  @override
  String get storageIscsiExtentEditTitle => 'iSCSI 익스텐트 편집';

  @override
  String get storageIscsiExtentNewTitle => '새 iSCSI 익스텐트';

  @override
  String get storageIscsiExtentSubtitle => '타깃 매핑을 통해 제공되는 스토리지';

  @override
  String get storageIscsiExtentClose => '닫기';

  @override
  String get storageIscsiExtentBack => '뒤로';

  @override
  String get storageIscsiExtentCancel => '취소';

  @override
  String get storageIscsiExtentReview => '검토';

  @override
  String get storageIscsiExtentSaveChanges => '변경 사항 저장';

  @override
  String get storageIscsiExtentCreateExtent => '익스텐트 생성';

  @override
  String get storageIscsiExtentNameLabel => '이름';

  @override
  String get storageIscsiExtentNameHelper => 'iSCSI 관리자에게 표시되는 고유 이름';

  @override
  String get storageIscsiExtentCommentLabel => '설명';

  @override
  String get storageIscsiExtentCommentHelper => '선택적 설명';

  @override
  String get storageIscsiExtentBackingStore => '백킹 스토어';

  @override
  String get storageIscsiExtentTypeDisk => '디바이스';

  @override
  String get storageIscsiExtentTypeFile => '파일';

  @override
  String get storageIscsiExtentDiskLabel => '디스크 또는 zvol';

  @override
  String get storageIscsiExtentDiskHelper => '이 TrueNAS 서버가 보고한 현재 선택지';

  @override
  String get storageIscsiExtentNoDiskChoices =>
      '이 서버는 새 익스텐트에 사용 가능한 디스크 또는 zvol을 반환하지 않았습니다.';

  @override
  String get storageIscsiExtentOldDiskUnavailable =>
      '이전에 선택한 디스크 또는 zvol은 이 서버에서 더 이상 제공되지 않습니다.';

  @override
  String storageIscsiExtentOldDiskUnavailableNotice(Object disk) {
    return '이전 백킹 스토어 $disk를 더 이상 사용할 수 없습니다. 저장하기 전에 현재 디스크 또는 zvol을 선택하세요.';
  }

  @override
  String get storageIscsiExtentPathLabel => '파일 경로';

  @override
  String get storageIscsiExtentPathHelper => '/mnt/ 아래 절대 경로';

  @override
  String get storageIscsiExtentFileAllocateNotice =>
      '파일 익스텐트는 TrueNAS이 백킹 파일을 생성하거나 확장할 때 데이터셋에서 요청된 공간을 할당할 수 있습니다.';

  @override
  String get storageIscsiExtentBackingChangeNotice =>
      '익스텐트 유형 또는 백킹 스토어를 변경하면 타깃 매핑과 연결된 클라이언트 I/O가 중단될 수 있습니다.';

  @override
  String get storageIscsiExtentFilesizeLabel => '파일 크기(바이트)';

  @override
  String get storageIscsiExtentFilesizeHelper => '0은 지원될 때 기존 파일 크기를 사용합니다';

  @override
  String get storageIscsiExtentBlocksizeLabel => '논리 블록 크기';

  @override
  String get storageIscsiExtentRpmLabel => '보고된 드라이브 속도';

  @override
  String get storageIscsiExtentRpmUnknown => '알 수 없음';

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
  String get storageIscsiExtentReadOnlyTitle => '읽기 전용';

  @override
  String get storageIscsiExtentReadOnlySubtitle => '개시자가 이 익스텐트에 쓰지 못하게 합니다.';

  @override
  String get storageIscsiExtentEnabledTitle => '활성화됨';

  @override
  String get storageIscsiExtentEnabledSubtitle => '타깃 매핑이 이 익스텐트를 제시하도록 허용합니다.';

  @override
  String get storageIscsiExtentAdvancedTitle => '고급';

  @override
  String get storageIscsiExtentAdvancedSubtitle => '프로토콜 호환성 및 디바이스 ID';

  @override
  String get storageIscsiExtentPhysicalBlockTitle => '물리 블록 크기 보고';

  @override
  String get storageIscsiExtentPhysicalBlockSubtitle =>
      '논리 블록 크기를 물리 크기로 노출합니다.';

  @override
  String get storageIscsiExtentThresholdLabel => '사용 가능 용량 임계값(%)';

  @override
  String get storageIscsiExtentThresholdHelper => '1에서 99 사이의 선택적 백분율';

  @override
  String get storageIscsiExtentInsecureTpcTitle => '비보안 TPC 허용';

  @override
  String get storageIscsiExtentInsecureTpcSubtitle => '자격 증명 없이 제3자 복사를 허용합니다.';

  @override
  String get storageIscsiExtentXenTitle => 'Xen 호환성';

  @override
  String get storageIscsiExtentXenSubtitle => '레거시 Xen 개시자 호환성을 사용합니다.';

  @override
  String get storageIscsiExtentSerialLabel => '시리얼';

  @override
  String get storageIscsiExtentSerialHelper => '선택적 SCSI 시리얼 번호';

  @override
  String get storageIscsiExtentProductIdLabel => '제품 ID';

  @override
  String get storageIscsiExtentProductIdHelper => '최대 16자의 선택적 SCSI 제품 식별자';

  @override
  String get storageIscsiExtentReviewName => '이름';

  @override
  String get storageIscsiExtentReviewType => '유형';

  @override
  String get storageIscsiExtentReviewBackingStore => '백킹 스토어';

  @override
  String get storageIscsiExtentReviewFilesize => '파일 크기';

  @override
  String storageIscsiExtentReviewFilesizeValue(int count) {
    return '$count 바이트';
  }

  @override
  String get storageIscsiExtentReviewBlocksize => '논리 블록 크기';

  @override
  String storageIscsiExtentReviewBlocksizeValue(int count) {
    return '$count 바이트';
  }

  @override
  String get storageIscsiExtentReviewSpeed => '보고된 속도';

  @override
  String get storageIscsiExtentReviewReadOnly => '읽기 전용';

  @override
  String get storageIscsiExtentReviewEnabled => '활성화됨';

  @override
  String get storageIscsiExtentReviewPhysicalBlock => '물리 블록 크기';

  @override
  String get storageIscsiExtentReviewThreshold => '용량 임계값';

  @override
  String get storageIscsiExtentReviewThresholdNone => '없음';

  @override
  String storageIscsiExtentReviewThresholdValue(int value) {
    return '$value%';
  }

  @override
  String get storageIscsiExtentReviewInsecureTpc => '비보안 TPC';

  @override
  String get storageIscsiExtentReviewXen => 'Xen 호환성';

  @override
  String get storageIscsiExtentReviewSerial => '시리얼';

  @override
  String get storageIscsiExtentReviewSerialAutomatic => '자동';

  @override
  String get storageIscsiExtentReviewProductId => '제품 ID';

  @override
  String get storageIscsiExtentReviewProductIdDefault => '기본값';

  @override
  String get storageIscsiExtentReviewComment => '설명';

  @override
  String get storageIscsiExtentReviewNone => '없음';

  @override
  String get storageIscsiExtentReviewYes => '예';

  @override
  String get storageIscsiExtentReviewNo => '아니오';

  @override
  String get storageIscsiExtentBackingChangedNotice =>
      '이는 익스텐트 유형 또는 백킹 스토어를 변경합니다. 기존 타깃 매핑이 중단될 수 있습니다. 저장 후 매핑된 LUN과 클라이언트 I/O를 확인하세요.';

  @override
  String storageIscsiExtentFileAllocateReviewNotice(Object path, int bytes) {
    return 'TrueNAS이 $path를 사용하고 해당 데이터셋에 $bytes 바이트를 할당할 수 있습니다.';
  }

  @override
  String storageIscsiExtentReviewNoticeEdit(Object name) {
    return 'TrueNAS이 $name에 이 값을 적용합니다. 서버가 업데이트를 거부하지 않는 한 타깃 연결은 유지됩니다.';
  }

  @override
  String get storageIscsiExtentReviewNoticeCreate =>
      'TrueNAS이 이 익스텐트를 생성합니다. 타깃과 LUN에 할당되기 전까지 개시자에게 사용할 수 없습니다.';

  @override
  String get storageIscsiExtentValidationNameLength => '1에서 64자 사이의 이름을 입력하세요.';

  @override
  String get storageIscsiExtentValidationDiskRequired => '디스크 또는 zvol을 선택하세요.';

  @override
  String get storageIscsiExtentValidationDiskUnavailable =>
      '이 서버에서 제공하는 디스크 또는 zvol을 선택하세요.';

  @override
  String get storageIscsiExtentValidationDiskPathConflict =>
      '디스크 익스텐트는 파일 경로를 함께 사용할 수 없습니다.';

  @override
  String get storageIscsiExtentValidationPathRequired =>
      '/mnt/ 아래의 파일 경로를 입력하세요.';

  @override
  String get storageIscsiExtentValidationFileDiskConflict =>
      '파일 익스텐트는 디스크를 함께 사용할 수 없습니다.';

  @override
  String get storageIscsiExtentValidationFileSizeNegative =>
      '음수가 아닌 파일 크기를 입력하세요.';

  @override
  String get storageIscsiExtentValidationFileSizeWholeNumber =>
      '정수 바이트를 입력하세요.';

  @override
  String get storageIscsiExtentValidationBlockSize => '지원되는 블록 크기를 선택하세요.';

  @override
  String get storageIscsiExtentValidationThresholdRange =>
      '1에서 99 퍼센트 사이의 임계값을 입력하세요.';

  @override
  String get storageIscsiExtentValidationThresholdWholeNumber =>
      '정수 백분율을 입력하세요.';

  @override
  String get storageIscsiExtentValidationProductIdLength =>
      '1에서 16자 사이의 제품 ID를 입력하세요.';

  @override
  String get storageIscsiTeReviewTitle => 'iSCSI 연결 검토';

  @override
  String get storageIscsiTeEditTitle => 'iSCSI 연결 편집';

  @override
  String get storageIscsiTeNewTitle => '새 iSCSI 연결';

  @override
  String get storageIscsiTeSubtitle => '타깃과 LUN을 통해 익스텐트 노출';

  @override
  String get storageIscsiTeClose => '닫기';

  @override
  String get storageIscsiTeBack => '뒤로';

  @override
  String get storageIscsiTeCancel => '취소';

  @override
  String get storageIscsiTeReview => '검토';

  @override
  String get storageIscsiTeSaveChanges => '변경 사항 저장';

  @override
  String get storageIscsiTeCreateAssociation => '연결 생성';

  @override
  String get storageIscsiTeTargetLabel => '타깃';

  @override
  String get storageIscsiTeTargetHelper => '클라이언트가 이 iSCSI 타깃을 통해 연결합니다';

  @override
  String get storageIscsiTeExtentLabel => '익스텐트';

  @override
  String get storageIscsiTeExtentHelper => '클라이언트에 제공되는 스토리지';

  @override
  String get storageIscsiTeAutoLunTitle => 'LUN 자동 할당';

  @override
  String get storageIscsiTeAutoLunSubtitle =>
      'TrueNAS이 다음 사용 가능한 LUN ID를 선택하도록 합니다';

  @override
  String get storageIscsiTeLunIdLabel => 'LUN ID';

  @override
  String get storageIscsiTeLunIdHelperEdit => '편집 시 구체적인 음수가 아닌 LUN ID가 필요합니다';

  @override
  String get storageIscsiTeLunIdHelperCreate => '사용 가능한 음수가 아닌 정수를 사용하세요';

  @override
  String get storageIscsiTeMissingResourcesNotice =>
      '저장된 타깃 또는 익스텐트가 이 서버에서 더 이상 제공되지 않습니다. 저장하기 전에 사용 가능한 리소스를 선택하세요.';

  @override
  String get storageIscsiTeReviewTarget => '타깃';

  @override
  String get storageIscsiTeReviewExtent => '익스텐트';

  @override
  String get storageIscsiTeReviewLunId => 'LUN ID';

  @override
  String get storageIscsiTeReviewLunIdAutomatic => '자동';

  @override
  String get storageIscsiTeReviewAccess => '접근';

  @override
  String get storageIscsiTeReviewAccessReadOnly => '읽기 전용';

  @override
  String get storageIscsiTeReviewAccessReadWrite => '읽기 및 쓰기';

  @override
  String get storageIscsiTeImpactTitle => '영향';

  @override
  String get storageIscsiTeImpactNoticeEdit =>
      '저장하면 이 연결이 재할당됩니다. 타깃을 사용하는 클라이언트가 이전 매핑에 대한 접근을 잃고 업데이트된 LUN을 볼 수 있습니다.';

  @override
  String get storageIscsiTeImpactNoticeCreate =>
      '이 연결을 생성하면 타깃에 연결이 허용된 개시자에게 익스텐트가 표시됩니다.';

  @override
  String get storageIscsiTeExposureReadOnly =>
      '이 연결은 인증된 클라이언트에 익스텐트를 읽기 전용 스토리지로 노출합니다.';

  @override
  String get storageIscsiTeExposureReadWrite =>
      '이 연결은 인증된 클라이언트에 익스텐트를 읽기 및 쓰기 접근으로 노출합니다.';

  @override
  String get storageIscsiTeExtentDisabledNotice =>
      '선택한 익스텐트가 비활성화되어 활성화될 때까지 스토리지를 제공하지 않습니다.';

  @override
  String get storageIscsiTeExtentLockedNotice =>
      '선택한 익스텐트가 잠겨 있어 백킹 스토리지가 잠금 해제될 때까지 데이터를 제공할 수 없습니다.';

  @override
  String get storageIscsiTeValidationTargetInvalid => '유효한 iSCSI 타깃을 선택하세요.';

  @override
  String get storageIscsiTeValidationTargetUnavailable =>
      '이 TrueNAS 서버에서 제공하는 타깃을 선택하세요.';

  @override
  String get storageIscsiTeValidationExtentInvalid => '유효한 iSCSI 익스텐트를 선택하세요.';

  @override
  String get storageIscsiTeValidationExtentUnavailable =>
      '이 TrueNAS 서버에서 제공하는 익스텐트를 선택하세요.';

  @override
  String get storageIscsiTeValidationLunidNegative => '음수가 아닌 LUN ID를 사용하세요.';

  @override
  String get storageIscsiTeValidationLunidEmpty => '음수가 아닌 LUN ID를 입력하세요.';

  @override
  String get storageIscsiTeValidationLunidWholeNumber =>
      '정수이고 음수가 아닌 LUN ID를 사용하세요.';

  @override
  String get storageIscsiConfigClose => '닫기';

  @override
  String get storageIscsiConfigBack => '뒤로';

  @override
  String get storageIscsiConfigCancel => '취소';

  @override
  String get storageIscsiConfigReview => '검토';

  @override
  String get storageIscsiPortalReviewTitle => 'iSCSI 포털 검토';

  @override
  String get storageIscsiPortalNewTitle => '새 iSCSI 포털';

  @override
  String get storageIscsiPortalEditTitle => 'iSCSI 포털 편집';

  @override
  String get storageIscsiPortalSubtitle => 'iSCSI 연결을 수신하는 고정 주소';

  @override
  String get storageIscsiPortalCreate => '포털 생성';

  @override
  String get storageIscsiPortalSaveChanges => '변경 사항 저장';

  @override
  String get storageIscsiPortalListenAddresses => '수신 주소';

  @override
  String get storageIscsiPortalListenHelper =>
      'TrueNAS는 포털을 호스팅할 수 있는 고정 주소만 제공합니다.';

  @override
  String get storageIscsiPortalNoAddress =>
      '이 서버는 고정 수신 주소를 반환하지 않았습니다. 포털을 생성하기 전에 고정 인터페이스 주소를 구성하세요.';

  @override
  String storageIscsiPortalUnavailableNotice(Object addresses) {
    return 'TrueNAS는 더 이상 $addresses를 고정 수신 주소로 제공하지 않습니다. 저장하기 전에 현재 주소를 선택하세요.';
  }

  @override
  String get storageIscsiPortalCommentLabel => '설명';

  @override
  String get storageIscsiPortalCommentHelper => '이 포털의 선택적 라벨';

  @override
  String get storageIscsiPortalUpdateNotice =>
      '이 포털을 사용하는 타깃은 TrueNAS이 변경을 적용한 후 업데이트된 주소 집합에서 연결을 수신합니다.';

  @override
  String get storageIscsiPortalReviewListen => '수신 주소';

  @override
  String get storageIscsiPortalReviewPort => '포트';

  @override
  String get storageIscsiPortalReviewPortValue => '3260 (TrueNAS이 관리)';

  @override
  String get storageIscsiPortalReviewComment => '설명';

  @override
  String get storageIscsiPortalReviewNone => '없음';

  @override
  String get storageIscsiPortalReviewNotice =>
      '포털은 네트워크 엔드포인트만 노출합니다. 스토리지를 클라이언트에 사용할 수 있으려면 여전히 타깃, 익스텐트 및 LUN 연결이 필요합니다.';

  @override
  String get storageIscsiPortalValidationListenRequired =>
      '하나 이상의 수신 주소를 선택하세요.';

  @override
  String get storageIscsiPortalValidationListenFormat =>
      '고유하고 유효한 IPv4 또는 IPv6 주소를 사용하세요.';

  @override
  String get storageIscsiPortalValidationListenUnavailable =>
      '이 TrueNAS 서버에서 제공하는 주소만 선택하세요.';

  @override
  String get storageIscsiInitiatorReviewTitle => '개시자 그룹 검토';

  @override
  String get storageIscsiInitiatorNewTitle => '새 개시자 그룹';

  @override
  String get storageIscsiInitiatorEditTitle => '개시자 그룹 편집';

  @override
  String get storageIscsiInitiatorSubtitle => 'iSCSI 타깃에 연결하도록 인증된 클라이언트';

  @override
  String get storageIscsiInitiatorCreate => '그룹 생성';

  @override
  String get storageIscsiInitiatorSaveChanges => '변경 사항 저장';

  @override
  String get storageIscsiInitiatorLabel => '인증된 개시자';

  @override
  String get storageIscsiInitiatorHelper =>
      '한 줄에 하나의 IQN 또는 IP 주소 · 비워 두면 모든 개시자 허용';

  @override
  String get storageIscsiInitiatorCommentLabel => '설명';

  @override
  String get storageIscsiInitiatorCommentHelper => '이 클라이언트 그룹의 선택적 라벨';

  @override
  String get storageIscsiInitiatorUpdateNotice =>
      '이 그룹을 변경하면 이를 참조하는 모든 타깃 그룹에 영향을 미칩니다.';

  @override
  String get storageIscsiInitiatorReviewClients => '인증된 클라이언트';

  @override
  String get storageIscsiInitiatorReviewAll => '모든 개시자';

  @override
  String get storageIscsiInitiatorReviewComment => '설명';

  @override
  String get storageIscsiInitiatorReviewNone => '없음';

  @override
  String get storageIscsiInitiatorAllNotice =>
      '이 그룹은 모든 개시자를 허용합니다. 접근은 여전히 타깃 인증과 네트워크 제어로 제한할 수 있습니다.';

  @override
  String get storageIscsiInitiatorListedNotice =>
      '이 그룹이 타깃에 할당되면 TrueNAS은 나열된 IQN 또는 IP 주소만 인증합니다.';

  @override
  String get storageIscsiInitiatorValidationFormat =>
      '공백 없이 고유한 IQN 또는 IP 주소를 사용하세요.';

  @override
  String get appsInstallReviewTitle => '설치 검토';

  @override
  String appsInstallReconfigureTitle(Object name) {
    return '$name 재구성';
  }

  @override
  String appsInstallInstallTitle(Object title) {
    return '$title 설치';
  }

  @override
  String appsInstallSubtitle(Object train, Object version) {
    return '$train · $version';
  }

  @override
  String get appsInstallClose => '닫기';

  @override
  String get appsInstallBack => '뒤로';

  @override
  String get appsInstallCancel => '취소';

  @override
  String get appsInstallReview => '검토';

  @override
  String get appsInstallReconfigureAction => '앱 재구성';

  @override
  String get appsInstallInstallAction => '앱 설치';

  @override
  String get appsInstallDefaultGroup => '구성';

  @override
  String get appsValidationNameFormat => '1~40자의 소문자, 숫자 또는 내부 하이픈을 사용하세요.';

  @override
  String get appsValidationUnsupportedField => '이 카탈로그 필드 유형은 지원되지 않습니다.';

  @override
  String get appsValidationFieldRequired => '이 필드는 필수입니다.';

  @override
  String get appsValidationWholeNumber => '정수를 입력하세요.';

  @override
  String appsValidationMinimumValue(int bound) {
    return '최솟값은 $bound입니다.';
  }

  @override
  String appsValidationMaximumValue(int bound) {
    return '최댓값은 $bound입니다.';
  }

  @override
  String appsValidationMinimumLength(int bound) {
    return '$bound자 이상 입력하세요.';
  }

  @override
  String appsValidationMaximumLength(int bound) {
    return '$bound자 이하로 입력하세요.';
  }

  @override
  String get appsValidationAbsolutePath => '/로 시작하는 절대 경로를 입력하세요.';

  @override
  String get appsValidationUriScheme => '스킴이 포함된 URI를 입력하세요.';

  @override
  String get appsValidationIpAddress => '유효한 IPv4 또는 IPv6 주소를 입력하세요.';

  @override
  String get appsValidationChooseOption => '사용 가능한 값 중 하나를 선택하세요.';

  @override
  String appsValidationMinimumItems(int bound) {
    return '항목을 $bound개 이상 추가하세요.';
  }

  @override
  String appsValidationMaximumItems(int bound) {
    return '항목을 $bound개 이하로 사용하세요.';
  }

  @override
  String get appsValidationListNoSchema => '이 목록에는 편집 가능한 항목 스키마가 없습니다.';

  @override
  String get appsValidationItemRequired => '이 항목은 필수입니다.';

  @override
  String get appsValidationItemWholeNumber => '정수를 입력하세요.';

  @override
  String get appsInstallInstanceInfoLabel => '앱 인스턴스';

  @override
  String get appsInstallInstanceNameLabel => '앱 인스턴스 이름';

  @override
  String get appsInstallInstanceNameHelper => '소문자, 숫자 및 내부 하이픈';

  @override
  String get appsInstallCatalogVersionLabel => '카탈로그 버전';

  @override
  String get appsInstallVersionUnavailableSuffix => ' · 사용 불가';

  @override
  String get appsInstallVersionUnsupported => '이 카탈로그 버전은 연결된 서버에서 지원되지 않습니다.';

  @override
  String get appsInstallNoQuestions => '이 앱은 카탈로그 기본값을 사용하며 추가 구성이 필요하지 않습니다.';

  @override
  String get appsInstallReviewServerAction => '서버 작업';

  @override
  String get appsInstallReviewActionReconfigure => '앱 재구성';

  @override
  String get appsInstallReviewActionInstall => '카탈로그 앱 설치';

  @override
  String get appsInstallReviewApp => '앱';

  @override
  String get appsInstallReviewInstance => '인스턴스';

  @override
  String get appsInstallReviewTrain => '트레인';

  @override
  String get appsInstallReviewVersion => '버전';

  @override
  String get appsInstallReviewNoticeUpdate =>
      'TrueNAS이 구성을 다시 검증하고 새 값으로 앱 컨테이너를 재생성합니다. TrueNAS 작업이 완료될 때까지 사용자는 접근할 수 없습니다.';

  @override
  String get appsInstallReviewNoticeInstall =>
      'TrueNAS이 구성을 검증하고 컨테이너 이미지를 가져오며 앱 스토리지를 만들고 백그라운드 작업으로 워크로드를 시작합니다.';

  @override
  String get appsInstallSecretsNotice =>
      '민감한 값은 마스킹되며 연결된 TrueNAS 서버로만 전송됩니다. TrueDock은 이 설치 양식을 저장하지 않습니다.';

  @override
  String get appsInstallListNoItemType => '이 카탈로그 목록은 항목 유형을 설명하지 않습니다.';

  @override
  String get appsInstallRemoveItem => '항목 제거';

  @override
  String get appsInstallAddItem => '항목 추가';

  @override
  String get appsInstallSelect => '선택';

  @override
  String appsInstallOptionCount(int count) {
    return '옵션 $count개';
  }

  @override
  String get appsInstallOptionSearch => '옵션 검색';

  @override
  String get appsInstallNoMatchingOptions => '일치하는 옵션이 없습니다.';

  @override
  String get jobsFilterActive => '진행 중';

  @override
  String get jobsActiveDialogTitle => '실행 중인 작업';

  @override
  String jobsActiveFabTooltip(int count) {
    return '실행 중인 작업 $count개';
  }

  @override
  String get jobsFilterFailed => '실패';

  @override
  String get jobsFilterCompleted => '완료됨';

  @override
  String get jobsFilterAll => '전체';

  @override
  String jobsFilterChipLabel(Object label, int count) {
    return '$label ($count)';
  }

  @override
  String get jobsEmptyActive => '실행 중인 작업이 없습니다.';

  @override
  String get jobsEmptyFailed => '실패한 작업이 보고되지 않았습니다.';

  @override
  String get jobsEmptyCompleted => '완료된 작업이 보고되지 않았습니다.';

  @override
  String get jobsEmptyAll => '작업을 찾을 수 없습니다.';

  @override
  String get jobsAbortDialogTitle => '이 작업을 중단할까요?';

  @override
  String jobsAbortDialogBody(int id, Object method) {
    return 'TrueDock이 서버에 작업 $id($method) 중단을 요청합니다. 작업이 이미 수행한 내용은 롤백되지 않으며, 중단이 처리되기 전에 서버가 작업을 완료할 수 있습니다.';
  }

  @override
  String jobsAbortTarget(int id, Object method) {
    return '작업 $id ($method)';
  }

  @override
  String get jobsAbortConsequenceNoRollback => '작업이 이미 수행한 부분은 되돌아가지 않습니다.';

  @override
  String get jobsAbortConsequenceRace => '서버가 중단 요청을 처리하기 전에 작업을 끝낼 수도 있습니다.';

  @override
  String get jobsAbortKeepRunning => '계속 실행';

  @override
  String get jobsAbortConfirm => '작업 중단';

  @override
  String get jobsAbortFailed => '중단 요청이 실패했습니다.';

  @override
  String jobsAbortRequested(int id) {
    return '작업 $id에 대한 중단을 요청했습니다.';
  }

  @override
  String get jobsAbortTooltip => '작업 중단';

  @override
  String get jobsDetailJobId => '작업 ID';

  @override
  String get jobsDetailMethod => 'API 메서드';

  @override
  String get jobsMethodPoolScrub => '풀 스크럽';

  @override
  String get jobsMethodPoolCreate => '풀 생성';

  @override
  String get jobsMethodPoolExport => '풀 내보내기';

  @override
  String get jobsMethodDatasetCreate => '데이터셋 생성';

  @override
  String get jobsMethodDatasetUpdate => '데이터셋 수정';

  @override
  String get jobsMethodDatasetDelete => '데이터셋 삭제';

  @override
  String get jobsMethodSnapshotCreate => '스냅샷 생성';

  @override
  String get jobsMethodSnapshotDelete => '스냅샷 삭제';

  @override
  String get jobsMethodSnapshotRollback => '스냅샷 롤백';

  @override
  String get jobsMethodSnapshotClone => '스냅샷 복제';

  @override
  String get jobsMethodSetAcl => 'ACL 설정';

  @override
  String get jobsMethodAppInstall => '앱 설치';

  @override
  String get jobsMethodAppUpgrade => '앱 업그레이드';

  @override
  String get jobsMethodAppRollback => '앱 롤백';

  @override
  String get jobsMethodAppDelete => '앱 삭제';

  @override
  String get jobsMethodReplicationRun => '복제 실행';

  @override
  String get jobsMethodCloudSyncRun => '클라우드 동기화 실행';

  @override
  String get jobsMethodRsyncRun => 'Rsync 실행';

  @override
  String get jobsMethodSystemUpdate => '시스템 업데이트';

  @override
  String get jobsMethodSystemReboot => '시스템 재시작';

  @override
  String get jobsMethodSystemShutdown => '시스템 종료';

  @override
  String get jobsMethodUnknown => 'TrueNAS 작업';

  @override
  String get jobsDetailState => '상태';

  @override
  String get jobsDetailProgress => '진행률';

  @override
  String get jobsDetailStep => '단계';

  @override
  String get jobsDetailStarted => '시작';

  @override
  String get jobsDetailFinished => '종료';

  @override
  String get jobsDetailDuration => '소요 시간';

  @override
  String get jobsDetailLogExcerpt => '로그 발췌';

  @override
  String get jobsNotAbortable =>
      '이 작업은 TrueDock에서 중단할 수 없습니다. 서버가 중단 가능으로 보고하지 않았습니다.';

  @override
  String get jobsStateRunning => '실행 중';

  @override
  String get jobsStateWaiting => '대기 중';

  @override
  String get jobsStateSucceeded => '성공';

  @override
  String get jobsStateFailed => '실패';

  @override
  String get jobsStateAborted => '중단됨';

  @override
  String get storageSectionPools => '풀';

  @override
  String get storageSectionCreatePool => '풀 생성';

  @override
  String get storageSectionNoPools => '스토리지 풀을 찾을 수 없습니다.';

  @override
  String get storageSectionDatasets => '데이터셋';

  @override
  String get storageSectionCreateDataset => '데이터셋 생성';

  @override
  String get storageSectionNoDatasets => '데이터셋을 찾을 수 없습니다.';

  @override
  String get storageSnapshotCreated => '스냅샷을 생성했습니다.';

  @override
  String get storageSectionDisks => '디스크';

  @override
  String get storageSectionNoDisks => '디스크를 찾을 수 없습니다.';

  @override
  String get storageSectionShares => '공유';

  @override
  String get storageSmbPurposeReadOnly =>
      '레거시 또는 서버별 SMB 용도는 TrueDock에서 읽기 전용입니다.';

  @override
  String get storageNoSharesFound => '지원되는 공유 또는 iSCSI 리소스를 찾을 수 없습니다.';

  @override
  String get storageScanScrubInProgress => '스크럽 진행 중';

  @override
  String get storageScanResilverInProgress => '리실버 진행 중';

  @override
  String get storageCreateShort => '생성';

  @override
  String get storageDiskSolidState => 'SSD';

  @override
  String get storageDiskUnavailable => '사용 불가';

  @override
  String get storageEditSmbPermissions => 'SMB 권한 편집';

  @override
  String get storageEditSharePermissions => '공유 권한 편집';

  @override
  String get storageDeleteShareTooltip => '공유 삭제';

  @override
  String get storageDeleteExtentTooltip => '익스텐트 삭제';

  @override
  String get storageDeleteTooltip => '삭제';

  @override
  String storageIscsiLunSubtitle(Object lun) {
    return 'iSCSI LUN · $lun';
  }

  @override
  String get storageLunAutomatic => '자동';

  @override
  String get storageBadgeLocked => '잠김';

  @override
  String get storageBadgeEnabled => '활성';

  @override
  String get storageBadgeDisabled => '비활성';

  @override
  String get storageDeleteExtentSheetTitle => '익스텐트 삭제';

  @override
  String get storageDeleteExtentAlsoDestroy => '백킹 스토리지도 파기';

  @override
  String get storageDetailTarget => '타깃';

  @override
  String get storageDetailMode => '모드';

  @override
  String get storageDetailGroups => '그룹';

  @override
  String get storageDetailType => '유형';

  @override
  String get storageDetailBacking => '백킹';

  @override
  String get storageDetailCapacity => '용량';

  @override
  String get storageDetailBlockSize => '블록 크기';

  @override
  String storageDetailBlockSizeValue(int bytes) {
    return '$bytes B';
  }

  @override
  String get storageDetailAccess => '접근';

  @override
  String get storageDetailAccessReadOnly => '읽기 전용';

  @override
  String get storageDetailAccessReadWrite => '읽기 및 쓰기';

  @override
  String get storageDetailState => '상태';

  @override
  String get storageDetailStateLocked => '잠김';

  @override
  String get storageDetailStateEnabled => '활성화됨';

  @override
  String get storageDetailStateDisabled => '비활성화됨';

  @override
  String get storageCreateSnapshotTitle => '스냅샷 생성';

  @override
  String get storageSnapshotNameLabel => '스냅샷 이름';

  @override
  String get storageSnapshotCreating => '생성 중…';

  @override
  String get storageActionFailed => 'TrueNAS 작업이 실패했습니다.';

  @override
  String get storageServerFallbackName => '이 TrueNAS 서버';

  @override
  String storageAclConfirmTitle(Object name) {
    return '$name의 권한을 교체할까요?';
  }

  @override
  String get storageAclConfirmAction => '권한 교체';

  @override
  String storageAclConfirmRules(int count) {
    return '전체 목록이 기존 ACL을 교체합니다. TrueNAS 작업이 완료되면 규칙 $count개가 적용됩니다.';
  }

  @override
  String get storageAclConfirmUnlisted =>
      '현재 공유에 접근하지만 목록에 없는 클라이언트는 접근 권한을 잃습니다.';

  @override
  String get storageDeleteDatasetTitle => '데이터셋을 삭제할까요?';

  @override
  String get storageDeleteDatasetAction => '데이터셋 삭제';

  @override
  String storageDeleteDatasetData(Object size) {
    return '이 데이터셋의 데이터 $size 전체가 파기되며 복구할 수 없습니다.';
  }

  @override
  String storageDeleteDatasetChildren(int count) {
    return '하위 데이터셋 $count개도 함께 파기됩니다.';
  }

  @override
  String storageDeleteDatasetSnapshots(int count) {
    return '이 경로의 스냅샷 $count개가 파기됩니다.';
  }

  @override
  String storageDeleteDatasetShares(int count, Object path) {
    return '공유 $count개가 $path를 가리키고 있으며 데이터 제공을 중단합니다.';
  }

  @override
  String get storageDeleteDatasetNoteLeaf => '이 경로에 쓰는 애플리케이션이 실패하기 시작합니다.';

  @override
  String get storageDeleteDatasetNoteRecursive =>
      '하위 데이터셋이 재귀적으로 제거되며, 사용 중인 데이터셋은 삭제를 진행할 수 있도록 마운트 해제됩니다.';

  @override
  String get storageDeleteSmbTitle => 'SMB 공유를 삭제할까요?';

  @override
  String get storageDeleteShareAction => '공유 삭제';

  @override
  String get storageDeleteSmbClients => '연결된 SMB 클라이언트는 즉시 접근 권한을 잃습니다.';

  @override
  String get storageDeleteSmbConfig => 'ACL을 포함한 공유 구성이 제거됩니다.';

  @override
  String get storageDeleteShareNote => '데이터셋과 그 파일은 삭제되지 않습니다.';

  @override
  String get storageDeleteNfsTitle => 'NFS 공유를 삭제할까요?';

  @override
  String get storageDeleteNfsClients => '이 내보내기를 마운트한 NFS 클라이언트는 접근 권한을 잃습니다.';

  @override
  String get storageDeleteNfsRules => '내보내기의 호스트, 네트워크 및 매핑 규칙이 제거됩니다.';

  @override
  String storageIscsiPortalFallbackLabel(int tag) {
    return '포털 $tag';
  }

  @override
  String get storageDeletePortalTitle => 'iSCSI 포털을 삭제할까요?';

  @override
  String get storageDeletePortalAction => '포털 삭제';

  @override
  String get storageDeletePortalInitiators =>
      '이 주소를 통해 타깃에 접근하던 개시자의 연결이 끊깁니다.';

  @override
  String get storageDeleteIscsiInUse => '타깃이 아직 사용 중이면 TrueNAS이 삭제를 거부합니다.';

  @override
  String get storageDeletePortalNote => '익스텐트와 그 백킹 스토리지는 영향을 받지 않습니다.';

  @override
  String storageIscsiInitiatorFallbackLabel(int id) {
    return '개시자 그룹 $id';
  }

  @override
  String get storageDeleteInitiatorTitle => '개시자 그룹을 삭제할까요?';

  @override
  String get storageDeleteInitiatorAction => '그룹 삭제';

  @override
  String get storageDeleteInitiatorAllowList => '이 그룹으로 제한된 타깃은 허용 목록을 잃습니다.';

  @override
  String get storageDeleteTargetTitle => 'iSCSI 타깃을 삭제할까요?';

  @override
  String get storageDeleteTargetAction => '타깃 삭제';

  @override
  String get storageDeleteTargetInitiators =>
      '연결된 개시자가 즉시 블록 디바이스를 잃게 되어 진행 중인 쓰기가 손상될 수 있습니다.';

  @override
  String storageDeleteTargetLuns(int count) {
    return '타깃과 함께 LUN 연결 $count개가 제거됩니다.';
  }

  @override
  String get storageDeleteTargetNote => '익스텐트는 데이터를 유지하며 다른 타깃에 연결할 수 있습니다.';

  @override
  String get storageDestroyExtentTitle => '익스텐트 데이터를 파기할까요?';

  @override
  String get storageDeleteExtentTitle => 'iSCSI 익스텐트를 삭제할까요?';

  @override
  String get storageDeleteExtentDestroyAction => '삭제 및 파기';

  @override
  String get storageDeleteExtentAction => '익스텐트 삭제';

  @override
  String storageDeleteExtentBackingDestroyed(Object type, Object store) {
    return '백킹 $type $store이(가) 파기되며 복구할 수 없습니다.';
  }

  @override
  String get storageDeleteExtentBackingKept => '익스텐트는 제거되지만 백킹 스토리지는 유지됩니다.';

  @override
  String storageDeleteExtentLuns(int count) {
    return '익스텐트와 함께 LUN 연결 $count개가 제거됩니다.';
  }

  @override
  String get storageDeleteExtentInitiators =>
      '이 LUN을 사용하는 개시자는 즉시 블록 디바이스를 잃습니다.';

  @override
  String storageIscsiAssociationLabel(int targetId, int extentId) {
    return '타깃 $targetId → 익스텐트 $extentId';
  }

  @override
  String get storageRemoveLunTitle => 'LUN 연결을 제거할까요?';

  @override
  String get storageRemoveLunAction => '연결 제거';

  @override
  String get storageRemoveLunDisappears =>
      'LUN이 타깃에서 사라지고 개시자는 해당 블록 디바이스를 잃습니다.';

  @override
  String get storageRemoveLunExtentKept => '익스텐트와 그 데이터는 유지되며 다시 연결할 수 있습니다.';

  @override
  String get storageLockDatasetTitle => '데이터셋을 잠글까요?';

  @override
  String get storageLockDatasetAction => '데이터셋 잠금';

  @override
  String get storageLockDatasetKey =>
      '암호화 키가 제거되어 다시 잠금 해제할 때까지 데이터를 읽을 수 없습니다.';

  @override
  String storageLockDatasetChildren(int count) {
    return '이 키를 공유하는 하위 데이터셋 $count개도 함께 잠깁니다.';
  }

  @override
  String storageLockDatasetShares(int count) {
    return '이 경로의 공유 $count개가 데이터 제공을 중단합니다.';
  }

  @override
  String get storageLockDatasetNotePassphrase => '다시 잠금 해제하려면 암호가 필요합니다.';

  @override
  String get storageLockDatasetNoteKey => '다시 잠금 해제하려면 16진수 키가 필요합니다.';

  @override
  String storagePromoteTitle(Object name) {
    return '$name을(를) 승격할까요?';
  }

  @override
  String get storagePromoteAction => '복제본 승격';

  @override
  String storagePromoteOwnership(Object name, Object origin) {
    return '$name이(가) $origin에 대한 의존을 중단하고 공유하던 데이터의 소유권을 가져옵니다.';
  }

  @override
  String storagePromoteReverses(Object originDataset, Object origin) {
    return '의존 관계가 역전됩니다. $originDataset이(가) 의존 데이터셋이 되므로 이후 $origin과 그 이전 스냅샷을 삭제할 수 있습니다.';
  }

  @override
  String get storagePromoteSpace =>
      '데이터가 복사되거나 삭제되지는 않지만, 이전에 원본에 청구되던 공간이 이후 이 데이터셋에 청구됩니다.';

  @override
  String storageCreatePoolTitle(Object name) {
    return '풀 $name을(를) 생성할까요?';
  }

  @override
  String get storageCreatePoolAction => '풀 생성';

  @override
  String storageCreatePoolDisks(int count) {
    return '디스크 $count개가 포맷됩니다. 해당 디스크의 기존 데이터는 복구할 수 없습니다.';
  }

  @override
  String get storageCreatePoolNoRedundancy =>
      '이 풀에는 중복성이 없습니다. 디스크 하나만 고장 나도 풀 전체를 잃습니다.';

  @override
  String get storageCreatePoolEncrypted =>
      '풀이 저장 시 암호화됩니다. 복구 키를 안전하게 보관하지 않으면 데이터를 복구할 수 없습니다.';

  @override
  String get storageCreatePoolNote => '이 작업은 파괴적이며 되돌릴 수 없습니다.';

  @override
  String get storageStopScrubTitle => '스크럽을 중지할까요?';

  @override
  String get storageStopScrubAction => '스크럽 중지';

  @override
  String get storageStopScrubProgress => '스크럽 진행 상황이 폐기되며 처음부터 다시 시작해야 합니다.';

  @override
  String get storageStopScrubUnverified =>
      '아직 검증되지 않은 블록은 다음 실행까지 확인되지 않은 상태로 남습니다.';

  @override
  String get storageScrubActionPause => '스크럽 일시 중지';

  @override
  String get storageScrubActionResume => '스크럽 재개';

  @override
  String get storageScrubActionStop => '스크럽 중지';

  @override
  String storageOfflineTitle(Object name) {
    return '$name을(를) 오프라인으로 전환할까요?';
  }

  @override
  String get storageOfflineAction => '오프라인으로 전환';

  @override
  String storageOfflineDegraded(Object pool) {
    return '$pool이(가) 성능 저하 상태로 실행되며 이 디바이스가 제공하던 중복성을 잃습니다.';
  }

  @override
  String get storageOfflineSecondFailure =>
      '성능 저하 상태에서 디바이스가 하나 더 고장 나면 풀 전체를 잃을 수 있습니다.';

  @override
  String get storageOfflineNote => '가능한 한 빨리 디바이스를 다시 온라인으로 전환하거나 교체하세요.';

  @override
  String storageAttachTitle(Object disk) {
    return '$disk을(를) 풀 멤버에 연결할까요?';
  }

  @override
  String get storageAttachAction => '디스크 연결';

  @override
  String get storageAttachResilver =>
      '미러에 연결하면 리실버가 시작됩니다. 풀은 온라인 상태를 유지하지만 완료될 때까지 디스크 대역폭을 사용합니다.';

  @override
  String storageAttachJoins(Object disk, Object pool) {
    return '$disk이(가) $pool의 선택한 vdev에 합류하며 더 이상 스페어나 다른 풀에 사용할 수 없습니다.';
  }

  @override
  String get storageAttachNote => '리실버가 완료될 때까지 풀을 온라인 상태로 유지하세요.';

  @override
  String storageReplaceTitle(Object member, Object disk) {
    return '$member을(를) $disk(으)로 교체할까요?';
  }

  @override
  String get storageReplaceAction => '디스크 교체';

  @override
  String get storageReplaceResilver =>
      '리실버가 새 디스크로 데이터를 복사합니다. 풀은 온라인 상태를 유지하지만 리실버가 끝날 때까지 성능 저하 상태로 실행됩니다.';

  @override
  String storageReplaceRemoved(Object member, Object pool) {
    return '리실버가 완료되면 $member이(가) $pool에서 제거되며 안전하게 분리할 수 있습니다.';
  }

  @override
  String get storageReplaceForce =>
      '강제 실행하면 아직 읽는 중이더라도 이전 디스크를 제거합니다. 디스크가 고장 난 경우에만 사용하세요.';

  @override
  String get storageReplaceNote => '리실버가 끝날 때까지 이전 디스크를 제거하지 마세요.';

  @override
  String get storageDestroyPoolTitle => '풀을 파기할까요?';

  @override
  String get storageExportPoolTitle => '풀을 내보낼까요?';

  @override
  String get storageDestroyPoolAction => '풀 파기';

  @override
  String get storageExportPoolAction => '풀 내보내기';

  @override
  String storageDestroyPoolWiped(Object pool, Object size) {
    return '$pool의 모든 디스크가 지워집니다. 데이터 $size을(를) 복구할 수 없습니다.';
  }

  @override
  String get storageExportPoolDetached =>
      '풀이 이 서버에서 분리됩니다. 디스크는 데이터를 유지하며 다시 가져올 수 있습니다.';

  @override
  String storageExportPoolDatasets(int count) {
    return '데이터셋 $count개가 즉시 제공을 중단합니다.';
  }

  @override
  String get storageExportPoolSharesDeleted => '이 풀을 참조하는 공유와 작업이 삭제됩니다.';

  @override
  String get storageDestroyPoolNote => '이 작업은 되돌릴 수 없으며 복구 방법도 없습니다.';

  @override
  String get storageExportPoolNote => '이 풀을 사용하는 애플리케이션과 공유가 실패하기 시작합니다.';

  @override
  String storagePoolFailedCreate(Object name) {
    return 'TrueNAS이 $name을(를) 생성하지 못했습니다.';
  }

  @override
  String storagePoolSuccessCreate(Object name) {
    return '$name을(를) 생성하는 중입니다.';
  }

  @override
  String storagePoolFailedScrub(Object pool) {
    return 'TrueNAS이 $pool의 스크럽을 변경하지 못했습니다.';
  }

  @override
  String storagePoolSuccessScrubStarted(Object pool) {
    return '$pool의 스크럽을 시작했습니다.';
  }

  @override
  String storagePoolSuccessScrubAction(Object action, Object pool) {
    return '$pool에 대해 $action을(를) 요청했습니다.';
  }

  @override
  String storagePoolFailedOnline(Object name) {
    return 'TrueNAS이 $name을(를) 온라인으로 전환하지 못했습니다.';
  }

  @override
  String storagePoolFailedOffline(Object name) {
    return 'TrueNAS이 $name을(를) 오프라인으로 전환하지 못했습니다.';
  }

  @override
  String storagePoolSuccessOnline(Object name) {
    return '$name이(가) 다시 온라인으로 전환되는 중입니다.';
  }

  @override
  String storagePoolSuccessOffline(Object name) {
    return '$name을(를) 오프라인으로 전환했습니다.';
  }

  @override
  String storagePoolFailedAttach(Object disk, Object pool) {
    return 'TrueNAS이 $disk을(를) $pool에 연결하지 못했습니다.';
  }

  @override
  String storagePoolSuccessAttach(Object disk, Object pool) {
    return '$pool의 $disk에 대한 리실버를 시작했습니다.';
  }

  @override
  String storagePoolFailedReplace(Object member, Object pool) {
    return 'TrueNAS이 $pool의 $member을(를) 교체하지 못했습니다.';
  }

  @override
  String storagePoolSuccessReplace(Object disk, Object pool) {
    return '$pool의 $disk(으)로 리실버를 시작했습니다.';
  }

  @override
  String storagePoolFailedExport(Object pool) {
    return 'TrueNAS이 $pool을(를) 내보내지 못했습니다.';
  }

  @override
  String storagePoolSuccessDestroying(Object pool) {
    return '$pool을(를) 파기하는 중입니다.';
  }

  @override
  String storagePoolSuccessExporting(Object pool) {
    return '$pool을(를) 내보내는 중입니다.';
  }

  @override
  String get storageChapCreateTitle => 'CHAP 자격 증명을 생성할까요?';

  @override
  String get storageChapCreateAction => '자격 증명 생성';

  @override
  String get storageChapCreateStored =>
      '새 CHAP 사용자와 비밀값이 서버에 저장됩니다. 타깃 그룹이 이 자격 증명을 참조하면 개시자가 이를 사용해 인증할 수 있습니다.';

  @override
  String get storageChapCreateMutual => '상호 CHAP은 피어 사용자와 피어 비밀값도 저장합니다.';

  @override
  String get storageChapCreateNote =>
      '비밀값은 이 세션을 통해서만 전송되며 TrueDock이 저장하거나 로깅하지 않습니다.';

  @override
  String storageChapUpdateTitle(Object user) {
    return '$user의 변경 사항을 저장할까요?';
  }

  @override
  String get storageChapUpdateAction => '변경 사항 저장';

  @override
  String get storageChapUpdateImmediate =>
      '이 자격 증명을 참조하는 타깃 그룹은 업데이트된 사용자와 비밀값을 즉시 사용하기 시작합니다. 개시자도 일치하도록 재구성하지 않으면 인증에 실패합니다.';

  @override
  String get storageChapUpdateRotated => 'CHAP 비밀값이 입력한 새 값으로 교체됩니다.';

  @override
  String get storageChapUpdateNoteRotating =>
      '새 비밀값은 이 세션을 통해서만 전송되며 TrueDock이 저장하거나 로깅하지 않습니다.';

  @override
  String get storageChapUpdateNoteUnchanged => '기존 비밀값은 서버에서 변경되지 않고 유지됩니다.';

  @override
  String storageChapDeleteTitle(Object user) {
    return 'CHAP 자격 증명 $user을(를) 삭제할까요?';
  }

  @override
  String get storageChapDeleteAction => '자격 증명 삭제';

  @override
  String get storageChapDeleteAuth =>
      '태그로 이 자격 증명을 참조하는 타깃 그룹은 인증을 잃습니다. 이 사용자를 제시하는 개시자는 거부됩니다.';

  @override
  String get storageChapDeleteSecret => '저장된 비밀값이 서버에서 제거됩니다.';

  @override
  String get storageChapDeleteNote =>
      '삭제하기 전에 이 태그를 사용하는 타깃 그룹을 업데이트하거나 제거하세요.';

  @override
  String storageDatasetFailedUpdate(Object name) {
    return 'TrueNAS이 $name을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageDatasetSuccessUpdate(Object name) {
    return '$name을(를) 업데이트했습니다.';
  }

  @override
  String storageDatasetFailedRename(Object name) {
    return 'TrueNAS이 $name의 이름을 변경하지 못했습니다.';
  }

  @override
  String storageDatasetSuccessRename(Object name) {
    return '$name(으)로 이름을 변경했습니다.';
  }

  @override
  String storageDatasetFailedDelete(Object name) {
    return 'TrueNAS이 $name을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageDatasetSuccessDelete(Object name) {
    return '$name을(를) 삭제했습니다.';
  }

  @override
  String storageDatasetFailedLock(Object name) {
    return 'TrueNAS이 $name을(를) 잠그지 못했습니다.';
  }

  @override
  String storageDatasetSuccessLock(Object name) {
    return '$name을(를) 잠갔습니다.';
  }

  @override
  String storageDatasetFailedPromote(Object name) {
    return 'TrueNAS이 $name을(를) 승격하지 못했습니다.';
  }

  @override
  String storageDatasetSuccessPromote(Object name) {
    return '$name을(를) 승격했습니다.';
  }

  @override
  String storageDatasetFailedUnlock(Object name) {
    return 'TrueNAS이 $name의 잠금을 해제하지 못했습니다.';
  }

  @override
  String storageDatasetSuccessUnlock(Object name) {
    return '$name의 잠금을 해제했습니다.';
  }

  @override
  String get storageSmbFailedLoadPresets => 'TrueNAS이 SMB 프리셋을 불러오지 못했습니다.';

  @override
  String get storageSmbFailedValidate => 'TrueNAS이 SMB 공유를 검증하지 못했습니다.';

  @override
  String get storageSmbFailedLoadAcl => 'TrueNAS이 공유 권한을 불러오지 못했습니다.';

  @override
  String storageSmbFailedCreate(Object name) {
    return 'TrueNAS이 $name을(를) 생성하지 못했습니다.';
  }

  @override
  String storageSmbSuccessCreate(Object name) {
    return 'SMB 공유 $name을(를) 생성했습니다.';
  }

  @override
  String storageSmbFailedUpdate(Object name) {
    return 'TrueNAS이 $name을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageSmbSuccessUpdate(Object name) {
    return 'SMB 공유 $name을(를) 업데이트했습니다.';
  }

  @override
  String get storageSmbFailedSetAcl => 'TrueNAS이 SMB 공유 권한을 교체하지 못했습니다.';

  @override
  String storageSmbSuccessSetAcl(Object name) {
    return '$name의 권한을 교체했습니다.';
  }

  @override
  String storageSmbFailedDelete(Object name) {
    return 'TrueNAS이 $name을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageSmbSuccessDelete(Object name) {
    return 'SMB 공유 $name을(를) 삭제했습니다.';
  }

  @override
  String storageNfsFailedCreate(Object path) {
    return 'TrueNAS이 $path을(를) 생성하지 못했습니다.';
  }

  @override
  String storageNfsSuccessCreate(Object path) {
    return 'NFS 공유 $path을(를) 생성했습니다.';
  }

  @override
  String storageNfsFailedUpdate(Object path) {
    return 'TrueNAS이 $path을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageNfsSuccessUpdate(Object path) {
    return 'NFS 공유 $path을(를) 업데이트했습니다.';
  }

  @override
  String storageNfsFailedDelete(Object path) {
    return 'TrueNAS이 $path을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageNfsSuccessDelete(Object path) {
    return 'NFS 공유 $path을(를) 삭제했습니다.';
  }

  @override
  String get storageIscsiFailedLoadPortals => 'TrueNAS이 포털 주소를 불러오지 못했습니다.';

  @override
  String get storageIscsiFailedValidateTarget => 'TrueNAS이 타깃 이름을 검증하지 못했습니다.';

  @override
  String get storageIscsiFailedLoadExtents => 'TrueNAS이 익스텐트 선택지를 불러오지 못했습니다.';

  @override
  String get storageIscsiFailedCreatePortal => 'TrueNAS이 iSCSI 포털을 생성하지 못했습니다.';

  @override
  String get storageIscsiSuccessCreatePortal => 'iSCSI 포털을 생성했습니다.';

  @override
  String storageIscsiFailedUpdatePortal(int tag) {
    return 'TrueNAS이 포털 $tag을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdatePortal(int tag) {
    return '포털 $tag을(를) 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedDeletePortal(Object label) {
    return 'TrueNAS이 $label을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessDeletePortal(Object label) {
    return '$label을(를) 삭제했습니다.';
  }

  @override
  String get storageIscsiFailedCreateInitiator =>
      'TrueNAS이 개시자 그룹을 생성하지 못했습니다.';

  @override
  String get storageIscsiSuccessCreateInitiator => '개시자 그룹을 생성했습니다.';

  @override
  String storageIscsiFailedUpdateInitiator(int id) {
    return 'TrueNAS이 개시자 그룹 $id을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdateInitiator(int id) {
    return '개시자 그룹 $id을(를) 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedDeleteInitiator(Object label) {
    return 'TrueNAS이 $label을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessDeleteInitiator(Object label) {
    return '$label을(를) 삭제했습니다.';
  }

  @override
  String storageIscsiFailedCreateTarget(Object name) {
    return 'TrueNAS이 타깃 $name을(를) 생성하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessCreateTarget(Object name) {
    return '타깃 $name을(를) 생성했습니다.';
  }

  @override
  String storageIscsiFailedUpdateTarget(Object name) {
    return 'TrueNAS이 타깃 $name을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdateTarget(Object name) {
    return '타깃 $name을(를) 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedDeleteTarget(Object name) {
    return 'TrueNAS이 $name을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessDeleteTarget(Object name) {
    return '타깃 $name을(를) 삭제했습니다.';
  }

  @override
  String storageIscsiFailedCreateExtent(Object name) {
    return 'TrueNAS이 익스텐트 $name을(를) 생성하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessCreateExtent(Object name) {
    return '익스텐트 $name을(를) 생성했습니다.';
  }

  @override
  String storageIscsiFailedUpdateExtent(Object name) {
    return 'TrueNAS이 익스텐트 $name을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdateExtent(Object name) {
    return '익스텐트 $name을(를) 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedDeleteExtent(Object name) {
    return 'TrueNAS이 $name을(를) 삭제하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessDeleteExtent(Object name) {
    return '익스텐트 $name을(를) 삭제했습니다.';
  }

  @override
  String get storageIscsiFailedAssociate => 'TrueNAS이 타깃과 익스텐트를 연결하지 못했습니다.';

  @override
  String get storageIscsiSuccessAssociate => '타깃과 익스텐트를 연결했습니다.';

  @override
  String storageIscsiFailedUpdateLun(Object lun) {
    return 'TrueNAS이 LUN $lun을(를) 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdateLun(Object lun) {
    return 'LUN $lun을(를) 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedRemoveLun(Object label) {
    return 'TrueNAS이 $label을(를) 제거하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessRemoveLun(Object label) {
    return '$label을(를) 제거했습니다.';
  }

  @override
  String storageIscsiFailedCreateChap(Object user) {
    return 'TrueNAS이 $user의 CHAP 자격 증명을 생성하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessCreateChap(Object user) {
    return '$user의 CHAP 자격 증명을 생성했습니다.';
  }

  @override
  String storageIscsiFailedUpdateChap(Object user) {
    return 'TrueNAS이 $user의 CHAP 자격 증명을 업데이트하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessUpdateChap(Object user) {
    return '$user의 CHAP 자격 증명을 업데이트했습니다.';
  }

  @override
  String storageIscsiFailedDeleteChap(Object user) {
    return 'TrueNAS이 $user의 CHAP 자격 증명을 삭제하지 못했습니다.';
  }

  @override
  String storageIscsiSuccessDeleteChap(Object user) {
    return '$user의 CHAP 자격 증명을 삭제했습니다.';
  }

  @override
  String get storageUnlockTitle => '데이터셋 잠금 해제';

  @override
  String get storageUnlockPassphraseLabel => '암호';

  @override
  String get storageUnlockHexKeyLabel => '16진수 키';

  @override
  String get storageUnlockPassphraseHelper => '이 데이터셋을 암호화할 때 설정한 암호입니다.';

  @override
  String get storageUnlockHexKeyHelper => '이 데이터셋의 64자 16진수 키입니다.';

  @override
  String get storageUnlockShow => '표시';

  @override
  String get storageUnlockHide => '숨기기';

  @override
  String get storageUnlockChildrenTitle => '하위 데이터셋 잠금 해제';

  @override
  String get storageUnlockChildrenSubtitle =>
      '이 암호화 키를 공유하는 하위 데이터셋도 함께 잠금 해제됩니다.';

  @override
  String get storageUnlockSecretNotice =>
      'TrueDock은 데이터셋을 잠금 해제하기 위해 이 비밀값을 서버로 전송하며 저장하지 않습니다.';

  @override
  String get storageUnlockAction => '잠금 해제';

  @override
  String get storageUnlockErrorPassphraseRequired => '이 데이터셋의 암호를 입력하세요.';

  @override
  String get storageUnlockErrorHexKeyRequired => '이 데이터셋의 16진수 키를 입력하세요.';

  @override
  String get storageUnlockErrorHexKeyFormat => '16진수 키는 0-9와 a-f만 포함합니다.';

  @override
  String get storageDatasetEditComments => '설명';

  @override
  String get storageDatasetEditInherit => '상속';

  @override
  String get storageDatasetEditSetHere => '여기서 설정';

  @override
  String get coreLandingNoFakeData => 'TrueDock은 서버 화면을 임의로 만든 데이터로 채우지 않습니다.';

  @override
  String get coreLandingConnectServer => '서버 연결';

  @override
  String get coreLandingManage => '관리';

  @override
  String coreLandingConnectToLoad(String title) {
    return '$title 데이터를 불러오려면 서버에 연결하세요';
  }

  @override
  String get dropdownSelect => '선택';

  @override
  String dropdownOptionCount(int count) {
    return '옵션 $count개';
  }

  @override
  String get dropdownSearch => '옵션 검색';

  @override
  String get dropdownNoMatches => '일치하는 옵션이 없습니다.';

  @override
  String storagePoolMemberSummary(String category, String status) {
    return '$category · $status';
  }

  @override
  String get storageValueOnline => '온라인';

  @override
  String get storageValueOffline => '오프라인';

  @override
  String get storageValueDegraded => '성능 저하';

  @override
  String get storageValueFaulted => '고장';

  @override
  String get storageValueUnavailable => '사용 불가';

  @override
  String get storageValueData => '데이터';

  @override
  String get storageValueCache => '캐시';

  @override
  String get storageValueLog => '로그';

  @override
  String get storageValueSpare => '예비';

  @override
  String get storageValueSpecial => '특수';

  @override
  String get storageIscsiTargetModeIscsi => 'iSCSI';

  @override
  String storageSectionError(String section, String detail) {
    return '$section: $detail';
  }

  @override
  String get storageIscsiTargetsLabel => 'iSCSI 대상';

  @override
  String get storageIscsiExtentsLabel => 'iSCSI 익스텐트';

  @override
  String get storageIscsiPortalsLabel => 'iSCSI 포털';

  @override
  String get storageIscsiInitiatorsLabel => 'iSCSI 초기자';

  @override
  String get storageIscsiAssociationsLabel => 'iSCSI 연결';

  @override
  String get storageIscsiChapLabel => 'iSCSI CHAP 자격 증명';

  @override
  String storageShareProtocolPath(String protocol, String path) {
    return '$protocol · $path';
  }

  @override
  String get storageReadOnlySuffix => ' · 읽기 전용';

  @override
  String storageNfsListSubtitle(String path, String access) {
    return 'NFS · $path · $access';
  }

  @override
  String storageIscsiTargetListSubtitle(String mode, String name, int count) {
    return '$mode 대상 · $name · 포털 그룹 $count개';
  }

  @override
  String get storageIscsiInitiatorListAll => 'iSCSI 초기자 · 모든 클라이언트';

  @override
  String storageIscsiInitiatorListAllowed(int count) {
    return 'iSCSI 초기자 · $count개 허용';
  }

  @override
  String storageIscsiExtentListSubtitle(String type, String store) {
    return '$type 익스텐트 · $store';
  }

  @override
  String storageIscsiExtentListSubtitleReadOnly(String type, String store) {
    return '$type 익스텐트 · $store · 읽기 전용';
  }

  @override
  String storageDeleteExtentBackingWarning(String store) {
    return '$store 및 그 안의 모든 데이터를 제거합니다.';
  }

  @override
  String get sysRouteDestinationHelper => 'CIDR, 예: 192.168.50.0/24';

  @override
  String storageWebShareSubtitle(Object path) {
    return 'WebShare · $path';
  }

  @override
  String connMsgSignInAgainToReconnect(Object name) {
    return '$name에 다시 연결하려면 다시 로그인하세요.';
  }

  @override
  String get connMsgCredentialRequired => '연결하기 전에 자격 증명을 입력하거나 잠금 해제하세요.';

  @override
  String get connMsgAuthenticationRejected => '사용자 이름 또는 자격 증명이 거부되었습니다.';

  @override
  String get connMsgCredentialExpired => '이 자격 증명이 만료되었습니다.';

  @override
  String get connMsgCertificateExpired =>
      '서버의 TLS 인증서가 만료되었습니다. TrueNAS 관리자에게 인증서 갱신을 요청하세요.';

  @override
  String connMsgCertificateExpiringSoon(String authority) {
    return '$authority의 TLS 인증서가 곧 만료됩니다. TrueNAS 관리자에게 인증서 갱신을 요청하세요.';
  }

  @override
  String get connMsgRedirectUnsupported => '리디렉션 인증은 아직 지원되지 않습니다.';

  @override
  String get connMsgInsecureConnection => '안전하게 연결하지 못했습니다. 주소와 인증서를 확인하세요.';

  @override
  String get connMsgCertificateInspectionFailed =>
      '서버 인증서를 확인하지 못했습니다. 주소를 확인하고 다시 시도하세요.';

  @override
  String get connMsgCredentialAccessFailed =>
      '저장된 로그인 정보에 접근하지 못했습니다. TrueDock의 잠금을 풀고 다시 시도하세요.';

  @override
  String get connMsgAppPinAccessFailed =>
      'TrueDock PIN으로 저장된 로그인 정보의 잠금을 풀지 못했습니다.';

  @override
  String get connMsgUnsupportedServer =>
      'TrueDock이 지원하지 않는 서버 또는 TrueNAS 버전입니다.';

  @override
  String get connMsgInvalidSavedData => '저장된 서버 정보가 올바르지 않습니다. 서버를 다시 등록하세요.';

  @override
  String get connMsgAddressTestSignInUnavailable =>
      '활성 로그인 정보를 사용할 수 없습니다. 서버가 변경 사항을 롤백하도록 두고 다시 로그인하세요.';

  @override
  String get connMsgAddressTestOtpRequired =>
      '이 로그인에는 새 인증 코드가 필요합니다. 변경 사항을 롤백한 뒤 정상적으로 다시 연결하세요.';

  @override
  String get connMsgAddressTestAuthenticationRejected =>
      '서버가 새 주소에서 활성 로그인을 거부했습니다.';

  @override
  String get connMsgAddressTestInvalidAddress => '올바른 보안 서버 주소를 입력하세요.';

  @override
  String get connMsgSavedSignInFailed => '연결되었지만 로그인 정보를 저장하지 못했습니다.';

  @override
  String get connMsgServerRegistrationFailed => '연결되었지만 서버를 등록하지 못했습니다.';

  @override
  String get securityBiometricPromptTitle => 'TrueDock 잠금 해제';

  @override
  String get securityBiometricPromptSubtitle => '저장된 서버에 접근하려면 인증하세요';

  @override
  String get securityBiometricPromptCancel => '취소';

  @override
  String dataMsgDecodeFailed(Object method) {
    return '$method을(를) 디코딩하지 못했습니다.';
  }

  @override
  String dataMsgInvalidData(Object method) {
    return '$method이(가) 잘못된 데이터를 반환했습니다.';
  }

  @override
  String dataMsgMethodUnavailable(Object method) {
    return '이 TrueNAS 버전에서는 $method을(를) 사용할 수 없습니다.';
  }

  @override
  String get dataMsgDecodeDiskTemperatures => 'disk.temperatures를 디코딩하지 못했습니다.';

  @override
  String get dataMsgDecodeCatalogApps => 'catalog.apps를 디코딩하지 못했습니다.';

  @override
  String get dataMsgDecodeCatalogTrains => 'catalog.trains를 디코딩하지 못했습니다.';

  @override
  String get dataMsgDecodeAppDetails => 'catalog.get_app_details를 디코딩하지 못했습니다.';

  @override
  String get dataMsgNoInstallableVersions => '설치 가능한 앱 버전이 반환되지 않았습니다.';

  @override
  String get dataMsgReportingUnsupported => '이 TrueNAS 버전에서는 리포팅을 사용할 수 없습니다.';

  @override
  String get dataMsgReportingUnreadable => '리포팅 데이터를 읽지 못했습니다.';

  @override
  String get sysTunableTitle => '시스템 튜너블';

  @override
  String get sysTunableNavSubtitle => 'SYSCTL, UDEV 및 ZFS 매개변수';

  @override
  String get sysTunableSubtitle =>
      'TrueNAS가 적용하는 저수준 설정입니다. 잘못된 값은 안정성이나 접근에 영향을 줄 수 있습니다.';

  @override
  String get sysTunableEmpty => '사용자 지정 튜너블이 없습니다.';

  @override
  String get sysTunableCreate => '튜너블 추가';

  @override
  String get sysTunableCreateTitle => '새 시스템 튜너블';

  @override
  String get sysTunableEditTitle => '시스템 튜너블 편집';

  @override
  String get sysTunableType => '유형';

  @override
  String get sysTunableTypeSysctl => 'SYSCTL · 런타임 커널';

  @override
  String get sysTunableTypeUdev => 'UDEV · 장치 규칙';

  @override
  String get sysTunableTypeZfs => 'ZFS · 모듈 매개변수';

  @override
  String get sysTunableVariable => '변수';

  @override
  String get sysTunableVariableSysctlHelper => '커널 매개변수, 예: kernel.watchdog';

  @override
  String get sysTunableVariableUdevHelper => '규칙 파일 이름이며 TrueNAS가 .rules를 붙입니다';

  @override
  String get sysTunableVariableZfsHelper => 'OpenZFS 모듈 매개변수 이름';

  @override
  String get sysTunableValue => '값';

  @override
  String get sysTunableComment => '설명';

  @override
  String get sysTunableEnabled => '활성화';

  @override
  String get sysTunableDisabled => '비활성화';

  @override
  String get sysTunableUpdateInitramfs => 'initramfs 업데이트';

  @override
  String get sysTunableUpdateInitramfsSubtitle =>
      '수동 재생성을 하지 않는다면 ZFS 설정을 부팅 후에도 유지하는 데 필요합니다.';

  @override
  String get sysTunableValidationVariable => '변수 이름을 입력하세요.';

  @override
  String get sysTunableValidationValue => '값을 입력하세요.';

  @override
  String get sysTunableCreateConfirmTitle => '이 시스템 튜너블을 추가할까요?';

  @override
  String get sysTunableUpdateConfirmTitle => '튜너블 변경 사항을 적용할까요?';

  @override
  String get sysTunableCreateAction => '튜너블 추가';

  @override
  String get sysTunableUpdateAction => '변경 적용';

  @override
  String get sysTunableSysctlConsequence => 'SYSCTL 설정은 일반적으로 서버 전체에 즉시 적용됩니다.';

  @override
  String get sysTunableUdevConsequence =>
      'UDEV 규칙은 일치하는 하드웨어 이벤트가 발생할 때 적용됩니다.';

  @override
  String get sysTunableZfsConsequence =>
      'ZFS 모듈 설정에는 initramfs 업데이트와 재부팅이 필요할 수 있습니다.';

  @override
  String get sysTunableRiskConsequence =>
      '잘못된 저수준 설정은 TrueNAS를 불안정하게 하거나 접근을 끊을 수 있습니다.';

  @override
  String get sysTunableDeleteTitle => '이 시스템 튜너블을 삭제할까요?';

  @override
  String get sysTunableDeleteAction => '튜너블 삭제';

  @override
  String get sysTunableDeleteConsequence =>
      '저장된 재정의가 제거됩니다. 실행 중인 값이 완전히 돌아오려면 재부팅이나 장치 이벤트가 필요할 수 있습니다.';

  @override
  String get sysTunableCreated => '시스템 튜너블을 추가했습니다.';

  @override
  String get sysTunableUpdated => '시스템 튜너블을 업데이트했습니다.';

  @override
  String get sysTunableDeleted => '시스템 튜너블을 삭제했습니다.';

  @override
  String get navAbout => '앱 정보';

  @override
  String get aboutTitle => 'TrueDock 정보';

  @override
  String get aboutSettingsSubtitle => '버전, 라이선스, 프로젝트 링크';

  @override
  String get aboutTagline => 'TrueNAS 관리의 새로운 정박지';

  @override
  String get aboutMadeWith => 'Made with ❤️ in 🇰🇷';

  @override
  String get aboutSectionApp => '애플리케이션';

  @override
  String get aboutVersionLabel => '버전';

  @override
  String aboutVersionValue(String version, String build) {
    return '$version (빌드 $build)';
  }

  @override
  String get aboutLicenseLabel => '라이선스';

  @override
  String get aboutSectionProject => '프로젝트';

  @override
  String get aboutRepositoryLabel => '소스 코드';

  @override
  String get aboutRepositorySubtitle => 'GitHub에서 소스를 보거나 문제를 제보하고 기여할 수 있습니다.';

  @override
  String get aboutSectionOpenSource => '오픈소스 라이선스';

  @override
  String get aboutOpenSourceIntro =>
      'TrueDock은 다음 오픈소스 패키지를 기반으로 만들어졌습니다. 관리자분들께 감사드립니다.';

  @override
  String aboutOpenSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '패키지 $count개',
    );
    return '$_temp0';
  }

  @override
  String get aboutLinkFailed => '이 기기에서 링크를 열 수 없습니다.';

  @override
  String get aboutOpenSourceSubtitle => 'TrueDock에 포함된 패키지와 라이선스';

  @override
  String get aboutPackageOpenPage => '패키지 페이지 열기';

  @override
  String get aboutPackageLicenseUnavailable =>
      '이 패키지에 번들된 라이선스 텍스트가 없습니다. 패키지 페이지에서 라이선스를 확인하세요.';
}
