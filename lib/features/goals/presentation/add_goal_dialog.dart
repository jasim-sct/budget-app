import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';

/// Modal bottom sheet for adding savings goals with required monthly savings calculator.
class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _initialController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));
  final String _selectedCategory = 'Savings';

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final initial = double.tryParse(_initialController.text.trim()) ?? 0.0;

    if (title.isEmpty || target == null || target <= 0) return;

    final newGoal = GoalModel(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      targetAmount: target,
      currentAmount: initial,
      targetDateMilliseconds: _targetDate.millisecondsSinceEpoch,
      category: _selectedCategory,
    );

    GoalRepository.instance.addGoal(newGoal);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double target = double.tryParse(_targetController.text.trim()) ?? 0.0;
    final double current = double.tryParse(_initialController.text.trim()) ?? 0.0;
    final monthsRemaining = (_targetDate.difference(DateTime.now()).inDays / 30).clamp(1.0, 120.0);
    final requiredMonthly = (target - current) > 0 ? (target - current) / monthsRemaining : 0.0;

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
                  'Create Savings Goal',
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
              controller: _titleController,
              label: 'GOAL TITLE',
              hint: 'e.g. Emergency Reserve, Vacation, House',
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _targetController,
              label: 'TARGET GOAL AMOUNT',
              hint: '5000.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _initialController,
              label: 'INITIAL STARTING SAVINGS',
              hint: '0.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),

            // Target Date Picker
            Text('TARGET DATE', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppFormatters.dateShort(_targetDate),
                      style: AppTypography.titleMedium(isDark),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue, size: 18),
                  ],
                ),
              ),
            ),

            if (target > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REQUIRED MONTHLY SAVINGS', style: AppTypography.sectionLabel(isDark).copyWith(color: AppColors.primaryBlue)),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${AppFormatters.currency(requiredMonthly)} / month',
                            style: AppTypography.titleLarge(isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Create Goal',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
