abstract class AppConstants {
  static const String appName = 'MJSM';
  static const String appVersion = '1.0.0';
  static const String defaultCurrency = 'USD';
  
  // Performance & Memory Limits
  static const int defaultPageSize = 50;
  static const double fixedListItemExtent = 64.0;
  static const int maxRecentItems = 10;
  
  // Storage Keys
  static const String keyUserPin = 'user_pin_hash';
  static const String keyBiometricsEnabled = 'use_biometrics';
  static const String keyThemeMode = 'theme_mode';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyFirstRun = 'is_first_run';
}
