import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/apps/domain/app_installation.dart';
import 'package:true_dock/features/apps/domain/apps_catalog.dart';
import 'package:true_dock/features/apps/presentation/app_installation_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Syncthing catalog fields render in Korean', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppInstallationSheet(app: _app, details: _details),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용자 및 그룹 구성'), findsOneWidget);
    expect(find.text('Syncthing 사용자 및 그룹 구성'), findsOneWidget);
    expect(find.text('실행 계정'), findsOneWidget);
    expect(find.text('Syncthing 파일 소유자로 사용할 UID입니다.'), findsOneWidget);

    await _scrollTo(tester, find.text('네트워크 구성'));
    expect(find.text('Syncthing 네트워크 구성'), findsOneWidget);
    expect(find.text('WebUI 포트'), findsOneWidget);
    expect(find.text('호스트 IP'), findsOneWidget);
    expect(find.textContaining('</br>'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('app-option-webui.bind_mode')));
    await tester.pumpAndSettle();
    expect(find.text('외부 접속을 위해 호스트에 포트 공개'), findsWidgets);
    expect(find.text('컨테이너 간 통신용 포트 공개'), findsOneWidget);
    expect(find.text('없음'), findsOneWidget);
    expect(find.textContaining('</br>'), findsNothing);
    Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('DNS 옵션'));
    expect(find.text('네트워크'), findsWidgets);
    expect(find.text('연결할 Docker 네트워크'), findsOneWidget);
    expect(find.text('DNS 옵션'), findsOneWidget);
    expect(find.textContaining('컨테이너의 DNS 옵션입니다.'), findsOneWidget);

    await _scrollTo(tester, find.text('스토리지 구성'));
    expect(find.text('Syncthing 설정 스토리지'), findsOneWidget);
    expect(find.text('Syncthing 설정을 저장할 경로입니다.'), findsOneWidget);
    expect(find.text('ACL 활성화'), findsOneWidget);
    expect(find.text('추가 스토리지'), findsOneWidget);

    await _scrollTo(tester, find.text('라벨 구성'));
    expect(find.text('Syncthing 라벨 구성'), findsOneWidget);
    expect(find.text('라벨'), findsOneWidget);

    await _scrollTo(tester, find.text('리소스 구성'));
    expect(find.text('Syncthing 리소스 구성'), findsOneWidget);
    expect(find.text('제한'), findsOneWidget);
    expect(find.text('Syncthing CPU 제한입니다.'), findsOneWidget);
    expect(find.text('Syncthing 메모리 제한입니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

const _app = CatalogApp(
  name: 'syncthing',
  title: 'Syncthing',
  train: 'community',
  description: 'File synchronization',
  healthy: true,
  recommended: false,
  categories: [],
  tags: [],
);

final _details = CatalogAppInstallationDetails.fromJson(
  {
    'name': 'syncthing',
    'latest_version': '1.0.0',
    'versions': {
      '1.0.0': {
        'version': '1.0.0',
        'human_version': '1.0.0',
        'healthy': true,
        'supported': true,
        'schema': {
          'groups': [
            {
              'name': 'User and Group Configuration',
              'description': 'Configure User and Group for Syncthing',
            },
            {
              'name': 'Network Configuration',
              'description': 'Configure Network for Syncthing',
            },
            {
              'name': 'Storage Configuration',
              'description': 'Configure Storage for Syncthing',
            },
            {
              'name': 'Labels Configuration',
              'description': 'Configure Labels for Syncthing',
            },
            {
              'name': 'Resources Configuration',
              'description': 'Configure Resources for Syncthing',
            },
          ],
          'questions': [
            {
              'variable': 'run_as',
              'label': 'Run As',
              'group': 'User and Group Configuration',
              'schema': {
                'type': 'dict',
                'attrs': [
                  {
                    'variable': 'uid',
                    'label': 'User ID',
                    'description':
                        'The user id that Syncthing files will be owned by.',
                    'schema': {'type': 'int', 'default': 568},
                  },
                  {
                    'variable': 'gid',
                    'label': 'Group ID',
                    'description':
                        'The group id that Syncthing files will be owned by.',
                    'schema': {'type': 'int', 'default': 568},
                  },
                ],
              },
            },
            {
              'variable': 'webui',
              'label': 'WebUI Port',
              'group': 'Network Configuration',
              'schema': {
                'type': 'dict',
                'attrs': [
                  {
                    'variable': 'bind_mode',
                    'label': 'Port Bind Mode',
                    'description':
                        'The port bind mode.</br>- Publish: The port will be published on the host for external access.</br>',
                    'schema': {
                      'type': 'string',
                      'enum': [
                        {
                          'value': 'published',
                          'description':
                              'Publish port on the host for external access',
                        },
                        {
                          'value': 'exposed',
                          'description':
                              'Expose port for inter-container communication',
                        },
                        {'value': 'none', 'description': 'None'},
                      ],
                      'default': 'published',
                    },
                  },
                  {
                    'variable': 'host_ips',
                    'label': 'Host IPs',
                    'description': 'IPs on the host to bind this port',
                    'schema': {
                      'type': 'list',
                      'items': [
                        {
                          'variable': 'ip',
                          'label': 'Host IP',
                          'schema': {'type': 'string'},
                        },
                      ],
                      'default': [],
                    },
                  },
                ],
              },
            },
            {
              'variable': 'networks',
              'label': 'Networks',
              'description': 'The docker networks to join',
              'group': 'Network Configuration',
              'schema': {
                'type': 'list',
                'items': [
                  {
                    'variable': 'network',
                    'label': 'Network',
                    'schema': {'type': 'string'},
                  },
                ],
                'default': [],
              },
            },
            {
              'variable': 'dns_options',
              'label': 'DNS Options',
              'description':
                  'DNS options for the container.\nFormat: key:value\nExample: attempts:3',
              'group': 'Network Configuration',
              'schema': {
                'type': 'list',
                'items': [
                  {
                    'variable': 'option',
                    'label': 'Value',
                    'schema': {'type': 'string'},
                  },
                ],
                'default': [],
              },
            },
            {
              'variable': 'config_storage',
              'label': 'Syncthing Config Storage',
              'description': 'The path to store Syncthing Config.',
              'group': 'Storage Configuration',
              'schema': {
                'type': 'dict',
                'attrs': [
                  {
                    'variable': 'enable_acl',
                    'label': 'Enable ACL',
                    'description': 'Enable ACL for the storage.',
                    'schema': {'type': 'boolean', 'default': false},
                  },
                ],
              },
            },
            {
              'variable': 'additional_storage',
              'label': 'Additional Storage',
              'group': 'Storage Configuration',
              'schema': {
                'type': 'list',
                'items': [
                  {
                    'variable': 'path',
                    'label': 'Host Path',
                    'schema': {'type': 'string'},
                  },
                ],
                'default': [],
              },
            },
            {
              'variable': 'labels',
              'label': 'Labels',
              'group': 'Labels Configuration',
              'schema': {
                'type': 'list',
                'items': [
                  {
                    'variable': 'label',
                    'label': 'Value',
                    'schema': {'type': 'string'},
                  },
                ],
                'default': [],
              },
            },
            {
              'variable': 'limits',
              'label': 'Limits',
              'group': 'Resources Configuration',
              'schema': {
                'type': 'dict',
                'attrs': [
                  {
                    'variable': 'cpu',
                    'label': 'CPU Limit',
                    'description': 'CPUs limit for Syncthing.',
                    'schema': {'type': 'int', 'default': 2},
                  },
                  {
                    'variable': 'memory',
                    'label': 'Memory Limit',
                    'description': 'Memory Limit for Syncthing.',
                    'schema': {'type': 'int', 'default': 4096},
                  },
                ],
              },
            },
          ],
        },
        'values': const {},
      },
    },
  },
  fallbackName: 'syncthing',
  train: 'community',
);
