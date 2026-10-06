import 'package:flutter/material.dart';

/// An always-dark journal palette, local to the Home design.
abstract final class HomeStyle {
  static const background = Color(0xFF151B18);
  static const surface = Color(0xFF222D26);
  static const forest = Color(0xFF284638);
  static const text = Color(0xFFEDEDE2);
  static const muted = Color(0xFFA5B1A7);
  static const rule = Color(0xFF35433A);
  static const accent = Color(0xFFE99577);
  static const sage = Color(0xFFC4D5BC);
  static const warmSurface = Color(0xFF342B25);

  static const eyebrow = TextStyle(
    color: muted,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.8,
  );
}
