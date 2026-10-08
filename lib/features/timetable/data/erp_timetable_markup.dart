import 'dart:convert';

abstract final class ErpTimetableMarkup {
  static const extractionScript = '''
    (() => {
      if (location.origin !== 'https://igit.icrp.in' ||
          location.pathname.toLowerCase() !== '/academic/student-cp/form_display_division_timetables.aspx') return JSON.stringify({});
      const table = document.querySelector('[id\$="_tbl_time_table"]');
      if (!table) return JSON.stringify({});
      const frame = table.closest('[id\$="_div_timetable"]') || table.parentElement.closest('table') || table;
      const legends = Array.from(document.querySelectorAll('table')).filter(t =>
        t !== frame && t !== table && !frame.contains(t) &&
        /Subject Full Name|Faculty Full Name|DIVISION TIME TABLE/i.test(t.textContent));
      return JSON.stringify({html: frame.outerHTML + legends.map(t => t.outerHTML).join('')});
    })();
  ''';

  static String decode(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned an unreadable timetable.');
    }
    dynamic data = jsonDecode(value);
    // Android quotes the JavaScript string again; WKWebView returns it directly.
    if (data is String) data = jsonDecode(data);
    if (data is! Map || data['html'] is! String) {
      throw const FormatException(
        'ERP has not published a timetable for this account.',
      );
    }
    return data['html'] as String;
  }
}
