import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/core/config/festival_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final date = DateTime.utc(2026, 11, 8, 8);
  String snapshot({DateTime? generated, List<Object>? events}) => jsonEncode({
    'version': 1,
    'generatedAt': (generated ?? date).toIso8601String(),
    'years': [2026, 2027],
    'events':
        events ??
        [
          {
            'id': 'diwali',
            'date': '2026-11-08',
            'name': 'Diwali/Deepavali',
            'wish': 'Happy Diwali!',
            'priority': 100,
          },
          {'id': 'other', 'date': '2026-11-08', 'name': 'Naraka Chaturdasi'},
          {
            'id': 'eid',
            'date': '2027-03-10',
            'name': 'Ramzan Id',
            'wish': 'Eid Mubarak!',
            'priority': 100,
          },
        ],
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FestivalService.stopUpdates();
    FestivalService.wish.value = null;
  });

  test('Calendar-month expiry handles February and year rollover in IST', () {
    expect(
      FestivalService.expiresAt(DateTime.utc(2026, 2, 1)),
      DateTime.utc(2026, 2, 28, 18, 30),
    );
    expect(
      FestivalService.expiresAt(DateTime.utc(2026, 12, 31, 19)),
      DateTime.utc(2027, 1, 31, 18, 30),
    );
    expect(
      FestivalService.expiresAt(DateTime.utc(2028, 2, 1)),
      DateTime.utc(2028, 2, 29, 18, 30),
    );
  });

  test(
    'Wish begins and ends at IST midnight and normal dates have no wish',
    () {
      final events = FestivalService.parse(snapshot(), date);
      expect(
        FestivalService.greetingFor(events, DateTime.utc(2026, 11, 7, 18, 29)),
        isNull,
      );
      expect(
        FestivalService.greetingFor(events, DateTime.utc(2026, 11, 7, 18, 30)),
        'Happy Diwali!',
      );
      expect(
        FestivalService.greetingFor(events, DateTime.utc(2026, 11, 8, 18, 29)),
        'Happy Diwali!',
      );
      expect(
        FestivalService.greetingFor(events, DateTime.utc(2026, 11, 8, 18, 30)),
        isNull,
      );
    },
  );

  test('Same-day priority chooses one suitable wish', () {
    final events = FestivalService.parse(
      snapshot(
        events: [
          {
            'id': 'one',
            'date': '2026-11-08',
            'name': 'Other',
            'wish': 'Other wish',
            'priority': 50,
          },
          {
            'id': 'two',
            'date': '2026-11-08',
            'name': 'Diwali',
            'wish': 'Happy Diwali!',
            'priority': 100,
          },
        ],
      ),
      date,
    );
    expect(FestivalService.greetingFor(events, date), 'Happy Diwali!');
  });

  test(
    'Invalid dates, duplicate IDs and out-of-range years fail atomically',
    () {
      for (final events in [
        [
          {'id': 'x', 'date': '2026-02-30', 'name': 'Bad'},
        ],
        [
          {'id': 'x', 'date': '2028-01-01', 'name': 'Bad'},
        ],
        List.generate(
          2,
          (_) => {'id': 'x', 'date': '2026-11-08', 'name': 'Same'},
        ),
      ]) {
        expect(
          () => FestivalService.parse(snapshot(events: events), date),
          throwsFormatException,
        );
      }
    },
  );

  test('Cache avoids HTTP within month but daily wish still changes', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(snapshot(), 200);
    });
    await FestivalService.refresh(client: client, now: () => date);
    expect(FestivalService.wish.value, 'Happy Diwali!');
    await FestivalService.refresh(
      client: client,
      now: () => date.add(const Duration(days: 1)),
    );
    expect(FestivalService.wish.value, isNull);
    expect(requests, 1);
    await FestivalService.refresh(
      client: client,
      now: () => FestivalService.expiresAt(date),
    );
    expect(requests, 2);
  });

  test(
    'Failed monthly refresh preserves known dates and limits retries',
    () async {
      await FestivalService.refresh(
        client: MockClient((_) async => http.Response(snapshot(), 200)),
        now: () => date,
      );
      var requests = 0;
      final blocked = MockClient((_) async {
        requests++;
        return http.Response('', 503);
      });
      final nextMonth = FestivalService.expiresAt(date);
      await FestivalService.refresh(client: blocked, now: () => nextMonth);
      await FestivalService.refresh(
        client: blocked,
        now: () => nextMonth.add(const Duration(minutes: 1)),
      );
      expect(requests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('festivalCalendar'), snapshot());
      await FestivalService.loadCached(now: () => date);
      expect(FestivalService.wish.value, 'Happy Diwali!');
    },
  );

  test(
    'Older feed at monthly boundary does not block later updated publication',
    () async {
      var requests = 0;
      final first = DateTime.utc(2026, 12, 1);
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          snapshot(generated: requests == 1 ? date : first),
          200,
        );
      });
      await FestivalService.refresh(client: client, now: () => first);
      expect(prefs.getString('festivalCalendarCheckedAt'), isNull);
      await FestivalService.refresh(
        client: client,
        now: () => first.add(const Duration(hours: 6)),
      );
      expect(prefs.getString('festivalCalendarCheckedAt'), isNotNull);
      await FestivalService.refresh(
        client: client,
        now: () => first.add(const Duration(hours: 7)),
      );
      expect(requests, 2);
    },
  );
}
