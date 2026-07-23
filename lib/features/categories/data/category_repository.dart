import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/state/micro_notifier.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  static CategoryRepository? _instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  final MicroState<List<CategoryModel>> categoriesNotifier = MicroState([]);
  final MicroState<Set<String>> usedCategoryNamesNotifier = MicroState({});

  CategoryRepository._internal() {
    FinancialSyncService.instance.addListener(loadCategories);
  }

  static CategoryRepository get instance {
    _instance ??= CategoryRepository._internal();
    return _instance!;
  }

  Future<void> loadCategories() async {
    var rawList = await _db.getAllCategories();
    if (rawList.isEmpty) {
      await _seedDefaultCategories();
      rawList = await _db.getAllCategories();
    }
    final models = rawList.map((map) => CategoryModel.fromMap(map)).toList();
    categoriesNotifier.update(models);

    final used = await _db.getUsedCategoryNames();
    usedCategoryNamesNotifier.update(used);
  }

  Future<void> _seedDefaultCategories() async {
    final defaultCats = <CategoryModel>[
      const CategoryModel(
        id: 'cat_food',
        name: 'Food & Dining',
        iconCode: 0xe25a,
        colorValue: 0xFFF59E0B,
        sortOrder: 1,
      ),
      const CategoryModel(
        id: 'cat_transport',
        name: 'Transportation',
        iconCode: 0xe1d5,
        colorValue: 0xFF3B82F6,
        sortOrder: 2,
      ),
      const CategoryModel(
        id: 'cat_bills',
        name: 'Bills & Utilities',
        iconCode: 0xe517,
        colorValue: 0xFFEF4444,
        sortOrder: 3,
      ),
      const CategoryModel(
        id: 'cat_shopping',
        name: 'Shopping & Retail',
        iconCode: 0xe59c,
        colorValue: 0xFF8B5CF6,
        sortOrder: 4,
      ),
      const CategoryModel(
        id: 'cat_housing',
        name: 'Housing & Rent',
        iconCode: 0xe318,
        colorValue: 0xFF10B981,
        sortOrder: 5,
      ),
      const CategoryModel(
        id: 'cat_health',
        name: 'Health & Medical',
        iconCode: 0xe3d9,
        colorValue: 0xFFEC4899,
        sortOrder: 6,
      ),
      const CategoryModel(
        id: 'cat_entertainment',
        name: 'Entertainment & Leisure',
        iconCode: 0xe40a,
        colorValue: 0xFF06B6D4,
        sortOrder: 7,
      ),
      const CategoryModel(
        id: 'cat_subscriptions',
        name: 'Subscriptions',
        iconCode: 0xe02e,
        colorValue: 0xFF6366F1,
        sortOrder: 8,
      ),
    ];

    for (final cat in defaultCats) {
      await _db.insertCategory(cat.toMap());
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.insertCategory(category.toMap());
    await loadCategories();
    FinancialSyncService.instance.notifyMutation();
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    await loadCategories();
    FinancialSyncService.instance.notifyMutation();
  }
}
