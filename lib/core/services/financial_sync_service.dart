import 'package:flutter/material.dart';
import '../database/database_helper.dart';

/// Centralized Inter-Module Event Sync Bus.
/// Broadcasts financial updates when transactions, categories, budgets, goals, or accounts are mutated.
class FinancialSyncService extends ChangeNotifier {
  static FinancialSyncService? _instance;

  FinancialSyncService._internal();

  static FinancialSyncService get instance {
    _instance ??= FinancialSyncService._internal();
    return _instance!;
  }

  /// Broadcast mutation event to all dependent listeners.
  void notifyMutation() {
    notifyListeners();
  }

  /// Force SQLite WAL checkpoint to disk, then broadcast.
  Future<void> persistAndNotify() async {
    await DatabaseHelper.instance.forcePersistToDisk();
    notifyListeners();
  }
}
