import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/onboarding/loginpage.dart';
import 'welcome_page.dart';
import 'onboarding_page1.dart';
import 'onboarding_page2.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
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
    // Save the onboarding completion status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // Navigate to the home page
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Animation
          AnimatedContainer(
            duration: Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getBackgroundColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Onboarding Pages
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              WelcomePage(
                  onNext: () => _pageController.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      )),
              OnboardingPage1(
                onNext: () => _pageController.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
              OnboardingPage2(),
              LoginPage(onNextPressed: _onNextPressed),
            ],
          ),

          // Dots Indicator
          if (_currentPage < 3) // Hide dots on the login page
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
                      color:
                          _currentPage == index ? Colors.white : Colors.white70,
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

  List<Color> _getBackgroundColors() {
    switch (_currentPage) {
      case 0:
        return [
          Color(0xFFFFE0B2),
          Color(0xFFFFCCBC),
        ];
      case 1:
        return [
          Color.fromARGB(255, 201, 245, 252),
          Color.fromARGB(255, 188, 228, 255),
        ];
      case 2:
        return [
          Color.fromARGB(255, 216, 255, 215),
          Color.fromARGB(255, 197, 255, 201),
        ];
      case 3:
      default:
        return [Color(0xFFF1F8E9), Color(0xFFF1F8E9)];
    }
  }
}
