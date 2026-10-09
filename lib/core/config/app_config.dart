import 'package:flutter/foundation.dart';

class AppConfig {
  final List<Map<String, String>> stories;
  final List<Map<String, String>> customStories;
  final List<Map<String, String>> dailyStories;
  final List<Map<String, String>> contributors;
  AppConfig({
    List<Map<String, String>> stories = const [],
    List<Map<String, String>> dailyStories = const [],
    List<Map<String, String>> contributors = const [],
  }) : customStories = List.unmodifiable(
         stories.map((item) => Map<String, String>.unmodifiable(item)),
       ),
       dailyStories = List.unmodifiable(
         dailyStories.map((item) => Map<String, String>.unmodifiable(item)),
       ),
       stories = List.unmodifiable(
         [
           ...stories,
           ...dailyStories,
         ].map((item) => Map<String, String>.unmodifiable(item)),
       ),
       contributors = List.unmodifiable(
         contributors.map((item) => Map<String, String>.unmodifiable(item)),
       );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> readList(String key) => (json[key] as List? ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();
    return AppConfig(
      stories: readList('storyUrls'),
      dailyStories: readList('dailyStories'),
      contributors: readList('contributors'),
    );
  }
}

class AppConfiguration {
  static final current = ValueNotifier<AppConfig>(AppConfig());
}

// Read-only access preserves the existing view interfaces.
List<Map<String, String>> get storyUrls =>
    AppConfiguration.current.value.stories;
List<Map<String, String>> get contributors =>
    AppConfiguration.current.value.contributors;
