import '../../../l10n/app_localizations.dart';
import '../domain/app_installation.dart';

/// Maps app installation validation issues onto ARB-localized strings. Issues
/// that carry a numeric bound substitute it into the localized message.
extension AppsLocalizations on AppLocalizations {
  /// Localizes client-owned fallbacks while preserving values supplied by the
  /// connected server.
  String appVersionLabel(String value) =>
      value.trim().isEmpty || value == 'Unknown version'
      ? appsVersionUnavailable
      : value;

  String appImageLabel(String value) =>
      value.trim().isEmpty || value == 'Unknown image'
      ? appsImageUnavailable
      : value;

  String appRuntimeState(String state) => switch (state.toUpperCase()) {
    'RUNNING' => appsStateRunning,
    'STOPPED' => appsStateStopped,
    'DEPLOYING' => appsStateDeploying,
    'STARTING' => appsStateStarting,
    'STOPPING' => appsStateStopping,
    'CRASHED' => appsStateCrashed,
    'HEALTHY' => appsStateHealthy,
    'UNHEALTHY' => appsStateUnhealthy,
    'UNKNOWN' => appsStateUnknown,
    _ => state,
  };

  String appDeviceType(String type) => switch (type.toUpperCase()) {
    'DISK' => appsDeviceTypeDisk,
    'NIC' || 'NETWORK' => appsDeviceTypeNetwork,
    'DISPLAY' || 'GPU' => appsDeviceTypeDisplay,
    'USB' => appsDeviceTypeUsb,
    'PCI' || 'PCIE' => appsDeviceTypePci,
    'TPM' => appsDeviceTypeTpm,
    'CDROM' => appsDeviceTypeCdrom,
    _ => type,
  };

  String appValidationMessage(AppValidationIssue issue) {
    final bound = issue.bound?.toInt() ?? 0;
    return switch (issue.code) {
      AppValidationCode.nameFormat => appsValidationNameFormat,
      AppValidationCode.unsupportedField => appsValidationUnsupportedField,
      AppValidationCode.fieldRequired => appsValidationFieldRequired,
      AppValidationCode.wholeNumber => appsValidationWholeNumber,
      AppValidationCode.minimumValue => appsValidationMinimumValue(bound),
      AppValidationCode.maximumValue => appsValidationMaximumValue(bound),
      AppValidationCode.minimumLength => appsValidationMinimumLength(bound),
      AppValidationCode.maximumLength => appsValidationMaximumLength(bound),
      AppValidationCode.absolutePath => appsValidationAbsolutePath,
      AppValidationCode.uriScheme => appsValidationUriScheme,
      AppValidationCode.ipAddress => appsValidationIpAddress,
      AppValidationCode.chooseOption => appsValidationChooseOption,
      AppValidationCode.minimumItems => appsValidationMinimumItems(bound),
      AppValidationCode.maximumItems => appsValidationMaximumItems(bound),
      AppValidationCode.listNoSchema => appsValidationListNoSchema,
      AppValidationCode.itemRequired => appsValidationItemRequired,
      AppValidationCode.itemWholeNumber => appsValidationItemWholeNumber,
    };
  }

  /// Localizes recurring display text supplied by the TrueNAS app catalog.
  /// Unknown, app-specific text deliberately remains unchanged.
  String appCatalogText(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'<\s*/?\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
    final normalized = cleaned
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), '\n');
    final timezone = RegExp(
      r'''^[\x27\x22`]([^\x27\x22`]+)[\x27\x22`]\s+timezone$''',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (timezone != null) return timezone.group(1)!;

    const exact = <String, String>{
      'Configuration': '구성',
      'App Configuration': '앱 구성',
      'Application Configuration': '애플리케이션 구성',
      'Network': '네트워크',
      'Network Configuration': '네트워크 구성',
      'Storage': '스토리지',
      'Storage Configuration': '스토리지 구성',
      'Resources': '리소스',
      'Resource Configuration': '리소스 구성',
      'Resources Configuration': '리소스 구성',
      'Labels Configuration': '라벨 구성',
      'User and Group Settings': '사용자 및 그룹 설정',
      'User and Group Configuration': '사용자 및 그룹 구성',
      'User': '사용자',
      'Group': '그룹',
      'Run As': '실행 계정',
      'User ID': '사용자 ID',
      'Group ID': '그룹 ID',
      'Host name': '호스트 이름',
      'Host Path': '호스트 경로',
      'Host IPs': '호스트 IP',
      'Host Network': '호스트 네트워크',
      'Networks': '네트워크',
      'DNS Options': 'DNS 옵션',
      'Data path': '데이터 경로',
      'Dataset': '데이터셋',
      'Timezone': '시간대',
      'GPU Configuration': 'GPU 구성',
      'Image Configuration': '이미지 구성',
      'Port': '포트',
      'API Port': 'API 포트',
      'Port Bind Mode': '포트 바인딩 방식',
      'WebUI Port': 'WebUI 포트',
      'Debug logging': '디버그 로깅',
      'Advanced options': '고급 옵션',
      'Additional Environment Variables': '추가 환경 변수',
      'Environment Variable': '환경 변수',
      'Name': '이름',
      'Value': '값',
      'Certificate': '인증서',
      'No Certificate': '인증서 없음',
      'Database': '데이터베이스',
      'Password': '비밀번호',
      'Enable': '활성화',
      'Enabled': '활성화됨',
      'Network settings': '네트워크 설정',
      'Storage settings': '스토리지 설정',
      'Additional Storage': '추가 스토리지',
      'Enable ACL': 'ACL 활성화',
      'Labels': '라벨',
      'Limits': '제한',
      'CPU Limit': 'CPU 제한',
      'Memory Limit': '메모리 제한',
      'No description provided.': '설명이 제공되지 않았습니다.',
      'The docker networks to join': '연결할 Docker 네트워크',
      'DNS options for the container.\nFormat: key:value\nExample: attempts:3':
          '컨테이너의 DNS 옵션입니다.\n형식: key:value\n예시: attempts:3',
      'The configuration for the ixVolume dataset.': 'ixVolume 데이터셋 구성입니다.',
      'Enable ACL for the storage.': '스토리지에 ACL을 활성화합니다.',
      'ixVolume (Dataset created automatically by the system.)':
          'ixVolume (시스템에서 데이터셋 자동 생성)',
      'Host Path (Path that already exists on the system.)':
          '호스트 경로 (시스템에 이미 존재하는 경로)',
      'Publish port on the host for external access': '외부 접속을 위해 호스트에 포트 공개',
      'Expose only inside the application': '애플리케이션 내부에서만 노출',
      'Expose port for inter-container communication': '컨테이너 간 통신용 포트 공개',
      'None': '없음',
      'IPs on the host to bind this port': '이 포트를 바인딩할 호스트 IP',
      'The port bind mode.\n- Publish: The port will be published on the host for external access.':
          '포트 바인딩 방식입니다.\n- 공개: 외부 접속을 위해 호스트에 포트를 공개합니다.',
    };
    final translated = exact[normalized];
    if (translated != null) return translated;

    const suffixes = <String, String>{
      ' Configuration': ' 구성',
      ' Settings': ' 설정',
    };
    for (final entry in suffixes.entries) {
      if (normalized.endsWith(entry.key)) {
        return '${normalized.substring(0, normalized.length - entry.key.length)}${entry.value}';
      }
    }
    if (normalized.startsWith('Configure Network for ')) {
      return '${normalized.substring('Configure Network for '.length)} 네트워크 구성';
    }
    if (normalized.startsWith('Configure Storage for ')) {
      return '${normalized.substring('Configure Storage for '.length)} 스토리지 구성';
    }
    if (normalized.startsWith('Configure Labels for ')) {
      return '${normalized.substring('Configure Labels for '.length)} 라벨 구성';
    }
    if (normalized.startsWith('Configure Resources for ')) {
      return '${normalized.substring('Configure Resources for '.length)} 리소스 구성';
    }
    if (normalized.startsWith('Configure User and Group for ')) {
      return '${normalized.substring('Configure User and Group for '.length)} 사용자 및 그룹 구성';
    }
    if (normalized.startsWith('The port bind mode.')) {
      return normalized
          .replaceFirst('The port bind mode.', '포트 바인딩 방식입니다.')
          .replaceAll(
            'Publish: The port will be published on the host for external access.',
            '공개: 외부 접속을 위해 호스트에 포트를 공개합니다.',
          )
          .replaceAll(
            'Expose: The port will be exposed for inter-container communication.',
            '노출: 컨테이너 간 통신을 위해 포트를 노출합니다.',
          )
          .replaceAll(
            'None: The port will not be exposed.',
            '없음: 포트를 노출하지 않습니다.',
          );
    }
    final configStorage = RegExp(
      r'^(.+) Config Storage$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (configStorage != null) {
      return '${configStorage.group(1)} 설정 스토리지';
    }
    final configPath = RegExp(
      r'^The path to store (.+) Config\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (configPath != null) {
      return '${configPath.group(1)} 설정을 저장할 경로입니다.';
    }
    final certificate = RegExp(
      r'^The certificate to use for (.+)\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (certificate != null) {
      return '${certificate.group(1)}에 사용할 인증서입니다.';
    }
    final cpuLimit = RegExp(
      r'^CPUs? limit for (.+)\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (cpuLimit != null) return '${cpuLimit.group(1)} CPU 제한입니다.';
    final memoryLimit = RegExp(
      r'^Memory limit for (.+)\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (memoryLimit != null) return '${memoryLimit.group(1)} 메모리 제한입니다.';
    if (normalized.startsWith('ixVolume: Is dataset created automatically')) {
      return normalized
          .replaceFirst(
            RegExp(
              r'ixVolume: Is dataset created automatically by the system\.?',
              caseSensitive: false,
            ),
            'ixVolume: 시스템에서 데이터셋을 자동으로 생성합니다.',
          )
          .replaceFirst(
            RegExp(
              r'Host Path: Is a path that already exists on the system\.?',
              caseSensitive: false,
            ),
            '호스트 경로: 시스템에 이미 존재하는 경로를 사용합니다.',
          );
    }
    final userOwner = RegExp(
      r'^The user id that (.+) files will be owned by\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (userOwner != null) {
      return '${userOwner.group(1)} 파일 소유자로 사용할 UID입니다.';
    }
    final groupOwner = RegExp(
      r'^The group id that (.+) files will be owned by\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (groupOwner != null) {
      return '${groupOwner.group(1)} 파일 소유 그룹으로 사용할 GID입니다.';
    }
    final hostNetwork = RegExp(
      r'^Enabling this will use the host network for (.+)\.\nThe TCP and UDP ports will listen on port ([0-9]+)\.\nWeb UI will listen on the port specified above\.$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (hostNetwork != null) {
      return '활성화하면 ${hostNetwork.group(1)}에서 호스트 네트워크를 사용합니다.\n'
          'TCP 및 UDP 포트는 ${hostNetwork.group(2)}번 포트에서 수신하며, '
          'Web UI는 위에서 지정한 포트를 사용합니다.';
    }
    return normalized;
  }
}
