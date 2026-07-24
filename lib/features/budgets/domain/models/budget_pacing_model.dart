import 'package:flutter/foundation.dart';

enum PacingStatus {
  lowUsage,
  onTrack,
  highUsage,
  critical,
}

extension PacingStatusX on PacingStatus {
  String get label {
    switch (this) {
      case PacingStatus.lowUsage:
        return 'Low Usage';
      case PacingStatus.onTrack:
        return 'On Track';
      case PacingStatus.highUsage:
        return 'High Usage';
      case PacingStatus.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case PacingStatus.lowUsage:
        return 'Spending is below expected pace. Excellent savings headroom!';
      case PacingStatus.onTrack:
        return 'Spending aligns closely with expected daily budget targets.';
      case PacingStatus.highUsage:
        return 'Spending exceeds expected pace. Minor adjustments recommended.';
      case PacingStatus.critical:
        return 'Spending is significantly ahead of budget. Risk of overspending.';
    }
  }
}

@immutable
class BudgetPacingModel {
  final double monthlyBudget;
  final double totalSpent;
  final double remainingBudget;
  final int daysInMonth;
  final int currentDay;
  final int remainingDays;
  final double expectedSpentToDate;
  final double dailyBudgetTarget;
  final double requiredDailySpending;
  final PacingStatus pacingStatus;
  final double pacingPercentage;
  final double varianceAmount;
  final double projectedMonthEndSpent;
  final double todaySpent;

  const BudgetPacingModel({
    required this.monthlyBudget,
    required this.totalSpent,
    required this.remainingBudget,
    required this.daysInMonth,
    required this.currentDay,
    required this.remainingDays,
    required this.expectedSpentToDate,
    required this.dailyBudgetTarget,
    required this.requiredDailySpending,
    required this.pacingStatus,
    required this.pacingPercentage,
    required this.varianceAmount,
    required this.projectedMonthEndSpent,
    this.todaySpent = 0.0,
  });

  bool get isOverBudget => totalSpent > monthlyBudget;
  double get progressRatio => monthlyBudget > 0 ? (totalSpent / monthlyBudget).clamp(0.0, 1.0) : 0.0;
  double get expectedProgressRatio => monthlyBudget > 0 ? (expectedSpentToDate / monthlyBudget).clamp(0.0, 1.0) : 0.0;

  double get todayRemainingAllowance => (requiredDailySpending - todaySpent).clamp(0.0, monthlyBudget);
  double get todayAllowanceProgressRatio => requiredDailySpending > 0 ? (todaySpent / requiredDailySpending).clamp(0.0, 1.0) : 0.0;

  double get averageDailyBurn => currentDay > 0 ? totalSpent / currentDay : 0.0;
  double get runwayDaysRemaining => averageDailyBurn > 0 ? (remainingBudget / averageDailyBurn).clamp(0.0, remainingDays.toDouble()) : remainingDays.toDouble();
}
