import 'package:flutter/material.dart';
import 'package:port/features/onboarding/presentation/profile_setup_form.dart';

class ProfileSetupPage extends StatelessWidget {
  final VoidCallback onNextPressed;

  const ProfileSetupPage({required this.onNextPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: ProfileSetupForm(onNextPressed: onNextPressed),
    );
  }
}
