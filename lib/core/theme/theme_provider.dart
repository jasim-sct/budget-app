import 'package:flutter/material.dart';
import '../services/user_settings_store.dart';

/// Notifier managing light/dark theme switching across the app.
/// Persists selection via [UserSettingsStore] (SQLite app storage).
class ThemeProvider extends ValueNotifier<ThemeMode> {
  ThemeProvider() : super(ThemeMode.light);

  bool get isDarkMode => value == ThemeMode.dark;

  void toggleTheme() {
    setThemeMode(value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    await UserSettingsStore.instance.setThemeMode(
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> loadSavedTheme() async {
    final raw = await UserSettingsStore.instance.getThemeMode();
    if (raw == 'dark') {
      value = ThemeMode.dark;
    } else if (raw == 'light') {
      value = ThemeMode.light;
    }
  }

  static final ThemeProvider instance = ThemeProvider();
}
