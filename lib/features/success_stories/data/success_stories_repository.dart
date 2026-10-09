import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';

class SuccessStoriesRepository {
  static const _cacheKey = 'successStoriesFeed';
  static const _updatedKey = 'successStoriesUpdatedAt';
  static Future<List<Map<String, String>>>? _pending;

  static DateTime expiresAt(DateTime fetched) {
    final india = fetched.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateTime.utc(
      india.year,
      india.month + 1,
    ).subtract(const Duration(hours: 5, minutes: 30));
  }

  static List<Map<String, String>> parse(String raw) {
    if (raw.length > 1024 * 1024) {
      throw const FormatException('Success stories feed too large');
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Unknown story feed');
    final items = json['stories'] as List;
    if (items.length > 200) throw const FormatException('Too many stories');
    final seen = <String>{};
    final stories = <Map<String, String>>[];
    for (final item in items) {
      final story = Map<String, String>.from(item as Map);
      for (final key in ['id', 'name', 'company', 'body', 'image_url']) {
        if ((story[key] ?? '').trim().isEmpty) {
          throw FormatException('Story missing $key');
        }
      }
      final image = Uri.tryParse(story['image_url']!);
      if (!seen.add(story['id']!) ||
          image == null ||
          image.scheme != 'https' ||
          image.host.isEmpty ||
          image.userInfo.isNotEmpty) {
        throw const FormatException('Invalid story metadata');
      }
      // Preserve the body verbatim: whitespace and Markdown belong to content.
      stories.add(Map.unmodifiable(story));
    }
    return List.unmodifiable(stories);
  }

  static Future<List<Map<String, String>>> fetchStories({
    http.Client? client,
    bool forceRefresh = false,
    DateTime Function()? now,
  }) async {
    if (_pending != null) return _pending!;
    final operation = _fetchStories(
      client: client,
      forceRefresh: forceRefresh,
      now: now,
    );
    _pending = operation;
    try {
      return await operation;
    } finally {
      _pending = null;
    }
  }

  static Future<List<Map<String, String>>> _fetchStories({
    http.Client? client,
    required bool forceRefresh,
    DateTime Function()? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = (now ?? DateTime.now)();
    List<Map<String, String>>? cached;
    try {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) cached = parse(raw);
    } catch (_) {
      // A corrupt cache must not prevent a fresh download.
    }
    final updated = DateTime.tryParse(prefs.getString(_updatedKey) ?? '');
    if (!forceRefresh &&
        cached != null &&
        updated != null &&
        !date.isBefore(updated) &&
        date.isBefore(expiresAt(updated))) {
      return cached;
    }
    try {
      final raw = await GitHubContentClient(
        client: client,
      ).getText(GitHubSources.successStories, cacheBust: true);
      final stories = parse(raw);
      await prefs.setString(_cacheKey, raw);
      await prefs.setString(
        _updatedKey,
        (now ?? DateTime.now)().toUtc().toIso8601String(),
      );
      return stories;
    } catch (error) {
      if (cached != null) {
        debugPrint(
          'Success stories refresh failed; using saved stories: $error',
        );
        return cached;
      }
      rethrow;
    }
  }
}
