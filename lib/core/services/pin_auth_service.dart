import '../services/user_settings_store.dart';

/// Persists and reads the app security PIN from SQLite app storage.
class PinAuthService {
  PinAuthService._();
  static final PinAuthService instance = PinAuthService._();

  Future<String?> getPin() async {
    final value = await UserSettingsStore.instance.getPin();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.length == 4;
  }

  Future<void> savePin(String pin) async {
    if (pin.length != 4) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
    await UserSettingsStore.instance.setPin(pin);
  }

  Future<void> clearPin() async {
    await UserSettingsStore.instance.clearPin();
  }
}
