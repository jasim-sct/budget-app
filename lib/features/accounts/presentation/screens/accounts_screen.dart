import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_metrics.dart';
import '../../../../core/services/financial_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../../transactions/presentation/add_transaction_dialog.dart';
import '../../application/accounts_controller.dart';
import '../../domain/models/account_model.dart';

/// Commercial-Grade Wallets & Accounts Screen.
class AccountsScreen extends StatefulWidget {
  final AccountsController controller;

  const AccountsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const List<AccountType> _allowedWalletTypes = [
    AccountType.bank,
    AccountType.cash,
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.loadAccounts();
    FinancialCalculationEngine.instance.recalculate();
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'BANK';
      case AccountType.cash:
        return 'WALLET';
      default:
        return type.name.toUpperCase();
    }
  }

  void _showAddLedgerModal({String? accountId, TransactionType initialType = TransactionType.income}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionDialog(
        initialAccountId: accountId,
        initialType: initialType,
        onSubmit: (tx) async {
          await DatabaseHelper.instance.insertTransaction(tx.toMap());
          FinancialSyncService.instance.notifyMutation();
          await FinancialCalculationEngine.instance.recalculate();
        },
      ),
    );
  }

  void _showAddAccountModal() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.00');
    AccountType selectedType = AccountType.bank;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        final isDark = Theme.of(bottomContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassBottomSheet(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Wallet or Bank Account',
                      style: AppTypography.headline(isDark),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: nameController,
                      label: 'ACCOUNT NAME',
                      hint: 'e.g. Chase Bank, Main Cash Wallet, Savings Account',
                      prefixIcon: Icons.account_balance_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: balanceController,
                      label: 'INITIAL LEDGER BALANCE',
                      hint: '0.00',
                      isCurrency: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'An opening ledger entry will be recorded automatically for this wallet.',
                      style: AppTypography.caption(isDark),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('WALLET TYPE', style: AppTypography.sectionLabel(isDark)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: _allowedWalletTypes.map((type) {
                        final isSelected = selectedType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: AppChip(
                              label: _getAccountTypeLabel(type),
                              isSelected: isSelected,
                              onTap: () => setModalState(() => selectedType = type),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Save Account',
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final initialBalance = double.tryParse(balanceController.text.trim()) ?? 0.0;

                        if (name.isNotEmpty) {
                          final accountId = 'acc_${DateTime.now().millisecondsSinceEpoch}';
                          final account = AccountModel(
                            id: accountId,
                            name: name,
                            type: selectedType,
                            balance: 0.0,
                            currency: 'USD',
                            colorValue: 0xFF10B981,
                            updatedAt: DateTime.now().millisecondsSinceEpoch,
                          );
                          await widget.controller.saveAccount(account);

                          if (initialBalance != 0) {
                            final initialTx = TransactionModel(
                              title: 'Initial Balance - $name',
                              amount: initialBalance.abs(),
                              dateMilliseconds: DateTime.now().millisecondsSinceEpoch,
                              category: 'Salary & Wages',
                              type: initialBalance >= 0 ? TransactionType.income : TransactionType.expense,
                              accountId: accountId,
                              accountName: name,
                            );
                            await DatabaseHelper.instance.insertTransaction(initialTx.toMap());
                            FinancialSyncService.instance.notifyMutation();
                            await FinancialCalculationEngine.instance.recalculate();
                          }

                          if (bottomContext.mounted) {
                            Navigator.pop(bottomContext);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      balanceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Net Worth'),
      ),
      body: ValueListenableBuilder<FinancialMetrics>(
        valueListenable: FinancialCalculationEngine.instance.metricsNotifier,
        builder: (context, metrics, _) {
          return ListenableBuilder(
            listenable: widget.controller.stateNotifier,
            builder: (context, _) {
              final state = widget.controller.stateNotifier.value;

              if (state.isLoading && state.accounts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.primaryBlue,
                  ),
                );
              }

              if (state.accounts.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No Accounts Configured',
                  description: 'Add your bank accounts or cash wallets to track your Net Worth.',
                  actionLabel: 'Add First Account',
                  onActionTap: _showAddAccountModal,
                );
              }

              return Column(
                children: [
                  // Net Worth & Liabilities Banner Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NET WORTH AGGREGATION',
                            style: AppTypography.sectionLabel(isDark),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppFormatters.currency(metrics.netWorth),
                            style: AppTypography.displayLarge(isDark).copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded, color: AppColors.incomeGreen, size: 14),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Assets: ${AppFormatters.currency(metrics.totalAssets)}',
                                    style: AppTypography.titleMedium(isDark),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded, color: AppColors.expenseRed, size: 14),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Liabilities: ${AppFormatters.currency(metrics.totalLiabilities)}',
                                    style: AppTypography.titleMedium(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Account List
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.accounts.length,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 80),
                      itemBuilder: (context, index) {
                        final acc = state.accounts[index];
                        final IconData icon = _getAccountIcon(acc.type);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(acc.colorValue).withValues(alpha: 0.12),
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: Icon(icon, color: Color(acc.colorValue), size: 20),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc.name,
                                        style: AppTypography.titleLarge(isDark),
                                      ),
                                      Text(
                                        _getAccountTypeLabel(acc.type),
                                        style: AppTypography.labelSmall(isDark),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormatters.currency(acc.balance),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: acc.balance < 0 ? AppColors.expenseRed : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    InkWell(
                                      onTap: () => _showAddLedgerModal(accountId: acc.id),
                                      borderRadius: AppRadius.borderSm,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                          borderRadius: AppRadius.borderSm,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded, size: 12, color: AppColors.primaryBlue),
                                            SizedBox(width: 2),
                                            Text(
                                              'Ledger',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_add_ledger',
              onPressed: () => _showAddLedgerModal(),
              icon: const Icon(Icons.add_card_rounded, size: 20),
              label: const Text('Add Ledger'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FloatingActionButton(
              heroTag: 'fab_add_wallet',
              onPressed: _showAddAccountModal,
              tooltip: 'Add Wallet Account',
              child: const Icon(Icons.account_balance_wallet_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.savings:
        return Icons.savings_rounded;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.investment:
        return Icons.show_chart_rounded;
    }
  }
}
