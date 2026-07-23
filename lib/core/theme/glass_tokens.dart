import 'package:flutter/material.dart';

/// Centralized Design Tokens for Apple VisionOS / macOS Big Sur inspired Glassmorphism.
abstract class GlassTokens {
  // Ultra-Heavy Frosted Blur Intensities
  static const double blurSm = 14.0;
  static const double blurMd = 28.0;
  static const double blurLg = 42.0;
  static const double blurXl = 60.0;

  // Glass Opacities
  static const double opacitySubtle = 0.08;
  static const double opacityLow = 0.15;
  static const double opacityMd = 0.25;
  static const double opacityHigh = 0.40;

  // Glass Frosted Colors
  static const Color darkGlassBg = Color(0x40131B2E);
  static const Color darkGlassSurface = Color(0x551E293B);
  static const Color lightGlassBg = Color(0x75FFFFFF);
  static const Color lightGlassSurface = Color(0xAAFFFFFF);

  // Border Highlights & Reflection Stroking
  static const Color borderHighlightLight = Color(0x65FFFFFF);
  static const Color borderHighlightDark = Color(0x30FFFFFF);
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
      Color(0x55FFFFFF),
      Color(0x15FFFFFF),
      Color(0x40334155),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderGradientLight = LinearGradient(
    colors: [
      Color(0x88FFFFFF),
      Color(0x44FFFFFF),
      Color(0x33CBD5E1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
