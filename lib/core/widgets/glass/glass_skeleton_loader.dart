import 'package:flutter/material.dart';
import 'glass_card.dart';

class GlassSkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;

  const GlassSkeletonLoader({
    super.key,
    this.height = 72,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  @override
  State<GlassSkeletonLoader> createState() => _GlassSkeletonLoaderState();
}

class _GlassSkeletonLoaderState extends State<GlassSkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: _animation.value * 0.15)
                  : Colors.black.withValues(alpha: _animation.value * 0.08),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
