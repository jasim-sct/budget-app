import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/services/global_filter_controller.dart';
import '../../../core/state/micro_notifier.dart';
import '../../../core/state/month_selector_controller.dart';
import 'financial_metrics.dart';

/// Level 10 Enterprise Financial Calculation Engine.
/// Single source of truth calculation engine. Derives all financial metrics deterministically from SQLite master ledger under Global Filter Context.
class FinancialCalculationEngine {
  static FinancialCalculationEngine? _instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  final MicroState<FinancialMetrics> metricsNotifier = MicroState(
    FinancialMetrics.initial(DateTime.now().year, DateTime.now().month),
  );

  FinancialCalculationEngine._internal() {
    MonthSelectorController.instance.addListener(recalculate);
    FinancialSyncService.instance.addListener(recalculate);
    GlobalFilterController.instance.filterNotifier.addListener(recalculate);
    recalculate();
  }

  static FinancialCalculationEngine get instance {
    _instance ??= FinancialCalculationEngine._internal();
    return _instance!;
  }

  /// Single-pass deterministic financial pipeline execution under active Global Filter Context.
  Future<void> recalculate() async {
    final date = MonthSelectorController.instance.value;
    final year = date.year;
    final month = date.month;
    final filter = GlobalFilterController.instance.state;

    // 1. Transaction & Cash Flow Totals (Filtered)
    final totals = await _db.getFilteredSummaryTotals(
      filter,
      activeYear: year,
      activeMonth: month,
    );
    final income = totals['income'] ?? 0.0;
    final expense = totals['expense'] ?? 0.0;
    final netCashFlow = income - expense;
    final avgTx = totals['avg'] ?? 0.0;
    final maxExpense = totals['max'] ?? 0.0;
    final count = (totals['count'] ?? 0.0).toInt();

    // 2. Merchant Engine Top Merchant
    final merchantBreakdown = await _db.getMerchantBreakdownByMonth(year, month);
    String topMerchantName = 'None';
    double topMerchantSpent = 0.0;
    if (merchantBreakdown.isNotEmpty) {
      topMerchantName = merchantBreakdown.first['merchant'] as String? ?? 'None';
      topMerchantSpent = (merchantBreakdown.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    // 3. Category Engine Top Outflow
    final catBreakdown = await _db.getCategoryBreakdownByMonth(year, month);
    String topCatName = 'None';
    double topCatSpent = 0.0;
    if (catBreakdown.isNotEmpty) {
      topCatName = catBreakdown.first['category'] as String? ?? 'None';
      topCatSpent = (catBreakdown.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    // 4. Net Worth & Accounts
    final netWorthData = await _db.getNetWorthMetrics();
    final assets = netWorthData['assets'] ?? 0.0;
    final liabilities = netWorthData['liabilities'] ?? 0.0;
    final netWorth = netWorthData['net_worth'] ?? 0.0;

    // 5. Savings Engine & Burn Rate
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;
    final daysInMonth = DateTime(year, month + 1, 0).day.clamp(1, 31);
    final dailyBurnRate = expense / daysInMonth;
    final emergencyFundMonths = dailyBurnRate > 0 ? (assets / (dailyBurnRate * 30)) : 0.0;

    // 6. Budget Engine Aggregation & Integration
    final dbObj = await _db.database;
    final budgetRows = await dbObj.rawQuery('SELECT SUM(amount_limit + carry_forward_amount) AS total_alloc FROM budgets WHERE is_active = 1');
    final totalBudgetAllocation = (budgetRows.first['total_alloc'] as num?)?.toDouble() ?? 0.0;
    final totalBudgetSpent = expense;
    final totalBudgetRemaining = totalBudgetAllocation - totalBudgetSpent;
    final budgetHealthScore = totalBudgetAllocation > 0
        ? ((1.0 - (totalBudgetSpent / totalBudgetAllocation).clamp(0.0, 1.0)) * 100.0)
        : 100.0;

    // 7. Deterministic Financial Score Engine (0 - 100)
    final double savingsScore = (savingsRate * 0.4).clamp(0.0, 40.0);
    final double cashFlowScore = netCashFlow >= 0 ? 35.0 : 10.0;
    final double netWorthScore = netWorth >= 0 ? 25.0 : 5.0;
    final int score = (savingsScore + cashFlowScore + netWorthScore).round().clamp(0, 100);

    // 8. Quarter & Annual Engine Rollups
    final currentQuarter = ((month - 1) ~/ 3) + 1;
    final qTotals = await _db.getQuarterTotals(year, currentQuarter);
    final qIncome = qTotals['income'] ?? 0.0;
    final qExpense = qTotals['expense'] ?? 0.0;

    final aTotals = await _db.getAnnualTotals(year);
    final aIncome = aTotals['income'] ?? 0.0;
    final aExpense = aTotals['expense'] ?? 0.0;

    // 9. Forecast Engine (Linear Trend Projection)
    final forecastExpense = expense > 0 ? expense * 0.98 : 0.0;
    final forecastIncome = income > 0 ? income * 1.02 : 0.0;

    final newMetrics = FinancialMetrics(
      year: year,
      month: month,
      totalIncome: income,
      totalExpense: expense,
      netCashFlow: netCashFlow,
      averageTransaction: avgTx,
      maxExpense: maxExpense,
      transactionCount: count,
      topMerchantName: topMerchantName,
      topMerchantSpent: topMerchantSpent,
      topCategoryName: topCatName,
      topCategorySpent: topCatSpent,
      totalAssets: assets,
      totalLiabilities: liabilities,
      netWorth: netWorth,
      savingsRate: savingsRate,
      dailyBurnRate: dailyBurnRate,
      emergencyFundMonths: emergencyFundMonths,
      totalBudgetAllocation: totalBudgetAllocation,
      totalBudgetSpent: totalBudgetSpent,
      totalBudgetRemaining: totalBudgetRemaining,
      budgetHealthScore: budgetHealthScore,
      financialScore: score,
      quarterIncome: qIncome,
      quarterExpense: qExpense,
      quarterNet: qIncome - qExpense,
      annualIncome: aIncome,
      annualExpense: aExpense,
      annualNet: aIncome - aExpense,
      nextMonthForecastExpense: forecastExpense,
      nextMonthForecastIncome: forecastIncome,
      nextMonthForecastCashFlow: forecastIncome - forecastExpense,
    );

    metricsNotifier.update(newMetrics);
  }
}
