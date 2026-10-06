import 'package:port/shared/theme/app_style.dart';
import 'widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:port/features/onboarding/presentation/onboarding_page1.dart';
import 'package:port/features/onboarding/presentation/onboarding_page2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/features/onboarding/presentation/profile_setup_page.dart';
import 'package:port/features/onboarding/presentation/welcome_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _onNextPressed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      currentPage: _currentPage,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              WelcomePage(
                onNext: () => _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
              OnboardingPage1(
                onNext: () => _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
              OnboardingPage2(),
              ProfileSetupPage(onNextPressed: _onNextPressed),
            ],
          ),
          if (_currentPage < 3)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    height: 12,
                    width: _currentPage == index ? 24 : 12,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppStyle.accent
                          : AppStyle.rule,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
