import 'package:flutter/material.dart';

/// Motion language for the Financial Operating System.
/// Every duration/curve answers: what changed, where from/to, what to notice.
abstract class AppDurations {
  /// Micro press / chip select
  static const Duration instant = Duration(milliseconds: 90);

  /// Button feedback, chip morph, focus ring
  static const Duration fast = Duration(milliseconds: 150);

  /// Card elevation, list item settle, toast enter
  static const Duration normal = Duration(milliseconds: 250);

  /// Number tween, progress fill, panel expand
  static const Duration emphasized = Duration(milliseconds: 360);

  /// Page / sheet transitions
  static const Duration page = Duration(milliseconds: 280);

  /// Longer contextual morphs (rare)
  static const Duration slow = Duration(milliseconds: 420);

  /// Legacy aliases
  static const Duration pageTransition = page;
}

abstract class AppCurves {
  /// Primary UI motion — calm deceleration
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized attention (totals, health score)
  static const Curve emphasized = Curves.fastOutSlowIn;

  /// Entering surfaces (sheets, overlays)
  static const Curve enter = Curves.easeOutCubic;

  /// Exiting surfaces
  static const Curve exit = Curves.easeInCubic;

  /// Press / release micro-feedback
  static const Curve press = Curves.easeOutCubic;
}

/// Soft structural depth — hierarchy, not decoration.
abstract class AppElevation {
  static const List<BoxShadow> level0 = [];

  /// Resting cards / inputs
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Raised interactive surfaces
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  /// Floating bars / sheets / dialogs
  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static List<BoxShadow> forLevel(int level, {required bool isDark}) {
    final base = switch (level) {
      0 => level0,
      1 => level1,
      2 => level2,
      _ => level3,
    };
    if (!isDark || base.isEmpty) return base;
    // Slightly stronger in dark mode for readable separation without glow.
    return base
        .map(
          (s) => BoxShadow(
            color: Color.fromRGBO(0, 0, 0, isDark ? 0.35 : 0.04),
            blurRadius: s.blurRadius,
            offset: s.offset,
          ),
        )
        .toList();
  }
}
