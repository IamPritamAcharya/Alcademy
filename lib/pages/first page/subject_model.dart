class Subject {
  final String name;
  final List<SubjectItem> items;

  Subject({required this.name, required this.items});

  factory Subject.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<SubjectItem> itemList = list.map((i) => SubjectItem.fromJson(i)).toList();

    return Subject(
      name: json['name'],
      items: itemList,
    );
  }
}

class SubjectItem {
  final String name;
  final String url;

  SubjectItem({required this.name, required this.url});

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      name: json['name'],
      url: json['url'],
    );
  }
}
