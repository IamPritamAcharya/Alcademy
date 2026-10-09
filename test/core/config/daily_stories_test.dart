import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/core/config/config_service.dart';
import 'package:port/core/config/daily_stories_service.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final date = DateTime.utc(2026, 10, 8, 8);
  final automated = {
    'id': 'news-1',
    'type': 'news',
    'kind': 'news',
    'title': 'Science news',
    'description': 'A discovery',
    'imageUrl': 'https://example.com/photo.jpg',
    'category': 'tech',
    'sourceUrl': 'https://example.com/news',
  };
  String feed({DateTime? generated, List<Object>? stories}) => jsonEncode({
    'version': 2,
    'generatedAt': (generated ?? date).toIso8601String(),
    'expiresAt': (generated ?? date)
        .add(const Duration(days: 3))
        .toIso8601String(),
    'stories': stories ?? [automated],
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfiguration.current.value = AppConfig(
      stories: [
        {'type': 'text', 'text': 'Custom story'},
      ],
    );
  });

  test(
    'Daily stories follow custom stories and lists remain immutable',
    () async {
      await DailyStoriesService.refresh(
        now: () => date,
        client: MockClient((_) async => http.Response(feed(), 200)),
      );
      expect(storyUrls.first['text'], 'Custom story');
      expect(storyUrls.last['id'], 'news-1');
      expect(() => storyUrls.last['text'] = 'changed', throwsUnsupportedError);
      expect(AppConfiguration.current.value.customStories.length, 1);
    },
  );

  test(
    'Daily boundary is 10am IST, including exact reset and month rollover',
    () {
      expect(
        DailyStoriesService.expiresAt(DateTime.utc(2026, 10, 8, 4, 29)),
        DateTime.utc(2026, 10, 8, 4, 30),
      );
      expect(
        DailyStoriesService.expiresAt(DateTime.utc(2026, 10, 8, 4, 30)),
        DateTime.utc(2026, 10, 9, 4, 30),
      );
      expect(
        DailyStoriesService.expiresAt(DateTime.utc(2026, 12, 31, 23)),
        DateTime.utc(2027, 1, 1, 4, 30),
      );
    },
  );

  test('No repeat fetch within a day; exact 10am reset fetches once', () async {
    var requests = 0;
    final before = DateTime.utc(2026, 10, 9, 4, 29);
    final client = MockClient((_) async {
      requests++;
      return http.Response(feed(generated: before), 200);
    });
    await DailyStoriesService.refresh(client: client, now: () => before);
    await DailyStoriesService.refresh(
      client: client,
      now: () => before.add(const Duration(seconds: 59)),
    );
    expect(requests, 1);
    final prefs = await SharedPreferences.getInstance();
    final reset = DateTime.utc(2026, 10, 9, 4, 30);
    expect(DailyStoriesService.readCached(prefs, now: reset), isEmpty);
    await DailyStoriesService.refresh(client: client, now: () => reset);
    expect(requests, 2);
    await DailyStoriesService.refresh(
      client: client,
      now: () => reset.add(const Duration(hours: 12)),
    );
    expect(requests, 2);
    expect(
      DailyStoriesService.readCached(
        prefs,
        now: reset.add(const Duration(hours: 12)),
      ),
      isNotEmpty,
    );
  });

  test(
    'Expired cache is removed offline and a later retry can recover',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dailyStoriesFeed', feed());
      await prefs.setString('dailyStoriesCheckedAt', date.toIso8601String());
      AppConfiguration.current.value = AppConfig(dailyStories: [automated]);
      final reset = DailyStoriesService.expiresAt(date);
      await DailyStoriesService.refresh(
        now: () => reset,
        client: MockClient((_) async => http.Response('', 503)),
      );
      expect(prefs.getString('dailyStoriesFeed'), isNull);
      expect(prefs.getString('dailyStoriesCheckedAt'), isNull);
      expect(AppConfiguration.current.value.dailyStories, isEmpty);
      await DailyStoriesService.refresh(
        now: () => reset,
        client: MockClient(
          (_) async => http.Response(feed(generated: reset), 200),
        ),
      );
      expect(AppConfiguration.current.value.dailyStories, isNotEmpty);
    },
  );

  test('Incomplete news is skipped while complete news remains', () {
    final items = DailyStoriesService.parse(
      feed(
        stories: [
          {...automated, 'id': 'no-title', 'title': '  '},
          {...automated, 'id': 'no-description', 'description': '  '},
          {...automated, 'id': 'missing-description'}..remove('description'),
          automated,
        ],
      ),
      date,
    );
    expect(items, [automated]);
  });

  test('Invalid, duplicate and excessive feeds are rejected atomically', () {
    expect(
      () => DailyStoriesService.parse(
        feed(stories: [automated, automated]),
        date,
      ),
      throwsFormatException,
    );
    expect(
      () => DailyStoriesService.parse(
        feed(stories: List.filled(17, automated)),
        date,
      ),
      throwsFormatException,
    );
    expect(
      () => DailyStoriesService.parse(
        feed(
          stories: [
            {...automated, 'type': 'video'},
          ],
        ),
        date,
      ),
      throwsFormatException,
    );
    expect(
      DailyStoriesService.parse(
        feed(generated: date.subtract(const Duration(days: 4))),
        date,
      ),
      isEmpty,
    );
  });

  test(
    'Failed request preserves cached daily stories; expired cache disappears',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dailyStoriesFeed', feed());
      await prefs.setString('dailyStoriesCheckedAt', date.toIso8601String());
      AppConfiguration.current.value = AppConfig(
        stories: [
          {'type': 'text', 'text': 'Custom story'},
        ],
        dailyStories: [automated],
      );
      final client = MockClient((_) async => http.Response('Unavailable', 403));
      await DailyStoriesService.refresh(client: client, now: () => date);
      expect(storyUrls.length, 2);
      await DailyStoriesService.refresh(
        client: client,
        now: () => date.add(const Duration(days: 3)),
      );
      expect(storyUrls.length, 1);
      expect(storyUrls.single['text'], 'Custom story');
    },
  );

  test('Fresh daily cache avoids requests independently of settings', () async {
    var requests = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastFetchDate', date.toIso8601String());
    final client = MockClient((request) async {
      requests++;
      expect(request.url.path, Uri.parse(GitHubSources.dailyStories).path);
      return http.Response(feed(), 200);
    });
    await ConfigService.fetchAndUpdateConfig(client: client, now: () => date);
    await ConfigService.fetchAndUpdateConfig(client: client, now: () => date);
    expect(requests, 1);
    expect(storyUrls.length, 2);
  });

  test('Cached feed is read immediately and expiry is respected', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dailyStoriesFeed', feed());
    await prefs.setString('dailyStoriesCheckedAt', date.toIso8601String());
    expect(
      DailyStoriesService.readCached(prefs, now: date).single['id'],
      'news-1',
    );
    expect(
      DailyStoriesService.readCached(
        prefs,
        now: date.add(const Duration(days: 3)),
      ),
      isEmpty,
    );
  });

  test(
    'Concurrent custom settings and feed refresh preserve both results',
    () async {
      await ConfigService.fetchAndUpdateConfig(
        now: () => date,
        client: MockClient((request) async {
          if (request.url.path == Uri.parse(GitHubSources.settings).path) {
            return http.Response(
              jsonEncode({
                'storyUrls': [
                  {'type': 'text', 'text': 'Updated custom'},
                ],
                'contributors': [
                  {'name': 'Contributor'},
                ],
              }),
              200,
            );
          }
          return http.Response(feed(), 200);
        }),
      );
      expect(storyUrls.first['text'], 'Updated custom');
      expect(storyUrls.last['id'], 'news-1');
      expect(contributors.single['name'], 'Contributor');
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('storyUrls')!).length, 1);
    },
  );
}
