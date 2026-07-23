import 'package:flutter/material.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/month_selector_bar.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../transactions/data/transaction_repository.dart';

/// VisionOS Ultra-Premium Glassmorphic Financial Overview Header.
/// Features holographic chip styling, quick action glass pill buttons, and real-time Level 10 calculation engine metrics.
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

              // Welcome Profile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.neonMeshGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.neonGlow(AppColors.primaryEmerald),
                        ),
                        child: const Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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
                            'FINANCIAL OPERATING SYSTEM',
                            style: AppTypography.labelSmall(isDark),
                          ),
                          Text(
                            'Alex Morgan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.violetGradient,
                          borderRadius: AppRadius.borderPill,
                          boxShadow: AppShadows.glow(AppColors.accentViolet),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Score: ${metrics.financialScore}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
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

              // Credit Card Style Holographic VisionOS Glass Card
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
                          'TOTAL LIQUID NET WORTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: AppRadius.borderPill,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.primaryEmerald),
                              SizedBox(width: 4),
                              Text(
                                'SQLite Vault v3',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _hideBalance ? '\$••••••••' : AppFormatters.currency(metrics.netWorth),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Metrics Trio Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Inflow',
                            amount: metrics.totalIncome,
                            color: AppColors.incomeGreen,
                            icon: Icons.arrow_downward_rounded,
                            hidden: _hideBalance,
                          ),
                        ),
                        Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.18)),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'Outflow',
                            amount: metrics.totalExpense,
                            color: AppColors.expenseRed,
                            icon: Icons.arrow_upward_rounded,
                            hidden: _hideBalance,
                          ),
                        ),
                        Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.18)),
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
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              // Quick Actions Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'Statements',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    },
                    isDark: isDark,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.trending_up_rounded,
                    label: 'Analytics',
                    onTap: () {},
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
              // Automated Level 10 Engine Insight Banner
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryEmerald, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        metrics.totalExpense > 0
                            ? 'Engine Insight: ${metrics.topCategoryName} is top spend (${metrics.savingsRate.toStringAsFixed(1)}% savings rate).'
                            : 'Engine Insight: Zero outflows logged. Outstanding cash retention!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: GlassCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryEmerald, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
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
                  fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
