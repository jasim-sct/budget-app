import 'package:flutter/foundation.dart';

enum TransactionType { expense, income, transfer }

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
  final String? paymentMethod;
  final String? referenceNumber;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.dateMilliseconds,
    required this.category,
    required this.type,
    this.accountId,
    this.accountName,
    this.paymentMethod,
    this.referenceNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'date': dateMilliseconds,
      'category': category,
      'type': type == TransactionType.income
          ? 1
          : (type == TransactionType.transfer ? 2 : 0),
      'account_id': accountId ?? 'acc_cash',
      'account_name': accountName ?? 'Cash Wallet',
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (referenceNumber != null) 'reference_number': referenceNumber,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final typeCode = map['type'] as int? ?? 0;
    final TransactionType resolvedType;
    if (typeCode == 1) {
      resolvedType = TransactionType.income;
    } else if (typeCode == 2) {
      resolvedType = TransactionType.transfer;
    } else {
      resolvedType = TransactionType.expense;
    }

    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dateMilliseconds: map['date'] as int,
      category: map['category'] as String,
      type: resolvedType,
      accountId: map['account_id'] as String?,
      accountName: map['account_name'] as String?,
      paymentMethod: map['payment_method'] as String?,
      referenceNumber: map['reference_number'] as String?,
    );
  }
}
