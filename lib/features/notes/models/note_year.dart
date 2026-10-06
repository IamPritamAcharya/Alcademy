class NoteYear {
  final String name;
  final String url;
  const NoteYear({required this.name, required this.url});

  factory NoteYear.fromJson(Map<String, dynamic> json) {
    if (json['name'] is! String || json['url'] is! String) {
      throw const FormatException('Invalid note year');
    }
    return NoteYear(name: json['name'] as String, url: json['url'] as String);
  }

  Map<String, String> toJson() => {'name': name, 'url': url};
}
