import 'package:flutter/material.dart';

import 'theme_controller.dart';

abstract final class AppTheme {
  static const defaultSeed = Color(0xFF2E999C);

  static ({ColorScheme light, ColorScheme dark}) resolveSchemes({
    required ThemeSettings settings,
    required ColorScheme? dynamicLight,
    required ColorScheme? dynamicDark,
  }) {
    if (settings.source == ThemeSource.systemDynamic &&
        dynamicLight != null &&
        dynamicDark != null) {
      return (light: dynamicLight, dark: dynamicDark);
    }

    return (
      light: ColorScheme.fromSeed(
        seedColor: settings.seedColor,
        brightness: Brightness.light,
      ),
      dark: ColorScheme.fromSeed(
        seedColor: settings.seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  static ThemeData build(ColorScheme colors) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      brightness: colors.brightness,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        // Administrative validation and guidance often names a server rule,
        // resource, and consequence. Keep the full text visible on phones
        // instead of silently replacing the end with an ellipsis.
        errorMaxLines: 20,
        helperMaxLines: 10,
        // Keep labels inside the field. Once a value is present the label is
        // hidden instead of cutting a notch through the rounded outline.
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surfaceContainer,
        indicatorColor: colors.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surfaceContainer,
        indicatorColor: colors.secondaryContainer,
        useIndicator: true,
        labelType: NavigationRailLabelType.all,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
