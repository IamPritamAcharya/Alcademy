import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/stories/presentation/news_story_content.dart';
import 'package:port/features/stories/presentation/random_bg.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('ProductSans')
          ..addFont(rootBundle.load('assets/fonts/Product Sans Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Product Sans Bold.ttf')))
        .load();
  });
  const story = {
    'type': 'news',
    'category': 'tech',
    'source': 'Tech publisher',
    'title':
        'A longer technology headline that needs several lines on a small phone',
    'description':
        'A short explanation of the development, with enough detail to help decide whether to open the original article.',
    'imageUrl': 'https://example.com/image.jpg',
  };

  Future<void> show(
    WidgetTester tester,
    Map<String, String> item, {
    double scale = 1,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: NewsStoryContent(
            story: item,
            onOpenSource: () {},
            imageOverride: const ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'News title is centered, patterned and article link is at the top',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewsStoryContent(
              story: story,
              onOpenSource: () => opened = true,
              imageOverride: const ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      );
      final title = find.byKey(const Key('news-story-title'));
      expect(tester.widget<AutoSizeText>(title).textAlign, TextAlign.center);
      expect(tester.getCenter(title).dx, 195);
      expect(find.byType(StoryBackdrop), findsOneWidget);
      final link = find.byKey(const Key('news-story-source-button'));
      expect(tester.getRect(link).bottom, lessThan(100));
      await tester.tap(link);
      expect(opened, isTrue);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Read full story'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'News stays readable on small phones with enlarged text without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester, {
        ...story,
        'title': List.filled(12, 'New technology').join(' '),
        'description': List.filled(
          14,
          'A useful development',
        ).join(' ').substring(0, 280),
      }, scale: 1.6);
      expect(find.byType(Scrollable), findsNothing);
      for (final key in ['news-story-title', 'news-story-description']) {
        final text = find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.text.toPlainText(), isNotEmpty);
        final rendered = key == 'news-story-description'
            ? tester.widget<Text>(find.byKey(Key(key)))
            : tester.widget<Text>(
                find.descendant(
                  of: find.byKey(Key(key)),
                  matching: find.byType(Text),
                ),
              );
        expect(
          rendered.style!.fontSize,
          greaterThanOrEqualTo(key == 'news-story-title' ? 20 : 16),
        );
        expect(tester.getRect(text).bottom, lessThanOrEqualTo(568 - 104));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hindustan Times election story keeps full readable text on a standard phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final election = {
        ...story,
        'source': 'Hindustan Times',
        'title':
            "Election results Tamil Nadu LIVE: Vijay's TVK snatches lead from AIADMK in Dharapuram, also ahead in Madurantakam",
        'description':
            "Election results Tamil Nadu LIVE: Chief minister Vijay-led TVK's candidate snatched the lead spot from AIADMK nominee Banumathi in Dharapuram (SC) after five rounds of counting for bypolls, according to ECI website. Vijay's party is also leading in Madurantakam (SC) Assembly…",
      };
      await show(tester, election);
      expect(find.byType(FittedBox), findsNothing);
      for (final key in ['news-story-title', 'news-story-description']) {
        final text = find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(RichText),
        );
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
          reason: key,
        );
        expect(tester.getRect(text).bottom, lessThanOrEqualTo(844 - 104));
      }
      final imageHeight = tester
          .getSize(find.byKey(const Key('news-story-image')))
          .height;
      await show(tester, election, scale: 1.6);
      expect(
        tester.getSize(find.byKey(const Key('news-story-image'))).height,
        lessThan(imageHeight),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Article link stays fixed across story lengths', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final button = find.byKey(const Key('news-story-source-button'));
    await show(tester, {...story, 'description': 'A short description.'});
    final position = tester.getRect(button);
    await show(tester, {
      ...story,
      'description': List.filled(
        14,
        'A longer description.',
      ).join(' ').substring(0, 280),
    });
    expect(tester.getRect(button), position);
    expect(tester.takeException(), isNull);
  });
}
