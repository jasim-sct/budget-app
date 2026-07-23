import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// Data model representing a country currency configuration.
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;
  final String country;

  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
    required this.country,
  });
}

/// Centralized Currency Provider managing active country currency selection across the app.
class CurrencyProvider extends ValueNotifier<CurrencyOption> {
  static const List<CurrencyOption> availableCurrencies = [
    CurrencyOption(code: 'USD', symbol: '\$', name: 'US Dollar', country: 'United States'),
    CurrencyOption(code: 'INR', symbol: '₹', name: 'Indian Rupee', country: 'India'),
    CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro', country: 'Eurozone'),
    CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound', country: 'United Kingdom'),
    CurrencyOption(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', country: 'Canada'),
    CurrencyOption(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', country: 'Australia'),
    CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen', country: 'Japan'),
    CurrencyOption(code: 'AED', symbol: 'AED ', name: 'UAE Dirham', country: 'United Arab Emirates'),
  ];

  CurrencyProvider() : super(availableCurrencies[0]);

  String get currentSymbol => value.symbol;
  String get currentCode => value.code;

  void selectCurrency(CurrencyOption option) {
    value = option;
    _saveSetting(option.code);
  }

  void selectByCode(String code) {
    final match = availableCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => availableCurrencies[0],
    );
    value = match;
    _saveSetting(match.code);
  }

  Future<void> loadSavedCurrency() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: ['currency_code'],
      );
      if (result.isNotEmpty) {
        final code = result.first['value'] as String?;
        if (code != null) {
          final match = availableCurrencies.firstWhere(
            (c) => c.code.toUpperCase() == code.toUpperCase(),
            orElse: () => availableCurrencies[0],
          );
          value = match;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSetting(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'user_settings',
        {'key': 'currency_code', 'value': code},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  static final CurrencyProvider instance = CurrencyProvider();
}
