import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/glass_tokens.dart';

/// Reusable GlassContainer featuring BackdropFilter blur, semi-transparent frosted background,
/// linear border highlights, and soft ambient shadow reflections.
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
    this.blur = GlassTokens.blurMd,
    this.opacity = GlassTokens.opacityMd,
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
        (isDark ? GlassTokens.darkGlassBg : GlassTokens.lightGlassBg);

    final border = Border.all(
      color: borderColor ?? (isDark ? GlassTokens.borderHighlightDark : GlassTokens.borderHighlightLight),
      width: 1.2,
    );

    Widget frostedBox = Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: gradient == null ? defaultBg : null,
              gradient: gradient,
              borderRadius: defaultRadius,
              border: border,
              boxShadow: boxShadow ?? AppShadows.card,
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: defaultRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultRadius,
          child: frostedBox,
        ),
      );
    }

    return frostedBox;
  }
}
