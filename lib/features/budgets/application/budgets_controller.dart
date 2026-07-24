import '../../../core/services/financial_sync_service.dart';
import '../../../core/state/micro_notifier.dart';
import '../../../core/state/month_selector_controller.dart';
import '../data/datasources/budget_dao.dart';
import '../domain/models/budget_model.dart';
import '../domain/models/budget_pacing_model.dart';
import '../domain/models/budget_period.dart';
import '../domain/services/budget_history_engine.dart';
import '../domain/services/budget_pacing_calculator.dart';

class BudgetsState {
  final List<BudgetSpentSummary> summaries;
  final BudgetPeriodType selectedPeriod;
  final BudgetPacingModel overallPacing;
  final List<double> dailyCumulativeSpent;
  final PeriodComparisonMetrics? comparisonMetrics;
  final bool isLoading;

  const BudgetsState({
    required this.summaries,
    required this.selectedPeriod,
    required this.overallPacing,
    required this.dailyCumulativeSpent,
    this.comparisonMetrics,
    required this.isLoading,
  });

  static BudgetsState initial() {
    final now = DateTime.now();
    return BudgetsState(
      summaries: const [],
      selectedPeriod: BudgetPeriodType.monthly,
      overallPacing: BudgetPacingCalculator.calculate(
        monthlyBudget: 0.0,
        totalSpent: 0.0,
        year: now.year,
        month: now.month,
      ),
      dailyCumulativeSpent: const [],
      comparisonMetrics: null,
      isLoading: true,
    );
  }

  BudgetsState copyWith({
    List<BudgetSpentSummary>? summaries,
    BudgetPeriodType? selectedPeriod,
    BudgetPacingModel? overallPacing,
    List<double>? dailyCumulativeSpent,
    PeriodComparisonMetrics? comparisonMetrics,
    bool? isLoading,
  }) {
    return BudgetsState(
      summaries: summaries ?? this.summaries,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      overallPacing: overallPacing ?? this.overallPacing,
      dailyCumulativeSpent: dailyCumulativeSpent ?? this.dailyCumulativeSpent,
      comparisonMetrics: comparisonMetrics ?? this.comparisonMetrics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BudgetsController {
  final BudgetDao _dao;
  final BudgetHistoryEngine _historyEngine = BudgetHistoryEngine();

  final MicroState<BudgetsState> stateNotifier = MicroState(
    BudgetsState.initial(),
  );

  BudgetsController(this._dao) {
    FinancialSyncService.instance.addListener(loadBudgets);
    MonthSelectorController.instance.addListener(loadBudgets);
    _initRolloverAndLoad();
  }

  Future<void> _initRolloverAndLoad() async {
    try {
      await _historyEngine.checkAndRunRollover();
    } catch (_) {}
    await loadBudgets();
  }

  void setPeriod(BudgetPeriodType period) {
    if (stateNotifier.value.selectedPeriod == period) return;
    stateNotifier.update(stateNotifier.value.copyWith(selectedPeriod: period));
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    stateNotifier.update(stateNotifier.value.copyWith(isLoading: true));

    try {
      final activeDate = MonthSelectorController.instance.value;
      final selectedPeriod = stateNotifier.value.selectedPeriod;
      final year = activeDate.year;
      final month = activeDate.month;

      final summaries = await _dao.getBudgetsForPeriod(
        periodType: selectedPeriod,
        referenceDate: activeDate,
      );

      final dailySpent = await _dao.getDailyCumulativeExpenses(year, month);
      final comparison = await _historyEngine.comparePeriods(
        periodType: selectedPeriod,
        currentDate: activeDate,
      );

      final double totalLimit = summaries.fold(0.0, (sum, s) => sum + s.metrics.allocation);
      final double totalSpent = summaries.fold(0.0, (sum, s) => sum + s.spent);

      final now = DateTime.now();
      final daysInMonth = DateTime(year, month + 1, 0).day;
      int currentDay = (year == now.year && month == now.month) ? now.day.clamp(1, daysInMonth) : daysInMonth;

      double todaySpent = 0.0;
      if (dailySpent.isNotEmpty && currentDay <= dailySpent.length) {
        if (currentDay == 1) {
          todaySpent = dailySpent[0];
        } else {
          todaySpent = (dailySpent[currentDay - 1] - dailySpent[currentDay - 2]).clamp(0.0, double.infinity);
        }
      }

      double monthlyBaseLimit = totalLimit;
      switch (selectedPeriod) {
        case BudgetPeriodType.daily:
          monthlyBaseLimit = totalLimit * daysInMonth;
          break;
        case BudgetPeriodType.weekly:
          monthlyBaseLimit = (totalLimit / 7.0) * daysInMonth;
          break;
        case BudgetPeriodType.monthly:
          monthlyBaseLimit = totalLimit;
          break;
        case BudgetPeriodType.yearly:
          monthlyBaseLimit = totalLimit / 12.0;
          break;
      }

      final overallPacing = BudgetPacingCalculator.calculate(
        monthlyBudget: monthlyBaseLimit,
        totalSpent: selectedPeriod == BudgetPeriodType.monthly ? totalSpent : (totalSpent * (monthlyBaseLimit > 0 ? (monthlyBaseLimit / (totalLimit > 0 ? totalLimit : 1.0)) : 1.0)),
        year: year,
        month: month,
        todaySpent: todaySpent,
      );

      stateNotifier.update(
        BudgetsState(
          summaries: summaries,
          selectedPeriod: selectedPeriod,
          overallPacing: overallPacing,
          dailyCumulativeSpent: dailySpent,
          comparisonMetrics: comparison,
          isLoading: false,
        ),
      );
    } catch (_) {
      stateNotifier.update(stateNotifier.value.copyWith(isLoading: false));
    }
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
