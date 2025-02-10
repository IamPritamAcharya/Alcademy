import 'package:flutter/material.dart';
import 'package:port/forums/post.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({Key? key, required this.post}) : super(key: key);

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
            letterSpacing: 3,
          ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero widget for image with fallback
            post.imageUrl.isNotEmpty
                ? Hero(
                    tag: post.id,
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 100,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 100,
                  ),
            const SizedBox(height: 16),
            // Title with divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: Colors.white.withOpacity(0.3), // Subtle divider
                    thickness: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description in Markdown format
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: MarkdownBody(
                data: post.description,
                styleSheet: MarkdownStyleSheet(
                  // General Text
                  p: const TextStyle(
                    color: Color(0xFFF5F5F5), // Light white for paragraphs
                    fontSize: 16,
                    fontFamily: 'ProductSans',
                  ),
                  pPadding: const EdgeInsets.symmetric(vertical: 8),
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
                  tableHead: const TextStyle(
                    color: Color(0xFFD8E6FF), // Light blue for headers
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'ProductSans',
                  ),
                  // Table Body Content Styles
                  tableBody: const TextStyle(
                    color: Colors.white, // Orange color for table body content
                    fontSize: 14,
                    fontFamily: 'ProductSans',
                  ),
                  // Table Cell Decoration
                  tableCellsDecoration: BoxDecoration(
                    color:
                        Colors.black.withOpacity(0.1), // Subtle dark background
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Color(0xFFAAAAAA), // Light grey border
                      width: 1,
                    ),
                  ),
                  blockquote: const TextStyle(
                    color: Color(0xFFFFD700), // Gold color for blockquote text
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'ProductSans',
                  ),
                  // Blockquote decoration (background, border)
                  blockquotePadding: const EdgeInsets.all(12),
                  blockquoteDecoration: BoxDecoration(
                    color:
                        Colors.black.withOpacity(1), // Subtle dark background
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xFFADD8E6), // Light blue left border
                        width: 4,
                      ),
                    ),
                  ),
                  // Bullet Points
                  listBullet: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  listBulletPadding:
                      const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                ),
                onTapLink: (text, href, title) async {
                  if (href != null) {
                    final uri = Uri.parse(href);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      // Handle the error if the URL can't be launched
                      print('Could not launch $href');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
