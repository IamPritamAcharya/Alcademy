import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:port/features/home/presentation/home_page.dart';
import 'package:port/features/home/presentation/widgets/home_header.dart';
import 'package:port/features/home/presentation/widgets/home_subject_list.dart';
import 'package:port/features/home/presentation/widgets/home_style.dart';
import 'package:port/features/home/presentation/widgets/tabs_widget.dart';
import 'package:port/features/home/presentation/widgets/first_tab_page.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/notes/models/subject.dart';

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
            theme: ThemeData(fontFamily: 'ProductSans'),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 932),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                backgroundColor: HomeStyle.background,
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
                        currentSentence: 'Another day, another chance!',
                        onMenu: () => menuOpened = true,
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
}
