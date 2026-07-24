import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_sync_service.dart';
import '../services/budget_status_engine.dart';

class BudgetTransferResult {
  final bool success;
  final String message;
  final double transferredAmount;
  final String? transferId;
  final int? outTransactionId;
  final int? inTransactionId;

  const BudgetTransferResult({
    required this.success,
    required this.message,
    this.transferredAmount = 0.0,
    this.transferId,
    this.outTransactionId,
    this.inTransactionId,
  });
}

class BudgetTransferService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Remaining budget → destination account as a true self-transfer:
  /// exactly two ledger legs (Transfer Out + Transfer In).
  Future<BudgetTransferResult> transferRemainingBudget({
    required BudgetStatusMetrics metrics,
    required String destinationAccountId,
    required String destinationAccountName,
    required double transferAmount,
    String? sourceAccountId,
    String? sourceAccountName,
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
        message:
            'Transfer amount (\$${transferAmount.toStringAsFixed(2)}) exceeds available balance (\$${metrics.availableBalance.toStringAsFixed(2)}).',
      );
    }

    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      // Resolve source account (must differ from destination for two-ledger transfer).
      String fromId = sourceAccountId ?? '';
      String fromName = sourceAccountName ?? '';
      if (fromId.isEmpty || fromId == destinationAccountId) {
        final accounts = await _dbHelper.getAllAccounts();
        final source = accounts.cast<Map<String, dynamic>?>().firstWhere(
              (a) => a != null && (a['id'] as String?) != destinationAccountId,
              orElse: () => null,
            );
        if (source == null) {
          return const BudgetTransferResult(
            success: false,
            message:
                'Self-transfer needs two accounts. Add another wallet to move remaining budget.',
          );
        }
        fromId = source['id'] as String;
        fromName = source['name'] as String? ?? 'Source Wallet';
      }

      final transferId =
          'bgt_xfer_${nowMs}_${metrics.budget.id}_$destinationAccountId';
      final baseTitle = 'Budget Remaining - ${metrics.budget.name}';
      final sharedNotes = customNotes ??
          'Remaining budget transfer of \$${transferAmount.toStringAsFixed(2)} from $fromName to $destinationAccountName.';

      late final int outId;
      late final int inId;

      await db.transaction((txn) async {
        final destList = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [destinationAccountId],
        );
        final srcList = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [fromId],
        );
        if (destList.isEmpty) {
          throw Exception('Destination account not found.');
        }
        if (srcList.isEmpty) {
          throw Exception('Source account not found.');
        }

        final outRow = <String, dynamic>{
          'title': '$baseTitle → $destinationAccountName',
          'merchant': 'Budget Engine Rollover',
          'amount': transferAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': 'Transfer',
          'sub_category': 'Budget Rollover',
          'type': DatabaseHelper.ledgerTransfer,
          'account_id': fromId,
          'account_name': fromName,
          'payment_method': DatabaseHelper.transferOutMethod,
          'notes': sharedNotes,
          'reference_number': transferId,
          'status': 'cleared',
        };

        final inRow = <String, dynamic>{
          'title': '$baseTitle ← $fromName',
          'merchant': 'Budget Engine Rollover',
          'amount': transferAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': 'Transfer',
          'sub_category': 'Budget Rollover',
          'type': DatabaseHelper.ledgerTransfer,
          'account_id': destinationAccountId,
          'account_name': destinationAccountName,
          'payment_method': DatabaseHelper.transferInMethod,
          'notes': sharedNotes,
          'reference_number': transferId,
          'status': 'cleared',
        };

        outId = await txn.insert('transactions', outRow);
        inId = await txn.insert('transactions', inRow);

        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [DatabaseHelper.ledgerBalanceDelta(outRow), nowMs, fromId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [DatabaseHelper.ledgerBalanceDelta(inRow), nowMs, destinationAccountId],
        );

        final updatedTransferred = metrics.transferredAmount + transferAmount;
        await txn.update(
          'budgets',
          {'transferred_amount': updatedTransferred},
          where: 'id = ?',
          whereArgs: [metrics.budget.id],
        );

        await txn.insert('audit_logs', {
          'entity_type': 'budget_transfer',
          'entity_id': metrics.budget.id,
          'action': 'REMAINING_TRANSFER',
          'old_value': 'transferred=${metrics.transferredAmount}',
          'new_value':
              'transferred=$updatedTransferred, transferId=$transferId, out=$outId, in=$inId, from=$fromId, dest=$destinationAccountId, amount=$transferAmount',
          'timestamp': nowMs,
        });
      });

      await FinancialSyncService.instance.persistAndNotify();

      return BudgetTransferResult(
        success: true,
        message:
            'Transferred \$${transferAmount.toStringAsFixed(2)} with two ledger entries ($fromName → $destinationAccountName).',
        transferredAmount: transferAmount,
        transferId: transferId,
        outTransactionId: outId,
        inTransactionId: inId,
      );
    } catch (e) {
      return BudgetTransferResult(
        success: false,
        message: 'Failed to complete budget transfer: ${e.toString()}',
      );
    }
  }

  /// Overspend recovery: two ledger legs (out from funding account, in to cash/operating).
  Future<BudgetTransferResult> recoverBudgetOverspend({
    required BudgetStatusMetrics metrics,
    required String fundingAccountId,
    required String fundingAccountName,
    required double recoveryAmount,
    String? destinationAccountId,
    String? destinationAccountName,
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

      String toId = destinationAccountId ?? '';
      String toName = destinationAccountName ?? '';
      if (toId.isEmpty || toId == fundingAccountId) {
        final accounts = await _dbHelper.getAllAccounts();
        final dest = accounts.cast<Map<String, dynamic>?>().firstWhere(
              (a) => a != null && (a['id'] as String?) != fundingAccountId,
              orElse: () => null,
            );
        if (dest == null) {
          return const BudgetTransferResult(
            success: false,
            message:
                'Self-transfer needs two accounts. Add another wallet for overspend recovery.',
          );
        }
        toId = dest['id'] as String;
        toName = dest['name'] as String? ?? 'Destination Wallet';
      }

      final transferId =
          'bgt_rec_${nowMs}_${metrics.budget.id}_$fundingAccountId';
      final baseTitle = 'Overspend Recovery - ${metrics.budget.name}';
      final sharedNotes = customNotes ??
          'Overspend recovery of \$${recoveryAmount.toStringAsFixed(2)} from $fundingAccountName.';

      late final int outId;
      late final int inId;

      await db.transaction((txn) async {
        final srcList = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [fundingAccountId],
        );
        final destList = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [toId],
        );
        if (srcList.isEmpty) {
          throw Exception('Funding account not found.');
        }
        if (destList.isEmpty) {
          throw Exception('Destination account not found.');
        }

        final outRow = <String, dynamic>{
          'title': '$baseTitle → $toName',
          'merchant': 'Budget Recovery Engine',
          'amount': recoveryAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': 'Transfer',
          'sub_category': 'Overspend Adjustment',
          'type': DatabaseHelper.ledgerTransfer,
          'account_id': fundingAccountId,
          'account_name': fundingAccountName,
          'payment_method': DatabaseHelper.transferOutMethod,
          'notes': sharedNotes,
          'reference_number': transferId,
          'status': 'cleared',
        };

        final inRow = <String, dynamic>{
          'title': '$baseTitle ← $fundingAccountName',
          'merchant': 'Budget Recovery Engine',
          'amount': recoveryAmount,
          'date': nowMs,
          'month': now.month,
          'year': now.year,
          'category': 'Transfer',
          'sub_category': 'Overspend Adjustment',
          'type': DatabaseHelper.ledgerTransfer,
          'account_id': toId,
          'account_name': toName,
          'payment_method': DatabaseHelper.transferInMethod,
          'notes': sharedNotes,
          'reference_number': transferId,
          'status': 'cleared',
        };

        outId = await txn.insert('transactions', outRow);
        inId = await txn.insert('transactions', inRow);

        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [DatabaseHelper.ledgerBalanceDelta(outRow), nowMs, fundingAccountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
          [DatabaseHelper.ledgerBalanceDelta(inRow), nowMs, toId],
        );

        final updatedRecovered = metrics.recoveredAmount + recoveryAmount;
        await txn.update(
          'budgets',
          {'recovered_amount': updatedRecovered},
          where: 'id = ?',
          whereArgs: [metrics.budget.id],
        );

        await txn.insert('audit_logs', {
          'entity_type': 'budget_recovery',
          'entity_id': metrics.budget.id,
          'action': 'OVERSPEND_RECOVERY',
          'old_value': 'recovered=${metrics.recoveredAmount}',
          'new_value':
              'recovered=$updatedRecovered, transferId=$transferId, out=$outId, in=$inId, source=$fundingAccountId, dest=$toId, amount=$recoveryAmount',
          'timestamp': nowMs,
        });
      });

      await FinancialSyncService.instance.persistAndNotify();

      return BudgetTransferResult(
        success: true,
        message:
            'Recovered \$${recoveryAmount.toStringAsFixed(2)} with two ledger entries ($fundingAccountName → $toName).',
        transferredAmount: recoveryAmount,
        transferId: transferId,
        outTransactionId: outId,
        inTransactionId: inId,
      );
    } catch (e) {
      return BudgetTransferResult(
        success: false,
        message: 'Failed to complete overspend recovery: ${e.toString()}',
      );
    }
  }
}
