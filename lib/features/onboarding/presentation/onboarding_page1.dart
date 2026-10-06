import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class OnboardingPage1 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingPage1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'Stay Informed, Always',
    description:
        'Get all your college updates, events, and notices in one place.',
    buttonLabel: 'Next',
    icon: Icons.notifications_active_outlined,
    accent: AppStyle.blue,
    onNext: onNext,
  );
}
