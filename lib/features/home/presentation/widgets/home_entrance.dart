import 'package:flutter/material.dart';

class HomeEntrance extends StatelessWidget {
  final Widget child;
  final int order;
  const HomeEntrance({super.key, required this.child, this.order = 0});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = order.clamp(0, 6) * 60;
    final duration = 450 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      curve: Interval(delay / duration, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
