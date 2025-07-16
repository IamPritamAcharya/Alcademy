import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/pages/club/ImageViewerPage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'club_model.dart';

class ClubPostDetailPage extends StatefulWidget {
  final String postId;

  const ClubPostDetailPage({required this.postId, super.key});

  @override
  State<ClubPostDetailPage> createState() => _ClubPostDetailPageState();
}

class _ClubPostDetailPageState extends State<ClubPostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _hasLiked = false;
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchLikesAndStatus();
    _fetchComments();
  }

  Future<void> _fetchLikesAndStatus() async {
    _likeCount = await _getLikeCount(widget.postId);
    _hasLiked = await _hasUserLiked(widget.postId);
    setState(() {});
  }

  Future<void> _toggleLike() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await Supabase.instance.client
        .from('post_likes')
        .select('id')
        .eq('post_id', widget.postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await Supabase.instance.client
          .from('post_likes')
          .delete()
          .eq('id', existing['id']);
    } else {
      await Supabase.instance.client.from('post_likes').insert({
        'post_id': widget.postId,
        'user_id': userId,
      });
    }
    await _fetchLikesAndStatus();
  }

  Future<int> _getLikeCount(String postId) async {
    final res = await Supabase.instance.client
        .from('post_likes')
        .select()
        .eq('post_id', postId);
    return res.length;
  }

  Future<bool> _hasUserLiked(String postId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    final res = await Supabase.instance.client
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<void> _fetchComments() async {
    final res = await Supabase.instance.client
        .from('post_comments')
        .select()
        .eq('post_id', widget.postId)
        .order('created_at', ascending: false);
    setState(() {
      _comments = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _addComment() async {
    final user = Supabase.instance.client.auth.currentUser;
    final text = _commentController.text.trim();
    if (user != null && text.isNotEmpty) {
      await Supabase.instance.client.from('post_comments').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'comment': text,
        'user_name': user.userMetadata?['name'] ?? 'Unknown',
        'user_avatar': user.userMetadata?['avatar_url'],
      });
      _commentController.clear();
      await _fetchComments();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClubPost>>(
      future: fetchPostById(widget.postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E1E1E),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final post = snapshot.data!.first;

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
                  post.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.body,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                if (post.images.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        return GestureDetector(
                          onTap: () => _openImageViewer(post.images, index),
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
                                    post.images[index],
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
                      onPressed: () => _sharePost(widget.postId),
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
      },
    );
  }
}
