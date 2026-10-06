import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/college_resources/data/document_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Daily document cache expires at midnight and uses existing keys',
      () async {
    SharedPreferences.setMockInitialValues({
      'academic_calendar_url': 'https://example.com/old.pdf',
      'academic_calendar_last_updated': '2026-10-06T00:00:00.000',
    });
    var now = DateTime(2026, 10, 6, 12);
    var requests = 0;
    final repository = DocumentRepository(
        now: () => now,
        client: MockClient((_) async {
          requests++;
          return http.Response(' https://example.com/new.pdf\n', 200);
        }));
    expect(await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/old.pdf');
    expect(requests, 0);
    now = DateTime(2026, 10, 7);
    expect(await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/new.pdf');
    expect(requests, 1);
    expect(await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/new.pdf');
    expect(requests, 1);
  });

  test('Failed document request does not replace existing cached data',
      () async {
    SharedPreferences.setMockInitialValues({
      'holiday_list_url': 'https://example.com/old.pdf',
      'holiday_list_last_updated': '2026-10-05T00:00:00.000',
    });
    final repository = DocumentRepository(
        now: () => DateTime(2026, 10, 6),
        client: MockClient((_) async => http.Response('', 500)));
    await expectLater(
        repository.getUrl(DocumentDefinition.holidays), throwsException);
    expect(
        (await SharedPreferences.getInstance()).getString('holiday_list_url'),
        'https://example.com/old.pdf');
  });
}
