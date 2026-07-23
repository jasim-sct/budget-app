import 'package:flutter/material.dart';

/// Simplified Glass Design Tokens – subtle fills and borders only.
/// No decorative blur, glow, or neon effects.
abstract class GlassTokens {
  // Ultra-Subtle Blur Intensities (if ever used)
  static const double blurSm = 4.0;
  static const double blurMd = 8.0;
  static const double blurLg = 12.0;
  static const double blurXl = 16.0;

  // Opacity Tokens
  static const double opacitySubtle = 0.02;
  static const double opacityLow = 0.05;
  static const double opacityMd = 0.10;
  static const double opacityHigh = 0.15;

  // Glass Surface Fills (solid, not transparent)
  static const Color darkGlassBg = Color(0xFF141C2E);
  static const Color darkGlassSurface = Color(0xFF141C2E);
  static const Color lightGlassBg = Color(0xFFFFFFFF);
  static const Color lightGlassSurface = Color(0xFFFFFFFF);

  // Border Colors
  static const Color borderHighlightLight = Color(0xFFE2E8F0);
  static const Color borderHighlightDark = Color(0xFF233044);
  static const Color borderSubtleDark = Color(0xFF233044);

  // Semantic Accent Colors (for chart / indicator usage only)
  static const Color glowEmerald = Color(0xFF10B981);
  static const Color glowIndigo = Color(0xFF2563EB);
  static const Color glowViolet = Color(0xFF2563EB);
  static const Color glowCyan = Color(0xFF0284C7);
  static const Color glowAmber = Color(0xFFF59E0B);
  static const Color glowRose = Color(0xFFEF4444);

  // Flat Border Fills (no gradient shimmer)
  static const LinearGradient glassBorderGradientDark = LinearGradient(
    colors: [Color(0xFF233044), Color(0xFF233044)],
  );

  static const LinearGradient glassBorderGradientLight = LinearGradient(
    colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
  );
}
