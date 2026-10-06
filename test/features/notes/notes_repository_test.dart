import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/notes/data/notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Existing year cache and selection remain usable without a request',
      () async {
    SharedPreferences.setMockInitialValues({
      'cachedYearLinks': jsonEncode([
        {'name': 'Year 1', 'url': 'https://example.com/1.json'}
      ]),
      'selectedYearUrl': 'https://example.com/1.json',
    });
    final repository = NotesRepository(
        client: MockClient((_) async =>
            throw StateError('Cached years should not request the network')));
    expect((await repository.getYears()).single.name, 'Year 1');
    expect(await repository.getSelectedYear(), 'https://example.com/1.json');
    await repository.selectYear('https://example.com/2.json');
    expect((await SharedPreferences.getInstance()).getString('selectedYearUrl'),
        'https://example.com/2.json');
  });

  test('Malformed cache recovers and force refresh replaces the old cache',
      () async {
    SharedPreferences.setMockInitialValues({'cachedYearLinks': '{broken'});
    var requests = 0;
    final repository = NotesRepository(client: MockClient((_) async {
      requests++;
      return http.Response(
          jsonEncode([
            {
              'name': 'Year $requests.json',
              'download_url': 'https://example.com/$requests.json'
            },
            {'name': 'README.md', 'download_url': 'https://example.com/readme'},
          ]),
          200);
    }));
    expect((await repository.getYears()).single.name, 'Year 1');
    expect((await repository.getYears()).single.name, 'Year 1');
    expect(requests, 1);
    expect(
        (await repository.getYears(forceRefresh: true)).single.name, 'Year 2');
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('cachedYearLinks')!).single['name'],
        'Year 2');
  });
}
