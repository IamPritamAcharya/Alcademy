import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache encoding and expiry mechanics; each feature owns its keys and policy.
class PreferencesCache {
  final SharedPreferences preferences;
  const PreferencesCache(this.preferences);

  Object? readJson(String key) {
    final value = preferences.getString(key);
    if (value == null) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Object value) async {
    await preferences.setString(key, jsonEncode(value));
  }

  String? readFreshString(String key, String updatedKey, DateTime since) {
    final updated = DateTime.tryParse(preferences.getString(updatedKey) ?? '');
    if (updated == null || updated.isBefore(since)) return null;
    return preferences.getString(key);
  }

  Future<void> writeString(
      String key, String value, String updatedKey, DateTime updated) async {
    await preferences.setString(key, value);
    await preferences.setString(updatedKey, updated.toIso8601String());
  }
}
