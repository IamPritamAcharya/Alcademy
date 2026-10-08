import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../college_resources/data/erp_session_manager.dart';
import '../models/student_results.dart';

class ResultsCache {
  const ResultsCache();
  static DateTime expiresAt(DateTime fetchedAt) {
    final local = fetchedAt.toLocal();
    return DateTime(local.year, local.month + 1);
  }

  Future<StudentResults?> read(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ErpSessionManager.resultsCacheKey);
    if (raw == null) return null;
    try {
      final data = StudentResults.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final fetched = data.fetchedAt.toLocal();
      if (!data.complete ||
          now.isBefore(fetched) ||
          fetched.year != now.year ||
          fetched.month != now.month) {
        await prefs.remove(ErpSessionManager.resultsCacheKey);
        return null;
      }
      return data;
    } catch (_) {
      await prefs.remove(ErpSessionManager.resultsCacheKey);
      return null;
    }
  }

  Future<void> write(StudentResults data) async {
    if (!data.complete) return;
    await (await SharedPreferences.getInstance()).setString(
      ErpSessionManager.resultsCacheKey,
      jsonEncode(data.toJson()),
    );
  }
}
