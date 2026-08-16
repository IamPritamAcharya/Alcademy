import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingPage2 extends StatelessWidget {
  final Color accentPurple = const Color(0xFF5865F2);
  final Color mutedPurple = const Color(0xFF6C79EE);
  final Color textColor = const Color(0xFF1E2677);
  final Color discordPurple = const Color(0xFF5865F2);

  const OnboardingPage2({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
          Positioned(
            top: -30,
            left: -100,
            child: _buildBlurredTriangle(
              size: 250,
              color: mutedPurple.withValues(alpha: 0.3),
              angle: 5,
            ),
          ),
          Positioned(
            top: -40,
            right: -50,
            child: _buildBlurredTriangle(
              size: 180,
              color: accentPurple.withValues(alpha: 0.2),
              angle: -10,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -60,
            child: _buildBlurredTriangle(
              size: 200,
              color: mutedPurple.withValues(alpha: 0.2),
              angle: 50,
            ),
          ),
          Positioned(
            bottom: 0,
            right: -30,
            child: _buildBlurredTriangle(
              size: 170,
              color: accentPurple.withValues(alpha: 0.3),
              angle: -40,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: accentPurple,
                ),
                const SizedBox(height: 30),
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
                Text(
                  "Stay connected to receive the latest updates, important announcements, and exclusive feature releases for the app.",
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  height: 5,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        mutedPurple,
                        accentPurple,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
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
                    _openUrl("https://discord.gg/d7AZzFwzwX");
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: discordPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    shadowColor: accentPurple.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredTriangle({
    required double size,
    required Color color,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle * pi / 180,
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
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
