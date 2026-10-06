import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/app_http_client.dart';

class BlogRepository {
  static final instance = BlogRepository();
  static const sourceUrl =
      'https://api.github.com/repos/Academia-IGIT/DATA_hub/contents/Blog';
  final http.Client _client;
  List<Map<String, String>>? _files;
  final Map<String, String> _content = {};
  BlogRepository({http.Client? client}) : _client = client ?? appHttpClient;

  Future<List<Map<String, String>>> getFiles(
      {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _files = null;
      _content.clear();
    }
    if (_files != null) return _files!;
    final response =
        await _client.get(Uri.parse(sourceUrl)).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load markdown files');
    }
    final data = jsonDecode(response.body) as List;
    final files = data
        .where((file) => file['name'].toString().endsWith('.md'))
        .map((file) => <String, String>{
              'name': file['name'].toString(),
              'download_url': file['download_url'].toString()
            })
        .toList();
    for (final file in files) {
      await getMarkdown(file['download_url']!);
    }
    _files = files;
    return files;
  }

  Future<String> getMarkdown(String url) async {
    final cached = _content[url];
    if (cached != null) return cached;
    final response = await _client.get(Uri.parse(url)).timeout(requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load markdown content');
    }
    return _content[url] = response.body;
  }
}
