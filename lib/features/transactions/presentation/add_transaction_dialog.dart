import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/transaction_model.dart';

/// Low-overhead Modal Dialog to create a transaction.
/// Ensures all controllers are disposed immediately upon closure.
class AddTransactionDialog extends StatefulWidget {
  final ValueChanged<TransactionModel> onSubmit;

  const AddTransactionDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  TransactionType _selectedType = TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController(text: 'General');
  }

  @override
  void dispose() {
    // Explicit disposal of all text controllers to prevent memory leaks on 1GB RAM hardware
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _titleController.text.trim();
    final double? amount = double.tryParse(_amountController.text.trim());
    final String category = _categoryController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0 || category.isEmpty) {
      return;
    }

    final transaction = TransactionModel(
      title: title,
      amount: amount,
      dateMilliseconds: DateTime.now().millisecondsSinceEpoch,
      category: category,
      type: _selectedType,
    );

    widget.onSubmit(transaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Expense / Income Selector
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = TransactionType.expense),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedType == TransactionType.expense
                            ? AppTheme.expenseRed
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedType == TransactionType.expense
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = TransactionType.income),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedType == TransactionType.income
                            ? AppTheme.incomeGreen
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedType == TransactionType.income
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
