import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/utils/refresh_tracker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'club_model.dart';
import 'club_post_detail.dart';

final supabase = Supabase.instance.client;

class ClubPostsList extends StatefulWidget {
  final String clubId;
  const ClubPostsList({super.key, required this.clubId});

  @override
  State<ClubPostsList> createState() => ClubPostsListState();
}

class ClubPostsListState extends State<ClubPostsList> {
  List<ClubPost> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  int _currentPage = 0;
  final int _postsPerPage = 10;
  String? _errorMessage;

  int _likesRemaining = 20;
  int _commentsRemaining = 10;

  Timer? _autoRefreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    RefreshTracker.init().then((_) {
      _loadMorePosts();
      _initRateLimits();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    debugPrint(' [UI AUTO REFRESH] Starting auto-refresh timer');
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(Duration(hours: 1), (timer) {
      debugPrint(' [UI AUTO REFRESH] Auto-refresh timer triggered');
      if (mounted) {
        debugPrint(
            ' [UI AUTO REFRESH] Widget is mounted, calling refreshPosts');
        refreshPosts();
      } else {
        debugPrint(' [UI AUTO REFRESH] Widget not mounted, skipping refresh');
      }
    });
  }

  String getClubId() {
    return widget.clubId;
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
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_clock_outlined,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daily Limit Reached',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You’ve reached your daily limit for $actionType.\n\nLimit resets at midnight.\nWe apologize for the inconvenience. This is because the app is free of cost and we have limited processing power.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadMorePosts({bool forceRefresh = false}) async {
    debugPrint(
        ' [UI LOAD MORE] _loadMorePosts called (forceRefresh: $forceRefresh, isLoading: $_isLoading, hasMorePosts: $_hasMorePosts)');

    if (_isLoading || !_hasMorePosts) {
      debugPrint(' [UI LOAD MORE] Skipping - already loading or no more posts');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    debugPrint(
        ' [UI LOAD MORE] Set loading state, fetching page $_currentPage...');

    try {
      final newPosts = await fetchClubPostsPaginated(
        widget.clubId,
        _currentPage,
        _postsPerPage,
        forceRefresh: forceRefresh,
      );

      debugPrint(
          ' [UI LOAD MORE] Received ${newPosts.length} posts with like data, updating state...');
      setState(() {
        _posts.addAll(newPosts);
        _currentPage++;
        _hasMorePosts = newPosts.length == _postsPerPage;
        _isLoading = false;
      });
      debugPrint(
          ' [UI LOAD MORE] State updated - Total posts: ${_posts.length}, Current page: $_currentPage, Has more: $_hasMorePosts');
    } catch (e) {
      debugPrint(' [UI LOAD MORE] Error occurred: $e');
      setState(() {
        _errorMessage = "Failed to load posts: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshPosts() async {
    debugPrint(
        ' [UI REFRESH] refreshPosts called (isRefreshing: $_isRefreshing)');

    if (_isRefreshing) {
      debugPrint(' [UI REFRESH] Already refreshing, skipping');
      return;
    }

    final canRefresh = await RefreshTracker.incrementRefreshCount();
    if (!canRefresh) {
      debugPrint(' [UI REFRESH] Refresh limit reached');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Refresh limit reached. Please wait before refreshing again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    debugPrint(' [UI REFRESH] Starting refresh process...');
    setState(() {
      _isRefreshing = true;
      _posts = [];
      _currentPage = 0;
      _hasMorePosts = true;
      _errorMessage = null;
    });

    try {
      debugPrint(' [UI REFRESH] Loading fresh data...');
      await _loadMorePosts(forceRefresh: true);
      await _initRateLimits();
      debugPrint(' [UI REFRESH] Refresh completed successfully');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        debugPrint(' [UI REFRESH] Refresh process finished');
      }
    }
  }

  Future<void> _showSignInDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign In Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please sign in to interact with posts.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            if (mounted) {
                              context.push('/user');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      await _showSignInDialog();
      return;
    }
    if (!await _canPerformAction('like')) {
      return;
    }

    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      setState(() {
        _posts[postIndex] = post.copyWith(
          likeCount:
              post.isLikedByUser ? post.likeCount - 1 : post.likeCount + 1,
          isLikedByUser: !post.isLikedByUser,
        );
      });
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

      await ClubDataCache.clearClubPostsCache(widget.clubId);
    } catch (e) {
      if (postIndex != -1) {
        final post = _posts[postIndex];
        setState(() {
          _posts[postIndex] = post.copyWith(
            likeCount:
                post.isLikedByUser ? post.likeCount - 1 : post.likeCount + 1,
            isLikedByUser: !post.isLikedByUser,
          );
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling like: ${e.toString()}')),
        );
      }
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
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LineIcons.newspaper,
                      color: Colors.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Latest Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (_posts.isEmpty && !_isLoading)
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.article_outlined,
                          color: Colors.white38,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No posts yet",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_posts.length, (index) {
                final post = _posts[index];

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onTap: () async {
                        final currentComments = await _getPostComments(post.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClubPostDetailPage(
                              post: post,
                              initialLikeCount: post.likeCount,
                              initialHasLiked: post.isLikedByUser,
                              initialComments: currentComments,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.body,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            if (post.images.isNotEmpty)
                              Container(
                                height: 180,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.images.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, imgIndex) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                                                color: Colors.white54,
                                                size: 32,
                                              ),
                                            ),
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            width: 280,
                                            height: 180,
                                            color: Colors.grey[800],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _likesRemaining <= 0 &&
                                          !post.isLikedByUser
                                      ? () => _showRateLimitDialog('likes')
                                      : () => _toggleLike(post.id),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: post.isLikedByUser
                                          ? Colors.pinkAccent.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: post.isLikedByUser
                                          ? Border.all(
                                              color: Colors.pinkAccent
                                                  .withOpacity(0.3),
                                            )
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              post.isLikedByUser
                                                  ? LineIcons.heartAlt
                                                  : LineIcons.heart,
                                              color: post.isLikedByUser
                                                  ? Colors.pinkAccent
                                                  : _likesRemaining <= 0
                                                      ? Colors.grey
                                                      : Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${post.likeCount}',
                                              style: TextStyle(
                                                color: post.isLikedByUser
                                                    ? Colors.pinkAccent
                                                    : Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () => _showCommentBottomSheet(post.id),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Icon(
                                          LineIcons.comment,
                                          color: _commentsRemaining <= 0
                                              ? Colors.grey
                                              : Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        final link =
                                            "https://aca-web-c0e77.web.app/post/${post.id}";
                                        Share.share(
                                            "Check out this post: ${post.title}\n$link");
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Icon(
                                          LineIcons.share,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (_hasMorePosts && _posts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _loadMorePosts(forceRefresh: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Load more",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else if (_posts.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    "No more posts",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
        if (_isRefreshing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
