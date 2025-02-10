import 'package:flutter/material.dart';
import '../../widgets/refresh_tracker.dart';
import '../../widgets/custom_snackbar.dart';
import '../services/data_fetch_service.dart';
import 'story_details_page.dart';

class SuccessStoriesPage extends StatefulWidget {
  @override
  _SuccessStoriesPageState createState() => _SuccessStoriesPageState();
}

class _SuccessStoriesPageState extends State<SuccessStoriesPage> {
  static List<Map<String, String>>?
      cachedStories; // Static variable for caching
  late Future<List<Map<String, String>>> storiesFuture;

  @override
  void initState() {
    super.initState();
    storiesFuture = _fetchStories(); // Initialize the future
  }

  Future<List<Map<String, String>>> _fetchStories(
      {bool forceRefresh = false}) async {
    if (cachedStories != null && !forceRefresh) {
      return cachedStories!;
    }
    cachedStories = await DataFetchService.fetchStories();
    return cachedStories!;
  }

  Future<void> _handleRefresh() async {
  bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
  if (!isRefreshAllowed) {
      // Show cooldown snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          isCooldown: true,
          context: context,
        ),
      );
      return;
    }

    // Proceed with refreshing
    setState(() {
      storiesFuture = _fetchStories(forceRefresh: true); // Force refresh
    });
    await storiesFuture; // Await completion before further actions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        title: const Text(
          'Success Stories',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1D1E),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF1A1D1E),
        child: FutureBuilder<List<Map<String, String>>>(
          future: storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No success stories found.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final stories = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: stories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final story = stories[index];
                return GlassmorphicCard(
                  onTap: () {
                    final name = story['name'];
                    final body = story['body'];

                    // Debugging
                    if (name == null || body == null) {
                      print(
                          'Error: Missing story details. Name: $name, Body: $body');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load story details.'),
                        ),
                      );
                      return; // Stop navigation if data is incomplete
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoryDetailPage(
                          name: story['name']!,
                          body: story['body']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(story['image_url']!),
                      ),
                      title: Text(
                        story['name']!,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        story['company']!,
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const GlassmorphicCard({
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: child,
        ),
      ),
    );
  }
}
