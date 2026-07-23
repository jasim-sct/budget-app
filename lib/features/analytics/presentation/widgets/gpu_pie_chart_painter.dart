import 'dart:math';
import 'package:flutter/material.dart';

/// Smooth Donut Chart CustomPainter for Analytics Category Distribution.
class GpuPieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  const GpuPieChartPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final double total = values.fold(0.0, (sum, v) => sum + v);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.38
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      if (sweepAngle <= 0) continue;

      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.8),
        startAngle,
        max(0.01, sweepAngle - 0.06),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant GpuPieChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
