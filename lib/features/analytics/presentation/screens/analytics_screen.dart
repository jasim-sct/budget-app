import 'package:flutter/material.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_metrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_chip.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../widgets/gpu_pie_chart_painter.dart';

/// VisionOS Frosted Glass Analytics & Financial Insights Screen.
/// Powered by Level 10 Deterministic FinancialCalculationEngine.
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

    const List<double> values = [450.0, 220.0, 180.0, 120.0, 90.0];
    const List<String> labels = ['Food & Dining', 'Transportation', 'Utilities', 'Shopping', 'Others'];
    const List<Color> colors = [
      AppColors.expenseRed,
      AppColors.accentAmber,
      AppColors.accentSky,
      AppColors.accentViolet,
      AppColors.primaryEmerald,
    ];

    final double totalExpense = values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analytics & Forecasting Engine',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: ValueListenableBuilder<FinancialMetrics>(
        valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
        builder: (context, metrics, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.sm),

              // Time Period Glass Filter Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GlassChip(
                      label: period,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedPeriod = period),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Key Stat Glass Cards Row
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.expenseRed.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: const Icon(Icons.show_chart_rounded, color: AppColors.expenseRed, size: 16),
                              ),
                              const SizedBox(width: 6),
                              Text('DAILY BURN', style: AppTypography.labelSmall(isDark)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppFormatters.currency(metrics.dailyBurnRate),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: const Icon(Icons.savings_outlined, color: AppColors.primaryEmerald, size: 16),
                              ),
                              const SizedBox(width: 6),
                              Text('SAVINGS RATE', style: AppTypography.labelSmall(isDark)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${metrics.savingsRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Forecast Engine Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentViolet.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accentViolet, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NEXT MONTH PROJECTED EXPENSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accentViolet)),
                          Text(
                            AppFormatters.currency(metrics.nextMonthForecastExpense),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Linear trend forecast based on active ledger velocity',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(
                'EXPENSE BREAKDOWN BY CATEGORY',
                style: AppTypography.labelSmall(isDark),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category Glass Donut Chart Card
              GlassCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CustomPaint(
                            size: Size(180, 180),
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
                                style: AppTypography.labelSmall(isDark),
                              ),
                              Text(
                                AppFormatters.currency(metrics.totalExpense > 0 ? metrics.totalExpense : totalExpense),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Interactive Legend List
                    ...List.generate(labels.length, (index) {
                      final percentage = ((values[index] / totalExpense) * 100).toStringAsFixed(1);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  labels[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  AppFormatters.currency(values[index]),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}
