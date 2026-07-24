import '../../features/budgets/domain/models/budget_model.dart';

/// Resolves all lowercase keys that can match a budget to a transaction category.
Set<String> budgetCategoryMatchKeys(
  BudgetModel budget, {
  Map<String, String>? categoryIdToName,
}) {
  final keys = <String>{};
  void add(String? value) {
    final v = value?.trim().toLowerCase();
    if (v != null && v.isNotEmpty) keys.add(v);
  }

  add(budget.name);
  add(budget.categoryId);

  final mappedName = categoryIdToName?[budget.categoryId];
  add(mappedName);

  // Synthetic ids from free-text budgets: cat_food_dining → try spaced name fallback already covered by budget.name
  final id = budget.categoryId.toLowerCase();
  if (id.startsWith('cat_') && id.length > 4) {
    add(id.substring(4).replaceAll('_', ' '));
  }

  return keys;
}

double spentForBudgetKeys(Map<String, double> spendingMap, Set<String> keys) {
  for (final key in keys) {
    final value = spendingMap[key];
    if (value != null) return value;
  }
  return 0.0;
}

int countForBudgetKeys(Map<String, int> countMap, Set<String> keys) {
  for (final key in keys) {
    final value = countMap[key];
    if (value != null) return value;
  }
  return 0;
}
