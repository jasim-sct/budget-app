import 'package:flutter/material.dart';

/// Centralized Spacing, Radius, and Shadow Tokens (strict 8px grid).
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
  /// No shadow.
  static const List<BoxShadow> none = [];

  /// Subtle shadow for flat cards and inputs.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Default card elevation.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevated elements (FABs, modals, dropdowns).
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ── Legacy aliases (kept for backward compatibility) ──
  static const List<BoxShadow> soft = sm;
  static const List<BoxShadow> card = md;
  static const List<BoxShadow> floating = lg;

  static List<BoxShadow> glow(Color color) => md;
  static List<BoxShadow> neonGlow(Color color) => md;
}
