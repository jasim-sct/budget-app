import '../../../features/transactions/domain/transaction_model.dart';

enum TimeRangePreset {
  allTime,
  today,
  yesterday,
  thisWeek,
  lastWeek,
  last7Days,
  last15Days,
  last30Days,
  thisMonth,
  previousMonth,
  last3Months,
  last6Months,
  thisQuarter,
  previousQuarter,
  thisYear,
  previousYear,
  custom,
}

enum SortByField { date, amount, category, merchant }

/// Single source of truth Global Filter State Model (Enterprise Engine).
class GlobalFilterState {
  final TimeRangePreset timeRangePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<TransactionType> transactionTypes;
  final Set<String> categoryIds;
  final Set<String> accountIds;
  final double? minAmount;
  final double? maxAmount;
  final String searchQuery;
  final SortByField sortBy;
  final bool isAscending;

  const GlobalFilterState({
    this.timeRangePreset = TimeRangePreset.thisMonth,
    this.startDate,
    this.endDate,
    this.transactionTypes = const {},
    this.categoryIds = const {},
    this.accountIds = const {},
    this.minAmount,
    this.maxAmount,
    this.searchQuery = '',
    this.sortBy = SortByField.date,
    this.isAscending = false,
  });

  bool get isFilterActive {
    return timeRangePreset != TimeRangePreset.thisMonth ||
        transactionTypes.isNotEmpty ||
        categoryIds.isNotEmpty ||
        accountIds.isNotEmpty ||
        minAmount != null ||
        maxAmount != null ||
        searchQuery.trim().isNotEmpty ||
        startDate != null ||
        endDate != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (timeRangePreset != TimeRangePreset.thisMonth || startDate != null) count++;
    if (transactionTypes.isNotEmpty) count += transactionTypes.length;
    if (categoryIds.isNotEmpty) count += categoryIds.length;
    if (accountIds.isNotEmpty) count += accountIds.length;
    if (minAmount != null || maxAmount != null) count++;
    if (searchQuery.trim().isNotEmpty) count++;
    return count;
  }

  GlobalFilterState copyWith({
    TimeRangePreset? timeRangePreset,
    DateTime? startDate,
    DateTime? endDate,
    Set<TransactionType>? transactionTypes,
    Set<String>? categoryIds,
    Set<String>? accountIds,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
    SortByField? sortBy,
    bool? isAscending,
  }) {
    return GlobalFilterState(
      timeRangePreset: timeRangePreset ?? this.timeRangePreset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactionTypes: transactionTypes ?? this.transactionTypes,
      categoryIds: categoryIds ?? this.categoryIds,
      accountIds: accountIds ?? this.accountIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}
