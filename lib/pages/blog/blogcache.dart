import 'package:http/http.dart' as http;

class BlogCacheManager {
  static final Map<String, String> _cachedContent = {}; // Static cache to store content

  // Fetch content from the cache or API
  static Future<String> fetchContent(String url) async {
    if (_cachedContent.containsKey(url)) {
      // Return cached content if available
      return _cachedContent[url]!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _cachedContent[url] = response.body; // Cache the content
      return response.body;
    } else {
      throw Exception('Failed to load markdown content');
    }
  }
}
