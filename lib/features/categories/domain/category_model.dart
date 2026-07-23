import 'package:flutter/material.dart';

enum CategoryType { expense, income, transfer, savings, investment, loan, tax, subscription, medical, education, travel, shopping, utilities, entertainment, others }

/// Category Model supporting hierarchical sub-categories, system taxonomy, and custom categories.
class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;
  final int iconCode;
  final int colorValue;
  final String? parentCategoryId;
  final bool isFavorite;
  final bool isHidden;
  final bool isArchived;
  final int sortOrder;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
    this.parentCategoryId,
    this.isFavorite = false,
    this.isHidden = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.description,
  });

  bool get isSubCategory => parentCategoryId != null && parentCategoryId!.isNotEmpty;

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'icon_code': iconCode,
      'color_value': colorValue,
      'parent_id': parentCategoryId,
      'is_favorite': isFavorite ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'description': description,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    final typeIdx = map['type'] as int? ?? 0;
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: typeIdx < CategoryType.values.length ? CategoryType.values[typeIdx] : CategoryType.expense,
      iconCode: map['icon_code'] as int? ?? 0xe25a,
      colorValue: map['color_value'] as int? ?? 0xFF10B981,
      parentCategoryId: map['parent_id'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      description: map['description'] as String?,
    );
  }
}
