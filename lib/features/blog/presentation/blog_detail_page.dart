import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';

class MarkdownViewerPage extends StatelessWidget {
  final String body;

  const MarkdownViewerPage({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text(''),
        centerTitle: false,
        backgroundColor: AppStyle.surface,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SharedMarkdownViewer(markdownData: body, compact: false),
      ),
    );
  }
}
