import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingPage1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'In the loop.\nAhead of the day.',
    spread: 1,
    kicker: 'THE DETAILS THAT MATTER',
    description:
        'Catch the latest notices, check your syllabus and find your way around campus. All from one place.',
    buttonLabel: 'Keep going',
    accent: AppStyle.blue,
    onNext: onNext,
  );
}
