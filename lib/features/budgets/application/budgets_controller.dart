import '../../../core/services/financial_sync_service.dart';
import '../../../core/state/micro_notifier.dart';
import '../../../core/state/month_selector_controller.dart';
import '../data/datasources/budget_dao.dart';
import '../domain/models/budget_model.dart';

class BudgetsState {
  final List<BudgetSpentSummary> summaries;
  final bool isLoading;

  const BudgetsState({required this.summaries, required this.isLoading});
}

class BudgetsController {
  final BudgetDao _dao;

  final MicroState<BudgetsState> stateNotifier = MicroState(
    const BudgetsState(summaries: [], isLoading: true),
  );

  BudgetsController(this._dao) {
    FinancialSyncService.instance.addListener(loadBudgets);
    MonthSelectorController.instance.addListener(loadBudgets);
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    stateNotifier.update(BudgetsState(summaries: stateNotifier.value.summaries, isLoading: true));
    final list = await _dao.getBudgetsWithSpent();
    stateNotifier.update(BudgetsState(summaries: list, isLoading: false));
  }

  Future<void> saveBudget(BudgetModel budget) async {
    await _dao.saveBudget(budget);
    await loadBudgets();
    FinancialSyncService.instance.notifyMutation();
  }

  Future<void> deleteBudget(String id) async {
    await _dao.deleteBudget(id);
    await loadBudgets();
    FinancialSyncService.instance.notifyMutation();
  }
}
