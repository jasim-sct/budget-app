import 'package:flutter/material.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/month_selector_bar.dart';
import '../../transactions/data/transaction_repository.dart';
import 'widgets/custom_chart_painter.dart';

/// Modern VisionOS Glassmorphic Financial Overview Header.
/// Powered by Level 10 Deterministic FinancialCalculationEngine.
class DashboardHeader extends StatefulWidget {
  final TransactionRepository repository;

  const DashboardHeader({
    super.key,
    required this.repository,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<FinancialMetrics>(
      valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
      builder: (context, metrics, _) {
        final savings = (metrics.totalIncome - metrics.totalExpense).clamp(0.0, double.infinity);

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Global Month Selector Bar
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.sm),

              // Welcome Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.glow(AppColors.primaryEmerald),
                        ),
                        child: const Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK',
                            style: AppTypography.labelSmall(isDark),
                          ),
                          Text(
                            'Alex Morgan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                          borderRadius: AppRadius.borderPill,
                          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.primaryEmerald),
                            const SizedBox(width: 4),
                            Text(
                              'Score: ${metrics.financialScore}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryEmerald),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        onPressed: () => setState(() => _hideBalance = !_hideBalance),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Credit Card Style Frosted Glass Balance Card
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL NET BALANCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 12, color: AppColors.primaryEmerald),
                              SizedBox(width: 4),
                              Text(
                                'Glass Vault',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _hideBalance ? '\$••••••••' : AppFormatters.currency(metrics.netCashFlow),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Income / Expense / Savings Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Income',
                            amount: metrics.totalIncome,
                            color: AppColors.incomeGreen,
                            icon: Icons.arrow_downward_rounded,
                            hidden: _hideBalance,
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Expense',
                            amount: metrics.totalExpense,
                            color: AppColors.expenseRed,
                            icon: Icons.arrow_upward_rounded,
                            hidden: _hideBalance,
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Saved',
                            amount: savings,
                            color: AppColors.accentViolet,
                            icon: Icons.savings_outlined,
                            hidden: _hideBalance,
                          ),
                        ),
                      ],
                    ),

                    if (metrics.totalExpense > 0) ...[
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 8,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: CustomChartPainter(
                            values: [
                              metrics.totalExpense * 0.45,
                              metrics.totalExpense * 0.35,
                              metrics.totalExpense * 0.20,
                            ],
                            colors: const [
                              AppColors.expenseRed,
                              AppColors.accentAmber,
                              AppColors.accentSky,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              // Smart Financial Insight Glass Banner
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: AppColors.primaryEmerald, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        metrics.totalExpense > 0
                            ? 'Engine Insight: Top outflow category is ${metrics.topCategoryName} (${metrics.savingsRate.toStringAsFixed(1)}% savings rate).'
                            : 'Engine Insight: Zero expenses recorded for this month. Excellent cash retention!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricItem({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required bool hidden,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            hidden ? '\$•••' : AppFormatters.currency(amount),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
