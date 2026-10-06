import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/app/theme.dart';
import 'package:port/features/amenities/presentation/amenities_page.dart';
import 'package:port/features/amenities/presentation/amenity_photo.dart';
import 'package:port/features/amenities/presentation/details_page.dart';
import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  final fixtures = [
    {
      'name': 'Central library',
      'tag': 'Study',
      'images': <String>[],
      'description':
          '## A place to study\n\nBooks, reading rooms, and reference material.',
    },
    {
      'name': 'Electronics laboratory',
      'tag': 'Lab',
      'images': <String>[],
      'description': 'Practical classes and equipment.',
    },
    {
      'name': 'Research centre',
      'tag': 'Laboratory',
      'images': <String>[],
      'description': 'Research facilities.',
    },
  ];
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'amenities_data': jsonEncode(fixtures),
    }),
  );

  Future<void> showPage(
    WidgetTester tester,
    Widget page, {
    double width = 430,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('amenities-preview'),
          child: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty searches keep controls available and clear filters restores places',
    (tester) async {
      await showPage(tester, const AmenitiesPage());
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Find a place or facility'));
      await tester.pumpAndSettle();
      expect(find.text('Search amenities'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'not a place');
      await tester.pumpAndSettle();
      expect(find.text('No matches found.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Central library'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lab'));
      await tester.pumpAndSettle();
      expect(find.text('Electronics laboratory'), findsOneWidget);
      expect(find.text('Research centre'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('amenity details retain content and fit enlarged text', (
    tester,
  ) async {
    await showPage(tester, const AmenitiesPage(), width: 320, textScale: 1.6);
    await tester.scrollUntilVisible(
      find.text('Central library').hitTestable(),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Central library'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    expect(find.text('A place to study'), findsOneWidget);
    expect(
      find.text('Books, reading rooms, and reference material.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh failure keeps cached places and a smaller refresh clamps pagination',
    (tester) async {
      final places = List.generate(
        12,
        (i) => {
          'name': 'Campus place ${i + 1}',
          'tag': 'Campus',
          'images': <String>[],
          'description': '',
        },
      );
      SharedPreferences.setMockInitialValues({
        'amenities_data': jsonEncode(places),
      });
      var fail = true;
      final client = MockClient(
        (_) async => fail
            ? http.Response('', 503)
            : http.Response(jsonEncode(fixtures.take(1).toList()), 200),
      );
      addTearDown(client.close);
      await showPage(tester, AmenitiesPage(client: client));
      await tester.scrollUntilVisible(
        find.byTooltip('Next amenities').hitTestable(),
        400,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byTooltip('Next amenities'));
      await tester.pumpAndSettle();
      expect(find.text('Campus place 11'), findsOneWidget);
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(find.text('Campus place 11'), findsOneWidget);
      expect(
        find.text('The campus guide couldn’t update. Please try again.'),
        findsOneWidget,
      );
      fail = false;
      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();
      expect(find.text('Central library'), findsOneWidget);
      expect(find.text('Campus place 11'), findsNothing);
      expect(find.byTooltip('Next amenities'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('photo gallery supports paging and opening a zoomable photo', (
    tester,
  ) async {
    await showPage(
      tester,
      DetailsPage(
        item: {
          'name': 'Library',
          'tag': 'Study',
          'images': [
            'https://example.com/one.png',
            'https://example.com/two.png',
          ],
          'description': 'Reading rooms.',
        },
      ),
    );
    expect(find.text('PHOTO 1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Next photo'));
    await tester.pumpAndSettle();
    expect(find.text('PHOTO 2 / 2'), findsOneWidget);
    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Close photo'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campus directory matches its design', (tester) async {
    await showPage(tester, const AmenitiesPage());
    await expectLater(
      find.byKey(const ValueKey('amenities-preview')),
      matchesGoldenFile('../goldens/amenities.png'),
    );
    expect(tester.takeException(), isNull);
  });

  test('Drive image links support both sharing formats', () {
    expect(
      amenityImageUrl(
        'https://drive.google.com/file/d/photo-id/view?usp=sharing',
      ),
      'https://drive.google.com/uc?export=view&id=photo-id',
    );
    expect(
      amenityImageUrl('https://drive.google.com/open?id=photo-id'),
      'https://drive.google.com/uc?export=view&id=photo-id',
    );
    expect(
      amenityImageUrl('https://example.com/photo.png'),
      'https://example.com/photo.png',
    );
  });
}
