import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/core/widgets/device_data_reset_confirmation.dart';

void main() {
  test('reset code has two mixed alphanumeric groups', () {
    final code = generateDeviceDataResetCode(random: Random(7));

    expect(code, matches(RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$')));
    for (final group in code.split('-')) {
      expect(group, contains(RegExp('[A-Z]')));
      expect(group, contains(RegExp('[0-9]')));
    }
  });

  test('formatter uppercases and inserts the separator', () {
    const formatter = DeviceDataResetCodeFormatter();
    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'a7k2p9m4extra'),
    );

    expect(value.text, 'A7K2-P9M4');
    expect(value.selection.baseOffset, value.text.length);
  });
}
