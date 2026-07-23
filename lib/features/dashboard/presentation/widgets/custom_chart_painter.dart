import 'package:flutter/material.dart';

/// High-performance CustomPainter rendering expense breakdown segments directly on Canvas.
class CustomChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const CustomChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double total = values.fold(0.0, (sum, val) => sum + val);
    if (total <= 0) return;

    final Paint paint = Paint()..style = PaintingStyle.fill;
    double currentX = 0.0;
    final double barHeight = size.height;
    const double radius = 4.0;

    for (int i = 0; i < values.length; i++) {
      final double segmentWidth = (values[i] / total) * size.width;
      if (segmentWidth <= 0) continue;

      paint.color = colors[i % colors.length];

      final Rect rect = Rect.fromLTWH(currentX, 0, (segmentWidth - 3.0).clamp(1.0, size.width), barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
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
