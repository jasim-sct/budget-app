import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/accounts_controller.dart';
import '../../domain/models/account_model.dart';

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

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.00');
    AccountType selectedType = AccountType.bank;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Text('Add Account / Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account Name', isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Initial Balance (\$)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                    colorValue: 0xFF2563EB,
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  widget.controller.saveAccount(account);
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      balanceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets & Accounts'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller.stateNotifier,
        builder: (context, _) {
          final state = widget.controller.stateNotifier.value;

          if (state.isLoading && state.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary));
          }

          return Column(
            children: [
              // Total Balance Header Card
              Container(
                width: double.infinity,
                color: AppTheme.cardBg,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NET WORTH / TOTAL ASSETS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.currency(state.totalBalance),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              // Account List
              Expanded(
                child: ListView.builder(
                  itemCount: state.accounts.length,
                  itemExtent: 68.0,
                  itemBuilder: (context, index) {
                    final acc = state.accounts[index];
                    return Container(
                      height: 68.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardBg,
                        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(acc.colorValue).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getAccountIcon(acc.type),
                              color: Color(acc.colorValue),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  acc.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  acc.type.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.currency(acc.balance),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
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
