import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Cookie sessions are shared by the ERP and timetable browser controllers.
/// A changed/deleted login must not reuse the previous student's session.
abstract final class ErpSessionManager {
  static const invalidatedKey = 'erp_session_invalidated';
  static const timetableCacheKey = 'erp_timetable_cache_v1';
  static const attendanceCacheKey = 'erp_attendance_cache_v1';
  static const resultsCacheKey = 'erp_results_cache_v1';
  static const feesCacheKey = 'erp_fees_cache_v1';
  static const holidaysCacheKey = 'erp_holidays_cache_v1';

  static Future<void> invalidate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(timetableCacheKey);
    await prefs.remove(attendanceCacheKey);
    await prefs.remove(resultsCacheKey);
    await prefs.remove(feesCacheKey);
    await prefs.remove(holidaysCacheKey);
    await prefs.setBool(invalidatedKey, true);
  }

  static Future<void> prepare({Future<bool> Function()? clearCookies}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(invalidatedKey) != true) return;
    await (clearCookies ?? WebViewCookieManager().clearCookies)();
    await prefs.remove(invalidatedKey);
  }
}
