import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';

class AnimatedBackground extends StatelessWidget {
  final int currentPage;
  final Widget child;
  const AnimatedBackground({
    super.key,
    required this.currentPage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.alphaBlend(
              [
                AppStyle.accent,
                AppStyle.blue,
                AppStyle.lilac,
                AppStyle.paper,
              ][currentPage].withValues(alpha: .08),
              AppStyle.background,
            ),
            AppStyle.background,
          ],
        ),
      ),
      child: child,
    ),
  );
}
