import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass/glass_card.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';
import 'add_category_dialog.dart';

/// Custom Category Management Screen.
/// Users can view, create, and manage custom expense and income categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    CategoryRepository.instance.loadCategories();
  }

  void _openAddCategory() {
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Categories & Taxonomies',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryEmerald),
            onPressed: _openAddCategory,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<CategoryModel>>(
        valueListenable: CategoryRepository.instance.categoriesNotifier,
        builder: (context, categories, _) {
          if (categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenseCats = categories.where((c) => c.type == CategoryType.expense).toList();
          final incomeCats = categories.where((c) => c.type == CategoryType.income).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('EXPENSE CATEGORIES', style: AppTypography.labelSmall(isDark)),
                  GestureDetector(
                    onTap: _openAddCategory,
                    child: const Text(
                      '+ Add Custom',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryEmerald),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...expenseCats.map((cat) => _buildCategoryTile(cat, isDark)),
              const SizedBox(height: AppSpacing.xl),

              Text('INCOME CATEGORIES', style: AppTypography.labelSmall(isDark)),
              const SizedBox(height: AppSpacing.sm),
              ...incomeCats.map((cat) => _buildCategoryTile(cat, isDark)),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(CategoryModel cat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.18),
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (cat.description != null && cat.description!.isNotEmpty)
                    Text(
                      cat.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expenseRed),
              onPressed: () => CategoryRepository.instance.deleteCategory(cat.id),
            ),
          ],
        ),
      ),
    );
  }
}
