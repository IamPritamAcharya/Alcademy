import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/college_holiday.dart';

abstract final class HolidaySource {
  static final uri = Uri.parse(
    'https://igit.icrp.in/academic/Student-cp/List_Students_College_Wise_Holidays.aspx',
  );
  static const script = '''
    (() => {
      if (location.origin !== 'https://igit.icrp.in' ||
          location.pathname.toLowerCase() !== '/academic/student-cp/list_students_college_wise_holidays.aspx')
        return JSON.stringify({error: true});
      if (!window.__alcademyHolidays) {
        window.__alcademyHolidays = {pending: true};
        fetch(location.pathname + '/ListHoliday', {
          method: 'POST', credentials: 'same-origin',
          headers: {'Content-Type': 'application/json'}, body: '{}'
        }).then(response => {
          if (!response.ok) throw new Error('ERP holiday request failed');
          return response.json();
        }).then(data => { window.__alcademyHolidays = {data}; })
          .catch(() => { window.__alcademyHolidays = {error: true}; });
      }
      return JSON.stringify(window.__alcademyHolidays);
    })();
  ''';
  static String? decode(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned unreadable holidays.');
    }
    dynamic result = jsonDecode(value);
    if (result is String) result = jsonDecode(result);
    if (result is! Map || result['error'] == true) {
      throw const FormatException('Couldn’t read ERP holidays.');
    }
    if (result['pending'] == true) return null;
    if (!result.containsKey('data')) {
      throw const FormatException('ERP returned incomplete holidays.');
    }
    return jsonEncode(result['data']);
  }

  static List<CollegeHoliday> parse(String raw) {
    final response = jsonDecode(raw);
    if (response is! Map || !response.containsKey('d')) {
      throw const FormatException('ERP returned an unexpected holiday list.');
    }
    dynamic rows = response['d'];
    if (rows is String) rows = jsonDecode(rows);
    if (rows is! List) {
      throw const FormatException('ERP returned an unexpected holiday list.');
    }
    final dates = DateFormat('dd/MM/yyyy');
    final holidays = <CollegeHoliday>[];
    for (final row in rows) {
      if (row is! Map ||
          row['HolidayName'] is! String ||
          row['FromDate'] is! String ||
          row['ToDate'] is! String) {
        throw const FormatException('ERP returned an incomplete holiday.');
      }
      final name = (row['HolidayName'] as String).trim();
      final from = dates.parseStrict(row['FromDate'].trim());
      final to = dates.parseStrict(row['ToDate'].trim());
      if (name.isEmpty || to.isBefore(from)) {
        throw const FormatException('ERP returned an invalid holiday.');
      }
      holidays.add(
        CollegeHoliday(
          name: name,
          from: from,
          to: to,
          description: (row['Description'] ?? '').toString().trim(),
        ),
      );
    }
    holidays.sort((a, b) => a.from.compareTo(b.from));
    return List.unmodifiable(holidays);
  }
}
