import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/datasources/budget_dao.dart';
import '../widgets/budget_overspend_recovery_sheet.dart';
import '../widgets/remaining_budget_transfer_sheet.dart';

/// Enterprise Category Envelope Budget Card component displaying complete split-wise metrics and action triggers.
class BudgetEnvelopeCard extends StatelessWidget {
  final BudgetSpentSummary summary;
  final VoidCallback? onActionCompleted;

  const BudgetEnvelopeCard({
    super.key,
    required this.summary,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = summary.metrics;
    final statusColor = metrics.status.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.0,
        ),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(Icons.pie_chart_rounded, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.budget.name,
                        style: AppTypography.titleLarge(isDark),
                      ),
                      Text(
                        'Period: ${metrics.periodType.label} • ${metrics.remainingDays} days left',
                        style: AppTypography.caption(isDark),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: metrics.status.badgeBackgroundColor,
                  borderRadius: AppRadius.borderXs,
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  metrics.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
              value: (metrics.progressPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
              color: statusColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Progress Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${metrics.progressPercentage.toStringAsFixed(1)}% Used',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
              Text(
                'Spent ${AppFormatters.currency(metrics.spent)} / ${AppFormatters.currency(metrics.allocation)}',
                style: AppTypography.labelSmall(isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Split-wise Enterprise Grid
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: AppRadius.borderSm,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricText('Remaining:', AppFormatters.currency(metrics.remaining), color: metrics.remaining >= 0 ? AppColors.emerald : AppColors.rose),
                    _buildMetricText('Available:', AppFormatters.currency(metrics.availableBalance), color: AppColors.cyan),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricText('Daily Target:', '${AppFormatters.currency(metrics.dailyTarget)}/day'),
                    _buildMetricText('Burn Rate:', '${AppFormatters.currency(metrics.currentBurnRate)}/day'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricText('Est. End Spend:', AppFormatters.currency(metrics.estimatedEndOfPeriodSpending)),
                    _buildMetricText('Health Score:', '${metrics.budgetHealthScore.toStringAsFixed(0)}/100', color: statusColor),
                  ],
                ),
              ],
            ),
          ),

          // Action Triggers Row (Transfer Remaining or Recover Overspend)
          if (metrics.canTransferRemaining || metrics.needsRecovery) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (metrics.canTransferRemaining)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.emerald),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Transfer Remaining', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      RemainingBudgetTransferSheet.show(
                        context,
                        metrics: metrics,
                        onTransferCompleted: () {
                          if (onActionCompleted != null) onActionCompleted!();
                        },
                      );
                    },
                  ),
                if (metrics.needsRecovery)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose,
                      side: const BorderSide(color: AppColors.rose),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 16),
                    label: const Text('Recover Overspend', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      BudgetOverspendRecoverySheet.show(
                        context,
                        metrics: metrics,
                        onRecoveryCompleted: () {
                          if (onActionCompleted != null) onActionCompleted!();
                        },
                      );
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricText(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
