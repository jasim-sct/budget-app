import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../services/filter_query_builder.dart';
import '../services/financial_sync_service.dart';
import '../services/global_filter_state.dart';

/// Commercial-grade SQLite Database Engine (Version 3).
/// Single source of truth master ledger supporting sub-categories, multi-currency exchange rates,
/// envelope budget carry-forwards, goal risk metrics, and enterprise global filtering.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Forces WAL pages into the main DB file on disk (app-private storage).
  Future<void> forcePersistToDisk() async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL);');
  }

  Future<void> _persistAndNotify() async {
    await forcePersistToDisk();
    FinancialSyncService.instance.notifyMutation();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'budget_lite_enterprise_v3.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL;');
        // FULL forces durable disk flush of each committed frame (app storage).
        await db.execute('PRAGMA synchronous = FULL;');
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN updated_at INTEGER DEFAULT 0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN interest_rate REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN interest_type TEXT DEFAULT "flat";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN interest_frequency TEXT DEFAULT "Monthly";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN loan_tenure_months INTEGER DEFAULT 12;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE accounts ADD COLUMN initial_principal REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN name TEXT;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN alert_threshold REAL DEFAULT 0.8;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN is_active INTEGER DEFAULT 1;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN period_type TEXT DEFAULT "Monthly";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN carry_forward_rule TEXT DEFAULT "carry_remaining";');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN carry_forward_amount REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN transferred_amount REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN recovered_amount REAL DEFAULT 0.0;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN start_date INTEGER;');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE budgets ADD COLUMN end_date INTEGER;');
        } catch (_) {}
        try {
          await db.execute('CREATE TABLE IF NOT EXISTS user_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audit_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              action TEXT NOT NULL,
              old_value TEXT,
              new_value TEXT,
              timestamp INTEGER NOT NULL
            );
          ''');
        } catch (_) {}
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budget_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              budget_id TEXT NOT NULL,
              category_id TEXT NOT NULL,
              category_name TEXT NOT NULL,
              period_type TEXT NOT NULL,
              period_key TEXT NOT NULL,
              allocated_amount REAL NOT NULL,
              spent_amount REAL NOT NULL,
              remaining_amount REAL NOT NULL,
              transferred_amount REAL DEFAULT 0.0,
              recovered_amount REAL DEFAULT 0.0,
              carry_forward_amount REAL DEFAULT 0.0,
              health_score REAL DEFAULT 100.0,
              completion_percentage REAL DEFAULT 0.0,
              transaction_count INTEGER DEFAULT 0,
              status TEXT DEFAULT 'On Track',
              top_merchant TEXT,
              created_at INTEGER NOT NULL
            );
          ''');
        } catch (_) {}
        try {
          await _seedFundingAccountsIfMissing(db);
        } catch (_) {}
      },
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. Master Ledger Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        merchant TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        category TEXT NOT NULL,
        sub_category TEXT,
        custom_category TEXT,
        type INTEGER NOT NULL, -- 0: Expense, 1: Income, 2: Transfer, 3: Recurring, 4: Loan, 5: Investment
        account_id TEXT DEFAULT 'acc_cash',
        account_name TEXT DEFAULT 'Cash Wallet',
        payment_method TEXT DEFAULT 'Cash',
        notes TEXT,
        tags TEXT,
        location TEXT,
        reference_number TEXT,
        attachment_path TEXT,
        currency TEXT DEFAULT 'USD',
        exchange_rate REAL DEFAULT 1.0,
        is_recurring INTEGER DEFAULT 0,
        scheduled_date INTEGER,
        status TEXT DEFAULT 'cleared'
      )
    ''');

    // 2. Hierarchical Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        parent_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        is_hidden INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        description TEXT
      )
    ''');

    // 3. Multi-Account Engine Table
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        opening_balance REAL NOT NULL DEFAULT 0.0,
        credit_limit REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'USD',
        color_value INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER DEFAULT 0,
        interest_rate REAL DEFAULT 0.0,
        interest_type TEXT DEFAULT 'flat',
        interest_frequency TEXT DEFAULT 'Monthly',
        loan_tenure_months INTEGER DEFAULT 12,
        initial_principal REAL DEFAULT 0.0
      )
    ''');

    // 4. Advanced Budgets Table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        amount_limit REAL NOT NULL,
        envelope_allocated REAL DEFAULT 0.0,
        carry_forward INTEGER DEFAULT 0,
        period_type TEXT NOT NULL DEFAULT 'Monthly',
        alert_threshold REAL DEFAULT 0.8,
        is_active INTEGER DEFAULT 1,
        month INTEGER,
        year INTEGER
      )
    ''');

    // 5. Financial Goals Table
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        target_date INTEGER NOT NULL,
        category TEXT NOT NULL,
        account_id TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_tx_date ON transactions(date DESC);');
    await db.execute('CREATE INDEX idx_tx_month_year ON transactions(year, month);');
    await db.execute('CREATE INDEX idx_tx_cat ON transactions(category);');
    await db.execute('CREATE INDEX idx_cat_parent ON categories(parent_id);');

    await db.execute(
      'CREATE TABLE IF NOT EXISTS user_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);',
    );

    await _seedEnterpriseDefaults(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      await db.execute('ALTER TABLE accounts ADD COLUMN interest_rate REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE accounts ADD COLUMN interest_type TEXT DEFAULT "flat"');
      await db.execute('ALTER TABLE accounts ADD COLUMN interest_frequency TEXT DEFAULT "Monthly"');
      await db.execute('ALTER TABLE accounts ADD COLUMN loan_tenure_months INTEGER DEFAULT 12');
      await db.execute('ALTER TABLE accounts ADD COLUMN initial_principal REAL DEFAULT 0.0');
    } catch (_) {}

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN merchant TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN location TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN sub_category TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN exchange_rate REAL DEFAULT 1.0');
        await db.execute('ALTER TABLE transactions ADD COLUMN reference_number TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN scheduled_date INTEGER');

        await db.execute('ALTER TABLE categories ADD COLUMN parent_id TEXT');
        await db.execute('ALTER TABLE categories ADD COLUMN is_favorite INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE categories ADD COLUMN is_hidden INTEGER DEFAULT 0');

        await db.execute('ALTER TABLE accounts ADD COLUMN opening_balance REAL DEFAULT 0.0');
        await db.execute('ALTER TABLE accounts ADD COLUMN credit_limit REAL DEFAULT 0.0');

        await db.execute('ALTER TABLE budgets ADD COLUMN carry_forward INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE budgets ADD COLUMN envelope_allocated REAL DEFAULT 0.0');
      } catch (_) {}
    }
  }

  Future<void> _seedEnterpriseDefaults(Database db) async {
    final batch = db.batch();

    // Default Accounts with Initial Balances & Ledger Entries
    final nowTime = DateTime.now().millisecondsSinceEpoch;

    batch.insert('accounts', {
      'id': 'acc_cash',
      'name': 'Cash Wallet',
      'type': 'Cash',
      'balance': 350.0,
      'opening_balance': 350.0,
      'credit_limit': 0.0,
      'currency': 'USD',
      'color_value': 0xFF10B981,
      'is_active': 1,
      'updated_at': nowTime,
      'initial_principal': 350.0,
    });

    batch.insert('accounts', {
      'id': 'acc_checking',
      'name': 'Main Checking',
      'type': 'Checking',
      'balance': 2500.0,
      'opening_balance': 2500.0,
      'credit_limit': 0.0,
      'currency': 'USD',
      'color_value': 0xFF2563EB,
      'is_active': 1,
      'updated_at': nowTime,
      'initial_principal': 2500.0,
    });

    batch.insert('accounts', {
      'id': 'acc_credit',
      'name': 'Sapphire Credit Card',
      'type': 'Credit Card',
      'balance': 0.0,
      'opening_balance': 0.0,
      'credit_limit': 5000.0,
      'currency': 'USD',
      'color_value': 0xFFEC4899,
      'is_active': 1,
      'updated_at': nowTime,
      'initial_principal': 0.0,
    });

    batch.insert('accounts', {
      'id': 'acc_savings',
      'name': 'High-Yield Savings',
      'type': 'Savings',
      'balance': 7500.0,
      'opening_balance': 7500.0,
      'credit_limit': 0.0,
      'currency': 'USD',
      'color_value': 0xFF8B5CF6,
      'is_active': 1,
      'updated_at': nowTime,
      'initial_principal': 7500.0,
    });

    // Default Initial Ledger Transactions for Seeded Accounts
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final month = DateTime.now().month;
    final year = DateTime.now().year;

    batch.insert('transactions', {
      'title': 'Initial Balance - Cash Wallet',
      'amount': 350.0,
      'date': nowMs - 86400000,
      'month': month,
      'year': year,
      'category': 'Salary & Income',
      'type': 1, // Income
      'account_id': 'acc_cash',
      'account_name': 'Cash Wallet',
      'payment_method': 'Cash',
      'notes': 'Opening balance transaction',
      'currency': 'USD',
      'status': 'cleared',
    });

    batch.insert('transactions', {
      'title': 'Initial Balance - Main Checking',
      'amount': 2500.0,
      'date': nowMs - 86400000,
      'month': month,
      'year': year,
      'category': 'Salary & Income',
      'type': 1, // Income
      'account_id': 'acc_checking',
      'account_name': 'Main Checking',
      'payment_method': 'Direct Deposit',
      'notes': 'Opening balance transaction',
      'currency': 'USD',
      'status': 'cleared',
    });

    batch.insert('transactions', {
      'title': 'Initial Balance - High-Yield Savings',
      'amount': 7500.0,
      'date': nowMs - 86400000,
      'month': month,
      'year': year,
      'category': 'Salary & Income',
      'type': 1, // Income
      'account_id': 'acc_savings',
      'account_name': 'High-Yield Savings',
      'payment_method': 'Bank Transfer',
      'notes': 'Opening balance transaction',
      'currency': 'USD',
      'status': 'cleared',
    });

    // Parent System Categories
    final defaultParentCats = [
      {'id': 'cat_food', 'name': 'Food & Dining', 'type': 0, 'icon': 0xe25a, 'color': 0xFFDC2626},
      {'id': 'cat_transport', 'name': 'Transportation', 'type': 0, 'icon': 0xe1d5, 'color': 0xFFF59E0B},
      {'id': 'cat_utilities', 'name': 'Bills & Utilities', 'type': 0, 'icon': 0xe57d, 'color': 0xFF8B5CF6},
      {'id': 'cat_housing', 'name': 'Housing & Rent', 'type': 0, 'icon': 0xe318, 'color': 0xFF10B981},
      {'id': 'cat_shopping', 'name': 'Shopping', 'type': 0, 'icon': 0xe59c, 'color': 0xFFEC4899},
      {'id': 'cat_entertainment', 'name': 'Entertainment', 'type': 0, 'icon': 0xe40f, 'color': 0xFF06B6D4},
      {'id': 'cat_salary', 'name': 'Salary & Income', 'type': 1, 'icon': 0xe000, 'color': 0xFF059669},
      {'id': 'cat_investments', 'name': 'Investments', 'type': 1, 'icon': 0xe850, 'color': 0xFF6366F1},
    ];

    for (final cat in defaultParentCats) {
      batch.insert('categories', {
        'id': cat['id'],
        'name': cat['name'],
        'type': cat['type'],
        'icon_code': cat['icon'],
        'color_value': cat['color'],
        'parent_id': null,
        'is_favorite': 1,
        'is_hidden': 0,
        'is_archived': 0,
        'sort_order': 0,
        'description': 'Parent system category',
      });
    }

    // Sub-Categories
    final defaultSubCats = [
      {'id': 'sub_groceries', 'parent_id': 'cat_food', 'name': 'Groceries', 'type': 0, 'icon': 0xe59c, 'color': 0xFFDC2626},
      {'id': 'sub_restaurants', 'parent_id': 'cat_food', 'name': 'Restaurants', 'type': 0, 'icon': 0xe25a, 'color': 0xFFDC2626},
      {'id': 'sub_coffee', 'parent_id': 'cat_food', 'name': 'Coffee & Cafe', 'type': 0, 'icon': 0xe25a, 'color': 0xFFDC2626},
      {'id': 'sub_fuel', 'parent_id': 'cat_transport', 'name': 'Fuel & Gas', 'type': 0, 'icon': 0xe1d5, 'color': 0xFFF59E0B},
      {'id': 'sub_rideshare', 'parent_id': 'cat_transport', 'name': 'Uber & Taxi', 'type': 0, 'icon': 0xe1d5, 'color': 0xFFF59E0B},
    ];

    for (final sub in defaultSubCats) {
      batch.insert('categories', {
        'id': sub['id'],
        'name': sub['name'],
        'type': sub['type'],
        'icon_code': sub['icon'],
        'color_value': sub['color'],
        'parent_id': sub['parent_id'],
        'is_favorite': 0,
        'is_hidden': 0,
        'is_archived': 0,
        'sort_order': 0,
        'description': 'Sub-category',
      });
    }

    // Default Budgets
    batch.insert('budgets', {
      'id': 'bgt_food',
      'name': 'Food & Dining',
      'category_id': 'cat_food',
      'category_name': 'Food & Dining',
      'amount_limit': 650.0,
      'envelope_allocated': 650.0,
      'carry_forward': 1,
      'period_type': 'Monthly',
      'alert_threshold': 0.8,
      'is_active': 1,
      'month': DateTime.now().month,
      'year': DateTime.now().year,
    });

    batch.insert('budgets', {
      'id': 'bgt_transport',
      'name': 'Transportation',
      'category_id': 'cat_transport',
      'category_name': 'Transportation',
      'amount_limit': 300.0,
      'envelope_allocated': 300.0,
      'carry_forward': 0,
      'period_type': 'Monthly',
      'alert_threshold': 0.8,
      'is_active': 1,
      'month': DateTime.now().month,
      'year': DateTime.now().year,
    });

    // Default Goals
    batch.insert('goals', {
      'id': 'goal_emergency',
      'title': 'Emergency Reserve',
      'target_amount': 10000.0,
      'current_amount': 7500.0,
      'target_date': DateTime.now().add(const Duration(days: 180)).millisecondsSinceEpoch,
      'category': 'Savings',
      'account_id': 'acc_savings',
      'is_completed': 0,
    });

    batch.insert('goals', {
      'id': 'goal_vacation',
      'title': 'Japan Summer Trip',
      'target_amount': 3500.0,
      'current_amount': 1800.0,
      'target_date': DateTime.now().add(const Duration(days: 120)).millisecondsSinceEpoch,
      'category': 'Travel',
      'account_id': 'acc_savings',
      'is_completed': 0,
    });

    await batch.commit(noResult: true);
  }

  // --- AUDIT LOGGING ENGINE ---

  Future<void> logAudit(
    String entityType,
    String entityId,
    String action, {
    String? oldValue,
    String? newValue,
  }) async {
    try {
      final db = await database;
      await db.insert('audit_logs', {
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'old_value': oldValue,
        'new_value': newValue,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAuditLogs(String entityType, String entityId) async {
    final db = await database;
    return await db.query(
      'audit_logs',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'timestamp DESC',
    );
  }

  // --- MASTER LEDGER CRUD & ENTERPRISE FILTERED AGGREGATIONS ---

  /// Ledger type codes (root model).
  /// 0 Expense · 1 Income · 2 Self-transfer (always two legs: out + in)
  static const int ledgerExpense = 0;
  static const int ledgerIncome = 1;
  static const int ledgerTransfer = 2;

  static const String transferOutMethod = 'Transfer Out';
  static const String transferInMethod = 'Transfer In';

  /// Balance delta for a single ledger row.
  /// Self-transfer must be two rows: out (−) and in (+). Never one row alone.
  static double ledgerBalanceDelta(Map<String, dynamic> row) {
    final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
    final type = row['type'] as int? ?? ledgerExpense;
    if (type == ledgerIncome) return amount;
    if (type == ledgerTransfer) {
      final method = row['payment_method'] as String? ?? '';
      if (method == transferInMethod) return amount;
      return -amount; // Transfer Out (default for type 2)
    }
    return -amount; // expense / other debit types
  }

  /// Creates a self-transfer as two linked ledger entries:
  /// 1) remove from [fromAccountId]  2) add to [toAccountId]
  /// Does not affect income/expense totals (type = 2).
  Future<Map<String, dynamic>> createSelfTransfer({
    required String fromAccountId,
    required String fromAccountName,
    required String toAccountId,
    required String toAccountName,
    required double amount,
    String? title,
    int? dateMilliseconds,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero.');
    }
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Source and destination accounts must differ.');
    }

    final db = await database;
    final dateMs = dateMilliseconds ?? DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final transferId = 'xfer_${dateMs}_${fromAccountId}_$toAccountId';
    final baseTitle = title?.trim().isNotEmpty == true ? title!.trim() : 'Self Transfer';
    final sharedNotes = notes ?? 'Self transfer $transferId';

    late final int outId;
    late final int inId;

    await db.transaction((txn) async {
      final outRow = <String, dynamic>{
        'title': '$baseTitle → $toAccountName',
        'amount': amount,
        'date': dateMs,
        'month': dt.month,
        'year': dt.year,
        'category': 'Transfer',
        'type': ledgerTransfer,
        'account_id': fromAccountId,
        'account_name': fromAccountName,
        'payment_method': transferOutMethod,
        'notes': sharedNotes,
        'reference_number': transferId,
        'status': 'cleared',
      };

      final inRow = <String, dynamic>{
        'title': '$baseTitle ← $fromAccountName',
        'amount': amount,
        'date': dateMs,
        'month': dt.month,
        'year': dt.year,
        'category': 'Transfer',
        'type': ledgerTransfer,
        'account_id': toAccountId,
        'account_name': toAccountName,
        'payment_method': transferInMethod,
        'notes': sharedNotes,
        'reference_number': transferId,
        'status': 'cleared',
      };

      outId = await txn.insert('transactions', outRow);
      inId = await txn.insert('transactions', inRow);

      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
        [ledgerBalanceDelta(outRow), dateMs, fromAccountId],
      );
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
        [ledgerBalanceDelta(inRow), dateMs, toAccountId],
      );
    });

    await logAudit(
      'transfer',
      transferId,
      'created',
      newValue:
          '$baseTitle • \$${amount.toStringAsFixed(2)} • $fromAccountName → $toAccountName (out=$outId, in=$inId)',
    );

    await _persistAndNotify();
    return {
      'transfer_id': transferId,
      'out_id': outId,
      'in_id': inId,
      'amount': amount,
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
    };
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final type = row['type'] as int? ?? ledgerExpense;
    if (type == ledgerTransfer) {
      throw StateError(
        'Self-transfer requires two ledger legs. Use createSelfTransfer() instead of insertTransaction().',
      );
    }

    final db = await database;
    final dateMs = row['date'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(dateMs);

    final map = Map<String, dynamic>.from(row);
    map['date'] = dateMs;
    map['month'] = map['month'] ?? dt.month;
    map['year'] = map['year'] ?? dt.year;

    final accountId = map['account_id'] as String? ?? 'acc_cash';
    final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final double delta = ledgerBalanceDelta(map);

    final id = await db.insert(
      'transactions',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [delta, accountId],
    );

    await logAudit(
      'transaction',
      '$id',
      'created',
      newValue: '${map['title']} • ${type == ledgerIncome ? "+" : "-"}\$${amount.toStringAsFixed(2)} (${map['category']})',
    );

    await _persistAndNotify();
    return id;
  }

  Future<int> updateTransaction(Map<String, dynamic> row) async {
    final db = await database;
    final id = row['id'] as int;

    final oldRows = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (oldRows.isEmpty) return 0;
    final oldRow = oldRows.first;

    if ((oldRow['type'] as int? ?? 0) == ledgerTransfer ||
        (row['type'] as int? ?? 0) == ledgerTransfer) {
      throw StateError(
        'Self-transfer legs cannot be updated individually. Delete the pair and create a new transfer.',
      );
    }

    final oldAccountId = oldRow['account_id'] as String? ?? 'acc_cash';
    final oldAmount = (oldRow['amount'] as num?)?.toDouble() ?? 0.0;
    final oldType = oldRow['type'] as int? ?? 0;
    final double oldDelta = ledgerBalanceDelta(oldRow);

    await db.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [oldDelta, oldAccountId]);

    final int dateMs = (row['date'] as int?) ?? (oldRow['date'] as int? ?? DateTime.now().millisecondsSinceEpoch);
    final dt = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final map = Map<String, dynamic>.from(row);
    map['date'] = dateMs;
    map['month'] = dt.month;
    map['year'] = dt.year;

    final newAccountId = map['account_id'] as String? ?? 'acc_cash';
    final newAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final newType = map['type'] as int? ?? 0;
    final double newDelta = ledgerBalanceDelta(map);

    await db.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [newDelta, newAccountId]);

    final count = await db.update('transactions', map, where: 'id = ?', whereArgs: [id]);

    final String oldSummary = '${oldRow['title']} • ${oldType == ledgerIncome ? "+" : "-"}\$${oldAmount.toStringAsFixed(2)} (${oldRow['category']})';
    final String newSummary = '${map['title']} • ${newType == ledgerIncome ? "+" : "-"}\$${newAmount.toStringAsFixed(2)} (${map['category']})';

    await logAudit('transaction', '$id', 'updated', oldValue: oldSummary, newValue: newSummary);

    await _persistAndNotify();
    return count;
  }

  Future<Map<String, dynamic>> getAccountAnalytics(String accountId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 1 THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 0 THEN amount ELSE 0 END) AS total_expense,
        COUNT(*) AS tx_count
      FROM transactions
      WHERE account_id = ?
    ''', [accountId]);

    if (result.isNotEmpty) {
      final row = result.first;
      final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      final count = (row['tx_count'] as num?)?.toInt() ?? 0;
      return {
        'income': income,
        'expense': expense,
        'net': income - expense,
        'count': count,
      };
    }
    return {'income': 0.0, 'expense': 0.0, 'net': 0.0, 'count': 0};
  }

  Future<List<Map<String, dynamic>>> getTransactionsForAccount(String accountId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getFilteredTransactions(
    GlobalFilterState filter, {
    required int limit,
    required int offset,
    int? activeYear,
    int? activeMonth,
  }) async {
    final db = await database;
    final query = FilterQueryBuilder.buildQuery(filter, activeYear: activeYear, activeMonth: activeMonth);

    return await db.query(
      'transactions',
      where: query.whereClause,
      whereArgs: query.whereArgs,
      orderBy: query.orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, double>> getFilteredSummaryTotals(
    GlobalFilterState filter, {
    int? activeYear,
    int? activeMonth,
  }) async {
    final db = await database;
    final query = FilterQueryBuilder.buildQuery(filter, activeYear: activeYear, activeMonth: activeMonth);

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 1 THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 0 THEN amount ELSE 0 END) AS total_expense,
        AVG(CASE WHEN type = 0 THEN amount ELSE NULL END) AS avg_tx,
        MAX(CASE WHEN type = 0 THEN amount ELSE 0 END) AS max_tx,
        COUNT(*) AS tx_count
      FROM transactions
      WHERE ${query.whereClause}
    ''', query.whereArgs);

    if (result.isNotEmpty) {
      final row = result.first;
      final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      final avg = (row['avg_tx'] as num?)?.toDouble() ?? 0.0;
      final max = (row['max_tx'] as num?)?.toDouble() ?? 0.0;
      final count = (row['tx_count'] as num?)?.toDouble() ?? 0.0;
      return {
        'income': income,
        'expense': expense,
        'avg': avg,
        'max': max,
        'count': count,
      };
    }
    return {'income': 0.0, 'expense': 0.0, 'avg': 0.0, 'max': 0.0, 'count': 0.0};
  }

  Future<List<Map<String, dynamic>>> getTransactionsPaginated({
    required int limit,
    required int offset,
  }) async {
    final db = await database;
    return await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByMonth({
    required int year,
    required int month,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, double>> getSummaryTotalsByMonth(int year, int month) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 1 THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 0 THEN amount ELSE 0 END) AS total_expense,
        AVG(CASE WHEN type = 0 THEN amount ELSE NULL END) AS avg_tx,
        MAX(CASE WHEN type = 0 THEN amount ELSE 0 END) AS max_tx,
        COUNT(*) AS tx_count
      FROM transactions
      WHERE year = ? AND month = ?
    ''', [year, month]);

    if (result.isNotEmpty) {
      final row = result.first;
      final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      final avg = (row['avg_tx'] as num?)?.toDouble() ?? 0.0;
      final max = (row['max_tx'] as num?)?.toDouble() ?? 0.0;
      final count = (row['tx_count'] as num?)?.toDouble() ?? 0.0;
      return {
        'income': income,
        'expense': expense,
        'avg': avg,
        'max': max,
        'count': count,
      };
    }
    return {'income': 0.0, 'expense': 0.0, 'avg': 0.0, 'max': 0.0, 'count': 0.0};
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdownByMonth(int year, int month) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM transactions
      WHERE type = 0 AND year = ? AND month = ?
      GROUP BY category
      ORDER BY total DESC
      LIMIT 10;
    ''', [year, month]);
  }

  Future<List<Map<String, dynamic>>> getMerchantBreakdownByMonth(int year, int month) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT title AS merchant, SUM(amount) AS total, COUNT(*) AS visit_count
      FROM transactions
      WHERE type = 0 AND year = ? AND month = ?
      GROUP BY title
      ORDER BY total DESC
      LIMIT 1;
    ''', [year, month]);
  }

  Future<Map<String, double>> getQuarterTotals(int year, int quarter) async {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = startMonth + 2;

    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 1 THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 0 THEN amount ELSE 0 END) AS total_expense
      FROM transactions
      WHERE year = ? AND month >= ? AND month <= ?
    ''', [year, startMonth, endMonth]);

    if (result.isNotEmpty) {
      final row = result.first;
      final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      return {'income': income, 'expense': expense};
    }
    return {'income': 0.0, 'expense': 0.0};
  }

  Future<Map<String, double>> getAnnualTotals(int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 1 THEN amount ELSE 0 END) AS total_income,
        SUM(CASE WHEN type = 0 THEN amount ELSE 0 END) AS total_expense
      FROM transactions
      WHERE year = ?
    ''', [year]);

    if (result.isNotEmpty) {
      final row = result.first;
      final income = (row['total_income'] as num?)?.toDouble() ?? 0.0;
      final expense = (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      return {'income': income, 'expense': expense};
    }
    return {'income': 0.0, 'expense': 0.0};
  }

  Future<Map<String, double>> getNetWorthMetrics() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN balance > 0 THEN balance ELSE 0 END) AS total_assets,
        SUM(CASE WHEN balance < 0 THEN ABS(balance) ELSE 0 END) AS total_liabilities
      FROM accounts
      WHERE is_active = 1
    ''');

    if (result.isNotEmpty) {
      final row = result.first;
      final assets = (row['total_assets'] as num?)?.toDouble() ?? 0.0;
      final liabilities = (row['total_liabilities'] as num?)?.toDouble() ?? 0.0;
      return {'assets': assets, 'liabilities': liabilities, 'net_worth': assets - liabilities};
    }
    return {'assets': 0.0, 'liabilities': 0.0, 'net_worth': 0.0};
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return 0;

    final row = rows.first;
    final type = row['type'] as int? ?? ledgerExpense;

    // Self-transfer: delete both linked legs and revert both balances.
    if (type == ledgerTransfer) {
      final transferId = row['reference_number'] as String?;
      if (transferId != null && transferId.isNotEmpty) {
        return deleteSelfTransfer(transferId);
      }
    }

    final accountId = row['account_id'] as String? ?? 'acc_cash';
    final double applied = ledgerBalanceDelta(row);
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance - ? WHERE id = ?',
      [applied, accountId],
    );
    final res = await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await _persistAndNotify();
    return res;
  }

  /// Deletes both legs of a self-transfer and reverts both account balances.
  Future<int> deleteSelfTransfer(String transferId) async {
    final db = await database;
    final legs = await db.query(
      'transactions',
      where: 'type = ? AND reference_number = ?',
      whereArgs: [ledgerTransfer, transferId],
    );
    if (legs.isEmpty) return 0;

    await db.transaction((txn) async {
      for (final leg in legs) {
        final accountId = leg['account_id'] as String? ?? 'acc_cash';
        final applied = ledgerBalanceDelta(leg);
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [applied, accountId],
        );
        await txn.delete('transactions', where: 'id = ?', whereArgs: [leg['id']]);
      }
    });

    await logAudit('transfer', transferId, 'deleted');
    await _persistAndNotify();
    return legs.length;
  }

  // --- CATEGORIES CRUD ---

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', where: 'is_archived = 0', orderBy: 'sort_order ASC, name ASC');
  }

  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('categories', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _persistAndNotify();
    return id;
  }

  Future<Set<String>> getUsedCategoryNames() async {
    final db = await database;
    final result = await db.rawQuery("SELECT DISTINCT category FROM transactions WHERE category IS NOT NULL AND category != ''");
    return result.map((r) => (r['category'] as String).trim().toLowerCase()).toSet();
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    // Soft delete parent category AND any child sub-categories with parent_id == id
    final count = await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ? OR parent_id = ?',
      whereArgs: [id, id],
    );
    await _persistAndNotify();
    return count;
  }

  // --- ACCOUNTS CRUD ---

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await database;
    return await db.query('accounts', where: 'is_active = 1');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('accounts', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _persistAndNotify();
    return id;
  }

  // --- BUDGETS & GOALS CRUD ---

  Future<List<Map<String, dynamic>>> getBudgetsForMonth(int year, int month) async {
    final db = await database;
    return await db.query('budgets');
  }

  Future<int> insertBudget(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('budgets', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _persistAndNotify();
    return id;
  }

  Future<List<Map<String, dynamic>>> getAllGoals() async {
    final db = await database;
    return await db.query('goals');
  }

  Future<int> insertGoal(Map<String, dynamic> row) async {
    final db = await database;
    final id = await db.insert('goals', row, conflictAlgorithm: ConflictAlgorithm.replace);
    await _persistAndNotify();
    return id;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('accounts');
    await db.delete('budgets');
    await db.delete('goals');
    await db.delete('budget_history');
    await db.execute('VACUUM;');
    await _persistAndNotify();
  }

  Future<void> _seedFundingAccountsIfMissing(Database db) async {
    final nowTime = DateTime.now().millisecondsSinceEpoch;

    final accountsToEnsure = [
      {
        'id': 'acc_wife',
        'name': 'Wife Wallet',
        'type': 'Checking',
        'balance': 1500.0,
        'opening_balance': 1500.0,
        'credit_limit': 0.0,
        'currency': 'USD',
        'color_value': 0xFFF43F5E,
        'is_active': 1,
        'updated_at': nowTime,
        'initial_principal': 1500.0,
      },
      {
        'id': 'acc_son',
        'name': 'Son Wallet',
        'type': 'Savings',
        'balance': 500.0,
        'opening_balance': 500.0,
        'credit_limit': 0.0,
        'currency': 'USD',
        'color_value': 0xFF0EA5E9,
        'is_active': 1,
        'updated_at': nowTime,
        'initial_principal': 500.0,
      },
      {
        'id': 'acc_daughter',
        'name': 'Daughter Wallet',
        'type': 'Savings',
        'balance': 500.0,
        'opening_balance': 500.0,
        'credit_limit': 0.0,
        'currency': 'USD',
        'color_value': 0xFFA855F7,
        'is_active': 1,
        'updated_at': nowTime,
        'initial_principal': 500.0,
      },
      {
        'id': 'acc_investment',
        'name': 'Investment Portfolio',
        'type': 'Investment',
        'balance': 10000.0,
        'opening_balance': 10000.0,
        'credit_limit': 0.0,
        'currency': 'USD',
        'color_value': 0xFF10B981,
        'is_active': 1,
        'updated_at': nowTime,
        'initial_principal': 10000.0,
      },
      {
        'id': 'acc_emergency',
        'name': 'Emergency Reserve',
        'type': 'Savings',
        'balance': 5000.0,
        'opening_balance': 5000.0,
        'credit_limit': 0.0,
        'currency': 'USD',
        'color_value': 0xFFEAB308,
        'is_active': 1,
        'updated_at': nowTime,
        'initial_principal': 5000.0,
      },
    ];

    for (final acc in accountsToEnsure) {
      final existing = await db.query('accounts', where: 'id = ?', whereArgs: [acc['id']]);
      if (existing.isEmpty) {
        await db.insert('accounts', acc);
      }
    }
  }

  // --- BUDGET HISTORY CRUD ---

  Future<int> insertBudgetHistory(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('budget_history', row);
  }

  Future<List<Map<String, dynamic>>> getBudgetHistory({
    String? periodType,
    String? periodKey,
    String? categoryId,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (periodType != null) {
      whereClauses.add('period_type = ?');
      whereArgs.add(periodType);
    }
    if (periodKey != null) {
      whereClauses.add('period_key = ?');
      whereArgs.add(periodKey);
    }
    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    final whereStr = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    return await db.query('budget_history', where: whereStr, whereArgs: whereArgs, orderBy: 'created_at DESC');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
