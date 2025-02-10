import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomePage({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Enhanced Decorative Blurred Shapes
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurredCircle(200, Colors.white.withOpacity(0.3)),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildBlurredCircle(300, Colors.white.withOpacity(0.15)),
          ),
          Positioned(
            top: 150,
            right: 50,
            child: _buildBlurredCircle(100, Colors.white.withOpacity(0.2)),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon (Optional)
                Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Color(0xFF5D4037).withOpacity(0.8), // Coffee tone
                ),
                SizedBox(height: 30),
                // Title
                Text(
                  "Welcome to Alcademy!",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037), // Rich coffee brown
                    letterSpacing: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Subtitle
                Text(
                  "Your academic journey starts here.\nSimplified. Organized. Accessible.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black.withOpacity(0.8),
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
                        Color(0xFF8D6E63),
                        Color(0xFF6D4C41)
                      ], // Coffee tones
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
                    backgroundColor: Color(0xFF6D4C41), // Dark coffee
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    shadowColor: Colors.brown.withOpacity(0.5),
                  ),
                  child: Text(
                    "Get Started",
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

  // Creates a refined soft blurred shape
  Widget _buildBlurredCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80, // Softer, more diffused blur
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
