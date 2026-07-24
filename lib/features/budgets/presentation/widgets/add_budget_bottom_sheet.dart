import 'package:flutter/material.dart';
import '../../../../core/state/month_selector_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/domain/category_model.dart';
import '../../domain/models/budget_model.dart';
import '../../domain/models/budget_period.dart';

/// Modal Bottom Sheet for adding category spending limits with live daily pacing target calculation.
class AddBudgetBottomSheet extends StatefulWidget {
  final Function(BudgetModel) onSubmit;
  final BudgetPeriodType initialPeriod;

  const AddBudgetBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialPeriod = BudgetPeriodType.monthly,
  });

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  final BudgetPeriodType _selectedPeriod = BudgetPeriodType.monthly;
  double _calculatedDailyTarget = 0.0;
  double _calculatedWeeklyTarget = 0.0;
  double _calculatedYearlyTarget = 0.0;

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _loadingCategories = true;
  bool _isCreatingNewCategory = false;

  @override
  void initState() {
    super.initState();
    _limitController.addListener(_onLimitChanged);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = CategoryRepository.instance;
    await repo.loadCategories();
    if (!mounted) return;
    final cats = repo.categoriesNotifier.value
        .where((c) => !c.isHidden && !c.isArchived)
        .toList();
    setState(() {
      _categories = cats;
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
      _loadingCategories = false;
      if (cats.isEmpty) {
        _isCreatingNewCategory = true;
      }
    });
  }

  void _onLimitChanged() {
    final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;
    final activeDate = MonthSelectorController.instance.value;
    final daysInMonth = DateTime(activeDate.year, activeDate.month + 1, 0).day;
    setState(() {
      _calculatedDailyTarget = limit > 0 ? (limit / daysInMonth) : 0.0;
      _calculatedWeeklyTarget = limit > 0 ? ((limit / daysInMonth) * 7.0) : 0.0;
      _calculatedYearlyTarget = limit > 0 ? (limit * 12.0) : 0.0;
    });
  }

  @override
  void dispose() {
    _limitController.removeListener(_onLimitChanged);
    _limitController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) return;

    if (_isCreatingNewCategory) {
      final newName = _newCategoryController.text.trim();
      if (newName.isEmpty) return;

      final newCat = CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: newName,
        iconCode: 0xe574,
        colorValue: 0xFF3B82F6,
        sortOrder: _categories.length + 1,
      );

      await CategoryRepository.instance.addCategory(newCat);

      final budget = BudgetModel(
        id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
        name: newCat.name,
        categoryId: newCat.id,
        amountLimit: limit,
        periodType: _selectedPeriod,
      );
      widget.onSubmit(budget);
      if (mounted) Navigator.pop(context);
    } else {
      final category = _selectedCategory;
      if (category != null) {
        final budget = BudgetModel(
          id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
          name: category.name,
          categoryId: category.id,
          amountLimit: limit,
          periodType: _selectedPeriod,
        );
        widget.onSubmit(budget);
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDate = MonthSelectorController.instance.value;
    final daysInMonth = DateTime(activeDate.year, activeDate.month + 1, 0).day;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppRadius.borderPill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set Monthly Budget Limit',
                  style: AppTypography.headline(isDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryBlue),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Select an existing category or create a new one for automatic safe-spend tracking.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CATEGORY', style: AppTypography.sectionLabel(isDark)),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCreatingNewCategory = !_isCreatingNewCategory;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Text(
                      _isCreatingNewCategory ? '← Select Existing' : '+ Create New Category',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_isCreatingNewCategory)
              AppTextField(
                label: 'NEW CATEGORY NAME',
                controller: _newCategoryController,
                hint: 'e.g. Subscriptions, Groceries, Fitness',
              )
            else if (_categories.isEmpty)
              Text(
                'No categories found. Switch to "+ Create New Category" above to add one.',
                style: AppTypography.caption(isDark),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory?.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: [
                  ..._categories.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: '__create_new__',
                    child: Text(
                      '+ Create New Category...',
                      style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id == '__create_new__') {
                    setState(() {
                      _isCreatingNewCategory = true;
                    });
                  } else if (id != null) {
                    setState(() {
                      _selectedCategory = _categories.firstWhere((c) => c.id == id);
                    });
                  }
                },
              ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'MONTHLY BUDGET LIMIT (\$)',
              controller: _limitController,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_calculatedDailyTarget > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_outlined, size: 16, color: AppColors.primaryBlue),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Auto-Calculated Allowances ($daysInMonth Days in Month)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Daily Allowance:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${AppFormatters.currency(_calculatedDailyTarget)} / day', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Weekly Allowance:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${AppFormatters.currency(_calculatedWeeklyTarget)} / week', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Yearly Projection:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${AppFormatters.currency(_calculatedYearlyTarget)} / year', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save Monthly Budget Target',
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
