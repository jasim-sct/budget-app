import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animated_circular_progress.dart';

import '../../../../core/widgets/financial_knowledge_sheet.dart';

/// Budget Health Summary Card component.
class BudgetHealthCard extends StatelessWidget {
  final double totalSpent;
  final double totalLimit;
  final int healthScore;
  final double overallRatio;

  const BudgetHealthCard({
    super.key,
    required this.totalSpent,
    required this.totalLimit,
    required this.healthScore,
    required this.overallRatio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double remaining = totalLimit - totalSpent;

    return GestureDetector(
      onTap: () {
        FinancialKnowledgeSheet.showForMetric(
          context,
          type: FinancialMetricType.budgetRemaining,
          metricValue: AppFormatters.currency(remaining),
          customTitle: 'Overall Budget Health & Remaining',
          customSources: [
            'Total Allocated Envelopes: ${AppFormatters.currency(totalLimit)}',
            'Total Period Expenses: ${AppFormatters.currency(totalSpent)}',
            'Budget Health Score: $healthScore / 100',
            'Envelope Consumption Ratio: ${(overallRatio * 100).toStringAsFixed(1)}%',
          ],
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AnimatedCircularProgress(
            progress: overallRatio.clamp(0.0, 1.0),
            size: 80,
            strokeWidth: 8,
            centerChild: Text(
              '$healthScore',
              style: AppTypography.displayMedium(isDark).copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUDGET HEALTH SCORE',
                  style: AppTypography.sectionLabel(isDark),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppFormatters.currency(totalSpent),
                  style: AppTypography.currency(isDark, fontSize: 22),
                ),
                Text(
                  'of ${AppFormatters.currency(totalLimit)} envelope limit',
                  style: AppTypography.caption(isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
