import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/system_general_configuration.dart';

void main() {
  group('SystemGeneralConfiguration.fromConfig', () {
    test('seeds fields from a system.general.config response', () {
      final config = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'description': 'Living room NAS',
        'timezone': 'Asia/Seoul',
        'sysloglevel': 'WARNING',
      });
      expect(config.hostname, 'nas01');
      expect(config.timezone, 'Asia/Seoul');
      expect(config.syslogLevel, SystemSyslogLevel.warning);
    });

    test('falls back to defaults for a sparse config', () {
      final config = SystemGeneralConfiguration.fromConfig({});
      expect(config.hostname, isEmpty);
      expect(config.timezone, isEmpty);
      expect(config.syslogLevel, SystemSyslogLevel.defaultLevel);
    });
  });

  group('SystemGeneralConfiguration.changedFields', () {
    test('emits only the changed fields', () {
      final baseline = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'description': 'Old',
        'timezone': 'UTC',
        'sysloglevel': 'INFO',
      });
      final next = baseline.copyWith(hostname: 'nas02', timezone: 'Asia/Seoul');
      expect(next.changedFields(baseline), {
        'hostname': 'nas02',
        'timezone': 'Asia/Seoul',
      });
    });

    test('emits nothing when nothing changed', () {
      final baseline = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'timezone': 'UTC',
        'sysloglevel': 'INFO',
      });
      expect(baseline.changedFields(baseline), isEmpty);
    });

    test('emits sysloglevel by its API name', () {
      final baseline = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'timezone': 'UTC',
        'sysloglevel': 'INFO',
      });
      final next = baseline.copyWith(syslogLevel: SystemSyslogLevel.error);
      expect(next.changedFields(baseline), {'sysloglevel': 'ERROR'});
    });
  });

  group('validateSystemGeneralConfiguration', () {
    test('accepts a valid configuration', () {
      final config = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'timezone': 'UTC',
      });
      expect(validateSystemGeneralConfiguration(config), isEmpty);
    });

    test('rejects an empty hostname', () {
      final config = SystemGeneralConfiguration.fromConfig({
        'hostname': '',
        'timezone': 'UTC',
      });
      expect(validateSystemGeneralConfiguration(config), contains('hostname'));
    });

    test('rejects an empty timezone', () {
      final config = SystemGeneralConfiguration.fromConfig({
        'hostname': 'nas01',
        'timezone': '',
      });
      expect(validateSystemGeneralConfiguration(config), contains('timezone'));
    });
  });

  test('SystemSyslogLevel.fromApi falls back to default', () {
    expect(SystemSyslogLevel.fromApi('NOPE'), SystemSyslogLevel.defaultLevel);
    expect(SystemSyslogLevel.fromApi('DEBUG'), SystemSyslogLevel.debug);
  });
}
