import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';


class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final BoxDecoration? decoration;
  final double blur;
  final Color borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.decoration,
    this.blur = 8.0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: decoration?.copyWith(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ) ??
              BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: borderColor.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
          child: child,
        ),
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double borderRadius;
  final double blur;
  final Color borderColor;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 20.0,
    this.blur = 8.0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: child,
          ),
        ),
      ),
    );
  }
}
