double calculateSGPA(Map<String, String> grades, List<Map<String, dynamic>> subjects) {
  const gradePoints = {'O': 10, 'E': 9, 'A': 8, 'B': 7, 'C': 6, 'D': 5, 'M': 0};
  int totalCredits = 0;
  int totalCreditPoints = 0;

  grades.forEach((subject, grade) {
    int gradePoint = gradePoints[grade] ?? 0;

    // Find the corresponding subject credit
    int credit = subjects.firstWhere((item) => item['subject'] == subject)['credit'];
    totalCredits += credit;
    totalCreditPoints += gradePoint * credit;
  });

  return totalCredits > 0 ? totalCreditPoints / totalCredits : 0.0;
}
