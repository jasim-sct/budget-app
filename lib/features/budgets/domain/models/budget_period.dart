import 'package:flutter/material.dart';

enum BudgetPeriodType {
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case BudgetPeriodType.daily:
        return 'Daily';
      case BudgetPeriodType.weekly:
        return 'Weekly';
      case BudgetPeriodType.monthly:
        return 'Monthly';
      case BudgetPeriodType.yearly:
        return 'Yearly';
    }
  }

  String toDbString() => label;

  static BudgetPeriodType fromDbString(String? value) {
    if (value == null) return BudgetPeriodType.monthly;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'daily':
        return BudgetPeriodType.daily;
      case 'weekly':
        return BudgetPeriodType.weekly;
      case 'yearly':
      case 'annual':
        return BudgetPeriodType.yearly;
      case 'monthly':
      default:
        return BudgetPeriodType.monthly;
    }
  }

  /// Calculates start and end DateTime for the period containing [referenceDate].
  DateTimeRange calculatePeriodBounds(DateTime referenceDate) {
    final year = referenceDate.year;
    final month = referenceDate.month;
    final day = referenceDate.day;

    switch (this) {
      case BudgetPeriodType.daily:
        final start = DateTime(year, month, day, 0, 0, 0);
        final end = DateTime(year, month, day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BudgetPeriodType.weekly:
        final monday = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final sunday = start.add(const Duration(days: 6));
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BudgetPeriodType.monthly:
        final start = DateTime(year, month, 1, 0, 0, 0);
        final lastDay = DateTime(year, month + 1, 0).day;
        final end = DateTime(year, month, lastDay, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);

      case BudgetPeriodType.yearly:
        final start = DateTime(year, 1, 1, 0, 0, 0);
        final end = DateTime(year, 12, 31, 23, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
    }
  }

  /// Returns total days in the period.
  int getTotalDays(DateTime referenceDate) {
    final bounds = calculatePeriodBounds(referenceDate);
    return bounds.end.difference(bounds.start).inDays + 1;
  }

  /// Returns elapsed days up to [currentDate] within the period.
  int getElapsedDays(DateTime referenceDate, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final bounds = calculatePeriodBounds(referenceDate);

    if (now.isBefore(bounds.start)) return 0;
    if (now.isAfter(bounds.end)) return getTotalDays(referenceDate);

    final elapsed = now.difference(bounds.start).inDays + 1;
    return elapsed.clamp(1, getTotalDays(referenceDate));
  }

  /// Returns remaining days from [currentDate] to end of period.
  int getRemainingDays(DateTime referenceDate, [DateTime? currentDate]) {
    final total = getTotalDays(referenceDate);
    final elapsed = getElapsedDays(referenceDate, currentDate);
    final remaining = total - elapsed + 1;
    return remaining.clamp(1, total);
  }

  /// Generates a unique key for indexing and archiving historical periods.
  String getPeriodKey(DateTime referenceDate) {
    final year = referenceDate.year;
    final month = referenceDate.month.toString().padLeft(2, '0');
    final day = referenceDate.day.toString().padLeft(2, '0');

    switch (this) {
      case BudgetPeriodType.daily:
        return '$year-$month-$day';
      case BudgetPeriodType.weekly:
        final monday = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
        final mMonth = monday.month.toString().padLeft(2, '0');
        final mDay = monday.day.toString().padLeft(2, '0');
        return '$year-W${monday.year}-$mMonth-$mDay';
      case BudgetPeriodType.monthly:
        return '$year-$month';
      case BudgetPeriodType.yearly:
        return '$year';
    }
  }
}

enum CarryForwardRule {
  carryRemaining,
  carryOverspend,
  ignore,
  resetCompletely,
  manualRollover;

  String get label {
    switch (this) {
      case CarryForwardRule.carryRemaining:
        return 'Carry Forward Remaining Balance';
      case CarryForwardRule.carryOverspend:
        return 'Deduct Overspend from Next Cycle';
      case CarryForwardRule.ignore:
        return 'Ignore Unused Balance';
      case CarryForwardRule.resetCompletely:
        return 'Reset Allocation Completely';
      case CarryForwardRule.manualRollover:
        return 'Manual Rollover Confirmation';
    }
  }

  String toDbString() {
    switch (this) {
      case CarryForwardRule.carryRemaining:
        return 'carry_remaining';
      case CarryForwardRule.carryOverspend:
        return 'carry_overspend';
      case CarryForwardRule.ignore:
        return 'ignore';
      case CarryForwardRule.resetCompletely:
        return 'reset';
      case CarryForwardRule.manualRollover:
        return 'manual';
    }
  }

  static CarryForwardRule fromDbString(String? value) {
    if (value == null) return CarryForwardRule.carryRemaining;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'carry_remaining':
      case '1':
        return CarryForwardRule.carryRemaining;
      case 'carry_overspend':
        return CarryForwardRule.carryOverspend;
      case 'ignore':
        return CarryForwardRule.ignore;
      case 'reset':
        return CarryForwardRule.resetCompletely;
      case 'manual':
        return CarryForwardRule.manualRollover;
      default:
        return CarryForwardRule.carryRemaining;
    }
  }
}
