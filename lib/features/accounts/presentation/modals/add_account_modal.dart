import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/financial_calculation_engine.dart';
import '../../../../core/services/financial_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/feedback_toast.dart';
import '../../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../../transactions/domain/transaction_model.dart';
import '../../domain/models/account_model.dart';

class AddAccountModal extends StatefulWidget {
  final Function(AccountModel account)? onSaved;

  const AddAccountModal({
    super.key,
    this.onSaved,
  });

  static Future<T?> show<T>(BuildContext context, {Function(AccountModel account)? onSaved}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAccountModal(onSaved: onSaved),
    );
  }

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0.00');

  AccountType _selectedType = AccountType.bank;

  static const List<AccountType> _allowedWalletTypes = [
    AccountType.bank,
    AccountType.cash,
    AccountType.savings,
    AccountType.creditCard,
    AccountType.investment,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _getAccountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'BANK';
      case AccountType.cash:
        return 'CASH';
      case AccountType.savings:
        return 'SAVINGS';
      case AccountType.creditCard:
        return 'CREDIT';
      case AccountType.investment:
        return 'INVESTMENT';
      default:
        return type.name.toUpperCase();
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final initialBalance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

    if (name.isEmpty) {
      FeedbackToast.show(
        context,
        message: 'Please enter a valid wallet/account name.',
        isSuccess: false,
      );
      return;
    }

    final accountId = 'acc_${DateTime.now().millisecondsSinceEpoch}';
    final account = AccountModel(
      id: accountId,
      name: name,
      type: _selectedType,
      balance: 0.0,
      currency: 'USD',
      colorValue: 0xFF10B981,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await DatabaseHelper.instance.insertAccount(account.toMap());

    if (initialBalance != 0) {
      final initialTx = TransactionModel(
        title: 'Initial Balance - $name',
        amount: initialBalance.abs(),
        dateMilliseconds: DateTime.now().millisecondsSinceEpoch,
        category: 'Opening Balance',
        type: initialBalance > 0 ? TransactionType.income : TransactionType.expense,
        accountId: accountId,
        accountName: name,
      );
      await DatabaseHelper.instance.insertTransaction(initialTx.toMap());
    }

    FinancialSyncService.instance.notifyMutation();
    await FinancialCalculationEngine.instance.recalculate();

    if (widget.onSaved != null) {
      widget.onSaved!(account);
    }

    if (mounted) {
      FeedbackToast.show(
        context,
        message: 'Wallet "$name" created successfully.',
        isSuccess: true,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Wallet or Bank Account',
                  style: AppTypography.headline(isDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _nameController,
              label: 'ACCOUNT NAME',
              hint: 'e.g. Chase Checking, Main Wallet, High Yield Savings',
              prefixIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _balanceController,
              label: 'INITIAL BALANCE',
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
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _allowedWalletTypes.map((type) {
                final isSelected = _selectedType == type;
                return AppChip(
                  label: _getAccountTypeLabel(type),
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save Account',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
