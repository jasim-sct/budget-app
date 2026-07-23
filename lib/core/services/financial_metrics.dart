/// Master Financial Metrics Data Class (Level 10 Engine).
/// Contains deterministic, calculated scalar values derived exclusively from SQLite single source of truth.
class FinancialMetrics {
  final int year;
  final int month;

  // Cash Flow & Transactions
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double averageTransaction;
  final double maxExpense;
  final int transactionCount;

  // Merchant Engine
  final String topMerchantName;
  final double topMerchantSpent;

  // Category Engine
  final String topCategoryName;
  final double topCategorySpent;

  // Net Worth & Accounts
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;

  // Savings & Runway
  final double savingsRate;
  final double dailyBurnRate;
  final double emergencyFundMonths;

  // Financial Score (0 - 100)
  final int financialScore;

  // Quarter & Annual Engine Rollups
  final double quarterIncome;
  final double quarterExpense;
  final double quarterNet;
  final double annualIncome;
  final double annualExpense;
  final double annualNet;

  // Forecast Engine
  final double nextMonthForecastExpense;
  final double nextMonthForecastIncome;
  final double nextMonthForecastCashFlow;

  const FinancialMetrics({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.averageTransaction,
    required this.maxExpense,
    required this.transactionCount,
    required this.topMerchantName,
    required this.topMerchantSpent,
    required this.topCategoryName,
    required this.topCategorySpent,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.savingsRate,
    required this.dailyBurnRate,
    required this.emergencyFundMonths,
    required this.financialScore,
    required this.quarterIncome,
    required this.quarterExpense,
    required this.quarterNet,
    required this.annualIncome,
    required this.annualExpense,
    required this.annualNet,
    required this.nextMonthForecastExpense,
    required this.nextMonthForecastIncome,
    required this.nextMonthForecastCashFlow,
  });

  factory FinancialMetrics.initial(int year, int month) {
    return FinancialMetrics(
      year: year,
      month: month,
      totalIncome: 0.0,
      totalExpense: 0.0,
      netCashFlow: 0.0,
      averageTransaction: 0.0,
      maxExpense: 0.0,
      transactionCount: 0,
      topMerchantName: 'None',
      topMerchantSpent: 0.0,
      topCategoryName: 'None',
      topCategorySpent: 0.0,
      totalAssets: 0.0,
      totalLiabilities: 0.0,
      netWorth: 0.0,
      savingsRate: 0.0,
      dailyBurnRate: 0.0,
      emergencyFundMonths: 0.0,
      financialScore: 100,
      quarterIncome: 0.0,
      quarterExpense: 0.0,
      quarterNet: 0.0,
      annualIncome: 0.0,
      annualExpense: 0.0,
      annualNet: 0.0,
      nextMonthForecastExpense: 0.0,
      nextMonthForecastIncome: 0.0,
      nextMonthForecastCashFlow: 0.0,
    );
  }
}
