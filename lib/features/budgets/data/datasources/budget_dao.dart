import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/state/month_selector_controller.dart';
import '../../domain/models/budget_model.dart';

class BudgetSpentSummary {
  final BudgetModel budget;
  final double spent;

  const BudgetSpentSummary({required this.budget, required this.spent});

  double get remaining => budget.amountLimit - spent;
  double get progressRatio => budget.amountLimit > 0 ? (spent / budget.amountLimit).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spent > budget.amountLimit;
  bool get isNearAlert => progressRatio >= budget.alertThreshold;
}

class BudgetDao {
  final AppDatabase _dbHelper;

  BudgetDao(this._dbHelper);

  Future<List<BudgetSpentSummary>> getBudgetsWithSpent({int? year, int? month}) async {
    final db = await _dbHelper.database;
    final budgetMaps = await db.query(DbConstants.tableBudgets, where: 'is_active = 1');
    if (budgetMaps.isEmpty) return [];

    final activeDate = MonthSelectorController.instance.value;
    final targetYear = year ?? activeDate.year;
    final targetMonth = month ?? activeDate.month;

    // Single JOIN / GROUP BY query for month spending performance
    final spendingRows = await db.rawQuery('''
      SELECT category, sub_category, SUM(amount) AS total_spent
      FROM ${DbConstants.tableTransactions}
      WHERE type = 0 AND year = ? AND month = ?
      GROUP BY category, sub_category
    ''', [targetYear, targetMonth]);

    final Map<String, double> spendingMap = {};
    for (final row in spendingRows) {
      final cat = row['category'] as String? ?? '';
      final subCat = row['sub_category'] as String? ?? '';
      final spent = (row['total_spent'] as num?)?.toDouble() ?? 0.0;
      spendingMap[cat.toLowerCase()] = (spendingMap[cat.toLowerCase()] ?? 0.0) + spent;
      if (subCat.isNotEmpty) {
        spendingMap[subCat.toLowerCase()] = (spendingMap[subCat.toLowerCase()] ?? 0.0) + spent;
      }
    }

    final List<BudgetSpentSummary> summaries = [];
    for (final map in budgetMaps) {
      final budget = BudgetModel.fromMap(map);
      final keyName = budget.name.toLowerCase();
      final keyId = budget.categoryId.toLowerCase();
      final spent = spendingMap[keyName] ?? spendingMap[keyId] ?? 0.0;

      summaries.add(BudgetSpentSummary(budget: budget, spent: spent));
    }

    return summaries;
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
}
