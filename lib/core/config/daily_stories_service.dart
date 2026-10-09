import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:port/core/config/app_config.dart';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';

/// Automatic stories are separate from manually curated settings.
abstract final class DailyStoriesService {
  static const _cacheKey = 'dailyStoriesFeed';
  static const _checkedKey = 'dailyStoriesCheckedAt';
  static bool _refreshing = false;
  static bool _watching = false;
  static Timer? _resetTimer;

  /// Next 10am in India, independent of the device's selected timezone.
  static DateTime expiresAt(DateTime fetchedAt) {
    final utc = fetchedAt.toUtc();
    final india = utc.add(const Duration(hours: 5, minutes: 30));
    final today = DateTime.utc(india.year, india.month, india.day, 4, 30);
    return utc.isBefore(today) ? today : today.add(const Duration(days: 1));
  }

  static Future<void> startUpdates() async {
    _watching = true;
    await refresh();
  }

  static void stopUpdates() {
    _watching = false;
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  static Future<void> _scheduleReset() async {
    _resetTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    if (!_watching) return;
    final now = DateTime.now();
    final fetched = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
    final fresh = readCached(prefs, now: now).isNotEmpty;
    final delay = fresh && fetched != null
        ? expiresAt(fetched).difference(now)
        : const Duration(minutes: 15);
    _resetTimer = Timer(delay, () => unawaited(refresh()));
  }

  static List<Map<String, String>> parse(String raw, DateTime now) {
    if (raw.length > 100000) throw const FormatException('Feed too large');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 2) {
      throw const FormatException('Unknown feed version');
    }
    final generated = DateTime.parse(json['generatedAt'] as String);
    final expires = DateTime.parse(json['expiresAt'] as String);
    if (generated.isAfter(now.add(const Duration(hours: 1))) ||
        !expires.isAfter(generated) ||
        expires.difference(generated) > const Duration(days: 3)) {
      throw const FormatException('Invalid feed dates');
    }
    if (!now.isBefore(expires)) return [];
    final items = json['stories'] as List;
    if (items.length > 16) throw const FormatException('Too many stories');
    final seen = <String>{};
    final stories = <Map<String, String>>[];
    for (final value in items) {
      final item = Map<String, String>.from(value as Map);
      if ((item['title'] ?? '').trim().isEmpty ||
          (item['description'] ?? '').trim().isEmpty) {
        continue;
      }
      final id = item['id'];
      final source = Uri.tryParse(item['sourceUrl'] ?? '');
      if (id == null ||
          !seen.add(id) ||
          source?.scheme != 'https' ||
          source!.host.isEmpty) {
        throw const FormatException('Invalid story');
      }
      if (item['kind'] != 'news' || item['type'] != 'news') {
        throw const FormatException('Unknown story type');
      }
      final image = Uri.tryParse(item['imageUrl'] ?? '');
      if (image?.scheme != 'https' ||
          image!.host.isEmpty ||
          !{'tech', 'india'}.contains(item['category'])) {
        throw const FormatException('News needs an image and category');
      }
      stories.add(item);
    }
    return stories;
  }

  static List<Map<String, String>> readCached(
    SharedPreferences prefs, {
    DateTime? now,
  }) {
    try {
      final raw = prefs.getString(_cacheKey);
      final date = now ?? DateTime.now();
      final fetched = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
      if (raw == null ||
          fetched == null ||
          date.isBefore(fetched) ||
          !date.isBefore(expiresAt(fetched))) {
        return [];
      }
      return parse(raw, date);
    } catch (_) {
      return [];
    }
  }

  static Future<void> refresh({
    http.Client? client,
    DateTime Function()? now,
  }) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = (now ?? DateTime.now)();
      final cached = readCached(prefs, now: date);
      final current = AppConfiguration.current.value;
      // Expired stories disappear even when the subsequent request fails.
      if (cached.isEmpty && current.dailyStories.isNotEmpty) {
        _publish([]);
      }
      if (cached.isNotEmpty) {
        _publish(cached);
        return;
      }
      // Remove the previous period's snapshot even when offline.
      await prefs.remove(_cacheKey);
      await prefs.remove(_checkedKey);
      final raw = await GitHubContentClient(
        client: client,
      ).getText(GitHubSources.dailyStories, cacheBust: true);
      final fetchedAt = (now ?? DateTime.now)();
      final items = parse(raw, fetchedAt);
      if (items.isEmpty) return;
      await prefs.setString(_cacheKey, raw);
      await prefs.setString(_checkedKey, fetchedAt.toUtc().toIso8601String());
      _publish(items);
    } catch (error) {
      debugPrint('Daily stories refresh failed: $error');
    } finally {
      _refreshing = false;
      if (_watching) await _scheduleReset();
    }
  }

  static void _publish(List<Map<String, String>> items) {
    final current = AppConfiguration.current.value;
    AppConfiguration.current.value = AppConfig(
      stories: current.customStories,
      contributors: current.contributors,
      dailyStories: items,
    );
  }
}
