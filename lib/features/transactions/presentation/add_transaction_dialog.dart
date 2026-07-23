import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/glass_button.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_chip.dart';
import '../../../core/widgets/glass/glass_input.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/presentation/add_category_dialog.dart';
import '../domain/transaction_model.dart';

/// Commercial-grade Glassmorphic Modal Bottom Sheet for adding ledger transactions.
class AddTransactionDialog extends StatefulWidget {
  final Function(TransactionModel) onSubmit;

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
  String _selectedCategory = 'Food & Dining';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController(text: _selectedCategory);
    CategoryRepository.instance.loadCategories();
  }

  @override
  void dispose() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields with a valid amount.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
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

  void _openAddCustomCategory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCategoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: const Icon(Icons.add_card_rounded, color: AppColors.primaryEmerald, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'New Ledger Transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Segmented Glass Expense / Income Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x351E293B) : const Color(0x60FFFFFF),
                borderRadius: AppRadius.borderPill,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = TransactionType.expense),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.expense
                              ? AppColors.expenseRed
                              : Colors.transparent,
                          borderRadius: AppRadius.borderPill,
                        ),
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedType == TransactionType.expense
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = TransactionType.income),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.income
                              ? AppColors.incomeGreen
                              : Colors.transparent,
                          borderRadius: AppRadius.borderPill,
                        ),
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedType == TransactionType.income
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Hero Glass Amount Input
            GlassInput(
              controller: _amountController,
              label: 'Transaction Amount',
              hint: '0.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title Glass Input
            GlassInput(
              controller: _titleController,
              label: 'Title / Merchant',
              hint: 'e.g. Starbucks, Apple Store, Salary',
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: AppSpacing.md),

            // Glass Category Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT CATEGORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: _openAddCustomCategory,
                  child: const Text(
                    '+ Custom',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryEmerald),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<List<CategoryModel>>(
              valueListenable: CategoryRepository.instance.categoriesNotifier,
              builder: (context, catModels, _) {
                final catNames = catModels.map((c) => c.name).toList();
                if (!catNames.contains('Food & Dining')) catNames.insert(0, 'Food & Dining');
                if (!catNames.contains('Transportation')) catNames.add('Transportation');
                if (!catNames.contains('Bills & Utilities')) catNames.add('Bills & Utilities');
                if (!catNames.contains('Salary & Wages')) catNames.add('Salary & Wages');

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: catNames.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GlassChip(
                      label: cat,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _categoryController.text = cat;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Glass Save Action Button
            GlassButton(
              label: 'Save Transaction',
              icon: Icons.check_circle_outline_rounded,
              variant: GlassButtonVariant.gradient,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
