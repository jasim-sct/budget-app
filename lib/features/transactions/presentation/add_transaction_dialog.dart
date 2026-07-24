import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/feedback_toast.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../accounts/domain/models/account_model.dart';
import '../../budgets/data/datasources/budget_dao.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/presentation/add_category_dialog.dart';
import '../domain/transaction_model.dart';

/// Modal Bottom Sheet for adding ledger transactions with behavioral auto-suggestions and quick preset chips.
class AddTransactionDialog extends StatefulWidget {
  final String? initialAccountId;
  final TransactionType? initialType;
  final Future<void> Function(TransactionModel) onSubmit;

  const AddTransactionDialog({
    super.key,
    this.initialAccountId,
    this.initialType,
    required this.onSubmit,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;

  late TransactionType _selectedType;
  late String _selectedCategory;

  List<AccountModel> _accounts = [];
  List<BudgetSpentSummary> _budgetSummaries = [];
  String? _selectedAccountId;
  String? _selectedAccountName;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();

    _selectedType = widget.initialType ?? (widget.initialAccountId != null ? TransactionType.income : TransactionType.expense);
    _selectedCategory = _selectedType == TransactionType.income ? 'Salary & Wages' : 'Food & Dining';
    _categoryController = TextEditingController(text: _selectedCategory);
    _selectedAccountId = widget.initialAccountId;

    CategoryRepository.instance.loadCategories();
    _loadAccounts();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final dao = BudgetDao(AppDatabase.instance);
    final summaries = await dao.getBudgetsWithSpent();
    if (mounted) {
      setState(() {
        _budgetSummaries = summaries;
      });
    }
  }

  Future<void> _loadAccounts() async {
    final rawAccounts = await DatabaseHelper.instance.getAllAccounts();
    final list = rawAccounts.map((m) => AccountModel.fromMap(m)).toList();
    if (mounted) {
      setState(() {
        _accounts = list;
        if (_selectedAccountId != null) {
          final matched = _accounts.firstWhere(
            (a) => a.id == _selectedAccountId,
            orElse: () => _accounts.isNotEmpty
                ? _accounts.first
                : AccountModel(
                    id: 'acc_cash',
                    name: 'Cash Wallet',
                    type: AccountType.cash,
                    balance: 0.0,
                    currency: 'USD',
                    colorValue: 0xFF10B981,
                    updatedAt: 0,
                  ),
          );
          _selectedAccountId = matched.id;
          _selectedAccountName = matched.name;
        } else if (_accounts.isNotEmpty) {
          _selectedAccountId = _accounts.first.id;
          _selectedAccountName = _accounts.first.name;
        } else {
          _selectedAccountId = 'acc_cash';
          _selectedAccountName = 'Cash Wallet';
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onTitleChanged(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('coffee') || lower.contains('starbucks') || lower.contains('food') || lower.contains('burger') || lower.contains('pizza') || lower.contains('dinner') || lower.contains('lunch')) {
      if (_selectedCategory != 'Food & Dining') {
        setState(() {
          _selectedCategory = 'Food & Dining';
          _categoryController.text = _selectedCategory;
        });
      }
    } else if (lower.contains('uber') || lower.contains('lyft') || lower.contains('bus') || lower.contains('train') || lower.contains('gas') || lower.contains('fuel')) {
      if (_selectedCategory != 'Transportation') {
        setState(() {
          _selectedCategory = 'Transportation';
          _categoryController.text = _selectedCategory;
        });
      }
    } else if (lower.contains('salary') || lower.contains('paycheck') || lower.contains('payroll')) {
      if (_selectedType != TransactionType.income || _selectedCategory != 'Salary & Wages') {
        setState(() {
          _selectedType = TransactionType.income;
          _selectedCategory = 'Salary & Wages';
          _categoryController.text = _selectedCategory;
        });
      }
    } else if (lower.contains('rent') || lower.contains('electricity') || lower.contains('water') || lower.contains('bill') || lower.contains('internet')) {
      if (_selectedCategory != 'Bills & Utilities') {
        setState(() {
          _selectedCategory = 'Bills & Utilities';
          _categoryController.text = _selectedCategory;
        });
      }
    }
  }

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final String title = _titleController.text.trim();
    final double? amount = double.tryParse(_amountController.text.trim());
    final String category = _categoryController.text.trim();

    if (title.isEmpty || amount == null || amount <= 0 || category.isEmpty) {
      FeedbackToast.show(
        context,
        message: 'Please fill out all required fields with a valid amount.',
        isSuccess: false,
      );
      return;
    }

    final transaction = TransactionModel(
      title: title,
      amount: amount,
      dateMilliseconds: DateTime.now().millisecondsSinceEpoch,
      category: category,
      type: _selectedType,
      accountId: _selectedAccountId ?? 'acc_cash',
      accountName: _selectedAccountName ?? 'Cash Wallet',
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(transaction);
      if (!mounted) return;
      FeedbackToast.show(
        context,
        message: 'Transaction recorded cleanly to ledger.',
        isSuccess: true,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      FeedbackToast.show(
        context,
        message: 'Could not save transaction. Please try again.',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

    return GlassBottomSheet(
      child: SingleChildScrollView(
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
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: const Icon(Icons.add_card_rounded, color: AppColors.primaryBlue, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'New Ledger Entry',
                      style: AppTypography.headline(isDark),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Segmented Expense / Income Switcher
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.expense;
                          if (_selectedCategory == 'Salary & Wages') {
                            _selectedCategory = 'Food & Dining';
                            _categoryController.text = _selectedCategory;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.expense
                              ? AppColors.expenseRed
                              : Colors.transparent,
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                      onTap: () {
                        setState(() {
                          _selectedType = TransactionType.income;
                          if (_selectedCategory == 'Food & Dining') {
                            _selectedCategory = 'Salary & Wages';
                            _categoryController.text = _selectedCategory;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedType == TransactionType.income
                              ? AppColors.incomeGreen
                              : Colors.transparent,
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
            const SizedBox(height: AppSpacing.md),

            // Target Wallet Selector
            Text('TARGET WALLET', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            if (_accounts.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _accounts.map((acc) {
                  final isSelected = _selectedAccountId == acc.id;
                  return AppChip(
                    label: acc.name,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedAccountId = acc.id;
                        _selectedAccountName = acc.name;
                      });
                    },
                  );
                }).toList(),
              )
            else
              const AppChip(label: 'Cash Wallet', isSelected: true),
            const SizedBox(height: AppSpacing.md),

            // Amount Input & Preset Chips
            AppTextField(
              controller: _amountController,
              label: 'TRANSACTION AMOUNT',
              hint: '0.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [5, 10, 20, 50, 100, 500].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AppChip(
                      label: '\$$amt',
                      isSelected: _amountController.text == amt.toString(),
                      onTap: () {
                        setState(() {
                          _amountController.text = amt.toString();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title Input
            AppTextField(
              controller: _titleController,
              label: 'TITLE / MERCHANT',
              hint: 'e.g. Coffee, Uber, Salary, Rent',
              prefixIcon: Icons.title_rounded,
              onChanged: _onTitleChanged,
            ),
            const SizedBox(height: AppSpacing.md),

            // Active Budget Envelopes Section
            if (_selectedType == TransactionType.expense && _budgetSummaries.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LINK TO BUDGET ENVELOPE', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue)),
                  Text(
                    '${_budgetSummaries.length} Active',
                    style: AppTypography.caption(isDark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _budgetSummaries.map((summary) {
                  final budgetName = summary.budget.name;
                  final isSelected = _selectedCategory.toLowerCase() == budgetName.toLowerCase();
                  return AppChip(
                    label: '$budgetName (${(summary.progressRatio * 100).toInt()}%)',
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = budgetName;
                        _categoryController.text = budgetName;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Category Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ALL CATEGORIES', style: AppTypography.sectionLabel(isDark)),
                GestureDetector(
                  onTap: _openAddCustomCategory,
                  child: const Text(
                    '+ Custom',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<List<CategoryModel>>(
              valueListenable: CategoryRepository.instance.categoriesNotifier,
              builder: (context, catModels, _) {
                // Build a case-insensitively unique name list so the same
                // category can never render as two chips.
                final catNames = <String>[];
                final seen = <String>{};
                for (final c in catModels) {
                  final name = c.name.trim();
                  if (name.isEmpty) continue;
                  if (seen.add(name.toLowerCase())) catNames.add(name);
                }
                // Only fall back to defaults when there are genuinely no
                // categories yet (never merge them into an existing list).
                if (catNames.isEmpty) {
                  catNames.addAll(const ['Food & Dining', 'Transportation', 'Bills & Utilities', 'Salary & Wages']);
                }

                return Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: catNames.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return AppChip(
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
            const SizedBox(height: AppSpacing.lg),

            // Submit Action Button
            AppButton(
              label: 'Save Transaction',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
