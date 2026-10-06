import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/app_http_client.dart';

class ChatRepository {
  final http.Client _client;
  ChatRepository({http.Client? client}) : _client = client ?? appHttpClient;

  Future<String> reply(
      {required String apiKey, required String context}) async {
    final url = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/gemini-1.5-flash-latest:generateContent',
        {'key': apiKey});
    final response = await _client.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': context}
              ]
            }
          ]
        }));
    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode}');
    }
    final result = jsonDecode(response.body);
    return result['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
