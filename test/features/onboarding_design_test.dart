import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/onboarding/presentation/onboarding_page.dart';
import 'package:port/features/onboarding/presentation/onboarding_page1.dart';
import 'package:port/features/onboarding/presentation/welcome_page.dart';
import 'package:port/features/onboarding/presentation/onboarding_page2.dart';
import 'package:port/features/onboarding/presentation/profile_setup_form.dart';
import '../support/load_fonts.dart';
import 'package:port/features/onboarding/presentation/widgets/dropdown_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'cachedYearLinks': jsonEncode([
        {'name': 'First Year', 'url': 'https://example.com/first'},
        {'name': 'Second Year', 'url': 'https://example.com/second'},
      ]),
    }),
  );

  Future<void> tapVisible(WidgetTester tester, String label) async {
    final target = label.startsWith('Choose your')
        ? find.ancestor(
            of: find.text(label),
            matching: find.byType(DropdownWidget),
          )
        : find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('all steps continue and save setup', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Your home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Get Started');
    expect(find.text('02 / 04'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous step'));
    await tester.pumpAndSettle();
    expect(find.text('01 / 04'), findsOneWidget);
    await tapVisible(tester, 'Get Started');
    await tapVisible(tester, 'Keep going');
    expect(find.text('03 / 04'), findsOneWidget);
    expect(find.textContaining('Join'), findsNothing);
    await tapVisible(tester, 'Make it yours');
    await tapVisible(tester, 'Enter Alcademy');
    expect(
      find.text('Add your name, branch and notes to continue.'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isNull);
    await tester.enterText(find.byType(TextField), '  Student  ');
    await tapVisible(tester, 'Choose your branch');
    await tapVisible(tester, 'Computer Science');
    await tapVisible(tester, 'Choose your notes');
    await tapVisible(tester, 'First Year');
    await tapVisible(tester, 'Enter Alcademy');
    expect(find.text('Your home'), findsOneWidget);
    expect(prefs.getString('userName'), 'Student');
    expect(prefs.getString('userBranch'), 'Computer Science');
    expect(prefs.getString('selectedYearUrl'), 'https://example.com/first');
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup stays scrollable with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
            viewInsets: EdgeInsets.only(bottom: 280),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(body: ProfileSetupForm(onNextPressed: () {})),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Student');
    await tester.ensureVisible(find.text('Enter Alcademy'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Alcademy').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buttons remain at the bottom while every step scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final steps = <String, Widget>{
      'Get Started': WelcomePage(onNext: () {}),
      'Keep going': OnboardingPage1(onNext: () {}),
      'Make it yours': OnboardingPage2(onNext: () {}),
      'Enter Alcademy': ProfileSetupForm(onNextPressed: () {}),
    };
    for (final step in steps.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(body: step.value),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, step.key);
      final before = tester.getRect(button);
      expect(before.bottom, closeTo(616, 1));
      expect(button.hitTestable(), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(button), before);
      expect(tester.takeException(), isNull);
    }
  });

  final spreads = <String, Widget Function()>{
    'onboarding_updates': () => OnboardingPage1(onNext: () {}),
    'onboarding_community': () => OnboardingPage2(onNext: () {}),
    'onboarding_setup': () => ProfileSetupForm(onNextPressed: () {}),
  };
  for (final spread in spreads.entries) {
    testWidgets('${spread.key} design preview', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: const ValueKey('spread'),
            child: Scaffold(body: spread.value()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('spread')),
        matchesGoldenFile('../goldens/${spread.key}.png'),
      );
    });
  }
}
