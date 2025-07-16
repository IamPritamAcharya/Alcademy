import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'RepresentativesPage.dart';
import 'club_model.dart';
import 'club_post_detail.dart';

final supabase = Supabase.instance.client;

class ClubPostsList extends StatefulWidget {
  final String clubId;
  const ClubPostsList({super.key, required this.clubId});

  @override
  State<ClubPostsList> createState() => _ClubPostsListState();
}

class _ClubPostsListState extends State<ClubPostsList> {
  List<ClubPost> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  int _currentPage = 0;
  final int _postsPerPage = 10;
  String? _errorMessage;

  
  int _likesRemaining = 20;
  int _commentsRemaining = 10;
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _loadMorePosts();
    _initRateLimits();
  }

  String getClubId() {
    return widget.clubId ?? 'default_club_id';
  }

  Future<void> _initRateLimits() async {
    final today = _getTodayKey();
    final prefs = await SharedPreferences.getInstance();

    
    final lastDate = prefs.getString('last_rate_limit_date') ?? '';
    if (lastDate != today) {
      
      await prefs.setString('last_rate_limit_date', today);
      await prefs.setInt('likes_used_$today', 0);
      await prefs.setInt('comments_used_$today', 0);
    }

    
    _currentDate = today;
    final likesUsed = prefs.getInt('likes_used_$today') ?? 0;
    final commentsUsed = prefs.getInt('comments_used_$today') ?? 0;

    setState(() {
      _likesRemaining = 20 - likesUsed;
      _commentsRemaining = 10 - commentsUsed;
    });
  }

  String _getTodayKey() {
    
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _incrementLikeUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    final likesUsed = prefs.getInt('likes_used_$today') ?? 0;
    await prefs.setInt('likes_used_$today', likesUsed + 1);

    setState(() {
      _likesRemaining = 20 - (likesUsed + 1);
    });
  }

  Future<void> _incrementCommentUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    final commentsUsed = prefs.getInt('comments_used_$today') ?? 0;
    await prefs.setInt('comments_used_$today', commentsUsed + 1);

    setState(() {
      _commentsRemaining = 10 - (commentsUsed + 1);
    });
  }

  Future<bool> _canPerformAction(String actionType) async {
    await _initRateLimits(); 

    if (actionType == 'like' && _likesRemaining <= 0) {
      _showRateLimitDialog('likes');
      return false;
    } else if (actionType == 'comment' && _commentsRemaining <= 0) {
      _showRateLimitDialog('comments');
      return false;
    }

    return true;
  }

  void _showRateLimitDialog(String actionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Daily Limit Reached',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'You\'ve reached your daily limit for $actionType. The limit will reset at midnight.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMorePosts) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newPosts = await fetchClubPostsPaginated(
        widget.clubId,
        _currentPage,
        _postsPerPage,
      );

      setState(() {
        _posts.addAll(newPosts);
        _currentPage++;
        _hasMorePosts = newPosts.length == _postsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load posts: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<List<ClubPost>> fetchClubPostsPaginated(
      String clubId, int page, int limit) async {
    try {
      final startIndex = page * limit;
      final response = await supabase
          .from('club_posts')
          .select('*')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      return response.map((post) => ClubPost.fromJson(post)).toList();
    } catch (e) {
      throw Exception('Failed to fetch paginated posts: $e');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = [];
      _currentPage = 0;
      _hasMorePosts = true;
      _errorMessage = null;
    });
    await _loadMorePosts();
    await _initRateLimits(); 
  }

  Future<void> _toggleLike(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    
    if (!await _canPerformAction('like')) {
      return;
    }

    try {
      final existing = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await supabase.from('post_likes').delete().eq('id', existing['id']);
      } else {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }

      
      await _incrementLikeUsage();

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling like: ${e.toString()}')),
      );
    }
  }

  Future<int> _getLikeCount(String postId) async {
    try {
      final response =
          await supabase.from('post_likes').select('*').eq('post_id', postId);
      return response.length;
    } catch (e) {
      return 0; 
    }
  }

  Future<bool> _hasUserLiked(String postId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final data = await supabase
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false; 
    }
  }

  Future<List<Map<String, dynamic>>> _getPostComments(String postId) async {
    try {
      final comments = await supabase
          .from('post_comments')
          .select('comment, created_at, user_name, user_avatar')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return comments;
    } catch (e) {
      return []; 
    }
  }

  Future<void> _showCommentBottomSheet(String postId) async {
    final commentController = TextEditingController();
    List<Map<String, dynamic>> comments = await _getPostComments(postId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Comments",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: comments.isEmpty
                            ? const Center(
                                child: Text(
                                  "No comments yet",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: comments.length,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemBuilder: (context, index) {
                                  final c = comments[index];
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundImage: c['user_avatar'] != null
                                          ? NetworkImage(c['user_avatar'])
                                          : null,
                                      backgroundColor: Colors.grey,
                                      child: c['user_avatar'] == null
                                          ? const Icon(Icons.person,
                                              color: Colors.white)
                                          : null,
                                    ),
                                    title: Text(
                                      c['user_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c['comment'],
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(color: Colors.white24, height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: commentController,
                                maxLines: 3,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: _commentsRemaining > 0
                                      ? 'Write a comment...'
                                      : 'Daily comment limit reached',
                                  hintStyle:
                                      const TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: const Color(0xFF2C2C2C),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                enabled: _commentsRemaining > 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _commentsRemaining <= 0
                                  ? null
                                  : () async {
                                      try {
                                        
                                        if (!await _canPerformAction(
                                            'comment')) {
                                          Navigator.pop(context);
                                          return;
                                        }

                                        final user = supabase.auth.currentUser;
                                        final comment =
                                            commentController.text.trim();
                                        if (user != null &&
                                            comment.isNotEmpty) {
                                          await supabase
                                              .from('post_comments')
                                              .insert({
                                            'post_id': postId,
                                            'user_id': user.id,
                                            'comment': comment,
                                            'user_name':
                                                user.userMetadata?['name'] ??
                                                    'Unknown',
                                            'user_avatar': user
                                                .userMetadata?['avatar_url'],
                                          });

                                          
                                          await _incrementCommentUsage();

                                          commentController.clear();
                                          comments =
                                              await _getPostComments(postId);
                                          setStateSheet(() {});
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error posting comment: ${e.toString()}')),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: Colors.white,
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClubRepresentativesPage(
                          clubId:
                              getClubId(), 
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    foregroundColor: Colors.black, 
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), 
                    ),
                  ),
                  child: const Text(
                    "Representatives",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600, 
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          _posts.isEmpty && !_isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined,
                            color: Colors.white70, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          "No posts yet",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _refreshPosts,
                          child: const Text("Refresh",
                              style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(top: 5),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length + 1, 
                  itemBuilder: (context, index) {
                    
                    if (index == _posts.length) {
                      if (_isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        );
                      } else if (_hasMorePosts) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextButton(
                              onPressed: _loadMorePosts,
                              child: const Text("Load more",
                                  style: TextStyle(color: Colors.blue)),
                            ),
                          ),
                        );
                      } else {
                        return _posts.isNotEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    "No more posts",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                    }

                    
                    final post = _posts[index];

                    return FutureBuilder(
                      future: Future.wait(
                          [_getLikeCount(post.id), _hasUserLiked(post.id)]),
                      builder:
                          (context, AsyncSnapshot<List<dynamic>> likeSnapshot) {
                        if (!likeSnapshot.hasData) {
                          return const SizedBox(
                            height: 100,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          );
                        }

                        final likeCount = likeSnapshot.data![0] as int;
                        final isLiked = likeSnapshot.data![1] as bool;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ClubPostDetailPage(postId: post.id),
                              ),
                            ).then((_) => _refreshPosts());
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                
                                Text(
                                  post.body,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                

                                if (post.images.isNotEmpty)
                                  SizedBox(
                                    height: 180,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: post.images.length,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              2), 
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, imgIndex) {
                                        return ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            post.images[imgIndex],
                                            width: 280,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 280,
                                                height: 180,
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white70),
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                width: 280,
                                                height: 180,
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                const SizedBox(height: 12),

                                
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isLiked
                                                ? LineIcons.heartAlt
                                                : LineIcons.heart,
                                            color: isLiked
                                                ? Colors.pinkAccent
                                                : _likesRemaining <= 0
                                                    ? Colors.grey
                                                    : Colors.white,
                                          ),
                                          onPressed: _likesRemaining <= 0 &&
                                                  !isLiked
                                              ? () =>
                                                  _showRateLimitDialog('likes')
                                              : () => _toggleLike(post.id),
                                        ),
                                        Text('$likeCount',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: Icon(
                                            LineIcons.comment,
                                            color: _commentsRemaining <= 0
                                                ? Colors.grey
                                                : Colors.white,
                                          ),
                                          onPressed: () =>
                                              _showCommentBottomSheet(post.id),
                                        ),
                                      ],
                                    ),

                                    IconButton(
                                      icon: const Icon(LineIcons.share,
                                          color: Colors.white),
                                      onPressed: () {
                                        final link =
                                            "https://aca-web-c0e77.web.app/post/${post.id}";
                                        Share.share(
                                            "Check out this post: ${post.title}\n$link");
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
