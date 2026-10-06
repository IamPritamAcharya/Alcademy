import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/blog/data/blog_repository.dart';

void main() {
  test(
      'List and detail share cached content; refresh retrieves updated content',
      () async {
    var requests = 0;
    var version = 1;
    final repository = BlogRepository(client: MockClient((request) async {
      requests++;
      if (request.url.toString() == BlogRepository.sourceUrl) {
        return http.Response(
            '[{"name":"Post.md","download_url":"https://example.com/post.md"}]',
            200);
      }
      return http.Response('Version $version', 200);
    }));
    await repository.getFiles();
    expect(await repository.getMarkdown('https://example.com/post.md'),
        'Version 1');
    await repository.getFiles();
    expect(requests, 2);
    version = 2;
    await repository.getFiles(forceRefresh: true);
    expect(await repository.getMarkdown('https://example.com/post.md'),
        'Version 2');
    expect(requests, 4);
  });
}
