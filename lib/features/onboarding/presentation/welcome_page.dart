import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'Your campus.\nWithin reach.',
    description:
        'Notes, campus updates and everyday essentials. A little less searching. A lot more living.',
    buttonLabel: 'Get Started',
    accent: AppStyle.accent,
    onNext: onNext,
  );
}
