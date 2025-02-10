import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String githubApiUrl =
      'https://api.github.com/repos/Academia-IGIT/DATA_hub/contents/Notes';

  /// Fetch available notes from API or cache
  static Future<List<Map<String, String>>> fetchAvailableNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedYearLinks');

    if (cachedData != null) {
      try {
        final List<dynamic> jsonData = json.decode(cachedData);
        return jsonData
            .map((item) => {
                  'name': item['name'].toString(),
                  'url': item['url'].toString(),
                })
            .toList();
      } catch (e) {
        print('Error parsing cached data: $e');
      }
    }

    // If no valid cached data, fetch from API
    try {
      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Map<String, String>> notes = data
            .where((file) => file['name'].endsWith('.json'))
            .map((file) => {
                  'name': file['name'].toString().replaceAll('.json', ''),
                  'url': file['download_url'].toString(),
                })
            .toList();

        // Cache the data for future use
        await prefs.setString('cachedYearLinks', json.encode(notes));
        return notes;
      } else {
        throw Exception('Failed to fetch notes from API.');
      }
    } catch (e) {
      print('Error fetching notes: $e');
      rethrow;
    }
  }

  /// Save user preferences
  static Future<void> saveUserPreferences({
    required String name,
    required String branch,
    required String noteUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userBranch', branch);
    await prefs.setString('selectedYearUrl', noteUrl);
  }

  /// Retrieve user preferences
  static Future<Map<String, String?>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName'),
      'userBranch': prefs.getString('userBranch'),
      'selectedYearUrl': prefs.getString('selectedYearUrl'),
    };
  }
}
