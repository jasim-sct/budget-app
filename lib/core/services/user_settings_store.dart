import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../database/database_helper.dart';

/// Single write-through settings store backed by SQLite `user_settings`
/// in Android/Linux app-private storage. Every write is flushed to disk.
class UserSettingsStore {
  UserSettingsStore._();
  static final UserSettingsStore instance = UserSettingsStore._();

  static const String keyCurrencyCode = 'currency_code';

  Future<String?> get(String key) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await DatabaseHelper.instance.forcePersistToDisk();
  }

  Future<void> remove(String key) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    await DatabaseHelper.instance.forcePersistToDisk();
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final raw = await get(key);
    if (raw == null) return defaultValue;
    return raw == '1' || raw.toLowerCase() == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await set(key, value ? '1' : '0');
  }

  // Convenience accessors using AppConstants keys
  Future<String?> getThemeMode() => get(AppConstants.keyThemeMode);
  Future<void> setThemeMode(String mode) => set(AppConstants.keyThemeMode, mode);

  Future<String?> getUserName() => get(AppConstants.keyUserName);
  Future<void> setUserName(String name) => set(AppConstants.keyUserName, name);

  Future<String?> getPin() => get(AppConstants.keyUserPin);
  Future<void> setPin(String pin) => set(AppConstants.keyUserPin, pin);
  Future<void> clearPin() => remove(AppConstants.keyUserPin);

  Future<String?> getCurrencyCode() => get(keyCurrencyCode);
  Future<void> setCurrencyCode(String code) => set(keyCurrencyCode, code);

  Future<bool> getBiometricsEnabled() =>
      getBool(AppConstants.keyBiometricsEnabled, defaultValue: false);
  Future<void> setBiometricsEnabled(bool enabled) =>
      setBool(AppConstants.keyBiometricsEnabled, enabled);
}
