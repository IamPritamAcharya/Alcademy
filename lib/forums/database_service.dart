import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DatabaseService {
  static const String postsTable = 'posts';

  /// Fetch all posts from the database, including user display name
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await supabase
        .from(postsTable)
        .select(
            'id, title, image_url, description, user_id, email, created_at') // Using "email" to store display name
        .order('created_at', ascending: false);

    return response;
  }

  /// Add a new post to the database with the user's display name included
  static Future<bool> addPost(String title, String imageUrl, String description,
      String userId, String userEmail) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Check if the user has already made a post today
    final existingPost = await supabase
        .from(postsTable)
        .select()
        .eq('user_id', userId)
        .gte('created_at', startOfToday.toIso8601String())
        .limit(1)
        .maybeSingle();

    if (existingPost != null) {
      return false; // User has already posted today
    }

    // Insert the post along with the user's display name (stored in "email" column)
    await supabase.from(postsTable).insert({
      'title': title,
      'image_url': imageUrl,
      'description': description,
      'user_id': userId,
      'email': userEmail, // Store display name instead of email
      'created_at': now.toIso8601String(),
    });

    return true;
  }
}
