class PrivateNote {
  final String title;
  final String content;
  final int createdAt;
  final int modifiedAt;
  final Map<String, dynamic> metadata;
  const PrivateNote(
      {required this.title,
      required this.content,
      required this.createdAt,
      required this.modifiedAt,
      this.metadata = const {}});

  factory PrivateNote.fromJson(Map<String, dynamic> json) => PrivateNote(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      modifiedAt: (json['modifiedAt'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json)
        ..removeWhere((key, _) => const [
              'title',
              'content',
              'createdAt',
              'modifiedAt'
            ].contains(key)));

  Map<String, dynamic> toJson() => {
        ...metadata,
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'modifiedAt': modifiedAt
      };
}
