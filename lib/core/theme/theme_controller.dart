import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

enum ThemeSource { systemDynamic, brand, custom }

@immutable
class ThemeSettings {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.source = ThemeSource.systemDynamic,
    this.seedColor = AppTheme.defaultSeed,
    this.reduceAnimations = false,
  });

  final ThemeMode mode;
  final ThemeSource source;
  final Color seedColor;
  final bool reduceAnimations;

  ThemeSettings copyWith({
    ThemeMode? mode,
    ThemeSource? source,
    Color? seedColor,
    bool? reduceAnimations,
  }) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      source: source ?? this.source,
      seedColor: seedColor ?? this.seedColor,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    );
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeSettings>((ref) {
      return ThemeController(
        initialSource: defaultTargetPlatform == TargetPlatform.android
            ? ThemeSource.systemDynamic
            : ThemeSource.brand,
      )..load();
    });

class ThemeController extends StateNotifier<ThemeSettings> {
  ThemeController({required ThemeSource initialSource})
    : super(ThemeSettings(source: initialSource));

  static const _modeKey = 'appearance.theme_mode';
  static const _sourceKey = 'appearance.theme_source';
  static const _seedKey = 'appearance.seed_color';
  static const _reduceAnimationsKey = 'accessibility.reduce_animations';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _store async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> load() async {
    final preferences = await _store;
    final modeName = preferences.getString(_modeKey);
    final sourceName = preferences.getString(_sourceKey);
    final seedValue = preferences.getInt(_seedKey);
    final reduceAnimations = preferences.getBool(_reduceAnimationsKey);

    state = ThemeSettings(
      mode:
          ThemeMode.values
              .where((value) => value.name == modeName)
              .firstOrNull ??
          ThemeMode.system,
      source:
          ThemeSource.values
              .where((value) => value.name == sourceName)
              .firstOrNull ??
          state.source,
      seedColor: seedValue == null ? AppTheme.defaultSeed : Color(seedValue),
      reduceAnimations: reduceAnimations ?? false,
    );
  }

  Future<void> setMode(ThemeMode value) async {
    state = state.copyWith(mode: value);
    await (await _store).setString(_modeKey, value.name);
  }

  Future<void> setSource(ThemeSource value, {Color? seedColor}) async {
    state = state.copyWith(source: value, seedColor: seedColor);
    final preferences = await _store;
    await preferences.setString(_sourceKey, value.name);
    if (seedColor != null) {
      await preferences.setInt(_seedKey, seedColor.toARGB32());
    }
  }

  Future<void> setReduceAnimations(bool value) async {
    state = state.copyWith(reduceAnimations: value);
    await (await _store).setBool(_reduceAnimationsKey, value);
  }
}
