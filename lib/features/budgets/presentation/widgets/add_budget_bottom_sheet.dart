import 'package:flutter/material.dart';
import '../../../../core/state/month_selector_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final BudgetPeriodType _selectedPeriod = BudgetPeriodType.monthly;
  double _calculatedDailyTarget = 0.0;
  double _calculatedWeeklyTarget = 0.0;
  double _calculatedYearlyTarget = 0.0;

  @override
  void initState() {
    super.initState();
    _limitController.addListener(_onLimitChanged);
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
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    final limit = double.tryParse(_limitController.text.trim());

    if (name.isNotEmpty && limit != null && limit > 0) {
      final budget = BudgetModel(
        id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        categoryId: 'cat_${name.toLowerCase().replaceAll(' ', '_')}',
        amountLimit: limit,
        periodType: _selectedPeriod,
      );
      widget.onSubmit(budget);
      Navigator.pop(context);
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
            // Drag handle
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
                      'Budgets are configured on a Monthly basis. Daily, Weekly, and Yearly allowances are automatically calculated.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              label: 'CATEGORY NAME',
              controller: _nameController,
              hint: 'e.g., Dining & Groceries, Fuel, Entertainment',
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
