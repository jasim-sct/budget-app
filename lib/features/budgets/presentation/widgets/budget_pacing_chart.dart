import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/budget_pacing_model.dart';

/// Ultra-Advanced CustomPainter Chart plotting expected budget pace vs actual spend with gradient fill & projection band.
class BudgetPacingChart extends StatelessWidget {
  final BudgetPacingModel pacing;
  final List<double> dailyCumulativeSpent;

  const BudgetPacingChart({
    super.key,
    required this.pacing,
    required this.dailyCumulativeSpent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(pacing.pacingStatus);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPENDING TREND & PROJECTION',
                    style: AppTypography.sectionLabel(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Cumulative Expense Curve',
                    style: AppTypography.titleLarge(isDark),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    label: 'Target Pace',
                    isDashed: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildLegendItem(
                    color: statusColor,
                    label: 'Actual Spend',
                    isDashed: false,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _AdvancedPacingChartPainter(
                pacing: pacing,
                dailyCumulativeSpent: dailyCumulativeSpent,
                statusColor: statusColor,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PacingStatus status) {
    switch (status) {
      case PacingStatus.lowUsage:
        return AppColors.primaryBlue;
      case PacingStatus.onTrack:
        return AppColors.incomeGreen;
      case PacingStatus.highUsage:
        return AppColors.warningOrange;
      case PacingStatus.critical:
        return AppColors.expenseRed;
    }
  }

  Widget _buildLegendItem({required Color color, required String label, required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _AdvancedPacingChartPainter extends CustomPainter {
  final BudgetPacingModel pacing;
  final List<double> dailyCumulativeSpent;
  final Color statusColor;
  final bool isDark;

  _AdvancedPacingChartPainter({
    required this.pacing,
    required this.dailyCumulativeSpent,
    required this.statusColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 45.0;
    const double paddingBottom = 25.0;
    const double paddingTop = 15.0;
    const double paddingRight = 15.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final int D = pacing.daysInMonth > 0 ? pacing.daysInMonth : 30;
    final double maxY = [
      pacing.monthlyBudget,
      pacing.totalSpent,
      pacing.projectedMonthEndSpent,
      if (dailyCumulativeSpent.isNotEmpty) dailyCumulativeSpent.last,
    ].fold(100.0, (maxVal, val) => val > maxVal ? val : maxVal);

    final Paint gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Y-Axis Gridlines and Labels (3 ticks: 0, 50%, 100%)
    for (int i = 0; i <= 2; i++) {
      final double ratio = i / 2;
      final double y = paddingTop + chartHeight * (1.0 - ratio);
      final double val = maxY * ratio;

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      textPainter.text = TextSpan(
        text: AppFormatters.currencyCompact(val),
        style: TextStyle(
          fontSize: 9,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    // 2. X-Axis Day Labels (Day 1, Mid, Day D)
    final int midDay = D ~/ 2;
    final List<int> xDays = [1, midDay, D];
    for (final day in xDays) {
      final double ratioX = (day - 1) / (D - 1);
      final double x = paddingLeft + chartWidth * ratioX;

      textPainter.text = TextSpan(
        text: 'D$day',
        style: TextStyle(
          fontSize: 9,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - paddingBottom + 6));
    }

    // 3. Draw Target Linear Pace Line (Dashed)
    final Paint targetPaint = Paint()
      ..color = (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Offset startTarget = Offset(paddingLeft, paddingTop + chartHeight * (1.0 - 0.0));
    final double endTargetYRatio = (pacing.monthlyBudget / maxY).clamp(0.0, 1.0);
    final Offset endTarget = Offset(paddingLeft + chartWidth, paddingTop + chartHeight * (1.0 - endTargetYRatio));

    _drawDashedLine(canvas, startTarget, endTarget, targetPaint);

    // 4. Draw Gradient Area Fill & Actual Spend Line
    if (dailyCumulativeSpent.isNotEmpty) {
      final int len = dailyCumulativeSpent.length.clamp(1, D);
      final int currentDayIndex = pacing.currentDay.clamp(1, len);

      final Path strokePath = Path();
      final Path fillPath = Path();

      double lastX = paddingLeft;
      double lastY = paddingTop + chartHeight;

      for (int i = 0; i < currentDayIndex; i++) {
        final double dayNum = (i + 1).toDouble();
        final double ratioX = (dayNum - 1) / (D - 1);
        final double x = paddingLeft + chartWidth * ratioX;
        final double spent = dailyCumulativeSpent[i];
        final double ratioY = (spent / maxY).clamp(0.0, 1.0);
        final double y = paddingTop + chartHeight * (1.0 - ratioY);

        if (i == 0) {
          strokePath.moveTo(x, y);
          fillPath.moveTo(x, paddingTop + chartHeight);
          fillPath.lineTo(x, y);
        } else {
          strokePath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
        lastX = x;
        lastY = y;
      }

      fillPath.lineTo(lastX, paddingTop + chartHeight);
      fillPath.close();

      // Area Fill Shader
      final Shader fillShader = LinearGradient(
        colors: [
          statusColor.withValues(alpha: 0.28),
          statusColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));

      final Paint fillPaint = Paint()..shader = fillShader;
      canvas.drawPath(fillPath, fillPaint);

      // Stroke Line
      final Paint actualStroke = Paint()
        ..color = statusColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(strokePath, actualStroke);

      // 5. Projected Trend Corridor Line (from Current Day to End of Month)
      if (currentDayIndex < D) {
        final double projEndRatioY = (pacing.projectedMonthEndSpent / maxY).clamp(0.0, 1.0);
        final Offset projStart = Offset(lastX, lastY);
        final Offset projEnd = Offset(paddingLeft + chartWidth, paddingTop + chartHeight * (1.0 - projEndRatioY));

        final Paint projPaint = Paint()
          ..color = statusColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        _drawDashedLine(canvas, projStart, projEnd, projPaint);
      }

      // Current Day Node Marker Pin
      if (currentDayIndex > 0) {
        final Paint pinOuter = Paint()..color = statusColor.withValues(alpha: 0.3);
        final Paint pinInner = Paint()..color = statusColor;
        final Paint pinCenter = Paint()..color = Colors.white;

        canvas.drawCircle(Offset(lastX, lastY), 8, pinOuter);
        canvas.drawCircle(Offset(lastX, lastY), 4, pinInner);
        canvas.drawCircle(Offset(lastX, lastY), 1.5, pinCenter);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double totalLen = (Offset(dx, dy)).distance;
    if (totalLen <= 0) return;

    double drawn = 0.0;
    final double stepX = (dx / totalLen) * (dashWidth + dashSpace);
    final double stepY = (dy / totalLen) * (dashWidth + dashSpace);

    double startX = p1.dx;
    double startY = p1.dy;

    while (drawn < totalLen) {
      final double endX = (startX + (dx / totalLen) * dashWidth).clamp(p1.dx, p2.dx);
      final double endY = dy >= 0
          ? (startY + (dy / totalLen) * dashWidth).clamp(p1.dy, p2.dy)
          : (startY + (dy / totalLen) * dashWidth).clamp(p2.dy, p1.dy);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      startX += stepX;
      startY += stepY;
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedPacingChartPainter oldDelegate) {
    return oldDelegate.pacing != pacing ||
        oldDelegate.dailyCumulativeSpent != dailyCumulativeSpent ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.isDark != isDark;
  }
}
