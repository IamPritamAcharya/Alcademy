class ResultSubject {
  final String code, name, credit, grade;
  const ResultSubject({
    required this.code,
    required this.name,
    required this.credit,
    required this.grade,
  });
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'credit': credit,
    'grade': grade,
  };
  factory ResultSubject.fromJson(Map<String, dynamic> row) => ResultSubject(
    code: row['code'] as String,
    name: row['name'] as String,
    credit: row['credit'] as String,
    grade: row['grade'] as String,
  );
}

class ResultReport {
  final String sgpa, cgpa, credits, status;
  final List<ResultSubject> subjects;
  const ResultReport({
    required this.sgpa,
    required this.cgpa,
    required this.credits,
    required this.status,
    required this.subjects,
  });
  Map<String, dynamic> toJson() => {
    'sgpa': sgpa,
    'cgpa': cgpa,
    'credits': credits,
    'status': status,
    'subjects': subjects.map((row) => row.toJson()).toList(),
  };
  factory ResultReport.fromJson(Map<String, dynamic> row) => ResultReport(
    sgpa: row['sgpa'] as String,
    cgpa: row['cgpa'] as String,
    credits: row['credits'] as String,
    status: row['status'] as String,
    subjects: List.unmodifiable(
      (row['subjects'] as List).map(
        (s) => ResultSubject.fromJson(Map<String, dynamic>.from(s as Map)),
      ),
    ),
  );
}

class ExamResult {
  final String semester, exam, examType, publishedAt;
  final int semesterNumber;
  final bool declared;
  final ResultReport? report;
  const ExamResult({
    required this.semester,
    required this.exam,
    required this.examType,
    required this.publishedAt,
    required this.semesterNumber,
    required this.declared,
    this.report,
  });
  Map<String, dynamic> toJson() => {
    'semester': semester,
    'exam': exam,
    'examType': examType,
    'publishedAt': publishedAt,
    'semesterNumber': semesterNumber,
    'declared': declared,
    'report': report?.toJson(),
  };
  factory ExamResult.fromJson(Map<String, dynamic> row) => ExamResult(
    semester: row['semester'] as String,
    exam: row['exam'] as String,
    examType: row['examType'] as String,
    publishedAt: row['publishedAt'] as String,
    semesterNumber: row['semesterNumber'] as int,
    declared: row['declared'] as bool,
    report: row['report'] == null
        ? null
        : ResultReport.fromJson(
            Map<String, dynamic>.from(row['report'] as Map),
          ),
  );
}

class StudentResults {
  final List<ExamResult> exams;
  final DateTime fetchedAt;
  const StudentResults({required this.exams, required this.fetchedAt});
  bool get complete =>
      exams.every((row) => !row.declared || row.report != null);
  Map<String, dynamic> toJson() => {
    'exams': exams.map((row) => row.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  factory StudentResults.fromJson(Map<String, dynamic> data) => StudentResults(
    exams: List.unmodifiable(
      (data['exams'] as List).map(
        (row) => ExamResult.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    ),
    fetchedAt: DateTime.parse(data['fetchedAt'] as String).toLocal(),
  );
}
