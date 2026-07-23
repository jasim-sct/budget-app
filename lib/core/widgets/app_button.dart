import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, gradient, danger }

/// Premium animated button component with scale micro-interaction and loading feedback.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 52.0,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
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

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    Color bgColor;
    Color textColor;
    Border? border;
    Gradient? gradient;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primaryEmerald;
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.primaryEmerald);
        break;
      case AppButtonVariant.gradient:
        bgColor = Colors.transparent;
        gradient = AppColors.primaryGradient;
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.primaryEmerald);
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
          width: 1.5,
        );
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.expenseRed;
        textColor = Colors.white;
        shadow = AppShadows.glow(AppColors.expenseRed);
        break;
    }

    if (isDisabled && widget.variant != AppButtonVariant.ghost) {
      bgColor = isDark ? AppColors.darkSurfaceLight.withValues(alpha: 0.5) : AppColors.lightSurfaceSecondary;
      textColor = isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.lightTextSecondary;
      gradient = null;
      shadow = null;
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
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: Container(
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: gradient,
            borderRadius: AppRadius.borderMd,
            border: border,
            boxShadow: isDisabled ? null : shadow,
          ),
          child: Center(child: childContent),
        ),
      ),
    );
  }
}
