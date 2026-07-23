import 'package:flutter/foundation.dart';

enum AccountType { cash, bank, savings, creditCard, investment }

@immutable
class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final int colorValue;
  final bool isActive;
  final int updatedAt;

  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.colorValue,
    this.isActive = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'currency': currency,
      'color_value': colorValue,
      'is_active': isActive ? 1 : 0,
      'updated_at': updatedAt,
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.cash,
      ),
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String,
      colorValue: map['color_value'] as int,
      isActive: (map['is_active'] as int) == 1,
      updatedAt: map['updated_at'] as int,
    );
  }
}
