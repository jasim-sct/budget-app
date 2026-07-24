import 'package:flutter/material.dart';
import '../../features/budgets/domain/models/budget_model.dart';
import '../database/app_database.dart';
import '../utils/formatters.dart';
import '../widgets/calculation_explanation_modal.dart';
import 'budget_category_matcher.dart';
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
  /// Single home metric: today's fixed plan minus today's actual spend.
  /// Positive = still available today; negative = exceeded today.
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
  /// Fixed daily allocation from budget amount ÷ period length.
  /// Does not change when the user spends (only when the budget is edited).
  static double fixedDailyAllocation(BudgetModel budget, DateTime referenceDate) {
    final days = budget.periodType.getTotalDays(referenceDate).clamp(1, 366);
    return budget.amountLimit / days;
  }

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

    final db = await AppDatabase.instance.database;
    final budgetMaps = await db.query('budgets', where: 'is_active = 1');
    final budgets = budgetMaps.map(BudgetModel.fromMap).toList();

    final categoryRows = await db.query('categories');
    final categoryIdToName = <String, String>{
      for (final row in categoryRows)
        if (row['id'] != null && row['name'] != null)
          row['id'] as String: row['name'] as String,
    };

    final dayStart = DateTime(year, month, day).millisecondsSinceEpoch;
    final dayEnd = DateTime(year, month, day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final todaySpendRows = await db.rawQuery('''
      SELECT category, sub_category, SUM(amount) AS total_spent
      FROM transactions
      WHERE type = 0 AND date >= ? AND date <= ?
      GROUP BY category, sub_category
    ''', [dayStart, dayEnd]);

    final Map<String, double> todaySpendByCategory = {};
    for (final row in todaySpendRows) {
      final cat = (row['category'] as String? ?? '').trim().toLowerCase();
      final subCat = (row['sub_category'] as String? ?? '').trim().toLowerCase();
      final spent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      if (cat.isNotEmpty) {
        todaySpendByCategory[cat] = (todaySpendByCategory[cat] ?? 0.0) + spent;
      }
      if (subCat.isNotEmpty) {
        todaySpendByCategory[subCat] = (todaySpendByCategory[subCat] ?? 0.0) + spent;
      }
    }

    final envelopeDetails = <EnvelopeCalculationDetail>[];
    double todayPlannedTotal = 0.0;
    double todayBudgetedSpend = 0.0;
    double totalRemainingBudget = 0.0;

    // Period spend maps keyed by budget id (bounds may differ per budget period type).
    final periodSpendCache = <String, Map<String, double>>{};

    for (final budget in budgets) {
      final fixedDaily = fixedDailyAllocation(budget, now);
      todayPlannedTotal += fixedDaily;

      final keys = budgetCategoryMatchKeys(
        budget,
        categoryIdToName: categoryIdToName,
      );
      final todayCategorySpend = spentForBudgetKeys(todaySpendByCategory, keys);
      todayBudgetedSpend += todayCategorySpend;

      final periodBounds = budget.periodType.calculatePeriodBounds(now);
      final cacheKey =
          '${periodBounds.start.millisecondsSinceEpoch}_${periodBounds.end.millisecondsSinceEpoch}';
      var periodSpendMap = periodSpendCache[cacheKey];
      if (periodSpendMap == null) {
        final periodSpendRows = await db.rawQuery('''
          SELECT category, sub_category, SUM(amount) AS total_spent
          FROM transactions
          WHERE type = 0
            AND date >= ? AND date <= ?
          GROUP BY category, sub_category
        ''', [
          periodBounds.start.millisecondsSinceEpoch,
          periodBounds.end.millisecondsSinceEpoch,
        ]);
        periodSpendMap = <String, double>{};
        for (final row in periodSpendRows) {
          final cat = (row['category'] as String? ?? '').trim().toLowerCase();
          final subCat = (row['sub_category'] as String? ?? '').trim().toLowerCase();
          final spent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
          if (cat.isNotEmpty) periodSpendMap[cat] = (periodSpendMap[cat] ?? 0.0) + spent;
          if (subCat.isNotEmpty) periodSpendMap[subCat] = (periodSpendMap[subCat] ?? 0.0) + spent;
        }
        periodSpendCache[cacheKey] = periodSpendMap;
      }

      final periodSpent = spentForBudgetKeys(periodSpendMap, keys);
      final periodRemaining = (budget.amountLimit - periodSpent).clamp(0.0, double.infinity);
      totalRemainingBudget += periodRemaining;

      final periodDays = budget.periodType.getTotalDays(now).clamp(1, 366);

      envelopeDetails.add(
        EnvelopeCalculationDetail(
          category: budget.name,
          allocated: budget.amountLimit,
          spent: todayCategorySpend,
          remaining: fixedDaily - todayCategorySpend,
          daysRemaining: periodDays,
          dailyLimit: fixedDaily,
        ),
      );
    }

    // One amount for Home: planned today − budgeted category spend today (negative when exceeded).
    final dailySafeSpend = todayPlannedTotal - todayBudgetedSpend;
    final remainingBudget = totalRemainingBudget;

    String dailySpendVerdict;
    if (budgets.isEmpty) {
      dailySpendVerdict =
          'No active budget envelopes configured. Create a budget to calculate your daily limit.';
    } else if (dailySafeSpend < 0) {
      dailySpendVerdict =
          'Exceeded today\'s plan by ${AppFormatters.currency(-dailySafeSpend)}.';
    } else if (dailySafeSpend == 0) {
      dailySpendVerdict = 'Today\'s planned allocation is fully used.';
    } else {
      dailySpendVerdict =
          'You can safely spend ${AppFormatters.currency(dailySafeSpend)} today.';
    }

    final decisionCards = <IntentDecisionCardData>[];
    final conclusions = <String>[];

    for (final detail in envelopeDetails) {
      if (detail.dailyLimit <= 0) continue;
      if (detail.spent > detail.dailyLimit) {
        final over = detail.spent - detail.dailyLimit;
        decisionCards.add(
          IntentDecisionCardData(
            id: 'over_today_${detail.category}',
            title: '${detail.category} Over Today\'s Plan',
            statement:
                '${detail.category} exceeded today\'s fixed allocation by ${AppFormatters.currency(over)}. Tomorrow\'s plan stays ${AppFormatters.currency(detail.dailyLimit)}.',
            actionLabel: 'View Envelope',
            severity: IntentCardSeverity.warning,
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFF59E0B),
            extraData: {'category': detail.category, 'overspend': over},
          ),
        );
        conclusions.add(
          '${detail.category}: planned ${AppFormatters.currency(detail.dailyLimit)}, spent ${AppFormatters.currency(detail.spent)}.',
        );
      }
    }

    final netCashFlow = totalIncome - totalExpense;
    if (totalIncome > 0) {
      final savingsRatePct = ((netCashFlow / totalIncome) * 100).clamp(0.0, 100.0);
      conclusions.add('Current savings rate is ${savingsRatePct.toStringAsFixed(1)}% of total income.');
      if (savingsRatePct >= 20.0) {
        decisionCards.add(
          IntentDecisionCardData(
            id: 'savings_positive',
            title: 'Strong Savings Pace',
            statement:
                'You are retaining ${savingsRatePct.toStringAsFixed(0)}% of your income. Excellent financial health!',
            actionLabel: 'View Goal Progress',
            severity: IntentCardSeverity.positive,
            icon: Icons.savings_outlined,
            accentColor: const Color(0xFF10B981),
          ),
        );
      }
    }

    if (decisionCards.isEmpty) {
      decisionCards.add(
        IntentDecisionCardData(
          id: 'all_good',
          title: dailySafeSpend < 0 ? 'Over Today\'s Plan' : 'On Today\'s Plan',
          statement: dailySpendVerdict,
          actionLabel: 'Log Expense',
          severity: dailySafeSpend < 0 ? IntentCardSeverity.warning : IntentCardSeverity.positive,
          icon: dailySafeSpend < 0 ? Icons.trending_down_rounded : Icons.check_circle_outline_rounded,
          accentColor: dailySafeSpend < 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ),
      );
    }

    if (conclusions.isEmpty) {
      conclusions.add('Daily targets are fixed at budget creation and do not recalculate after spending.');
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
