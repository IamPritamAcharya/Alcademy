import 'package:port/core/network/github_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Update GitHub URLs in existing content caches without resetting user data.
Future<void> migrateGitHubContentCache(SharedPreferences preferences) async {
  const marker = 'github_content_migrated_to_alcademy_v1';
  if (preferences.getBool(marker) == true) return;
  for (final key in [
    'selectedYearUrl',
    'cachedYearLinks',
    'storyUrls',
    'amenities_data',
    'markdownContent_1st_tab',
  ]) {
    final text = preferences.getString(key);
    if (text != null) {
      await preferences.setString(key, GitHubSources.migrateLegacyLinks(text));
    }
  }
  // Refresh settings from their new location on the next online startup.
  await preferences.remove('lastFetchDate');
  await preferences.setBool(marker, true);
}
