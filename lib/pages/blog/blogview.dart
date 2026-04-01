import 'package:flutter/material.dart';
import 'package:port/pages/blog/blogcache.dart';
import 'package:port/utils/markdown_provider.dart';

class MarkdownViewerPage extends StatefulWidget {
  final String url;

  const MarkdownViewerPage({required this.url});

  @override
  State<MarkdownViewerPage> createState() => _MarkdownViewerPageState();
}

class _MarkdownViewerPageState extends State<MarkdownViewerPage>
    with AutomaticKeepAliveClientMixin {
  late Future<String> _contentFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _contentFuture = BlogCacheManager.fetchContent(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 3),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1F1F),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Container(
              color: const Color(0xFF121212),
              child: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          } else {
            return Container(
              color: const Color(0xFF121212),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SharedMarkdownViewer(
                  markdownData: snapshot.data ?? '',
                  compact: false,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
