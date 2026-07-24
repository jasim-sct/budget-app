import 'package:flutter/material.dart';
import '../core/database/app_database.dart';
import '../core/database/database_helper.dart';
import '../core/services/currency_provider.dart';
import '../core/services/user_profile_provider.dart';
import '../features/categories/data/category_repository.dart';
import '../core/services/financial_calculation_engine.dart';
import '../core/services/financial_sync_service.dart';
import '../core/services/pin_auth_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/context_action_bar.dart';
import '../core/widgets/feedback_toast.dart';
import '../core/widgets/glass/glass_bottom_bar.dart';
import '../features/accounts/application/accounts_controller.dart';
import '../features/accounts/data/datasources/account_dao.dart';
import '../features/accounts/data/repositories/account_repository_impl.dart';
import '../features/accounts/presentation/modals/add_account_modal.dart';
import '../features/accounts/presentation/screens/accounts_screen.dart';
import '../features/authentication/presentation/screens/pin_lock_screen.dart';
import '../features/authentication/presentation/screens/splash_screen.dart';
import '../features/budgets/application/budgets_controller.dart';
import '../features/budgets/data/datasources/budget_dao.dart';
import '../features/budgets/domain/models/budget_period.dart';
import '../features/budgets/presentation/screens/budgets_screen.dart';
import '../features/budgets/presentation/widgets/add_budget_bottom_sheet.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/goals/presentation/add_goal_dialog.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/domain/transaction_model.dart';
import '../features/transactions/presentation/add_transaction_dialog.dart';
import '../features/transactions/presentation/transactions_screen.dart';

class CommercialBudgetApp extends StatelessWidget {
  const CommercialBudgetApp({super.key});

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
              home: const _MainAppShell(),
            );
          },
        );
      },
    );
  }
}

class _MainAppShell extends StatefulWidget {
  const _MainAppShell();

  @override
  State<_MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<_MainAppShell> {
  bool _showSplash = true;
  bool _requirePinUnlock = false;
  String? _storedPin;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

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

    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    await ThemeProvider.instance.loadSavedTheme();
    await CurrencyProvider.instance.loadSavedCurrency();
    await UserProfileProvider.instance.loadSavedName();
    // Collapse any historical duplicate categories/budgets at startup so they
    // never surface, regardless of which screen the user opens first.
    await CategoryRepository.instance.loadCategories();
    await DatabaseHelper.instance.dedupeActiveBudgetsByCategory();
  }

  void _goToTab(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onSplashComplete() async {
    String? pin;
    try {
      pin = await PinAuthService.instance.getPin();
    } catch (_) {
      // Never trap the user on the splash screen if storage fails —
      // proceed without a PIN requirement.
      pin = null;
    }
    if (!mounted) return;
    setState(() {
      _showSplash = false;
      _storedPin = pin;
      _requirePinUnlock = pin != null && pin.length == 4;
    });
  }

  // ── Action Handlers ──

  void _openAddTransactionModal({bool isIncome = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(
        initialType: isIncome ? TransactionType.income : TransactionType.expense,
        onSubmit: (tx) async {
          await _transactionRepository.addTransaction(tx);
          await FinancialSyncService.instance.persistAndNotify();
          await FinancialCalculationEngine.instance.recalculate();
        },
      ),
    );
  }

  void _openAddBudgetModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBudgetBottomSheet(
        initialPeriod: BudgetPeriodType.monthly,
        onSubmit: (budget) async {
          await _budgetsController.saveBudget(budget);
          FeedbackToast.show(
            context,
            message: 'Budget allocated for ${budget.name}.',
            isSuccess: true,
          );
        },
      ),
    );
  }

  void _openAddWalletModal() {
    AddAccountModal.show(
      context,
      onSaved: (acc) async {
        await _accountsController.loadAccounts();
      },
    );
  }

  void _openAddGoalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalDialog(),
    );
  }

  // ── Context-Aware Actions per Screen ──

  List<ContextActionItem> _getActionsForScreen(int index) {
    switch (index) {
      case 0: // Home
        return [
          ContextActionItem(
            label: 'Log Expense',
            icon: Icons.remove_rounded,
            onTap: _openAddTransactionModal,
            isPrimary: true,
          ),
          ContextActionItem(
            label: 'Log Income',
            icon: Icons.add_rounded,
            onTap: () => _openAddTransactionModal(isIncome: true),
          ),
        ];
      case 1: // Activity
        return [
          ContextActionItem(
            label: 'Log Transaction',
            icon: Icons.add_rounded,
            onTap: _openAddTransactionModal,
            isPrimary: true,
          ),
        ];
      case 2: // Plan
        return [
          ContextActionItem(
            label: 'New Budget',
            icon: Icons.add_rounded,
            onTap: _openAddBudgetModal,
            isPrimary: true,
          ),
          ContextActionItem(
            label: 'Savings Goal',
            icon: Icons.flag_outlined,
            onTap: _openAddGoalModal,
          ),
        ];
      case 3: // Money
        return [
          ContextActionItem(
            label: 'Add Account',
            icon: Icons.add_rounded,
            onTap: _openAddWalletModal,
            isPrimary: true,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onSplashComplete: () {
          _onSplashComplete();
        },
      );
    }

    if (_requirePinUnlock) {
      return PinLockScreen(
        mode: PinLockMode.unlock,
        correctPin: _storedPin,
        onSuccess: () {
          setState(() {
            _requirePinUnlock = false;
          });
        },
      );
    }

    return Scaffold(
      extendBody: false,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          _KeepAlivePage(
            child: DashboardScreen(
              repository: _transactionRepository,
              onNavigateToLedger: () => _goToTab(1),
              onNavigateToWallets: () => _goToTab(3),
              onNavigateToBudgets: () => _goToTab(2),
              onNavigateToAnalytics: () => _goToTab(2),
            ),
          ),
          _KeepAlivePage(child: TransactionsScreen(repository: _transactionRepository)),
          _KeepAlivePage(child: BudgetsScreen(controller: _budgetsController)),
          _KeepAlivePage(child: AccountsScreen(controller: _accountsController)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContextActionBar(actions: _getActionsForScreen(_currentIndex)),
          GlassBottomBar(
            currentIndex: _currentIndex,
            onTap: _goToTab,
            items: const [
              NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Activity',
              ),
              NavItem(
                icon: Icons.pie_chart_outline_rounded,
                activeIcon: Icons.pie_chart_rounded,
                label: 'Plan',
              ),
              NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Money',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps a PageView child alive when swiped off-screen so tab state
/// (scroll position, controllers) survives horizontal navigation.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
