import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum GlassButtonVariant { primary, secondary, gradient, danger }

/// Professional button – delegates to same styling as AppButton.
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double? borderRadius;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 44.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;
    final radius = BorderRadius.circular(borderRadius ?? AppRadius.sm);

    Color bgColor;
    Color textColor;

    switch (variant) {
      case GlassButtonVariant.primary:
      case GlassButtonVariant.gradient:
        bgColor = AppColors.primaryBlue;
        textColor = Colors.white;
        break;
      case GlassButtonVariant.secondary:
        bgColor = isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case GlassButtonVariant.danger:
        bgColor = AppColors.expenseRed;
        textColor = Colors.white;
        break;
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
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: Material(
        color: bgColor,
        borderRadius: radius,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
            ),
            child: Center(child: childContent),
          ),
        ),
      ),
    );
  }
}
