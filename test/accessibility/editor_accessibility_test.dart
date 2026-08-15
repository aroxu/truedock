import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/data_protection/domain/cloud_sync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/replication_configuration.dart';
import 'package:true_dock/features/data_protection/domain/rsync_configuration.dart';
import 'package:true_dock/features/data_protection/domain/task_schedule.dart';
import 'package:true_dock/features/data_protection/domain/cloud_backup_configuration.dart';
import 'package:true_dock/features/data_protection/presentation/cloud_backup_sheet.dart';
import 'package:true_dock/features/data_protection/presentation/cloud_sync_task_sheet.dart';
import 'package:true_dock/features/data_protection/presentation/replication_task_sheet.dart';
import 'package:true_dock/features/data_protection/presentation/rsync_task_sheet.dart';
import 'package:true_dock/features/system/domain/interface_configuration.dart';
import 'package:true_dock/features/system/domain/static_route_configuration.dart';
import 'package:true_dock/features/system/presentation/interface_config_sheet.dart';
import 'package:true_dock/features/apps/presentation/instance_sheets.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/system/domain/virt_instance_configuration.dart';
import 'package:true_dock/features/system/domain/audit_entry.dart';
import 'package:true_dock/features/system/presentation/audit_retention_sheet.dart';
import 'package:true_dock/features/system/domain/cron_job_configuration.dart';
import 'package:true_dock/features/system/domain/tunable_configuration.dart';
import 'package:true_dock/features/system/domain/mail_configuration.dart';
import 'package:true_dock/features/system/domain/network_configuration.dart';
import 'package:true_dock/features/system/domain/service_configuration.dart';
import 'package:true_dock/features/system/domain/alert_class_configuration.dart';
import 'package:true_dock/features/system/presentation/alert_classes_sheet.dart';
import 'package:true_dock/features/system/presentation/alert_service_sheet.dart';
import 'package:true_dock/features/system/presentation/cron_job_sheet.dart';
import 'package:true_dock/features/system/presentation/tunable_sheet.dart';
import 'package:true_dock/features/system/presentation/mail_sheet.dart';
import 'package:true_dock/features/system/domain/privilege_configuration.dart';
import 'package:true_dock/features/system/domain/system_resources.dart';
import 'package:true_dock/features/system/presentation/network_global_sheet.dart';
import 'package:true_dock/features/system/presentation/privilege_sheet.dart';
import 'package:true_dock/features/system/presentation/service_config_sheet.dart';
import 'package:true_dock/features/system/presentation/static_route_sheet.dart';
import 'package:true_dock/l10n/app_localizations.dart';

/// Editors reachable from Data Protection and System, seeded with realistic
/// values so the checks run against populated rather than empty layouts.
final _editors = <String, Widget>{
  'Replication': const ReplicationTaskSheet(
    baseline: ReplicationConfiguration(
      name: 'Nightly offsite',
      direction: ReplicationDirection.push,
      transport: ReplicationTransport.ssh,
      sshCredentialId: 3,
      sourceDatasets: ['tank/media'],
      targetDataset: 'backup/media',
    ),
    datasets: ['tank/media', 'tank/docs'],
    sshCredentials: [SshCredential(id: 3, name: 'Offsite backup')],
  ),
  'Rsync': const RsyncTaskSheet(
    baseline: RsyncConfiguration(
      path: '/mnt/tank/media',
      user: 'backup',
      direction: RsyncDirection.push,
      mode: RsyncMode.ssh,
      remoteHost: 'offsite.example',
      remotePath: '/srv/media',
      sshCredentialId: 4,
    ),
    users: ['root', 'backup'],
    sshCredentials: [SshCredential(id: 4, name: 'Offsite backup')],
  ),
  'CloudSync': const CloudSyncTaskSheet(
    baseline: CloudSyncConfiguration(
      description: 'Nightly offsite',
      direction: CloudSyncDirection.push,
      transferMode: CloudSyncTransferMode.copy,
      path: '/mnt/tank/media',
      credentialId: 3,
      bucket: 'my-bucket',
      folder: 'media',
    ),
    credentials: [CloudCredential(id: 3, name: 'Backblaze', provider: 'S3')],
  ),
  // Cloud backup: the only editor whose secret field is required on create and
  // means "unchanged" when blank on an edit.
  'CloudBackup': const CloudBackupSheet(
    baseline: CloudBackupConfiguration(
      path: '/mnt/tank/docs',
      credentialId: 3,
      keepLast: 7,
      description: 'Nightly offsite',
      bucket: 'my-bucket',
      folder: 'docs',
    ),
    credentials: [CloudCredential(id: 3, name: 'Backblaze', provider: 'B2')],
    isNew: false,
  ),
  'Interface': const InterfaceConfigSheet(
    baseline: InterfaceConfiguration(
      id: 'eno1',
      name: 'eno1',
      description: 'LAN',
      ipv4Dhcp: false,
      aliases: [InterfaceAlias(address: '192.168.1.10', netmask: 24)],
      mtu: 1500,
    ),
  ),
  // Instances editors, added with 25.10's virt.* surface. The create sheet is
  // the widest layout of the set: a filter dropdown plus an icon action button,
  // which is where a 2x text scale overflow first showed up.
  'CreateInstance': const CreateInstanceSheet(
    images: [
      VirtImageChoice(
        id: 'alpine/3.22/default',
        label: 'Alpine 3.22 (amd64, default)',
        os: 'Alpine',
        release: '3.22',
        variant: 'default',
        architectures: ['amd64'],
        instanceTypes: ['CONTAINER'],
      ),
    ],
    storagePool: 'tank',
  ),
  'EditInstance': EditInstanceSheet(
    instance: VirtInstance(
      id: 'web',
      name: 'web',
      type: 'CONTAINER',
      status: 'RUNNING',
      autostart: true,
      privileged: false,
      vncEnabled: false,
      cpu: '2',
      memoryBytes: 512 * 1024 * 1024,
      storagePool: 'tank',
      imageDescription: 'Alpine 3.22 amd64',
    ),
  ),
  // The global network editor: seven fields plus a read-only effective-state
  // block, which is the densest layout in the set.
  'NetworkGlobal': const NetworkGlobalSheet(
    baseline: NetworkConfiguration(
      hostname: 'truenas',
      domain: 'local',
      nameserver1: '1.1.1.1',
      effective: EffectiveNetworkState(
        ipv4Gateway: '10.24.30.254',
        nameservers: ['10.24.30.254'],
      ),
    ),
    summary: NetworkSummary(
      interfaces: {
        'ens18': ['10.24.30.81/24'],
      },
      defaultRoutes: ['10.24.30.254'],
      nameservers: ['10.24.30.254'],
    ),
  ),
  // The administration editors added alongside the API coverage work. The alert
  // sheet is the densest: three dropdowns plus a variable attribute form.
  'AlertService': const AlertServiceSheet(),
  // Two dropdowns per row across a grouped list: the tightest horizontal
  // layout in the app, so 2x text scale is the real check here.
  'AlertClasses': AlertClassesSheet(
    configuration: AlertClassConfiguration.merge(
      definitions: AlertClassConfiguration.parseCategories(const [
        {
          'id': 'STORAGE',
          'title': 'Storage',
          'classes': [
            {
              'id': 'PoolDegraded',
              'title': 'Pool degraded',
              'level': 'CRITICAL',
            },
            {'id': 'ScrubFinished', 'title': 'Scrub finished', 'level': 'INFO'},
          ],
        },
      ]),
      overrides: const {
        'ScrubFinished': {'level': 'NOTICE', 'policy': 'NEVER'},
      },
    ),
  ),
  'CronJob': const CronJobSheet(
    baseline: CronJobConfiguration(
      command: 'zpool scrub tank',
      user: 'root',
      description: 'Weekly scrub',
    ),
    users: ['root', 'backup'],
  ),
  'Tunable': const TunableSheet(
    editing: true,
    baseline: TunableConfiguration(
      type: TunableType.zfs,
      variable: 'zfs_arc_max',
      value: '1073741824',
      comment: 'ARC limit',
    ),
  ),
  'Mail': const MailSheet(
    baseline: MailConfiguration(
      fromEmail: 'nas@example.com',
      fromName: 'NAS',
      outgoingServer: 'smtp.example.com',
      port: 587,
      security: MailSecurity.tls,
      smtpAuthentication: true,
      username: 'nas',
    ),
  ),
  // SNMP has the most fields of the five services, including secrets.
  'ServiceConfig': const ServiceConfigSheet(
    configuration: ServiceConfiguration(
      service: ConfigurableService.snmp,
      values: {
        'community': 'public',
        'contact': 'ops@example.com',
        'location': 'rack 4',
        'loglevel': 3,
        'traps': false,
        'zilstat': false,
        'v3': false,
        'v3_username': '',
        'v3_authtype': '',
        'v3_password': '',
        'v3_privproto': null,
        'v3_privpassphrase': '',
      },
    ),
    running: true,
  ),
  // Privileges: a searchable list of 141 roles plus group chips, so this is the
  // longest scrolling editor in the app.
  'Privilege': PrivilegeSheet(
    baseline: const PrivilegeConfiguration(
      name: 'Operators',
      roles: ['SHARING_ADMIN'],
      localGroupIds: [41],
    ),
    roles: [
      PrivilegeRole.fromJson(const {
        'name': 'SHARING_ADMIN',
        'title': 'SHARING_ADMIN',
        'includes': ['SHARING_READ'],
      }),
      PrivilegeRole.fromJson(const {
        'name': 'SHARING_READ',
        'title': 'SHARING_READ',
        'includes': <String>[],
      }),
      PrivilegeRole.fromJson(const {
        'name': 'FULL_ADMIN',
        'title': 'FULL_ADMIN',
        'includes': <String>[],
      }),
    ],
    groups: [
      NasGroup.fromJson(const {
        'id': 41,
        'name': 'operators',
        'gid': 951,
        'local': true,
        'builtin': false,
        'smb': true,
        'roles': <String>[],
        'users': <int>[],
      }),
    ],
    isNew: false,
  ),
  'StaticRoute': const StaticRouteSheet(
    baseline: StaticRouteConfiguration(
      destination: '192.168.50.0/24',
      gateway: '10.0.0.1',
      description: 'Branch office',
    ),
  ),
  'AuditRetention': const AuditRetentionSheet(
    baseline: AuditConfiguration(
      retentionDays: 7,
      quotaGiB: 20,
      quotaFillWarning: 75,
      quotaFillCritical: 95,
      usedBytes: 268435456,
      availableBytes: 21207008870,
      enabledServices: [AuditService.middleware],
    ),
  ),
};

Widget _wrap(Widget sheet, {double textScale = 1.0}) => MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: const Color(0xFF2E999C),
    useMaterial3: true,
  ),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: sheet),
  ),
);

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  for (final entry in _editors.entries) {
    group(entry.key, () {
      testWidgets('meets tap target, label, and contrast guidelines', (
        tester,
      ) async {
        _usePhoneSurface(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_wrap(entry.value));
        await tester.pumpAndSettle();

        // Touch targets must be reachable for motor-impaired users on both
        // platforms; TrueDock ships iOS first but keeps Android viable.
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        // Every tappable control must expose a label to screen readers.
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Text must stay legible against its background.
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        handle.dispose();
      });

      testWidgets('renders at 2x text scale without overflow', (tester) async {
        _usePhoneSurface(tester);
        await tester.pumpWidget(_wrap(entry.value, textScale: 2.0));
        await tester.pumpAndSettle();
        // A RenderFlex overflow throws during pump; reaching here means the
        // layout absorbed the larger type.
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in dark mode without contrast failures', (
        tester,
      ) async {
        _usePhoneSurface(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF2E999C),
              brightness: Brightness.dark,
              useMaterial3: true,
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: entry.value),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    });
  }
}
