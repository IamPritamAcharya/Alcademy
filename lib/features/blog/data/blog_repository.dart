import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';

class BlogRepository {
  static final instance = BlogRepository();
  static const sourceUrl = GitHubSources.blogs;
  final GitHubContentClient _contentClient;
  final DateTime Function() _now;

  BlogRepository({http.Client? client, DateTime Function()? now})
    : _contentClient = GitHubContentClient(client: client),
      _now = now ?? DateTime.now;

  static const _cacheKey = 'blogsFeed';
  static const _updatedKey = 'blogsUpdatedAt';
  Future<List<Map<String, String>>>? _pending;

  static DateTime expiresAt(DateTime fetched) {
    final india = fetched.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateTime.utc(
      india.year,
      india.month + 1,
    ).subtract(const Duration(hours: 5, minutes: 30));
  }

  static List<Map<String, String>> parse(String raw) {
    if (raw.length > 1024 * 1024) {
      throw const FormatException('Blogs feed too large');
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) throw const FormatException('Unknown blogs feed');
    final items = json['blogs'] as List;
    if (items.length > 200) throw const FormatException('Too many articles');
    final seen = <String>{};
    final blogs = <Map<String, String>>[];
    for (final item in items) {
      final blog = Map<String, String>.from(item as Map);
      for (final key in ['id', 'title', 'body']) {
        if ((blog[key] ?? '').trim().isEmpty) {
          throw FormatException('Article missing $key');
        }
      }
      if (!seen.add(blog['id']!)) {
        throw const FormatException('Duplicate article id');
      }
      // Preserve the body verbatim: whitespace and Markdown belong to content.
      blogs.add(Map.unmodifiable(blog));
    }
    return List.unmodifiable(blogs);
  }

  Future<List<Map<String, String>>> fetchBlogs({
    bool forceRefresh = false,
  }) async {
    if (_pending != null) return _pending!;
    final operation = _fetchBlogs(forceRefresh: forceRefresh);
    _pending = operation;
    try {
      return await operation;
    } finally {
      _pending = null;
    }
  }

  Future<List<Map<String, String>>> _fetchBlogs({
    required bool forceRefresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _now();
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
      final raw = await _contentClient.getText(sourceUrl, cacheBust: true);
      final blogs = parse(raw);
      await prefs.setString(_cacheKey, raw);
      await prefs.setString(_updatedKey, _now().toUtc().toIso8601String());
      return blogs;
    } catch (error) {
      if (cached != null) {
        debugPrint('Blogs refresh failed; using saved articles: $error');
        return cached;
      }
      rethrow;
    }
  }
}
