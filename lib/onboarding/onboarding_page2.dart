import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingPage2 extends StatelessWidget {
  final Color accentGreen = const Color(0xFF4CAF50); // Main accent green
  final Color mutedGreen = const Color(0xFF81C784); // Muted green
  final Color textColor = const Color(0xFF2E7D32); // Darker green for text

  Future<void> _openUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Decorative Triangles
          Positioned(
            top: -30,
            left: -100,
            child: _buildBlurredTriangle(
              size: 250,
              color: mutedGreen.withOpacity(0.3),
              angle: 5,
            ),
          ),
          Positioned(
            top: -40,
            right: -50,
            child: _buildBlurredTriangle(
              size: 180,
              color: accentGreen.withOpacity(0.2),
              angle: -10,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -60,
            child: _buildBlurredTriangle(
              size: 200,
              color: mutedGreen.withOpacity(0.2),
              angle: 50,
            ),
          ),
          Positioned(
            bottom: 0,
            right: -30,
            child: _buildBlurredTriangle(
              size: 170,
              color: accentGreen.withOpacity(0.3),
              angle: -40,
            ),
          ),
          // Page Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Center Icon
                Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: accentGreen,
                ),
                const SizedBox(height: 30),
                // Title
                Text(
                  "Join Our Community",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.3,
                    letterSpacing: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  "Stay connected to receive the latest updates, important announcements, and exclusive feature releases for the app.",
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withOpacity(0.8),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Decorative Divider
                Container(
                  height: 5,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        mutedGreen,
                        accentGreen,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                // Join Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.link, color: Colors.white),
                  label: const Text(
                    "Join the Group",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    _openUrl(
                        "https://chat.whatsapp.com/DDuQv0UAkKpBmXB29fBjLw");
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    shadowColor: accentGreen.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for blurred triangles with rotation
  Widget _buildBlurredTriangle({
    required double size,
    required Color color,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle * pi / 180, // Convert degrees to radians
      child: SizedBox(
        height: size,
        width: size,
        child: CustomPaint(
          painter: TrianglePainter(color: color),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top vertex
    path.lineTo(0, size.height); // Bottom left vertex
    path.lineTo(size.width, size.height); // Bottom right vertex
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
