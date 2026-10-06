import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/github_content_client.dart';
import '../network/github_sources.dart';
import '../storage/preferences_cache.dart';
import 'app_config.dart';

class ConfigService {
  static const settingsUrl = GitHubSources.settings;
  static const fetchIntervalHours = 1;

  static Future<void> loadCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = PreferencesCache(prefs);
    try {
      AppConfiguration.current.value = AppConfig.fromJson({
        'storyUrls': cache.readJson('storyUrls') ?? [],
        'contributors': cache.readJson('contributors') ?? [],
        'name_1st_tab': prefs.getString('name_1st_tab') ?? 'Horizon',
        'markdownContent_1st_tab':
            prefs.getString('markdownContent_1st_tab') ?? '',
        'showFirstTab': prefs.getBool('showFirstTab') ?? true,
      });
    } catch (error) {
      debugPrint('Error loading cached configuration: $error');
    }
  }

  static Future<void> fetchAndUpdateConfig({
    http.Client? client,
    DateTime Function()? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = (now ?? DateTime.now)();
    final lastFetch = DateTime.tryParse(prefs.getString('lastFetchDate') ?? '');
    if (lastFetch != null &&
        date.difference(lastFetch).inHours < fetchIntervalHours) {
      return;
    }
    try {
      final text = await GitHubContentClient(
        client: client,
      ).getText(settingsUrl);
      // Parse fully before publishing; malformed settings cannot partially update views.
      final config = AppConfig.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
      final cache = PreferencesCache(prefs);
      await cache.writeJson('storyUrls', config.stories);
      await cache.writeJson('contributors', config.contributors);
      await prefs.setString('name_1st_tab', config.firstTabName);
      await prefs.setString('markdownContent_1st_tab', config.firstTabMarkdown);
      await prefs.setBool('showFirstTab', config.showFirstTab);
      await prefs.setString('lastFetchDate', date.toIso8601String());
      AppConfiguration.current.value = config;
    } catch (error) {
      debugPrint('Error fetching configuration: $error');
    }
  }
}
