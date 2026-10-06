import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class OnboardingPage2 extends StatelessWidget {
  final VoidCallback? onNext;
  const OnboardingPage2({super.key, this.onNext});

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'A little\ninspiration.',
    spread: 2,
    kicker: 'BEYOND THE CLASSROOM',
    description:
        'Discover student stories, explore the blog and make space for what comes next.',
    buttonLabel: 'Make it yours',
    accent: AppStyle.lilac,
    onNext: onNext ?? () {},
  );
}
