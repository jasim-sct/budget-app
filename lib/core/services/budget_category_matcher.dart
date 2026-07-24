import '../../features/budgets/domain/models/budget_model.dart';

/// Resolves all lowercase keys that can match a budget to a transaction
/// category. Multi-category aware: covers every category the budget spans.
Set<String> budgetCategoryMatchKeys(
  BudgetModel budget, {
  Map<String, String>? categoryIdToName,
}) {
  final keys = <String>{};
  void add(String? value) {
    final v = value?.trim().toLowerCase();
    if (v != null && v.isNotEmpty) keys.add(v);
  }

  for (final id in budget.effectiveCategoryIds) {
    add(id);
    add(categoryIdToName?[id]);
    final lower = id.toLowerCase();
    if (lower.startsWith('cat_') && lower.length > 4) {
      add(lower.substring(4).replaceAll('_', ' '));
    }
  }
  // Legacy fallback for single-category budgets named after their category.
  add(budget.name);

  return keys;
}

/// The distinct transaction-category NAMES (lowercased) a budget covers — one
/// per category, so spend can be summed without double counting.
Set<String> budgetCategoryNameKeys(
  BudgetModel budget, {
  Map<String, String>? categoryIdToName,
}) {
  final names = <String>{};
  void add(String? value) {
    final v = value?.trim().toLowerCase();
    if (v != null && v.isNotEmpty) names.add(v);
  }

  for (final id in budget.effectiveCategoryIds) {
    final mapped = categoryIdToName?[id];
    if (mapped != null && mapped.trim().isNotEmpty) {
      add(mapped);
    } else if (id.toLowerCase().startsWith('cat_') && id.length > 4) {
      add(id.substring(4).replaceAll('_', ' '));
    } else {
      add(id);
    }
  }
  if (names.isEmpty) add(budget.name);
  return names;
}

/// Sums spend across every category a budget covers (multi-category aware).
/// For a single-category budget the distinct-name set has one entry, so this
/// matches the old first-match behaviour exactly.
double spentForBudgetKeys(Map<String, double> spendingMap, Set<String> keys) {
  // [keys] here are distinct category names (from budgetCategoryNameKeys).
  var total = 0.0;
  var matched = false;
  for (final key in keys) {
    final value = spendingMap[key];
    if (value != null) {
      total += value;
      matched = true;
    }
  }
  return matched ? total : 0.0;
}

int countForBudgetKeys(Map<String, int> countMap, Set<String> keys) {
  var total = 0;
  for (final key in keys) {
    total += countMap[key] ?? 0;
  }
  return total;
}
