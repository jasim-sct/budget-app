abstract class DbConstants {
  static const String dbName = 'budget_lite_v2.db';
  static const int dbVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableAccounts = 'accounts';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionSplits = 'transaction_splits';
  static const String tableTags = 'tags';
  static const String tableTransactionTags = 'transaction_tags';
  static const String tableBudgets = 'budgets';
  static const String tableBills = 'bills';
  static const String tableGoals = 'goals';
  static const String tableRecurring = 'recurring_transactions';
  static const String tableSettings = 'settings';
  static const String tableNotifications = 'notifications';
}
