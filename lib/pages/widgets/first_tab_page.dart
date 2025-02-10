import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/config.dart';

class FirstTabPage extends StatelessWidget {
  const FirstTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E), // Dark background
      appBar: AppBar(
        title: Text(
          name_1st_tab,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16), // Top padding
              MarkdownBody(
                data: markdownContent_1st_tab,
                styleSheet: MarkdownStyleSheet(
                  // General Paragraph Text
                  p: const TextStyle(
                    color: Color(0xFFFAFAFA), // Soft white for readability
                    fontSize: 16,
                    height: 1.5,
                  ),
                  // Headings
                  h1: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE57373), // Light red
                  ),
                  h2: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64B5F6), // Light blue
                  ),
                  h3: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF81C784), // Light green
                  ),
                  h4: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD54F), // Light yellow
                  ),
                  h5: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4FC3F7), // Light cyan
                  ),
                  h6: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9575CD), // Light purple
                  ),
                  // Blockquote
                  blockquote: const TextStyle(
                    color: Color(0xFFFFCC80), // Light orange for blockquotes
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                  blockquotePadding: const EdgeInsets.all(16),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(
                        0xFF2E2E2E), // Slightly lighter dark background
                    border: Border(
                      left: BorderSide(
                        color: Color(0xFFFFCC80), // Matching blockquote border
                        width: 4,
                      ),
                    ),
                  ),
                  // Links
                  a: const TextStyle(
                    color: Color(0xFF64B5F6), // Light blue
                    decoration: TextDecoration.underline,
                  ),
                  // Bullet Points
                  listBullet: const TextStyle(
                    color: Color(0xFF4FC3F7), // Cyan bullets
                    fontSize: 16,
                  ),
                  // Code Block
                  codeblockPadding: const EdgeInsets.all(16),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF263238), // Dark gray for code blocks
                    borderRadius: BorderRadius.circular(4),
                  ),
                  code: const TextStyle(
                    color: Color(0xFFFFF176), // Bright yellow for inline code
                    fontFamily: 'Courier',
                    fontSize: 14,
                  ),
                  // Table Header
                  tableHead: const TextStyle(
                    color: Color(0xFF64B5F6), // Light blue headers
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  // Table Body
                  tableBody: const TextStyle(
                    color: Color(0xFFFAFAFA), // Light text for table body
                    fontSize: 14,
                  ),
                  tableCellsDecoration: BoxDecoration(
                    color: const Color(0xFF2C2F33), // Dark table cells
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF757575), // Subtle border color
                    ),
                  ),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href));
                  }
                },
              ),
              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
