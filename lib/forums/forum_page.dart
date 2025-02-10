import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:port/config.dart';
import 'package:port/forums/add_post_page.dart';
import 'package:port/forums/post.dart';
import 'package:port/forums/stories_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'database_service.dart';
import 'post_detail_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({Key? key}) : super(key: key);

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  List<Post> posts = [];
  Map<String, String> userNames = {}; // Cache for usernames
  int refreshCount = 0;
  final int maxRefreshesPerHour = 6;
  late DateTime lastRefreshTime;

  // Pagination variables
  int currentPage = 1;
  final int itemsPerPage = 10;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    loadPostsFromCache();
    fetchPostsFromDatabase();
    lastRefreshTime = DateTime.now();
  }

  Future<void> loadPostsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPosts = prefs.getString('cachedPosts');
      if (cachedPosts != null) {
        final decodedData = json.decode(cachedPosts) as List;
        setState(() {
          posts = decodedData.map((data) => Post.fromMap(data)).toList();
          updatePagination();
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cachedPosts');
      debugPrint('Error loading cached posts: $e. Cache cleared.');
    }
  }

  Future<void> savePostsToCache(List<Post> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData =
          json.encode(posts.map((post) => post.toMap()).toList());
      await prefs.setString('cachedPosts', encodedData);
    } catch (e) {
      debugPrint('Error saving posts to cache: $e');
    }
  }

  Future<void> fetchPostsFromDatabase() async {
    final data = await DatabaseService.fetchPosts();
    final fetchedPosts = data.map((item) => Post.fromMap(item)).toList();

    setState(() {
      posts = fetchedPosts;
      updatePagination();
    });

    await savePostsToCache(fetchedPosts);
  }

  void updatePagination() {
    totalPages = (posts.length / itemsPerPage).ceil();
    currentPage = 1; // Reset to first page when posts are updated
  }

  List<Post> getCurrentPagePosts() {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return posts.sublist(
        startIndex, endIndex > posts.length ? posts.length : endIndex);
  }

  Future<void> handleRefresh() async {
    final now = DateTime.now();

    if (refreshCount >= maxRefreshesPerHour) {
      final nextRefreshWindow = lastRefreshTime.add(const Duration(hours: 1));
      if (now.isBefore(nextRefreshWindow)) {
        // Show a simple and clean centered popup dialog with dark glassmorphic design
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent closing by tapping outside
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Rounded corners
              ),
              backgroundColor: Colors
                  .transparent, // Transparent background for glassmorphism
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Rounded corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 8.0, sigmaY: 8.0), // Slight blur effect
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.6), // Semi-transparent dark background
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4), // Shadow effect
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.greenAccent,
                          size: 40, // Smaller icon size
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Refresh Limit Reached',
                          style: TextStyle(
                            fontSize: 18, // Smaller font size
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your limit will reset after 1 hour.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14, // Smaller font size for clarity
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent, // Light blue button
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Rounded button
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14, // Smaller font size for the button
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        return;
      } else {
        refreshCount = 0;
        lastRefreshTime = now;
      }
    }

    setState(() {
      refreshCount += 1;
    });

    await fetchPostsFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final currentPosts = getCurrentPagePosts();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1A1D1E),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.white.withOpacity(0.2),
              height: 1,
            ),
          ),
          title: const Text(
            'IGIT THREADS',
            style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'ProductSans',
                letterSpacing: 2),
          )),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              backgroundColor: const Color(0xFF1A1D1E),
              color: Colors.redAccent,
              onRefresh: handleRefresh,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: currentPosts.isEmpty
                    ? 1
                    : currentPosts.length + 2, // Empty state fallback
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: StoriesWidget(stories: storyUrls),
                    );
                  }
                  if (index == currentPosts.length + 1 ||
                      currentPosts.isEmpty) {
                    return const SizedBox(
                      height: 20,
                    ); // Footer or fallback space
                  }
                  final post = currentPosts[index - 1];
                  final userName = userNames[post.userId] ?? '';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailPage(post: post),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 1,
                        color: const Color.fromARGB(255, 35, 35, 35),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.black.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                    ),
                                    child: post.imageUrl.isNotEmpty
                                        ? Hero(
                                            tag: post.id,
                                            child: Image.network(
                                              post.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons
                                                      .image_not_supported),
                                            ),
                                          )
                                        : const Icon(Icons.image_not_supported),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.title,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Posted by: $userName ${post.email}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (posts.length > itemsPerPage)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: currentPage > 1 ? Colors.redAccent : Colors.grey,
                    ),
                    onPressed: currentPage > 1
                        ? () {
                            setState(() {
                              currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $currentPage of $totalPages',
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: currentPage < totalPages
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                    onPressed: currentPage < totalPages
                        ? () {
                            setState(() {
                              currentPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
      floatingActionButton: Padding(
        padding:
            const EdgeInsets.only(bottom: 90), // Adjust this value as needed
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Customize corner radius
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostPage()),
          ).then((_) => fetchPostsFromDatabase()),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
