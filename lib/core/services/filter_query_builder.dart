import 'package:flutter/material.dart';
import 'global_filter_state.dart';

class FilterQueryResult {
  final String whereClause;
  final List<dynamic> whereArgs;
  final String orderBy;

  const FilterQueryResult({
    required this.whereClause,
    required this.whereArgs,
    required this.orderBy,
  });
}

/// Parameterized SQL Query Builder for Enterprise Global Filtering.
class FilterQueryBuilder {
  static FilterQueryResult buildQuery(GlobalFilterState filter, {int? activeYear, int? activeMonth}) {
    final List<String> conditions = [];
    final List<dynamic> args = [];

    // 1. Time Range Condition
    final dateBounds = _calculateDateBounds(filter, activeYear: activeYear, activeMonth: activeMonth);
    if (dateBounds != null) {
      conditions.add('date >= ? AND date <= ?');
      args.add(dateBounds.start.millisecondsSinceEpoch);
      args.add(dateBounds.end.millisecondsSinceEpoch);
    }

    // 2. Transaction Types Condition
    if (filter.transactionTypes.isNotEmpty) {
      final typeIndexes = filter.transactionTypes.map((t) => t.index).toList();
      final placeholders = List.filled(typeIndexes.length, '?').join(', ');
      conditions.add('type IN ($placeholders)');
      args.addAll(typeIndexes);
    }

    // 3. Categories Condition
    if (filter.categoryIds.isNotEmpty) {
      final placeholders = List.filled(filter.categoryIds.length, '?').join(', ');
      conditions.add('(category IN ($placeholders) OR sub_category IN ($placeholders))');
      args.addAll(filter.categoryIds);
      args.addAll(filter.categoryIds);
    }

    // 4. Accounts Condition
    if (filter.accountIds.isNotEmpty) {
      final placeholders = List.filled(filter.accountIds.length, '?').join(', ');
      conditions.add('account_id IN ($placeholders)');
      args.addAll(filter.accountIds);
    }

    // 5. Amount Range Condition
    if (filter.minAmount != null) {
      conditions.add('amount >= ?');
      args.add(filter.minAmount);
    }
    if (filter.maxAmount != null) {
      conditions.add('amount <= ?');
      args.add(filter.maxAmount);
    }

    // 6. Global Search Query Condition
    final query = filter.searchQuery.trim();
    if (query.isNotEmpty) {
      conditions.add('(title LIKE ? OR merchant LIKE ? OR notes LIKE ? OR tags LIKE ? OR reference_number LIKE ?)');
      final term = '%$query%';
      args.addAll([term, term, term, term, term]);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : '1 = 1';

    // Order By Field Mapping
    String orderField = 'date';
    switch (filter.sortBy) {
      case SortByField.amount:
        orderField = 'amount';
        break;
      case SortByField.category:
        orderField = 'category';
        break;
      case SortByField.merchant:
        orderField = 'merchant';
        break;
      case SortByField.date:
        orderField = 'date';
        break;
    }
    final orderBy = '$orderField ${filter.isAscending ? 'ASC' : 'DESC'}';

    return FilterQueryResult(
      whereClause: whereClause,
      whereArgs: args,
      orderBy: orderBy,
    );
  }

  static DateTimeRange? _calculateDateBounds(GlobalFilterState filter, {int? activeYear, int? activeMonth}) {
    if (filter.timeRangePreset == TimeRangePreset.allTime) {
      return null;
    }

    final now = DateTime.now();

    if (filter.timeRangePreset == TimeRangePreset.custom && filter.startDate != null && filter.endDate != null) {
      return DateTimeRange(start: filter.startDate!, end: filter.endDate!);
    }

    switch (filter.timeRangePreset) {
      case TimeRangePreset.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case TimeRangePreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day, 0, 0, 0);
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);

      case TimeRangePreset.last7Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

      case TimeRangePreset.last15Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 15)), end: now);

      case TimeRangePreset.last30Days:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

      case TimeRangePreset.thisMonth:
      default:
        final year = activeYear ?? now.year;
        final month = activeMonth ?? now.month;
        final start = DateTime(year, month, 1, 0, 0, 0);
        final lastDay = DateTime(year, month + 1, 0).day;
        final end = DateTime(year, month, lastDay, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
    }
  }
}
