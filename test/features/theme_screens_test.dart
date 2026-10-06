import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/expenses/presentation/expense_tracker_page.dart';
import 'package:port/features/home/presentation/widgets/app_drawer.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:port/features/notes/presentation/notes_selector_page.dart';
import 'package:port/features/notes/presentation/subject_details_page.dart';
import 'package:port/features/notifications/models/notification_model.dart';
import 'package:port/features/notifications/presentation/notification_detail_page.dart';
import 'package:port/features/onboarding/presentation/welcome_page.dart';
import 'package:port/features/onboarding/presentation/onboarding_page1.dart';
import 'package:port/features/onboarding/presentation/onboarding_page2.dart';
import 'package:port/features/profile/presentation/profile_page.dart';
import 'package:port/features/sgpa/presentation/branch_selector.dart';
import 'package:port/features/sgpa/presentation/subject_grade_input.dart';
import 'package:port/features/college_resources/presentation/syllabus_page.dart';
import 'package:port/features/success_stories/presentation/story_details_page.dart';
import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'userName': 'Student',
      'userBranch': 'Computer Science',
      'cachedYearLinks': jsonEncode([
        {'name': 'First Year', 'url': 'https://example.com/first'},
        {'name': 'Second Year', 'url': 'https://example.com/second'},
      ]),
      'selectedYearUrl': 'https://example.com/first',
      'expenses': '[]',
      'budget': 1000.0,
    }),
  );
  final pages = <String, Widget Function()>{
    'welcome': () => WelcomePage(onNext: () {}),
    'onboarding updates': () => OnboardingPage1(onNext: () {}),
    'onboarding community': () => const OnboardingPage2(),
    'profile': () => const UserProfilePage(),
    'year selection': () => const NotesSelector(),
    'expenses': () => const ExpenseTrackerPage(),
    'SGPA selection': () => const BranchSelector(),
    'SGPA grades': () => const SubjectGradeInput(
      branch: 'Computer Science Engineering',
      semester: 'Semester 1',
    ),
    'syllabus': () => const SyllabusPage(),
    'resources': () => SubjectDetailsPage(
      subject: Subject(
        name: 'Introduction to Electrical and Electronics Engineering',
        items: [
          SubjectItem(
            name:
                'A complete collection of revision notes and previous examination questions',
            url: 'https://example.com/notes',
          ),
        ],
      ),
    ),
    'success story': () => const StoryDetailPage(
      name: 'A student’s journey into engineering and research',
      body:
          '# The journey\n\nA longer paragraph with **important details** and a [resource](https://example.com).',
    ),
    'notification': () => NotificationDetailPage(
      notification: NotificationModel(
        id: '1',
        title: 'The revised schedule for your semester examinations',
        body: 'Please read the updated schedule and check your subjects.',
        timestamp: DateTime(2026, 10, 6),
      ),
    ),
  };
  for (final page in pages.entries) {
    testWidgets('${page.key} fits a narrow screen with enlarged text', (
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
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: page.value(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restyled expense form still saves an expense', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const ExpenseTrackerPage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Lunch');
    await tester.enterText(find.byType(TextField).at(1), '125');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final expenses = jsonDecode(prefs.getString('expenses')!) as List;
    expect(expenses.single['item'], 'Lunch');
    expect(expenses.single['value'], 125);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer matches its redesigned layout', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RepaintBoundary(
          key: const ValueKey('drawer-preview'),
          child: Scaffold(
            drawer: const UniqueDrawer(themeColor: AppStyle.paper),
            appBar: AppBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('drawer-preview')),
      matchesGoldenFile('../goldens/drawer.png'),
    );
  });

  testWidgets('bento drawer fits a narrow screen with enlarged text', (
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
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          drawer: const UniqueDrawer(themeColor: AppStyle.paper),
          appBar: AppBar(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Notifications').hitTestable(),
      160,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Notifications').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer closes and opens the selected destination', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            drawer: const UniqueDrawer(themeColor: AppStyle.paper),
            appBar: AppBar(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) =>
              const Scaffold(body: Text('Notification destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Notifications').hitTestable(),
      160,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notification destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
