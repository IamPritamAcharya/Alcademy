import 'package:port/shared/widgets/editorial_list_row.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/theme/app_style.dart';
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

  Future<List<Map<String, String>>> _fetchMarkdownFiles({
    bool forceRefresh = false,
  }) => _repository.fetchBlogs(forceRefresh: forceRefresh);

  Future<void> _handleRefresh() async {
    bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
    if (!isRefreshAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar.build(isCooldown: true, context: context));
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
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text(
          'Blogs',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: -.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppStyle.background,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppStyle.text,
        backgroundColor: AppStyle.background,
        child: FutureBuilder<List<Map<String, String>>>(
          future: markdownFilesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppStyle.text),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppStyle.text),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No articles found.',
                  style: TextStyle(color: AppStyle.text),
                ),
              );
            }

            final files = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: files.length + 1,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CollectionIntro(
                    title: 'Worth a read.',
                    eyebrow: 'THE READING ROOM',
                    detail: '${files.length} articles from the campus journal',
                  );
                }
                final file = files[index - 1];
                return EditorialListRow(
                  number: index,
                  title: file['title']!,
                  category: 'Article',
                  accent: AppStyle.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkdownViewerPage(body: file['body']!),
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
