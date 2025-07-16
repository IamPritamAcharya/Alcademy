import 'package:http/http.dart' as http;

class BlogCacheManager {
  static final Map<String, String> _cachedContent = {}; 

  static Future<String> fetchContent(String url) async {
    if (_cachedContent.containsKey(url)) {

      return _cachedContent[url]!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _cachedContent[url] = response.body; 
      return response.body;
    } else {
      throw Exception('Failed to load markdown content');
    }
  }
}
