import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../utils/formatters.dart';

/// Animated number text — communicates “this value changed” without abrupt jumps.
class AnimatedNumberText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String Function(double)? formatter;
  final Duration duration;
  final Curve curve;

  const AnimatedNumberText({
    super.key,
    required this.value,
    required this.style,
    this.formatter,
    this.duration = AppDurations.emphasized,
    this.curve = AppCurves.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedVal, _) {
        final text = formatter != null
            ? formatter!(animatedVal)
            : AppFormatters.currency(animatedVal);
        return Text(
          text,
          style: style,
        );
      },
    );
  }
}
