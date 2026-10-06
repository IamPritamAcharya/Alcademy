import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryDetailPage extends StatelessWidget {
  final String name;
  final String body;

  const StoryDetailPage({super.key, required this.name, required this.body});

  @override
  Widget build(BuildContext context) {
    const colorShades = [
      AppStyle.blue,
      AppStyle.text,
      AppStyle.paper,
      AppStyle.lilac,
      AppStyle.accent,
      AppStyle.muted,
    ];

    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        centerTitle: false,
        backgroundColor: AppStyle.background,
        iconTheme: const IconThemeData(color: AppStyle.text),
        bottom: const AppBarDivider(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SharedMarkdownViewer(
          enableDefaultLinks: false,
          markdownData: body,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: AppStyle.text,
              fontSize: 16,
              fontFamily: 'ProductSans',
            ),
            pPadding: const EdgeInsets.symmetric(vertical: 8),
            h1: TextStyle(
              color: colorShades[1],
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h1Padding: const EdgeInsets.symmetric(vertical: 10),
            h2: TextStyle(
              color: colorShades[2],
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h2Padding: const EdgeInsets.symmetric(vertical: 10),
            h3: TextStyle(
              color: colorShades[3],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h3Padding: const EdgeInsets.symmetric(vertical: 0),
            h4: TextStyle(
              color: colorShades[4],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h4Padding: const EdgeInsets.symmetric(vertical: 6),
            h5: TextStyle(
              color: colorShades[5],
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h5Padding: const EdgeInsets.symmetric(vertical: 4),
            h6: TextStyle(
              color: colorShades[5].withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h6Padding: const EdgeInsets.symmetric(vertical: 4),
            listBullet: TextStyle(color: colorShades[0], fontSize: 16),
            listBulletPadding: const EdgeInsets.only(
              left: 12,
              top: 4,
              bottom: 4,
            ),
            a: TextStyle(
              color: colorShades[0],
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            em: TextStyle(
              color: colorShades[0].withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
            ),
            strong: const TextStyle(
              color: AppStyle.text,
              fontWeight: FontWeight.bold,
            ),
            blockquotePadding: const EdgeInsets.all(12),
            blockquoteDecoration: BoxDecoration(
              color: AppStyle.surface,
              border: Border(left: BorderSide(color: colorShades[3], width: 4)),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorShades[4], width: 1),
            ),
            horizontalRuleDecoration: BoxDecoration(color: colorShades[5]),
            tableHead: TextStyle(
              color: colorShades[1],
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'ProductSans',
            ),
            tableBody: const TextStyle(
              color: AppStyle.text,
              fontSize: 14,
              fontFamily: 'ProductSans',
            ),
            tablePadding: const EdgeInsets.symmetric(vertical: 6),
            tableBorder: TableBorder.all(
              color: AppStyle.rule.withValues(alpha: .65),
              width: 1,
            ),
            tableCellsPadding: const EdgeInsets.all(8),
            tableCellsDecoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
          onTapLink: (text, url, title) {
            if (url != null) {
              launchUrl(Uri.parse(url));
            } else {
              debugPrint('Invalid URL: $url');
            }
          },
        ),
      ),
    );
  }
}
