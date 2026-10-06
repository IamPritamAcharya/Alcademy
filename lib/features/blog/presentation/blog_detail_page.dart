import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:flutter/material.dart';
import 'package:port/features/blog/data/blog_repository.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';

class MarkdownViewerPage extends StatefulWidget {
  final String url;

  const MarkdownViewerPage({super.key, required this.url});

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
    _contentFuture = BlogRepository.instance.getMarkdown(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text(
          '',
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
        backgroundColor: AppStyle.surface,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: AppStyle.background,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppStyle.text),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Container(
              color: AppStyle.background,
              child: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppStyle.text),
                ),
              ),
            );
          } else {
            return Container(
              color: AppStyle.background,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
