import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/budget_model.dart';

/// Modal Bottom Sheet for adding category spending limits.
class AddBudgetBottomSheet extends StatefulWidget {
  final Function(BudgetModel) onSubmit;

  const AddBudgetBottomSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends State<AddBudgetBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();

  @override
  void dispose() {
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
      );
      widget.onSubmit(budget);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Set Category Spending Limit',
                style: AppTypography.headline(isDark),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'CATEGORY NAME',
            controller: _nameController,
            hint: 'e.g., Dining & Groceries, Fuel, Entertainment',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'MONTHLY LIMIT (\$)',
            controller: _limitController,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save Spending Limit',
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
