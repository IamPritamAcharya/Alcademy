import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/core/network/app_http_client.dart';
import 'package:port/core/storage/preferences_cache.dart';

class DocumentDefinition {
  final String title;
  final String sourceUrl;
  final String cacheKey;
  final String updatedKey;
  const DocumentDefinition(
      {required this.title,
      required this.sourceUrl,
      required this.cacheKey,
      required this.updatedKey});

  static const calendar = DocumentDefinition(
      title: 'Academic Calendar',
      sourceUrl:
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/academic_calender.txt',
      cacheKey: 'academic_calendar_url',
      updatedKey: 'academic_calendar_last_updated');
  static const holidays = DocumentDefinition(
      title: 'Holiday List: 2025',
      sourceUrl:
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/holiday_list.txt',
      cacheKey: 'holiday_list_url',
      updatedKey: 'holiday_list_last_updated');
}

class DocumentRepository {
  final http.Client _client;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;
  DocumentRepository(
      {http.Client? client,
      Future<SharedPreferences> Function()? preferences,
      DateTime Function()? now})
      : _client = client ?? appHttpClient,
        _preferences = preferences ?? SharedPreferences.getInstance,
        _now = now ?? DateTime.now;

  Future<String> getUrl(DocumentDefinition document) async {
    final cache = PreferencesCache(await _preferences());
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final cached =
        cache.readFreshString(document.cacheKey, document.updatedKey, today);
    if (cached != null) return cached;
    final response = await _client
        .get(Uri.parse(document.sourceUrl))
        .timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch document URL.');
    }
    final url = response.body.trim();
    if (url.isEmpty) throw const FormatException('The fetched URL is empty.');
    await cache.writeString(document.cacheKey, url, document.updatedKey, now);
    return url;
  }
}
