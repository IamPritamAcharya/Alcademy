import 'package:flutter/material.dart';
import 'profile_setup_form.dart';

class ProfileSetupPage extends StatelessWidget {
  final VoidCallback onNextPressed;
  const ProfileSetupPage({required this.onNextPressed, super.key});

  @override
  Widget build(BuildContext context) =>
      ProfileSetupForm(onNextPressed: onNextPressed);
}
