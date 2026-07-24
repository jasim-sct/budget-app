import 'package:flutter/material.dart';

enum CategoryType { expense }

/// Unified Budget Planning Category Model.
class CategoryModel {
  final String id;
  final String name;
  final CategoryType type;
  final int iconCode;
  final int colorValue;
  final bool isFavorite;
  final bool isHidden;
  final bool isArchived;
  final int sortOrder;
  final String? description;

  const CategoryModel({
    required this.id,
    required this.name,
    this.type = CategoryType.expense,
    required this.iconCode,
    required this.colorValue,
    this.isFavorite = false,
    this.isHidden = false,
    this.isArchived = false,
    this.sortOrder = 0,
    this.description,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': 0, // Always 0 (Expense / Budget Category)
      'icon_code': iconCode,
      'color_value': colorValue,
      'parent_id': null,
      'is_favorite': isFavorite ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'sort_order': sortOrder,
      'description': description,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.expense,
      iconCode: map['icon_code'] as int? ?? 0xe25a,
      colorValue: map['color_value'] as int? ?? 0xFF10B981,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      description: map['description'] as String?,
    );
  }
}
