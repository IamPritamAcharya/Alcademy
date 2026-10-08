class AttendanceRecord {
  final String name;
  final int conducted, filled, pending, attended, absent, leave;
  final double percentage, leavePercentage, aggregatePercentage;
  final int? month, year;
  const AttendanceRecord({
    required this.name,
    required this.conducted,
    required this.filled,
    required this.pending,
    required this.attended,
    required this.absent,
    required this.leave,
    required this.percentage,
    required this.leavePercentage,
    required this.aggregatePercentage,
    this.month,
    this.year,
  });
  Map<String, dynamic> toJson() => {
    'name': name,
    'conducted': conducted,
    'filled': filled,
    'pending': pending,
    'attended': attended,
    'absent': absent,
    'leave': leave,
    'percentage': percentage,
    'leavePercentage': leavePercentage,
    'aggregatePercentage': aggregatePercentage,
    'month': month,
    'year': year,
  };
  factory AttendanceRecord.fromJson(Map<String, dynamic> row) =>
      AttendanceRecord(
        name: row['name'] as String,
        conducted: row['conducted'] as int,
        filled: row['filled'] as int,
        pending: row['pending'] as int,
        attended: row['attended'] as int,
        absent: row['absent'] as int,
        leave: row['leave'] as int,
        percentage: (row['percentage'] as num).toDouble(),
        leavePercentage: (row['leavePercentage'] as num).toDouble(),
        aggregatePercentage: (row['aggregatePercentage'] as num).toDouble(),
        month: row['month'] as int?,
        year: row['year'] as int?,
      );
}

class Attendance {
  final List<AttendanceRecord> months, subjects;
  final DateTime fetchedAt;
  const Attendance({
    required this.months,
    required this.subjects,
    required this.fetchedAt,
  });
  List<AttendanceRecord> get summaryRecords =>
      months.isNotEmpty ? months : subjects;
  int get filled => summaryRecords.fold(0, (sum, row) => sum + row.filled);
  int get attended => summaryRecords.fold(0, (sum, row) => sum + row.attended);
  int get leave => summaryRecords.fold(0, (sum, row) => sum + row.leave);
  double? get percentage =>
      filled == 0 ? null : (attended + leave) * 100 / filled;
  Map<String, dynamic> toJson() => {
    'months': months.map((row) => row.toJson()).toList(),
    'subjects': subjects.map((row) => row.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  factory Attendance.fromJson(Map<String, dynamic> data) => Attendance(
    months: List.unmodifiable(
      (data['months'] as List).map(
        (row) =>
            AttendanceRecord.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    ),
    subjects: List.unmodifiable(
      (data['subjects'] as List).map(
        (row) =>
            AttendanceRecord.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    ),
    fetchedAt: DateTime.parse(data['fetchedAt'] as String).toLocal(),
  );
}
