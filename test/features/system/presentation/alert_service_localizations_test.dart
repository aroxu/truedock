import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/alert_service_configuration.dart';
import 'package:true_dock/features/system/presentation/alert_service_sheet.dart';
import 'package:true_dock/l10n/app_localizations_en.dart';
import 'package:true_dock/l10n/app_localizations_ko.dart';

void main() {
  test('generic alert destination names are localized', () {
    final en = AppLocalizationsEn();
    final ko = AppLocalizationsKo();

    expect(en.alertKindLabel(AlertServiceKind.mail), 'Email');
    expect(ko.alertKindLabel(AlertServiceKind.mail), '이메일');
    expect(en.alertKindLabel(AlertServiceKind.snmpTrap), 'SNMP trap');
    expect(ko.alertKindLabel(AlertServiceKind.snmpTrap), 'SNMP 트랩');
    expect(ko.alertKindLabel(AlertServiceKind.slack), 'Slack');
  });

  test('alert severity names are localized instead of exposing API values', () {
    final en = AppLocalizationsEn();
    final ko = AppLocalizationsKo();

    expect(en.alertLevelLabel(AlertLevel.emergency), 'Emergency');
    expect(ko.alertLevelLabel(AlertLevel.emergency), '비상');
    expect(en.alertLevelLabel(AlertLevel.critical), 'Critical');
    expect(ko.alertLevelLabel(AlertLevel.critical), '심각');
    expect(ko.alertLevelLabel(AlertLevel.info), '정보');
  });
}
