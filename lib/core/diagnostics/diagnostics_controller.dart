import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_backend.dart';
import 'sentry_diagnostics.dart';

@immutable
class DiagnosticsSettings {
  const DiagnosticsSettings({
    this.enabled = true,
    this.isLoaded = false,
    this.isUpdating = false,
    this.updateFailed = false,
  });

  final bool enabled;
  final bool isLoaded;
  final bool isUpdating;
  final bool updateFailed;

  DiagnosticsSettings copyWith({
    bool? enabled,
    bool? isLoaded,
    bool? isUpdating,
    bool? updateFailed,
  }) => DiagnosticsSettings(
    enabled: enabled ?? this.enabled,
    isLoaded: isLoaded ?? this.isLoaded,
    isUpdating: isUpdating ?? this.isUpdating,
    updateFailed: updateFailed ?? this.updateFailed,
  );
}

final diagnosticsBackendProvider = Provider<DiagnosticsBackend>(
  (ref) => sentryDiagnosticsBackend,
);

final diagnosticsSettingsProvider =
    StateNotifierProvider<DiagnosticsController, DiagnosticsSettings>((ref) {
      return DiagnosticsController(ref.watch(diagnosticsBackendProvider))
        ..load();
    });

class DiagnosticsController extends StateNotifier<DiagnosticsSettings> {
  DiagnosticsController(this._backend) : super(const DiagnosticsSettings());

  static const preferenceKey = 'privacy.anonymous_diagnostics_enabled';

  final DiagnosticsBackend _backend;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final store = await _store;
    final enabled = store.getBool(preferenceKey) ?? true;
    state = state.copyWith(enabled: enabled, isLoaded: true);
  }

  Future<void> setEnabled(bool enabled) async {
    if (state.isUpdating || (state.isLoaded && state.enabled == enabled)) {
      return;
    }
    final previous = state.enabled;
    state = state.copyWith(
      enabled: enabled,
      isLoaded: true,
      isUpdating: true,
      updateFailed: false,
    );
    try {
      await _backend.setCollectionEnabled(enabled);
      await (await _store).setBool(preferenceKey, enabled);
      state = state.copyWith(isUpdating: false);
    } on Object {
      state = state.copyWith(
        enabled: previous,
        isUpdating: false,
        updateFailed: true,
      );
    }
  }

  void clearUpdateFailure() {
    if (state.updateFailed) state = state.copyWith(updateFailed: false);
  }

  static Future<bool> readPersistedSetting() async =>
      (await SharedPreferences.getInstance()).getBool(preferenceKey) ?? true;
}
