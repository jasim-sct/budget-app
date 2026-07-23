import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/glass_tokens.dart';

enum GlassButtonVariant { primary, secondary, gradient, danger }

/// Frosted Glass Button component with glowing edges and scale micro-animations.
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color glassBg;
    Color textColor;
    Gradient? gradient;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case GlassButtonVariant.primary:
        glassBg = AppColors.primaryEmerald.withValues(alpha: 0.85);
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.primaryEmerald);
        break;
      case GlassButtonVariant.gradient:
        glassBg = Colors.transparent;
        gradient = AppColors.primaryGradient;
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.primaryEmerald);
        break;
      case GlassButtonVariant.secondary:
        glassBg = isDark ? const Color(0x351E293B) : const Color(0x70FFFFFF);
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case GlassButtonVariant.danger:
        glassBg = AppColors.expenseRed.withValues(alpha: 0.85);
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.expenseRed);
        break;
    }

    final childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: textColor,
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => !isDisabled ? _controller.forward() : null,
        onTapUp: (_) => !isDisabled ? _controller.reverse() : null,
        onTapCancel: () => !isDisabled ? _controller.reverse() : null,
        onTap: isDisabled ? null : widget.onPressed,
        child: ClipRRect(
          borderRadius: AppRadius.borderMd,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: GlassTokens.blurMd, sigmaY: GlassTokens.blurMd),
            child: Container(
              width: widget.isFullWidth ? double.infinity : null,
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: gradient == null ? glassBg : null,
                gradient: gradient,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: isDark ? GlassTokens.borderHighlightDark : GlassTokens.borderHighlightLight,
                  width: 1.2,
                ),
                boxShadow: shadow,
              ),
              child: Center(child: childContent),
            ),
          ),
        ),
      ),
    );
  }
}
