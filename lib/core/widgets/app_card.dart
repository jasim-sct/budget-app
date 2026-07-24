import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_micro_pressable.dart';

/// Unified card component with optional left accent edge.
/// Single card language across the entire application.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? accentColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBg = backgroundColor ??
        (isDark
            ? (elevated ? AppColors.darkSurfaceElevated : AppColors.darkCardBg)
            : (elevated ? AppColors.lightSurfaceElevated : AppColors.lightCardBg));

    final effectiveRadius = borderRadius ?? AppRadius.borderMd;

    final card = Container(
      clipBehavior: (accentColor != null || borderRadius != null) ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: elevated ? AppShadows.sm : AppShadows.none,
      ),
      child: accentColor != null
          ? IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 3,
                    color: accentColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: padding ?? const EdgeInsets.all(AppSpacing.cardInner),
                      child: child,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.cardInner),
              child: child,
            ),
    );

    if (onTap != null) {
      return AppMicroPressable(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
