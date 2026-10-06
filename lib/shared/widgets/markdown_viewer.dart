import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedMarkdownViewer extends StatelessWidget {
  final String markdownData;
  final bool compact;
  final MarkdownStyleSheet? styleSheet;
  final MarkdownTapLinkCallback? onTapLink;
  final bool enableDefaultLinks;
  final EdgeInsetsGeometry? padding;

  const SharedMarkdownViewer({
    super.key,
    required this.markdownData,
    this.compact = false,
    this.styleSheet,
    this.onTapLink,
    this.enableDefaultLinks = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdownData,
      styleSheet: styleSheet ?? _getMarkdownStyleSheet(),
      onTapLink:
          onTapLink ??
          (enableDefaultLinks
              ? (text, url, title) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  } else {
                    debugPrint('Invalid URL: $url');
                  }
                }
              : null),
    );
  }

  MarkdownStyleSheet _getMarkdownStyleSheet() {
    if (compact) {
      return MarkdownStyleSheet(
        p: const TextStyle(
          color: AppStyle.text,
          fontSize: 14,
          fontFamily: 'ProductSans',
        ),
        pPadding: const EdgeInsets.symmetric(vertical: 4),
        h1: const TextStyle(
          color: AppStyle.paper,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h1Padding: const EdgeInsets.symmetric(vertical: 6),
        h2: const TextStyle(
          color: AppStyle.paper,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h2Padding: const EdgeInsets.symmetric(vertical: 5),
        h3: const TextStyle(
          color: AppStyle.gold,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h3Padding: const EdgeInsets.symmetric(vertical: 4),
        h4: const TextStyle(
          color: AppStyle.accent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h4Padding: const EdgeInsets.symmetric(vertical: 3),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppStyle.text,
        ),
        em: const TextStyle(fontStyle: FontStyle.italic, color: AppStyle.muted),
        del: const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: AppStyle.muted,
        ),
        code: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 12,
          color: AppStyle.gold,
          backgroundColor: AppStyle.surface,
        ),
        listBullet: const TextStyle(color: AppStyle.text, fontSize: 14),
        listBulletPadding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
        blockquotePadding: const EdgeInsets.all(8),
        blockquoteDecoration: BoxDecoration(
          color: AppStyle.surface,
          border: const Border(
            left: BorderSide(color: AppStyle.muted, width: 3),
          ),
        ),
        horizontalRuleDecoration: const BoxDecoration(color: AppStyle.muted),
        tableHead: const TextStyle(
          color: AppStyle.paper,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'ProductSans',
        ),
        tableBody: const TextStyle(
          color: AppStyle.text,
          fontSize: 12,
          fontFamily: 'ProductSans',
        ),
        tablePadding: const EdgeInsets.symmetric(vertical: 3),
        tableBorder: TableBorder.all(
          color: AppStyle.rule.withValues(alpha: .65),
          width: 1,
        ),
        tableCellsPadding: const EdgeInsets.all(6),
        tableCellsDecoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
        ),
        a: const TextStyle(
          color: AppStyle.blue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
        codeblockPadding: const EdgeInsets.all(8),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppStyle.rule, width: 1),
        ),
        img: const TextStyle(fontSize: 14, color: AppStyle.text),
      );
    } else {
      return MarkdownStyleSheet(
        p: const TextStyle(
          color: AppStyle.text,
          fontSize: 16,
          fontFamily: 'ProductSans',
        ),
        pPadding: const EdgeInsets.symmetric(vertical: 8),
        h1: const TextStyle(
          color: AppStyle.paper,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h1Padding: const EdgeInsets.symmetric(vertical: 10),
        h2: const TextStyle(
          color: AppStyle.paper,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h2Padding: const EdgeInsets.symmetric(vertical: 10),
        h3: const TextStyle(
          color: AppStyle.gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h3Padding: const EdgeInsets.symmetric(vertical: 8),
        h4: const TextStyle(
          color: AppStyle.accent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'ProductSans',
        ),
        h4Padding: const EdgeInsets.symmetric(vertical: 6),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppStyle.text,
        ),
        em: const TextStyle(fontStyle: FontStyle.italic, color: AppStyle.muted),
        del: const TextStyle(
          decoration: TextDecoration.lineThrough,
          color: AppStyle.muted,
        ),
        code: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 14,
          color: AppStyle.gold,
          backgroundColor: AppStyle.surface,
        ),
        listBullet: const TextStyle(color: AppStyle.text, fontSize: 16),
        listBulletPadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        blockquotePadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          color: AppStyle.surface,
          border: const Border(
            left: BorderSide(color: AppStyle.muted, width: 4),
          ),
        ),
        horizontalRuleDecoration: const BoxDecoration(color: AppStyle.muted),
        tableHead: const TextStyle(
          color: AppStyle.paper,
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
        a: const TextStyle(
          color: AppStyle.blue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppStyle.rule, width: 1),
        ),
        img: const TextStyle(fontSize: 16, color: AppStyle.text),
      );
    }
  }
}
