import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/shared/theme/app_style.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';
import 'profile_setup_page.dart';
import 'welcome_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _next() => _pageController.nextPage(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 500),
    curve: Curves.easeInOutCubic,
  );

  Future<void> _onNextPressed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppStyle.background,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 26, 0),
            child: Row(
              children: [
                if (_currentPage > 0)
                  IconButton(
                    tooltip: 'Previous step',
                    onPressed: () => _pageController.previousPage(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  )
                else
                  const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Alcademy.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -.8,
                    ),
                  ),
                ),
                Text('0${_currentPage + 1} / 04', style: AppStyle.eyebrow),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
            child: Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 5),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 400),
                      height: 3,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppStyle.paper
                            : AppStyle.rule,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _currentPage = index);
              },
              children: [
                WelcomePage(onNext: _next),
                OnboardingPage1(onNext: _next),
                OnboardingPage2(onNext: _next),
                ProfileSetupPage(onNextPressed: _onNextPressed),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
