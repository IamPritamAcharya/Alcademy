import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CachedErpRecords<T> {
  final List<T> records;
  final DateTime fetchedAt;
  const CachedErpRecords(this.records, this.fetchedAt);
}

/// Lists remain fresh through the end of the fetch's local calendar month.
class ErpMonthlyCache<T> {
  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  const ErpMonthlyCache({
    required this.key,
    required this.fromJson,
    required this.toJson,
  });

  static DateTime expiresAt(DateTime fetchedAt) {
    final local = fetchedAt.toLocal();
    return DateTime(local.year, local.month + 1);
  }

  Future<CachedErpRecords<T>?> read(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final fetched = DateTime.parse(data['fetchedAt'] as String).toLocal();
      final localNow = now.toLocal();
      if (fetched.isAfter(localNow) ||
          fetched.year != localNow.year ||
          fetched.month != localNow.month) {
        await prefs.remove(key);
        return null;
      }
      final records = (data['records'] as List).map(
        (row) => fromJson(row as Map<String, dynamic>),
      );
      return CachedErpRecords(List.unmodifiable(records), fetched);
    } catch (_) {
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> write(List<T> records, DateTime fetchedAt) async {
    await (await SharedPreferences.getInstance()).setString(
      key,
      jsonEncode({
        'fetchedAt': fetchedAt.toIso8601String(),
        'records': records.map(toJson).toList(),
      }),
    );
  }
}
