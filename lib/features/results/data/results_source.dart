import 'dart:convert';

abstract final class ResultsSource {
  static final uri = Uri.parse(
    'https://igit.icrp.in/academic/Student-cp/Student_Result.aspx',
  );
  static const script = '''
    (() => {
      if (location.origin !== 'https://igit.icrp.in' || location.pathname.toLowerCase() !== '/academic/student-cp/student_result.aspx')
        return JSON.stringify({error: true});
      if (!window.__alcademyResults) {
        window.__alcademyResults = {pending: true};
        const fetchWithTimeout = async (url, options) => {
          const abort = new AbortController();
          const timer = setTimeout(() => abort.abort(), 20000);
          try {
            const response = await fetch(url, {...options, credentials: 'same-origin', signal: abort.signal});
            if (!response.ok || new URL(response.url).origin !== location.origin) throw new Error('ERP request failed');
            return response;
          } finally { clearTimeout(timer); }
        };
        const post = async (url, data) => {
          const response = await fetchWithTimeout(url, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data)});
          return response.json();
        };
        (async () => {
          const response = await post(location.pathname + '/ListStudentResult', {filter_mode: 0});
          const rows = typeof response.d === 'string' ? JSON.parse(response.d) : response.d;
          if (!Array.isArray(rows)) throw new Error('Unreadable result list');
          const exams = [];
          // GetStudResult establishes the report's session context. Read each
          // report before selecting the next exam; parallel requests mix grades.
          for (const row of rows) {
            const item = {record: {
              Semester_Name: row.Semester_Name, exam_name: row.exam_name,
              student_exam_type: row.student_exam_type, idt_date: row.idt_date,
              is_result_declare: row.is_result_declare
            }};
            if (String(row.is_result_declare) === '1') {
              try {
                const report = await post(location.pathname + '/GetStudResult', {
                  swd_sem_id: row.swd_sem_id, swd_term_id: row.swd_term_id, swd_year_id: row.swd_year_id,
                  swd_id: row.swd_id, collegeid: row.swd_college_id, Degree_id: row.Degree_id,
                  Student_Id: row.Student_Id, Degree_Result_Page_Url: row.Degree_Result_Page_Url
                });
                const url = new URL(report.d, location.href);
                if (url.origin !== location.origin || !url.pathname.toLowerCase().endsWith('/form_result_view_subject.aspx'))
                  throw new Error('Unsupported result report');
                // Load the report page first, just as ERP does, before its API.
                const page = await fetchWithTimeout(url.href, {});
                if (new URL(page.url).pathname.toLowerCase() !== url.pathname.toLowerCase()) throw new Error('Report session expired');
                await page.text();
                item.report = await post(url.origin + url.pathname + '/ListStudentResult', {});
              } catch (_) { item.report = null; }
            }
            exams.push(item);
          }
          window.__alcademyResults = {exams};
        })().catch(() => { window.__alcademyResults = {error: true}; });
      }
      return JSON.stringify(window.__alcademyResults);
    })();
  ''';
  static String? decode(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned unreadable results.');
    }
    dynamic data = jsonDecode(value);
    if (data is String) data = jsonDecode(data);
    if (data is! Map || data['error'] == true) {
      throw const FormatException(
        'Couldn’t read results from ERP. Please try again.',
      );
    }
    if (data['pending'] == true) return null;
    if (data['exams'] is! List) {
      throw const FormatException('ERP returned an incomplete result list.');
    }
    return jsonEncode(data);
  }
}
