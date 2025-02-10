import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie animation
          Lottie.network(
            'https://lottie.host/e216131d-bb31-48ad-976f-b1c53db8e760/msefpf7MTG.json', // Known working file
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 50), // Add some spacing
          // Optional text below the animation
        ],
      ),
    );
  }
}
