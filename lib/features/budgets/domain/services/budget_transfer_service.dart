import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_sync_service.dart';
import '../models/budget_model.dart';
import '../services/budget_status_engine.dart';

class BudgetTransferResult {
  final bool success;
  final String message;
  final double transferredAmount;
  final String? transactionId;

  const BudgetTransferResult({
    required this.success,
    required this.message,
    this.transferredAmount = 0.0,
    this.transactionId,
  });
}

class BudgetTransferService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Executes atomic Remaining Budget Transfer workflow.
  /// Transfers unused remaining budget balance from a budget category to a destination account.
  Future<BudgetTransferResult> transferRemainingBudget({
    required BudgetStatusMetrics metrics,
    required String destinationAccountId,
    required String destinationAccountName,
    required double transferAmount,
    String? customNotes,
  }) async {
    if (transferAmount <= 0) {
      return const BudgetTransferResult(
        success: false,
        message: 'Transfer amount must be greater than zero.',
      );
    }

    if (transferAmount > metrics.availableBalance) {
      return BudgetTransferResult(
        success: false,
        message: 'Transfer amount (\$${transferAmount.toStringAsFixed(2)}) exceeds available balance (\$${metrics.availableBalance.toStringAsFixed(2)}).',
      );
    }

    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      await db.transaction((txn) async {
        // 1. Fetch current destination account
        final accList = await txn.query('accounts', where: 'id = ?', whereArgs: [destinationAccountId]);
        if (accList.isEmpty) {
          throw Exception('Destination account not found.');
        }

        final currentAccBalance = (accList.first['balance'] as num?)?.toDouble() ?? 0.0;
        final newAccBalance = currentAccBalance + transferAmount;

        // 2. Insert Master Ledger Transaction (Transfer)
        final txId = await txn.insert('transactions', {
          'title': 'Budget Remaining Rollover Transfer - ${metrics.budget.name}',
          'merchant': 'Budget Engine Rollover',
          'amount': transferAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': metrics.budget.name,
          'sub_category': 'Budget Rollover',
          'type': 2, // Transfer
          'account_id': destinationAccountId,
          'account_name': destinationAccountName,
          'payment_method': 'System Transfer',
          'notes': customNotes ?? 'Automated remaining budget transfer of \$${transferAmount.toStringAsFixed(2)} to $destinationAccountName.',
          'status': 'cleared',
        });

        // 3. Update Destination Account Balance
        await txn.update(
          'accounts',
          {
            'balance': newAccBalance,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [destinationAccountId],
        );

        // 4. Update Budget record transferred_amount
        final updatedTransferred = metrics.transferredAmount + transferAmount;
        await txn.update(
          'budgets',
          {
            'transferred_amount': updatedTransferred,
          },
          where: 'id = ?',
          whereArgs: [metrics.budget.id],
        );

        // 5. Insert Audit Log
        await txn.insert('audit_logs', {
          'entity_type': 'budget_transfer',
          'entity_id': metrics.budget.id,
          'action': 'REMAINING_TRANSFER',
          'old_value': 'transferred=${metrics.transferredAmount}',
          'new_value': 'transferred=$updatedTransferred, dest=$destinationAccountId, amount=$transferAmount, txId=$txId',
          'timestamp': nowMs,
        });
      });

      // Broadcast event to trigger recalculation across all modules
      FinancialSyncService.instance.notifyMutation();

      return BudgetTransferResult(
        success: true,
        message: 'Successfully transferred \$${transferAmount.toStringAsFixed(2)} to $destinationAccountName.',
        transferredAmount: transferAmount,
      );
    } catch (e) {
      return BudgetTransferResult(
        success: false,
        message: 'Failed to complete budget transfer: ${e.toString()}',
      );
    }
  }

  /// Executes atomic Budget Overspend Recovery workflow.
  /// Debits funding source account to credit and recover overspent budget category.
  Future<BudgetTransferResult> recoverBudgetOverspend({
    required BudgetStatusMetrics metrics,
    required String fundingAccountId,
    required String fundingAccountName,
    required double recoveryAmount,
    String? customNotes,
  }) async {
    if (recoveryAmount <= 0) {
      return const BudgetTransferResult(
        success: false,
        message: 'Recovery amount must be greater than zero.',
      );
    }

    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      await db.transaction((txn) async {
        // 1. Fetch current funding account
        final accList = await txn.query('accounts', where: 'id = ?', whereArgs: [fundingAccountId]);
        if (accList.isEmpty) {
          throw Exception('Funding account not found.');
        }

        final currentAccBalance = (accList.first['balance'] as num?)?.toDouble() ?? 0.0;
        final newAccBalance = currentAccBalance - recoveryAmount;

        // 2. Insert Master Ledger Adjustment Transaction
        final txId = await txn.insert('transactions', {
          'title': 'Overspend Recovery - ${metrics.budget.name}',
          'merchant': 'Budget Recovery Engine',
          'amount': recoveryAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': metrics.budget.name,
          'sub_category': 'Overspend Adjustment',
          'type': 2, // Adjustment / Transfer
          'account_id': fundingAccountId,
          'account_name': fundingAccountName,
          'payment_method': 'System Adjustment',
          'notes': customNotes ?? 'Automated overspend recovery debit of \$${recoveryAmount.toStringAsFixed(2)} from $fundingAccountName to ${metrics.budget.name}.',
          'status': 'cleared',
        });

        // 3. Update Funding Account Balance (Debit)
        await txn.update(
          'accounts',
          {
            'balance': newAccBalance,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [fundingAccountId],
        );

        // 4. Update Budget record recovered_amount
        final updatedRecovered = metrics.recoveredAmount + recoveryAmount;
        await txn.update(
          'budgets',
          {
            'recovered_amount': updatedRecovered,
          },
          where: 'id = ?',
          whereArgs: [metrics.budget.id],
        );

        // 5. Insert Audit Log
        await txn.insert('audit_logs', {
          'entity_type': 'budget_recovery',
          'entity_id': metrics.budget.id,
          'action': 'OVERSPEND_RECOVERY',
          'old_value': 'recovered=${metrics.recoveredAmount}',
          'new_value': 'recovered=$updatedRecovered, source=$fundingAccountId, amount=$recoveryAmount, txId=$txId',
          'timestamp': nowMs,
        });
      });

      // Broadcast event to trigger recalculation across all modules
      FinancialSyncService.instance.notifyMutation();

      return BudgetTransferResult(
        success: true,
        message: 'Successfully recovered \$${recoveryAmount.toStringAsFixed(2)} from $fundingAccountName.',
        transferredAmount: recoveryAmount,
      );
    } catch (e) {
      return BudgetTransferResult(
        success: false,
        message: 'Failed to complete overspend recovery: ${e.toString()}',
      );
    }
  }
}
