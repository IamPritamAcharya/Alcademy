import 'package:flutter/material.dart';
import 'package:port/onboarding/pages/login_form.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onNextPressed;

  const LoginPage({required this.onNextPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: LoginForm(onNextPressed: onNextPressed),
    );
  }
}
