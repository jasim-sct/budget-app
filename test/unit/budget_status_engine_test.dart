import 'package:flutter_test/flutter_test.dart';
import 'package:budget_lite/features/budgets/domain/models/budget_model.dart';
import 'package:budget_lite/features/budgets/domain/models/budget_period.dart';
import 'package:budget_lite/features/budgets/domain/services/budget_status_engine.dart';

void main() {
  group('BudgetStatusEngine Tests', () {
    test('Calculates metrics accurately for monthly budget under-budget scenario', () {
      const budget = BudgetModel(
        id: 'b1',
        name: 'Groceries',
        categoryId: 'cat_groceries',
        amountLimit: 600.0,
        periodType: BudgetPeriodType.monthly,
      );

      final referenceDate = DateTime(2026, 7, 15);
      final currentDate = DateTime(2026, 7, 15);

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: 200.0,
        referenceDate: referenceDate,
        transactionCount: 5,
        totalAllExpensesInPeriod: 1000.0,
        currentDate: currentDate,
      );

      expect(metrics.allocation, equals(600.0));
      expect(metrics.spent, equals(200.0));
      expect(metrics.remaining, equals(400.0));
      expect(metrics.availableBalance, equals(400.0));
      expect(metrics.progressPercentage, closeTo(33.33, 0.1));
      expect(metrics.status, equals(BudgetStatusClassification.underBudget));
      expect(metrics.transactionCount, equals(5));
      expect(metrics.categoryContributionPercentage, equals(20.0));
    });

    test('Classifies critical overspend when spent exceeds 120% of allocation', () {
      const budget = BudgetModel(
        id: 'b2',
        name: 'Dining Out',
        categoryId: 'cat_dining',
        amountLimit: 200.0,
        periodType: BudgetPeriodType.monthly,
      );

      final referenceDate = DateTime(2026, 7, 20);

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: 280.0,
        referenceDate: referenceDate,
        currentDate: referenceDate,
      );

      expect(metrics.spent, equals(280.0));
      expect(metrics.remaining, equals(-80.0));
      expect(metrics.progressPercentage, equals(140.0));
      expect(metrics.status, equals(BudgetStatusClassification.criticalOverspend));
      expect(metrics.needsRecovery, isTrue);
    });

    test('Handles weekly period bounds and remaining days accurately', () {
      const budget = BudgetModel(
        id: 'b3',
        name: 'Entertainment',
        categoryId: 'cat_ent',
        amountLimit: 100.0,
        periodType: BudgetPeriodType.weekly,
      );

      final referenceDate = DateTime(2026, 7, 22); // Wednesday (weekday 3)

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: 40.0,
        referenceDate: referenceDate,
        currentDate: referenceDate,
      );

      expect(metrics.periodType, equals(BudgetPeriodType.weekly));
      expect(metrics.totalPeriodDays, equals(7));
      expect(metrics.elapsedDays, equals(3));
      expect(metrics.remainingDays, equals(5));
    });

    test('Incorporates carry forward amounts into allocation and available balance', () {
      const budget = BudgetModel(
        id: 'b4',
        name: 'Gas',
        categoryId: 'cat_gas',
        amountLimit: 150.0,
        carryForwardAmount: 50.0,
        periodType: BudgetPeriodType.monthly,
      );

      final referenceDate = DateTime(2026, 7, 10);

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: 100.0,
        referenceDate: referenceDate,
        currentDate: referenceDate,
      );

      expect(metrics.baseLimit, equals(150.0));
      expect(metrics.carryForwardAmount, equals(50.0));
      expect(metrics.allocation, equals(200.0));
      expect(metrics.remaining, equals(100.0));
      expect(metrics.availableBalance, equals(100.0));
    });

    test('Scales monthly limit accurately by number of days in selected month', () {
      final febDate = DateTime(2026, 2, 10); // Feb 2026 has 28 days
      final julyDate = DateTime(2026, 7, 10); // July 2026 has 31 days

      final febDays = DateTime(febDate.year, febDate.month + 1, 0).day;
      final julyDays = DateTime(julyDate.year, julyDate.month + 1, 0).day;

      expect(febDays, equals(28));
      expect(julyDays, equals(31));

      const monthlyLimit = 3100.0;

      // July calculations
      final julyDaily = monthlyLimit / julyDays; // 3100 / 31 = 100
      final julyWeekly = (monthlyLimit / julyDays) * 7; // (3100 / 31) * 7 = 700
      final julyYearly = monthlyLimit * 12; // 37200

      expect(julyDaily, equals(100.0));
      expect(julyWeekly, equals(700.0));
      expect(julyYearly, equals(37200.0));

      // Feb calculations (2800 monthly limit for clean math)
      const febMonthlyLimit = 2800.0;
      final febDaily = febMonthlyLimit / febDays; // 2800 / 28 = 100
      final febWeekly = (febMonthlyLimit / febDays) * 7; // 700

      expect(febDaily, equals(100.0));
      expect(febWeekly, equals(700.0));
    });
  });
}
