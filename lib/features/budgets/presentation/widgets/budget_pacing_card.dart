import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/budget_pacing_model.dart';

import '../../../../core/widgets/financial_knowledge_sheet.dart';

/// Dynamic Budget Pacing Summary Card.
class BudgetPacingCard extends StatelessWidget {
  final BudgetPacingModel pacing;

  const BudgetPacingCard({
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

    return GestureDetector(
      onTap: () {
        FinancialKnowledgeSheet.showForMetric(
          context,
          type: FinancialMetricType.dailySafeSpending,
          metricValue: '${AppFormatters.currency(pacing.dailyBudgetTarget)}/day',
          customTitle: 'Dynamic Budget Pacing',
          customSources: [
            'Current Daily Target: ${AppFormatters.currency(pacing.dailyBudgetTarget)}/day',
            'Today\'s Actual Spending: ${AppFormatters.currency(pacing.todaySpent)}',
            'Estimated Month-End Spending: ${AppFormatters.currency(pacing.projectedMonthEndSpent)}',
            'Variance to Budget: ${AppFormatters.currency(pacing.varianceAmount)}',
            'Pacing Consumption Ratio: ${(pacing.pacingPercentage).toStringAsFixed(1)}%',
          ],
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DYNAMIC BUDGET PACING',
                    style: AppTypography.sectionLabel(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Month Pacing Overview',
                    style: AppTypography.titleLarge(isDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      pacing.pacingStatus.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          // Description Banner
          Text(
            pacing.pacingStatus.description,
            style: AppTypography.caption(isDark).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Pacing Progress Indicator with Pace Pin
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final progressRatio = pacing.progressRatio;
              final expectedRatio = pacing.expectedProgressRatio;

              return Column(
                children: [
                  Stack(
                    children: [
                      // Base Track
                      Container(
                        height: 10,
                        width: width,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                          borderRadius: AppRadius.borderPill,
                        ),
                      ),
                      // Actual Spent Fill
                      FractionallySizedBox(
                        widthFactor: progressRatio,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: AppRadius.borderPill,
                          ),
                        ),
                      ),
                      // Expected Pace Vertical Marker
                      Positioned(
                        left: (expectedRatio * width - 2).clamp(0.0, width - 4),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black87,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Day ${pacing.currentDay} of ${pacing.daysInMonth}',
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Expected Pace: ${AppFormatters.currency(pacing.expectedSpentToDate)}',
                        style: AppTypography.labelSmall(isDark),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // 6-Tile Key Metrics Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            crossAxisSpacing: AppSpacing.xs,
            mainAxisSpacing: AppSpacing.xs,
            children: [
              _buildMetricTile(
                isDark: isDark,
                label: 'MONTHLY BUDGET',
                value: AppFormatters.currency(pacing.monthlyBudget),
                subtext: '${pacing.daysInMonth} days total',
              ),
              _buildMetricTile(
                isDark: isDark,
                label: 'TOTAL SPENT',
                value: AppFormatters.currency(pacing.totalSpent),
                subtext: '${(pacing.progressRatio * 100).toStringAsFixed(0)}% of limit',
                valueColor: statusColor,
              ),
              _buildMetricTile(
                isDark: isDark,
                label: 'REMAINING BUDGET',
                value: AppFormatters.currency(pacing.remainingBudget),
                subtext: pacing.isOverBudget ? 'Over Budget' : 'Available',
                valueColor: pacing.isOverBudget ? AppColors.expenseRed : null,
              ),
              _buildMetricTile(
                isDark: isDark,
                label: 'BASE DAILY TARGET',
                value: AppFormatters.currency(pacing.dailyBudgetTarget),
                subtext: 'Ideal per day',
              ),
              _buildMetricTile(
                isDark: isDark,
                label: 'REMAINING DAYS',
                value: '${pacing.remainingDays} d',
                subtext: 'Incl. today',
              ),
              _buildMetricTile(
                isDark: isDark,
                label: 'REQ. DAILY LIMIT',
                value: AppFormatters.currency(pacing.requiredDailySpending),
                subtext: 'To stay under limit',
                valueColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String label,
    required String value,
    required String subtext,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurfaceSecondary.withValues(alpha: 0.5),
        borderRadius: AppRadius.borderSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
