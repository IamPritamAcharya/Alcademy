import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/college_resources/presentation/syllabus_page.dart';
import 'package:port/features/sgpa/data/data.dart';
import 'package:port/features/sgpa/presentation/branch_selector.dart';
import 'package:port/features/sgpa/presentation/subject_grade_input.dart';
import 'package:port/shared/widgets/study_selection_field.dart';
import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> showPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RepaintBoundary(key: const ValueKey('study-page'), child: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label, String option) async {
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is StudySelectionField && widget.label == label,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'syllabus branch search and pin controls persist without opening the PDF',
    (tester) async {
      await showPage(tester, const SyllabusPage());
      await tester.tap(find.byType(StudySelectionField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'computer');
      await tester.pumpAndSettle();
      expect(find.text('Mechanical Eng'), findsNothing);
      await tester.tap(find.text('Computer Science'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pin First Year'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('pinnedSyllabi'), hasLength(1));
      expect(find.text('PINNED / 1'), findsOneWidget);
      expect(find.byType(SyllabusViewer), findsNothing);
      await tester.tap(find.byTooltip('Unpin First Year').first);
      await tester.pumpAndSettle();
      expect(prefs.getStringList('pinnedSyllabi'), isEmpty);
      expect(find.text('PINNED / 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('study-page')),
        matchesGoldenFile('../goldens/syllabus.png'),
      );
    },
  );

  testWidgets('changing SGPA branch resets semester and disables continuing', (
    tester,
  ) async {
    await showPage(tester, const BranchSelector());
    await choose(tester, 'Branch', 'Computer Science Engineering');
    await choose(tester, 'Semester', 'Semester 1');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await choose(tester, 'Branch', 'Mechanical Engineering');
    expect(find.text('Semester 1'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SGPA grade flow keeps credit weighting and requires every grade', (
    tester,
  ) async {
    await showPage(tester, const BranchSelector());
    await choose(tester, 'Branch', 'Computer Science Engineering');
    await choose(tester, 'Semester', 'Semester 1');
    await expectLater(
      find.byKey(const ValueKey('study-page')),
      matchesGoldenFile('../goldens/sgpa_setup.png'),
    );
    await tester.tap(find.text('Choose grades'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectGradeInput), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    final subjects =
        subjectCreditMap['Computer Science Engineering']!['Semester 1']!;
    for (var i = 0; i < subjects.length; i++) {
      final grade = i == 0 ? 'M' : 'O';
      final target = find.byKey(
        ValueKey('grade-${subjects[i]['subject']}-$grade'),
      );
      await tester.scrollUntilVisible(
        target.hitTestable(),
        150,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(find.text('10 of 10 graded'), findsOneWidget);
    await tester.tap(find.text('Calculate SGPA'));
    await tester.pumpAndSettle();
    // Mathematics-I has 3 of the semester's 20 credits: M + nine O grades = 8.50.
    expect(find.text('8.50'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('8.50'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SGPA grade sheet matches its design', (tester) async {
    await showPage(
      tester,
      const SubjectGradeInput(
        branch: 'Computer Science Engineering',
        semester: 'Semester 1',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('grade-Mathematics-I-O')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('study-page')),
      matchesGoldenFile('../goldens/sgpa_grades.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'branch search and selected syllabus fit enlarged text with a keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const SyllabusPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(StudySelectionField));
      await tester.tap(find.byType(StudySelectionField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.enterText(find.byType(TextField), 'civil');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Civil Eng'));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Pin First Year').hitTestable(),
        120,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byTooltip('Pin First Year'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
