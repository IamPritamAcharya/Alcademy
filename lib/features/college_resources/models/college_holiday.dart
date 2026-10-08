class CollegeHoliday {
  final String name;
  final DateTime from;
  final DateTime to;
  final String description;
  const CollegeHoliday({
    required this.name,
    required this.from,
    required this.to,
    required this.description,
  });
  factory CollegeHoliday.fromJson(Map<String, dynamic> data) => CollegeHoliday(
    name: data['name'] as String,
    from: DateTime.parse(data['from'] as String),
    to: DateTime.parse(data['to'] as String),
    description: data['description'] as String,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'from': from.toIso8601String(),
    'to': to.toIso8601String(),
    'description': description,
  };
}
