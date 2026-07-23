import 'package:flutter/material.dart';

/// Commercial Design System Color Palette & VisionOS Gradient Tokens.
class AppColors {
  AppColors._();

  // Dark Mode Glass Palette (VisionOS Slate & Obsidian)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceLight = Color(0xFF334155);
  static const Color darkGlassBorder = Color(0x33FFFFFF);
  static const Color darkGlassOverlay = Color(0x1FFFFFFF);
  static const Color darkBorder = Color(0x1AFFFFFF);
  static const Color darkCardBg = Color(0xFF1E293B);

  // Light Mode Glass Palette (macOS Big Sur Frosted Ice)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightGlassBorder = Color(0x35000000);
  static const Color lightGlassOverlay = Color(0x66FFFFFF);
  static const Color lightBorder = Color(0x0F000000);
  static const Color lightCardBg = Color(0xFFFFFFFF);

  // Brand Accents
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryEmeraldDark = Color(0xFF059669);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentSky = Color(0xFF0EA5E9);

  // Financial Status Colors
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color transferBlue = Color(0xFF3B82F6);
  static const Color warningOrange = Color(0xFFF59E0B);

  // Typography Colors
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // VisionOS Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A), Color(0xFF064E3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0284C7), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonMeshGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
