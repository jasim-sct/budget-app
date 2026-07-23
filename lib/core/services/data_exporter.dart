import 'dart:convert';
import '../database/database_helper.dart';

/// Financial Data Exporter and Relational Backup / Restore Service.
class DataExporter {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Exports ledger transactions into standard CSV format.
  static Future<String> exportTransactionsToCsv({int? year, int? month}) async {
    final List<Map<String, dynamic>> rawList = (year != null && month != null)
        ? await _db.getTransactionsByMonth(year: year, month: month, limit: 1000)
        : await _db.getTransactionsPaginated(limit: 5000, offset: 0);

    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Date,Title,Amount,Type,Category,CustomCategory,Account,PaymentMethod,Notes,Currency,Status');

    for (final row in rawList) {
      final dateStr = DateTime.fromMillisecondsSinceEpoch(row['date'] as int? ?? 0).toIso8601String();
      final typeStr = (row['type'] as int? ?? 0) == 1 ? 'Income' : ((row['type'] as int? ?? 0) == 2 ? 'Transfer' : 'Expense');
      final title = '"${(row['title'] as String? ?? '').replaceAll('"', '""')}"';
      final category = '"${(row['category'] as String? ?? '').replaceAll('"', '""')}"';
      final notes = '"${(row['notes'] as String? ?? '').replaceAll('"', '""')}"';

      csv.writeln(
        '${row['id']},$dateStr,$title,${row['amount']},$typeStr,$category,${row['custom_category']},${row['account_name']},${row['payment_method']},$notes,${row['currency']},${row['status']}',
      );
    }

    return csv.toString();
  }

  /// Exports full relational database state into a single JSON backup.
  static Future<String> exportFullBackupJson() async {
    final db = await _db.database;

    final txs = await db.query('transactions');
    final cats = await db.query('categories');
    final accs = await db.query('accounts');
    final bgts = await db.query('budgets');
    final goals = await db.query('goals');

    final Map<String, dynamic> backup = {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'transactions': txs,
      'categories': cats,
      'accounts': accs,
      'budgets': bgts,
      'goals': goals,
    };

    return jsonEncode(backup);
  }

  /// Restores full database state from JSON backup.
  static Future<void> restoreBackupFromJson(String jsonStr) async {
    final Map<String, dynamic> backup = jsonDecode(jsonStr);
    final db = await _db.database;

    final batch = db.batch();
    batch.delete('transactions');
    batch.delete('categories');
    batch.delete('accounts');
    batch.delete('budgets');
    batch.delete('goals');

    if (backup['categories'] != null) {
      for (final item in (backup['categories'] as List)) {
        batch.insert('categories', Map<String, dynamic>.from(item as Map));
      }
    }
    if (backup['accounts'] != null) {
      for (final item in (backup['accounts'] as List)) {
        batch.insert('accounts', Map<String, dynamic>.from(item as Map));
      }
    }
    if (backup['transactions'] != null) {
      for (final item in (backup['transactions'] as List)) {
        batch.insert('transactions', Map<String, dynamic>.from(item as Map));
      }
    }
    if (backup['budgets'] != null) {
      for (final item in (backup['budgets'] as List)) {
        batch.insert('budgets', Map<String, dynamic>.from(item as Map));
      }
    }
    if (backup['goals'] != null) {
      for (final item in (backup['goals'] as List)) {
        batch.insert('goals', Map<String, dynamic>.from(item as Map));
      }
    }

    await batch.commit(noResult: true);
  }
}
