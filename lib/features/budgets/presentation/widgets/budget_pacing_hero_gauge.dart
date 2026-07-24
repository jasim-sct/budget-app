import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/budget_pacing_model.dart';

/// Ultra-Advanced Radial Arc Pacing Gauge & Daily Allowance HUD Hero Component.
class BudgetPacingHeroGauge extends StatelessWidget {
  final BudgetPacingModel pacing;

  const BudgetPacingHeroGauge({
    super.key,
    required this.pacing,
  });

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

  IconData _getStatusIcon(PacingStatus status) {
    switch (status) {
      case PacingStatus.lowUsage:
        return Icons.savings_outlined;
      case PacingStatus.onTrack:
        return Icons.check_circle_outline_rounded;
      case PacingStatus.highUsage:
        return Icons.trending_up_rounded;
      case PacingStatus.critical:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(pacing.pacingStatus);
    final statusIcon = _getStatusIcon(pacing.pacingStatus);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(statusIcon, size: 18, color: statusColor),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DYNAMIC BUDGET PACING',
                        style: AppTypography.sectionLabel(isDark),
                      ),
                      Text(
                        'Pacing Velocity & Runway',
                        style: AppTypography.titleLarge(isDark),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  pacing.pacingStatus.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Main Hero Body: Arc Gauge + Daily Safe Allowance HUD
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 420;

              final gaugeWidget = SizedBox(
                height: 150,
                width: 160,
                child: CustomPaint(
                  painter: _RadialArcGaugePainter(
                    pacing: pacing,
                    statusColor: statusColor,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormatters.currency(pacing.totalSpent),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'of ${AppFormatters.currency(pacing.monthlyBudget)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final allowanceWidget = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSecondary,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TODAY\'S SAFE ALLOWANCE',
                                style: AppTypography.sectionLabel(isDark),
                              ),
                              Text(
                                '${pacing.remainingDays}d remaining',
                                style: AppTypography.caption(isDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            AppFormatters.currency(pacing.requiredDailySpending),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Today's Spent vs Daily Limit Bar
                          ClipRRect(
                            borderRadius: AppRadius.borderPill,
                            child: LinearProgressIndicator(
                              value: pacing.todayAllowanceProgressRatio,
                              minHeight: 6,
                              backgroundColor: isDark ? AppColors.darkSurfaceLight : Colors.grey.shade300,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent today: ${AppFormatters.currency(pacing.todaySpent)}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${AppFormatters.currency(pacing.todayRemainingAllowance)} safe left',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),
                    // Runway & Pacing Variance Pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.speed_rounded, size: 14, color: statusColor),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              pacing.varianceAmount >= 0
                                  ? 'Pace variance: +${AppFormatters.currency(pacing.varianceAmount)} vs target'
                                  : 'Pace variance: -${AppFormatters.currency(pacing.varianceAmount.abs())} under target',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    gaugeWidget,
                    const SizedBox(width: AppSpacing.md),
                    allowanceWidget,
                  ],
                );
              } else {
                return Column(
                  children: [
                    Center(child: gaugeWidget),
                    const SizedBox(height: AppSpacing.sm),
                    Row(children: [allowanceWidget]),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RadialArcGaugePainter extends CustomPainter {
  final BudgetPacingModel pacing;
  final Color statusColor;
  final bool isDark;

  _RadialArcGaugePainter({
    required this.pacing,
    required this.statusColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = math.min(size.width, size.height) * 0.48;

    const startAngle = math.pi * 0.8;
    const sweepAngle = math.pi * 1.4;

    final Paint trackPaint = Paint()
      ..color = (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Actual Spend Arc
    final progressRatio = pacing.progressRatio.clamp(0.0, 1.0);
    final activeSweep = sweepAngle * progressRatio;

    if (activeSweep > 0) {
      final Paint progressPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        progressPaint,
      );
    }

    // Target Pace Marker Pin
    final expectedRatio = pacing.expectedProgressRatio.clamp(0.0, 1.0);
    final expectedAngle = startAngle + (sweepAngle * expectedRatio);
    final pinRadius = radius;
    final pinX = center.dx + pinRadius * math.cos(expectedAngle);
    final pinY = center.dy + pinRadius * math.sin(expectedAngle);

    final Paint pinPaint = Paint()..color = (isDark ? Colors.white : Colors.black);
    canvas.drawCircle(Offset(pinX, pinY), 5.0, pinPaint);
    final Paint pinCore = Paint()..color = statusColor;
    canvas.drawCircle(Offset(pinX, pinY), 2.5, pinCore);
  }

  @override
  bool shouldRepaint(covariant _RadialArcGaugePainter oldDelegate) {
    return oldDelegate.pacing != pacing ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.isDark != isDark;
  }
}
