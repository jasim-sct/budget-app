import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/data_exporter.dart';
import '../../../core/state/month_selector_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass/glass_button.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/month_selector_bar.dart';

/// Commercial Financial Reports & Statement Engine Screen.
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
          title: Text('CSV Export for ${AppFormatters.monthYear(date)}'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Financial Statements',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryEmerald,
          labelColor: AppColors.primaryEmerald,
          unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Income Stmt'),
            Tab(text: 'Cash Flow'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Summary Tab
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EXECUTIVE CASH FLOW SUMMARY', style: AppTypography.labelSmall(isDark)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('INFLOW', style: TextStyle(fontSize: 11, color: AppColors.incomeGreen, fontWeight: FontWeight.w800)),
                            Text(AppFormatters.currency(income), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OUTFLOW', style: TextStyle(fontSize: 11, color: AppColors.expenseRed, fontWeight: FontWeight.w800)),
                            Text(AppFormatters.currency(expense), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NET CASH FLOW', style: TextStyle(fontSize: 11, color: AppColors.primaryEmerald, fontWeight: FontWeight.w800)),
                            Text(
                              AppFormatters.currency(netCashFlow),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: netCashFlow >= 0 ? AppColors.incomeGreen : AppColors.expenseRed,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('TOP CATEGORY EXPENSES', style: AppTypography.labelSmall(isDark)),
              const SizedBox(height: AppSpacing.sm),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _breakdown.isEmpty
                      ? GlassCard(
                          child: Center(
                            child: Text(
                              'No expense records found for ${AppFormatters.monthYear(date)}',
                              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                        )
                      : GlassCard(
                          child: Column(
                            children: _breakdown.map((row) {
                              final cat = row['category'] as String;
                              final total = (row['total'] as num).toDouble();
                              final pct = expense > 0 ? ((total / expense) * 100).toStringAsFixed(1) : '0.0';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(cat, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Row(
                                      children: [
                                        Text('$pct%', style: const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 12),
                                        Text(AppFormatters.currency(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
              const SizedBox(height: AppSpacing.xl),
              GlassButton(
                label: 'Export ${AppFormatters.shortMonthYear(date)} Report (CSV)',
                icon: Icons.file_download_outlined,
                onPressed: _exportCsv,
                variant: GlassButtonVariant.primary,
              ),
              const SizedBox(height: 100),
            ],
          ),

          // 2. Income Statement Tab
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INCOME STATEMENT (P&L)', style: AppTypography.labelSmall(isDark)),
                    const SizedBox(height: AppSpacing.md),
                    _buildRow('Gross Revenue (Income)', income, isPositive: true),
                    const Divider(),
                    _buildRow('Operating Outflows (Expenses)', expense, isPositive: false),
                    const Divider(),
                    _buildRow('Net Income / (Loss)', netCashFlow, isBold: true),
                  ],
                ),
              ),
            ],
          ),

          // 3. Cash Flow Statement Tab
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const MonthSelectorBar(),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CASH FLOW STATEMENT', style: AppTypography.labelSmall(isDark)),
                    const SizedBox(height: AppSpacing.md),
                    _buildRow('Operating Inflows', income, isPositive: true),
                    _buildRow('Operating Outflows', expense, isPositive: false),
                    const Divider(),
                    _buildRow('Net Operating Cash Flow', netCashFlow, isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String title, double value, {bool isPositive = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            AppFormatters.currency(value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
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
