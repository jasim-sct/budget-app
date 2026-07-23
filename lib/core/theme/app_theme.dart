import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Centralized Theme System supplying Light and Dark theme configurations.
abstract class AppTheme {
  // Legacy & Compatibility Static Accessors
  static const Color primary = AppColors.primaryEmerald;
  static const Color background = AppColors.lightBackground;
  static const Color cardBg = AppColors.lightCardBg;
  static const Color textPrimary = AppColors.lightTextPrimary;
  static const Color textSecondary = AppColors.lightTextSecondary;
  static const Color incomeGreen = AppColors.incomeGreen;
  static const Color expenseRed = AppColors.expenseRed;
  static const Color divider = AppColors.lightBorder;

  // Dark legacy static accessors
  static const Color darkBg = AppColors.darkBackground;
  static const Color darkCard = AppColors.darkCardBg;
  static const Color darkTextPri = AppColors.darkTextPrimary;
  static const Color darkTextSec = AppColors.darkTextSecondary;
  static const Color darkBorderColor = AppColors.darkBorder;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primaryEmerald,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryEmerald,
        secondary: AppColors.accentIndigo,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.expenseRed,
      ),
      dividerColor: AppColors.lightBorder,
      cardTheme: const CardThemeData(
        color: AppColors.lightCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        elevation: 12,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryEmerald,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryEmerald,
        secondary: AppColors.accentViolet,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.expenseRed,
      ),
      dividerColor: AppColors.darkBorder,
      cardTheme: const CardThemeData(
        color: AppColors.darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        elevation: 12,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
    );
  }
}
