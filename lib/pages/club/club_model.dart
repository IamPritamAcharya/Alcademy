import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

final supabase = Supabase.instance.client;

class Club {
  final String id;
  final String name;
  final String bannerUrl;
  final String logoUrl;
  final int memberCount;
  final String clubGroup;
  final String? description;
  final Map<String, String>? socialMedia;

  Club({
    required this.id,
    required this.name,
    required this.bannerUrl,
    required this.logoUrl,
    required this.memberCount,
    required this.clubGroup,
    this.description,
    this.socialMedia,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      memberCount: json['member_count'] ?? 0,
      clubGroup: json['club_group'] ?? '',
      description: json['description'],
      socialMedia: json['social_media'] != null
          ? Map<String, String>.from(json['social_media'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'banner_url': bannerUrl,
      'logo_url': logoUrl,
      'member_count': memberCount,
      'club_group': clubGroup,
      'description': description,
      'social_media': socialMedia,
    };
  }

  factory Club.empty() {
    return Club(
      id: '',
      name: '',
      bannerUrl: '',
      logoUrl: '',
      memberCount: 0,
      clubGroup: '',
      description: null,
      socialMedia: null,
    );
  }
}

class ClubPost {
  final String id;
  final String title;
  final String body;
  final List<String> images;
  final DateTime createdAt;
  final String clubId;

  final int likeCount;
  final bool isLikedByUser;

  ClubPost({
    required this.id,
    required this.title,
    required this.body,
    required this.images,
    required this.createdAt,
    required this.clubId,
    this.likeCount = 0,
    this.isLikedByUser = false,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      clubId: json['club_id'] ?? '',
      likeCount: (json['like_count'] as int?) ?? 0,
      isLikedByUser: (json['user_liked'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'club_id': clubId,
      'like_count': likeCount,
      'user_liked': isLikedByUser,
    };
  }

  ClubPost copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? images,
    DateTime? createdAt,
    String? clubId,
    int? likeCount,
    bool? isLikedByUser,
  }) {
    return ClubPost(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      clubId: clubId ?? this.clubId,
      likeCount: likeCount ?? this.likeCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }
}

class ClubDataCache {
  static const String _clubsCacheKey = 'cached_clubs';
  static const String _clubsTimestampKey = 'clubs_cache_timestamp';
  static const String _postsPrefix = 'cached_posts_';
  static const String _postsTimestampPrefix = 'posts_timestamp_';

  static const Duration _cacheExpiry = Duration(minutes: 10);

  static Future<void> _cacheClubs(List<Club> clubs) async {
    debugPrint(' [CACHE] Caching ${clubs.length} clubs to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    final clubsJson = clubs.map((club) => club.toJson()).toList();
    await prefs.setString(_clubsCacheKey, json.encode(clubsJson));
    await prefs.setString(_clubsTimestampKey, DateTime.now().toIso8601String());
    debugPrint(' [CACHE] Clubs cached successfully at ${DateTime.now()}');
  }

  static Future<List<Club>?> _getCachedClubs() async {
    debugPrint(' [CACHE] Checking for cached clubs...');
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_clubsCacheKey);
    final timestampStr = prefs.getString(_clubsTimestampKey);

    if (cachedData == null || timestampStr == null) {
      debugPrint(' [CACHE] No cached clubs found');
      return null;
    }

    final timestamp = DateTime.parse(timestampStr);
    final age = DateTime.now().difference(timestamp);
    debugPrint(' [CACHE] Cached clubs found, age: ${age.inMinutes} minutes');

    if (age > _cacheExpiry) {
      debugPrint(
          ' [CACHE] Cached clubs expired (older than ${_cacheExpiry.inMinutes} minutes)');
      return null;
    }

    final List<dynamic> clubsJson = json.decode(cachedData);
    final clubs = clubsJson.map((json) => Club.fromJson(json)).toList();
    debugPrint(' [CACHE] Returning ${clubs.length} cached clubs');
    return clubs;
  }

  static Future<void> _cacheClubPosts(
      String clubId, List<ClubPost> posts) async {
    debugPrint(
        ' [CACHE] Caching ${posts.length} posts with social data for club $clubId');
    final prefs = await SharedPreferences.getInstance();
    final postsJson = posts.map((post) => post.toJson()).toList();
    await prefs.setString('$_postsPrefix$clubId', json.encode(postsJson));
    await prefs.setString(
        '$_postsTimestampPrefix$clubId', DateTime.now().toIso8601String());
    debugPrint(
        ' [CACHE] Posts with social data cached successfully for club $clubId at ${DateTime.now()}');
  }

  static Future<List<ClubPost>?> _getCachedClubPosts(String clubId) async {
    debugPrint(
        ' [CACHE] Checking for cached posts with social data for club $clubId...');
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('$_postsPrefix$clubId');
    final timestampStr = prefs.getString('$_postsTimestampPrefix$clubId');

    if (cachedData == null || timestampStr == null) {
      debugPrint(' [CACHE] No cached posts found for club $clubId');
      return null;
    }

    final timestamp = DateTime.parse(timestampStr);
    final age = DateTime.now().difference(timestamp);
    debugPrint(
        ' [CACHE] Cached posts found for club $clubId, age: ${age.inMinutes} minutes');

    if (age > _cacheExpiry) {
      debugPrint(
          ' [CACHE] Cached posts expired for club $clubId (older than ${_cacheExpiry.inMinutes} minutes)');
      return null;
    }

    final List<dynamic> postsJson = json.decode(cachedData);
    final posts = postsJson.map((json) => ClubPost.fromJson(json)).toList();
    debugPrint(
        ' [CACHE] Returning ${posts.length} cached posts with social data for club $clubId');
    return posts;
  }

  static Future<void> clearClubPostsCache(String clubId) async {
    debugPrint(' [CACHE] Clearing posts cache for club $clubId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_postsPrefix$clubId');
    await prefs.remove('$_postsTimestampPrefix$clubId');
    debugPrint(' [CACHE] Posts cache cleared for club $clubId');
  }

  static Future<void> clearAllCache() async {
    debugPrint(' [CACHE] Clearing all cache data...');
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int removedCount = 0;

    for (String key in keys) {
      if (key.startsWith(_clubsCacheKey) ||
          key.startsWith(_clubsTimestampKey) ||
          key.startsWith(_postsPrefix) ||
          key.startsWith(_postsTimestampPrefix)) {
        await prefs.remove(key);
        removedCount++;
      }
    }
    debugPrint(' [CACHE] All cache cleared, removed $removedCount keys');
  }
}

Future<List<Club>> fetchClubs({bool forceRefresh = false}) async {
  debugPrint(
      ' [FETCH CLUBS] Starting fetchClubs (forceRefresh: $forceRefresh)');

  if (!forceRefresh) {
    debugPrint(' [FETCH CLUBS] Checking cache first...');
    final cachedClubs = await ClubDataCache._getCachedClubs();
    if (cachedClubs != null) {
      debugPrint(
          ' [FETCH CLUBS] Using cached data, returning ${cachedClubs.length} clubs');
      return cachedClubs;
    }
  } else {
    debugPrint(' [FETCH CLUBS] Force refresh requested, skipping cache');
  }

  try {
    debugPrint(' [FETCH CLUBS] Fetching from Supabase...');
    final response = await supabase.from('clubs').select();
    final clubs = response.map((json) => Club.fromJson(json)).toList();
    debugPrint(
        ' [FETCH CLUBS] Successfully fetched ${clubs.length} clubs from server');

    await ClubDataCache._cacheClubs(clubs);
    return clubs;
  } catch (e) {
    debugPrint(' [FETCH CLUBS] Network error: $e');

    debugPrint(
        ' [FETCH CLUBS] Network failed, trying expired cache as fallback...');
    final cachedClubs = await ClubDataCache._getCachedClubs();
    if (cachedClubs != null) {
      debugPrint(' [FETCH CLUBS] Using expired cached data as fallback');
      return cachedClubs;
    }
    debugPrint(' [FETCH CLUBS] No fallback available, rethrowing error');
    rethrow;
  }
}

Future<List<ClubPost>> fetchClubPosts(String clubId,
    {bool forceRefresh = false}) async {
  debugPrint(
      ' [FETCH POSTS] Starting fetchClubPosts for club $clubId (forceRefresh: $forceRefresh)');

  if (!forceRefresh) {
    debugPrint(' [FETCH POSTS] Checking cache first...');
    final cachedPosts = await ClubDataCache._getCachedClubPosts(clubId);
    if (cachedPosts != null) {
      debugPrint(
          ' [FETCH POSTS] Using cached data, returning ${cachedPosts.length} posts with social data');
      return cachedPosts;
    }
  } else {
    debugPrint(' [FETCH POSTS] Force refresh requested, skipping cache');
  }

  try {
    final userId = supabase.auth.currentUser?.id ?? '';
    debugPrint(' [FETCH POSTS] Fetching posts first...');

    final postsResponse = await supabase
        .from('club_posts')
        .select('*')
        .eq('club_id', clubId)
        .order('created_at', ascending: false);

    debugPrint(' [DEBUG] Found ${postsResponse.length} posts');

    if (postsResponse.isEmpty) {
      await ClubDataCache._cacheClubPosts(clubId, []);
      return [];
    }

    final postIds = postsResponse.map((post) => post['id'] as String).toList();
    debugPrint(' [DEBUG] Post IDs: $postIds');

    final likesResponse = await supabase
        .from('post_likes')
        .select('post_id, user_id')
        .inFilter('post_id', postIds);

    debugPrint(' [DEBUG] Found ${likesResponse.length} total likes');

    final posts = postsResponse.map((post) {
      final postId = post['id'] as String;

      final postLikes =
          likesResponse.where((like) => like['post_id'] == postId).toList();
      final likeCount = postLikes.length;
      final userLiked = postLikes.any((like) => like['user_id'] == userId);

      debugPrint(
          ' [DEBUG] Post $postId: ${postLikes.length} likes, user liked: $userLiked');

      final cleanPost = Map<String, dynamic>.from(post);
      cleanPost['like_count'] = likeCount;
      cleanPost['user_liked'] = userLiked;

      return ClubPost.fromJson(cleanPost);
    }).toList();

    debugPrint(
        ' [FETCH POSTS] Successfully processed ${posts.length} posts with social data');

    await ClubDataCache._cacheClubPosts(clubId, posts);
    return posts;
  } catch (e) {
    debugPrint(' [FETCH POSTS] Network error: $e');

    debugPrint(
        ' [FETCH POSTS] Network failed, trying expired cache as fallback...');
    final cachedPosts = await ClubDataCache._getCachedClubPosts(clubId);
    if (cachedPosts != null) {
      debugPrint(' [FETCH POSTS] Using expired cached data as fallback');
      return cachedPosts;
    }
    debugPrint(' [FETCH POSTS] No fallback available, rethrowing error');
    rethrow;
  }
}

Future<List<ClubPost>> fetchClubPostsPaginated(
    String clubId, int page, int limit,
    {bool forceRefresh = false}) async {
  debugPrint(
      ' [FETCH PAGINATED] Starting fetchClubPostsPaginated for club $clubId (page: $page, limit: $limit, forceRefresh: $forceRefresh)');

  if (page == 0 && !forceRefresh) {
    debugPrint(' [FETCH PAGINATED] First page requested, checking cache...');
    final cachedPosts = await ClubDataCache._getCachedClubPosts(clubId);
    if (cachedPosts != null) {
      final result = cachedPosts.take(limit).toList();
      debugPrint(
          ' [FETCH PAGINATED] Using cached data for first page, returning ${result.length} posts with social data');
      return result;
    }
  } else if (page == 0) {
    debugPrint(
        ' [FETCH PAGINATED] First page with force refresh, skipping cache');
  } else {
    debugPrint(
        ' [FETCH PAGINATED] Page $page requested, fetching from server (pagination doesn\'t use cache)');
  }

  try {
    final startIndex = page * limit;
    final userId = supabase.auth.currentUser?.id ?? '';

    debugPrint(' [FETCH PAGINATED] Fetching posts first...');

    final postsResponse = await supabase
        .from('club_posts')
        .select('*')
        .eq('club_id', clubId)
        .order('created_at', ascending: false)
        .range(startIndex, startIndex + limit - 1);

    debugPrint(' [DEBUG] Found ${postsResponse.length} posts');

    if (postsResponse.isEmpty) {
      return [];
    }

    final postIds = postsResponse.map((post) => post['id'] as String).toList();
    debugPrint(' [DEBUG] Post IDs: $postIds');

    final likesResponse = await supabase
        .from('post_likes')
        .select('post_id, user_id')
        .inFilter('post_id', postIds);

    debugPrint(' [DEBUG] Found ${likesResponse.length} total likes');
    debugPrint(' [DEBUG] Likes data: $likesResponse');

    final posts = postsResponse.map((post) {
      final postId = post['id'] as String;

      final postLikes =
          likesResponse.where((like) => like['post_id'] == postId).toList();
      final likeCount = postLikes.length;
      final userLiked = postLikes.any((like) => like['user_id'] == userId);

      debugPrint(
          ' [DEBUG] Post $postId: ${postLikes.length} likes, user liked: $userLiked');

      final cleanPost = Map<String, dynamic>.from(post);
      cleanPost['like_count'] = likeCount;
      cleanPost['user_liked'] = userLiked;

      return ClubPost.fromJson(cleanPost);
    }).toList();

    debugPrint(
        ' [FETCH PAGINATED] Successfully processed ${posts.length} posts with social data');

    if (page == 0) {
      debugPrint(
          ' [FETCH PAGINATED] Caching first page data with social info...');
      await ClubDataCache._cacheClubPosts(clubId, posts);
    }

    return posts;
  } catch (e) {
    debugPrint(' [FETCH PAGINATED] Network error: $e');

    if (page == 0) {
      debugPrint(
          ' [FETCH PAGINATED] Network failed for first page, trying expired cache as fallback...');
      final cachedPosts = await ClubDataCache._getCachedClubPosts(clubId);
      if (cachedPosts != null) {
        final result = cachedPosts.take(limit).toList();
        debugPrint(
            ' [FETCH PAGINATED] Using expired cached data as fallback, returning ${result.length} posts');
        return result;
      }
    }
    debugPrint(' [FETCH PAGINATED] No fallback available, throwing exception');
    throw Exception('Failed to fetch paginated posts: $e');
  }
}

Future<List<ClubPost>> fetchPostById(String postId) async {
  debugPrint(' [FETCH POST BY ID] Fetching post with ID: $postId');
  try {
    final userId = supabase.auth.currentUser?.id ?? '';

    final response = await supabase.from('club_posts').select('''
          *,
          post_likes(user_id)
        ''').eq('id', postId).limit(1);

    final posts = response.map((post) {
      final postLikes = post['post_likes'] as List? ?? [];
      final likeCount = postLikes.length;
      final userLiked = postLikes.any((like) => like['user_id'] == userId);

      final cleanPost = Map<String, dynamic>.from(post);
      cleanPost['like_count'] = likeCount;
      cleanPost['user_liked'] = userLiked;
      cleanPost.remove('post_likes');

      return ClubPost.fromJson(cleanPost);
    }).toList();

    debugPrint(
        ' [FETCH POST BY ID] Successfully fetched ${posts.length} post(s) with social data');
    return posts;
  } catch (e) {
    debugPrint(' [FETCH POST BY ID] Error fetching post: $e');
    rethrow;
  }
}

class AutoRefreshManager {
  static Timer? _refreshTimer;
  static void Function()? _onRefreshCallback;

  static void startAutoRefresh(void Function() onRefresh) {
    debugPrint(
        ' [AUTO REFRESH] Starting auto-refresh timer (1 hour intervals)');
    _onRefreshCallback = onRefresh;
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(Duration(hours: 1), (timer) {
      debugPrint(' [AUTO REFRESH] Timer triggered, calling refresh callback');
      _onRefreshCallback?.call();
    });
  }

  static void stopAutoRefresh() {
    debugPrint(' [AUTO REFRESH] Stopping auto-refresh timer');
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _onRefreshCallback = null;
  }

  static void dispose() {
    debugPrint(' [AUTO REFRESH] Disposing auto-refresh manager');
    stopAutoRefresh();
  }
}
