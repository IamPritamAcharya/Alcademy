import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// TODO: Replace this URL with your raw GitHub JSON link.
// Example: 'https://raw.githubusercontent.com/username/repo/main/lib/assets/gate_source.json'
const String kGateJsonUrl = '';

Future<Map<String, dynamic>> fetchGateData() async {
  if (kGateJsonUrl.isNotEmpty && kGateJsonUrl.startsWith('http')) {
    try {
      final response = await http.get(Uri.parse(kGateJsonUrl));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Fallback to local asset if network fetch fails
      debugPrint('Failed to fetch remote gate data: $e');
    }
  }
  
  // Fallback to local asset
  final String response = await rootBundle.loadString('lib/assets/gate_source.json');
  return json.decode(response);
}

void debugPrint(String message) {
  // Simple print for debug
  print(message);
}
