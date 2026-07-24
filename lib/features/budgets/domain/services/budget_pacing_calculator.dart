import '../models/budget_pacing_model.dart';

/// Pure domain service calculating dynamic budget pacing metrics.
class BudgetPacingCalculator {
  BudgetPacingCalculator._();

  /// Calculates dynamic budget pacing for a monthly budget configuration.
  static BudgetPacingModel calculate({
    required double monthlyBudget,
    required double totalSpent,
    required int year,
    required int month,
    double todaySpent = 0.0,
    DateTime? todayDate,
  }) {
    final now = todayDate ?? DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;

    int currentDay;
    if (year < now.year || (year == now.year && month < now.month)) {
      // Past month: completed
      currentDay = daysInMonth;
    } else if (year > now.year || (year == now.year && month > now.month)) {
      // Future month: not started yet
      currentDay = 1;
    } else {
      // Current active month
      currentDay = now.day.clamp(1, daysInMonth);
    }

    final remainingDays = (daysInMonth - currentDay + 1).clamp(1, daysInMonth);
    final dailyBudgetTarget = monthlyBudget > 0 ? (monthlyBudget / daysInMonth) : 0.0;
    final expectedSpentToDate = dailyBudgetTarget * currentDay;
    final remainingBudget = monthlyBudget - totalSpent;

    final double requiredDailySpending;
    if (remainingBudget <= 0) {
      requiredDailySpending = 0.0;
    } else {
      requiredDailySpending = remainingBudget / remainingDays;
    }

    final varianceAmount = totalSpent - expectedSpentToDate;
    final pacingPercentage = expectedSpentToDate > 0 ? (totalSpent / expectedSpentToDate) * 100 : 0.0;
    final projectedMonthEndSpent = currentDay > 0 ? (totalSpent / currentDay) * daysInMonth : totalSpent;

    PacingStatus status;
    if (monthlyBudget <= 0) {
      status = PacingStatus.onTrack;
    } else if (totalSpent >= monthlyBudget || remainingBudget <= 0) {
      status = PacingStatus.critical;
    } else if (expectedSpentToDate > 0 && totalSpent > 1.30 * expectedSpentToDate) {
      status = PacingStatus.critical;
    } else if (expectedSpentToDate > 0 && totalSpent > 1.10 * expectedSpentToDate) {
      status = PacingStatus.highUsage;
    } else if (expectedSpentToDate > 0 && totalSpent < 0.85 * expectedSpentToDate) {
      status = PacingStatus.lowUsage;
    } else {
      status = PacingStatus.onTrack;
    }

    return BudgetPacingModel(
      monthlyBudget: monthlyBudget,
      totalSpent: totalSpent,
      remainingBudget: remainingBudget,
      daysInMonth: daysInMonth,
      currentDay: currentDay,
      remainingDays: remainingDays,
      expectedSpentToDate: expectedSpentToDate,
      dailyBudgetTarget: dailyBudgetTarget,
      requiredDailySpending: requiredDailySpending,
      pacingStatus: status,
      pacingPercentage: pacingPercentage,
      varianceAmount: varianceAmount,
      projectedMonthEndSpent: projectedMonthEndSpent,
      todaySpent: todaySpent,
    );
  }
}
