import 'package:flutter/material.dart';
import 'user_settings_store.dart';

/// Holds the user's display name app-wide. Reactive: the dashboard greeting,
/// settings profile, and about screen all listen to this single source.
class UserProfileProvider extends ValueNotifier<String> {
  UserProfileProvider() : super(defaultName);

  static const String defaultName = 'Friend';
  static final UserProfileProvider instance = UserProfileProvider();

  /// First name only, for the greeting ("Good Evening, `<first>`").
  String get firstName => value.trim().split(' ').first;

  /// Up-to-two-letter initials for avatars.
  String get initials {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  Future<void> loadSavedName() async {
    final name = await UserSettingsStore.instance.getUserName();
    if (name != null && name.trim().isNotEmpty) {
      value = name.trim();
    }
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    value = trimmed;
    await UserSettingsStore.instance.setUserName(trimmed);
  }
}
