import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/refresh_tracker.dart';
import '../widgets/custom_snackbar.dart';
import 'blogview.dart';

class MarkdownListPage extends StatefulWidget {
  @override
  _MarkdownListPageState createState() => _MarkdownListPageState();
}

class _MarkdownListPageState extends State<MarkdownListPage> {
  final String repoUrl =
      'https://api.github.com/repos/Academia-IGIT/DATA_hub/contents/Blog';

  static List<Map<String, String>>?
      cachedFiles; // Static variable for caching files
  static Map<String, String> cachedContent =
      {}; // Static map for caching file content
  late Future<List<Map<String, String>>> markdownFilesFuture;

  @override
  void initState() {
    super.initState();
    markdownFilesFuture = _fetchMarkdownFiles(); // Initialize the future
  }

  Future<List<Map<String, String>>> _fetchMarkdownFiles(
      {bool forceRefresh = false}) async {
    if (cachedFiles != null && !forceRefresh) {
      return cachedFiles!;
    }

    final response = await http.get(Uri.parse(repoUrl));

    if (response.statusCode == 200) {
      List<dynamic> files = json.decode(response.body);

      // Filter and map Markdown files
      cachedFiles = files
          .where((file) => file['name'].toString().endsWith('.md'))
          .map((file) => {
                'name': file['name'].toString(),
                'download_url': file['download_url'].toString(),
              })
          .toList();

      // Preload content for all files
      for (var file in cachedFiles!) {
        await _fetchMarkdownContent(
            file['download_url']!); // Cache the content for each file
      }

      return cachedFiles!;
    } else {
      throw Exception('Failed to load markdown files');
    }
  }

  Future<String> _fetchMarkdownContent(String url) async {
    if (cachedContent.containsKey(url)) {
      return cachedContent[url]!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      cachedContent[url] = response.body;
      return response.body;
    } else {
      throw Exception('Failed to load markdown content');
    }
  }

  Future<void> _handleRefresh() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      // Show cooldown snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          isCooldown: true,
          context: context,
        ) as SnackBar,
      );
      return;
    }

    // Force refresh the files and their content
    setState(() {
      cachedFiles = null; // Clear cached files
      cachedContent.clear(); // Clear cached content
      markdownFilesFuture =
          _fetchMarkdownFiles(forceRefresh: true); // Force refresh
    });
    await markdownFilesFuture; // Await completion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        title: const Text(
          'BLOGS',
          style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 4),
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
          future: markdownFilesFuture,
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
                  'No markdown files found.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final files = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: files.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final file = files[index];
                return GlassmorphicCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MarkdownViewerPage(url: file['download_url']!),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 36,
                      ),
                      title: Text(
                        file['name']!.replaceAll('.md', ''), // Remove .md
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 16,
                          color: Colors.white,
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
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
