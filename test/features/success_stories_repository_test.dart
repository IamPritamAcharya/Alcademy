import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/success_stories/data/success_stories_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final date = DateTime.utc(2026, 10, 9);
  const body =
      '\n# Story\n\n**Bold**  \nSecond line\n\n[Read](https://example.com)\n\n';
  String feed({String text = body}) => jsonEncode({
    'version': 1,
    'stories': [
      {
        'id': 'one',
        'name': 'Student',
        'company': 'Company',
        'image_url': 'https://example.com/p.jpg',
        'body': text,
      },
    ],
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Editable JSON preserves the eight original stories in order', () {
    final raw = File('content/success-stories.json').readAsStringSync();
    final stories = SuccessStoriesRepository.parse(raw);
    expect(stories.map((story) => story['name']), [
      'Abhishek Kumar Sahu',
      'Akash Kumar Sadangi',
      'Narayan Sahu',
      'Nikhil Agrawal',
      'Nilachala Sahoo',
      'Priyabrata Pattanaik',
      'Sidharth Nayak',
      'Subham Nayak',
    ]);
    expect(
      stories.every(
        (story) =>
            story['body']!.contains('\n') && story['body']!.contains('#'),
      ),
      isTrue,
    );
  });

  test(
    'One fetch persists exact text and avoids repeat requests until next month',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(feed(), 200);
      });
      final first = await SuccessStoriesRepository.fetchStories(
        client: client,
        now: () => date,
      );
      expect(first.single['body'], body);
      await SuccessStoriesRepository.fetchStories(
        client: client,
        now: () => date.add(const Duration(days: 1)),
      );
      expect(requests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(
        SuccessStoriesRepository.parse(
          prefs.getString('successStoriesFeed')!,
        ).single['body'],
        body,
      );
      await SuccessStoriesRepository.fetchStories(
        client: client,
        now: () => SuccessStoriesRepository.expiresAt(date),
      );
      expect(requests, 2);
    },
  );

  test(
    'Manual refresh bypasses valid cache, and a failed refresh preserves it',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          feed(text: requests == 1 ? body : 'Updated\n'),
          200,
        );
      });
      await SuccessStoriesRepository.fetchStories(
        client: client,
        now: () => date,
      );
      final updated = await SuccessStoriesRepository.fetchStories(
        client: client,
        now: () => date,
        forceRefresh: true,
      );
      expect(requests, 2);
      expect(updated.single['body'], 'Updated\n');
      for (final response in [
        http.Response('', 503),
        http.Response('{bad}', 200),
      ]) {
        final saved = await SuccessStoriesRepository.fetchStories(
          client: MockClient((_) async => response),
          now: () => date,
          forceRefresh: true,
        );
        expect(saved.single['body'], 'Updated\n');
      }
    },
  );

  test('Invalid feed fails without a saved snapshot', () async {
    await expectLater(
      SuccessStoriesRepository.fetchStories(
        client: MockClient((_) async => http.Response('{}', 200)),
        now: () => date,
      ),
      throwsA(anything),
    );
    expect(
      () => SuccessStoriesRepository.parse(
        feed().replaceFirst('https://example.com/p.jpg', 'file:///tmp/p.jpg'),
      ),
      throwsFormatException,
    );
  });

  test('Concurrent page loads share a single request', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    var requests = 0;
    final client = MockClient((_) {
      requests++;
      started.complete();
      return pending.future;
    });
    final first = SuccessStoriesRepository.fetchStories(
      client: client,
      now: () => date,
    );
    await started.future;
    final second = SuccessStoriesRepository.fetchStories(
      client: client,
      now: () => date,
    );
    pending.complete(http.Response(feed(), 200));
    final results = await Future.wait([first, second]);
    expect(results[0], results[1]);
    expect(requests, 1);
  });
}
