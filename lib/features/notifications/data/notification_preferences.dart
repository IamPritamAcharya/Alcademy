import 'package:shared_preferences/shared_preferences.dart';

enum NotificationCategory { notices, general }

class NotificationPreferences {
  final bool notices;
  final bool general;
  const NotificationPreferences({this.notices = true, this.general = true});

  bool allows(Map<String, dynamic> data) =>
      data['type'] == 'college_notice' ? notices : general;
}

class NotificationPreferencesRepository {
  const NotificationPreferencesRepository();
  static const noticesKey = 'notification_notices_enabled';
  static const generalKey = 'notification_general_enabled';

  Future<NotificationPreferences> read() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return NotificationPreferences(
      notices: prefs.getBool(noticesKey) ?? true,
      general: prefs.getBool(generalKey) ?? true,
    );
  }

  Future<void> setEnabled(NotificationCategory category, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setBool(
      category == NotificationCategory.notices ? noticesKey : generalKey,
      enabled,
    );
    if (!saved) throw StateError('Could not save notification preference');
  }
}
