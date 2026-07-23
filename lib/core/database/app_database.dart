import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../constants/db_constants.dart';

/// Commercial-grade, normalized relational SQLite database service.
/// Optimized for weak eMMC storage using WAL mode and compound indexing.
class AppDatabase {
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Lazy database getter. Startup renders first frame without waiting for DB creation.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DbConstants.dbName);

    return await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onConfigure: (db) async {
        // WAL Mode for faster concurrent reads & minimal write amplification on eMMC
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createTables,
    );
  }

  FutureOr<void> _createTables(Database db, int version) async {
    final batch = db.batch();

    // 1. Users
    batch.execute('''
      CREATE TABLE ${DbConstants.tableUsers} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        currency_code TEXT NOT NULL DEFAULT 'USD',
        has_pin INTEGER NOT NULL DEFAULT 0,
        pin_hash TEXT,
        use_biometrics INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');

    // 2. Accounts / Wallets
    batch.execute('''
      CREATE TABLE ${DbConstants.tableAccounts} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'USD',
        color_value INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL
      );
    ''');

    // 3. Categories
    batch.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        id TEXT PRIMARY KEY,
        parent_id TEXT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (parent_id) REFERENCES ${DbConstants.tableCategories}(id) ON DELETE CASCADE
      );
    ''');

    // 4. Transactions
    batch.execute('''
      CREATE TABLE ${DbConstants.tableTransactions} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        notes TEXT,
        type INTEGER NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_id TEXT,
        attachment_path TEXT,
        FOREIGN KEY (account_id) REFERENCES ${DbConstants.tableAccounts}(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES ${DbConstants.tableCategories}(id) ON DELETE RESTRICT
      );
    ''');

    // 5. Transaction Splits
    batch.execute('''
      CREATE TABLE ${DbConstants.tableTransactionSplits} (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        FOREIGN KEY (transaction_id) REFERENCES ${DbConstants.tableTransactions}(id) ON DELETE CASCADE
      );
    ''');

    // 6. Tags
    batch.execute('''
      CREATE TABLE ${DbConstants.tableTags} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      );
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableTransactionTags} (
        transaction_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (transaction_id, tag_id),
        FOREIGN KEY (transaction_id) REFERENCES ${DbConstants.tableTransactions}(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES ${DbConstants.tableTags}(id) ON DELETE CASCADE
      );
    ''');

    // 7. Budgets
    batch.execute('''
      CREATE TABLE ${DbConstants.tableBudgets} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        amount_limit REAL NOT NULL,
        period_type TEXT NOT NULL,
        alert_threshold REAL NOT NULL DEFAULT 0.8,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES ${DbConstants.tableCategories}(id) ON DELETE CASCADE
      );
    ''');

    // 8. Bills
    batch.execute('''
      CREATE TABLE ${DbConstants.tableBills} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER NOT NULL,
        frequency TEXT NOT NULL,
        is_auto_pay INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'unpaid',
        FOREIGN KEY (account_id) REFERENCES ${DbConstants.tableAccounts}(id),
        FOREIGN KEY (category_id) REFERENCES ${DbConstants.tableCategories}(id)
      );
    ''');

    // 9. Goals
    batch.execute('''
      CREATE TABLE ${DbConstants.tableGoals} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date INTEGER NOT NULL,
        category TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 10. Recurring Transactions Engine
    batch.execute('''
      CREATE TABLE ${DbConstants.tableRecurring} (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        frequency TEXT NOT NULL,
        next_run_date INTEGER NOT NULL,
        type INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      );
    ''');

    // 11. Settings
    batch.execute('''
      CREATE TABLE ${DbConstants.tableSettings} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // 12. Notifications
    batch.execute('''
      CREATE TABLE ${DbConstants.tableNotifications} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        scheduled_at INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        payload TEXT
      );
    ''');

    // Compound High-Performance Indexes for 1GB RAM CPU queries
    batch.execute('CREATE INDEX idx_tx_date ON ${DbConstants.tableTransactions}(date DESC);');
    batch.execute('CREATE INDEX idx_tx_cat ON ${DbConstants.tableTransactions}(category_id);');
    batch.execute('CREATE INDEX idx_tx_acc ON ${DbConstants.tableTransactions}(account_id);');
    batch.execute('CREATE INDEX idx_budget_cat ON ${DbConstants.tableBudgets}(category_id);');
    batch.execute('CREATE INDEX idx_bill_due ON ${DbConstants.tableBills}(due_date);');

    // Pre-populate system default categories & accounts
    _seedDefaultData(batch);

    await batch.commit(noResult: true);
  }

  void _seedDefaultData(Batch batch) {
    // Default Cash & Bank Accounts
    final now = DateTime.now().millisecondsSinceEpoch;
    batch.insert(DbConstants.tableAccounts, {
      'id': 'acc_cash_default',
      'name': 'Cash Wallet',
      'type': 'cash',
      'balance': 0.0,
      'currency': 'USD',
      'color_value': 0xFF107C41,
      'is_active': 1,
      'updated_at': now,
    });

    batch.insert(DbConstants.tableAccounts, {
      'id': 'acc_bank_default',
      'name': 'Bank Account',
      'type': 'bank',
      'balance': 0.0,
      'currency': 'USD',
      'color_value': 0xFF2563EB,
      'is_active': 1,
      'updated_at': now,
    });

    // Default System Categories
    final defaultCategories = [
      {'id': 'cat_food', 'name': 'Food & Dining', 'type': 0, 'icon': 0xe25a, 'color': 0xFFDC2626},
      {'id': 'cat_transport', 'name': 'Transportation', 'type': 0, 'icon': 0xe1d5, 'color': 0xFFF59E0B},
      {'id': 'cat_utilities', 'name': 'Bills & Utilities', 'type': 0, 'icon': 0xe57d, 'color': 0xFF8B5CF6},
      {'id': 'cat_housing', 'name': 'Housing & Rent', 'type': 0, 'icon': 0xe318, 'color': 0xFF10B981},
      {'id': 'cat_shopping', 'name': 'Shopping', 'type': 0, 'icon': 0xe59c, 'color': 0xFFEC4899},
      {'id': 'cat_salary', 'name': 'Salary & Wages', 'type': 1, 'icon': 0xe000, 'color': 0xFF059669},
      {'id': 'cat_freelance', 'name': 'Freelance Income', 'type': 1, 'icon': 0xe6e1, 'color': 0xFF3B82F6},
      {'id': 'cat_investment', 'name': 'Investments', 'type': 1, 'icon': 0xe850, 'color': 0xFF6366F1},
    ];

    for (final cat in defaultCategories) {
      batch.insert(DbConstants.tableCategories, {
        'id': cat['id'],
        'parent_id': null,
        'name': cat['name'],
        'type': cat['type'],
        'icon_code': cat['icon'],
        'color_value': cat['color'],
        'is_system': 1,
      });
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
