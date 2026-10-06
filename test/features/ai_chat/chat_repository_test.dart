import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/ai_chat/data/chat_repository.dart';

void main() {
  test('Conversation and key reach the API and the reply is extracted',
      () async {
    final repository = ChatRepository(client: MockClient((request) async {
      expect(request.url.queryParameters['key'], 'test-key');
      expect(request.headers['Content-Type'], startsWith('application/json'));
      final body = jsonDecode(request.body);
      expect(body['contents'][0]['parts'][0]['text'], 'User: Hello');
      return http.Response(
          '{"candidates":[{"content":{"parts":[{"text":"Hello back"}]}}]}',
          200);
    }));
    expect(await repository.reply(apiKey: 'test-key', context: 'User: Hello'),
        'Hello back');
  });
  test('API failures propagate to the screen error handler', () async {
    final repository =
        ChatRepository(client: MockClient((_) async => http.Response('', 403)));
    await expectLater(repository.reply(apiKey: 'test-key', context: 'Hello'),
        throwsException);
  });
}
