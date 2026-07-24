import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/data_exporter.dart';
import '../../../core/state/month_selector_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/financial_knowledge_sheet.dart';
import '../../../core/widgets/month_selector_bar.dart';
import '../../../core/widgets/scan_first_components.dart';

/// Financial Statements & Reports Screen.
/// Follows Scan-First Reading Experience & Mobile-First layout (320px+ viewports).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late final TabController _tabController;

  Map<String, double> _summary = {'income': 0.0, 'expense': 0.0};
  List<Map<String, dynamic>> _breakdown = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    MonthSelectorController.instance.addListener(_loadReportData);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    MonthSelectorController.instance.removeListener(_loadReportData);
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final date = MonthSelectorController.instance.value;
    final totals = await _db.getSummaryTotalsByMonth(date.year, date.month);
    final catBreakdown = await _db.getCategoryBreakdownByMonth(date.year, date.month);

    if (mounted) {
      setState(() {
        _summary = totals;
        _breakdown = catBreakdown;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    final date = MonthSelectorController.instance.value;
    final csvStr = await DataExporter.exportTransactionsToCsv(year: date.year, month: date.month);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('CSV Export (${AppFormatters.monthYear(date)})'),
          content: SingleChildScrollView(
            child: SelectableText(csvStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = MonthSelectorController.instance.value;

    final income = _summary['income'] ?? 0.0;
    final expense = _summary['expense'] ?? 0.0;
    final netCashFlow = income - expense;
    final topCategory = _breakdown.isNotEmpty ? _breakdown.first['category'] as String : 'None';
    final topCategorySpent = _breakdown.isNotEmpty ? (_breakdown.first['total'] as num).toDouble() : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Statements'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'P&L Stmt'),
            Tab(text: 'Cash Flow'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Summary Tab (Scan-First Conclusions First)
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.xs),

              // HIGHLIGHTED CONCLUSIONS GRID
              Text('EXECUTIVE CONCLUSIONS', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue)),
              const SizedBox(height: AppSpacing.xs),

              Row(
                children: [
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Total Spent',
                      value: AppFormatters.currency(expense),
                      statusPill: expense > 0 ? 'OUTFLOW' : 'ZERO',
                      statusColor: expense > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                      subtitle: 'Period Total',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Top Category',
                      value: topCategory,
                      statusPill: AppFormatters.currency(topCategorySpent),
                      statusColor: AppColors.warningOrange,
                      subtitle: 'Highest Category',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Net Savings',
                      value: AppFormatters.currency(netCashFlow),
                      statusPill: netCashFlow >= 0 ? 'ON TARGET' : 'DEFICIT',
                      statusColor: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                      subtitle: 'Retained Cash',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppScannableKpiTile(
                      title: 'Total Income',
                      value: AppFormatters.currency(income),
                      statusPill: 'INFLOW',
                      statusColor: AppColors.incomeGreen,
                      subtitle: 'Gross Revenue',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // FINANCIAL STATEMENT CASH FLOW BAR
              GestureDetector(
                onTap: () {
                  FinancialKnowledgeSheet.showForMetric(
                    context,
                    type: FinancialMetricType.netCashFlow,
                    metricValue: AppFormatters.currency(netCashFlow),
                    customTitle: 'Executive Cash Flow Statement',
                    customSources: [
                      'Total Inflow (Income): ${AppFormatters.currency(income)}',
                      'Total Outflow (Expenses): ${AppFormatters.currency(expense)}',
                      'Net Retained Cash: ${AppFormatters.currency(netCashFlow)}',
                      'Active Period: ${AppFormatters.monthYear(date)}',
                    ],
                  );
                },
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CASH FLOW SUMMARY', style: AppTypography.sectionLabel(isDark)),
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryBlue),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('INFLOW', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.incomeGreen, fontSize: 9)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(AppFormatters.currency(income), style: AppTypography.titleMedium(isDark)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('OUTFLOW', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.expenseRed, fontSize: 9)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(AppFormatters.currency(expense), style: AppTypography.titleMedium(isDark)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NET CASH', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue, fontSize: 9)),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    AppFormatters.currency(netCashFlow),
                                    style: AppTypography.titleMedium(isDark).copyWith(
                                      color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // CATEGORY BREAKDOWN LIST
              Text('CATEGORY BREAKDOWN', style: AppTypography.sectionLabel(isDark)),
              const SizedBox(height: AppSpacing.xs),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.0))
                  : _breakdown.isEmpty
                      ? AppCard(
                          child: Center(
                            child: Text(
                              'No expense records found for ${AppFormatters.monthYear(date)}',
                              style: AppTypography.caption(isDark),
                            ),
                          ),
                        )
                      : AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Column(
                            children: _breakdown.map((row) {
                              final cat = row['category'] as String;
                              final total = (row['total'] as num).toDouble();
                              final pct = expense > 0 ? ((total / expense) * 100).toStringAsFixed(1) : '0.0';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.titleMedium(isDark),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AppStatusBadge(
                                          label: '$pct%',
                                          color: AppColors.primaryBlue,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          AppFormatters.currency(total),
                                          style: AppTypography.titleMedium(isDark).copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Export ${AppFormatters.shortMonthYear(date)} Report (CSV)',
                icon: Icons.file_download_outlined,
                onPressed: _exportCsv,
              ),
              const SizedBox(height: 80),
            ],
          ),

          // 2. Income Statement Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INCOME STATEMENT (P&L)', style: AppTypography.sectionLabel(isDark)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow('Gross Revenue (Income)', income, isDark: isDark, isPositive: true),
                    const Divider(),
                    _buildRow('Operating Outflows (Expenses)', expense, isDark: isDark, isPositive: false),
                    const Divider(),
                    _buildRow('Net Income / (Loss)', netCashFlow, isDark: isDark, isBold: true),
                  ],
                ),
              ),
            ],
          ),

          // 3. Cash Flow Statement Tab
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CASH FLOW STATEMENT', style: AppTypography.sectionLabel(isDark)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRow('Operating Inflows', income, isDark: isDark, isPositive: true),
                    _buildRow('Operating Outflows', expense, isDark: isDark, isPositive: false),
                    const Divider(),
                    _buildRow('Net Operating Cash Flow', netCashFlow, isDark: isDark, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, double value, {required bool isDark, bool isPositive = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isBold ? AppTypography.titleLarge(isDark).copyWith(fontSize: 14) : AppTypography.bodyMedium(isDark),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppFormatters.currency(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold
                  ? (value >= 0 ? AppColors.incomeGreen : AppColors.expenseRed)
                  : (isPositive ? AppColors.incomeGreen : AppColors.expenseRed),
            ),
          ),
        ],
      ),
    );
  }
}
