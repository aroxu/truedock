import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_dock/core/diagnostics/diagnostics_backend.dart';
import 'package:true_dock/core/diagnostics/diagnostics_controller.dart';

class _Backend implements DiagnosticsBackend {
  bool fail = false;
  final List<bool> changes = [];

  @override
  bool get isConfigured => true;

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    changes.add(enabled);
    if (fail) throw StateError('diagnostic backend failed');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('anonymous diagnostics default to enabled', () async {
    final controller = DiagnosticsController(_Backend());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.isLoaded, isTrue);
    expect(controller.state.enabled, isTrue);
  });

  test('persisted opt-out is restored', () async {
    SharedPreferences.setMockInitialValues({
      DiagnosticsController.preferenceKey: false,
    });
    final controller = DiagnosticsController(_Backend());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.state.enabled, isFalse);
  });

  test('changing collection updates the backend and preference', () async {
    final backend = _Backend();
    final controller = DiagnosticsController(backend);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(false);

    expect(backend.changes, [false]);
    expect(controller.state.enabled, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        DiagnosticsController.preferenceKey,
      ),
      isFalse,
    );
  });

  test('backend failure restores the previous preference', () async {
    final backend = _Backend()..fail = true;
    final controller = DiagnosticsController(backend);
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(false);

    expect(controller.state.enabled, isTrue);
    expect(controller.state.updateFailed, isTrue);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        DiagnosticsController.preferenceKey,
      ),
      isFalse,
    );
  });
}
