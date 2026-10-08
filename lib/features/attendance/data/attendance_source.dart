import 'dart:convert';

abstract final class AttendanceSource {
  static final uri = Uri.parse(
    'https://igit.icrp.in/academic/Student-cp/Form_Students_Attendance_Monthy_Count.aspx',
  );
  // Native WebView JS evaluation does not await a Promise. Start the same
  // read-only requests used by ERP, then poll their result in this document.
  static const script = '''
    (() => {
      if (location.origin !== 'https://igit.icrp.in' ||
          location.pathname.toLowerCase() !== '/academic/student-cp/form_students_attendance_monthy_count.aspx')
        return JSON.stringify({error: true});
      if (!window.__alcademyAttendance) {
        window.__alcademyAttendance = {pending: true};
        const read = async endpoint => {
          const response = await fetch(location.pathname + '/' + endpoint, {
            method: 'POST', credentials: 'same-origin',
            headers: {'Content-Type': 'application/json'}, body: '{}'
          });
          if (!response.ok) throw new Error('ERP attendance request failed');
          return response.json();
        };
        Promise.all([read('ListAttendance'), read('ListAttendance_subject_wise')])
          .then(([months, subjects]) => { window.__alcademyAttendance = {months, subjects}; })
          .catch(() => { window.__alcademyAttendance = {error: true}; });
      }
      return JSON.stringify(window.__alcademyAttendance);
    })();
  ''';
  static String? decode(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned unreadable attendance data.');
    }
    dynamic data = jsonDecode(value);
    if (data is String) data = jsonDecode(data);
    if (data is! Map || data['error'] == true) {
      throw const FormatException(
        'ERP couldn’t return attendance. Please try again or open ERP.',
      );
    }
    if (data['pending'] == true) return null;
    if (!data.containsKey('months') || !data.containsKey('subjects')) {
      throw const FormatException('ERP returned incomplete attendance data.');
    }
    return jsonEncode(data);
  }
}
