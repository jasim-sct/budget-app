import 'package:flutter/material.dart';

/// Centralized Design Tokens for Apple VisionOS / macOS Big Sur inspired Glassmorphism.
abstract class GlassTokens {
  // Blur Intensities
  static const double blurSm = 8.0;
  static const double blurMd = 16.0;
  static const double blurLg = 24.0;
  static const double blurXl = 32.0;

  // Glass Opacities
  static const double opacitySubtle = 0.08;
  static const double opacityLow = 0.15;
  static const double opacityMd = 0.25;
  static const double opacityHigh = 0.40;

  // Glass Frosted Colors
  static const Color darkGlassBg = Color(0x35131B2E);
  static const Color darkGlassSurface = Color(0x451E293B);
  static const Color lightGlassBg = Color(0x60FFFFFF);
  static const Color lightGlassSurface = Color(0x90F8FAFC);

  // Border Highlights & Reflection Stroking
  static const Color borderHighlightLight = Color(0x55FFFFFF);
  static const Color borderHighlightDark = Color(0x25FFFFFF);
  static const Color borderSubtleDark = Color(0x20334155);

  // Ambient Glow Accents
  static const Color glowEmerald = Color(0xFF10B981);
  static const Color glowIndigo = Color(0xFF6366F1);
  static const Color glowViolet = Color(0xFF8B5CF6);
  static const Color glowCyan = Color(0xFF06B6D4);
  static const Color glowAmber = Color(0xFFF59E0B);
  static const Color glowRose = Color(0xFFF43F5E);

  // Glass Linear Border Gradients
  static const LinearGradient glassBorderGradientDark = LinearGradient(
    colors: [
      Color(0x45FFFFFF),
      Color(0x10FFFFFF),
      Color(0x30334155),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderGradientLight = LinearGradient(
    colors: [
      Color(0x77FFFFFF),
      Color(0x33FFFFFF),
      Color(0x22CBD5E1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
