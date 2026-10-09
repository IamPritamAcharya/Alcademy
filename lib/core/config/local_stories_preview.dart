import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';
import 'daily_stories_service.dart';

/// Opt-in local snapshot. Never enabled in profile or release builds.
abstract final class LocalStoriesPreview {
  static const enabled =
      kDebugMode && bool.fromEnvironment('LOCAL_STORIES_PREVIEW');

  static Future<AppConfig> load({AssetBundle? assets}) async {
    if (!kDebugMode) throw StateError('Story preview requires a debug build');
    final bundle = assets ?? rootBundle;
    final settings = AppConfig.fromJson(
      jsonDecode(await bundle.loadString('content/settings.json'))
          as Map<String, dynamic>,
    );
    final raw = await bundle.loadString('assets/data/stories-preview.json');
    // A preview is a frozen snapshot. Live feeds still enforce real-time expiry.
    final generated = DateTime.parse(
      (jsonDecode(raw) as Map<String, dynamic>)['generatedAt'] as String,
    );
    return AppConfig(
      stories: settings.customStories,
      contributors: settings.contributors,
      dailyStories: DailyStoriesService.parse(raw, generated),
    );
  }
}
