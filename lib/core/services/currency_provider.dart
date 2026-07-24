import 'package:flutter/material.dart';
import 'user_settings_store.dart';

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

  Future<void> selectCurrency(CurrencyOption option) async {
    value = option;
    await UserSettingsStore.instance.setCurrencyCode(option.code);
  }

  Future<void> selectByCode(String code) async {
    final match = availableCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => availableCurrencies[0],
    );
    value = match;
    await UserSettingsStore.instance.setCurrencyCode(match.code);
  }

  Future<void> loadSavedCurrency() async {
    final code = await UserSettingsStore.instance.getCurrencyCode();
    if (code == null) return;
    final match = availableCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => availableCurrencies[0],
    );
    value = match;
  }

  static final CurrencyProvider instance = CurrencyProvider();
}
