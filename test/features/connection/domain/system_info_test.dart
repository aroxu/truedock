import 'package:flutter_test/flutter_test.dart';
import 'package:true_dock/features/connection/domain/system_info.dart';

void main() {
  test('removes fractional milliseconds from uptime', () {
    final info = SystemInfo.fromJson({
      'hostname': 'nas',
      'version': '25.10.6',
      'uptime': '1 day, 08:14:37.582319',
      'uptime_seconds': 116077.582319,
      'physmem': 1024,
      'model': 'CPU',
      'cores': 4,
    });

    expect(info.uptime, '1 day, 08:14:37');
    expect(info.uptimeSeconds, 116077.582319);
  });

  test('does not alter unrelated version-like values in uptime text', () {
    final info = SystemInfo.fromJson({
      'uptime': '12.345 seconds',
      'version': '25.10.6',
    });

    expect(info.uptime, '12 seconds');
    expect(info.version, '25.10.6');
  });
}
