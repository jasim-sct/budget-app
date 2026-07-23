import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Reusable container with consistent padding, border, radius, and shadow.
/// No BackdropFilter blur – uses solid backgrounds for performance.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? glassColor;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 0,
    this.opacity = 0.05,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glassColor,
    this.borderColor,
    this.gradient,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultRadius = borderRadius ?? AppRadius.borderMd;

    final defaultBg = glassColor ??
        (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);

    final border = Border.all(
      color: borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      width: 1.0,
    );

    Widget container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: gradient == null ? defaultBg : null,
        gradient: gradient,
        borderRadius: defaultRadius,
        border: border,
        boxShadow: boxShadow ?? (isDark ? AppShadows.none : AppShadows.sm),
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: defaultRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}
