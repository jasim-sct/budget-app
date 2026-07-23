import 'package:flutter/material.dart';

/// Centralized Spacing, Radius, and Shadow Tokens (4pt/8pt grid).
abstract class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

abstract class AppRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double pill = 999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

abstract class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> neonGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.50),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];
}
