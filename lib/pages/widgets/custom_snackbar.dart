import 'dart:ui';
import 'package:flutter/material.dart';

class CustomSnackBar {
  static SnackBar build({
    String message =
        'You have used too many refreshes.\n• Your refresh will work again in 1 hour.\n• This limitation is due to the app being free of cost.\n• I apologize for the inconvenience.',
    bool isCooldown = false,
    BuildContext? context,
  }) {
    // Split the message by lines and create separate Text widgets
    List<String> messageLines = message.split('\n');

    return SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0), // Blur effect
            child: Container(
              decoration: BoxDecoration(
                color: isCooldown
                    ? Colors.redAccent.withOpacity(0.8)
                    : Colors.black.withOpacity(0.6), // Frosted glass effect
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: messageLines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
    );
  }
}
