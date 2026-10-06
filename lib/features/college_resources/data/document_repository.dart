import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:port/core/storage/preferences_cache.dart';

class DocumentDefinition {
  final String title;
  final String sourceUrl;
  final String cacheKey;
  final String updatedKey;
  final String jsonKey;
  const DocumentDefinition({
    required this.title,
    required this.sourceUrl,
    required this.cacheKey,
    required this.updatedKey,
    required this.jsonKey,
  });

  static const calendar = DocumentDefinition(
    title: 'Academic Calendar',
    sourceUrl: GitHubSources.documents,
    jsonKey: 'academicCalendar',
    cacheKey: 'academic_calendar_url',
    updatedKey: 'academic_calendar_last_updated',
  );
  static const holidays = DocumentDefinition(
    title: 'Holiday List: 2026',
    sourceUrl: GitHubSources.documents,
    jsonKey: 'holidays',
    cacheKey: 'holiday_list_url',
    updatedKey: 'holiday_list_last_updated',
  );
}

class DocumentRepository {
  final GitHubContentClient _content;
  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;
  DocumentRepository({
    http.Client? client,
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? now,
  }) : _content = GitHubContentClient(client: client),
       _preferences = preferences ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  Future<String> getUrl(DocumentDefinition document) async {
    final cache = PreferencesCache(await _preferences());
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final cached = cache.readFreshString(
      document.cacheKey,
      document.updatedKey,
      today,
    );
    if (cached != null) return cached;
    final data =
        jsonDecode(await _content.getText(document.sourceUrl))
            as Map<String, dynamic>;
    final url = (data[document.jsonKey] as String).trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('The document URL is invalid.');
    }
    await cache.writeString(document.cacheKey, url, document.updatedKey, now);
    return url;
  }
}
