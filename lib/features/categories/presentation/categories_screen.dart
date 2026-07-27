import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../budgets/data/datasources/budget_dao.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';
import 'add_category_dialog.dart';

/// Unified Budget Planning Categories Management Screen.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  Map<String, double> _budgetLimits = {};

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndBudgets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoriesAndBudgets() async {
    setState(() => _isLoading = true);
    try {
      await CategoryRepository.instance.loadCategories();
      
      final dao = BudgetDao(AppDatabase.instance);
      final budgets = await dao.getBudgetsWithSpent();
      final Map<String, double> limits = {};
      for (final b in budgets) {
        limits[b.budget.name.trim().toLowerCase()] = b.budget.amountLimit;
        limits[b.budget.categoryId.trim().toLowerCase()] = b.budget.amountLimit;
      }

      if (mounted) {
        setState(() {
          _budgetLimits = limits;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openAddCategory({String? name, double? limit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategoryDialog(
        initialName: name,
        initialLimit: limit,
      ),
    ).then((_) => _fetchCategoriesAndBudgets());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            onPressed: () => _openAddCategory(),
            tooltip: 'Add New Category',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CategoryModel>>(
        valueListenable: CategoryRepository.instance.categoriesNotifier,
        builder: (context, categories, _) {
          if (_isLoading && categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.primaryBlue,
              ),
            );
          }

          if (categories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.category_outlined,
              title: 'No Categories Found',
              description: 'Create custom budget planning categories to organize your expenses.',
              actionLabel: 'Add First Category',
              onActionTap: () => _openAddCategory(),
            );
          }

          return ValueListenableBuilder<Set<String>>(
            valueListenable: CategoryRepository.instance.usedCategoryNamesNotifier,
            builder: (context, usedCategories, _) {
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final catKey = cat.name.trim().toLowerCase();
                  final idKey = cat.id.trim().toLowerCase();
                  
                  final hasBudget = _budgetLimits.containsKey(catKey) || _budgetLimits.containsKey(idKey);
                  final budgetLimit = _budgetLimits[catKey] ?? _budgetLimits[idKey];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.12),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: AppTypography.titleLarge(isDark),
                                ),
                                const SizedBox(height: 2),
                                if (hasBudget && budgetLimit != null)
                                  Text(
                                    'Limit: ${AppFormatters.currency(budgetLimit)}/mo',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.incomeGreen,
                                    ),
                                  )
                                else
                                  Text(
                                    'No Budget Configured',
                                    style: AppTypography.caption(isDark),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _openAddCategory(name: cat.name, limit: budgetLimit),
                                borderRadius: AppRadius.borderSm,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: hasBudget
                                        ? AppColors.primaryBlue.withValues(alpha: 0.12)
                                        : AppColors.incomeGreen.withValues(alpha: 0.12),
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: Text(
                                    hasBudget ? 'Update Budget' : 'Setup Budget',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: hasBudget ? AppColors.primaryBlue : AppColors.incomeGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expenseRed),
                                tooltip: 'Delete Category',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Category'),
                                      content: Text(
                                        'Are you sure you want to delete "${cat.name}"? It will be removed from future choices, but previous transactions will retain their historical records.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: TextButton.styleFrom(foregroundColor: AppColors.expenseRed),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await CategoryRepository.instance.deleteCategory(cat.id);
                                    await _fetchCategoriesAndBudgets();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
