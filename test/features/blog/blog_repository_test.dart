import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/blog/data/blog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

String feed(String body) => jsonEncode({
  'version': 1,
  'blogs': [
    {'id': 'second', 'title': 'Zebra', 'body': body},
    {'id': 'first', 'title': 'Alpha', 'body': '# Another article'},
  ],
});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'one request preserves order, Markdown and persistent monthly cache',
    () async {
      var requests = 0;
      var date = DateTime.utc(2026, 10, 9);
      const body = '# Heading\n\n**Bold**  \n[Link](https://example.com)\n';
      final client = MockClient((request) async {
        requests++;
        expect(request.url.path, endsWith('/content/blogs.json'));
        return http.Response(feed(body), 200);
      });
      final repository = BlogRepository(client: client, now: () => date);
      final blogs = await repository.fetchBlogs();
      expect(blogs.map((b) => b['title']), ['Zebra', 'Alpha']);
      expect(blogs.first['body'], body);
      await BlogRepository(client: client, now: () => date).fetchBlogs();
      expect(requests, 1);
      date = DateTime.utc(2026, 10, 31, 18, 29, 59);
      await repository.fetchBlogs();
      expect(requests, 1);
      date = DateTime.utc(2026, 10, 31, 18, 30);
      await repository.fetchBlogs();
      expect(requests, 2);
    },
  );

  test(
    'manual refresh fetches updated article without detail requests',
    () async {
      var requests = 0;
      final repository = BlogRepository(
        client: MockClient((_) async {
          return http.Response(feed('Version ${++requests}'), 200);
        }),
      );
      expect((await repository.fetchBlogs()).first['body'], 'Version 1');
      expect(
        (await repository.fetchBlogs(forceRefresh: true)).first['body'],
        'Version 2',
      );
      expect(requests, 2);
    },
  );

  test('failed or invalid refresh retains last valid cache', () async {
    var response = http.Response(feed('Saved article'), 200);
    final repository = BlogRepository(
      client: MockClient((_) async => response),
    );
    await repository.fetchBlogs();
    for (final failure in [
      http.Response('offline', 503),
      http.Response('{}', 200),
    ]) {
      response = failure;
      expect(
        (await repository.fetchBlogs(forceRefresh: true)).first['body'],
        'Saved article',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        BlogRepository.parse(prefs.getString('blogsFeed')!).first['body'],
        'Saved article',
      );
    }
  });

  test(
    'cold failures propagate, concurrent requests share one download',
    () async {
      final response = Completer<http.Response>();
      var requests = 0;
      final repository = BlogRepository(
        client: MockClient((_) {
          requests++;
          return response.future;
        }),
      );
      final first = repository.fetchBlogs();
      final second = repository.fetchBlogs();
      final checks = Future.wait([
        expectLater(first, throwsA(isA<Exception>())),
        expectLater(second, throwsA(isA<Exception>())),
      ]);
      response.complete(http.Response('offline', 503));
      await checks;
      expect(requests, 1);
    },
  );

  test('feed rejects duplicate IDs and blank bodies', () {
    final duplicate = jsonDecode(feed('Body'));
    duplicate['blogs'][1]['id'] = 'second';
    expect(
      () => BlogRepository.parse(jsonEncode(duplicate)),
      throwsFormatException,
    );
    expect(() => BlogRepository.parse(feed('  \n')), throwsFormatException);
  });

  test(
    'consolidated feed contains original articles in their existing order',
    () {
      final blogs = BlogRepository.parse(
        File('content/blogs.json').readAsStringSync(),
      );
      expect(blogs.take(3).map((b) => b['title']), [
        'AI Tools Overview',
        'Company-Wise Recruitment Process',
        'FAANG+ Interview Guides',
      ]);
      for (final blog in blogs) {
        expect(blog['body'], startsWith('# ${blog['title']}'));
      }
    },
  );
}
