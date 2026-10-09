import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/github_content_client.dart';
import '../network/github_sources.dart';

abstract final class FestivalService {
  static final wish = ValueNotifier<String?>(null);
  static const _previewDate = String.fromEnvironment('FESTIVAL_PREVIEW_DATE');
  static const _cacheKey = 'festivalCalendar';
  static const _checkedKey = 'festivalCalendarCheckedAt';
  static const _attemptKey = 'festivalCalendarAttemptAt';
  static List<Map<String, dynamic>> _events = [];
  static bool _refreshing = false;
  static bool _watching = false;
  static Timer? _timer;

  static DateTime _greetingDate(DateTime now) {
    if (!kDebugMode || _previewDate.isEmpty) return now;
    final date = DateTime.tryParse(_previewDate);
    if (date == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(_previewDate) ||
        date.toIso8601String().substring(0, 10) != _previewDate) {
      return now;
    }
    // Only preview the displayed wish. Fetching and expiry use the real clock.
    return DateTime.utc(date.year, date.month, date.day, 12);
  }

  static DateTime indiaDate(DateTime now) {
    final india = now.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateTime.utc(india.year, india.month, india.day);
  }

  /// A calendar-month boundary in IST, not a rolling 30-day duration.
  static DateTime expiresAt(DateTime fetched) {
    final india = indiaDate(fetched);
    return DateTime.utc(
      india.year,
      india.month + 1,
    ).subtract(const Duration(hours: 5, minutes: 30));
  }

  static List<Map<String, dynamic>> parse(String raw, DateTime now) {
    if (raw.length > 150000) throw const FormatException('Calendar too large');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final generated = DateTime.parse(json['generatedAt'] as String);
    final years = (json['years'] as List).cast<int>();
    final generatedYear = indiaDate(generated).year;
    if (json['version'] != 1 ||
        years.length != 2 ||
        years[0] != generatedYear ||
        years[1] != generatedYear + 1 ||
        generated.isAfter(now.add(const Duration(hours: 1)))) {
      throw const FormatException('Invalid calendar snapshot');
    }
    // Permit an offline last-known snapshot during monthly refresh failures.
    if (!years.contains(indiaDate(now).year) ||
        now.difference(generated) > const Duration(days: 90)) {
      return [];
    }
    final values = json['events'] as List;
    if (values.isEmpty || values.length > 400) {
      throw const FormatException('Invalid event count');
    }
    final seen = <String>{};
    final events = <Map<String, dynamic>>[];
    for (final value in values) {
      final event = Map<String, dynamic>.from(value as Map);
      final id = event['id'] as String;
      final name = event['name'] as String;
      final date = event['date'] as String;
      final parsed = DateTime.tryParse(date);
      final greeting = event['wish'];
      final priority = event['priority'] ?? 0;
      if (id.isEmpty ||
          !seen.add(id) ||
          name.trim().isEmpty ||
          name.length > 180 ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          parsed == null ||
          parsed.toIso8601String().substring(0, 10) != date ||
          !years.contains(parsed.year) ||
          priority is! int ||
          priority < 0 ||
          priority > 100 ||
          (greeting != null &&
              (greeting is! String ||
                  greeting.trim().isEmpty ||
                  greeting.length > 64))) {
        throw const FormatException('Invalid festival event');
      }
      events.add(Map.unmodifiable(event));
    }
    return List.unmodifiable(events);
  }

  static String? greetingFor(List<Map<String, dynamic>> events, DateTime now) {
    final today = indiaDate(now).toIso8601String().substring(0, 10);
    final matches = events
        .where((event) => event['date'] == today && event['wish'] != null)
        .toList();
    matches.sort((a, b) {
      final priority = (b['priority'] as int? ?? 0).compareTo(
        a['priority'] as int? ?? 0,
      );
      return priority == 0
          ? (a['name'] as String).compareTo(b['name'] as String)
          : priority;
    });
    return matches.isEmpty ? null : matches.first['wish'] as String;
  }

  static Future<void> loadCached({
    DateTime Function()? now,
    AssetBundle? assets,
  }) async {
    final date = (now ?? DateTime.now)();
    final prefs = await SharedPreferences.getInstance();
    try {
      _events = parse(prefs.getString(_cacheKey) ?? '', date);
    } catch (_) {
      _events = [];
    }
    if (_events.isEmpty) {
      try {
        _events = parse(
          await (assets ?? rootBundle).loadString('assets/data/festivals.json'),
          date,
        );
      } catch (_) {
        _events = [];
      }
    }
    wish.value = greetingFor(_events, _greetingDate(date));
  }

  static Future<void> startUpdates() async {
    _watching = true;
    await refresh();
  }

  static void stopUpdates() {
    _watching = false;
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> refresh({
    http.Client? client,
    DateTime Function()? now,
  }) async {
    if (_refreshing) return;
    _refreshing = true;
    final clock = now ?? DateTime.now;
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = clock();
      // Re-evaluate today's wish even when the monthly cache avoids all HTTP.
      await loadCached(now: () => date);
      final checked = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
      if (_events.isNotEmpty &&
          checked != null &&
          !date.isBefore(checked) &&
          date.isBefore(expiresAt(checked))) {
        return;
      }
      final attempted = DateTime.tryParse(prefs.getString(_attemptKey) ?? '');
      if (attempted != null &&
          !date.isBefore(attempted) &&
          date.difference(attempted) < const Duration(hours: 6)) {
        return;
      }
      await prefs.setString(_attemptKey, date.toUtc().toIso8601String());
      final raw = await GitHubContentClient(
        client: client,
      ).getText(GitHubSources.festivals, cacheBust: true);
      final fetched = clock();
      final events = parse(raw, fetched);
      if (events.isEmpty) return;
      await prefs.setString(_cacheKey, raw);
      _events = events;
      wish.value = greetingFor(events, _greetingDate(fetched));
      final generated = DateTime.parse(
        (jsonDecode(raw) as Map)['generatedAt'] as String,
      );
      // A first-of-month request can precede the scheduled publication. Don't
      // lock an older snapshot into the new month's cache; retry after 6h.
      if (indiaDate(generated).year == indiaDate(fetched).year &&
          indiaDate(generated).month == indiaDate(fetched).month) {
        await prefs.setString(_checkedKey, fetched.toUtc().toIso8601String());
      } else {
        await prefs.remove(_checkedKey);
      }
    } catch (error) {
      debugPrint('Festival calendar refresh failed: $error');
    } finally {
      _refreshing = false;
      if (_watching) await _scheduleNext(clock());
    }
  }

  static Future<void> _scheduleNext(DateTime now) async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    if (!_watching) return;
    final midnight = indiaDate(now)
        .add(const Duration(days: 1))
        .subtract(const Duration(hours: 5, minutes: 30));
    var delay = midnight.difference(now.toUtc());
    final checked = DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
    if (checked == null || !now.isBefore(expiresAt(checked))) {
      final attempted = DateTime.tryParse(prefs.getString(_attemptKey) ?? '');
      final retry =
          attempted?.add(const Duration(hours: 6)).difference(now) ??
          Duration.zero;
      if (retry < delay) delay = retry.isNegative ? Duration.zero : retry;
    }
    _timer = Timer(delay, () => unawaited(refresh()));
  }
}
