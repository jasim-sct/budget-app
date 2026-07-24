import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_sync_service.dart';
import '../models/budget_model.dart';
import '../models/budget_period.dart';
import '../services/budget_status_engine.dart';

class PeriodComparisonMetrics {
  final String currentPeriodKey;
  final String previousPeriodKey;
  final double currentSpent;
  final double previousSpent;
  final double spentVariance;
  final double spentChangePercentage;
  final double currentAllocation;
  final double previousAllocation;
  final double currentHealthScore;
  final double previousHealthScore;

  const PeriodComparisonMetrics({
    required this.currentPeriodKey,
    required this.previousPeriodKey,
    required this.currentSpent,
    required this.previousSpent,
    required this.spentVariance,
    required this.spentChangePercentage,
    required this.currentAllocation,
    required this.previousAllocation,
    required this.currentHealthScore,
    required this.previousHealthScore,
  });
}

class BudgetHistoryEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Checks if any budget cycle boundary has elapsed and runs automated cycle reset + archiving.
  Future<void> checkAndRunRollover({DateTime? currentDate}) async {
    final now = currentDate ?? DateTime.now();
    final db = await _dbHelper.database;

    for (final periodType in BudgetPeriodType.values) {
      final currentKey = periodType.getPeriodKey(now);
      final settingKey = 'last_rollover_key_${periodType.toDbString().toLowerCase()}';

      final res = await db.query('user_settings', where: 'key = ?', whereArgs: [settingKey]);
      final lastKey = res.isNotEmpty ? res.first['value'] as String? : null;

      if (lastKey != null && lastKey != currentKey) {
        // Cycle completed! Archive snapshots for completed cycle key
        await _executeCycleRollover(periodType: periodType, completedPeriodKey: lastKey, referenceDate: now);
      }

      // Update stored key
      await db.insert(
        'user_settings',
        {'key': settingKey, 'value': currentKey},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Executes cycle archiving and applies carry-forward rules for new cycle.
  Future<void> _executeCycleRollover({
    required BudgetPeriodType periodType,
    required String completedPeriodKey,
    required DateTime referenceDate,
  }) async {
    final db = await _dbHelper.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final budgetMaps = await db.query(
      'budgets',
      where: 'is_active = 1 AND (period_type = ? OR period_type IS NULL OR period_type = "")',
      whereArgs: [periodType.toDbString()],
    );

    for (final map in budgetMaps) {
      final budget = BudgetModel.fromMap(map);

      // Compute status for completing cycle
      final bounds = periodType.calculatePeriodBounds(referenceDate);
      final startMs = bounds.start.millisecondsSinceEpoch;
      final endMs = bounds.end.millisecondsSinceEpoch;

      final spentRes = await db.rawQuery('''
        SELECT SUM(amount) AS total, COUNT(id) AS tx_count
        FROM transactions
        WHERE type = 0 AND category = ? AND date >= ? AND date <= ?
      ''', [budget.name, startMs, endMs]);

      final spent = (spentRes.first['total'] as num?)?.toDouble() ?? 0.0;
      final txCount = (spentRes.first['tx_count'] as num?)?.toInt() ?? 0;

      final metrics = BudgetStatusEngine.calculate(
        budget: budget,
        spent: spent,
        referenceDate: referenceDate,
        transactionCount: txCount,
      );

      // 1. Save historical snapshot into budget_history table
      await db.insert('budget_history', {
        'budget_id': budget.id,
        'category_id': budget.categoryId,
        'category_name': budget.name,
        'period_type': periodType.toDbString(),
        'period_key': completedPeriodKey,
        'allocated_amount': metrics.allocation,
        'spent_amount': metrics.spent,
        'remaining_amount': metrics.remaining,
        'transferred_amount': metrics.transferredAmount,
        'recovered_amount': metrics.recoveredAmount,
        'carry_forward_amount': metrics.carryForwardAmount,
        'health_score': metrics.budgetHealthScore,
        'completion_percentage': metrics.progressPercentage,
        'transaction_count': metrics.transactionCount,
        'status': metrics.status.label,
        'top_merchant': 'Archived',
        'created_at': nowMs,
      });

      // 2. Apply Carry-Forward Rules for new cycle
      double newCarryForward = 0.0;
      switch (budget.carryForwardRule) {
        case CarryForwardRule.carryRemaining:
          newCarryForward = metrics.remaining > 0 ? metrics.remaining : 0.0;
          break;
        case CarryForwardRule.carryOverspend:
          newCarryForward = metrics.remaining < 0 ? metrics.remaining : 0.0;
          break;
        case CarryForwardRule.ignore:
        case CarryForwardRule.resetCompletely:
        case CarryForwardRule.manualRollover:
          newCarryForward = 0.0;
          break;
      }

      // 3. Reset budget transfer/recovery amounts & apply new carry-forward
      await db.update(
        'budgets',
        {
          'carry_forward_amount': newCarryForward,
          'transferred_amount': 0.0,
          'recovered_amount': 0.0,
        },
        where: 'id = ?',
        whereArgs: [budget.id],
      );
    }

    FinancialSyncService.instance.notifyMutation();
  }

  /// Calculates period-over-period comparison metrics.
  Future<PeriodComparisonMetrics> comparePeriods({
    required BudgetPeriodType periodType,
    required DateTime currentDate,
  }) async {
    final currentKey = periodType.getPeriodKey(currentDate);

    DateTime prevDate;
    switch (periodType) {
      case BudgetPeriodType.daily:
        prevDate = currentDate.subtract(const Duration(days: 1));
        break;
      case BudgetPeriodType.weekly:
        prevDate = currentDate.subtract(const Duration(days: 7));
        break;
      case BudgetPeriodType.monthly:
        prevDate = DateTime(currentDate.year, currentDate.month - 1, 15);
        break;
      case BudgetPeriodType.yearly:
        prevDate = DateTime(currentDate.year - 1, 6, 15);
        break;
    }

    final prevKey = periodType.getPeriodKey(prevDate);

    final db = await _dbHelper.database;

    // Current period spending
    final currentBounds = periodType.calculatePeriodBounds(currentDate);
    final curStart = currentBounds.start.millisecondsSinceEpoch;
    final curEnd = currentBounds.end.millisecondsSinceEpoch;

    final curSpentRes = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM transactions WHERE type = 0 AND date >= ? AND date <= ?',
      [curStart, curEnd],
    );
    final curSpent = (curSpentRes.first['total'] as num?)?.toDouble() ?? 0.0;

    // Prev period spending
    final prevBounds = periodType.calculatePeriodBounds(prevDate);
    final pStart = prevBounds.start.millisecondsSinceEpoch;
    final pEnd = prevBounds.end.millisecondsSinceEpoch;

    final prevSpentRes = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM transactions WHERE type = 0 AND date >= ? AND date <= ?',
      [pStart, pEnd],
    );
    final prevSpent = (prevSpentRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final variance = curSpent - prevSpent;
    final changePct = prevSpent > 0 ? ((curSpent - prevSpent) / prevSpent * 100.0) : 0.0;

    // Allocations
    final budgetsRes = await db.rawQuery('SELECT SUM(amount_limit + carry_forward_amount) AS total FROM budgets WHERE is_active = 1');
    final curAlloc = (budgetsRes.first['total'] as num?)?.toDouble() ?? 0.0;

    return PeriodComparisonMetrics(
      currentPeriodKey: currentKey,
      previousPeriodKey: prevKey,
      currentSpent: curSpent,
      previousSpent: prevSpent,
      spentVariance: variance,
      spentChangePercentage: changePct,
      currentAllocation: curAlloc,
      previousAllocation: curAlloc,
      currentHealthScore: curAlloc > 0 ? ((1.0 - (curSpent / curAlloc)) * 100.0).clamp(0.0, 100.0) : 100.0,
      previousHealthScore: curAlloc > 0 ? ((1.0 - (prevSpent / curAlloc)) * 100.0).clamp(0.0, 100.0) : 100.0,
    );
  }
}
