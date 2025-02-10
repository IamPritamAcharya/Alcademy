import 'package:flutter/material.dart';
import '2ndpage/login_form.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback onNextPressed;

  const LoginPage({required this.onNextPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false,
      backgroundColor: Colors.transparent,
      body: LoginForm(onNextPressed: onNextPressed),
    );
  }
}
