import 'package:port/app/theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'support/load_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/features/onboarding/presentation/onboarding_page.dart';
import 'package:port/features/profile/presentation/profile_page.dart';
import 'package:port/features/notes/presentation/notes_selector_page.dart';
import 'package:port/features/expenses/presentation/expense_tracker_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  final screens = <String, Widget Function()>{
    'onboarding': () => const OnboardingScreen(),
    'profile': () => const UserProfilePage(),
    'notes': () => const NotesSelector(),
    'expenses': () => const ExpenseTrackerPage(),
  };
  for (final screen in screens.entries) {
    testWidgets('${screen.key} matches its approved screen', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'userName': 'Student',
        'userBranch': 'Computer Science',
        'cachedYearLinks': jsonEncode([
          {'name': 'First Year', 'url': 'https://example.com/year1'},
          {'name': 'Second Year', 'url': 'https://example.com/year2'},
        ]),
        'selectedYearUrl': 'https://example.com/year1',
        'expenses': '[]',
        'budget': 1000.0,
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: const ValueKey('screen'),
            child: screen.value(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('screen')),
        matchesGoldenFile('goldens/${screen.key}.png'),
      );
    });
  }
}
