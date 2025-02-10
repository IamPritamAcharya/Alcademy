import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class StoryDetailPage extends StatelessWidget {
  final String name;
  final String body;

  const StoryDetailPage({
    required this.name,
    required this.body,
  });

  Color getRandomVibrantColor() {
    final hue = Random().nextInt(360); // Full color spectrum (0-360 degrees)
    final saturation = 0.8 +
        Random().nextDouble() *
            0.2; // Saturation between 0.8 and 1.0 (very vibrant)
    final lightness = 0.45 +
        Random().nextDouble() *
            0.15; // Lightness between 0.45 and 0.60 (balanced brightness)

    return HSLColor.fromAHSL(1, hue.toDouble(), saturation, lightness)
        .toColor();
  }

  List<Color> generateColorShades(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      hslColor.withLightness(0.85).toColor(), // Lightest
      hslColor.withLightness(0.75).toColor(), // Light
      hslColor.withLightness(0.65).toColor(), // Medium Light
      hslColor.withLightness(0.55).toColor(), // Base
      hslColor.withLightness(0.45).toColor(), // Medium Dark
      hslColor.withLightness(0.35).toColor(), // Dark
    ];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = getRandomVibrantColor(); // Get a random vibrant color
    final colorShades = generateColorShades(baseColor); // Generate shades

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        title: Text(
          name,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1D1E),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: MarkdownBody(
          data: body,
          styleSheet: MarkdownStyleSheet(
            // Paragraph
            p: const TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 16,
              fontFamily: 'ProductSans',
            ),
            pPadding: const EdgeInsets.symmetric(vertical: 8),

            // Headings
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
              color: colorShades[5].withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
            ),
            h6Padding: const EdgeInsets.symmetric(vertical: 4),

            // Lists
            listBullet: TextStyle(
              color: colorShades[0],
              fontSize: 16,
            ),
            listBulletPadding:
                const EdgeInsets.only(left: 12, top: 4, bottom: 4),

            // Links
            a: TextStyle(
              color: colorShades[0],
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),

            // Emphasis
            em: TextStyle(
              color: colorShades[0].withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            strong: const TextStyle(
              color: Color(0xFFF5F5F5),
              fontWeight: FontWeight.bold,
            ),

            // Blockquote
            blockquotePadding: const EdgeInsets.all(12),
            blockquoteDecoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                left: BorderSide(
                  color: colorShades[3],
                  width: 4,
                ),
              ),
            ),

            // Code block
            codeblockPadding: const EdgeInsets.all(12),
            codeblockDecoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorShades[4],
                width: 1,
              ),
            ),

            // Horizontal Rule
            horizontalRuleDecoration: BoxDecoration(
              color: colorShades[5],
            ),

            // Tables
            tableHead: TextStyle(
              color: colorShades[1],
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'ProductSans',
            ),
            tableBody: const TextStyle(
              color: Color(0xFFF5F5F5),
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
              color: Colors.black.withOpacity(0.1),
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
      ),
    );
  }
}
