import 'dart:convert';
import '../models/student_results.dart';

class ResultsParser {
  static String _text(dynamic value) =>
      value == null ? '' : '$value'.replaceAll(RegExp(r'\s+'), ' ').trim();
  StudentResults parse(String source, {DateTime? fetchedAt}) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    if (data['exams'] is! List) {
      throw const FormatException('ERP returned an unreadable results list.');
    }
    final exams = <ExamResult>[];
    for (final raw in data['exams'] as List) {
      final item = raw as Map;
      final row = item['record'] as Map;
      final semester = _text(row['Semester_Name']);
      final exam = _text(row['exam_name']);
      if (semester.isEmpty || exam.isEmpty) {
        throw const FormatException('ERP returned an unnamed exam result.');
      }
      final declared = _text(row['is_result_declare']) == '1';
      ResultReport? report;
      if (declared && item['report'] != null) {
        try {
          report = _report(item['report'], exam);
        } on FormatException {
          /* Keep the exam visible; do not cache incomplete reports. */
        }
      }
      final number =
          int.tryParse(
            RegExp(
                  r'SEM[-\s]*(\d+)',
                  caseSensitive: false,
                ).firstMatch(semester)?.group(1) ??
                '',
          ) ??
          0;
      exams.add(
        ExamResult(
          semester: semester,
          exam: exam,
          examType: _text(row['student_exam_type']),
          publishedAt: _text(row['idt_date']),
          semesterNumber: number,
          declared: declared,
          report: report,
        ),
      );
    }
    // Preserve multiple attempts in a semester; never deduplicate them by name.
    exams.sort((a, b) {
      final semester = b.semesterNumber.compareTo(a.semesterNumber);
      return semester != 0 ? semester : b.publishedAt.compareTo(a.publishedAt);
    });
    return StudentResults(
      exams: List.unmodifiable(exams),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  ResultReport _report(dynamic response, String expectedExam) {
    if (response is! Map || !response.containsKey('d')) {
      throw const FormatException('Missing result report.');
    }
    dynamic rows = response['d'];
    if (rows is String) rows = jsonDecode(rows);
    if (rows is! List || rows.isEmpty) {
      throw const FormatException('No grades were returned for this result.');
    }
    final first = rows.first as Map;
    // ERP's session chooses the report. Reject stale/overlapping report context.
    if (_text(first['exam_held_id']) != expectedExam) {
      throw const FormatException('ERP returned grades for a different exam.');
    }
    final subjects = <ResultSubject>[];
    for (final row in rows) {
      if (_text(row['exam_held_id']) != expectedExam) {
        throw const FormatException('ERP returned mixed exam reports.');
      }
      final name = _text(row['subject_name']);
      final code = _text(row['sub_code']);
      if (name.isEmpty ||
          code.isEmpty ||
          !row.containsKey('srd_Grade_sub') ||
          !row.containsKey('sub_credit')) {
        throw const FormatException('ERP changed the result report layout.');
      }
      subjects.add(
        ResultSubject(
          name: name,
          code: code,
          credit: _text(row['sub_credit']),
          grade: _text(row['srd_Grade_sub']),
        ),
      );
    }
    return ResultReport(
      sgpa: _text(first['ssrd_SGPA']),
      cgpa: _text(first['ssrd_CGPA']),
      credits: _text(first['ssrd_sgpa_credit']),
      status: _text(first['result']),
      subjects: List.unmodifiable(subjects),
    );
  }
}
