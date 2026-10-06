import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:port/core/storage/preferences_cache.dart';
import 'package:port/features/notes/models/note_year.dart';

class NotesRepository {
  static const yearsUrl = GitHubSources.noteYears;
  static const yearsCacheKey = 'cachedYearLinks';
  static const selectedYearKey = 'selectedYearUrl';
  final GitHubContentClient _content;
  final Future<SharedPreferences> Function() _preferences;

  NotesRepository({
    http.Client? client,
    Future<SharedPreferences> Function()? preferences,
  }) : _content = GitHubContentClient(client: client),
       _preferences = preferences ?? SharedPreferences.getInstance;

  Future<List<NoteYear>> getYears({bool forceRefresh = false}) async {
    final cache = PreferencesCache(await _preferences());
    if (!forceRefresh) {
      final cached = cache.readJson(yearsCacheKey);
      if (cached is List) {
        try {
          return cached
              .map(
                (entry) =>
                    NoteYear.fromJson(Map<String, dynamic>.from(entry as Map)),
              )
              .toList();
        } on FormatException {
          // Recover invalid caches through the existing remote source.
        } on TypeError {
          // Old or malformed data should not leave the selector loading forever.
        }
      }
    }
    final files = jsonDecode(await _content.getText(yearsUrl)) as List;
    final years = files
        .where(
          (file) =>
              file['name'] is String &&
              (file['name'] as String).endsWith('.json'),
        )
        .map(
          (file) => NoteYear(
            name: (file['name'] as String).replaceAll('.json', ''),
            url: file['download_url'] as String,
          ),
        )
        .toList();
    await cache.writeJson(
      yearsCacheKey,
      years.map((year) => year.toJson()).toList(),
    );
    return years;
  }

  Future<String?> getSelectedYear() async =>
      (await _preferences()).getString(selectedYearKey);

  Future<void> selectYear(String url) async {
    await (await _preferences()).setString(selectedYearKey, url);
  }
}
