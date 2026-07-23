import 'package:sqflite/sqflite.dart';
import '../../../../core/constants/db_constants.dart';
import '../../../../core/database/app_database.dart';
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

  Future<List<BudgetSpentSummary>> getBudgetsWithSpent() async {
    final db = await _dbHelper.database;
    final budgetMaps = await db.query(DbConstants.tableBudgets, where: 'is_active = 1');
    
    final List<BudgetSpentSummary> summaries = [];
    for (final map in budgetMaps) {
      final budget = BudgetModel.fromMap(map);
      
      // SQL aggregate query matching category_id, name, and sub_category
      final res = await db.rawQuery(
        'SELECT SUM(amount) as total FROM ${DbConstants.tableTransactions} WHERE (category = ? OR category = ? OR sub_category = ?) AND type = 0',
        [budget.categoryId, budget.name, budget.name],
      );
      
      double spent = 0.0;
      if (res.isNotEmpty && res.first['total'] != null) {
        spent = (res.first['total'] as num).toDouble();
      }

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

  Future<void> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    await db.delete(DbConstants.tableBudgets, where: 'id = ?', whereArgs: [id]);
  }
}
