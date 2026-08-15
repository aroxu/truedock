import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/system/domain/tunable_configuration.dart';

void main() {
  test('create payload matches the TrueNAS 25.10 schema', () {
    const configuration = TunableConfiguration(
      type: TunableType.zfs,
      variable: ' zfs_dirty_data_max_max ',
      value: ' 783091712 ',
      comment: ' cache limit ',
      enabled: false,
      updateInitramfs: false,
    );

    expect(configuration.toCreateApiJson(), {
      'type': 'ZFS',
      'var': 'zfs_dirty_data_max_max',
      'value': '783091712',
      'comment': 'cache limit',
      'enabled': false,
      'update_initramfs': false,
    });
  });

  test('update payload cannot change the immutable type or variable', () {
    const configuration = TunableConfiguration(
      type: TunableType.udev,
      variable: '10-disable-usb',
      value: 'ACTION=="add"',
      comment: 'test',
    );

    expect(configuration.toUpdateApiJson(), {
      'value': 'ACTION=="add"',
      'comment': 'test',
      'enabled': true,
      'update_initramfs': true,
    });
  });

  test('decodes server entry and original value', () {
    final tunable = Tunable.fromJson({
      'id': 7,
      'type': 'SYSCTL',
      'var': 'kernel.watchdog',
      'value': '0',
      'orig_value': '1',
      'comment': '',
      'enabled': true,
      'update_initramfs': true,
    });

    expect(tunable.id, 7);
    expect(tunable.configuration.type, TunableType.sysctl);
    expect(tunable.configuration.variable, 'kernel.watchdog');
    expect(tunable.originalValue, '1');
  });

  test(
    'requires both variable and value without inventing extra constraints',
    () {
      final issues = const TunableConfiguration(
        variable: ' ',
        value: '',
      ).validate();
      expect(issues.map((issue) => issue.code), {
        TunableValidationCode.variableRequired,
        TunableValidationCode.valueRequired,
      });
    },
  );
}
