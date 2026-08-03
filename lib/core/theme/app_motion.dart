import 'package:flutter/material.dart';

/// Shared Material motion timings for TrueDock.
///
/// Every custom animation resolves through [BuildContext.motionDuration]. This
/// makes the in-app reduced-motion preference and the operating system's
/// accessibility preference authoritative without scattering conditionals
/// through feature widgets.
abstract final class AppMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const emphasized = Duration(milliseconds: 360);

  static const standardCurve = Curves.easeInOutCubicEmphasized;
  static const exitCurve = Curves.easeInCubic;
}

extension AppMotionContext on BuildContext {
  bool get animationsReduced =>
      MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  Duration motionDuration(Duration duration) =>
      animationsReduced ? Duration.zero : duration;
}
