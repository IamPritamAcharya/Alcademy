import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/utils/config.dart';

class FirstTabPage extends StatelessWidget {
  const FirstTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E), 
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
              const SizedBox(height: 16), 
              MarkdownBody(
                data: markdownContent_1st_tab,
                styleSheet: MarkdownStyleSheet(
                  
                  p: const TextStyle(
                    color: Color(0xFFFAFAFA), 
                    fontSize: 16,
                    height: 1.5,
                  ),
                  
                  h1: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE57373), 
                  ),
                  h2: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64B5F6), 
                  ),
                  h3: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF81C784), 
                  ),
                  h4: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD54F), 
                  ),
                  h5: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4FC3F7), 
                  ),
                  h6: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9575CD), 
                  ),
                  
                  blockquote: const TextStyle(
                    color: Color(0xFFFFCC80), 
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                  blockquotePadding: const EdgeInsets.all(16),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(
                        0xFF2E2E2E), 
                    border: Border(
                      left: BorderSide(
                        color: Color(0xFFFFCC80), 
                        width: 4,
                      ),
                    ),
                  ),
                  
                  a: const TextStyle(
                    color: Color(0xFF64B5F6), 
                    decoration: TextDecoration.underline,
                  ),
                  
                  listBullet: const TextStyle(
                    color: Color(0xFF4FC3F7), 
                    fontSize: 16,
                  ),
                  
                  codeblockPadding: const EdgeInsets.all(16),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF263238), 
                    borderRadius: BorderRadius.circular(4),
                  ),
                  code: const TextStyle(
                    color: Color(0xFFFFF176), 
                    fontFamily: 'Courier',
                    fontSize: 14,
                  ),
                  
                  tableHead: const TextStyle(
                    color: Color(0xFF64B5F6), 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  
                  tableBody: const TextStyle(
                    color: Color(0xFFFAFAFA), 
                    fontSize: 14,
                  ),
                  tableCellsDecoration: BoxDecoration(
                    color: const Color(0xFF2C2F33), 
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF757575), 
                    ),
                  ),
                ),
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href));
                  }
                },
              ),
              const SizedBox(height: 24), 
            ],
          ),
        ),
      ),
    );
  }
}
