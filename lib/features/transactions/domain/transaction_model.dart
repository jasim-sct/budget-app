import 'package:flutter/foundation.dart';

enum TransactionType { expense, income }

@immutable
class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final int dateMilliseconds;
  final String category;
  final TransactionType type;
  final String? accountId;
  final String? accountName;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dateMilliseconds,
    required this.category,
    required this.type,
    this.accountId,
    this.accountName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': dateMilliseconds,
      'category': category,
      'type': type == TransactionType.income ? 1 : 0,
      'account_id': accountId ?? 'acc_cash',
      'account_name': accountName ?? 'Cash Wallet',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dateMilliseconds: map['date'] as int,
      category: map['category'] as String,
      type: (map['type'] as int) == 1 ? TransactionType.income : TransactionType.expense,
      accountId: map['account_id'] as String?,
      accountName: map['account_name'] as String?,
    );
  }
}
