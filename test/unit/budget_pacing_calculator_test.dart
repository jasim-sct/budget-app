import 'package:flutter_test/flutter_test.dart';
import 'package:budget_lite/features/budgets/domain/models/budget_pacing_model.dart';
import 'package:budget_lite/features/budgets/domain/services/budget_pacing_calculator.dart';

void main() {
  group('BudgetPacingCalculator Tests', () {
    test('Calculates base daily targets and remaining days accurately for July (31 days)', () {
      final today = DateTime(2026, 7, 15);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 3100.0,
        totalSpent: 1500.0,
        year: 2026,
        month: 7,
        todayDate: today,
      );

      expect(pacing.daysInMonth, equals(31));
      expect(pacing.currentDay, equals(15));
      expect(pacing.remainingDays, equals(17)); // 31 - 15 + 1 = 17
      expect(pacing.dailyBudgetTarget, equals(100.0));
      expect(pacing.expectedSpentToDate, equals(1500.0));
      expect(pacing.remainingBudget, equals(1600.0));
      expect(pacing.requiredDailySpending, closeTo(1600.0 / 17, 0.01));
      expect(pacing.pacingStatus, equals(PacingStatus.onTrack));
    });

    test('Identifies Low Usage status when spending is significantly below pace', () {
      final today = DateTime(2026, 7, 15);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 3100.0,
        totalSpent: 1000.0, // Expected was 1500
        year: 2026,
        month: 7,
        todayDate: today,
      );

      expect(pacing.pacingStatus, equals(PacingStatus.lowUsage));
    });

    test('Identifies High Usage status when spending exceeds pace slightly', () {
      final today = DateTime(2026, 7, 15);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 3100.0,
        totalSpent: 1800.0, // Expected was 1500, >1.10*1500 (1650)
        year: 2026,
        month: 7,
        todayDate: today,
      );

      expect(pacing.pacingStatus, equals(PacingStatus.highUsage));
    });

    test('Identifies Critical status when spending severely exceeds pace or budget', () {
      final today = DateTime(2026, 7, 15);
      final pacingCriticalOverPace = BudgetPacingCalculator.calculate(
        monthlyBudget: 3100.0,
        totalSpent: 2100.0, // > 1.30 * 1500 (1950)
        year: 2026,
        month: 7,
        todayDate: today,
      );

      expect(pacingCriticalOverPace.pacingStatus, equals(PacingStatus.critical));

      final pacingExceeded = BudgetPacingCalculator.calculate(
        monthlyBudget: 3100.0,
        totalSpent: 3200.0,
        year: 2026,
        month: 7,
        todayDate: today,
      );

      expect(pacingExceeded.pacingStatus, equals(PacingStatus.critical));
      expect(pacingExceeded.isOverBudget, isTrue);
      expect(pacingExceeded.requiredDailySpending, equals(0.0));
    });

    test('Handles past completed month correctly', () {
      final today = DateTime(2026, 8, 10);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 3000.0,
        totalSpent: 2800.0,
        year: 2026,
        month: 7, // July in past
        todayDate: today,
      );

      expect(pacing.currentDay, equals(31));
      expect(pacing.remainingDays, equals(1));
      expect(pacing.expectedSpentToDate, equals(3000.0));
      expect(pacing.pacingStatus, equals(PacingStatus.onTrack));
    });

    test('Handles future month correctly', () {
      final today = DateTime(2026, 7, 15);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 3000.0,
        totalSpent: 0.0,
        year: 2026,
        month: 9, // September in future
        todayDate: today,
      );

      expect(pacing.currentDay, equals(1));
      expect(pacing.daysInMonth, equals(30));
      expect(pacing.totalSpent, equals(0.0));
    });

    test('Handles leap year February correctly', () {
      final today = DateTime(2028, 2, 14);
      final pacing = BudgetPacingCalculator.calculate(
        monthlyBudget: 2900.0,
        totalSpent: 1400.0,
        year: 2028,
        month: 2,
        todayDate: today,
      );

      expect(pacing.daysInMonth, equals(29));
      expect(pacing.dailyBudgetTarget, equals(100.0));
      expect(pacing.expectedSpentToDate, equals(1400.0));
      expect(pacing.pacingStatus, equals(PacingStatus.onTrack));
    });
  });
}
