import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, gradient, danger }

/// Professional button component with consistent sizing and loading feedback.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 44.0,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;
    final radius = BorderRadius.circular(borderRadius ?? AppRadius.sm);

    Color bgColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.gradient:
        bgColor = AppColors.primaryBlue;
        textColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        );
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.expenseRed;
        textColor = Colors.white;
        break;
    }

    if (isDisabled && variant != AppButtonVariant.ghost) {
      bgColor = isDark ? AppColors.darkSurfaceLight.withValues(alpha: 0.5) : AppColors.lightSurfaceSecondary;
      textColor = isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.lightTextSecondary;
      border = null;
    }

    final childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: radius,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: radius,
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border,
            ),
            child: Center(child: childContent),
          ),
        ),
      ),
    );
  }
}
