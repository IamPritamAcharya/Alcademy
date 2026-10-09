import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/core/network/github_content_client.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:port/features/notes/data/subject_repository.dart';
import 'package:port/features/success_stories/data/success_stories_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'folder listings and settings use this repository and its content directory',
    () {
      for (final url in [GitHubSources.noteYears]) {
        final uri = Uri.parse(url);
        expect(uri.host, 'api.github.com');
        expect(
          uri.path,
          startsWith('/repos/${GitHubSources.contentRepository}/contents/'),
        );
        expect(uri.queryParameters['ref'], GitHubSources.contentBranch);
      }
      expect(GitHubSources.blogs, endsWith('/content/blogs.json'));
      expect(Uri.parse(GitHubSources.blogs).host, 'raw.githubusercontent.com');
      expect(
        GitHubSources.settings,
        contains(
          '/${GitHubSources.contentRepository}/${GitHubSources.contentBranch}/${GitHubSources.contentDirectory}/settings.json',
        ),
      );
      expect(
        GitHubSources.defaultSubjects,
        endsWith('/content/Notes/All%20First%20Years.json'),
      );
    },
  );

  test('shared client preserves downloaded UTF-8 text', () async {
    final client = GitHubContentClient(
      client: MockClient(
        (_) async => http.Response(
          '## Campus — résumé',
          200,
          headers: {'content-type': 'text/plain; charset=utf-8'},
        ),
      ),
    );
    expect(await client.getText(GitHubSources.blogs), '## Campus — résumé');
  });

  test('refresh cache busting preserves existing query parameters', () async {
    final requested = <Uri>[];
    final client = GitHubContentClient(
      now: () => DateTime.fromMillisecondsSinceEpoch(12345),
      client: MockClient((request) async {
        requested.add(request.url);
        return http.Response('[]', 200);
      }),
    );
    const url =
        'https://raw.githubusercontent.com/owner/repo/main/year.json?token=test&timestamp=old';
    await client.getText(url);
    await client.getText(url, cacheBust: true);
    expect(requested.first.queryParameters['timestamp'], 'old');
    expect(requested.last.queryParameters, {
      'token': 'test',
      'timestamp': '12345',
    });
  });

  test('non-success responses share a typed status error', () async {
    final client = GitHubContentClient(
      client: MockClient((_) async => http.Response('limited', 403)),
    );
    await expectLater(
      client.getText(GitHubSources.noteYears),
      throwsA(
        isA<GitHubContentException>()
            .having((error) => error.statusCode, 'status', 403)
            .having(
              (error) => error.source,
              'source',
              Uri.parse(GitHubSources.noteYears),
            ),
      ),
    );
  });

  test('slow content requests time out', () async {
    final pending = Completer<http.Response>();
    final client = GitHubContentClient(
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) => pending.future),
    );
    await expectLater(
      client.getText(GitHubSources.settings),
      throwsA(isA<TimeoutException>()),
    );
    pending.complete(http.Response('{}', 200));
  });

  test(
    'subjects use the same transport for selection changes and refresh',
    () async {
      final requested = <Uri>[];
      final repository = SubjectRepository(
        GitHubSources.defaultSubjects,
        client: MockClient((request) async {
          requested.add(request.url);
          return http.Response(
            '[{"name":"Maths","items":[{"name":"Unit 1","url":"https://example.com/unit.pdf"}]}]',
            200,
          );
        }),
      );
      expect(
        (await repository.fetchSubjects()).single.items.single.name,
        'Unit 1',
      );
      repository.url = 'https://example.com/year.json?ref=main';
      expect(
        (await repository.fetchSubjectsWithCacheBust()).single.name,
        'Maths',
      );
      expect(requested.first.toString(), GitHubSources.defaultSubjects);
      expect(requested.last.queryParameters['ref'], 'main');
      expect(requested.last.queryParameters['timestamp'], isNotEmpty);
    },
  );

  test('success stories download one JSON file and preserve Markdown', () async {
    const body =
        '\n# Résumé\n\n**Bold**  \nNext line\n\n[Link](https://example.com/a:b)\n';
    final requests = <Uri>[];
    final stories = await SuccessStoriesRepository.fetchStories(
      client: MockClient((request) async {
        requests.add(request.url);
        expect(request.url.host, 'raw.githubusercontent.com');
        expect(request.url.path, Uri.parse(GitHubSources.successStories).path);
        return http.Response(
          jsonEncode({
            'version': 1,
            'stories': [
              {
                'id': 'student',
                'name': 'Student',
                'image_url': 'https://example.com/photo.jpg',
                'company': 'Campus',
                'body': body,
              },
            ],
          }),
          200,
        );
      }),
    );
    expect(requests, hasLength(1));
    expect(stories.single['name'], 'Student');
    expect(stories.single['body'], body);
    expect(stories.single['image_url'], 'https://example.com/photo.jpg');
  });
}
