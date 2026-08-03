import 'package:flutter/material.dart';

/// Semantic chart colors derived entirely from the active Material 3 scheme.
///
/// This keeps metrics recognizable across overview and history screens while
/// allowing every user-selected seed color (and Android dynamic color) to
/// recolor the full chart family automatically.
class ChartPalette {
  const ChartPalette({
    required this.cpu,
    required this.memory,
    required this.load,
    required this.networkReceived,
    required this.networkSent,
    required this.diskReads,
    required this.diskWrites,
  });

  factory ChartPalette.fromScheme(ColorScheme colors) => ChartPalette(
    cpu: colors.primary,
    memory: colors.tertiary,
    load: colors.secondary,
    networkReceived: colors.primary,
    networkSent: colors.tertiary,
    diskReads: colors.secondary,
    diskWrites: colors.primary,
  );

  final Color cpu;
  final Color memory;
  final Color load;
  final Color networkReceived;
  final Color networkSent;
  final Color diskReads;
  final Color diskWrites;
}

extension ChartPaletteContext on BuildContext {
  ChartPalette get chartPalette =>
      ChartPalette.fromScheme(Theme.of(this).colorScheme);
}
