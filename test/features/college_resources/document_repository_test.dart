import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/features/college_resources/data/document_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'combined index resolves the correct calendar and holiday URLs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = DocumentRepository(
        client: MockClient(
          (_) async => http.Response(
            File('content/documents.json').readAsStringSync(),
            200,
          ),
        ),
      );
      expect(
        await repository.getUrl(DocumentDefinition.calendar),
        contains('academic_calender__a4_2026-27'),
      );
      expect(
        await repository.getUrl(DocumentDefinition.holidays),
        'https://igitsarang.ac.in/assets/documents/holiday/holiday_saka_era-2026_1775198826.pdf',
      );
    },
  );

  test(
    'invalid document index leaves the existing cached link untouched',
    () async {
      SharedPreferences.setMockInitialValues({
        'holiday_list_url': 'https://example.com/old.pdf',
      });
      final repository = DocumentRepository(
        client: MockClient(
          (_) async => http.Response('{"holidays":"not a URL"}', 200),
        ),
      );
      await expectLater(
        repository.getUrl(DocumentDefinition.holidays),
        throwsFormatException,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('holiday_list_url'),
        'https://example.com/old.pdf',
      );
    },
  );
  test(
    'Daily document cache expires at midnight and uses existing keys',
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
          return http.Response(
            '{"academicCalendar":" https://example.com/new.pdf "}',
            200,
          );
        }),
      );
      expect(
        await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/old.pdf',
      );
      expect(requests, 0);
      now = DateTime(2026, 10, 7);
      expect(
        await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/new.pdf',
      );
      expect(requests, 1);
      expect(
        await repository.getUrl(DocumentDefinition.calendar),
        'https://example.com/new.pdf',
      );
      expect(requests, 1);
    },
  );

  test(
    'Failed document request does not replace existing cached data',
    () async {
      SharedPreferences.setMockInitialValues({
        'holiday_list_url': 'https://example.com/old.pdf',
        'holiday_list_last_updated': '2026-10-05T00:00:00.000',
      });
      final repository = DocumentRepository(
        now: () => DateTime(2026, 10, 6),
        client: MockClient((_) async => http.Response('', 500)),
      );
      await expectLater(
        repository.getUrl(DocumentDefinition.holidays),
        throwsException,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('holiday_list_url'),
        'https://example.com/old.pdf',
      );
    },
  );
}
