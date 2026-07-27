import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Centralized Theme System supplying Light and Dark theme configurations.
abstract class AppTheme {
  // ── Legacy Static Accessors (backward compat) ──
  static const Color primary = AppColors.primaryBlue;
  static const Color background = AppColors.lightBackground;
  static const Color cardBg = AppColors.lightCardBg;
  static const Color textPrimary = AppColors.lightTextPrimary;
  static const Color textSecondary = AppColors.lightTextSecondary;
  static const Color incomeGreen = AppColors.incomeGreen;
  static const Color expenseRed = AppColors.expenseRed;
  static const Color divider = AppColors.lightBorder;

  static const Color darkBg = AppColors.darkBackground;
  static const Color darkCard = AppColors.darkCardBg;
  static const Color darkTextPri = AppColors.darkTextPrimary;
  static const Color darkTextSec = AppColors.darkTextSecondary;
  static const Color darkBorderColor = AppColors.darkBorder;

  // ── Shared component constants ──

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      pageTransitionsTheme: const AppPageTransitionsTheme(),
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
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
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.md,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          side: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.lightTextSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
        backgroundColor: AppColors.lightSurfaceSecondary,
        selectedColor: AppColors.primaryBlue,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        extendedTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      pageTransitionsTheme: const AppPageTransitionsTheme(),
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
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
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.md,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        elevation: 4,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.expenseRed, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontSize: 13,
          color: AppColors.darkTextSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        backgroundColor: AppColors.darkTextPrimary,
        contentTextStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkBackground,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
        backgroundColor: AppColors.darkSurfaceLight,
        selectedColor: AppColors.primaryBlue,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        extendedTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
