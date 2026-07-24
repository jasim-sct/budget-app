import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../domain/services/budget_history_engine.dart';

class BudgetHistoryComparisonWidget extends StatelessWidget {
  final PeriodComparisonMetrics metrics;

  const BudgetHistoryComparisonWidget({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final isIncrease = metrics.spentVariance > 0;
    final varianceColor = isIncrease ? AppColors.rose : AppColors.emerald;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Period Comparison',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${metrics.currentPeriodKey} vs ${metrics.previousPeriodKey}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Current Period',
                  value: '\$${metrics.currentSpent.toStringAsFixed(2)}',
                  subtext: 'Allocation: \$${metrics.currentAllocation.toStringAsFixed(2)}',
                  valueColor: Colors.white,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Previous Period',
                  value: '\$${metrics.previousSpent.toStringAsFixed(2)}',
                  subtext: 'Allocation: \$${metrics.previousAllocation.toStringAsFixed(2)}',
                  valueColor: Colors.white70,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: varianceColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isIncrease ? '+' : ''}\$${metrics.spentVariance.abs().toStringAsFixed(2)} (${isIncrease ? '+' : ''}${metrics.spentChangePercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: varianceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                'Health Score: ${metrics.currentHealthScore.toStringAsFixed(0)}/100',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required String subtext,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
