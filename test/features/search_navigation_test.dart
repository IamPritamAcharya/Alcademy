import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/amenities/presentation/amenities_page.dart';
import 'package:port/features/amenities/presentation/details_page.dart';
import 'package:port/features/private_space/presentation/private_content_viewer.dart';
import 'package:port/shared/widgets/search_results_page.dart';
import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> showPage(
    WidgetTester tester,
    Widget page, {
    bool enlarged = false,
  }) async {
    tester.view.physicalSize = Size(enlarged ? 320 : 430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(enlarged ? 1.6 : 1)),
          child: child!,
        ),
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'amenity search includes later pages and returns to the unchanged directory',
    (tester) async {
      final places = List.generate(
        12,
        (i) => {
          'name': 'Campus place ${i + 1}',
          'tag': 'Campus',
          'images': <String>[],
          'description': 'Place ${i + 1} details.',
        },
      );
      SharedPreferences.setMockInitialValues({
        'amenities_data': jsonEncode(places),
      });
      await showPage(tester, const AmenitiesPage());
      await tester.tap(find.text('Find a place or facility'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).autofocus,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), ' CAMPUS PLACE 12 ');
      await tester.pumpAndSettle();
      expect(find.text('1 RESULT'), findsOneWidget);
      await tester.tap(find.text('Campus place 12'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailsPage), findsOneWidget);
      expect(find.text('Place 12 details.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1 RESULT'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Campus place 1'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'private file search uses a result page and leaves the library untouched',
    (tester) async {
      await showPage(
        tester,
        PrivateContentViewer(
          contentType: 'Documents',
          items: const ['/tmp/algebra.pdf', '/tmp/chemistry.pdf'],
          onDelete: (_) => fail('Searching must not delete a file'),
        ),
      );
      await tester.tap(find.byTooltip('Search private documents'));
      await tester.pumpAndSettle();
      expect(find.text('Search private documents'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ALGEBRA');
      await tester.pumpAndSettle();
      expect(find.text('algebra'), findsOneWidget);
      expect(find.text('chemistry'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Private Documents'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search results fit enlarged text above an open keyboard', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    await showPage(
      tester,
      SearchResultsPage<String>(
        title: 'Search documents',
        hint: 'Find a document',
        items: const [
          'Electrical and Electronics Engineering revision notes',
          'Semester schedules',
        ],
        searchableText: (item) => item,
        resultBuilder: (_, item, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(item),
        ),
      ),
      enlarged: true,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(find.byType(TextField), 'electrical');
    await tester.pumpAndSettle();
    expect(find.text('1 RESULT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
