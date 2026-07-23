import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'glass_container.dart';

/// VisionOS Ultra-Premium Glass Card Widget with gradient borders and scale animations.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.borderRadius = 20,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = Border.all(
      color: widget.borderColor ??
          (isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08)),
      width: 1.2,
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.35) : AppColors.primaryEmerald.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
            gradient: widget.gradient,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
