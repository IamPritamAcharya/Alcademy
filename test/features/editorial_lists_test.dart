import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/notices/data/notice_repository.dart';
import 'package:port/features/notices/models/notice.dart';
import 'package:port/features/notices/presentation/notice_page.dart';
import 'package:port/features/notices/presentation/widgets/notice_entry.dart';
import '../support/load_fonts.dart';

String noticeHtml(int count) =>
    '<table>${List.generate(count, (index) => '<tr id="noticerow_$index"><td><a href="https://example.com/circular-$index.pdf">Circular ${index + 1}: Revised examination schedule and academic registration</a></td><td>06 Oct 2026</td><td></td></tr>').join()}</table>';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  testWidgets('notice pages stay valid when a refresh reduces the list', (
    tester,
  ) async {
    var count = 12;
    final repository = NoticeRepository(
      client: MockClient((_) async => http.Response(noticeHtml(count), 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: NoticePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Next notices').hitTestable(),
      400,
    );
    await tester.tap(find.byTooltip('Next notices'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    count = 3;
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty notice board keeps refresh available', (tester) async {
    final repository = NoticeRepository(
      client: MockClient((_) async => http.Response('<table></table>', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: NoticePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The board is quiet. Check back for new circulars.'),
      findsOneWidget,
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('1 / 0'), findsNothing);
  });

  testWidgets('notice entries fit enlarged text and retain their taps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final notice = Notice(
      title:
          'Revised examination schedule for Electrical and Electronics Engineering students',
      date: 'Tuesday, 06 October 2026',
      downloadLink: 'https://example.com/schedule.pdf',
    );
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (_, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              NoticeEntry(
                notice: notice,
                number: 1,
                featured: true,
                onTap: () => opened++,
              ),
              NoticeEntry(notice: notice, number: 2, onTap: () => opened++),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(notice.title).first);
    expect(opened, 1);
    await tester.scrollUntilVisible(
      find.text(notice.title).last.hitTestable(),
      200,
    );
    await tester.tap(find.text(notice.title).last);
    expect(opened, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice board matches its editorial design', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = NoticeRepository(
      client: MockClient((_) async => http.Response(noticeHtml(3), 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: RepaintBoundary(
          key: const ValueKey('notice-board'),
          child: NoticePage(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('notice-board')),
      matchesGoldenFile('../goldens/notices.png'),
    );
  });
}
