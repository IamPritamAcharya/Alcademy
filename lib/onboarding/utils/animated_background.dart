import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  final int currentPage;
  final Widget child;

  const AnimatedBackground({
    Key? key,
    required this.currentPage,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
         
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getBackgroundColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        
          child,
        ],
      ),
    );
  }

  List<Color> _getBackgroundColors() {
    switch (currentPage) {
      case 0:
        return [
          const Color(0xFFFFE0B2),
          const Color(0xFFFFCCBC),
        ];
      case 1:
        return [
          const Color.fromARGB(255, 201, 245, 252),
          const Color.fromARGB(255, 188, 228, 255),
        ];
      case 2:
        return [
          const Color.fromARGB(255, 216, 255, 215),
          const Color.fromARGB(255, 197, 255, 201),
        ];
      case 3:
      default:
        return [
          const Color(0xFFF1F8E9),
          const Color(0xFFF1F8E9),
        ];
    }
  }
}