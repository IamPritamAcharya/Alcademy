import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/features/blog/data/blog_repository.dart';
import 'package:port/features/blog/presentation/blog_detail_page.dart';
import 'package:port/core/network/refresh_tracker.dart';
import 'package:port/shared/widgets/custom_snackbar.dart';

class MarkdownListPage extends StatefulWidget {
  const MarkdownListPage({super.key});

  @override
  State<MarkdownListPage> createState() => _MarkdownListPageState();
}

class _MarkdownListPageState extends State<MarkdownListPage> {
  final _repository = BlogRepository.instance;
  late Future<List<Map<String, String>>> markdownFilesFuture;

  @override
  void initState() {
    super.initState();
    markdownFilesFuture = _fetchMarkdownFiles();
  }

  Future<List<Map<String, String>>> _fetchMarkdownFiles(
          {bool forceRefresh = false}) =>
      _repository.getFiles(forceRefresh: forceRefresh);

  Future<void> _handleRefresh() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.build(
          isCooldown: true,
          context: context,
        ),
      );
      return;
    }

    if (mounted) {
      setState(() {
        markdownFilesFuture = _fetchMarkdownFiles(forceRefresh: true);
      });
    }
    await markdownFilesFuture;
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
        bottom: const AppBarDivider(),
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
                        file['name']!.replaceAll('.md', ''),
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
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
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
