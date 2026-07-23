import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../core/theme/app_theme.dart';
import '../features/accounts/application/accounts_controller.dart';
import '../features/accounts/data/datasources/account_dao.dart';
import '../features/accounts/data/repositories/account_repository_impl.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/budgets/application/budgets_controller.dart';
import '../features/budgets/data/datasources/budget_dao.dart';
import '../features/budgets/presentation/screens/budgets_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/presentation/transactions_screen.dart';

class CommercialBudgetApp extends StatefulWidget {
  const CommercialBudgetApp({super.key});

  @override
  State<CommercialBudgetApp> createState() => _CommercialBudgetAppState();
}

class _CommercialBudgetAppState extends State<CommercialBudgetApp> {
  int _currentIndex = 0;

  late final TransactionRepository _transactionRepository;
  late final AccountsController _accountsController;
  late final BudgetsController _budgetsController;

  @override
  void initState() {
    super.initState();
    final db = AppDatabase.instance;
    _transactionRepository = TransactionRepository();

    final accountDao = AccountDao(db);
    final accountRepo = AccountRepositoryImpl(accountDao);
    _accountsController = AccountsController(accountRepo);

    final budgetDao = BudgetDao(db);
    _budgetsController = BudgetsController(budgetDao);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Lite Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            TransactionsScreen(repository: _transactionRepository),
            AccountsScreen(controller: _accountsController),
            BudgetsScreen(controller: _budgetsController),
            const AnalyticsScreen(),
            SettingsScreen(repository: _transactionRepository),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardBg,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Ledger'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Accounts'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline_rounded), label: 'Budgets'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
