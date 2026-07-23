import '../../../features/transactions/domain/transaction_model.dart';
import '../state/micro_notifier.dart';
import '../state/month_selector_controller.dart';
import 'global_filter_state.dart';

/// Singleton Global Filter Controller managing application-wide filtering context.
class GlobalFilterController {
  static GlobalFilterController? _instance;

  final MicroState<GlobalFilterState> filterNotifier = MicroState(const GlobalFilterState());

  GlobalFilterController._internal() {
    MonthSelectorController.instance.addListener(_onMonthChanged);
  }

  static GlobalFilterController get instance {
    _instance ??= GlobalFilterController._internal();
    return _instance!;
  }

  GlobalFilterState get state => filterNotifier.value;

  void _onMonthChanged() {
    if (state.timeRangePreset == TimeRangePreset.thisMonth) {
      filterNotifier.update(state.copyWith());
    }
  }

  void updateTimeRange(TimeRangePreset preset, {DateTime? startDate, DateTime? endDate}) {
    filterNotifier.update(
      state.copyWith(
        timeRangePreset: preset,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  void toggleTransactionType(TransactionType type) {
    final current = Set<TransactionType>.from(state.transactionTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    filterNotifier.update(state.copyWith(transactionTypes: current));
  }

  void toggleCategory(String categoryId) {
    final current = Set<String>.from(state.categoryIds);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    filterNotifier.update(state.copyWith(categoryIds: current));
  }

  void setSearchQuery(String query) {
    filterNotifier.update(state.copyWith(searchQuery: query));
  }

  void setAmountRange(double? min, double? max) {
    filterNotifier.update(state.copyWith(minAmount: min, maxAmount: max));
  }

  void setSorting(SortByField sortBy, {required bool isAscending}) {
    filterNotifier.update(state.copyWith(sortBy: sortBy, isAscending: isAscending));
  }

  void resetFilters() {
    filterNotifier.update(const GlobalFilterState());
  }
}
