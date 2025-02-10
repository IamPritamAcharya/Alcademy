import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:port/config.dart'; // Import the global config variables
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String settingsUrl =
      'https://raw.githubusercontent.com/IamPritamAcharya/DATA_hub/main/settings.json';
  static const String fetchTime =
      '00:00'; // Time to fetch the configuration (24-hour format)

  // Fetch and update the configuration data
  static Future<void> fetchAndUpdateConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the last fetch date
    String? lastFetchDate = prefs.getString('lastFetchDate');
    DateTime now = DateTime.now();
    DateTime todayFetchTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(fetchTime.split(':')[0]),
      int.parse(fetchTime.split(':')[1]),
    );

    // Check if fetching is required
    if (lastFetchDate != null &&
        DateTime.parse(lastFetchDate).isAfter(todayFetchTime)) {
      print("Using cached configuration.");
      _loadFromSharedPreferences(prefs);
      return;
    }

    // Fetch from GitHub and update if needed
    try {
      final response = await http.get(Uri.parse(settingsUrl)).timeout(
        Duration(seconds: 10), // Set a timeout for the HTTP request
        onTimeout: () {
          print("Request to $settingsUrl timed out");
          throw Exception("Request timeout");
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> configData = jsonDecode(response.body);

        // Debugging: Log the raw data to understand its structure
        print("Fetched Config Data: $configData");

        // Update the global variables with the fetched config data
        _updateGlobalVariables(configData);

        // Save the updated configuration locally
        _saveToSharedPreferences(prefs);

        // Update the last fetch date
        await prefs.setString('lastFetchDate', now.toIso8601String());

        print("Configuration fetched, updated, and cached.");
      } else {
        print("Failed to fetch configuration: ${response.statusCode}");
        _loadFromSharedPreferences(prefs); // Fallback to cache
      }
    } catch (e) {
      print("Error fetching configuration: $e");
      _loadFromSharedPreferences(prefs); // Fallback to cache
    }
  }

  // Load data from SharedPreferences
  static void _loadFromSharedPreferences(SharedPreferences prefs) {
    try {
      String? storyUrlsString = prefs.getString('storyUrls');
      String? contributorsString = prefs.getString('contributors');
      String? bannedEmailsString = prefs.getString('bannedEmails');
      String? bannedWordsString = prefs.getString('bannedWords');

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

      if (bannedEmailsString != null && bannedEmailsString.isNotEmpty) {
        bannedEmails = List<String>.from(jsonDecode(bannedEmailsString));
      }

      if (bannedWordsString != null && bannedWordsString.isNotEmpty) {
        bannedWords = List<String>.from(jsonDecode(bannedWordsString));
      }

      name_1st_tab = prefs.getString('name_1st_tab') ?? 'Horizon';
      markdownContent_1st_tab =
          prefs.getString('markdownContent_1st_tab') ?? '';
      showFirstTab = prefs.getBool('showFirstTab') ?? true;
    } catch (e) {
      print("Error loading data from SharedPreferences: $e");
    }
  }

  // Update global variables with the fetched config data
  static void _updateGlobalVariables(Map<String, dynamic> configData) {
    try {
      storyUrls = (configData['storyUrls'] as List)
          .map((item) => Map<String, String>.from(item))
          .toList();

      contributors = (configData['contributors'] as List)
          .map((item) => Map<String, String>.from(item))
          .toList();

      bannedEmails = List<String>.from(configData['bannedEmails']);
      bannedWords = List<String>.from(configData['bannedWords']);
      name_1st_tab = configData['name_1st_tab'] ?? 'Horizon';
      markdownContent_1st_tab = configData['markdownContent_1st_tab'] ?? "";
      showFirstTab = configData['showFirstTab'] ?? true;
    } catch (e) {
      print("Error updating global variables: $e");
    }
  }

  // Save the updated configuration to SharedPreferences
  static Future<void> _saveToSharedPreferences(SharedPreferences prefs) async {
    try {
      await prefs.setString('storyUrls', jsonEncode(storyUrls));
      await prefs.setString('contributors', jsonEncode(contributors));
      await prefs.setString('bannedEmails', jsonEncode(bannedEmails));
      await prefs.setString('bannedWords', jsonEncode(bannedWords));
      await prefs.setString('name_1st_tab', name_1st_tab);
      await prefs.setString('markdownContent_1st_tab', markdownContent_1st_tab);
      await prefs.setBool('showFirstTab', showFirstTab);
    } catch (e) {
      print("Error saving data to SharedPreferences: $e");
    }
  }
}
