import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/pages/club/ImageViewerPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'club_model.dart';

class ClubPostDetailPage extends StatefulWidget {
  final ClubPost? post; 
  final String? postId; 
  final int? initialLikeCount; 
  final bool? initialHasLiked; 
  final List<Map<String, dynamic>>? initialComments; 

  const ClubPostDetailPage({
    this.post,
    this.postId,
    this.initialLikeCount, 
    this.initialHasLiked, 
    this.initialComments, 
    super.key,
  }) : assert(post != null || postId != null,
            'Either post or postId must be provided');

  @override
  State<ClubPostDetailPage> createState() => _ClubPostDetailPageState();
}

class _ClubPostDetailPageState extends State<ClubPostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _hasLiked = false;
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = [];
  ClubPost? _post;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePost();
  }

  Future<void> _initializePost() async {
    if (widget.post != null) {
      _post = widget.post;

      
      if (widget.initialLikeCount != null && widget.initialHasLiked != null) {
        _likeCount = widget.initialLikeCount!;
        _hasLiked = widget.initialHasLiked!;
      } else {
        await _fetchLikesAndStatus();
      }

      if (widget.initialComments != null) {
        _comments = widget.initialComments!;
      } else {
        await _fetchComments();
      }
    } else if (widget.postId != null) {
      
      setState(() => _isLoading = true);
      try {
        final posts = await fetchPostById(widget.postId!);
        if (posts.isNotEmpty) {
          _post = posts.first;
          await _fetchLikesAndStatus();
          await _fetchComments();
        }
      } catch (e) {
        print('Error fetching post: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String get postId => _post?.id ?? widget.postId ?? '';

  Future<void> _fetchLikesAndStatus() async {
    if (postId.isEmpty) return;
    _likeCount = await _getLikeCount(postId);
    _hasLiked = await _hasUserLiked(postId);
    if (mounted) setState(() {});
  }

  Future<void> _toggleLike() async {
    if (postId.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    print('User ID in _toggleLike: $userId'); 
    if (userId == null) {
      print('Showing sign in dialog from _toggleLike'); 
      _showSignInDialog();
      return;
    }

    
    final previousLiked = _hasLiked;
    final previousCount = _likeCount;

    setState(() {
      _hasLiked = !_hasLiked;
      _likeCount = _hasLiked ? _likeCount + 1 : _likeCount - 1;
    });

    try {
      final existing = await Supabase.instance.client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }

      
      await _fetchLikesAndStatus();
    } catch (e) {
      
      setState(() {
        _hasLiked = previousLiked;
        _likeCount = previousCount;
      });
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  Future<int> _getLikeCount(String postId) async {
    try {
      final res = await Supabase.instance.client
          .from('post_likes')
          .select()
          .eq('post_id', postId);
      return res.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> _hasUserLiked(String postId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;
      final res = await Supabase.instance.client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchComments() async {
    if (postId.isEmpty) return;

    try {
      final res = await Supabase.instance.client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _addComment() async {
    if (postId.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    print('User in _addComment: $user'); 
    if (user == null) {
      print('Showing sign in dialog from _addComment'); 
      _showSignInDialog();
      return;
    }

    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      try {
        await Supabase.instance.client.from('post_comments').insert({
          'post_id': postId,
          'user_id': user.id,
          'comment': text,
          'user_name': user.userMetadata?['name'] ?? 'Unknown',
          'user_avatar': user.userMetadata?['avatar_url'],
        });
        _commentController.clear();
        await _fetchComments();
      } catch (e) {
        print('Error adding comment: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error posting comment: $e')),
          );
        }
      }
    }
  }

  void _sharePost(String postId) {
    final link = 'https://aca-web-c0e77.web.app/post/$postId';
    Share.share('Check out this post: $link');
  }

  void _openImageViewer(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
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
                              context.go('/user');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_post == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(
          child: Text(
            'Post not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1A1D1E),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.white.withOpacity(0.2),
              height: 1,
            ),
          )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _post!.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _post!.body,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (_post!.images.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _post!.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    return GestureDetector(
                      onTap: () => _openImageViewer(_post!.images, index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                _post!.images[index],
                                width: 320,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 320,
                                    height: 220,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.white70, size: 48),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 320,
                                    height: 220,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _hasLiked ? LineIcons.heartAlt : LineIcons.heart,
                    color: _hasLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(
                  '$_likeCount likes',
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LineIcons.share, color: Colors.white),
                  onPressed: () => _sharePost(postId),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _addComment,
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Comments",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (_comments.isEmpty)
              const Text("No comments yet.",
                  style: TextStyle(color: Colors.white54)),
            ..._comments.map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: c['user_avatar'] != null
                          ? NetworkImage(c['user_avatar'])
                          : null,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['user_name'] ?? 'Unknown',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['comment'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
