import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/notes/models/note_branch.dart';
import 'package:port/features/notes/models/note_year.dart';
import 'package:port/features/notes/presentation/notes_selector_page.dart';
import 'package:port/features/notes/presentation/notes_shelf_picker.dart';
import 'package:port/features/onboarding/presentation/profile_setup_form.dart';
import 'package:port/features/onboarding/presentation/widgets/dropdown_widget.dart';
import '../../support/load_fonts.dart';

const years = [
  NoteYear(name: 'All First Years', url: 'https://example.com/first'),
  NoteYear(name: 'CSE Sem 3', url: 'https://example.com/cse'),
  NoteYear(name: 'ELEC Sem 3', url: 'https://example.com/elec'),
  NoteYear(name: 'MME Sem 3', url: 'https://example.com/mme'),
];

void main() {
  setUpAll(loadAppFonts);
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'userBranch': 'Computer Science',
      'cachedYearLinks': jsonEncode(
        years.map((year) => year.toJson()).toList(),
      ),
    }),
  );

  test(
    'profile labels and legacy MME names map to the correct notes branch',
    () {
      expect(NoteBranch.fromProfile('Computer Science'), NoteBranch.cse);
      expect(NoteBranch.fromProfile('Electronics & TC'), NoteBranch.etc);
      expect(NoteBranch.fromProfile('Metallurgical'), NoteBranch.mme);
      expect(NoteBranch.fromProfile('MME'), NoteBranch.mme);
      expect(
        NoteBranch.fromProfile('Metallurgy & Materials Engineering'),
        NoteBranch.mme,
      );
      expect(
        NoteBranch.filter(years, NoteBranch.cse).map((year) => year.name),
        ['All First Years', 'CSE Sem 3'],
      );
      expect(NoteBranch.filter(years, NoteBranch.mme).last.name, 'MME Sem 3');
      expect(NoteBranch.filter(years, null), years);
    },
  );

  Future<void> switchBranch(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<NoteBranch?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Change year starts on profile branch and allows other branches',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const NotesSelector()),
      );
      await tester.pumpAndSettle();
      expect(find.text('CSE Sem 3'), findsOneWidget);
      expect(find.text('All First Years'), findsOneWidget);
      expect(find.text('ELEC Sem 3'), findsNothing);
      await switchBranch(tester, 'ELEC · Electrical');
      expect(find.text('CSE Sem 3'), findsNothing);
      expect(find.text('ELEC Sem 3'), findsOneWidget);
      await tester.tap(find.text('ELEC Sem 3'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedYearUrl'), years[2].url);
      expect(prefs.getString('userBranch'), 'Computer Science');
      await switchBranch(tester, 'All branches');
      expect(find.text('CSE Sem 3'), findsOneWidget);
      expect(find.text('MME Sem 3'), findsOneWidget);
      expect(find.text('Selected shelf'), findsOneWidget);
    },
  );

  testWidgets(
    'onboarding follows branch choice and permits a different shelf',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ProfileSetupForm(onNextPressed: () => saved = true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Student');
      final branch = find.byType(DropdownWidget);
      await tester.ensureVisible(branch);
      await tester.tap(branch);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Computer Science').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose your notes'));
      await tester.tap(find.text('Choose your notes'));
      await tester.pumpAndSettle();
      expect(find.text('CSE Sem 3'), findsOneWidget);
      expect(find.text('ELEC Sem 3'), findsNothing);
      await switchBranch(tester, 'MME · Metallurgy & Materials Engineering');
      await tester.tap(find.text('MME Sem 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter Alcademy'));
      await tester.pumpAndSettle();
      expect(saved, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userBranch'), 'Computer Science');
      expect(prefs.getString('selectedYearUrl'), years[3].url);
    },
  );

  testWidgets('branch with no semester notes retains common shelf and escape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: NotesShelfPicker(
            years: years,
            preferredBranch: 'Production',
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('All First Years'), findsOneWidget);
    expect(find.textContaining('No PROD semester notes yet'), findsOneWidget);
    await switchBranch(tester, 'All branches');
    expect(find.text('CSE Sem 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
