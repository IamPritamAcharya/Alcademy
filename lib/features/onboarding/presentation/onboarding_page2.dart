import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:port/shared/theme/app_style.dart';
import 'widgets/onboarding_intro.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => OnboardingIntro(
    title: 'Stay Connected',
    description:
        'Join our student community for updates, discussions, and support.',
    buttonLabel: 'Join the Group',
    icon: Icons.people_outline_rounded,
    accent: AppStyle.lilac,
    onNext: () => _openUrl('https://chat.whatsapp.com/DDuQv0UAkKpBmXB29fBjLw'),
  );
}
