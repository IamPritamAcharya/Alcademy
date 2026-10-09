import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/github_content_client.dart';
import '../network/github_sources.dart';
import '../storage/preferences_cache.dart';
import 'app_config.dart';
import 'daily_stories_service.dart';
import 'local_stories_preview.dart';

class ConfigService {
  static const settingsUrl = GitHubSources.settings;
  static const fetchIntervalHours = 1;

  static Future<void> loadCachedConfig() async {
    if (LocalStoriesPreview.enabled) {
      AppConfiguration.current.value = await LocalStoriesPreview.load();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    // Remove obsolete configuration and experimental story caches.
    for (final key in [
      'name_1st_tab',
      'markdownContent_1st_tab',
      'showFirstTab',
      'redditMemes',
      'redditMemesFetchedAt',
      'redditMemesAttemptAt',
    ]) {
      if (prefs.containsKey(key)) await prefs.remove(key);
    }
    final cache = PreferencesCache(prefs);
    try {
      AppConfiguration.current.value = AppConfig.fromJson({
        'storyUrls': cache.readJson('storyUrls') ?? [],
        'dailyStories': DailyStoriesService.readCached(prefs),
        'contributors': cache.readJson('contributors') ?? [],
      });
    } catch (error) {
      debugPrint('Error loading cached configuration: $error');
    }
  }

  static Future<void> fetchAndUpdateConfig({
    http.Client? client,
    DateTime Function()? now,
  }) async {
    if (LocalStoriesPreview.enabled) {
      AppConfiguration.current.value = await LocalStoriesPreview.load();
      return;
    }
    await Future.wait([
      _fetchSettings(client: client, now: now),
      DailyStoriesService.refresh(client: client, now: now),
    ]);
  }

  static Future<void> _fetchSettings({
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
      await cache.writeJson('storyUrls', config.customStories);
      await cache.writeJson('contributors', config.contributors);
      await prefs.setString('lastFetchDate', date.toIso8601String());
      AppConfiguration.current.value = AppConfig(
        stories: config.customStories,
        contributors: config.contributors,
        dailyStories: AppConfiguration.current.value.dailyStories,
      );
    } catch (error) {
      debugPrint('Error fetching configuration: $error');
    }
  }
}
