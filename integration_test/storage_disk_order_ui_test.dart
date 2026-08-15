import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:true_dock/features/resources/domain/server_resources.dart';
import 'package:true_dock/features/storage/presentation/storage_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('storage disk rows use natural device-name order', (
    tester,
  ) async {
    StorageDisk disk(String name) => StorageDisk(
      id: name,
      name: name,
      model: 'QEMU_HARDDISK',
      serial: name,
      type: 'HDD',
      sizeBytes: 32 * 1024 * 1024 * 1024,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StorageDiskList(
            disks: [
              disk('sdb'),
              disk('nvme10p1'),
              disk('sdc'),
              disk('nvme2p1'),
              disk('sda'),
            ],
            temperatures: const DiskTemperatureReport(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where((text) => text.contains('QEMU_HARDDISK'))
        .toList();
    expect(labels, [
      'nvme2p1 · QEMU_HARDDISK',
      'nvme10p1 · QEMU_HARDDISK',
      'sda · QEMU_HARDDISK',
      'sdb · QEMU_HARDDISK',
      'sdc · QEMU_HARDDISK',
    ]);
  });
}
