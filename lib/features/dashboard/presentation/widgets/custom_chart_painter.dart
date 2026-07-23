import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Single-pass CustomPainter rendering expense breakdown directly on Canvas.
/// Completely bypasses widget creation overhead for maximum rendering speed on low-end GPUs.
class CustomChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  CustomChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double total = values.fold(0.0, (sum, val) => sum + val);
    if (total <= 0) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false; // Disable MSAA anti-aliasing for GPU speed on low-end hardware

    double currentX = 0.0;
    const double barHeight = 12.0;
    final double radius = 3.0;

    for (int i = 0; i < values.length; i++) {
      final double segmentWidth = (values[i] / total) * size.width;
      if (segmentWidth <= 0) continue;

      paint.color = colors[i % colors.length];

      final Rect rect = Rect.fromLTWH(currentX, 0, segmentWidth - 2.0, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );

      currentX += segmentWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
