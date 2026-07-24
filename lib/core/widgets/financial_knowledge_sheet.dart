import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass/glass_card.dart';

/// Preset metric types for instant Click-to-Explain modals across the app.
enum FinancialMetricType {
  netWorth,
  dailySafeSpending,
  financialScore,
  savingsRate,
  budgetRemaining,
  netCashFlow,
  dailyBurnRate,
  accountBalance,
  goalSavings,
  forecastBalance,
  custom,
}

class FinancialKnowledgeSheet extends StatelessWidget {
  final String title;
  final String metricValue;
  final String subtitle;
  final String definition;
  final String purpose;
  final String decisionHelp;
  final String formulaLatex;
  final String formulaDescription;
  final List<String> sourceDetails;
  final String dateRange;
  final String historyTrend;
  final String recommendation;
  final String statusText;
  final Color statusColor;
  final Map<String, VoidCallback>? navigationActions;

  const FinancialKnowledgeSheet({
    super.key,
    required this.title,
    required this.metricValue,
    required this.subtitle,
    required this.definition,
    required this.purpose,
    required this.decisionHelp,
    required this.formulaLatex,
    required this.formulaDescription,
    required this.sourceDetails,
    required this.dateRange,
    required this.historyTrend,
    required this.recommendation,
    this.statusText = 'Verified',
    this.statusColor = AppColors.incomeGreen,
    this.navigationActions,
  });

  /// Factory helper to generate complete Click-to-Explain sheet for standard metrics.
  static void showForMetric(
    BuildContext context, {
    required FinancialMetricType type,
    required String metricValue,
    String? customTitle,
    List<String>? customSources,
    Map<String, VoidCallback>? navigationActions,
  }) {
    String title = customTitle ?? 'Financial Metric';
    String subtitle = 'Calculated from Master Ledger';
    String definition = '';
    String purpose = '';
    String decisionHelp = '';
    String formulaLatex = '';
    String formulaDescription = '';
    List<String> sourceDetails = customSources ?? [];
    String dateRange = 'Current Active Month';
    String historyTrend = 'Stable compared to previous period.';
    String recommendation = 'Maintain current financial habits.';
    String statusText = 'Optimal';
    Color statusColor = AppColors.incomeGreen;

    switch (type) {
      case FinancialMetricType.netWorth:
        title = customTitle ?? 'Net Worth';
        subtitle = 'Total Value of Assets minus Total Liabilities';
        definition = 'Your Net Worth represents your true overall financial wealth after taking into account all your money, investments, and physical assets, then subtracting all credit card balances, loans, and outstanding debts.';
        purpose = 'It exists to give you a single, unambiguous measure of financial solvency and overall wealth growth over time.';
        decisionHelp = 'A growing Net Worth indicates positive wealth accumulation. If Net Worth drops, inspect whether credit debt increased or assets were depleted.';
        formulaLatex = r'\text{Net Worth} = \sum \text{Liquid Assets} - \sum \text{Liabilities}';
        formulaDescription = 'Sum of all positive Cash, Checking, Savings, Investment balances minus Credit Card debt, Loans, and Overdrafts.';
        sourceDetails = customSources ?? [
          'Liquid Accounts: Cash, Checking, Savings, Investments',
          'Liability Accounts: Credit Cards, Personal Loans, Overdrafts',
          'Ledger Source: SQLite Account Balances'
        ];
        historyTrend = 'Calculated live from atomic account ledger transactions.';
        recommendation = 'Aim to increase net worth by allocating surplus cash to savings accounts or debt reduction.';
        statusText = 'Verified Solvency';
        statusColor = AppColors.primaryBlue;
        break;

      case FinancialMetricType.dailySafeSpending:
        title = customTitle ?? 'Daily Safe Spending';
        subtitle = 'Safe Daily Expenditure Limit';
        definition = 'The exact dollar amount you can spend today without exceeding your allocated budget envelopes for the remaining days of the month.';
        purpose = 'It exists to translate complex monthly budgets into a simple, actionable daily number that guides real-time purchasing decisions.';
        decisionHelp = 'If you stay under this limit today, your monthly budget will stay 100% on track automatically.';
        formulaLatex = r'\text{Daily Safe Spend} = \frac{\text{Total Budget Remaining}}{\text{Days Remaining in Month}}';
        formulaDescription = 'Remaining unspent budget divided by remaining days in the active month period.';
        sourceDetails = customSources ?? [
          'Active Envelopes: Food, Utilities, Entertainment, Transport',
          'Month Progress: Remaining days in active cycle',
          'Ledger Source: SQLite Category Transactions'
        ];
        historyTrend = 'Dynamically adjusts daily based on today\'s actual spending.';
        recommendation = 'Keep today\'s total spending below this limit to preserve budget buffer.';
        statusText = 'Pacing Normal';
        statusColor = AppColors.incomeGreen;
        break;

      case FinancialMetricType.financialScore:
        title = customTitle ?? 'Financial Health Score';
        subtitle = 'Deterministic Score (0 - 100)';
        definition = 'A comprehensive financial health score calculated deterministically from your savings rate %, net cash flow status, and budget adherence.';
        purpose = 'It provides an objective, executive-level summary of your financial discipline and stability.';
        decisionHelp = 'Scores above 70 indicate strong financial resilience. Scores below 50 highlight areas requiring immediate expense reduction or savings acceleration.';
        formulaLatex = r'\text{Score} = (0.4 \times \text{SavingsRate}) + \text{CashFlowScore} + \text{NetWorthScore}';
        formulaDescription = 'Weighted score: Savings Rate (max 40 pts) + Positive Cash Flow (35 pts) + Positive Net Worth (25 pts).';
        sourceDetails = customSources ?? [
          'Savings Rate % (40% Weight)',
          'Net Cash Flow Status (35% Weight)',
          'Net Worth Solvency (25% Weight)'
        ];
        historyTrend = 'Re-evaluated automatically on every new transaction.';
        recommendation = 'Boost your score by saving at least 20% of income and keeping expenses below income.';
        statusText = 'Health Index';
        statusColor = AppColors.primaryBlue;
        break;

      case FinancialMetricType.savingsRate:
        title = customTitle ?? 'Savings Rate %';
        subtitle = 'Percentage of Income Retained';
        definition = 'The proportion of your total gross income that remains unspent at the end of the calculation period.';
        purpose = 'Measures your ability to convert income into lasting wealth rather than consuming everything earned.';
        decisionHelp = 'A savings rate of 20%+ is standard for long-term wealth building. A negative rate means you are spending debt or savings reserves.';
        formulaLatex = r'\text{Savings Rate \%} = \frac{\text{Income} - \text{Expenses}}{\text{Income}} \times 100';
        formulaDescription = 'Net Cash Flow divided by Total Income expressed as a percentage.';
        sourceDetails = customSources ?? [
          'Master Ledger Income Transactions',
          'Master Ledger Expense Transactions',
          'Global Month & Filter Scope'
        ];
        historyTrend = 'Higher than previous month average.';
        recommendation = 'Automate transfers to savings accounts at the beginning of the month.';
        statusText = 'Wealth Builder';
        statusColor = AppColors.incomeGreen;
        break;

      case FinancialMetricType.budgetRemaining:
        title = customTitle ?? 'Budget Remaining';
        subtitle = 'Available Envelope Funds';
        definition = 'The total unspent balance left inside your active spending envelopes for the current period.';
        purpose = 'Prevents overspending by showing exactly how much capital remains reserved for planned categories.';
        decisionHelp = 'If this reaches zero before the end of the month, any further purchases will require budget transfer or debt creation.';
        formulaLatex = r'\text{Remaining} = \text{Allocated Budget} - \text{Spent Amount}';
        formulaDescription = 'Sum of category envelope caps minus category expense transactions.';
        sourceDetails = customSources ?? [
          'Active Category Envelope Limits',
          'Master Ledger Category Expenses'
        ];
        historyTrend = 'Pacing evenly across cycle days.';
        recommendation = 'Monitor high-outflow categories like Dining and Shopping.';
        statusText = 'Envelope Buffer';
        statusColor = AppColors.primaryBlue;
        break;

      case FinancialMetricType.netCashFlow:
        title = customTitle ?? 'Net Cash Flow';
        subtitle = 'Period Surplus or Deficit';
        definition = 'The net money remaining after subtracting total expenses from total income during the selected period.';
        purpose = 'Indicates whether your financial engine is generating positive capital or consuming existing capital.';
        decisionHelp = 'Positive cash flow can be allocated to goals and debt repayment. Negative cash flow is an urgent signal to reduce discretionary expenses.';
        formulaLatex = r'\text{Net Cash Flow} = \text{Total Income} - \text{Total Expense}';
        formulaDescription = 'Income ledger sum minus Expense ledger sum for selected date range.';
        sourceDetails = customSources ?? [
          'SQLite Income Transactions',
          'SQLite Expense Transactions'
        ];
        historyTrend = 'Evaluated over active filter period.';
        recommendation = 'Maintain positive cash flow by capping discretionary expenses.';
        statusText = 'Cash Flow Status';
        statusColor = AppColors.incomeGreen;
        break;

      case FinancialMetricType.dailyBurnRate:
        title = customTitle ?? 'Daily Burn Rate';
        subtitle = 'Average Outflow per Day';
        definition = 'The average amount of money spent per day across the current billing cycle.';
        purpose = 'Helps project your total month-end expenditure if spending habits remain unchanged.';
        decisionHelp = 'Multiply your Daily Burn Rate by remaining days in the month to forecast total period outflow.';
        formulaLatex = r'\text{Daily Burn Rate} = \frac{\text{Total Expenses}}{\text{Days Elapsed in Month}}';
        formulaDescription = 'Total month-to-date expense sum divided by elapsed calendar days.';
        sourceDetails = customSources ?? [
          'Master Ledger Expense Transactions',
          'Elapsed Calendar Days in Active Month'
        ];
        historyTrend = 'Calculated daily from ledger expenses.';
        recommendation = 'If burn rate exceeds daily safe spending, lower discretionary spending immediately.';
        statusText = 'Burn Speed';
        statusColor = AppColors.warningOrange;
        break;

      case FinancialMetricType.accountBalance:
        title = customTitle ?? 'Account Balance';
        subtitle = 'Real-time Wallet Balance';
        definition = 'The total current monetary value stored within this specific financial wallet or bank account.';
        purpose = 'Shows liquid availability or outstanding balance for a specific wallet or liability.';
        decisionHelp = 'Checking this before large transactions ensures you do not trigger overdraft fees or overextend credit limits.';
        formulaLatex = r'\text{Balance} = \text{Initial Balance} + \sum \text{Credits} - \sum \text{Debits}';
        formulaDescription = 'Atomic sum of starting balance plus all linked deposit transactions minus withdrawal transactions.';
        sourceDetails = customSources ?? [
          'Account Master Table Record',
          'Linked SQLite Ledger Transactions'
        ];
        historyTrend = 'Updated atomically on every ledger transaction.';
        recommendation = 'Keep liquid cash buffers to cover upcoming bills.';
        statusText = 'Live Wallet';
        statusColor = AppColors.primaryBlue;
        break;

      case FinancialMetricType.goalSavings:
        title = customTitle ?? 'Goal Savings Target';
        subtitle = 'Monthly Required Savings';
        definition = 'The exact monthly amount you must deposit into your savings account to reach your goal target on schedule.';
        purpose = 'Breaks large long-term financial targets down into manageable monthly milestone payments.';
        decisionHelp = 'Fulfilling this monthly allocation guarantees your goal will be achieved by your target date.';
        formulaLatex = r'\text{Required Monthly Savings} = \frac{\text{Target Amount} - \text{Saved Amount}}{\text{Months Remaining}}';
        formulaDescription = 'Unsaved goal target balance divided by remaining months until target date.';
        sourceDetails = customSources ?? [
          'Goal Target Amount & Current Saved Amount',
          'Months Remaining until Target Date'
        ];
        historyTrend = 'On track for scheduled completion.';
        recommendation = 'Transfer required monthly amount as soon as income is received.';
        statusText = 'Goal Pacing';
        statusColor = AppColors.incomeGreen;
        break;

      case FinancialMetricType.forecastBalance:
        title = customTitle ?? 'End-of-Month Forecast';
        subtitle = 'Linear Projected Surplus / Deficit';
        definition = 'The projected total cash position at the end of the current month based on active burn rate and scheduled bills.';
        purpose = 'Gives you an early warning system to prevent negative end-of-month balances before they occur.';
        decisionHelp = 'A positive forecast confirms healthy budget pacing. A negative forecast indicates overspending risk.';
        formulaLatex = r'\text{Forecast} = \text{Current Cash} + (\text{Daily Net Rate} \times \text{Days Remaining})';
        formulaDescription = 'Current net balance plus projected daily net cash flow over remaining cycle days.';
        sourceDetails = customSources ?? [
          'Current Account Balances',
          'Historical Expense Burn Rate'
        ];
        historyTrend = 'Based on linear trend projection.';
        recommendation = 'Adjust daily spending if projected end balance falls below emergency target.';
        statusText = 'Predictive Model';
        statusColor = AppColors.primaryBlue;
        break;

      default:
        title = customTitle ?? 'Financial Calculation';
        definition = 'Detailed financial calculation derived deterministically from the master transaction ledger.';
        purpose = 'Provides transparency and eliminates mystery numbers.';
        decisionHelp = 'Use this metric to understand your financial standing.';
        formulaLatex = r'\text{Result} = f(\text{Ledger Transactions})';
        formulaDescription = 'Derived directly from user ledger transactions.';
        sourceDetails = customSources ?? ['Master SQLite Database Ledger'];
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FinancialKnowledgeSheet(
        title: title,
        metricValue: metricValue,
        subtitle: subtitle,
        definition: definition,
        purpose: purpose,
        decisionHelp: decisionHelp,
        formulaLatex: formulaLatex,
        formulaDescription: formulaDescription,
        sourceDetails: sourceDetails,
        dateRange: dateRange,
        historyTrend: historyTrend,
        recommendation: recommendation,
        statusText: statusText,
        statusColor: statusColor,
        navigationActions: navigationActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.school_outlined, color: AppColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleLarge(isDark).copyWith(fontSize: 17),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(isDark).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // 1. Metric Display Hero Box
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CALCULATED VALUE',
                              style: AppTypography.sectionLabel(isDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metricValue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displayLarge(isDark).copyWith(
                                fontSize: 26,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Financial Knowledge Layer (What / Why / How)
                _buildSectionHeader('1. WHAT IS THIS & WHY DOES IT EXIST?', isDark),
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKnowledgeTile('Definition', definition, isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildKnowledgeTile('Financial Purpose', purpose, isDark),
                      const SizedBox(height: AppSpacing.sm),
                      _buildKnowledgeTile('Decision Value', decisionHelp, isDark, isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Mathematical Formula Breakdown
                _buildSectionHeader('2. MATHEMATICAL FORMULA & CALCULATION LOGIC', isDark),
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          formulaLatex,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formulaDescription,
                        style: AppTypography.caption(isDark).copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Data Source & Traceability Trail
                _buildSectionHeader('3. DATA SOURCES & AUDIT TRAIL', isDark),
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Calculation Scope:', style: AppTypography.caption(isDark)),
                          Text(dateRange, style: AppTypography.caption(isDark).copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Divider(height: 16),
                      ...sourceDetails.map((src) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right_rounded, size: 18, color: AppColors.primaryBlue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                src,
                                style: AppTypography.caption(isDark).copyWith(height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 5. Contextual Recommendation & Action
                _buildSectionHeader('4. RECOMMENDATION & ACTION PLAN', isDark),
                const SizedBox(height: AppSpacing.xs),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.incomeGreen, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: AppTypography.bodyMedium(isDark).copyWith(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 6. Navigation Actions (if provided)
                if (navigationActions != null && navigationActions!.isNotEmpty) ...[
                  _buildSectionHeader('5. DIRECT MODULE SHORTCUTS', isDark),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: navigationActions!.entries.map((entry) {
                      return ActionChip(
                        avatar: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primaryBlue),
                        label: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                        ),
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                        onPressed: () {
                          Navigator.pop(context);
                          entry.value();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
    );
  }

  Widget _buildKnowledgeTile(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppColors.primaryBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium(isDark).copyWith(
            fontSize: 13,
            height: 1.4,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
            color: isHighlight ? (isDark ? Colors.white : Colors.black) : null,
          ),
        ),
      ],
    );
  }
}
