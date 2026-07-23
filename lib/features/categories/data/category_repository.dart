import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/state/micro_notifier.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  static CategoryRepository? _instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  final MicroState<List<CategoryModel>> categoriesNotifier = MicroState([]);

  CategoryRepository._internal() {
    FinancialSyncService.instance.addListener(loadCategories);
  }

  static CategoryRepository get instance {
    _instance ??= CategoryRepository._internal();
    return _instance!;
  }

  Future<void> loadCategories() async {
    final rawList = await _db.getAllCategories();
    final models = rawList.map((map) => CategoryModel.fromMap(map)).toList();
    categoriesNotifier.update(models);
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
