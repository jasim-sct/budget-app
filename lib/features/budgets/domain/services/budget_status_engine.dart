import 'dart:math';
import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/budget_period.dart';

enum BudgetStatusClassification {
  underBudget,
  onTrack,
  nearLimit,
  overBudget,
  criticalOverspend;

  String get label {
    switch (this) {
      case BudgetStatusClassification.underBudget:
        return 'Under Budget';
      case BudgetStatusClassification.onTrack:
        return 'On Track';
      case BudgetStatusClassification.nearLimit:
        return 'Near Limit';
      case BudgetStatusClassification.overBudget:
        return 'Over Budget';
      case BudgetStatusClassification.criticalOverspend:
        return 'Critical Overspend';
    }
  }

  Color get primaryColor {
    switch (this) {
      case BudgetStatusClassification.underBudget:
        return const Color(0xFF10B981); // Emerald Green
      case BudgetStatusClassification.onTrack:
        return const Color(0xFF06B6D4); // Cyan/Teal
      case BudgetStatusClassification.nearLimit:
        return const Color(0xFFA855F7); // Purple/Indigo
      case BudgetStatusClassification.overBudget:
        return const Color(0xFFF59E0B); // Amber/Orange
      case BudgetStatusClassification.criticalOverspend:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }

  Color get badgeBackgroundColor {
    return primaryColor.withValues(alpha: 0.15);
  }
}

class BudgetStatusMetrics {
  final BudgetModel budget;
  final double baseLimit;
  final double allocation; // baseLimit + carryForward
  final double spent;
  final double remaining;
  final double availableBalance;
  final double remainingPercentage;
  final double progressPercentage;
  final double budgetHealthScore; // 0 - 100
  final double dailyTarget;
  final double actualDailySpend;
  final double currentBurnRate;
  final double estimatedEndOfPeriodSpending;
  final double pacingRatio;
  final double variance;
  final int remainingDays;
  final int elapsedDays;
  final int totalPeriodDays;
  final double expectedOverspend;
  final double carryForwardAmount;
  final double transferredAmount;
  final double recoveredAmount;
  final int transactionCount;
  final double categoryContributionPercentage;
  final double spendingTrendPercentage;
  final DateTime lastUpdated;
  final BudgetPeriodType periodType;
  final BudgetStatusClassification status;

  const BudgetStatusMetrics({
    required this.budget,
    required this.baseLimit,
    required this.allocation,
    required this.spent,
    required this.remaining,
    required this.availableBalance,
    required this.remainingPercentage,
    required this.progressPercentage,
    required this.budgetHealthScore,
    required this.dailyTarget,
    required this.actualDailySpend,
    required this.currentBurnRate,
    required this.estimatedEndOfPeriodSpending,
    required this.pacingRatio,
    required this.variance,
    required this.remainingDays,
    required this.elapsedDays,
    required this.totalPeriodDays,
    required this.expectedOverspend,
    required this.carryForwardAmount,
    required this.transferredAmount,
    required this.recoveredAmount,
    required this.transactionCount,
    required this.categoryContributionPercentage,
    required this.spendingTrendPercentage,
    required this.lastUpdated,
    required this.periodType,
    required this.status,
  });

  bool get isExceeded => spent > allocation;
  bool get canTransferRemaining => remaining > 0 && availableBalance > 0;
  bool get needsRecovery => spent > allocation;
}

class BudgetStatusEngine {
  /// Deterministically computes complete [BudgetStatusMetrics] for a budget item.
  static BudgetStatusMetrics calculate({
    required BudgetModel budget,
    required double spent,
    required DateTime referenceDate,
    double totalAllExpensesInPeriod = 0.0,
    int transactionCount = 0,
    double previousPeriodSpent = 0.0,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final periodType = budget.periodType;

    final totalDays = periodType.getTotalDays(referenceDate);
    final elapsedDays = periodType.getElapsedDays(referenceDate, now);
    final remainingDays = periodType.getRemainingDays(referenceDate, now);

    final baseLimit = budget.amountLimit;
    final carryForward = budget.carryForwardAmount;
    final transferred = budget.transferredAmount;
    final recovered = budget.recoveredAmount;

    // Effective budget allocation considering carry-forward
    final allocation = max(0.0, baseLimit + carryForward);

    // Remaining balance
    final remaining = allocation - spent;

    // Available balance factoring transfers & recoveries
    final availableBalance = max(0.0, allocation - spent - transferred + recovered);

    // Percentages
    final progressPercentage = allocation > 0 ? (spent / allocation * 100.0) : (spent > 0 ? 100.0 : 0.0);
    final remainingPercentage = allocation > 0 ? ((remaining / allocation) * 100.0).clamp(-100.0, 100.0) : 0.0;

    // Daily calculations — fixed plan = allocation ÷ period days (does not shrink with spend).
    final actualDailySpend = elapsedDays > 0 ? spent / elapsedDays : 0.0;
    final currentBurnRate = actualDailySpend;
    final idealDailyRate = allocation > 0 ? allocation / totalDays : 0.0;
    final dailyTarget = idealDailyRate;

    // Projections
    final estimatedEndOfPeriodSpending = actualDailySpend * totalDays;
    final expectedOverspend = max(0.0, estimatedEndOfPeriodSpending - allocation);

    // Pacing Ratio: ratio of actual burn rate to ideal burn rate
    final pacingRatio = idealDailyRate > 0 ? (actualDailySpend / idealDailyRate) : (spent > 0 ? 2.0 : 0.0);

    // Variance: spent vs expected benchmark spent up to elapsed days
    final expectedSpentToDate = idealDailyRate * elapsedDays;
    final variance = spent - expectedSpentToDate;

    // Category Contribution %
    final categoryContributionPercentage = totalAllExpensesInPeriod > 0
        ? ((spent / totalAllExpensesInPeriod) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    // Spending Trend % vs Previous Period
    final spendingTrendPercentage = previousPeriodSpent > 0
        ? (((spent - previousPeriodSpent) / previousPeriodSpent) * 100.0)
        : 0.0;

    // Status Classification
    final status = _determineStatus(
      spent: spent,
      allocation: allocation,
      progressPercentage: progressPercentage,
      pacingRatio: pacingRatio,
      alertThreshold: budget.alertThreshold,
    );

    // Budget Health Score (0 - 100)
    final healthScore = _calculateHealthScore(
      progressPercentage: progressPercentage,
      pacingRatio: pacingRatio,
      remainingDays: remainingDays,
      totalDays: totalDays,
    );

    return BudgetStatusMetrics(
      budget: budget,
      baseLimit: baseLimit,
      allocation: allocation,
      spent: spent,
      remaining: remaining,
      availableBalance: availableBalance,
      remainingPercentage: remainingPercentage,
      progressPercentage: progressPercentage,
      budgetHealthScore: healthScore,
      dailyTarget: dailyTarget,
      actualDailySpend: actualDailySpend,
      currentBurnRate: currentBurnRate,
      estimatedEndOfPeriodSpending: estimatedEndOfPeriodSpending,
      pacingRatio: pacingRatio,
      variance: variance,
      remainingDays: remainingDays,
      elapsedDays: elapsedDays,
      totalPeriodDays: totalDays,
      expectedOverspend: expectedOverspend,
      carryForwardAmount: carryForward,
      transferredAmount: transferred,
      recoveredAmount: recovered,
      transactionCount: transactionCount,
      categoryContributionPercentage: categoryContributionPercentage,
      spendingTrendPercentage: spendingTrendPercentage,
      lastUpdated: now,
      periodType: periodType,
      status: status,
    );
  }

  static BudgetStatusClassification _determineStatus({
    required double spent,
    required double allocation,
    required double progressPercentage,
    required double pacingRatio,
    required double alertThreshold,
  }) {
    if (allocation <= 0) {
      return spent > 0 ? BudgetStatusClassification.criticalOverspend : BudgetStatusClassification.onTrack;
    }

    if (progressPercentage > 120.0) {
      return BudgetStatusClassification.criticalOverspend;
    } else if (progressPercentage > 100.0) {
      return BudgetStatusClassification.overBudget;
    } else if (progressPercentage >= (alertThreshold * 100.0)) {
      return BudgetStatusClassification.nearLimit;
    } else if (progressPercentage <= 60.0 && pacingRatio <= 1.0) {
      return BudgetStatusClassification.underBudget;
    } else {
      return BudgetStatusClassification.onTrack;
    }
  }

  static double _calculateHealthScore({
    required double progressPercentage,
    required double pacingRatio,
    required int remainingDays,
    required int totalDays,
  }) {
    double score = 100.0;

    // Deduct for overspend
    if (progressPercentage > 100.0) {
      final overPercentage = progressPercentage - 100.0;
      score -= (overPercentage * 2.5);
    } else {
      // Deduct for pacing mismatch if spending faster than time elapsed
      if (pacingRatio > 1.1) {
        score -= ((pacingRatio - 1.0) * 30.0);
      }
    }

    return score.clamp(0.0, 100.0);
  }
}
