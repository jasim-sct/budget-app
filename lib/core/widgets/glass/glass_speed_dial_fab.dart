import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SpeedDialOption {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SpeedDialOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class GlassSpeedDialFab extends StatefulWidget {
  final List<SpeedDialOption> options;

  const GlassSpeedDialFab({
    super.key,
    required this.options,
  });

  @override
  State<GlassSpeedDialFab> createState() => _GlassSpeedDialFabState();
}

class _GlassSpeedDialFabState extends State<GlassSpeedDialFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // Backdrop overlay when open
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

        // Speed Dial Options
        Positioned(
          bottom: 72,
          child: ScaleTransition(
            scale: _expandAnimation,
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        _toggle();
                        option.onTap();
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xDC1E293B) : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: option.color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(option.icon, color: option.color, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Main FAB Button
        FloatingActionButton(
          heroTag: 'global_speed_dial_fab',
          onPressed: _toggle,
          elevation: 8,
          backgroundColor: AppColors.primaryEmerald,
          shape: const CircleBorder(),
          child: RotationTransition(
            turns: _rotateAnimation,
            child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
