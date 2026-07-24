import 'package:flutter/material.dart';

import 'app_motion.dart';
export 'app_motion.dart';

/// Centralized Spacing, Radius, Shadow, and Duration Tokens.
abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Standard page horizontal padding.
  static const double pagePadding = 16.0;

  /// Semantic spacing tokens.
  static const double sectionGap = 20.0;
  static const double cardInner = 14.0;
  static const double screenPadding = 16.0;
}

abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

abstract class AppShadows {
  static const List<BoxShadow> none = AppElevation.level0;
  static const List<BoxShadow> sm = AppElevation.level1;
  static const List<BoxShadow> md = AppElevation.level2;
  static const List<BoxShadow> lg = AppElevation.level3;

  static const List<BoxShadow> soft = sm;
  static const List<BoxShadow> card = md;
  static const List<BoxShadow> floating = lg;

  static List<BoxShadow> glow(Color color) => md;
  static List<BoxShadow> neonGlow(Color color) => md;
}
