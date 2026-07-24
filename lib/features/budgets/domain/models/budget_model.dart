import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'budget_period.dart';

@immutable
class BudgetModel {
  final String id;
  final String name;
  final String categoryId;

  /// All categories this budget covers. A budget can span multiple categories;
  /// a category belongs to at most one budget. [categoryId] is the first of
  /// this list, kept for backward compatibility.
  final List<String> categoryIds;
  final double amountLimit;
  final BudgetPeriodType periodType;
  final CarryForwardRule carryForwardRule;
  final double carryForwardAmount;
  final double transferredAmount;
  final double recoveredAmount;
  final double alertThreshold; // e.g. 0.8 = 80%
  final bool isActive;
  final int? startDate;
  final int? endDate;

  const BudgetModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amountLimit,
    List<String>? categoryIds,
    this.periodType = BudgetPeriodType.monthly,
    this.carryForwardRule = CarryForwardRule.carryRemaining,
    this.carryForwardAmount = 0.0,
    this.transferredAmount = 0.0,
    this.recoveredAmount = 0.0,
    this.alertThreshold = 0.8,
    this.isActive = true,
    this.startDate,
    this.endDate,
  }) : categoryIds = categoryIds ?? const [];

  /// Effective category set — falls back to the single [categoryId] for
  /// legacy budgets that predate multi-category support.
  List<String> get effectiveCategoryIds =>
      categoryIds.isNotEmpty ? categoryIds : [categoryId];

  BudgetModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    List<String>? categoryIds,
    double? amountLimit,
    BudgetPeriodType? periodType,
    CarryForwardRule? carryForwardRule,
    double? carryForwardAmount,
    double? transferredAmount,
    double? recoveredAmount,
    double? alertThreshold,
    bool? isActive,
    int? startDate,
    int? endDate,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      amountLimit: amountLimit ?? this.amountLimit,
      periodType: periodType ?? this.periodType,
      carryForwardRule: carryForwardRule ?? this.carryForwardRule,
      carryForwardAmount: carryForwardAmount ?? this.carryForwardAmount,
      transferredAmount: transferredAmount ?? this.transferredAmount,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toMap() {
    final ids = effectiveCategoryIds;
    return {
      'id': id,
      'name': name,
      'category_id': ids.first,
      'category_ids': jsonEncode(ids),
      'category_name': name,
      'amount_limit': amountLimit,
      'period_type': periodType.toDbString(),
      'carry_forward_rule': carryForwardRule.toDbString(),
      'carry_forward_amount': carryForwardAmount,
      'transferred_amount': transferredAmount,
      'recovered_amount': recoveredAmount,
      'alert_threshold': alertThreshold,
      'is_active': isActive ? 1 : 0,
      'start_date': startDate,
      'end_date': endDate,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    final rawIds = map['category_ids'];
    List<String> parsedIds = const [];
    if (rawIds is String && rawIds.trim().isNotEmpty) {
      try {
        parsedIds = (jsonDecode(rawIds) as List).map((e) => e.toString()).toList();
      } catch (_) {
        parsedIds = const [];
      }
    }
    final primaryId = (map['category_id'] ?? 'cat_general') as String;
    return BudgetModel(
      id: map['id'] as String,
      name: (map['name'] ?? map['category_name'] ?? 'Spending Limit') as String,
      categoryId: primaryId,
      categoryIds: parsedIds.isNotEmpty ? parsedIds : [primaryId],
      amountLimit: ((map['amount_limit'] ?? 0.0) as num).toDouble(),
      periodType: BudgetPeriodType.fromDbString(map['period_type'] as String?),
      carryForwardRule: CarryForwardRule.fromDbString(
        map['carry_forward_rule'] as String? ?? map['carry_forward']?.toString(),
      ),
      carryForwardAmount: ((map['carry_forward_amount'] ?? 0.0) as num).toDouble(),
      transferredAmount: ((map['transferred_amount'] ?? 0.0) as num).toDouble(),
      recoveredAmount: ((map['recovered_amount'] ?? 0.0) as num).toDouble(),
      alertThreshold: ((map['alert_threshold'] ?? 0.8) as num).toDouble(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      startDate: map['start_date'] as int?,
      endDate: map['end_date'] as int?,
    );
  }
}
