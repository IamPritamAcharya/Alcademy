
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Club {
  final String id;
  final String name;
  final String bannerUrl;
  final String logoUrl;
  final int memberCount;
  final String clubGroup; 

  Club({
    required this.id,
    required this.name,
    required this.bannerUrl,
    required this.logoUrl,
    required this.memberCount,
    required this.clubGroup,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      memberCount: json['member_count'] ?? 0,
      clubGroup: json['club_group'] ?? '', 
    );
  }

  factory Club.empty() {
    return Club(
      id: '',
      name: '',
      bannerUrl: '',
      logoUrl: '',
      memberCount: 0,
      clubGroup: '', 
    );
  }
}


class ClubPost {
  final String id;
  final String title;
  final String body;
  final List<String> images;
  final DateTime createdAt;

  ClubPost({
    required this.id,
    required this.title,
    required this.body,
    required this.images,
    required this.createdAt,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'],
      title: json['title'],
      body: json['body'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

Future<List<Club>> fetchClubs() async {
  final response = await supabase.from('clubs').select();
  return response.map((json) => Club.fromJson(json)).toList();
}

Future<List<ClubPost>> fetchClubPosts(String clubId) async {
  final response = await supabase
      .from('club_posts')
      .select()
      .eq('club_id', clubId)
      .order('created_at', ascending: false);
  return response.map((json) => ClubPost.fromJson(json)).toList();
}

Future<List<ClubPost>> fetchPostById(String postId) async {
  final response =
      await supabase.from('club_posts').select().eq('id', postId).limit(1);
  return response.map((json) => ClubPost.fromJson(json)).toList();
}
