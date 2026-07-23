import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Typography Scale.
/// Limited to 4 weights: w400 (regular), w500 (medium), w600 (semibold), w700 (bold).
abstract class AppTypography {
  /// 32px bold – hero numbers (balance, net worth).
  static TextStyle displayLarge(bool isDark) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 24px semibold – page-level summaries.
  static TextStyle displayMedium(bool isDark) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 18px semibold – section / card titles.
  static TextStyle headline(bool isDark) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 15px semibold – row titles, bold labels.
  static TextStyle titleLarge(bool isDark) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 13px semibold – list item titles, button labels.
  static TextStyle titleMedium(bool isDark) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 14px regular – body text, descriptions.
  static TextStyle bodyLarge(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

  /// 13px regular – secondary body text.
  static TextStyle bodyMedium(bool isDark) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  /// 12px regular – captions, timestamps, supporting info.
  static TextStyle caption(bool isDark) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  /// 11px medium uppercase – section headers, category labels.
  static TextStyle sectionLabel(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.3,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  /// 11px medium – small labels, badges, meta info.
  static TextStyle labelSmall(bool isDark) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.3,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      );

  /// Currency / financial number display.
  static TextStyle currency(bool isDark, {double fontSize = 24, FontWeight fontWeight = FontWeight.w700, Color? color}) => TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
        height: 1.2,
        color: color ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
      );
}
