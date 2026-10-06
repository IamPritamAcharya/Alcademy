import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AmenitiesRepository {
  final GitHubContentClient _content;
  final Future<SharedPreferences> Function() _preferences;

  AmenitiesRepository({
    http.Client? client,
    Future<SharedPreferences> Function()? preferences,
  }) : _content = GitHubContentClient(
         client: client,
         timeout: const Duration(seconds: 20),
       ),
       _preferences = preferences ?? SharedPreferences.getInstance;

  List<Map<String, dynamic>> _parse(String text) =>
      (jsonDecode(text) as List).map((raw) {
        final item = raw as Map<String, dynamic>;
        return <String, dynamic>{
          'name': item['name'] as String? ?? 'Unnamed amenity',
          'tag': item['tag'] as String? ?? 'Campus',
          'images': (item['images'] as List? ?? [])
              .whereType<String>()
              .toList(),
          'description': item['description'] as String? ?? '',
        };
      }).toList();

  Future<List<Map<String, dynamic>>> load({bool forceRefresh = false}) async {
    final prefs = await _preferences();
    final cached = prefs.getString('amenities_data');
    if (!forceRefresh && cached != null) {
      try {
        return _parse(cached);
      } catch (_) {
        // Recover damaged cached data through the existing remote source.
      }
    }
    final text = await _content.getText(GitHubSources.amenities);
    final items = _parse(text);
    await prefs.setString('amenities_data', text);
    return items;
  }
}
