import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const WelcomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'Welcome to Alcademy!',
    description:
        'Your academic journey starts here.\nSimplified. Organized. Accessible.',
    buttonLabel: 'Get Started',
    icon: Icons.auto_stories_outlined,
    accent: AppStyle.accent,
    onNext: onNext,
  );
}
