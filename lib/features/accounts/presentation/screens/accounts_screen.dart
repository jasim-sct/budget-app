import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../../../core/widgets/glass/glass_button.dart';
import '../../../../core/widgets/glass/glass_card.dart';
import '../../../../core/widgets/glass/glass_input.dart';
import '../../application/accounts_controller.dart';
import '../../domain/models/account_model.dart';

/// VisionOS Frosted Glass Wallets & Accounts Screen.
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
  @override
  void initState() {
    super.initState();
    widget.controller.loadAccounts();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Glass Wallet or Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: nameController,
                    label: 'ACCOUNT NAME',
                    hint: 'e.g. Chase Bank, Cash Wallet',
                    prefixIcon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GlassInput(
                    controller: balanceController,
                    label: 'INITIAL BALANCE',
                    hint: '0.00',
                    isCurrency: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('ACCOUNT TYPE', style: AppTypography.labelSmall(isDark)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AccountType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type.name.toUpperCase()),
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        onSelected: (_) => setModalState(() => selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassButton(
                    label: 'Save Glass Account',
                    variant: GlassButtonVariant.gradient,
                    onPressed: () {
                      final name = nameController.text.trim();
                      final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
                      if (name.isNotEmpty) {
                        final account = AccountModel(
                          id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          type: selectedType,
                          balance: balance,
                          currency: 'USD',
                          colorValue: 0xFF10B981,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        widget.controller.saveAccount(account);
                        Navigator.pop(bottomContext);
                      }
                    },
                  ),
                ],
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Wallets & Glass Accounts',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller.stateNotifier,
        builder: (context, _) {
          final state = widget.controller.stateNotifier.value;

          if (state.isLoading && state.accounts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryEmerald,
              ),
            );
          }

          if (state.accounts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Glass Accounts Configured',
              description: 'Add your bank accounts, credit cards, or cash wallets to calculate Net Worth.',
              actionLabel: 'Add First Account',
              onActionTap: _showAddAccountModal,
            );
          }

          return Column(
            children: [
              // Glass Net Worth Asset Banner Card
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: GlassCard(
                  gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL ASSETS / NET WORTH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppFormatters.currency(state.totalBalance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined, color: AppColors.primaryEmerald, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${state.accounts.length} Active Glass Accounts Connected',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Colors.transparent),

              // Account Glass List
              Expanded(
                child: ListView.builder(
                  itemCount: state.accounts.length,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final acc = state.accounts[index];
                    final IconData icon = _getAccountIcon(acc.type);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Color(acc.colorValue).withValues(alpha: 0.15),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(color: Color(acc.colorValue).withValues(alpha: 0.3), width: 1),
                              ),
                              child: Icon(icon, color: Color(acc.colorValue), size: 24),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    acc.type.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.currency(acc.balance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: _showAddAccountModal,
          backgroundColor: AppColors.primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.w800)),
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
      case AccountType.loan:
        return Icons.request_quote_rounded;
      case AccountType.investment:
        return Icons.show_chart_rounded;
    }
  }
}
