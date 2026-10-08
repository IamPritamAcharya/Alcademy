class TimetableClass {
  final String label;
  final String? code;
  final String? subject;
  final String? location;
  final String? batch;
  const TimetableClass({
    required this.label,
    this.code,
    this.subject,
    this.location,
    this.batch,
  });
  String get title => subject ?? label;
}

class TimetableLesson {
  final int weekday;
  final int startMinute;
  final int endMinute;

  /// Multiple labels in a division cell are retained as alternatives.
  final List<TimetableClass> classes;
  const TimetableLesson({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.classes,
  });
  bool get isLab =>
      classes.any((item) => item.label.toUpperCase().contains('LABORATORY'));
}

class TimetableBreak {
  final int startMinute;
  final int endMinute;
  final String label;
  const TimetableBreak({
    required this.startMinute,
    required this.endMinute,
    required this.label,
  });
}

class Timetable {
  final String division;
  final String department;
  final String academicYear;
  final String effectiveFrom;
  final List<int> weekdays;
  final List<TimetableLesson> lessons;
  final List<TimetableBreak> breaks;
  final Map<String, String> subjects;
  final Map<String, String> faculty;
  final DateTime fetchedAt;
  const Timetable({
    required this.division,
    required this.department,
    required this.academicYear,
    required this.effectiveFrom,
    required this.weekdays,
    required this.lessons,
    required this.breaks,
    required this.subjects,
    required this.faculty,
    required this.fetchedAt,
  });
  List<TimetableLesson> forDay(int weekday) =>
      lessons.where((lesson) => lesson.weekday == weekday).toList()
        ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
}
