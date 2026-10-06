import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/github_content_client.dart';
import '../../../core/network/github_sources.dart';

class BlogRepository {
  static final instance = BlogRepository();
  static const sourceUrl = GitHubSources.blogs;
  final GitHubContentClient _contentClient;
  List<Map<String, String>>? _files;
  final Map<String, String> _content = {};
  BlogRepository({http.Client? client})
    : _contentClient = GitHubContentClient(client: client);

  Future<List<Map<String, String>>> getFiles({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _files = null;
      _content.clear();
    }
    if (_files != null) return _files!;
    final data = jsonDecode(await _contentClient.getText(sourceUrl)) as List;
    final files = data
        .where((file) => file['name'].toString().endsWith('.md'))
        .map(
          (file) => <String, String>{
            'name': file['name'].toString(),
            'download_url': file['download_url'].toString(),
          },
        )
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
    return _content[url] = await _contentClient.getText(url);
  }
}
