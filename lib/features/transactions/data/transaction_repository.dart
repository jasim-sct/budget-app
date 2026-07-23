import '../../../core/database/app_database.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/services/global_filter_controller.dart';
import '../../../core/state/micro_notifier.dart';
import '../../../core/state/month_selector_controller.dart';
import '../domain/transaction_model.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;
  final bool isLoading;
  final bool hasMore;

  const TransactionState({
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.isLoading,
    required this.hasMore,
  });

  double get balance => totalIncome - totalExpense;

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    double? totalIncome,
    double? totalExpense,
    bool? isLoading,
    bool? hasMore,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Feature repository managing data pagination, enterprise global filtering, and micro-state.
class TransactionRepository {
  static const int pageSize = 50;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final MicroState<TransactionState> stateNotifier = MicroState(
    const TransactionState(
      transactions: [],
      totalIncome: 0.0,
      totalExpense: 0.0,
      isLoading: false,
      hasMore: true,
    ),
  );

  int _currentOffset = 0;
  bool _isFetching = false;

  TransactionRepository() {
    MonthSelectorController.instance.addListener(loadInitialData);
    FinancialSyncService.instance.addListener(loadInitialData);
    GlobalFilterController.instance.filterNotifier.addListener(loadInitialData);
  }

  /// Loads filtered transactions and summary totals based on GlobalFilterController and active Month.
  Future<void> loadInitialData() async {
    _isFetching = true;
    _currentOffset = 0;

    stateNotifier.update(stateNotifier.value.copyWith(isLoading: true));

    final date = MonthSelectorController.instance.value;
    final filter = GlobalFilterController.instance.state;

    final rawTxList = await _dbHelper.getFilteredTransactions(
      filter,
      limit: pageSize,
      offset: 0,
      activeYear: date.year,
      activeMonth: date.month,
    );

    final totals = await _dbHelper.getFilteredSummaryTotals(
      filter,
      activeYear: date.year,
      activeMonth: date.month,
    );

    final txModels = rawTxList.map((map) => TransactionModel.fromMap(map)).toList();

    _currentOffset = txModels.length;

    stateNotifier.update(
      TransactionState(
        transactions: txModels,
        totalIncome: totals['income'] ?? 0.0,
        totalExpense: totals['expense'] ?? 0.0,
        isLoading: false,
        hasMore: txModels.length == pageSize,
      ),
    );

    _isFetching = false;
  }

  /// Appends next page of filtered transactions on scroll
  Future<void> loadMore() async {
    if (_isFetching || !stateNotifier.value.hasMore) return;
    _isFetching = true;

    final date = MonthSelectorController.instance.value;
    final filter = GlobalFilterController.instance.state;

    final rawTxList = await _dbHelper.getFilteredTransactions(
      filter,
      limit: pageSize,
      offset: _currentOffset,
      activeYear: date.year,
      activeMonth: date.month,
    );

    final newTxModels = rawTxList.map((map) => TransactionModel.fromMap(map)).toList();

    _currentOffset += newTxModels.length;

    final updatedList = List<TransactionModel>.from(stateNotifier.value.transactions)
      ..addAll(newTxModels);

    stateNotifier.update(
      stateNotifier.value.copyWith(
        transactions: updatedList,
        hasMore: newTxModels.length == pageSize,
      ),
    );

    _isFetching = false;
  }

  /// Add new transaction with indexed SQL insert and broadcast inter-module sync
  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbHelper.insertTransaction(transaction.toMap());
    await loadInitialData();
    FinancialSyncService.instance.notifyMutation();
  }

  /// Delete transaction
  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await loadInitialData();
    FinancialSyncService.instance.notifyMutation();
  }

  /// Clear all stored application data across all database tables
  Future<void> clearAll() async {
    await _dbHelper.clearAllData();
    await AppDatabase.instance.clearAllData();
    await loadInitialData();
    FinancialSyncService.instance.notifyMutation();
    await FinancialCalculationEngine.instance.recalculate();
  }
}
