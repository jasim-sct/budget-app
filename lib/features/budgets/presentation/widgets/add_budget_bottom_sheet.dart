import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/state/month_selector_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_chip.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final BudgetPeriodType _selectedPeriod = BudgetPeriodType.monthly;
  double _calculatedDailyTarget = 0.0;
  double _calculatedWeeklyTarget = 0.0;
  double _calculatedYearlyTarget = 0.0;

  List<CategoryModel> _categories = [];
  final Set<String> _selectedCategoryIds = {};
  bool _loadingCategories = true;
  bool _isCreatingNewCategory = false;
  bool _nameEditedManually = false;

  @override
  void initState() {
    super.initState();
    _limitController.addListener(_onLimitChanged);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = CategoryRepository.instance;
    await repo.loadCategories();
    // Categories that already own a budget are removed from the pool — picking
    // a category for a budget moves it out entirely (one budget per category).
    final budgeted = await DatabaseHelper.instance.getBudgetedCategoryIds();
    if (!mounted) return;
    final cats = repo.categoriesNotifier.value
        .where((c) => !c.isHidden && !c.isArchived && !budgeted.contains(c.id))
        .toList();
    setState(() {
      _categories = cats;
      _loadingCategories = false;
      if (cats.isEmpty) {
        _isCreatingNewCategory = true;
      }
    });
  }

  void _toggleCategory(CategoryModel cat) {
    setState(() {
      if (_selectedCategoryIds.contains(cat.id)) {
        _selectedCategoryIds.remove(cat.id);
      } else {
        _selectedCategoryIds.add(cat.id);
      }
      _syncAutoName();
    });
  }

  /// Auto-name the budget from its selected categories until the user types
  /// their own name.
  void _syncAutoName() {
    if (_nameEditedManually) return;
    final names = _categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();
    _nameController.text = switch (names.length) {
      0 => '',
      1 => names.first,
      2 => '${names[0]} & ${names[1]}',
      _ => '${names[0]} +${names.length - 1} more',
    };
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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory() async {
    final newName = _newCategoryController.text.trim();
    if (newName.isEmpty) return;
    final newCat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: newName,
      iconCode: 0xe574,
      colorValue: 0xFF3B82F6,
      sortOrder: _categories.length + 1,
    );
    // Reuse an existing same-named category rather than duplicating it.
    final canonical = await CategoryRepository.instance.addCategory(newCat);
    if (!mounted) return;
    setState(() {
      if (!_categories.any((c) => c.id == canonical.id)) {
        _categories = [..._categories, canonical];
      }
      _selectedCategoryIds.add(canonical.id);
      _newCategoryController.clear();
      _isCreatingNewCategory = false;
      _syncAutoName();
    });
  }

  Future<void> _handleSubmit() async {
    final limit = double.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) return;
    if (_selectedCategoryIds.isEmpty) return;

    final ids = _selectedCategoryIds.toList();
    final budgetName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_categories.firstWhere((c) => c.id == ids.first).name);

    final budget = BudgetModel(
      id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
      name: budgetName,
      categoryId: ids.first,
      categoryIds: ids,
      amountLimit: limit,
      periodType: _selectedPeriod,
    );
    widget.onSubmit(budget);
    if (mounted) Navigator.pop(context);
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
                  'New Budget',
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
                      'Group one or more categories under a single limit. A category can belong to only one budget.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'BUDGET NAME',
              controller: _nameController,
              hint: 'e.g. Essentials, Fun Money',
              onChanged: (v) => _nameEditedManually = v.trim().isNotEmpty,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CATEGORIES', style: AppTypography.sectionLabel(isDark)),
                if (_selectedCategoryIds.isNotEmpty)
                  Text(
                    '${_selectedCategoryIds.length} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
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
            else ...[
              if (_categories.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _categories.map((c) {
                    return AppChip(
                      label: c.name,
                      isSelected: _selectedCategoryIds.contains(c.id),
                      onTap: () => _toggleCategory(c),
                    );
                  }).toList(),
                )
              else if (!_isCreatingNewCategory)
                Text(
                  'Every category already belongs to a budget. Add a new category below.',
                  style: AppTypography.caption(isDark),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (_isCreatingNewCategory)
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'NEW CATEGORY NAME',
                        controller: _newCategoryController,
                        hint: 'e.g. Subscriptions, Fitness',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: IconButton.filled(
                        icon: const Icon(Icons.check_rounded, size: 20),
                        onPressed: _addNewCategory,
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isCreatingNewCategory = true),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New category'),
                  ),
                ),
            ],
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
