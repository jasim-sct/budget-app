import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_sync_service.dart';
import '../../../core/state/micro_notifier.dart';
import '../domain/goal_model.dart';

class GoalRepository {
  static GoalRepository? _instance;
  final DatabaseHelper _db = DatabaseHelper.instance;

  final MicroState<List<GoalModel>> goalsNotifier = MicroState([]);

  GoalRepository._internal() {
    FinancialSyncService.instance.addListener(loadGoals);
  }

  static GoalRepository get instance {
    _instance ??= GoalRepository._internal();
    return _instance!;
  }

  Future<void> loadGoals() async {
    final rawList = await _db.getAllGoals();
    final models = rawList.map((map) => GoalModel.fromMap(map)).toList();
    goalsNotifier.update(models);
  }

  Future<void> addGoal(GoalModel goal) async {
    await _db.insertGoal(goal.toMap());
    await loadGoals();
    await FinancialSyncService.instance.persistAndNotify();
  }
}
