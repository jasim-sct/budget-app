import 'package:flutter/material.dart';

/// Notifier managing light/dark theme switching across the app.
class ThemeProvider extends ValueNotifier<ThemeMode> {
  ThemeProvider() : super(ThemeMode.light);

  bool get isDarkMode => value == ThemeMode.dark;

  void toggleTheme() {
    value = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    value = mode;
  }

  static final ThemeProvider instance = ThemeProvider();
}
