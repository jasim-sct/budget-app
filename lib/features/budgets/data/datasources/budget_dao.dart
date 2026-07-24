import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/state/month_selector_controller.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_pacing_model.dart';
import '../../domain/models/budget_period.dart';
import '../../domain/services/budget_pacing_calculator.dart';
import '../../domain/services/budget_status_engine.dart';

class BudgetSpentSummary {
  final BudgetModel budget;
  final double spent;
  final BudgetStatusMetrics metrics;

  const BudgetSpentSummary({
    required this.budget,
    required this.spent,
    required this.metrics,
  });

  double get remaining => metrics.remaining;
  double get progressRatio => (metrics.progressPercentage / 100.0).clamp(0.0, 1.0);
  bool get isExceeded => metrics.isExceeded;
  bool get isNearAlert => metrics.status == BudgetStatusClassification.nearLimit;

  BudgetPacingModel getPacing({int? year, int? month}) {
    final activeDate = MonthSelectorController.instance.value;
    return BudgetPacingCalculator.calculate(
      monthlyBudget: budget.amountLimit,
      totalSpent: spent,
      year: year ?? activeDate.year,
      month: month ?? activeDate.month,
    );
  }
}

class BudgetDao {
  final AppDatabase _dbHelper;

  BudgetDao(this._dbHelper);

  /// Retrieves all budgets and computes deterministic [BudgetStatusMetrics] for the given [periodType] and [referenceDate].
  Future<List<BudgetSpentSummary>> getBudgetsForPeriod({
    required BudgetPeriodType periodType,
    required DateTime referenceDate,
  }) async {
    final db = await _dbHelper.database;
    final budgetMaps = await db.query(
      DbConstants.tableBudgets,
      where: 'is_active = 1',
    );

    if (budgetMaps.isEmpty) return [];

    final activeBudgets = budgetMaps.map((m) {
      final b = BudgetModel.fromMap(m);
      final scaled = _scaleAmountLimit(
        b.amountLimit,
        from: b.periodType,
        to: periodType,
        referenceDate: referenceDate,
      );
      return b.copyWith(amountLimit: scaled, periodType: periodType);
    }).toList();

    final bounds = periodType.calculatePeriodBounds(referenceDate);
    final startMs = bounds.start.millisecondsSinceEpoch;
    final endMs = bounds.end.millisecondsSinceEpoch;

    // 1. Category Spending aggregation for period
    final spendingRows = await db.rawQuery('''
      SELECT category, sub_category, SUM(amount) AS total_spent, COUNT(id) AS tx_count
      FROM ${DbConstants.tableTransactions}
      WHERE type = 0 AND date >= ? AND date <= ?
      GROUP BY category, sub_category
    ''', [startMs, endMs]);

    final Map<String, double> spendingMap = {};
    final Map<String, int> countMap = {};
    double totalAllExpensesInPeriod = 0.0;

    for (final row in spendingRows) {
      final cat = (row['category'] as String? ?? '').toLowerCase();
      final subCat = (row['sub_category'] as String? ?? '').toLowerCase();
      final spent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      final count = (row['tx_count'] as num?)?.toInt() ?? 0;

      totalAllExpensesInPeriod += spent;

      if (cat.isNotEmpty) {
        spendingMap[cat] = (spendingMap[cat] ?? 0.0) + spent;
        countMap[cat] = (countMap[cat] ?? 0) + count;
      }
      if (subCat.isNotEmpty) {
        spendingMap[subCat] = (spendingMap[subCat] ?? 0.0) + spent;
        countMap[subCat] = (countMap[subCat] ?? 0) + count;
      }
    }

    // 2. Previous Period Spending for trend calculations
    final prevDate = _getPreviousPeriodReferenceDate(periodType, referenceDate);
    final prevBounds = periodType.calculatePeriodBounds(prevDate);
    final prevStartMs = prevBounds.start.millisecondsSinceEpoch;
    final prevEndMs = prevBounds.end.millisecondsSinceEpoch;

    final prevSpendingRows = await db.rawQuery('''
      SELECT category, sub_category, SUM(amount) AS total_spent
      FROM ${DbConstants.tableTransactions}
      WHERE type = 0 AND date >= ? AND date <= ?
      GROUP BY category, sub_category
    ''', [prevStartMs, prevEndMs]);

    final Map<String, double> prevSpendingMap = {};
    for (final row in prevSpendingRows) {
      final cat = (row['category'] as String? ?? '').toLowerCase();
      final subCat = (row['sub_category'] as String? ?? '').toLowerCase();
      final spent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      if (cat.isNotEmpty) prevSpendingMap[cat] = (prevSpendingMap[cat] ?? 0.0) + spent;
      if (subCat.isNotEmpty) prevSpendingMap[subCat] = (prevSpendingMap[subCat] ?? 0.0) + spent;
    }

    // 3. Compute BudgetStatusMetrics for each budget
    final List<BudgetSpentSummary> summaries = [];
    for (final budget in activeBudgets) {
      final keyName = budget.name.toLowerCase();
      final keyId = budget.categoryId.toLowerCase();

      final spent = spendingMap[keyName] ?? spendingMap[keyId] ?? 0.0;
      final txCount = countMap[keyName] ?? countMap[keyId] ?? 0;
      final prevSpent = prevSpendingMap[keyName] ?? prevSpendingMap[keyId] ?? 0.0;

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: spent,
        referenceDate: referenceDate,
        totalAllExpensesInPeriod: totalAllExpensesInPeriod,
        transactionCount: txCount,
        previousPeriodSpent: prevSpent,
      );

      summaries.add(BudgetSpentSummary(
        budget: budget,
        spent: spent,
        metrics: metrics,
      ));
    }

    return summaries;
  }

  /// Backward compatible wrapper for month-based queries
  Future<List<BudgetSpentSummary>> getBudgetsWithSpent({int? year, int? month}) async {
    final activeDate = MonthSelectorController.instance.value;
    final targetDate = DateTime(year ?? activeDate.year, month ?? activeDate.month, 15);
    return getBudgetsForPeriod(periodType: BudgetPeriodType.monthly, referenceDate: targetDate);
  }

  /// Calculates cumulative daily expenses for days 1..D in selected year/month.
  Future<List<double>> getDailyCumulativeExpenses(int year, int month) async {
    final db = await _dbHelper.database;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final rows = await db.rawQuery('''
      SELECT date, amount
      FROM ${DbConstants.tableTransactions}
      WHERE type = 0 AND year = ? AND month = ?
      ORDER BY date ASC
    ''', [year, month]);

    final Map<int, double> dayTotals = {};
    for (final row in rows) {
      final dateMs = row['date'] as int?;
      final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
      if (dateMs != null) {
        final day = DateTime.fromMillisecondsSinceEpoch(dateMs).day;
        dayTotals[day] = (dayTotals[day] ?? 0.0) + amount;
      }
    }

    final List<double> cumulative = List.filled(daysInMonth, 0.0);
    double runningSum = 0.0;
    for (int d = 1; d <= daysInMonth; d++) {
      runningSum += (dayTotals[d] ?? 0.0);
      cumulative[d - 1] = runningSum;
    }
    return cumulative;
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final db = await _dbHelper.database;
    await db.insert(
      DbConstants.tableBudgets,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBudget(BudgetModel budget) async {
    await saveBudget(budget);
  }

  Future<void> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    await db.delete(DbConstants.tableBudgets, where: 'id = ?', whereArgs: [id]);
  }

  DateTime _getPreviousPeriodReferenceDate(BudgetPeriodType periodType, DateTime referenceDate) {
    switch (periodType) {
      case BudgetPeriodType.daily:
        return referenceDate.subtract(const Duration(days: 1));
      case BudgetPeriodType.weekly:
        return referenceDate.subtract(const Duration(days: 7));
      case BudgetPeriodType.monthly:
        return DateTime(referenceDate.year, referenceDate.month - 1, 15);
      case BudgetPeriodType.yearly:
        return DateTime(referenceDate.year - 1, 6, 15);
    }
  }

  double _scaleAmountLimit(
    double amount, {
    required BudgetPeriodType from,
    required BudgetPeriodType to,
    required DateTime referenceDate,
  }) {
    if (amount <= 0) return amount;

    final daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;

    double monthlyBase;
    switch (from) {
      case BudgetPeriodType.daily:
        monthlyBase = amount * daysInMonth;
        break;
      case BudgetPeriodType.weekly:
        monthlyBase = (amount / 7.0) * daysInMonth;
        break;
      case BudgetPeriodType.monthly:
        monthlyBase = amount;
        break;
      case BudgetPeriodType.yearly:
        monthlyBase = amount / 12.0;
        break;
    }

    switch (to) {
      case BudgetPeriodType.daily:
        return monthlyBase / daysInMonth;
      case BudgetPeriodType.weekly:
        return (monthlyBase / daysInMonth) * 7.0;
      case BudgetPeriodType.monthly:
        return monthlyBase;
      case BudgetPeriodType.yearly:
        return monthlyBase * 12.0;
    }
  }
}
