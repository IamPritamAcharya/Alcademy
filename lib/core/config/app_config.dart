import 'package:flutter/foundation.dart';

class AppConfig {
  final bool showFirstTab;
  final String firstTabName;
  final String firstTabMarkdown;
  final List<Map<String, String>> stories;
  final List<Map<String, String>> contributors;
  AppConfig(
      {this.showFirstTab = true,
      this.firstTabName = 'Horizon',
      this.firstTabMarkdown = '',
      List<Map<String, String>> stories = const [],
      List<Map<String, String>> contributors = const []})
      : stories = List.unmodifiable(
            stories.map((item) => Map<String, String>.unmodifiable(item))),
        contributors = List.unmodifiable(
            contributors.map((item) => Map<String, String>.unmodifiable(item)));

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> readList(String key) => (json[key] as List? ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();
    return AppConfig(
        showFirstTab: json['showFirstTab'] as bool? ?? true,
        firstTabName: json['name_1st_tab'] as String? ?? 'Horizon',
        firstTabMarkdown: json['markdownContent_1st_tab'] as String? ?? '',
        stories: readList('storyUrls'),
        contributors: readList('contributors'));
  }
}

class AppConfiguration {
  static final current = ValueNotifier<AppConfig>(AppConfig());
}

// Read-only access preserves the existing view interfaces.
bool get showFirstTab => AppConfiguration.current.value.showFirstTab;
String get nameFirstTab => AppConfiguration.current.value.firstTabName;
String get markdownContentFirstTab =>
    AppConfiguration.current.value.firstTabMarkdown;
List<Map<String, String>> get storyUrls =>
    AppConfiguration.current.value.stories;
List<Map<String, String>> get contributors =>
    AppConfiguration.current.value.contributors;
