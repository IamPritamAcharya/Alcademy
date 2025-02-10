import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:port/pages/blog/blogcache.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewerPage extends StatelessWidget {
  final String url;

  const MarkdownViewerPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
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
        backgroundColor: const Color(0xFF1F1F1F), // Slightly lighter dark tone
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2), // Subtle separator
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: BlogCacheManager.fetchContent(url), // Use the cache manager
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
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: MarkdownBody(
                data: snapshot.data ?? '',
                styleSheet: MarkdownStyleSheet(
                  // General Text
                  p: const TextStyle(
                    color: Color(0xFFF5F5F5), // Light white for paragraphs
                    fontSize: 16,
                    fontFamily: 'ProductSans',
                  ),
                  pPadding: const EdgeInsets.symmetric(vertical: 8),

                  // Headings
                  h1: const TextStyle(
                    color: Color(0xFFD8E6FF), // Light blue
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                  ),
                  h1Padding: const EdgeInsets.symmetric(vertical: 10),
                  h2: const TextStyle(
                    color: Color(0xFFDBFFE1), // Light green
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                  ),
                  h2Padding: const EdgeInsets.symmetric(vertical: 10),
                  h3: const TextStyle(
                    color: Color(0xFFFFEED8), // Light orange
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                  ),
                  h3Padding: const EdgeInsets.symmetric(vertical: 8),
                  h4: const TextStyle(
                    color: Color(0xFFFFDADA), // Light red
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ProductSans',
                  ),
                  h4Padding: const EdgeInsets.symmetric(vertical: 6),

                  // Bold Text
                  strong: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6E6E6), // Slightly brighter white
                  ),

                  // Italic Text
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC5C5C5), // Greyish white
                  ),

                  // Strikethrough Text
                  del: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Color(0xFFAAAAAA), // Grey
                  ),

                  // Inline Code
                  code: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Color(0xFFFFC107), // Yellowish code color
                    backgroundColor: Color(0xFF333333), // Dark background
                  ),

                  // Bullet Points
                  listBullet: const TextStyle(
                    color: Colors.white, // Fully white bullets
                    fontSize: 16,
                  ),
                  listBulletPadding:
                      const EdgeInsets.only(left: 12, top: 4, bottom: 4),

                  // Blockquote
                  blockquotePadding: const EdgeInsets.all(12),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFFAAAAAA), // Grey border
                        width: 4,
                      ),
                    ),
                  ),

                  // Horizontal Rule
                  horizontalRuleDecoration: const BoxDecoration(
                    color: Color(0xFFAAAAAA), // Medium grey
                  ),

                  // Tables
                  tableHead: const TextStyle(
                    color: Color(0xFFD8E6FF), // Light blue for headers
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'ProductSans',
                  ),
                  tableBody: const TextStyle(
                    color: Color(0xFFF5F5F5), // Light white for content
                    fontSize: 14,
                    fontFamily: 'ProductSans',
                  ),
                  tablePadding: const EdgeInsets.symmetric(vertical: 6),
                  tableBorder: TableBorder.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  tableCellsPadding: const EdgeInsets.all(8),
                  tableCellsDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1), // Subtle dark tone
                  ),

                  // Links
                  a: const TextStyle(
                    color: Color(0xFFADD8E6), // Light blue
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),

                  // Code Block
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFCCCCCC), // Light grey
                      width: 1,
                    ),
                  ),

                  // Images
                  img: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                onTapLink: (text, url, title) {
                  if (url != null) {
                    launchUrl(Uri.parse(url));
                  } else {
                    print('Invalid URL: $url');
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }
}
