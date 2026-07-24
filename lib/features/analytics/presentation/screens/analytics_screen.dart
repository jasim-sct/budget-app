import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_metrics.dart';
import '../../../../core/services/intent_decision_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_chip.dart';
import '../../../../core/widgets/financial_knowledge_sheet.dart';
import '../../../../core/widgets/month_selector_bar.dart';
import '../../../../core/widgets/scan_first_components.dart';
import '../../../categories/presentation/categories_screen.dart';
import '../../../reports/presentation/reports_screen.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../widgets/gpu_pie_chart_painter.dart';

/// Scan-First Spending Insights Engine & Mobile-First layout (320px+ viewports).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Monthly';
  IntentDecisionState? _intentState;
  bool _showNarrativeDetails = false;

  @override
  void initState() {
    super.initState();
    _loadIntent();
  }

  Future<void> _loadIntent() async {
    final state = await IntentDecisionEngine.evaluateCurrentIntent();
    if (mounted) {
      setState(() {
        _intentState = state;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Insights'),
        actions: [
          IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.table_chart_outlined, size: 20),
            tooltip: 'Financial Statements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.category_outlined, size: 20),
            tooltip: 'Category Manager',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(repository: TransactionRepository())),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<FinancialMetrics>(
        valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
        builder: (context, metrics, _) {
          final isSavingsOnTrack = metrics.savingsRate >= 0.20;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.xs),

              // SECTION 1: HIGHLIGHTED CONCLUSIONS GRID
              Text(
                'EXECUTIVE FINANCIAL CONCLUSIONS',
                style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue),
              ),
              const SizedBox(height: AppSpacing.xs),

              Row(
                children: [
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Total Spent',
                      value: AppFormatters.currency(metrics.totalExpense),
                      statusPill: metrics.totalExpense > 0 ? 'OUTFLOW' : 'ZERO',
                      statusColor: metrics.totalExpense > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                      subtitle: 'Month Outflow',
                      onTap: () {
                        FinancialKnowledgeSheet.showForMetric(
                          context,
                          type: FinancialMetricType.dailyBurnRate,
                          metricValue: AppFormatters.currency(metrics.totalExpense),
                          customTitle: 'Total Expense Summary',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Savings Rate',
                      value: '${(metrics.savingsRate * 100).toStringAsFixed(1)}%',
                      statusPill: isSavingsOnTrack ? 'ON TARGET' : 'BUILDING',
                      statusColor: isSavingsOnTrack ? AppColors.incomeGreen : AppColors.warningOrange,
                      subtitle: 'Retained Cash',
                      onTap: () {
                        FinancialKnowledgeSheet.showForMetric(
                          context,
                          type: FinancialMetricType.savingsRate,
                          metricValue: '${(metrics.savingsRate * 100).toStringAsFixed(1)}%',
                          customTitle: 'Savings Rate Metric',
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              Row(
                children: [
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Daily Velocity',
                      value: AppFormatters.currency(metrics.dailyBurnRate),
                      statusPill: 'VELOCITY',
                      statusColor: AppColors.primaryBlue,
                      subtitle: 'Per Calendar Day',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Forecast',
                      value: AppFormatters.currency(metrics.nextMonthForecastExpense),
                      statusPill: 'PROJECTED',
                      statusColor: AppColors.warningOrange,
                      subtitle: 'Linear Extrapolation',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Progressive Disclosure for Executive Narrative
              GestureDetector(
                onTap: () => setState(() => _showNarrativeDetails = !_showNarrativeDetails),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 15),
                          SizedBox(width: 5),
                          Text(
                            'Financial Narrative & Audit',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _showNarrativeDetails ? 'Hide' : 'Expand',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                          ),
                          Icon(
                            _showNarrativeDetails ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 15,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_showNarrativeDetails) ...[
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: _buildExecutiveConclusionsList(metrics, isDark),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // SECTION 2: SUPPORTING CATEGORY BREAKDOWN
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUPPORTING CATEGORY BREAKDOWN',
                    style: AppTypography.sectionLabel(isDark),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GlassChip(
                          label: period,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedPeriod = period),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 40,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No Expense Data Available',
                              style: AppTypography.headline(isDark).copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Log transactions in ${AppFormatters.monthName(metrics.month)} to generate breakdown insights.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption(isDark),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(160, 160),
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
                                    style: AppTypography.sectionLabel(isDark).copyWith(fontSize: 9),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      AppFormatters.currency(totalExpense),
                                      style: AppTypography.headline(isDark).copyWith(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        ...List.generate(labels.length, (index) {
                          final percentage = totalExpense > 0
                              ? ((values[index] / totalExpense) * 100).toStringAsFixed(1)
                              : '0.0';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    labels[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.titleMedium(isDark).copyWith(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AppStatusBadge(
                                  label: '$percentage%',
                                  color: colors[index % colors.length],
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  AppFormatters.currency(values[index]),
                                  style: AppTypography.titleMedium(isDark).copyWith(fontSize: 13, fontWeight: FontWeight.w800),
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
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildExecutiveConclusionsList(FinancialMetrics metrics, bool isDark) {
    final list = <String>[];
    if (metrics.totalExpense == 0) {
      list.add('No spending recorded for this month yet. Daily velocity is clean.');
    } else {
      final netCash = metrics.totalIncome - metrics.totalExpense;
      if (netCash >= 0) {
        list.add('Overall expenses are strictly within income limits, keeping cash flow positive.');
      } else {
        list.add('Monthly spending currently exceeds recorded income by ${AppFormatters.currency(metrics.totalExpense - metrics.totalIncome)}.');
      }

      if (metrics.savingsRate >= 0.20) {
        list.add('Savings improved by ${(metrics.savingsRate * 100).toStringAsFixed(0)}% of total income.');
      } else {
        list.add('Current savings rate is ${(metrics.savingsRate * 100).toStringAsFixed(0)}%. Spending up to daily target will help grow savings.');
      }

      if (_intentState != null && _intentState!.plainLanguageConclusions.isNotEmpty) {
        list.addAll(_intentState!.plainLanguageConclusions);
      }
    }

    return list.map((conclusion) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3.0),
              child: Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.incomeGreen),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                conclusion,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
