import 'package:flutter/material.dart';

/// Shared always-dark palette and type styles for Alcademy.
abstract final class AppStyle {
  static const background = Color(0xFF181818);
  static const surface = Color(0xFF252525);
  static const cover = Color(0xFF343434);
  static const text = Color(0xFFF2F2F2);
  static const muted = Color(0xFFA8A8A8);
  static const rule = Color(0xFF3C3C3C);
  static const accent = Color(0xFFFFA987);
  static const paper = Color(0xFFDADADA);

  static const blue = Color(0xFF9CCAF1);
  static const lilac = Color(0xFFCDB4F2);
  static const gold = Color(0xFFE8CD79);
  static const highlights = [accent, gold, blue, lilac, paper];

  static const danger = Color(0xFFEF8792);
  static const success = Color(0xFFAED5BB);
  static const onAccent = background;
  static const radius = BorderRadius.all(Radius.circular(12));
  static const pageTitle = TextStyle(
    fontFamily: 'ProductSans',
    color: text,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -.5,
  );

  static const eyebrow = TextStyle(
    color: muted,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.8,
  );
}
