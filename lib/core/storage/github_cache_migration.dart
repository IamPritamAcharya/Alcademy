import 'package:port/core/network/github_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Update GitHub URLs in existing content caches without resetting user data.
Future<void> migrateGitHubContentCache(SharedPreferences preferences) async {
  const marker = 'github_content_cleanup_v3';
  if (preferences.getBool(marker) == true) return;
  for (final key in [
    'selectedYearUrl',
    'cachedYearLinks',
    'storyUrls',
    'amenities_data',
  ]) {
    final text = preferences.getString(key);
    if (text != null) {
      await preferences.setString(key, GitHubSources.migrateLegacyLinks(text));
    }
  }
  // Refresh settings from their new location on the next online startup.
  await preferences.remove('lastFetchDate');
  // The college holiday document has changed from 2025 to 2026.
  await preferences.remove('holiday_list_url');
  await preferences.remove('holiday_list_last_updated');
  await preferences.setBool(marker, true);
}
