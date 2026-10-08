import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../college_resources/data/erp_session_manager.dart';
import '../models/attendance.dart';

class AttendanceCache {
  const AttendanceCache();

  /// Calendar boundary in device local time; before 9am use today's 9am.
  static DateTime expiresAt(DateTime fetchedAt) {
    final local = fetchedAt.toLocal();
    final today = DateTime(local.year, local.month, local.day, 9);
    return local.isBefore(today)
        ? today
        : DateTime(local.year, local.month, local.day + 1, 9);
  }

  Future<Attendance?> read(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ErpSessionManager.attendanceCacheKey);
    if (raw == null) return null;
    try {
      final data = Attendance.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (!now.isBefore(expiresAt(data.fetchedAt)) ||
          now.isBefore(data.fetchedAt)) {
        await prefs.remove(ErpSessionManager.attendanceCacheKey);
        return null;
      }
      return data;
    } catch (_) {
      await prefs.remove(ErpSessionManager.attendanceCacheKey);
      return null;
    }
  }

  Future<void> write(Attendance data) async =>
      (await SharedPreferences.getInstance()).setString(
        ErpSessionManager.attendanceCacheKey,
        jsonEncode(data.toJson()),
      );
}
