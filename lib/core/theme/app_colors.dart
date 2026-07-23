import 'package:flutter/material.dart';

/// Restrained, Enterprise-Grade Fintech Color Palette.
/// Single primary accent. Semantic-only color usage.
class AppColors {
  AppColors._();

  // ── Dark Mode Surfaces ──
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF141C2E);
  static const Color darkSurfaceLight = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF233044);
  static const Color darkCardBg = Color(0xFF141C2E);

  // ── Light Mode Surfaces ──
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightCardBg = Color(0xFFFFFFFF);

  // ── Primary Action Color ──
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF3B82F6);

  // ── Semantic / Financial Status Colors ──
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color transferBlue = Color(0xFF3B82F6);
  static const Color infoGray = Color(0xFF64748B);

  // ── Typography Colors ──
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ── Compatibility aliases (mapped to primary blue) ──
  static const Color primaryEmerald = primaryBlue;
  static const Color primaryEmeraldDark = primaryBlueDark;
  static const Color accentViolet = primaryBlue;
  static const Color accentIndigo = primaryBlue;
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accentAmber = warningOrange;
  static const Color accentRose = expenseRed;
  static const Color accentSky = Color(0xFF0EA5E9);

  // ── Minimal Gradient (Primary button / hero only) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Legacy gradient aliases (flat-mapped for compat) ──
  static const LinearGradient violetGradient = primaryGradient;
  static const LinearGradient neonMeshGradient = primaryGradient;

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [darkCardBg, darkCardBg],
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [lightCardBg, lightCardBg],
  );

  // ── Glass overlay aliases (kept for backward compatibility) ──
  static const Color darkGlassBorder = darkBorder;
  static const Color darkGlassOverlay = darkSurface;
  static const Color lightGlassBorder = lightBorder;
  static const Color lightGlassOverlay = lightSurface;
}
