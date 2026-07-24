import 'package:flutter/material.dart';

/// Trust-First Financial Color System.
/// Calm, professional, semantic-only color usage.
/// No decorative colors — every color communicates meaning.
class AppColors {
  AppColors._();

  // ── Dark Mode Surfaces ──
  static const Color darkBackground = Color(0xFF0C1017);
  static const Color darkSurface = Color(0xFF151B28);
  static const Color darkSurfaceElevated = Color(0xFF1C2436);
  static const Color darkSurfaceSubtle = Color(0xFF111722);
  static const Color darkBorder = Color(0xFF243044);
  static const Color darkCardBg = Color(0xFF151B28);

  // ── Light Mode Surfaces ──
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F4F8);
  static const Color lightBorder = Color(0xFFE4E8EE);
  static const Color lightCardBg = Color(0xFFFFFFFF);

  // ── Primary Accent ──
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF3B82F6);

  // ── Semantic / Financial Status ──
  static const Color incomeGreen = Color(0xFF10B981);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color transferBlue = Color(0xFF3B82F6);
  static const Color infoGray = Color(0xFF64748B);
  static const Color accentTeal = Color(0xFF0D9488);

  // ── Typography ──
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF8896AB);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ── Semantic helpers ──
  static Color statusBackground(Color statusColor) =>
      statusColor.withValues(alpha: 0.10);
  static Color statusForeground(Color statusColor) => statusColor;

  // ── Compatibility aliases ──
  static const Color darkSurfaceLight = darkSurfaceElevated;
  static const Color primaryEmerald = primaryBlue;
  static const Color primaryEmeraldDark = primaryBlueDark;
  static const Color accentViolet = primaryBlue;
  static const Color accentIndigo = primaryBlue;
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accentAmber = warningOrange;
  static const Color accentRose = expenseRed;
  static const Color accentSky = Color(0xFF0EA5E9);
  static const Color emerald = incomeGreen;
  static const Color rose = expenseRed;
  static const Color amber = warningOrange;
  static const Color cyan = accentCyan;
  static const Color textSecondary = darkTextSecondary;
  static const Color glassBorder = darkBorder;
  static const Color surfaceDark = darkSurface;

  // ── Minimal Gradient (primary hero only) ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = primaryGradient;
  static const LinearGradient neonMeshGradient = primaryGradient;

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [darkCardBg, darkCardBg],
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [lightCardBg, lightCardBg],
  );

  static const Color darkGlassBorder = darkBorder;
  static const Color darkGlassOverlay = darkSurface;
  static const Color lightGlassBorder = lightBorder;
  static const Color lightGlassOverlay = lightSurface;
}
