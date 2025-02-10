class Post {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String userId;
  final String email; // Add this field
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.userId,
    required this.email, // Initialize it
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      title: map['title'] as String,
      imageUrl: map['image_url'] as String,
      description: map['description'] as String,
      userId: map['user_id'] as String,
      email: map['email'] as String, // Map it
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'description': description,
      'user_id': userId,
      'email': email, // Include it
      'created_at': createdAt.toIso8601String(),
    };
  }
}
