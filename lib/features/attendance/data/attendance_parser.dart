import 'dart:convert';
import '../models/attendance.dart';

class AttendanceParser {
  Attendance parse(String source, {DateTime? fetchedAt}) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    List<AttendanceRecord> records(dynamic response, bool subject) {
      if (response is! Map || !response.containsKey('d')) {
        throw const FormatException(
          'ERP returned an unreadable attendance response.',
        );
      }
      dynamic rows = response['d'];
      if (rows is String) rows = jsonDecode(rows);
      if (rows is String &&
          RegExp(
            r'^(Subject Wise )?Attendance record not found\.$',
            caseSensitive: false,
          ).hasMatch(rows)) {
        return [];
      }
      if (rows is! List) {
        throw const FormatException('The ERP attendance layout has changed.');
      }
      return rows.map((raw) {
        final row = raw as Map;
        int count(String key) {
          final value = int.tryParse('${row[key]}');
          if (value == null || value < 0) {
            throw const FormatException(
              'ERP returned an invalid attendance count.',
            );
          }
          return value;
        }

        double percent(String key) {
          final value = double.tryParse(
            '${row[key]}'.replaceAll('%', '').trim(),
          );
          if (value == null || !value.isFinite || value < 0 || value > 100) {
            throw const FormatException(
              'ERP returned an invalid attendance percentage.',
            );
          }
          return value;
        }

        final name = '${row[subject ? 'sub_fullname' : 'month'] ?? ''}'
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (name.isEmpty) {
          throw const FormatException(
            'ERP returned an unnamed attendance record.',
          );
        }
        return AttendanceRecord(
          name: name,
          conducted: count(subject ? 'tot_lect' : 'total_arrange_lect'),
          filled: count(subject ? 'tot_attendance_lect' : 'total_lecture'),
          pending: count(subject ? 'remaining_lect' : 'remaning'),
          attended: count(subject ? 'present_lect' : 'present_lecture'),
          absent: count(subject ? 'absent_lect' : 'absent_lecture'),
          leave: count('total_leave'),
          percentage: percent(subject ? 'persentage_lect' : 'persentage'),
          leavePercentage: percent('percentage_leave'),
          aggregatePercentage: percent('aggr_leave'),
          month: subject ? null : count('month_no'),
          year: subject ? null : count('month_year'),
        );
      }).toList();
    }

    final months = records(data['months'], false)
      ..sort(
        (a, b) => (b.year! * 12 + b.month!).compareTo(a.year! * 12 + a.month!),
      );
    return Attendance(
      months: List.unmodifiable(months),
      subjects: List.unmodifiable(records(data['subjects'], true)),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }
}
