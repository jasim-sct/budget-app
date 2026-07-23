import 'package:flutter/foundation.dart';

@immutable
class BudgetModel {
  final String id;
  final String name;
  final String categoryId;
  final double amountLimit;
  final String periodType; // monthly, weekly, yearly
  final double alertThreshold; // 0.8 = 80%
  final bool isActive;

  const BudgetModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amountLimit,
    this.periodType = 'monthly',
    this.alertThreshold = 0.8,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'category_name': name,
      'amount_limit': amountLimit,
      'period_type': periodType,
      'alert_threshold': alertThreshold,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      name: (map['name'] ?? map['category_name'] ?? 'Spending Limit') as String,
      categoryId: (map['category_id'] ?? 'cat_general') as String,
      amountLimit: ((map['amount_limit'] ?? 0.0) as num).toDouble(),
      periodType: (map['period_type'] ?? 'monthly') as String,
      alertThreshold: ((map['alert_threshold'] ?? 0.8) as num).toDouble(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
