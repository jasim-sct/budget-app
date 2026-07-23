import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/datasources/budget_dao.dart';

/// Category Envelope Limit Card component.
class BudgetEnvelopeCard extends StatelessWidget {
  final BudgetSpentSummary summary;

  const BudgetEnvelopeCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color progressColor = summary.isExceeded
        ? AppColors.expenseRed
        : (summary.isNearAlert ? AppColors.warningOrange : AppColors.incomeGreen);

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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(Icons.pie_chart_rounded, color: progressColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    summary.budget.name,
                    style: AppTypography.titleLarge(isDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderXs,
                ),
                child: Text(
                  summary.isExceeded ? 'Exceeded' : (summary.isNearAlert ? 'Warning' : 'Safe'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress Indicator
          ClipRRect(
            borderRadius: AppRadius.borderPill,
            child: LinearProgressIndicator(
              value: summary.progressRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              color: progressColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.isExceeded
                    ? 'Exceeded by ${AppFormatters.currency(summary.spent - summary.budget.amountLimit)}'
                    : '${AppFormatters.currency(summary.remaining)} remaining',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
              Text(
                '${AppFormatters.currency(summary.spent)} / ${AppFormatters.currency(summary.budget.amountLimit)}',
                style: AppTypography.labelSmall(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
