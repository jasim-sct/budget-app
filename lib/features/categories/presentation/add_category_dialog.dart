import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass/glass_button.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../../../core/widgets/glass/glass_input.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';

/// Modal dialog for adding custom user categories and sub-categories.
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  CategoryType _selectedType = CategoryType.expense;
  String? _selectedParentId;
  int _selectedColor = 0xFF10B981;
  int _selectedIcon = 0xe25a;

  static const List<int> _colors = [
    0xFF10B981, 0xFF2563EB, 0xFF8B5CF6, 0xFFEC4899,
    0xFFF59E0B, 0xFFDC2626, 0xFF06B6D4, 0xFF6366F1,
  ];

  static const List<int> _icons = [
    0xe25a, // Fastfood
    0xe1d5, // DirectionsCar
    0xe57d, // Receipt
    0xe318, // Home
    0xe59c, // ShoppingBag
    0xe40f, // Movie
    0xe000, // AttachMoney
    0xe6e1, // Work
    0xe850, // TrendingUp
    0xe556, // Flight
    0xe548, // LocalHospital
    0xe80c, // School
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;

    final newCat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      iconCode: _selectedIcon,
      colorValue: _selectedColor,
      parentCategoryId: _selectedParentId,
      description: _descController.text.trim(),
    );

    CategoryRepository.instance.addCategory(newCat);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentCats = CategoryRepository.instance.categoriesNotifier.value
        .where((c) => !c.isSubCategory)
        .toList();

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
                  'Add Category / Sub-Category',
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
              controller: _nameController,
              label: 'Category Name',
              hint: 'e.g. Subscriptions, Coffee, Groceries',
            ),
            const SizedBox(height: AppSpacing.md),

            // Parent Category Selector (Optional Sub-Category Assignment)
            Text('PARENT CATEGORY (OPTIONAL)', style: AppTypography.labelSmall(isDark)),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    selected: _selectedParentId == null,
                    label: const Text('Top-Level Parent'),
                    onSelected: (_) => setState(() => _selectedParentId = null),
                  ),
                  const SizedBox(width: 6),
                  ...parentCats.map((parent) {
                    final isSelected = _selectedParentId == parent.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(parent.name),
                        onSelected: (_) => setState(() => _selectedParentId = parent.id),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Text('TYPE', style: AppTypography.labelSmall(isDark)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    selected: _selectedType == CategoryType.expense,
                    label: const Text('Expense'),
                    onSelected: (_) => setState(() => _selectedType = CategoryType.expense),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    selected: _selectedType == CategoryType.income,
                    label: const Text('Income'),
                    onSelected: (_) => setState(() => _selectedType = CategoryType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('COLOR', style: AppTypography.labelSmall(isDark)),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('ICON', style: AppTypography.labelSmall(isDark)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((ic) {
                final isSelected = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryEmerald : Colors.transparent,
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(
                      // ignore: non_const_argument_for_const_parameter
                      IconData(ic, fontFamily: 'MaterialIcons'),
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassButton(
              label: 'Create Category',
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
