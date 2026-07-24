import 'package:flutter/material.dart';
import '../../features/budgets/data/datasources/budget_dao.dart';
import '../../features/budgets/domain/models/budget_period.dart';
import '../database/app_database.dart';
import '../utils/formatters.dart';
import '../widgets/calculation_explanation_modal.dart';
import 'financial_calculation_engine.dart';

enum IntentCardSeverity {
  actionRequired,
  warning,
  positive,
  info,
}

class IntentDecisionCardData {
  final String id;
  final String title;
  final String statement;
  final String actionLabel;
  final IntentCardSeverity severity;
  final IconData icon;
  final Color accentColor;
  final Map<String, dynamic>? extraData;

  const IntentDecisionCardData({
    required this.id,
    required this.title,
    required this.statement,
    required this.actionLabel,
    required this.severity,
    required this.icon,
    required this.accentColor,
    this.extraData,
  });
}

class IntentDecisionState {
  final double dailySafeSpend;
  final double remainingBudget;
  final int remainingDays;
  final String dailySpendVerdict;
  final List<IntentDecisionCardData> decisionCards;
  final List<String> plainLanguageConclusions;
  final List<EnvelopeCalculationDetail> envelopeDetails;

  const IntentDecisionState({
    required this.dailySafeSpend,
    required this.remainingBudget,
    required this.remainingDays,
    required this.dailySpendVerdict,
    required this.decisionCards,
    required this.plainLanguageConclusions,
    required this.envelopeDetails,
  });
}

class IntentDecisionEngine {
  static Future<IntentDecisionState> evaluateCurrentIntent() async {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    final remainingDays = (lastDay - day + 1).clamp(1, 31);

    final metrics = FinancialCalculationEngine.instance.metricsNotifier.value;
    final totalIncome = metrics.totalIncome;
    final totalExpense = metrics.totalExpense;

    final dao = BudgetDao(AppDatabase.instance);
    final summaries = await dao.getBudgetsForPeriod(
      periodType: BudgetPeriodType.monthly,
      referenceDate: now,
    );

    final envelopeDetails = <EnvelopeCalculationDetail>[];
    double totalDailySafeSpend = 0.0;
    double totalRemainingBudget = 0.0;

    for (final summary in summaries) {
      final category = summary.budget.name;
      final allocated = summary.metrics.allocation;
      final spent = summary.spent;
      final remaining = (allocated - spent).clamp(0.0, double.infinity);
      final daysLeft = remainingDays;
      final envelopeDailyLimit = remaining / daysLeft;

      envelopeDetails.add(
        EnvelopeCalculationDetail(
          category: category,
          allocated: allocated,
          spent: spent,
          remaining: remaining,
          daysRemaining: daysLeft,
          dailyLimit: envelopeDailyLimit,
        ),
      );

      totalDailySafeSpend += envelopeDailyLimit;
      totalRemainingBudget += remaining;
    }

    final dailySafeSpend = totalDailySafeSpend;
    final remainingBudget = totalRemainingBudget;

    String dailySpendVerdict;
    if (summaries.isEmpty) {
      dailySpendVerdict = 'No active budget envelopes configured. Create a budget to calculate your daily limit.';
    } else if (dailySafeSpend > 50) {
      dailySpendVerdict = 'You can safely spend ${AppFormatters.currency(dailySafeSpend)} today.';
    } else if (dailySafeSpend > 10) {
      dailySpendVerdict = 'Moderate allowance: ${AppFormatters.currency(dailySafeSpend)} available today.';
    } else {
      dailySpendVerdict = 'Tight budget: Only ${AppFormatters.currency(dailySafeSpend)} remaining per day.';
    }

    final decisionCards = <IntentDecisionCardData>[];
    final conclusions = <String>[];

    // 1. Evaluate Budget Envelope Risks with Emotional Guidance
    for (final summary in summaries) {
      final category = summary.budget.name;
      final allocated = summary.metrics.allocation;
      final spent = summary.spent;

      if (allocated > 0) {
        final ratio = spent / allocated;
        if (ratio >= 1.0) {
          final overspend = spent - allocated;
          final recoveryDailyReduce = remainingDays > 0 ? (overspend / remainingDays) : overspend;
          decisionCards.add(
            IntentDecisionCardData(
              id: 'overspend_$category',
              title: '$category Spending Guide',
              statement: '$category exceeded its budget by ${AppFormatters.currency(overspend)}. Reducing spending by ${AppFormatters.currency(recoveryDailyReduce)}/day over the next $remainingDays days will return it to your target.',
              actionLabel: 'Rebalance Target',
              severity: IntentCardSeverity.info,
              icon: Icons.shield_outlined,
              accentColor: const Color(0xFF3B82F6),
              extraData: {'category': category, 'overspend': overspend},
            ),
          );
          conclusions.add('$category spent ${AppFormatters.currency(spent)} vs planned ${AppFormatters.currency(allocated)}.');
        } else if (ratio >= 0.8) {
          final remaining = allocated - spent;
          final dailyLimit = remainingDays > 0 ? (remaining / remainingDays) : remaining;
          decisionCards.add(
            IntentDecisionCardData(
              id: 'risk_$category',
              title: '$category Pacing',
              statement: 'You have ${AppFormatters.currency(remaining)} remaining for $category. Spending up to ${AppFormatters.currency(dailyLimit)}/day keeps you on track for the remaining $remainingDays days.',
              actionLabel: 'View Envelope',
              severity: IntentCardSeverity.info,
              icon: Icons.pie_chart_outline_rounded,
              accentColor: const Color(0xFF10B981),
              extraData: {'category': category},
            ),
          );
          conclusions.add('$category is ${((1.0 - ratio) * 100).toInt()}% under budget with $remainingDays days remaining.');
        }
      }
    }

    // 2. Evaluate Cashflow & Savings Conclusions
    final netCashFlow = totalIncome - totalExpense;
    if (totalIncome > 0) {
      final savingsRatePct = ((netCashFlow / totalIncome) * 100).clamp(0.0, 100.0);
      conclusions.add('Current savings rate is ${savingsRatePct.toStringAsFixed(1)}% of total income.');
      if (savingsRatePct >= 20.0) {
        decisionCards.add(
          IntentDecisionCardData(
            id: 'savings_positive',
            title: 'Strong Savings Pace',
            statement: 'You are retaining ${savingsRatePct.toStringAsFixed(0)}% of your income. Excellent financial health!',
            actionLabel: 'View Goal Progress',
            severity: IntentCardSeverity.positive,
            icon: Icons.savings_outlined,
            accentColor: const Color(0xFF10B981),
          ),
        );
      }
    }

    // 3. Fallback General Card if clean
    if (decisionCards.isEmpty) {
      decisionCards.add(
        IntentDecisionCardData(
          id: 'all_good',
          title: 'Finances On Track',
          statement: 'All budget envelopes are within safe limits. You can safely spend ${AppFormatters.currency(dailySafeSpend)} today.',
          actionLabel: 'Log Expense',
          severity: IntentCardSeverity.positive,
          icon: Icons.check_circle_outline_rounded,
          accentColor: const Color(0xFF10B981),
        ),
      );
    }

    if (conclusions.isEmpty) {
      conclusions.add('Spending velocity is steady across all categories.');
      conclusions.add('No budget anomalies or overspending detected today.');
    }

    return IntentDecisionState(
      dailySafeSpend: dailySafeSpend,
      remainingBudget: remainingBudget,
      remainingDays: remainingDays,
      dailySpendVerdict: dailySpendVerdict,
      decisionCards: decisionCards,
      plainLanguageConclusions: conclusions,
      envelopeDetails: envelopeDetails,
    );
  }
}
