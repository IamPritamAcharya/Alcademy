import 'package:port/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:port/features/home/presentation/home_page.dart';
import 'package:port/features/home/presentation/greetings.dart';
import 'package:port/features/home/presentation/widgets/home_header.dart';
import 'package:port/features/home/presentation/widgets/home_subject_list.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/tabs_widget.dart';
import 'package:port/features/home/presentation/widgets/first_tab_page.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:port/features/stories/presentation/stories_widget.dart';
import 'package:port/features/stories/presentation/story_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('ProductSans')
          ..addFont(rootBundle.load('assets/fonts/Product Sans Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Product Sans Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('home fits width $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final online = ValueNotifier(true);
        addTearDown(online.dispose);
        var menuOpened = false;
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 932),
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: Scaffold(
                backgroundColor: AppStyle.background,
                bottomNavigationBar: HomeNavigation(
                  selectedIndex: 0,
                  onSelected: (index) => selected = index,
                ),
                body: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHeader(
                        isOnlineNotifier: online,
                        userName: 'Alexandrapriyadarshini',
                        currentSentence:
                            'One small step today can change your whole semester.',
                        onMenu: () => menuOpened = true,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: StoriesWidget(
                        stories: [
                          {
                            'type': 'text',
                            'text':
                                'A fresh update from campus, with everything you need to know this week.',
                          },
                          {'type': 'text', 'text': 'Something worth sharing.'},
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(child: TabsWidget(onTabPressed: (_) {})),
                    HomeSubjectList(
                      subjects: [
                        Subject(
                          name:
                              'Introduction to Electrical and Electronics Engineering',
                          items: [],
                        ),
                      ],
                      onSubjectTap: (_, __) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .getSize(find.byKey(const ValueKey('hero-headline-slot')))
              .height,
          68,
        );
        final richFinder = find.descendant(
          of: find.byType(AutoSizeText),
          matching: find.byType(RichText),
        );
        final rich = tester.widget<RichText>(richFinder);
        final painter = TextPainter(
          text: rich.text,
          textDirection: rich.textDirection ?? TextDirection.ltr,
          textScaler: rich.textScaler,
          maxLines: rich.maxLines,
          ellipsis: '…',
        )..layout(maxWidth: tester.getSize(richFinder).width);
        expect(painter.computeLineMetrics().length, lessThanOrEqualTo(2));
        painter.dispose();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Open menu'));
        expect(menuOpened, isTrue);
        online.value = false;
        await tester.pump();
        expect(find.text('OFFLINE'), findsOneWidget);
        await tester.tap(find.text('Notices'));
        expect(selected, 1);
      });
    }
  }

  testWidgets('story covers open the selected story', (tester) async {
    const stories = [
      {'type': 'text', 'text': 'First campus update'},
      {'type': 'text', 'text': 'Second campus update'},
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StoriesWidget(stories: stories)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second campus update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final screen = tester.widget<StoryScreen>(find.byType(StoryScreen));
    expect(screen.initialIndex, 1);
    expect(screen.stories, stories);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('subject row opens the selected subject', (tester) async {
    final subject = Subject(
      name: 'Applied Physics',
      items: [
        SubjectItem(name: 'Chapter one', url: 'https://example.com/chapter'),
      ],
    );
    Subject? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              HomeSubjectList(
                subjects: [subject],
                onSubjectTap: (_, value) => selected = value,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('1 resource'), findsOneWidget);
    await tester.tap(find.text('Applied Physics'));
    expect(selected, same(subject));
  });

  testWidgets('configurable campus tool retains its route', (tester) async {
    final original = AppConfiguration.current.value;
    addTearDown(() => AppConfiguration.current.value = original);
    AppConfiguration.current.value = AppConfig(firstTabName: 'Campus updates');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TabsWidget(onTabPressed: (_) {})),
      ),
    );
    await tester.tap(find.text('Campus updates'));
    await tester.pumpAndSettle();
    expect(find.byType(FirstTabPage), findsOneWidget);
  });
  testWidgets(
    'book motion stops in reduced-motion mode and shows resource count',
    (tester) async {
      final online = ValueNotifier(true);
      addTearDown(online.dispose);
      Widget preview(bool reduced) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(430, 932),
            disableAnimations: reduced,
          ),
          child: Scaffold(
            body: HomeHeader(
              isOnlineNotifier: online,
              userName: 'Student',
              currentSentence: 'Another day, another chance!',
              resourceCount: 7,
              onMenu: () {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(preview(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('7 resources. All within reach.'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(preview(true));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  test('a fresh greeting does not repeat the previous greeting', () {
    var previous = getRandomSentence();
    for (var i = 0; i < 30; i++) {
      final next = getRandomSentence(previous: previous);
      expect(next, isNot(previous));
      expect(next, isNotEmpty);
      previous = next;
    }
  });

  testWidgets(
    'new greeting control updates the headline and preserves resource count',
    (tester) async {
      final online = ValueNotifier(true);
      addTearDown(online.dispose);
      var sentence = 'Another day, another chance!';
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (_, setState) => HomeHeader(
                  isOnlineNotifier: online,
                  userName: 'Student',
                  currentSentence: sentence,
                  resourceCount: 7,
                  onMenu: () {},
                  onNewGreeting: () => setState(
                    () => sentence = getRandomSentence(previous: sentence),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final previous = sentence;
      expect(find.text(previous), findsOneWidget);
      await tester.tap(find.byTooltip('New greeting'));
      await tester.pumpAndSettle();
      expect(sentence, isNot(previous));
      expect(find.text(previous), findsNothing);
      expect(find.text(sentence), findsOneWidget);
      expect(find.text('7 resources. All within reach.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'greeting changes keep the hero height stable without layout errors',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final online = ValueNotifier(true);
      addTearDown(online.dispose);
      var sentence = 'You’ve got this.';
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(430, 932)),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (_, setState) => HomeHeader(
                  isOnlineNotifier: online,
                  userName: 'Student',
                  currentSentence: sentence,
                  resourceCount: 7,
                  onMenu: () {},
                  onNewGreeting: () => setState(() {
                    sentence = sentence.length < 30
                        ? 'One small step today can change your whole semester.'
                        : 'You’ve got this.';
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      final heroHeight = tester
          .getSize(find.byKey(const ValueKey('home-hero')))
          .height;
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('New greeting'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(sentence), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('home-hero'))).height,
          heroHeight,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
