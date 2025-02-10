import 'dart:convert';
import 'package:http/http.dart' as http;

class DataFetchService {
  static const String apiUrl =
      'https://api.github.com/repos/Academia-IGIT/DATA_hub/contents/Success%20stories';
  static const String rawBaseUrl =
      'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/Success%20stories';

  // Fetch list of .md files and their content
  static Future<List<Map<String, String>>> fetchStories() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch files: ${response.body}');
      }

      final List<dynamic> files = json.decode(response.body);
      if (files.isEmpty) {
        print('No files found in the directory.');
        return [];
      }

      print('Fetched ${files.length} files from GitHub.');

      final List<Map<String, String>> stories = [];

      for (var file in files) {
        if (file['name'].endsWith('.md')) {
          final content = await _fetchFileContent(file['name']);
          if (content != null) {
            stories.add(content);
            print('Successfully parsed story: ${content['name']}');
          } else {
            print('Skipped invalid file: ${file['name']}');
          }
        } else {
          print('Ignored non-MD file: ${file['name']}');
        }
      }

      print('Total valid stories fetched: ${stories.length}');
      return stories;
    } catch (e) {
      print('Error in fetchStories: $e');
      rethrow;
    }
  }

  // Fetch individual file content
  static Future<Map<String, String>?> _fetchFileContent(String filename) async {
    try {
      final url = '$rawBaseUrl/$filename';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('Failed to fetch content for $filename: ${response.body}');
        return null;
      }

      final content = response.body;
      final metadata = RegExp(r'---(.*?)---', dotAll: true).firstMatch(content);

      if (metadata != null) {
        final yaml = metadata.group(1);
        final details = _parseYamlToMap(yaml!);
        final body = content.replaceFirst(metadata.group(0)!, '').trim();

        if (details.containsKey('name') &&
            details.containsKey('image_url') &&
            details.containsKey('company')) {
          return {
            'name': details['name']!,
            'image_url': details['image_url']!,
            'company': details['company']!,
            'body': body,
          };
        } else {
          print('Invalid metadata in file $filename. Details: $details');
        }
      } else {
        print('Missing metadata in file $filename');
      }
    } catch (e) {
      print('Error in _fetchFileContent for $filename: $e');
    }

    return null;
  }

  // Parse YAML metadata into a map
  static Map<String, String> _parseYamlToMap(String yaml) {
    final Map<String, String> map = {};
    final lines = yaml.split('\n');
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          map[key] = value;
        }
      }
    }
    return map;
  }
}
