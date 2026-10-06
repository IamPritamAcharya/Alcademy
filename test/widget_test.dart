import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/onboarding/presentation/welcome_page.dart';
import 'package:port/features/profile/data/profile_repository.dart';
import 'package:port/features/profile/presentation/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Welcome page continues when Get Started is tapped',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var continued = false;
    await tester.pumpWidget(MaterialApp(
      home: WelcomePage(onNext: () => continued = true),
    ));

    expect(find.text('Welcome to Alcademy!'), findsOneWidget);
    expect(continued, isFalse);
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    expect(continued, isTrue);
  });

  testWidgets('Local profile loads and saves a name without backend setup',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'userName': 'Student',
      'userBranch': 'Computer Science',
    });
    await tester.pumpWidget(const MaterialApp(home: UserProfilePage()));
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('API Key'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_note_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New Name');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('New Name'), findsOneWidget);
    expect(await ProfileRepository.getUserName(), 'New Name');
    expect(await ProfileRepository.getUserBranch(), 'Computer Science');
  });
}
