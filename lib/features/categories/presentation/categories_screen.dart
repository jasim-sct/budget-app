import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass/ambient_background.dart';
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

    return AmbientBackground(
      child: Scaffold(
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

            final parentCats = categories.where((c) => !c.isSubCategory).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: parentCats.length,
              itemBuilder: (context, index) {
                final parent = parentCats[index];
                final subCats = categories.where((c) => c.parentCategoryId == parent.id).toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: parent.color.withValues(alpha: 0.18),
                                    borderRadius: AppRadius.borderSm,
                                    border: Border.all(color: parent.color.withValues(alpha: 0.35), width: 1),
                                  ),
                                  child: Icon(parent.icon, color: parent.color, size: 20),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      parent.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${parent.type.name.toUpperCase()} • ${subCats.length} Sub-categories',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.expenseRed),
                              onPressed: () {
                                CategoryRepository.instance.deleteCategory(parent.id);
                              },
                            ),
                          ],
                        ),

                        if (subCats.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.xs),
                          ...subCats.map((sub) => Padding(
                                padding: const EdgeInsets.only(left: 48, top: 6, bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(sub.icon, size: 16, color: sub.color),
                                        const SizedBox(width: 8),
                                        Text(
                                          sub.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.expenseRed),
                                      onPressed: () {
                                        CategoryRepository.instance.deleteCategory(sub.id);
                                      },
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
