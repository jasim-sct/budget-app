import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Tactile press feedback — scale communicates “this accepted input”.
class AppMicroPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;

  const AppMicroPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.975,
    this.duration = AppDurations.instant,
    this.curve = AppCurves.press,
  });

  @override
  State<AppMicroPressable> createState() => _AppMicroPressableState();
}

class _AppMicroPressableState extends State<AppMicroPressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _setPressed(false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
