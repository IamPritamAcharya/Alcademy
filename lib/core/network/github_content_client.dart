import 'package:http/http.dart' as http;

import 'app_http_client.dart';
import 'github_sources.dart';

/// Shared transport for GitHub listings and their downloaded content.
/// Feature repositories retain their existing parsers and cache policies.
class GitHubContentClient {
  static final instance = GitHubContentClient();
  final http.Client _client;
  final Duration timeout;
  final DateTime Function() _now;

  GitHubContentClient({
    http.Client? client,
    this.timeout = requestTimeout,
    DateTime Function()? now,
  }) : _client = client ?? appHttpClient,
       _now = now ?? DateTime.now;

  Future<String> getText(String url, {bool cacheBust = false}) async {
    var uri = Uri.parse(GitHubSources.migrateLegacyLinks(url));
    if (cacheBust) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'timestamp': '${_now().millisecondsSinceEpoch}',
        },
      );
    }
    final response = await _client.get(uri).timeout(timeout);
    if (response.statusCode != 200) {
      throw GitHubContentException(uri, response.statusCode);
    }
    return response.body;
  }
}

class GitHubContentException implements Exception {
  final Uri source;
  final int statusCode;
  const GitHubContentException(this.source, this.statusCode);

  @override
  String toString() => 'Content request failed ($statusCode): $source';
}
