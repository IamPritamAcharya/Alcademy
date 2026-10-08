import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../college_resources/data/erp_session_manager.dart';
import '../models/timetable.dart';

/// Successful fetches are valid through the end of their local calendar month.
/// Changing or forgetting ERP credentials removes this cache with the session.
class TimetableCache {
  const TimetableCache();

  Future<Timetable?> read(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ErpSessionManager.timetableCacheKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final fetched = DateTime.parse(data['fetchedAt'] as String).toLocal();
      if (fetched.year != now.year ||
          fetched.month != now.month ||
          fetched.isAfter(now)) {
        await prefs.remove(ErpSessionManager.timetableCacheKey);
        return null;
      }
      return Timetable(
        division: data['division'] as String,
        department: data['department'] as String,
        academicYear: data['academicYear'] as String,
        effectiveFrom: data['effectiveFrom'] as String,
        weekdays: List<int>.unmodifiable(data['weekdays'] as List),
        subjects: Map<String, String>.unmodifiable(data['subjects'] as Map),
        faculty: Map<String, String>.unmodifiable(data['faculty'] as Map),
        fetchedAt: fetched,
        lessons: List.unmodifiable(
          (data['lessons'] as List).map(
            (row) => TimetableLesson(
              weekday: row['weekday'] as int,
              startMinute: row['startMinute'] as int,
              endMinute: row['endMinute'] as int,
              classes: List.unmodifiable(
                (row['classes'] as List).map(
                  (item) => TimetableClass(
                    label: item['label'] as String,
                    code: item['code'] as String?,
                    subject: item['subject'] as String?,
                    location: item['location'] as String?,
                    batch: item['batch'] as String?,
                  ),
                ),
              ),
            ),
          ),
        ),
        breaks: List.unmodifiable(
          (data['breaks'] as List).map(
            (row) => TimetableBreak(
              startMinute: row['startMinute'] as int,
              endMinute: row['endMinute'] as int,
              label: row['label'] as String,
            ),
          ),
        ),
      );
    } catch (_) {
      await prefs.remove(ErpSessionManager.timetableCacheKey);
      return null;
    }
  }

  Future<void> write(Timetable data) async {
    await (await SharedPreferences.getInstance()).setString(
      ErpSessionManager.timetableCacheKey,
      jsonEncode({
        'division': data.division,
        'department': data.department,
        'academicYear': data.academicYear,
        'effectiveFrom': data.effectiveFrom,
        'weekdays': data.weekdays,
        'subjects': data.subjects,
        'faculty': data.faculty,
        'fetchedAt': data.fetchedAt.toIso8601String(),
        'lessons': [
          for (final row in data.lessons)
            {
              'weekday': row.weekday,
              'startMinute': row.startMinute,
              'endMinute': row.endMinute,
              'classes': [
                for (final item in row.classes)
                  {
                    'label': item.label,
                    'code': item.code,
                    'subject': item.subject,
                    'location': item.location,
                    'batch': item.batch,
                  },
              ],
            },
        ],
        'breaks': [
          for (final row in data.breaks)
            {
              'startMinute': row.startMinute,
              'endMinute': row.endMinute,
              'label': row.label,
            },
        ],
      }),
    );
  }
}
