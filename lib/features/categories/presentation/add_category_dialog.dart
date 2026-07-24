import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/currency_provider.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/glass/glass_bottom_sheet.dart';
import '../../budgets/data/datasources/budget_dao.dart';
import '../../budgets/domain/models/budget_model.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';

/// Modal dialog for adding custom Budget Planning Categories with Icon Selection & Optional Budget Limit.
class AddCategoryDialog extends StatefulWidget {
  final String? initialName;
  final double? initialLimit;

  const AddCategoryDialog({
    super.key,
    this.initialName,
    this.initialLimit,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  int _selectedColor = 0xFF2563EB;
  int _selectedIcon = 0xe25a;

  static const List<int> _colors = [
    0xFF2563EB, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899,
    0xFFF59E0B, 0xFFEF4444, 0xFF06B6D4, 0xFF6366F1,
    0xFF14B8A6, 0xFFF97316, 0xFF84CC16, 0xFF64748B,
  ];

  static const List<Map<String, dynamic>> _iconList = [
    {'name': 'Food & Dining', 'code': 0xe25a}, // fastfood
    {'name': 'Groceries', 'code': 0xe59c}, // shopping_cart
    {'name': 'Transportation', 'code': 0xe1d5}, // directions_car
    {'name': 'Fuel & Gas', 'code': 0xe3ab}, // local_gas_station
    {'name': 'Bills & Utilities', 'code': 0xe517}, // receipt
    {'name': 'Housing & Rent', 'code': 0xe318}, // home
    {'name': 'Shopping & Retail', 'code': 0xe59c}, // shopping_bag
    {'name': 'Entertainment', 'code': 0xe40f}, // movie
    {'name': 'Health & Medical', 'code': 0xe548}, // local_hospital
    {'name': 'Subscriptions', 'code': 0xe02e}, // subscriptions
    {'name': 'Education', 'code': 0xe80c}, // school
    {'name': 'Travel', 'code': 0xe556}, // flight
    {'name': 'Fitness & Gym', 'code': 0xeb43}, // fitness_center
    {'name': 'Coffee & Snacks', 'code': 0xe541}, // local_cafe
    {'name': 'Gifts & Donations', 'code': 0xe8f6}, // card_giftcard
    {'name': 'Pets', 'code': 0xe91d}, // pets
    {'name': 'Savings & Deposit', 'code': 0xe850}, // savings
    {'name': 'Maintenance', 'code': 0xe869}, // build
    {'name': 'Phone & Internet', 'code': 0xe32c}, // smartphone
    {'name': 'Business', 'code': 0xe6e1}, // work
    {'name': 'Income', 'code': 0xe0b2}, // attach_money
    {'name': 'General', 'code': 0xe574}, // category
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _limitController = TextEditingController(
      text: (widget.initialLimit != null && widget.initialLimit! > 0)
          ? widget.initialLimit!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final catId = 'cat_${name.toLowerCase().replaceAll(' ', '_')}';
    final newCat = CategoryModel(
      id: catId,
      name: name,
      iconCode: _selectedIcon,
      colorValue: _selectedColor,
    );

    await CategoryRepository.instance.addCategory(newCat);

    final limit = double.tryParse(_limitController.text.trim());
    if (limit != null && limit > 0) {
      final budgetDao = BudgetDao(AppDatabase.instance);
      final budget = BudgetModel(
        id: 'bgt_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        categoryId: catId,
        amountLimit: limit,
      );
      await budgetDao.insertBudget(budget);
      await FinancialSyncService.instance.persistAndNotify();
      await FinancialCalculationEngine.instance.recalculate();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
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
                Text(
                  widget.initialName != null ? 'Edit Budget Category' : 'Create Budget Category',
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
              controller: _nameController,
              label: 'CATEGORY NAME',
              hint: 'e.g. Dining Out, Electricity, Fitness, Subscriptions',
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _limitController,
              label: 'MONTHLY BUDGET LIMIT (${CurrencyProvider.instance.currentSymbol.trim()}) - OPTIONAL',
              hint: '0.00 (Leave blank if no limit)',
              isCurrency: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('COLOR PALETTE', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: isDark ? Colors.white : AppColors.lightTextPrimary, width: 2.5) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('SELECT ICON FROM LIST', style: AppTypography.sectionLabel(isDark)),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 180,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: _iconList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: AppSpacing.xs,
                  mainAxisSpacing: AppSpacing.xs,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final item = _iconList[index];
                  final int code = item['code'] as int;
                  final String iconName = item['name'] as String;
                  final isSelected = _selectedIcon == code;

                  return Tooltip(
                    message: iconName,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIcon = code),
                      borderRadius: AppRadius.borderSm,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceSecondary),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          // ignore: non_const_argument_for_const_parameter
                          IconData(code, fontFamily: 'MaterialIcons'),
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Save Budget Category',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
