import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/apps/presentation/apps_localizations.dart';
import 'package:true_dock/l10n/app_localizations_en.dart';
import 'package:true_dock/l10n/app_localizations_ko.dart';

void main() {
  test('timezone catalog labels show only the IANA identifier', () {
    final ko = AppLocalizationsKo();
    final en = AppLocalizationsEn();

    expect(ko.appCatalogText("'Asia/Seoul' timezone"), 'Asia/Seoul');
    expect(ko.appCatalogText('"Africa/Abidjan" timezone'), 'Africa/Abidjan');
    expect(en.appCatalogText("'Europe/London' timezone"), 'Europe/London');
  });

  test('client-owned app fallbacks are localized', () {
    final ko = AppLocalizationsKo();

    expect(ko.appVersionLabel('Unknown version'), '버전 정보 없음');
    expect(ko.appImageLabel('Unknown image'), '이미지 정보 없음');
    expect(ko.appCatalogText('No description provided.'), '설명이 제공되지 않았습니다.');
    expect(ko.appVersionLabel('25.10.1'), '25.10.1');
  });

  test('timezone cleanup does not alter unrelated catalog text', () {
    final ko = AppLocalizationsKo();

    expect(ko.appCatalogText('Timezone'), '시간대');
    expect(
      ko.appCatalogText('Custom application label'),
      'Custom application label',
    );
  });

  test('Syncthing catalog fields and descriptions are localized', () {
    final ko = AppLocalizationsKo();

    expect(ko.appCatalogText('Environment Variable'), '환경 변수');
    expect(ko.appCatalogText('Name'), '이름');
    expect(ko.appCatalogText('Value'), '값');
    expect(ko.appCatalogText('User and Group Configuration'), '사용자 및 그룹 구성');
    expect(
      ko.appCatalogText('Configure User and Group for Syncthing'),
      'Syncthing 사용자 및 그룹 구성',
    );
    expect(ko.appCatalogText('Run As'), '실행 계정');
    expect(
      ko.appCatalogText('The user id that Syncthing files will be owned by.'),
      'Syncthing 파일 소유자로 사용할 UID입니다.',
    );
    expect(ko.appCatalogText('WebUI Port'), 'WebUI 포트');
    expect(ko.appCatalogText('Host IPs'), '호스트 IP');
    expect(
      ko.appCatalogText('Expose port for inter-container communication'),
      '컨테이너 간 통신용 포트 공개',
    );
    expect(ko.appCatalogText('None'), '없음');
  });

  test('catalog HTML breaks are cleaned before translating descriptions', () {
    final ko = AppLocalizationsKo();
    final en = AppLocalizationsEn();
    const source =
        'Enabling this will use the host network for Syncthing.</br>'
        'The TCP and UDP ports will listen on port 22000. </br>'
        'Web UI will listen on the port specified above.';

    final translated = ko.appCatalogText(source);
    expect(translated, contains('Syncthing'));
    expect(translated, contains('22000'));
    expect(translated, isNot(contains('</br>')));
    expect(en.appCatalogText(source), isNot(contains('</br>')));
  });

  test('remaining Syncthing network and storage fields are localized', () {
    final ko = AppLocalizationsKo();

    expect(ko.appCatalogText('Networks'), '네트워크');
    expect(ko.appCatalogText('The docker networks to join'), '연결할 Docker 네트워크');
    expect(ko.appCatalogText('DNS Options'), 'DNS 옵션');
    expect(
      ko.appCatalogText(
        'DNS options for the container.\nFormat: key:value\nExample: attempts:3',
      ),
      '컨테이너의 DNS 옵션입니다.\n형식: key:value\n예시: attempts:3',
    );
    expect(ko.appCatalogText('No Certificate'), '인증서 없음');
    expect(
      ko.appCatalogText('The certificate to use for Syncthing.'),
      'Syncthing에 사용할 인증서입니다.',
    );
    expect(ko.appCatalogText('Syncthing Config Storage'), 'Syncthing 설정 스토리지');
    expect(
      ko.appCatalogText('The path to store Syncthing Config.'),
      'Syncthing 설정을 저장할 경로입니다.',
    );
    expect(ko.appCatalogText('Enable ACL'), 'ACL 활성화');
    expect(
      ko.appCatalogText('Enable ACL for the storage.'),
      '스토리지에 ACL을 활성화합니다.',
    );
    expect(ko.appCatalogText('Additional Storage'), '추가 스토리지');
  });

  test('labels and resource limits preserve the app name', () {
    final ko = AppLocalizationsKo();

    expect(ko.appCatalogText('Labels Configuration'), '라벨 구성');
    expect(
      ko.appCatalogText('Configure Labels for Syncthing'),
      'Syncthing 라벨 구성',
    );
    expect(ko.appCatalogText('Labels'), '라벨');
    expect(
      ko.appCatalogText('Configure Resources for Syncthing'),
      'Syncthing 리소스 구성',
    );
    expect(ko.appCatalogText('Limits'), '제한');
    expect(
      ko.appCatalogText('CPUs limit for Syncthing.'),
      'Syncthing CPU 제한입니다.',
    );
    expect(
      ko.appCatalogText('Memory Limit for Syncthing.'),
      'Syncthing 메모리 제한입니다.',
    );
  });
}
