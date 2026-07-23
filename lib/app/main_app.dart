import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../core/services/currency_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/glass/glass_bottom_bar.dart';
import '../features/accounts/application/accounts_controller.dart';
import '../features/accounts/data/datasources/account_dao.dart';
import '../features/accounts/data/repositories/account_repository_impl.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../features/budgets/application/budgets_controller.dart';
import '../features/budgets/data/datasources/budget_dao.dart';
import '../features/budgets/presentation/screens/budgets_screen.dart';
import '../features/onboarding/presentation/widgets/walkthrough_story_banner.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/presentation/transactions_screen.dart';

class CommercialBudgetApp extends StatefulWidget {
  const CommercialBudgetApp({super.key});

  @override
  State<CommercialBudgetApp> createState() => _CommercialBudgetAppState();
}

class _CommercialBudgetAppState extends State<CommercialBudgetApp> {
  bool _showSplash = true;
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

    CurrencyProvider.instance.loadSavedCurrency();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.instance,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<CurrencyOption>(
          valueListenable: CurrencyProvider.instance,
          builder: (context, currency, _) {
            return MaterialApp(
              title: 'MJSM',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: _showSplash
                  ? SplashScreen(
                      onSplashComplete: () {
                        setState(() {
                          _showSplash = false;
                        });
                      },
                    )
                  : Scaffold(
                      extendBody: false,
                      body: Stack(
                        children: [
                          IndexedStack(
                            index: _currentIndex,
                            children: [
                              TransactionsScreen(repository: _transactionRepository),
                              AccountsScreen(controller: _accountsController),
                              BudgetsScreen(controller: _budgetsController),
                              const AnalyticsScreen(),
                              SettingsScreen(repository: _transactionRepository),
                            ],
                          ),
                          WalkthroughStoryBanner(
                            onNavigateToWallets: () => setState(() => _currentIndex = 1),
                            onNavigateToAnalytics: () => setState(() => _currentIndex = 3),
                          ),
                        ],
                      ),
                      bottomNavigationBar: GlassBottomBar(
                        currentIndex: _currentIndex,
                        onTap: (index) => setState(() => _currentIndex = index),
                        items: const [
                          NavItem(
                            icon: Icons.receipt_long_outlined,
                            activeIcon: Icons.receipt_long_rounded,
                            label: 'Ledger',
                          ),
                          NavItem(
                            icon: Icons.account_balance_wallet_outlined,
                            activeIcon: Icons.account_balance_wallet_rounded,
                            label: 'Wallets',
                          ),
                          NavItem(
                            icon: Icons.pie_chart_outline_rounded,
                            activeIcon: Icons.pie_chart_rounded,
                            label: 'Budgets',
                          ),
                          NavItem(
                            icon: Icons.bar_chart_outlined,
                            activeIcon: Icons.bar_chart_rounded,
                            label: 'Analytics',
                          ),
                          NavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Profile',
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
