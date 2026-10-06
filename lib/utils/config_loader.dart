import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:port/utils/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String settingsUrl =
      'https://raw.githubusercontent.com/IamPritamAcharya/DATA_hub/main/settings.json';
  static const int fetchIntervalHours = 1;

  static Future<void> fetchAndUpdateConfig() async {
    final prefs = await SharedPreferences.getInstance();

    String? lastFetchDateString = prefs.getString('lastFetchDate');
    DateTime now = DateTime.now();

    if (lastFetchDateString != null) {
      DateTime lastFetchDate = DateTime.parse(lastFetchDateString);
      Duration timeSinceLastFetch = now.difference(lastFetchDate);

      if (timeSinceLastFetch.inHours < fetchIntervalHours) {
        debugPrint(
            "Using cached configuration. Next fetch in ${fetchIntervalHours - timeSinceLastFetch.inHours} hour(s).");
        _loadFromSharedPreferences(prefs);
        return;
      }
    }

    try {
      final response = await http.get(Uri.parse(settingsUrl)).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint("Request to $settingsUrl timed out");
          throw Exception("Request timeout");
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> configData = jsonDecode(response.body);

        debugPrint("Fetched Config Data: $configData");

        _updateGlobalVariables(configData);

        _saveToSharedPreferences(prefs);

        await prefs.setString('lastFetchDate', now.toIso8601String());

        debugPrint("Configuration fetched, updated, and cached.");
      } else {
        debugPrint("Failed to fetch configuration: ${response.statusCode}");
        _loadFromSharedPreferences(prefs);
      }
    } catch (e) {
      debugPrint("Error fetching configuration: $e");
      _loadFromSharedPreferences(prefs);
    }
  }

  static void _loadFromSharedPreferences(SharedPreferences prefs) {
    try {
      String? storyUrlsString = prefs.getString('storyUrls');
      String? contributorsString = prefs.getString('contributors');

      if (storyUrlsString != null && storyUrlsString.isNotEmpty) {
        storyUrls = List<Map<String, String>>.from(
          jsonDecode(storyUrlsString)
              .map((item) => Map<String, String>.from(item)),
        );
      }

      if (contributorsString != null && contributorsString.isNotEmpty) {
        contributors = List<Map<String, String>>.from(
          jsonDecode(contributorsString)
              .map((item) => Map<String, String>.from(item)),
        );
      }

      nameFirstTab = prefs.getString('name_1st_tab') ?? 'Horizon';
      markdownContentFirstTab =
          prefs.getString('markdownContent_1st_tab') ?? '';
      showFirstTab = prefs.getBool('showFirstTab') ?? true;
    } catch (e) {
      debugPrint("Error loading data from SharedPreferences: $e");
    }
  }

  static void _updateGlobalVariables(Map<String, dynamic> configData) {
    try {
      storyUrls = (configData['storyUrls'] as List)
          .map((item) => Map<String, String>.from(item))
          .toList();

      contributors = (configData['contributors'] as List)
          .map((item) => Map<String, String>.from(item))
          .toList();

      nameFirstTab = configData['name_1st_tab'] ?? 'Horizon';
      markdownContentFirstTab = configData['markdownContent_1st_tab'] ?? "";
      showFirstTab = configData['showFirstTab'] ?? true;
    } catch (e) {
      debugPrint("Error updating global variables: $e");
    }
  }

  static Future<void> _saveToSharedPreferences(SharedPreferences prefs) async {
    try {
      await prefs.setString('storyUrls', jsonEncode(storyUrls));
      await prefs.setString('contributors', jsonEncode(contributors));
      await prefs.setString('name_1st_tab', nameFirstTab);
      await prefs.setString('markdownContent_1st_tab', markdownContentFirstTab);
      await prefs.setBool('showFirstTab', showFirstTab);
    } catch (e) {
      debugPrint("Error saving data to SharedPreferences: $e");
    }
  }
}
