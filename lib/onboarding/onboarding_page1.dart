import 'package:flutter/material.dart';
import 'dart:math';

// Define color variables
const Color backgroundStart = Color(0xFFE8F5E9); // Mint Pastel Green
const Color backgroundEnd = Color(0xFFFCE4EC); // Blush Pink

const Color textPrimary = Color.fromARGB(255, 0, 100, 143); // Slate Black
const Color textSecondary = Color.fromARGB(255, 0, 100, 143); // Charcoal Gray
const Color buttonColor = Colors.cyan; // Lavender Accent
const Color shapeColor =
    Color.fromARGB(151, 75, 177, 221); // Soft Purple Pastel

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingPage1({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Decorative Shapes
          Positioned(
            top: -80,
            left: -50,
            child: _buildDecorativeShape(
              size: 250,
              color: Colors.blue.withOpacity(0.15),
              sides: 7,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: _buildDecorativeShape(
              size: 300,
              color: Colors.blue.withOpacity(0.12),
              sides: 5,
            ),
          ),
          Positioned(
            top: 200,
            right: 30,
            child: _buildDecorativeShape(
              size: 150,
              color: Colors.blue.withOpacity(0.2),
              sides: 6,
            ),
          ),
          // Page Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Center Icon with Neat Background
                Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: Colors.black87, // Placeholder text color
                ),
                SizedBox(height: 30),
                // Title
                Text(
                  "Stay Informed, Always",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Placeholder text color
                    height: 1.3,
                    letterSpacing: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Subtitle
                Text(
                  "Get all your college updates, events, and notices in one place.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54, // Placeholder secondary text color
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                // Decorative Divider
                Container(
                  height: 5,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade700,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                SizedBox(height: 50),
                // Call-to-Action Button
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    backgroundColor: Colors.blue, // Placeholder button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleHalo(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // Decorative Polygon
  Widget _buildDecorativeShape({
    required double size,
    required Color color,
    required int sides,
  }) {
    return Container(
      height: size,
      width: size,
      child: CustomPaint(
        painter: PolygonPainter(color: color, sides: sides),
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final Color color;
  final int sides;

  PolygonPainter({required this.color, required this.sides});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double radius = size.width / 2;
    final double angleStep = (2 * pi) / sides;

    for (int i = 0; i < sides; i++) {
      final double x = radius + radius * cos(angleStep * i);
      final double y = radius + radius * sin(angleStep * i);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
