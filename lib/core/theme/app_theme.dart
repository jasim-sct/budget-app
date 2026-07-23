import 'package:flutter/material.dart';

/// Ultra-lightweight Theme System optimized for low-end GPUs.
/// Avoids Material 3 dynamic color generation runtime overhead.
/// Uses flat ARGB colors to prevent offscreen render target allocations.
abstract class AppTheme {
  // Pre-instantiated ARGB Color constants (no runtime instantiation)
  static const Color primary = Color(0xFF107C41);
  static const Color background = Color(0xFFF4F6F8);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color incomeGreen = Color(0xFF059669);
  static const Color expenseRed = Color(0xFFDC2626);
  static const Color divider = Color(0xFFE5E7EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false, // Disables M3 ripple & elevation calculation overhead
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      splashFactory: NoSplash.splashFactory, // Removes CPU ripple animation frames
      highlightColor: Colors.transparent,
      dividerColor: divider,
      fontFamily: null, // Uses default system font to save font asset RAM
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
