import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_metrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/glass/glass_chip.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../widgets/gpu_pie_chart_painter.dart';

/// Analytics & Financial Insights Screen.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: ValueListenableBuilder<FinancialMetrics>(
        valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
        builder: (context, metrics, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.sm),

              // Time Period Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                    child: GlassChip(
                      label: period,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedPeriod = period),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              // Key Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.show_chart_rounded,
                      iconColor: AppColors.expenseRed,
                      label: 'DAILY BURN',
                      value: AppFormatters.currency(metrics.dailyBurnRate),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.savings_outlined,
                      iconColor: AppColors.primaryBlue,
                      label: 'SAVINGS RATE',
                      value: '${metrics.savingsRate.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Forecast Card
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PROJECTED MONTHLY EXPENSE', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            AppFormatters.currency(metrics.nextMonthForecastExpense),
                            style: AppTypography.headline(isDark),
                          ),
                          Text(
                            'Linear trend forecast based on ledger velocity',
                            style: AppTypography.labelSmall(isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'EXPENSE BREAKDOWN BY CATEGORY',
                style: AppTypography.sectionLabel(isDark),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category Donut Chart Card
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.getCategoryBreakdownByMonth(metrics.year, metrics.month),
                builder: (context, snapshot) {
                  final rows = snapshot.data ?? [];
                  final List<String> labels = rows.map((r) => r['category'] as String? ?? 'Uncategorized').toList();
                  final List<double> values = rows.map((r) => (r['total'] as num?)?.toDouble() ?? 0.0).toList();
                  final double totalExpense = values.fold(0.0, (sum, val) => sum + val);

                  const List<Color> colors = [
                    AppColors.expenseRed,
                    AppColors.warningOrange,
                    Color(0xFF0EA5E9),
                    AppColors.primaryBlue,
                    AppColors.incomeGreen,
                    Color(0xFF06B6D4),
                    Color(0xFFEC4899),
                    Color(0xFF6366F1),
                  ];

                  if (rows.isEmpty || totalExpense <= 0) {
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 48,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No Expense Breakdown',
                              style: AppTypography.headline(isDark),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No expense transactions recorded for ${AppFormatters.monthName(metrics.month)} ${metrics.year}',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(isDark),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AppCard(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(180, 180),
                                painter: GpuPieChartPainter(
                                  values: values,
                                  colors: colors,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: AppTypography.sectionLabel(isDark),
                                  ),
                                  Text(
                                    AppFormatters.currency(totalExpense),
                                    style: AppTypography.headline(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Legend List
                        ...List.generate(labels.length, (index) {
                          final percentage = totalExpense > 0
                              ? ((values[index] / totalExpense) * 100).toStringAsFixed(1)
                              : '0.0';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      labels[index],
                                      style: AppTypography.titleMedium(isDark),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '$percentage%',
                                      style: AppTypography.caption(isDark),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      AppFormatters.currency(values[index]),
                                      style: AppTypography.titleMedium(isDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderXs,
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.sectionLabel(isDark)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.titleLarge(isDark).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
