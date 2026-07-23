import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass/glass_button.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_input.dart';
import '../data/goal_repository.dart';
import '../domain/goal_model.dart';

/// Modal dialog for adding savings goals with required monthly savings calculator.
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
                Text(
                  'Create Financial Savings Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _titleController,
              label: 'Goal Title',
              hint: 'e.g. Emergency Reserve, Vacation, House',
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _targetController,
              label: 'Target Goal Amount',
              hint: '5000.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassInput(
              controller: _initialController,
              label: 'Initial Starting Savings',
              hint: '0.00',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),

            // Target Date Picker
            Text('TARGET DATE', style: AppTypography.labelSmall(isDark)),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppFormatters.dateShort(_targetDate),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primaryEmerald, size: 20),
                  ],
                ),
              ),
            ),

            if (target > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.primaryEmerald, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REQUIRED MONTHLY SAVINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryEmerald)),
                          Text(
                            '${AppFormatters.currency(requiredMonthly)} / month',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            GlassButton(
              label: 'Create Goal',
              onPressed: _save,
              variant: GlassButtonVariant.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
